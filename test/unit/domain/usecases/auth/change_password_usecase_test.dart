// test/unit/domain/usecases/auth/change_password_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ChangePasswordUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ChangePasswordUseCase(mockRepository);
  });

  const tCurrentPassword = 'CurrentPass123';
  const tNewPassword = 'NewPassword456';

  group('ChangePasswordUseCase - call', () {
    test(
      'should return Unit when password change succeeds',
      () async {
        // Arrange
        when(() => mockRepository.changePassword(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword'),
              confirmPassword: any(named: 'confirmPassword'),
            )).thenAnswer((_) async => const Right(unit));

        // Act
        final result = await useCase(const ChangePasswordParams(
          currentPassword: tCurrentPassword,
          newPassword: tNewPassword,
          confirmPassword: tNewPassword,
        ));

        // Assert
        expect(result, const Right(unit));
        verify(() => mockRepository.changePassword(
              currentPassword: tCurrentPassword,
              newPassword: tNewPassword,
              confirmPassword: tNewPassword,
            )).called(1);
      },
    );

    test(
      'should return ValidationFailure when current password is empty',
      () async {
        // Act
        final result = await useCase(const ChangePasswordParams(
          currentPassword: '',
          newPassword: tNewPassword,
          confirmPassword: tNewPassword,
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.first, contains('contraseña actual es requerida'));
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ValidationFailure when new password is empty',
      () async {
        // Act
        final result = await useCase(const ChangePasswordParams(
          currentPassword: tCurrentPassword,
          newPassword: '',
          confirmPassword: '',
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
      'should return ValidationFailure when new password is too short',
      () async {
        // Act
        final result = await useCase(const ChangePasswordParams(
          currentPassword: tCurrentPassword,
          newPassword: '12345',
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
      'should return ValidationFailure when new password has no lowercase',
      () async {
        // Act
        final result = await useCase(const ChangePasswordParams(
          currentPassword: tCurrentPassword,
          newPassword: 'PASSWORD123',
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
      'should return ValidationFailure when new password has no uppercase',
      () async {
        // Act
        final result = await useCase(const ChangePasswordParams(
          currentPassword: tCurrentPassword,
          newPassword: 'password123',
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
      'should return ValidationFailure when new password has no number',
      () async {
        // Act
        final result = await useCase(const ChangePasswordParams(
          currentPassword: tCurrentPassword,
          newPassword: 'PasswordABC',
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
        final result = await useCase(const ChangePasswordParams(
          currentPassword: tCurrentPassword,
          newPassword: tNewPassword,
          confirmPassword: 'DifferentPassword789',
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
      'should return ValidationFailure when new password is same as current',
      () async {
        // Act
        final result = await useCase(const ChangePasswordParams(
          currentPassword: tCurrentPassword,
          newPassword: tCurrentPassword,
          confirmPassword: tCurrentPassword,
        ));

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).errors.first, contains('debe ser diferente'));
          },
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ServerFailure when repository fails',
      () async {
        // Arrange
        const tFailure = ServerFailure('Current password is incorrect');
        when(() => mockRepository.changePassword(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword'),
              confirmPassword: any(named: 'confirmPassword'),
            )).thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase(const ChangePasswordParams(
          currentPassword: tCurrentPassword,
          newPassword: tNewPassword,
          confirmPassword: tNewPassword,
        ));

        // Assert
        expect(result, const Left(tFailure));
      },
    );
  });
}
