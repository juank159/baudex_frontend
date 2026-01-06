// test/unit/domain/usecases/customers/get_customers_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/customer_fixtures.dart';

// Mock repository
class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late GetCustomersUseCase useCase;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    useCase = GetCustomersUseCase(mockRepository);
  });

  group('GetCustomersUseCase', () {
    final tCustomers = CustomerFixtures.createCustomerEntityList(5);
    final tPaginationMeta = PaginationMeta(
      page: 1,
      totalPages: 2,
      totalItems: 10,
      limit: 5,
      hasNextPage: true,
      hasPreviousPage: false,
    );
    final tPaginatedResult = PaginatedResult<Customer>(
      data: tCustomers,
      meta: tPaginationMeta,
    );

    const tParams = GetCustomersParams(
      page: 1,
      limit: 10,
    );

    test('should call repository.getCustomers with correct parameters', () async {
      // Arrange
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tParams);

      // Assert
      verify(() => mockRepository.getCustomers(
            page: tParams.page,
            limit: tParams.limit,
            search: tParams.search,
            status: tParams.status,
            documentType: tParams.documentType,
            city: tParams.city,
            state: tParams.state,
            sortBy: tParams.sortBy,
            sortOrder: tParams.sortOrder,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return PaginatedResult when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
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
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle filtering by status', () async {
      // Arrange
      const tFilterParams = GetCustomersParams(
        page: 1,
        limit: 10,
        status: CustomerStatus.active,
      );
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tFilterParams);

      // Assert
      verify(() => mockRepository.getCustomers(
            page: 1,
            limit: 10,
            search: null,
            status: CustomerStatus.active,
            documentType: null,
            city: null,
            state: null,
            sortBy: null,
            sortOrder: null,
          )).called(1);
    });

    test('should handle filtering by document type', () async {
      // Arrange
      const tFilterParams = GetCustomersParams(
        page: 1,
        limit: 10,
        documentType: DocumentType.nit,
      );
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tFilterParams);

      // Assert
      verify(() => mockRepository.getCustomers(
            page: 1,
            limit: 10,
            search: null,
            status: null,
            documentType: DocumentType.nit,
            city: null,
            state: null,
            sortBy: null,
            sortOrder: null,
          )).called(1);
    });

    test('should handle filtering by city', () async {
      // Arrange
      const tFilterParams = GetCustomersParams(
        page: 1,
        limit: 10,
        city: 'Bogota',
      );
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tFilterParams);

      // Assert
      verify(() => mockRepository.getCustomers(
            page: 1,
            limit: 10,
            search: null,
            status: null,
            documentType: null,
            city: 'Bogota',
            state: null,
            sortBy: null,
            sortOrder: null,
          )).called(1);
    });

    test('should handle search query', () async {
      // Arrange
      const tSearchParams = GetCustomersParams(
        page: 1,
        limit: 10,
        search: 'John',
      );
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tSearchParams);

      // Assert
      verify(() => mockRepository.getCustomers(
            page: 1,
            limit: 10,
            search: 'John',
            status: null,
            documentType: null,
            city: null,
            state: null,
            sortBy: null,
            sortOrder: null,
          )).called(1);
    });

    test('should handle sorting', () async {
      // Arrange
      const tSortParams = GetCustomersParams(
        page: 1,
        limit: 10,
        sortBy: 'name',
        sortOrder: 'asc',
      );
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tSortParams);

      // Assert
      verify(() => mockRepository.getCustomers(
            page: 1,
            limit: 10,
            search: null,
            status: null,
            documentType: null,
            city: null,
            state: null,
            sortBy: 'name',
            sortOrder: 'asc',
          )).called(1);
    });

    test('should handle pagination', () async {
      // Arrange
      const tPaginationParams = GetCustomersParams(
        page: 2,
        limit: 20,
      );
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tPaginationParams);

      // Assert
      verify(() => mockRepository.getCustomers(
            page: 2,
            limit: 20,
            search: null,
            status: null,
            documentType: null,
            city: null,
            state: null,
            sortBy: null,
            sortOrder: null,
          )).called(1);
    });

    test('should handle multiple filters combined', () async {
      // Arrange
      const tComplexParams = GetCustomersParams(
        page: 1,
        limit: 10,
        search: 'Tech',
        status: CustomerStatus.active,
        documentType: DocumentType.nit,
        city: 'Bogota',
        state: 'Cundinamarca',
        sortBy: 'name',
        sortOrder: 'asc',
      );
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tPaginatedResult));

      // Act
      await useCase(tComplexParams);

      // Assert
      verify(() => mockRepository.getCustomers(
            page: 1,
            limit: 10,
            search: 'Tech',
            status: CustomerStatus.active,
            documentType: DocumentType.nit,
            city: 'Bogota',
            state: 'Cundinamarca',
            sortBy: 'name',
            sortOrder: 'asc',
          )).called(1);
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return empty list when no customers match filters', () async {
      // Arrange
      final tEmptyResult = PaginatedResult<Customer>(
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
      when(() => mockRepository.getCustomers(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            status: any(named: 'status'),
            documentType: any(named: 'documentType'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            sortBy: any(named: 'sortBy'),
            sortOrder: any(named: 'sortOrder'),
          )).thenAnswer((_) async => Right(tEmptyResult));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return empty list'),
        (data) {
          expect(data.data.length, 0);
          expect(data.meta.totalItems, 0);
        },
      );
    });
  });

  group('GetCustomersParams', () {
    test('should have default values', () {
      // Arrange & Act
      const params = GetCustomersParams();

      // Assert
      expect(params.page, 1);
      expect(params.limit, 10);
      expect(params.search, isNull);
      expect(params.status, isNull);
      expect(params.documentType, isNull);
      expect(params.city, isNull);
      expect(params.state, isNull);
      expect(params.sortBy, isNull);
      expect(params.sortOrder, isNull);
    });

    test('should allow custom values', () {
      // Arrange & Act
      const params = GetCustomersParams(
        page: 2,
        limit: 20,
        search: 'test',
        status: CustomerStatus.active,
        documentType: DocumentType.nit,
        city: 'Bogota',
        state: 'Cundinamarca',
        sortBy: 'name',
        sortOrder: 'asc',
      );

      // Assert
      expect(params.page, 2);
      expect(params.limit, 20);
      expect(params.search, 'test');
      expect(params.status, CustomerStatus.active);
      expect(params.documentType, DocumentType.nit);
      expect(params.city, 'Bogota');
      expect(params.state, 'Cundinamarca');
      expect(params.sortBy, 'name');
      expect(params.sortOrder, 'asc');
    });
  });
}
