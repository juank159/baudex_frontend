// lib/features/notifications/data/datasources/notification_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../dashboard/domain/entities/notification.dart';
import '../models/notification_model.dart';
import '../models/notification_response_model.dart';
import '../models/notification_query_model.dart';
import '../models/create_notification_request_model.dart';
import '../../domain/repositories/notification_repository.dart';

/// Contrato para el datasource remoto de notificaciones
abstract class NotificationRemoteDataSource {
  /// Obtener notificaciones con paginación y filtros
  Future<NotificationResponseModel> getNotifications(
    NotificationQueryModel query,
  );

  /// Obtener notificación por ID
  Future<NotificationModel> getNotificationById(String id);

  /// Obtener notificaciones no leídas
  Future<List<NotificationModel>> getUnreadNotifications({int limit = 10});

  /// Obtener contador de notificaciones no leídas
  Future<int> getUnreadCount();

  /// Obtener estadísticas de notificaciones
  Future<NotificationStats> getStatistics();

  /// Buscar notificaciones
  Future<List<NotificationModel>> searchNotifications(
    String query,
    int limit,
  );

  /// Crear notificación
  Future<NotificationModel> createNotification(
    CreateNotificationRequestModel request,
  );

  /// Marcar notificación como leída
  Future<NotificationModel> markAsRead(String id);

  /// Marcar notificación como no leída
  Future<NotificationModel> markAsUnread(String id);

  /// Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead();

  /// Eliminar notificación
  Future<void> deleteNotification(String id);

  /// Eliminar todas las notificaciones leídas
  Future<void> deleteAllRead();

  // ==================== DYNAMIC NOTIFICATION STATES ====================

  /// Obtener IDs de notificaciones dinámicas marcadas como leídas en el backend
  Future<List<String>> getReadDynamicNotificationIds();

  /// Sincronizar estado de una notificación dinámica con el backend
  Future<void> syncDynamicNotificationState(String dynamicNotificationId, bool isRead);

  /// Sincronizar múltiples estados de notificaciones dinámicas
  Future<void> syncDynamicNotificationStates(Map<String, bool> states);

  /// Marcar todas las notificaciones dinámicas como leídas en el backend
  Future<void> markAllDynamicNotificationsAsRead();
}

/// Implementación del datasource remoto usando Dio
class NotificationRemoteDataSourceImpl
    implements NotificationRemoteDataSource {
  final DioClient dioClient;

  const NotificationRemoteDataSourceImpl({required this.dioClient});

  static const String _baseUrl = '/notifications';
  static const String _dashboardUrl = '/dashboard/notifications';

  // ==================== READ OPERATIONS ====================

  @override
  Future<NotificationResponseModel> getNotifications(
    NotificationQueryModel query,
  ) async {
    try {
      // Usar endpoint unificado /dashboard/notifications que genera notificaciones
      // dinámicas basadas en reglas de negocio (stock bajo, facturas vencidas, etc.)
      final queryParams = <String, dynamic>{
        'page': query.page,
        'limit': query.limit,
        'includeRead': query.unreadOnly != true,
      };

      // Mapear prioridades si están definidas
      if (query.priority != null) {
        queryParams['priorities'] = _mapPriorityToString(query.priority!);
      }

      // Mapear tipos si están definidos
      if (query.type != null) {
        queryParams['types'] = _mapTypeToSmartType(query.type!);
      }

      final response = await dioClient.get(
        _dashboardUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return NotificationResponseModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener notificaciones: $e',
      );
    }
  }

  /// Mapear NotificationPriority a string para el endpoint del dashboard
  String _mapPriorityToString(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return 'critical';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.medium:
        return 'medium';
      case NotificationPriority.low:
        return 'low';
    }
  }

  /// Mapear NotificationType a string para el endpoint del dashboard
  String _mapTypeToSmartType(NotificationType type) {
    switch (type) {
      case NotificationType.lowStock:
        return 'stock_low';
      case NotificationType.invoice:
        return 'invoice_due_soon';
      case NotificationType.payment:
        return 'payment_received';
      case NotificationType.system:
        return 'system_error';
      case NotificationType.sale:
        return 'sales_milestone';
      case NotificationType.user:
        return 'new_customer';
      case NotificationType.expense:
        return 'payment_failed';
      case NotificationType.reminder:
        return 'invoice_due_soon';
    }
  }

  @override
  Future<NotificationModel> getNotificationById(String id) async {
    try {
      final response = await dioClient.get('$_baseUrl/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return NotificationModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener notificación: $e',
      );
    }
  }

  @override
  Future<List<NotificationModel>> getUnreadNotifications({
    int limit = 10,
  }) async {
    try {
      // Usar endpoint unificado /dashboard/notifications con includeRead=false
      final response = await dioClient.get(
        _dashboardUrl,
        queryParameters: {
          'limit': limit,
          'includeRead': false,
        },
      );

      if (response.statusCode == 200) {
        final notifications = _extractNotificationsFromResponse(response.data);
        return notifications;
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener notificaciones no leídas: $e',
      );
    }
  }

  /// Extraer lista de notificaciones de la respuesta del dashboard
  /// Maneja múltiples niveles de anidación
  List<NotificationModel> _extractNotificationsFromResponse(dynamic responseData) {
    try {
      Map<String, dynamic> data = responseData;

      // Desenvolver niveles de anidación: data.data.data.notifications
      if (data.containsKey('success') && data['data'] is Map<String, dynamic>) {
        data = data['data'] as Map<String, dynamic>;
      }
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        data = data['data'] as Map<String, dynamic>;
      }
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        data = data['data'] as Map<String, dynamic>;
      }

      // Buscar la lista de notificaciones
      List<dynamic>? notificationsList;
      if (data.containsKey('notifications') && data['notifications'] is List) {
        notificationsList = data['notifications'] as List<dynamic>;
      } else if (data.containsKey('data') && data['data'] is List) {
        notificationsList = data['data'] as List<dynamic>;
      }

      if (notificationsList != null) {
        return notificationsList
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error extrayendo notificaciones: $e');
      return [];
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      // Usar endpoint unificado /dashboard/notifications que retorna unreadCount
      final response = await dioClient.get(
        _dashboardUrl,
        queryParameters: {
          'limit': 1, // Solo necesitamos el contador, no todas las notificaciones
          'includeRead': false,
        },
      );

      if (response.statusCode == 200) {
        return _extractUnreadCountFromResponse(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener contador de no leídas: $e',
      );
    }
  }

  /// Extraer el contador de no leídas de la respuesta del dashboard
  int _extractUnreadCountFromResponse(dynamic responseData) {
    try {
      Map<String, dynamic> data = responseData;

      // Desenvolver niveles de anidación
      if (data.containsKey('success') && data['data'] is Map<String, dynamic>) {
        data = data['data'] as Map<String, dynamic>;
      }
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        data = data['data'] as Map<String, dynamic>;
      }
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        data = data['data'] as Map<String, dynamic>;
      }

      // Buscar unreadCount en diferentes niveles (servidor puede enviar String o int)
      if (data.containsKey('unreadCount')) {
        final value = data['unreadCount'];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      // Si no hay unreadCount, contar las notificaciones manualmente
      if (data.containsKey('notifications') && data['notifications'] is List) {
        return (data['notifications'] as List).length;
      }

      return 0;
    } catch (e) {
      print('Error extrayendo unreadCount: $e');
      return 0;
    }
  }

  @override
  Future<NotificationStats> getStatistics() async {
    try {
      final response = await dioClient.get('$_baseUrl/statistics');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return _parseStatistics(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener estadísticas: $e',
      );
    }
  }

  @override
  Future<List<NotificationModel>> searchNotifications(
    String query,
    int limit,
  ) async {
    try {
      final response = await dioClient.get(
        '$_baseUrl/search',
        queryParameters: {'q': query, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          return data
              .map((item) =>
                  NotificationModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al buscar notificaciones: $e');
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<NotificationModel> createNotification(
    CreateNotificationRequestModel request,
  ) async {
    try {
      // Validar request antes de enviar
      if (!request.isValid()) {
        throw ValidationException(request.getValidationErrors());
      }

      final response = await dioClient.post(
        _baseUrl,
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return NotificationModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw ServerException('Error inesperado al crear notificación: $e');
    }
  }

  @override
  Future<NotificationModel> markAsRead(String id) async {
    try {
      final response = await dioClient.patch('$_baseUrl/$id/read');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return NotificationModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al marcar como leída: $e',
      );
    }
  }

  @override
  Future<NotificationModel> markAsUnread(String id) async {
    try {
      final response = await dioClient.patch('$_baseUrl/$id/unread');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return NotificationModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al marcar como no leída: $e',
      );
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final response = await dioClient.patch('$_baseUrl/read-all');

      if (response.statusCode != 200) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al marcar todas como leídas: $e',
      );
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      final response = await dioClient.delete('$_baseUrl/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al eliminar notificación: $e');
    }
  }

  @override
  Future<void> deleteAllRead() async {
    try {
      final response = await dioClient.delete('$_baseUrl/read');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al eliminar notificaciones leídas: $e',
      );
    }
  }

  // ==================== ERROR HANDLING ====================

  AppException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ServerException(
          'Tiempo de espera agotado. Verifica tu conexión.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final errData = error.response?.data;
        final message = (errData is Map ? errData['message']?.toString() : errData?.toString()) ?? 'Error desconocido';

        switch (statusCode) {
          case 400:
            return ServerException('Solicitud inválida: $message', statusCode: 400);
          case 401:
            return ServerException('No autorizado: $message', statusCode: 401);
          case 403:
            return ServerException('Acceso denegado: $message', statusCode: 403);
          case 404:
            return ServerException('Notificación no encontrada', statusCode: 404);
          case 409:
            return ServerException('Conflicto: $message', statusCode: 409);
          case 422:
            return ServerException('Validación fallida: $message', statusCode: 422);
          case 500:
          case 502:
          case 503:
          case 504:
            return ServerException('Error del servidor: $message', statusCode: statusCode);
          default:
            return ServerException('Error HTTP $statusCode: $message', statusCode: statusCode);
        }

      case DioExceptionType.cancel:
        return ServerException('Solicitud cancelada');

      case DioExceptionType.connectionError:
        return ConnectionException(
          'Sin conexión a internet. Verifica tu red.',
        );

      case DioExceptionType.badCertificate:
        return ServerException('Certificado SSL inválido');

      case DioExceptionType.unknown:
      default:
        return ServerException('Error de red: ${error.message}');
    }
  }

  ServerException _handleErrorResponse(Response response) {
    final statusCode = response.statusCode;
    final errData = response.data;
    final message = (errData is Map ? errData['message']?.toString() : errData?.toString()) ?? 'Error desconocido';

    switch (statusCode) {
      case 400:
        return ServerException('Solicitud inválida: $message', statusCode: 400);
      case 401:
        return ServerException('No autorizado', statusCode: 401);
      case 403:
        return ServerException('Acceso denegado', statusCode: 403);
      case 404:
        return ServerException('Notificación no encontrada', statusCode: 404);
      case 409:
        return ServerException('Conflicto: $message', statusCode: 409);
      case 422:
        return ServerException('Validación fallida: $message', statusCode: 422);
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException('Error del servidor: $message', statusCode: statusCode);
      default:
        return ServerException('Error HTTP $statusCode: $message', statusCode: statusCode);
    }
  }

  // ==================== HELPERS ====================

  /// Parsear estadísticas desde JSON
  NotificationStats _parseStatistics(Map<String, dynamic> json) {
    return NotificationStats(
      total: json['total'] as int? ?? 0,
      unread: json['unread'] as int? ?? 0,
      read: json['read'] as int? ?? 0,
      byType: _parseByType(json['byType'] as Map<String, dynamic>? ?? {}),
      byPriority:
          _parseByPriority(json['byPriority'] as Map<String, dynamic>? ?? {}),
      lastNotificationDate: json['lastNotificationDate'] != null
          ? DateTime.parse(json['lastNotificationDate'] as String)
          : null,
      oldestUnreadDate: json['oldestUnreadDate'] != null
          ? DateTime.parse(json['oldestUnreadDate'] as String)
          : null,
    );
  }

  /// Parsear byType desde JSON
  Map<NotificationType, int> _parseByType(Map<String, dynamic> json) {
    final Map<NotificationType, int> result = {};

    for (final entry in json.entries) {
      final type = _stringToNotificationType(entry.key);
      final count = entry.value as int? ?? 0;
      result[type] = count;
    }

    return result;
  }

  /// Parsear byPriority desde JSON
  Map<NotificationPriority, int> _parseByPriority(Map<String, dynamic> json) {
    final Map<NotificationPriority, int> result = {};

    for (final entry in json.entries) {
      final priority = _stringToNotificationPriority(entry.key);
      final count = entry.value as int? ?? 0;
      result[priority] = count;
    }

    return result;
  }

  /// Convertir string a NotificationType
  NotificationType _stringToNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'system':
        return NotificationType.system;
      case 'payment':
        return NotificationType.payment;
      case 'invoice':
        return NotificationType.invoice;
      case 'lowstock':
      case 'low_stock':
        return NotificationType.lowStock;
      case 'expense':
        return NotificationType.expense;
      case 'sale':
        return NotificationType.sale;
      case 'user':
        return NotificationType.user;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.system;
    }
  }

  /// Convertir string a NotificationPriority
  NotificationPriority _stringToNotificationPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'medium':
        return NotificationPriority.medium;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.medium;
    }
  }

  // ==================== DYNAMIC NOTIFICATION STATES ====================

  @override
  Future<List<String>> getReadDynamicNotificationIds() async {
    try {
      final response = await dioClient.get('$_baseUrl/dynamic-states/read-ids');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['readIds'] != null) {
          return (responseData['readIds'] as List<dynamic>)
              .map((id) => id as String)
              .toList();
        }
        return [];
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener IDs de notificaciones dinámicas leídas: $e',
      );
    }
  }

  @override
  Future<void> syncDynamicNotificationState(
    String dynamicNotificationId,
    bool isRead,
  ) async {
    try {
      final response = await dioClient.patch(
        '$_baseUrl/dynamic-states/$dynamicNotificationId',
        data: {'isRead': isRead},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al sincronizar estado de notificación dinámica: $e',
      );
    }
  }

  @override
  Future<void> syncDynamicNotificationStates(Map<String, bool> states) async {
    try {
      final statesList = states.entries
          .map((e) => {'dynamicNotificationId': e.key, 'isRead': e.value})
          .toList();

      final response = await dioClient.post(
        '$_baseUrl/dynamic-states/sync',
        data: {'states': statesList},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al sincronizar estados de notificaciones dinámicas: $e',
      );
    }
  }

  @override
  Future<void> markAllDynamicNotificationsAsRead() async {
    try {
      final response = await dioClient.patch(
        '$_baseUrl/dynamic-states/read-all',
      );

      if (response.statusCode != 200) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al marcar todas las notificaciones dinámicas como leídas: $e',
      );
    }
  }
}
