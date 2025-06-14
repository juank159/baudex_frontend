import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para obtener el perfil del usuario actual
class GetProfileUseCase implements UseCase<User, NoParams> {
  final AuthRepository repository;

  const GetProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    return await repository.getProfile();
  }
}
