// test/unit/data/repositories/category_offline_repository_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/categories/data/models/isar/isar_category.dart';
import 'package:baudex_desktop/features/categories/data/repositories/category_offline_repository.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/mock_isar.dart';
import '../../../fixtures/category_fixtures.dart';

void main() {
  late CategoryOfflineRepository repository;
  late MockIsar mockIsar;
  late MockIsarDatabase mockIsarDatabase;

  setUp(() {
    mockIsar = MockIsar();
    mockIsarDatabase = MockIsarDatabase(mockIsar);
    repository = CategoryOfflineRepository(database: mockIsarDatabase);
  });

  tearDown(() async {
    await mockIsar.clear();
    await mockIsar.close();
  });

  group('CategoryOfflineRepository - getCategories', () {
    test(
      'should return paginated categories from ISAR',
      () async {
        // Arrange
        final categories = CategoryFixtures.createCategoryEntityList(10);
        for (final category in categories) {
          final isarCategory = IsarCategory.fromEntity(category);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCategorys.put(isarCategory);
          });
        }

        // Act
        final result = await repository.getCategories(page: 1, limit: 5);

        // Assert
        expect(result.isRight(), true, reason: result.fold((l) => 'Error: $l', (r) => 'Success'));
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 5);
            expect(paginatedResult.meta.page, 1);
            expect(paginatedResult.meta.totalItems, 10);
            expect(paginatedResult.meta.totalPages, 2);
            expect(paginatedResult.meta.hasNextPage, true);
          },
        );
      },
    );

    test(
      'should filter categories by status',
      () async {
        // Arrange
        final activeCategories = [
          CategoryFixtures.createCategoryEntity(id: 'cat-001', status: CategoryStatus.active),
          CategoryFixtures.createCategoryEntity(id: 'cat-002', status: CategoryStatus.active),
        ];
        final inactiveCategory = CategoryFixtures.createInactiveCategory(id: 'cat-003');

        for (final category in [...activeCategories, inactiveCategory]) {
          final isarCategory = IsarCategory.fromEntity(category);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCategorys.put(isarCategory);
          });
        }

        // Act
        final result = await repository.getCategories(
          status: CategoryStatus.active,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
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
      'should filter categories by parentId',
      () async {
        // Arrange
        final categories = [
          CategoryFixtures.createCategoryEntity(id: 'cat-001', parentId: null),
          CategoryFixtures.createCategoryEntity(id: 'cat-002', parentId: 'cat-001'),
          CategoryFixtures.createCategoryEntity(id: 'cat-003', parentId: 'cat-001'),
        ];

        for (final category in categories) {
          final isarCategory = IsarCategory.fromEntity(category);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCategorys.put(isarCategory);
          });
        }

        // Act
        final result = await repository.getCategories(
          parentId: 'cat-001',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
            expect(
              paginatedResult.data.every((c) => c.parentId == 'cat-001'),
              true,
            );
          },
        );
      },
    );

    test(
      'should filter categories by onlyParents',
      () async {
        // Arrange
        final categories = [
          CategoryFixtures.createCategoryEntity(id: 'cat-001', parentId: null),
          CategoryFixtures.createCategoryEntity(id: 'cat-002', parentId: null),
          CategoryFixtures.createCategoryEntity(id: 'cat-003', parentId: 'cat-001'),
        ];

        for (final category in categories) {
          final isarCategory = IsarCategory.fromEntity(category);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCategorys.put(isarCategory);
          });
        }

        // Act
        final result = await repository.getCategories(
          onlyParents: true,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
            expect(
              paginatedResult.data.every((c) => c.parentId == null),
              true,
            );
          },
        );
      },
    );

    test(
      'should search categories by name or description',
      () async {
        // Arrange
        final categories = [
          CategoryFixtures.createCategoryEntity(
            id: 'cat-001',
            name: 'Electronics',
            description: 'Electronic devices',
          ),
          CategoryFixtures.createCategoryEntity(
            id: 'cat-002',
            name: 'Books',
            description: 'Physical and digital books',
          ),
          CategoryFixtures.createCategoryEntity(
            id: 'cat-003',
            name: 'Electronic Books',
            description: 'E-books only',
          ),
        ];

        for (final category in categories) {
          final isarCategory = IsarCategory.fromEntity(category);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCategorys.put(isarCategory);
          });
        }

        // Act
        final result = await repository.getCategories(
          search: 'Electronic',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
          },
        );
      },
    );

    test(
      'should sort categories by name ascending',
      () async {
        // Arrange
        final categories = [
          CategoryFixtures.createCategoryEntity(id: 'cat-001', name: 'Zebra'),
          CategoryFixtures.createCategoryEntity(id: 'cat-002', name: 'Apple'),
          CategoryFixtures.createCategoryEntity(id: 'cat-003', name: 'Mango'),
        ];

        for (final category in categories) {
          final isarCategory = IsarCategory.fromEntity(category);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCategorys.put(isarCategory);
          });
        }

        // Act
        final result = await repository.getCategories(
          sortBy: 'name',
          sortOrder: 'asc',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data[0].name, 'Apple');
            expect(paginatedResult.data[1].name, 'Mango');
            expect(paginatedResult.data[2].name, 'Zebra');
          },
        );
      },
    );

    test(
      'should paginate results correctly',
      () async {
        // Arrange
        final categories = CategoryFixtures.createCategoryEntityList(25);
        for (final category in categories) {
          final isarCategory = IsarCategory.fromEntity(category);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCategorys.put(isarCategory);
          });
        }

        // Act - Get page 2 with limit 10
        final result = await repository.getCategories(page: 2, limit: 10);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 10);
            expect(paginatedResult.meta.page, 2);
            expect(paginatedResult.meta.totalItems, 25);
            expect(paginatedResult.meta.totalPages, 3);
            expect(paginatedResult.meta.hasNextPage, true);
            expect(paginatedResult.meta.hasPreviousPage, true);
          },
        );
      },
    );
  });

  group('CategoryOfflineRepository - getCategoryById', () {
    test(
      'should return category when found in ISAR',
      () async {
        // Arrange
        const tCategoryId = 'cat-001';
        final category = CategoryFixtures.createCategoryEntity(id: tCategoryId);
        final isarCategory = IsarCategory.fromEntity(category);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // Act
        final result = await repository.getCategoryById(tCategoryId);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (c) {
            expect(c.id, tCategoryId);
            expect(c.name, category.name);
          },
        );
      },
    );

    test(
      'should return CacheFailure when category not in ISAR',
      () async {
        // Act
        final result = await repository.getCategoryById('non-existent-id');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should not return deleted categories',
      () async {
        // Arrange
        const tCategoryId = 'cat-001';
        final category = CategoryFixtures.createCategoryEntity(id: tCategoryId);
        final isarCategory = IsarCategory.fromEntity(category);
        isarCategory.deletedAt = DateTime.now();
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // Act
        final result = await repository.getCategoryById(tCategoryId);

        // Assert
        expect(result.isLeft(), true);
      },
    );
  });

  group('CategoryOfflineRepository - createCategory', () {
    test(
      'should create category with offline ID',
      () async {
        // Act
        final result = await repository.createCategory(
          name: 'New Category',
          slug: 'new-category',
          description: 'New description',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (category) {
            expect(category.id.startsWith('cat_'), true);
            expect(category.name, 'New Category');
            expect(category.slug, 'new-category');
          },
        );

        // Verify it's in ISAR
        final isarCategories = await mockIsar.isarCategorys.where().findAll();
        expect(isarCategories.length, 1);
        expect(isarCategories.first.isSynced, false);
      },
    );

    test(
      'should mark category as unsynced',
      () async {
        // Act
        await repository.createCategory(
          name: 'New Category',
          slug: 'new-category',
        );

        // Assert
        final isarCategories = await mockIsar.isarCategorys.where().findAll();
        expect(isarCategories.first.isSynced, false);
      },
    );
  });

  group('CategoryOfflineRepository - updateCategory', () {
    test(
      'should update category in ISAR',
      () async {
        // Arrange
        const tCategoryId = 'cat-001';
        final category = CategoryFixtures.createCategoryEntity(id: tCategoryId);
        final isarCategory = IsarCategory.fromEntity(category);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // Act
        final result = await repository.updateCategory(
          id: tCategoryId,
          name: 'Updated Name',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (c) {
            expect(c.name, 'Updated Name');
          },
        );

        // Verify in ISAR
        final updated = await mockIsar.isarCategorys
            .filter()
            .serverIdEqualTo(tCategoryId)
            .findFirst();
        expect(updated!.name, 'Updated Name');
      },
    );

    test(
      'should mark category as unsynced after update',
      () async {
        // Arrange
        const tCategoryId = 'cat-001';
        final category = CategoryFixtures.createCategoryEntity(id: tCategoryId);
        final isarCategory = IsarCategory.fromEntity(category);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // Act
        await repository.updateCategory(
          id: tCategoryId,
          name: 'Updated Name',
        );

        // Assert
        final updated = await mockIsar.isarCategorys
            .filter()
            .serverIdEqualTo(tCategoryId)
            .findFirst();
        expect(updated!.isSynced, false);
      },
    );
  });

  group('CategoryOfflineRepository - deleteCategory', () {
    test(
      'should soft delete category in ISAR',
      () async {
        // Arrange
        const tCategoryId = 'cat-001';
        final category = CategoryFixtures.createCategoryEntity(id: tCategoryId);
        final isarCategory = IsarCategory.fromEntity(category);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // Act
        final result = await repository.deleteCategory(tCategoryId);

        // Assert
        expect(result.isRight(), true);

        // Verify soft delete
        final deleted = await mockIsar.isarCategorys
            .filter()
            .serverIdEqualTo(tCategoryId)
            .findFirst();
        expect(deleted!.deletedAt, isNotNull);
      },
    );
  });

  group('CategoryOfflineRepository - getCategoryBySlug', () {
    test(
      'should return category when slug found in ISAR',
      () async {
        // Arrange
        const tSlug = 'electronics';
        final category = CategoryFixtures.createCategoryEntity(
          id: 'cat-001',
          slug: tSlug,
        );
        final isarCategory = IsarCategory.fromEntity(category);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // Act
        final result = await repository.getCategoryBySlug(tSlug);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (c) {
            expect(c.slug, tSlug);
            expect(c.name, category.name);
          },
        );
      },
    );

    test(
      'should return CacheFailure when slug not found',
      () async {
        // Act
        final result = await repository.getCategoryBySlug('non-existent-slug');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('CategoryOfflineRepository - getCategoryTree', () {
    test(
      'should return hierarchical category tree',
      () async {
        // Arrange
        final parent1 = CategoryFixtures.createCategoryEntity(
          id: 'cat-001',
          name: 'Parent 1',
          parentId: null,
          sortOrder: 1,
        );
        final child1 = CategoryFixtures.createCategoryEntity(
          id: 'cat-002',
          name: 'Child 1',
          parentId: 'cat-001',
          sortOrder: 1,
        );
        final parent2 = CategoryFixtures.createCategoryEntity(
          id: 'cat-003',
          name: 'Parent 2',
          parentId: null,
          sortOrder: 2,
        );

        for (final category in [parent1, child1, parent2]) {
          final isarCategory = IsarCategory.fromEntity(category);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCategorys.put(isarCategory);
          });
        }

        // Act
        final result = await repository.getCategoryTree();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (tree) {
            expect(tree.length, 2); // 2 root categories
            expect(tree[0].id, 'cat-001');
            expect(tree[0].children?.length ?? 0, 1); // 1 child
            expect(tree[0].children?[0].id, 'cat-002');
            expect(tree[1].id, 'cat-003');
            expect(tree[1].children?.length ?? 0, 0); // No children
          },
        );
      },
    );
  });

  group('CategoryOfflineRepository - getCategoryStats', () {
    test(
      'should return category statistics',
      () async {
        // Arrange
        final activeCategories = [
          CategoryFixtures.createCategoryEntity(id: 'cat-001', status: CategoryStatus.active),
          CategoryFixtures.createCategoryEntity(id: 'cat-002', status: CategoryStatus.active),
        ];
        final inactiveCategory = CategoryFixtures.createInactiveCategory(id: 'cat-003');
        final deletedCategory = CategoryFixtures.createCategoryEntity(id: 'cat-004');
        final deletedIsarCategory = IsarCategory.fromEntity(deletedCategory);
        deletedIsarCategory.deletedAt = DateTime.now();

        for (final category in [...activeCategories, inactiveCategory]) {
          final isarCategory = IsarCategory.fromEntity(category);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCategorys.put(isarCategory);
          });
        }
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(deletedIsarCategory);
        });

        // Act
        final result = await repository.getCategoryStats();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (stats) {
            expect(stats.total, 3); // Excluding deleted
            expect(stats.active, 2);
            expect(stats.inactive, 1);
            expect(stats.deleted, 1);
          },
        );
      },
    );
  });

  group('CategoryOfflineRepository - searchCategories', () {
    test(
      'should search categories by term',
      () async {
        // Arrange
        final categories = [
          CategoryFixtures.createCategoryEntity(id: 'cat-001', name: 'Electronics'),
          CategoryFixtures.createCategoryEntity(id: 'cat-002', name: 'Electronic Books'),
          CategoryFixtures.createCategoryEntity(id: 'cat-003', name: 'Food'),
        ];

        for (final category in categories) {
          final isarCategory = IsarCategory.fromEntity(category);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCategorys.put(isarCategory);
          });
        }

        // Act
        final result = await repository.searchCategories('Electronic');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (categories) => expect(categories.length, 2),
        );
      },
    );
  });

  group('CategoryOfflineRepository - updateCategoryStatus', () {
    test(
      'should update category status',
      () async {
        // Arrange
        const tCategoryId = 'cat-001';
        final category = CategoryFixtures.createCategoryEntity(
          id: tCategoryId,
          status: CategoryStatus.active,
        );
        final isarCategory = IsarCategory.fromEntity(category);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // Act
        final result = await repository.updateCategoryStatus(
          id: tCategoryId,
          status: CategoryStatus.inactive,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (c) => expect(c.status, CategoryStatus.inactive),
        );

        // Verify in ISAR
        final updated = await mockIsar.isarCategorys
            .filter()
            .serverIdEqualTo(tCategoryId)
            .findFirst();
        expect(updated!.status, IsarCategoryStatus.inactive);
      },
    );
  });

  group('CategoryOfflineRepository - restoreCategory', () {
    test(
      'should restore soft-deleted category',
      () async {
        // Arrange
        const tCategoryId = 'cat-001';
        final category = CategoryFixtures.createCategoryEntity(id: tCategoryId);
        final isarCategory = IsarCategory.fromEntity(category);
        isarCategory.deletedAt = DateTime.now();
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // Act
        final result = await repository.restoreCategory(tCategoryId);

        // Assert
        expect(result.isRight(), true);

        // Verify restoration
        final restored = await mockIsar.isarCategorys
            .filter()
            .serverIdEqualTo(tCategoryId)
            .findFirst();
        expect(restored!.deletedAt, isNull);
      },
    );
  });

  group('CategoryOfflineRepository - isSlugAvailable', () {
    test(
      'should return false when slug exists',
      () async {
        // Arrange
        const tSlug = 'electronics';
        final category = CategoryFixtures.createCategoryEntity(
          id: 'cat-001',
          slug: tSlug,
        );
        final isarCategory = IsarCategory.fromEntity(category);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // Act
        final result = await repository.isSlugAvailable(tSlug);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (isAvailable) => expect(isAvailable, false),
        );
      },
    );

    test(
      'should return true when slug does not exist',
      () async {
        // Act
        final result = await repository.isSlugAvailable('unique-slug');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (isAvailable) => expect(isAvailable, true),
        );
      },
    );

    test(
      'should exclude specific category when checking slug',
      () async {
        // Arrange
        const tSlug = 'electronics';
        const tCategoryId = 'cat-001';
        final category = CategoryFixtures.createCategoryEntity(
          id: tCategoryId,
          slug: tSlug,
        );
        final isarCategory = IsarCategory.fromEntity(category);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // Act - Check same slug but exclude the category itself
        final result = await repository.isSlugAvailable(
          tSlug,
          excludeId: tCategoryId,
        );

        // Assert - Should be available since we exclude the category
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (isAvailable) => expect(isAvailable, true),
        );
      },
    );
  });

  group('CategoryOfflineRepository - generateUniqueSlug', () {
    test(
      'should generate slug from name',
      () async {
        // Act
        final result = await repository.generateUniqueSlug('Electronics & Gadgets');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (slug) {
            expect(slug, 'electronics-gadgets');
          },
        );
      },
    );

    test(
      'should append number if slug exists',
      () async {
        // Arrange
        const tSlug = 'electronics';
        final category = CategoryFixtures.createCategoryEntity(
          id: 'cat-001',
          slug: tSlug,
        );
        final isarCategory = IsarCategory.fromEntity(category);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // Act
        final result = await repository.generateUniqueSlug('Electronics');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (slug) {
            expect(slug.startsWith('electronics-'), true);
          },
        );
      },
    );
  });
}
