// lib/features/notifications/data/datasources/notification_local_datasource_isar.dart
import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../../dashboard/domain/entities/notification.dart';
import '../models/notification_model.dart';
import '../models/isar/isar_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_local_datasource.dart';

/// Implementación ISAR del datasource local de notificaciones
///
/// Almacenamiento persistente offline-first usando ISAR
class NotificationLocalDataSourceIsar implements NotificationLocalDataSource {
  final IsarDatabase _database;

  NotificationLocalDataSourceIsar(this._database);

  Isar get _isar => _database.database;

  // ==================== CACHE OPERATIONS ====================

  @override
  Future<void> cacheNotifications(
    List<NotificationModel> notifications,
  ) async {
    try {
      await _isar.writeTxn(() async {
        for (final notification in notifications) {
          IsarNotification? existing = await _isar.isarNotifications
              .filter()
              .serverIdEqualTo(notification.id)
              .findFirst();

          IsarNotification isarNotification;

          if (existing != null) {
            // Actualizar existente
            isarNotification = existing
              ..serverId = notification.id
              ..type = _mapNotificationType(notification.type)
              ..title = notification.title
              ..message = notification.message
              ..timestamp = notification.timestamp
              ..isRead = notification.isRead
              ..priority = _mapNotificationPriority(notification.priority)
              ..relatedId = notification.relatedId
              ..actionDataJson = notification.actionData != null
                  ? jsonEncode(notification.actionData)
                  : null
              ..updatedAt = DateTime.now()
              ..isSynced = true
              ..lastSyncAt = DateTime.now();
          } else {
            // Crear nuevo
            isarNotification = IsarNotification()
              ..serverId = notification.id
              ..type = _mapNotificationType(notification.type)
              ..title = notification.title
              ..message = notification.message
              ..timestamp = notification.timestamp
              ..isRead = notification.isRead
              ..priority = _mapNotificationPriority(notification.priority)
              ..relatedId = notification.relatedId
              ..actionDataJson = notification.actionData != null
                  ? jsonEncode(notification.actionData)
                  : null
              ..createdAt = notification.timestamp
              ..updatedAt = DateTime.now()
              ..isSynced = true
              ..lastSyncAt = DateTime.now()
              ..version = 0;
          }

          await _isar.isarNotifications.put(isarNotification);
        }
      });

      print('🔔 ISAR: ${notifications.length} notificaciones cacheadas');
    } catch (e) {
      print('❌ Error al cachear notificaciones en ISAR: $e');
      throw CacheException('Error al cachear notificaciones: $e');
    }
  }

  @override
  Future<void> cacheNotification(NotificationModel notification) async {
    try {
      await _isar.writeTxn(() async {
        IsarNotification? existing = await _isar.isarNotifications
            .filter()
            .serverIdEqualTo(notification.id)
            .findFirst();

        IsarNotification isarNotification;

        if (existing != null) {
          // Actualizar existente
          isarNotification = existing
            ..serverId = notification.id
            ..type = _mapNotificationType(notification.type)
            ..title = notification.title
            ..message = notification.message
            ..timestamp = notification.timestamp
            ..isRead = notification.isRead
            ..priority = _mapNotificationPriority(notification.priority)
            ..relatedId = notification.relatedId
            ..actionDataJson = notification.actionData != null
                ? jsonEncode(notification.actionData)
                : null
            ..updatedAt = DateTime.now()
            ..isSynced = true
            ..lastSyncAt = DateTime.now();
        } else {
          // Crear nuevo
          isarNotification = IsarNotification()
            ..serverId = notification.id
            ..type = _mapNotificationType(notification.type)
            ..title = notification.title
            ..message = notification.message
            ..timestamp = notification.timestamp
            ..isRead = notification.isRead
            ..priority = _mapNotificationPriority(notification.priority)
            ..relatedId = notification.relatedId
            ..actionDataJson = notification.actionData != null
                ? jsonEncode(notification.actionData)
                : null
            ..createdAt = notification.timestamp
            ..updatedAt = DateTime.now()
            ..isSynced = true
            ..lastSyncAt = DateTime.now()
            ..version = 0;
        }

        await _isar.isarNotifications.put(isarNotification);
      });

      print('🔔 ISAR: Notificación ${notification.title} cacheada');
    } catch (e) {
      print('❌ Error al cachear notificación en ISAR: $e');
      throw CacheException('Error al cachear notificación: $e');
    }
  }

  @override
  Future<void> cacheNotificationForSync(Notification notification) async {
    try {
      await _isar.writeTxn(() async {
        final isarNotification = IsarNotification()
          ..serverId = notification.id
          ..type = _mapNotificationType(notification.type)
          ..title = notification.title
          ..message = notification.message
          ..timestamp = notification.timestamp
          ..isRead = notification.isRead
          ..priority = _mapNotificationPriority(notification.priority)
          ..relatedId = notification.relatedId
          ..actionDataJson = notification.actionData != null
              ? jsonEncode(notification.actionData)
              : null
          ..createdAt = notification.timestamp
          ..updatedAt = DateTime.now()
          ..isSynced = false // Creada localmente, necesita sync
          ..version = 0;

        await _isar.isarNotifications.put(isarNotification);
      });

      print('✅ ISAR: Notificación guardada para sync: ${notification.title}');
    } catch (e) {
      print('❌ Error al guardar notificación para sync: $e');
      throw CacheException('Error al guardar notificación para sync: $e');
    }
  }

  // ==================== GET OPERATIONS ====================

  @override
  Future<List<NotificationModel>> getCachedNotifications() async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .deletedAtIsNull()
          .sortByTimestampDesc()
          .findAll();

      if (isarNotifications.isEmpty) {
        print('🔔 ISAR: No hay notificaciones en cache');
        return []; // Retornar lista vacía en lugar de lanzar excepción
      }

      final notifications = isarNotifications
          .map((isar) => _convertToNotificationModel(isar))
          .toList();

      print('🔔 ISAR: ${notifications.length} notificaciones obtenidas');
      return notifications;
    } catch (e) {
      print('❌ Error al obtener notificaciones de ISAR: $e');
      return []; // Retornar lista vacía en caso de error
    }
  }

  @override
  Future<NotificationModel?> getCachedNotification(String id) async {
    try {
      final isarNotification = await _isar.isarNotifications
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarNotification == null) {
        print('🔔 ISAR: Notificación con ID $id no encontrada');
        return null;
      }

      return _convertToNotificationModel(isarNotification);
    } catch (e) {
      print('❌ Error al obtener notificación de ISAR: $e');
      throw CacheException('Error al obtener notificación: $e');
    }
  }

  @override
  Future<List<NotificationModel>> searchCachedNotifications(
    String searchTerm,
  ) async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .deletedAtIsNull()
          .findAll();

      final term = searchTerm.toLowerCase();
      final filtered = isarNotifications.where((notification) {
        return notification.title.toLowerCase().contains(term) ||
            notification.message.toLowerCase().contains(term);
      }).toList();

      final notifications = filtered
          .map((isar) => _convertToNotificationModel(isar))
          .toList();

      print('🔔 ISAR: ${notifications.length} notificaciones encontradas');
      return notifications;
    } catch (e) {
      print('❌ Error al buscar notificaciones: $e');
      return [];
    }
  }

  @override
  Future<List<NotificationModel>> getCachedUnreadNotifications() async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .isReadEqualTo(false)
          .and()
          .deletedAtIsNull()
          .sortByTimestampDesc()
          .findAll();

      final notifications = isarNotifications
          .map((isar) => _convertToNotificationModel(isar))
          .toList();

      print('🔔 ISAR: ${notifications.length} notificaciones no leídas');
      return notifications;
    } catch (e) {
      print('❌ Error al obtener notificaciones no leídas: $e');
      return [];
    }
  }

  @override
  Future<int> getCachedUnreadCount() async {
    try {
      final count = await _isar.isarNotifications
          .filter()
          .isReadEqualTo(false)
          .and()
          .deletedAtIsNull()
          .count();

      return count;
    } catch (e) {
      print('❌ Error al obtener contador de no leídas: $e');
      return 0;
    }
  }

  @override
  Future<List<NotificationModel>> getCachedNotificationsByType(
    NotificationType type,
  ) async {
    try {
      final isarType = _mapNotificationType(type);
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .typeEqualTo(isarType)
          .and()
          .deletedAtIsNull()
          .sortByTimestampDesc()
          .findAll();

      final notifications = isarNotifications
          .map((isar) => _convertToNotificationModel(isar))
          .toList();

      return notifications;
    } catch (e) {
      print('❌ Error al obtener notificaciones por tipo: $e');
      return [];
    }
  }

  @override
  Future<List<NotificationModel>> getCachedNotificationsByPriority(
    NotificationPriority priority,
  ) async {
    try {
      final isarPriority = _mapNotificationPriority(priority);
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .priorityEqualTo(isarPriority)
          .and()
          .deletedAtIsNull()
          .sortByTimestampDesc()
          .findAll();

      final notifications = isarNotifications
          .map((isar) => _convertToNotificationModel(isar))
          .toList();

      return notifications;
    } catch (e) {
      print('❌ Error al obtener notificaciones por prioridad: $e');
      return [];
    }
  }

  // ==================== STATS OPERATIONS ====================

  @override
  Future<void> cacheNotificationStats(NotificationStats stats) async {
    try {
      await _isar.writeTxn(() async {
        // Usar clave especial para estadísticas
        final statsNotification = IsarNotification()
          ..serverId = 'STATS_CACHE'
          ..type = IsarNotificationType.system
          ..title = 'Notification Statistics Cache'
          ..message = 'Statistics cache'
          ..timestamp = DateTime.now()
          ..isRead = true
          ..priority = IsarNotificationPriority.low
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..isSynced = true
          ..lastSyncAt = DateTime.now()
          ..version = 0
          // Serializar estadísticas como JSON
          ..actionDataJson = jsonEncode({
            'total': stats.total,
            'unread': stats.unread,
            'read': stats.read,
            'byType': stats.byType
                .map((key, value) => MapEntry(key.name, value)),
            'byPriority': stats.byPriority
                .map((key, value) => MapEntry(key.name, value)),
            'lastNotificationDate':
                stats.lastNotificationDate?.toIso8601String(),
            'oldestUnreadDate': stats.oldestUnreadDate?.toIso8601String(),
          });

        await _isar.isarNotifications.put(statsNotification);
      });

      print('📊 ISAR: Estadísticas de notificaciones cacheadas');
    } catch (e) {
      print('❌ Error al cachear estadísticas: $e');
      throw CacheException('Error al cachear estadísticas: $e');
    }
  }

  @override
  Future<NotificationStats?> getCachedNotificationStats() async {
    try {
      final statsCache = await _isar.isarNotifications
          .filter()
          .serverIdEqualTo('STATS_CACHE')
          .findFirst();

      if (statsCache == null || statsCache.actionDataJson == null) {
        print('📊 ISAR: No hay estadísticas en cache');
        return null;
      }

      final statsJson = statsCache.actionDataJson!;
      try {
        final jsonMap = json.decode(statsJson) as Map<String, dynamic>;
        return _parseStatistics(jsonMap);
      } catch (parseError) {
        print('❌ Error al parsear estadísticas: $parseError');
        return null;
      }
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return null;
    }
  }

  // ==================== DELETE OPERATIONS ====================

  @override
  Future<void> removeCachedNotification(String id) async {
    try {
      await _isar.writeTxn(() async {
        final notification = await _isar.isarNotifications
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (notification == null) {
          throw CacheException('Notificación no encontrada: $id');
        }

        // Soft delete
        notification.softDelete();
        await _isar.isarNotifications.put(notification);
      });

      print('🗑️ ISAR: Notificación $id eliminada (soft delete)');
    } catch (e) {
      print('❌ Error al eliminar notificación: $e');
      throw CacheException('Error al eliminar notificación: $e');
    }
  }

  @override
  Future<void> clearNotificationCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarNotifications.clear();
      });

      print('🧹 ISAR: Cache de notificaciones limpiado');
    } catch (e) {
      print('❌ Error al limpiar cache: $e');
      throw CacheException('Error al limpiar cache: $e');
    }
  }

  // ==================== SYNC OPERATIONS ====================

  @override
  Future<List<Notification>> getUnsyncedNotifications() async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      final notifications =
          isarNotifications.map((isar) => isar.toEntity()).toList();

      print('🔄 ISAR: ${notifications.length} notificaciones sin sincronizar');
      return notifications;
    } catch (e) {
      print('❌ Error al obtener notificaciones sin sincronizar: $e');
      throw CacheException('Error al obtener sin sincronizar: $e');
    }
  }

  @override
  Future<void> markNotificationAsSynced(String tempId, String serverId) async {
    try {
      await _isar.writeTxn(() async {
        final notification = await _isar.isarNotifications
            .filter()
            .serverIdEqualTo(tempId)
            .findFirst();

        if (notification != null) {
          notification
            ..serverId = serverId
            ..isSynced = true
            ..lastSyncAt = DateTime.now();
          await _isar.isarNotifications.put(notification);
        }
      });

      print('✅ ISAR: Notificación marcada como sincronizada: $tempId → $serverId');
    } catch (e) {
      print('❌ Error al marcar como sincronizada: $e');
      throw CacheException('Error al marcar como sincronizada: $e');
    }
  }

  // ==================== VALIDATION ====================

  @override
  Future<bool> existsById(String id) async {
    try {
      final notification = await _isar.isarNotifications
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      return notification != null;
    } catch (e) {
      print('❌ Error al verificar existencia: $e');
      return false;
    }
  }

  // ==================== VERSION ACCESS ====================

  @override
  Future<IsarNotification?> getIsarNotification(String id) async {
    try {
      return await _isar.isarNotifications
          .filter()
          .serverIdEqualTo(id)
          .findFirst();
    } catch (e) {
      print('⚠️ Error al obtener IsarNotification: $e');
      return null;
    }
  }

  // ==================== MAPPERS ====================

  /// Convertir NotificationType a IsarNotificationType
  IsarNotificationType _mapNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return IsarNotificationType.system;
      case NotificationType.payment:
        return IsarNotificationType.payment;
      case NotificationType.invoice:
        return IsarNotificationType.invoice;
      case NotificationType.lowStock:
        return IsarNotificationType.lowStock;
      case NotificationType.expense:
        return IsarNotificationType.expense;
      case NotificationType.sale:
        return IsarNotificationType.sale;
      case NotificationType.user:
        return IsarNotificationType.user;
      case NotificationType.reminder:
        return IsarNotificationType.reminder;
    }
  }

  /// Convertir IsarNotificationType a NotificationType
  NotificationType _mapIsarNotificationType(IsarNotificationType type) {
    switch (type) {
      case IsarNotificationType.system:
        return NotificationType.system;
      case IsarNotificationType.payment:
        return NotificationType.payment;
      case IsarNotificationType.invoice:
        return NotificationType.invoice;
      case IsarNotificationType.lowStock:
        return NotificationType.lowStock;
      case IsarNotificationType.expense:
        return NotificationType.expense;
      case IsarNotificationType.sale:
        return NotificationType.sale;
      case IsarNotificationType.user:
        return NotificationType.user;
      case IsarNotificationType.reminder:
        return NotificationType.reminder;
    }
  }

  /// Convertir NotificationPriority a IsarNotificationPriority
  IsarNotificationPriority _mapNotificationPriority(
    NotificationPriority priority,
  ) {
    switch (priority) {
      case NotificationPriority.low:
        return IsarNotificationPriority.low;
      case NotificationPriority.medium:
        return IsarNotificationPriority.medium;
      case NotificationPriority.high:
        return IsarNotificationPriority.high;
      case NotificationPriority.urgent:
        return IsarNotificationPriority.urgent;
    }
  }

  /// Convertir IsarNotificationPriority a NotificationPriority
  NotificationPriority _mapIsarNotificationPriority(
    IsarNotificationPriority priority,
  ) {
    switch (priority) {
      case IsarNotificationPriority.low:
        return NotificationPriority.low;
      case IsarNotificationPriority.medium:
        return NotificationPriority.medium;
      case IsarNotificationPriority.high:
        return NotificationPriority.high;
      case IsarNotificationPriority.urgent:
        return NotificationPriority.urgent;
    }
  }

  // ==================== CONVERTERS ====================

  /// Convertir IsarNotification a NotificationModel
  NotificationModel _convertToNotificationModel(IsarNotification isar) {
    final notification = isar.toEntity();
    return NotificationModel.fromEntity(notification);
  }

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
}
