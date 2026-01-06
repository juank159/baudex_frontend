// test/unit/domain/usecases/auth/register_with_onboarding_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/auth/domain/entities/auth_result.dart';
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:baudex_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/register_with_onboarding_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/auth_fixtures.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterWithOnboardingUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterWithOnboardingUseCase(mockRepository);
  });

  const tFirstName = AuthFixtures.testFirstName;
  const tLastName = AuthFixtures.testLastName;
  const tEmail = AuthFixtures.testEmail;
  const tPassword = 'Password123';
  final tAuthResult = AuthFixtures.createAuthResult();

  group('RegisterWithOnboardingUseCase - call', () {
    test(
      'should return AuthResult when registration with onboarding succeeds',
      () async {
        // Arrange
        when(() => mockRepository.registerWithOnboarding(
              firstName: any(named: 'firstName'),
              lastName: any(named: 'lastName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
              organizationName: any(named: 'organizationName'),
            )).thenAnswer((_) async => Right(tAuthResult));

        // Act
        final result = await useCase(const RegisterWithOnboardingParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
          confirmPassword: tPassword,
        ));

        // Assert
        expect(result, Right(tAuthResult));
        verify(() => mockRepository.registerWithOnboarding(
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
        final result = await useCase(const RegisterWithOnboardingParams(
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
      'should return ValidationFailure when passwords do not match',
      () async {
        // Act
        final result = await useCase(const RegisterWithOnboardingParams(
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
      'should return ValidationFailure when password is invalid',
      () async {
        // Act
        final result = await useCase(const RegisterWithOnboardingParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: 'weak',
          confirmPassword: 'weak',
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
      'should pass optional parameters to repository',
      () async {
        // Arrange
        when(() => mockRepository.registerWithOnboarding(
              firstName: any(named: 'firstName'),
              lastName: any(named: 'lastName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
              organizationName: any(named: 'organizationName'),
            )).thenAnswer((_) async => Right(tAuthResult));

        // Act
        await useCase(const RegisterWithOnboardingParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
          confirmPassword: tPassword,
          role: UserRole.admin,
          organizationName: 'Test Org',
        ));

        // Assert
        verify(() => mockRepository.registerWithOnboarding(
              firstName: any(named: 'firstName'),
              lastName: any(named: 'lastName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: UserRole.admin,
              organizationName: 'Test Org',
            )).called(1);
      },
    );

    test(
      'should return ServerFailure when repository fails',
      () async {
        // Arrange
        const tFailure = ServerFailure('Registration failed');
        when(() => mockRepository.registerWithOnboarding(
              firstName: any(named: 'firstName'),
              lastName: any(named: 'lastName'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              role: any(named: 'role'),
              organizationName: any(named: 'organizationName'),
            )).thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase(const RegisterWithOnboardingParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
          confirmPassword: tPassword,
        ));

        // Assert
        expect(result, const Left(tFailure));
      },
    );
  });
}
