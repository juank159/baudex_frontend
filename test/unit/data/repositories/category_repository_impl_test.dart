// test/unit/data/repositories/category_repository_impl_test.dart
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/features/categories/data/datasources/category_local_datasource.dart';
import 'package:baudex_desktop/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:baudex_desktop/features/categories/data/models/category_model.dart';
import 'package:baudex_desktop/features/categories/data/models/category_response_model.dart';
import 'package:baudex_desktop/features/categories/data/models/category_query_model.dart';
import 'package:baudex_desktop/features/categories/data/models/create_category_request_model.dart';
import 'package:baudex_desktop/features/categories/data/models/update_category_request_model.dart';
import 'package:baudex_desktop/features/categories/data/models/isar/isar_category.dart';
import 'package:baudex_desktop/features/categories/data/repositories/category_repository_impl.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/category_fixtures.dart';
import '../../../mocks/mock_isar.dart';

// Mocks
class MockCategoryRemoteDataSource extends Mock
    implements CategoryRemoteDataSource {}

class MockCategoryLocalDataSource extends Mock
    implements CategoryLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late CategoryRepositoryImpl repository;
  late MockCategoryRemoteDataSource mockRemoteDataSource;
  late MockCategoryLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockIsar mockIsar;
  late MockIsarDatabase mockIsarDatabase;

  setUp(() {
    mockIsar = MockIsar();
    mockIsarDatabase = MockIsarDatabase(mockIsar);
    mockRemoteDataSource = MockCategoryRemoteDataSource();
    mockLocalDataSource = MockCategoryLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = CategoryRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
      database: mockIsar, // Use mockIsar directly, not mockIsarDatabase
    );

    // Register fallback values
    registerFallbackValue(
      CategoryQueryModel(page: 1, limit: 10),
    );
    registerFallbackValue(
      CreateCategoryRequestModel(name: 'Test', slug: 'test'),
    );
    registerFallbackValue(
      CategoryModel.fromEntity(
        CategoryFixtures.createCategoryEntity(),
      ),
    );
    registerFallbackValue(
      CategoryFixtures.createCategoryEntity(),
    );
    registerFallbackValue(
      UpdateCategoryRequestModel(),
    );
  });

  tearDown(() async {
    await mockIsar.clear();
    await mockIsar.close();
  });

  group('CategoryRepositoryImpl - getCategories', () {
    final tCategories = CategoryFixtures.createCategoryEntityList(5);
    final tCategoryModels = tCategories
        .map((e) => CategoryModel.fromEntity(e))
        .toList();
    final tPaginationMeta = PaginationMetaModel(
      page: 1,
      totalPages: 2,
      totalItems: 10,
      limit: 5,
      hasNextPage: true,
      hasPreviousPage: false,
    );
    final tCategoryResponse = CategoryResponseModel(
      data: tCategoryModels,
      meta: tPaginationMeta,
    );

    test(
      'should check if device is online when getCategories is called',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategories(any()))
            .thenAnswer((_) async => tCategoryResponse);
        when(() => mockLocalDataSource.cacheCategories(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getCategories();

        // Assert
        verify(() => mockNetworkInfo.isConnected);
      },
    );

    test(
      'should return remote data when device is online and call is successful',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategories(any()))
            .thenAnswer((_) async => tCategoryResponse);
        when(() => mockLocalDataSource.cacheCategories(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getCategories();

        // Assert
        verify(() => mockRemoteDataSource.getCategories(any()));
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 5);
            expect(paginatedResult.meta.page, 1);
            expect(paginatedResult.meta.totalItems, 10);
          },
        );
      },
    );

    test(
      'should cache data locally when online call is successful',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategories(any()))
            .thenAnswer((_) async => tCategoryResponse);
        when(() => mockLocalDataSource.cacheCategories(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getCategories();

        // Assert
        verify(() => mockLocalDataSource.cacheCategories(any()));
      },
    );

    test(
      'should return cached data when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedCategories())
            .thenAnswer((_) async => tCategoryModels);

        // Act
        final result = await repository.getCategories();

        // Assert
        verify(() => mockLocalDataSource.getCachedCategories());
        verifyNever(() => mockRemoteDataSource.getCategories(any()));
        expect(result.isRight(), true);
      },
    );

    test(
      'should return cached data when remote call fails (fallback)',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategories(any()))
            .thenThrow(ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedCategories())
            .thenAnswer((_) async => tCategoryModels);

        // Act
        final result = await repository.getCategories();

        // Assert
        verify(() => mockRemoteDataSource.getCategories(any()));
        verify(() => mockLocalDataSource.getCachedCategories());
        expect(result.isRight(), true);
      },
    );

    test(
      'should return CacheFailure when offline and no cached data available',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedCategories())
            .thenThrow(CacheException('No cached data'));

        // Act
        final result = await repository.getCategories();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should forward query parameters to remote datasource',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategories(any()))
            .thenAnswer((_) async => tCategoryResponse);
        when(() => mockLocalDataSource.cacheCategories(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getCategories(
          page: 2,
          limit: 20,
          search: 'test',
          status: CategoryStatus.active,
        );

        // Assert
        verify(() => mockRemoteDataSource.getCategories(
              any(that: predicate<CategoryQueryModel>((query) =>
                  query.page == 2 &&
                  query.limit == 20 &&
                  query.search == 'test' &&
                  query.status == CategoryStatus.active)),
            ));
      },
    );
  });

  group('CategoryRepositoryImpl - getCategoryById', () {
    const tCategoryId = 'cat-001';
    final tCategory = CategoryFixtures.createCategoryEntity(id: tCategoryId);
    final tCategoryModel = CategoryModel.fromEntity(tCategory);

    test(
      'should return category when device is online and remote call succeeds',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategoryById(any()))
            .thenAnswer((_) async => tCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getCategoryById(tCategoryId);

        // Assert
        verify(() => mockRemoteDataSource.getCategoryById(tCategoryId));
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (category) {
            expect(category.id, tCategoryId);
            expect(category.name, tCategory.name);
          },
        );
      },
    );

    test(
      'should cache category when online call succeeds',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategoryById(any()))
            .thenAnswer((_) async => tCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getCategoryById(tCategoryId);

        // Assert
        verify(() => mockLocalDataSource.cacheCategory(any()));
      },
    );

    test(
      'should return cached category when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedCategory(any()))
            .thenAnswer((_) async => tCategoryModel);

        // Act
        final result = await repository.getCategoryById(tCategoryId);

        // Assert
        verify(() => mockLocalDataSource.getCachedCategory(tCategoryId));
        verifyNever(() => mockRemoteDataSource.getCategoryById(any()));
        expect(result.isRight(), true);
      },
    );

    test(
      'should return CacheFailure when category not found in cache while offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedCategory(any()))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getCategoryById(tCategoryId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return cached category when remote call fails (fallback)',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategoryById(any()))
            .thenThrow(ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedCategory(any()))
            .thenAnswer((_) async => tCategoryModel);

        // Act
        final result = await repository.getCategoryById(tCategoryId);

        // Assert
        verify(() => mockRemoteDataSource.getCategoryById(any()));
        verify(() => mockLocalDataSource.getCachedCategory(any()));
        expect(result.isRight(), true);
      },
    );

    test(
      'should return ServerFailure when remote and cache both fail',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategoryById(any()))
            .thenThrow(ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedCategory(any()))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getCategoryById(tCategoryId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('CategoryRepositoryImpl - getCategoryTree', () {
    final tCategoryTree = CategoryFixtures.createCategoryTree();
    final tCategoryModels = tCategoryTree
        .map((e) => CategoryModel.fromEntity(e))
        .toList();

    test(
      'should return category tree when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategoryTree())
            .thenAnswer((_) async => tCategoryModels);
        when(() => mockLocalDataSource.cacheCategoryTree(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getCategoryTree();

        // Assert
        verify(() => mockRemoteDataSource.getCategoryTree());
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (tree) {
            expect(tree.length, tCategoryTree.length);
          },
        );
      },
    );

    test(
      'should cache category tree when online call succeeds',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategoryTree())
            .thenAnswer((_) async => tCategoryModels);
        when(() => mockLocalDataSource.cacheCategoryTree(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getCategoryTree();

        // Assert
        verify(() => mockLocalDataSource.cacheCategoryTree(any()));
      },
    );

    test(
      'should return cached tree when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedCategoryTree())
            .thenAnswer((_) async => tCategoryModels);

        // Act
        final result = await repository.getCategoryTree();

        // Assert
        verify(() => mockLocalDataSource.getCachedCategoryTree());
        verifyNever(() => mockRemoteDataSource.getCategoryTree());
        expect(result.isRight(), true);
      },
    );

    test(
      'should return cached tree when remote call fails (fallback)',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategoryTree())
            .thenThrow(ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedCategoryTree())
            .thenAnswer((_) async => tCategoryModels);

        // Act
        final result = await repository.getCategoryTree();

        // Assert
        verify(() => mockRemoteDataSource.getCategoryTree());
        verify(() => mockLocalDataSource.getCachedCategoryTree());
        expect(result.isRight(), true);
      },
    );
  });

  group('CategoryRepositoryImpl - searchCategories', () {
    const tSearchTerm = 'Electronics';
    const tLimit = 10;
    final tCategories = CategoryFixtures.createCategoryEntityList(3);
    final tCategoryModels = tCategories
        .map((e) => CategoryModel.fromEntity(e))
        .toList();

    test(
      'should return search results when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.searchCategories(any(), any()))
            .thenAnswer((_) async => tCategoryModels);

        // Act
        final result = await repository.searchCategories(tSearchTerm, limit: tLimit);

        // Assert
        verify(() => mockRemoteDataSource.searchCategories(tSearchTerm, tLimit));
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (categories) {
            expect(categories.length, 3);
          },
        );
      },
    );

    test(
      'should return ServerFailure when remote call fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.searchCategories(any(), any()))
            .thenThrow(ServerException('Server error'));

        // Act
        final result = await repository.searchCategories(tSearchTerm, limit: tLimit);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ConnectionFailure when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.searchCategories(tSearchTerm, limit: tLimit);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('CategoryRepositoryImpl - createCategory', () {
    final tCategory = CategoryFixtures.createCategoryEntity();
    final tCategoryModel = CategoryModel.fromEntity(tCategory);

    test(
      'should create category when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.createCategory(any()))
            .thenAnswer((_) async => tCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.createCategory(
          name: tCategory.name,
          slug: tCategory.slug,
          description: tCategory.description,
        );

        // Assert
        verify(() => mockRemoteDataSource.createCategory(any()));
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (category) {
            expect(category.name, tCategory.name);
            expect(category.slug, tCategory.slug);
          },
        );
      },
    );

    test(
      'should cache created category',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.createCategory(any()))
            .thenAnswer((_) async => tCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.createCategory(
          name: tCategory.name,
          slug: tCategory.slug,
          description: tCategory.description,
        );

        // Assert
        verify(() => mockLocalDataSource.cacheCategory(any()));
      },
    );

    test(
      'should fallback to offline creation when server fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.createCategory(any()))
            .thenThrow(ServerException('Server error'));
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.createCategory(
          name: tCategory.name,
          slug: tCategory.slug,
          description: tCategory.description,
        );

        // Assert - Should create offline successfully
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should create offline successfully'),
          (category) {
            expect(category.name, tCategory.name);
            expect(category.slug, tCategory.slug);
          },
        );
      },
    );

    test(
      'should create offline when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.createCategory(
          name: tCategory.name,
          slug: tCategory.slug,
          description: tCategory.description,
        );

        // Assert - Should create offline successfully
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should create offline successfully'),
          (category) {
            expect(category.name, tCategory.name);
            expect(category.slug, tCategory.slug);
          },
        );
      },
    );

  });

  group('CategoryRepositoryImpl - updateCategory', () {
    const tCategoryId = 'cat-001';
    final tCategory = CategoryFixtures.createCategoryEntity(id: tCategoryId);
    final tCategoryModel = CategoryModel.fromEntity(tCategory);

    test(
      'should update category when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.updateCategory(any(), any()))
            .thenAnswer((_) async => tCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateCategory(
          id: tCategoryId,
          name: 'Updated Name',
          description: 'Updated description',
        );

        // Assert
        verify(() => mockRemoteDataSource.updateCategory(tCategoryId, any()));
        expect(result.isRight(), true);
      },
    );

    test(
      'should cache updated category',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.updateCategory(any(), any()))
            .thenAnswer((_) async => tCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.updateCategory(
          id: tCategoryId,
          name: 'Updated Name',
        );

        // Assert
        verify(() => mockLocalDataSource.cacheCategory(any()));
      },
    );

    test(
      'should fallback to offline update when server fails',
      () async {
        // Arrange
        // Add category to ISAR first
        final isarCategory = IsarCategory.fromEntity(tCategory);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.updateCategory(any(), any()))
            .thenThrow(ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedCategory(any()))
            .thenAnswer((_) async => tCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateCategory(
          id: tCategoryId,
          name: 'Updated Name',
        );

        // Assert - Should update offline successfully
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should update offline successfully'),
          (category) => expect(category.name, 'Updated Name'),
        );
      },
    );

    test(
      'should update offline when device is offline',
      () async {
        // Arrange
        // Add category to ISAR first
        final isarCategory = IsarCategory.fromEntity(tCategory);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedCategory(any()))
            .thenAnswer((_) async => tCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateCategory(
          id: tCategoryId,
          name: 'Updated Name',
        );

        // Assert - Should update offline successfully
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should update offline successfully'),
          (category) => expect(category.name, 'Updated Name'),
        );
      },
    );
  });

  group('CategoryRepositoryImpl - deleteCategory', () {
    const tCategoryId = 'cat-001';

    test(
      'should delete category when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteCategory(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.removeCachedCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteCategory(tCategoryId);

        // Assert
        verify(() => mockRemoteDataSource.deleteCategory(tCategoryId));
        expect(result.isRight(), true);
      },
    );

    test(
      'should remove from cache after successful deletion',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteCategory(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.removeCachedCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteCategory(tCategoryId);

        // Assert
        verify(() => mockLocalDataSource.removeCachedCategory(tCategoryId));
      },
    );

    test(
      'should fallback to offline delete when server fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteCategory(any()))
            .thenThrow(ServerException('Server error', statusCode: 500));
        when(() => mockLocalDataSource.removeCachedCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteCategory(tCategoryId);

        // Assert - Should delete offline successfully
        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.removeCachedCategory(tCategoryId)).called(1);
      },
    );

    test(
      'should delete offline when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.removeCachedCategory(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteCategory(tCategoryId);

        // Assert - Should delete offline successfully
        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.removeCachedCategory(tCategoryId)).called(1);
      },
    );
  });
}
