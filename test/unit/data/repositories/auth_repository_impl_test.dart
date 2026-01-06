// test/unit/data/repositories/auth_repository_impl_test.dart
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:baudex_desktop/features/auth/data/models/auth_response_model.dart';
import 'package:baudex_desktop/features/auth/data/models/change_password_request_model.dart';
import 'package:baudex_desktop/features/auth/data/models/login_request_model.dart';
import 'package:baudex_desktop/features/auth/data/models/profile_response_model.dart';
import 'package:baudex_desktop/features/auth/data/models/refresh_token_response_model.dart';
import 'package:baudex_desktop/features/auth/data/models/register_request_model.dart';
import 'package:baudex_desktop/features/auth/data/models/update_profile_request_model.dart';
import 'package:baudex_desktop/features/auth/data/models/user_model.dart';
import 'package:baudex_desktop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:baudex_desktop/features/auth/domain/entities/auth_result.dart';
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/auth_fixtures.dart';

// Mocks
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

// Fake classes for mocktail fallback values
class FakeLoginRequestModel extends Fake implements LoginRequestModel {}
class FakeRegisterRequestModel extends Fake implements RegisterRequestModel {}
class FakeChangePasswordRequestModel extends Fake implements ChangePasswordRequestModel {}
class FakeUpdateProfileRequestModel extends Fake implements UpdateProfileRequestModel {}
class FakeAuthResponseModel extends Fake implements AuthResponseModel {}
class FakeUserModel extends Fake implements UserModel {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUpAll(() {
    // Register fallback values for models used with any()
    registerFallbackValue(FakeLoginRequestModel());
    registerFallbackValue(FakeRegisterRequestModel());
    registerFallbackValue(FakeChangePasswordRequestModel());
    registerFallbackValue(FakeUpdateProfileRequestModel());
    registerFallbackValue(FakeAuthResponseModel());
    registerFallbackValue(FakeUserModel());
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('AuthRepositoryImpl - login', () {
    const tEmail = AuthFixtures.testEmail;
    const tPassword = AuthFixtures.testPassword;
    final tAuthResponse = AuthFixtures.createAuthResponseModel();

    test(
      'should check if device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.login(any())).thenAnswer((_) async => tAuthResponse);
        when(() => mockLocalDataSource.saveAuthData(any())).thenAnswer((_) async => {});

        // Act
        await repository.login(email: tEmail, password: tPassword);

        // Assert
        verify(() => mockNetworkInfo.isConnected).called(1);
      },
    );

    test(
      'should return AuthResult when device is online and login succeeds',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.login(any())).thenAnswer((_) async => tAuthResponse);
        when(() => mockLocalDataSource.saveAuthData(any())).thenAnswer((_) async => {});

        // Act
        final result = await repository.login(email: tEmail, password: tPassword);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (authResult) {
            expect(authResult, isA<AuthResult>());
            expect(authResult.user.email, tEmail);
            expect(authResult.token, isNotEmpty);
          },
        );
      },
    );

    test(
      'should save auth data locally after successful login',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.login(any())).thenAnswer((_) async => tAuthResponse);
        when(() => mockLocalDataSource.saveAuthData(any())).thenAnswer((_) async => {});

        // Act
        await repository.login(email: tEmail, password: tPassword);

        // Assert
        verify(() => mockLocalDataSource.saveAuthData(any())).called(1);
      },
    );

    test(
      'should trim and lowercase email',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.login(any())).thenAnswer((_) async => tAuthResponse);
        when(() => mockLocalDataSource.saveAuthData(any())).thenAnswer((_) async => {});

        // Act
        await repository.login(email: '  TEST@TEST.COM  ', password: tPassword);

        // Assert
        verify(() => mockRemoteDataSource.login(any())).called(1);
      },
    );

    test(
      'should return ConnectionFailure when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.login(email: tEmail, password: tPassword);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ServerFailure when remote login fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.login(any())).thenThrow(
          const ServerException('Invalid credentials', statusCode: 401),
        );

        // Act
        final result = await repository.login(email: tEmail, password: tPassword);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ConnectionFailure on connection exception',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.login(any())).thenThrow(
          const ConnectionException('No internet'),
        );

        // Act
        final result = await repository.login(email: tEmail, password: tPassword);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return CacheFailure when local save fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.login(any())).thenAnswer((_) async => tAuthResponse);
        when(() => mockLocalDataSource.saveAuthData(any())).thenThrow(
          const CacheException('Save failed'),
        );

        // Act
        final result = await repository.login(email: tEmail, password: tPassword);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('AuthRepositoryImpl - register', () {
    const tFirstName = AuthFixtures.testFirstName;
    const tLastName = AuthFixtures.testLastName;
    const tEmail = AuthFixtures.testEmail;
    const tPassword = AuthFixtures.testPassword;
    final tAuthResponse = AuthFixtures.createAuthResponseModel();

    test(
      'should return AuthResult when registration succeeds',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.register(any())).thenAnswer((_) async => tAuthResponse);
        when(() => mockLocalDataSource.saveAuthData(any())).thenAnswer((_) async => {});

        // Act
        final result = await repository.register(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (authResult) {
            expect(authResult, isA<AuthResult>());
            expect(authResult.user.email, tEmail);
          },
        );
      },
    );

    test(
      'should save auth data after successful registration',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.register(any())).thenAnswer((_) async => tAuthResponse);
        when(() => mockLocalDataSource.saveAuthData(any())).thenAnswer((_) async => {});

        // Act
        await repository.register(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
        );

        // Assert
        verify(() => mockLocalDataSource.saveAuthData(any())).called(1);
      },
    );

    test(
      'should include optional fields when provided',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.register(any())).thenAnswer((_) async => tAuthResponse);
        when(() => mockLocalDataSource.saveAuthData(any())).thenAnswer((_) async => {});

        // Act
        await repository.register(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
          role: UserRole.admin,
          organizationName: 'Test Org',
        );

        // Assert
        verify(() => mockRemoteDataSource.register(any())).called(1);
      },
    );

    test(
      'should return ConnectionFailure when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.register(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ServerFailure when email already exists',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.register(any())).thenThrow(
          const ServerException('Email already exists', statusCode: 422),
        );

        // Act
        final result = await repository.register(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('AuthRepositoryImpl - registerWithOnboarding', () {
    const tFirstName = AuthFixtures.testFirstName;
    const tLastName = AuthFixtures.testLastName;
    const tEmail = AuthFixtures.testEmail;
    const tPassword = AuthFixtures.testPassword;
    final tAuthResponse = AuthFixtures.createAuthResponseModel();

    test(
      'should complete registration with onboarding',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.registerWithOnboarding(any())).thenAnswer(
          (_) async => tAuthResponse,
        );
        when(() => mockLocalDataSource.saveAuthData(any())).thenAnswer((_) async => {});

        // Act
        final result = await repository.registerWithOnboarding(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.registerWithOnboarding(any())).called(1);
      },
    );

    test(
      'should return ConnectionFailure when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.registerWithOnboarding(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('AuthRepositoryImpl - getProfile', () {
    final tUserModel = AuthFixtures.createUserModel();
    final tProfileResponse = ProfileResponseModel(user: tUserModel);

    test(
      'should return user profile when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getProfile()).thenAnswer((_) async => tProfileResponse);
        when(() => mockLocalDataSource.saveUser(any())).thenAnswer((_) async => {});

        // Act
        final result = await repository.getProfile();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (user) {
            expect(user, isA<User>());
            expect(user.email, tUserModel.email);
          },
        );
      },
    );

    test(
      'should update local cache after fetching profile',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getProfile()).thenAnswer((_) async => tProfileResponse);
        when(() => mockLocalDataSource.saveUser(any())).thenAnswer((_) async => {});

        // Act
        await repository.getProfile();

        // Assert
        verify(() => mockLocalDataSource.saveUser(any())).called(1);
      },
    );

    test(
      'should return cached profile when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getUser()).thenAnswer((_) async => tUserModel);

        // Act
        final result = await repository.getProfile();

        // Assert
        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.getUser()).called(1);
        verifyNever(() => mockRemoteDataSource.getProfile());
      },
    );

    test(
      'should return cached profile when remote call fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getProfile()).thenThrow(
          const ServerException('Server error'),
        );
        when(() => mockLocalDataSource.getUser()).thenAnswer((_) async => tUserModel);

        // Act
        final result = await repository.getProfile();

        // Assert
        expect(result.isRight(), true);
      },
    );

    test(
      'should return CacheFailure when both remote and cache fail',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getProfile()).thenThrow(
          const ServerException('Server error'),
        );
        when(() => mockLocalDataSource.getUser()).thenAnswer((_) async => null);

        // Act
        final result = await repository.getProfile();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('AuthRepositoryImpl - refreshToken', () {
    final tRefreshResponse = RefreshTokenResponseModel(
      token: AuthFixtures.testToken,
    );

    test(
      'should return new token when refresh succeeds',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.refreshToken()).thenAnswer((_) async => tRefreshResponse);
        when(() => mockLocalDataSource.saveToken(any())).thenAnswer((_) async => {});

        // Act
        final result = await repository.refreshToken();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (token) {
            expect(token, isNotEmpty);
            expect(token, AuthFixtures.testToken);
          },
        );
      },
    );

    test(
      'should save new token locally',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.refreshToken()).thenAnswer((_) async => tRefreshResponse);
        when(() => mockLocalDataSource.saveToken(any())).thenAnswer((_) async => {});

        // Act
        await repository.refreshToken();

        // Assert
        verify(() => mockLocalDataSource.saveToken(AuthFixtures.testToken)).called(1);
      },
    );

    test(
      'should return ConnectionFailure when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.refreshToken();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ServerFailure when refresh token is invalid',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.refreshToken()).thenThrow(
          const ServerException('Invalid refresh token', statusCode: 401),
        );

        // Act
        final result = await repository.refreshToken();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('AuthRepositoryImpl - logout', () {
    test(
      'should complete logout when online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.logout()).thenAnswer((_) async => {});
        when(() => mockLocalDataSource.clearAuthData()).thenAnswer((_) async => {});

        // Act
        final result = await repository.logout();

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.logout()).called(1);
        verify(() => mockLocalDataSource.clearAuthData()).called(1);
      },
    );

    test(
      'should clear local data even when remote logout fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.logout()).thenThrow(Exception('Logout failed'));
        when(() => mockLocalDataSource.clearAuthData()).thenAnswer((_) async => {});

        // Act
        final result = await repository.logout();

        // Assert
        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.clearAuthData()).called(1);
      },
    );

    test(
      'should clear local data when offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.clearAuthData()).thenAnswer((_) async => {});

        // Act
        final result = await repository.logout();

        // Assert
        expect(result.isRight(), true);
        verifyNever(() => mockRemoteDataSource.logout());
        verify(() => mockLocalDataSource.clearAuthData()).called(1);
      },
    );

    test(
      'should return CacheFailure when clearing local data fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.clearAuthData()).thenThrow(
          const CacheException('Clear failed'),
        );

        // Act
        final result = await repository.logout();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('AuthRepositoryImpl - updateProfile', () {
    final tUpdatedUser = AuthFixtures.createUserModel(
      firstName: 'Updated',
      lastName: 'Name',
    );

    test(
      'should update profile when device is online',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.updateProfile(any())).thenAnswer((_) async => tUpdatedUser);
        when(() => mockLocalDataSource.saveUser(any())).thenAnswer((_) async => {});

        // Act
        final result = await repository.updateProfile(
          firstName: 'Updated',
          lastName: 'Name',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (user) {
            expect(user.firstName, 'Updated');
            expect(user.lastName, 'Name');
          },
        );
      },
    );

    test(
      'should save updated user locally',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.updateProfile(any())).thenAnswer((_) async => tUpdatedUser);
        when(() => mockLocalDataSource.saveUser(any())).thenAnswer((_) async => {});

        // Act
        await repository.updateProfile(firstName: 'Updated');

        // Assert
        verify(() => mockLocalDataSource.saveUser(any())).called(1);
      },
    );

    test(
      'should return ValidationFailure when no fields to update',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        // Act
        final result = await repository.updateProfile();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ConnectionFailure when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.updateProfile(firstName: 'Updated');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('AuthRepositoryImpl - changePassword', () {
    const tCurrentPassword = AuthFixtures.testPassword;
    const tNewPassword = 'newPassword123';

    test(
      'should change password successfully',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.changePassword(any())).thenAnswer((_) async => {});

        // Act
        final result = await repository.changePassword(
          currentPassword: tCurrentPassword,
          newPassword: tNewPassword,
          confirmPassword: tNewPassword,
        );

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.changePassword(any())).called(1);
      },
    );

    test(
      'should return ConnectionFailure when device is offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await repository.changePassword(
          currentPassword: tCurrentPassword,
          newPassword: tNewPassword,
          confirmPassword: tNewPassword,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConnectionFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return ServerFailure when current password is incorrect',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.changePassword(any())).thenThrow(
          const ServerException('Current password is incorrect', statusCode: 400),
        );

        // Act
        final result = await repository.changePassword(
          currentPassword: 'wrongPassword',
          newPassword: tNewPassword,
          confirmPassword: tNewPassword,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('AuthRepositoryImpl - isAuthenticated', () {
    test(
      'should return true when user is authenticated',
      () async {
        // Arrange
        when(() => mockLocalDataSource.isAuthenticated()).thenAnswer((_) async => true);

        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (isAuth) => expect(isAuth, true),
        );
      },
    );

    test(
      'should return false when user is not authenticated',
      () async {
        // Arrange
        when(() => mockLocalDataSource.isAuthenticated()).thenAnswer((_) async => false);

        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (isAuth) => expect(isAuth, false),
        );
      },
    );

    test(
      'should return CacheFailure on exception',
      () async {
        // Arrange
        when(() => mockLocalDataSource.isAuthenticated()).thenThrow(
          const CacheException('Check failed'),
        );

        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('AuthRepositoryImpl - getLocalUser', () {
    final tUserModel = AuthFixtures.createUserModel();

    test(
      'should return local user when exists',
      () async {
        // Arrange
        when(() => mockLocalDataSource.getUser()).thenAnswer((_) async => tUserModel);

        // Act
        final result = await repository.getLocalUser();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (user) {
            expect(user, isA<User>());
            expect(user.email, tUserModel.email);
          },
        );
      },
    );

    test(
      'should return CacheFailure when user not found',
      () async {
        // Arrange
        when(() => mockLocalDataSource.getUser()).thenAnswer((_) async => null);

        // Act
        final result = await repository.getLocalUser();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should return CacheFailure on exception',
      () async {
        // Arrange
        when(() => mockLocalDataSource.getUser()).thenThrow(
          const CacheException('Get failed'),
        );

        // Act
        final result = await repository.getLocalUser();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('AuthRepositoryImpl - clearLocalAuth', () {
    test(
      'should clear local auth data successfully',
      () async {
        // Arrange
        when(() => mockLocalDataSource.clearAuthData()).thenAnswer((_) async => {});

        // Act
        final result = await repository.clearLocalAuth();

        // Assert
        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.clearAuthData()).called(1);
      },
    );

    test(
      'should return CacheFailure on clear failure',
      () async {
        // Arrange
        when(() => mockLocalDataSource.clearAuthData()).thenThrow(
          const CacheException('Clear failed'),
        );

        // Act
        final result = await repository.clearLocalAuth();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });
}
