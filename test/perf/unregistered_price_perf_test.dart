import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/invoices/domain/price_entry.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

class _Db implements IIsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
}

IsarProduct _product(int i, {String? sku}) => (IsarProduct.create(
      serverId: 'p$i',
      name: 'PRODUCTO DE PRUEBA NUMERO $i PRESENTACION ${i % 7}00 GR',
      description: 'Descripcion del producto $i',
      sku: sku ?? 'SKU-${100000 + i}',
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
    ))
      ..id = i + 1;

/// Medición: Enter con un valor ("3500") en un catálogo de 20.000 productos.
/// Antes, la app consultaba la base local por SKU exacto antes de decidir;
/// mientras la sincronización escribe, esa consulta espera.
void main() {
  late Isar isar;
  late ProductOfflineRepository repo;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
    final dir = await Directory.systemTemp.createTemp('isar_unreg_perf');
    isar = await Isar.open([IsarProductSchema], directory: dir.path);
    repo = ProductOfflineRepository(database: _Db(isar));
    await isar.writeTxn(() => isar.isarProducts.putAll([
          for (var i = 0; i < 20000; i++) _product(i),
          _product(20001, sku: '5000'),
        ]));
  });

  tearDownAll(() => isar.close(deleteFromDisk: true));

  Future<double> ms(Future<void> Function() f) async {
    final w = Stopwatch()..start();
    await f();
    return w.elapsedMicroseconds / 1000;
  }

  // ANTES: lo que hacía la app (copiado de main).
  Future<void> oldSkuLookup(String sku) => isar.isarProducts
      .filter()
      .skuEqualTo(sku)
      .and()
      .deletedAtIsNull()
      .findFirst();
  Future<void> oldBarcodeLookup(String code) async {
    final exact = await isar.isarProducts
        .filter()
        .barcodeEqualTo(code)
        .and()
        .deletedAtIsNull()
        .findFirst();
    // Sin coincidencia exacta: la búsqueda "que contenga" de todo el catálogo.
    if (exact == null) await repo.searchProducts(code);
  }
  // Pantalla de productos: "que contenga", tope 50 (tras 500 ms de pausa).
  Future<void> oldListBarcode(String code) => repo.searchProducts(code, limit: 50);

  /// Escrituras como las de la sincronización (tandas de 500 productos).
  Future<void> syncWrites(Completer<void> stop) async {
    var n = 0;
    while (!stop.isCompleted) {
      await isar.writeTxn(() => isar.isarProducts.putAll([
            for (var i = 0; i < 500; i++) _product((n * 500 + i) % 20000),
          ]));
      n++;
    }
  }

  Future<List<double>> repeat(Future<void> Function() f, [int n = 5]) async =>
      [for (var i = 0; i < n; i++) await ms(f)];

  String fmt(List<double> v) =>
      v.map((e) => e.toStringAsFixed(1)).join(', ');

  test('antes y después con 20.000 productos', () async {
    const foundCode = '77${(1000000000 + 12345 * 7919) % 10000000000}';
    const missingCode = '7709999999999';
    late ShortCodeIndex index;
    final buildMs = await ms(() async {
      index = ShortCodeIndex.build(await repo.activeProductCodes(),
          complete: true);
    });

    Future<void> report(String when) async {
      final r = <String, List<double>>{
        'ANTES valor "3500" (consulta SKU)': await repeat(() => oldSkuLookup('3500')),
        'DESPUES valor "3500" (memoria)': await repeat(() async {
          final d = decidePriceEntry('3500', index);
          expect(d, isA<AddUnregisteredProduct>());
        }),
        'ANTES escaneo encontrado': await repeat(() => oldBarcodeLookup(foundCode)),
        'DESPUES escaneo encontrado': await repeat(() => repo.getProductByBarcode(foundCode)),
        'ANTES escaneo no encontrado': await repeat(() => oldBarcodeLookup(missingCode)),
        'DESPUES escaneo no encontrado': await repeat(() async {
          for (final v in barcodeVariants(missingCode)) {
            await repo.getProductByBarcode(v);
          }
        }),
        'ANTES pantalla productos (sin la pausa de 500 ms)': await repeat(() => oldListBarcode(foundCode)),
      };
      for (final e in r.entries) {
        // ignore: avoid_print
        print('MEDICION [$when] ${e.key}: ${fmt(e.value)} ms');
      }
    }

    // ignore: avoid_print
    print('MEDICION índice de códigos cortos: ${buildMs.toStringAsFixed(1)} ms '
        '(${index.length} códigos), en segundo plano');
    expect(decidePriceEntry('5000', index), isA<AddExistingProduct>());
    await report('sin sync');
    final stop = Completer<void>();
    final writer = syncWrites(stop);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await report('con sync escribiendo');
    stop.complete();
    await writer;
  });
}
