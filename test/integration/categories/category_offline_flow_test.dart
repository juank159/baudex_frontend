// test/integration/categories/category_offline_flow_test.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/categories/data/models/isar/isar_category.dart';
import 'package:baudex_desktop/features/categories/data/repositories/category_offline_repository.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_isar.dart';
import '../../fixtures/category_fixtures.dart';

void main() {
  late CategoryOfflineRepository repository;
  late MockIsar mockIsar;
  late MockIsarDatabase mockIsarDatabase;

  setUp(() {
    mockIsar = MockIsar();
    mockIsarDatabase = MockIsarDatabase(mockIsar);
    final dynamic db = mockIsarDatabase;
    repository = CategoryOfflineRepository(database: db);
  });

  tearDown(() async {
    await mockIsar.clear();
    await mockIsar.close();
  });

  group('Category Offline Flow Integration', () {
    test(
      'create multiple categories offline',
      () async {
        // Create 10 categories offline
        final categoryIds = <String>[];

        for (int i = 1; i <= 10; i++) {
          final result = await repository.createCategory(
            name: 'Offline Category $i',
            slug: 'offline-category-$i',
            description: 'Description for offline category $i',
          );

          result.fold(
            (failure) => fail('Create should succeed'),
            (category) => categoryIds.add(category.id),
          );
        }

        // Verify all created with offline IDs
        expect(categoryIds.length, 10);
        expect(categoryIds.every((id) => id.startsWith('cat_')), true);

        // Verify in ISAR
        final isarCategories = await mockIsar.isarCategorys.where().findAll();
        expect(isarCategories.length, 10);
        expect(isarCategories.every((c) => !c.isSynced), true);
      },
    );

    test(
      'search categories offline',
      () async {
        // Create categories with different names
        await repository.createCategory(
          name: 'Electronics',
          slug: 'electronics',
          description: 'Electronic devices',
        );

        await repository.createCategory(
          name: 'Electronic Books',
          slug: 'electronic-books',
          description: 'Digital books',
        );

        await repository.createCategory(
          name: 'Food & Beverages',
          slug: 'food-beverages',
          description: 'Food items',
        );

        // Search for "Electronic"
        final searchResult = await repository.searchCategories('Electronic');

        searchResult.fold(
          (failure) => fail('Search should succeed'),
          (categories) {
            expect(categories.length, 2);
            expect(categories.every((c) => c.name.contains('Electronic')), true);
          },
        );
      },
    );

    test(
      'filter categories by status offline',
      () async {
        // Create active categories
        await repository.createCategory(
          name: 'Active Category 1',
          slug: 'active-category-1',
          status: CategoryStatus.active,
        );

        await repository.createCategory(
          name: 'Active Category 2',
          slug: 'active-category-2',
          status: CategoryStatus.active,
        );

        // Create inactive category manually in ISAR
        final inactiveCategory = IsarCategory()
          ..serverId = 'cat_offline_inactive'
          ..name = 'Inactive Category'
          ..slug = 'inactive-category'
          ..status = IsarCategoryStatus.inactive
          ..sortOrder = 0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..isSynced = false;

        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(inactiveCategory);
        });

        // Filter by active status
        final result = await repository.getCategories(
          status: CategoryStatus.active,
        );

        result.fold(
          (failure) => fail('Filter should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
            expect(
              paginatedResult.data.every((c) => c.status == CategoryStatus.active),
              true,
            );
          },
        );
      },
    );

    test(
      'filter categories by parent offline',
      () async {
        // Create parent category
        final parentResult = await repository.createCategory(
          name: 'Parent Category',
          slug: 'parent-category',
        );

        String? parentId;
        parentResult.fold(
          (failure) => fail('Parent create should succeed'),
          (category) => parentId = category.id,
        );

        // Create child categories
        await repository.createCategory(
          name: 'Child Category 1',
          slug: 'child-category-1',
          parentId: parentId,
        );

        await repository.createCategory(
          name: 'Child Category 2',
          slug: 'child-category-2',
          parentId: parentId,
        );

        await repository.createCategory(
          name: 'Standalone Category',
          slug: 'standalone-category',
        );

        // Filter by parent
        final result = await repository.getCategories(
          parentId: parentId,
        );

        result.fold(
          (failure) => fail('Filter should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
            expect(
              paginatedResult.data.every((c) => c.parentId == parentId),
              true,
            );
          },
        );
      },
    );

    test(
      'paginate categories offline',
      () async {
        // Create 25 categories
        for (int i = 1; i <= 25; i++) {
          await repository.createCategory(
            name: 'Category $i',
            slug: 'category-${i.toString().padLeft(3, '0')}',
          );
        }

        // Get page 1 (limit 10)
        final page1Result = await repository.getCategories(
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
        final page2Result = await repository.getCategories(
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
        final page3Result = await repository.getCategories(
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
      'get category tree offline',
      () async {
        // Create hierarchical categories
        final electronics = await repository.createCategory(
          name: 'Electronics',
          slug: 'electronics',
          sortOrder: 1,
        );

        String? electronicsId;
        electronics.fold(
          (failure) => fail('Create electronics should succeed'),
          (category) => electronicsId = category.id,
        );

        await repository.createCategory(
          name: 'Computers',
          slug: 'computers',
          parentId: electronicsId,
          sortOrder: 1,
        );

        await repository.createCategory(
          name: 'Phones',
          slug: 'phones',
          parentId: electronicsId,
          sortOrder: 2,
        );

        final books = await repository.createCategory(
          name: 'Books',
          slug: 'books',
          sortOrder: 2,
        );

        // Get tree
        final treeResult = await repository.getCategoryTree();

        treeResult.fold(
          (failure) => fail('Get tree should succeed'),
          (tree) {
            expect(tree.length, 2); // 2 root categories
            expect(tree[0].children?.length ?? 0, 2); // Electronics has 2 children
            expect(tree[1].children?.length ?? 0, 0); // Books has no children
          },
        );
      },
    );

    test(
      'delete category offline',
      () async {
        // Create category
        final createResult = await repository.createCategory(
          name: 'Category to Delete',
          slug: 'category-to-delete',
        );

        String? categoryId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (category) => categoryId = category.id,
        );

        // Delete
        final deleteResult = await repository.deleteCategory(categoryId!);

        expect(deleteResult.isRight(), true);

        // Verify soft deleted in ISAR
        final deletedCategory = await mockIsar.isarCategorys
            .filter()
            .serverIdEqualTo(categoryId!)
            .findFirst();

        expect(deletedCategory!.deletedAt, isNotNull);

        // Should not appear in normal queries
        final getResult = await repository.getCategoryById(categoryId!);
        expect(getResult.isLeft(), true);
      },
    );

    test(
      'get category stats offline',
      () async {
        // Create categories with different statuses
        await repository.createCategory(
          name: 'Active Category 1',
          slug: 'active-1',
          status: CategoryStatus.active,
        );

        await repository.createCategory(
          name: 'Active Category 2',
          slug: 'active-2',
          status: CategoryStatus.active,
        );

        final inactiveCategory = IsarCategory()
          ..serverId = 'cat_inactive'
          ..name = 'Inactive Category'
          ..slug = 'inactive'
          ..status = IsarCategoryStatus.inactive
          ..sortOrder = 0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..isSynced = false;

        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(inactiveCategory);
        });

        // Get stats
        final statsResult = await repository.getCategoryStats();

        statsResult.fold(
          (failure) => fail('Get stats should succeed'),
          (stats) {
            expect(stats.total, 3);
            expect(stats.active, 2);
            expect(stats.inactive, 1);
          },
        );
      },
    );

    test(
      'complete offline workflow with all operations',
      () async {
        // Simulate complete offline session

        // 1. Create categories
        final categoryIds = <String>[];
        for (int i = 1; i <= 5; i++) {
          final result = await repository.createCategory(
            name: 'Workflow Category $i',
            slug: 'workflow-category-$i',
            description: 'Workflow description $i',
          );

          result.fold(
            (failure) => fail('Create should succeed'),
            (category) => categoryIds.add(category.id),
          );
        }

        // 2. Search
        final searchResult = await repository.searchCategories('Workflow');
        searchResult.fold(
          (failure) => fail('Search should succeed'),
          (categories) => expect(categories.length, 5),
        );

        // 3. Update some categories
        await repository.updateCategory(
          id: categoryIds[0],
          name: 'Updated Workflow Category 1',
        );

        await repository.updateCategoryStatus(
          id: categoryIds[1],
          status: CategoryStatus.inactive,
        );

        // 4. Filter by status
        final activeResult = await repository.getCategories(
          status: CategoryStatus.active,
        );

        activeResult.fold(
          (failure) => fail('Filter should succeed'),
          (paginatedResult) => expect(paginatedResult.data.length, 4),
        );

        // 5. Paginate
        final paginatedResult = await repository.getCategories(
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

        // 6. Delete a category
        await repository.deleteCategory(categoryIds[4]);

        // Verify final state
        final finalCategories = await mockIsar.isarCategorys
            .filter()
            .deletedAtIsNull()
            .findAll();

        expect(finalCategories.length, 4); // 5 created - 1 deleted

        // All should be unsynced
        expect(finalCategories.every((c) => !c.isSynced), true);
      },
    );
  });
}
