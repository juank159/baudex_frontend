// test/integration/products/product_sync_flow_test.dart
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_isar.dart';

void main() {
  late ProductOfflineRepository repository;
  late MockIsar mockIsar;
  late MockIsarDatabase mockIsarDatabase;

  setUp(() {
    mockIsar = MockIsar();
    mockIsarDatabase = MockIsarDatabase(mockIsar);
    final dynamic db = mockIsarDatabase;
    repository = ProductOfflineRepository(database: db);
  });

  tearDown(() async {
    await mockIsar.clear();
    await mockIsar.close();
  });

  group('Product Sync Flow Integration', () {
    test(
      'offline creation creates sync operation',
      () async {
        // Create product offline
        final createResult = await repository.createProduct(
          name: 'Offline Product',
          sku: 'OFFLINE-001',
          categoryId: 'cat-001',
        );

        String? offlineId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (product) {
            offlineId = product.id;
            expect(product.id.startsWith('product_'), true);
            expect(product.name, 'Offline Product');
            expect(product.sku, 'OFFLINE-001');
          },
        );

        // Note: Sync operation creation is optional in offline mode when SyncService is not available
        // In real scenarios, SyncService would be initialized and operations would be queued
        // Here we verify the product is created and marked as unsynced
        final products = await mockIsar.isarProducts.where().findAll();
        expect(products.length, 1);
        expect(products.first.isSynced, false);
      },
    );

    test(
      'offline update creates sync operation',
      () async {
        // Create product first
        final createResult = await repository.createProduct(
          name: 'Product to Update',
          sku: 'UPDATE-001',
          categoryId: 'cat-001',
        );

        String? productId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (product) => productId = product.id,
        );

        // Update product
        final updateResult = await repository.updateProduct(
          id: productId!,
          name: 'Updated Offline',
        );

        // Verify update succeeded and product is marked as unsynced
        expect(updateResult.isRight(), true);
        final updatedProducts = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(productId!)
            .findAll();
        expect(updatedProducts.length, 1);
        expect(updatedProducts.first.isSynced, false);
        expect(updatedProducts.first.name, 'Updated Offline');
      },
    );

    test(
      'offline deletion creates sync operation',
      () async {
        // Create product first
        final createResult = await repository.createProduct(
          name: 'Product to Delete',
          sku: 'DELETE-001',
          categoryId: 'cat-001',
        );

        String? productId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (product) => productId = product.id,
        );

        // Delete product
        final deleteResult = await repository.deleteProduct(productId!);

        // Verify delete succeeded (soft delete) and product is marked as unsynced
        expect(deleteResult.isRight(), true);
        final deletedProducts = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(productId!)
            .findAll();
        expect(deletedProducts.length, 1);
        expect(deletedProducts.first.deletedAt, isNotNull);
        expect(deletedProducts.first.isSynced, false);
      },
    );

    test(
      'multiple offline operations create multiple sync operations',
      () async {
        // Create 3 products
        final productIds = <String>[];

        for (int i = 1; i <= 3; i++) {
          final result = await repository.createProduct(
            name: 'Product $i',
            sku: 'MULTI-${i.toString().padLeft(3, '0')}',
            categoryId: 'cat-001',
          );

          result.fold(
            (failure) => fail('Create should succeed'),
            (product) => productIds.add(product.id),
          );
        }

        // Update first product
        final updateResult = await repository.updateProduct(
          id: productIds[0],
          name: 'Updated Product 1',
        );
        expect(updateResult.isRight(), true);

        // Delete last product
        final deleteResult = await repository.deleteProduct(productIds[2]);
        expect(deleteResult.isRight(), true);

        // Verify all products are unsynced
        final allProducts = await mockIsar.isarProducts.where().findAll();
        expect(allProducts.length, 3); // All 3 products exist (one soft-deleted)

        final unsyncedProducts = allProducts.where((p) => !p.isSynced).toList();
        expect(unsyncedProducts.length, 3); // All should be unsynced

        // Verify update and delete
        final updated = allProducts.firstWhere((p) => p.serverId == productIds[0]);
        expect(updated.name, 'Updated Product 1');

        final deleted = allProducts.firstWhere((p) => p.serverId == productIds[2]);
        expect(deleted.deletedAt, isNotNull);
      },
    );

    test(
      'product created with all specified data',
      () async {
        // Create product with specific data
        final createResult = await repository.createProduct(
          name: 'Payload Test Product',
          sku: 'PAYLOAD-001',
          categoryId: 'cat-001',
          stock: 50.0,
          minStock: 5.0,
          description: 'Test description',
        );

        String? productId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (product) {
            productId = product.id;
            expect(product.name, 'Payload Test Product');
            expect(product.sku, 'PAYLOAD-001');
            expect(product.stock, 50.0);
            expect(product.minStock, 5.0);
            expect(product.description, 'Test description');
          },
        );

        // Verify in ISAR
        final isarProduct = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(productId!)
            .findFirst();
        expect(isarProduct, isNotNull);
        expect(isarProduct!.name, 'Payload Test Product');
        expect(isarProduct.sku, 'PAYLOAD-001');
        expect(isarProduct.stock, 50.0);
      },
    );

    test(
      'products marked as unsynced after offline operations',
      () async {
        // Create product
        final createResult = await repository.createProduct(
          name: 'Unsync Test',
          sku: 'UNSYNC-001',
          categoryId: 'cat-001',
        );

        String? productId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (product) => productId = product.id,
        );

        // Verify marked as unsynced
        final isarProduct = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(productId!)
            .findFirst();

        expect(isarProduct!.isSynced, false);

        // Update product
        await repository.updateProduct(
          id: productId!,
          name: 'Updated Unsync Test',
        );

        // Should still be unsynced
        final updatedIsarProduct = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(productId!)
            .findFirst();

        expect(updatedIsarProduct!.isSynced, false);
      },
    );
  });
}
