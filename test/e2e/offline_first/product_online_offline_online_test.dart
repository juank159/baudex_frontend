// test/e2e/offline_first/product_online_offline_online_test.dart
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_local_datasource_isar.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_remote_datasource.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/models/product_model.dart';
import 'package:baudex_desktop/features/products/data/models/create_product_request_model.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_repository_impl.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_isar.dart';
import '../../fixtures/product_fixtures.dart';

// Mocks
class MockProductRemoteDataSource extends Mock
    implements ProductRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

// Fake classes for mocktail fallback values
class FakeCreateProductRequestModel extends Fake
    implements CreateProductRequestModel {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeCreateProductRequestModel());
  });
  late ProductRepositoryImpl repository;
  late ProductLocalDataSourceIsar localDataSource;
  late MockProductRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockIsar mockIsar;
  late MockIsarDatabase mockIsarDatabase;

  setUp(() {
    mockIsar = MockIsar();
    mockIsarDatabase = MockIsarDatabase(mockIsar);
    final dynamic db = mockIsarDatabase;
    localDataSource = ProductLocalDataSourceIsar(db);
    mockRemoteDataSource = MockProductRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();

    repository = ProductRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: localDataSource,
      networkInfo: mockNetworkInfo,
      database: mockIsarDatabase,
    );
  });

  tearDown(() async {
    await mockIsar.clear();
    await mockIsar.close();
  });

  group('Product E2E: Online → Offline → Online', () {
    test(
      'complete flow: online create → offline read → online sync',
      () async {
        // ========== PHASE 1: ONLINE - Create Product ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final tProduct = ProductFixtures.createProductEntity();
        final tProductModel = ProductModel.fromEntity(tProduct);

        when(() => mockRemoteDataSource.createProduct(any()))
            .thenAnswer((_) async => tProductModel);

        final createResult = await repository.createProduct(
          name: tProduct.name,
          sku: tProduct.sku,
          categoryId: tProduct.categoryId,
        );

        expect(createResult.isRight(), true);

        String? productId;
        createResult.fold(
          (failure) => fail('Online create should succeed'),
          (product) {
            productId = product.id;
            expect(product.name, tProduct.name);
          },
        );

        // Verify cached locally
        final cachedProduct = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(productId!)
            .findFirst();

        expect(cachedProduct, isNotNull);
        expect(cachedProduct!.isSynced, true);

        // ========== PHASE 2: OFFLINE - Read Product ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final offlineReadResult = await repository.getProductById(productId!);

        expect(offlineReadResult.isRight(), true);
        offlineReadResult.fold(
          (failure) => fail('Offline read should succeed from cache'),
          (product) {
            expect(product.id, productId);
            expect(product.name, tProduct.name);
          },
        );

        // ========== PHASE 3: OFFLINE - Update Product ==========
        final offlineUpdateResult = await repository.updateProduct(
          id: productId!,
          name: 'Updated Offline',
          stock: 75.0,
        );

        expect(offlineUpdateResult.isRight(), true);

        // Verify marked as unsynced
        final updatedCachedProduct = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(productId!)
            .findFirst();

        expect(updatedCachedProduct!.isSynced, false);
        expect(updatedCachedProduct.name, 'Updated Offline');

        // ========== PHASE 4: ONLINE AGAIN - Sync Changes ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final updatedProductModel = ProductModel.fromEntity(
          ProductFixtures.createProductEntity(
            id: productId!,
            name: 'Updated Offline',
            stock: 75.0,
          ),
        );

        when(() => mockRemoteDataSource.getProductById(any()))
            .thenAnswer((_) async => updatedProductModel);

        final onlineReadResult = await repository.getProductById(productId!);

        expect(onlineReadResult.isRight(), true);
        onlineReadResult.fold(
          (failure) => fail('Online read should succeed'),
          (product) {
            expect(product.name, 'Updated Offline');
            expect(product.stock, 75.0);
          },
        );
      },
    );

    test(
      'offline product creation then online sync with server ID replacement',
      () async {
        // ========== PHASE 1: OFFLINE - Create Product ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Note: This would normally use offline repository
        // For E2E we simulate by directly creating in ISAR
        final offlineProduct = IsarProduct()
          ..serverId = 'product_offline_123'
          ..name = 'Offline Created Product'
          ..sku = 'OFFLINE-SKU'
          ..type = IsarProductType.product
          ..status = IsarProductStatus.active
          ..stock = 50.0
          ..minStock = 10.0
          ..categoryId = 'cat-001'
          ..createdById = 'user-001'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..isSynced = false;

        await mockIsar.writeTxn(() async {
          await mockIsar.isarProducts.put(offlineProduct);
        });

        // Verify offline ID
        final createdProduct = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo('product_offline_123')
            .findFirst();

        expect(createdProduct, isNotNull);
        expect(createdProduct!.isSynced, false);

        // ========== PHASE 2: ONLINE - Sync with Server ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        // Simulate server assigning real ID
        final serverProduct = ProductModel.fromEntity(
          ProductFixtures.createProductEntity(
            id: 'prod-server-456',
            name: 'Offline Created Product',
            sku: 'OFFLINE-SKU',
          ),
        );

        // Cache with server ID (simulates sync process)
        await localDataSource.cacheProduct(serverProduct);

        // Verify server ID replaced offline ID
        final syncedProduct = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo('prod-server-456')
            .findFirst();

        expect(syncedProduct, isNotNull);
        expect(syncedProduct!.isSynced, true);
        expect(syncedProduct.name, 'Offline Created Product');

        // Original offline product should be updated (same SKU)
        final allProducts = await mockIsar.isarProducts.where().findAll();
        expect(allProducts.length, 1); // Should have merged, not duplicated
      },
    );

    test(
      'network interruption during operation with graceful degradation',
      () async {
        // ========== PHASE 1: ONLINE - Initial State ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final tProduct = ProductFixtures.createProductEntity();
        final tProductModel = ProductModel.fromEntity(tProduct);

        when(() => mockRemoteDataSource.createProduct(any()))
            .thenAnswer((_) async => tProductModel);

        await repository.createProduct(
          name: tProduct.name,
          sku: tProduct.sku,
          categoryId: tProduct.categoryId,
        );

        // ========== PHASE 2: NETWORK INTERRUPTION ==========
        // Simulate network failure during read
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getProductById(any()))
            .thenThrow(Exception('Network timeout'));

        // Should fallback to cache gracefully
        final result = await repository.getProductById(tProduct.id);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should fallback to cache'),
          (product) => expect(product.id, tProduct.id),
        );
      },
    );
  });
}
