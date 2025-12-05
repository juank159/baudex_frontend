// lib/features/customer_credits/data/repositories/customer_credit_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/entities/customer_credit.dart';
import '../datasources/customer_credit_remote_datasource.dart';
import '../models/customer_credit_model.dart';

/// Contrato del repositorio de créditos
abstract class CustomerCreditRepository {
  /// Obtener todos los créditos con filtros
  Future<Either<Failure, List<CustomerCredit>>> getCredits(CustomerCreditQueryParams? query);

  /// Obtener un crédito por ID
  Future<Either<Failure, CustomerCredit>> getCreditById(String id);

  /// Obtener créditos de un cliente
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

  /// Marcar créditos vencidos
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

  /// Obtener todos los saldos a favor
  Future<Either<Failure, List<ClientBalanceModel>>> getAllClientBalances();

  /// Obtener saldo de un cliente
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
  Future<Either<Failure, CustomerAccountModel>> getCustomerAccount(String customerId);
}

/// Implementación del repositorio de créditos
class CustomerCreditRepositoryImpl implements CustomerCreditRepository {
  final CustomerCreditRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CustomerCreditRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CustomerCredit>>> getCredits(CustomerCreditQueryParams? query) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final credits = await remoteDataSource.getCredits(query);
      return Right(credits);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener créditos: $e'));
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> getCreditById(String id) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final credit = await remoteDataSource.getCreditById(id);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener crédito: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CustomerCredit>>> getCreditsByCustomer(String customerId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final credits = await remoteDataSource.getCreditsByCustomer(customerId);
      return Right(credits);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener créditos del cliente: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CustomerCredit>>> getPendingCreditsByCustomer(String customerId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final credits = await remoteDataSource.getPendingCreditsByCustomer(customerId);
      return Right(credits);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener créditos pendientes: $e'));
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> createCredit(CreateCustomerCreditDto dto) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final credit = await remoteDataSource.createCredit(dto);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al crear crédito: $e'));
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> addPayment(String creditId, AddCreditPaymentDto dto) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final credit = await remoteDataSource.addPayment(creditId, dto);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al agregar pago: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CreditPayment>>> getCreditPayments(String creditId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final payments = await remoteDataSource.getCreditPayments(creditId);
      return Right(payments);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener pagos: $e'));
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> cancelCredit(String creditId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final credit = await remoteDataSource.cancelCredit(creditId);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al cancelar crédito: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> markOverdueCredits() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final count = await remoteDataSource.markOverdueCredits();
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al marcar créditos vencidos: $e'));
    }
  }

  @override
  Future<Either<Failure, CreditStats>> getCreditStats() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final stats = await remoteDataSource.getCreditStats();
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener estadísticas: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCredit(String creditId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      await remoteDataSource.deleteCredit(creditId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al eliminar crédito: $e'));
    }
  }

  // ==================== CREDIT TRANSACTIONS ====================

  @override
  Future<Either<Failure, List<CreditTransactionModel>>> getCreditTransactions(String creditId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final transactions = await remoteDataSource.getCreditTransactions(creditId);
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener transacciones: $e'));
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> addAmountToCredit(String creditId, AddAmountToCreditDto dto) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final credit = await remoteDataSource.addAmountToCredit(creditId, dto);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al agregar monto al crédito: $e'));
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> applyBalanceToCredit(String creditId, ApplyBalanceToCreditDto dto) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final credit = await remoteDataSource.applyBalanceToCredit(creditId, dto);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al aplicar saldo a favor: $e'));
    }
  }

  // ==================== CLIENT BALANCE ====================

  @override
  Future<Either<Failure, List<ClientBalanceModel>>> getAllClientBalances() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final balances = await remoteDataSource.getAllClientBalances();
      return Right(balances);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener saldos a favor: $e'));
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel?>> getClientBalance(String customerId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final balance = await remoteDataSource.getClientBalance(customerId);
      return Right(balance);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener saldo del cliente: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ClientBalanceTransactionModel>>> getClientBalanceTransactions(String customerId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final transactions = await remoteDataSource.getClientBalanceTransactions(customerId);
      return Right(transactions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener transacciones de saldo: $e'));
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> depositBalance(DepositBalanceDto dto) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final balance = await remoteDataSource.depositBalance(dto);
      return Right(balance);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al depositar saldo: $e'));
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> useBalance(UseBalanceDto dto) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final balance = await remoteDataSource.useBalance(dto);
      return Right(balance);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al usar saldo a favor: $e'));
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> refundBalance(RefundBalanceDto dto) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final balance = await remoteDataSource.refundBalance(dto);
      return Right(balance);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al reembolsar saldo: $e'));
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> adjustBalance(AdjustBalanceDto dto) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final balance = await remoteDataSource.adjustBalance(dto);
      return Right(balance);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al ajustar saldo: $e'));
    }
  }

  // ==================== CUSTOMER ACCOUNT ====================

  @override
  Future<Either<Failure, CustomerAccountModel>> getCustomerAccount(String customerId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('Sin conexión a internet'));
    }

    try {
      final account = await remoteDataSource.getCustomerAccount(customerId);
      return Right(account);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener cuenta corriente: $e'));
    }
  }
}
