import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/data/repositories/inventory_offline_repository.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

/// Simulación del caso del negocio: se crea un producto con 20 unidades (el
/// servidor crea su lote en el Almacén Principal), el equipo descarga ese
/// lote y se abre "Ajuste de Stock" con el Almacén Principal elegido.
///
/// El lote llega TAL COMO lo manda el servidor (campo `warehouseId`). La app
/// lo buscaba como `warehouse_id`: el lote quedaba en el equipo sin almacén,
/// el saldo del almacén daba 0 y cualquier cantidad escrita se tomaba como
/// aumento.
void main() {
  late Isar isar;
  late InventoryOfflineRepository repo;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_ajuste');
    isar = await Isar.open(
      [IsarProductSchema, IsarInventoryBatchSchema, IsarInventoryMovementSchema],
      directory: dir.path,
    );
    repo = InventoryOfflineRepository(database: _FakeDb(isar));
  });
  tearDown(() => isar.close(deleteFromDisk: true));

  /// Lote como lo entrega el servidor (entidad tal cual + producto).
  Map<String, dynamic> serverBatch({required int quantity}) => {
        'id': 'lote-1',
        'productId': 'bianchi',
        'batchNumber': 'BATCH-202611-000001',
        'originalQuantity': quantity,
        'currentQuantity': quantity,
        'unitCost': '1500.00',
        'purchaseDate': '2026-11-20T10:00:00.000Z',
        'expirationDate': null,
        'warehouseId': 'almacen-principal',
        'status': 'active',
        'createdAt': '2026-11-20T10:00:00.000Z',
        'updatedAt': '2026-11-20T10:00:00.000Z',
        'product': {'id': 'bianchi', 'name': 'BIANCHI FRESA', 'sku': 'BF-1'},
      };

  test('producto con 20 unidades: el ajuste ve 20 en el Almacén Principal, '
      'y escribir 15 es una DISMINUCIÓN de 5', () async {
    final rows = syncInventoryBatchRows([serverBatch(quantity: 20)])
        .cast<IsarInventoryBatch>();
    await isar.writeTxn(() async {
      await isar.isarProducts.put(IsarProduct.create(
        serverId: 'bianchi',
        name: 'BIANCHI FRESA',
        sku: 'BF-1',
        type: IsarProductType.product,
        status: IsarProductStatus.active,
        stock: 20,
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
      await isar.isarInventoryBatchs.putAll(rows);
    });

    expect(rows.single.warehouseId, 'almacen-principal',
        reason: 'el lote descargado conserva su almacén');

    final balance = (await repo.getBalanceByProduct('bianchi',
            warehouseId: 'almacen-principal'))
        .getOrElse(() => throw 'falló');
    expect(balance.totalQuantity, 20,
        reason: 'Stock Total que muestra la pantalla de ajuste');

    // Lo que hace la pantalla: diferencia = cantidad final − stock actual.
    const cantidadFinal = 15;
    expect(cantidadFinal - balance.totalQuantity, -5,
        reason: 'debe disminuir 5, no aumentar 15');
  });
}

class _FakeDb implements IsarDatabase {
  _FakeDb(this.database);
  @override
  final Isar database;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
