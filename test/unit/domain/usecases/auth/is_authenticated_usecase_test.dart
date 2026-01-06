// test/unit/domain/usecases/auth/is_authenticated_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/is_authenticated_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late IsAuthenticatedUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = IsAuthenticatedUseCase(mockRepository);
  });

  group('IsAuthenticatedUseCase - call', () {
    test(
      'should call repository isAuthenticated',
      () async {
        // Arrange
        when(() => mockRepository.isAuthenticated()).thenAnswer((_) async => const Right(true));

        // Act
        await useCase(NoParams());

        // Assert
        verify(() => mockRepository.isAuthenticated()).called(1);
      },
    );

    test(
      'should return true when user is authenticated',
      () async {
        // Arrange
        when(() => mockRepository.isAuthenticated()).thenAnswer((_) async => const Right(true));

        // Act
        final result = await useCase(NoParams());

        // Assert
        expect(result, const Right(true));
      },
    );

    test(
      'should return false when user is not authenticated',
      () async {
        // Arrange
        when(() => mockRepository.isAuthenticated()).thenAnswer((_) async => const Right(false));

        // Act
        final result = await useCase(NoParams());

        // Assert
        expect(result, const Right(false));
      },
    );

    test(
      'should return Failure when check fails',
      () async {
        // Arrange
        const tFailure = CacheFailure('Authentication check failed');
        when(() => mockRepository.isAuthenticated()).thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase(NoParams());

        // Assert
        expect(result, const Left(tFailure));
      },
    );
  });
}
