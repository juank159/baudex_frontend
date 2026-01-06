// test/unit/data/models/isar_category_test.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/categories/data/models/isar/isar_category.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/category_fixtures.dart';

void main() {
  group('IsarCategory', () {
    final tCategory = CategoryFixtures.createCategoryEntity();

    group('fromEntity', () {
      test('should convert Category entity to IsarCategory', () {
        // Act
        final result = IsarCategory.fromEntity(tCategory);

        // Assert
        expect(result, isA<IsarCategory>());
        expect(result.serverId, tCategory.id);
        expect(result.name, tCategory.name);
        expect(result.slug, tCategory.slug);
        expect(result.sortOrder, tCategory.sortOrder);
        expect(result.parentId, tCategory.parentId);
      });

      test('should map CategoryStatus enum to IsarCategoryStatus', () {
        // Arrange
        final activeCategory = CategoryFixtures.createCategoryEntity(
          status: CategoryStatus.active,
        );

        // Act
        final result = IsarCategory.fromEntity(activeCategory);

        // Assert
        expect(result.status, IsarCategoryStatus.active);
      });

      test('should map inactive CategoryStatus to IsarCategoryStatus', () {
        // Arrange
        final inactiveCategory = CategoryFixtures.createInactiveCategory();

        // Act
        final result = IsarCategory.fromEntity(inactiveCategory);

        // Assert
        expect(result.status, IsarCategoryStatus.inactive);
      });

      test('should preserve isSynced from entity', () {
        // Act
        final result = IsarCategory.fromEntity(tCategory);

        // Assert
        expect(result.isSynced, tCategory.isSynced);
        expect(result.lastSyncAt, tCategory.lastSyncAt);
      });

      test('should handle null optional fields', () {
        // Arrange
        final categoryWithNulls = CategoryFixtures.createCategoryEntity(
          description: null,
          image: null,
          parentId: null,
        );

        // Act
        final result = IsarCategory.fromEntity(categoryWithNulls);

        // Assert
        expect(result.description, isNull);
        expect(result.image, isNull);
        expect(result.parentId, isNull);
      });

      test('should handle null productsCount', () {
        // Arrange
        final categoryWithoutProductsCount = CategoryFixtures.createCategoryEntity(
          productsCount: null,
        );

        // Act
        final result = IsarCategory.fromEntity(categoryWithoutProductsCount);

        // Assert
        expect(result.productsCount, isNull);
      });

      test('should convert parent category', () {
        // Arrange
        final childCategory = CategoryFixtures.createChildCategory();

        // Act
        final result = IsarCategory.fromEntity(childCategory);

        // Assert
        expect(result.parentId, childCategory.parentId);
      });

      test('should handle products count correctly', () {
        // Arrange
        final categoryWithProducts = CategoryFixtures.createCategoryWithManyProducts(
          productsCount: 500,
        );

        // Act
        final result = IsarCategory.fromEntity(categoryWithProducts);

        // Assert
        expect(result.productsCount, 500);
      });
    });

    group('toEntity', () {
      test('should convert IsarCategory to Category entity', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);

        // Act
        final result = isarCategory.toEntity();

        // Assert
        expect(result, isA<Category>());
        expect(result.id, isarCategory.serverId);
        expect(result.name, isarCategory.name);
        expect(result.slug, isarCategory.slug);
      });

      test('should map IsarCategoryStatus to CategoryStatus enum', () {
        // Arrange
        final activeCategory = CategoryFixtures.createCategoryEntity(
          status: CategoryStatus.active,
        );
        final isarCategory = IsarCategory.fromEntity(activeCategory);

        // Act
        final result = isarCategory.toEntity();

        // Assert
        expect(result.status, CategoryStatus.active);
      });

      test('should map inactive IsarCategoryStatus to CategoryStatus enum', () {
        // Arrange
        final inactiveCategory = CategoryFixtures.createInactiveCategory();
        final isarCategory = IsarCategory.fromEntity(inactiveCategory);

        // Act
        final result = isarCategory.toEntity();

        // Assert
        expect(result.status, CategoryStatus.inactive);
      });

      test('should preserve sync flags', () {
        // Arrange
        final category = CategoryFixtures.createCategoryEntity(isSynced: true);
        final isarCategory = IsarCategory.fromEntity(category);

        // Act
        final result = isarCategory.toEntity();

        // Assert
        expect(result.isSynced, true);
        expect(result.lastSyncAt, category.lastSyncAt);
      });

      test('should handle null optional fields', () {
        // Arrange
        final categoryWithNulls = CategoryFixtures.createCategoryEntity(
          description: null,
          image: null,
          parentId: null,
        );
        final isarCategory = IsarCategory.fromEntity(categoryWithNulls);

        // Act
        final result = isarCategory.toEntity();

        // Assert
        expect(result.description, isNull);
        expect(result.image, isNull);
        expect(result.parentId, isNull);
      });
    });

    group('fromModel', () {
      test('should create IsarCategory from CategoryModel', () {
        // Arrange
        final category = CategoryFixtures.createCategoryEntity();

        // Act
        final result = IsarCategory.fromModel(category);

        // Assert
        expect(result, isA<IsarCategory>());
        expect(result.serverId, category.id);
        expect(result.name, category.name);
        expect(result.slug, category.slug);
      });

      test('should mark as synced when created from model', () {
        // Arrange
        final category = CategoryFixtures.createCategoryEntity();

        // Act
        final result = IsarCategory.fromModel(category);

        // Assert
        expect(result.isSynced, true);
        expect(result.lastSyncAt, isNotNull);
      });

      test('should handle all model fields correctly', () {
        // Arrange
        final category = CategoryFixtures.createParentCategoryWithChildren();

        // Act
        final result = IsarCategory.fromModel(category);

        // Assert
        expect(result.serverId, category.id);
        expect(result.name, category.name);
        expect(result.description, category.description);
        expect(result.slug, category.slug);
        expect(result.sortOrder, category.sortOrder);
        expect(result.productsCount, category.productsCount);
      });
    });

    group('utility methods', () {
      test('isDeleted should return true when deletedAt is set', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);
        isarCategory.deletedAt = DateTime.now();

        // Act & Assert
        expect(isarCategory.isDeleted, true);
      });

      test('isDeleted should return false when deletedAt is null', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);

        // Act & Assert
        expect(isarCategory.isDeleted, false);
      });

      test('isActive should return true when status is active and not deleted', () {
        // Arrange
        final activeCategory = CategoryFixtures.createCategoryEntity(
          status: CategoryStatus.active,
        );
        final isarCategory = IsarCategory.fromEntity(activeCategory);

        // Act & Assert
        expect(isarCategory.isActive, true);
      });

      test('isActive should return false when deleted', () {
        // Arrange
        final activeCategory = CategoryFixtures.createCategoryEntity(
          status: CategoryStatus.active,
        );
        final isarCategory = IsarCategory.fromEntity(activeCategory);
        isarCategory.deletedAt = DateTime.now();

        // Act & Assert
        expect(isarCategory.isActive, false);
      });

      test('isActive should return false when status is inactive', () {
        // Arrange
        final inactiveCategory = CategoryFixtures.createInactiveCategory();
        final isarCategory = IsarCategory.fromEntity(inactiveCategory);

        // Act & Assert
        expect(isarCategory.isActive, false);
      });

      test('needsSync should return true when isSynced is false', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);
        isarCategory.isSynced = false;

        // Act & Assert
        expect(isarCategory.needsSync, true);
      });

      test('needsSync should return false when isSynced is true', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);
        isarCategory.isSynced = true;

        // Act & Assert
        expect(isarCategory.needsSync, false);
      });

      test('isRoot should return true when parentId is null', () {
        // Arrange
        final rootCategory = CategoryFixtures.createCategoryEntity(parentId: null);
        final isarCategory = IsarCategory.fromEntity(rootCategory);

        // Act & Assert
        expect(isarCategory.isRoot, true);
      });

      test('isRoot should return false when parentId is set', () {
        // Arrange
        final childCategory = CategoryFixtures.createChildCategory();
        final isarCategory = IsarCategory.fromEntity(childCategory);

        // Act & Assert
        expect(isarCategory.isRoot, false);
      });

      test('hasProducts should return true when productsCount > 0', () {
        // Arrange
        final categoryWithProducts = CategoryFixtures.createCategoryWithManyProducts(
          productsCount: 100,
        );
        final isarCategory = IsarCategory.fromEntity(categoryWithProducts);

        // Act & Assert
        expect(isarCategory.hasProducts, true);
      });

      test('hasProducts should return false when productsCount is 0', () {
        // Arrange
        final emptyCategory = CategoryFixtures.createEmptyCategory();
        final isarCategory = IsarCategory.fromEntity(emptyCategory);

        // Act & Assert
        expect(isarCategory.hasProducts, false);
      });

      test('hasProducts should return false when productsCount is null', () {
        // Arrange
        final categoryWithNullCount = CategoryFixtures.createCategoryEntity(
          productsCount: null,
        );
        final isarCategory = IsarCategory.fromEntity(categoryWithNullCount);

        // Act & Assert
        expect(isarCategory.hasProducts, false);
      });
    });

    group('sync methods', () {
      test('markAsUnsynced should set isSynced to false', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);
        isarCategory.isSynced = true;

        // Act
        isarCategory.markAsUnsynced();

        // Assert
        expect(isarCategory.isSynced, false);
      });

      test('markAsUnsynced should update updatedAt timestamp', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);
        final oldUpdatedAt = isarCategory.updatedAt;

        // Wait a tiny bit to ensure timestamp difference
        Future.delayed(const Duration(milliseconds: 10));

        // Act
        isarCategory.markAsUnsynced();

        // Assert
        expect(isarCategory.updatedAt.isAfter(oldUpdatedAt) ||
               isarCategory.updatedAt.isAtSameMomentAs(oldUpdatedAt), true);
      });

      test('markAsSynced should set isSynced to true', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);
        isarCategory.isSynced = false;

        // Act
        isarCategory.markAsSynced();

        // Assert
        expect(isarCategory.isSynced, true);
      });

      test('markAsSynced should update lastSyncAt timestamp', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);
        final oldLastSyncAt = isarCategory.lastSyncAt;

        // Act
        isarCategory.markAsSynced();

        // Assert
        expect(isarCategory.lastSyncAt, isNotNull);
        if (oldLastSyncAt != null) {
          expect(isarCategory.lastSyncAt!.isAfter(oldLastSyncAt) ||
                 isarCategory.lastSyncAt!.isAtSameMomentAs(oldLastSyncAt), true);
        }
      });
    });

    group('soft delete', () {
      test('softDelete should set deletedAt timestamp', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);

        // Act
        isarCategory.softDelete();

        // Assert
        expect(isarCategory.deletedAt, isNotNull);
        expect(isarCategory.isDeleted, true);
      });

      test('softDelete should mark as unsynced', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);
        isarCategory.isSynced = true;

        // Act
        isarCategory.softDelete();

        // Assert
        expect(isarCategory.isSynced, false);
      });
    });

    group('updateProductCount', () {
      test('should update productsCount', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);

        // Act
        isarCategory.updateProductCount(150);

        // Assert
        expect(isarCategory.productsCount, 150);
      });

      test('should mark as unsynced when updating product count', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);
        isarCategory.isSynced = true;

        // Act
        isarCategory.updateProductCount(200);

        // Assert
        expect(isarCategory.isSynced, false);
      });
    });

    group('updateFromModel', () {
      test('should update all fields from model', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);
        final updatedCategory = CategoryFixtures.createCategoryEntity(
          id: tCategory.id,
          name: 'Updated Name',
          slug: 'updated-slug',
          description: 'Updated description',
          sortOrder: 10,
        );

        // Act
        isarCategory.updateFromModel(updatedCategory);

        // Assert
        expect(isarCategory.name, 'Updated Name');
        expect(isarCategory.slug, 'updated-slug');
        expect(isarCategory.description, 'Updated description');
        expect(isarCategory.sortOrder, 10);
      });

      test('should mark as synced when updating from model', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);
        isarCategory.isSynced = false;
        final updatedCategory = CategoryFixtures.createCategoryEntity();

        // Act
        isarCategory.updateFromModel(updatedCategory);

        // Assert
        expect(isarCategory.isSynced, true);
        expect(isarCategory.lastSyncAt, isNotNull);
      });
    });

    group('entity roundtrip', () {
      test('should maintain data integrity through fromEntity -> toEntity', () {
        // Arrange
        final originalCategory = tCategory;

        // Act
        final isarCategory = IsarCategory.fromEntity(originalCategory);
        final reconstructedCategory = isarCategory.toEntity();

        // Assert
        expect(reconstructedCategory.id, originalCategory.id);
        expect(reconstructedCategory.name, originalCategory.name);
        expect(reconstructedCategory.slug, originalCategory.slug);
        expect(reconstructedCategory.sortOrder, originalCategory.sortOrder);
        expect(reconstructedCategory.status, originalCategory.status);
        expect(reconstructedCategory.parentId, originalCategory.parentId);
      });

      test('should handle inactive category roundtrip', () {
        // Arrange
        final inactiveCategory = CategoryFixtures.createInactiveCategory();

        // Act
        final isarCategory = IsarCategory.fromEntity(inactiveCategory);
        final reconstructedCategory = isarCategory.toEntity();

        // Assert
        expect(reconstructedCategory.status, CategoryStatus.inactive);
      });

      test('should handle child category roundtrip', () {
        // Arrange
        final childCategory = CategoryFixtures.createChildCategory();

        // Act
        final isarCategory = IsarCategory.fromEntity(childCategory);
        final reconstructedCategory = isarCategory.toEntity();

        // Assert
        expect(reconstructedCategory.parentId, childCategory.parentId);
      });

      test('should handle category with products roundtrip', () {
        // Arrange
        final categoryWithProducts = CategoryFixtures.createCategoryWithManyProducts(
          productsCount: 250,
        );

        // Act
        final isarCategory = IsarCategory.fromEntity(categoryWithProducts);
        final reconstructedCategory = isarCategory.toEntity();

        // Assert
        expect(reconstructedCategory.productsCount, 250);
      });

      test('should handle empty category roundtrip', () {
        // Arrange
        final emptyCategory = CategoryFixtures.createEmptyCategory();

        // Act
        final isarCategory = IsarCategory.fromEntity(emptyCategory);
        final reconstructedCategory = isarCategory.toEntity();

        // Assert
        expect(reconstructedCategory.productsCount, 0);
      });
    });

    group('toString', () {
      test('should return formatted string representation', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);

        // Act
        final result = isarCategory.toString();

        // Assert
        expect(result, contains('IsarCategory'));
        expect(result, contains(tCategory.id));
        expect(result, contains(tCategory.name));
        expect(result, contains(tCategory.slug));
      });

      test('should include sync status in string representation', () {
        // Arrange
        final isarCategory = IsarCategory.fromEntity(tCategory);

        // Act
        final result = isarCategory.toString();

        // Assert
        expect(result, contains('isSynced'));
      });
    });
  });
}
