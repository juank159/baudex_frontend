import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/features/inventory/data/inventory_adjustment_payload.dart';
import 'package:baudex_desktop/features/inventory/data/models/inventory_movement_model.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/inventory/data/repositories/inventory_offline_repository.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_movement.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../../helpers/test_isar.dart';

/// Casos de borde de los arreglos de Inventario (F1, F2, F4, F5): que el
/// ajuste hecho con internet no se cuente doble cuando llega la descarga,
/// que lo ya encolado se rescate y que el saldo "sin confirmar" se marque.
void main() {
  late Isar isar;
  late InventoryOfflineRepository offline;

  /// Lote tal como lo manda el servidor (GET /inventory/batches y descarga).
  Map<String, dynamic> serverBatch(String id, int qty, String wh,
          {int original = 20}) =>
      {
        'id': id,
        'productId': 'p1',
        'batchNumber': 'B-$id',
        'originalQuantity': original,
        'currentQuantity': qty,
        'unitCost': 1000,
        'purchaseDate': '2026-11-01T10:00:00.000Z',
        'warehouseId': wh,
        'status': qty == 0 ? 'depleted' : 'active',
        'createdAt': '2026-11-01T10:00:00.000Z',
        'updatedAt': '2026-11-20T10:00:00.000Z',
        'product': {'name': 'Producto 1', 'sku': 'P1'},
      };

  Future<void> download(List<Map<String, dynamic>> rows) => isar.writeTxn(() =>
      isar.isarInventoryBatchs.putAllByServerId(
          syncInventoryBatchRows(rows).cast<IsarInventoryBatch>()));

  Future<void> putProduct(double stock, {bool synced = true}) =>
      isar.writeTxn(() => isar.isarProducts.put(IsarProduct.create(
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
            isSynced: synced,
            taxCategory: IsarTaxCategory.noGravado,
            taxRate: 0,
            isTaxable: false,
            hasRetention: false,
          )));

  Future<int> lots() async => (await isar.isarInventoryBatchs.where().findAll())
      .fold<int>(0, (s, b) => s + b.currentQuantity);
  Future<double> stock() async =>
      (await isar.isarProducts.filter().serverIdEqualTo('p1').findFirst())!
          .stock;

  setUp(() async {
    isar = await openTestIsar();
    offline = InventoryOfflineRepository(database: TestIsarDatabase(isar));
  });
  tearDown(() => closeTestIsar(isar));

  test('F1 aumento con internet: entra el lote REAL del servidor y la '
      'descarga posterior no lo cuenta doble', () async {
    await putProduct(20);
    await download([serverBatch('L1', 20, 'A')]);
    final afterAdjust = [
      serverBatch('L1', 20, 'A'),
      serverBatch('L2', 5, 'A', original: 5),
    ];

    await offline.reflectServerAdjustments(
      'p1',
      [(quantity: 5, warehouseId: 'A')],
      serverBatches: afterAdjust,
      serverStock: 25,
    );
    expect(await lots(), 25);
    expect(await stock(), 25);
    final rows = await isar.isarInventoryBatchs.where().findAll();
    expect(rows.every((b) => b.isSynced), isTrue);
    expect(rows.any((b) => b.serverId.startsWith('batch_offline_')), isFalse);

    await download(afterAdjust); // llega la descarga incremental
    expect(await lots(), 25);
    expect(await isar.isarInventoryBatchs.count(), 2);
  });

  test('F1 disminución con internet sin poder leer los lotes: se descuenta '
      'en local sin dejar nada pendiente y la descarga lo deja igual',
      () async {
    await putProduct(20);
    await download([serverBatch('L1', 20, 'A')]);

    await offline.reflectServerAdjustments(
        'p1', [(quantity: -5, warehouseId: 'A')]);
    expect(await lots(), 15);
    expect(await stock(), 15);
    final l1 = await isar.isarInventoryBatchs.getByServerId('L1');
    expect(l1!.isSynced, isTrue,
        reason: 'un lote pendiente bloquearía la descarga de ese lote');

    await download([serverBatch('L1', 15, 'A')]);
    expect(await lots(), 15);
  });

  test('F1 con una venta sin subir sobre el lote: no se pisa el lote local '
      'con el del servidor', () async {
    await putProduct(18, synced: false);
    await download([serverBatch('L1', 20, 'A')]);
    final l1 = (await isar.isarInventoryBatchs.getByServerId('L1'))!
      ..consume(2, modifiedBy: 'venta_offline'); // venta sin subir
    await isar.writeTxn(() => isar.isarInventoryBatchs.put(l1));

    await offline.reflectServerAdjustments(
      'p1',
      [(quantity: -5, warehouseId: 'A')],
      serverBatches: [serverBatch('L1', 15, 'A')], // servidor aún sin la venta
      serverStock: 15,
    );
    expect(await lots(), 13, reason: '20 - 2 (venta local) - 5 (ajuste)');
    expect(await stock(), 13);
  });

  test('F2 lo ya encolado con campos de más se limpia al enviarlo', () {
    final sent = relativeAdjustmentPayload({
      'productId': 'p1',
      'adjustmentQuantity': -3,
      'reason': 'adjustment',
      'warehouseId': 'A',
      'notes': null,
      'movementDate': null,
      'unitCost': 0.0,
      'idempotencyKey': 'k1',
    });
    expect(sent, {
      'productId': 'p1',
      'adjustmentQuantity': -3,
      'warehouseId': 'A',
      'unitCost': 0.0,
      'idempotencyKey': 'k1',
    });
  });

  test('F4 el saldo sin lotes se marca "sin confirmar"; con lotes en otro '
      'almacén el 0 es real', () async {
    await putProduct(20);
    var b = (await offline.getBalanceByProduct('p1', warehouseId: 'A'))
        .getOrElse(() => throw 'sin saldo');
    expect(b.totalQuantity, 20);
    expect(b.isStockUnconfirmed, isTrue);
    expect(b.isOutOfStock, isFalse);
    final many = (await offline.getBalancesByProducts(['p1'], warehouseId: 'A'))
        .getOrElse(() => throw 'sin saldos');
    expect(many.single.isStockUnconfirmed, isTrue);
    expect(many.single.totalQuantity, 20);

    await download([serverBatch('LB', 20, 'B')]);
    b = (await offline.getBalanceByProduct('p1', warehouseId: 'A'))
        .getOrElse(() => throw 'sin saldo');
    expect(b.totalQuantity, 0);
    expect(b.isStockUnconfirmed, isFalse);
    b = (await offline.getBalanceByProduct('p1', warehouseId: 'B'))
        .getOrElse(() => throw 'sin saldo');
    expect(b.totalQuantity, 20);
    expect(b.isStockUnconfirmed, isFalse);
  });

  test('F5 sentido de cada tipo del servidor', () {
    InventoryMovement mov(String type, num quantity) =>
        InventoryMovementModel.fromJson({
          'id': 'm',
          'movementNumber': 'MOV',
          'type': type,
          'status': 'confirmed',
          'movementDate': '2026-11-20T10:00:00.000Z',
          'quantity': quantity,
          'unitCost': 1000,
          'totalCost': 1000,
          'organizationId': 'org',
          'productId': 'p1',
          'createdAt': '2026-11-20T10:00:00.000Z',
          'updatedAt': '2026-11-20T10:00:00.000Z',
        }).toEntity();

    expect(mov('sale', -4).displayQuantity, '-4');
    expect(mov('sale', -4).quantity, 4);
    expect(mov('purchase', 7).displayQuantity, '+7');
    expect(mov('adjustment', 5).displayQuantity, '+5');
    expect(mov('adjustment', -5).signedQuantity, -5);
    expect(mov('waste', -2).type, InventoryMovementType.outbound);
    expect(mov('waste', -2).displayQuantity, '-2');
    expect(mov('return_in', 1).type, InventoryMovementType.inbound);
    expect(mov('return_out', -1).signedQuantity, -1);
    expect(mov('transfer_out', 3).signedQuantity, -3);
    expect(mov('transfer_in', 3).signedQuantity, 3);
    expect(mov('initial_stock', 20).signedQuantity, 20);
  });
}
