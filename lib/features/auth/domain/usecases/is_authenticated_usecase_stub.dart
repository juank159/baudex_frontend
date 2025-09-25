// lib/features/auth/domain/usecases/is_authenticated_usecase_stub.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../data/datasources/auth_local_datasource.dart';

/// Implementación stub de IsAuthenticatedUseCase
class IsAuthenticatedUseCaseStub implements UseCase<bool, NoParams> {
  final AuthLocalDataSource localDataSource;

  const IsAuthenticatedUseCaseStub({required this.localDataSource});

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    try {
      final isAuthenticated = await localDataSource.isAuthenticated();
      return Right(isAuthenticated);
    } catch (e) {
      return Left(CacheFailure('Error verificando autenticación: $e'));
    }
  }
}