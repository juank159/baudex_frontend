import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/data/repositories/inventory_offline_repository.dart';
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

/// Saldos de inventario desde el equipo: mismo resultado que antes, pero
/// calculado en una sola pasada (antes: una consulta por producto).
void main() {
  late Isar isar;
  late InventoryOfflineRepository repo;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  IsarProduct product(String id, String name, {double minStock = 0, String category = 'cat'}) =>
      IsarProduct.create(
        serverId: id,
        name: name,
        sku: 'SKU-$id',
        type: IsarProductType.product,
        status: IsarProductStatus.active,
        stock: 0,
        minStock: minStock,
        categoryId: category,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isSynced: true,
        taxCategory: IsarTaxCategory.noGravado,
        taxRate: 0,
        isTaxable: false,
        hasRetention: false,
      );

  IsarInventoryBatch batch(String id, String productId, int qty, double cost,
          {DateTime? expiry, DateTime? entry}) =>
      IsarInventoryBatch.create(
        serverId: id,
        productId: productId,
        productName: productId,
        productSku: productId,
        batchNumber: id,
        originalQuantity: qty,
        currentQuantity: qty,
        consumedQuantity: 0,
        unitCost: cost,
        totalCost: qty * cost,
        entryDate: entry ?? DateTime(2026, 1, 1),
        expiryDate: expiry,
        status: IsarInventoryBatchStatus.active,
        warehouseId: 'w1',
        createdAt: entry ?? DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        isSynced: true,
      );

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_inventory');
    isar = await Isar.open(
      [IsarProductSchema, IsarInventoryBatchSchema, IsarInventoryMovementSchema],
      directory: dir.path,
    );
    repo = InventoryOfflineRepository(database: _FakeDb(isar));
    await isar.writeTxn(() async {
      await isar.isarProducts.putAll([
        product('arroz', 'Arroz', minStock: 10, category: 'granos'),
        product('cafe', 'Café', minStock: 5, category: 'bebidas'),
        product('sal', 'Sal'),
        product('STATS_CACHE', 'stats'),
      ]);
      await isar.isarInventoryBatchs.putAll([
        batch('b1', 'arroz', 4, 2000),
        batch('b2', 'arroz', 3, 2200, entry: DateTime(2026, 2, 1)),
        batch('b3', 'cafe', 20, 5000),
        batch('b4', 'cafe', 0, 5000),
      ]);
    });
  });

  tearDown(() => isar.close(deleteFromDisk: true));

  test('página normal ordenada por nombre, con sus lotes, sin el registro interno', () async {
    final r = (await repo.getBalances(const InventoryBalanceQueryParams()))
        .getOrElse(() => throw 'falló');
    expect(r.data.map((b) => b.productId), ['arroz', 'cafe', 'sal']);
    expect(r.meta!.totalItems, 3);
    final arroz = r.data.first;
    expect(arroz.totalQuantity, 7);
    expect(arroz.totalValue, 4 * 2000 + 3 * 2200);
    expect(arroz.isLowStock, isTrue); // 7 <= 10
    expect(arroz.fifoLots.map((l) => l.lotNumber), ['b1', 'b2']); // FIFO
    expect(r.data[2].isOutOfStock, isTrue); // sal sin lotes
  });

  test('filtros por saldo y orden por cantidad', () async {
    final low = (await repo.getBalances(const InventoryBalanceQueryParams(lowStock: true)))
        .getOrElse(() => throw 'falló');
    expect(low.data.map((b) => b.productId), ['arroz']);
    final out = (await repo.getBalances(const InventoryBalanceQueryParams(outOfStock: true)))
        .getOrElse(() => throw 'falló');
    expect(out.data.map((b) => b.productId), ['sal']);
    final byQty = (await repo.getBalances(
            const InventoryBalanceQueryParams(sortBy: 'totalQuantity', sortOrder: 'desc')))
        .getOrElse(() => throw 'falló');
    expect(byQty.data.map((b) => b.productId), ['cafe', 'arroz', 'sal']);
  });

  test('saldos de varios productos en una pasada', () async {
    final r = (await repo.getBalancesByProducts(['cafe', 'arroz', 'no-existe']))
        .getOrElse(() => throw 'falló');
    expect(r.map((b) => '${b.productId}:${b.totalQuantity}'), ['cafe:20', 'arroz:7']);
  });

  test('estadísticas: stock bajo sin consultas por producto', () async {
    final s = (await repo.getInventoryStats(const InventoryStatsParams()))
        .getOrElse(() => throw 'falló');
    expect(s.totalBatches, 4);
    expect(s.movementsByType['lowStock'], 1); // arroz
  });

  test('rápido con el tamaño de una tienda real (2.500 productos, 7.400 lotes)', () async {
    await isar.writeTxn(() async {
      await isar.isarProducts.putAll([
        for (var i = 0; i < 2500; i++) product('p$i', 'Producto $i', minStock: 5),
      ]);
      await isar.isarInventoryBatchs.putAll([
        for (var i = 0; i < 7400; i++) batch('lb$i', 'p${i % 2500}', i % 9, 1000),
      ]);
    });
    final sw = Stopwatch()..start();
    await repo.getBalances(const InventoryBalanceQueryParams());
    final normal = sw.elapsedMilliseconds;
    sw.reset();
    await repo.getBalances(const InventoryBalanceQueryParams(lowStock: true));
    final filtered = sw.elapsedMilliseconds;
    sw.reset();
    await repo.getInventoryStats(const InventoryStatsParams());
    final stats = sw.elapsedMilliseconds;
    // ignore: avoid_print
    print('saldos página: $normal ms | stock bajo: $filtered ms | estadísticas: $stats ms');
    expect(normal, lessThan(300));
    expect(filtered, lessThan(1500));
    expect(stats, lessThan(1500));
  });
}

class _FakeDb implements IsarDatabase {
  _FakeDb(this.database);
  @override
  final Isar database;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
