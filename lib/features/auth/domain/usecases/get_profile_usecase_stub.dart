// lib/features/auth/domain/usecases/get_profile_usecase_stub.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/user.dart';
import '../../data/datasources/auth_local_datasource.dart';

/// Implementación stub de GetProfileUseCase
class GetProfileUseCaseStub implements UseCase<User, NoParams> {
  final AuthLocalDataSource localDataSource;

  const GetProfileUseCaseStub({required this.localDataSource});

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    try {
      final userModel = await localDataSource.getUser();
      
      if (userModel == null) {
        return Left(CacheFailure('Usuario no encontrado'));
      }

      return Right(userModel.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error obteniendo perfil: $e'));
    }
  }
}