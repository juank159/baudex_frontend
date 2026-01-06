// test/unit/domain/usecases/customers/get_customer_stats_usecase_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer_stats.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/get_customer_stats_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock repository
class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late GetCustomerStatsUseCase useCase;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    useCase = GetCustomerStatsUseCase(mockRepository);
  });

  group('GetCustomerStatsUseCase', () {
    final tStats = CustomerStats(
      total: 150,
      active: 120,
      inactive: 25,
      suspended: 5,
      totalCreditLimit: 50000000.0,
      totalBalance: 15000000.0,
      activePercentage: 80.0,
      customersWithOverdue: 20,
      averagePurchaseAmount: 500000.0,
    );

    test('should call repository.getCustomerStats', () async {
      // Arrange
      when(() => mockRepository.getCustomerStats())
          .thenAnswer((_) async => Right(tStats));

      // Act
      await useCase(const NoParams());

      // Assert
      verify(() => mockRepository.getCustomerStats()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return CustomerStats when repository call is successful', () async {
      // Arrange
      when(() => mockRepository.getCustomerStats())
          .thenAnswer((_) async => Right(tStats));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result, Right(tStats));
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return stats'),
        (stats) {
          expect(stats.total, 150);
          expect(stats.active, 120);
          expect(stats.inactive, 25);
          expect(stats.suspended, 5);
          expect(stats.totalCreditLimit, 50000000.0);
          expect(stats.totalBalance, 15000000.0);
          expect(stats.activePercentage, 80.0);
          expect(stats.customersWithOverdue, 20);
          expect(stats.averagePurchaseAmount, 500000.0);
        },
      );
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to get stats');
      when(() => mockRepository.getCustomerStats())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return NetworkFailure when network is unavailable', () async {
      // Arrange
      const tFailure = NetworkFailure('No internet connection');
      when(() => mockRepository.getCustomerStats())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should return CacheFailure when offline and no cached data', () async {
      // Arrange
      const tFailure = CacheFailure('No cached data available');
      when(() => mockRepository.getCustomerStats())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result, const Left(tFailure));
      expect(result.isLeft(), true);
    });

    test('should handle zero customers scenario', () async {
      // Arrange
      final tEmptyStats = CustomerStats(
        total: 0,
        active: 0,
        inactive: 0,
        suspended: 0,
        totalCreditLimit: 0.0,
        totalBalance: 0.0,
        activePercentage: 0.0,
        customersWithOverdue: 0,
        averagePurchaseAmount: 0.0,
      );
      when(() => mockRepository.getCustomerStats())
          .thenAnswer((_) async => Right(tEmptyStats));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return empty stats'),
        (stats) {
          expect(stats.total, 0);
          expect(stats.active, 0);
          expect(stats.activePercentage, 0.0);
        },
      );
    });

    test('should calculate correct percentages', () async {
      // Arrange
      final tStatsWithPercentage = CustomerStats(
        total: 100,
        active: 75,
        inactive: 20,
        suspended: 5,
        totalCreditLimit: 10000000.0,
        totalBalance: 2000000.0,
        activePercentage: 75.0,
        customersWithOverdue: 15,
        averagePurchaseAmount: 300000.0,
      );
      when(() => mockRepository.getCustomerStats())
          .thenAnswer((_) async => Right(tStatsWithPercentage));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return stats'),
        (stats) {
          expect(stats.total, 100);
          expect(stats.active, 75);
          expect(stats.activePercentage, 75.0);
          expect(stats.inactive + stats.active + stats.suspended, stats.total);
        },
      );
    });

    test('should handle large numbers', () async {
      // Arrange
      final tLargeStats = CustomerStats(
        total: 10000,
        active: 8500,
        inactive: 1400,
        suspended: 100,
        totalCreditLimit: 500000000000.0,
        totalBalance: 100000000000.0,
        activePercentage: 85.0,
        customersWithOverdue: 500,
        averagePurchaseAmount: 5000000.0,
      );
      when(() => mockRepository.getCustomerStats())
          .thenAnswer((_) async => Right(tLargeStats));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return stats'),
        (stats) {
          expect(stats.total, 10000);
          expect(stats.totalCreditLimit, greaterThan(100000000000.0));
          expect(stats.totalBalance, greaterThan(0.0));
        },
      );
    });

    test('should handle stats with all active customers', () async {
      // Arrange
      final tAllActiveStats = CustomerStats(
        total: 50,
        active: 50,
        inactive: 0,
        suspended: 0,
        totalCreditLimit: 25000000.0,
        totalBalance: 5000000.0,
        activePercentage: 100.0,
        customersWithOverdue: 10,
        averagePurchaseAmount: 400000.0,
      );
      when(() => mockRepository.getCustomerStats())
          .thenAnswer((_) async => Right(tAllActiveStats));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return stats'),
        (stats) {
          expect(stats.total, 50);
          expect(stats.active, 50);
          expect(stats.activePercentage, 100.0);
          expect(stats.inactive, 0);
          expect(stats.suspended, 0);
        },
      );
    });

    test('should handle stats with high overdue rate', () async {
      // Arrange
      final tHighOverdueStats = CustomerStats(
        total: 100,
        active: 90,
        inactive: 8,
        suspended: 2,
        totalCreditLimit: 50000000.0,
        totalBalance: 40000000.0,
        activePercentage: 90.0,
        customersWithOverdue: 70,
        averagePurchaseAmount: 600000.0,
      );
      when(() => mockRepository.getCustomerStats())
          .thenAnswer((_) async => Right(tHighOverdueStats));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return stats'),
        (stats) {
          expect(stats.customersWithOverdue, greaterThan(stats.total / 2));
          expect(stats.totalBalance / stats.totalCreditLimit, greaterThan(0.5));
        },
      );
    });
  });
}
