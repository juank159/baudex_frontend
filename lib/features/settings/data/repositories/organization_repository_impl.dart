// lib/features/settings/data/repositories/organization_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/create_organization_request.dart';
import '../../domain/repositories/organization_repository.dart';
import '../datasources/organization_remote_datasource.dart';
import '../models/create_organization_request_model.dart';

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
  Future<Either<Failure, List<Organization>>> getAllOrganizations() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAllOrganizations();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, Organization>> createOrganization(CreateOrganizationRequest request) async {
    if (await networkInfo.isConnected) {
      try {
        final model = CreateOrganizationRequestModel.fromEntity(request);
        final result = await remoteDataSource.createOrganization(model);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, Organization>> updateOrganization(String id, Map<String, dynamic> updates) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateOrganization(id, updates);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(ConnectionFailure('Sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOrganization(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteOrganization(id);
        return const Right(null);
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