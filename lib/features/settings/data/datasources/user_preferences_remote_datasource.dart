import 'package:dio/dio.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/dio_client.dart';
import '../models/user_preferences_model.dart';

abstract class UserPreferencesRemoteDataSource {
  Future<UserPreferencesModel> getUserPreferences();
  Future<UserPreferencesModel> updateUserPreferences(Map<String, dynamic> preferences);
}

class UserPreferencesRemoteDataSourceImpl implements UserPreferencesRemoteDataSource {
  final DioClient dioClient;

  UserPreferencesRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserPreferencesModel> getUserPreferences() async {
    try {
      final response = await dioClient.get('/user-preferences');
      
      if (response.statusCode == 200 && response.data != null) {
        // El backend devuelve la respuesta envuelta en {"success": true, "data": {...}}
        final data = response.data['data'] ?? response.data;
        return UserPreferencesModel.fromJson(data);
      } else {
        throw ServerException('Error al obtener preferencias de usuario');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<UserPreferencesModel> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final updateData = UserPreferencesModel.toUpdateJson(preferences);
      
      final response = await dioClient.patch(
        '/user-preferences',
        data: updateData,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        // El backend devuelve la respuesta envuelta en {"success": true, "data": {...}}
        final data = response.data['data'] ?? response.data;
        return UserPreferencesModel.fromJson(data);
      } else {
        throw ServerException('Error al actualizar preferencias de usuario');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de respuesta agotado';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Error del servidor';
        return '[$statusCode] $message';
      case DioExceptionType.cancel:
        return 'Petición cancelada';
      case DioExceptionType.connectionError:
        return 'Error de conexión. Verifique su conexión a internet';
      default:
        return 'Error de red: ${e.message}';
    }
  }
}