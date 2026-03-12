// lib/features/settings/data/repositories/user_preferences_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';

import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../datasources/user_preferences_local_datasource.dart';
import '../datasources/user_preferences_remote_datasource.dart';

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  final UserPreferencesRemoteDataSource remoteDataSource;
  final UserPreferencesLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  UserPreferencesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserPreferences>> getUserPreferences() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getUserPreferences();

        // Cachear resultado
        await localDataSource.cacheUserPreferences(result);

        return Right(result);
      } on ServerException catch (e) {
        // Si falla el servidor, intentar cache local
        final localResult = await localDataSource.getUserPreferences();
        return localResult.fold(
          (failure) => Left(ServerFailure(e.message)),
          (preferences) => Right(preferences),
        );
      }
    } else {
      // Modo offline - usar cache local
      return localDataSource.getUserPreferences();
    }
  }

  @override
  Future<Either<Failure, UserPreferences>> updateUserPreferences(
    Map<String, dynamic> preferences,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateUserPreferences(preferences);

        // Actualizar cache local
        await localDataSource.cacheUserPreferences(result);

        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      // Modo offline - actualizar localmente y agregar a cola de sync
      final localResult = await localDataSource.updateUserPreferencesLocal(preferences);

      return localResult.fold(
        (failure) => Left(failure),
        (updatedPrefs) async {
          // Agregar a cola de sincronización
          try {
            final syncService = Get.find<SyncService>();
            await syncService.addOperationForCurrentUser(
              entityType: 'user_preferences',
              entityId: updatedPrefs.id,
              operationType: SyncOperationType.update,
              data: preferences,
            );
          } catch (e) {
            print('Warning: Could not add preferences to sync queue: $e');
          }

          return Right(updatedPrefs);
        },
      );
    }
  }

  /// Obtener preferencias de cache local (para uso interno)
  Future<Either<Failure, UserPreferences>> getLocalPreferences() async {
    return localDataSource.getUserPreferences();
  }

  /// Obtener preferencias no sincronizadas
  Future<Either<Failure, List<UserPreferences>>> getUnsyncedPreferences() async {
    return localDataSource.getUnsyncedPreferences();
  }

  /// Marcar preferencias como sincronizadas
  Future<Either<Failure, void>> markAsSynced(String preferencesId) async {
    return localDataSource.markAsSynced(preferencesId);
  }

  /// Limpiar cache de preferencias
  Future<Either<Failure, void>> clearCache() async {
    return localDataSource.clearCache();
  }
}
