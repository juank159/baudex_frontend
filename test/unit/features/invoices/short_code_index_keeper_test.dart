// El índice de códigos cortos de la factura recibe al instante el producto
// recién creado o editado en el equipo: si el cajero escribe enseguida su
// código, gana el producto, no "sin registrar".
import 'dart:async';
import 'dart:ffi';
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

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
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
    );
    await keeper.refresh();
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
}
