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

import 'package:baudex_desktop/app/config/themes/app_theme.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_balance.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_batch.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/kardex_report.dart';
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
  _WdC([GetWarehouseByIdUseCase? byId])
      : super(
          getWarehouseByIdUseCase: byId ?? _WhById(),
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

InventoryMovement _movement(
  String id,
  String name,
  InventoryMovementType type,
  InventoryMovementReason reason,
  int qty, {
  InventoryMovementStatus status = InventoryMovementStatus.confirmed,
  String? notes,
  Map<String, dynamic>? metadata,
}) =>
    InventoryMovement(
      id: id,
      productId: 'p-$id',
      productName: name,
      productSku: 'SKU-$id',
      type: type,
      status: status,
      reason: reason,
      quantity: qty,
      unitCost: 2500,
      totalCost: 2500.0 * qty.abs(),
      warehouseId: 'w1',
      warehouseName: 'Bodega Principal',
      notes: notes,
      metadata: metadata,
      userName: 'Cajero 1',
      movementDate: _now,
      createdAt: _now,
      updatedAt: _now,
    );

final _movements = [
  // Ajuste que resta 5 (el ajuste trae el signo en la cantidad).
  _movement('m1', 'Gaseosa Cola 400 ml', InventoryMovementType.adjustment, InventoryMovementReason.damage, -5),
  // Ajuste que suma 5.
  _movement('m2', 'Arroz Diana 500 g', InventoryMovementType.adjustment, InventoryMovementReason.adjustment, 5),
  _movement('m3', 'Detergente en polvo multiusos aroma lavanda bolsa grande 3 kg', InventoryMovementType.inbound, InventoryMovementReason.purchase, 120000),
  _movement('m4', 'Aceite girasol 1 L', InventoryMovementType.outbound, InventoryMovementReason.sale, 3, status: InventoryMovementStatus.pending),
];

InventoryBatch _batch(String id, String number, int original, int current, InventoryBatchStatus status, {DateTime? expiry, String? supplier}) =>
    InventoryBatch(
      id: id,
      productId: 'p1',
      productName: 'Gaseosa Cola 400 ml',
      productSku: 'SKU-p1',
      batchNumber: number,
      originalQuantity: original,
      currentQuantity: current,
      consumedQuantity: original - current,
      unitCost: 2500,
      totalCost: 2500.0 * current,
      entryDate: _now.subtract(const Duration(days: 40)),
      expiryDate: expiry,
      status: status,
      supplierId: supplier == null ? null : 's1',
      supplierName: supplier,
      warehouseId: 'w1',
      warehouseName: 'Bodega Principal',
      createdAt: _now,
      updatedAt: _now,
    );

KardexMovement _kmov(int day, String number, String type, String desc, double inQ, double outQ, double balance) => KardexMovement(
      date: DateTime(2026, 11, day, 10),
      movementNumber: number,
      movementType: type,
      description: desc,
      entryQuantity: inQ,
      exitQuantity: outQ,
      balance: balance,
      unitCost: 2500,
      entryCost: inQ * 2500,
      exitCost: outQ * 2500,
      balanceValue: balance * 2500,
      createdBy: 'Cajero 1',
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
          // El mismo tema que usa la app (main.dart). El título de la barra
          // no fija fuente (en el equipo usa la del sistema); aquí se le
          // pone Roboto para que no salga en cuadros.
          theme: AppTheme.lightTheme.copyWith(
            appBarTheme: AppTheme.lightTheme.appBarTheme.copyWith(
              titleTextStyle: AppTheme.lightTheme.appBarTheme.titleTextStyle
                  ?.copyWith(fontFamily: 'Roboto'),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: AppTheme.lightTheme.elevatedButtonTheme.style?.copyWith(
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: AppTheme.lightTheme.outlinedButtonTheme.style?.copyWith(
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: AppTheme.lightTheme.textButtonTheme.style?.copyWith(
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
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
    c.movements.assignAll(_movements);
    c.filteredMovements.assignAll(_movements);
    c.selectedTab.value = 1;
    c.error.value = '';
    await both(tester, 'lista-3-movimientos', () => const InventoryListScreen());
    c.selectedTab.value = 0;
    c.error.value = 'Solicitud incorrecta: DioException [bad response]: status 400 null';
    await both(tester, 'lista-4-error', () => const InventoryListScreen());
    c.error.value = '';
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
    c.valuationData.assignAll({'totalValue': 1225057500.0, 'totalProducts': 4.0, 'totalUnits': 125023.0});
    await both(tester, 'valorizacion-2-con-datos', () => const InventoryValuationScreen());
    c.valuationData.clear();
    c.error.value = 'Solicitud incorrecta: Internal server error';
    await both(tester, 'valorizacion-3-error', () => const InventoryValuationScreen());
    c.error.value = '';
    c.isLoading.value = true;
    await both(tester, 'saldos-0-cargando', () => const InventoryBalanceScreen());
  });

  testWidgets('lotes, movimientos, kardex', (tester) async {
    tolerateOverflow();
    final b = Get.put<InventoryBatchesController>(_BatC());
    await both(tester, 'lotes-1-vacio', () => const InventoryBatchesScreen());
    b.productName.value = 'Gaseosa Cola 400 ml';
    b.inventoryBatches.assignAll([
      _batch('b1', 'L-2026-001', 48, 20, InventoryBatchStatus.active, expiry: DateTime(2027, 3, 1), supplier: 'Distribuidora Andina de Bebidas y Alimentos S.A.S.'),
      _batch('b2', 'L-2026-002', 24, 24, InventoryBatchStatus.active, expiry: DateTime(2026, 12, 5)),
      _batch('b3', 'L-2025-118', 30, 0, InventoryBatchStatus.depleted),
      _batch('b4', 'L-2025-090', 12, 4, InventoryBatchStatus.expired, expiry: DateTime(2026, 10, 1)),
    ]);
    b.totalFixedItems.value = 4;
    b.activeBatchesCount.value = 2;
    b.expiredBatchesCount.value = 1;
    b.consumedBatchesCount.value = 1;
    await both(tester, 'lotes-2-con-datos', mobH: 1300, () => const InventoryBatchesScreen());
    b.inventoryBatches.clear();
    b.error.value = 'SocketException: Failed host lookup';
    await both(tester, 'lotes-3-error', () => const InventoryBatchesScreen());

    final m = Get.put<InventoryMovementsController>(_MovC());
    await both(tester, 'movimientos-1-vacio', () => const InventoryMovementsScreen());
    m.movements.assignAll(_movements);
    m.filteredMovements.assignAll(_movements);
    m.totalItems.value = _movements.length;
    await both(tester, 'movimientos-2-con-datos', mobH: 1300, () => const InventoryMovementsScreen());

    final k = Get.put<KardexController>(_KarC());
    await both(tester, 'kardex-1-vacio', () => const KardexScreen());
    k.kardexReport.value = KardexReport(
      product: const KardexProduct(id: 'p1', name: 'Gaseosa Cola 400 ml', sku: 'SKU-p1', categoryName: 'Bebidas'),
      period: KardexPeriod(startDate: DateTime(2026, 11, 1), endDate: DateTime(2026, 11, 26)),
      initialBalance: const KardexBalance(quantity: 20, value: 50000, averageCost: 2500),
      movements: [
        _kmov(3, 'MOV-0001', 'purchase', 'Compra a proveedor', 120000, 0, 120020),
        _kmov(10, 'MOV-0002', 'adjustment', 'Ajuste: mercancía dañada', 0, 5, 120015),
        _kmov(18, 'MOV-0003', 'transfer_in', 'Traslado desde Punto de venta Centro', 3, 0, 120018),
        _kmov(25, 'MOV-0004', 'sale', 'Venta factura FV-1024', 0, 18, 120000),
      ],
      finalBalance: const KardexBalance(quantity: 120000, value: 300000000, averageCost: 2500),
      summary: const KardexSummary(totalEntries: 120003, totalExits: 23, totalPurchases: 300000000, totalSales: 54000, averageUnitCost: 2500, totalValue: 300000000),
    );
    await both(tester, 'kardex-2-con-datos', mobH: 1600, () => const KardexScreen());
    k.selectedTab.value = 1;
    await both(tester, 'kardex-2b-movimientos', mobH: 1300, () => const KardexScreen());
    k.selectedTab.value = 0;
    k.kardexReport.value = null;
    k.error.value = 'Solicitud incorrecta: product not found';
    await both(tester, 'kardex-3-error', () => const KardexScreen());
  });

  testWidgets('traslados y crear traslado', (tester) async {
    tolerateOverflow();
    final t = Get.put<InventoryTransfersController>(_TrC());
    await both(tester, 'traslados-1-vacio', () => const InventoryTransfersScreen());
    t.transfers.assignAll([
      _movement('t1', 'Gaseosa Cola 400 ml', InventoryMovementType.transferOut, InventoryMovementReason.transfer, 12,
          notes: 'Reposición semanal', metadata: {'fromWarehouseName': 'Bodega Principal', 'toWarehouseName': 'Punto de venta Centro'}),
      _movement('t2', 'Detergente en polvo multiusos aroma lavanda bolsa grande 3 kg', InventoryMovementType.transferOut, InventoryMovementReason.transfer, 4,
          status: InventoryMovementStatus.pending, metadata: {'fromWarehouseName': 'Bodega Principal', 'toWarehouseName': 'Bodega de devoluciones y mercancía averiada sede norte'}),
    ]);
    await both(tester, 'traslados-2-con-datos', mobH: 1300, () => const InventoryTransfersScreen());
    final c = Get.put<CreateTransferController>(_CtC());
    c.warehouses.assignAll([_wh, _wh2]);
    await both(tester, 'crear-traslado-1-vacio', () => const CreateTransferScreen());
  });

  testWidgets('antigüedad', (tester) async {
    tolerateOverflow();
    final a = Get.put<InventoryAgingController>(_AgC());
    await both(tester, 'antiguedad-1-vacia', () => const InventoryAgingReportScreen());
    a.agingData.assignAll([
      {'productName': 'Gaseosa Cola 400 ml', 'productSku': 'SKU-p1', 'quantity': 20, 'totalValue': 50000.0, 'averageAgeDays': 12, 'oldestBatchAge': 40, 'newestBatchAge': 3},
      {'productName': 'Detergente en polvo multiusos aroma lavanda bolsa grande 3 kg', 'productSku': 'SKU-p3', 'quantity': 125000, 'totalValue': 1225000000.0, 'averageAgeDays': 95, 'oldestBatchAge': 210, 'newestBatchAge': 30},
      {'productName': 'Arroz Diana 500 g', 'productSku': 'SKU-p2', 'quantity': 3, 'totalValue': 7500.0, 'averageAgeDays': 200, 'oldestBatchAge': 380, 'newestBatchAge': 120},
    ]);
    a.agingSummary.value = AgingSummary(totalProducts: 3, totalValue: 1225057500, averageAgeDays: 102);
    await both(tester, 'antiguedad-2-con-datos', mobH: 1300, () => const InventoryAgingReportScreen());
    a.agingData.clear();
    a.error.value = 'Solicitud incorrecta: Internal server error';
    await both(tester, 'antiguedad-3-error', () => const InventoryAgingReportScreen());
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
          Warehouse(
            id: 'w3',
            name: 'Bodega de devoluciones y mercancía averiada sede norte',
            code: 'DEV-NORTE-0003',
            description: 'Mercancía devuelta por clientes y productos con empaque dañado',
            address: 'Carrera 45 # 123-67, parque industrial La Estrella, Medellín',
            isActive: false,
            isMainWarehouse: false,
          ),
        ]));
    when(() => stats(any())).thenAnswer((_) async => const Left(ServerFailure('sin datos')));
    Get.put<WarehousesController>(_WhC(get, stats));
    // La primera toma de escritorio sale cargando; la segunda ya con datos.
    await both(tester, 'almacenes-0-cargando', () => const WarehousesScreen());
    await both(tester, 'almacenes-2-con-datos', () => const WarehousesScreen());
    Get.put<WarehouseDetailController>(_WdC());
    await both(tester, 'almacen-detalle-1-sin-datos', () => const WarehouseDetailScreen());
    Get.delete<WarehouseDetailController>(force: true);

    // Detalle CON datos: nombre y dirección largos.
    final byId = _WhById();
    when(() => byId(any())).thenAnswer((_) async => Right(Warehouse(
          id: 'w3',
          name: 'Bodega de devoluciones y mercancía averiada sede norte',
          code: 'DEV-NORTE-0003',
          description: 'Mercancía devuelta por clientes y productos con empaque dañado pendientes de revisión',
          address: 'Carrera 45 # 123-67, bodega 12, parque industrial La Estrella, Medellín',
          isActive: true,
          createdAt: _now.subtract(const Duration(days: 120)),
          updatedAt: _now,
        )));
    final wd = Get.put<WarehouseDetailController>(_WdC(byId));
    await tester.runAsync(() => wd.loadWarehouseDetails());
    await both(tester, 'almacen-detalle-2-con-datos', mobH: 1400, () => const WarehouseDetailScreen());

    final wf = Get.put<WarehouseFormController>(_WfC());
    await both(tester, 'almacen-form-1-nuevo', () => const WarehouseFormScreen());
    wf.nameController.text = 'Bodega de devoluciones y mercancía averiada sede norte';
    wf.codeController.text = 'DEV-NORTE-0003';
    wf.descriptionController.text = 'Mercancía devuelta por clientes pendiente de revisión';
    wf.addressController.text = 'Carrera 45 # 123-67, parque industrial La Estrella';
    await both(tester, 'almacen-form-2-lleno', mobH: 1400, () => const WarehouseFormScreen());
  });
}
