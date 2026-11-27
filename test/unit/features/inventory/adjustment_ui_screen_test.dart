// ignore_for_file: must_call_super
// Pantalla de Ajuste de stock: tocar la opción, escribir, leer la frase de
// resultado y el texto del botón. También que no se desborde en celular.
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_balance.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/warehouse.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_stock_adjustment_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_balance_by_product_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouses_usecase.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_adjustments_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_adjustments_screen.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/usecases/search_products_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import '../../../helpers/session_role.dart';

class _Create extends Mock implements CreateStockAdjustmentUseCase {}

class _Balance extends Mock implements GetInventoryBalanceByProductUseCase {}

class _Search extends Mock implements SearchProductsUseCase {}

class _Warehouses extends Mock implements GetWarehousesUseCase {}

class _Sync extends GetxService with Mock implements SyncService {
  final _online = true.obs;
  @override
  Future<void> onInit() async {}
  @override
  bool get isOnline => _online.value;
  @override
  int get permanentlyFailedCount => 0;
  @override
  SyncState get syncState => SyncState.idle;
  @override
  int get pendingOperationsCount => 0;
  @override
  DateTime? get lastSyncTime => DateTime(2026, 11, 26, 9, 55);
}

final _now = DateTime(2026, 11, 26, 10);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late InventoryAdjustmentsController c;

  setUp(() {
    Get.testMode = true;
    Get.put(TenantDateTimeService());
    Get.put<SyncService>(_Sync());
    // Estas pruebas son del administrador (el único que ajusta).
    putSessionRole(UserRole.admin);
  });
  tearDown(Get.reset);

  Future<void> mount(
    WidgetTester tester,
    Size size, {
    int stock = 20,
    bool unconfirmed = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final warehouses = _Warehouses();
    when(() => warehouses()).thenAnswer(
      (_) async => const Right([
        Warehouse(
          id: 'w1',
          name: 'Bodega Principal',
          code: 'B1',
          isActive: true,
          isMainWarehouse: true,
        ),
      ]),
    );
    final balance = _Balance();
    when(
      () => balance(any(), warehouseId: any(named: 'warehouseId')),
    ).thenAnswer(
      (_) async => Right(
        InventoryBalance(
          productId: 'p1',
          productName: 'Gaseosa Cola 400 ml',
          productSku: 'SKU-p1',
          categoryName: 'Bebidas',
          totalQuantity: stock,
          reservedQuantity: 3,
          minStock: 5,
          averageCost: 2500,
          totalValue: 2500.0 * stock,
          isLowStock: false,
          isOutOfStock: false,
          warehouseId: 'w1',
          lastUpdated: _now,
          isStockUnconfirmed: unconfirmed,
        ),
      ),
    );
    final create = _Create();
    when(
      () => create(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('x')));

    c = Get.put(
      InventoryAdjustmentsController(
        createStockAdjustmentUseCase: create,
        getInventoryBalanceByProductUseCase: balance,
        searchProductsUseCase: _Search(),
        getWarehousesUseCase: warehouses,
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: const InventoryAdjustmentsScreen(),
      ),
    );
    await tester.pump();
    await c.selectProduct(
      Product(
        id: 'p1',
        name: 'Gaseosa Cola 400 ml',
        sku: 'SKU-p1',
        type: ProductType.product,
        status: ProductStatus.active,
        stock: stock.toDouble(),
        minStock: 5,
        unit: 'und',
        categoryId: 'c1',
        createdById: 'u1',
        createdAt: _now,
        updatedAt: _now,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  String buttonText(WidgetTester tester) {
    final button = find.byKey(const ValueKey('adjust-submit'));
    return tester
        .widgetList<Text>(
          find.descendant(of: button, matching: find.byType(Text)),
        )
        .map((t) => t.data)
        .join();
  }

  bool buttonEnabled(WidgetTester tester) =>
      tester
          .widget<ButtonStyleButton>(
            find.byKey(const ValueKey('adjust-submit')),
          )
          .enabled;

  testWidgets('escritorio: restar 5 muestra la frase y el botón con el verbo', (
    tester,
  ) async {
    await mount(tester, const Size(1440, 900));

    expect(
      find.textContaining('unidades de', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('3 están apartadas en pedidos'), findsOneWidget);
    expect(buttonEnabled(tester), isFalse, reason: 'ninguna opción elegida');

    await tester.tap(find.byKey(const ValueKey('adjust-mode-subtract')));
    await tester.pump();
    expect(find.text('¿Cuántas unidades salen?'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('adjust-amount')), '5');
    await tester.pump();
    expect(
      find.textContaining('quedarán 15 (−5)', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Costo de lo que sale: \$ 12.500'), findsOneWidget);
    expect(buttonText(tester), 'Restar 5 unidades');
    expect(find.text('Elige una razón para guardar'), findsOneWidget);
    expect(buttonEnabled(tester), isFalse);

    await tester.tap(find.text('Mercancía dañada'));
    await tester.pump();
    expect(find.text('Elige una razón para guardar'), findsNothing);
    expect(buttonEnabled(tester), isTrue);

    // Restar más de lo que hay.
    await tester.enterText(find.byKey(const ValueKey('adjust-amount')), '25');
    await tester.pump();
    expect(find.text('No puedes restar 25: solo hay 20.'), findsOneWidget);
    expect(buttonEnabled(tester), isFalse);
  });

  testWidgets('celular: sumar y cantidad exacta sin desbordes', (tester) async {
    await mount(tester, const Size(390, 844));

    await tester.tap(find.byKey(const ValueKey('adjust-mode-add')));
    await tester.pump();
    expect(find.text('¿Cuántas unidades entran?'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('adjust-amount')), '4');
    await tester.pump();
    expect(
      find.textContaining('quedarán 24 (+4)', findRichText: true),
      findsOneWidget,
    );
    expect(buttonText(tester), 'Sumar 4 unidades');

    await tester.ensureVisible(find.byKey(const ValueKey('adjust-mode-exact')));
    await tester.tap(find.byKey(const ValueKey('adjust-mode-exact')));
    await tester.pump();
    expect(find.text('¿Cuántas unidades contaste?'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('adjust-amount')), '20');
    await tester.pump();
    expect(find.text('Ya hay 20. No hay nada que cambiar.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('adjust-amount')), '17');
    await tester.pump();
    expect(buttonText(tester), 'Guardar: quedan 17');
    expect(
      buttonEnabled(tester),
      isTrue,
      reason: 'la razón de conteo queda elegida',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('saldo sin confirmar: aviso y botón apagado', (tester) async {
    await mount(tester, const Size(1440, 900), unconfirmed: true);
    expect(
      find.textContaining('(sin confirmar)', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(kUnconfirmedStockMessage), findsOneWidget);
    expect(buttonEnabled(tester), isFalse);
  });
}
