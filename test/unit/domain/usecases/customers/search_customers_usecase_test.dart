// test/unit/domain/usecases/customers/search_customers_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/search_customers_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/customer_fixtures.dart';

// Mock repository
class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late SearchCustomersUseCase useCase;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    useCase = SearchCustomersUseCase(mockRepository);
  });

  group('SearchCustomersUseCase', () {
    final tCustomers = CustomerFixtures.createCustomerEntityList(3);
    const tSearchTerm = 'John';
    const tParams = SearchCustomersParams(searchTerm: tSearchTerm);

    test('should call repository.searchCustomers with correct search term', () async {
      // Arrange
      when(() => mockRepository.searchCustomers(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(tCustomers));

      // Act
      await useCase(tParams);

      // Assert
      verify(() => mockRepository.searchCustomers(tSearchTerm, limit: 10)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return List<Customer> when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.searchCustomers(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(tCustomers));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, Right(tCustomers));
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return customers'),
        (customers) {
          expect(customers.length, 3);
        },
      );
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Search failed');
      when(() => mockRepository.searchCustomers(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle custom limit parameter', () async {
      // Arrange
      const tCustomParams = SearchCustomersParams(searchTerm: 'Tech', limit: 20);
      when(() => mockRepository.searchCustomers(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(tCustomers));

      // Act
      await useCase(tCustomParams);

      // Assert
      verify(() => mockRepository.searchCustomers('Tech', limit: 20)).called(1);
    });

    test('should return empty list when no customers match search', () async {
      // Arrange
      when(() => mockRepository.searchCustomers(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return empty list'),
        (customers) {
          expect(customers.length, 0);
        },
      );
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.searchCustomers(any(), limit: any(named: 'limit')))
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
      when(() => mockRepository.searchCustomers(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle searching by email', () async {
      // Arrange
      final tCustomer = CustomerFixtures.createCustomerEntity(email: 'john@example.com');
      const tEmailParams = SearchCustomersParams(searchTerm: 'john@example.com');
      when(() => mockRepository.searchCustomers(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right([tCustomer]));

      // Act
      final result = await useCase(tEmailParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return customers'),
        (customers) {
          expect(customers.length, 1);
          expect(customers.first.email, 'john@example.com');
        },
      );
    });

    test('should handle searching by document number', () async {
      // Arrange
      final tCustomer = CustomerFixtures.createCustomerEntity(documentNumber: '1234567890');
      const tDocParams = SearchCustomersParams(searchTerm: '1234567890');
      when(() => mockRepository.searchCustomers(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right([tCustomer]));

      // Act
      final result = await useCase(tDocParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return customers'),
        (customers) {
          expect(customers.length, 1);
          expect(customers.first.documentNumber, '1234567890');
        },
      );
    });

    test('should handle searching by company name', () async {
      // Arrange
      final tCorporateCustomer = CustomerFixtures.createCorporateCustomer();
      const tCompanyParams = SearchCustomersParams(searchTerm: 'Tech Solutions');
      when(() => mockRepository.searchCustomers(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right([tCorporateCustomer]));

      // Act
      final result = await useCase(tCompanyParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return customers'),
        (customers) {
          expect(customers.length, 1);
          expect(customers.first.companyName, contains('Tech Solutions'));
        },
      );
    });

    test('should handle partial name matches', () async {
      // Arrange
      final tMatchingCustomers = [
        CustomerFixtures.createCustomerEntity(id: 'cust-001', firstName: 'John', lastName: 'Doe'),
        CustomerFixtures.createCustomerEntity(id: 'cust-002', firstName: 'Johnny', lastName: 'Smith'),
        CustomerFixtures.createCustomerEntity(id: 'cust-003', firstName: 'Johnson', lastName: 'Lee'),
      ];
      const tPartialParams = SearchCustomersParams(searchTerm: 'John');
      when(() => mockRepository.searchCustomers(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(tMatchingCustomers));

      // Act
      final result = await useCase(tPartialParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return customers'),
        (customers) {
          expect(customers.length, 3);
        },
      );
    });
  });

  group('SearchCustomersParams', () {
    test('should have default limit of 10', () {
      // Arrange & Act
      const params = SearchCustomersParams(searchTerm: 'test');

      // Assert
      expect(params.searchTerm, 'test');
      expect(params.limit, 10);
    });

    test('should allow custom limit', () {
      // Arrange & Act
      const params = SearchCustomersParams(searchTerm: 'test', limit: 20);

      // Assert
      expect(params.searchTerm, 'test');
      expect(params.limit, 20);
    });

    test('should have required searchTerm field', () {
      // Arrange & Act
      const params = SearchCustomersParams(searchTerm: 'John Doe');

      // Assert
      expect(params.searchTerm, 'John Doe');
    });
  });
}
