// lib/features/subscriptions/data/datasources/subscription_local_datasource.dart

import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../domain/entities/subscription.dart';
import '../models/isar/isar_subscription.dart';
import 'subscription_cache.dart';

abstract class SubscriptionLocalDataSource {
  /// Obtener suscripcion cacheada
  Future<Either<Failure, Subscription>> getCachedSubscription();

  /// Obtener suscripcion por organizacion
  Future<Either<Failure, Subscription>> getCachedSubscriptionByOrganization(
    String organizationId,
  );

  /// Guardar suscripcion en cache
  Future<Either<Failure, void>> cacheSubscription(Subscription subscription);

  /// Verificar si la suscripcion en cache esta expirada
  Future<bool> isCachedSubscriptionExpired();

  /// Verificar si esta en periodo de gracia offline
  Future<bool> isInOfflineGracePeriod();

  /// Marcar que expiro mientras estaba offline
  Future<void> markExpiredWhileOffline();

  /// Verificar si expiro mientras estaba offline
  Future<bool> wasExpiredWhileOffline();

  /// Limpiar flag de expiracion offline
  Future<void> clearExpiredOfflineFlag();

  /// Obtener fecha de ultima sincronizacion
  Future<DateTime?> getLastSyncDate();

  /// Limpiar cache de suscripcion
  Future<Either<Failure, void>> clearCache();
}

class SubscriptionLocalDataSourceImpl implements SubscriptionLocalDataSource {
  final IsarDatabase _database;

  SubscriptionLocalDataSourceImpl({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  @override
  Future<Either<Failure, Subscription>> getCachedSubscription() async {
    try {
      final isarSubscription = await currentCachedSubscription(_isar);

      if (isarSubscription == null) {
        return Left(CacheFailure('Suscripcion no encontrada en cache local'));
      }

      return Right(isarSubscription.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error obteniendo suscripcion: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Subscription>> getCachedSubscriptionByOrganization(
    String organizationId,
  ) async {
    try {
      final isarSubscription = await _isar.isarSubscriptions
          .filter()
          .organizationIdEqualTo(organizationId)
          .findFirst();

      if (isarSubscription == null) {
        return Left(
          CacheFailure('Suscripcion no encontrada para la organizacion'),
        );
      }

      return Right(isarSubscription.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error obteniendo suscripcion: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheSubscription(
    Subscription subscription,
  ) async {
    try {
      // Guarda la que envió el servidor y borra las anteriores: cada
      // renovación crea una suscripción nueva y las viejas no deben quedar.
      await storeCurrentSubscription(_isar, subscription);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error cacheando suscripcion: ${e.toString()}'));
    }
  }

  @override
  Future<bool> isCachedSubscriptionExpired() async {
    try {
      final isarSubscription = await currentCachedSubscription(_isar);

      // Sin copia local (o si no se pudo leer) NO se puede afirmar que venció.
      if (isarSubscription == null) {
        return false;
      }

      return isarSubscription.toEntity().isExpired;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isInOfflineGracePeriod() async {
    try {
      final isarSubscription = await currentCachedSubscription(_isar);

      if (isarSubscription == null) {
        return false;
      }

      return isarSubscription.isInOfflineGracePeriod;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> markExpiredWhileOffline() async {
    try {
      final isarSubscription = await currentCachedSubscription(_isar);

      if (isarSubscription != null) {
        isarSubscription.wasExpiredOffline = true;
        isarSubscription.setOfflineGracePeriod(days: 3);
        await _isar.writeTxn(() async {
          await _isar.isarSubscriptions.put(isarSubscription);
        });
      }
    } catch (e) {
      // Log error silently
    }
  }

  @override
  Future<bool> wasExpiredWhileOffline() async {
    try {
      final isarSubscription = await currentCachedSubscription(_isar);

      return isarSubscription?.wasExpiredOffline ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clearExpiredOfflineFlag() async {
    try {
      final isarSubscription = await currentCachedSubscription(_isar);

      if (isarSubscription != null) {
        isarSubscription.wasExpiredOffline = false;
        isarSubscription.offlineGraceEnd = null;
        await _isar.writeTxn(() async {
          await _isar.isarSubscriptions.put(isarSubscription);
        });
      }
    } catch (e) {
      // Log error silently
    }
  }

  @override
  Future<DateTime?> getLastSyncDate() async {
    try {
      final isarSubscription = await currentCachedSubscription(_isar);

      return isarSubscription?.lastSyncAt;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarSubscriptions.clear();
      });
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Error limpiando cache de suscripcion: ${e.toString()}'),
      );
    }
  }
}
