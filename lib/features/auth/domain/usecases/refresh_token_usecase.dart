import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para refrescar token
class RefreshTokenUseCase implements UseCase<String, NoParams> {
  final AuthRepository repository;

  const RefreshTokenUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(NoParams params) async {
    return await repository.refreshToken();
  }
}
