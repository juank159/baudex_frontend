// test/integration/products/product_crud_flow_test.dart
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_isar.dart';
import '../../fixtures/product_fixtures.dart';

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

  group('Product CRUD Flow Integration', () {
    test(
      'complete CRUD flow: Create → Read → Update → Delete',
      () async {
        // ========== CREATE ==========
        final createResult = await repository.createProduct(
          name: 'Test Product',
          sku: 'TEST-001',
          categoryId: 'cat-001',
          stock: 100.0,
          minStock: 10.0,
        );

        String? productId;
        createResult.fold(
          (failure) {
            print('❌ CREATE FAILED: ${failure.message}');
            fail('Create should succeed: ${failure.message}');
          },
          (product) {
            productId = product.id;
            expect(product.name, 'Test Product');
            expect(product.sku, 'TEST-001');
            expect(product.stock, 100.0);
          },
        );

        expect(createResult.isRight(), true);

        // Verify created in ISAR
        final isarProducts = await mockIsar.isarProducts.where().findAll();
        expect(isarProducts.length, 1);
        expect(isarProducts.first.isSynced, false);

        // Note: Sync operation creation is optional in offline mode when SyncService is not available
        // In real scenarios, SyncService would be initialized and operations would be queued

        // ========== READ ==========
        final readResult = await repository.getProductById(productId!);

        expect(readResult.isRight(), true);
        readResult.fold(
          (failure) => fail('Read should succeed'),
          (product) {
            expect(product.id, productId);
            expect(product.name, 'Test Product');
          },
        );

        // ========== UPDATE ==========
        final updateResult = await repository.updateProduct(
          id: productId!,
          name: 'Updated Product',
          stock: 75.0,
        );

        expect(updateResult.isRight(), true);
        updateResult.fold(
          (failure) => fail('Update should succeed'),
          (product) {
            expect(product.name, 'Updated Product');
            expect(product.stock, 75.0);
          },
        );

        // Verify update in ISAR
        final updatedInIsar = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(productId!)
            .findFirst();
        expect(updatedInIsar!.name, 'Updated Product');
        expect(updatedInIsar.stock, 75.0);
        expect(updatedInIsar.isSynced, false); // Marked as unsynced

        // ========== DELETE ==========
        final deleteResult = await repository.deleteProduct(productId!);

        expect(deleteResult.isRight(), true);

        // Verify soft delete in ISAR
        final deletedInIsar = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(productId!)
            .findFirst();
        expect(deletedInIsar!.deletedAt, isNotNull);
        expect(deletedInIsar.isSynced, false); // Marked as unsynced

        // Verify should not appear in normal queries
        final afterDeleteResult = await repository.getProductById(productId!);
        expect(afterDeleteResult.isLeft(), true);
      },
    );

    test(
      'CRUD flow with stock operations',
      () async {
        // Create product with initial stock
        final createResult = await repository.createProduct(
          name: 'Stock Product',
          sku: 'STOCK-001',
          categoryId: 'cat-001',
          stock: 100.0,
          minStock: 10.0,
        );

        String? productId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (product) => productId = product.id,
        );

        // Subtract stock
        final subtractResult = await repository.updateProductStock(
          id: productId!,
          quantity: 25.0,
          operation: 'subtract',
        );

        subtractResult.fold(
          (failure) => fail('Subtract stock should succeed'),
          (product) => expect(product.stock, 75.0),
        );

        // Add stock
        final addResult = await repository.updateProductStock(
          id: productId!,
          quantity: 30.0,
          operation: 'add',
        );

        addResult.fold(
          (failure) => fail('Add stock should succeed'),
          (product) => expect(product.stock, 105.0),
        );

        // Verify final stock in ISAR
        final finalProduct = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(productId!)
            .findFirst();
        expect(finalProduct!.stock, 105.0);
      },
    );

    test(
      'multiple products CRUD flow',
      () async {
        // Create multiple products
        final products = <String>[];

        for (int i = 1; i <= 5; i++) {
          final result = await repository.createProduct(
            name: 'Product $i',
            sku: 'SKU-${i.toString().padLeft(3, '0')}',
            categoryId: 'cat-001',
            stock: 100.0 - (i * 10),
            minStock: 10.0,
          );

          result.fold(
            (failure) => fail('Create should succeed'),
            (product) => products.add(product.id),
          );
        }

        // Verify all created
        expect(products.length, 5);
        final allProducts = await mockIsar.isarProducts.where().findAll();
        expect(allProducts.length, 5);

        // Update one product
        final updateResult = await repository.updateProduct(
          id: products[2],
          name: 'Updated Product 3',
        );

        expect(updateResult.isRight(), true);

        // Delete one product
        final deleteResult = await repository.deleteProduct(products[4]);

        expect(deleteResult.isRight(), true);

        // Verify final state
        final activeProducts = await mockIsar.isarProducts
            .filter()
            .deletedAtIsNull()
            .findAll();
        expect(activeProducts.length, 4);
      },
    );

    test(
      'CRUD with cache consistency',
      () async {
        // Create product
        final createResult = await repository.createProduct(
          name: 'Cache Test Product',
          sku: 'CACHE-001',
          categoryId: 'cat-001',
        );

        String? productId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (product) => productId = product.id,
        );

        // Read from cache immediately
        final readResult1 = await repository.getProductById(productId!);
        expect(readResult1.isRight(), true);

        // Update
        await repository.updateProduct(
          id: productId!,
          name: 'Updated Cache Test',
        );

        // Read again to verify cache updated
        final readResult2 = await repository.getProductById(productId!);
        readResult2.fold(
          (failure) => fail('Read should succeed'),
          (product) => expect(product.name, 'Updated Cache Test'),
        );

        // Delete
        await repository.deleteProduct(productId!);

        // Read should fail (deleted)
        final readResult3 = await repository.getProductById(productId!);
        expect(readResult3.isLeft(), true);
      },
    );
  });
}
