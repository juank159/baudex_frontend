// Genera imágenes (PNG) de las pantallas de Inventario con fuentes reales,
// para revisarlas a ojo sin abrir la app. Solo corre si se indica dónde
// guardar:
//
//   BAUDEX_VISUAL_OUT=/ruta flutter test test/visual/inventory_screens_visual_test.dart
//
// Los controladores son los reales, con los casos de uso simulados y sin
// cargar nada al iniciar (onInit vacío); los datos se ponen a mano.
// ignore_for_file: must_call_super
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_balance.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/warehouse.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/calculate_fifo_consumption_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/cancel_inventory_movement_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/check_warehouse_code_exists_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/check_warehouse_has_movements_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/confirm_inventory_movement_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/confirm_inventory_transfer_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_bulk_stock_adjustments_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_inventory_movement_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_inventory_transfer_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_stock_adjustment_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_warehouse_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/delete_warehouse_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_active_warehouses_count_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_expired_products_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_aging_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_balance_by_product_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_balances_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_batches_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_movement_by_id_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_movements_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_stats_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_valuation_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_kardex_report_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_near_expiry_products_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_out_of_stock_products_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouse_by_id_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouse_movements_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouse_stats_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouses_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/update_warehouse_usecase.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/create_transfer_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_adjustments_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_aging_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_balance_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_batches_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_bulk_adjustments_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_movements_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_transfers_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/kardex_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/warehouse_detail_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/warehouse_form_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/warehouses_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/create_transfer_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_adjustments_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_aging_report_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_balance_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_batches_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_bulk_adjustments_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_movements_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_transfers_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_valuation_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/kardex_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/warehouse_detail_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/warehouse_form_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/warehouses_screen.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_low_stock_products_usecase.dart';
import 'package:baudex_desktop/features/products/domain/usecases/search_products_usecase.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

final _out = Platform.environment['BAUDEX_VISUAL_OUT'];
const _fonts = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

class _CreateTransfer extends Mock implements CreateInventoryTransferUseCase {}
class _GetWarehouses extends Mock implements GetWarehousesUseCase {}
class _SearchProducts extends Mock implements SearchProductsUseCase {}
class _BalanceByProduct extends Mock implements GetInventoryBalanceByProductUseCase {}
class _CreateAdjustment extends Mock implements CreateStockAdjustmentUseCase {}
class _Aging extends Mock implements GetInventoryAgingUseCase {}
class _Balances extends Mock implements GetInventoryBalancesUseCase {}
class _Valuation extends Mock implements GetInventoryValuationUseCase {}
class _Batches extends Mock implements GetInventoryBatchesUseCase {}
class _Bulk extends Mock implements CreateBulkStockAdjustmentsUseCase {}
class _Movements extends Mock implements GetInventoryMovementsUseCase {}
class _Stats extends Mock implements GetInventoryStatsUseCase {}
class _Low extends Mock implements GetLowStockProductsUseCase {}
class _Out extends Mock implements GetOutOfStockProductsUseCase {}
class _Expired extends Mock implements GetExpiredProductsUseCase {}
class _Near extends Mock implements GetNearExpiryProductsUseCase {}
class _WhMovements extends Mock implements GetWarehouseMovementsUseCase {}
class _CreateMovement extends Mock implements CreateInventoryMovementUseCase {}
class _MovementById extends Mock implements GetInventoryMovementByIdUseCase {}
class _ConfirmMovement extends Mock implements ConfirmInventoryMovementUseCase {}
class _CancelMovement extends Mock implements CancelInventoryMovementUseCase {}
class _Fifo extends Mock implements CalculateFifoConsumptionUseCase {}
class _ConfirmTransfer extends Mock implements ConfirmInventoryTransferUseCase {}
class _Kardex extends Mock implements GetKardexReportUseCase {}
class _WhById extends Mock implements GetWarehouseByIdUseCase {}
class _DeleteWh extends Mock implements DeleteWarehouseUseCase {}
class _HasMov extends Mock implements CheckWarehouseHasMovementsUseCase {}
class _ActiveCount extends Mock implements GetActiveWarehousesCountUseCase {}
class _CreateWh extends Mock implements CreateWarehouseUseCase {}
class _UpdateWh extends Mock implements UpdateWarehouseUseCase {}
class _CodeExists extends Mock implements CheckWarehouseCodeExistsUseCase {}
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
class _WhStats extends Mock implements GetWarehouseStatsUseCase {}

// ---------- Controladores reales sin carga al iniciar ----------
class _AdjC extends InventoryAdjustmentsController {
  _AdjC()
      : super(
          createStockAdjustmentUseCase: _CreateAdjustment(),
          getInventoryBalanceByProductUseCase: _BalanceByProduct(),
          searchProductsUseCase: _SearchProducts(),
          getWarehousesUseCase: _GetWarehouses(),
        );
  @override
  void onInit() {}
}

class _BulkC extends InventoryBulkAdjustmentsController {
  _BulkC()
      : super(
          createBulkStockAdjustmentsUseCase: _Bulk(),
          getInventoryBalanceByProductUseCase: _BalanceByProduct(),
          searchProductsUseCase: _SearchProducts(),
          getWarehousesUseCase: _GetWarehouses(),
        );
  @override
  void onInit() {}
}

class _InvC extends InventoryController {
  _InvC()
      : super(
          getInventoryBalancesUseCase: _Balances(),
          getInventoryMovementsUseCase: _Movements(),
          getInventoryStatsUseCase: _Stats(),
          getLowStockProductsUseCase: _Low(),
          getOutOfStockProductsUseCase: _Out(),
          getExpiredProductsUseCase: _Expired(),
          getNearExpiryProductsUseCase: _Near(),
        );
  @override
  void onInit() {}
  @override
  void onReady() {}
}

class _BalC extends InventoryBalanceController {
  _BalC() : super(getInventoryBalancesUseCase: _Balances(), getInventoryValuationUseCase: _Valuation());
  @override
  void onInit() {}
}

class _BatC extends InventoryBatchesController {
  _BatC() : super(getInventoryBatchesUseCase: _Batches());
  @override
  void onInit() {}
  @override
  void onReady() {}
}

class _MovC extends InventoryMovementsController {
  _MovC()
      : super(
          getInventoryMovementsUseCase: _Movements(),
          getWarehouseMovementsUseCase: _WhMovements(),
          createInventoryMovementUseCase: _CreateMovement(),
          getInventoryMovementByIdUseCase: _MovementById(),
          confirmInventoryMovementUseCase: _ConfirmMovement(),
          cancelInventoryMovementUseCase: _CancelMovement(),
          calculateFifoConsumptionUseCase: _Fifo(),
          searchProductsUseCase: _SearchProducts(),
        );
  @override
  void onInit() {}
}

class _KarC extends KardexController {
  _KarC() : super(getKardexReportUseCase: _Kardex());
  @override
  void onInit() {}
}

class _TrC extends InventoryTransfersController {
  _TrC()
      : super(
          createTransferUseCase: _CreateTransfer(),
          confirmTransferUseCase: _ConfirmTransfer(),
          getMovementsUseCase: _Movements(),
          cancelInventoryMovementUseCase: _CancelMovement(),
          getWarehousesUseCase: _GetWarehouses(),
          searchProductsUseCase: _SearchProducts(),
          getInventoryBalanceByProductUseCase: _BalanceByProduct(),
        );
  @override
  void onInit() {}
  @override
  void onReady() {}
}

class _CtC extends CreateTransferController {
  _CtC()
      : super(
          createTransferUseCase: _CreateTransfer(),
          getWarehousesUseCase: _GetWarehouses(),
          searchProductsUseCase: _SearchProducts(),
          getInventoryBalanceByProductUseCase: _BalanceByProduct(),
        );
  @override
  void onInit() {}
}

class _AgC extends InventoryAgingController {
  _AgC() : super(getInventoryAgingUseCase: _Aging());
  @override
  void onInit() {}
}

class _WhC extends WarehousesController {
  _WhC(GetWarehousesUseCase get, GetWarehouseStatsUseCase stats)
      : super(getWarehousesUseCase: get, getWarehouseStatsUseCase: stats, deleteWarehouseUseCase: _DeleteWh());
}

class _WdC extends WarehouseDetailController {
  _WdC()
      : super(
          getWarehouseByIdUseCase: _WhById(),
          deleteWarehouseUseCase: _DeleteWh(),
          checkWarehouseHasMovementsUseCase: _HasMov(),
          getActiveWarehousesCountUseCase: _ActiveCount(),
        );
}

class _WfC extends WarehouseFormController {
  _WfC()
      : super(
          createWarehouseUseCase: _CreateWh(),
          updateWarehouseUseCase: _UpdateWh(),
          getWarehouseByIdUseCase: _WhById(),
          checkWarehouseCodeExistsUseCase: _CodeExists(),
        );
}

// ---------- Datos de ejemplo ----------
final _now = DateTime(2026, 11, 26, 10);
const _wh = Warehouse(id: 'w1', name: 'Bodega Principal', code: 'BOD-01', isActive: true, isMainWarehouse: true);
const _wh2 = Warehouse(id: 'w2', name: 'Punto de venta Centro', code: 'PV-02', isActive: true, isMainWarehouse: false);

Product _product(String id, String name, int stock) => Product(
      id: id,
      name: name,
      sku: 'SKU-$id',
      type: ProductType.product,
      status: ProductStatus.active,
      stock: stock.toDouble(),
      minStock: 5,
      unit: 'und',
      categoryId: 'c1',
      createdById: 'u1',
      createdAt: _now,
      updatedAt: _now,
    );

InventoryBalance _balance(String id, String name, int qty, {double cost = 2500}) => InventoryBalance(
      productId: id,
      productName: name,
      productSku: 'SKU-$id',
      categoryName: 'Bebidas',
      totalQuantity: qty,
      minStock: 5,
      averageCost: cost,
      totalValue: cost * qty,
      isLowStock: qty > 0 && qty <= 5,
      isOutOfStock: qty == 0,
      warehouseId: 'w1',
      lastUpdated: _now,
    );

void main() {
  if (_out == null) {
    test('imágenes de Inventario (omitida: falta BAUDEX_VISUAL_OUT)', () {}, skip: 'Solo para revisión visual');
    return;
  }

  final boundaryKey = GlobalKey();

  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('es_CO');
    tzdata.initializeTimeZones();
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final file in files) {
        final bytes = File('$_fonts/$file').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    }

    await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']);
    await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  setUp(() {
    Get.testMode = true;
    Get.put(TenantDateTimeService());
    Get.put<SyncService>(_Sync());
  });
  tearDown(Get.reset);

  Widget app(Widget home) => RepaintBoundary(
        key: boundaryKey,
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
          home: home,
        ),
      );

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  // Monta la pantalla en escritorio y celular y guarda ambas tomas.
  Future<void> both(WidgetTester tester, String name, Widget Function() screen, {double deskH = 900, double mobH = 844}) async {
    for (final s in [(Size(1440, deskH), 'escritorio'), (Size(390, mobH), 'celular')]) {
      tester.view.physicalSize = s.$1;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(app(KeyedSubtree(key: UniqueKey(), child: screen())));
      await settle(tester);
      await shot(tester, '$name-${s.$2}');
    }
    tester.view.reset();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  // Errores de dibujo (desbordes) se anotan, no detienen la toma.
  void tolerateOverflow() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed') || text.contains('RenderFlex')) {
        // ignore: avoid_print
        print('DESBORDE: ${text.split('\n').first}');
        return;
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  testWidgets('ajuste de stock: vacío, con producto, sumando y restando', (tester) async {
    tolerateOverflow();
    final c = Get.put<InventoryAdjustmentsController>(_AdjC());
    c.warehouses.assignAll([_wh, _wh2]);
    c.selectedWarehouseId.value = 'w1';
    c.selectedWarehouseName.value = 'Bodega Principal';
    await both(tester, 'ajuste-1-sin-producto', () => const InventoryAdjustmentsScreen());

    final p = _product('p1', 'Gaseosa Cola 400 ml', 20);
    c.selectedProduct.value = p;
    c.selectedProductId.value = 'p1';
    c.selectedProductName.value = p.name;
    c.currentBalance.value = _balance('p1', p.name, 20).copyWith(reservedQuantity: 3);
    c.currentStock.value = 20;
    c.newQuantity.value = 20;
    c.unitCost.value = 2500;
    c.unitCostController.text = '2500';
    await both(tester, 'ajuste-2-con-producto', () => const InventoryAdjustmentsScreen());

    // Restar 5 con razón elegida.
    c.setMode(StockAdjustMode.subtract);
    c.amountController.text = '5';
    c.setAmount(5);
    c.setReasonFromPredefined('Mercancía dañada');
    await both(tester, 'ajuste-3-restar-5', mobH: 1900, () => const InventoryAdjustmentsScreen());

    // Restar más de lo que hay.
    c.amountController.text = '25';
    c.setAmount(25);
    await both(tester, 'ajuste-4-restar-de-mas', mobH: 1900, () => const InventoryAdjustmentsScreen());

    // Sumar 5 sin razón todavía.
    c.setMode(StockAdjustMode.add);
    c.amountController.text = '5';
    c.setAmount(5);
    await both(tester, 'ajuste-5-sumar-5-sin-razon', mobH: 1900, () => const InventoryAdjustmentsScreen());

    // Cantidad exacta.
    c.setMode(StockAdjustMode.exact);
    c.amountController.text = '17';
    c.setAmount(17);
    await both(tester, 'ajuste-6-exacta-17', mobH: 1900, () => const InventoryAdjustmentsScreen());

    // Stock que no se pudo leer.
    c.currentBalance.value = null;
    c.balanceError.value = 'sin conexión';
    await both(tester, 'ajuste-7-stock-sin-leer', () => const InventoryAdjustmentsScreen());
    c.isLoadingBalance.value = true;
    await both(tester, 'ajuste-8-stock-cargando', () => const InventoryAdjustmentsScreen());
    c.isLoadingBalance.value = false;
    c.currentBalance.value = _balance('p1', p.name, 20).copyWith(isStockUnconfirmed: true);
    c.balanceError.value = '';
    await both(tester, 'ajuste-9-sin-confirmar', () => const InventoryAdjustmentsScreen());

    c.isLoading.value = true;
    c.warehouses.clear();
    await both(tester, 'ajuste-0-cargando', () => const InventoryAdjustmentsScreen());
    c.isLoading.value = false;
  });

  testWidgets('ajustes masivos: vacío y con productos', (tester) async {
    tolerateOverflow();
    final c = Get.put<InventoryBulkAdjustmentsController>(_BulkC());
    c.warehouses.assignAll([_wh, _wh2]);
    c.selectedWarehouseId.value = 'w1';
    c.selectedWarehouseName.value = 'Bodega Principal';
    await both(tester, 'masivo-1-vacio', () => const InventoryBulkAdjustmentsScreen());

    final names = [
      ('p1', 'Gaseosa Cola 400 ml', 20),
      ('p2', 'Arroz Diana 500 g', 8),
      ('p3', 'Detergente en polvo multiusos aroma lavanda bolsa grande 3 kg', 2),
      ('p4', 'Aceite girasol 1 L', 5),
      ('p5', 'Galletas de soda', 0),
    ];
    final items = [
      for (final n in names)
        BulkAdjustmentItem(
          id: n.$1,
          product: _product(n.$1, n.$2, n.$3),
          // p5: el stock no se pudo leer.
          currentBalance: n.$1 == 'p5' ? null : _balance(n.$1, n.$2, n.$3),
        )..newQuantity.value = n.$3,
    ];
    items[0]
      ..setMode(StockAdjustMode.subtract)
      ..setAmount(5);
    items[1]
      ..setMode(StockAdjustMode.add)
      ..setAmount(4);
    items[2]
      ..setMode(StockAdjustMode.subtract)
      ..setAmount(6); // más de lo que hay
    items[3].setMode(StockAdjustMode.exact);
    c.adjustmentItems.assignAll(items);
    c.generalReason.value = 'Corrección de inventario físico';
    await both(tester, 'masivo-2-con-productos', mobH: 1900, () => const InventoryBulkAdjustmentsScreen());
    items[2].setAmount(2);
    items[3].setAmount(9);
    await both(tester, 'masivo-3-listo', mobH: 1900, () => const InventoryBulkAdjustmentsScreen());
    c.adjustmentItems.add(BulkAdjustmentItem(
      id: 'p6',
      product: _product('p6', 'Leche entera 1 L', 12),
      currentBalance: _balance('p6', 'Leche entera 1 L', 12).copyWith(isStockUnconfirmed: true),
    )..newQuantity.value = 12);
    await both(tester, 'masivo-4-sin-confirmar', mobH: 2200, () => const InventoryBulkAdjustmentsScreen());
  });

  testWidgets('tablero y lista de inventario', (tester) async {
    tolerateOverflow();
    final c = Get.put<InventoryController>(_InvC());
    await both(tester, 'tablero-1-vacio', () => const InventoryDashboardScreen());
    await both(tester, 'lista-1-vacia', () => const InventoryListScreen());
    final data = [
      _balance('p1', 'Gaseosa Cola 400 ml', 20),
      _balance('p2', 'Arroz Diana 500 g', 3),
      _balance('p3', 'Detergente en polvo multiusos aroma lavanda bolsa grande 3 kg', 0),
    ];
    c.balances.assignAll(data);
    c.filteredBalances.assignAll(data);
    c.lowStockProducts.assignAll([data[1]]);
    c.outOfStockProducts.assignAll([data[2]]);
    await both(tester, 'tablero-2-con-datos', () => const InventoryDashboardScreen());
    await both(tester, 'lista-2-con-datos', () => const InventoryListScreen());
  });

  testWidgets('saldos y valorización', (tester) async {
    tolerateOverflow();
    final c = Get.put<InventoryBalanceController>(_BalC());
    await both(tester, 'saldos-1-vacio', () => const InventoryBalanceScreen());
    await both(tester, 'valorizacion-1-vacia', () => const InventoryValuationScreen());
    c.inventoryBalances.assignAll([
      _balance('p1', 'Gaseosa Cola 400 ml', 20),
      _balance('p2', 'Arroz Diana 500 g', 3),
      _balance('p3', 'Detergente en polvo multiusos aroma lavanda bolsa grande 3 kg', 0),
      _balance('p4', 'Aceite girasol 1 L', 125000, cost: 9800),
    ]);
    await both(tester, 'saldos-2-con-datos', () => const InventoryBalanceScreen());
    c.isLoading.value = true;
    await both(tester, 'saldos-0-cargando', () => const InventoryBalanceScreen());
  });

  testWidgets('lotes, movimientos, kardex', (tester) async {
    tolerateOverflow();
    Get.put<InventoryBatchesController>(_BatC());
    await both(tester, 'lotes-1-vacio', () => const InventoryBatchesScreen());
    Get.put<InventoryMovementsController>(_MovC());
    await both(tester, 'movimientos-1-vacio', () => const InventoryMovementsScreen());
    Get.put<KardexController>(_KarC());
    await both(tester, 'kardex-1-vacio', () => const KardexScreen());
  });

  testWidgets('traslados y crear traslado', (tester) async {
    tolerateOverflow();
    Get.put<InventoryTransfersController>(_TrC());
    await both(tester, 'traslados-1-vacio', () => const InventoryTransfersScreen());
    final c = Get.put<CreateTransferController>(_CtC());
    c.warehouses.assignAll([_wh, _wh2]);
    await both(tester, 'crear-traslado-1-vacio', () => const CreateTransferScreen());
  });

  testWidgets('antigüedad', (tester) async {
    tolerateOverflow();
    Get.put<InventoryAgingController>(_AgC());
    await both(tester, 'antiguedad-1-vacia', () => const InventoryAgingReportScreen());
  });

  testWidgets('almacenes: lista, detalle y formulario', (tester) async {
    tolerateOverflow();
    final emptyGet = _GetWarehouses();
    when(() => emptyGet()).thenAnswer((_) async => const Right(<Warehouse>[]));
    Get.put<WarehousesController>(_WhC(emptyGet, _WhStats()));
    await both(tester, 'almacenes-1-vacio', () => const WarehousesScreen());
    Get.delete<WarehousesController>(force: true);
    final get = _GetWarehouses();
    final stats = _WhStats();
    when(() => get()).thenAnswer((_) async => const Right([
          _wh,
          _wh2,
          Warehouse(id: 'w3', name: 'Bodega de devoluciones y mercancía averiada sede norte', code: 'DEV-NORTE-0003', isActive: false, isMainWarehouse: false),
        ]));
    when(() => stats(any())).thenAnswer((_) async => const Left(ServerFailure('sin datos')));
    Get.put<WarehousesController>(_WhC(get, stats));
    await both(tester, 'almacenes-2-con-datos', () => const WarehousesScreen());
    Get.put<WarehouseDetailController>(_WdC());
    await both(tester, 'almacen-detalle-1-sin-datos', () => const WarehouseDetailScreen());
    Get.put<WarehouseFormController>(_WfC());
    await both(tester, 'almacen-form-1-nuevo', () => const WarehouseFormScreen());
  });
}
