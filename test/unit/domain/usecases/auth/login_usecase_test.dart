// test/unit/domain/usecases/auth/login_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/auth/domain/entities/auth_result.dart';
import 'package:baudex_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/login_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/auth_fixtures.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  const tEmail = AuthFixtures.testEmail;
  const tPassword = AuthFixtures.testPassword;
  final tAuthResult = AuthFixtures.createAuthResult();

  group('LoginUseCase - call', () {
    test(
      'should return AuthResult when login succeeds',
      () async {
        // Arrange
        when(() => mockRepository.login(email: any(named: 'email'), password: any(named: 'password')))
            .thenAnswer((_) async => Right(tAuthResult));

        // Act
        final result = await useCase(const LoginParams(
          email: tEmail,
          password: tPassword,
        ));

        // Assert
        expect(result, Right(tAuthResult));
        verify(() => mockRepository.login(email: any(named: 'email'), password: any(named: 'password'))).called(1);
      },
    );

    test(
      'should return ServerFailure when login fails',
      () async {
        // Arrange
        const tFailure = ServerFailure('Invalid credentials');
        when(() => mockRepository.login(email: any(named: 'email'), password: any(named: 'password')))
            .thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase(const LoginParams(
          email: tEmail,
          password: tPassword,
        ));

        // Assert
        expect(result, const Left(tFailure));
      },
    );

    test(
      'should return ValidationFailure when email is empty',
      () async {
        // Act
        final result = await useCase(const LoginParams(
          email: '',
          password: tPassword,
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.first, contains('email es requerido'));
          },
          (_) => fail('Should return Left'),
        );
        verifyNever(() => mockRepository.login(email: any(named: 'email'), password: any(named: 'password')));
      },
    );

    test(
      'should return ValidationFailure when email format is invalid',
      () async {
        // Act
        final result = await useCase(const LoginParams(
          email: 'invalid-email',
          password: tPassword,
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
      'should return ValidationFailure when password is empty',
      () async {
        // Act
        final result = await useCase(const LoginParams(
          email: tEmail,
          password: '',
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.first, contains('contraseña es requerida'));
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ValidationFailure when password is too short',
      () async {
        // Act
        final result = await useCase(const LoginParams(
          email: tEmail,
          password: '12345',
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.first, contains('al menos 6 caracteres'));
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ValidationFailure with multiple errors',
      () async {
        // Act
        final result = await useCase(const LoginParams(
          email: 'invalid',
          password: '123',
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.length, greaterThan(1));
          },
          (_) => fail('Should return Left'),
        );
      },
    );
  });
}
