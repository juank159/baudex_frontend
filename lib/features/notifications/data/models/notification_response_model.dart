// lib/features/notifications/data/models/notification_response_model.dart
import '../../../../app/core/models/pagination_meta.dart';
import '../../../dashboard/domain/entities/notification.dart';
import 'notification_model.dart';

class NotificationResponseModel {
  final List<NotificationModel> data;
  final PaginationMeta meta;

  const NotificationResponseModel({
    required this.data,
    required this.meta,
  });

  /// Crear desde JSON (API response)
  /// Soporta múltiples formatos de respuesta del backend:
  /// 1. Formato envuelto: {"success":true,"data":{"notifications":[],"total":0,"page":1,"totalPages":0}}
  /// 2. Formato directo: {"data":[...],"meta":{...}}
  /// 3. Formato dashboard con anidación: {"success":true,"data":{"data":{"data":{"notifications":[],"unreadCount":0}}}}
  factory NotificationResponseModel.fromJson(Map<String, dynamic> json) {
    // Desenvolver múltiples niveles de anidación del dashboard
    Map<String, dynamic> responseData = _unwrapNestedData(json);

    // Obtener la lista de notificaciones
    List<NotificationModel> notifications = _extractNotifications(responseData, json);

    // Construir metadata de paginación
    PaginationMeta meta = _buildPaginationMeta(responseData, notifications.length);

    return NotificationResponseModel(
      data: notifications,
      meta: meta,
    );
  }

  /// Desenvolver niveles anidados de data (dashboard usa data.data.data)
  static Map<String, dynamic> _unwrapNestedData(Map<String, dynamic> json) {
    Map<String, dynamic> data = json;

    // Nivel 1: Si tiene 'success', extraer 'data'
    if (data.containsKey('success') && data['data'] is Map<String, dynamic>) {
      data = data['data'] as Map<String, dynamic>;
    }

    // Nivel 2: Si aún tiene 'data' como Map, extraer
    if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
      data = data['data'] as Map<String, dynamic>;
    }

    // Nivel 3: Si aún tiene 'data' como Map, extraer (dashboard tiene triple anidación)
    if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
      data = data['data'] as Map<String, dynamic>;
    }

    return data;
  }

  /// Extraer lista de notificaciones de la respuesta
  static List<NotificationModel> _extractNotifications(
    Map<String, dynamic> responseData,
    Map<String, dynamic> originalJson,
  ) {
    List<NotificationModel> notifications = [];

    // Formato 1: data.notifications (backend y dashboard)
    if (responseData.containsKey('notifications')) {
      final notificationsList = responseData['notifications'];
      if (notificationsList is List) {
        notifications = notificationsList
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    // Formato 2: data es directamente la lista
    else if (responseData['data'] is List) {
      notifications = (responseData['data'] as List)
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    // Formato 3: json['data'] es directamente la lista (sin success wrapper)
    else if (originalJson['data'] is List) {
      notifications = (originalJson['data'] as List)
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return notifications;
  }

  /// Construir metadata de paginación
  static PaginationMeta _buildPaginationMeta(
    Map<String, dynamic> responseData,
    int notificationsCount,
  ) {
    // Si hay 'meta' explícito
    if (responseData.containsKey('meta') && responseData['meta'] is Map<String, dynamic>) {
      return PaginationMeta.fromJson(responseData['meta'] as Map<String, dynamic>);
    }

    // Construir meta desde campos planos (total, page, totalPages, limit)
    // El dashboard puede no tener estos campos, usar valores por defecto
    // Nota: El servidor puede enviar valores como String o int
    final total = _parseIntSafe(responseData['total']) ??
                  _parseIntSafe(responseData['totalItems']) ??
                  _parseIntSafe(responseData['unreadCount']) ??
                  notificationsCount;
    final page = _parseIntSafe(responseData['page']) ?? 1;
    final totalPages = _parseIntSafe(responseData['totalPages']) ??
                       (total > 0 ? ((total / 20).ceil()) : 1);
    final limit = _parseIntSafe(responseData['limit']) ?? 20;

    return PaginationMeta(
      page: page,
      limit: limit,
      totalItems: total,
      totalPages: totalPages,
      hasNextPage: page < totalPages,
      hasPreviousPage: page > 1,
    );
  }

  /// Parsea un valor que puede venir como int, num o String del servidor
  static int? _parseIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }

  /// Conversión a PaginatedResult del dominio
  PaginatedResult<NotificationModel> toPaginatedResult() {
    return PaginatedResult<NotificationModel>(
      data: data,
      meta: meta,
    );
  }

  /// Conversión a PaginatedResult con entidades del dominio
  PaginatedResult<dynamic> toPaginatedResultWithEntities() {
    return PaginatedResult(
      data: data.map((model) => model.toEntity()).toList(),
      meta: meta,
    );
  }

  /// Obtener solo las notificaciones no leídas
  List<NotificationModel> get unreadNotifications {
    return data.where((notification) => !notification.isRead).toList();
  }

  /// Obtener contador de notificaciones no leídas
  int get unreadCount {
    return data.where((notification) => !notification.isRead).length;
  }

  /// Verificar si hay notificaciones no leídas
  bool get hasUnread => unreadCount > 0;

  /// Obtener notificaciones por tipo
  List<NotificationModel> getByType(NotificationType type) {
    return data.where((notification) => notification.type == type).toList();
  }

  /// Obtener notificaciones por prioridad
  List<NotificationModel> getByPriority(NotificationPriority priority) {
    return data.where((notification) => notification.priority == priority).toList();
  }

  /// Obtener notificaciones urgentes
  List<NotificationModel> get urgentNotifications {
    return data
        .where((notification) => notification.priority == NotificationPriority.urgent)
        .toList();
  }

  /// Verificar si hay notificaciones urgentes
  bool get hasUrgent => urgentNotifications.isNotEmpty;

  @override
  String toString() {
    return 'NotificationResponseModel(data: ${data.length} notifications, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationResponseModel &&
        other.data.length == data.length &&
        other.meta == meta;
  }

  @override
  int get hashCode => data.hashCode ^ meta.hashCode;
}
