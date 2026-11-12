// lib/features/cash_register/domain/repositories/cash_register_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/cash_register.dart';
import '../entities/cash_register_movement.dart';

abstract class CashRegisterRepository {
  /// Estado de la caja del tenant en este momento (abierta o no).
  Future<Either<Failure, CashRegisterCurrentState>> getCurrent();

  /// Abrir caja con un saldo inicial. Falla si ya hay una abierta.
  Future<Either<Failure, CashRegister>> open({
    required double openingAmount,
    String? openingNotes,
  });

  /// Cerrar la caja con el efectivo contado físicamente.
  Future<Either<Failure, CashRegister>> close({
    required String id,
    required double closingActualAmount,
    String? closingNotes,
  });

  /// Detalle de una caja por id (incluye cerradas).
  Future<Either<Failure, CashRegister>> findById(String id);

  /// Trazabilidad del turno: cada cobro, abono y gasto, uno por uno.
  /// Con conexión se trae del servidor y se guarda; sin conexión se muestra
  /// lo último guardado de esa caja.
  Future<Either<Failure, CashRegisterMovements>> movements(String id);

  /// Historial de cajas del tenant.
  Future<Either<Failure, List<CashRegister>>> list({
    CashRegisterStatus? status,
    int limit = 30,
    int offset = 0,
  });
}
