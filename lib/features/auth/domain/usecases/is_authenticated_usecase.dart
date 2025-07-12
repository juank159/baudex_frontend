// import 'package:dartz/dartz.dart';
// import '../../../../app/core/errors/failures.dart';
// import '../../../../app/core/usecases/usecase.dart';
// import '../repositories/auth_repository.dart';

// /// Caso de uso para verificar si está autenticado
// class IsAuthenticatedUseCase implements UseCase<bool, NoParams> {
//   final AuthRepository repository;

//   const IsAuthenticatedUseCase(this.repository);

//   @override
//   Future<Either<Failure, bool>> call(NoParams params) async {
//     try {
//       final isAuth = await repository.isAuthenticated();
//       return Right(isAuth);
//     } catch (e) {
//       return Left(CacheFailure('Error al verificar autenticación: $e'));
//     }
//   }
// }

// lib/features/auth/domain/usecases/is_authenticated_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart'; // Para NoParams
import '../repositories/auth_repository.dart';

/// Caso de uso para verificar si está autenticado
class IsAuthenticatedUseCase implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  const IsAuthenticatedUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    // ✅ Directamente retorna el Either que viene del repositorio.
    // El repositorio ya se encarga de envolver el éxito (bool) o el fallo (Failure).
    return await repository.isAuthenticated();
  }
}
