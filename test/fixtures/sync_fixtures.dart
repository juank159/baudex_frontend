// test/fixtures/sync_fixtures.dart
import 'package:baudex_desktop/features/products/data/models/product_model.dart';
import 'package:baudex_desktop/features/categories/data/models/category_model.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_model.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';

/// Test fixtures for Sync operations
class SyncFixtures {
  /// Creates a ProductModel for testing sync operations
  static ProductModel createProductModel({
    String id = 'prod-001',
    String name = 'Test Product',
    String sku = 'SKU-001',
    String categoryId = 'cat-001',
  }) {
    return ProductModel(
      id: id,
      name: name,
      description: 'Test product description',
      sku: sku,
      barcode: '1234567890',
      type: 'product',
      status: 'active',
      stock: 100.0,
      minStock: 10.0,
      unit: 'pcs',
      categoryId: categoryId,
      createdById: 'user-001',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates a CategoryModel for testing sync operations
  static CategoryModel createCategoryModel({
    String id = 'cat-001',
    String name = 'Test Category',
    String slug = 'test-category',
  }) {
    return CategoryModel(
      id: id,
      name: name,
      description: 'Test category description',
      slug: slug,
      status: CategoryStatus.active,
      sortOrder: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates a CustomerModel for testing sync operations
  static CustomerModel createCustomerModel({
    String id = 'cust-001',
    String firstName = 'John',
    String lastName = 'Doe',
  }) {
    return CustomerModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      documentType: DocumentType.cc,
      documentNumber: '1234567890',
      email: 'john.doe@test.com',
      phone: '+1234567890',
      status: CustomerStatus.active,
      creditLimit: 0.0,
      currentBalance: 0.0,
      paymentTerms: 30,
      totalPurchases: 0.0,
      totalOrders: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }
}
