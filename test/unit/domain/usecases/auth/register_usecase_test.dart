// test/unit/domain/usecases/auth/register_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/auth/domain/entities/auth_result.dart';
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:baudex_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/register_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/auth_fixtures.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterUseCase(mockRepository);
  });

  const tFirstName = AuthFixtures.testFirstName;
  const tLastName = AuthFixtures.testLastName;
  const tEmail = AuthFixtures.testEmail;
  const tPassword = 'Password123';
  final tAuthResult = AuthFixtures.createAuthResult();

  group('RegisterUseCase - call', () {
    test(
      'should return AuthResult when registration succeeds',
      () async {
        // Arrange
        when(() => mockRepository.register(
              firstName: any(named: 'firstName'),
              lastName: any(named: 'lastName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
              organizationName: any(named: 'organizationName'),
            )).thenAnswer((_) async => Right(tAuthResult));

        // Act
        final result = await useCase(const RegisterParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
          confirmPassword: tPassword,
        ));

        // Assert
        expect(result, Right(tAuthResult));
        verify(() => mockRepository.register(
              firstName: any(named: 'firstName'),
              lastName: any(named: 'lastName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
              organizationName: any(named: 'organizationName'),
            )).called(1);
      },
    );

    test(
      'should return ValidationFailure when first name is empty',
      () async {
        // Act
        final result = await useCase(const RegisterParams(
          firstName: '',
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
          confirmPassword: tPassword,
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.first, contains('nombre es requerido'));
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ValidationFailure when first name is too short',
      () async {
        // Act
        final result = await useCase(const RegisterParams(
          firstName: 'J',
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
          confirmPassword: tPassword,
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.first, contains('al menos 2 caracteres'));
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ValidationFailure when last name is empty',
      () async {
        // Act
        final result = await useCase(const RegisterParams(
          firstName: tFirstName,
          lastName: '',
          email: tEmail,
          password: tPassword,
          confirmPassword: tPassword,
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ValidationFailure when email is invalid',
      () async {
        // Act
        final result = await useCase(const RegisterParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: 'invalid-email',
          password: tPassword,
          confirmPassword: tPassword,
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.first, contains('formato válido'));
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ValidationFailure when password is too short',
      () async {
        // Act
        final result = await useCase(const RegisterParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: '12345',
          confirmPassword: '12345',
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ValidationFailure when password has no lowercase',
      () async {
        // Act
        final result = await useCase(const RegisterParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: 'PASSWORD123',
          confirmPassword: 'PASSWORD123',
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.any((e) => e.contains('minúscula')), true);
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ValidationFailure when password has no uppercase',
      () async {
        // Act
        final result = await useCase(const RegisterParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: 'password123',
          confirmPassword: 'password123',
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.any((e) => e.contains('mayúscula')), true);
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ValidationFailure when password has no number',
      () async {
        // Act
        final result = await useCase(const RegisterParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: 'PasswordABC',
          confirmPassword: 'PasswordABC',
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.any((e) => e.contains('número')), true);
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ValidationFailure when passwords do not match',
      () async {
        // Act
        final result = await useCase(const RegisterParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
          confirmPassword: 'DifferentPassword123',
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.first, contains('no coinciden'));
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should pass optional parameters to repository',
      () async {
        // Arrange
        when(() => mockRepository.register(
              firstName: any(named: 'firstName'),
              lastName: any(named: 'lastName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
              organizationName: any(named: 'organizationName'),
            )).thenAnswer((_) async => Right(tAuthResult));

        // Act
        await useCase(const RegisterParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
          confirmPassword: tPassword,
          role: UserRole.admin,
          organizationName: 'Test Org',
        ));

        // Assert
        verify(() => mockRepository.register(
              firstName: any(named: 'firstName'),
              lastName: any(named: 'lastName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: UserRole.admin,
              organizationName: 'Test Org',
            )).called(1);
      },
    );
  });
}
