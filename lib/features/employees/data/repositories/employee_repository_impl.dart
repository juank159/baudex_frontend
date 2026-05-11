import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/employee_repository.dart';
import '../datasources/employee_remote_datasource.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  final EmployeeRemoteDataSource remote;
  final NetworkInfo networkInfo;

  EmployeeRepositoryImpl({
    required this.remote,
    required this.networkInfo,
  });

  Future<Either<Failure, T>> _online<T>(Future<T> Function() fn) async {
    if (!await networkInfo.isConnected) {
      return const Left(ConnectionFailure(
        'Sin conexión. La gestión de empleados requiere internet.',
      ));
    }
    try {
      return Right(await fn());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, List<User>>> list(EmployeeListFilters filters) =>
      _online(() async => (await remote.list(filters))
          .map((m) => m as User)
          .toList());

  @override
  Future<Either<Failure, User>> findById(String id) =>
      _online(() async => await remote.findById(id) as User);

  @override
  Future<Either<Failure, User>> create({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) =>
      _online(() async => await remote.create(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            role: role,
            phone: phone,
          ) as User);

  @override
  Future<Either<Failure, User>> update({
    required String id,
    String? firstName,
    String? lastName,
    String? phone,
    UserRole? role,
  }) =>
      _online(() async => await remote.update(
            id: id,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            role: role,
          ) as User);

  @override
  Future<Either<Failure, User>> updateStatus({
    required String id,
    required UserStatus status,
  }) =>
      _online(() async =>
          await remote.updateStatus(id: id, status: status) as User);

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String id,
    required String newPassword,
  }) =>
      _online(() async {
        await remote.resetPassword(id: id, newPassword: newPassword);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> delete(String id) => _online(() async {
        await remote.delete(id);
        return unit;
      });

  @override
  Future<Either<Failure, User>> restore(String id) =>
      _online(() async => await remote.restore(id) as User);
}
