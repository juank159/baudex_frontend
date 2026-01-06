// test/fixtures/product_fixtures.dart
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
import 'package:baudex_desktop/features/products/domain/entities/tax_enums.dart';

/// Test fixtures for Products module
class ProductFixtures {
  // ============================================================================
  // ENTITY FIXTURES (Domain Layer)
  // ============================================================================

  /// Creates a single product entity with default test data
  static Product createProductEntity({
    String id = 'prod-001',
    String name = 'Test Product',
    String? description = 'Test product description',
    String sku = 'SKU-001',
    String? barcode = '1234567890',
    ProductType type = ProductType.product,
    ProductStatus status = ProductStatus.active,
    double stock = 100.0,
    double minStock = 10.0,
    String? unit = 'pcs',
    String categoryId = 'cat-001',
    String createdById = 'user-001',
    List<ProductPrice>? prices,
    TaxCategory taxCategory = TaxCategory.iva,
    double taxRate = 19.0,
    bool isTaxable = true,
    RetentionCategory? retentionCategory,
    double? retentionRate,
    bool hasRetention = false,
  }) {
    return Product(
      id: id,
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      type: type,
      status: status,
      stock: stock,
      minStock: minStock,
      unit: unit,
      categoryId: categoryId,
      createdById: createdById,
      prices: prices ?? [createProductPriceEntity(productId: id)],
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      taxCategory: taxCategory,
      taxRate: taxRate,
      isTaxable: isTaxable,
      retentionCategory: retentionCategory,
      retentionRate: retentionRate,
      hasRetention: hasRetention,
    );
  }

  /// Creates a list of product entities
  static List<Product> createProductEntityList(int count) {
    return List.generate(count, (index) {
      return createProductEntity(
        id: 'prod-${(index + 1).toString().padLeft(3, '0')}',
        name: 'Test Product ${index + 1}',
        sku: 'SKU-${(index + 1).toString().padLeft(3, '0')}',
        barcode: '1234567890${index.toString().padLeft(3, '0')}',
        stock: 100.0 - (index * 5),
      );
    });
  }

  /// Creates a product price entity
  static ProductPrice createProductPriceEntity({
    String id = 'price-001',
    PriceType type = PriceType.price1,
    double amount = 100000.0,
    String currency = 'COP',
    PriceStatus status = PriceStatus.active,
    double discountPercentage = 0.0,
    double minQuantity = 1.0,
    String productId = 'prod-001',
  }) {
    return ProductPrice(
      id: id,
      type: type,
      amount: amount,
      currency: currency,
      status: status,
      discountPercentage: discountPercentage,
      minQuantity: minQuantity,
      productId: productId,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES
  // ============================================================================

  /// Creates a low stock product (stock <= minStock)
  static Product createLowStockProduct({
    String id = 'prod-low-stock',
    double stock = 5.0,
    double minStock = 10.0,
  }) {
    return createProductEntity(
      id: id,
      name: 'Low Stock Product',
      sku: 'SKU-LOW-STOCK',
      stock: stock,
      minStock: minStock,
      status: ProductStatus.active,
    );
  }

  /// Creates an out of stock product
  static Product createOutOfStockProduct({
    String id = 'prod-out-stock',
  }) {
    return createProductEntity(
      id: id,
      name: 'Out of Stock Product',
      sku: 'SKU-OUT-STOCK',
      stock: 0.0,
      minStock: 10.0,
      status: ProductStatus.outOfStock,
    );
  }

  /// Creates an inactive product
  static Product createInactiveProduct({
    String id = 'prod-inactive',
  }) {
    return createProductEntity(
      id: id,
      name: 'Inactive Product',
      sku: 'SKU-INACTIVE',
      status: ProductStatus.inactive,
    );
  }

  /// Creates a service type product
  static Product createServiceProduct({
    String id = 'prod-service',
  }) {
    return createProductEntity(
      id: id,
      name: 'Service Product',
      sku: 'SKU-SERVICE',
      type: ProductType.service,
      stock: 0.0,
      minStock: 0.0,
    );
  }

  /// Creates a product with multiple prices
  static Product createProductWithMultiplePrices({
    String id = 'prod-multi-price',
  }) {
    return createProductEntity(
      id: id,
      name: 'Product with Multiple Prices',
      sku: 'SKU-MULTI-PRICE',
      prices: [
        createProductPriceEntity(
          id: 'price-001',
          productId: id,
          type: PriceType.cost,
          amount: 50000.0,
        ),
        createProductPriceEntity(
          id: 'price-002',
          productId: id,
          type: PriceType.price1,
          amount: 100000.0,
        ),
        createProductPriceEntity(
          id: 'price-003',
          productId: id,
          type: PriceType.price2,
          amount: 90000.0,
        ),
        createProductPriceEntity(
          id: 'price-004',
          productId: id,
          type: PriceType.price3,
          amount: 80000.0,
        ),
      ],
    );
  }

  /// Creates a product with discount
  static Product createProductWithDiscount({
    String id = 'prod-discount',
    double discountPercentage = 10.0,
  }) {
    return createProductEntity(
      id: id,
      name: 'Product with Discount',
      sku: 'SKU-DISCOUNT',
      prices: [
        createProductPriceEntity(
          productId: id,
          amount: 100000.0,
          discountPercentage: discountPercentage,
        ),
      ],
    );
  }

  /// Creates a product with tax exemption
  static Product createTaxExemptProduct({
    String id = 'prod-tax-exempt',
  }) {
    return createProductEntity(
      id: id,
      name: 'Tax Exempt Product',
      sku: 'SKU-TAX-EXEMPT',
      taxRate: 0.0,
      isTaxable: false,
    );
  }

  /// Creates a product with retention
  static Product createProductWithRetention({
    String id = 'prod-retention',
  }) {
    return createProductEntity(
      id: id,
      name: 'Product with Retention',
      sku: 'SKU-RETENTION',
    );
  }

  // ============================================================================
  // BATCH CREATION HELPERS
  // ============================================================================

  /// Creates a mix of products with different statuses
  static List<Product> createMixedStatusProducts() {
    return [
      createProductEntity(id: 'prod-001', status: ProductStatus.active),
      createProductEntity(id: 'prod-002', status: ProductStatus.active),
      createInactiveProduct(id: 'prod-003'),
      createOutOfStockProduct(id: 'prod-004'),
      createLowStockProduct(id: 'prod-005'),
    ];
  }

  /// Creates a mix of products with different types
  static List<Product> createMixedTypeProducts() {
    return [
      createProductEntity(id: 'prod-001', type: ProductType.product),
      createProductEntity(id: 'prod-002', type: ProductType.product),
      createServiceProduct(id: 'prod-003'),
    ];
  }
}
