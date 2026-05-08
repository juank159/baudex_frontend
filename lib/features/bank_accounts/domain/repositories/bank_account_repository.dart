// lib/features/bank_accounts/domain/repositories/bank_account_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/bank_account.dart';
import '../entities/bank_account_movement.dart';
import '../entities/bank_account_transaction.dart';

/// Página de movements (con paginación).
class BankAccountMovementsPage {
  final List<BankAccountMovement> items;
  final int total;
  final int page;
  final int limit;

  const BankAccountMovementsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  bool get hasNextPage => page * limit < total;
}

/// Contrato del repositorio de cuentas bancarias
abstract class BankAccountRepository {
  // ==================== READ OPERATIONS ====================

  /// Obtener todas las cuentas bancarias del tenant
  Future<Either<Failure, List<BankAccount>>> getBankAccounts({
    BankAccountType? type,
    bool? isActive,
    bool includeInactive = false,
  });

  /// Obtener solo cuentas activas (para dropdowns/selects)
  Future<Either<Failure, List<BankAccount>>> getActiveBankAccounts();

  /// Obtener cuenta bancaria por ID
  Future<Either<Failure, BankAccount>> getBankAccountById(String id);

  /// Obtener cuenta predeterminada
  Future<Either<Failure, BankAccount?>> getDefaultBankAccount();

  /// Obtener transacciones de una cuenta bancaria (LEGACY: calculadas
  /// desde Payment + CreditPayment). Mantenido para compatibilidad.
  Future<Either<Failure, BankAccountTransactionsResponse>>
      getBankAccountTransactions(
    String accountId, {
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
    String? search,
  });

  /// Listar movements REALES de la cuenta desde la tabla
  /// `bank_account_movements` (incluye depósitos manuales, retiros,
  /// transferencias, refunds, ajustes, además de invoice/credit payments).
  /// Cada movement trae snapshot de `balance_after`.
  Future<Either<Failure, BankAccountMovementsPage>> listMovements(
    String accountId, {
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  });

  // ==================== WRITE OPERATIONS ====================

  /// Crear nueva cuenta bancaria
  Future<Either<Failure, BankAccount>> createBankAccount({
    required String name,
    required BankAccountType type,
    String? bankName,
    String? accountNumber,
    String? holderName,
    String? icon,
    bool isActive = true,
    bool isDefault = false,
    int sortOrder = 0,
    String? description,
  });

  /// Actualizar cuenta bancaria
  Future<Either<Failure, BankAccount>> updateBankAccount({
    required String id,
    String? name,
    BankAccountType? type,
    String? bankName,
    String? accountNumber,
    String? holderName,
    String? icon,
    bool? isActive,
    bool? isDefault,
    int? sortOrder,
    String? description,
  });

  /// Eliminar cuenta bancaria (soft delete)
  Future<Either<Failure, void>> deleteBankAccount(String id);

  /// Establecer cuenta como predeterminada
  Future<Either<Failure, BankAccount>> setDefaultBankAccount(String id);

  /// Activar/desactivar cuenta
  Future<Either<Failure, BankAccount>> toggleBankAccountActive(String id);

  // ==================== MOVEMENTS WRITE ====================

  /// Registrar un depósito manual en una cuenta. Online → POST al backend
  /// + cachea movement en ISAR. Offline → crea movement local + actualiza
  /// saldo de la cuenta + encola sync op.
  Future<Either<Failure, BankAccountMovement>> depositManual({
    required String bankAccountId,
    required double amount,
    String? description,
    DateTime? movementDate,
  });

  /// Registrar un retiro manual de una cuenta. Misma mecánica que depósito
  /// pero el monto resta del saldo.
  Future<Either<Failure, BankAccountMovement>> withdrawManual({
    required String bankAccountId,
    required double amount,
    String? description,
    DateTime? movementDate,
  });

  /// Transferir entre dos cuentas. Backend genera 2 movements atómicos.
  /// Offline → genera 2 movements locales con `counterpartyMovementId`
  /// cruzados + encola un solo sync op compuesto.
  Future<Either<Failure, List<BankAccountMovement>>> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? description,
    DateTime? movementDate,
  });
}
