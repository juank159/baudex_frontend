// El índice de códigos cortos de la factura recibe al instante el producto
// recién creado o editado en el equipo: si el cajero escribe enseguida su
// código, gana el producto, no "sin registrar".
import 'dart:async';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/invoices/data/short_code_index_keeper.dart';
import 'package:baudex_desktop/features/invoices/domain/price_entry.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/product_code_events.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../../helpers/isar_test_lib.dart';

class _Db implements IIsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
}

IsarProduct _product(String id, String sku, {String? barcode}) => IsarProduct.create(
      serverId: id,
      name: 'Producto $id',
      sku: sku,
      barcode: barcode,
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
    );

void main() {
  late Isar isar;
  late ProductOfflineRepository repo;
  late ShortCodeIndexKeeper keeper;
  var loads = 0;

  setUpAll(() async {
    await initIsarForTests();
  });

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_short_codes');
    isar = await Isar.open([IsarProductSchema], directory: dir.path);
    repo = ProductOfflineRepository(database: _Db(isar));
    await isar.writeTxn(() => isar.isarProducts.putAll([
          _product('a', 'ARR-1', barcode: '7701111111111'),
          _product('b', '5000'),
        ]));
    keeper = ShortCodeIndexKeeper(
      loadCodes: repo.activeProductCodes,
      isCatalogComplete: () async => true,
      codeChanges: ProductCodeEvents.stream,
      collectionChanges: isar.isarProducts.watchLazy(),
      settleDelay: const Duration(milliseconds: 150),
      maxSettle: const Duration(milliseconds: 600),
      onLoaded: (_) => loads++,
    );
    await keeper.refresh();
    loads = 0;
  });

  tearDown(() async {
    keeper.dispose();
    await isar.close(deleteFromDisk: true);
  });

  test('crear un producto con SKU 12345 y escribir 12345 enseguida: gana el producto',
      () async {
    expect(keeper.decide('12345'), isA<AddUnregisteredProduct>());

    final created = await repo.createProduct(
        name: 'Galletas', sku: '12345', categoryId: 'c');
    final product = created.getOrElse(() => throw 'no se creó');

    // Sin esperar el siguiente ciclo ni el vigilante de la base.
    final d = keeper.decide('12345');
    expect(d, isA<AddExistingProduct>());
    final local = await repo.getProductByLocalId((d as AddExistingProduct).localId);
    expect(local?.id, product.id);
  });

  test('código de barras corto 12345 recién creado también gana', () async {
    await repo.createProduct(
        name: 'Pan', sku: 'PAN-9', barcode: '12345', categoryId: 'c');
    expect(keeper.decide('12345'), isA<AddExistingProduct>());
  });

  test('editar el código: el viejo vuelve a ser valor, el nuevo es el producto',
      () async {
    final created = await repo.createProduct(
        name: 'Galletas', sku: '12345', categoryId: 'c');
    final id = created.getOrElse(() => throw 'x').id;
    await repo.updateProduct(id: id, sku: '54321');
    expect(keeper.decide('54321'), isA<AddExistingProduct>());
    // Mientras se rehace por el aviso de la base, nunca "sin registrar"
    // a ciegas; al terminar, 12345 es un valor otra vez.
    await keeper.refresh();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await keeper.refresh();
    expect(keeper.decide('12345'), isA<AddUnregisteredProduct>());
  });

  test('borrar el producto lo saca del índice', () async {
    final created = await repo.createProduct(
        name: 'Galletas', sku: '12345', categoryId: 'c');
    final id = created.getOrElse(() => throw 'x').id;
    expect(await repo.deleteProduct(id), isA<Object>());
    final d = keeper.decide('12345');
    expect(d, isNot(isA<AddExistingProduct>()));
  });

  test('producto que llega por la sincronización: no sale "sin registrar"',
      () async {
    // Escritura directa (como la descarga), sin aviso inmediato.
    await isar.writeTxn(() => isar.isarProducts.put(_product('s', '777')));
    await Future<void>.delayed(const Duration(milliseconds: 50)); // vigilante
    expect(keeper.decide('777'), isA<PriceEntryNeedsLookup>(),
        reason: 'pendiente: se consulta la base');
    await keeper.refresh();
    expect(keeper.decide('777'), isA<AddExistingProduct>());
  });

  // ───── La pantalla nunca espera: [guess] responde siempre en memoria ─────

  test('sincronización escribiendo: guess responde al instante y avisa que falta confirmar',
      () async {
    await isar.writeTxn(() => isar.isarProducts.put(_product('s', '777')));
    await Future<void>.delayed(const Duration(milliseconds: 50)); // vigilante
    final g = keeper.guess('3500');
    expect(g.existingLocalId, isNull);
    expect(g.certain, isFalse, reason: 'pendiente: se confirma en segundo plano');
    // Un código que el índice ya conoce sigue ganando aunque esté pendiente.
    expect(keeper.guess('5000').existingLocalId, isNotNull);
  });

  test('teclear con la sincronización escribiendo no rehace el índice por cada tecla',
      () async {
    var n = 0;
    final writer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      n++;
      isar.writeTxn(() => isar.isarProducts.put(_product('w$n', 'W-$n')));
    });
    for (var i = 0; i < 20; i++) {
      keeper.guess('${i}00');
      keeper.decide('${i}00');
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    writer.cancel();
    expect(loads, lessThanOrEqualTo(1),
        reason: 'antes: una carga por tecla mientras había escrituras');
  });

  test('cuando las escrituras se calman el índice se rehace solo y vuelve a ser seguro',
      () async {
    await isar.writeTxn(() => isar.isarProducts.put(_product('s', '777')));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(keeper.isStale, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(keeper.isStale, isFalse);
    expect(loads, 1);
    expect(keeper.guess('777').existingLocalId, isNotNull);
    expect(keeper.guess('3500').certain, isTrue);
  });

  test('escrituras que no paran: se rehace igual al tope de espera', () async {
    var n = 0;
    final writer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      n++;
      isar.writeTxn(() => isar.isarProducts.put(_product('w$n', 'W-$n')));
    });
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    writer.cancel();
    expect(loads, greaterThanOrEqualTo(1));
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });

  test('catálogo sin terminar de bajar: guess no espera y marca por confirmar',
      () async {
    final partial = ShortCodeIndexKeeper(
      loadCodes: repo.activeProductCodes,
      isCatalogComplete: () async => false,
    );
    // Sin cargar todavía.
    expect(partial.guess('3500').existingLocalId, isNull);
    expect(partial.guess('3500').certain, isFalse);
    await partial.refresh();
    expect(partial.guess('3500').certain, isFalse);
    expect(partial.guess('5000').existingLocalId, isNotNull,
        reason: 'lo que ya bajó sí se conoce');
    partial.dispose();
  });
}
