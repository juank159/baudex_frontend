// test/unit/domain/usecases/auth/get_profile_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:baudex_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/auth_fixtures.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetProfileUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetProfileUseCase(mockRepository);
  });

  final tUser = AuthFixtures.createUserEntity();

  group('GetProfileUseCase - call', () {
    test(
      'should call repository getProfile',
      () async {
        // Arrange
        when(() => mockRepository.getProfile()).thenAnswer((_) async => Right(tUser));

        // Act
        await useCase(NoParams());

        // Assert
        verify(() => mockRepository.getProfile()).called(1);
      },
    );

    test(
      'should return User when profile fetch succeeds',
      () async {
        // Arrange
        when(() => mockRepository.getProfile()).thenAnswer((_) async => Right(tUser));

        // Act
        final result = await useCase(NoParams());

        // Assert
        expect(result, Right(tUser));
      },
    );

    test(
      'should return Failure when profile fetch fails',
      () async {
        // Arrange
        const tFailure = ServerFailure('Failed to fetch profile');
        when(() => mockRepository.getProfile()).thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase(NoParams());

        // Assert
        expect(result, const Left(tFailure));
      },
    );

    test(
      'should return CacheFailure when offline and no cache',
      () async {
        // Arrange
        const tFailure = CacheFailure('No cached profile');
        when(() => mockRepository.getProfile()).thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase(NoParams());

        // Assert
        expect(result, const Left(tFailure));
      },
    );
  });
}
