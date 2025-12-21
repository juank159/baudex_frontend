// lib/features/bank_accounts/domain/repositories/bank_account_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/bank_account.dart';
import '../entities/bank_account_transaction.dart';

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

  /// Obtener transacciones de una cuenta bancaria
  Future<Either<Failure, BankAccountTransactionsResponse>>
      getBankAccountTransactions(
    String accountId, {
    String? startDate,
    String? endDate,
    int? page,
    int? limit,
    String? search,
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
}
