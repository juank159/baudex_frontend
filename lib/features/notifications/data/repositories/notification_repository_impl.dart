// lib/features/notifications/data/repositories/notification_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../dashboard/domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../datasources/notification_local_datasource.dart';
import '../models/notification_model.dart';
import '../models/notification_query_model.dart';
import '../models/create_notification_request_model.dart';

/// Implementación del repositorio de notificaciones
///
/// Esta clase maneja la lógica de datos combinando fuentes remotas y locales,
/// implementando estrategias de cache y manejo de errores robusto con patrón offline-first.
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

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
    AppLogger.d('NotificationRepository: getNotifications llamado');
    AppLogger.d('Params: page=$page, limit=$limit, unreadOnly=$unreadOnly');

    try {
      final isConnected = await networkInfo.isConnected;
      AppLogger.d('NotificationRepository: isConnected = $isConnected');

      if (isConnected) {
        AppLogger.i('NotificationRepository: HAY CONEXIÓN - Llamando backend...');
        try {
          final query = NotificationQueryModel(
            page: page,
            limit: limit,
            unreadOnly: unreadOnly,
            type: type,
            priority: priority,
            startDate: startDate,
            endDate: endDate,
            sortBy: sortBy,
            sortOrder: sortOrder,
          );

          final response = await remoteDataSource.getNotifications(query);
          AppLogger.d('Respuesta recibida: ${response.data.length} notificaciones');

          // Cachear si es primera página sin filtros específicos
          // IMPORTANTE: Preservar el estado isRead de notificaciones dinámicas
          if (_shouldCacheResult(page, unreadOnly, type, priority)) {
            try {
              final notificationsToCache = await _preserveDynamicNotificationReadState(response.data);
              await localDataSource.cacheNotifications(notificationsToCache);
            } catch (e) {
              AppLogger.w('Error al cachear notificaciones: $e');
            }
          }

          // Preservar estado isRead también en el resultado retornado
          final notificationsWithPreservedState = await _preserveDynamicNotificationReadState(response.data);
          final paginatedResult = response.toPaginatedResult();
          return Right(
            PaginatedResult<Notification>(
              data: notificationsWithPreservedState
                  .map((model) => model.toEntity())
                  .toList(),
              meta: paginatedResult.meta,
            ),
          );
        } on ServerException catch (e) {
          AppLogger.w('ServerException: ${e.message} - Usando cache...');
          return _getNotificationsFromCache(
            page: page,
            limit: limit,
            unreadOnly: unreadOnly,
            type: type,
            priority: priority,
          );
        } catch (e) {
          AppLogger.e('Error en rama ONLINE: $e - Usando cache...');
          return _getNotificationsFromCache(
            page: page,
            limit: limit,
            unreadOnly: unreadOnly,
            type: type,
            priority: priority,
          );
        }
      } else {
        AppLogger.w('NotificationRepository: SIN CONEXIÓN - Usando cache');
        return _getNotificationsFromCache(
          page: page,
          limit: limit,
          unreadOnly: unreadOnly,
          type: type,
          priority: priority,
        );
      }
    } catch (e) {
      AppLogger.e('Error general en getNotifications: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, Notification>> getNotificationById(String id) async {
    AppLogger.d('NotificationRepository: getNotificationById($id)');

    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final notification = await remoteDataSource.getNotificationById(id);

          // Cachear notificación individual
          try {
            await localDataSource.cacheNotification(notification);
          } catch (e) {
            AppLogger.w('Error al cachear notificación: $e');
          }

          return Right(notification.toEntity());
        } on ServerException catch (e) {
          if (e.statusCode == 404) {
            return Left(ServerFailure('Notificación no encontrada'));
          }
          AppLogger.w('ServerException: ${e.message} - Buscando en cache...');
          return _getNotificationFromCache(id);
        } catch (e) {
          AppLogger.e('Error en rama ONLINE: $e');
          return _getNotificationFromCache(id);
        }
      } else {
        return _getNotificationFromCache(id);
      }
    } catch (e) {
      AppLogger.e('Error general en getNotificationById: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> searchNotifications(
    String searchTerm, {
    int limit = 10,
  }) async {
    AppLogger.d('NotificationRepository: searchNotifications($searchTerm)');

    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final notifications =
              await remoteDataSource.searchNotifications(searchTerm, limit);

          return Right(
            notifications.map((model) => model.toEntity()).toList(),
          );
        } on ServerException catch (e) {
          AppLogger.w('ServerException: ${e.message} - Buscando en cache...');
          return _searchNotificationsInCache(searchTerm);
        } catch (e) {
          AppLogger.e('Error en rama ONLINE: $e');
          return _searchNotificationsInCache(searchTerm);
        }
      } else {
        return _searchNotificationsInCache(searchTerm);
      }
    } catch (e) {
      AppLogger.e('Error general en searchNotifications: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    AppLogger.d('NotificationRepository: getUnreadCount');

    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final count = await remoteDataSource.getUnreadCount();
          return Right(count);
        } on ServerException catch (e) {
          AppLogger.w('ServerException: ${e.message} - Usando cache...');
          return _getUnreadCountFromCache();
        } catch (e) {
          AppLogger.e('Error en rama ONLINE: $e');
          return _getUnreadCountFromCache();
        }
      } else {
        return _getUnreadCountFromCache();
      }
    } catch (e) {
      AppLogger.e('Error general en getUnreadCount: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> getUnreadNotifications({
    int limit = 20,
  }) async {
    AppLogger.d('NotificationRepository: getUnreadNotifications');

    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final notifications =
              await remoteDataSource.getUnreadNotifications(limit: limit);

          return Right(
            notifications.map((model) => model.toEntity()).toList(),
          );
        } on ServerException catch (e) {
          AppLogger.w('ServerException: ${e.message} - Usando cache...');
          return _getUnreadNotificationsFromCache();
        } catch (e) {
          AppLogger.e('Error en rama ONLINE: $e');
          return _getUnreadNotificationsFromCache();
        }
      } else {
        return _getUnreadNotificationsFromCache();
      }
    } catch (e) {
      AppLogger.e('Error general en getUnreadNotifications: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> getNotificationsByType(
    NotificationType type, {
    int limit = 20,
  }) async {
    AppLogger.d('NotificationRepository: getNotificationsByType($type)');

    try {
      final cached =
          await localDataSource.getCachedNotificationsByType(type);
      final notifications =
          cached.map((model) => model.toEntity()).toList();

      if (notifications.length >= limit) {
        return Right(notifications.take(limit).toList());
      }

      return Right(notifications);
    } catch (e) {
      AppLogger.e('Error en getNotificationsByType: $e');
      return Left(CacheFailure('Error al obtener notificaciones por tipo'));
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> getNotificationsByPriority(
    NotificationPriority priority, {
    int limit = 20,
  }) async {
    AppLogger.d('NotificationRepository: getNotificationsByPriority($priority)');

    try {
      final cached =
          await localDataSource.getCachedNotificationsByPriority(priority);
      final notifications =
          cached.map((model) => model.toEntity()).toList();

      if (notifications.length >= limit) {
        return Right(notifications.take(limit).toList());
      }

      return Right(notifications);
    } catch (e) {
      AppLogger.e('Error en getNotificationsByPriority: $e');
      return Left(
        CacheFailure('Error al obtener notificaciones por prioridad'),
      );
    }
  }

  @override
  Future<Either<Failure, NotificationStats>> getStatistics() async {
    AppLogger.d('NotificationRepository: getStatistics');

    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final stats = await remoteDataSource.getStatistics();

          // Cachear estadísticas
          try {
            await localDataSource.cacheNotificationStats(stats);
          } catch (e) {
            AppLogger.w('Error al cachear estadísticas: $e');
          }

          return Right(stats);
        } on ServerException catch (e) {
          AppLogger.w('ServerException: ${e.message} - Usando cache...');
          return _getStatisticsFromCache();
        } catch (e) {
          AppLogger.e('Error en rama ONLINE: $e');
          return _getStatisticsFromCache();
        }
      } else {
        return _getStatisticsFromCache();
      }
    } catch (e) {
      AppLogger.e('Error general en getStatistics: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
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
    AppLogger.d('NotificationRepository: createNotification');

    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final request = CreateNotificationRequestModel.fromParams(
            type: type,
            title: title,
            message: message,
            priority: priority,
            relatedId: relatedId,
            actionData: actionData,
          );

          final notification =
              await remoteDataSource.createNotification(request);

          // Cachear notificación creada
          try {
            await localDataSource.cacheNotification(notification);
          } catch (e) {
            AppLogger.w('Error al cachear notificación creada: $e');
          }

          return Right(notification.toEntity());
        } on ValidationException catch (e) {
          return Left(ValidationFailure(e.errors));
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        } catch (e) {
          AppLogger.e('Error al crear notificación: $e');
          return Left(UnknownFailure('Error al crear notificación'));
        }
      } else {
        // Sin conexión: crear localmente y agregar a cola de sync
        AppLogger.w('Sin conexión - Creando notificación offline');
        return Left(
          NetworkFailure(
            'Sin conexión. Las notificaciones se crean solo online.',
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error general en createNotification: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, Notification>> markAsRead(String id) async {
    AppLogger.d('NotificationRepository: markAsRead($id)');

    try {
      // Verificar si es una notificación dinámica (generada por el dashboard)
      // Estas notificaciones tienen prefijos como stock_, invoice_, payment_, etc.
      if (_isDynamicNotification(id)) {
        AppLogger.i('NotificationRepository: Notificación dinámica detectada - marcando localmente');
        return _markDynamicNotificationAsRead(id);
      }

      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final notification = await remoteDataSource.markAsRead(id);

          // Actualizar en cache
          try {
            await localDataSource.cacheNotification(notification);
          } catch (e) {
            AppLogger.w('Error al actualizar cache: $e');
          }

          return Right(notification.toEntity());
        } on ServerException catch (e) {
          if (e.statusCode == 404) {
            return Left(ServerFailure('Notificación no encontrada'));
          }
          AppLogger.w('ServerException: ${e.message}');
          // Agregar a cola de sincronización
          await _addMarkAsReadToSyncQueue(id);
          return Left(ServerFailure(e.message));
        } catch (e) {
          AppLogger.e('Error al marcar como leída: $e');
          await _addMarkAsReadToSyncQueue(id);
          return Left(UnknownFailure('Error al marcar como leída'));
        }
      } else {
        // Sin conexión: agregar a cola de sync
        AppLogger.w('Sin conexión - Agregando a cola de sync');
        await _addMarkAsReadToSyncQueue(id);
        return Left(NetworkFailure('Sin conexión'));
      }
    } catch (e) {
      AppLogger.e('Error general en markAsRead: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  /// Verificar si el ID corresponde a una notificación dinámica del dashboard
  /// Las notificaciones dinámicas tienen prefijos como: stock_, invoice_, payment_, etc.
  bool _isDynamicNotification(String id) {
    final dynamicPrefixes = [
      'stock_',
      'invoice_',
      'payment_',
      'customer_',
      'system_',
      'report_',
      'backup_',
      'security_',
    ];

    return dynamicPrefixes.any((prefix) => id.startsWith(prefix));
  }

  /// Marcar notificación dinámica como leída (localmente y en backend)
  /// Las notificaciones dinámicas se generan en tiempo real pero su estado
  /// de lectura se persiste en el backend para sincronización entre dispositivos
  Future<Either<Failure, Notification>> _markDynamicNotificationAsRead(String id) async {
    try {
      // Buscar la notificación en el cache local
      final cachedNotification = await localDataSource.getCachedNotification(id);

      if (cachedNotification != null) {
        // Crear versión marcada como leída
        final updatedNotification = cachedNotification.copyWith(isRead: true);

        // Guardar en cache local
        await localDataSource.cacheNotification(updatedNotification);

        // Sincronizar con el backend si hay conexión
        _syncDynamicNotificationStateToBackend(id, true);

        AppLogger.i('NotificationRepository: Notificación dinámica $id marcada como leída localmente');
        return Right(updatedNotification.toEntity());
      } else {
        // Si no está en cache, crear una notificación mínima marcada como leída
        // Esto permite que la UI se actualice correctamente
        AppLogger.w('NotificationRepository: Notificación dinámica $id no encontrada en cache');

        // Sincronizar con el backend de todas formas
        _syncDynamicNotificationStateToBackend(id, true);

        // Crear notificación mínima para retornar
        final minimalNotification = Notification(
          id: id,
          type: _getTypeFromDynamicId(id),
          title: 'Notificación',
          message: '',
          timestamp: DateTime.now(),
          isRead: true,
          priority: NotificationPriority.medium,
        );

        return Right(minimalNotification);
      }
    } catch (e) {
      AppLogger.e('Error al marcar notificación dinámica como leída: $e');
      return Left(CacheFailure('Error al marcar notificación como leída'));
    }
  }

  /// Sincronizar estado de notificación dinámica con el backend (fire and forget)
  /// Se ejecuta en segundo plano sin bloquear la UI
  void _syncDynamicNotificationStateToBackend(String id, bool isRead) async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await remoteDataSource.syncDynamicNotificationState(id, isRead);
        AppLogger.d('Estado de notificación dinámica $id sincronizado con backend', tag: 'NOTIFICATION');
      } else {
        AppLogger.d('Sin conexión - Estado de notificación dinámica $id pendiente de sincronización', tag: 'NOTIFICATION');
      }
    } catch (e) {
      // No fallar silenciosamente, solo log. El estado local ya está guardado.
      AppLogger.w('Error al sincronizar estado de notificación dinámica con backend: $e', tag: 'NOTIFICATION');
    }
  }

  /// Obtener el tipo de notificación basado en el prefijo del ID dinámico
  NotificationType _getTypeFromDynamicId(String id) {
    if (id.startsWith('stock_')) return NotificationType.lowStock;
    if (id.startsWith('invoice_')) return NotificationType.invoice;
    if (id.startsWith('payment_')) return NotificationType.payment;
    if (id.startsWith('customer_')) return NotificationType.user;
    if (id.startsWith('system_')) return NotificationType.system;
    if (id.startsWith('report_')) return NotificationType.sale;
    return NotificationType.system;
  }

  @override
  Future<Either<Failure, Notification>> markAsUnread(String id) async {
    AppLogger.d('NotificationRepository: markAsUnread($id)');

    try {
      // Verificar si es una notificación dinámica
      if (_isDynamicNotification(id)) {
        AppLogger.i('NotificationRepository: Notificación dinámica detectada - marcando como no leída localmente');
        return _markDynamicNotificationAsUnread(id);
      }

      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          final notification = await remoteDataSource.markAsUnread(id);

          // Actualizar en cache
          try {
            await localDataSource.cacheNotification(notification);
          } catch (e) {
            AppLogger.w('Error al actualizar cache: $e');
          }

          return Right(notification.toEntity());
        } on ServerException catch (e) {
          if (e.statusCode == 404) {
            return Left(ServerFailure('Notificación no encontrada'));
          }
          return Left(ServerFailure(e.message));
        } catch (e) {
          AppLogger.e('Error al marcar como no leída: $e');
          return Left(UnknownFailure('Error al marcar como no leída'));
        }
      } else {
        return Left(NetworkFailure('Sin conexión'));
      }
    } catch (e) {
      AppLogger.e('Error general in markAsUnread: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  /// Marcar notificación dinámica como no leída (localmente y en backend)
  Future<Either<Failure, Notification>> _markDynamicNotificationAsUnread(String id) async {
    try {
      final cachedNotification = await localDataSource.getCachedNotification(id);

      if (cachedNotification != null) {
        final updatedNotification = cachedNotification.copyWith(isRead: false);
        await localDataSource.cacheNotification(updatedNotification);

        // Sincronizar con el backend
        _syncDynamicNotificationStateToBackend(id, false);

        AppLogger.i('NotificationRepository: Notificación dinámica $id marcada como no leída localmente');
        return Right(updatedNotification.toEntity());
      } else {
        AppLogger.w('NotificationRepository: Notificación dinámica $id no encontrada en cache');
        return Left(CacheFailure('Notificación no encontrada en cache'));
      }
    } catch (e) {
      AppLogger.e('Error al marcar notificación dinámica como no leída: $e');
      return Left(CacheFailure('Error al marcar notificación como no leída'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllAsRead() async {
    AppLogger.d('NotificationRepository: markAllAsRead');

    try {
      final isConnected = await networkInfo.isConnected;

      // Primero, marcar todas las notificaciones dinámicas como leídas localmente
      await _markAllDynamicNotificationsAsRead();

      if (isConnected) {
        try {
          await remoteDataSource.markAllAsRead();
          return const Right(unit);
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        } catch (e) {
          AppLogger.e('Error al marcar todas como leídas: $e');
          return Left(UnknownFailure('Error al marcar todas como leídas'));
        }
      } else {
        return Left(NetworkFailure('Sin conexión'));
      }
    } catch (e) {
      AppLogger.e('Error general en markAllAsRead: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  /// Marcar todas las notificaciones dinámicas como leídas en el cache local y sincronizar con backend
  Future<void> _markAllDynamicNotificationsAsRead() async {
    try {
      final cachedNotifications = await localDataSource.getCachedNotifications();

      for (final notification in cachedNotifications) {
        if (_isDynamicNotification(notification.id) && !notification.isRead) {
          final updatedNotification = notification.copyWith(isRead: true);
          await localDataSource.cacheNotification(updatedNotification);
          AppLogger.d('Notificación dinámica ${notification.id} marcada como leída localmente', tag: 'NOTIFICATION');
        }
      }

      // Sincronizar con el backend (fire and forget)
      _syncAllDynamicNotificationsReadToBackend();

      AppLogger.i('Todas las notificaciones dinámicas marcadas como leídas', tag: 'NOTIFICATION');
    } catch (e) {
      AppLogger.w('Error al marcar notificaciones dinámicas como leídas: $e', tag: 'NOTIFICATION');
    }
  }

  /// Sincronizar todas las notificaciones dinámicas como leídas en el backend
  void _syncAllDynamicNotificationsReadToBackend() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        await remoteDataSource.markAllDynamicNotificationsAsRead();
        AppLogger.d('Todas las notificaciones dinámicas sincronizadas como leídas en backend', tag: 'NOTIFICATION');
      }
    } catch (e) {
      AppLogger.w('Error al sincronizar notificaciones dinámicas con backend: $e', tag: 'NOTIFICATION');
    }
  }

  @override
  Future<Either<Failure, Unit>> markTypeAsRead(NotificationType type) async {
    AppLogger.d('NotificationRepository: markTypeAsRead($type)');
    // Esta operación requiere backend, por ahora retornar not implemented
    return Left(
      ServerFailure('Operación no implementada en el backend'),
    );
  }

  @override
  Future<Either<Failure, Unit>> deleteNotification(String id) async {
    AppLogger.d('NotificationRepository: deleteNotification($id)');

    try {
      // Para notificaciones dinámicas, solo eliminar del cache local
      if (_isDynamicNotification(id)) {
        AppLogger.i('NotificationRepository: Eliminando notificación dinámica localmente');
        try {
          await localDataSource.removeCachedNotification(id);
          return const Right(unit);
        } catch (e) {
          AppLogger.e('Error al eliminar notificación dinámica del cache: $e');
          return Left(CacheFailure('Error al eliminar notificación'));
        }
      }

      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          await remoteDataSource.deleteNotification(id);

          // Remover del cache
          try {
            await localDataSource.removeCachedNotification(id);
          } catch (e) {
            AppLogger.w('Error al remover del cache: $e');
          }

          return const Right(unit);
        } on ServerException catch (e) {
          if (e.statusCode == 404) {
            return Left(ServerFailure('Notificación no encontrada'));
          }
          return Left(ServerFailure(e.message));
        } catch (e) {
          AppLogger.e('Error al eliminar notificación: $e');
          return Left(UnknownFailure('Error al eliminar notificación'));
        }
      } else {
        return Left(NetworkFailure('Sin conexión'));
      }
    } catch (e) {
      AppLogger.e('Error general en deleteNotification: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAllRead() async {
    AppLogger.d('NotificationRepository: deleteAllRead');

    try {
      final isConnected = await networkInfo.isConnected;

      if (isConnected) {
        try {
          await remoteDataSource.deleteAllRead();
          return const Right(unit);
        } on ServerException catch (e) {
          return Left(ServerFailure(e.message));
        } catch (e) {
          AppLogger.e('Error al eliminar leídas: $e');
          return Left(UnknownFailure('Error al eliminar leídas'));
        }
      } else {
        return Left(NetworkFailure('Sin conexión'));
      }
    } catch (e) {
      AppLogger.e('Error general en deleteAllRead: $e');
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteOlderThan(DateTime date) async {
    AppLogger.d('NotificationRepository: deleteOlderThan($date)');
    // Esta operación requiere backend, por ahora retornar not implemented
    return Left(
      ServerFailure('Operación no implementada en el backend'),
    );
  }

  @override
  Future<Either<Failure, Notification>> restoreNotification(String id) async {
    AppLogger.d('NotificationRepository: restoreNotification($id)');
    // Esta operación requiere backend, por ahora retornar not implemented
    return Left(
      ServerFailure('Operación no implementada en el backend'),
    );
  }

  // ==================== CACHE OPERATIONS ====================

  @override
  Future<Either<Failure, List<Notification>>> getCachedNotifications() async {
    AppLogger.d('NotificationRepository: getCachedNotifications');

    try {
      final cached = await localDataSource.getCachedNotifications();
      final notifications = cached.map((model) => model.toEntity()).toList();
      return Right(notifications);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      AppLogger.e('Error al obtener cache: $e');
      return Left(CacheFailure('Error al obtener notificaciones del cache'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearNotificationCache() async {
    AppLogger.d('NotificationRepository: clearNotificationCache');

    try {
      await localDataSource.clearNotificationCache();
      return const Right(unit);
    } catch (e) {
      AppLogger.e('Error al limpiar cache: $e');
      return Left(CacheFailure('Error al limpiar cache'));
    }
  }

  // ==================== VALIDATION OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> hasUnreadNotifications() async {
    AppLogger.d('NotificationRepository: hasUnreadNotifications');

    try {
      final count = await localDataSource.getCachedUnreadCount();
      return Right(count > 0);
    } catch (e) {
      AppLogger.e('Error en hasUnreadNotifications: $e');
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, bool>> existsById(String id) async {
    AppLogger.d('NotificationRepository: existsById($id)');

    try {
      final exists = await localDataSource.existsById(id);
      return Right(exists);
    } catch (e) {
      AppLogger.e('Error en existsById: $e');
      return const Right(false);
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Verificar si debe cachear el resultado
  /// FASE 3: Siempre cachear a ISAR (upsert por serverId evita duplicados)
  bool _shouldCacheResult(
    int page,
    bool? unreadOnly,
    NotificationType? type,
    NotificationPriority? priority,
  ) {
    return true;
  }

  /// Obtener notificaciones desde cache con paginación y filtros
  Future<Either<Failure, PaginatedResult<Notification>>>
      _getNotificationsFromCache({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
    NotificationType? type,
    NotificationPriority? priority,
  }) async {
    try {
      var cached = await localDataSource.getCachedNotifications();

      // Aplicar filtros en memoria
      if (unreadOnly == true) {
        cached = cached.where((n) => !n.isRead).toList();
      }

      if (type != null) {
        cached = cached.where((n) => n.type == type).toList();
      }

      if (priority != null) {
        cached = cached.where((n) => n.priority == priority).toList();
      }

      // Calcular paginación
      final totalItems = cached.length;
      final totalPages = (totalItems / limit).ceil();
      final offset = (page - 1) * limit;

      final paginatedData = cached.skip(offset).take(limit).toList();
      final notifications =
          paginatedData.map((model) => model.toEntity()).toList();

      final meta = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      );

      return Right(PaginatedResult(data: notifications, meta: meta));
    } on CacheException catch (e) {
      AppLogger.e('CacheException: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      AppLogger.e('Error al obtener desde cache: $e');
      return Left(CacheFailure('No hay notificaciones en cache'));
    }
  }

  /// Obtener notificación individual desde cache
  Future<Either<Failure, Notification>> _getNotificationFromCache(
    String id,
  ) async {
    try {
      final cached = await localDataSource.getCachedNotification(id);

      if (cached == null) {
        return Left(ServerFailure('Notificación no encontrada en cache'));
      }

      return Right(cached.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al obtener notificación del cache'));
    }
  }

  /// Buscar notificaciones en cache
  Future<Either<Failure, List<Notification>>> _searchNotificationsInCache(
    String searchTerm,
  ) async {
    try {
      final cached =
          await localDataSource.searchCachedNotifications(searchTerm);
      final notifications = cached.map((model) => model.toEntity()).toList();
      return Right(notifications);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al buscar en cache'));
    }
  }

  /// Obtener contador de no leídas desde cache
  Future<Either<Failure, int>> _getUnreadCountFromCache() async {
    try {
      final count = await localDataSource.getCachedUnreadCount();
      return Right(count);
    } catch (e) {
      return const Right(0);
    }
  }

  /// Obtener notificaciones no leídas desde cache
  Future<Either<Failure, List<Notification>>>
      _getUnreadNotificationsFromCache() async {
    try {
      final cached = await localDataSource.getCachedUnreadNotifications();
      final notifications = cached.map((model) => model.toEntity()).toList();
      return Right(notifications);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al obtener no leídas del cache'));
    }
  }

  /// Obtener estadísticas desde cache
  Future<Either<Failure, NotificationStats>> _getStatisticsFromCache() async {
    try {
      final stats = await localDataSource.getCachedNotificationStats();

      if (stats == null) {
        // Retornar estadísticas vacías en lugar de fallar
        return Right(
          NotificationStats(
            total: 0,
            unread: 0,
            read: 0,
            byType: {},
            byPriority: {},
          ),
        );
      }

      return Right(stats);
    } catch (e) {
      AppLogger.e('Error al obtener estadísticas del cache: $e');
      return Right(
        NotificationStats(
          total: 0,
          unread: 0,
          read: 0,
          byType: {},
          byPriority: {},
        ),
      );
    }
  }

  /// Agregar operación "marcar como leída" a la cola de sincronización
  /// NO agrega notificaciones dinámicas ya que estas no existen en el backend
  Future<void> _addMarkAsReadToSyncQueue(String notificationId) async {
    // Las notificaciones dinámicas no deben agregarse a la cola de sync
    // ya que no existen en la base de datos del backend
    if (_isDynamicNotification(notificationId)) {
      AppLogger.d('Notificación dinámica - no se agrega a cola de sync', tag: 'NOTIFICATION');
      return;
    }

    try {
      final syncService = Get.find<SyncService>();
      await syncService.addOperationForCurrentUser(
        entityType: 'notification',
        entityId: notificationId,
        operationType: SyncOperationType.update,
        data: {'isRead': true},
      );

      AppLogger.i('Operación markAsRead agregada a cola de sync', tag: 'NOTIFICATION');
    } catch (e) {
      AppLogger.e('Error al agregar a cola de sync: $e');
    }
  }

  /// Preservar el estado isRead de notificaciones dinámicas
  /// Consulta tanto el cache local como el backend para obtener el estado más actualizado
  Future<List<NotificationModel>> _preserveDynamicNotificationReadState(
    List<NotificationModel> serverNotifications,
  ) async {
    try {
      // Obtener IDs de notificaciones dinámicas que vienen del servidor
      final dynamicIds = serverNotifications
          .where((n) => _isDynamicNotification(n.id))
          .map((n) => n.id)
          .toSet();

      if (dynamicIds.isEmpty) {
        // No hay notificaciones dinámicas, retornar sin cambios
        return serverNotifications;
      }

      // Obtener estado actual del cache para notificaciones dinámicas
      final Map<String, bool> readState = {};

      // 1. Primero obtener estados del cache local
      for (final id in dynamicIds) {
        try {
          final cached = await localDataSource.getCachedNotification(id);
          if (cached != null && cached.isRead) {
            readState[id] = true;
            AppLogger.d('Estado local isRead=true para notificación dinámica: $id', tag: 'NOTIFICATION');
          }
        } catch (e) {
          // Ignorar errores de cache individual
        }
      }

      // 2. Obtener estados del backend (para sincronización entre dispositivos)
      try {
        final isConnected = await networkInfo.isConnected;
        if (isConnected) {
          final backendReadIds = await remoteDataSource.getReadDynamicNotificationIds();
          for (final id in backendReadIds) {
            if (dynamicIds.contains(id) && !readState.containsKey(id)) {
              readState[id] = true;
              AppLogger.d('Estado backend isRead=true para notificación dinámica: $id', tag: 'NOTIFICATION');
            }
          }
        }
      } catch (e) {
        AppLogger.w('Error obteniendo estados del backend: $e', tag: 'NOTIFICATION');
      }

      if (readState.isEmpty) {
        // No hay estados que preservar
        return serverNotifications;
      }

      // Crear nueva lista con estados preservados
      final result = serverNotifications.map((notification) {
        if (readState.containsKey(notification.id)) {
          // Preservar el estado isRead: true
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      AppLogger.i('Preservados ${readState.length} estados isRead de notificaciones dinámicas', tag: 'NOTIFICATION');
      return result;
    } catch (e) {
      AppLogger.w('Error preservando estados isRead: $e - retornando sin cambios', tag: 'NOTIFICATION');
      return serverNotifications;
    }
  }
}
