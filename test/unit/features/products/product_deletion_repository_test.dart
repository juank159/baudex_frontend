import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_local_datasource.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_remote_datasource.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';

class _Db implements IIsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
}

class _Remote extends Mock implements ProductRemoteDataSource {}

class _Local extends Mock implements ProductLocalDataSource {}

class _Network extends Mock implements NetworkInfo {}

/// Integridad: borrar un producto con existencias, con y sin internet, y qué
/// pasa cuando el servidor rechaza el borrado.
void main() {
  late Isar isar;
  late _Remote remote;
  late _Local local;
  late _Network network;
  late ProductRepositoryImpl repo;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  IsarProduct product(String id, double stock) => IsarProduct.create(
        serverId: id,
        name: 'Arroz',
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

  Future<IsarProduct?> stored(String id) =>
      isar.isarProducts.filter().serverIdEqualTo(id).findFirst();

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_delete');
    isar = await Isar.open([IsarProductSchema], directory: dir.path);
    await isar.writeTxn(() => isar.isarProducts.putAll([
          product('con-stock', 10),
          product('sin-stock', 0),
        ]));
    remote = _Remote();
    local = _Local();
    network = _Network();
    when(() => local.removeCachedProduct(any())).thenAnswer((_) async {});
    repo = ProductRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: network,
      database: _Db(isar),
    );
  });

  tearDown(() => isar.close(deleteFromDisk: true));

  test('con internet y con existencias: no se borra y ni siquiera se llama al servidor', () async {
    when(() => network.isConnected).thenAnswer((_) async => true);

    final result = await repo.deleteProduct('con-stock');

    expect(result.fold((f) => f, (_) => null), isA<BusinessRuleFailure>());
    verifyNever(() => remote.deleteProduct(any()));
    expect((await stored('con-stock'))!.deletedAt, isNull);
  });

  test('sin internet y con existencias: tampoco se borra en este equipo', () async {
    when(() => network.isConnected).thenAnswer((_) async => false);

    final result = await repo.deleteProduct('con-stock');

    expect(result.fold((f) => f, (_) => null), isA<BusinessRuleFailure>());
    expect((await stored('con-stock'))!.deletedAt, isNull);
  });

  test('el servidor lo rechaza (409, orden de compra abierta): no se borra en local', () async {
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => remote.deleteProduct('sin-stock')).thenThrow(
      const ServerException('Está en una orden de compra abierta', statusCode: 409),
    );

    final result = await repo.deleteProduct('sin-stock');

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<BusinessRuleFailure>());
    expect(failure!.message, contains('orden de compra'));
    expect((await stored('sin-stock'))!.deletedAt, isNull);
  });

  test('el servidor lo acepta: queda borrado en local', () async {
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => remote.deleteProduct('sin-stock')).thenAnswer((_) async {});

    final result = await repo.deleteProduct('sin-stock');

    expect(result.isRight(), isTrue);
    expect((await stored('sin-stock'))!.deletedAt, isNotNull);
  });

  test('servidor caído (500) y sin existencias: se borra en local para sincronizar después', () async {
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => remote.deleteProduct('sin-stock'))
        .thenThrow(const ServerException('Error interno', statusCode: 500));

    final result = await repo.deleteProduct('sin-stock');

    expect(result.isRight(), isTrue);
    expect((await stored('sin-stock'))!.deletedAt, isNotNull);
  });

  test('repositorio sin conexión: con existencias no se borra', () async {
    final offline = ProductOfflineRepository(database: _Db(isar));

    final result = await offline.deleteProduct('con-stock');

    expect(result.fold((f) => f, (_) => null), isA<BusinessRuleFailure>());
    expect((await stored('con-stock'))!.deletedAt, isNull);
  });
}
