import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../datasources/user_preferences_remote_datasource.dart';

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  final UserPreferencesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UserPreferencesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserPreferences>> getUserPreferences() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getUserPreferences();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserPreferences>> updateUserPreferences(
    Map<String, dynamic> preferences,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateUserPreferences(preferences);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }
}