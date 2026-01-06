// test/e2e/offline_first/product_low_stock_alert_test.dart
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

  group('Product E2E: Low Stock Alert Scenarios', () {
    test(
      'product becomes low stock after sales - triggers alert',
      () async {
        // ========== SETUP: Create Product with Normal Stock ==========
        final createResult = await repository.createProduct(
          name: 'Product for Stock Alert',
          sku: 'ALERT-001',
          categoryId: 'cat-001',
          stock: 50.0,
          minStock: 10.0,
        );

        String? productId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (product) {
            productId = product.id;
            expect(product.stock, 50.0);
            expect(product.minStock, 10.0);
          },
        );

        // ========== VERIFY: Initially Not Low Stock ==========
        var lowStockResult = await repository.getLowStockProducts();

        lowStockResult.fold(
          (failure) {
            print('❌ GET LOW STOCK FAILED: ${failure.message}');
            fail('Get low stock should succeed: ${failure.message}');
          },
          (products) => expect(products.length, 0), // Not low stock yet
        );

        // ========== SIMULATE: Multiple Sales ==========
        // Sale 1: Sell 15 units (50 - 15 = 35)
        await repository.updateProductStock(
          id: productId!,
          quantity: 15.0,
          operation: 'subtract',
        );

        // Sale 2: Sell 20 units (35 - 20 = 15)
        await repository.updateProductStock(
          id: productId!,
          quantity: 20.0,
          operation: 'subtract',
        );

        // Sale 3: Sell 10 units (15 - 10 = 5) → NOW LOW STOCK!
        await repository.updateProductStock(
          id: productId!,
          quantity: 10.0,
          operation: 'subtract',
        );

        // ========== VERIFY: Now Appears in Low Stock Alert ==========
        lowStockResult = await repository.getLowStockProducts();

        lowStockResult.fold(
          (failure) => fail('Get low stock should succeed'),
          (products) {
            expect(products.length, 1);
            expect(products.first.id, productId);
            expect(products.first.stock, 5.0);
            expect(products.first.stock <= products.first.minStock, true);
          },
        );

        // ========== VERIFY: Product Status ==========
        final productResult = await repository.getProductById(productId!);

        productResult.fold(
          (failure) => fail('Get product should succeed'),
          (product) {
            expect(product.stock, 5.0);
            expect(product.stock <= product.minStock, true);
          },
        );
      },
    );

    test(
      'restocking removes product from low stock alert',
      () async {
        // ========== SETUP: Create Low Stock Product ==========
        final createResult = await repository.createProduct(
          name: 'Low Stock Product',
          sku: 'RESTOCK-001',
          categoryId: 'cat-001',
          stock: 5.0,
          minStock: 10.0,
        );

        String? productId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (product) => productId = product.id,
        );

        // ========== VERIFY: Initially Low Stock ==========
        var lowStockResult = await repository.getLowStockProducts();

        lowStockResult.fold(
          (failure) => fail('Get low stock should succeed'),
          (products) {
            expect(products.length, 1);
            expect(products.first.stock, 5.0);
          },
        );

        // ========== SIMULATE: Restocking ==========
        await repository.updateProductStock(
          id: productId!,
          quantity: 50.0,
          operation: 'add',
        );

        // ========== VERIFY: No Longer Low Stock ==========
        lowStockResult = await repository.getLowStockProducts();

        lowStockResult.fold(
          (failure) => fail('Get low stock should succeed'),
          (products) => expect(products.length, 0), // No longer low stock
        );

        // ========== VERIFY: Stock Updated ==========
        final productResult = await repository.getProductById(productId!);

        productResult.fold(
          (failure) => fail('Get product should succeed'),
          (product) {
            expect(product.stock, 55.0);
            expect(product.stock > product.minStock, true);
          },
        );
      },
    );

    test(
      'multiple products with different stock levels',
      () async {
        // ========== SETUP: Create Products with Different Stock Levels ==========

        // Product 1: Normal stock
        await repository.createProduct(
          name: 'Normal Stock Product',
          sku: 'NORMAL-001',
          categoryId: 'cat-001',
          stock: 100.0,
          minStock: 10.0,
        );

        // Product 2: Low stock
        await repository.createProduct(
          name: 'Low Stock Product 1',
          sku: 'LOW-001',
          categoryId: 'cat-001',
          stock: 5.0,
          minStock: 10.0,
        );

        // Product 3: Critical stock (0)
        await repository.createProduct(
          name: 'Critical Stock Product',
          sku: 'CRITICAL-001',
          categoryId: 'cat-001',
          stock: 0.0,
          minStock: 10.0,
        );

        // Product 4: Low stock
        await repository.createProduct(
          name: 'Low Stock Product 2',
          sku: 'LOW-002',
          categoryId: 'cat-001',
          stock: 8.0,
          minStock: 15.0,
        );

        // ========== VERIFY: Low Stock Products ==========
        final lowStockResult = await repository.getLowStockProducts();

        lowStockResult.fold(
          (failure) => fail('Get low stock should succeed'),
          (products) {
            expect(products.length, 3); // 3 products below min stock
            expect(
              products.every((p) => p.stock <= p.minStock),
              true,
            );

            // Verify critical stock product included
            final criticalProduct = products.firstWhere(
              (p) => p.sku == 'CRITICAL-001',
            );
            expect(criticalProduct.stock, 0.0);
          },
        );
      },
    );

    test(
      'low stock filter works both online and offline',
      () async {
        // ========== SETUP: Create Mixed Stock Products ==========
        await repository.createProduct(
          name: 'Product A',
          sku: 'A-001',
          categoryId: 'cat-001',
          stock: 100.0,
          minStock: 10.0,
        );

        await repository.createProduct(
          name: 'Product B',
          sku: 'B-001',
          categoryId: 'cat-001',
          stock: 8.0,
          minStock: 10.0,
        );

        // ========== SCENARIO 1: Using getLowStockProducts() ==========
        final lowStockMethod = await repository.getLowStockProducts();

        lowStockMethod.fold(
          (failure) => fail('getLowStockProducts should succeed'),
          (products) => expect(products.length, 1),
        );

        // ========== SCENARIO 2: Using getProducts with lowStock filter ==========
        final lowStockFilter = await repository.getProducts(
          lowStock: true,
        );

        lowStockFilter.fold(
          (failure) => fail('lowStock filter should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 1);
            expect(paginatedResult.data.first.sku, 'B-001');
          },
        );
      },
    );

    test(
      'stock at exactly minStock threshold triggers alert',
      () async {
        // ========== SETUP: Create Product at Threshold ==========
        final createResult = await repository.createProduct(
          name: 'Threshold Product',
          sku: 'THRESHOLD-001',
          categoryId: 'cat-001',
          stock: 10.0,
          minStock: 10.0, // Exactly at threshold
        );

        String? productId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (product) => productId = product.id,
        );

        // ========== VERIFY: At Threshold = Low Stock ==========
        final lowStockResult = await repository.getLowStockProducts();

        lowStockResult.fold(
          (failure) => fail('Get low stock should succeed'),
          (products) {
            expect(products.length, 1);
            expect(products.first.id, productId);
          },
        );
      },
    );

    test(
      'low stock detection works across pagination',
      () async {
        // ========== SETUP: Create Many Low Stock Products ==========
        for (int i = 1; i <= 25; i++) {
          await repository.createProduct(
            name: 'Low Stock Product $i',
            sku: 'LS-${i.toString().padLeft(3, '0')}',
            categoryId: 'cat-001',
            stock: 5.0,
            minStock: 10.0,
          );
        }

        // ========== VERIFY: All Low Stock Products Retrieved ==========
        final lowStockResult = await repository.getLowStockProducts();

        lowStockResult.fold(
          (failure) => fail('Get low stock should succeed'),
          (products) {
            expect(products.length, 25);
            expect(products.every((p) => p.stock <= p.minStock), true);
          },
        );

        // ========== VERIFY: Can Paginate Low Stock Products ==========
        final paginatedResult = await repository.getProducts(
          lowStock: true,
          page: 1,
          limit: 10,
        );

        paginatedResult.fold(
          (failure) => fail('Pagination should succeed'),
          (result) {
            expect(result.data.length, 10);
            expect(result.meta.totalItems, 25);
            expect(result.meta.totalPages, 3);
          },
        );
      },
    );
  });
}
