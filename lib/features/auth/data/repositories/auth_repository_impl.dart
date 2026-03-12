// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
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
    // Generar hash del password para uso offline
    final passwordHash = _hashPassword(password, email);

    if (await networkInfo.isConnected) {
      try {
        final request = LoginRequestModel(email: email, password: password);
        final response = await remoteDataSource.login(request);

        // Guardar datos localmente
        await localDataSource.saveAuthData(response);

        // Guardar credenciales hasheadas para login offline
        await localDataSource.saveOfflineCredentials(email, passwordHash);
        print('🔐 AuthRepository: Credenciales offline guardadas para login futuro');

        return Right(response.toAuthResult());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        // Si hay error de conexión, intentar login offline
        print('⚠️ AuthRepository: Error de conexión, intentando login offline...');
        return _attemptOfflineLogin(email, passwordHash);
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        // Si es un error de conexión, intentar login offline
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection') ||
            e.toString().contains('Network')) {
          print('⚠️ AuthRepository: Error de red detectado, intentando login offline...');
          return _attemptOfflineLogin(email, passwordHash);
        }
        return Left(UnknownFailure('Error inesperado durante el login: $e'));
      }
    } else {
      // Sin conexión - intentar login offline
      print('📴 AuthRepository: Sin conexión, intentando login offline...');
      return _attemptOfflineLogin(email, passwordHash);
    }
  }

  /// Intenta realizar login offline con credenciales cacheadas
  Future<Either<Failure, AuthResult>> _attemptOfflineLogin(
    String email,
    String passwordHash,
  ) async {
    try {
      // Verificar si hay credenciales offline guardadas
      final hasOfflineCredentials = await localDataSource.hasOfflineCredentials();
      if (!hasOfflineCredentials) {
        return const Left(AuthFailure(
          message: 'No hay sesión previa guardada. Necesitas conexión a internet para el primer login.',
          errorCode: 'NO_OFFLINE_CREDENTIALS',
        ));
      }

      // Verificar credenciales
      final credentialsValid = await localDataSource.verifyOfflineCredentials(
        email,
        passwordHash,
      );

      if (!credentialsValid) {
        return const Left(AuthFailure(
          message: 'Credenciales incorrectas',
          errorCode: 'INVALID_CREDENTIALS',
        ));
      }

      // Verificar que hay sesión local válida
      final isAuth = await localDataSource.isAuthenticated();
      if (!isAuth) {
        return const Left(AuthFailure(
          message: 'Sesión expirada. Necesitas conexión a internet para renovar tu sesión.',
          errorCode: 'SESSION_EXPIRED',
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

      print('✅ AuthRepository: Login offline exitoso para ${localUser.email}');

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

  /// Genera un hash seguro del password combinado con el email
  String _hashPassword(String password, String email) {
    // Usar email como salt para mayor seguridad
    final saltedPassword = '${email.toLowerCase().trim()}:$password';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
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

        print(
          '🏗️ AuthRepository: Ejecutando registro con onboarding automático...',
        );
        final response = await remoteDataSource.registerWithOnboarding(request);

        // Guardar datos localmente
        await localDataSource.saveAuthData(response);
        print('✅ AuthRepository: Onboarding completado exitosamente');

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
      // Intentar logout remoto si hay conexión
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.logout();
        } catch (e) {
          // Si falla el logout remoto, continúa con el local
          print('Error en logout remoto (continuando con local): $e');
        }
      }

      // CRÍTICO: Limpiar base de datos ISAR (datos de negocio del tenant)
      try {
        final isarDatabase = IsarDatabase.instance;
        if (isarDatabase.isInitialized) {
          await isarDatabase.clear();
          print('✅ ISAR: Base de datos de negocio limpiada en logout');
        }
      } catch (e) {
        print('⚠️ Error limpiando ISAR en logout (no crítico): $e');
      }

      // Limpiar datos locales (auth + cache de negocio en SecureStorage)
      await localDataSource.clearAuthData();

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

        // Guardar usuario actualizado
        await localDataSource.saveUser(updatedUserModel);

        // Agregar a cola de sincronización
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
          print('Warning: Could not add profile update to sync queue: $e');
        }

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
      // Limpiar ISAR (datos de negocio del tenant)
      try {
        final isarDatabase = IsarDatabase.instance;
        if (isarDatabase.isInitialized) {
          await isarDatabase.clear();
          print('✅ ISAR: Base de datos limpiada en clearLocalAuth');
        }
      } catch (e) {
        print('⚠️ Error limpiando ISAR en clearLocalAuth: $e');
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
