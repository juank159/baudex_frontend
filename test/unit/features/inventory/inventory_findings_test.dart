import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_local_datasource_isar.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:baudex_desktop/features/inventory/data/models/inventory_movement_model.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/data/repositories/inventory_offline_repository.dart';
import 'package:baudex_desktop/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../../helpers/test_isar.dart';

/// AUDITORÍA del módulo de Inventario (2026-11-26). Cada prueba describe lo
/// que DEBERÍA pasar; las que fallan hoy demuestran una falla real.
/// Datos: tal como los manda el servidor (entidades de
/// backend/src/inventory/entities y sync-entities.ts).

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
    ops.add({'entityType': entityType, ...data});
  }
}

class _Net implements NetworkInfo {
  _Net(this.online);
  final bool online;
  @override
  Future<bool> get isConnected async => online;
  @override
  void markServerUnreachable() {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Servidor simulado: aplica el ajuste relativo y devuelve el movimiento.
class _Remote implements InventoryRemoteDataSource {
  final calls = <Map<String, dynamic>>[];
  @override
  Future<InventoryMovementModel> createStockAdjustment(
      Map<String, dynamic> request) async {
    calls.add(request);
    return InventoryMovementModel.fromJson(serverMovement(
      id: 'mov-${calls.length}',
      type: 'adjustment',
      quantity: request['adjustmentQuantity'] as int,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _LocalCache implements InventoryLocalDataSource {
  @override
  Future<void> clearBalancesCache() async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Movimiento tal como lo entrega el servidor (sync-entities.ts serialize).
Map<String, dynamic> serverMovement({
  required String id,
  required String type,
  required num quantity,
  String date = '2026-11-20T10:00:00.000Z',
  String warehouseId = 'A',
}) =>
    {
      'id': id,
      'movementNumber': 'MOV-$id',
      'type': type,
      'status': 'confirmed',
      'movementDate': date,
      'quantity': quantity,
      'unitCost': 1000,
      'totalCost': quantity.abs() * 1000,
      'unitPrice': null,
      'totalPrice': null,
      'stockAfter': 0,
      'stockValueAfter': 0,
      'referenceType': type,
      'notes': null,
      'metadata': {'reason': 'x'},
      'organizationId': 'org',
      'productId': 'p1',
      'performedById': 'u1',
      'warehouseId': warehouseId,
      'createdAt': date,
      'updatedAt': date,
      'productName': 'Producto 1',
      'productSku': 'P1',
      'product': null,
      'performedBy': null,
    };

void main() {
  late Isar isar;
  late InventoryOfflineRepository offline;
  late _FakeSync sync;

  IsarInventoryBatch batch(String id, int qty, String? wh) =>
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
        warehouseId: wh,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
        isSynced: true,
      );

  Future<void> putProduct(double stock) => isar.writeTxn(() =>
      isar.isarProducts.put(IsarProduct.create(
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
      )));

  Future<int> balance({String? wh}) async =>
      (await offline.getBalanceByProduct('p1', warehouseId: wh))
          .getOrElse(() => throw 'sin saldo')
          .totalQuantity;

  setUp(() async {
    isar = await openTestIsar();
    Get.testMode = true;
    sync = _FakeSync();
    Get.put<SyncService>(sync);
    offline = InventoryOfflineRepository(database: TestIsarDatabase(isar));
    Get.put<InventoryOfflineRepository>(offline);
  });

  tearDown(() async {
    Get.reset();
    await closeTestIsar(isar);
  });

  test('F1 ajuste CON internet: el equipo debe mostrar el stock nuevo y no '
      'permitir repetir el mismo ajuste', () async {
    await putProduct(20);
    await isar.writeTxn(() => isar.isarInventoryBatchs.put(batch('L1', 20, 'A')));
    final remote = _Remote();
    final repo = InventoryRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: _LocalCache(),
      networkInfo: _Net(true),
    );

    // Pantalla: stock actual 20, el usuario escribe 15 → diferencia -5.
    var actual = await balance(wh: 'A');
    expect((await repo.createStockAdjustment({
      'productId': 'p1',
      'adjustmentQuantity': 15 - actual,
      'warehouseId': 'A',
      'unitCost': 0.0,
    }))
        .isRight(), isTrue);

    // Vuelve a abrir el ajuste antes de la próxima descarga.
    actual = await balance(wh: 'A');
    final segunda = 15 - actual;
    expect(actual, 15,
        reason: 'tras el ajuste con internet el equipo sigue en 20 hasta la '
            'próxima descarga; escribir 15 otra vez manda otro -5');
    expect(segunda, 0);
  });

  test('F2 ajuste MASIVO sin internet: lo que queda en cola debe ser '
      'aceptado por /inventory/adjustments/relative', () async {
    await putProduct(20);
    await isar.writeTxn(() => isar.isarInventoryBatchs.put(batch('L1', 20, 'A')));
    final r = await offline.createBulkStockAdjustments([
      const CreateStockAdjustmentParams(
        productId: 'p1',
        adjustmentQuantity: -3,
        reason: InventoryMovementReason.adjustment,
        warehouseId: 'A',
      ),
    ], idempotencyKeys: ['k1']);
    expect(r.isRight(), isTrue);

    // Campos de RelativeInventoryAdjustmentDto (whitelist +
    // forbidNonWhitelisted en main.ts: cualquier otro campo = 400).
    const allowed = {
      'productId', 'adjustmentQuantity', 'warehouseId', 'notes',
      'movementDate', 'unitCost', 'idempotencyKey',
    };
    final sent = Map.of(sync.ops.single)..remove('entityType');
    expect(sent.keys.toSet().difference(allowed), isEmpty,
        reason: 'el servidor responde 400 "property reason should not exist" '
            'y la app descarta el ajuste al sincronizar');
  });

  test('F3 ajuste negativo sin internet con stock en 2 almacenes: no debe '
      'aceptar más de lo que hay en el almacén elegido', () async {
    await putProduct(20);
    await isar.writeTxn(() => isar.isarInventoryBatchs
        .putAll([batch('LA', 5, 'A'), batch('LB', 15, 'B')]));

    final r = await offline.createStockAdjustment({
      'productId': 'p1',
      'adjustmentQuantity': -10,
      'warehouseId': 'A',
      'unitCost': 0.0,
    });
    final product =
        await isar.isarProducts.filter().serverIdEqualTo('p1').findFirst();
    final lotes = (await isar.isarInventoryBatchs.where().findAll())
        .fold<int>(0, (s, b) => s + b.currentQuantity);
    expect(product!.stock, lotes,
        reason: 'stock del producto (${product.stock}) distinto de la suma '
            'de lotes ($lotes)');
    expect(r.isLeft(), isTrue,
        reason: 'el servidor lo rechaza: "Stock insuficiente en almacén A"');
  });

  test('F4 producto recién creado con stock (lote aún no descargado): el '
      'ajuste no debe partir de 0', () async {
    await putProduct(20); // el servidor ya creó su lote; no ha llegado
    expect(await balance(wh: 'A'), 20,
        reason: 'Stock Total 0 → cualquier cantidad se toma como aumento');
  });

  test('F5 movimientos del servidor: el ajuste que disminuye y el stock '
      'inicial conservan su sentido', () async {
    final dec = InventoryMovementModel.fromJson(
            serverMovement(id: 'm1', type: 'adjustment', quantity: -5))
        .toEntity();
    final ini = InventoryMovementModel.fromJson(
            serverMovement(id: 'm2', type: 'initial_stock', quantity: 20))
        .toEntity();
    expect(ini.type, isNot(InventoryMovementType.adjustment),
        reason: 'initial_stock se lee como "ajuste"');
    expect(dec.displayQuantity, '-5',
        reason: 'una disminución de 5 se muestra como "+5"');
  });

  test('F6 Kardex SIN internet: stock inicial 20, ajuste -5, traslado '
      'entrante 3 → saldo 18', () async {
    final rows = syncInventoryMovementRows([
      serverMovement(id: 'm1', type: 'initial_stock', quantity: 20,
          date: '2026-11-01T10:00:00.000Z'),
      serverMovement(id: 'm2', type: 'adjustment', quantity: -5,
          date: '2026-11-02T10:00:00.000Z'),
      serverMovement(id: 'm3', type: 'transfer_in', quantity: 3,
          date: '2026-11-03T10:00:00.000Z'),
    ]).cast<IsarInventoryMovement>();
    await isar.writeTxn(() => isar.isarInventoryMovements.putAll(rows));
    final repo = InventoryRepositoryImpl(
      remoteDataSource: _Remote(),
      localDataSource: InventoryLocalDataSourceIsar(TestIsarDatabase(isar)),
      networkInfo: _Net(false),
    );
    final k = (await repo.getKardexReport(KardexReportParams(
      productId: 'p1',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 12, 1),
    )))
        .getOrElse(() => throw 'sin kardex');
    expect(k.movements.length, 3);
    expect(k.finalBalance.quantity, 18,
        reason: 'el Kardex del equipo toma todo lo que no es "compra" como '
            'salida: da ${k.finalBalance.quantity}');
  });
}
