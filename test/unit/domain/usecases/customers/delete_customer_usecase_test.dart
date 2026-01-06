// test/unit/domain/usecases/customers/delete_customer_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/delete_customer_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock repository
class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late DeleteCustomerUseCase useCase;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    useCase = DeleteCustomerUseCase(mockRepository);
  });

  group('DeleteCustomerUseCase', () {
    const tCustomerId = 'cust-001';
    const tParams = DeleteCustomerParams(id: tCustomerId);

    test('should call repository.deleteCustomer with correct customer ID', () async {
      // Arrange
      when(() => mockRepository.deleteCustomer(any()))
          .thenAnswer((_) async => const Right(unit));

      // Act
      await useCase(tParams);

      // Assert
      verify(() => mockRepository.deleteCustomer(tCustomerId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Unit when deletion is successful', () async {
      // Arrange
      when(() => mockRepository.deleteCustomer(any()))
          .thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Right(unit));
      expect(result.isRight(), true);
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to delete customer');
      when(() => mockRepository.deleteCustomer(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return NotFoundFailure when customer does not exist', () async {
      // Arrange
      const tFailure = ServerFailure('Customer not found');
      when(() => mockRepository.deleteCustomer(any()))
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
      when(() => mockRepository.deleteCustomer(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return ValidationFailure when customer is in use', () async {
      // Arrange
      const tFailure = ValidationFailure(['Cannot delete customer that has active invoices']);
      when(() => mockRepository.deleteCustomer(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle deletion of different customer IDs', () async {
      // Arrange
      const tDifferentParams = DeleteCustomerParams(id: 'cust-999');
      when(() => mockRepository.deleteCustomer('cust-999'))
          .thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(tDifferentParams);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.deleteCustomer('cust-999')).called(1);
    });
  });

  group('DeleteCustomerParams', () {
    test('should support value equality', () {
      // Arrange
      const params1 = DeleteCustomerParams(id: 'cust-001');
      const params2 = DeleteCustomerParams(id: 'cust-001');
      const params3 = DeleteCustomerParams(id: 'cust-002');

      // Assert
      expect(params1, params2);
      expect(params1 == params3, false);
    });

    test('should have required id field', () {
      // Arrange & Act
      const params = DeleteCustomerParams(id: 'test-id');

      // Assert
      expect(params.id, 'test-id');
    });
  });
}
