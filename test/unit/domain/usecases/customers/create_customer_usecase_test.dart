// test/unit/domain/usecases/customers/create_customer_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/create_customer_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/customer_fixtures.dart';

class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  setUpAll(() {
    // Register fallback values for enums used with any()
    registerFallbackValue(CustomerStatus.active);
    registerFallbackValue(DocumentType.cc);
  });

  late CreateCustomerUseCase useCase;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    useCase = CreateCustomerUseCase(mockRepository);
  });

  final tCustomer = CustomerFixtures.createCustomerEntity();
  final tParams = CreateCustomerParams(
    firstName: 'John',
    lastName: 'Doe',
    email: 'john.doe@example.com',
    documentType: DocumentType.cc,
    documentNumber: '1234567890',
  );

  test(
    'should create customer through repository',
    () async {
      // Arrange
      when(() => mockRepository.createCustomer(
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
      verify(() => mockRepository.createCustomer(
            firstName: tParams.firstName,
            lastName: tParams.lastName,
            companyName: tParams.companyName,
            email: tParams.email,
            phone: tParams.phone,
            mobile: tParams.mobile,
            documentType: tParams.documentType,
            documentNumber: tParams.documentNumber,
            address: tParams.address,
            city: tParams.city,
            state: tParams.state,
            zipCode: tParams.zipCode,
            country: tParams.country,
            status: tParams.status,
            creditLimit: tParams.creditLimit,
            paymentTerms: tParams.paymentTerms,
            birthDate: tParams.birthDate,
            notes: tParams.notes,
            metadata: tParams.metadata,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    },
  );

  test(
    'should pass all parameters correctly',
    () async {
      // Arrange
      final tParamsWithAllFields = CreateCustomerParams(
        firstName: 'John',
        lastName: 'Doe',
        companyName: 'Test Company',
        email: 'john.doe@example.com',
        phone: '+57 300 123 4567',
        mobile: '+57 300 123 4567',
        documentType: DocumentType.nit,
        documentNumber: '900123456-1',
        address: '123 Main St',
        city: 'Bogota',
        state: 'Cundinamarca',
        zipCode: '110111',
        country: 'Colombia',
        status: CustomerStatus.active,
        creditLimit: 5000000.0,
        paymentTerms: 60,
        birthDate: DateTime(1990, 1, 1),
        notes: 'Important customer',
        metadata: {'vip': true},
      );

      when(() => mockRepository.createCustomer(
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
      verify(() => mockRepository.createCustomer(
            firstName: 'John',
            lastName: 'Doe',
            companyName: 'Test Company',
            email: 'john.doe@example.com',
            phone: '+57 300 123 4567',
            mobile: '+57 300 123 4567',
            documentType: DocumentType.nit,
            documentNumber: '900123456-1',
            address: '123 Main St',
            city: 'Bogota',
            state: 'Cundinamarca',
            zipCode: '110111',
            country: 'Colombia',
            status: CustomerStatus.active,
            creditLimit: 5000000.0,
            paymentTerms: 60,
            birthDate: DateTime(1990, 1, 1),
            notes: 'Important customer',
            metadata: {'vip': true},
          )).called(1);
    },
  );

  test(
    'should return ServerFailure when repository fails',
    () async {
      // Arrange
      const tFailure = ServerFailure('Server error');
      when(() => mockRepository.createCustomer(
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
    'should return ConnectionFailure when offline',
    () async {
      // Arrange
      const tFailure = ConnectionFailure.noInternet;
      when(() => mockRepository.createCustomer(
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
    'should handle optional fields correctly',
    () async {
      // Arrange
      final tMinimalParams = CreateCustomerParams(
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        documentType: DocumentType.cc,
        documentNumber: '1234567890',
      );

      when(() => mockRepository.createCustomer(
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
      await useCase(tMinimalParams);

      // Assert
      verify(() => mockRepository.createCustomer(
            firstName: 'John',
            lastName: 'Doe',
            companyName: null,
            email: 'john.doe@example.com',
            phone: null,
            mobile: null,
            documentType: DocumentType.cc,
            documentNumber: '1234567890',
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
    },
  );
}
