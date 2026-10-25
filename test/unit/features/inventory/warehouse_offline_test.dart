import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/inventory/data/models/warehouse_model.dart';
import 'package:baudex_desktop/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

/// Almacenes SIN internet: se crean, editan y eliminan en el equipo y se
/// encolan, con las mismas reglas del servidor.
class _FakeSync extends SyncService {
  _FakeSync() : super(null);
  final ops = <Map<String, dynamic>>[];

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
    ops.add({'entityType': entityType, 'entityId': entityId, 'op': operationType.name, ...data});
  }
}

class _Offline implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MemoryLocal implements InventoryLocalDataSource {
  List<WarehouseModel> warehouses = [];
  @override
  Future<void> cacheWarehouses(List<WarehouseModel> list) async => warehouses = list;
  @override
  Future<List<WarehouseModel>> getCachedWarehouses() async => warehouses;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoRemote implements InventoryRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late Isar isar;
  late InventoryRepositoryImpl repo;
  late _MemoryLocal local;
  late _FakeSync sync;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_wh');
    isar = await Isar.open([IsarInventoryBatchSchema], directory: dir.path);
    IsarDatabase.debugSetDatabase(isar);
    Get.testMode = true;
    sync = _FakeSync();
    Get.put<SyncService>(sync);
    local = _MemoryLocal()
      ..warehouses = [
        const WarehouseModel(id: 'main', name: 'Principal', code: 'PRI', isMainWarehouse: true),
        const WarehouseModel(id: 'bodega', name: 'Bodega', code: 'BOD'),
      ];
    repo = InventoryRepositoryImpl(
      remoteDataSource: _NoRemote(),
      localDataSource: local,
      networkInfo: _Offline(),
    );
    await isar.writeTxn(() => isar.isarInventoryBatchs.put(IsarInventoryBatch.create(
          serverId: 'lote', productId: 'p', productName: 'P', productSku: 'P',
          batchNumber: 'L1', originalQuantity: 3, currentQuantity: 3, consumedQuantity: 0,
          unitCost: 1, totalCost: 3, entryDate: DateTime(2026),
          status: IsarInventoryBatchStatus.active, warehouseId: 'bodega',
          createdAt: DateTime(2026), updatedAt: DateTime(2026), isSynced: true)));
  });

  tearDown(() async {
    Get.reset();
    await isar.close(deleteFromDisk: true);
    IsarDatabase.debugSetDatabase(null);
  });

  test('crear sin internet: queda en el equipo y en cola', () async {
    final result = await repo.createWarehouse(
        const CreateWarehouseParams(name: 'Sucursal', code: 'SUC'));

    expect(result.isRight(), isTrue);
    final created = result.getOrElse(() => throw 'sin almacén');
    expect(created.id, startsWith('warehouse_offline_'));
    final listed = (await repo.getWarehouses()).getOrElse(() => []);
    expect(listed.map((w) => w.code), contains('SUC'));
    expect(sync.ops.single['op'], 'create');
  });

  test('código repetido se rechaza', () async {
    final result = await repo.createWarehouse(
        const CreateWarehouseParams(name: 'Otra', code: 'bod'));
    expect(result.isLeft(), isTrue);
    expect(sync.ops, isEmpty);
  });

  test('no se elimina el principal ni uno con unidades; uno vacío sí', () async {
    expect((await repo.deleteWarehouse('main')).isLeft(), isTrue);
    final conUnidades = await repo.deleteWarehouse('bodega');
    expect(conUnidades.isLeft(), isTrue);
    conUnidades.fold((f) => expect(f.message, contains('3 unidades')), (_) {});

    final nuevo = (await repo.createWarehouse(
            const CreateWarehouseParams(name: 'Vacío', code: 'VAC')))
        .getOrElse(() => throw 'sin almacén');
    final borrado = await repo.deleteWarehouse(nuevo.id);
    expect(borrado.isRight(), isTrue);
    expect(sync.ops.last['op'], 'delete');
    expect(local.warehouses.any((w) => w.id == nuevo.id), isFalse);
  });
}
