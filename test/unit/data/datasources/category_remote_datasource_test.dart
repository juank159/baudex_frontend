// test/unit/data/datasources/category_remote_datasource_test.dart
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:baudex_desktop/features/categories/data/models/category_model.dart';
import 'package:baudex_desktop/features/categories/data/models/category_query_model.dart';
import 'package:baudex_desktop/features/categories/data/models/category_response_model.dart';
import 'package:baudex_desktop/features/categories/data/models/category_stats_model.dart';
import 'package:baudex_desktop/features/categories/data/models/create_category_request_model.dart';
import 'package:baudex_desktop/features/categories/data/models/update_category_request_model.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/category_fixtures.dart';

// Mocks
class MockDioClient extends Mock implements DioClient {}

void main() {
  late CategoryRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = CategoryRemoteDataSourceImpl(dioClient: mockDioClient);

    // Register fallback values
    registerFallbackValue(
      CategoryQueryModel(page: 1, limit: 10),
    );
    registerFallbackValue(
      CreateCategoryRequestModel(name: 'Test', slug: 'test'),
    );
    registerFallbackValue(
      UpdateCategoryRequestModel(),
    );
  });

  group('CategoryRemoteDataSource - getCategories', () {
    final tCategories = CategoryFixtures.createCategoryEntityList(5);
    final tCategoryModels = tCategories
        .map((e) => CategoryModel.fromEntity(e))
        .toList();

    final tResponseData = {
      'success': true,
      'data': tCategoryModels.map((e) => e.toJson()).toList(),
      'meta': {
        'page': 1,
        'totalPages': 2,
        'totalItems': 10,
        'limit': 5,
        'hasNextPage': true,
        'hasPreviousPage': false,
      },
      'message': 'Categories retrieved successfully',
    };

    test(
      'should perform GET request to /categories with query parameters',
      () async {
        // Arrange
        final query = CategoryQueryModel(
          page: 1,
          limit: 10,
          search: 'test',
          status: CategoryStatus.active,
        );

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        await dataSource.getCategories(query);

        // Assert
        verify(() => mockDioClient.get(
              '/categories',
              queryParameters: query.toQueryParameters(),
            )).called(1);
      },
    );

    test(
      'should return CategoryResponseModel when status code is 200',
      () async {
        // Arrange
        final query = CategoryQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        final result = await dataSource.getCategories(query);

        // Assert
        expect(result, isA<CategoryResponseModel>());
        expect(result.data.length, 5);
        expect(result.meta.page, 1);
      },
    );

    test(
      'should throw ServerException when status code is 404',
      () async {
        // Arrange
        final query = CategoryQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Not found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getCategories(query),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw ServerException when status code is 500',
      () async {
        // Arrange
        final query = CategoryQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Internal server error'},
            statusCode: 500,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getCategories(query),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw ConnectionException on DioException with no response',
      () async {
        // Arrange
        final query = CategoryQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/categories'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getCategories(query),
          throwsA(isA<ConnectionException>()),
        );
      },
    );
  });

  group('CategoryRemoteDataSource - getCategoryById', () {
    const tCategoryId = 'cat-001';
    final tCategory = CategoryFixtures.createCategoryEntity(id: tCategoryId);
    final tCategoryModel = CategoryModel.fromEntity(tCategory);

    final tResponseData = {
      'success': true,
      'data': tCategoryModel.toJson(),
      'message': 'Category retrieved successfully',
    };

    test(
      'should perform GET request to /categories/:id',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/$tCategoryId'),
          ),
        );

        // Act
        await dataSource.getCategoryById(tCategoryId);

        // Assert
        verify(() => mockDioClient.get('/categories/$tCategoryId')).called(1);
      },
    );

    test(
      'should return CategoryModel when status code is 200',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/$tCategoryId'),
          ),
        );

        // Act
        final result = await dataSource.getCategoryById(tCategoryId);

        // Assert
        expect(result, isA<CategoryModel>());
        expect(result.id, tCategoryId);
        expect(result.name, tCategory.name);
      },
    );

    test(
      'should throw ServerException when category not found (404)',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Category not found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: '/categories/$tCategoryId'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getCategoryById(tCategoryId),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('CategoryRemoteDataSource - getCategoryBySlug', () {
    const tSlug = 'test-category';
    final tCategory = CategoryFixtures.createCategoryEntity(slug: tSlug);
    final tCategoryModel = CategoryModel.fromEntity(tCategory);

    final tResponseData = {
      'success': true,
      'data': tCategoryModel.toJson(),
      'message': 'Category retrieved successfully',
    };

    test(
      'should perform GET request to /categories/slug/:slug',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/slug/$tSlug'),
          ),
        );

        // Act
        await dataSource.getCategoryBySlug(tSlug);

        // Assert
        verify(() => mockDioClient.get('/categories/slug/$tSlug')).called(1);
      },
    );

    test(
      'should return CategoryModel when slug found',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/slug/$tSlug'),
          ),
        );

        // Act
        final result = await dataSource.getCategoryBySlug(tSlug);

        // Assert
        expect(result, isA<CategoryModel>());
        expect(result.slug, tSlug);
      },
    );

    test(
      'should throw ServerException when slug not found',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Category not found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: '/categories/slug/$tSlug'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getCategoryBySlug(tSlug),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('CategoryRemoteDataSource - getCategoryTree', () {
    final tCategoryTree = CategoryFixtures.createCategoryTree();
    final tCategoryModels = tCategoryTree
        .map((e) => CategoryModel.fromEntity(e))
        .toList();

    final tResponseData = {
      'success': true,
      'data': tCategoryModels.map((e) => e.toJson()).toList(),
      'message': 'Category tree retrieved successfully',
    };

    test(
      'should perform GET request to /categories/tree',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/tree'),
          ),
        );

        // Act
        await dataSource.getCategoryTree();

        // Assert
        verify(() => mockDioClient.get('/categories/tree')).called(1);
      },
    );

    test(
      'should return list of CategoryModels when successful',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/tree'),
          ),
        );

        // Act
        final result = await dataSource.getCategoryTree();

        // Assert
        expect(result, isA<List<CategoryModel>>());
        expect(result.length, tCategoryTree.length);
      },
    );

    test(
      'should throw ServerException on error',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Server error'},
            statusCode: 500,
            requestOptions: RequestOptions(path: '/categories/tree'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getCategoryTree(),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('CategoryRemoteDataSource - getCategoryStats', () {
    final tStatsData = {
      'totalCategories': 50,
      'activeCategories': 45,
      'inactiveCategories': 5,
      'totalProducts': 500,
      'categoriesWithProducts': 40,
      'emptyCategoriesCount': 10,
    };

    final tResponseData = {
      'success': true,
      'data': tStatsData,
      'message': 'Stats retrieved successfully',
    };

    test(
      'should perform GET request to /categories/stats',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/stats'),
          ),
        );

        // Act
        await dataSource.getCategoryStats();

        // Assert
        verify(() => mockDioClient.get('/categories/stats')).called(1);
      },
    );

    test(
      'should return CategoryStatsModel when successful',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/stats'),
          ),
        );

        // Act
        final result = await dataSource.getCategoryStats();

        // Assert
        expect(result, isA<CategoryStatsModel>());
      },
    );
  });

  group('CategoryRemoteDataSource - searchCategories', () {
    const tSearchTerm = 'Electronics';
    const tLimit = 10;
    final tCategories = CategoryFixtures.createCategoryEntityList(3);
    final tCategoryModels = tCategories
        .map((e) => CategoryModel.fromEntity(e))
        .toList();

    final tResponseData = {
      'success': true,
      'data': tCategoryModels.map((e) => e.toJson()).toList(),
      'message': 'Search successful',
    };

    test(
      'should perform GET request to /categories/search with query params',
      () async {
        // Arrange
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/search'),
          ),
        );

        // Act
        await dataSource.searchCategories(tSearchTerm, tLimit);

        // Assert
        verify(() => mockDioClient.get(
              '/categories/search',
              queryParameters: {'q': tSearchTerm, 'limit': tLimit},
            )).called(1);
      },
    );

    test(
      'should return list of CategoryModels on successful search',
      () async {
        // Arrange
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/search'),
          ),
        );

        // Act
        final result = await dataSource.searchCategories(tSearchTerm, tLimit);

        // Assert
        expect(result, isA<List<CategoryModel>>());
        expect(result.length, 3);
      },
    );

    test(
      'should throw ServerException on search error',
      () async {
        // Arrange
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Search failed'},
            statusCode: 500,
            requestOptions: RequestOptions(path: '/categories/search'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.searchCategories(tSearchTerm, tLimit),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('CategoryRemoteDataSource - createCategory', () {
    final tCategory = CategoryFixtures.createCategoryEntity();
    final tCategoryModel = CategoryModel.fromEntity(tCategory);
    final tRequest = CreateCategoryRequestModel(
      name: tCategory.name,
      slug: tCategory.slug,
      description: tCategory.description,
      parentId: tCategory.parentId,
    );

    final tResponseData = {
      'success': true,
      'data': tCategoryModel.toJson(),
      'message': 'Category created successfully',
    };

    test(
      'should perform POST request to /categories',
      () async {
        // Arrange
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        await dataSource.createCategory(tRequest);

        // Assert
        verify(() => mockDioClient.post(
              '/categories',
              data: tRequest.toJson(),
            )).called(1);
      },
    );

    test(
      'should return CategoryModel when status code is 201',
      () async {
        // Arrange
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act
        final result = await dataSource.createCategory(tRequest);

        // Assert
        expect(result, isA<CategoryModel>());
        expect(result.name, tCategory.name);
        expect(result.slug, tCategory.slug);
      },
    );

    test(
      'should throw ServerException on validation error (400)',
      () async {
        // Arrange
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: {
              'success': false,
              'message': 'Validation failed',
              'errors': ['Name is required']
            },
            statusCode: 400,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.createCategory(tRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw ServerException on duplicate slug (409)',
      () async {
        // Arrange
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Slug already exists'},
            statusCode: 409,
            requestOptions: RequestOptions(path: '/categories'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.createCategory(tRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('CategoryRemoteDataSource - updateCategory', () {
    const tCategoryId = 'cat-001';
    final tCategory = CategoryFixtures.createCategoryEntity(id: tCategoryId);
    final tCategoryModel = CategoryModel.fromEntity(tCategory);
    final tRequest = UpdateCategoryRequestModel(
      name: 'Updated Name',
      description: 'Updated description',
    );

    final tResponseData = {
      'success': true,
      'data': tCategoryModel.toJson(),
      'message': 'Category updated successfully',
    };

    test(
      'should perform PATCH request to /categories/:id',
      () async {
        // Arrange
        when(() => mockDioClient.patch(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/$tCategoryId'),
          ),
        );

        // Act
        await dataSource.updateCategory(tCategoryId, tRequest);

        // Assert
        verify(() => mockDioClient.patch(
              '/categories/$tCategoryId',
              data: tRequest.toJson(),
            )).called(1);
      },
    );

    test(
      'should return updated CategoryModel when successful',
      () async {
        // Arrange
        when(() => mockDioClient.patch(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/categories/$tCategoryId'),
          ),
        );

        // Act
        final result = await dataSource.updateCategory(tCategoryId, tRequest);

        // Assert
        expect(result, isA<CategoryModel>());
        expect(result.id, tCategoryId);
      },
    );

    test(
      'should throw ServerException when category not found',
      () async {
        // Arrange
        when(() => mockDioClient.patch(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Category not found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: '/categories/$tCategoryId'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.updateCategory(tCategoryId, tRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('CategoryRemoteDataSource - deleteCategory', () {
    const tCategoryId = 'cat-001';

    test(
      'should perform DELETE request to /categories/:id',
      () async {
        // Arrange
        when(() => mockDioClient.delete(any())).thenAnswer(
          (_) async => Response(
            data: {'success': true},
            statusCode: 204,
            requestOptions: RequestOptions(path: '/categories/$tCategoryId'),
          ),
        );

        // Act
        await dataSource.deleteCategory(tCategoryId);

        // Assert
        verify(() => mockDioClient.delete('/categories/$tCategoryId')).called(1);
      },
    );

    test(
      'should complete successfully on 204 status code',
      () async {
        // Arrange
        when(() => mockDioClient.delete(any())).thenAnswer(
          (_) async => Response(
            data: null,
            statusCode: 204,
            requestOptions: RequestOptions(path: '/categories/$tCategoryId'),
          ),
        );

        // Act & Assert
        await expectLater(
          dataSource.deleteCategory(tCategoryId),
          completes,
        );
      },
    );

    test(
      'should throw ServerException when category not found',
      () async {
        // Arrange
        when(() => mockDioClient.delete(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Category not found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: '/categories/$tCategoryId'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.deleteCategory(tCategoryId),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw ServerException when category has products (409)',
      () async {
        // Arrange
        when(() => mockDioClient.delete(any())).thenAnswer(
          (_) async => Response(
            data: {
              'success': false,
              'message': 'Cannot delete category with products'
            },
            statusCode: 409,
            requestOptions: RequestOptions(path: '/categories/$tCategoryId'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.deleteCategory(tCategoryId),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('CategoryRemoteDataSource - Connection Handling', () {
    test(
      'should throw ConnectionException on connection timeout',
      () async {
        // Arrange
        final query = CategoryQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/categories'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getCategories(query),
          throwsA(isA<ConnectionException>()),
        );
      },
    );

    test(
      'should throw ConnectionException on socket exception',
      () async {
        // Arrange
        final query = CategoryQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/categories'),
            type: DioExceptionType.unknown,
            message: 'SocketException: Connection failed',
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getCategories(query),
          throwsA(isA<ConnectionException>()),
        );
      },
    );
  });
}
