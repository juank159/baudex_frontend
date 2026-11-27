// "Abro Ajuste de Stock recién actualizada la app, elijo un producto y dice
// 0 unidades": los lotes guardados por versiones anteriores a la 1.0.14 no
// tienen almacén y solo se reparan cuando termina la re-descarga en segundo
// plano. Mientras tanto la pantalla leía del equipo y afirmaba 0.
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/local_first.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:baudex_desktop/features/inventory/data/models/inventory_balance_model.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/inventory/data/models/warehouse_model.dart';
import 'package:baudex_desktop/features/inventory/data/repositories/inventory_offline_repository.dart';
import 'package:baudex_desktop/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_balance.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/warehouse.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_bulk_stock_adjustments_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_stock_adjustment_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_balance_for_stock_action_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_inventory_balance_by_product_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouses_usecase.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_adjustments_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_bulk_adjustments_controller.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/usecases/search_products_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_isar.dart';

class _Net implements NetworkInfo {
  _Net(this.online);
  bool online;
  @override
  Future<bool> get isConnected async => online;
  @override
  void markServerUnreachable() {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// La descarga completa ya terminó: las pantallas leen del equipo.
class _SyncDone extends GetxService implements FullSyncService {
  @override
  Future<bool> isModuleDownloaded(String entity) async => true;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Servidor simulado: saldo por almacén y lotes del producto.
class _Remote implements InventoryRemoteDataSource {
  int balanceCalls = 0;
  int quantity = 20;
  Duration delay = Duration.zero;
  bool fails = false;
  List<Map<String, dynamic>> batches = [];

  @override
  Future<InventoryBalanceModel> getBalanceByProduct(
    String productId, {
    String? warehouseId,
  }) async {
    balanceCalls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (fails) throw const ConnectionException('sin conexión');
    return InventoryBalanceModel(
      productId: productId,
      productName: 'Producto 1',
      productSku: 'P1',
      categoryName: 'c',
      totalQuantity: quantity,
      minStock: 0,
      averageCost: 1000,
      totalValue: quantity * 1000.0,
      isLowStock: false,
      isOutOfStock: quantity == 0,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getBatches({
    String? productId,
    String? warehouseId,
    String? status,
    String? search,
    bool? activeOnly,
    bool? expiredOnly,
    bool? nearExpiryOnly,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (fails) throw const ConnectionException('sin conexión');
    return batches;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _LocalCache implements InventoryLocalDataSource {
  List<String> warehouseIds = ['w1'];
  @override
  Future<void> cacheBalance(InventoryBalanceModel balance) async {}
  @override
  Future<List<WarehouseModel>> getCachedWarehouses() async => [
        for (final id in warehouseIds)
          WarehouseModel(id: id, name: id, code: id, isActive: true),
      ];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Create extends Mock implements CreateStockAdjustmentUseCase {}

class _Bulk extends Mock implements CreateBulkStockAdjustmentsUseCase {}

class _Search extends Mock implements SearchProductsUseCase {}

class _Warehouses extends Mock implements GetWarehousesUseCase {}

Warehouse _warehouse(String id) =>
    Warehouse(id: id, name: id, code: id, isActive: true);

final _product = Product(
  id: 'p1',
  name: 'Producto 1',
  sku: 'P1',
  type: ProductType.product,
  status: ProductStatus.active,
  stock: 20,
  minStock: 0,
  unit: 'und',
  categoryId: 'c',
  createdById: 'u1',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// Lote tal como lo manda el servidor (GET /inventory/batches).
Map<String, dynamic> _serverBatch(String id, int qty, String warehouse) => {
      'id': id,
      'productId': 'p1',
      'batchNumber': id,
      'originalQuantity': 20,
      'currentQuantity': qty,
      'unitCost': 1000,
      'purchaseDate': '2026-11-01T10:00:00.000Z',
      'warehouseId': warehouse,
      'status': qty == 0 ? 'depleted' : 'active',
      'createdAt': '2026-11-01T10:00:00.000Z',
      'updatedAt': '2026-11-20T10:00:00.000Z',
      'product': {'name': 'Producto 1', 'sku': 'P1'},
    };

void main() {
  late Isar isar;
  late InventoryOfflineRepository offline;
  late _Remote remote;
  late _Net net;
  late _LocalCache cache;
  late InventoryRepositoryImpl repository;

  /// Lote como lo dejaron las versiones ≤ 1.0.13: sin almacén.
  IsarInventoryBatch batch(String id, int qty, String? warehouse) =>
      IsarInventoryBatch.create(
        serverId: id,
        productId: 'p1',
        productName: 'Producto 1',
        productSku: 'P1',
        batchNumber: id,
        originalQuantity: qty,
        currentQuantity: qty,
        consumedQuantity: 0,
        unitCost: 1000,
        totalCost: qty * 1000,
        entryDate: DateTime(2026, 11, 1),
        status: IsarInventoryBatchStatus.active,
        warehouseId: warehouse,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
        isSynced: true,
      );

  Future<void> seed(List<IsarInventoryBatch> batches, {double stock = 20}) =>
      isar.writeTxn(() async {
        await isar.isarProducts.put(IsarProduct.create(
          serverId: 'p1',
          name: 'Producto 1',
          sku: 'P1',
          type: IsarProductType.product,
          status: IsarProductStatus.active,
          stock: stock,
          minStock: 0,
          categoryId: 'c',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          isSynced: true,
          taxCategory: IsarTaxCategory.noGravado,
          taxRate: 0,
          isTaxable: false,
          hasRetention: false,
        ));
        await isar.isarInventoryBatchs.putAll(batches);
      });

  setUp(() async {
    isar = await openTestIsar();
    Get.testMode = true;
    resetLocalCollectionsReady();
    Get.put<FullSyncService>(_SyncDone());
    offline = InventoryOfflineRepository(database: TestIsarDatabase(isar));
    Get.put<InventoryOfflineRepository>(offline);
    remote = _Remote();
    net = _Net(true);
    cache = _LocalCache();
    repository = InventoryRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: cache,
      networkInfo: net,
    );
  });
  tearDown(() async {
    Get.reset();
    resetLocalCollectionsReady();
    InventoryRepositoryImpl.debugResetStockActionPause();
    InventoryRepositoryImpl.stockActionServerWait = const Duration(seconds: 4);
    await closeTestIsar(isar);
  });

  test('CAUSA: con lotes sin almacén, la lectura de siempre afirma 0 sin '
      'consultar al servidor (que tiene 20)', () async {
    await seed([batch('L1', 20, null)]);

    final balance = (await GetInventoryBalanceByProductUseCase(repository)(
      'p1',
      warehouseId: 'w1',
    ))
        .getOrElse(() => throw 'sin saldo');

    expect(balance.totalQuantity, 0, reason: 'el 0 falso que vio el dueño');
    expect(balance.isStockUnconfirmed, isFalse,
        reason: 'y lo afirma como cierto: la pantalla deja ajustar sobre 0');
    expect(remote.balanceCalls, 0, reason: 'nunca le pregunta al servidor');
  });

  Future<InventoryBalance> forAdjustment({String warehouse = 'w1'}) async =>
      (await GetBalanceForStockActionUseCase(repository)(
        'p1',
        warehouseId: warehouse,
      ))
          .getOrElse(() => throw 'sin saldo');

  Future<int> localUnits() async =>
      (await isar.isarInventoryBatchs.where().findAll())
          .fold<int>(0, (sum, b) => sum + b.currentQuantity);

  group('saldo para ajustar (repositorio)', () {
    test('(a) lotes sin almacén + servidor dice 20 → 20 confirmado, y el '
        'equipo queda reparado sin contar doble', () async {
      await seed([batch('L1', 20, null)]);
      remote.batches = [_serverBatch('L1', 20, 'w1')];

      final balance = await forAdjustment();

      expect(balance.totalQuantity, 20);
      expect(balance.isStockUnconfirmed, isFalse);
      expect(balance.warehouseId, 'w1');
      expect(remote.balanceCalls, 1);
      final l1 = await isar.isarInventoryBatchs.getByServerId('L1');
      expect(l1!.warehouseId, 'w1', reason: 'el lote ya tiene su almacén');
      expect(l1.isSynced, isTrue);
      expect(await localUnits(), 20, reason: 'sin doble conteo');
      // La lectura de siempre (otras pantallas) ya da 20 también.
      final usual = (await repository.getBalanceByProduct('p1',
              warehouseId: 'w1'))
          .getOrElse(() => throw 'sin saldo');
      expect(usual.totalQuantity, 20);
    });

    test('(b) sin internet, lotes sin almacén y UN solo almacén → 20 '
        'confirmado', () async {
      await seed([batch('L1', 20, null)]);
      net.online = false;

      final balance = await forAdjustment();

      expect(balance.totalQuantity, 20);
      expect(balance.isStockUnconfirmed, isFalse);
      expect(remote.balanceCalls, 0);
    });

    test('(b) sin internet, lotes sin almacén y DOS almacenes → sin '
        'confirmar (no afirma 0)', () async {
      await seed([batch('L1', 20, null)]);
      net.online = false;
      cache.warehouseIds = ['w1', 'w2'];

      final balance = await forAdjustment();

      expect(balance.isStockUnconfirmed, isTrue);
    });

    test('sin internet y no se sabe cuántos almacenes hay → sin confirmar',
        () async {
      await seed([batch('L1', 20, null)]);
      net.online = false;
      cache.warehouseIds = [];

      expect((await forAdjustment()).isStockUnconfirmed, isTrue);
    });

    test('sin internet con lotes sanos: la cifra del almacén, confirmada '
        '(lo que ya funcionaba)', () async {
      await seed([batch('L1', 12, 'w1'), batch('L2', 8, 'w2')]);
      net.online = false;
      cache.warehouseIds = ['w1', 'w2'];

      final w1 = await forAdjustment();
      expect(w1.totalQuantity, 12);
      expect(w1.isStockUnconfirmed, isFalse);
      final w3 = await forAdjustment(warehouse: 'w3');
      expect(w3.totalQuantity, 0, reason: '0 real: todo está en otros');
      expect(w3.isStockUnconfirmed, isFalse);
    });

    test('sin internet y el producto dice tener más que sus lotes (faltan '
        'lotes por bajar) → sin confirmar', () async {
      await seed([batch('L1', 5, 'w1')], stock: 20);
      net.online = false;

      expect((await forAdjustment()).isStockUnconfirmed, isTrue);
    });

    test('(c) el servidor no responde a tiempo → lo del equipo, sin '
        'afirmar 0', () async {
      await seed([batch('L1', 20, null)]);
      cache.warehouseIds = ['w1', 'w2'];
      InventoryRepositoryImpl.stockActionServerWait =
          const Duration(milliseconds: 40);
      remote.delay = const Duration(milliseconds: 300);

      final sw = Stopwatch()..start();
      final balance = await forAdjustment();

      expect(sw.elapsedMilliseconds, lessThan(250), reason: 'tope de espera');
      expect(balance.isStockUnconfirmed, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 350));
    });

    test('el servidor falla → lo del equipo', () async {
      await seed([batch('L1', 20, 'w1')]);
      remote.fails = true;

      final balance = await forAdjustment();
      expect(balance.totalQuantity, 20);
      expect(balance.isStockUnconfirmed, isFalse);
    });

    test('(d) el servidor dice 0 real → 0 confirmado, con el nombre del '
        'producto', () async {
      await seed([batch('L1', 20, null)]);
      remote.quantity = 0;
      remote.batches = [_serverBatch('L1', 20, 'w2')];

      final balance = await forAdjustment();

      expect(balance.totalQuantity, 0);
      expect(balance.isOutOfStock, isTrue);
      expect(balance.isStockUnconfirmed, isFalse);
      expect(balance.productName, 'Producto 1');
    });

    test('cambios del equipo sin subir: gana el equipo y no se pisan sus '
        'lotes', () async {
      final pending = batch('L1', 25, 'w1')..isSynced = false;
      await seed([pending], stock: 25);
      remote.quantity = 20; // el servidor aún no conoce el +5
      remote.batches = [_serverBatch('L1', 20, 'w1')];

      final balance = await forAdjustment();

      expect(balance.totalQuantity, 25);
      expect(remote.balanceCalls, 0);
      expect(await localUnits(), 25);
    });
  });

  group('saldo de origen en traslados', () {
    Future<InventoryBalance> forTransfer() async =>
        (await GetBalanceForStockActionUseCase(repository, forTransfer: true)(
          'p1',
          warehouseId: 'w1',
        ))
            .getOrElse(() => throw 'sin saldo');

    setUp(() => cache.warehouseIds = ['w1', 'w2']);

    test('equipo sano: no se consulta al servidor (igual que antes)',
        () async {
      await seed([batch('L1', 12, 'w1'), batch('L2', 8, 'w2')]);
      expect((await forTransfer()).availableQuantity, 12);
      expect(remote.balanceCalls, 0);
    });

    test('lotes sin almacén con internet: se confirma con el servidor (20) '
        'en vez de decir 0', () async {
      await seed([batch('L1', 20, null)]);
      remote.batches = [_serverBatch('L1', 20, 'w1')];
      expect((await forTransfer()).availableQuantity, 20);
    });

    test('lotes sin almacén sin internet: la cifra de siempre, nunca más de '
        'lo que el equipo puede trasladar', () async {
      await seed([batch('L1', 20, null)]);
      net.online = false;
      final balance = await forTransfer();
      expect(balance.availableQuantity, 0);
    });

    test('si el servidor falló, las siguientes lecturas no insisten',
        () async {
      await seed([batch('L1', 20, null)]);
      remote.fails = true;
      await forTransfer();
      await forTransfer();
      await forTransfer();
      expect(remote.balanceCalls, 1);
    });
  });

  group('pantallas', () {
    late _Warehouses warehouses;

    setUp(() {
      warehouses = _Warehouses();
      when(() => warehouses()).thenAnswer(
        (_) async => Right([
          for (final id in cache.warehouseIds) _warehouse(id),
        ]),
      );
    });

    Future<InventoryAdjustmentsController> adjustments() async {
      final c = Get.put(
        InventoryAdjustmentsController(
          createStockAdjustmentUseCase: _Create(),
          getInventoryBalanceByProductUseCase:
              GetBalanceForStockActionUseCase(repository),
          searchProductsUseCase: _Search(),
          getWarehousesUseCase: warehouses,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      if (c.selectedWarehouseId.value.isEmpty) {
        c.setSelectedWarehouse('w1', 'w1');
      }
      return c;
    }

    test('(a)(c) Ajuste de Stock: al elegir el producto muestra "cargando" '
        'y luego 20; nunca pasa por un 0 afirmado', () async {
      await seed([batch('L1', 20, null)]);
      remote.batches = [_serverBatch('L1', 20, 'w1')];
      remote.delay = const Duration(milliseconds: 80); // servidor lento
      final c = await adjustments();
      final seen = <int?>[];
      final watch = ever<InventoryBalance?>(
          c.currentBalance, (b) => seen.add(b?.totalQuantity));

      final selecting = c.selectProduct(_product);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.isLoadingBalance.value, isTrue);
      expect(c.canAdjust, isFalse, reason: 'botón apagado mientras se lee');
      expect(c.blockingReason, contains('leyendo'));
      await selecting;

      expect(c.isLoadingBalance.value, isFalse);
      expect(c.currentStock.value, 20);
      expect(c.canAdjust, isTrue);
      expect(seen.where((q) => q != null), [20],
          reason: 'la pantalla nunca recibió un saldo de 0');
      watch.dispose();
    });

    test('(b) Ajuste de Stock sin internet, dos almacenes y lotes sin '
        'almacén → sin confirmar y botón apagado', () async {
      cache.warehouseIds = ['w1', 'w2'];
      await seed([batch('L1', 20, null)]);
      net.online = false;
      final c = await adjustments();

      await c.selectProduct(_product);

      expect(c.isStockUnconfirmed, isTrue);
      expect(c.canAdjust, isFalse);
      expect(c.blockingReason, kUnconfirmedStockMessage);
    });

    test('(b) Ajuste de Stock sin internet con un solo almacén → 20 y se '
        'puede ajustar', () async {
      await seed([batch('L1', 20, null)]);
      net.online = false;
      final c = await adjustments();

      await c.selectProduct(_product);

      expect(c.currentStock.value, 20);
      expect(c.canAdjust, isTrue);
    });

    test('(d) el servidor dice 0 real → muestra 0 y deja sumar', () async {
      await seed([batch('L1', 20, null)]);
      remote.quantity = 0;
      final c = await adjustments();

      await c.selectProduct(_product);
      c
        ..setMode(StockAdjustMode.add)
        ..setAmount(5);

      expect(c.currentStock.value, 0);
      expect(c.canAdjust, isTrue);
      expect(c.plan.error, isNull);
      expect(c.newQuantity.value, 5);
    });

    test('al cambiar de almacén se vuelve a preguntar; una respuesta vieja '
        'no pisa la nueva', () async {
      cache.warehouseIds = ['w1', 'w2'];
      await seed([batch('L1', 20, 'w1')]);
      final c = await adjustments();
      await c.selectProduct(_product);
      expect(c.currentStock.value, 20);

      remote.delay = const Duration(milliseconds: 120);
      c.setSelectedWarehouse('w2', 'w2'); // lectura lenta en curso (20)
      await Future<void>.delayed(const Duration(milliseconds: 10));
      remote
        ..delay = Duration.zero
        ..quantity = 7;
      c.setSelectedWarehouse('w1', 'w1');
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(remote.balanceCalls, 3);
      expect(c.selectedWarehouseId.value, 'w1');
      expect(c.currentStock.value, 7);
      expect(c.isLoadingBalance.value, isFalse);
    });

    test('(a)(b) Ajustes Masivos: la fila entra con 20; sin internet y dos '
        'almacenes entra sin confirmar', () async {
      await seed([batch('L1', 20, null)]);
      remote.batches = [_serverBatch('L1', 20, 'w1')];
      final c = Get.put(
        InventoryBulkAdjustmentsController(
          createBulkStockAdjustmentsUseCase: _Bulk(),
          getInventoryBalanceByProductUseCase:
              GetBalanceForStockActionUseCase(repository),
          searchProductsUseCase: _Search(),
          getWarehousesUseCase: warehouses,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      c.selectedWarehouseId.value = 'w1';

      // Dos toques seguidos: una sola fila.
      await Future.wait([
        c.addProductToAdjustment(_product),
        c.addProductToAdjustment(_product),
      ]);
      expect(c.adjustmentItems, hasLength(1));
      expect(c.adjustmentItems.single.currentQuantity, 20);
      expect(c.adjustmentItems.single.stockKnown, isTrue);

      // Otro equipo, aún sin reparar, sin internet y con dos almacenes.
      c.adjustmentItems.clear();
      await isar.writeTxn(() async {
        await isar.isarInventoryBatchs.clear();
        await isar.isarInventoryBatchs.put(batch('L1', 20, null));
      });
      cache.warehouseIds = ['w1', 'w2'];
      net.online = false;
      await c.addProductToAdjustment(_product);
      expect(c.adjustmentItems.single.stockUnconfirmed, isTrue);
      expect(c.adjustmentItems.single.stockKnown, isFalse);
    });
  });
}
