// lib/features/notifications/data/datasources/notification_local_datasource.dart
import '../../../dashboard/domain/entities/notification.dart';
import '../models/notification_model.dart';
import '../models/isar/isar_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Contrato para el datasource local de notificaciones
abstract class NotificationLocalDataSource {
  /// Cachear múltiples notificaciones
  Future<void> cacheNotifications(List<NotificationModel> notifications);

  /// Cachear una notificación individual
  Future<void> cacheNotification(NotificationModel notification);

  /// Cachear notificación para sincronización (creada offline)
  Future<void> cacheNotificationForSync(Notification notification);

  /// Obtener todas las notificaciones cacheadas
  Future<List<NotificationModel>> getCachedNotifications();

  /// Obtener notificación por ID
  Future<NotificationModel?> getCachedNotification(String id);

  /// Buscar notificaciones en cache
  Future<List<NotificationModel>> searchCachedNotifications(String searchTerm);

  /// Obtener notificaciones no leídas del cache
  Future<List<NotificationModel>> getCachedUnreadNotifications();

  /// Obtener contador de notificaciones no leídas
  Future<int> getCachedUnreadCount();

  /// Cachear estadísticas de notificaciones
  Future<void> cacheNotificationStats(NotificationStats stats);

  /// Obtener estadísticas cacheadas
  Future<NotificationStats?> getCachedNotificationStats();

  /// Remover notificación del cache
  Future<void> removeCachedNotification(String id);

  /// Limpiar todo el cache de notificaciones
  Future<void> clearNotificationCache();

  /// Obtener notificaciones pendientes de sincronizar
  Future<List<Notification>> getUnsyncedNotifications();

  /// Marcar notificación como sincronizada
  Future<void> markNotificationAsSynced(String tempId, String serverId);

  /// Verificar si existe una notificación
  Future<bool> existsById(String id);

  /// Obtener notificaciones por tipo
  Future<List<NotificationModel>> getCachedNotificationsByType(
    NotificationType type,
  );

  /// Obtener notificaciones por prioridad
  Future<List<NotificationModel>> getCachedNotificationsByPriority(
    NotificationPriority priority,
  );

  /// Obtener IsarNotification directamente para acceso a campos de versionamiento
  Future<IsarNotification?> getIsarNotification(String id);
}
