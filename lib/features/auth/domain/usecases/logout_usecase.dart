import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para cerrar sesión
class LogoutUseCase implements UseCase<Unit, NoParams> {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    return await repository.logout();
  }
}
