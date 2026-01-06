// test/unit/data/datasources/product_remote_datasource_test.dart
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_remote_datasource.dart';
import 'package:baudex_desktop/features/products/data/models/create_product_request_model.dart';
import 'package:baudex_desktop/features/products/data/models/product_model.dart';
import 'package:baudex_desktop/features/products/data/models/product_query_model.dart';
import 'package:baudex_desktop/features/products/data/models/product_response_model.dart';
import 'package:baudex_desktop/features/products/data/models/update_product_request_model.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/product_fixtures.dart';

// Mocks
class MockDioClient extends Mock implements DioClient {}

void main() {
  late ProductRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = ProductRemoteDataSourceImpl(dioClient: mockDioClient);

    // Register fallback values
    registerFallbackValue(
      ProductQueryModel(page: 1, limit: 10),
    );
  });

  group('ProductRemoteDataSource - getProducts', () {
    final tProducts = ProductFixtures.createProductEntityList(5);
    final tProductModels = tProducts
        .map((e) => ProductModel.fromEntity(e))
        .toList();

    final tResponseData = {
      'success': true,
      'data': tProductModels.map((e) => e.toJson()).toList(),
      'meta': {
        'page': 1,
        'totalPages': 2,
        'totalItems': 10,
        'limit': 5,
        'hasNextPage': true,
        'hasPreviousPage': false,
      },
      'message': 'Products retrieved successfully',
    };

    test(
      'should perform GET request to /products with query parameters',
      () async {
        // Arrange
        final query = ProductQueryModel(
          page: 1,
          limit: 10,
          search: 'test',
          status: ProductStatus.active,
        );

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products'),
          ),
        );

        // Act
        await dataSource.getProducts(query);

        // Assert
        verify(() => mockDioClient.get(
              '/products',
              queryParameters: query.toQueryParameters(),
            )).called(1);
      },
    );

    test(
      'should return ProductResponseModel when status code is 200',
      () async {
        // Arrange
        final query = ProductQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products'),
          ),
        );

        // Act
        final result = await dataSource.getProducts(query);

        // Assert
        expect(result, isA<ProductResponseModel>());
        expect(result.data.length, 5);
        expect(result.meta.page, 1);
      },
    );

    test(
      'should throw ServerException when status code is 404',
      () async {
        // Arrange
        final query = ProductQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Not found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: '/products'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getProducts(query),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw ServerException when status code is 500',
      () async {
        // Arrange
        final query = ProductQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Internal server error'},
            statusCode: 500,
            requestOptions: RequestOptions(path: '/products'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getProducts(query),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw ConnectionException on DioException with no response',
      () async {
        // Arrange
        final query = ProductQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/products'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getProducts(query),
          throwsA(isA<ConnectionException>()),
        );
      },
    );
  });

  group('ProductRemoteDataSource - getProductById', () {
    const tProductId = 'prod-001';
    final tProduct = ProductFixtures.createProductEntity(id: tProductId);
    final tProductModel = ProductModel.fromEntity(tProduct);

    final tResponseData = {
      'success': true,
      'data': tProductModel.toJson(),
      'message': 'Product retrieved successfully',
    };

    test(
      'should perform GET request to /products/:id',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/$tProductId'),
          ),
        );

        // Act
        await dataSource.getProductById(tProductId);

        // Assert
        verify(() => mockDioClient.get('/products/$tProductId')).called(1);
      },
    );

    test(
      'should return ProductModel when status code is 200',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/$tProductId'),
          ),
        );

        // Act
        final result = await dataSource.getProductById(tProductId);

        // Assert
        expect(result, isA<ProductModel>());
        expect(result.id, tProductId);
        expect(result.name, tProduct.name);
      },
    );

    test(
      'should throw ServerException when product not found (404)',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Product not found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: '/products/$tProductId'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getProductById(tProductId),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('ProductRemoteDataSource - createProduct', () {
    final tProduct = ProductFixtures.createProductEntity();
    final tProductModel = ProductModel.fromEntity(tProduct);
    final tRequest = CreateProductRequestModel(
      name: tProduct.name,
      sku: tProduct.sku,
      categoryId: tProduct.categoryId,
      description: tProduct.description,
      barcode: tProduct.barcode,
    );

    final tResponseData = {
      'success': true,
      'data': tProductModel.toJson(),
      'message': 'Product created successfully',
    };

    test(
      'should perform POST request to /products',
      () async {
        // Arrange
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/products'),
          ),
        );

        // Act
        await dataSource.createProduct(tRequest);

        // Assert
        verify(() => mockDioClient.post(
              '/products',
              data: tRequest.toJson(),
            )).called(1);
      },
    );

    test(
      'should return created ProductModel when status code is 201',
      () async {
        // Arrange
        when(() => mockDioClient.post(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/products'),
          ),
        );

        // Act
        final result = await dataSource.createProduct(tRequest);

        // Assert
        expect(result, isA<ProductModel>());
        expect(result.name, tProduct.name);
        expect(result.sku, tProduct.sku);
      },
    );

    test(
      'should throw ValidationException on 400 status code',
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
              'errors': {'sku': 'SKU already exists'}
            },
            statusCode: 400,
            requestOptions: RequestOptions(path: '/products'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.createProduct(tRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('ProductRemoteDataSource - updateProduct', () {
    const tProductId = 'prod-001';
    final tProduct = ProductFixtures.createProductEntity(id: tProductId);
    final tProductModel = ProductModel.fromEntity(tProduct);
    final tRequest = UpdateProductRequestModel(
      name: 'Updated Name',
      stock: 75.0,
    );

    final tResponseData = {
      'success': true,
      'data': tProductModel.toJson(),
      'message': 'Product updated successfully',
    };

    test(
      'should perform PUT request to /products/:id',
      () async {
        // Arrange
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/$tProductId'),
          ),
        );

        // Act
        await dataSource.updateProduct(tProductId, tRequest);

        // Assert
        verify(() => mockDioClient.put(
              '/products/$tProductId',
              data: tRequest.toJson(),
            )).called(1);
      },
    );

    test(
      'should return updated ProductModel when status code is 200',
      () async {
        // Arrange
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/$tProductId'),
          ),
        );

        // Act
        final result = await dataSource.updateProduct(tProductId, tRequest);

        // Assert
        expect(result, isA<ProductModel>());
        expect(result.id, tProductId);
      },
    );

    test(
      'should throw ServerException when product not found',
      () async {
        // Arrange
        when(() => mockDioClient.put(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Product not found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: '/products/$tProductId'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.updateProduct(tProductId, tRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('ProductRemoteDataSource - deleteProduct', () {
    const tProductId = 'prod-001';

    test(
      'should perform DELETE request to /products/:id',
      () async {
        // Arrange
        when(() => mockDioClient.delete(any())).thenAnswer(
          (_) async => Response(
            data: {'success': true, 'message': 'Product deleted successfully'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/$tProductId'),
          ),
        );

        // Act
        await dataSource.deleteProduct(tProductId);

        // Assert
        verify(() => mockDioClient.delete('/products/$tProductId')).called(1);
      },
    );

    test(
      'should complete successfully when status code is 200',
      () async {
        // Arrange
        when(() => mockDioClient.delete(any())).thenAnswer(
          (_) async => Response(
            data: {'success': true, 'message': 'Product deleted successfully'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/$tProductId'),
          ),
        );

        // Act & Assert - should not throw
        await dataSource.deleteProduct(tProductId);
      },
    );

    test(
      'should throw ServerException when deletion fails',
      () async {
        // Arrange
        when(() => mockDioClient.delete(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Cannot delete product'},
            statusCode: 400,
            requestOptions: RequestOptions(path: '/products/$tProductId'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.deleteProduct(tProductId),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('ProductRemoteDataSource - updateProductStock', () {
    const tProductId = 'prod-001';
    const tQuantity = 10.0;
    const tOperation = 'subtract';
    final tProduct = ProductFixtures.createProductEntity(id: tProductId, stock: 90.0);
    final tProductModel = ProductModel.fromEntity(tProduct);

    final tResponseData = {
      'success': true,
      'data': tProductModel.toJson(),
      'message': 'Stock updated successfully',
    };

    test(
      'should perform PATCH request to /products/:id/stock',
      () async {
        // Arrange
        when(() => mockDioClient.patch(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/$tProductId/stock'),
          ),
        );

        // Act
        await dataSource.updateProductStock(tProductId, tQuantity, tOperation);

        // Assert
        verify(() => mockDioClient.patch(
              '/products/$tProductId/stock',
              data: {'quantity': tQuantity, 'operation': tOperation},
            )).called(1);
      },
    );

    test(
      'should return updated ProductModel',
      () async {
        // Arrange
        when(() => mockDioClient.patch(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/$tProductId/stock'),
          ),
        );

        // Act
        final result = await dataSource.updateProductStock(
          tProductId,
          tQuantity,
          tOperation,
        );

        // Assert
        expect(result, isA<ProductModel>());
        expect(result.id, tProductId);
      },
    );
  });

  group('ProductRemoteDataSource - searchProducts', () {
    const tSearchTerm = 'test';
    const tLimit = 10;
    final tProducts = ProductFixtures.createProductEntityList(3);
    final tProductModels = tProducts
        .map((e) => ProductModel.fromEntity(e))
        .toList();

    final tResponseData = {
      'success': true,
      'data': tProductModels.map((e) => e.toJson()).toList(),
      'message': 'Search results',
    };

    test(
      'should perform GET request to /products/search with query params',
      () async {
        // Arrange
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/search'),
          ),
        );

        // Act
        await dataSource.searchProducts(tSearchTerm, tLimit);

        // Assert
        verify(() => mockDioClient.get(
              '/products/search',
              queryParameters: {'term': tSearchTerm, 'limit': tLimit},
            )).called(1);
      },
    );

    test(
      'should return list of ProductModels',
      () async {
        // Arrange
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/search'),
          ),
        );

        // Act
        final result = await dataSource.searchProducts(tSearchTerm, tLimit);

        // Assert
        expect(result, isA<List<ProductModel>>());
        expect(result.length, 3);
      },
    );
  });

  group('ProductRemoteDataSource - getLowStockProducts', () {
    final tProducts = [
      ProductFixtures.createLowStockProduct(id: 'prod-001'),
      ProductFixtures.createLowStockProduct(id: 'prod-002'),
    ];
    final tProductModels = tProducts
        .map((e) => ProductModel.fromEntity(e))
        .toList();

    final tResponseData = {
      'success': true,
      'data': tProductModels.map((e) => e.toJson()).toList(),
      'message': 'Low stock products retrieved',
    };

    test(
      'should perform GET request to /products/low-stock',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/low-stock'),
          ),
        );

        // Act
        await dataSource.getLowStockProducts();

        // Assert
        verify(() => mockDioClient.get('/products/low-stock')).called(1);
      },
    );

    test(
      'should return list of low stock ProductModels',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/products/low-stock'),
          ),
        );

        // Act
        final result = await dataSource.getLowStockProducts();

        // Assert
        expect(result, isA<List<ProductModel>>());
        expect(result.length, 2);
      },
    );
  });

  group('ProductRemoteDataSource - error handling', () {
    test(
      'should throw ConnectionException on network timeout',
      () async {
        // Arrange
        final query = ProductQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/products'),
            type: DioExceptionType.connectionTimeout,
            message: 'Connection timeout',
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getProducts(query),
          throwsA(isA<ConnectionException>()),
        );
      },
    );

    test(
      'should throw ConnectionException on receive timeout',
      () async {
        // Arrange
        final query = ProductQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/products'),
            type: DioExceptionType.receiveTimeout,
            message: 'Receive timeout',
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getProducts(query),
          throwsA(isA<ConnectionException>()),
        );
      },
    );

    test(
      'should throw ServerException on unexpected errors',
      () async {
        // Arrange
        final query = ProductQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(Exception('Unexpected error'));

        // Act & Assert
        expect(
          () => dataSource.getProducts(query),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });
}
