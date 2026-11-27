// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/security/offline_password_hasher.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/ops/ops_reporter.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/rules/login_failure_rules.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/change_password_request_model.dart';
import '../models/update_profile_request_model.dart';

/// Implementación del repositorio de autenticación
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  }) async {
    // Login SIEMPRE intenta primero online (sin depender de NetworkInfo pre-check).
    // El pre-check de NetworkInfo puede fallar por timeout del health ping,
    // pero el servidor puede responder bien a requests reales.
    try {
      final request = LoginRequestModel(email: email, password: password);
      final response = await remoteDataSource.login(request);

      // Login exitoso - resetear reachability para que el resto de la app funcione
      networkInfo.resetServerReachability();

      // Guardar la sesión en este equipo. Si falla, el servidor YA aceptó el
      // ingreso: se dice eso, nunca "credenciales incorrectas".
      try {
        await localDataSource
            .saveAuthData(response)
            .timeout(LoginDeadlines.saveSession);
      } on TimeoutException catch (e, st) {
        // El almacén de sesión del equipo no respondió: se corta la espera
        // (antes el botón se quedaba cargando sin fin) y se dice qué pasó.
        OpsReporter.capture(
          e,
          st,
          errorType: 'LoginLocalSave',
          fingerprint: 'login_local_save|session_timeout',
          context: {'step': 'saveAuthData'},
        );
        return Left(LoginTimeoutFailure(
          LoginWaitStage.saveSession,
          detail: 'El almacén de sesión del equipo no respondió en '
              '${LoginDeadlines.saveSession.inSeconds} s.',
        ));
      } catch (e, st) {
        OpsReporter.capture(
          e,
          st,
          errorType: 'LoginLocalSave',
          fingerprint: 'login_local_save|session',
          context: {'step': 'saveAuthData'},
        );
        return Left(LocalSessionSaveFailure('$e'));
      }

      // Huella de la contraseña para entrar sin internet (PBKDF2 con sal
      // nueva). Es opcional: si no se puede guardar, el ingreso en línea
      // sigue y solo se pierde entrar sin internet hasta el próximo ingreso.
      try {
        await (() async => localDataSource.saveOfflineCredentials(
              email,
              await OfflinePasswordHasher.hash(password),
            ))()
            .timeout(LoginDeadlines.saveOfflineAccess);
      } catch (e, st) {
        OpsReporter.capture(
          e,
          st,
          level: 'warning',
          errorType: 'LoginLocalSave',
          fingerprint: 'login_local_save|offline_credentials',
          context: {'step': 'saveOfflineCredentials'},
        );
      }

      return Right(response.toAuthResult());
    } on ConnectionException catch (e) {
      return _attemptOfflineLogin(email, password, cause: e.message);
    } on ServerException catch (e) {
      return Left(_mapServerExceptionToFailure(e));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      // Si es un error de conexión, intentar login offline
      if (isConnectionProblem(e)) {
        return _attemptOfflineLogin(email, password, cause: '$e');
      }
      return Left(UnknownFailure('Error inesperado durante el login: $e'));
    }
  }

  /// ¿Esta excepción sin tipo es un problema para llegar al servidor?
  @visibleForTesting
  static bool isConnectionProblem(Object e) {
    final text = e.toString();
    return text.contains('SocketException') ||
        text.contains('HandshakeException') ||
        text.contains('TlsException') ||
        text.contains('CERTIFICATE_VERIFY_FAILED') ||
        text.contains('Connection') ||
        text.contains('Network') ||
        text.contains('timeout');
  }

  /// Intenta realizar login offline con credenciales cacheadas
  ///
  /// [cause] es por qué no se pudo llegar al servidor: viaja en el fallo para
  /// que la pantalla diga "sin conexión" (con el detalle) y no "credenciales".
  Future<Either<Failure, AuthResult>> _attemptOfflineLogin(
    String email,
    String password, {
    String? cause,
  }) async {
    try {
      return await _readOfflineSession(email, password, cause: cause)
          .timeout(LoginDeadlines.offlineSession);
    } on TimeoutException {
      return Left(LoginTimeoutFailure(
        LoginWaitStage.offlineSession,
        detail: cause,
      ));
    }
  }

  Future<Either<Failure, AuthResult>> _readOfflineSession(
    String email,
    String password, {
    String? cause,
  }) async {
    try {
      // Verificar si hay credenciales offline guardadas
      final hasOfflineCredentials = await localDataSource.hasOfflineCredentials();
      if (!hasOfflineCredentials) {
        return Left(AuthFailure(
          message: 'No hay sesión previa guardada. Necesitas conexión a internet para el primer login.',
          errorCode: 'NO_OFFLINE_CREDENTIALS',
          detail: cause,
        ));
      }

      // Verificar credenciales
      final credentialsValid = await localDataSource.verifyOfflineCredentials(
        email,
        password,
      );

      if (!credentialsValid) {
        // No es "credenciales incorrectas": el servidor nunca las vio.
        return Left(AuthFailure(
          message: 'Sin conexión con el servidor, y el correo o la contraseña '
              'no coinciden con la última sesión guardada en este equipo.',
          errorCode: 'OFFLINE_PASSWORD_MISMATCH',
          detail: cause,
        ));
      }

      // Verificar que hay sesión local válida
      final isAuth = await localDataSource.isAuthenticated();
      if (!isAuth) {
        return Left(AuthFailure(
          message: 'Sesión expirada. Necesitas conexión a internet para renovar tu sesión.',
          errorCode: 'SESSION_EXPIRED',
          detail: cause,
        ));
      }

      // Obtener datos del usuario local
      final localUser = await localDataSource.getUser();
      if (localUser == null) {
        return const Left(CacheFailure(
          'No se encontraron datos de usuario. Necesitas conexión a internet.',
        ));
      }

      // Obtener token local
      final localToken = await localDataSource.getToken();
      if (localToken == null || localToken.isEmpty) {
        return const Left(CacheFailure(
          'Token no encontrado. Necesitas conexión a internet.',
        ));
      }

      // Obtener refresh token local
      final localRefreshToken = await localDataSource.getRefreshToken();

      // Retornar AuthResult con datos locales
      return Right(AuthResult(
        token: localToken,
        user: localUser.toEntity(),
        refreshToken: localRefreshToken,
      ));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error durante login offline: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    UserRole? role,
    String? organizationName,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = RegisterRequestModel.fromParams(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          role: role,
          organizationName: organizationName,
        );

        final response = await remoteDataSource.register(request);

        // Guardar datos localmente
        await localDataSource.saveAuthData(response);

        return Right(response.toAuthResult());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado durante el registro: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, AuthResult>> registerWithOnboarding({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    UserRole? role,
    String? organizationName,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = RegisterRequestModel.fromParams(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          role: role,
          organizationName: organizationName,
        );

        final response = await remoteDataSource.registerWithOnboarding(request);

        // Guardar datos localmente
        await localDataSource.saveAuthData(response);

        return Right(response.toAuthResult());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure(
            'Error inesperado durante el registro con onboarding: $e',
          ),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getProfile();

        // Actualizar datos locales con la información más reciente
        await localDataSource.saveUser(response.user);

        return Right(response.user.toEntity());
      } on ServerException {
        // Si falla la llamada remota, intentar obtener desde cache
        return _getProfileFromCache();
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return _getProfileFromCache();
      }
    } else {
      // Sin conexión, obtener desde cache
      return _getProfileFromCache();
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.refreshToken();

        // Guardar el nuevo token
        await localDataSource.saveToken(response.token);

        return Right(response.token);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al refrescar token: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      // ✅ ESTRATEGIA "LOGOUT PEREZOSO" — preserva el cache offline-first.
      // Antes el logout borraba TODA la BD ISAR (datos de negocio: clientes,
      // facturas, productos, etc). Si el usuario hacía logout offline o
      // backend caído, perdía todos sus datos sin posibilidad de recuperar.
      //
      // AHORA:
      //   1. Persistir el userId actual en SecureStorage (`lastUserId`).
      //   2. Logout remoto best-effort (si hay red).
      //   3. Limpiar tokens auth (clearAuthData), pero NO TOCAR ISAR.
      //   4. La BD se borra solo en el próximo login si detecta que es OTRO
      //      usuario distinto al `lastUserId` (cambio real de tenant).
      //   5. Si vuelves a entrar con el MISMO usuario, los datos están ahí
      //      intactos y solo se hace un sync incremental (FullSync).

      // 1. Guardar lastUserId ANTES de limpiar tokens (para que sobreviva
      //    al clearAuthData y esté disponible en el próximo login).
      try {
        final currentUser = await localDataSource.getUser();
        if (currentUser != null) {
          final storage = Get.find<SecureStorageService>();
          await storage.setLastUserId(currentUser.id);
        }
      } catch (e) {
      }

      // 2. Logout remoto best-effort
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.logout();
        } catch (e) {
        }
      }

      // 3. Limpiar SOLO tokens auth — NO TOCAR ISAR.
      // SecureStorage.clearAll() ahora preserva lastUserId además de deviceId.
      // Si clearAuthData falla (storage corrupto), intentamos al MENOS
      // borrar el token (lo más sensible) con un fallback directo. Mejor
      // dejar la app inconsistente que dejar el token vivo en disco.
      try {
        await localDataSource.clearAuthData();
      } catch (e) {
        try {
          final storage = Get.find<SecureStorageService>();
          await storage.deleteToken();
          await storage.deleteRefreshToken();
          await storage.deleteUserData();
        } catch (e2) {
          return Left(UnknownFailure('No se pudo limpiar credenciales: $e2'));
        }
      }

      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado durante el logout: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatar,
  }) async {
    final request = UpdateProfileRequestModel.fromParams(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      avatar: avatar,
    );

    // Verificar si hay cambios
    if (!request.hasUpdates) {
      return Left(ValidationFailure(['No hay cambios para actualizar']));
    }

    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.updateProfile(request);

        // Actualizar datos locales
        await localDataSource.saveUser(response);

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al actualizar perfil: $e'),
        );
      }
    } else {
      // Modo offline - actualizar localmente y agregar a cola de sync
      try {
        final localUser = await localDataSource.getUser();
        if (localUser == null) {
          return const Left(CacheFailure('Usuario no encontrado en cache'));
        }

        // Crear usuario actualizado
        final updatedUserModel = localUser.copyWith(
          firstName: firstName ?? localUser.firstName,
          lastName: lastName ?? localUser.lastName,
          phone: phone ?? localUser.phone,
          avatar: avatar ?? localUser.avatar,
        );

        // Primero a la cola: si no se puede, el cambio nunca llegaría al
        // servidor, así que no se aplica y se avisa.
        try {
          final syncService = Get.find<SyncService>();
          await syncService.addOperationForCurrentUser(
            entityType: 'user_profile',
            entityId: localUser.id,
            operationType: SyncOperationType.update,
            data: {
              if (firstName != null) 'firstName': firstName,
              if (lastName != null) 'lastName': lastName,
              if (phone != null) 'phone': phone,
              if (avatar != null) 'avatar': avatar,
            },
          );
        } catch (e) {
          return Left(CacheFailure(
            'No se pudo guardar el cambio para sincronizar. No se aplicó: $e',
          ));
        }

        // Guardar usuario actualizado
        await localDataSource.saveUser(updatedUserModel);

        return Right(updatedUserModel.toEntity());
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error al actualizar perfil offline: $e'),
        );
      }
    }
  }

  @override
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = ChangePasswordRequestModel(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        );

        await remoteDataSource.changePassword(request);

        return const Right(unit);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al cambiar contraseña: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      // localDataSource.isAuthenticated() devuelve un Future<bool>
      final isAuth = await localDataSource.isAuthenticated();
      return Right(isAuth); // ✅ Envuelve el resultado booleano en un Right
    } on CacheException catch (e) {
      // Si hay una excepción de cache, la manejamos como un Left(CacheFailure)
      return Left(CacheFailure(e.message));
    } catch (e) {
      // Para cualquier otra excepción inesperada
      return Left(
        UnknownFailure('Error inesperado al verificar autenticación local: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, User>> getLocalUser() async {
    try {
      final user = await localDataSource.getUser();
      if (user != null) {
        return Right(user.toEntity());
      } else {
        return const Left(CacheFailure.notFound);
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Error inesperado al obtener usuario local: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> clearLocalAuth() async {
    try {
      // ✅ Misma estrategia "logout perezoso" que `logout()`:
      // persistir lastUserId, NO tocar ISAR, solo limpiar tokens auth.
      // La BD se borra en el próximo login si detecta cambio de tenant.
      try {
        final currentUser = await localDataSource.getUser();
        if (currentUser != null) {
          final storage = Get.find<SecureStorageService>();
          await storage.setLastUserId(currentUser.id);
        }
      } catch (e) {
      }

      await localDataSource.clearAuthData();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Error inesperado al limpiar datos locales: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> verifyEmail({
    required String email,
    required String code,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.verifyEmail(email, code);
        return Right(result);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error al verificar email: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, bool>> resendVerificationCode({
    required String email,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.resendVerificationCode(email);
        return Right(result);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error al reenviar código: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, bool>> forgotPassword({
    required String email,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.forgotPassword(email);
        return Right(result);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error al solicitar recuperación: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, bool>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.resetPassword(email, code, newPassword);
        return Right(result);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error al restablecer contraseña: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  // ================== MÉTODOS PRIVADOS ==================

  /// Obtener perfil desde cache local
  Future<Either<Failure, User>> _getProfileFromCache() async {
    try {
      final user = await localDataSource.getUser();
      if (user != null) {
        return Right(user.toEntity());
      } else {
        return const Left(CacheFailure.notFound);
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al obtener perfil desde cache: $e'));
    }
  }

  /// Mapear ServerException a Failure
  Failure _mapServerExceptionToFailure(ServerException exception) {
    if (exception.statusCode != null) {
      return ServerFailure.fromStatusCode(
        exception.statusCode!,
        exception.message,
      );
    } else {
      return ServerFailure(exception.message);
    }
  }
}
