// lib/features/customer_credits/domain/repositories/customer_credit_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/customer_credit.dart';
import '../../data/models/customer_credit_model.dart';

/// Contrato del repositorio de créditos de clientes
///
/// Define todas las operaciones disponibles para gestionar créditos,
/// saldos a favor y cuentas corrientes de clientes.
abstract class CustomerCreditRepository {
  // ==================== CREDIT OPERATIONS ====================

  /// Obtener todos los créditos con filtros opcionales
  Future<Either<Failure, List<CustomerCredit>>> getCredits(CustomerCreditQueryParams? query);

  /// Obtener un crédito por ID
  Future<Either<Failure, CustomerCredit>> getCreditById(String id);

  /// Obtener créditos de un cliente específico
  Future<Either<Failure, List<CustomerCredit>>> getCreditsByCustomer(String customerId);

  /// Obtener créditos pendientes de un cliente
  Future<Either<Failure, List<CustomerCredit>>> getPendingCreditsByCustomer(String customerId);

  /// Crear un nuevo crédito
  Future<Either<Failure, CustomerCredit>> createCredit(CreateCustomerCreditDto dto);

  /// Agregar un pago a un crédito
  Future<Either<Failure, CustomerCredit>> addPayment(String creditId, AddCreditPaymentDto dto);

  /// Obtener pagos de un crédito
  Future<Either<Failure, List<CreditPayment>>> getCreditPayments(String creditId);

  /// Cancelar un crédito
  Future<Either<Failure, CustomerCredit>> cancelCredit(String creditId);

  /// Marcar créditos como vencidos
  Future<Either<Failure, int>> markOverdueCredits();

  /// Obtener estadísticas de créditos
  Future<Either<Failure, CreditStats>> getCreditStats();

  /// Eliminar un crédito (soft delete)
  Future<Either<Failure, void>> deleteCredit(String creditId);

  // ==================== CREDIT TRANSACTIONS ====================

  /// Obtener transacciones de un crédito
  Future<Either<Failure, List<CreditTransactionModel>>> getCreditTransactions(String creditId);

  /// Agregar monto a un crédito (aumentar deuda)
  Future<Either<Failure, CustomerCredit>> addAmountToCredit(String creditId, AddAmountToCreditDto dto);

  /// Aplicar saldo a favor a un crédito
  Future<Either<Failure, CustomerCredit>> applyBalanceToCredit(String creditId, ApplyBalanceToCreditDto dto);

  // ==================== CLIENT BALANCE ====================

  /// Obtener todos los saldos a favor de clientes
  Future<Either<Failure, List<ClientBalanceModel>>> getAllClientBalances();

  /// Obtener saldo a favor de un cliente
  Future<Either<Failure, ClientBalanceModel?>> getClientBalance(String customerId);

  /// Obtener transacciones de saldo de un cliente
  Future<Either<Failure, List<ClientBalanceTransactionModel>>> getClientBalanceTransactions(String customerId);

  /// Depositar saldo a favor
  Future<Either<Failure, ClientBalanceModel>> depositBalance(DepositBalanceDto dto);

  /// Usar saldo a favor
  Future<Either<Failure, ClientBalanceModel>> useBalance(UseBalanceDto dto);

  /// Reembolsar saldo a favor
  Future<Either<Failure, ClientBalanceModel>> refundBalance(RefundBalanceDto dto);

  /// Ajustar saldo manualmente
  Future<Either<Failure, ClientBalanceModel>> adjustBalance(AdjustBalanceDto dto);

  // ==================== CUSTOMER ACCOUNT ====================

  /// Obtener cuenta corriente consolidada de un cliente
  /// Incluye créditos, saldos a favor y transacciones
  Future<Either<Failure, CustomerAccountModel>> getCustomerAccount(String customerId);
}
