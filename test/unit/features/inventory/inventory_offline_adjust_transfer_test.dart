import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch_movement.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/data/repositories/inventory_offline_repository.dart';
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

/// Ajustes y traslados de inventario SIN internet: mismas reglas que el
/// servidor y siempre encolados con su clave (el servidor no los repite).
class _FakeSync extends SyncService {
  _FakeSync() : super(null);
  final ops = <Map<String, dynamic>>[];
  bool fail = false;

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
    if (fail) throw Exception('cola no disponible');
    ops.add({'entityType': entityType, 'entityId': entityId, ...data});
  }
}

class _Db implements IsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Isar isar;
  late InventoryOfflineRepository repo;
  late _FakeSync sync;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  IsarInventoryBatch batch(String id, int qty, double cost, String wh, DateTime entry) =>
      IsarInventoryBatch.create(
        serverId: id,
        productId: 'arroz',
        productName: 'Arroz',
        productSku: 'SKU-arroz',
        batchNumber: id,
        originalQuantity: qty,
        currentQuantity: qty,
        consumedQuantity: 0,
        unitCost: cost,
        totalCost: qty * cost,
        entryDate: entry,
        status: IsarInventoryBatchStatus.active,
        warehouseId: wh,
        createdAt: entry,
        updatedAt: entry,
        isSynced: true,
      );

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_inv_adjust');
    isar = await Isar.open([
      IsarProductSchema,
      IsarInventoryBatchSchema,
      IsarInventoryMovementSchema,
      IsarInventoryBatchMovementSchema,
    ], directory: dir.path);
    IsarDatabase.debugSetDatabase(isar);
    Get.testMode = true;
    sync = _FakeSync();
    Get.put<SyncService>(sync);
    repo = InventoryOfflineRepository(database: _Db(isar));

    await isar.writeTxn(() async {
      await isar.isarProducts.put(IsarProduct.create(
        serverId: 'arroz', name: 'Arroz', sku: 'SKU-arroz', type: IsarProductType.product,
        status: IsarProductStatus.active, stock: 15, minStock: 0, categoryId: 'c',
        createdAt: DateTime(2026), updatedAt: DateTime(2026), isSynced: true,
        taxCategory: IsarTaxCategory.noGravado, taxRate: 0, isTaxable: false,
        hasRetention: false));
      await isar.isarInventoryBatchs.putAll([
        batch('viejo', 5, 100, 'principal', DateTime(2026, 1, 1)),
        batch('nuevo', 10, 120, 'principal', DateTime(2026, 2, 1)),
      ]);
    });
  });

  tearDown(() async {
    Get.reset();
    await isar.close(deleteFromDisk: true);
    IsarDatabase.debugSetDatabase(null);
  });

  Future<double> stock() async =>
      (await isar.isarProducts.filter().serverIdEqualTo('arroz').findFirst())!.stock;
  Future<int> qtyOf(String id) async =>
      (await isar.isarInventoryBatchs.filter().serverIdEqualTo(id).findFirst())!.currentQuantity;

  test('ajuste negativo: lotes del más antiguo al más nuevo y en cola con clave', () async {
    final result = await repo.createStockAdjustment({
      'productId': 'arroz', 'adjustmentQuantity': -7, 'warehouseId': 'principal',
      'notes': 'Conteo físico', 'unitCost': 0.0,
    });

    expect(result.isRight(), isTrue);
    expect(await stock(), 8);
    expect(await qtyOf('viejo'), 0);
    expect(await qtyOf('nuevo'), 8);
    expect(sync.ops.single['entityType'], 'InventoryAdjustment');
    expect(sync.ops.single['idempotencyKey'], startsWith('adjustment_offline_'));
  });

  test('no deja el stock en negativo', () async {
    final result = await repo.createStockAdjustment({
      'productId': 'arroz', 'adjustmentQuantity': -20, 'unitCost': 0.0,
    });
    expect(result.isLeft(), isTrue);
    expect(await stock(), 15);
    expect(sync.ops, isEmpty);
  });

  test('entrada: sin costo se rechaza; con costo entra como lote nuevo', () async {
    final sinCosto = await repo.createStockAdjustment({
      'productId': 'arroz', 'adjustmentQuantity': 4, 'unitCost': 0.0,
    });
    expect(sinCosto.isLeft(), isTrue);

    final conCosto = await repo.createStockAdjustment({
      'productId': 'arroz', 'adjustmentQuantity': 4, 'unitCost': 130.0,
      'warehouseId': 'principal', 'idempotencyKey': 'clave-del-intento-online',
    });
    expect(conCosto.isRight(), isTrue);
    expect(await stock(), 19);
    final nuevos = await isar.isarInventoryBatchs
        .filter()
        .serverIdStartsWith('batch_offline_')
        .findAll();
    expect(nuevos.single.currentQuantity, 4);
    expect(sync.ops.single['idempotencyKey'], 'clave-del-intento-online');
  });

  test('traslado: sale del origen, entra al destino y el total no cambia', () async {
    final result = await repo.createTransfer(const CreateInventoryTransferParams(
      items: [TransferItem(productId: 'arroz', quantity: 6)],
      fromWarehouseId: 'principal',
      toWarehouseId: 'bodega2',
    ));

    expect(result.isRight(), isTrue);
    expect(await stock(), 15);
    expect(await qtyOf('viejo'), 0);
    expect(await qtyOf('nuevo'), 9);
    final destino = await isar.isarInventoryBatchs
        .filter()
        .warehouseIdEqualTo('bodega2')
        .findAll();
    expect(destino.single.currentQuantity, 6);
    expect(sync.ops.single['entityType'], 'InventoryTransfer');
  });

  test('traslado con más de lo que hay en el origen no mueve nada', () async {
    final result = await repo.createTransfer(const CreateInventoryTransferParams(
      items: [TransferItem(productId: 'arroz', quantity: 99)],
      fromWarehouseId: 'principal',
      toWarehouseId: 'bodega2',
    ));
    expect(result.isLeft(), isTrue);
    expect(await qtyOf('nuevo'), 10);
    expect(sync.ops, isEmpty);
  });

  test('si no se puede encolar no se aplica nada', () async {
    sync.fail = true;
    final result = await repo.createStockAdjustment({
      'productId': 'arroz', 'adjustmentQuantity': -3, 'unitCost': 0.0,
    });
    expect(result.isLeft(), isTrue);
    expect(await stock(), 15);
  });
}
