// test/unit/domain/usecases/products/create_product_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/tax_enums.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/create_product_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/product_fixtures.dart';

// Mock repository
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late CreateProductUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = CreateProductUseCase(mockRepository);
  });

  group('CreateProductUseCase', () {
    final tProduct = ProductFixtures.createProductEntity();
    const tParams = CreateProductParams(
      name: 'Test Product',
      sku: 'SKU-001',
      categoryId: 'cat-001',
      description: 'Test product description',
      type: ProductType.product,
      status: ProductStatus.active,
      stock: 100.0,
      minStock: 10.0,
      unit: 'pcs',
    );

    test('should call repository.createProduct with correct parameters', () async {
      // Arrange
      when(() => mockRepository.createProduct(
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
      verify(() => mockRepository.createProduct(
            name: tParams.name,
            description: tParams.description,
            sku: tParams.sku,
            barcode: tParams.barcode,
            type: tParams.type,
            status: tParams.status,
            stock: tParams.stock,
            minStock: tParams.minStock,
            unit: tParams.unit,
            weight: tParams.weight,
            length: tParams.length,
            width: tParams.width,
            height: tParams.height,
            images: tParams.images,
            metadata: tParams.metadata,
            categoryId: tParams.categoryId,
            prices: tParams.prices,
            taxCategory: tParams.taxCategory,
            taxRate: tParams.taxRate,
            isTaxable: tParams.isTaxable,
            taxDescription: tParams.taxDescription,
            retentionCategory: tParams.retentionCategory,
            retentionRate: tParams.retentionRate,
            hasRetention: tParams.hasRetention,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Product when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.createProduct(
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
          expect(product.name, 'Test Product');
          expect(product.sku, 'SKU-001');
        },
      );
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to create product');
      when(() => mockRepository.createProduct(
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

    test('should return ValidationFailure when SKU already exists', () async {
      // Arrange
      const tFailure = ValidationFailure(['Product with SKU SKU-001 already exists']);
      when(() => mockRepository.createProduct(
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

    test('should create product with minimum required fields', () async {
      // Arrange
      const tMinimalParams = CreateProductParams(
        name: 'Minimal Product',
        sku: 'SKU-MIN',
        categoryId: 'cat-001',
      );

      when(() => mockRepository.createProduct(
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
      final result = await useCase(tMinimalParams);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.createProduct(
            name: 'Minimal Product',
            sku: 'SKU-MIN',
            categoryId: 'cat-001',
            description: null,
            barcode: null,
            type: null,
            status: null,
            stock: null,
            minStock: null,
            unit: null,
            weight: null,
            length: null,
            width: null,
            height: null,
            images: null,
            metadata: null,
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

    test('should create product with tax configuration', () async {
      // Arrange
      const tTaxParams = CreateProductParams(
        name: 'Taxable Product',
        sku: 'SKU-TAX',
        categoryId: 'cat-001',
        taxCategory: TaxCategory.iva,
        taxRate: 19.0,
        isTaxable: true,
      );

      when(() => mockRepository.createProduct(
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
      final result = await useCase(tTaxParams);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.createProduct(
            name: 'Taxable Product',
            sku: 'SKU-TAX',
            categoryId: 'cat-001',
            taxCategory: TaxCategory.iva,
            taxRate: 19.0,
            isTaxable: true,
            description: null,
            barcode: null,
            type: null,
            status: null,
            stock: null,
            minStock: null,
            unit: null,
            weight: null,
            length: null,
            width: null,
            height: null,
            images: null,
            metadata: null,
            prices: null,
            taxDescription: null,
            retentionCategory: null,
            retentionRate: null,
            hasRetention: null,
          )).called(1);
    });

    test('should create service type product with zero stock', () async {
      // Arrange
      const tServiceParams = CreateProductParams(
        name: 'Service Product',
        sku: 'SKU-SERVICE',
        categoryId: 'cat-001',
        type: ProductType.service,
        stock: 0.0,
        minStock: 0.0,
      );

      when(() => mockRepository.createProduct(
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
      final result = await useCase(tServiceParams);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.createProduct(
            name: 'Service Product',
            sku: 'SKU-SERVICE',
            categoryId: 'cat-001',
            type: ProductType.service,
            stock: 0.0,
            minStock: 0.0,
            description: null,
            barcode: null,
            status: null,
            unit: null,
            weight: null,
            length: null,
            width: null,
            height: null,
            images: null,
            metadata: null,
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
      when(() => mockRepository.createProduct(
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

  group('CreateProductParams', () {
    test('should support value equality', () {
      // Arrange
      const params1 = CreateProductParams(
        name: 'Test',
        sku: 'SKU-001',
        categoryId: 'cat-001',
      );
      const params2 = CreateProductParams(
        name: 'Test',
        sku: 'SKU-001',
        categoryId: 'cat-001',
      );
      const params3 = CreateProductParams(
        name: 'Test',
        sku: 'SKU-002',
        categoryId: 'cat-001',
      );

      // Assert
      expect(params1, params2);
      expect(params1 == params3, false);
    });

    test('should have required fields', () {
      // Arrange & Act
      const params = CreateProductParams(
        name: 'Test Product',
        sku: 'SKU-001',
        categoryId: 'cat-001',
      );

      // Assert
      expect(params.name, 'Test Product');
      expect(params.sku, 'SKU-001');
      expect(params.categoryId, 'cat-001');
    });
  });
}
