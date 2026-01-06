// test/unit/data/datasources/bank_account_remote_datasource_test.dart
import 'package:baudex_desktop/app/config/constants/api_constants.dart';
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/features/bank_accounts/data/datasources/bank_account_remote_datasource.dart';
import 'package:baudex_desktop/features/bank_accounts/data/models/bank_account_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/bank_account_fixtures.dart';

// Mocks
class MockDioClient extends Mock implements DioClient {}

void main() {
  late BankAccountRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = BankAccountRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('BankAccountRemoteDataSource - getBankAccounts', () {
    final tBankAccounts = BankAccountFixtures.createBankAccountEntityList(5);
    final tBankAccountModels = tBankAccounts
        .map((e) => BankAccountModel.fromEntity(e))
        .toList();

    final tResponseData = {
      'success': true,
      'data': tBankAccountModels.map((e) => e.toJson()).toList(),
      'message': 'Bank accounts retrieved successfully',
    };

    test(
      'should perform GET request to /bank-accounts',
      () async {
        // Arrange
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.bankAccounts),
          ),
        );

        // Act
        await dataSource.getBankAccounts();

        // Assert
        verify(() => mockDioClient.get(
              ApiConstants.bankAccounts,
              queryParameters: any(named: 'queryParameters'),
            )).called(1);
      },
    );

    test(
      'should return List<BankAccountModel> when status code is 200',
      () async {
        // Arrange
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.bankAccounts),
          ),
        );

        // Act
        final result = await dataSource.getBankAccounts();

        // Assert
        expect(result, isA<List<BankAccountModel>>());
        expect(result.length, 5);
      },
    );

    test(
      'should filter by type when type parameter is provided',
      () async {
        // Arrange
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.bankAccounts),
          ),
        );

        // Act
        await dataSource.getBankAccounts(type: 'cash');

        // Assert
        verify(() => mockDioClient.get(
              ApiConstants.bankAccounts,
              queryParameters: {'type': 'cash'},
            )).called(1);
      },
    );

    test(
      'should filter by isActive when isActive parameter is provided',
      () async {
        // Arrange
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.bankAccounts),
          ),
        );

        // Act
        await dataSource.getBankAccounts(isActive: true);

        // Assert
        verify(() => mockDioClient.get(
              ApiConstants.bankAccounts,
              queryParameters: {'isActive': true},
            )).called(1);
      },
    );

    test(
      'should throw ServerException when status code is 404',
      () async {
        // Arrange
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Not found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: ApiConstants.bankAccounts),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getBankAccounts(),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw ServerException on DioException',
      () async {
        // Arrange
        when(() => mockDioClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.bankAccounts),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getBankAccounts(),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('BankAccountRemoteDataSource - getActiveBankAccounts', () {
    final tBankAccounts = BankAccountFixtures.createBankAccountEntityList(3);
    final tBankAccountModels = tBankAccounts
        .map((e) => BankAccountModel.fromEntity(e))
        .toList();

    final tResponseData = {
      'success': true,
      'data': tBankAccountModels.map((e) => e.toJson()).toList(),
    };

    test(
      'should perform GET request to /bank-accounts/active',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions:
                RequestOptions(path: ApiConstants.bankAccountsActive),
          ),
        );

        // Act
        await dataSource.getActiveBankAccounts();

        // Assert
        verify(() => mockDioClient.get(ApiConstants.bankAccountsActive))
            .called(1);
      },
    );

    test(
      'should return List<BankAccountModel> when status code is 200',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions:
                RequestOptions(path: ApiConstants.bankAccountsActive),
          ),
        );

        // Act
        final result = await dataSource.getActiveBankAccounts();

        // Assert
        expect(result, isA<List<BankAccountModel>>());
        expect(result.length, 3);
      },
    );
  });

  group('BankAccountRemoteDataSource - getBankAccountById', () {
    const tBankAccountId = 'bank-001';
    final tBankAccount =
        BankAccountFixtures.createBankAccountEntity(id: tBankAccountId);
    final tBankAccountModel = BankAccountModel.fromEntity(tBankAccount);

    final tResponseData = {
      'success': true,
      'data': tBankAccountModel.toJson(),
      'message': 'Bank account retrieved successfully',
    };

    test(
      'should perform GET request to /bank-accounts/:id',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(
                path: ApiConstants.bankAccountById(tBankAccountId)),
          ),
        );

        // Act
        await dataSource.getBankAccountById(tBankAccountId);

        // Assert
        verify(() =>
                mockDioClient.get(ApiConstants.bankAccountById(tBankAccountId)))
            .called(1);
      },
    );

    test(
      'should return BankAccountModel when status code is 200',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(
                path: ApiConstants.bankAccountById(tBankAccountId)),
          ),
        );

        // Act
        final result = await dataSource.getBankAccountById(tBankAccountId);

        // Assert
        expect(result, isA<BankAccountModel>());
        expect(result.id, tBankAccountId);
        expect(result.name, tBankAccount.name);
      },
    );

    test(
      'should throw ServerException when bank account not found',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Bank account not found'},
            statusCode: 404,
            requestOptions: RequestOptions(
                path: ApiConstants.bankAccountById(tBankAccountId)),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getBankAccountById(tBankAccountId),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('BankAccountRemoteDataSource - getDefaultBankAccount', () {
    final tBankAccount = BankAccountFixtures.createDefaultBankAccount();
    final tBankAccountModel = BankAccountModel.fromEntity(tBankAccount);

    final tResponseData = {
      'success': true,
      'data': tBankAccountModel.toJson(),
    };

    test(
      'should perform GET request to /bank-accounts/default',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions:
                RequestOptions(path: ApiConstants.bankAccountsDefault),
          ),
        );

        // Act
        await dataSource.getDefaultBankAccount();

        // Assert
        verify(() => mockDioClient.get(ApiConstants.bankAccountsDefault))
            .called(1);
      },
    );

    test(
      'should return BankAccountModel when default account exists',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions:
                RequestOptions(path: ApiConstants.bankAccountsDefault),
          ),
        );

        // Act
        final result = await dataSource.getDefaultBankAccount();

        // Assert
        expect(result, isA<BankAccountModel>());
        expect(result!.isDefault, true);
      },
    );

    test(
      'should return null when no default account exists (404)',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'No default account'},
            statusCode: 404,
            requestOptions:
                RequestOptions(path: ApiConstants.bankAccountsDefault),
          ),
        );

        // Act
        final result = await dataSource.getDefaultBankAccount();

        // Assert
        expect(result, isNull);
      },
    );

    test(
      'should return null on DioException with 404',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenThrow(
          DioException(
            requestOptions:
                RequestOptions(path: ApiConstants.bankAccountsDefault),
            response: Response(
              statusCode: 404,
              requestOptions:
                  RequestOptions(path: ApiConstants.bankAccountsDefault),
            ),
          ),
        );

        // Act
        final result = await dataSource.getDefaultBankAccount();

        // Assert
        expect(result, isNull);
      },
    );
  });

  group('BankAccountRemoteDataSource - createBankAccount', () {
    final tBankAccount = BankAccountFixtures.createBankAccountEntity();
    final tBankAccountModel = BankAccountModel.fromEntity(tBankAccount);
    final tRequest = CreateBankAccountRequest(
      name: tBankAccount.name,
      type: tBankAccount.type.value,
      bankName: tBankAccount.bankName,
      accountNumber: tBankAccount.accountNumber,
      holderName: tBankAccount.holderName,
      icon: tBankAccount.icon,
      isActive: tBankAccount.isActive,
      isDefault: tBankAccount.isDefault,
      sortOrder: tBankAccount.sortOrder,
      description: tBankAccount.description,
    );

    final tResponseData = {
      'success': true,
      'data': tBankAccountModel.toJson(),
      'message': 'Bank account created successfully',
    };

    test(
      'should perform POST request to /bank-accounts',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data')))
            .thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: ApiConstants.bankAccounts),
          ),
        );

        // Act
        await dataSource.createBankAccount(tRequest);

        // Assert
        verify(() => mockDioClient.post(
              ApiConstants.bankAccounts,
              data: tRequest.toJson(),
            )).called(1);
      },
    );

    test(
      'should return BankAccountModel when creation is successful',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data')))
            .thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: ApiConstants.bankAccounts),
          ),
        );

        // Act
        final result = await dataSource.createBankAccount(tRequest);

        // Assert
        expect(result, isA<BankAccountModel>());
        expect(result.name, tBankAccount.name);
        expect(result.type, tBankAccount.type);
      },
    );

    test(
      'should throw ServerException when validation fails',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data')))
            .thenAnswer(
          (_) async => Response(
            data: {
              'success': false,
              'message': 'Validation failed',
              'errors': {}
            },
            statusCode: 422,
            requestOptions: RequestOptions(path: ApiConstants.bankAccounts),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.createBankAccount(tRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('BankAccountRemoteDataSource - updateBankAccount', () {
    const tBankAccountId = 'bank-001';
    final tBankAccount =
        BankAccountFixtures.createBankAccountEntity(id: tBankAccountId);
    final tBankAccountModel = BankAccountModel.fromEntity(tBankAccount);
    final tRequest = UpdateBankAccountRequest(
      name: 'Updated Name',
      isActive: false,
    );

    final tResponseData = {
      'success': true,
      'data': tBankAccountModel.toJson(),
      'message': 'Bank account updated successfully',
    };

    test(
      'should perform PATCH request to /bank-accounts/:id',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any(), data: any(named: 'data')))
            .thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(
                path: ApiConstants.bankAccountById(tBankAccountId)),
          ),
        );

        // Act
        await dataSource.updateBankAccount(tBankAccountId, tRequest);

        // Assert
        verify(() => mockDioClient.patch(
              ApiConstants.bankAccountById(tBankAccountId),
              data: tRequest.toJson(),
            )).called(1);
      },
    );

    test(
      'should return updated BankAccountModel',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any(), data: any(named: 'data')))
            .thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(
                path: ApiConstants.bankAccountById(tBankAccountId)),
          ),
        );

        // Act
        final result =
            await dataSource.updateBankAccount(tBankAccountId, tRequest);

        // Assert
        expect(result, isA<BankAccountModel>());
        expect(result.id, tBankAccountId);
      },
    );
  });

  group('BankAccountRemoteDataSource - deleteBankAccount', () {
    const tBankAccountId = 'bank-001';

    test(
      'should perform DELETE request to /bank-accounts/:id',
      () async {
        // Arrange
        when(() => mockDioClient.delete(any())).thenAnswer(
          (_) async => Response(
            data: {'success': true, 'message': 'Bank account deleted'},
            statusCode: 200,
            requestOptions: RequestOptions(
                path: ApiConstants.bankAccountById(tBankAccountId)),
          ),
        );

        // Act
        await dataSource.deleteBankAccount(tBankAccountId);

        // Assert
        verify(() =>
                mockDioClient.delete(ApiConstants.bankAccountById(tBankAccountId)))
            .called(1);
      },
    );

    test(
      'should throw ServerException when deletion fails',
      () async {
        // Arrange
        when(() => mockDioClient.delete(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Cannot delete bank account'},
            statusCode: 400,
            requestOptions: RequestOptions(
                path: ApiConstants.bankAccountById(tBankAccountId)),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.deleteBankAccount(tBankAccountId),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('BankAccountRemoteDataSource - setDefaultBankAccount', () {
    const tBankAccountId = 'bank-001';
    final tBankAccount =
        BankAccountFixtures.createBankAccountEntity(id: tBankAccountId);
    final tBankAccountModel = BankAccountModel.fromEntity(tBankAccount);

    final tResponseData = {
      'success': true,
      'data': tBankAccountModel.toJson(),
    };

    test(
      'should perform PATCH request to /bank-accounts/:id/set-default',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(
                path: ApiConstants.setDefaultBankAccount(tBankAccountId)),
          ),
        );

        // Act
        await dataSource.setDefaultBankAccount(tBankAccountId);

        // Assert
        verify(() => mockDioClient
            .patch(ApiConstants.setDefaultBankAccount(tBankAccountId))).called(1);
      },
    );

    test(
      'should return BankAccountModel',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(
                path: ApiConstants.setDefaultBankAccount(tBankAccountId)),
          ),
        );

        // Act
        final result = await dataSource.setDefaultBankAccount(tBankAccountId);

        // Assert
        expect(result, isA<BankAccountModel>());
        expect(result.id, tBankAccountId);
      },
    );
  });

  group('BankAccountRemoteDataSource - toggleBankAccountActive', () {
    const tBankAccountId = 'bank-001';
    final tBankAccount =
        BankAccountFixtures.createBankAccountEntity(id: tBankAccountId);
    final tBankAccountModel = BankAccountModel.fromEntity(tBankAccount);

    final tResponseData = {
      'success': true,
      'data': tBankAccountModel.toJson(),
    };

    test(
      'should perform PATCH request to /bank-accounts/:id/toggle-active',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(
                path: ApiConstants.toggleBankAccountActive(tBankAccountId)),
          ),
        );

        // Act
        await dataSource.toggleBankAccountActive(tBankAccountId);

        // Assert
        verify(() => mockDioClient
                .patch(ApiConstants.toggleBankAccountActive(tBankAccountId)))
            .called(1);
      },
    );

    test(
      'should return BankAccountModel with toggled active state',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any())).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(
                path: ApiConstants.toggleBankAccountActive(tBankAccountId)),
          ),
        );

        // Act
        final result =
            await dataSource.toggleBankAccountActive(tBankAccountId);

        // Assert
        expect(result, isA<BankAccountModel>());
        expect(result.id, tBankAccountId);
      },
    );
  });

  group('BankAccountRemoteDataSource - getBankAccountTransactions', () {
    const tAccountId = 'bank-001';
    final tTransactions = BankAccountFixtures.createTransactionList(5);

    final tResponseData = {
      'account': {
        'id': tAccountId,
        'name': 'Caja Principal',
        'type': 'cash',
        'currentBalance': 10000000.0,
      },
      'transactions': tTransactions
          .map((t) => {
                'id': t.id,
                'date': t.date.toIso8601String(),
                'type': 'invoice_payment',
                'amount': t.amount,
                'paymentMethod': t.paymentMethod,
                'description': t.description,
              })
          .toList(),
      'pagination': {
        'page': 1,
        'limit': 10,
        'total': 50,
        'totalPages': 5,
      },
      'summary': {
        'totalIncome': 5000000.0,
        'transactionCount': 50,
        'averageTransaction': 100000.0,
      },
    };

    test(
      'should perform GET request to /bank-accounts/:id/transactions',
      () async {
        // Arrange
        when(() => mockDioClient.get(any(),
            queryParameters: any(named: 'queryParameters'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(
                path: '${ApiConstants.bankAccounts}/$tAccountId/transactions'),
          ),
        );

        // Act
        await dataSource.getBankAccountTransactions(tAccountId);

        // Assert
        verify(() => mockDioClient.get(
              '${ApiConstants.bankAccounts}/$tAccountId/transactions',
              queryParameters: any(named: 'queryParameters'),
            )).called(1);
      },
    );

    test(
      'should return Map with transactions data when status code is 200',
      () async {
        // Arrange
        when(() => mockDioClient.get(any(),
            queryParameters: any(named: 'queryParameters'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(
                path: '${ApiConstants.bankAccounts}/$tAccountId/transactions'),
          ),
        );

        // Act
        final result =
            await dataSource.getBankAccountTransactions(tAccountId);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['transactions'], isA<List>());
      },
    );

    test(
      'should include query parameters when provided',
      () async {
        // Arrange
        when(() => mockDioClient.get(any(),
            queryParameters: any(named: 'queryParameters'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(
                path: '${ApiConstants.bankAccounts}/$tAccountId/transactions'),
          ),
        );

        // Act
        await dataSource.getBankAccountTransactions(
          tAccountId,
          startDate: '2024-01-01',
          endDate: '2024-01-31',
          page: 2,
          limit: 20,
          search: 'test',
        );

        // Assert
        verify(() => mockDioClient.get(
              '${ApiConstants.bankAccounts}/$tAccountId/transactions',
              queryParameters: {
                'startDate': '2024-01-01',
                'endDate': '2024-01-31',
                'page': 2,
                'limit': 20,
                'search': 'test',
              },
            )).called(1);
      },
    );

    test(
      'should throw ServerException on error',
      () async {
        // Arrange
        when(() => mockDioClient.get(any(),
            queryParameters: any(named: 'queryParameters'))).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Error'},
            statusCode: 500,
            requestOptions: RequestOptions(
                path: '${ApiConstants.bankAccounts}/$tAccountId/transactions'),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getBankAccountTransactions(tAccountId),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });
}
