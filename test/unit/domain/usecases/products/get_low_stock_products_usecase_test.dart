// test/unit/domain/usecases/products/get_low_stock_products_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_low_stock_products_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/product_fixtures.dart';

// Mock repository
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late GetLowStockProductsUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetLowStockProductsUseCase(mockRepository);
  });

  group('GetLowStockProductsUseCase', () {
    final tLowStockProducts = [
      ProductFixtures.createLowStockProduct(id: 'prod-001', stock: 5.0, minStock: 10.0),
      ProductFixtures.createLowStockProduct(id: 'prod-002', stock: 3.0, minStock: 10.0),
      ProductFixtures.createOutOfStockProduct(id: 'prod-003'),
    ];

    test('should call repository.getLowStockProducts', () async {
      // Arrange
      when(() => mockRepository.getLowStockProducts())
          .thenAnswer((_) async => Right(tLowStockProducts));

      // Act
      await useCase(NoParams());

      // Assert
      verify(() => mockRepository.getLowStockProducts()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return List<Product> when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.getLowStockProducts())
          .thenAnswer((_) async => Right(tLowStockProducts));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result, Right(tLowStockProducts));
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return products'),
        (products) {
          expect(products.length, 3);
          expect(products, isA<List<Product>>());
        },
      );
    });

    test('should return only products with stock <= minStock', () async {
      // Arrange
      when(() => mockRepository.getLowStockProducts())
          .thenAnswer((_) async => Right(tLowStockProducts));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return products'),
        (products) {
          for (var product in products) {
            expect(product.stock, lessThanOrEqualTo(product.minStock));
          }
        },
      );
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to get low stock products');
      when(() => mockRepository.getLowStockProducts())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return empty list when no low stock products exist', () async {
      // Arrange
      when(() => mockRepository.getLowStockProducts())
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return empty list'),
        (products) {
          expect(products.isEmpty, true);
        },
      );
    });

    test('should include out of stock products (stock = 0)', () async {
      // Arrange
      final tOutOfStockProduct = ProductFixtures.createOutOfStockProduct();
      when(() => mockRepository.getLowStockProducts())
          .thenAnswer((_) async => Right([tOutOfStockProduct]));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (products) {
          expect(products.length, 1);
          expect(products.first.stock, 0.0);
          expect(products.first.status, ProductStatus.outOfStock);
        },
      );
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.getLowStockProducts())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return CacheFailure when offline and no cached data', () async {
      // Arrange
      const tFailure = CacheFailure('No cached data available');
      when(() => mockRepository.getLowStockProducts())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle products with different stock levels', () async {
      // Arrange
      final tMixedStockProducts = [
        ProductFixtures.createLowStockProduct(id: 'prod-001', stock: 9.0, minStock: 10.0),
        ProductFixtures.createLowStockProduct(id: 'prod-002', stock: 5.0, minStock: 10.0),
        ProductFixtures.createLowStockProduct(id: 'prod-003', stock: 1.0, minStock: 10.0),
        ProductFixtures.createOutOfStockProduct(id: 'prod-004'),
      ];

      when(() => mockRepository.getLowStockProducts())
          .thenAnswer((_) async => Right(tMixedStockProducts));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return products'),
        (products) {
          expect(products.length, 4);
          expect(products.every((p) => p.stock <= p.minStock), true);
        },
      );
    });

    test('should not include service products (stock tracking disabled)', () async {
      // Arrange - Service products typically have stock = 0 and shouldn't trigger alerts
      when(() => mockRepository.getLowStockProducts())
          .thenAnswer((_) async => Right(tLowStockProducts));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return products'),
        (products) {
          // Verify no service type products in low stock list
          expect(
            products.every((p) => p.type != ProductType.service),
            true,
          );
        },
      );
    });
  });
}
