// test/unit/data/models/category_model_test.dart
import 'dart:convert';
import 'package:baudex_desktop/features/categories/data/models/category_model.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/category_fixtures.dart';

void main() {
  group('CategoryModel', () {
    final tCategory = CategoryFixtures.createCategoryEntity();
    final tCategoryModel = CategoryModel.fromEntity(tCategory);

    final tCategoryJson = {
      'id': tCategory.id,
      'name': tCategory.name,
      'description': tCategory.description,
      'slug': tCategory.slug,
      'image': tCategory.image,
      'status': tCategory.status.name,
      'sortOrder': tCategory.sortOrder,
      'parentId': tCategory.parentId,
      'parent': null,
      'children': null,
      'productsCount': tCategory.productsCount,
      'createdAt': tCategory.createdAt.toIso8601String(),
      'updatedAt': tCategory.updatedAt.toIso8601String(),
      'deletedAt': tCategory.deletedAt?.toIso8601String(),
    };

    group('fromJson', () {
      test('should return valid CategoryModel from JSON', () {
        // Act
        final result = CategoryModel.fromJson(tCategoryJson);

        // Assert
        expect(result, isA<CategoryModel>());
        expect(result.id, tCategory.id);
        expect(result.name, tCategory.name);
        expect(result.slug, tCategory.slug);
        expect(result.status, tCategory.status);
      });

      test('should handle null optional fields', () {
        // Arrange
        final jsonWithNulls = {
          'id': 'cat-001',
          'name': 'Test Category',
          'description': null,
          'slug': 'test-category',
          'image': null,
          'status': 'active',
          'sortOrder': 0,
          'parentId': null,
          'parent': null,
          'children': null,
          'productsCount': null,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'deletedAt': null,
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithNulls);

        // Assert
        expect(result.description, isNull);
        expect(result.image, isNull);
        expect(result.parentId, isNull);
        expect(result.productsCount, isNull);
      });

      test('should parse sortOrder as int from number', () {
        // Arrange
        final jsonWithIntSortOrder = {
          ...tCategoryJson,
          'sortOrder': 5,
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithIntSortOrder);

        // Assert
        expect(result.sortOrder, 5);
      });

      test('should parse sortOrder as int from double', () {
        // Arrange
        final jsonWithDoubleSortOrder = {
          ...tCategoryJson,
          'sortOrder': 5.0,
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithDoubleSortOrder);

        // Assert
        expect(result.sortOrder, 5);
      });

      test('should default sortOrder to 0 when null', () {
        // Arrange
        final jsonWithNullSortOrder = {
          ...tCategoryJson,
          'sortOrder': null,
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithNullSortOrder);

        // Assert
        expect(result.sortOrder, 0);
      });

      test('should parse productsCount as int from number', () {
        // Arrange
        final jsonWithProductsCount = {
          ...tCategoryJson,
          'productsCount': 150,
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithProductsCount);

        // Assert
        expect(result.productsCount, 150);
      });

      test('should parse productsCount as int from double', () {
        // Arrange
        final jsonWithDoubleProductsCount = {
          ...tCategoryJson,
          'productsCount': 150.0,
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithDoubleProductsCount);

        // Assert
        expect(result.productsCount, 150);
      });

      test('should parse parent object correctly', () {
        // Arrange
        final jsonWithParent = {
          ...tCategoryJson,
          'parent': {
            'id': 'cat-parent',
            'name': 'Parent Category',
            'slug': 'parent-category',
            'status': 'active',
            'sortOrder': 0,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithParent);

        // Assert
        expect(result.parent, isNotNull);
        expect(result.parent!.id, 'cat-parent');
        expect(result.parent!.name, 'Parent Category');
      });

      test('should parse children array correctly', () {
        // Arrange
        final jsonWithChildren = {
          ...tCategoryJson,
          'children': [
            {
              'id': 'cat-child-1',
              'name': 'Child 1',
              'slug': 'child-1',
              'status': 'active',
              'sortOrder': 0,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            },
            {
              'id': 'cat-child-2',
              'name': 'Child 2',
              'slug': 'child-2',
              'status': 'active',
              'sortOrder': 1,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            }
          ],
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithChildren);

        // Assert
        expect(result.children, isNotNull);
        expect(result.children!.length, 2);
        expect(result.children!.first, isA<CategoryModel>());
      });

      test('should parse status as active', () {
        // Arrange
        final jsonWithActiveStatus = {
          ...tCategoryJson,
          'status': 'active',
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithActiveStatus);

        // Assert
        expect(result.status, CategoryStatus.active);
      });

      test('should parse status as inactive', () {
        // Arrange
        final jsonWithInactiveStatus = {
          ...tCategoryJson,
          'status': 'inactive',
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithInactiveStatus);

        // Assert
        expect(result.status, CategoryStatus.inactive);
      });

      test('should default to active when status is null', () {
        // Arrange
        final jsonWithNullStatus = {
          ...tCategoryJson,
          'status': null,
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithNullStatus);

        // Assert
        expect(result.status, CategoryStatus.active);
      });

      test('should default to active when status is unknown', () {
        // Arrange
        final jsonWithUnknownStatus = {
          ...tCategoryJson,
          'status': 'unknown',
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithUnknownStatus);

        // Assert
        expect(result.status, CategoryStatus.active);
      });

      test('should parse createdAt as DateTime', () {
        // Arrange
        final dateTime = DateTime(2024, 1, 15, 10, 30);
        final jsonWithCreatedAt = {
          ...tCategoryJson,
          'createdAt': dateTime.toIso8601String(),
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithCreatedAt);

        // Assert
        expect(result.createdAt, dateTime);
      });

      test('should use DateTime.now() when createdAt is null', () {
        // Arrange
        final before = DateTime.now();
        final jsonWithNullCreatedAt = {
          ...tCategoryJson,
          'createdAt': null,
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithNullCreatedAt);
        final after = DateTime.now();

        // Assert
        expect(result.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(result.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
      });

      test('should parse updatedAt as DateTime', () {
        // Arrange
        final dateTime = DateTime(2024, 1, 20, 14, 45);
        final jsonWithUpdatedAt = {
          ...tCategoryJson,
          'updatedAt': dateTime.toIso8601String(),
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithUpdatedAt);

        // Assert
        expect(result.updatedAt, dateTime);
      });

      test('should use DateTime.now() when updatedAt is null', () {
        // Arrange
        final before = DateTime.now();
        final jsonWithNullUpdatedAt = {
          ...tCategoryJson,
          'updatedAt': null,
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithNullUpdatedAt);
        final after = DateTime.now();

        // Assert
        expect(result.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(result.updatedAt.isBefore(after.add(const Duration(seconds: 1))), true);
      });

      test('should parse deletedAt when present', () {
        // Arrange
        final dateTime = DateTime(2024, 2, 1, 9, 15);
        final jsonWithDeletedAt = {
          ...tCategoryJson,
          'deletedAt': dateTime.toIso8601String(),
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithDeletedAt);

        // Assert
        expect(result.deletedAt, dateTime);
      });

      test('should handle null deletedAt', () {
        // Arrange
        final jsonWithNullDeletedAt = {
          ...tCategoryJson,
          'deletedAt': null,
        };

        // Act
        final result = CategoryModel.fromJson(jsonWithNullDeletedAt);

        // Assert
        expect(result.deletedAt, isNull);
      });
    });

    group('toJson', () {
      test('should return valid JSON map', () {
        // Act
        final result = tCategoryModel.toJson();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], tCategory.id);
        expect(result['name'], tCategory.name);
        expect(result['slug'], tCategory.slug);
        expect(result['status'], tCategory.status.name);
      });

      test('should serialize dates as ISO 8601 strings', () {
        // Act
        final result = tCategoryModel.toJson();

        // Assert
        expect(result['createdAt'], isA<String>());
        expect(result['updatedAt'], isA<String>());
        expect(
          DateTime.parse(result['createdAt'] as String),
          isA<DateTime>(),
        );
      });

      test('should serialize null fields as null', () {
        // Arrange
        final categoryWithNulls = CategoryModel(
          id: 'cat-001',
          name: 'Test',
          slug: 'test',
          status: CategoryStatus.active,
          sortOrder: 0,
          description: null,
          image: null,
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = categoryWithNulls.toJson();

        // Assert
        expect(result['description'], isNull);
        expect(result['image'], isNull);
        expect(result['parentId'], isNull);
      });

      test('should serialize status as string', () {
        // Arrange
        final activeCategory = CategoryModel.fromEntity(
          CategoryFixtures.createCategoryEntity(status: CategoryStatus.active),
        );

        // Act
        final result = activeCategory.toJson();

        // Assert
        expect(result['status'], 'active');
      });

      test('should serialize inactive status as string', () {
        // Arrange
        final inactiveCategory = CategoryModel.fromEntity(
          CategoryFixtures.createInactiveCategory(),
        );

        // Act
        final result = inactiveCategory.toJson();

        // Assert
        expect(result['status'], 'inactive');
      });

      test('should serialize parent when present', () {
        // Arrange
        final childCategory = CategoryModel.fromEntity(
          CategoryFixtures.createChildCategory(),
        );

        // Act
        final result = childCategory.toJson();

        // Assert
        expect(result['parent'], isNotNull);
        expect(result['parent'], isA<Map<String, dynamic>>());
      });

      test('should serialize children array when present', () {
        // Arrange
        final parentCategory = CategoryModel.fromEntity(
          CategoryFixtures.createParentCategoryWithChildren(childrenCount: 3),
        );

        // Act
        final result = parentCategory.toJson();

        // Assert
        expect(result['children'], isNotNull);
        expect(result['children'], isA<List>());
        expect((result['children'] as List).length, 3);
      });

      test('should serialize deletedAt when present', () {
        // Arrange
        final deletedAt = DateTime(2024, 3, 1);
        final deletedCategory = CategoryModel(
          id: 'cat-001',
          name: 'Deleted',
          slug: 'deleted',
          status: CategoryStatus.inactive,
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: deletedAt,
        );

        // Act
        final result = deletedCategory.toJson();

        // Assert
        expect(result['deletedAt'], isNotNull);
        expect(result['deletedAt'], deletedAt.toIso8601String());
      });

      test('should serialize null deletedAt', () {
        // Act
        final result = tCategoryModel.toJson();

        // Assert
        expect(result['deletedAt'], isNull);
      });
    });

    group('toEntity', () {
      test('should convert to Category entity', () {
        // Act
        final result = tCategoryModel.toEntity();

        // Assert
        expect(result, isA<Category>());
        expect(result.id, tCategoryModel.id);
        expect(result.name, tCategoryModel.name);
        expect(result.slug, tCategoryModel.slug);
      });

      test('should preserve all fields', () {
        // Arrange
        final categoryModel = CategoryModel.fromEntity(tCategory);

        // Act
        final result = categoryModel.toEntity();

        // Assert
        expect(result.id, tCategory.id);
        expect(result.name, tCategory.name);
        expect(result.description, tCategory.description);
        expect(result.slug, tCategory.slug);
        expect(result.image, tCategory.image);
        expect(result.status, tCategory.status);
        expect(result.sortOrder, tCategory.sortOrder);
        expect(result.parentId, tCategory.parentId);
        expect(result.productsCount, tCategory.productsCount);
      });

      test('should preserve status', () {
        // Arrange
        final inactiveModel = CategoryModel.fromEntity(
          CategoryFixtures.createInactiveCategory(),
        );

        // Act
        final result = inactiveModel.toEntity();

        // Assert
        expect(result.status, CategoryStatus.inactive);
      });

      test('should handle null optional fields', () {
        // Arrange
        final categoryWithNulls = CategoryModel(
          id: 'cat-001',
          name: 'Test',
          slug: 'test',
          status: CategoryStatus.active,
          sortOrder: 0,
          description: null,
          image: null,
          parentId: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = categoryWithNulls.toEntity();

        // Assert
        expect(result.description, isNull);
        expect(result.image, isNull);
        expect(result.parentId, isNull);
      });
    });

    group('fromEntity', () {
      test('should create CategoryModel from Category entity', () {
        // Arrange
        final category = CategoryFixtures.createCategoryEntity();

        // Act
        final result = CategoryModel.fromEntity(category);

        // Assert
        expect(result, isA<CategoryModel>());
        expect(result.id, category.id);
        expect(result.name, category.name);
        expect(result.slug, category.slug);
      });

      test('should preserve all entity fields', () {
        // Arrange
        final category = CategoryFixtures.createCategoryEntity(
          id: 'cat-test',
          name: 'Test Category',
          description: 'Test description',
          slug: 'test-category',
          image: 'test.jpg',
          status: CategoryStatus.active,
          sortOrder: 5,
          productsCount: 100,
        );

        // Act
        final result = CategoryModel.fromEntity(category);

        // Assert
        expect(result.id, 'cat-test');
        expect(result.name, 'Test Category');
        expect(result.description, 'Test description');
        expect(result.slug, 'test-category');
        expect(result.image, 'test.jpg');
        expect(result.status, CategoryStatus.active);
        expect(result.sortOrder, 5);
        expect(result.productsCount, 100);
      });

      test('should convert parent entity to model', () {
        // Arrange
        final childCategory = CategoryFixtures.createChildCategory();

        // Act
        final result = CategoryModel.fromEntity(childCategory);

        // Assert
        expect(result.parent, isNotNull);
        expect(result.parent, isA<CategoryModel>());
        expect(result.parent!.id, childCategory.parent!.id);
      });

      test('should convert children entities to models', () {
        // Arrange
        final parentCategory = CategoryFixtures.createParentCategoryWithChildren(
          childrenCount: 3,
        );

        // Act
        final result = CategoryModel.fromEntity(parentCategory);

        // Assert
        expect(result.children, isNotNull);
        expect(result.children!.length, 3);
        expect(result.children!.first, isA<CategoryModel>());
      });

      test('should handle null parent', () {
        // Arrange
        final rootCategory = CategoryFixtures.createCategoryEntity(parentId: null);

        // Act
        final result = CategoryModel.fromEntity(rootCategory);

        // Assert
        expect(result.parent, isNull);
      });

      test('should handle null children', () {
        // Arrange
        final leafCategory = CategoryFixtures.createCategoryEntity();

        // Act
        final result = CategoryModel.fromEntity(leafCategory);

        // Assert
        expect(result.children, isNull);
      });

      test('should preserve inactive status', () {
        // Arrange
        final inactiveCategory = CategoryFixtures.createInactiveCategory();

        // Act
        final result = CategoryModel.fromEntity(inactiveCategory);

        // Assert
        expect(result.status, CategoryStatus.inactive);
      });
    });

    group('JSON roundtrip', () {
      test('should maintain data integrity through toJson -> fromJson', () {
        // Arrange
        final originalModel = tCategoryModel;

        // Act
        final json = originalModel.toJson();
        final reconstructedModel = CategoryModel.fromJson(json);

        // Assert
        expect(reconstructedModel.id, originalModel.id);
        expect(reconstructedModel.name, originalModel.name);
        expect(reconstructedModel.slug, originalModel.slug);
        expect(reconstructedModel.status, originalModel.status);
        expect(reconstructedModel.sortOrder, originalModel.sortOrder);
      });

      test('should maintain data integrity through toEntity -> fromEntity', () {
        // Arrange
        final originalEntity = tCategory;

        // Act
        final model = CategoryModel.fromEntity(originalEntity);
        final reconstructedEntity = model.toEntity();

        // Assert
        expect(reconstructedEntity.id, originalEntity.id);
        expect(reconstructedEntity.name, originalEntity.name);
        expect(reconstructedEntity.slug, originalEntity.slug);
        expect(reconstructedEntity.status, originalEntity.status);
        expect(reconstructedEntity.sortOrder, originalEntity.sortOrder);
      });

      test('should handle category with children roundtrip', () {
        // Arrange
        final parentCategory = CategoryFixtures.createParentCategoryWithChildren();

        // Act
        final model = CategoryModel.fromEntity(parentCategory);
        final json = model.toJson();
        final reconstructedModel = CategoryModel.fromJson(json);

        // Assert
        expect(reconstructedModel.children, isNotNull);
        expect(reconstructedModel.children!.length, parentCategory.children!.length);
      });

      test('should handle inactive category roundtrip', () {
        // Arrange
        final inactiveCategory = CategoryFixtures.createInactiveCategory();

        // Act
        final model = CategoryModel.fromEntity(inactiveCategory);
        final json = model.toJson();
        final reconstructedModel = CategoryModel.fromJson(json);

        // Assert
        expect(reconstructedModel.status, CategoryStatus.inactive);
      });
    });
  });
}
