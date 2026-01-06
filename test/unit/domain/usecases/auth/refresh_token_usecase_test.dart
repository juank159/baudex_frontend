// test/unit/domain/usecases/auth/refresh_token_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/auth_fixtures.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RefreshTokenUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RefreshTokenUseCase(mockRepository);
  });

  const tToken = AuthFixtures.testToken;

  group('RefreshTokenUseCase - call', () {
    test(
      'should call repository refreshToken',
      () async {
        // Arrange
        when(() => mockRepository.refreshToken()).thenAnswer((_) async => const Right(tToken));

        // Act
        await useCase(NoParams());

        // Assert
        verify(() => mockRepository.refreshToken()).called(1);
      },
    );

    test(
      'should return new token when refresh succeeds',
      () async {
        // Arrange
        when(() => mockRepository.refreshToken()).thenAnswer((_) async => const Right(tToken));

        // Act
        final result = await useCase(NoParams());

        // Assert
        expect(result, const Right(tToken));
      },
    );

    test(
      'should return ServerFailure when refresh fails',
      () async {
        // Arrange
        const tFailure = ServerFailure('Invalid refresh token');
        when(() => mockRepository.refreshToken()).thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase(NoParams());

        // Assert
        expect(result, const Left(tFailure));
      },
    );

    test(
      'should return ConnectionFailure when device is offline',
      () async {
        // Arrange
        const tFailure = ConnectionFailure('No internet connection');
        when(() => mockRepository.refreshToken()).thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase(NoParams());

        // Assert
        expect(result, const Left(tFailure));
      },
    );
  });
}
