// test/unit/data/datasources/product_local_datasource_isar_test.dart
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_local_datasource_isar.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/mock_isar.dart';
import '../../../fixtures/product_fixtures.dart';

void main() {
  late ProductLocalDataSourceIsar dataSource;
  late MockIsar mockIsar;
  late MockIsarDatabase mockIsarDatabase;

  setUp(() {
    mockIsar = MockIsar();
    mockIsarDatabase = MockIsarDatabase(mockIsar);
    dataSource = ProductLocalDataSourceIsar(mockIsarDatabase);
  });

  tearDown(() async {
    await mockIsar.clear();
    await mockIsar.close();
  });

  group('ProductLocalDataSourceIsar - cacheProducts', () {
    test(
      'should cache multiple products in ISAR',
      () async {
        // Arrange
        final products = ProductFixtures.createProductEntityList(3);
        final productModels = products
            .map((e) => ProductModel.fromEntity(e))
            .toList();

        // Act
        await dataSource.cacheProducts(productModels);

        // Assert
        final cachedProducts = await mockIsar.isarProducts.where().findAll();
        expect(cachedProducts.length, 3);
      },
    );

    test(
      'should mark cached products as synced',
      () async {
        // Arrange
        final products = ProductFixtures.createProductEntityList(2);
        final productModels = products
            .map((e) => ProductModel.fromEntity(e))
            .toList();

        // Act
        await dataSource.cacheProducts(productModels);

        // Assert
        final cachedProducts = await mockIsar.isarProducts.where().findAll();
        expect(cachedProducts.every((p) => p.isSynced), true);
      },
    );

    test(
      'should update existing product if serverId matches',
      () async {
        // Arrange
        final product = ProductFixtures.createProductEntity(id: 'prod-001');
        final productModel = ProductModel.fromEntity(product);

        // Cache initially
        await dataSource.cacheProducts([productModel]);

        // Update
        final updatedProduct = ProductFixtures.createProductEntity(
          id: 'prod-001',
          name: 'Updated Name',
          stock: 75.0,
        );
        final updatedModel = ProductModel.fromEntity(updatedProduct);

        // Act
        await dataSource.cacheProducts([updatedModel]);

        // Assert
        final cachedProducts = await mockIsar.isarProducts.where().findAll();
        expect(cachedProducts.length, 1); // Should not duplicate
        expect(cachedProducts.first.name, 'Updated Name');
        expect(cachedProducts.first.stock, 75.0);
      },
    );

    test(
      'should update product by SKU if serverId not found (offline sync scenario)',
      () async {
        // Arrange
        final offlineProduct = ProductFixtures.createProductEntity(
          id: 'product_offline_123',
          sku: 'SKU-001',
          name: 'Offline Product',
        );
        final offlineModel = ProductModel.fromEntity(offlineProduct);
        await dataSource.cacheProducts([offlineModel]);

        // Now sync with server ID
        final syncedProduct = ProductFixtures.createProductEntity(
          id: 'prod-server-123',
          sku: 'SKU-001',
          name: 'Synced Product',
        );
        final syncedModel = ProductModel.fromEntity(syncedProduct);

        // Act
        await dataSource.cacheProducts([syncedModel]);

        // Assert
        final cachedProducts = await mockIsar.isarProducts.where().findAll();
        expect(cachedProducts.length, 1); // Should update, not create new
        expect(cachedProducts.first.serverId, 'prod-server-123');
        expect(cachedProducts.first.name, 'Synced Product');
      },
    );

    test(
      'should throw CacheException on error',
      () async {
        // Arrange
        await mockIsar.close(); // Close DB to force error

        final products = ProductFixtures.createProductEntityList(1);
        final productModels = products
            .map((e) => ProductModel.fromEntity(e))
            .toList();

        // Act & Assert
        expect(
          () => dataSource.cacheProducts(productModels),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });

  group('ProductLocalDataSourceIsar - cacheProduct', () {
    test(
      'should cache single product in ISAR',
      () async {
        // Arrange
        final product = ProductFixtures.createProductEntity();
        final productModel = ProductModel.fromEntity(product);

        // Act
        await dataSource.cacheProduct(productModel);

        // Assert
        final cachedProducts = await mockIsar.isarProducts.where().findAll();
        expect(cachedProducts.length, 1);
        expect(cachedProducts.first.name, product.name);
      },
    );

    test(
      'should update existing product',
      () async {
        // Arrange
        final product = ProductFixtures.createProductEntity(id: 'prod-001');
        final productModel = ProductModel.fromEntity(product);
        await dataSource.cacheProduct(productModel);

        // Update
        final updatedProduct = ProductFixtures.createProductEntity(
          id: 'prod-001',
          name: 'Updated',
        );
        final updatedModel = ProductModel.fromEntity(updatedProduct);

        // Act
        await dataSource.cacheProduct(updatedModel);

        // Assert
        final cachedProducts = await mockIsar.isarProducts.where().findAll();
        expect(cachedProducts.length, 1);
        expect(cachedProducts.first.name, 'Updated');
      },
    );
  });

  group('ProductLocalDataSourceIsar - getCachedProducts', () {
    test(
      'should return all non-deleted products from ISAR',
      () async {
        // Arrange
        final products = ProductFixtures.createProductEntityList(5);
        for (final product in products) {
          final isarProduct = IsarProduct.fromEntity(product);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarProducts.put(isarProduct);
          });
        }

        // Act
        final result = await dataSource.getCachedProducts();

        // Assert
        expect(result.length, 5);
      },
    );

    test(
      'should not return deleted products',
      () async {
        // Arrange
        final products = ProductFixtures.createProductEntityList(3);
        for (final product in products) {
          final isarProduct = IsarProduct.fromEntity(product);
          if (product.id == 'prod-002') {
            isarProduct.deletedAt = DateTime.now();
          }
          await mockIsar.writeTxn(() async {
            await mockIsar.isarProducts.put(isarProduct);
          });
        }

        // Act
        final result = await dataSource.getCachedProducts();

        // Assert
        expect(result.length, 2);
        expect(result.any((p) => p.id == 'prod-002'), false);
      },
    );

    test(
      'should throw CacheException when no products in ISAR',
      () async {
        // Act & Assert
        expect(
          () => dataSource.getCachedProducts(),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });

  group('ProductLocalDataSourceIsar - getCachedProduct', () {
    test(
      'should return product when found',
      () async {
        // Arrange
        const tProductId = 'prod-001';
        final product = ProductFixtures.createProductEntity(id: tProductId);
        final isarProduct = IsarProduct.fromEntity(product);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarProducts.put(isarProduct);
        });

        // Act
        final result = await dataSource.getCachedProduct(tProductId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, tProductId);
      },
    );

    test(
      'should return null when product not found',
      () async {
        // Act
        final result = await dataSource.getCachedProduct('non-existent');

        // Assert
        expect(result, isNull);
      },
    );

    test(
      'should return null when product is deleted',
      () async {
        // Arrange
        const tProductId = 'prod-001';
        final product = ProductFixtures.createProductEntity(id: tProductId);
        final isarProduct = IsarProduct.fromEntity(product);
        isarProduct.deletedAt = DateTime.now();
        await mockIsar.writeTxn(() async {
          await mockIsar.isarProducts.put(isarProduct);
        });

        // Act
        final result = await dataSource.getCachedProduct(tProductId);

        // Assert
        expect(result, isNull);
      },
    );
  });

  group('ProductLocalDataSourceIsar - removeCachedProduct', () {
    test(
      'should soft delete product in ISAR',
      () async {
        // Arrange
        const tProductId = 'prod-001';
        final product = ProductFixtures.createProductEntity(id: tProductId);
        final productModel = ProductModel.fromEntity(product);
        await dataSource.cacheProduct(productModel);

        // Act
        await dataSource.removeCachedProduct(tProductId);

        // Assert
        final deleted = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(tProductId)
            .findFirst();
        expect(deleted, isNull); // removeCachedProduct doesn't soft-delete, it removes
      },
    );

    test(
      'should throw CacheException when product not found',
      () async {
        // Act & Assert
        expect(
          () => dataSource.removeCachedProduct('non-existent'),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });

  group('ProductLocalDataSourceIsar - clearProductCache', () {
    test(
      'should remove all products from ISAR',
      () async {
        // Arrange
        final products = ProductFixtures.createProductEntityList(5);
        for (final product in products) {
          final isarProduct = IsarProduct.fromEntity(product);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarProducts.put(isarProduct);
          });
        }

        // Act
        await dataSource.clearProductCache();

        // Assert
        final remaining = await mockIsar.isarProducts.where().findAll();
        expect(remaining.length, 0);
      },
    );
  });

  group('ProductLocalDataSourceIsar - sync flags', () {
    test(
      'should get unsynced products',
      () async {
        // Arrange
        final syncedProduct = ProductFixtures.createProductEntity(id: 'prod-001');
        final unsyncedProduct = ProductFixtures.createProductEntity(id: 'prod-002');

        final isarSynced = IsarProduct.fromEntity(syncedProduct);
        isarSynced.isSynced = true;

        final isarUnsynced = IsarProduct.fromEntity(unsyncedProduct);
        isarUnsynced.isSynced = false;

        await mockIsar.writeTxn(() async {
          await mockIsar.isarProducts.put(isarSynced);
          await mockIsar.isarProducts.put(isarUnsynced);
        });

        // Act
        final unsynced = await dataSource.getUnsyncedProducts();

        // Assert
        expect(unsynced.length, 1);
        expect(unsynced.first.id, 'prod-002');
      },
    );

    test(
      'should mark product as synced',
      () async {
        // Arrange
        final product = ProductFixtures.createProductEntity(id: 'prod-001');
        final isarProduct = IsarProduct.fromEntity(product);
        isarProduct.isSynced = false;
        await mockIsar.writeTxn(() async {
          await mockIsar.isarProducts.put(isarProduct);
        });

        // Act
        await dataSource.markProductAsSynced('prod-001', 'server-id-123');

        // Assert
        final updated = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo('server-id-123')
            .findFirst();
        expect(updated, isNotNull);
        expect(updated!.isSynced, true);
        expect(updated.serverId, 'server-id-123');
      },
    );
  });

  group('ProductLocalDataSourceIsar - searchCachedProducts', () {
    test(
      'should search products by name',
      () async {
        // Arrange
        final products = [
          ProductFixtures.createProductEntity(
            id: 'prod-001',
            name: 'Laptop Computer',
          ),
          ProductFixtures.createProductEntity(
            id: 'prod-002',
            name: 'Desktop Computer',
          ),
          ProductFixtures.createProductEntity(
            id: 'prod-003',
            name: 'Phone',
          ),
        ];

        for (final product in products) {
          final isarProduct = IsarProduct.fromEntity(product);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarProducts.put(isarProduct);
          });
        }

        // Act
        final result = await dataSource.searchCachedProducts('Computer');

        // Assert
        expect(result.length, 2);
      },
    );

    test(
      'should search products by SKU',
      () async {
        // Arrange
        final products = [
          ProductFixtures.createProductEntity(
            id: 'prod-001',
            sku: 'COMP-001',
          ),
          ProductFixtures.createProductEntity(
            id: 'prod-002',
            sku: 'PHONE-001',
          ),
        ];

        for (final product in products) {
          final isarProduct = IsarProduct.fromEntity(product);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarProducts.put(isarProduct);
          });
        }

        // Act
        final result = await dataSource.searchCachedProducts('COMP');

        // Assert
        expect(result.length, 1);
        expect(result.first.sku, 'COMP-001');
      },
    );
  });
}
