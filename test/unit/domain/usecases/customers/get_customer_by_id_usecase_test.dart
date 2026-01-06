// test/unit/domain/usecases/customers/get_customer_by_id_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/get_customer_by_id_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/customer_fixtures.dart';

// Mock repository
class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late GetCustomerByIdUseCase useCase;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    useCase = GetCustomerByIdUseCase(mockRepository);
  });

  group('GetCustomerByIdUseCase', () {
    final tCustomer = CustomerFixtures.createCustomerEntity(id: 'cust-001');
    const tCustomerId = 'cust-001';
    const tParams = GetCustomerByIdParams(id: tCustomerId);

    test('should call repository.getCustomerById with correct customer ID', () async {
      // Arrange
      when(() => mockRepository.getCustomerById(any()))
          .thenAnswer((_) async => Right(tCustomer));

      // Act
      await useCase(tParams);

      // Assert
      verify(() => mockRepository.getCustomerById(tCustomerId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Customer when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.getCustomerById(any()))
          .thenAnswer((_) async => Right(tCustomer));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, Right(tCustomer));
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return customer'),
        (customer) {
          expect(customer.id, tCustomerId);
          expect(customer.firstName, 'John');
          expect(customer.lastName, 'Doe');
        },
      );
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Customer not found');
      when(() => mockRepository.getCustomerById(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return NotFoundFailure when customer does not exist', () async {
      // Arrange
      const tFailure = ServerFailure('Customer with id cust-999 not found');
      when(() => mockRepository.getCustomerById('cust-999'))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const GetCustomerByIdParams(id: 'cust-999'));

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.getCustomerById(any()))
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
      when(() => mockRepository.getCustomerById(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle corporate customer', () async {
      // Arrange
      final tCorporateCustomer = CustomerFixtures.createCorporateCustomer();
      when(() => mockRepository.getCustomerById(any()))
          .thenAnswer((_) async => Right(tCorporateCustomer));

      // Act
      final result = await useCase(const GetCustomerByIdParams(id: 'cust-corporate'));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return customer'),
        (customer) {
          expect(customer.companyName, 'Tech Solutions S.A.S.');
          expect(customer.documentType, DocumentType.nit);
        },
      );
    });

    test('should handle individual customer', () async {
      // Arrange
      final tIndividualCustomer = CustomerFixtures.createIndividualCustomer();
      when(() => mockRepository.getCustomerById(any()))
          .thenAnswer((_) async => Right(tIndividualCustomer));

      // Act
      final result = await useCase(const GetCustomerByIdParams(id: 'cust-individual'));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return customer'),
        (customer) {
          expect(customer.companyName, isNull);
          expect(customer.documentType, DocumentType.cc);
        },
      );
    });

    test('should handle inactive customer', () async {
      // Arrange
      final tInactiveCustomer = CustomerFixtures.createInactiveCustomer();
      when(() => mockRepository.getCustomerById(any()))
          .thenAnswer((_) async => Right(tInactiveCustomer));

      // Act
      final result = await useCase(const GetCustomerByIdParams(id: 'cust-inactive'));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return customer'),
        (customer) {
          expect(customer.status, CustomerStatus.inactive);
        },
      );
    });

    test('should handle suspended customer', () async {
      // Arrange
      final tSuspendedCustomer = CustomerFixtures.createSuspendedCustomer();
      when(() => mockRepository.getCustomerById(any()))
          .thenAnswer((_) async => Right(tSuspendedCustomer));

      // Act
      final result = await useCase(const GetCustomerByIdParams(id: 'cust-suspended'));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return customer'),
        (customer) {
          expect(customer.status, CustomerStatus.suspended);
          expect(customer.currentBalance, greaterThan(customer.creditLimit));
        },
      );
    });

    test('should handle VIP customer', () async {
      // Arrange
      final tVIPCustomer = CustomerFixtures.createVIPCustomer();
      when(() => mockRepository.getCustomerById(any()))
          .thenAnswer((_) async => Right(tVIPCustomer));

      // Act
      final result = await useCase(const GetCustomerByIdParams(id: 'cust-vip'));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return customer'),
        (customer) {
          expect(customer.creditLimit, greaterThanOrEqualTo(10000000.0));
          expect(customer.totalOrders, greaterThanOrEqualTo(100));
        },
      );
    });
  });

  group('GetCustomerByIdParams', () {
    test('should support value equality', () {
      // Arrange
      const params1 = GetCustomerByIdParams(id: 'cust-001');
      const params2 = GetCustomerByIdParams(id: 'cust-001');
      const params3 = GetCustomerByIdParams(id: 'cust-002');

      // Assert
      expect(params1, params2);
      expect(params1 == params3, false);
    });

    test('should have required id field', () {
      // Arrange & Act
      const params = GetCustomerByIdParams(id: 'test-id');

      // Assert
      expect(params.id, 'test-id');
    });
  });
}
