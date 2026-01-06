// test/unit/domain/usecases/products/get_products_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_products_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/product_fixtures.dart';

// Mock repository
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late GetProductsUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProductsUseCase(mockRepository);
  });

  group('GetProductsUseCase', () {
    final tProducts = ProductFixtures.createProductEntityList(5);
    final tPaginationMeta = PaginationMeta(
      page: 1,
      totalPages: 2,
      totalItems: 10,
      limit: 5,
      hasNextPage: true,
      hasPreviousPage: false,
    );
    final tPaginatedResult = PaginatedResult<Product>(
      data: tProducts,
      meta: tPaginationMeta,
    );

    const tParams = GetProductsParams(
      page: 1,
      limit: 10,
    );

    test('should call repository.getProducts with correct parameters', () async {
      // Arrange
      when(() => mockRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            type: any(named: 'type'),
            categoryId: any(named: 'categoryId'),
            createdById: any(named: 'createdById'),
            inStock: any(named: 'inStock'),
            lowStock: any(named: 'lowStock'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            priceType: any(named: 'priceType'),
            includePrices: any(named: 'includePrices'),
            includeCategory: any(named: 'includeCategory'),
            includeCreatedBy: any(named: 'includeCreatedBy'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tParams);

      // Assert
      verify(() => mockRepository.getProducts(
            page: tParams.page,
            limit: tParams.limit,
            search: tParams.search,
            status: tParams.status,
            type: tParams.type,
            categoryId: tParams.categoryId,
            createdById: tParams.createdById,
            inStock: tParams.inStock,
            lowStock: tParams.lowStock,
            minPrice: tParams.minPrice,
            maxPrice: tParams.maxPrice,
            priceType: tParams.priceType,
            includePrices: tParams.includePrices,
            includeCategory: tParams.includeCategory,
            includeCreatedBy: tParams.includeCreatedBy,
            sortBy: tParams.sortBy,
            sortOrder: tParams.sortOrder,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return PaginatedResult when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            type: any(named: 'type'),
            categoryId: any(named: 'categoryId'),
            createdById: any(named: 'createdById'),
            inStock: any(named: 'inStock'),
            lowStock: any(named: 'lowStock'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            priceType: any(named: 'priceType'),
            includePrices: any(named: 'includePrices'),
            includeCategory: any(named: 'includeCategory'),
            includeCreatedBy: any(named: 'includeCreatedBy'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, Right(tPaginatedResult));
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return data'),
        (data) {
          expect(data.data.length, 5);
          expect(data.meta.currentPage, 1);
          expect(data.meta.totalItems, 10);
        },
      );
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Server error');
      when(() => mockRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            type: any(named: 'type'),
            categoryId: any(named: 'categoryId'),
            createdById: any(named: 'createdById'),
            inStock: any(named: 'inStock'),
            lowStock: any(named: 'lowStock'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            priceType: any(named: 'priceType'),
            includePrices: any(named: 'includePrices'),
            includeCategory: any(named: 'includeCategory'),
            includeCreatedBy: any(named: 'includeCreatedBy'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle search parameter correctly', () async {
      // Arrange
      const tSearchParams = GetProductsParams(
        page: 1,
        limit: 10,
        search: 'Test Product',
      );

      when(() => mockRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            type: any(named: 'type'),
            categoryId: any(named: 'categoryId'),
            createdById: any(named: 'createdById'),
            inStock: any(named: 'inStock'),
            lowStock: any(named: 'lowStock'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            priceType: any(named: 'priceType'),
            includePrices: any(named: 'includePrices'),
            includeCategory: any(named: 'includeCategory'),
            includeCreatedBy: any(named: 'includeCreatedBy'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tSearchParams);

      // Assert
      verify(() => mockRepository.getProducts(
            page: tSearchParams.page,
            limit: tSearchParams.limit,
            search: 'Test Product',
            status: tSearchParams.status,
            type: tSearchParams.type,
            categoryId: tSearchParams.categoryId,
            createdById: tSearchParams.createdById,
            inStock: tSearchParams.inStock,
            lowStock: tSearchParams.lowStock,
            minPrice: tSearchParams.minPrice,
            maxPrice: tSearchParams.maxPrice,
            priceType: tSearchParams.priceType,
            includePrices: tSearchParams.includePrices,
            includeCategory: tSearchParams.includeCategory,
            includeCreatedBy: tSearchParams.includeCreatedBy,
            sortBy: tSearchParams.sortBy,
            sortOrder: tSearchParams.sortOrder,
          )).called(1);
    });

    test('should handle status filter parameter correctly', () async {
      // Arrange
      const tStatusParams = GetProductsParams(
        page: 1,
        limit: 10,
        status: ProductStatus.active,
      );

      when(() => mockRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            type: any(named: 'type'),
            categoryId: any(named: 'categoryId'),
            createdById: any(named: 'createdById'),
            inStock: any(named: 'inStock'),
            lowStock: any(named: 'lowStock'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            priceType: any(named: 'priceType'),
            includePrices: any(named: 'includePrices'),
            includeCategory: any(named: 'includeCategory'),
            includeCreatedBy: any(named: 'includeCreatedBy'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tStatusParams);

      // Assert
      verify(() => mockRepository.getProducts(
            page: tStatusParams.page,
            limit: tStatusParams.limit,
            search: tStatusParams.search,
            status: ProductStatus.active,
            type: tStatusParams.type,
            categoryId: tStatusParams.categoryId,
            createdById: tStatusParams.createdById,
            inStock: tStatusParams.inStock,
            lowStock: tStatusParams.lowStock,
            minPrice: tStatusParams.minPrice,
            maxPrice: tStatusParams.maxPrice,
            priceType: tStatusParams.priceType,
            includePrices: tStatusParams.includePrices,
            includeCategory: tStatusParams.includeCategory,
            includeCreatedBy: tStatusParams.includeCreatedBy,
            sortBy: tStatusParams.sortBy,
            sortOrder: tStatusParams.sortOrder,
          )).called(1);
    });

    test('should handle type filter parameter correctly', () async {
      // Arrange
      const tTypeParams = GetProductsParams(
        page: 1,
        limit: 10,
        type: ProductType.product,
      );

      when(() => mockRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            type: any(named: 'type'),
            categoryId: any(named: 'categoryId'),
            createdById: any(named: 'createdById'),
            inStock: any(named: 'inStock'),
            lowStock: any(named: 'lowStock'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            priceType: any(named: 'priceType'),
            includePrices: any(named: 'includePrices'),
            includeCategory: any(named: 'includeCategory'),
            includeCreatedBy: any(named: 'includeCreatedBy'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tTypeParams);

      // Assert
      verify(() => mockRepository.getProducts(
            page: tTypeParams.page,
            limit: tTypeParams.limit,
            search: tTypeParams.search,
            status: tTypeParams.status,
            type: ProductType.product,
            categoryId: tTypeParams.categoryId,
            createdById: tTypeParams.createdById,
            inStock: tTypeParams.inStock,
            lowStock: tTypeParams.lowStock,
            minPrice: tTypeParams.minPrice,
            maxPrice: tTypeParams.maxPrice,
            priceType: tTypeParams.priceType,
            includePrices: tTypeParams.includePrices,
            includeCategory: tTypeParams.includeCategory,
            includeCreatedBy: tTypeParams.includeCreatedBy,
            sortBy: tTypeParams.sortBy,
            sortOrder: tTypeParams.sortOrder,
          )).called(1);
    });

    test('should handle price range filter parameters correctly', () async {
      // Arrange
      const tPriceParams = GetProductsParams(
        page: 1,
        limit: 10,
        minPrice: 50000.0,
        maxPrice: 150000.0,
        priceType: PriceType.price1,
      );

      when(() => mockRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            type: any(named: 'type'),
            categoryId: any(named: 'categoryId'),
            createdById: any(named: 'createdById'),
            inStock: any(named: 'inStock'),
            lowStock: any(named: 'lowStock'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            priceType: any(named: 'priceType'),
            includePrices: any(named: 'includePrices'),
            includeCategory: any(named: 'includeCategory'),
            includeCreatedBy: any(named: 'includeCreatedBy'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tPriceParams);

      // Assert
      verify(() => mockRepository.getProducts(
            page: tPriceParams.page,
            limit: tPriceParams.limit,
            search: tPriceParams.search,
            status: tPriceParams.status,
            type: tPriceParams.type,
            categoryId: tPriceParams.categoryId,
            createdById: tPriceParams.createdById,
            inStock: tPriceParams.inStock,
            lowStock: tPriceParams.lowStock,
            minPrice: 50000.0,
            maxPrice: 150000.0,
            priceType: PriceType.price1,
            includePrices: tPriceParams.includePrices,
            includeCategory: tPriceParams.includeCategory,
            includeCreatedBy: tPriceParams.includeCreatedBy,
            sortBy: tPriceParams.sortBy,
            sortOrder: tPriceParams.sortOrder,
          )).called(1);
    });

    test('should handle stock filter parameters correctly', () async {
      // Arrange
      const tStockParams = GetProductsParams(
        page: 1,
        limit: 10,
        inStock: true,
        lowStock: false,
      );

      when(() => mockRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            type: any(named: 'type'),
            categoryId: any(named: 'categoryId'),
            createdById: any(named: 'createdById'),
            inStock: any(named: 'inStock'),
            lowStock: any(named: 'lowStock'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            priceType: any(named: 'priceType'),
            includePrices: any(named: 'includePrices'),
            includeCategory: any(named: 'includeCategory'),
            includeCreatedBy: any(named: 'includeCreatedBy'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tStockParams);

      // Assert
      verify(() => mockRepository.getProducts(
            page: tStockParams.page,
            limit: tStockParams.limit,
            search: tStockParams.search,
            status: tStockParams.status,
            type: tStockParams.type,
            categoryId: tStockParams.categoryId,
            createdById: tStockParams.createdById,
            inStock: true,
            lowStock: false,
            minPrice: tStockParams.minPrice,
            maxPrice: tStockParams.maxPrice,
            priceType: tStockParams.priceType,
            includePrices: tStockParams.includePrices,
            includeCategory: tStockParams.includeCategory,
            includeCreatedBy: tStockParams.includeCreatedBy,
            sortBy: tStockParams.sortBy,
            sortOrder: tStockParams.sortOrder,
          )).called(1);
    });

    test('should handle sorting parameters correctly', () async {
      // Arrange
      const tSortParams = GetProductsParams(
        page: 1,
        limit: 10,
        sortBy: 'name',
        sortOrder: 'ASC',
      );

      when(() => mockRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            type: any(named: 'type'),
            categoryId: any(named: 'categoryId'),
            createdById: any(named: 'createdById'),
            inStock: any(named: 'inStock'),
            lowStock: any(named: 'lowStock'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            priceType: any(named: 'priceType'),
            includePrices: any(named: 'includePrices'),
            includeCategory: any(named: 'includeCategory'),
            includeCreatedBy: any(named: 'includeCreatedBy'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tSortParams);

      // Assert
      verify(() => mockRepository.getProducts(
            page: tSortParams.page,
            limit: tSortParams.limit,
            search: tSortParams.search,
            status: tSortParams.status,
            type: tSortParams.type,
            categoryId: tSortParams.categoryId,
            createdById: tSortParams.createdById,
            inStock: tSortParams.inStock,
            lowStock: tSortParams.lowStock,
            minPrice: tSortParams.minPrice,
            maxPrice: tSortParams.maxPrice,
            priceType: tSortParams.priceType,
            includePrices: tSortParams.includePrices,
            includeCategory: tSortParams.includeCategory,
            includeCreatedBy: tSortParams.includeCreatedBy,
            sortBy: 'name',
            sortOrder: 'ASC',
          )).called(1);
    });

    test('should return empty list when no products found', () async {
      // Arrange
      final tEmptyResult = PaginatedResult<Product>(
        data: [],
        meta: PaginationMeta(
          page: 1,
          totalPages: 0,
          totalItems: 0,
          limit: 10,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      );

      when(() => mockRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            type: any(named: 'type'),
            categoryId: any(named: 'categoryId'),
            createdById: any(named: 'createdById'),
            inStock: any(named: 'inStock'),
            lowStock: any(named: 'lowStock'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            priceType: any(named: 'priceType'),
            includePrices: any(named: 'includePrices'),
            includeCategory: any(named: 'includeCategory'),
            includeCreatedBy: any(named: 'includeCreatedBy'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tEmptyResult));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return data'),
        (data) {
          expect(data.data.isEmpty, true);
          expect(data.meta.totalItems, 0);
        },
      );
    });

    test('should handle NetworkFailure correctly', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.getProducts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            type: any(named: 'type'),
            categoryId: any(named: 'categoryId'),
            createdById: any(named: 'createdById'),
            inStock: any(named: 'inStock'),
            lowStock: any(named: 'lowStock'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            priceType: any(named: 'priceType'),
            includePrices: any(named: 'includePrices'),
            includeCategory: any(named: 'includeCategory'),
            includeCreatedBy: any(named: 'includeCreatedBy'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });
  });

  group('GetProductsParams', () {
    test('should have default values', () {
      // Arrange & Act
      const params = GetProductsParams();

      // Assert
      expect(params.page, 1);
      expect(params.limit, 10);
      expect(params.search, null);
      expect(params.status, null);
      expect(params.type, null);
      expect(params.includePrices, true);
      expect(params.includeCategory, true);
      expect(params.includeCreatedBy, false);
      expect(params.sortBy, 'createdAt');
      expect(params.sortOrder, 'DESC');
    });

    test('should support value equality', () {
      // Arrange
      const params1 = GetProductsParams(page: 1, limit: 10);
      const params2 = GetProductsParams(page: 1, limit: 10);
      const params3 = GetProductsParams(page: 2, limit: 10);

      // Assert
      expect(params1, params2);
      expect(params1 == params3, false);
    });

    test('copyWith should create new instance with updated values', () {
      // Arrange
      const original = GetProductsParams(page: 1, limit: 10);

      // Act
      final updated = original.copyWith(page: 2, search: 'test');

      // Assert
      expect(updated.page, 2);
      expect(updated.limit, 10);
      expect(updated.search, 'test');
      expect(original.page, 1);
      expect(original.search, null);
    });
  });
}
