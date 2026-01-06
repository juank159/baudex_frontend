// test/integration/auth/auth_flow_integration_test.dart
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_local_datasource_isar.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:baudex_desktop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/is_authenticated_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/login_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/logout_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/register_usecase.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/auth_fixtures.dart';

// Mocks
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late AuthLocalDataSourceIsar localDataSource;
  late MockSecureStorageService mockSecureStorage;
  late MockNetworkInfo mockNetworkInfo;

  late LoginUseCase loginUseCase;
  late RegisterUseCase registerUseCase;
  late LogoutUseCase logoutUseCase;
  late GetProfileUseCase getProfileUseCase;
  late ChangePasswordUseCase changePasswordUseCase;
  late IsAuthenticatedUseCase isAuthenticatedUseCase;

  setUpAll(() {
    registerFallbackValue(AuthFixtures.createLoginRequestModel());
    registerFallbackValue(AuthFixtures.createRegisterRequestModel());
    registerFallbackValue(AuthFixtures.createChangePasswordRequestModel());
    registerFallbackValue(AuthFixtures.createUpdateProfileRequestModel());
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockSecureStorage = MockSecureStorageService();
    mockNetworkInfo = MockNetworkInfo();
    localDataSource = AuthLocalDataSourceIsar(mockSecureStorage);

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: localDataSource,
      networkInfo: mockNetworkInfo,
    );

    loginUseCase = LoginUseCase(repository);
    registerUseCase = RegisterUseCase(repository);
    logoutUseCase = LogoutUseCase(repository);
    getProfileUseCase = GetProfileUseCase(repository);
    changePasswordUseCase = ChangePasswordUseCase(repository);
    isAuthenticatedUseCase = IsAuthenticatedUseCase(repository);
  });

  group('Integration - Login Flow', () {
    final tAuthResponse = AuthFixtures.createAuthResponseModel();
    const tEmail = AuthFixtures.testEmail;
    const tPassword = AuthFixtures.testPassword;

    test(
      'complete login flow should authenticate user and store data locally',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.login(any())).thenAnswer((_) async => tAuthResponse);
        when(() => mockSecureStorage.saveToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveRefreshToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveUserData(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.isAuthenticated()).thenAnswer((_) async => true);

        // Act - Login
        final loginResult = await loginUseCase(const LoginParams(
          email: tEmail,
          password: tPassword,
        ));

        // Assert login succeeded
        expect(loginResult.isRight(), true);
        loginResult.fold(
          (failure) => fail('Login should succeed'),
          (authResult) {
            expect(authResult.user.email, tEmail);
            expect(authResult.token, isNotEmpty);
          },
        );

        // Act - Check authentication
        final isAuthResult = await isAuthenticatedUseCase(NoParams());

        // Assert user is authenticated
        expect(isAuthResult.isRight(), true);
        isAuthResult.fold(
          (failure) => fail('Should be authenticated'),
          (isAuth) => expect(isAuth, true),
        );

        // Verify all data was saved locally
        verify(() => mockSecureStorage.saveToken(any())).called(1);
        verify(() => mockSecureStorage.saveRefreshToken(any())).called(1);
        verify(() => mockSecureStorage.saveUserData(any())).called(1);
      },
    );

    test(
      'login flow should fail gracefully with invalid credentials',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.login(any())).thenThrow(
          Exception('Invalid credentials'),
        );

        // Act
        final result = await loginUseCase(const LoginParams(
          email: tEmail,
          password: 'wrongPassword',
        ));

        // Assert
        expect(result.isLeft(), true);
        verifyNever(() => mockSecureStorage.saveToken(any()));
      },
    );
  });

  group('Integration - Registration Flow', () {
    final tAuthResponse = AuthFixtures.createAuthResponseModel();
    const tFirstName = AuthFixtures.testFirstName;
    const tLastName = AuthFixtures.testLastName;
    const tEmail = 'newuser@test.com';
    const tPassword = 'Password123';

    test(
      'complete registration flow should create user and authenticate',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.register(any())).thenAnswer((_) async => tAuthResponse);
        when(() => mockSecureStorage.saveToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveRefreshToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveUserData(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.isAuthenticated()).thenAnswer((_) async => true);

        // Act - Register
        final registerResult = await registerUseCase(const RegisterParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: tPassword,
          confirmPassword: tPassword,
        ));

        // Assert registration succeeded
        expect(registerResult.isRight(), true);
        registerResult.fold(
          (failure) => fail('Registration should succeed'),
          (authResult) {
            expect(authResult.user.email, AuthFixtures.testEmail);
            expect(authResult.token, isNotEmpty);
          },
        );

        // Verify data was saved
        verify(() => mockSecureStorage.saveToken(any())).called(1);
        verify(() => mockSecureStorage.saveUserData(any())).called(1);
      },
    );

    test(
      'registration should fail with validation errors',
      () async {
        // Act - Try to register with weak password
        final result = await registerUseCase(const RegisterParams(
          firstName: tFirstName,
          lastName: tLastName,
          email: tEmail,
          password: 'weak',
          confirmPassword: 'weak',
        ));

        // Assert
        expect(result.isLeft(), true);
        verifyNever(() => mockRemoteDataSource.register(any()));
      },
    );
  });

  group('Integration - Logout Flow', () {
    test(
      'complete logout flow should clear all local data',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.logout()).thenAnswer((_) async => {});
        when(() => mockSecureStorage.clearAuthData()).thenAnswer((_) async => {});
        when(() => mockSecureStorage.isAuthenticated()).thenAnswer((_) async => false);

        // Act - Logout
        final logoutResult = await logoutUseCase(NoParams());

        // Assert logout succeeded
        expect(logoutResult.isRight(), true);
        verify(() => mockSecureStorage.clearAuthData()).called(1);

        // Act - Check authentication
        final isAuthResult = await isAuthenticatedUseCase(NoParams());

        // Assert user is NOT authenticated
        expect(isAuthResult.isRight(), true);
        isAuthResult.fold(
          (failure) => fail('Should check authentication'),
          (isAuth) => expect(isAuth, false),
        );
      },
    );

    test(
      'logout should clear local data even when remote logout fails',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.logout()).thenThrow(Exception('Server error'));
        when(() => mockSecureStorage.clearAuthData()).thenAnswer((_) async => {});

        // Act
        final result = await logoutUseCase(NoParams());

        // Assert - Should still succeed locally
        expect(result.isRight(), true);
        verify(() => mockSecureStorage.clearAuthData()).called(1);
      },
    );
  });

  group('Integration - Profile Management Flow', () {
    final tUserModel = AuthFixtures.createUserModel();
    final tProfileResponse = AuthFixtures.createProfileResponseModel(user: tUserModel);

    test(
      'should fetch profile from server and cache locally',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getProfile()).thenAnswer((_) async => tProfileResponse);
        when(() => mockSecureStorage.saveUserData(any())).thenAnswer((_) async => {});

        // Act
        final result = await getProfileUseCase(NoParams());

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should fetch profile'),
          (user) {
            expect(user.email, tUserModel.email);
            expect(user.firstName, tUserModel.firstName);
          },
        );

        // Verify cache was updated
        verify(() => mockSecureStorage.saveUserData(any())).called(1);
      },
    );

    test(
      'should return cached profile when offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockSecureStorage.getUserData()).thenAnswer((_) async => tUserModel.toJson());

        // Act
        final result = await getProfileUseCase(NoParams());

        // Assert
        expect(result.isRight(), true);
        verifyNever(() => mockRemoteDataSource.getProfile());
      },
    );
  });

  group('Integration - Password Change Flow', () {
    const tCurrentPassword = 'CurrentPass123';
    const tNewPassword = 'NewPassword456';

    test(
      'should successfully change password',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.changePassword(any())).thenAnswer((_) async => {});

        // Act
        final result = await changePasswordUseCase(const ChangePasswordParams(
          currentPassword: tCurrentPassword,
          newPassword: tNewPassword,
          confirmPassword: tNewPassword,
        ));

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.changePassword(any())).called(1);
      },
    );

    test(
      'should fail password change when offline',
      () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // Act
        final result = await changePasswordUseCase(const ChangePasswordParams(
          currentPassword: tCurrentPassword,
          newPassword: tNewPassword,
          confirmPassword: tNewPassword,
        ));

        // Assert
        expect(result.isLeft(), true);
        verifyNever(() => mockRemoteDataSource.changePassword(any()));
      },
    );
  });

  group('Integration - Session Management', () {
    final tAuthResponse = AuthFixtures.createAuthResponseModel();
    const tEmail = AuthFixtures.testEmail;
    const tPassword = AuthFixtures.testPassword;

    test(
      'complete session flow: login → check auth → logout → check auth',
      () async {
        // Step 1: Login
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.login(any())).thenAnswer((_) async => tAuthResponse);
        when(() => mockSecureStorage.saveToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveRefreshToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveUserData(any())).thenAnswer((_) async => {});

        final loginResult = await loginUseCase(const LoginParams(
          email: tEmail,
          password: tPassword,
        ));
        expect(loginResult.isRight(), true);

        // Step 2: Check authentication (should be true)
        when(() => mockSecureStorage.isAuthenticated()).thenAnswer((_) async => true);
        var isAuthResult = await isAuthenticatedUseCase(NoParams());
        expect(isAuthResult.isRight(), true);
        isAuthResult.fold(
          (failure) => fail('Should be authenticated'),
          (isAuth) => expect(isAuth, true),
        );

        // Step 3: Logout
        when(() => mockRemoteDataSource.logout()).thenAnswer((_) async => {});
        when(() => mockSecureStorage.clearAuthData()).thenAnswer((_) async => {});

        final logoutResult = await logoutUseCase(NoParams());
        expect(logoutResult.isRight(), true);

        // Step 4: Check authentication (should be false)
        when(() => mockSecureStorage.isAuthenticated()).thenAnswer((_) async => false);
        isAuthResult = await isAuthenticatedUseCase(NoParams());
        expect(isAuthResult.isRight(), true);
        isAuthResult.fold(
          (failure) => fail('Should check authentication'),
          (isAuth) => expect(isAuth, false),
        );
      },
    );
  });
}
