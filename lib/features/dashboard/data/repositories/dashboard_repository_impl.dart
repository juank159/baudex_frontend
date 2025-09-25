// lib/features/dashboard/data/repositories/dashboard_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/recent_activity.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../datasources/dashboard_local_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteStats = await remoteDataSource.getDashboardStats(
          startDate: startDate,
          endDate: endDate,
        );
        
        // Cache solo si no hay filtros de fecha (datos generales)
        if (startDate == null && endDate == null) {
          await localDataSource.cacheDashboardStats(remoteStats);
        }
        
        return Right(remoteStats);
      } on ServerException catch (e) {
        // Si hay error del servidor, intentar usar cache
        if (startDate == null && endDate == null) {
          final cachedStats = await localDataSource.getCachedDashboardStats();
          if (cachedStats != null) {
            return Right(cachedStats);
          }
        }
        return Left(ServerFailure(e.message));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    } else {
      // Sin conexión, usar cache si no hay filtros
      if (startDate == null && endDate == null) {
        try {
          final cachedStats = await localDataSource.getCachedDashboardStats();
          if (cachedStats != null) {
            return Right(cachedStats);
          }
          return Left(CacheFailure('No hay datos en cache'));
        } on CacheException catch (e) {
          return Left(CacheFailure(e.message));
        }
      } else {
        return Left(ConnectionFailure('Sin conexión a internet'));
      }
    }
  }

  @override
  Future<Either<Failure, List<RecentActivity>>> getRecentActivity({
    int limit = 20,
    List<ActivityType>? types,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteActivity = await remoteDataSource.getRecentActivity(
          limit: limit,
          types: types,
        );
        
        // Cache solo si no hay filtros
        if (types == null || types.isEmpty) {
          await localDataSource.cacheRecentActivity(remoteActivity);
        }
        
        return Right(remoteActivity);
      } on ServerException catch (e) {
        // Si hay error, intentar usar cache
        if (types == null || types.isEmpty) {
          final cachedActivity = await localDataSource.getCachedRecentActivity();
          if (cachedActivity != null) {
            return Right(cachedActivity);
          }
        }
        return Left(ServerFailure(e.message));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    } else {
      // Sin conexión, usar cache si no hay filtros
      if (types == null || types.isEmpty) {
        try {
          final cachedActivity = await localDataSource.getCachedRecentActivity();
          if (cachedActivity != null) {
            return Right(cachedActivity);
          }
          return Left(CacheFailure('No hay datos en cache'));
        } on CacheException catch (e) {
          return Left(CacheFailure(e.message));
        }
      } else {
        return Left(ConnectionFailure('Sin conexión a internet'));
      }
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> getNotifications({
    int limit = 50,
    bool? unreadOnly,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteNotifications = await remoteDataSource.getNotifications(
          limit: limit,
          unreadOnly: unreadOnly,
        );
        
        // Cache solo si no hay filtros
        if (unreadOnly == null) {
          await localDataSource.cacheNotifications(remoteNotifications);
        }
        
        return Right(remoteNotifications);
      } on ServerException catch (e) {
        // Si hay error, intentar usar cache
        if (unreadOnly == null) {
          final cachedNotifications = await localDataSource.getCachedNotifications();
          if (cachedNotifications != null) {
            return Right(cachedNotifications);
          }
        }
        return Left(ServerFailure(e.message));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    } else {
      // Sin conexión, usar cache si no hay filtros
      if (unreadOnly == null) {
        try {
          final cachedNotifications = await localDataSource.getCachedNotifications();
          if (cachedNotifications != null) {
            return Right(cachedNotifications);
          }
          return Left(CacheFailure('No hay datos en cache'));
        } on CacheException catch (e) {
          return Left(CacheFailure(e.message));
        }
      } else {
        return Left(ConnectionFailure('Sin conexión a internet'));
      }
    }
  }

  @override
  Future<Either<Failure, Notification>> markNotificationAsRead(String notificationId) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedNotification = await remoteDataSource.markNotificationAsRead(notificationId);
        
        // Actualizar cache
        try {
          final cachedNotifications = await localDataSource.getCachedNotifications();
          if (cachedNotifications != null) {
            final updatedList = cachedNotifications.map((notification) {
              if (notification.id == notificationId) {
                return updatedNotification;
              }
              return notification;
            }).toList();
            await localDataSource.cacheNotifications(updatedList);
          }
        } catch (e) {
          // Error silencioso en cache
        }
        
        return Right(updatedNotification);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.markAllNotificationsAsRead();
        
        // Limpiar cache para forzar recarga
        try {
          await localDataSource.clearCache();
        } catch (e) {
          // Error silencioso en cache
        }
        
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteNotification(notificationId);
        
        // Actualizar cache
        try {
          final cachedNotifications = await localDataSource.getCachedNotifications();
          if (cachedNotifications != null) {
            final updatedList = cachedNotifications
                .where((notification) => notification.id != notificationId)
                .toList();
            await localDataSource.cacheNotifications(updatedList);
          }
        } catch (e) {
          // Error silencioso en cache
        }
        
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadNotificationsCount() async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getUnreadNotificationsCount();
        await localDataSource.cacheUnreadNotificationsCount(count);
        return Right(count);
      } on ServerException catch (e) {
        // Si hay error, intentar usar cache
        final cachedCount = await localDataSource.getCachedUnreadNotificationsCount();
        if (cachedCount != null) {
          return Right(cachedCount);
        }
        return Left(ServerFailure(e.message));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    } else {
      // Sin conexión, usar cache
      try {
        final cachedCount = await localDataSource.getCachedUnreadNotificationsCount();
        if (cachedCount != null) {
          return Right(cachedCount);
        }
        return Left(CacheFailure('No hay datos en cache'));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      }
    }
  }

  @override
  Future<Either<Failure, SalesStats>> getSalesStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getSalesStats(
          startDate: startDate,
          endDate: endDate,
        );
        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, InvoiceStats>> getInvoiceStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getInvoiceStats(
          startDate: startDate,
          endDate: endDate,
        );
        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, ProductStats>> getProductStats() async {
    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getProductStats();
        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, CustomerStats>> getCustomerStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getCustomerStats(
          startDate: startDate,
          endDate: endDate,
        );
        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, ExpenseStats>> getExpenseStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getExpenseStats(
          startDate: startDate,
          endDate: endDate,
        );
        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, ProfitabilityStats>> getProfitabilityStats({
    DateTime? startDate,
    DateTime? endDate,
    String? warehouseId,
    String? categoryId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getProfitabilityStats(
          startDate: startDate,
          endDate: endDate,
          warehouseId: warehouseId,
          categoryId: categoryId,
        );
        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(ConnectionFailure('Sin conexión a internet'));
    }
  }
}