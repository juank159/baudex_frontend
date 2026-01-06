// test/unit/domain/usecases/products/get_product_stats_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_stats.dart';
import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_product_stats_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock repository
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late GetProductStatsUseCase useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProductStatsUseCase(mockRepository);
  });

  group('GetProductStatsUseCase', () {
    const tProductStats = ProductStats(
      total: 100,
      active: 85,
      inactive: 10,
      outOfStock: 5,
      lowStock: 15,
      activePercentage: 85.0,
      totalValue: 5000000.0,
      averagePrice: 50000.0,
    );

    test('should call repository.getProductStats', () async {
      // Arrange
      when(() => mockRepository.getProductStats())
          .thenAnswer((_) async => const Right(tProductStats));

      // Act
      await useCase(NoParams());

      // Assert
      verify(() => mockRepository.getProductStats()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ProductStats when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.getProductStats())
          .thenAnswer((_) async => const Right(tProductStats));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result, const Right(tProductStats));
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return stats'),
        (stats) {
          expect(stats.total, 100);
          expect(stats.active, 85);
          expect(stats.inactive, 10);
          expect(stats.outOfStock, 5);
          expect(stats.lowStock, 15);
          expect(stats.totalValue, 5000000.0);
          expect(stats.averagePrice, 50000.0);
        },
      );
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to get stats');
      when(() => mockRepository.getProductStats())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return stats with zero values when no products exist', () async {
      // Arrange
      const tEmptyStats = ProductStats(
        total: 0,
        active: 0,
        inactive: 0,
        outOfStock: 0,
        lowStock: 0,
        activePercentage: 0.0,
        totalValue: 0.0,
        averagePrice: 0.0,
      );

      when(() => mockRepository.getProductStats())
          .thenAnswer((_) async => const Right(tEmptyStats));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return stats'),
        (stats) {
          expect(stats.total, 0);
          expect(stats.active, 0);
          expect(stats.totalValue, 0.0);
          expect(stats.averagePrice, 0.0);
        },
      );
    });

    test('should return NetworkFailure when offline', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.getProductStats())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return CacheFailure when offline and no cached data', () async {
      // Arrange
      const tFailure = CacheFailure('No cached data available');
      when(() => mockRepository.getProductStats())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle stats with high values', () async {
      // Arrange
      const tHighValueStats = ProductStats(
        total: 10000,
        active: 9500,
        inactive: 300,
        outOfStock: 200,
        lowStock: 500,
        activePercentage: 95.0,
        totalValue: 500000000.0, // 500 million
        averagePrice: 50000.0,
      );

      when(() => mockRepository.getProductStats())
          .thenAnswer((_) async => const Right(tHighValueStats));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return stats'),
        (stats) {
          expect(stats.total, 10000);
          expect(stats.totalValue, 500000000.0);
        },
      );
    });

    test('should validate stats consistency (total = active + inactive + outOfStock)', () async {
      // Arrange
      when(() => mockRepository.getProductStats())
          .thenAnswer((_) async => const Right(tProductStats));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return stats'),
        (stats) {
          // Validate that total equals sum of statuses
          expect(
            stats.total,
            stats.active + stats.inactive + stats.outOfStock,
          );
        },
      );
    });

    test('should handle stats with fractional values', () async {
      // Arrange
      const tFractionalStats = ProductStats(
        total: 100,
        active: 85,
        inactive: 10,
        outOfStock: 5,
        lowStock: 15,
        activePercentage: 85.0,
        totalValue: 5234567.89,
        averagePrice: 52345.67,
      );

      when(() => mockRepository.getProductStats())
          .thenAnswer((_) async => const Right(tFractionalStats));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return stats'),
        (stats) {
          expect(stats.totalValue, 5234567.89);
          expect(stats.averagePrice, 52345.67);
        },
      );
    });

    test('should return stats even when lowStock is high', () async {
      // Arrange
      const tHighLowStockStats = ProductStats(
        total: 100,
        active: 100,
        inactive: 0,
        outOfStock: 0,
        lowStock: 75, // 75% of products low stock
        activePercentage: 100.0,
        totalValue: 5000000.0,
        averagePrice: 50000.0,
      );

      when(() => mockRepository.getProductStats())
          .thenAnswer((_) async => const Right(tHighLowStockStats));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return stats'),
        (stats) {
          expect(stats.lowStock, 75);
          expect(stats.active, 100);
        },
      );
    });
  });
}
