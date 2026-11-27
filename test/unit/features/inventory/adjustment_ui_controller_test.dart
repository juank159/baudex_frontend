// Controladores de Ajuste de stock y Ajustes masivos tras el rediseño:
// lo que se envía al servidor debe ser exactamente lo de antes.
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_balance.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/warehouse.dart';
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_bulk_stock_adjustments_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_stock_adjustment_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_balance_by_product_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouses_usecase.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_adjustments_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_bulk_adjustments_controller.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/usecases/search_products_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class _Create extends Mock implements CreateStockAdjustmentUseCase {}

class _Bulk extends Mock implements CreateBulkStockAdjustmentsUseCase {}

class _Balance extends Mock implements GetInventoryBalanceByProductUseCase {}

class _Search extends Mock implements SearchProductsUseCase {}

class _Warehouses extends Mock implements GetWarehousesUseCase {}

final _now = DateTime(2026, 11, 26, 10);
const _wh = Warehouse(
  id: 'w1',
  name: 'Bodega Principal',
  code: 'BOD-01',
  isActive: true,
  isMainWarehouse: true,
);

Product _product(String id) => Product(
  id: id,
  name: 'Producto $id',
  sku: 'SKU-$id',
  type: ProductType.product,
  status: ProductStatus.active,
  stock: 20,
  minStock: 5,
  unit: 'und',
  categoryId: 'c1',
  createdById: 'u1',
  createdAt: _now,
  updatedAt: _now,
);

InventoryBalance _balance(String id, int qty, {bool unconfirmed = false}) =>
    InventoryBalance(
      isStockUnconfirmed: unconfirmed,
      productId: id,
      productName: 'Producto $id',
      productSku: 'SKU-$id',
      categoryName: 'Bebidas',
      totalQuantity: qty,
      minStock: 5,
      averageCost: 2500,
      totalValue: 2500.0 * qty,
      isLowStock: false,
      isOutOfStock: qty == 0,
      warehouseId: 'w1',
      lastUpdated: _now,
    );

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<CreateStockAdjustmentParams>[]);
  });

  late _Create create;
  late _Balance balance;
  late _Warehouses warehouses;

  setUp(() {
    Get.testMode = true;
    create = _Create();
    balance = _Balance();
    warehouses = _Warehouses();
    when(() => warehouses()).thenAnswer((_) async => const Right([_wh]));
    when(() => create(any())).thenAnswer(
      (_) async => const Left(ServerFailure('Solicitud incorrecta: prueba')),
    );
  });
  tearDown(Get.reset);

  Future<InventoryAdjustmentsController> ready(
    WidgetTester tester, {
    int stock = 20,
    bool balanceFails = false,
    bool unconfirmed = false,
  }) async {
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
    if (balanceFails) {
      when(
        () => balance(any(), warehouseId: any(named: 'warehouseId')),
      ).thenAnswer((_) async => const Left(CacheFailure('sin datos')));
    } else {
      when(
        () => balance(any(), warehouseId: any(named: 'warehouseId')),
      ).thenAnswer(
        (_) async => Right(_balance('p1', stock, unconfirmed: unconfirmed)),
      );
    }
    final c = Get.put(
      InventoryAdjustmentsController(
        createStockAdjustmentUseCase: create,
        getInventoryBalanceByProductUseCase: balance,
        searchProductsUseCase: _Search(),
        getWarehousesUseCase: warehouses,
      ),
    );
    await tester.pump();
    await c.selectProduct(_product('p1'));
    return c;
  }

  Future<Map<String, dynamic>> submit(
    WidgetTester tester,
    InventoryAdjustmentsController c,
  ) async {
    await c.createAdjustment();
    await tester.pump(const Duration(seconds: 6));
    final captured =
        verify(() => create(captureAny())).captured.single
            as Map<String, dynamic>;
    return captured;
  }

  group('Ajuste de stock', () {
    testWidgets(
      'restar 5 de 20 envía adjustmentQuantity −5 y los mismos campos',
      (tester) async {
        final c = await ready(tester);
        expect(c.selectedWarehouseId.value, 'w1');
        expect(
          c.mode.value,
          isNull,
          reason: 'ninguna opción elegida al entrar',
        );
        c.setMode(StockAdjustMode.subtract);
        c.setAmount(5);
        c.setReasonFromPredefined('Mercancía dañada');
        expect(c.newQuantity.value, 15);
        expect(c.isFormValid, isTrue);
        expect(c.submitButtonText, 'Restar 5 unidades');
        expect(c.costText, 'Costo de lo que sale: \$ 12.500');

        final sent = await submit(tester, c);
        expect(sent.keys.toSet(), {
          'productId',
          'adjustmentQuantity',
          'warehouseId',
          'notes',
          'movementDate',
          'unitCost',
        });
        expect(sent['productId'], 'p1');
        expect(sent['adjustmentQuantity'], -5);
        expect(sent['warehouseId'], 'w1');
        expect(sent['notes'], isNull, reason: 'la razón no se envía');
        expect(sent['unitCost'], 2500.0);
      },
    );

    testWidgets('sumar 5 a 20 envía +5', (tester) async {
      final c = await ready(tester);
      c.setMode(StockAdjustMode.add);
      c.setAmount(5);
      c.setReasonFromPredefined('Devolución de cliente');
      c.notesController.text = 'llegó del cliente';
      final sent = await submit(tester, c);
      expect(sent['adjustmentQuantity'], 5);
      expect(sent['notes'], 'llegó del cliente');
    });

    testWidgets(
      'cantidad exacta 17 con 20: envía −3 y la razón queda elegida',
      (tester) async {
        final c = await ready(tester);
        c.setMode(StockAdjustMode.exact);
        expect(c.reason.value, 'Corrección de inventario físico');
        c.setAmount(17);
        expect(c.submitButtonText, 'Guardar: quedan 17');
        final sent = await submit(tester, c);
        expect(sent['adjustmentQuantity'], -3);
      },
    );

    testWidgets('restar más de lo que hay: no envía nada', (tester) async {
      final c = await ready(tester);
      c.setMode(StockAdjustMode.subtract);
      c.setAmount(25);
      c.setReasonFromPredefined('Pérdida o robo');
      expect(c.blockingReason, 'No puedes restar 25: solo hay 20.');
      await c.createAdjustment();
      await tester.pump(const Duration(seconds: 6));
      verifyNever(() => create(any()));
    });

    testWidgets('exacta igual a lo que hay: no envía nada', (tester) async {
      final c = await ready(tester);
      c.setMode(StockAdjustMode.exact);
      c.setAmount(20);
      expect(c.blockingReason, 'Ya hay 20. No hay nada que cambiar.');
      await c.createAdjustment();
      await tester.pump(const Duration(seconds: 6));
      verifyNever(() => create(any()));
    });

    testWidgets('sin razón pide elegir una', (tester) async {
      final c = await ready(tester);
      c.setMode(StockAdjustMode.subtract);
      c.setAmount(2);
      expect(c.blockingReason, 'Elige una razón para guardar');
      expect(c.isFormValid, isFalse);
    });

    testWidgets('stock que no se pudo leer: no permite ajustar ni envía', (
      tester,
    ) async {
      final c = await ready(tester, balanceFails: true);
      expect(c.canAdjust, isFalse);
      expect(c.balanceError.value, isNotEmpty);
      c.setMode(StockAdjustMode.add);
      c.setAmount(5);
      c.setReasonFromPredefined('Otro');
      expect(c.isFormValid, isFalse);
      expect(c.blockingReason, contains('No pudimos leer'));
      await c.createAdjustment();
      await tester.pump(const Duration(seconds: 6));
      verifyNever(() => create(any()));
    });

    testWidgets('saldo sin confirmar: botón apagado y no envía', (
      tester,
    ) async {
      final c = await ready(tester, unconfirmed: true);
      expect(c.isStockUnconfirmed, isTrue);
      expect(c.canAdjust, isFalse);
      c.setMode(StockAdjustMode.subtract);
      c.setAmount(2);
      c.setReasonFromPredefined('Otro');
      expect(c.isFormValid, isFalse);
      expect(c.blockingReason, kUnconfirmedStockMessage);
      await c.createAdjustment();
      await tester.pump(const Duration(seconds: 6));
      verifyNever(() => create(any()));
    });

    testWidgets('al cambiar de opción se limpia el número', (tester) async {
      final c = await ready(tester);
      c.setMode(StockAdjustMode.subtract);
      c.setAmount(5);
      c.setMode(StockAdjustMode.add);
      expect(c.amount.value, isNull);
      expect(c.newQuantity.value, 20);
    });
  });

  group('Ajustes masivos', () {
    testWidgets(
      'envía las mismas diferencias y campos; omite filas sin stock leído',
      (tester) async {
        await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
        Get.put(TenantDateTimeService());
        final bulk = _Bulk();
        when(
          () => bulk(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('prueba')));
        final c = Get.put(
          InventoryBulkAdjustmentsController(
            createBulkStockAdjustmentsUseCase: bulk,
            getInventoryBalanceByProductUseCase: balance,
            searchProductsUseCase: _Search(),
            getWarehousesUseCase: warehouses,
          ),
        );
        await tester.pump();
        expect(c.selectedWarehouseId.value, 'w1');

        BulkAdjustmentItem row(String id, int? qty) => BulkAdjustmentItem(
          id: id,
          product: _product(id),
          currentBalance: qty == null ? null : _balance(id, qty),
        )..newQuantity.value = qty ?? 0;
        final a =
            row('a', 20)
              ..setMode(StockAdjustMode.subtract)
              ..setAmount(5);
        final b =
            row('b', 8)
              ..setMode(StockAdjustMode.add)
              ..setAmount(4);
        final d =
            row('d', 5)
              ..setMode(StockAdjustMode.exact)
              ..setAmount(9);
        final unknown = row('u', null)..setMode(StockAdjustMode.add);
        unknown.setAmount(3);
        c.adjustmentItems.assignAll([a, b, d, unknown]);

        expect(a.plan.shortResultText, '20 → 15 (−5)');
        expect(unknown.hasChanges, isFalse);
        expect(c.itemsWithChanges, [a, b, d]);
        expect(c.isFormValid, isTrue);

        await c.createBulkAdjustments();
        await tester.pump(const Duration(seconds: 6));
        final sent =
            verify(() => bulk(captureAny())).captured.single
                as List<CreateStockAdjustmentParams>;
        expect(sent.map((p) => p.productId), ['a', 'b', 'd']);
        expect(sent.map((p) => p.adjustmentQuantity), [-5, 4, 4]);
        expect(sent.every((p) => p.warehouseId == 'w1'), isTrue);
        expect(
          sent.every((p) => p.reason == InventoryMovementReason.adjustment),
          isTrue,
        );
        // Salidas con 0; entradas con el costo de la ficha (aquí sin precios: 0),
        // igual que antes.
        expect(sent.map((p) => p.unitCost), [0.0, 0.0, 0.0]);
      },
    );

    testWidgets('restar de más bloquea; Poner en Cero deja exacta en 0', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      Get.put(TenantDateTimeService());
      final c = Get.put(
        InventoryBulkAdjustmentsController(
          createBulkStockAdjustmentsUseCase: _Bulk(),
          getInventoryBalanceByProductUseCase: balance,
          searchProductsUseCase: _Search(),
          getWarehousesUseCase: warehouses,
        ),
      );
      await tester.pump();
      final a = BulkAdjustmentItem(
        id: 'a',
        product: _product('a'),
        currentBalance: _balance('a', 2),
      )..newQuantity.value = 2;
      c.adjustmentItems.assignAll([a]);
      a
        ..setMode(StockAdjustMode.subtract)
        ..setAmount(6);
      expect(a.errorText, 'No puedes restar 6: solo hay 2.');
      expect(c.isFormValid, isFalse);

      c.setQuantityForAllSelected(0);
      expect(a.mode.value, StockAdjustMode.exact);
      expect(a.adjustmentDifference, -2);
      expect(c.isFormValid, isTrue);

      c.resetQuantityForAllSelected();
      expect(a.adjustmentDifference, 0);
      expect(c.isFormValid, isFalse);

      // Una fila marcada con saldo sin confirmar apaga el botón.
      final u = BulkAdjustmentItem(
        id: 'u',
        product: _product('u'),
        currentBalance: _balance('u', 7, unconfirmed: true),
      );
      a.setExact(0);
      c.adjustmentItems.add(u);
      expect(u.stockKnown, isFalse);
      expect(c.hasUnconfirmedSelected, isTrue);
      expect(c.isFormValid, isFalse);
      u.isSelected.value = false;
      expect(c.isFormValid, isTrue);
    });
  });
}
