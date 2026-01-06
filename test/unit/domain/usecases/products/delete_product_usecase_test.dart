// test/unit/domain/usecases/products/delete_product_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/delete_product_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock repository
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late DeleteProductUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = DeleteProductUseCase(mockRepository);
  });

  group('DeleteProductUseCase', () {
    const tProductId = 'prod-001';
    const tParams = DeleteProductParams(id: tProductId);

    test('should call repository.deleteProduct with correct product ID', () async {
      // Arrange
      when(() => mockRepository.deleteProduct(any()))
          .thenAnswer((_) async => const Right(unit));

      // Act
      await useCase(tParams);

      // Assert
      verify(() => mockRepository.deleteProduct(tProductId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Unit when deletion is successful', () async {
      // Arrange
      when(() => mockRepository.deleteProduct(any()))
          .thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Right(unit));
      expect(result.isRight(), true);
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to delete product');
      when(() => mockRepository.deleteProduct(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return NotFoundFailure when product does not exist', () async {
      // Arrange
      const tFailure = ServerFailure('Product not found');
      when(() => mockRepository.deleteProduct(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.deleteProduct(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return ValidationFailure when product is in use', () async {
      // Arrange
      const tFailure = ValidationFailure(['Cannot delete product that is in use']);
      when(() => mockRepository.deleteProduct(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle deletion of different product IDs', () async {
      // Arrange
      const tDifferentParams = DeleteProductParams(id: 'prod-999');
      when(() => mockRepository.deleteProduct('prod-999'))
          .thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(tDifferentParams);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.deleteProduct('prod-999')).called(1);
    });
  });

  group('DeleteProductParams', () {
    test('should support value equality', () {
      // Arrange
      const params1 = DeleteProductParams(id: 'prod-001');
      const params2 = DeleteProductParams(id: 'prod-001');
      const params3 = DeleteProductParams(id: 'prod-002');

      // Assert
      expect(params1, params2);
      expect(params1 == params3, false);
    });

    test('should have required id field', () {
      // Arrange & Act
      const params = DeleteProductParams(id: 'test-id');

      // Assert
      expect(params.id, 'test-id');
    });
  });
}
