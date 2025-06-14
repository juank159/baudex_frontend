// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/entities/user.dart';
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
    if (await networkInfo.isConnected) {
      try {
        final request = LoginRequestModel(email: email, password: password);
        final response = await remoteDataSource.login(request);

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
        return Left(UnknownFailure('Error inesperado durante el login: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, AuthResult>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    UserRole? role,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = RegisterRequestModel.fromParams(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          role: role,
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
  Future<Either<Failure, User>> getProfile() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getProfile();

        // Actualizar datos locales con la información más reciente
        await localDataSource.saveUser(response.user);

        return Right(response.user.toEntity());
      } on ServerException catch (e) {
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

      // Limpiar datos locales siempre
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
    if (await networkInfo.isConnected) {
      try {
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
      return const Left(ConnectionFailure.noInternet);
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
