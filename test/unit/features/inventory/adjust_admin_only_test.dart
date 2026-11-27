// ignore_for_file: must_call_super
// Ajustes de inventario solo para el ADMINISTRADOR (decisión del dueño,
// 2026-11-27): la regla, las pantallas, los controladores, los accesos y la
// cola sin internet cuando el servidor responde 403.
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_failure_policy.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch_movement.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/data/repositories/inventory_offline_repository.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_balance.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/warehouse.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/domain/inventory_adjust_permission.dart';
import 'package:baudex_desktop/features/inventory/data/models/inventory_movement_model.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/calculate_fifo_consumption_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/cancel_inventory_movement_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/confirm_inventory_movement_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_inventory_movement_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_movement_by_id_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_movements_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouse_movements_usecase.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_movements_controller.dart';
import 'package:baudex_desktop/features/products/domain/usecases/delete_product_usecase.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_product_by_id_usecase.dart';
import 'package:baudex_desktop/features/products/domain/usecases/update_product_stock_usecase.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/product_detail_controller.dart';
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_bulk_stock_adjustments_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_stock_adjustment_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_balance_by_product_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouses_usecase.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_adjustments_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_bulk_adjustments_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_adjustments_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_bulk_adjustments_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/widgets/inventory_quick_actions.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_remote_datasource.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/models/product_model.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/usecases/search_products_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../../helpers/session_role.dart';

class _Create extends Mock implements CreateStockAdjustmentUseCase {}

class _Bulk extends Mock implements CreateBulkStockAdjustmentsUseCase {}

class _Balance extends Mock implements GetInventoryBalanceByProductUseCase {}

class _Search extends Mock implements SearchProductsUseCase {}

class _Warehouses extends Mock implements GetWarehousesUseCase {}

class _UiSync extends GetxService with Mock implements SyncService {
  @override
  Future<void> onInit() async {}
  @override
  bool get isOnline => true;
  @override
  int get permanentlyFailedCount => 0;
  @override
  SyncState get syncState => SyncState.idle;
  @override
  int get pendingOperationsCount => 0;
  @override
  DateTime? get lastSyncTime => DateTime(2026, 11, 27, 9);
}

final _now = DateTime(2026, 11, 27, 10);

const _wh = Warehouse(
  id: 'w1',
  name: 'Bodega Principal',
  code: 'B1',
  isActive: true,
  isMainWarehouse: true,
);

final _product = Product(
  id: 'p1',
  name: 'Gaseosa Cola 400 ml',
  sku: 'SKU-p1',
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

InventoryBalance _balance20() => InventoryBalance(
  productId: 'p1',
  productName: 'Gaseosa Cola 400 ml',
  productSku: 'SKU-p1',
  categoryName: 'Bebidas',
  totalQuantity: 20,
  reservedQuantity: 0,
  minStock: 5,
  averageCost: 2500,
  totalValue: 50000,
  isLowStock: false,
  isOutOfStock: false,
  warehouseId: 'w1',
  lastUpdated: _now,
);

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<CreateStockAdjustmentParams>[]);
    registerFallbackValue(
      CreateInventoryMovementParams(
        productId: 'x',
        type: InventoryMovementType.inbound,
        reason: InventoryMovementReason.adjustment,
        quantity: 1,
        unitCost: 0,
      ),
    );
    registerFallbackValue(
      const UpdateProductStockParams(id: 'x', quantity: 1),
    );
  });

  // ─────────────────────────── REGLA ───────────────────────────
  group('canAdjustInventory', () {
    test('solo el administrador; sin rol conocido no se permite', () {
      expect(canAdjustInventory(UserRole.admin), isTrue);
      expect(canAdjustInventory(UserRole.manager), isFalse);
      expect(canAdjustInventory(UserRole.user), isFalse);
      expect(canAdjustInventory(null), isFalse);
    });

    test('nuevo movimiento manual: todos los tipos al administrador, ninguno a los demás', () {
      expect(movementTypesFor(UserRole.admin), InventoryMovementType.values);
      for (final role in [UserRole.manager, UserRole.user, null]) {
        expect(movementTypesFor(role), isEmpty);
      }
    });
  });

  // ──────────── OTROS CAMINOS QUE CAMBIAN STOCK ────────────
  group('movimiento tipo ajuste y "Gestionar Stock" del producto', () {
    setUp(() {
      Get.testMode = true;
      Get.put(TenantDateTimeService());
    });
    tearDown(Get.reset);

    InventoryMovementsController movements(_CreateMovement create) =>
        InventoryMovementsController(
          getInventoryMovementsUseCase: _GetMovements(),
          getWarehouseMovementsUseCase: _GetWarehouseMovements(),
          createInventoryMovementUseCase: create,
          getInventoryMovementByIdUseCase: _GetMovementById(),
          confirmInventoryMovementUseCase: _ConfirmMovement(),
          cancelInventoryMovementUseCase: _CancelMovement(),
          calculateFifoConsumptionUseCase: _Fifo(),
          searchProductsUseCase: _Search(),
        );

    testWidgets('el controlador de movimientos no crea un "ajuste" de gerente', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      final auth = putSessionRole(UserRole.manager);
      final create = _CreateMovement();
      final c = movements(create)
        ..selectedProductId.value = 'p1'
        ..selectedProductName.value = 'Gaseosa'
        ..quantity.value = 3
        ..selectedType.value = InventoryMovementType.adjustment;

      expect(c.ensureAllowedManualMovement(), isFalse);
      await c.createMovement();
      await tester.pump(const Duration(seconds: 5));
      verifyNever(() => create(any()));

      // Desde 2026-11-27 tampoco otros tipos (entrada/salida a mano).
      c.selectedType.value = InventoryMovementType.outbound;
      expect(c.ensureAllowedManualMovement(), isFalse);
      // El administrador sí.
      auth.setRole(UserRole.admin);
      c.selectedType.value = InventoryMovementType.adjustment;
      expect(c.ensureAllowedManualMovement(), isTrue);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });

    ProductDetailController detail(_UpdateStock update) =>
        ProductDetailController(
          getProductByIdUseCase: _GetProduct(),
          updateProductStockUseCase: update,
          deleteProductUseCase: _DeleteProduct(),
        );

    testWidgets('"Gestionar Stock": el controlador se niega con gerente', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      putSessionRole(UserRole.manager);
      final update = _UpdateStock();
      final c = detail(update);

      expect(c.ensureAllowedToChangeStock(), isFalse);
      await c.updateStock(5, 'add');
      c.showStockDialog();
      await tester.pump(const Duration(seconds: 5));
      verifyNever(() => update(any()));
      expect(Get.isDialogOpen, isFalse);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });

    testWidgets('"Gestionar Stock": sin usuario tampoco; admin sí', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      final c = detail(_UpdateStock());
      expect(c.ensureAllowedToChangeStock(), isFalse);
      await tester.pump(const Duration(seconds: 5));
      putSessionRole(UserRole.admin);
      expect(c.ensureAllowedToChangeStock(), isTrue);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });
  });

  // ──────────────────── PANTALLAS Y CONTROLADORES ────────────────────
  group('pantallas y controladores', () {
    late _Create create;
    late _Bulk bulk;
    late _Balance balance;
    late _Warehouses warehouses;

    setUp(() {
      Get.testMode = true;
      Get.put(TenantDateTimeService());
      Get.put<SyncService>(_UiSync());
      create = _Create();
      bulk = _Bulk();
      balance = _Balance();
      warehouses = _Warehouses();
      when(() => warehouses()).thenAnswer((_) async => const Right([_wh]));
      when(
        () => balance(any(), warehouseId: any(named: 'warehouseId')),
      ).thenAnswer((_) async => Right(_balance20()));
      when(() => create(any())).thenAnswer(
        (_) async => const Left(ServerFailure('prueba')),
      );
      when(() => bulk(any())).thenAnswer(
        (_) async => const Left(ServerFailure('prueba')),
      );
    });
    tearDown(Get.reset);

    InventoryAdjustmentsController single() => Get.put(
      InventoryAdjustmentsController(
        createStockAdjustmentUseCase: create,
        getInventoryBalanceByProductUseCase: balance,
        searchProductsUseCase: _Search(),
        getWarehousesUseCase: warehouses,
      ),
    );

    InventoryBulkAdjustmentsController many() => Get.put(
      InventoryBulkAdjustmentsController(
        createBulkStockAdjustmentsUseCase: bulk,
        getInventoryBalanceByProductUseCase: balance,
        searchProductsUseCase: _Search(),
        getWarehousesUseCase: warehouses,
      ),
    );

    Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(debugShowCheckedModeBanner: false, home: screen),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    /// Deja el ajuste listo para guardar: almacén, producto y "restar 5".
    Future<void> fillSingle(WidgetTester tester, InventoryAdjustmentsController c) async {
      c.setSelectedWarehouse('w1', 'Bodega Principal');
      await c.selectProduct(_product);
      await tester.pump(const Duration(milliseconds: 400));
      c.setMode(StockAdjustMode.subtract);
      c.setAmount(5);
      c.setReasonFromPredefined('Mercancía dañada');
      await tester.pump();
    }

    for (final role in [UserRole.manager, UserRole.user, null]) {
      testWidgets('Ajuste de Stock con ${role?.name ?? 'sin usuario'}: '
          'mensaje y sin botón para aplicar', (tester) async {
        putSessionRole(role);
        single();
        await pumpScreen(tester, const InventoryAdjustmentsScreen());

        expect(find.text(kAdjustInventoryAdminOnlyMessage), findsOneWidget);
        expect(find.byKey(const ValueKey('adjust-admin-only')), findsOneWidget);
        expect(find.byKey(const ValueKey('adjust-submit')), findsNothing);
        expect(find.text('Sumar unidades'), findsNothing);
      });
    }

    testWidgets('Ajuste de Stock con administrador: igual que hoy', (
      tester,
    ) async {
      putSessionRole(UserRole.admin);
      final c = single();
      await pumpScreen(tester, const InventoryAdjustmentsScreen());
      await fillSingle(tester, c);

      expect(find.text(kAdjustInventoryAdminOnlyMessage), findsNothing);
      final button = find.byKey(const ValueKey('adjust-submit'));
      expect(button, findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(button).enabled, isTrue);
      expect(find.text('Restar 5 unidades'), findsOneWidget);
    });

    testWidgets('si el administrador sale y entra un gerente, se bloquea', (
      tester,
    ) async {
      final auth = putSessionRole(UserRole.admin);
      single();
      await pumpScreen(tester, const InventoryAdjustmentsScreen());
      expect(find.text(kAdjustInventoryAdminOnlyMessage), findsNothing);

      auth.setRole(UserRole.manager);
      await tester.pump();
      expect(find.text(kAdjustInventoryAdminOnlyMessage), findsOneWidget);
      expect(find.byKey(const ValueKey('adjust-submit')), findsNothing);
    });

    testWidgets('Ajustes Masivos con gerente: mensaje y sin botón', (
      tester,
    ) async {
      putSessionRole(UserRole.manager);
      many();
      await pumpScreen(tester, const InventoryBulkAdjustmentsScreen());

      expect(find.text(kAdjustInventoryAdminOnlyMessage), findsOneWidget);
      expect(find.byKey(const ValueKey('bulk-submit')), findsNothing);
    });

    testWidgets('Ajustes Masivos con administrador: se ve el formulario', (
      tester,
    ) async {
      putSessionRole(UserRole.admin);
      many();
      await pumpScreen(tester, const InventoryBulkAdjustmentsScreen());

      expect(find.text(kAdjustInventoryAdminOnlyMessage), findsNothing);
      expect(find.byKey(const ValueKey('adjust-admin-only')), findsNothing);
    });

    testWidgets('el controlador de Ajuste se niega con gerente: no envía nada', (
      tester,
    ) async {
      final auth = putSessionRole(UserRole.admin);
      final c = single();
      await pumpScreen(tester, const SizedBox());
      await fillSingle(tester, c);
      expect(c.isFormValid, isTrue);

      // Cambia el usuario (p. ej. otra sesión) con el formulario listo.
      auth.setRole(UserRole.manager);
      expect(c.ensureAllowedToAdjust(), isFalse);
      await c.createAdjustment();
      await tester.pump(const Duration(seconds: 5));

      verifyNever(() => create(any()));
    });

    testWidgets('el controlador de Ajustes Masivos se niega con usuario', (
      tester,
    ) async {
      putSessionRole(UserRole.user);
      final c = many();
      await pumpScreen(tester, const SizedBox());
      expect(c.ensureAllowedToAdjust(), isFalse);
      await c.createBulkAdjustments();
      await tester.pump(const Duration(seconds: 5));

      verifyNever(() => bulk(any()));
    });

    testWidgets('el controlador del administrador sí envía', (tester) async {
      putSessionRole(UserRole.admin);
      final c = single();
      await pumpScreen(tester, const SizedBox());
      await fillSingle(tester, c);
      expect(c.ensureAllowedToAdjust(), isTrue);
      await c.createAdjustment();
      await tester.pump(const Duration(seconds: 5));

      verify(() => create(any())).called(1);
    });
  });

  // ─────────────────────────── ACCESOS ───────────────────────────
  group('accesos', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    Future<void> pumpActions(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: InventoryQuickActions()),
          ),
        ),
      );
      await tester.pump();
    }

    for (final size in [const Size(1440, 900), const Size(390, 844)]) {
      final label = size.width < 600 ? 'celular' : 'escritorio';
      testWidgets('acciones rápidas ($label): gerente no ve los ajustes', (
        tester,
      ) async {
        putSessionRole(UserRole.manager);
        await pumpActions(tester, size);
        expect(find.text('Ajuste de Stock'), findsNothing);
        expect(find.text('Ajustes Masivos'), findsNothing);
        // Entrada/salida a mano: tampoco (2026-11-27).
        expect(find.text('Nuevo Movimiento'), findsNothing);
      });

      testWidgets('acciones rápidas ($label): administrador sí los ve', (
        tester,
      ) async {
        putSessionRole(UserRole.admin);
        await pumpActions(tester, size);
        expect(find.text('Ajuste de Stock'), findsOneWidget);
        expect(find.text('Ajustes Masivos'), findsOneWidget);
      });
    }

    testWidgets('acciones rápidas sin usuario: no se ven los ajustes', (
      tester,
    ) async {
      await pumpActions(tester, const Size(1440, 900));
      expect(find.text('Ajuste de Stock'), findsNothing);
      expect(find.text('Ajustes Masivos'), findsNothing);
    });
  });

  // ──────────────────── COLA SIN INTERNET: 403 ────────────────────
  group('clasificación del rechazo de un ajuste encolado', () {
    InventoryStockFailure adj(Object e) =>
        classifyInventoryStockFailure(e, isTransfer: false);

    test('403 (como lo lanza la app) → solo administrador', () {
      expect(adj(Exception('Error 403: Forbidden resource')),
          InventoryStockFailure.adminOnly);
      expect(adj(const ServerException('Forbidden resource', statusCode: 403)),
          InventoryStockFailure.adminOnly);
    });

    test('403 por suscripción vencida NO se revierte: se reintenta', () {
      expect(
        adj(Exception('Error 403: Su suscripción ha expirado')),
        InventoryStockFailure.retry,
      );
      expect(
        adj(const ServerException('Subscription has expired', statusCode: 403)),
        InventoryStockFailure.retry,
      );
    });

    test('400 sigue igual (rechazo); red, 401 y 500 se reintentan', () {
      expect(adj(Exception('Error 400: stock insuficiente')),
          InventoryStockFailure.rejected);
      expect(adj(Exception('Error 500: boom')), InventoryStockFailure.retry);
      expect(adj(Exception('Error 401: Unauthorized')), InventoryStockFailure.retry);
      expect(adj(Exception('Error de conexión. Verifica tu conexión a internet.')),
          InventoryStockFailure.retry);
    });

    test('un traslado con 403 no dice "ajuste": rechazo genérico', () {
      expect(
        classifyInventoryStockFailure(Exception('Error 403: Forbidden'),
            isTransfer: true),
        InventoryStockFailure.rejected,
      );
    });
  });

  group('cola sin internet: el servidor responde 403 a un ajuste', () {
    late Isar isar;
    late InventoryOfflineRepository repo;
    late _QueueSync queue;
    late _Remote remote;

    setUpAll(() async {
      final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
          'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
      await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('isar_adjust_403');
      isar = await Isar.open([
        IsarProductSchema,
        IsarInventoryBatchSchema,
        IsarInventoryMovementSchema,
        IsarInventoryBatchMovementSchema,
      ], directory: dir.path);
      IsarDatabase.debugSetDatabase(isar);
      Get.testMode = true;
      queue = _QueueSync();
      Get.put<SyncService>(queue);
      remote = _Remote();
      Get.put<InventoryRemoteDataSource>(remote);
      Get.put<ProductRemoteDataSource>(_ProductRemote());
      repo = InventoryOfflineRepository(database: _Db(isar));
      await isar.writeTxn(() async {
        await isar.isarProducts.put(IsarProduct.create(
          serverId: 'arroz', name: 'Arroz', sku: 'SKU-arroz',
          type: IsarProductType.product, status: IsarProductStatus.active,
          stock: 15, minStock: 0, categoryId: 'c',
          createdAt: DateTime(2026), updatedAt: DateTime(2026), isSynced: true,
          taxCategory: IsarTaxCategory.noGravado, taxRate: 0, isTaxable: false,
          hasRetention: false));
        await isar.isarInventoryBatchs.put(IsarInventoryBatch.create(
          serverId: 'lote', productId: 'arroz', productName: 'Arroz',
          productSku: 'SKU-arroz', batchNumber: 'lote', originalQuantity: 15,
          currentQuantity: 15, consumedQuantity: 0, unitCost: 100,
          totalCost: 1500, entryDate: DateTime(2026, 1, 1),
          status: IsarInventoryBatchStatus.active, warehouseId: 'principal',
          createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1),
          isSynced: true));
      });
    });

    tearDown(() async {
      Get.reset();
      await isar.close(deleteFromDisk: true);
      IsarDatabase.debugSetDatabase(null);
    });

    Future<double> stock() async =>
        (await isar.isarProducts.filter().serverIdEqualTo('arroz').findFirst())!
            .stock;

    /// Ajuste hecho sin internet (−7) y la operación que quedó en la cola.
    Future<SyncOperation> offlineAdjustment() async {
      final r = await repo.createStockAdjustment({
        'productId': 'arroz', 'adjustmentQuantity': -7,
        'warehouseId': 'principal', 'unitCost': 0.0,
      });
      expect(r.isRight(), isTrue);
      final op = queue.ops.last;
      return SyncOperation.create(
        entityType: op.entityType,
        entityId: op.entityId,
        operationType: SyncOperationType.create,
        payload: jsonEncode(op.data),
        organizationId: 'org-1',
      );
    }

    test('se revierte, avisa una vez con mensaje claro y no se reintenta', () async {
      final first = await offlineAdjustment();
      final second = await offlineAdjustment();
      expect(await stock(), 1); // 15 − 7 − 7 en el equipo
      expect(
        await isar.isarInventoryMovements
            .filter()
            .serverIdStartsWith(first.entityId)
            .count(),
        greaterThan(0),
      );

      remote.error = Exception('Error 403: Forbidden resource');
      final notices = <String>[];
      final sync = SyncService(null)
        ..debugOnInventoryRejectedNotice = (t, m) => notices.add('$t|$m');

      // Termina sin lanzar: la cola la da por cerrada (no la reintenta).
      await sync.debugSyncInventoryStockOperation(first);
      await sync.debugSyncInventoryStockOperation(second);

      expect(remote.calls, 2);
      // Movimientos temporales fuera y stock como en el servidor.
      for (final op in [first, second]) {
        expect(
          await isar.isarInventoryMovements
              .filter()
              .serverIdStartsWith(op.entityId)
              .count(),
          0,
        );
      }
      expect(await stock(), 15);
      // Un solo aviso para los dos ajustes, con el mensaje para el cajero.
      expect(notices, hasLength(1));
      expect(notices.single, contains(kAdjustRejectedAdminOnlyMessage));
      expect(notices.single, isNot(contains('Forbidden')));
    });

    test('403 como ServerException (cliente HTTP) también se revierte', () async {
      final op = await offlineAdjustment();
      remote.error = const ServerException('Forbidden resource', statusCode: 403);
      final notices = <String>[];
      final sync = SyncService(null)
        ..debugOnInventoryRejectedNotice = (t, m) => notices.add(m);

      await sync.debugSyncInventoryStockOperation(op);

      expect(await stock(), 15);
      expect(notices.single, contains(kAdjustRejectedAdminOnlyMessage));
    });

    /// Movimiento hecho sin internet y la operación que quedó en la cola.
    Future<SyncOperation> offlineMovement(InventoryMovementType type) async {
      final r = await repo.createMovement(CreateInventoryMovementParams(
        productId: 'arroz',
        type: type,
        reason: InventoryMovementReason.adjustment,
        quantity: 4,
        unitCost: 100,
        warehouseId: 'principal',
      ));
      expect(r.isRight(), isTrue);
      final op = queue.ops.last;
      expect(op.entityType, 'InventoryMovement');
      return SyncOperation.create(
        entityType: op.entityType,
        entityId: op.entityId,
        operationType: SyncOperationType.create,
        payload: jsonEncode(op.data),
        organizationId: 'org-1',
      );
    }

    Future<int> localMovements(String key) => isar.isarInventoryMovements
        .filter()
        .serverIdEqualTo(key)
        .count();

    test('movimiento tipo ajuste con 403: se revierte, un aviso, sin reintento',
        () async {
      final first = await offlineMovement(InventoryMovementType.adjustment);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final second = await offlineMovement(InventoryMovementType.adjustment);
      expect(await localMovements(first.entityId), 1);
      remote.error = Exception('Error 403: Forbidden resource');
      final notices = <String>[];
      final sync = SyncService(null)
        ..debugOnInventoryRejectedNotice = (t, m) => notices.add(m);

      // Termina sin lanzar: la cola la da por cerrada (no la reintenta).
      await sync.debugSyncInventoryMovementOperation(first);
      await sync.debugSyncInventoryMovementOperation(second);

      expect(remote.movementCalls, 2);
      expect(await localMovements(first.entityId), 0);
      expect(await localMovements(second.entityId), 0);
      expect(await stock(), 15);
      expect(notices, hasLength(1));
      expect(notices.single, contains(kAdjustRejectedAdminOnlyMessage));
    });

    test('movimiento que no es ajuste con 403: también se revierte (2026-11-27)',
        () async {
      final op = await offlineMovement(InventoryMovementType.inbound);
      expect(await localMovements(op.entityId), 1);
      remote.error = Exception('Error 403: Forbidden resource');
      final notices = <String>[];
      final sync = SyncService(null)
        ..debugOnInventoryRejectedNotice = (t, m) => notices.add(m);

      await sync.debugSyncInventoryMovementOperation(op);

      expect(await localMovements(op.entityId), 0);
      expect(await stock(), 15);
      expect(notices.single, contains(kAdjustRejectedAdminOnlyMessage));
    });

    test('movimiento tipo ajuste con 403 por suscripción: se conserva', () async {
      final op = await offlineMovement(InventoryMovementType.adjustment);
      remote.error = Exception('Error 403: Su suscripción ha expirado');
      final sync = SyncService(null)
        ..debugOnInventoryRejectedNotice = (t, m) => fail('no debe avisar');

      await expectLater(
        sync.debugSyncInventoryMovementOperation(op),
        throwsA(isA<Exception>()),
      );
      expect(await localMovements(op.entityId), 1);
    });

    test('403 por suscripción vencida: se conserva en el equipo y en la cola',
        () async {
      final op = await offlineAdjustment();
      remote.error = Exception('Error 403: Su suscripción ha expirado');
      final notices = <String>[];
      final sync = SyncService(null)
        ..debugOnInventoryRejectedNotice = (t, m) => notices.add(m);

      // Lanza: la cola la deja pendiente (pausa por suscripción).
      await expectLater(
        sync.debugSyncInventoryStockOperation(op),
        throwsA(isA<Exception>()),
      );
      expect(await stock(), 8);
      expect(notices, isEmpty);
    });
  });
}

// ─────────────────────────── DOBLES ───────────────────────────

class _QueuedOp {
  _QueuedOp(this.entityType, this.entityId, this.data);
  final String entityType;
  final String entityId;
  final Map<String, dynamic> data;
}

class _QueueSync extends SyncService {
  _QueueSync() : super(null);
  final ops = <_QueuedOp>[];

  @override
  Future<void> onInit() async {}

  @override
  Future<void> addOperationForCurrentUser({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    ops.add(_QueuedOp(entityType, entityId, data));
  }
}

class _Db implements IsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Remote extends Mock implements InventoryRemoteDataSource {
  Object error = Exception('sin configurar');
  int calls = 0;

  @override
  Future<Never> createStockAdjustment(Map<String, dynamic> request) async {
    calls++;
    throw error;
  }

  int movementCalls = 0;

  @override
  Future<InventoryMovementModel> createMovement(
    CreateInventoryMovementRequest request,
  ) async {
    movementCalls++;
    throw error;
  }
}

class _CreateMovement extends Mock implements CreateInventoryMovementUseCase {}

class _GetMovements extends Mock implements GetInventoryMovementsUseCase {}

class _GetWarehouseMovements extends Mock
    implements GetWarehouseMovementsUseCase {}

class _GetMovementById extends Mock implements GetInventoryMovementByIdUseCase {}

class _ConfirmMovement extends Mock implements ConfirmInventoryMovementUseCase {}

class _CancelMovement extends Mock implements CancelInventoryMovementUseCase {}

class _Fifo extends Mock implements CalculateFifoConsumptionUseCase {}

class _UpdateStock extends Mock implements UpdateProductStockUseCase {}

class _GetProduct extends Mock implements GetProductByIdUseCase {}

class _DeleteProduct extends Mock implements DeleteProductUseCase {}

class _ServerProduct extends Mock implements ProductModel {
  @override
  double get stock => 15;
}

class _ProductRemote extends Mock implements ProductRemoteDataSource {
  @override
  Future<ProductModel> getProductById(String id) async => _ServerProduct();
}
