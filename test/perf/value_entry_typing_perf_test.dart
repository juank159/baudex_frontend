// Medición: el cajero teclea un valor ("2", "20", "200", "2000") con un
// catálogo grande, mientras la sincronización escribe productos o con el
// catálogo sin terminar de bajar. ¿Cuántas teclas deciden en memoria y
// cuánto se frena el hilo de la pantalla al rehacer el índice?
//
//   flutter test test/perf/value_entry_typing_perf_test.dart
//   (BAUDEX_PERF_PRODUCTS=50000 por defecto)
import 'dart:async';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/invoices/data/short_code_index_keeper.dart';
import 'package:baudex_desktop/features/invoices/domain/price_entry.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../helpers/isar_test_lib.dart';

class _Db implements IIsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
}

IsarProduct _product(int i) => (IsarProduct.create(
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
    ))
      ..id = i + 1;

void main() {
  final total =
      int.tryParse(Platform.environment['BAUDEX_PERF_PRODUCTS'] ?? '') ?? 50000;
  late Isar isar;
  late ProductOfflineRepository repo;
  var lastLoads = 0;

  setUpAll(() async {
    await initIsarForTests();
    final dir = await Directory.systemTemp.createTemp('isar_value_typing');
    isar = await Isar.open([IsarProductSchema], directory: dir.path);
    repo = ProductOfflineRepository(database: _Db(isar));
    for (var from = 0; from < total; from += 5000) {
      await isar.writeTxn(() => isar.isarProducts.putAll([
            for (var i = from; i < from + 5000 && i < total; i++) _product(i),
          ]));
    }
  });

  tearDownAll(() => isar.close(deleteFromDisk: true));

  /// Tandas como las de la descarga (50 productos por transacción).
  Future<void> syncWrites(Completer<void> stop, Duration pause) async {
    var n = 0;
    while (!stop.isCompleted) {
      await isar.writeTxn(() => isar.isarProducts.putAll([
            for (var i = 0; i < 50; i++) _product((n * 50 + i) % total),
          ]));
      n++;
      await Future<void>.delayed(pause);
    }
  }

  /// Teclea 4 valores por ronda, una tecla cada 120 ms. Devuelve el
  /// resumen: teclas que decidieron en memoria, cargas del índice y la
  /// pausa más larga del hilo (latido cada 4 ms).
  Future<String> typing({
    required String label,
    required bool complete,
    Duration? syncPause,
    int rounds = 25,
  }) async {
    var loads = 0;
    final keeper = ShortCodeIndexKeeper(
      loadCodes: () {
        loads++;
        return repo.activeProductCodes();
      },
      isCatalogComplete: () async => complete,
      collectionChanges: isar.isarProducts.watchLazy(),
    );
    await keeper.refresh();
    loads = 0;

    var worstGapMs = 0.0;
    var last = Stopwatch()..start();
    final beat = Timer.periodic(const Duration(milliseconds: 4), (_) {
      final gap = last.elapsedMicroseconds / 1000;
      if (gap > worstGapMs) worstGapMs = gap;
      last = Stopwatch()..start();
    });

    final stop = Completer<void>();
    final writer =
        syncPause == null ? Future<void>.value() : syncWrites(stop, syncPause);

    var keys = 0, instant = 0, certain = 0;
    var worstDecideUs = 0;
    for (var r = 0; r < rounds; r++) {
      for (final text in const ['2', '20', '200', '2000']) {
        final w = Stopwatch()..start();
        final guess = keeper.guess(text);
        final shown = guess.existingLocalId == null;
        if (guess.certain) certain++;
        final us = w.elapsedMicroseconds;
        if (us > worstDecideUs) worstDecideUs = us;
        keys++;
        if (shown) instant++;
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    }
    stop.complete();
    await writer;
    beat.cancel();
    keeper.dispose();
    final line = 'MEDICION [$label] $total productos: '
        'opción al instante en $instant de $keys teclas '
        '(${(100 * instant / keys).toStringAsFixed(0)} %; con el índice seguro: $certain), '
        'cargas del índice: $loads, '
        'pausa más larga del hilo: ${worstGapMs.toStringAsFixed(0)} ms, '
        'decisión más lenta: ${(worstDecideUs / 1000).toStringAsFixed(2)} ms';
    // ignore: avoid_print
    print(line);
    lastLoads = loads;
    return '$instant/$keys';
  }

  test('carga del índice', () async {
    for (var i = 0; i < 3; i++) {
      final w = Stopwatch()..start();
      final codes = await repo.activeProductCodes();
      final readMs = w.elapsedMicroseconds / 1000;
      w
        ..reset()
        ..start();
      final index = ShortCodeIndex.build(codes, complete: true);
      // ignore: avoid_print
      print('MEDICION índice $total productos: leer ${readMs.toStringAsFixed(0)} ms '
          '+ armar ${(w.elapsedMicroseconds / 1000).toStringAsFixed(0)} ms '
          '(en el hilo de la pantalla), ${index.length} códigos cortos');
    }
  });

  test('tecleo sin sincronización', () async {
    expect(await typing(label: 'sin sync', complete: true), '100/100');
  });

  test('tecleo con la sincronización escribiendo productos', () async {
    final r = await typing(
      label: 'sync escribiendo',
      complete: true,
      syncPause: const Duration(milliseconds: 150),
    );
    expect(r, '100/100');
    // Antes: una carga del índice por casi cada tecla (73 en 100).
    expect(lastLoads, lessThanOrEqualTo(3));
  });

  test('tecleo con el catálogo sin terminar de bajar', () async {
    final r = await typing(label: 'catálogo incompleto', complete: false);
    expect(r, '100/100');
  });
}
