// test/unit/domain/usecases/auth/logout_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/logout_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LogoutUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LogoutUseCase(mockRepository);
  });

  group('LogoutUseCase - call', () {
    test(
      'should call repository logout',
      () async {
        // Arrange
        when(() => mockRepository.logout()).thenAnswer((_) async => const Right(unit));

        // Act
        await useCase(NoParams());

        // Assert
        verify(() => mockRepository.logout()).called(1);
      },
    );

    test(
      'should return Unit when logout succeeds',
      () async {
        // Arrange
        when(() => mockRepository.logout()).thenAnswer((_) async => const Right(unit));

        // Act
        final result = await useCase(NoParams());

        // Assert
        expect(result, const Right(unit));
      },
    );

    test(
      'should return Failure when logout fails',
      () async {
        // Arrange
        const tFailure = CacheFailure('Logout failed');
        when(() => mockRepository.logout()).thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase(NoParams());

        // Assert
        expect(result, const Left(tFailure));
      },
    );
  });
}
