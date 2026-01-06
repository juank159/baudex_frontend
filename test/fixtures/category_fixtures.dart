// test/fixtures/category_fixtures.dart
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';

/// Test fixtures for Categories module
class CategoryFixtures {
  // ============================================================================
  // ENTITY FIXTURES (Domain Layer)
  // ============================================================================

  /// Creates a single category entity with default test data
  static Category createCategoryEntity({
    String id = 'cat-001',
    String name = 'Test Category',
    String? description = 'Test category description',
    String slug = 'test-category',
    String? image,
    CategoryStatus status = CategoryStatus.active,
    int sortOrder = 0,
    String? parentId,
    Category? parent,
    List<Category>? children,
    int? productsCount = 0,
    bool isSynced = true,
  }) {
    return Category(
      id: id,
      name: name,
      description: description,
      slug: slug,
      image: image,
      status: status,
      sortOrder: sortOrder,
      parentId: parentId,
      parent: parent,
      children: children,
      productsCount: productsCount,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      isSynced: isSynced,
    );
  }

  /// Creates a list of category entities
  static List<Category> createCategoryEntityList(int count) {
    return List.generate(count, (index) {
      return createCategoryEntity(
        id: 'cat-${(index + 1).toString().padLeft(3, '0')}',
        name: 'Test Category ${index + 1}',
        slug: 'test-category-${index + 1}',
        sortOrder: index,
        productsCount: index * 10,
      );
    });
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES
  // ============================================================================

  /// Creates an inactive category
  static Category createInactiveCategory({
    String id = 'cat-inactive',
  }) {
    return createCategoryEntity(
      id: id,
      name: 'Inactive Category',
      slug: 'inactive-category',
      status: CategoryStatus.inactive,
    );
  }

  /// Creates a parent category with children
  static Category createParentCategoryWithChildren({
    String id = 'cat-parent',
    int childrenCount = 3,
  }) {
    final children = List.generate(childrenCount, (index) {
      return createCategoryEntity(
        id: '$id-child-${index + 1}',
        name: 'Child Category ${index + 1}',
        slug: 'child-category-${index + 1}',
        parentId: id,
        sortOrder: index,
      );
    });

    return createCategoryEntity(
      id: id,
      name: 'Parent Category',
      slug: 'parent-category',
      children: children,
      productsCount: 50,
    );
  }

  /// Creates a child category
  static Category createChildCategory({
    String id = 'cat-child',
    String parentId = 'cat-parent',
  }) {
    final parent = createCategoryEntity(
      id: parentId,
      name: 'Parent Category',
      slug: 'parent-category',
    );

    return createCategoryEntity(
      id: id,
      name: 'Child Category',
      slug: 'child-category',
      parentId: parentId,
      parent: parent,
    );
  }

  /// Creates a category tree (multi-level hierarchy)
  static List<Category> createCategoryTree() {
    // Root categories
    final electronics = createCategoryEntity(
      id: 'cat-electronics',
      name: 'Electronics',
      slug: 'electronics',
      sortOrder: 0,
    );

    final clothing = createCategoryEntity(
      id: 'cat-clothing',
      name: 'Clothing',
      slug: 'clothing',
      sortOrder: 1,
    );

    // Electronics subcategories
    final phones = createCategoryEntity(
      id: 'cat-phones',
      name: 'Phones',
      slug: 'phones',
      parentId: 'cat-electronics',
      parent: electronics,
      sortOrder: 0,
    );

    final laptops = createCategoryEntity(
      id: 'cat-laptops',
      name: 'Laptops',
      slug: 'laptops',
      parentId: 'cat-electronics',
      parent: electronics,
      sortOrder: 1,
    );

    // Clothing subcategories
    final mens = createCategoryEntity(
      id: 'cat-mens',
      name: 'Mens',
      slug: 'mens',
      parentId: 'cat-clothing',
      parent: clothing,
      sortOrder: 0,
    );

    final womens = createCategoryEntity(
      id: 'cat-womens',
      name: 'Womens',
      slug: 'womens',
      parentId: 'cat-clothing',
      parent: clothing,
      sortOrder: 1,
    );

    return [electronics, clothing, phones, laptops, mens, womens];
  }

  /// Creates an unsynced category (for offline testing)
  static Category createUnsyncedCategory({
    String id = 'cat-unsynced',
  }) {
    return createCategoryEntity(
      id: id,
      name: 'Unsynced Category',
      slug: 'unsynced-category',
      isSynced: false,
    );
  }

  /// Creates a category with many products
  static Category createCategoryWithManyProducts({
    String id = 'cat-popular',
    int productsCount = 500,
  }) {
    return createCategoryEntity(
      id: id,
      name: 'Popular Category',
      slug: 'popular-category',
      productsCount: productsCount,
    );
  }

  /// Creates an empty category (no products)
  static Category createEmptyCategory({
    String id = 'cat-empty',
  }) {
    return createCategoryEntity(
      id: id,
      name: 'Empty Category',
      slug: 'empty-category',
      productsCount: 0,
    );
  }

  // ============================================================================
  // BATCH CREATION HELPERS
  // ============================================================================

  /// Creates a mix of categories with different statuses
  static List<Category> createMixedStatusCategories() {
    return [
      createCategoryEntity(id: 'cat-001', status: CategoryStatus.active),
      createCategoryEntity(id: 'cat-002', status: CategoryStatus.active),
      createInactiveCategory(id: 'cat-003'),
      createCategoryEntity(id: 'cat-004', status: CategoryStatus.active),
    ];
  }

  /// Creates categories with varying product counts
  static List<Category> createCategoriesWithVaryingProductCounts() {
    return [
      createEmptyCategory(id: 'cat-001'),
      createCategoryEntity(id: 'cat-002', productsCount: 10),
      createCategoryEntity(id: 'cat-003', productsCount: 50),
      createCategoryWithManyProducts(id: 'cat-004', productsCount: 200),
    ];
  }
}
