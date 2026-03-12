// lib/features/settings/data/datasources/user_preferences_local_datasource.dart
import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../domain/entities/user_preferences.dart';
import '../models/isar/isar_user_preferences.dart';

abstract class UserPreferencesLocalDataSource {
  Future<Either<Failure, UserPreferences>> getUserPreferences();
  Future<Either<Failure, UserPreferences>> getUserPreferencesByUserId(String userId);
  Future<Either<Failure, void>> cacheUserPreferences(UserPreferences preferences);
  Future<Either<Failure, UserPreferences>> updateUserPreferencesLocal(
    Map<String, dynamic> updates,
  );
  Future<Either<Failure, List<UserPreferences>>> getUnsyncedPreferences();
  Future<Either<Failure, void>> markAsSynced(String preferencesId);
  Future<Either<Failure, void>> clearCache();
}

class UserPreferencesLocalDataSourceImpl implements UserPreferencesLocalDataSource {
  final IsarDatabase _database;

  UserPreferencesLocalDataSourceImpl({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  @override
  Future<Either<Failure, UserPreferences>> getUserPreferences() async {
    try {
      // Obtener las primeras preferencias (generalmente solo hay una por usuario activo)
      final isarPrefs = await _isar.isarUserPreferences.where().findFirst();

      if (isarPrefs == null) {
        return Left(CacheFailure('Preferencias no encontradas en cache local'));
      }

      return Right(isarPrefs.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error obteniendo preferencias: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserPreferences>> getUserPreferencesByUserId(
    String userId,
  ) async {
    try {
      final isarPrefs = await _isar.isarUserPreferences
          .filter()
          .userIdEqualTo(userId)
          .findFirst();

      if (isarPrefs == null) {
        return Left(CacheFailure('Preferencias no encontradas para usuario'));
      }

      return Right(isarPrefs.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error obteniendo preferencias: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheUserPreferences(
    UserPreferences preferences,
  ) async {
    try {
      final existingPrefs = await _isar.isarUserPreferences
          .filter()
          .serverIdEqualTo(preferences.id)
          .findFirst();

      if (existingPrefs != null) {
        existingPrefs.updateFromEntity(preferences);
        await _isar.writeTxn(() async {
          await _isar.isarUserPreferences.put(existingPrefs);
        });
      } else {
        final isarPrefs = IsarUserPreferences.fromEntity(preferences);
        await _isar.writeTxn(() async {
          await _isar.isarUserPreferences.put(isarPrefs);
        });
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error cacheando preferencias: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserPreferences>> updateUserPreferencesLocal(
    Map<String, dynamic> updates,
  ) async {
    try {
      // Obtener preferencias existentes
      final isarPrefs = await _isar.isarUserPreferences.where().findFirst();

      if (isarPrefs == null) {
        return Left(CacheFailure('Preferencias no encontradas'));
      }

      // Aplicar actualizaciones
      isarPrefs.applyUpdates(updates);

      await _isar.writeTxn(() async {
        await _isar.isarUserPreferences.put(isarPrefs);
      });

      return Right(isarPrefs.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error actualizando preferencias: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserPreferences>>> getUnsyncedPreferences() async {
    try {
      final unsyncedPrefs = await _isar.isarUserPreferences
          .filter()
          .isSyncedEqualTo(false)
          .findAll();

      final preferences = unsyncedPrefs.map((isar) => isar.toEntity()).toList();
      return Right(preferences);
    } catch (e) {
      return Left(
        CacheFailure('Error obteniendo preferencias no sincronizadas: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> markAsSynced(String preferencesId) async {
    try {
      final isarPrefs = await _isar.isarUserPreferences
          .filter()
          .serverIdEqualTo(preferencesId)
          .findFirst();

      if (isarPrefs != null) {
        isarPrefs.markAsSynced();
        await _isar.writeTxn(() async {
          await _isar.isarUserPreferences.put(isarPrefs);
        });
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error marcando preferencias como sincronizadas: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarUserPreferences.clear();
      });
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error limpiando cache de preferencias: ${e.toString()}'));
    }
  }
}
