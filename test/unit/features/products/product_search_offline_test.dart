import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product_price.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

class _Db implements IIsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
}

/// Búsqueda de productos de facturación en la base local (sirve sin
/// internet). La búsqueda exacta no cambia; cuando no hay coincidencia, la
/// búsqueda sin tildes la resuelve la base sin recorrer todo el catálogo.
void main() {
  late Isar isar;
  late ProductOfflineRepository repo;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  IsarProduct p(String id, String name,
          {String? sku, String? barcode, String? desc, DateTime? deletedAt}) =>
      IsarProduct.create(
        serverId: id,
        name: name,
        description: desc,
        sku: sku ?? 'SKU-$id',
        barcode: barcode,
        type: IsarProductType.product,
        status: IsarProductStatus.active,
        stock: 10,
        minStock: 0,
        categoryId: 'c',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        deletedAt: deletedAt,
        isSynced: true,
        taxCategory: IsarTaxCategory.noGravado,
        taxRate: 0,
        isTaxable: false,
        hasRetention: false,
      );

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_products');
    isar = await Isar.open([IsarProductSchema], directory: dir.path);
    repo = ProductOfflineRepository(database: _Db(isar));
    await isar.writeTxn(() => isar.isarProducts.putAll([
          p('1', 'CAFÉ AGUILA ROJA 250GR'),
          p('2', 'PIÑATA FIESTA'),
          p('3', 'Arroz Diana 500g', barcode: '7702511000014'),
          p('4', 'Azúcar Manuelita', desc: 'endulzante'),
          p('5', 'Bolsa 7000', sku: '7000'),
          p('6', 'Cafetera vieja', deletedAt: DateTime(2026)),
        ]));
  });

  tearDown(() => isar.close(deleteFromDisk: true));

  Future<List<String>> exact(String q) async =>
      (await repo.searchProducts(q)).getOrElse(() => []).map((e) => e.id).toList();
  Future<List<String>> loose(String q) async =>
      (await repo.searchProductsIgnoringAccents(q))
          .getOrElse(() => [])
          .map((e) => e.id)
          .toList();

  test('la búsqueda exacta sigue igual', () async {
    expect(await exact('arroz'), ['3']);
    expect(await exact('7702511000014'), ['3']);
    expect(await exact('7000'), ['5']);
    expect(await exact('café'), ['1']);
  });

  test('sin tildes encuentra con tildes', () async {
    expect(await exact('cafe'), isEmpty); // la exacta no lo encuentra…
    expect(await loose('cafe'), ['1']); // …la búsqueda sin tildes sí
    expect(await loose('pinata'), ['2']);
    expect(await loose('azucar'), ['4']);
    expect(await loose('CAFE AGUILA'), ['1']);
  });

  test('sin tildes no inventa coincidencias ni muestra borrados', () async {
    expect(await loose('cofa'), isEmpty); // el comodín no deja pasar falsos
    expect(await loose('cafetera'), isEmpty); // borrado
    expect(await loose('5000'), isEmpty); // precio de no registrado
  });

  test('rápida con un catálogo grande (2.600 productos)', () async {
    await isar.writeTxn(() => isar.isarProducts.putAll([
          for (var i = 0; i < 2600; i++)
            p('m$i', 'PRODUCTO $i GALLETA', desc: 'descripcion $i'),
        ]));
    final sw = Stopwatch()..start();
    final none = await loose('queso campesino');
    final price = await loose('4500');
    sw.stop();
    expect(none, isEmpty);
    expect(price, isEmpty);
    // ignore: avoid_print
    print('búsquedas sin resultado en 2.600 productos: ${sw.elapsedMilliseconds} ms');
    expect(sw.elapsedMilliseconds, lessThan(500));
  });

  test('lista local: más nuevos primero con DESC, filtro de precio y sin registro interno', () async {
    IsarProductPrice price(double amount) => IsarProductPrice.create(
          serverId: 'p$amount',
          type: IsarPriceType.price1,
          amount: amount,
          currency: 'COP',
          status: IsarPriceStatus.active,
          discountPercentage: 0,
          minQuantity: 1,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );
    await isar.writeTxn(() async {
      await isar.isarProducts.clear();
      await isar.isarProducts.putAll([
        p('a', 'Viejo')..createdAt = DateTime(2026, 1, 1)..prices = [price(1000)],
        p('b', 'Medio')..createdAt = DateTime(2026, 5, 1)..prices = [price(5000)],
        p('c', 'Nuevo')..createdAt = DateTime(2026, 9, 1)..prices = [price(9000)],
        p('STATS_CACHE', 'stats'),
      ]);
    });
    Future<List<String>> ids({String order = 'DESC', double? min, double? max}) async =>
        (await repo.getProducts(sortBy: 'createdAt', sortOrder: order, minPrice: min, maxPrice: max))
            .getOrElse(() => throw 'falló')
            .data
            .map((e) => e.id)
            .toList();
    expect(await ids(), ['c', 'b', 'a']);
    expect(await ids(order: 'ASC'), ['a', 'b', 'c']);
    expect(await ids(min: 2000, max: 8000), ['b']);
    final stats = (await repo.getProductStats()).getOrElse(() => throw 'falló');
    expect(stats.total, 3);
  });
}
