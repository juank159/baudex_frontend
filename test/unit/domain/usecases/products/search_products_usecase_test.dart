// test/unit/domain/usecases/products/search_products_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/search_products_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/product_fixtures.dart';

// Mock repository
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late SearchProductsUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = SearchProductsUseCase(mockRepository);
  });

  group('SearchProductsUseCase', () {
    final tProducts = ProductFixtures.createProductEntityList(3);
    const tSearchTerm = 'Test Product';
    const tParams = SearchProductsParams(searchTerm: tSearchTerm, limit: 10);

    test('should call repository.searchProducts with correct parameters', () async {
      // Arrange
      when(() => mockRepository.searchProducts(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right(tProducts));

      // Act
      await useCase(tParams);

      // Assert
      verify(() => mockRepository.searchProducts(
            tSearchTerm,
            limit: 10,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return List<Product> when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.searchProducts(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right(tProducts));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, Right(tProducts));
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return products'),
        (products) {
          expect(products.length, 3);
          expect(products, isA<List<Product>>());
        },
      );
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Search failed');
      when(() => mockRepository.searchProducts(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return empty list when no products match search term', () async {
      // Arrange
      when(() => mockRepository.searchProducts(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return empty list'),
        (products) {
          expect(products.isEmpty, true);
        },
      );
    });

    test('should handle search by SKU', () async {
      // Arrange
      const tSkuParams = SearchProductsParams(searchTerm: 'SKU-001', limit: 10);
      final tSkuProduct = ProductFixtures.createProductEntity(sku: 'SKU-001');

      when(() => mockRepository.searchProducts(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right([tSkuProduct]));

      // Act
      final result = await useCase(tSkuParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (products) {
          expect(products.length, 1);
          expect(products.first.sku, 'SKU-001');
        },
      );
    });

    test('should handle search by barcode', () async {
      // Arrange
      const tBarcodeParams = SearchProductsParams(searchTerm: '1234567890', limit: 10);
      final tBarcodeProduct = ProductFixtures.createProductEntity(barcode: '1234567890');

      when(() => mockRepository.searchProducts(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right([tBarcodeProduct]));

      // Act
      final result = await useCase(tBarcodeParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (products) {
          expect(products.length, 1);
          expect(products.first.barcode, '1234567890');
        },
      );
    });

    test('should respect limit parameter', () async {
      // Arrange
      const tLimitParams = SearchProductsParams(searchTerm: 'Test', limit: 5);
      final tLimitedProducts = ProductFixtures.createProductEntityList(5);

      when(() => mockRepository.searchProducts(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right(tLimitedProducts));

      // Act
      final result = await useCase(tLimitParams);

      // Assert
      verify(() => mockRepository.searchProducts('Test', limit: 5)).called(1);
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return products'),
        (products) {
          expect(products.length, lessThanOrEqualTo(5));
        },
      );
    });

    test('should use default limit of 10 when not specified', () async {
      // Arrange
      const tDefaultLimitParams = SearchProductsParams(searchTerm: 'Test');

      when(() => mockRepository.searchProducts(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right(tProducts));

      // Act
      await useCase(tDefaultLimitParams);

      // Assert
      verify(() => mockRepository.searchProducts('Test', limit: 10)).called(1);
    });

    test('should handle partial name matches', () async {
      // Arrange
      const tPartialParams = SearchProductsParams(searchTerm: 'Prod', limit: 10);

      when(() => mockRepository.searchProducts(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right(tProducts));

      // Act
      final result = await useCase(tPartialParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return products'),
        (products) {
          expect(products.isNotEmpty, true);
        },
      );
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.searchProducts(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle case-insensitive search', () async {
      // Arrange
      const tCaseParams = SearchProductsParams(searchTerm: 'test product', limit: 10);

      when(() => mockRepository.searchProducts(
            any(),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right(tProducts));

      // Act
      final result = await useCase(tCaseParams);

      // Assert
      verify(() => mockRepository.searchProducts('test product', limit: 10)).called(1);
      expect(result.isRight(), true);
    });
  });

  group('SearchProductsParams', () {
    test('should support value equality', () {
      // Arrange
      const params1 = SearchProductsParams(searchTerm: 'Test', limit: 10);
      const params2 = SearchProductsParams(searchTerm: 'Test', limit: 10);
      const params3 = SearchProductsParams(searchTerm: 'Other', limit: 10);

      // Assert
      expect(params1, params2);
      expect(params1 == params3, false);
    });

    test('should have default limit of 10', () {
      // Arrange & Act
      const params = SearchProductsParams(searchTerm: 'Test');

      // Assert
      expect(params.searchTerm, 'Test');
      expect(params.limit, 10);
    });

    test('should have required searchTerm field', () {
      // Arrange & Act
      const params = SearchProductsParams(searchTerm: 'My Search');

      // Assert
      expect(params.searchTerm, 'My Search');
    });
  });
}
