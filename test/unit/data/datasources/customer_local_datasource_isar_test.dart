// test/unit/data/datasources/customer_local_datasource_isar_test.dart
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/features/customers/data/datasources/customer_local_datasource.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_model.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_stats_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:convert';

import '../../../fixtures/customer_fixtures.dart';

// Mocks
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late CustomerLocalDataSourceImpl dataSource;
  late MockSecureStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockSecureStorageService();
    dataSource = CustomerLocalDataSourceImpl(storageService: mockStorageService);
  });

  group('CustomerLocalDataSource - cacheCustomers', () {
    final tCustomers = CustomerFixtures.createCustomerEntityList(3);
    final tCustomerModels = tCustomers.map((e) => CustomerModel.fromEntity(e)).toList();

    test('should cache list of customers', () async {
      // Arrange
      when(() => mockStorageService.write(any(), any())).thenAnswer((_) async => {});

      // Act
      await dataSource.cacheCustomers(tCustomerModels);

      // Assert
      verify(() => mockStorageService.write('cached_customers', any())).called(1);
      verify(() => mockStorageService.write('customers_cache_timestamp', any())).called(1);
    });

    test('should serialize customers to JSON', () async {
      // Arrange
      String? capturedData;
      when(() => mockStorageService.write('cached_customers', any())).thenAnswer((invocation) async {
        capturedData = invocation.positionalArguments[1] as String;
      });
      when(() => mockStorageService.write('customers_cache_timestamp', any())).thenAnswer((_) async => {});

      // Act
      await dataSource.cacheCustomers(tCustomerModels);

      // Assert
      expect(capturedData, isNotNull);
      final decodedData = json.decode(capturedData!) as List;
      expect(decodedData.length, 3);
    });

    test('should not throw on storage failure', () async {
      // Arrange
      when(() => mockStorageService.write(any(), any())).thenThrow(Exception('Storage error'));

      // Act & Assert - should not throw
      await dataSource.cacheCustomers(tCustomerModels);
    });
  });

  group('CustomerLocalDataSource - getCachedCustomers', () {
    final tCustomers = CustomerFixtures.createCustomerEntityList(3);
    final tCustomerModels = tCustomers.map((e) => CustomerModel.fromEntity(e)).toList();
    final tCachedData = json.encode(tCustomerModels.map((e) => e.toJson()).toList());

    test('should return cached customers', () async {
      // Arrange
      when(() => mockStorageService.read('cached_customers')).thenAnswer((_) async => tCachedData);

      // Act
      final result = await dataSource.getCachedCustomers();

      // Assert
      expect(result, isA<List<CustomerModel>>());
      expect(result.length, 3);
    });

    test('should throw CacheException when cache is empty', () async {
      // Arrange
      when(() => mockStorageService.read('cached_customers')).thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => dataSource.getCachedCustomers(),
        throwsA(isA<CacheException>()),
      );
    });

    test('should throw CacheException on JSON decode error', () async {
      // Arrange
      when(() => mockStorageService.read('cached_customers')).thenAnswer((_) async => 'invalid json');

      // Act & Assert
      expect(
        () => dataSource.getCachedCustomers(),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('CustomerLocalDataSource - cacheCustomer', () {
    final tCustomer = CustomerFixtures.createCustomerEntity();
    final tCustomerModel = CustomerModel.fromEntity(tCustomer);

    test('should cache individual customer', () async {
      // Arrange
      when(() => mockStorageService.write(any(), any())).thenAnswer((_) async => {});

      // Act
      await dataSource.cacheCustomer(tCustomerModel);

      // Assert
      verify(() => mockStorageService.write('cached_customer_${tCustomer.id}', any())).called(1);
    });

    test('should serialize customer to JSON', () async {
      // Arrange
      String? capturedData;
      when(() => mockStorageService.write(any(), any())).thenAnswer((invocation) {
        if (invocation.positionalArguments[0].toString().contains('cached_customer_')) {
          capturedData = invocation.positionalArguments[1] as String;
        }
        return Future.value();
      });

      // Act
      await dataSource.cacheCustomer(tCustomerModel);

      // Assert
      expect(capturedData, isNotNull);
      final decodedData = json.decode(capturedData!) as Map<String, dynamic>;
      expect(decodedData['id'], tCustomer.id);
    });
  });

  group('CustomerLocalDataSource - getCachedCustomer', () {
    final tCustomer = CustomerFixtures.createCustomerEntity();
    final tCustomerModel = CustomerModel.fromEntity(tCustomer);
    final tCachedData = json.encode(tCustomerModel.toJson());

    test('should return cached customer by id', () async {
      // Arrange
      when(() => mockStorageService.read('cached_customer_${tCustomer.id}')).thenAnswer((_) async => tCachedData);

      // Act
      final result = await dataSource.getCachedCustomer(tCustomer.id);

      // Assert
      expect(result, isA<CustomerModel>());
      expect(result!.id, tCustomer.id);
    });

    test('should return null when customer not cached', () async {
      // Arrange
      when(() => mockStorageService.read(any())).thenAnswer((_) async => null);

      // Act
      final result = await dataSource.getCachedCustomer('non-existent');

      // Assert
      expect(result, isNull);
    });

    test('should throw CacheException on JSON decode error', () async {
      // Arrange
      when(() => mockStorageService.read(any())).thenAnswer((_) async => 'invalid');

      // Act & Assert
      expect(
        () => dataSource.getCachedCustomer('test-id'),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('CustomerLocalDataSource - removeCachedCustomer', () {
    const tCustomerId = 'cust-001';

    test('should delete customer from cache', () async {
      // Arrange
      when(() => mockStorageService.delete(any())).thenAnswer((_) async => {});

      // Act
      await dataSource.removeCachedCustomer(tCustomerId);

      // Assert
      verify(() => mockStorageService.delete('cached_customer_$tCustomerId')).called(1);
    });

    test('should throw CacheException on deletion error', () async {
      // Arrange
      when(() => mockStorageService.delete(any())).thenThrow(Exception('Delete error'));

      // Act & Assert
      expect(
        () => dataSource.removeCachedCustomer(tCustomerId),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('CustomerLocalDataSource - clearCustomerCache', () {
    test('should clear all customer cache', () async {
      // Arrange
      when(() => mockStorageService.delete(any())).thenAnswer((_) async => {});
      when(() => mockStorageService.readAll()).thenAnswer((_) async => {
            'cached_customer_001': 'data',
            'cached_customer_002': 'data',
            'other_key': 'data',
          });

      // Act
      await dataSource.clearCustomerCache();

      // Assert
      verify(() => mockStorageService.delete('cached_customers')).called(1);
      verify(() => mockStorageService.delete('cached_customer_stats')).called(1);
      verify(() => mockStorageService.delete('customers_cache_timestamp')).called(1);
    });

    test('should clear individual customer caches', () async {
      // Arrange
      when(() => mockStorageService.delete(any())).thenAnswer((_) async => {});
      when(() => mockStorageService.readAll()).thenAnswer((_) async => {
            'cached_customer_001': 'data',
            'cached_customer_002': 'data',
          });

      // Act
      await dataSource.clearCustomerCache();

      // Assert
      verify(() => mockStorageService.delete('cached_customer_001')).called(1);
      verify(() => mockStorageService.delete('cached_customer_002')).called(1);
    });
  });

  group('CustomerLocalDataSource - cacheCustomerStats', () {
    final tStats = CustomerStatsModel(
      total: 100,
      active: 80,
      inactive: 15,
      suspended: 5,
      totalCreditLimit: 50000000.0,
      totalBalance: 10000000.0,
      activePercentage: 80.0,
      customersWithOverdue: 10,
      averagePurchaseAmount: 250000.0,
    );

    test('should cache customer stats', () async {
      // Arrange
      when(() => mockStorageService.write(any(), any())).thenAnswer((_) async => {});

      // Act
      await dataSource.cacheCustomerStats(tStats);

      // Assert
      verify(() => mockStorageService.write('cached_customer_stats', any())).called(1);
    });
  });

  group('CustomerLocalDataSource - getCachedCustomerStats', () {
    final tStats = CustomerStatsModel(
      total: 100,
      active: 80,
      inactive: 15,
      suspended: 5,
      totalCreditLimit: 50000000.0,
      totalBalance: 10000000.0,
      activePercentage: 80.0,
      customersWithOverdue: 10,
      averagePurchaseAmount: 250000.0,
    );
    final tCachedData = json.encode(tStats.toJson());

    test('should return cached stats', () async {
      // Arrange
      when(() => mockStorageService.read('cached_customer_stats')).thenAnswer((_) async => tCachedData);

      // Act
      final result = await dataSource.getCachedCustomerStats();

      // Assert
      expect(result, isA<CustomerStatsModel>());
      expect(result!.total, 100);
    });

    test('should return null when stats not cached', () async {
      // Arrange
      when(() => mockStorageService.read(any())).thenAnswer((_) async => null);

      // Act
      final result = await dataSource.getCachedCustomerStats();

      // Assert
      expect(result, isNull);
    });
  });

  group('CustomerLocalDataSource - isCacheValid', () {
    test('should return true when cache is valid', () async {
      // Arrange
      final validTimestamp = DateTime.now().subtract(const Duration(minutes: 15));
      when(() => mockStorageService.read('customers_cache_timestamp')).thenAnswer(
        (_) async => validTimestamp.toIso8601String(),
      );

      // Act
      final result = await dataSource.isCacheValid();

      // Assert
      expect(result, true);
    });

    test('should return false when cache is expired', () async {
      // Arrange
      final expiredTimestamp = DateTime.now().subtract(const Duration(minutes: 35));
      when(() => mockStorageService.read('customers_cache_timestamp')).thenAnswer(
        (_) async => expiredTimestamp.toIso8601String(),
      );

      // Act
      final result = await dataSource.isCacheValid();

      // Assert
      expect(result, false);
    });

    test('should return false when no timestamp exists', () async {
      // Arrange
      when(() => mockStorageService.read(any())).thenAnswer((_) async => null);

      // Act
      final result = await dataSource.isCacheValid();

      // Assert
      expect(result, false);
    });

    test('should return false on timestamp parse error', () async {
      // Arrange
      when(() => mockStorageService.read(any())).thenAnswer((_) async => 'invalid date');

      // Act
      final result = await dataSource.isCacheValid();

      // Assert
      expect(result, false);
    });
  });
}
