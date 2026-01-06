// test/unit/data/datasources/customer_remote_datasource_test.dart
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:baudex_desktop/features/customers/data/models/create_customer_request_model.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_model.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_query_model.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_response_model.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_stats_model.dart';
import 'package:baudex_desktop/features/customers/data/models/update_customer_request_model.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/customer_fixtures.dart';

// Mocks
class MockDioClient extends Mock implements DioClient {}

void main() {
  late CustomerRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = CustomerRemoteDataSourceImpl(dioClient: mockDioClient);

    // Register fallback values
    registerFallbackValue(CustomerQueryModel(page: 1, limit: 10));
  });

  group('CustomerRemoteDataSource - getCustomers', () {
    final tCustomers = CustomerFixtures.createCustomerEntityList(5);
    final tCustomerModels = tCustomers
        .map((e) => CustomerModel.fromEntity(e))
        .toList();

    final tResponseData = {
      'success': true,
      'data': tCustomerModels.map((e) => e.toJson()).toList(),
      'meta': {
        'page': 1,
        'totalPages': 2,
        'totalItems': 10,
        'limit': 5,
        'hasNextPage': true,
        'hasPreviousPage': false,
      },
      'message': 'Customers retrieved successfully',
    };

    test(
      'should perform GET request to /customers with query parameters',
      () async {
        // Arrange
        final query = CustomerQueryModel(
          page: 1,
          limit: 10,
          search: 'test',
          status: 'active',
        );

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/customers'),
          ),
        );

        // Act
        await dataSource.getCustomers(query);

        // Assert
        verify(() => mockDioClient.get(
              '/customers',
              queryParameters: query.toQueryParameters(),
            )).called(1);
      },
    );

    test(
      'should return CustomerResponseModel when status code is 200',
      () async {
        // Arrange
        final query = CustomerQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/customers'),
          ),
        );

        // Act
        final result = await dataSource.getCustomers(query);

        // Assert
        expect(result, isA<CustomerResponseModel>());
        expect(result.data.length, 5);
        expect(result.meta.page, 1);
      },
    );

    test(
      'should throw ServerException when status code is 404',
      () async {
        // Arrange
        final query = CustomerQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Not found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: '/customers'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getCustomers(query),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw ConnectionException on DioException with no response',
      () async {
        // Arrange
        final query = CustomerQueryModel(page: 1, limit: 10);

        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/customers'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getCustomers(query),
          throwsA(isA<ConnectionException>()),
        );
      },
    );
  });

  group('CustomerRemoteDataSource - getCustomerById', () {
    const tCustomerId = 'cust-001';
    final tCustomer = CustomerFixtures.createCustomerEntity(id: tCustomerId);
    final tCustomerModel = CustomerModel.fromEntity(tCustomer);

    final tResponseData = {
      'success': true,
      'data': tCustomerModel.toJson(),
      'message': 'Customer retrieved successfully',
    };

    test(
      'should perform GET request to /customers/:id',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/customers/$tCustomerId'),
          ),
        );

        // Act
        await dataSource.getCustomerById(tCustomerId);

        // Assert
        verify(() => mockDioClient.get('/customers/$tCustomerId')).called(1);
      },
    );

    test(
      'should return CustomerModel when status code is 200',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/customers/$tCustomerId'),
          ),
        );

        // Act
        final result = await dataSource.getCustomerById(tCustomerId);

        // Assert
        expect(result, isA<CustomerModel>());
        expect(result.id, tCustomerId);
        expect(result.firstName, tCustomer.firstName);
      },
    );

    test(
      'should throw ServerException when customer not found',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Customer not found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: '/customers/$tCustomerId'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getCustomerById(tCustomerId),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('CustomerRemoteDataSource - createCustomer', () {
    final tCustomer = CustomerFixtures.createCustomerEntity();
    final tCustomerModel = CustomerModel.fromEntity(tCustomer);
    final tRequest = CreateCustomerRequestModel.fromParams(
      firstName: tCustomer.firstName,
      lastName: tCustomer.lastName,
      email: tCustomer.email,
      documentType: tCustomer.documentType,
      documentNumber: tCustomer.documentNumber,
    );

    final tResponseData = {
      'success': true,
      'data': tCustomerModel.toJson(),
      'message': 'Customer created successfully',
    };

    test(
      'should perform POST request to /customers',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/customers'),
          ),
        );

        // Act
        await dataSource.createCustomer(tRequest);

        // Assert
        verify(() => mockDioClient.post('/customers', data: tRequest.toJson())).called(1);
      },
    );

    test(
      'should return CustomerModel when creation is successful',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/customers'),
          ),
        );

        // Act
        final result = await dataSource.createCustomer(tRequest);

        // Assert
        expect(result, isA<CustomerModel>());
        expect(result.firstName, tCustomer.firstName);
        expect(result.lastName, tCustomer.lastName);
      },
    );

    test(
      'should throw ServerException when validation fails',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Validation failed', 'errors': {}},
            statusCode: 422,
            requestOptions: RequestOptions(path: '/customers'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.createCustomer(tRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('CustomerRemoteDataSource - updateCustomer', () {
    const tCustomerId = 'cust-001';
    final tCustomer = CustomerFixtures.createCustomerEntity(id: tCustomerId);
    final tCustomerModel = CustomerModel.fromEntity(tCustomer);
    final tRequest = UpdateCustomerRequestModel.fromParams(
      firstName: 'Updated Name',
    );

    final tResponseData = {
      'success': true,
      'data': tCustomerModel.toJson(),
      'message': 'Customer updated successfully',
    };

    test(
      'should perform PATCH request to /customers/:id',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/customers/$tCustomerId'),
          ),
        );

        // Act
        await dataSource.updateCustomer(tCustomerId, tRequest);

        // Assert
        verify(() => mockDioClient.patch('/customers/$tCustomerId', data: tRequest.toJson())).called(1);
      },
    );

    test(
      'should return updated CustomerModel',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/customers/$tCustomerId'),
          ),
        );

        // Act
        final result = await dataSource.updateCustomer(tCustomerId, tRequest);

        // Assert
        expect(result, isA<CustomerModel>());
        expect(result.id, tCustomerId);
      },
    );
  });

  group('CustomerRemoteDataSource - deleteCustomer', () {
    const tCustomerId = 'cust-001';

    test(
      'should perform DELETE request to /customers/:id',
      () async {
        // Arrange
        when(() => mockDioClient.delete(any())).thenAnswer(
          (_) async => Response(
            data: {'success': true, 'message': 'Customer deleted'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/customers/$tCustomerId'),
          ),
        );

        // Act
        await dataSource.deleteCustomer(tCustomerId);

        // Assert
        verify(() => mockDioClient.delete('/customers/$tCustomerId')).called(1);
      },
    );

    test(
      'should throw ServerException when deletion fails',
      () async {
        // Arrange
        when(() => mockDioClient.delete(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Cannot delete customer'},
            statusCode: 400,
            requestOptions: RequestOptions(path: '/customers/$tCustomerId'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.deleteCustomer(tCustomerId),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('CustomerRemoteDataSource - searchCustomers', () {
    const tSearchTerm = 'John';
    const tLimit = 10;
    final tCustomers = CustomerFixtures.createCustomerEntityList(3);
    final tCustomerModels = tCustomers.map((e) => CustomerModel.fromEntity(e)).toList();

    final tResponseData = {
      'success': true,
      'data': tCustomerModels.map((e) => e.toJson()).toList(),
      'message': 'Search results',
    };

    test(
      'should perform GET request to /customers/search with query params',
      () async {
        // Arrange
        when(() => mockDioClient.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/customers/search'),
          ),
        );

        // Act
        await dataSource.searchCustomers(tSearchTerm, tLimit);

        // Assert
        verify(() => mockDioClient.get(
              '/customers/search',
              queryParameters: {'q': tSearchTerm, 'limit': tLimit},
            )).called(1);
      },
    );

    test(
      'should return list of CustomerModel',
      () async {
        // Arrange
        when(() => mockDioClient.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/customers/search'),
          ),
        );

        // Act
        final result = await dataSource.searchCustomers(tSearchTerm, tLimit);

        // Assert
        expect(result, isA<List<CustomerModel>>());
        expect(result.length, 3);
      },
    );
  });

  group('CustomerRemoteDataSource - getCustomerStats', () {
    final tStatsModel = CustomerStatsModel(
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

    final tResponseData = {
      'success': true,
      'data': tStatsModel.toJson(),
      'message': 'Stats retrieved',
    };

    test(
      'should perform GET request to /customers/stats',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/customers/stats'),
          ),
        );

        // Act
        await dataSource.getCustomerStats();

        // Assert
        verify(() => mockDioClient.get('/customers/stats')).called(1);
      },
    );

    test(
      'should return CustomerStatsModel',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/customers/stats'),
          ),
        );

        // Act
        final result = await dataSource.getCustomerStats();

        // Assert
        expect(result, isA<CustomerStatsModel>());
        expect(result.total, 100);
        expect(result.active, 80);
      },
    );
  });
}
