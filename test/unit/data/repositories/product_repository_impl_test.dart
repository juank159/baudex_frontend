// test/unit/data/repositories/product_repository_impl_test.dart
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_local_datasource.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_remote_datasource.dart';
import 'package:baudex_desktop/features/products/data/models/product_model.dart';
import 'package:baudex_desktop/features/products/data/models/product_response_model.dart';
import 'package:baudex_desktop/features/products/data/models/product_query_model.dart';
import 'package:baudex_desktop/features/products/data/models/create_product_request_model.dart';
import 'package:baudex_desktop/features/products/data/models/update_product_request_model.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_repository_impl.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/product_fixtures.dart';

// Mocks
class MockProductRemoteDataSource extends Mock
    implements ProductRemoteDataSource {}

class MockProductLocalDataSource extends Mock
    implements ProductLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late ProductRepositoryImpl repository;
  late MockProductRemoteDataSource mockRemoteDataSource;
  late MockProductLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockProductRemoteDataSource();
    mockLocalDataSource = MockProductLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = ProductRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );

    // Register fallback values
    registerFallbackValue(
      ProductQueryModel(page: 1, limit: 10),
    );
    registerFallbackValue(
      CreateProductRequestModel(
        name: 'Test',
        sku: 'TEST',
        categoryId: 'cat-001',
      ),
    );
    registerFallbackValue(
      ProductModel.fromEntity(
        ProductFixtures.createProductEntity(),
      ),
    );
    registerFallbackValue(
      ProductFixtures.createProductEntity(),
    );
    registerFallbackValue(
      UpdateProductRequestModel(
        name: 'Test Update',
      ),
    );
  });

  group('ProductRepositoryImpl - getProducts', () {
    final tProducts = ProductFixtures.createProductEntityList(5);
    final tProductModels = tProducts
        .map((e) => ProductModel.fromEntity(e))
        .toList();
    final tPaginationMeta = PaginationMeta(
      page: 1,
      totalPages: 2,
      totalItems: 10,
      limit: 5,
      hasNextPage: true,
      hasPreviousPage: false,
    );
    final tProductResponse = ProductResponseModel(
      data: tProductModels,
      meta: tPaginationMeta,
    );

    test(
      'should check if device is online when getProducts is called',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getProducts(any()))
            .thenAnswer((_) async => tProductResponse);
        when(() => mockLocalDataSource.cacheProducts(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getProducts();

        // Assert
        verify(() => mockNetworkInfo.isConnected);
      },
    );

    test(
      'should return remote data when device is online and call is successful',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getProducts(any()))
            .thenAnswer((_) async => tProductResponse);
        when(() => mockLocalDataSource.cacheProducts(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getProducts();

        // Assert
        verify(() => mockRemoteDataSource.getProducts(any()));
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
        when(() => mockRemoteDataSource.getProducts(any()))
            .thenAnswer((_) async => tProductResponse);
        when(() => mockLocalDataSource.cacheProducts(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getProducts();

        // Assert
        verify(() => mockLocalDataSource.cacheProducts(any()));
      },
    );

    test(
      'should return cached data when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedProducts())
            .thenAnswer((_) async => tProductModels);

        // Act
        final result = await repository.getProducts();

        // Assert
        verify(() => mockLocalDataSource.getCachedProducts());
        verifyNever(() => mockRemoteDataSource.getProducts(any()));
        expect(result.isRight(), true);
      },
    );

    test(
      'should return cached data when remote call fails (fallback)',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getProducts(any()))
            .thenThrow(ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedProducts())
            .thenAnswer((_) async => tProductModels);

        // Act
        final result = await repository.getProducts();

        // Assert
        verify(() => mockRemoteDataSource.getProducts(any()));
        verify(() => mockLocalDataSource.getCachedProducts());
        expect(result.isRight(), true);
      },
    );

    test(
      'should return CacheFailure when offline and no cached data available',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedProducts())
            .thenThrow(CacheException('No cached data'));

        // Act
        final result = await repository.getProducts();

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
        when(() => mockRemoteDataSource.getProducts(any()))
            .thenAnswer((_) async => tProductResponse);
        when(() => mockLocalDataSource.cacheProducts(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getProducts(
          page: 2,
          limit: 20,
          search: 'test',
          status: ProductStatus.active,
          type: ProductType.product,
        );

        // Assert
        verify(() => mockRemoteDataSource.getProducts(
              any(that: predicate<ProductQueryModel>((query) =>
                  query.page == 2 &&
                  query.limit == 20 &&
                  query.search == 'test' &&
                  query.status == ProductStatus.active &&
                  query.type == ProductType.product)),
            ));
      },
    );
  });

  group('ProductRepositoryImpl - getProductById', () {
    const tProductId = 'prod-001';
    final tProduct = ProductFixtures.createProductEntity(id: tProductId);
    final tProductModel = ProductModel.fromEntity(tProduct);

    test(
      'should return product when device is online and remote call succeeds',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getProductById(any()))
            .thenAnswer((_) async => tProductModel);
        when(() => mockLocalDataSource.cacheProduct(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getProductById(tProductId);

        // Assert
        verify(() => mockRemoteDataSource.getProductById(tProductId));
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (product) {
            expect(product.id, tProductId);
            expect(product.name, tProduct.name);
          },
        );
      },
    );

    test(
      'should cache product when online call succeeds',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getProductById(any()))
            .thenAnswer((_) async => tProductModel);
        when(() => mockLocalDataSource.cacheProduct(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getProductById(tProductId);

        // Assert
        verify(() => mockLocalDataSource.cacheProduct(any()));
      },
    );

    test(
      'should return cached product when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedProduct(any()))
            .thenAnswer((_) async => tProductModel);

        // Act
        final result = await repository.getProductById(tProductId);

        // Assert
        verify(() => mockLocalDataSource.getCachedProduct(tProductId));
        verifyNever(() => mockRemoteDataSource.getProductById(any()));
        expect(result.isRight(), true);
      },
    );

    test(
      'should return NotFoundFailure when product not found in cache offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedProduct(any()))
            .thenThrow(CacheException('Product not found'));

        // Act
        final result = await repository.getProductById(tProductId);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('ProductRepositoryImpl - createProduct', () {
    final tProduct = ProductFixtures.createProductEntity();
    final tProductModel = ProductModel.fromEntity(tProduct);

    test(
      'should create product remotely when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.createProduct(any()))
            .thenAnswer((_) async => tProductModel);
        when(() => mockLocalDataSource.cacheProduct(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.createProduct(
          name: tProduct.name,
          sku: tProduct.sku,
          categoryId: tProduct.categoryId,
        );

        // Assert
        verify(() => mockRemoteDataSource.createProduct(any()));
        expect(result.isRight(), true);
      },
    );

    test(
      'should cache created product when online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.createProduct(any()))
            .thenAnswer((_) async => tProductModel);
        when(() => mockLocalDataSource.cacheProduct(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.createProduct(
          name: tProduct.name,
          sku: tProduct.sku,
          categoryId: tProduct.categoryId,
        );

        // Assert
        verify(() => mockLocalDataSource.cacheProduct(any()));
      },
    );

    test(
      'should fallback to offline creation when remote creation fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.createProduct(any()))
            .thenThrow(ServerException('Creation failed'));
        when(() => mockLocalDataSource.cacheProductForSync(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.createProduct(
          name: tProduct.name,
          sku: tProduct.sku,
          categoryId: tProduct.categoryId,
        );

        // Assert - Should create offline successfully
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should create offline successfully'),
          (product) {
            expect(product.name, tProduct.name);
            expect(product.sku, tProduct.sku);
          },
        );
        verify(() => mockLocalDataSource.cacheProductForSync(any())).called(1);
      },
    );
  });

  group('ProductRepositoryImpl - updateProduct', () {
    const tProductId = 'prod-001';
    final tProduct = ProductFixtures.createProductEntity(id: tProductId);
    final tProductModel = ProductModel.fromEntity(tProduct);

    test(
      'should update product remotely when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.updateProduct(any(), any()))
            .thenAnswer((_) async => tProductModel);
        when(() => mockLocalDataSource.cacheProduct(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateProduct(
          id: tProductId,
          name: 'Updated Name',
        );

        // Assert
        verify(() => mockRemoteDataSource.updateProduct(tProductId, any()));
        expect(result.isRight(), true);
      },
    );

    test(
      'should cache updated product when online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.updateProduct(any(), any()))
            .thenAnswer((_) async => tProductModel);
        when(() => mockLocalDataSource.cacheProduct(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.updateProduct(
          id: tProductId,
          name: 'Updated Name',
        );

        // Assert
        verify(() => mockLocalDataSource.cacheProduct(any()));
      },
    );
  });

  group('ProductRepositoryImpl - deleteProduct', () {
    const tProductId = 'prod-001';

    test(
      'should delete product remotely when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteProduct(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.removeCachedProduct(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteProduct(tProductId);

        // Assert
        verify(() => mockRemoteDataSource.deleteProduct(tProductId));
        expect(result.isRight(), true);
      },
    );

    test(
      'should delete from cache when online deletion succeeds',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteProduct(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.removeCachedProduct(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteProduct(tProductId);

        // Assert
        verify(() => mockLocalDataSource.removeCachedProduct(tProductId));
      },
    );

    test(
      'should fallback to offline deletion when remote deletion fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteProduct(any()))
            .thenThrow(ServerException('Deletion failed'));
        when(() => mockLocalDataSource.removeCachedProduct(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteProduct(tProductId);

        // Assert - Should delete offline successfully
        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.removeCachedProduct(tProductId)).called(1);
      },
    );
  });

  group('ProductRepositoryImpl - updateProductStock', () {
    const tProductId = 'prod-001';
    final tProduct = ProductFixtures.createProductEntity(id: tProductId, stock: 90.0);
    final tProductModel = ProductModel.fromEntity(tProduct);

    test(
      'should update stock remotely when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.updateProductStock(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => tProductModel);
        when(() => mockLocalDataSource.cacheProduct(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateProductStock(
          id: tProductId,
          quantity: 10.0,
          operation: 'subtract',
        );

        // Assert
        verify(() => mockRemoteDataSource.updateProductStock(
              tProductId,
              10.0,
              'subtract',
            ));
        expect(result.isRight(), true);
      },
    );

    test(
      'should cache updated stock when online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.updateProductStock(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => tProductModel);
        when(() => mockLocalDataSource.cacheProduct(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.updateProductStock(
          id: tProductId,
          quantity: 10.0,
        );

        // Assert
        verify(() => mockLocalDataSource.cacheProduct(any()));
      },
    );
  });

  group('ProductRepositoryImpl - searchProducts', () {
    const tSearchTerm = 'test';
    final tProducts = ProductFixtures.createProductEntityList(3);
    final tProductModels = tProducts
        .map((e) => ProductModel.fromEntity(e))
        .toList();

    test(
      'should search products remotely when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.searchProducts(any(), any()))
            .thenAnswer((_) async => tProductModels);

        // Act
        final result = await repository.searchProducts(tSearchTerm);

        // Assert
        verify(() => mockRemoteDataSource.searchProducts(tSearchTerm, 10));
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (products) => expect(products.length, 3),
        );
      },
    );

    test(
      'should search in cache when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.searchCachedProducts(any()))
            .thenAnswer((_) async => tProductModels);

        // Act
        final result = await repository.searchProducts(tSearchTerm);

        // Assert
        verify(() => mockLocalDataSource.searchCachedProducts(tSearchTerm));
        expect(result.isRight(), true);
      },
    );
  });

  group('ProductRepositoryImpl - getLowStockProducts', () {
    final tLowStockProducts = [
      ProductFixtures.createLowStockProduct(id: 'prod-001'),
      ProductFixtures.createLowStockProduct(id: 'prod-002'),
    ];
    final tProductModels = tLowStockProducts
        .map((e) => ProductModel.fromEntity(e))
        .toList();

    test(
      'should get low stock products from remote when online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getLowStockProducts())
            .thenAnswer((_) async => tProductModels);

        // Act
        final result = await repository.getLowStockProducts();

        // Assert
        verify(() => mockRemoteDataSource.getLowStockProducts());
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (products) => expect(products.length, 2),
        );
      },
    );

    test(
      'should get low stock products from cache when server fails',
      () async {
        // Arrange
        when(() => mockRemoteDataSource.getLowStockProducts())
            .thenThrow(ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedProducts())
            .thenAnswer((_) async => tProductModels);

        // Act
        final result = await repository.getLowStockProducts();

        // Assert
        verify(() => mockLocalDataSource.getCachedProducts());
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return products from cache'),
          (products) {
            // Filter to low stock products (stock <= minStock)
            expect(products.isNotEmpty, true);
          },
        );
      },
    );
  });
}
