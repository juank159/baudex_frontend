// test/unit/domain/usecases/customers/update_customer_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/update_customer_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/customer_fixtures.dart';

class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late UpdateCustomerUseCase useCase;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    useCase = UpdateCustomerUseCase(mockRepository);
  });

  final tCustomer = CustomerFixtures.createCustomerEntity();
  final tParams = UpdateCustomerParams(
    id: 'cust-001',
    firstName: 'Jane',
  );

  test(
    'should update customer through repository',
    () async {
      // Arrange
      when(() => mockRepository.updateCustomer(
            id: any(named: 'id'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            companyName: any(named: 'companyName'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            mobile: any(named: 'mobile'),
            documentType: any(named: 'documentType'),
            documentNumber: any(named: 'documentNumber'),
            address: any(named: 'address'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            zipCode: any(named: 'zipCode'),
            country: any(named: 'country'),
            status: any(named: 'status'),
            creditLimit: any(named: 'creditLimit'),
            paymentTerms: any(named: 'paymentTerms'),
            birthDate: any(named: 'birthDate'),
            notes: any(named: 'notes'),
            metadata: any(named: 'metadata'),
          )).thenAnswer((_) async => Right(tCustomer));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (customer) {
          expect(customer, equals(tCustomer));
        },
      );
      verify(() => mockRepository.updateCustomer(
            id: 'cust-001',
            firstName: 'Jane',
            lastName: null,
            companyName: null,
            email: null,
            phone: null,
            mobile: null,
            documentType: null,
            documentNumber: null,
            address: null,
            city: null,
            state: null,
            zipCode: null,
            country: null,
            status: null,
            creditLimit: null,
            paymentTerms: null,
            birthDate: null,
            notes: null,
            metadata: null,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    },
  );

  test(
    'should pass all parameters correctly when updating',
    () async {
      // Arrange
      final tParamsWithAllFields = UpdateCustomerParams(
        id: 'cust-001',
        firstName: 'Jane',
        lastName: 'Smith',
        companyName: 'New Company',
        email: 'jane.smith@example.com',
        phone: '+57 301 999 8888',
        mobile: '+57 301 999 8888',
        documentType: DocumentType.ce,
        documentNumber: '9876543210',
        address: '456 Second Ave',
        city: 'Medellin',
        state: 'Antioquia',
        zipCode: '050001',
        country: 'Colombia',
        status: CustomerStatus.inactive,
        creditLimit: 2000000.0,
        paymentTerms: 45,
        birthDate: DateTime(1985, 5, 15),
        notes: 'Updated notes',
        metadata: {'updated': true},
      );

      when(() => mockRepository.updateCustomer(
            id: any(named: 'id'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            companyName: any(named: 'companyName'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            mobile: any(named: 'mobile'),
            documentType: any(named: 'documentType'),
            documentNumber: any(named: 'documentNumber'),
            address: any(named: 'address'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            zipCode: any(named: 'zipCode'),
            country: any(named: 'country'),
            status: any(named: 'status'),
            creditLimit: any(named: 'creditLimit'),
            paymentTerms: any(named: 'paymentTerms'),
            birthDate: any(named: 'birthDate'),
            notes: any(named: 'notes'),
            metadata: any(named: 'metadata'),
          )).thenAnswer((_) async => Right(tCustomer));

      // Act
      await useCase(tParamsWithAllFields);

      // Assert
      verify(() => mockRepository.updateCustomer(
            id: 'cust-001',
            firstName: 'Jane',
            lastName: 'Smith',
            companyName: 'New Company',
            email: 'jane.smith@example.com',
            phone: '+57 301 999 8888',
            mobile: '+57 301 999 8888',
            documentType: DocumentType.ce,
            documentNumber: '9876543210',
            address: '456 Second Ave',
            city: 'Medellin',
            state: 'Antioquia',
            zipCode: '050001',
            country: 'Colombia',
            status: CustomerStatus.inactive,
            creditLimit: 2000000.0,
            paymentTerms: 45,
            birthDate: DateTime(1985, 5, 15),
            notes: 'Updated notes',
            metadata: {'updated': true},
          )).called(1);
    },
  );

  test(
    'should return ServerFailure when repository fails',
    () async {
      // Arrange
      const tFailure = ServerFailure('Server error');
      when(() => mockRepository.updateCustomer(
            id: any(named: 'id'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            companyName: any(named: 'companyName'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            mobile: any(named: 'mobile'),
            documentType: any(named: 'documentType'),
            documentNumber: any(named: 'documentNumber'),
            address: any(named: 'address'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            zipCode: any(named: 'zipCode'),
            country: any(named: 'country'),
            status: any(named: 'status'),
            creditLimit: any(named: 'creditLimit'),
            paymentTerms: any(named: 'paymentTerms'),
            birthDate: any(named: 'birthDate'),
            notes: any(named: 'notes'),
            metadata: any(named: 'metadata'),
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, equals(tFailure)),
        (_) => fail('Should return Left'),
      );
    },
  );

  test(
    'should return ValidationFailure when no fields are updated',
    () async {
      // Arrange
      const tFailure = ValidationFailure(['No hay cambios para actualizar']);
      when(() => mockRepository.updateCustomer(
            id: any(named: 'id'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            companyName: any(named: 'companyName'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            mobile: any(named: 'mobile'),
            documentType: any(named: 'documentType'),
            documentNumber: any(named: 'documentNumber'),
            address: any(named: 'address'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            zipCode: any(named: 'zipCode'),
            country: any(named: 'country'),
            status: any(named: 'status'),
            creditLimit: any(named: 'creditLimit'),
            paymentTerms: any(named: 'paymentTerms'),
            birthDate: any(named: 'birthDate'),
            notes: any(named: 'notes'),
            metadata: any(named: 'metadata'),
          )).thenAnswer((_) async => const Left(tFailure));

      final tEmptyParams = UpdateCustomerParams(id: 'cust-001');

      // Act
      final result = await useCase(tEmptyParams);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should return Left'),
      );
    },
  );

  test(
    'should update only specific fields',
    () async {
      // Arrange
      final tPartialUpdate = UpdateCustomerParams(
        id: 'cust-001',
        email: 'newemail@example.com',
        creditLimit: 3000000.0,
      );

      when(() => mockRepository.updateCustomer(
            id: any(named: 'id'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            companyName: any(named: 'companyName'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            mobile: any(named: 'mobile'),
            documentType: any(named: 'documentType'),
            documentNumber: any(named: 'documentNumber'),
            address: any(named: 'address'),
            city: any(named: 'city'),
            state: any(named: 'state'),
            zipCode: any(named: 'zipCode'),
            country: any(named: 'country'),
            status: any(named: 'status'),
            creditLimit: any(named: 'creditLimit'),
            paymentTerms: any(named: 'paymentTerms'),
            birthDate: any(named: 'birthDate'),
            notes: any(named: 'notes'),
            metadata: any(named: 'metadata'),
          )).thenAnswer((_) async => Right(tCustomer));

      // Act
      await useCase(tPartialUpdate);

      // Assert
      verify(() => mockRepository.updateCustomer(
            id: 'cust-001',
            firstName: null,
            lastName: null,
            companyName: null,
            email: 'newemail@example.com',
            phone: null,
            mobile: null,
            documentType: null,
            documentNumber: null,
            address: null,
            city: null,
            state: null,
            zipCode: null,
            country: null,
            status: null,
            creditLimit: 3000000.0,
            paymentTerms: null,
            birthDate: null,
            notes: null,
            metadata: null,
          )).called(1);
    },
  );
}
