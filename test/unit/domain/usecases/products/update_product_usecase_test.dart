// test/unit/domain/usecases/products/update_product_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/update_product_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/product_fixtures.dart';

// Mock repository
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late UpdateProductUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = UpdateProductUseCase(mockRepository);
  });

  group('UpdateProductUseCase', () {
    final tProduct = ProductFixtures.createProductEntity(
      id: 'prod-001',
      name: 'Updated Product',
    );
    const tParams = UpdateProductParams(
      id: 'prod-001',
      name: 'Updated Product',
      stock: 50.0,
    );

    test('should call repository.updateProduct with correct parameters', () async {
      // Arrange
      when(() => mockRepository.updateProduct(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            sku: any(named: 'sku'),
            barcode: any(named: 'barcode'),
            type: any(named: 'type'),
            status: any(named: 'status'),
            stock: any(named: 'stock'),
            minStock: any(named: 'minStock'),
            unit: any(named: 'unit'),
            weight: any(named: 'weight'),
            length: any(named: 'length'),
            width: any(named: 'width'),
            height: any(named: 'height'),
            images: any(named: 'images'),
            metadata: any(named: 'metadata'),
            categoryId: any(named: 'categoryId'),
            prices: any(named: 'prices'),
            taxCategory: any(named: 'taxCategory'),
            taxRate: any(named: 'taxRate'),
            isTaxable: any(named: 'isTaxable'),
            taxDescription: any(named: 'taxDescription'),
            retentionCategory: any(named: 'retentionCategory'),
            retentionRate: any(named: 'retentionRate'),
            hasRetention: any(named: 'hasRetention'),
          )).thenAnswer((_) async => Right(tProduct));

      // Act
      await useCase(tParams);

      // Assert
      verify(() => mockRepository.updateProduct(
            id: 'prod-001',
            name: 'Updated Product',
            stock: 50.0,
            description: null,
            sku: null,
            barcode: null,
            type: null,
            status: null,
            minStock: null,
            unit: null,
            weight: null,
            length: null,
            width: null,
            height: null,
            images: null,
            metadata: null,
            categoryId: null,
            prices: null,
            taxCategory: null,
            taxRate: null,
            isTaxable: null,
            taxDescription: null,
            retentionCategory: null,
            retentionRate: null,
            hasRetention: null,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return updated Product when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.updateProduct(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            sku: any(named: 'sku'),
            barcode: any(named: 'barcode'),
            type: any(named: 'type'),
            status: any(named: 'status'),
            stock: any(named: 'stock'),
            minStock: any(named: 'minStock'),
            unit: any(named: 'unit'),
            weight: any(named: 'weight'),
            length: any(named: 'length'),
            width: any(named: 'width'),
            height: any(named: 'height'),
            images: any(named: 'images'),
            metadata: any(named: 'metadata'),
            categoryId: any(named: 'categoryId'),
            prices: any(named: 'prices'),
            taxCategory: any(named: 'taxCategory'),
            taxRate: any(named: 'taxRate'),
            isTaxable: any(named: 'isTaxable'),
            taxDescription: any(named: 'taxDescription'),
            retentionCategory: any(named: 'retentionCategory'),
            retentionRate: any(named: 'retentionRate'),
            hasRetention: any(named: 'hasRetention'),
          )).thenAnswer((_) async => Right(tProduct));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, Right(tProduct));
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return product'),
        (product) {
          expect(product.id, 'prod-001');
          expect(product.name, 'Updated Product');
        },
      );
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to update product');
      when(() => mockRepository.updateProduct(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            sku: any(named: 'sku'),
            barcode: any(named: 'barcode'),
            type: any(named: 'type'),
            status: any(named: 'status'),
            stock: any(named: 'stock'),
            minStock: any(named: 'minStock'),
            unit: any(named: 'unit'),
            weight: any(named: 'weight'),
            length: any(named: 'length'),
            width: any(named: 'width'),
            height: any(named: 'height'),
            images: any(named: 'images'),
            metadata: any(named: 'metadata'),
            categoryId: any(named: 'categoryId'),
            prices: any(named: 'prices'),
            taxCategory: any(named: 'taxCategory'),
            taxRate: any(named: 'taxRate'),
            isTaxable: any(named: 'isTaxable'),
            taxDescription: any(named: 'taxDescription'),
            retentionCategory: any(named: 'retentionCategory'),
            retentionRate: any(named: 'retentionRate'),
            hasRetention: any(named: 'hasRetention'),
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
      when(() => mockRepository.updateProduct(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            sku: any(named: 'sku'),
            barcode: any(named: 'barcode'),
            type: any(named: 'type'),
            status: any(named: 'status'),
            stock: any(named: 'stock'),
            minStock: any(named: 'minStock'),
            unit: any(named: 'unit'),
            weight: any(named: 'weight'),
            length: any(named: 'length'),
            width: any(named: 'width'),
            height: any(named: 'height'),
            images: any(named: 'images'),
            metadata: any(named: 'metadata'),
            categoryId: any(named: 'categoryId'),
            prices: any(named: 'prices'),
            taxCategory: any(named: 'taxCategory'),
            taxRate: any(named: 'taxRate'),
            isTaxable: any(named: 'isTaxable'),
            taxDescription: any(named: 'taxDescription'),
            retentionCategory: any(named: 'retentionCategory'),
            retentionRate: any(named: 'retentionRate'),
            hasRetention: any(named: 'hasRetention'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should update only specified fields', () async {
      // Arrange
      const tPartialParams = UpdateProductParams(
        id: 'prod-001',
        stock: 75.0,
      );

      when(() => mockRepository.updateProduct(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            sku: any(named: 'sku'),
            barcode: any(named: 'barcode'),
            type: any(named: 'type'),
            status: any(named: 'status'),
            stock: any(named: 'stock'),
            minStock: any(named: 'minStock'),
            unit: any(named: 'unit'),
            weight: any(named: 'weight'),
            length: any(named: 'length'),
            width: any(named: 'width'),
            height: any(named: 'height'),
            images: any(named: 'images'),
            metadata: any(named: 'metadata'),
            categoryId: any(named: 'categoryId'),
            prices: any(named: 'prices'),
            taxCategory: any(named: 'taxCategory'),
            taxRate: any(named: 'taxRate'),
            isTaxable: any(named: 'isTaxable'),
            taxDescription: any(named: 'taxDescription'),
            retentionCategory: any(named: 'retentionCategory'),
            retentionRate: any(named: 'retentionRate'),
            hasRetention: any(named: 'hasRetention'),
          )).thenAnswer((_) async => Right(tProduct));

      // Act
      final result = await useCase(tPartialParams);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.updateProduct(
            id: 'prod-001',
            stock: 75.0,
            name: null,
            description: null,
            sku: null,
            barcode: null,
            type: null,
            status: null,
            minStock: null,
            unit: null,
            weight: null,
            length: null,
            width: null,
            height: null,
            images: null,
            metadata: null,
            categoryId: null,
            prices: null,
            taxCategory: null,
            taxRate: null,
            isTaxable: null,
            taxDescription: null,
            retentionCategory: null,
            retentionRate: null,
            hasRetention: null,
          )).called(1);
    });

    test('should update product status', () async {
      // Arrange
      const tStatusParams = UpdateProductParams(
        id: 'prod-001',
        status: ProductStatus.inactive,
      );

      when(() => mockRepository.updateProduct(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            sku: any(named: 'sku'),
            barcode: any(named: 'barcode'),
            type: any(named: 'type'),
            status: any(named: 'status'),
            stock: any(named: 'stock'),
            minStock: any(named: 'minStock'),
            unit: any(named: 'unit'),
            weight: any(named: 'weight'),
            length: any(named: 'length'),
            width: any(named: 'width'),
            height: any(named: 'height'),
            images: any(named: 'images'),
            metadata: any(named: 'metadata'),
            categoryId: any(named: 'categoryId'),
            prices: any(named: 'prices'),
            taxCategory: any(named: 'taxCategory'),
            taxRate: any(named: 'taxRate'),
            isTaxable: any(named: 'isTaxable'),
            taxDescription: any(named: 'taxDescription'),
            retentionCategory: any(named: 'retentionCategory'),
            retentionRate: any(named: 'retentionRate'),
            hasRetention: any(named: 'hasRetention'),
          )).thenAnswer((_) async => Right(tProduct));

      // Act
      final result = await useCase(tStatusParams);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.updateProduct(
            id: 'prod-001',
            status: ProductStatus.inactive,
            name: null,
            description: null,
            sku: null,
            barcode: null,
            type: null,
            stock: null,
            minStock: null,
            unit: null,
            weight: null,
            length: null,
            width: null,
            height: null,
            images: null,
            metadata: null,
            categoryId: null,
            prices: null,
            taxCategory: null,
            taxRate: null,
            isTaxable: null,
            taxDescription: null,
            retentionCategory: null,
            retentionRate: null,
            hasRetention: null,
          )).called(1);
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.updateProduct(
            id: any(named: 'id'),
            name: any(named: 'name'),
            description: any(named: 'description'),
            sku: any(named: 'sku'),
            barcode: any(named: 'barcode'),
            type: any(named: 'type'),
            status: any(named: 'status'),
            stock: any(named: 'stock'),
            minStock: any(named: 'minStock'),
            unit: any(named: 'unit'),
            weight: any(named: 'weight'),
            length: any(named: 'length'),
            width: any(named: 'width'),
            height: any(named: 'height'),
            images: any(named: 'images'),
            metadata: any(named: 'metadata'),
            categoryId: any(named: 'categoryId'),
            prices: any(named: 'prices'),
            taxCategory: any(named: 'taxCategory'),
            taxRate: any(named: 'taxRate'),
            isTaxable: any(named: 'isTaxable'),
            taxDescription: any(named: 'taxDescription'),
            retentionCategory: any(named: 'retentionCategory'),
            retentionRate: any(named: 'retentionRate'),
            hasRetention: any(named: 'hasRetention'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });
  });

  group('UpdateProductParams', () {
    test('should support value equality', () {
      // Arrange
      const params1 = UpdateProductParams(id: 'prod-001', name: 'Test');
      const params2 = UpdateProductParams(id: 'prod-001', name: 'Test');
      const params3 = UpdateProductParams(id: 'prod-002', name: 'Test');

      // Assert
      expect(params1, params2);
      expect(params1 == params3, false);
    });

    test('should have required id field', () {
      // Arrange & Act
      const params = UpdateProductParams(id: 'prod-001');

      // Assert
      expect(params.id, 'prod-001');
    });
  });
}
