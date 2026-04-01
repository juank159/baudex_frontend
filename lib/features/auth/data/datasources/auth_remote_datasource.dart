// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/change_password_request_model.dart';
import '../models/update_profile_request_model.dart';
import '../models/refresh_token_response_model.dart';
import '../models/profile_response_model.dart';
import '../models/user_model.dart';
import '../models/active_session_model.dart';
import '../models/api_error_model.dart';

/// Contrato para el datasource remoto de autenticación
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(LoginRequestModel request);
  Future<AuthResponseModel> register(RegisterRequestModel request);
  Future<AuthResponseModel> registerWithOnboarding(RegisterRequestModel request);
  Future<ProfileResponseModel> getProfile();
  Future<RefreshTokenResponseModel> refreshToken();
  Future<void> logout();
  Future<UserModel> updateProfile(UpdateProfileRequestModel request);
  Future<void> changePassword(ChangePasswordRequestModel request);
  Future<List<ActiveSessionModel>> getActiveSessions();
  Future<void> revokeSession(String sessionId);
  Future<int> revokeAllOtherSessions();
  Future<bool> verifyEmail(String email, String code);
  Future<bool> resendVerificationCode(String email);
  Future<bool> forgotPassword(String email);
  Future<bool> resetPassword(String email, String code, String newPassword);
}

/// Implementación del datasource remoto usando Dio
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  const AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await dioClient.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // El backend envuelve la respuesta en { success, data, timestamp }
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          return AuthResponseModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is ConnectionException) rethrow;
      throw ServerException('Error inesperado durante el login: $e');
    }
  }

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    try {
      final response = await dioClient.post(
        ApiConstants.register,
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // El backend envuelve la respuesta en { success, data, timestamp }
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          return AuthResponseModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado durante el registro: $e');
    }
  }

  @override
  Future<AuthResponseModel> registerWithOnboarding(RegisterRequestModel request) async {
    try {
      print('🏗️ AuthRemoteDataSource: Iniciando registro con onboarding automático...');

      // Registrar el usuario - el backend crea automáticamente:
      // almacén principal, datos de ejemplo, y suscripción trial
      final authResponse = await register(request);
      print('✅ AuthRemoteDataSource: Usuario registrado exitosamente');

      return authResponse;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado durante el registro con onboarding: $e');
    }
  }

  @override
  Future<ProfileResponseModel> getProfile() async {
    try {
      final response = await dioClient.get(ApiConstants.profile);

      if (response.statusCode == 200) {
        return ProfileResponseModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al obtener perfil: $e');
    }
  }

  @override
  Future<RefreshTokenResponseModel> refreshToken() async {
    try {
      final response = await dioClient.post(ApiConstants.refreshToken);

      if (response.statusCode == 200) {
        return RefreshTokenResponseModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al refrescar token: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.post(ApiConstants.logout);
    } catch (e) {
      // Si falla (ej: sin conexion), no bloquear el logout local
      print('⚠️ Logout remoto falló (no crítico): $e');
    }
  }

  @override
  Future<UserModel> updateProfile(UpdateProfileRequestModel request) async {
    try {
      final response = await dioClient.patch(
        ApiConstants.userProfile,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        // El backend podría retornar directamente el user o wrapped
        final userData = response.data['user'] ?? response.data;
        return UserModel.fromJson(userData);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al actualizar perfil: $e');
    }
  }

  @override
  Future<void> changePassword(ChangePasswordRequestModel request) async {
    try {
      final response = await dioClient.patch(
        ApiConstants.changePassword,
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw _handleErrorResponse(response);
      }
      // Si llega aquí, el cambio fue exitoso
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al cambiar contraseña: $e');
    }
  }

  @override
  Future<bool> verifyEmail(String email, String code) async {
    try {
      final response = await dioClient.post(
        ApiConstants.verifyEmail,
        data: {
          'email': email,
          'code': code,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return true;
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is ConnectionException) rethrow;
      throw ServerException('Error inesperado al verificar email: $e');
    }
  }

  @override
  Future<bool> resendVerificationCode(String email) async {
    try {
      final response = await dioClient.post(
        ApiConstants.resendVerification,
        data: {'email': email},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return true;
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is ConnectionException) rethrow;
      throw ServerException('Error inesperado al reenviar código: $e');
    }
  }

  @override
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await dioClient.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return true;
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is ConnectionException) rethrow;
      throw ServerException('Error inesperado al solicitar recuperación: $e');
    }
  }

  @override
  Future<bool> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await dioClient.post(
        ApiConstants.resetPassword,
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          return true;
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is ConnectionException) rethrow;
      throw ServerException('Error inesperado al restablecer contraseña: $e');
    }
  }

  /// Manejar errores de respuesta HTTP
  ServerException _handleErrorResponse(Response response) {
    try {
      final errorModel = ApiErrorModel.fromJson(response.data);
      return ServerException(
        errorModel.primaryMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      // Si no se puede parsear el error, usar mensaje genérico
      return ServerException(
        'Error del servidor: ${response.statusMessage}',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<List<ActiveSessionModel>> getActiveSessions() async {
    try {
      final response = await dioClient.get(ApiConstants.sessions);

      if (response.statusCode == 200) {
        final List<dynamic> sessionsList;
        final data = response.data;

        if (data is List) {
          sessionsList = data;
        } else if (data is Map && data.containsKey('data') && data['data'] is List) {
          sessionsList = data['data'] as List;
        } else if (data is Map && data.containsKey('success') && data['data'] is List) {
          sessionsList = data['data'] as List;
        } else {
          sessionsList = [];
        }

        return sessionsList
            .map((json) => ActiveSessionModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw ServerException('Error al obtener sesiones activas');
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is ConnectionException) rethrow;
      throw ServerException('Error inesperado al obtener sesiones: $e');
    }
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    try {
      await dioClient.delete('${ApiConstants.sessions}/$sessionId');
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is ConnectionException) rethrow;
      throw ServerException('Error al revocar sesión: $e');
    }
  }

  @override
  Future<int> revokeAllOtherSessions() async {
    try {
      final response = await dioClient.delete(ApiConstants.sessions);
      if (response.statusCode == 200 && response.data is Map) {
        return response.data['revokedCount'] as int? ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException || e is ConnectionException) rethrow;
      throw ServerException('Error al revocar sesiones: $e');
    }
  }

  /// Manejar excepciones de Dio
  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ConnectionException('Tiempo de conexión agotado');

      case DioExceptionType.badResponse:
        if (e.response != null) {
          return _handleErrorResponse(e.response!);
        }
        return const ServerException('Respuesta inválida del servidor');

      case DioExceptionType.cancel:
        return const ServerException('Solicitud cancelada');

      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') == true) {
          return const ConnectionException('Sin conexión a internet');
        }
        return ServerException('Error de conexión: ${e.message}');

      default:
        return ServerException('Error desconocido: ${e.message}');
    }
  }
}
