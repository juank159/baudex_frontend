// lib/features/settings/data/datasources/organization_remote_datasource.dart
import '../../../../app/core/errors/automatic_work.dart';
import '../../../../app/core/utils/tolerant_json.dart';
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
      return _read(response.data, response.requestOptions.path);
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener organización actual');
    } on AppException {
      // Ya viene tipado por el cliente HTTP (sin conexión, tiempo agotado,
      // rechazo con el mensaje del servidor): se pasa tal cual.
      rethrow;
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
      return _read(response.data, response.requestOptions.path);
    } on DioException catch (e) {
      throw _handleDioException(e, 'actualizar organización');
    } on AppException {
      // Ya viene tipado por el cliente HTTP (sin conexión, tiempo agotado,
      // rechazo con el mensaje del servidor): se pasa tal cual.
      rethrow;
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
      return _read(response.data, response.requestOptions.path);
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener organización');
    } on AppException {
      // Ya viene tipado por el cliente HTTP (sin conexión, tiempo agotado,
      // rechazo con el mensaje del servidor): se pasa tal cual.
      rethrow;
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
    } on AppException {
      // Ya viene tipado por el cliente HTTP (sin conexión, tiempo agotado,
      // rechazo con el mensaje del servidor): se pasa tal cual.
      rethrow;
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

  /// Lee el negocio de la respuesta sin fallar por un campo raro. Lo que no
  /// llegó como se esperaba queda anotado para Diagnóstico (campo y tipo,
  /// sin valores). Solo falla si la respuesta no trae un negocio.
  OrganizationModel _read(Object? body, String route) {
    final data = unwrapData(body,
        looksLikeIt: (m) => m.containsKey('id') && m.containsKey('name'));
    final issues = <JsonIssue>[];
    final model = OrganizationModel.fromJson(data, issues: issues);
    if (issues.isNotEmpty) {
      BackgroundFailureLog.instance.noteNotice(
        AutomaticWork.current ?? BackgroundFailureLog.userAction,
        'Lectura del negocio ($route)',
        issues.take(12).join('; '),
      );
    }
    if (model.id.isEmpty) {
      throw const ServerException(
        'El servidor respondió sin los datos del negocio',
        statusCode: 200,
      );
    }
    return model;
  }
}
