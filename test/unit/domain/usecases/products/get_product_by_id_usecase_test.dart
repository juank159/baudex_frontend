// test/unit/domain/usecases/products/get_product_by_id_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_product_by_id_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/product_fixtures.dart';

// Mock repository
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late GetProductByIdUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProductByIdUseCase(mockRepository);
  });

  group('GetProductByIdUseCase', () {
    final tProduct = ProductFixtures.createProductEntity(id: 'prod-001');
    const tProductId = 'prod-001';
    const tParams = GetProductByIdParams(id: tProductId);

    test('should call repository.getProductById with correct product ID', () async {
      // Arrange
      when(() => mockRepository.getProductById(any()))
          .thenAnswer((_) async => Right(tProduct));

      // Act
      await useCase(tParams);

      // Assert
      verify(() => mockRepository.getProductById(tProductId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Product when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.getProductById(any()))
          .thenAnswer((_) async => Right(tProduct));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, Right(tProduct));
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (product) {
          expect(product.id, tProductId);
          expect(product.name, 'Test Product');
        },
      );
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Product not found');
      when(() => mockRepository.getProductById(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return NotFoundFailure when product does not exist', () async {
      // Arrange
      const tFailure = ServerFailure('Product with id prod-999 not found');
      when(() => mockRepository.getProductById('prod-999'))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const GetProductByIdParams(id: 'prod-999'));

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.getProductById(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return CacheFailure when offline and no cached data', () async {
      // Arrange
      const tFailure = CacheFailure('No cached data available');
      when(() => mockRepository.getProductById(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle product with multiple prices', () async {
      // Arrange
      final tProductWithPrices = ProductFixtures.createProductWithMultiplePrices();
      when(() => mockRepository.getProductById(any()))
          .thenAnswer((_) async => Right(tProductWithPrices));

      // Act
      final result = await useCase(const GetProductByIdParams(id: 'prod-multi-price'));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (product) {
          expect(product.prices!.length, 4);
        },
      );
    });

    test('should handle low stock product', () async {
      // Arrange
      final tLowStockProduct = ProductFixtures.createLowStockProduct();
      when(() => mockRepository.getProductById(any()))
          .thenAnswer((_) async => Right(tLowStockProduct));

      // Act
      final result = await useCase(const GetProductByIdParams(id: 'prod-low-stock'));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (product) {
          expect(product.stock, lessThanOrEqualTo(product.minStock));
        },
      );
    });

    test('should handle service type product', () async {
      // Arrange
      final tServiceProduct = ProductFixtures.createServiceProduct();
      when(() => mockRepository.getProductById(any()))
          .thenAnswer((_) async => Right(tServiceProduct));

      // Act
      final result = await useCase(const GetProductByIdParams(id: 'prod-service'));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (product) {
          expect(product.type, ProductType.service);
          expect(product.stock, 0.0);
        },
      );
    });

    test('should handle inactive product', () async {
      // Arrange
      final tInactiveProduct = ProductFixtures.createInactiveProduct();
      when(() => mockRepository.getProductById(any()))
          .thenAnswer((_) async => Right(tInactiveProduct));

      // Act
      final result = await useCase(const GetProductByIdParams(id: 'prod-inactive'));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (product) {
          expect(product.status, ProductStatus.inactive);
        },
      );
    });
  });

  group('GetProductByIdParams', () {
    test('should support value equality', () {
      // Arrange
      const params1 = GetProductByIdParams(id: 'prod-001');
      const params2 = GetProductByIdParams(id: 'prod-001');
      const params3 = GetProductByIdParams(id: 'prod-002');

      // Assert
      expect(params1, params2);
      expect(params1 == params3, false);
    });

    test('should have required id field', () {
      // Arrange & Act
      const params = GetProductByIdParams(id: 'test-id');

      // Assert
      expect(params.id, 'test-id');
    });
  });
}
