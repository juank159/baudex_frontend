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

  // Lazy initialization del repositorio offline
  OrganizationOfflineRepository get _offlineRepo =>
      offlineRepository ?? OrganizationOfflineRepository();

  @override
  Future<Either<Failure, Organization>> getCurrentOrganization() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCurrentOrganization();

        // ✅ NUEVO: Cachear organización para uso offline
        try {
          await _offlineRepo.cacheOrganization(result);
          print('💾 Organización cacheada para uso offline');
        } catch (e) {
          print('⚠️ Error cacheando organización: $e');
        }

        return Right(result);
      } on ServerException catch (e) {
        // ✅ Si falla el servidor, intentar cache
        print('⚠️ Error del servidor, intentando cache: ${e.message}');
        return _getFromCache();
      }
    } else {
      // ✅ NUEVO: Cuando está offline, usar datos cacheados
      print('⚠️ Sin conexión - Buscando organización en cache offline...');
      return _getFromCache();
    }
  }

  /// Obtener organización desde cache offline
  Future<Either<Failure, Organization>> _getFromCache() async {
    try {
      final cachedResult = await _offlineRepo.getCurrentOrganization();
      return cachedResult.fold(
        (failure) {
          print('❌ No hay organización en cache: ${failure.message}');
          return Left(CacheFailure('No hay datos de organización disponibles offline'));
        },
        (organization) {
          print('✅ Organización obtenida de cache offline');
          return Right(organization);
        },
      );
    } catch (e) {
      print('❌ Error obteniendo organización de cache: $e');
      return Left(CacheFailure('Error obteniendo organización de cache: $e'));
    }
  }



  @override
  Future<Either<Failure, Organization>> updateCurrentOrganization(Map<String, dynamic> updates) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateCurrentOrganization(updates);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(ConnectionFailure('Sin conexión a internet'));
    }
  }


  @override
  Future<Either<Failure, Organization>> getOrganizationById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getOrganizationById(id);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateProfitMargin(double marginPercentage) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateProfitMargin(marginPercentage);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(ConnectionFailure('Sin conexión a internet'));
    }
  }
}