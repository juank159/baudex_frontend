// lib/features/settings/data/repositories/organization_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';
import '../datasources/organization_remote_datasource.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final OrganizationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  OrganizationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Organization>> getCurrentOrganization() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getCurrentOrganization();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(ConnectionFailure('Sin conexión a internet'));
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
}