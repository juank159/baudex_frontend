// test/integration/products/product_offline_flow_test.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
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

  group('Product Offline Flow Integration', () {
    test(
      'create multiple products offline',
      () async {
        // Create 10 products offline
        final productIds = <String>[];

        for (int i = 1; i <= 10; i++) {
          final result = await repository.createProduct(
            name: 'Offline Product $i',
            sku: 'OFF-${i.toString().padLeft(3, '0')}',
            categoryId: 'cat-001',
            stock: 100.0 - (i * 5),
            minStock: 10.0,
          );

          result.fold(
            (failure) => fail('Create should succeed'),
            (product) => productIds.add(product.id),
          );
        }

        // Verify all created with offline IDs
        expect(productIds.length, 10);
        expect(productIds.every((id) => id.startsWith('product_offline_')), true);

        // Verify in ISAR
        final isarProducts = await mockIsar.isarProducts.where().findAll();
        expect(isarProducts.length, 10);
        expect(isarProducts.every((p) => !p.isSynced), true);
      },
    );

    test(
      'search products offline',
      () async {
        // Create products with different names
        await repository.createProduct(
          name: 'Laptop Computer',
          sku: 'LAPTOP-001',
          categoryId: 'cat-001',
        );

        await repository.createProduct(
          name: 'Desktop Computer',
          sku: 'DESKTOP-001',
          categoryId: 'cat-001',
        );

        await repository.createProduct(
          name: 'Mobile Phone',
          sku: 'PHONE-001',
          categoryId: 'cat-001',
        );

        // Search for "Computer"
        final searchResult = await repository.searchProducts('Computer');

        searchResult.fold(
          (failure) => fail('Search should succeed'),
          (products) {
            expect(products.length, 2);
            expect(products.every((p) => p.name.contains('Computer')), true);
          },
        );
      },
    );

    test(
      'filter products by status offline',
      () async {
        // Create active products
        await repository.createProduct(
          name: 'Active Product 1',
          sku: 'ACT-001',
          categoryId: 'cat-001',
          status: ProductStatus.active,
        );

        await repository.createProduct(
          name: 'Active Product 2',
          sku: 'ACT-002',
          categoryId: 'cat-001',
          status: ProductStatus.active,
        );

        // Create inactive product manually in ISAR
        final inactiveProduct = IsarProduct()
          ..serverId = 'product_offline_inactive'
          ..name = 'Inactive Product'
          ..sku = 'INACT-001'
          ..type = IsarProductType.product
          ..status = IsarProductStatus.inactive
          ..stock = 0.0
          ..minStock = 0.0
          ..categoryId = 'cat-001'
          ..createdById = 'user-001'
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..isSynced = false;

        await mockIsar.writeTxn(() async {
          await mockIsar.isarProducts.put(inactiveProduct);
        });

        // Filter by active status
        final result = await repository.getProducts(
          status: ProductStatus.active,
        );

        result.fold(
          (failure) => fail('Filter should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
            expect(
              paginatedResult.data.every((p) => p.status == ProductStatus.active),
              true,
            );
          },
        );
      },
    );

    test(
      'filter products by category offline',
      () async {
        // Create products in different categories
        await repository.createProduct(
          name: 'Category A Product 1',
          sku: 'CATA-001',
          categoryId: 'cat-a',
        );

        await repository.createProduct(
          name: 'Category A Product 2',
          sku: 'CATA-002',
          categoryId: 'cat-a',
        );

        await repository.createProduct(
          name: 'Category B Product',
          sku: 'CATB-001',
          categoryId: 'cat-b',
        );

        // Filter by category A
        final result = await repository.getProducts(
          categoryId: 'cat-a',
        );

        result.fold(
          (failure) => fail('Filter should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
            expect(
              paginatedResult.data.every((p) => p.categoryId == 'cat-a'),
              true,
            );
          },
        );
      },
    );

    test(
      'paginate products offline',
      () async {
        // Create 25 products
        for (int i = 1; i <= 25; i++) {
          await repository.createProduct(
            name: 'Product $i',
            sku: 'PAGE-${i.toString().padLeft(3, '0')}',
            categoryId: 'cat-001',
          );
        }

        // Get page 1 (limit 10)
        final page1Result = await repository.getProducts(
          page: 1,
          limit: 10,
        );

        page1Result.fold(
          (failure) => fail('Page 1 should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 10);
            expect(paginatedResult.meta.page, 1);
            expect(paginatedResult.meta.totalItems, 25);
            expect(paginatedResult.meta.totalPages, 3);
            expect(paginatedResult.meta.hasNextPage, true);
            expect(paginatedResult.meta.hasPreviousPage, false);
          },
        );

        // Get page 2
        final page2Result = await repository.getProducts(
          page: 2,
          limit: 10,
        );

        page2Result.fold(
          (failure) => fail('Page 2 should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 10);
            expect(paginatedResult.meta.page, 2);
            expect(paginatedResult.meta.hasNextPage, true);
            expect(paginatedResult.meta.hasPreviousPage, true);
          },
        );

        // Get page 3
        final page3Result = await repository.getProducts(
          page: 3,
          limit: 10,
        );

        page3Result.fold(
          (failure) => fail('Page 3 should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 5);
            expect(paginatedResult.meta.page, 3);
            expect(paginatedResult.meta.hasNextPage, false);
            expect(paginatedResult.meta.hasPreviousPage, true);
          },
        );
      },
    );

    test(
      'update stock offline',
      () async {
        // Create product
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

        // Subtract stock multiple times
        await repository.updateProductStock(
          id: productId!,
          quantity: 10.0,
          operation: 'subtract',
        );

        await repository.updateProductStock(
          id: productId!,
          quantity: 15.0,
          operation: 'subtract',
        );

        // Add stock
        await repository.updateProductStock(
          id: productId!,
          quantity: 5.0,
          operation: 'add',
        );

        // Verify final stock: 100 - 10 - 15 + 5 = 80
        final result = await repository.getProductById(productId!);

        result.fold(
          (failure) => fail('Get product should succeed'),
          (product) => expect(product.stock, 80.0),
        );
      },
    );

    test(
      'get low stock products offline',
      () async {
        // Create products with varying stock levels
        await repository.createProduct(
          name: 'High Stock Product',
          sku: 'HIGH-001',
          categoryId: 'cat-001',
          stock: 100.0,
          minStock: 10.0,
        );

        await repository.createProduct(
          name: 'Low Stock Product 1',
          sku: 'LOW-001',
          categoryId: 'cat-001',
          stock: 5.0,
          minStock: 10.0,
        );

        await repository.createProduct(
          name: 'Low Stock Product 2',
          sku: 'LOW-002',
          categoryId: 'cat-001',
          stock: 8.0,
          minStock: 15.0,
        );

        // Get low stock products
        final result = await repository.getLowStockProducts();

        result.fold(
          (failure) => fail('Get low stock should succeed'),
          (products) {
            expect(products.length, 2);
            expect(products.every((p) => p.stock <= p.minStock), true);
          },
        );
      },
    );

    test(
      'delete product offline',
      () async {
        // Create product
        final createResult = await repository.createProduct(
          name: 'Product to Delete',
          sku: 'DEL-001',
          categoryId: 'cat-001',
        );

        String? productId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (product) => productId = product.id,
        );

        // Delete
        final deleteResult = await repository.deleteProduct(productId!);

        expect(deleteResult.isRight(), true);

        // Verify soft deleted in ISAR
        final deletedProduct = await mockIsar.isarProducts
            .filter()
            .serverIdEqualTo(productId!)
            .findFirst();

        expect(deletedProduct!.deletedAt, isNotNull);

        // Should not appear in normal queries
        final getResult = await repository.getProductById(productId!);
        expect(getResult.isLeft(), true);
      },
    );

    test(
      'complete offline workflow with all operations',
      () async {
        // Simulate complete offline session

        // 1. Create products
        final productIds = <String>[];
        for (int i = 1; i <= 5; i++) {
          final result = await repository.createProduct(
            name: 'Workflow Product $i',
            sku: 'WF-${i.toString().padLeft(3, '0')}',
            categoryId: 'cat-001',
            stock: 50.0,
            minStock: 10.0,
          );

          result.fold(
            (failure) => fail('Create should succeed'),
            (product) => productIds.add(product.id),
          );
        }

        // 2. Search
        final searchResult = await repository.searchProducts('Workflow');
        searchResult.fold(
          (failure) => fail('Search should succeed'),
          (products) => expect(products.length, 5),
        );

        // 3. Update some products
        await repository.updateProduct(
          id: productIds[0],
          name: 'Updated Workflow Product 1',
        );

        await repository.updateProductStock(
          id: productIds[1],
          quantity: 20.0,
          operation: 'subtract',
        );

        // 4. Filter by low stock
        await repository.updateProductStock(
          id: productIds[2],
          quantity: 45.0,
          operation: 'subtract',
        );

        final lowStockResult = await repository.getLowStockProducts();
        lowStockResult.fold(
          (failure) => fail('Get low stock should succeed'),
          (products) => expect(products.length, greaterThan(0)),
        );

        // 5. Paginate
        final paginatedResult = await repository.getProducts(
          page: 1,
          limit: 3,
        );

        paginatedResult.fold(
          (failure) => fail('Pagination should succeed'),
          (result) {
            expect(result.data.length, 3);
            expect(result.meta.hasNextPage, true);
          },
        );

        // 6. Delete a product
        await repository.deleteProduct(productIds[4]);

        // Verify final state
        final finalProducts = await mockIsar.isarProducts
            .filter()
            .deletedAtIsNull()
            .findAll();

        expect(finalProducts.length, 4); // 5 created - 1 deleted

        // All should be unsynced
        expect(finalProducts.every((p) => !p.isSynced), true);
      },
    );
  });
}
