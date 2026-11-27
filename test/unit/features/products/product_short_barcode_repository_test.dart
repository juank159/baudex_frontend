// Código de barras corto con ceros adelante ("0013390") por el repositorio
// real (base Isar real): con internet llega al servidor tal cual; sin
// internet queda en el equipo y en la cola tal cual; y la revisión de
// duplicados compara el código exacto.
import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_local_datasource_isar.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_remote_datasource.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/models/product_model.dart';
import 'package:baudex_desktop/features/products/data/models/update_product_request_model.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_repository_impl.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/product_fixtures.dart';

class _Db implements IIsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
}

class _Remote extends Mock implements ProductRemoteDataSource {}

class _Network extends Mock implements NetworkInfo {}

class _Sync extends GetxService with Mock implements SyncService {
  final queued = <Map<String, dynamic>>[];

  @override
  Future<void> onInit() async => super.onInit();

  @override
  Future<void> addOperationForCurrentUser({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    queued.add({...data, '_entityId': entityId, '_op': operationType});
  }
}

void main() {
  late Isar isar;
  late _Remote remote;
  late _Network network;
  late _Sync sync;
  late ProductRepositoryImpl repo;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
    registerFallbackValue(const UpdateProductRequestModel());
  });

  IsarProduct product(String id, {String? barcode}) => IsarProduct.create(
        serverId: id,
        name: 'Producto $id',
        sku: 'SKU-$id',
        barcode: barcode,
        type: IsarProductType.product,
        status: IsarProductStatus.active,
        stock: 5,
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
    Get.testMode = true;
    final dir = await Directory.systemTemp.createTemp('isar_short_barcode');
    isar = await Isar.open([IsarProductSchema], directory: dir.path);
    await isar.writeTxn(() => isar.isarProducts.putAll([
          product('sin-codigo'),
          product('otro', barcode: '13390'), // mismo número, SIN los ceros
        ]));
    remote = _Remote();
    network = _Network();
    sync = _Sync();
    Get.put<SyncService>(sync);
    final db = _Db(isar);
    repo = ProductRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: ProductLocalDataSourceIsar(db),
      networkInfo: network,
      database: db,
    );
  });

  tearDown(() async {
    Get.reset();
    await isar.close(deleteFromDisk: true);
  });

  test('con internet: el servidor recibe "0013390" como texto, con los ceros',
      () async {
    when(() => network.isConnected).thenAnswer((_) async => true);
    UpdateProductRequestModel? sent;
    when(() => remote.updateProduct(any(), any())).thenAnswer((inv) async {
      sent = inv.positionalArguments[1] as UpdateProductRequestModel;
      return ProductModel.fromEntity(ProductFixtures.createProductEntity(
          id: 'sin-codigo', barcode: sent!.barcode));
    });

    final result = await repo.updateProduct(
        id: 'sin-codigo', name: 'Producto sin-codigo', barcode: '0013390');

    expect(result.isRight(), isTrue);
    expect(sent!.toJson()['barcode'], '0013390');
    expect(sent!.toJson()['barcode'], isA<String>());
    expect(sync.queued, isEmpty, reason: 'el servidor ya lo tiene');
  });

  test('sin internet: queda en el equipo y en la cola, tal cual y una vez',
      () async {
    when(() => network.isConnected).thenAnswer((_) async => false);

    final result = await repo.updateProduct(
        id: 'sin-codigo', name: 'Producto sin-codigo', barcode: '0013390');

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => throw 'x').barcode, '0013390');
    final local = await stored('sin-codigo');
    expect(local!.barcode, '0013390');
    expect(local.isSynced, isFalse);
    expect(sync.queued, hasLength(1));
    expect(sync.queued.single['_entityId'], 'sin-codigo');
    expect(sync.queued.single['_op'], SyncOperationType.update);
    expect(sync.queued.single['barcode'], '0013390');
    verifyNever(() => remote.updateProduct(any(), any()));
  });

  group('duplicados con códigos cortos', () {
    setUp(() async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      await isar.writeTxn(() =>
          isar.isarProducts.put(product('con-ceros', barcode: '0013390')));
    });

    test('"0013390" ya existe en otro producto → duplicado', () async {
      final r = await repo.existsByBarcode('0013390', excludeId: 'sin-codigo');
      expect(r.getOrElse(() => false), isTrue);
    });

    test('el mismo producto no choca consigo mismo', () async {
      final r = await repo.existsByBarcode('0013390', excludeId: 'con-ceros');
      expect(r.getOrElse(() => true), isFalse);
    });

    test('"013390" (otros ceros) no es el mismo código', () async {
      final r = await repo.existsByBarcode('013390', excludeId: 'sin-codigo');
      expect(r.getOrElse(() => true), isFalse);
    });

    test('código de 1 dígito: compara exacto', () async {
      await isar.writeTxn(
          () => isar.isarProducts.put(product('uno', barcode: '7')));
      expect((await repo.existsByBarcode('7')).getOrElse(() => false), isTrue);
      expect((await repo.existsByBarcode('07')).getOrElse(() => true), isFalse);
    });

    test('base sin internet (ProductOfflineRepository): igual de exacta',
        () async {
      final offline = ProductOfflineRepository(database: _Db(isar));
      expect((await offline.existsByBarcode('0013390', excludeId: 'x'))
          .getOrElse(() => false), isTrue);
      expect((await offline.existsByBarcode('0013390', excludeId: 'con-ceros'))
          .getOrElse(() => true), isFalse);
      expect((await offline.existsByBarcode('13390', excludeId: 'otro'))
          .getOrElse(() => true), isFalse);
    });
  });
}
