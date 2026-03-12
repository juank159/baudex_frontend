// lib/features/dashboard/data/repositories/notification_offline_repository.dart
import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../domain/entities/notification.dart';
import '../../../notifications/data/models/isar/isar_notification.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';

/// Implementación offline del repositorio de notificaciones usando ISAR
///
/// Este repositorio maneja todas las operaciones offline usando solo ISAR,
/// sin requerir conexión a internet. Es usado por el SyncService.
class NotificationOfflineRepository implements NotificationRepository {
  final IsarDatabase _database;

  NotificationOfflineRepository({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  // ==================== READ OPERATIONS ====================

  @override
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
  }) async {
    try {
      var query = _isar.isarNotifications.filter().deletedAtIsNull();

      // Aplicar filtros
      if (unreadOnly == true) {
        query = query.and().isReadEqualTo(false);
      }

      if (type != null) {
        final isarType = _mapNotificationType(type);
        query = query.and().typeEqualTo(isarType);
      }

      if (priority != null) {
        final isarPriority = _mapNotificationPriority(priority);
        query = query.and().priorityEqualTo(isarPriority);
      }

      if (startDate != null) {
        query = query.and().timestampGreaterThan(startDate);
      }

      if (endDate != null) {
        query = query.and().timestampLessThan(endDate);
      }

      // Obtener todos (limitación de ISAR: no se puede ordenar y paginar a la vez)
      List<IsarNotification> isarNotifications = await query.findAll();

      // Ordenar en memoria por timestamp DESC (más recientes primero)
      isarNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Calcular total
      final totalItems = isarNotifications.length;

      // Paginar en memoria
      final offset = (page - 1) * limit;
      final paginatedNotifications =
          isarNotifications.skip(offset).take(limit).toList();

      // Convertir a entidades
      final notifications =
          paginatedNotifications.map((isar) => isar.toEntity()).toList();

      // Metadata de paginación
      final totalPages = (totalItems / limit).ceil();
      final meta = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      );

      return Right(PaginatedResult(data: notifications, meta: meta));
    } catch (e) {
      return Left(
        CacheFailure('Error loading notifications: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Notification>> getNotificationById(String id) async {
    try {
      final isarNotification = await _isar.isarNotifications
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarNotification == null) {
        return Left(CacheFailure('Notification not found'));
      }

      return Right(isarNotification.toEntity());
    } catch (e) {
      return Left(
        CacheFailure('Error loading notification: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> searchNotifications(
    String searchTerm, {
    int limit = 10,
  }) async {
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

      // Ordenar por timestamp DESC
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Limitar resultados
      final limited = filtered.take(limit).toList();
      final notifications = limited.map((isar) => isar.toEntity()).toList();

      return Right(notifications);
    } catch (e) {
      return Left(
        CacheFailure('Error searching notifications: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final count = await _isar.isarNotifications
          .filter()
          .isReadEqualTo(false)
          .and()
          .deletedAtIsNull()
          .count();

      return Right(count);
    } catch (e) {
      return Left(
        CacheFailure('Error getting unread count: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> getUnreadNotifications({
    int limit = 20,
  }) async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .isReadEqualTo(false)
          .and()
          .deletedAtIsNull()
          .sortByTimestampDesc()
          .limit(limit)
          .findAll();

      final notifications =
          isarNotifications.map((isar) => isar.toEntity()).toList();

      return Right(notifications);
    } catch (e) {
      return Left(
        CacheFailure('Error getting unread notifications: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> getNotificationsByType(
    NotificationType type, {
    int limit = 20,
  }) async {
    try {
      final isarType = _mapNotificationType(type);
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .typeEqualTo(isarType)
          .and()
          .deletedAtIsNull()
          .sortByTimestampDesc()
          .limit(limit)
          .findAll();

      final notifications =
          isarNotifications.map((isar) => isar.toEntity()).toList();

      return Right(notifications);
    } catch (e) {
      return Left(
        CacheFailure('Error getting notifications by type: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> getNotificationsByPriority(
    NotificationPriority priority, {
    int limit = 20,
  }) async {
    try {
      final isarPriority = _mapNotificationPriority(priority);
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .priorityEqualTo(isarPriority)
          .and()
          .deletedAtIsNull()
          .sortByTimestampDesc()
          .limit(limit)
          .findAll();

      final notifications =
          isarNotifications.map((isar) => isar.toEntity()).toList();

      return Right(notifications);
    } catch (e) {
      return Left(
        CacheFailure(
          'Error getting notifications by priority: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, NotificationStats>> getStatistics() async {
    try {
      final all = await _isar.isarNotifications
          .filter()
          .deletedAtIsNull()
          .findAll();

      final total = all.length;
      final unread = all.where((n) => !n.isRead).length;
      final read = all.where((n) => n.isRead).length;

      // Calcular por tipo
      final Map<NotificationType, int> byType = {};
      for (final notification in all) {
        final type = _mapIsarNotificationType(notification.type);
        byType[type] = (byType[type] ?? 0) + 1;
      }

      // Calcular por prioridad
      final Map<NotificationPriority, int> byPriority = {};
      for (final notification in all) {
        final priority = _mapIsarNotificationPriority(notification.priority);
        byPriority[priority] = (byPriority[priority] ?? 0) + 1;
      }

      // Última notificación
      DateTime? lastNotificationDate;
      if (all.isNotEmpty) {
        all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        lastNotificationDate = all.first.timestamp;
      }

      // Notificación no leída más antigua
      final unreadList = all.where((n) => !n.isRead).toList();
      DateTime? oldestUnreadDate;
      if (unreadList.isNotEmpty) {
        unreadList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        oldestUnreadDate = unreadList.first.timestamp;
      }

      final stats = NotificationStats(
        total: total,
        unread: unread,
        read: read,
        byType: byType,
        byPriority: byPriority,
        lastNotificationDate: lastNotificationDate,
        oldestUnreadDate: oldestUnreadDate,
      );

      return Right(stats);
    } catch (e) {
      return Left(
        CacheFailure('Error getting statistics: ${e.toString()}'),
      );
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, Notification>> createNotification({
    required NotificationType type,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.medium,
    String? relatedId,
    Map<String, dynamic>? actionData,
  }) async {
    // Las notificaciones se crean solo en el servidor
    return Left(
      ServerFailure('Notifications can only be created online'),
    );
  }

  @override
  Future<Either<Failure, Notification>> markAsRead(String id) async {
    try {
      final isarNotification = await _isar.isarNotifications
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarNotification == null) {
        return Left(CacheFailure('Notification not found'));
      }

      await _isar.writeTxn(() async {
        isarNotification.markAsRead();
        await _isar.isarNotifications.put(isarNotification);
      });

      return Right(isarNotification.toEntity());
    } catch (e) {
      return Left(
        CacheFailure('Error marking as read: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Notification>> markAsUnread(String id) async {
    try {
      final isarNotification = await _isar.isarNotifications
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarNotification == null) {
        return Left(CacheFailure('Notification not found'));
      }

      await _isar.writeTxn(() async {
        isarNotification.markAsUnread();
        await _isar.isarNotifications.put(isarNotification);
      });

      return Right(isarNotification.toEntity());
    } catch (e) {
      return Left(
        CacheFailure('Error marking as unread: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllAsRead() async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .isReadEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      await _isar.writeTxn(() async {
        for (final notification in isarNotifications) {
          notification.markAsRead();
          await _isar.isarNotifications.put(notification);
        }
      });

      return const Right(unit);
    } catch (e) {
      return Left(
        CacheFailure('Error marking all as read: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> markTypeAsRead(NotificationType type) async {
    try {
      final isarType = _mapNotificationType(type);
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .typeEqualTo(isarType)
          .and()
          .isReadEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      await _isar.writeTxn(() async {
        for (final notification in isarNotifications) {
          notification.markAsRead();
          await _isar.isarNotifications.put(notification);
        }
      });

      return const Right(unit);
    } catch (e) {
      return Left(
        CacheFailure('Error marking type as read: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteNotification(String id) async {
    try {
      final isarNotification = await _isar.isarNotifications
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarNotification == null) {
        return Left(CacheFailure('Notification not found'));
      }

      await _isar.writeTxn(() async {
        isarNotification.softDelete();
        await _isar.isarNotifications.put(isarNotification);
      });

      return const Right(unit);
    } catch (e) {
      return Left(
        CacheFailure('Error deleting notification: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAllRead() async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .isReadEqualTo(true)
          .and()
          .deletedAtIsNull()
          .findAll();

      await _isar.writeTxn(() async {
        for (final notification in isarNotifications) {
          notification.softDelete();
          await _isar.isarNotifications.put(notification);
        }
      });

      return const Right(unit);
    } catch (e) {
      return Left(
        CacheFailure('Error deleting read notifications: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteOlderThan(DateTime date) async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .timestampLessThan(date)
          .and()
          .deletedAtIsNull()
          .findAll();

      await _isar.writeTxn(() async {
        for (final notification in isarNotifications) {
          notification.softDelete();
          await _isar.isarNotifications.put(notification);
        }
      });

      return const Right(unit);
    } catch (e) {
      return Left(
        CacheFailure('Error deleting old notifications: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Notification>> restoreNotification(String id) async {
    try {
      final isarNotification = await _isar.isarNotifications
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarNotification == null) {
        return Left(CacheFailure('Notification not found'));
      }

      await _isar.writeTxn(() async {
        isarNotification.restore();
        await _isar.isarNotifications.put(isarNotification);
      });

      return Right(isarNotification.toEntity());
    } catch (e) {
      return Left(
        CacheFailure('Error restoring notification: ${e.toString()}'),
      );
    }
  }

  // ==================== CACHE OPERATIONS ====================

  @override
  Future<Either<Failure, List<Notification>>> getCachedNotifications() async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .deletedAtIsNull()
          .sortByTimestampDesc()
          .findAll();

      final notifications =
          isarNotifications.map((isar) => isar.toEntity()).toList();

      return Right(notifications);
    } catch (e) {
      return Left(
        CacheFailure('Error getting cached notifications: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> clearNotificationCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarNotifications.clear();
      });

      return const Right(unit);
    } catch (e) {
      return Left(
        CacheFailure('Error clearing cache: ${e.toString()}'),
      );
    }
  }

  // ==================== VALIDATION OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> hasUnreadNotifications() async {
    try {
      final count = await _isar.isarNotifications
          .filter()
          .isReadEqualTo(false)
          .and()
          .deletedAtIsNull()
          .count();

      return Right(count > 0);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, bool>> existsById(String id) async {
    try {
      final notification = await _isar.isarNotifications
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      return Right(notification != null);
    } catch (e) {
      return const Right(false);
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Obtener entidades pendientes de sincronizar
  Future<List<Notification>> getUnsyncedEntities() async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      return isarNotifications.map((isar) => isar.toEntity()).toList();
    } catch (e) {
      print('❌ Error getting unsynced notifications: $e');
      return [];
    }
  }

  /// Obtener entidades eliminadas pendientes de sincronizar
  Future<List<Notification>> getUnsyncedDeleted() async {
    try {
      final isarNotifications = await _isar.isarNotifications
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNotNull()
          .findAll();

      return isarNotifications.map((isar) => isar.toEntity()).toList();
    } catch (e) {
      print('❌ Error getting unsynced deleted notifications: $e');
      return [];
    }
  }

  /// Marcar notificaciones como sincronizadas
  Future<void> markAsSynced(List<String> ids) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in ids) {
          final notification = await _isar.isarNotifications
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (notification != null) {
            notification.markAsSynced();
            await _isar.isarNotifications.put(notification);
          }
        }
      });

      print('✅ ${ids.length} notifications marked as synced');
    } catch (e) {
      print('❌ Error marking notifications as synced: $e');
    }
  }

  /// Marcar notificación como no sincronizada
  Future<void> markAsUnsynced(String id) async {
    try {
      await _isar.writeTxn(() async {
        final notification = await _isar.isarNotifications
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (notification != null) {
          notification.markAsUnsynced();
          await _isar.isarNotifications.put(notification);
        }
      });
    } catch (e) {
      print('❌ Error marking notification as unsynced: $e');
    }
  }

  /// Guardar notificación localmente
  Future<void> saveLocally(Notification entity) async {
    try {
      await _isar.writeTxn(() async {
        final isarNotification = IsarNotification.fromEntity(entity);
        await _isar.isarNotifications.put(isarNotification);
      });

      print('✅ Notification saved locally: ${entity.title}');
    } catch (e) {
      print('❌ Error saving notification locally: $e');
    }
  }

  /// Guardar múltiples notificaciones localmente
  Future<void> saveAllLocally(List<Notification> entities) async {
    try {
      await _isar.writeTxn(() async {
        for (final entity in entities) {
          final isarNotification = IsarNotification.fromEntity(entity);
          await _isar.isarNotifications.put(isarNotification);
        }
      });

      print('✅ ${entities.length} notifications saved locally');
    } catch (e) {
      print('❌ Error saving notifications locally: $e');
    }
  }

  /// Eliminar notificación localmente
  Future<void> deleteLocally(String id) async {
    try {
      await _isar.writeTxn(() async {
        final notification = await _isar.isarNotifications
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (notification != null) {
          await _isar.isarNotifications.delete(notification.id);
        }
      });

      print('✅ Notification deleted locally: $id');
    } catch (e) {
      print('❌ Error deleting notification locally: $e');
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
}
