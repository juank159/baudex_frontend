// lib/features/settings/data/repositories/organization_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';
import '../datasources/organization_remote_datasource.dart';
import 'organization_offline_repository.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final OrganizationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final OrganizationOfflineRepository? offlineRepository;

  OrganizationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    this.offlineRepository,
  });

  OrganizationOfflineRepository get _offlineRepo =>
      offlineRepository ?? OrganizationOfflineRepository();

  /// Cache-first: lee ISAR directo sin tocar la red (instantáneo)
  Future<Either<Failure, Organization>> getCachedOrganization() async {
    return _getFromCache();
  }

  /// Fetch del servidor y actualizar cache ISAR. No lee cache como fallback.
  Future<Either<Failure, Organization>> refreshFromServer() async {
    if (!await networkInfo.isConnected) {
      return Left(ConnectionFailure.noInternet);
    }
    try {
      final result = await remoteDataSource.getCurrentOrganization();
      try {
        await _offlineRepo.cacheOrganization(result);
      } catch (_) {}
      return Right(result);
    } on ConnectionException catch (e) {
      networkInfo.markServerUnreachable();
      return Left(ConnectionFailure(e.message));
    } on ServerException catch (e) {
      if (e.message.contains('timeout') || e.message.contains('conexión')) {
        networkInfo.markServerUnreachable();
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, Organization>> getCurrentOrganization() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCurrentOrganization();

        try {
          await _offlineRepo.cacheOrganization(result);
        } catch (e) {
          print('⚠️ Error cacheando organización: $e');
        }

        return Right(result);
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _getFromCache();
      } on ServerException catch (e) {
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _getFromCache();
      } catch (e) {
        return _getFromCache();
      }
    } else {
      return _getFromCache();
    }
  }

  Future<Either<Failure, Organization>> _getFromCache() async {
    try {
      final cachedResult = await _offlineRepo.getCurrentOrganization();
      return cachedResult.fold(
        (failure) =>
            Left(CacheFailure('No hay datos de organización disponibles offline')),
        (organization) => Right(organization),
      );
    } catch (e) {
      return Left(CacheFailure('Error obteniendo organización de cache: $e'));
    }
  }

  @override
  Future<Either<Failure, Organization>> updateCurrentOrganization(
      Map<String, dynamic> updates) async {
    if (await networkInfo.isConnected) {
      try {
        final result =
            await remoteDataSource.updateCurrentOrganization(updates);

        try {
          await _offlineRepo.cacheOrganization(result);
        } catch (_) {}

        return Right(result);
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _offlineRepo.updateCurrentOrganization(updates);
      } on ServerException catch (e) {
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _offlineRepo.updateCurrentOrganization(updates);
      }
    } else {
      return _offlineRepo.updateCurrentOrganization(updates);
    }
  }

  @override
  Future<Either<Failure, Organization>> getOrganizationById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getOrganizationById(id);
        return Right(result);
      } on ConnectionException {
        networkInfo.markServerUnreachable();
        return _offlineRepo.getOrganizationById(id);
      } on ServerException {
        return _offlineRepo.getOrganizationById(id);
      }
    } else {
      return _offlineRepo.getOrganizationById(id);
    }
  }

  @override
  Future<Either<Failure, bool>> updateProfitMargin(
      double marginPercentage) async {
    if (await networkInfo.isConnected) {
      try {
        final result =
            await remoteDataSource.updateProfitMargin(marginPercentage);
        return Right(result);
      } on ConnectionException catch (e) {
        networkInfo.markServerUnreachable();
        return _offlineRepo.updateProfitMargin(marginPercentage);
      } on ServerException catch (e) {
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _offlineRepo.updateProfitMargin(marginPercentage);
      }
    } else {
      return _offlineRepo.updateProfitMargin(marginPercentage);
    }
  }
}
