// lib/features/settings/data/datasources/organization_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/organization_model.dart';

abstract class OrganizationRemoteDataSource {
  Future<OrganizationModel> getCurrentOrganization();
  Future<OrganizationModel> updateCurrentOrganization(
    Map<String, dynamic> updates,
  );
  Future<OrganizationModel> getOrganizationById(String id);
  Future<bool> updateProfitMargin(double marginPercentage);
}

class OrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  final DioClient dioClient;

  OrganizationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<OrganizationModel> getCurrentOrganization() async {
    try {
      final response = await dioClient.get('/organizations/current');
      return OrganizationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener organización actual');
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener organización actual: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<OrganizationModel> updateCurrentOrganization(
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await dioClient.patch(
        '/organizations/current',
        data: updates,
      );
      return OrganizationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e, 'actualizar organización');
    } catch (e) {
      throw ServerException(
        'Error inesperado al actualizar organización: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<OrganizationModel> getOrganizationById(String id) async {
    try {
      final response = await dioClient.get('/organizations/$id');
      return OrganizationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener organización');
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener organización: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> updateProfitMargin(double marginPercentage) async {
    try {
      final response = await dioClient.put(
        '/organizations/current/profit-margin',
        data: {'marginPercentage': marginPercentage},
      );
      return response.data['success'] as bool? ?? false;
    } on DioException catch (e) {
      throw _handleDioException(e, 'actualizar margen de ganancia');
    } catch (e) {
      throw ServerException(
        'Error inesperado al actualizar margen de ganancia: $e',
        statusCode: 500,
      );
    }
  }

  /// Distinguir entre errores de conexión y errores de servidor
  Exception _handleDioException(DioException e, String operation) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ConnectionException.timeout;

      case DioExceptionType.badResponse:
        if (e.response != null) {
          final errData = e.response?.data;
          final message = (errData is Map
                  ? errData['message']?.toString()
                  : errData?.toString()) ??
              'Error al $operation';
          return ServerException(message,
              statusCode: e.response?.statusCode ?? 500);
        }
        return ServerException('Respuesta inválida del servidor',
            statusCode: 500);

      case DioExceptionType.cancel:
        return const ServerException('Solicitud cancelada', statusCode: 499);

      case DioExceptionType.connectionError:
        return ConnectionException.noInternet;

      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') == true ||
            e.error.toString().contains('SocketException')) {
          return ConnectionException.socketException;
        }
        return ServerException('Error de conexión: ${e.message}',
            statusCode: 500);

      default:
        return ServerException('Error desconocido: ${e.message}',
            statusCode: 500);
    }
  }
}
