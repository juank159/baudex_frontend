import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

class _Db implements IIsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
}

/// Medición: cuánto tarda la búsqueda local cuando el cajero digita un valor
/// (p. ej. "2000" para un producto no registrado) en un catálogo grande.
void main() {
  late Isar isar;
  late ProductOfflineRepository repo;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
    final dir = await Directory.systemTemp.createTemp('isar_price_perf');
    isar = await Isar.open([IsarProductSchema], directory: dir.path);
    repo = ProductOfflineRepository(database: _Db(isar));
    final products = [
      for (var i = 0; i < 20000; i++)
        IsarProduct.create(
          serverId: 'p$i',
          name: 'PRODUCTO DE PRUEBA NUMERO $i PRESENTACION ${i % 7}00 GR',
          description: 'Descripcion del producto $i',
          sku: 'SKU-${100000 + i}',
          barcode: '77${(1000000000 + i * 7919) % 10000000000}',
          type: IsarProductType.product,
          status: IsarProductStatus.active,
          stock: 10,
          minStock: 0,
          categoryId: 'c',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          isSynced: true,
          taxCategory: IsarTaxCategory.noGravado,
          taxRate: 0,
          isTaxable: false,
          hasRetention: false,
        ),
    ];
    await isar.writeTxn(() => isar.isarProducts.putAll(products));
  });

  tearDownAll(() => isar.close(deleteFromDisk: true));

  Future<(int, int)> time(String term, int? limit) async {
    final watch = Stopwatch()..start();
    final result = await repo.searchProducts(term, limit: limit);
    return (watch.elapsedMilliseconds, result.getOrElse(() => []).length);
  }

  test('medición con 20.000 productos', () async {
    for (final term in ['2', '20', '200', '2000', '5000']) {
      final (allMs, allCount) = await time(term, null);
      final (capMs, capCount) = await time(term, 100);
      // ignore: avoid_print
      print('MEDICION "$term": sin tope ${allMs}ms ($allCount resultados) | tope 100: ${capMs}ms ($capCount)');
    }
  });
}
