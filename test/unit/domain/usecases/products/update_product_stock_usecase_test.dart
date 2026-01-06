// test/unit/domain/usecases/products/update_product_stock_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/update_product_stock_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/product_fixtures.dart';

// Mock repository
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late UpdateProductStockUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = UpdateProductStockUseCase(mockRepository);
  });

  group('UpdateProductStockUseCase', () {
    final tProduct = ProductFixtures.createProductEntity(stock: 75.0);
    const tParams = UpdateProductStockParams(
      id: 'prod-001',
      quantity: 25.0,
      operation: 'subtract',
    );

    test('should call repository.updateProductStock with correct parameters', () async {
      // Arrange
      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => Right(tProduct));

      // Act
      await useCase(tParams);

      // Assert
      verify(() => mockRepository.updateProductStock(
            id: 'prod-001',
            quantity: 25.0,
            operation: 'subtract',
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return updated Product when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => Right(tProduct));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, Right(tProduct));
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (product) {
          expect(product.stock, 75.0);
        },
      );
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to update stock');
      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle subtract operation correctly', () async {
      // Arrange
      final tUpdatedProduct = ProductFixtures.createProductEntity(stock: 75.0);
      const tSubtractParams = UpdateProductStockParams(
        id: 'prod-001',
        quantity: 25.0,
        operation: 'subtract',
      );

      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => Right(tUpdatedProduct));

      // Act
      final result = await useCase(tSubtractParams);

      // Assert
      verify(() => mockRepository.updateProductStock(
            id: 'prod-001',
            quantity: 25.0,
            operation: 'subtract',
          )).called(1);
      expect(result.isRight(), true);
    });

    test('should handle add operation correctly', () async {
      // Arrange
      final tUpdatedProduct = ProductFixtures.createProductEntity(stock: 125.0);
      const tAddParams = UpdateProductStockParams(
        id: 'prod-001',
        quantity: 25.0,
        operation: 'add',
      );

      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => Right(tUpdatedProduct));

      // Act
      final result = await useCase(tAddParams);

      // Assert
      verify(() => mockRepository.updateProductStock(
            id: 'prod-001',
            quantity: 25.0,
            operation: 'add',
          )).called(1);
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (product) {
          expect(product.stock, 125.0);
        },
      );
    });

    test('should use default operation "subtract" when not specified', () async {
      // Arrange
      const tDefaultParams = UpdateProductStockParams(
        id: 'prod-001',
        quantity: 25.0,
      );

      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => Right(tProduct));

      // Act
      await useCase(tDefaultParams);

      // Assert
      verify(() => mockRepository.updateProductStock(
            id: 'prod-001',
            quantity: 25.0,
            operation: 'subtract',
          )).called(1);
    });

    test('should return ValidationFailure when insufficient stock for subtract', () async {
      // Arrange
      const tFailure = ValidationFailure(['Insufficient stock. Available: 10, Required: 25']);
      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return NotFoundFailure when product does not exist', () async {
      // Arrange
      const tFailure = ServerFailure('Product not found');
      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle fractional quantities correctly', () async {
      // Arrange
      final tUpdatedProduct = ProductFixtures.createProductEntity(stock: 97.5);
      const tFractionalParams = UpdateProductStockParams(
        id: 'prod-001',
        quantity: 2.5,
        operation: 'subtract',
      );

      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => Right(tUpdatedProduct));

      // Act
      final result = await useCase(tFractionalParams);

      // Assert
      verify(() => mockRepository.updateProductStock(
            id: 'prod-001',
            quantity: 2.5,
            operation: 'subtract',
          )).called(1);
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (product) {
          expect(product.stock, 97.5);
        },
      );
    });

    test('should handle large quantity updates', () async {
      // Arrange
      final tUpdatedProduct = ProductFixtures.createProductEntity(stock: 1000.0);
      const tLargeParams = UpdateProductStockParams(
        id: 'prod-001',
        quantity: 1000.0,
        operation: 'add',
      );

      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => Right(tUpdatedProduct));

      // Act
      final result = await useCase(tLargeParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (product) {
          expect(product.stock, 1000.0);
        },
      );
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle stock reaching zero', () async {
      // Arrange
      final tOutOfStockProduct = ProductFixtures.createOutOfStockProduct();
      const tZeroStockParams = UpdateProductStockParams(
        id: 'prod-001',
        quantity: 100.0,
        operation: 'subtract',
      );

      when(() => mockRepository.updateProductStock(
            id: any(named: 'id'),
            quantity: any(named: 'quantity'),
            operation: any(named: 'operation'),
          )).thenAnswer((_) async => Right(tOutOfStockProduct));

      // Act
      final result = await useCase(tZeroStockParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (product) {
          expect(product.stock, 0.0);
          expect(product.status, ProductStatus.outOfStock);
        },
      );
    });
  });

  group('UpdateProductStockParams', () {
    test('should support value equality', () {
      // Arrange
      const params1 = UpdateProductStockParams(
        id: 'prod-001',
        quantity: 25.0,
        operation: 'subtract',
      );
      const params2 = UpdateProductStockParams(
        id: 'prod-001',
        quantity: 25.0,
        operation: 'subtract',
      );
      const params3 = UpdateProductStockParams(
        id: 'prod-001',
        quantity: 30.0,
        operation: 'subtract',
      );

      // Assert
      expect(params1, params2);
      expect(params1 == params3, false);
    });

    test('should have default operation of "subtract"', () {
      // Arrange & Act
      const params = UpdateProductStockParams(
        id: 'prod-001',
        quantity: 25.0,
      );

      // Assert
      expect(params.operation, 'subtract');
    });

    test('should have required fields', () {
      // Arrange & Act
      const params = UpdateProductStockParams(
        id: 'prod-001',
        quantity: 25.0,
        operation: 'add',
      );

      // Assert
      expect(params.id, 'prod-001');
      expect(params.quantity, 25.0);
      expect(params.operation, 'add');
    });
  });
}
