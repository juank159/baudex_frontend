// lib/features/cash_register/data/repositories/cash_register_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/entities/cash_register.dart';
import '../../domain/repositories/cash_register_repository.dart';
import '../datasources/cash_register_remote_datasource.dart';

class CashRegisterRepositoryImpl implements CashRegisterRepository {
  final CashRegisterRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CashRegisterRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, CashRegisterCurrentState>> getCurrent() async {
    if (!await networkInfo.isConnected) {
      // En esta primera versión la caja es ONLY ONLINE — el server es
      // la única fuente de verdad. Sin red no podemos saber el estado
      // exacto del turno. (Próxima fase: cache offline en ISAR.)
      return Left(NetworkFailure(
        'Sin conexión: la caja registradora requiere internet por ahora.',
      ));
    }
    try {
      final result = await remoteDataSource.getCurrent();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, CashRegister>> open({
    required double openingAmount,
    String? openingNotes,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión: no se puede abrir caja'));
    }
    try {
      final result = await remoteDataSource.open(
        openingAmount: openingAmount,
        openingNotes: openingNotes,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, CashRegister>> close({
    required String id,
    required double closingActualAmount,
    String? closingNotes,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión: no se puede cerrar caja'));
    }
    try {
      final result = await remoteDataSource.close(
        id: id,
        closingActualAmount: closingActualAmount,
        closingNotes: closingNotes,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, CashRegister>> findById(String id) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión'));
    }
    try {
      final result = await remoteDataSource.findById(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CashRegister>>> list({
    CashRegisterStatus? status,
    int limit = 30,
    int offset = 0,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión'));
    }
    try {
      final result = await remoteDataSource.list(
        status: status,
        limit: limit,
        offset: offset,
      );
      return Right(result.cast<CashRegister>());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }
}
