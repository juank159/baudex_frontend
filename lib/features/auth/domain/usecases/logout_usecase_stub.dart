// lib/features/auth/domain/usecases/logout_usecase_stub.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../data/datasources/auth_local_datasource.dart';

/// Implementación stub de LogoutUseCase
class LogoutUseCaseStub implements UseCase<Unit, NoParams> {
  final AuthLocalDataSource localDataSource;

  const LogoutUseCaseStub({required this.localDataSource});

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    try {
      await localDataSource.clearAuthData();
      print('✅ LogoutUseCaseStub: Datos de auth limpiados');
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error cerrando sesión: $e'));
    }
  }
}