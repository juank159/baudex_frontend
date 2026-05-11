import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../auth/domain/entities/user.dart';

/// Filtros opcionales para listar empleados.
class EmployeeListFilters {
  final String? search;
  final UserRole? role;
  final UserStatus? status;
  final int page;
  final int limit;

  const EmployeeListFilters({
    this.search,
    this.role,
    this.status,
    this.page = 1,
    this.limit = 50,
  });
}

/// Repositorio de empleados (CRUD del módulo de equipo del tenant).
/// Online-only — no requiere offline cache (no es flujo crítico de venta).
abstract class EmployeeRepository {
  Future<Either<Failure, List<User>>> list(EmployeeListFilters filters);

  Future<Either<Failure, User>> findById(String id);

  Future<Either<Failure, User>> create({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  });

  Future<Either<Failure, User>> update({
    required String id,
    String? firstName,
    String? lastName,
    String? phone,
    UserRole? role,
  });

  Future<Either<Failure, User>> updateStatus({
    required String id,
    required UserStatus status,
  });

  Future<Either<Failure, Unit>> resetPassword({
    required String id,
    required String newPassword,
  });

  Future<Either<Failure, Unit>> delete(String id);

  Future<Either<Failure, User>> restore(String id);
}
