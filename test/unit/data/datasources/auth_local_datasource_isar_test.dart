// test/unit/data/datasources/auth_local_datasource_isar_test.dart
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_local_datasource_isar.dart';
import 'package:baudex_desktop/features/auth/data/models/auth_response_model.dart';
import 'package:baudex_desktop/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/auth_fixtures.dart';

// Mocks
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late AuthLocalDataSourceIsar dataSource;
  late MockSecureStorageService mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockSecureStorageService();
    dataSource = AuthLocalDataSourceIsar(mockSecureStorage);
  });

  group('AuthLocalDataSourceIsar - saveAuthData', () {
    final tAuthResponse = AuthFixtures.createAuthResponseModel();

    test(
      'should save token using secure storage',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveRefreshToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveUserData(any())).thenAnswer((_) async => {});

        // Act
        await dataSource.saveAuthData(tAuthResponse);

        // Assert
        verify(() => mockSecureStorage.saveToken(tAuthResponse.token)).called(1);
      },
    );

    test(
      'should save refresh token if present',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveRefreshToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveUserData(any())).thenAnswer((_) async => {});

        // Act
        await dataSource.saveAuthData(tAuthResponse);

        // Assert
        verify(() => mockSecureStorage.saveRefreshToken(tAuthResponse.refreshToken!)).called(1);
      },
    );

    test(
      'should not save refresh token if null',
      () async {
        // Arrange
        final authResponseWithoutRefresh = AuthFixtures.createAuthResponseModel(
          refreshToken: null,
        );

        when(() => mockSecureStorage.saveToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveUserData(any())).thenAnswer((_) async => {});

        // Act
        await dataSource.saveAuthData(authResponseWithoutRefresh);

        // Assert
        verifyNever(() => mockSecureStorage.saveRefreshToken(any()));
      },
    );

    test(
      'should save user data',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveRefreshToken(any())).thenAnswer((_) async => {});
        when(() => mockSecureStorage.saveUserData(any())).thenAnswer((_) async => {});

        // Act
        await dataSource.saveAuthData(tAuthResponse);

        // Assert
        verify(() => mockSecureStorage.saveUserData(any())).called(1);
      },
    );

    test(
      'should throw CacheException on save failure',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveToken(any())).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => dataSource.saveAuthData(tAuthResponse),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });

  group('AuthLocalDataSourceIsar - getToken', () {
    const tToken = AuthFixtures.testToken;

    test(
      'should return token from secure storage',
      () async {
        // Arrange
        when(() => mockSecureStorage.getToken()).thenAnswer((_) async => tToken);

        // Act
        final result = await dataSource.getToken();

        // Assert
        expect(result, tToken);
        verify(() => mockSecureStorage.getToken()).called(1);
      },
    );

    test(
      'should return null when no token exists',
      () async {
        // Arrange
        when(() => mockSecureStorage.getToken()).thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getToken();

        // Assert
        expect(result, isNull);
      },
    );

    test(
      'should throw CacheException on retrieval error',
      () async {
        // Arrange
        when(() => mockSecureStorage.getToken()).thenThrow(Exception('Read error'));

        // Act & Assert
        expect(
          () => dataSource.getToken(),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });

  group('AuthLocalDataSourceIsar - getRefreshToken', () {
    const tRefreshToken = AuthFixtures.testRefreshToken;

    test(
      'should return refresh token from secure storage',
      () async {
        // Arrange
        when(() => mockSecureStorage.getRefreshToken()).thenAnswer((_) async => tRefreshToken);

        // Act
        final result = await dataSource.getRefreshToken();

        // Assert
        expect(result, tRefreshToken);
        verify(() => mockSecureStorage.getRefreshToken()).called(1);
      },
    );

    test(
      'should return null when no refresh token exists',
      () async {
        // Arrange
        when(() => mockSecureStorage.getRefreshToken()).thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getRefreshToken();

        // Assert
        expect(result, isNull);
      },
    );

    test(
      'should throw CacheException on retrieval error',
      () async {
        // Arrange
        when(() => mockSecureStorage.getRefreshToken()).thenThrow(Exception('Read error'));

        // Act & Assert
        expect(
          () => dataSource.getRefreshToken(),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });

  group('AuthLocalDataSourceIsar - getUser', () {
    final tUserModel = AuthFixtures.createUserModel();
    final tUserJson = tUserModel.toJson();

    test(
      'should return user from secure storage',
      () async {
        // Arrange
        when(() => mockSecureStorage.getUserData()).thenAnswer((_) async => tUserJson);

        // Act
        final result = await dataSource.getUser();

        // Assert
        expect(result, isA<UserModel>());
        expect(result!.id, tUserModel.id);
        expect(result.email, tUserModel.email);
        verify(() => mockSecureStorage.getUserData()).called(1);
      },
    );

    test(
      'should return null when no user data exists',
      () async {
        // Arrange
        when(() => mockSecureStorage.getUserData()).thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getUser();

        // Assert
        expect(result, isNull);
      },
    );

    test(
      'should return null on parsing error instead of throwing',
      () async {
        // Arrange
        when(() => mockSecureStorage.getUserData()).thenAnswer((_) async => {'invalid': 'data'});

        // Act
        final result = await dataSource.getUser();

        // Assert
        expect(result, isNull);
      },
    );
  });

  group('AuthLocalDataSourceIsar - isAuthenticated', () {
    test(
      'should return true when authenticated',
      () async {
        // Arrange
        when(() => mockSecureStorage.isAuthenticated()).thenAnswer((_) async => true);

        // Act
        final result = await dataSource.isAuthenticated();

        // Assert
        expect(result, true);
        verify(() => mockSecureStorage.isAuthenticated()).called(1);
      },
    );

    test(
      'should return false when not authenticated',
      () async {
        // Arrange
        when(() => mockSecureStorage.isAuthenticated()).thenAnswer((_) async => false);

        // Act
        final result = await dataSource.isAuthenticated();

        // Assert
        expect(result, false);
      },
    );

    test(
      'should return false on error',
      () async {
        // Arrange
        when(() => mockSecureStorage.isAuthenticated()).thenThrow(Exception('Error'));

        // Act
        final result = await dataSource.isAuthenticated();

        // Assert
        expect(result, false);
      },
    );
  });

  group('AuthLocalDataSourceIsar - clearAuthData', () {
    test(
      'should clear all auth data',
      () async {
        // Arrange
        when(() => mockSecureStorage.clearAuthData()).thenAnswer((_) async => {});

        // Act
        await dataSource.clearAuthData();

        // Assert
        verify(() => mockSecureStorage.clearAuthData()).called(1);
      },
    );

    test(
      'should throw CacheException on clear failure',
      () async {
        // Arrange
        when(() => mockSecureStorage.clearAuthData()).thenThrow(Exception('Clear error'));

        // Act & Assert
        expect(
          () => dataSource.clearAuthData(),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });

  group('AuthLocalDataSourceIsar - saveToken', () {
    const tToken = AuthFixtures.testToken;

    test(
      'should save token to secure storage',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveToken(any())).thenAnswer((_) async => {});

        // Act
        await dataSource.saveToken(tToken);

        // Assert
        verify(() => mockSecureStorage.saveToken(tToken)).called(1);
      },
    );

    test(
      'should throw CacheException on save failure',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveToken(any())).thenThrow(Exception('Save error'));

        // Act & Assert
        expect(
          () => dataSource.saveToken(tToken),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });

  group('AuthLocalDataSourceIsar - saveUser', () {
    final tUserModel = AuthFixtures.createUserModel();

    test(
      'should save user data to secure storage',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveUserData(any())).thenAnswer((_) async => {});

        // Act
        await dataSource.saveUser(tUserModel);

        // Assert
        verify(() => mockSecureStorage.saveUserData(any())).called(1);
      },
    );

    test(
      'should throw CacheException on save failure',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveUserData(any())).thenThrow(Exception('Save error'));

        // Act & Assert
        expect(
          () => dataSource.saveUser(tUserModel),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });

  group('AuthLocalDataSourceIsar - hasValidToken', () {
    test(
      'should return true when token exists and is not empty',
      () async {
        // Arrange
        when(() => mockSecureStorage.getToken()).thenAnswer((_) async => AuthFixtures.testToken);

        // Act
        final result = await dataSource.hasValidToken();

        // Assert
        expect(result, true);
      },
    );

    test(
      'should return false when token is null',
      () async {
        // Arrange
        when(() => mockSecureStorage.getToken()).thenAnswer((_) async => null);

        // Act
        final result = await dataSource.hasValidToken();

        // Assert
        expect(result, false);
      },
    );

    test(
      'should return false when token is empty',
      () async {
        // Arrange
        when(() => mockSecureStorage.getToken()).thenAnswer((_) async => '');

        // Act
        final result = await dataSource.hasValidToken();

        // Assert
        expect(result, false);
      },
    );

    test(
      'should return false on error',
      () async {
        // Arrange
        when(() => mockSecureStorage.getToken()).thenThrow(Exception('Error'));

        // Act
        final result = await dataSource.hasValidToken();

        // Assert
        expect(result, false);
      },
    );
  });

  group('AuthLocalDataSourceIsar - hasUserData', () {
    test(
      'should return true when user data exists',
      () async {
        // Arrange
        final tUserJson = AuthFixtures.createUserModel().toJson();
        when(() => mockSecureStorage.getUserData()).thenAnswer((_) async => tUserJson);

        // Act
        final result = await dataSource.hasUserData();

        // Assert
        expect(result, true);
      },
    );

    test(
      'should return false when user data is null',
      () async {
        // Arrange
        when(() => mockSecureStorage.getUserData()).thenAnswer((_) async => null);

        // Act
        final result = await dataSource.hasUserData();

        // Assert
        expect(result, false);
      },
    );

    test(
      'should return false on error',
      () async {
        // Arrange
        when(() => mockSecureStorage.getUserData()).thenThrow(Exception('Error'));

        // Act
        final result = await dataSource.hasUserData();

        // Assert
        expect(result, false);
      },
    );
  });

  group('AuthLocalDataSourceIsar - getAuthData', () {
    final tUserModel = AuthFixtures.createUserModel();
    final tUserJson = tUserModel.toJson();
    const tToken = AuthFixtures.testToken;
    const tRefreshToken = AuthFixtures.testRefreshToken;

    test(
      'should return complete auth data',
      () async {
        // Arrange
        when(() => mockSecureStorage.getToken()).thenAnswer((_) async => tToken);
        when(() => mockSecureStorage.getRefreshToken()).thenAnswer((_) async => tRefreshToken);
        when(() => mockSecureStorage.getUserData()).thenAnswer((_) async => tUserJson);

        // Act
        final result = await dataSource.getAuthData();

        // Assert
        expect(result, isNotNull);
        expect(result!.token, tToken);
        expect(result.refreshToken, tRefreshToken);
        expect(result.user.email, tUserModel.email);
      },
    );

    test(
      'should return null when token is missing',
      () async {
        // Arrange
        when(() => mockSecureStorage.getToken()).thenAnswer((_) async => null);
        when(() => mockSecureStorage.getRefreshToken()).thenAnswer((_) async => tRefreshToken);
        when(() => mockSecureStorage.getUserData()).thenAnswer((_) async => tUserJson);

        // Act
        final result = await dataSource.getAuthData();

        // Assert
        expect(result, isNull);
      },
    );

    test(
      'should return null when user is missing',
      () async {
        // Arrange
        when(() => mockSecureStorage.getToken()).thenAnswer((_) async => tToken);
        when(() => mockSecureStorage.getRefreshToken()).thenAnswer((_) async => tRefreshToken);
        when(() => mockSecureStorage.getUserData()).thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getAuthData();

        // Assert
        expect(result, isNull);
      },
    );

    test(
      'should throw CacheException on retrieval error',
      () async {
        // Arrange
        when(() => mockSecureStorage.getToken()).thenThrow(Exception('Error'));

        // Act & Assert
        expect(
          () => dataSource.getAuthData(),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });

  group('AuthLocalDataSourceIsar - updateToken', () {
    const tNewToken = 'new_token_xyz';

    test(
      'should update token',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveToken(any())).thenAnswer((_) async => {});

        // Act
        await dataSource.updateToken(tNewToken);

        // Assert
        verify(() => mockSecureStorage.saveToken(tNewToken)).called(1);
      },
    );

    test(
      'should throw CacheException on update failure',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveToken(any())).thenThrow(Exception('Update error'));

        // Act & Assert
        expect(
          () => dataSource.updateToken(tNewToken),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });

  group('AuthLocalDataSourceIsar - updateUser', () {
    final tUpdatedUser = AuthFixtures.createUserModel(
      firstName: 'Updated',
      lastName: 'User',
    );

    test(
      'should update user data',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveUserData(any())).thenAnswer((_) async => {});

        // Act
        await dataSource.updateUser(tUpdatedUser);

        // Assert
        verify(() => mockSecureStorage.saveUserData(any())).called(1);
      },
    );

    test(
      'should throw CacheException on update failure',
      () async {
        // Arrange
        when(() => mockSecureStorage.saveUserData(any())).thenThrow(Exception('Update error'));

        // Act & Assert
        expect(
          () => dataSource.updateUser(tUpdatedUser),
          throwsA(isA<CacheException>()),
        );
      },
    );
  });
}
