// lib/features/notifications/domain/repositories/notification_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../dashboard/domain/entities/notification.dart';

abstract class NotificationRepository {
  // ==================== READ OPERATIONS ====================

  /// Obtener notificaciones con paginación y filtros
  Future<Either<Failure, PaginatedResult<Notification>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
  });

  /// Obtener notificación por ID
  Future<Either<Failure, Notification>> getNotificationById(String id);

  /// Buscar notificaciones por término
  Future<Either<Failure, List<Notification>>> searchNotifications(
    String searchTerm, {
    int limit = 10,
  });

  /// Obtener contador de notificaciones no leídas
  Future<Either<Failure, int>> getUnreadCount();

  /// Obtener notificaciones no leídas
  Future<Either<Failure, List<Notification>>> getUnreadNotifications({
    int limit = 20,
  });

  /// Obtener notificaciones por tipo
  Future<Either<Failure, List<Notification>>> getNotificationsByType(
    NotificationType type, {
    int limit = 20,
  });

  /// Obtener notificaciones por prioridad
  Future<Either<Failure, List<Notification>>> getNotificationsByPriority(
    NotificationPriority priority, {
    int limit = 20,
  });

  /// Obtener estadísticas de notificaciones
  Future<Either<Failure, NotificationStats>> getStatistics();

  // ==================== WRITE OPERATIONS ====================

  /// Crear notificación
  Future<Either<Failure, Notification>> createNotification({
    required NotificationType type,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.medium,
    String? relatedId,
    Map<String, dynamic>? actionData,
  });

  /// Marcar notificación como leída
  Future<Either<Failure, Notification>> markAsRead(String id);

  /// Marcar notificación como no leída
  Future<Either<Failure, Notification>> markAsUnread(String id);

  /// Marcar todas las notificaciones como leídas
  Future<Either<Failure, Unit>> markAllAsRead();

  /// Marcar notificaciones por tipo como leídas
  Future<Either<Failure, Unit>> markTypeAsRead(NotificationType type);

  /// Eliminar notificación (soft delete)
  Future<Either<Failure, Unit>> deleteNotification(String id);

  /// Eliminar todas las notificaciones leídas
  Future<Either<Failure, Unit>> deleteAllRead();

  /// Eliminar notificaciones antiguas
  Future<Either<Failure, Unit>> deleteOlderThan(DateTime date);

  /// Restaurar notificación
  Future<Either<Failure, Notification>> restoreNotification(String id);

  // ==================== CACHE OPERATIONS ====================

  /// Obtener notificaciones desde cache
  Future<Either<Failure, List<Notification>>> getCachedNotifications();

  /// Limpiar cache de notificaciones
  Future<Either<Failure, Unit>> clearNotificationCache();

  // ==================== VALIDATION OPERATIONS ====================

  /// Verificar si hay notificaciones no leídas
  Future<Either<Failure, bool>> hasUnreadNotifications();

  /// Verificar si existe una notificación
  Future<Either<Failure, bool>> existsById(String id);
}

/// Estadísticas de notificaciones
class NotificationStats {
  final int total;
  final int unread;
  final int read;
  final Map<NotificationType, int> byType;
  final Map<NotificationPriority, int> byPriority;
  final DateTime? lastNotificationDate;
  final DateTime? oldestUnreadDate;

  const NotificationStats({
    required this.total,
    required this.unread,
    required this.read,
    required this.byType,
    required this.byPriority,
    this.lastNotificationDate,
    this.oldestUnreadDate,
  });

  double get unreadPercentage => total > 0 ? (unread / total) * 100 : 0;
  double get readPercentage => total > 0 ? (read / total) * 100 : 0;

  bool get hasUnread => unread > 0;
  bool get hasUrgent => byPriority[NotificationPriority.urgent] != null &&
      byPriority[NotificationPriority.urgent]! > 0;

  int getTypeCount(NotificationType type) => byType[type] ?? 0;
  int getPriorityCount(NotificationPriority priority) =>
      byPriority[priority] ?? 0;
}

/// Parámetros para crear notificación
class CreateNotificationParams {
  final NotificationType type;
  final String title;
  final String message;
  final NotificationPriority priority;
  final String? relatedId;
  final Map<String, dynamic>? actionData;

  const CreateNotificationParams({
    required this.type,
    required this.title,
    required this.message,
    this.priority = NotificationPriority.medium,
    this.relatedId,
    this.actionData,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'title': title,
    'message': message,
    'priority': priority.name,
    if (relatedId != null) 'relatedId': relatedId,
    if (actionData != null) 'actionData': actionData,
  };
}
