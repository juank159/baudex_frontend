// lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/dio_client.dart';
import '../models/subscription_model.dart';
import '../models/subscription_usage_model.dart';
import '../models/action_validation_model.dart';
import '../models/plan_limits_model.dart';

abstract class SubscriptionRemoteDataSource {
  /// Obtener suscripcion actual del servidor
  Future<SubscriptionModel> getCurrentSubscription();

  /// Obtener limites del plan actual
  Future<PlanLimitsModel> getSubscriptionLimits();

  /// Obtener uso de recursos actual
  Future<SubscriptionUsageModel> getSubscriptionUsage({
    int products = 0,
    int customers = 0,
    int users = 0,
    int invoicesThisMonth = 0,
    int expensesThisMonth = 0,
    int storageMB = 0,
  });

  /// Validar una accion segun el plan
  Future<ActionValidationModel> validateAction(
    String action, {
    int? currentUsage,
  });
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final DioClient dioClient;

  SubscriptionRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<SubscriptionModel> getCurrentSubscription() async {
    try {
      final response = await dioClient.get('/subscriptions/current');

      if (response.statusCode == 200 && response.data != null) {
        // El backend puede devolver la respuesta directamente o envuelta
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return SubscriptionModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException('Error al obtener suscripcion actual');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PlanLimitsModel> getSubscriptionLimits() async {
    try {
      final response = await dioClient.get('/subscriptions/limits');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        // El endpoint retorna SubscriptionLimitsResponseDto que contiene 'limits'
        final limitsData = data['limits'] ?? data;
        return PlanLimitsModel.fromJson(limitsData as Map<String, dynamic>);
      } else {
        throw ServerException('Error al obtener limites del plan');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<SubscriptionUsageModel> getSubscriptionUsage({
    int products = 0,
    int customers = 0,
    int users = 0,
    int invoicesThisMonth = 0,
    int expensesThisMonth = 0,
    int storageMB = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'products': products.toString(),
        'customers': customers.toString(),
        'users': users.toString(),
        'invoicesThisMonth': invoicesThisMonth.toString(),
        'expensesThisMonth': expensesThisMonth.toString(),
        'storageMB': storageMB.toString(),
      };

      final response = await dioClient.get(
        '/subscriptions/usage',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return SubscriptionUsageModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException('Error al obtener uso de suscripcion');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<ActionValidationModel> validateAction(
    String action, {
    int? currentUsage,
  }) async {
    try {
      final body = <String, dynamic>{
        'action': action,
        if (currentUsage != null) 'currentUsage': currentUsage,
      };

      final response = await dioClient.post(
        '/subscriptions/validate-action',
        data: body,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return ActionValidationModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException('Error al validar accion');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error inesperado: $e');
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexion agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envio agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de respuesta agotado';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Error del servidor';
        return '[$statusCode] $message';
      case DioExceptionType.cancel:
        return 'Peticion cancelada';
      case DioExceptionType.connectionError:
        return 'Error de conexion. Verifique su conexion a internet';
      default:
        return 'Error de red: ${e.message}';
    }
  }
}
