import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/breb/data/breb_local_stock.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

/// Una venta por Bre-B la crea el servidor: el equipo copia de allá el stock de
/// los productos vendidos para mostrarlo de inmediato.
void main() {
  late Isar isar;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  IsarProduct product(String id, double stock) => IsarProduct.create(
        serverId: id,
        name: 'Producto $id',
        sku: 'SKU-$id',
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
      );

  Future<double> stockOf(String id) async =>
      (await isar.isarProducts.filter().serverIdEqualTo(id).findFirst())!.stock;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_breb_stock');
    isar = await Isar.open([IsarProductSchema], directory: dir.path);
    await isar.writeTxn(() => isar.isarProducts.putAll([product('a', 200), product('b', 50)]));
  });

  tearDown(() => isar.close(deleteFromDisk: true));

  test('copia el stock del servidor de los productos vendidos', () async {
    final updated = await refreshLocalStock(
      productIds: ['a'],
      serverStockOf: (id) async => 197,
      isar: isar,
    );
    expect(updated, 1);
    expect(await stockOf('a'), 197);
    expect(await stockOf('b'), 50, reason: 'los demás productos no se tocan');
  });

  test('repetirlo no descuenta dos veces (se copia, no se resta)', () async {
    for (var i = 0; i < 2; i++) {
      await refreshLocalStock(productIds: ['a', 'a'], serverStockOf: (id) async => 197, isar: isar);
    }
    expect(await stockOf('a'), 197);
  });

  test('sin conexión no cambia nada ni falla', () async {
    final updated = await refreshLocalStock(
      productIds: ['a', 'b'],
      serverStockOf: (id) async => throw Exception('sin red'),
      isar: isar,
    );
    expect(updated, 0);
    expect(await stockOf('a'), 200);
  });

  test('un producto que no está en el equipo se ignora', () async {
    expect(
      await refreshLocalStock(productIds: ['zzz'], serverStockOf: (id) async => 5, isar: isar),
      0,
    );
  });
}
