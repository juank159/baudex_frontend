// test/unit/data/repositories/customer_repository_impl_test.dart
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/features/customers/data/datasources/customer_local_datasource.dart';
import 'package:baudex_desktop/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_model.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_response_model.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_query_model.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_stats_model.dart';
import 'package:baudex_desktop/features/customers/data/models/create_customer_request_model.dart';
import 'package:baudex_desktop/features/customers/data/models/update_customer_request_model.dart';
import 'package:baudex_desktop/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/customer_fixtures.dart';
import '../../../mocks/mock_isar.dart';

// Mocks
class MockCustomerRemoteDataSource extends Mock
    implements CustomerRemoteDataSource {}

class MockCustomerLocalDataSource extends Mock
    implements CustomerLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

// Fake classes for mocktail fallback values
class FakeCustomerStatsModel extends Fake implements CustomerStatsModel {}
class FakeCustomerQueryModel extends Fake implements CustomerQueryModel {}
class FakeCreateCustomerRequestModel extends Fake implements CreateCustomerRequestModel {}
class FakeUpdateCustomerRequestModel extends Fake implements UpdateCustomerRequestModel {}

void main() {
  setUpAll(() {
    // Register fallback values for models used with any()
    registerFallbackValue(FakeCustomerStatsModel());
    registerFallbackValue(FakeCustomerQueryModel());
    registerFallbackValue(FakeCreateCustomerRequestModel());
    registerFallbackValue(FakeUpdateCustomerRequestModel());
  });

  late CustomerRepositoryImpl repository;
  late MockCustomerRemoteDataSource mockRemoteDataSource;
  late MockCustomerLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockIsar mockIsar;
  late MockIsarDatabase mockIsarDatabase;

  setUp(() {
    mockRemoteDataSource = MockCustomerRemoteDataSource();
    mockLocalDataSource = MockCustomerLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockIsar = MockIsar();
    mockIsarDatabase = MockIsarDatabase(mockIsar);
    repository = CustomerRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
      database: mockIsarDatabase,
    );

    // Register fallback values
    registerFallbackValue(
      CustomerQueryModel(page: 1, limit: 10),
    );
    registerFallbackValue(
      CreateCustomerRequestModel.fromParams(
        firstName: 'Test',
        lastName: 'Customer',
        email: 'test@example.com',
        documentType: DocumentType.cc,
        documentNumber: '1234567890',
      ),
    );
    registerFallbackValue(
      CustomerModel.fromEntity(
        CustomerFixtures.createCustomerEntity(),
      ),
    );
    registerFallbackValue(
      UpdateCustomerRequestModel.fromParams(
        firstName: 'Test Update',
      ),
    );
  });

  tearDown(() async {
    await mockIsar.clear();
    await mockIsar.close();
  });

  group('CustomerRepositoryImpl - getCustomers', () {
    final tCustomers = CustomerFixtures.createCustomerEntityList(5);
    final tCustomerModels = tCustomers
        .map((e) => CustomerModel.fromEntity(e))
        .toList();
    final tPaginationMeta = PaginationMeta(
      page: 1,
      totalPages: 2,
      totalItems: 10,
      limit: 5,
      hasNextPage: true,
      hasPreviousPage: false,
    );
    final tCustomerResponse = CustomerResponseModel(
      data: tCustomerModels,
      meta: tPaginationMeta,
    );

    test(
      'should check if device is online when getCustomers is called',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomers(any()))
            .thenAnswer((_) async => tCustomerResponse);
        when(() => mockLocalDataSource.cacheCustomers(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getCustomers();

        // Assert
        verify(() => mockNetworkInfo.isConnected).called(1);
      },
    );

    test(
      'should return remote data when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomers(any()))
            .thenAnswer((_) async => tCustomerResponse);
        when(() => mockLocalDataSource.cacheCustomers(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getCustomers();

        // Assert
        verify(() => mockRemoteDataSource.getCustomers(any())).called(1);
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 5);
            expect(paginatedResult.meta.page, 1);
            expect(paginatedResult.meta.totalItems, 10);
          },
        );
      },
    );

    test(
      'should cache data when online request succeeds',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomers(any()))
            .thenAnswer((_) async => tCustomerResponse);
        when(() => mockLocalDataSource.cacheCustomers(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getCustomers();

        // Assert
        verify(() => mockLocalDataSource.cacheCustomers(any())).called(1);
      },
    );

    test(
      'should return cached data when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedCustomers())
            .thenAnswer((_) async => tCustomerModels);

        // Act
        final result = await repository.getCustomers();

        // Assert
        verify(() => mockLocalDataSource.getCachedCustomers()).called(1);
        verifyNever(() => mockRemoteDataSource.getCustomers(any()));
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 5);
          },
        );
      },
    );

    test(
      'should return cached data when remote call fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomers(any()))
            .thenThrow(const ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedCustomers())
            .thenAnswer((_) async => tCustomerModels);

        // Act
        final result = await repository.getCustomers();

        // Assert
        verify(() => mockLocalDataSource.getCachedCustomers()).called(1);
        expect(result.isRight(), true);
      },
    );

    test(
      'should return CacheFailure when both remote and cache fail',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomers(any()))
            .thenThrow(const ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedCustomers())
            .thenThrow(const CacheException('Cache error'));

        // Act
        final result = await repository.getCustomers();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should pass query parameters correctly',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomers(any()))
            .thenAnswer((_) async => tCustomerResponse);
        when(() => mockLocalDataSource.cacheCustomers(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getCustomers(
          page: 2,
          limit: 20,
          search: 'test',
          status: CustomerStatus.active,
        );

        // Assert
        verify(() => mockRemoteDataSource.getCustomers(
          any(that: predicate<CustomerQueryModel>((query) =>
              query.page == 2 &&
              query.limit == 20 &&
              query.search == 'test' &&
              query.status == CustomerStatus.active.name)),
        )).called(1);
      },
    );
  });

  group('CustomerRepositoryImpl - getCustomerById', () {
    final tCustomer = CustomerFixtures.createCustomerEntity();
    final tCustomerModel = CustomerModel.fromEntity(tCustomer);

    test(
      'should return remote data when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomerById(any()))
            .thenAnswer((_) async => tCustomerModel);
        when(() => mockLocalDataSource.cacheCustomer(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getCustomerById('cust-001');

        // Assert
        verify(() => mockRemoteDataSource.getCustomerById('cust-001')).called(1);
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (customer) {
            expect(customer.id, 'cust-001');
            expect(customer.firstName, 'John');
          },
        );
      },
    );

    test(
      'should cache customer after successful remote fetch',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomerById(any()))
            .thenAnswer((_) async => tCustomerModel);
        when(() => mockLocalDataSource.cacheCustomer(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getCustomerById('cust-001');

        // Assert
        verify(() => mockLocalDataSource.cacheCustomer(any())).called(1);
      },
    );

    test(
      'should return cached data when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedCustomer(any()))
            .thenAnswer((_) async => tCustomerModel);

        // Act
        final result = await repository.getCustomerById('cust-001');

        // Assert
        verify(() => mockLocalDataSource.getCachedCustomer('cust-001')).called(1);
        verifyNever(() => mockRemoteDataSource.getCustomerById(any()));
        expect(result.isRight(), true);
      },
    );

    test(
      'should return cached data when remote call fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomerById(any()))
            .thenThrow(const ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedCustomer(any()))
            .thenAnswer((_) async => tCustomerModel);

        // Act
        final result = await repository.getCustomerById('cust-001');

        // Assert
        expect(result.isRight(), true);
      },
    );

    test(
      'should return ServerFailure when both remote and cache fail',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomerById(any()))
            .thenThrow(const ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedCustomer(any()))
            .thenThrow(const CacheException('Cache error'));

        // Act
        final result = await repository.getCustomerById('cust-001');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('CustomerRepositoryImpl - createCustomer', () {
    final tCustomer = CustomerFixtures.createCustomerEntity();
    final tCustomerModel = CustomerModel.fromEntity(tCustomer);

    test(
      'should create customer remotely when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.createCustomer(any()))
            .thenAnswer((_) async => tCustomerModel);
        when(() => mockLocalDataSource.cacheCustomer(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.clearCustomerCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@example.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );

        // Assert
        verify(() => mockRemoteDataSource.createCustomer(any())).called(1);
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (customer) {
            expect(customer.firstName, 'John');
            expect(customer.lastName, 'Doe');
          },
        );
      },
    );

    test(
      'should cache created customer',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.createCustomer(any()))
            .thenAnswer((_) async => tCustomerModel);
        when(() => mockLocalDataSource.cacheCustomer(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.clearCustomerCache())
            .thenAnswer((_) async => {});

        // Act
        await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@example.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );

        // Assert
        verify(() => mockLocalDataSource.cacheCustomer(any())).called(1);
        verify(() => mockLocalDataSource.clearCustomerCache()).called(1);
      },
    );

    test(
      'should create customer offline when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@example.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );

        // Assert
        verifyNever(() => mockRemoteDataSource.createCustomer(any()));
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (customer) {
            expect(customer.id, startsWith('customer_offline_'));
            expect(customer.firstName, 'John');
          },
        );
      },
    );

    test(
      'should fallback to offline creation when remote fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.createCustomer(any()))
            .thenThrow(const ServerException('Server error'));

        // Act
        final result = await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@example.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right - offline fallback'),
          (customer) {
            expect(customer.id, startsWith('customer_offline_'));
          },
        );
      },
    );
  });

  group('CustomerRepositoryImpl - updateCustomer', () {
    final tCustomer = CustomerFixtures.createCustomerEntity();
    final tCustomerModel = CustomerModel.fromEntity(tCustomer);

    test(
      'should update customer remotely when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.updateCustomer(any(), any()))
            .thenAnswer((_) async => tCustomerModel);
        when(() => mockLocalDataSource.cacheCustomer(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.clearCustomerCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateCustomer(
          id: 'cust-001',
          firstName: 'Jane',
        );

        // Assert
        verify(() => mockRemoteDataSource.updateCustomer('cust-001', any()))
            .called(1);
        expect(result.isRight(), true);
      },
    );

    test(
      'should return ValidationFailure when no fields to update',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        // Act
        final result = await repository.updateCustomer(
          id: 'cust-001',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should fallback to offline update when remote fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.updateCustomer(any(), any()))
            .thenThrow(const ServerException('Server error'));
        when(() => mockLocalDataSource.getCachedCustomer(any()))
            .thenAnswer((_) async => tCustomerModel);
        when(() => mockLocalDataSource.cacheCustomer(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateCustomer(
          id: 'cust-001',
          firstName: 'Jane',
        );

        // Assert
        expect(result.isRight(), true);
      },
    );

    test(
      'should update customer offline when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedCustomer(any()))
            .thenAnswer((_) async => tCustomerModel);
        when(() => mockLocalDataSource.cacheCustomer(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateCustomer(
          id: 'cust-001',
          firstName: 'Jane',
        );

        // Assert
        verifyNever(() => mockRemoteDataSource.updateCustomer(any(), any()));
        expect(result.isRight(), true);
      },
    );
  });

  group('CustomerRepositoryImpl - deleteCustomer', () {
    test(
      'should delete customer remotely when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteCustomer(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.removeCachedCustomer(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.clearCustomerCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteCustomer('cust-001');

        // Assert
        verify(() => mockRemoteDataSource.deleteCustomer('cust-001')).called(1);
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (unit) => expect(unit, equals(unit)),
        );
      },
    );

    test(
      'should remove from cache after successful delete',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteCustomer(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.removeCachedCustomer(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.clearCustomerCache())
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteCustomer('cust-001');

        // Assert
        verify(() => mockLocalDataSource.removeCachedCustomer('cust-001'))
            .called(1);
        verify(() => mockLocalDataSource.clearCustomerCache()).called(1);
      },
    );

    test(
      'should fallback to offline delete when remote fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.deleteCustomer(any()))
            .thenThrow(const ServerException('Server error'));
        when(() => mockLocalDataSource.removeCachedCustomer(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.clearCustomerCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteCustomer('cust-001');

        // Assert
        expect(result.isRight(), true);
      },
    );

    test(
      'should delete customer offline when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.removeCachedCustomer(any()))
            .thenAnswer((_) async => {});
        when(() => mockLocalDataSource.clearCustomerCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteCustomer('cust-001');

        // Assert
        verifyNever(() => mockRemoteDataSource.deleteCustomer(any()));
        expect(result.isRight(), true);
      },
    );
  });

  group('CustomerRepositoryImpl - searchCustomers', () {
    final tCustomers = CustomerFixtures.createCustomerEntityList(3);
    final tCustomerModels = tCustomers
        .map((e) => CustomerModel.fromEntity(e))
        .toList();

    test(
      'should return search results when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.searchCustomers(any(), any()))
            .thenAnswer((_) async => tCustomerModels);

        // Act
        final result = await repository.searchCustomers('john');

        // Assert
        verify(() => mockRemoteDataSource.searchCustomers('john', 10)).called(1);
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (customers) => expect(customers.length, 3),
        );
      },
    );

    test(
      'should return ConnectionFailure when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.searchCustomers('john');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('CustomerRepositoryImpl - getCustomerStats', () {
    final tStatsModel = CustomerStatsModel(
      total: 100,
      active: 80,
      inactive: 15,
      suspended: 5,
      totalCreditLimit: 100000000.0,
      totalBalance: 50000000.0,
      activePercentage: 80.0,
      customersWithOverdue: 10,
      averagePurchaseAmount: 500000.0,
    );

    test(
      'should return stats when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomerStats())
            .thenAnswer((_) async => tStatsModel);
        when(() => mockLocalDataSource.cacheCustomerStats(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getCustomerStats();

        // Assert
        verify(() => mockRemoteDataSource.getCustomerStats()).called(1);
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (stats) {
            expect(stats.total, 100);
            expect(stats.active, 80);
          },
        );
      },
    );

    test(
      'should cache stats after successful fetch',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCustomerStats())
            .thenAnswer((_) async => tStatsModel);
        when(() => mockLocalDataSource.cacheCustomerStats(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.getCustomerStats();

        // Assert
        verify(() => mockLocalDataSource.cacheCustomerStats(any())).called(1);
      },
    );

    test(
      'should return cached stats when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedCustomerStats())
            .thenAnswer((_) async => tStatsModel);

        // Act
        final result = await repository.getCustomerStats();

        // Assert
        verify(() => mockLocalDataSource.getCachedCustomerStats()).called(1);
        expect(result.isRight(), true);
      },
    );
  });
}
