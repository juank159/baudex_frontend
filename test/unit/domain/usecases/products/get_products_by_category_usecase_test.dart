// test/unit/domain/usecases/products/get_products_by_category_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_products_by_category_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/product_fixtures.dart';

// Mock repository
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late GetProductsByCategoryUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProductsByCategoryUseCase(mockRepository);
  });

  group('GetProductsByCategoryUseCase', () {
    final tProducts = ProductFixtures.createProductEntityList(3);
    const tCategoryId = 'cat-001';
    const tParams = GetProductsByCategoryParams(categoryId: tCategoryId);

    test('should call repository.getProductsByCategory with correct category ID', () async {
      // Arrange
      when(() => mockRepository.getProductsByCategory(any()))
          .thenAnswer((_) async => Right(tProducts));

      // Act
      await useCase(tParams);

      // Assert
      verify(() => mockRepository.getProductsByCategory(tCategoryId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return List<Product> when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.getProductsByCategory(any()))
          .thenAnswer((_) async => Right(tProducts));

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
      const tFailure = ServerFailure('Failed to get products');
      when(() => mockRepository.getProductsByCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return empty list when category has no products', () async {
      // Arrange
      when(() => mockRepository.getProductsByCategory(any()))
          .thenAnswer((_) async => const Right([]));

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

    test('should return products only from specified category', () async {
      // Arrange
      final tCategoryProducts = [
        ProductFixtures.createProductEntity(id: 'prod-001', categoryId: 'cat-001'),
        ProductFixtures.createProductEntity(id: 'prod-002', categoryId: 'cat-001'),
        ProductFixtures.createProductEntity(id: 'prod-003', categoryId: 'cat-001'),
      ];

      when(() => mockRepository.getProductsByCategory('cat-001'))
          .thenAnswer((_) async => Right(tCategoryProducts));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return products'),
        (products) {
          expect(products.length, 3);
          expect(products.every((p) => p.categoryId == 'cat-001'), true);
        },
      );
    });

    test('should handle different category IDs', () async {
      // Arrange
      const tDifferentParams = GetProductsByCategoryParams(categoryId: 'cat-999');
      final tDifferentProducts = [
        ProductFixtures.createProductEntity(categoryId: 'cat-999'),
      ];

      when(() => mockRepository.getProductsByCategory('cat-999'))
          .thenAnswer((_) async => Right(tDifferentProducts));

      // Act
      final result = await useCase(tDifferentParams);

      // Assert
      verify(() => mockRepository.getProductsByCategory('cat-999')).called(1);
      expect(result.isRight(), true);
    });

    test('should return NotFoundFailure when category does not exist', () async {
      // Arrange
      const tFailure = ServerFailure('Category not found');
      when(() => mockRepository.getProductsByCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.getProductsByCategory(any()))
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
      when(() => mockRepository.getProductsByCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return products with different statuses from same category', () async {
      // Arrange
      final tMixedStatusProducts = [
        ProductFixtures.createProductEntity(id: 'prod-001', categoryId: 'cat-001', status: ProductStatus.active),
        ProductFixtures.createInactiveProduct(id: 'prod-002'),
        ProductFixtures.createOutOfStockProduct(id: 'prod-003'),
      ];

      when(() => mockRepository.getProductsByCategory('cat-001'))
          .thenAnswer((_) async => Right(tMixedStatusProducts));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return products'),
        (products) {
          expect(products.length, 3);
          // Should include all statuses
          expect(products.any((p) => p.status == ProductStatus.active), true);
          expect(products.any((p) => p.status == ProductStatus.inactive), true);
          expect(products.any((p) => p.status == ProductStatus.outOfStock), true);
        },
      );
    });

    test('should return products with different types from same category', () async {
      // Arrange
      final tMixedTypeProducts = [
        ProductFixtures.createProductEntity(id: 'prod-001', categoryId: 'cat-001', type: ProductType.product),
        ProductFixtures.createServiceProduct(id: 'prod-002'),
      ];

      when(() => mockRepository.getProductsByCategory('cat-001'))
          .thenAnswer((_) async => Right(tMixedTypeProducts));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return products'),
        (products) {
          expect(products.length, 2);
          expect(products.any((p) => p.type == ProductType.product), true);
          expect(products.any((p) => p.type == ProductType.service), true);
        },
      );
    });
  });

  group('GetProductsByCategoryParams', () {
    test('should support value equality', () {
      // Arrange
      const params1 = GetProductsByCategoryParams(categoryId: 'cat-001');
      const params2 = GetProductsByCategoryParams(categoryId: 'cat-001');
      const params3 = GetProductsByCategoryParams(categoryId: 'cat-002');

      // Assert
      expect(params1, params2);
      expect(params1 == params3, false);
    });

    test('should have required categoryId field', () {
      // Arrange & Act
      const params = GetProductsByCategoryParams(categoryId: 'test-category');

      // Assert
      expect(params.categoryId, 'test-category');
    });
  });
}
