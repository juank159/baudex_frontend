// lib/features/cash_register/data/repositories/cash_register_repository_impl.dart
import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../domain/entities/cash_register.dart';
import '../../domain/repositories/cash_register_repository.dart';
import '../datasources/cash_register_remote_datasource.dart';
import '../models/cash_register_model.dart';

class CashRegisterRepositoryImpl implements CashRegisterRepository {
  final CashRegisterRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SecureStorageService? secureStorage;

  /// Clave de cache para el último estado conocido de la caja.
  /// Persistido en SecureStorage para que las protecciones de venta
  /// en efectivo funcionen aún sin red.
  static const _cacheKey = 'cash_register_current_cache';

  CashRegisterRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    this.secureStorage,
  });

  @override
  Future<Either<Failure, CashRegisterCurrentState>> getCurrent() async {
    // ============ MODO OFFLINE: leer último estado conocido ============
    if (!await networkInfo.isConnected) {
      final cached = await _readCache();
      if (cached != null) return Right(cached);
      return Left(NetworkFailure(
        'Sin conexión y sin estado en caché. Conéctate al menos una vez para sincronizar la caja.',
      ));
    }

    // ============ MODO ONLINE: pull del server + actualizar cache ============
    try {
      final result = await remoteDataSource.getCurrent();
      // Persistir el estado para acceso offline futuro.
      await _writeCache(result);
      return Right(result);
    } on ServerException catch (e) {
      // Si el server falla pero tenemos cache, usarlo (degradado pero funcional).
      final cached = await _readCache();
      if (cached != null) return Right(cached);
      return Left(ServerFailure(e.message));
    } catch (e) {
      final cached = await _readCache();
      if (cached != null) return Right(cached);
      return Left(UnknownFailure('Error inesperado: $e'));
    }
  }

  Future<void> _writeCache(CashRegisterCurrentStateModel state) async {
    if (secureStorage == null) return;
    try {
      final json = <String, dynamic>{
        'cashRegister': state.cashRegister != null
            ? _serializeRegister(state.cashRegister!)
            : null,
        'summary': (state.summary as CashRegisterSummaryModel).toJson(),
        'expectedAmount': state.expectedAmount,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await secureStorage!.write(_cacheKey, jsonEncode(json));
    } catch (_) {
      // No bloquear flujo por error de cache.
    }
  }

  Future<CashRegisterCurrentStateModel?> _readCache() async {
    if (secureStorage == null) return null;
    try {
      final raw = await secureStorage!.read(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return CashRegisterCurrentStateModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _serializeRegister(CashRegister r) {
    return {
      'id': r.id,
      'status': r.status.value,
      'openingAmount': r.openingAmount,
      'closingExpectedAmount': r.closingExpectedAmount,
      'closingActualAmount': r.closingActualAmount,
      'closingDifference': r.closingDifference,
      'closingSummary': r.closingSummary == null
          ? null
          : (r.closingSummary as CashRegisterSummaryModel).toJson(),
      'openedAt': r.openedAt.toIso8601String(),
      'openedById': r.openedById,
      'openedBy': r.openedByName == null ? null : {'fullName': r.openedByName},
      'closedAt': r.closedAt?.toIso8601String(),
      'closedById': r.closedById,
      'closedBy': r.closedByName == null ? null : {'fullName': r.closedByName},
      'openingNotes': r.openingNotes,
      'closingNotes': r.closingNotes,
      'organizationId': r.organizationId,
      'createdAt': r.createdAt.toIso8601String(),
      'updatedAt': r.updatedAt.toIso8601String(),
      'deletedAt': r.deletedAt?.toIso8601String(),
    };
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
