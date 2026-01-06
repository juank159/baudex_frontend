// test/unit/data/datasources/auth_remote_datasource_test.dart
import 'package:baudex_desktop/app/config/constants/api_constants.dart';
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:baudex_desktop/features/auth/data/models/auth_response_model.dart';
import 'package:baudex_desktop/features/auth/data/models/profile_response_model.dart';
import 'package:baudex_desktop/features/auth/data/models/refresh_token_response_model.dart';
import 'package:baudex_desktop/features/auth/data/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/auth_fixtures.dart';

// Mocks
class MockDioClient extends Mock implements DioClient {}

void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockDioClient mockDioClient;

  setUp(() {
    mockDioClient = MockDioClient();
    dataSource = AuthRemoteDataSourceImpl(dioClient: mockDioClient);
  });

  group('AuthRemoteDataSource - login', () {
    final tLoginRequest = AuthFixtures.createLoginRequestModel();
    final tAuthResponseModel = AuthFixtures.createAuthResponseModel();
    final tResponseData = AuthFixtures.createLoginResponseJson();

    test(
      'should perform POST request to /auth/login',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.login),
          ),
        );

        // Act
        await dataSource.login(tLoginRequest);

        // Assert
        verify(() => mockDioClient.post(ApiConstants.login, data: tLoginRequest.toJson())).called(1);
      },
    );

    test(
      'should return AuthResponseModel when status code is 200',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.login),
          ),
        );

        // Act
        final result = await dataSource.login(tLoginRequest);

        // Assert
        expect(result, isA<AuthResponseModel>());
        expect(result.token, AuthFixtures.testToken);
        expect(result.user.email, AuthFixtures.testEmail);
      },
    );

    test(
      'should return AuthResponseModel when status code is 201',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: ApiConstants.login),
          ),
        );

        // Act
        final result = await dataSource.login(tLoginRequest);

        // Assert
        expect(result, isA<AuthResponseModel>());
      },
    );

    test(
      'should throw ServerException when status code is 401',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: AuthFixtures.createErrorApiResponseJson(
              message: 'Invalid credentials',
              statusCode: 401,
            ),
            statusCode: 401,
            requestOptions: RequestOptions(path: ApiConstants.login),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.login(tLoginRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw ServerException when success is false',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: {
              'success': false,
              'message': 'Login failed',
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.login),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.login(tLoginRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw ConnectionException on DioException with connection timeout',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.login),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.login(tLoginRequest),
          throwsA(isA<ConnectionException>()),
        );
      },
    );

    test(
      'should throw ConnectionException on DioException with receive timeout',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.login),
            type: DioExceptionType.receiveTimeout,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.login(tLoginRequest),
          throwsA(isA<ConnectionException>()),
        );
      },
    );

    test(
      'should throw ConnectionException on socket exception',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.login),
            type: DioExceptionType.unknown,
            message: 'SocketException: Connection refused',
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.login(tLoginRequest),
          throwsA(isA<ConnectionException>()),
        );
      },
    );
  });

  group('AuthRemoteDataSource - register', () {
    final tRegisterRequest = AuthFixtures.createRegisterRequestModel();
    final tAuthResponseModel = AuthFixtures.createAuthResponseModel();
    final tResponseData = AuthFixtures.createRegisterResponseJson();

    test(
      'should perform POST request to /auth/register',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: ApiConstants.register),
          ),
        );

        // Act
        await dataSource.register(tRegisterRequest);

        // Assert
        verify(() => mockDioClient.post(ApiConstants.register, data: tRegisterRequest.toJson())).called(1);
      },
    );

    test(
      'should return AuthResponseModel when registration is successful',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: ApiConstants.register),
          ),
        );

        // Act
        final result = await dataSource.register(tRegisterRequest);

        // Assert
        expect(result, isA<AuthResponseModel>());
        expect(result.token, isNotEmpty);
        expect(result.user.email, AuthFixtures.testEmail);
      },
    );

    test(
      'should throw ServerException when email already exists',
      () async {
        // Arrange
        when(() => mockDioClient.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: AuthFixtures.createErrorApiResponseJson(
              message: 'Email already exists',
              statusCode: 422,
              errors: {'email': ['The email has already been taken.']},
            ),
            statusCode: 422,
            requestOptions: RequestOptions(path: ApiConstants.register),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.register(tRegisterRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('AuthRemoteDataSource - registerWithOnboarding', () {
    final tRegisterRequest = AuthFixtures.createRegisterRequestModel();
    final tAuthResponseModel = AuthFixtures.createAuthResponseModel();
    final tRegisterResponseData = AuthFixtures.createRegisterResponseJson();

    test(
      'should successfully register user and create warehouse',
      () async {
        // Arrange
        when(() => mockDioClient.post(ApiConstants.register, data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tRegisterResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: ApiConstants.register),
          ),
        );

        when(() => mockDioClient.post('/warehouses', data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: {'success': true, 'message': 'Warehouse created'},
            statusCode: 201,
            requestOptions: RequestOptions(path: '/warehouses'),
          ),
        );

        // Act
        final result = await dataSource.registerWithOnboarding(tRegisterRequest);

        // Assert
        expect(result, isA<AuthResponseModel>());
        verify(() => mockDioClient.post(ApiConstants.register, data: any(named: 'data'))).called(1);
        verify(() => mockDioClient.post('/warehouses', data: any(named: 'data'))).called(1);
      },
    );

    test(
      'should complete registration even if warehouse creation fails',
      () async {
        // Arrange
        when(() => mockDioClient.post(ApiConstants.register, data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tRegisterResponseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: ApiConstants.register),
          ),
        );

        when(() => mockDioClient.post('/warehouses', data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/warehouses'),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act
        final result = await dataSource.registerWithOnboarding(tRegisterRequest);

        // Assert
        expect(result, isA<AuthResponseModel>());
        expect(result.user.email, AuthFixtures.testEmail);
      },
    );

    test(
      'should throw exception if registration fails',
      () async {
        // Arrange
        when(() => mockDioClient.post(ApiConstants.register, data: any(named: 'data'))).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.register),
            type: DioExceptionType.badResponse,
            response: Response(
              data: {'success': false, 'message': 'Registration failed'},
              statusCode: 400,
              requestOptions: RequestOptions(path: ApiConstants.register),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.registerWithOnboarding(tRegisterRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('AuthRemoteDataSource - getProfile', () {
    final tUserModel = AuthFixtures.createUserModel();
    final tProfileResponse = AuthFixtures.createProfileResponseJson();

    test(
      'should perform GET request to /auth/profile',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tProfileResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.profile),
          ),
        );

        // Act
        await dataSource.getProfile();

        // Assert
        verify(() => mockDioClient.get(ApiConstants.profile)).called(1);
      },
    );

    test(
      'should return ProfileResponseModel when status code is 200',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: tProfileResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.profile),
          ),
        );

        // Act
        final result = await dataSource.getProfile();

        // Assert
        expect(result, isA<ProfileResponseModel>());
        expect(result.user.email, AuthFixtures.testEmail);
      },
    );

    test(
      'should throw ServerException when unauthorized',
      () async {
        // Arrange
        when(() => mockDioClient.get(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Unauthorized'},
            statusCode: 401,
            requestOptions: RequestOptions(path: ApiConstants.profile),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.getProfile(),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('AuthRemoteDataSource - refreshToken', () {
    final tRefreshTokenResponse = AuthFixtures.createRefreshTokenResponseJson();

    test(
      'should perform POST request to /auth/refresh',
      () async {
        // Arrange
        when(() => mockDioClient.post(any())).thenAnswer(
          (_) async => Response(
            data: tRefreshTokenResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.refreshToken),
          ),
        );

        // Act
        await dataSource.refreshToken();

        // Assert
        verify(() => mockDioClient.post(ApiConstants.refreshToken)).called(1);
      },
    );

    test(
      'should return RefreshTokenResponseModel when successful',
      () async {
        // Arrange
        when(() => mockDioClient.post(any())).thenAnswer(
          (_) async => Response(
            data: tRefreshTokenResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.refreshToken),
          ),
        );

        // Act
        final result = await dataSource.refreshToken();

        // Assert
        expect(result, isA<RefreshTokenResponseModel>());
        expect(result.token, isNotEmpty);
      },
    );

    test(
      'should throw ServerException when refresh token is invalid',
      () async {
        // Arrange
        when(() => mockDioClient.post(any())).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Invalid refresh token'},
            statusCode: 401,
            requestOptions: RequestOptions(path: ApiConstants.refreshToken),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.refreshToken(),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('AuthRemoteDataSource - logout', () {
    test(
      'should complete logout successfully',
      () async {
        // Act
        await dataSource.logout();

        // Assert - no exception should be thrown
        expect(true, true);
      },
    );

    test(
      'should not throw exception on logout',
      () async {
        // Act & Assert
        expect(
          () => dataSource.logout(),
          returnsNormally,
        );
      },
    );
  });

  group('AuthRemoteDataSource - updateProfile', () {
    final tUpdateRequest = AuthFixtures.createUpdateProfileRequestModel(
      firstName: 'Updated',
      lastName: 'Name',
    );
    final tUserModel = AuthFixtures.createUserModel(
      firstName: 'Updated',
      lastName: 'Name',
    );

    final tResponseData = {
      'user': tUserModel.toJson(),
    };

    test(
      'should perform PATCH request to /users/profile',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.userProfile),
          ),
        );

        // Act
        await dataSource.updateProfile(tUpdateRequest);

        // Assert
        verify(() => mockDioClient.patch(ApiConstants.userProfile, data: tUpdateRequest.toJson())).called(1);
      },
    );

    test(
      'should return updated UserModel',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: tResponseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.userProfile),
          ),
        );

        // Act
        final result = await dataSource.updateProfile(tUpdateRequest);

        // Assert
        expect(result, isA<UserModel>());
        expect(result.firstName, 'Updated');
        expect(result.lastName, 'Name');
      },
    );

    test(
      'should throw ServerException when validation fails',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: {'success': false, 'message': 'Validation error'},
            statusCode: 422,
            requestOptions: RequestOptions(path: ApiConstants.userProfile),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.updateProfile(tUpdateRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('AuthRemoteDataSource - changePassword', () {
    final tChangePasswordRequest = AuthFixtures.createChangePasswordRequestModel();

    test(
      'should perform PATCH request to /auth/change-password',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: {'success': true, 'message': 'Password changed'},
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.changePassword),
          ),
        );

        // Act
        await dataSource.changePassword(tChangePasswordRequest);

        // Assert
        verify(() => mockDioClient.patch(ApiConstants.changePassword, data: tChangePasswordRequest.toJson())).called(1);
      },
    );

    test(
      'should complete successfully when password is changed',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: {'success': true, 'message': 'Password changed'},
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiConstants.changePassword),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.changePassword(tChangePasswordRequest),
          returnsNormally,
        );
      },
    );

    test(
      'should throw ServerException when current password is incorrect',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: {
              'success': false,
              'message': 'Current password is incorrect',
            },
            statusCode: 400,
            requestOptions: RequestOptions(path: ApiConstants.changePassword),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.changePassword(tChangePasswordRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw ServerException when passwords do not match',
      () async {
        // Arrange
        when(() => mockDioClient.patch(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            data: {
              'success': false,
              'message': 'Password confirmation does not match',
            },
            statusCode: 422,
            requestOptions: RequestOptions(path: ApiConstants.changePassword),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.changePassword(tChangePasswordRequest),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });
}
