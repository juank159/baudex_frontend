// lib/features/customer_credits/data/repositories/customer_credit_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/customer_credit.dart';
import '../datasources/customer_credit_local_datasource.dart';
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
  final CustomerCreditLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CustomerCreditRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CustomerCredit>>> getCredits(CustomerCreditQueryParams? query) async {
    // Intentar obtener del servidor
    try {
      final credits = await remoteDataSource.getCredits(query);
      // Cachear en local
      await localDataSource.cacheCredits(credits.cast<CustomerCreditModel>());
      return Right(credits);
    } catch (e) {
      print('⚠️ Error obteniendo créditos del servidor: $e - intentando cache local...');

      // Fallback: obtener del cache local
      try {
        final cachedCredits = await localDataSource.getCachedCredits();
        if (cachedCredits.isNotEmpty) {
          print('✅ Créditos cargados desde cache local (${cachedCredits.length} registros)');
          return Right(cachedCredits);
        }
        return Left(CacheFailure('No hay créditos en cache local'));
      } catch (cacheError) {
        return Left(CacheFailure('Error al obtener créditos del cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> getCreditById(String id) async {
    // Intentar obtener del servidor
    try {
      final credit = await remoteDataSource.getCreditById(id);
      // Cachear en local
      await localDataSource.cacheCredit(credit as CustomerCreditModel);
      return Right(credit);
    } catch (e) {
      print('⚠️ Error obteniendo crédito del servidor: $e - intentando cache local...');

      // Fallback: obtener del cache local
      try {
        final cachedCredit = await localDataSource.getCachedCredit(id);
        if (cachedCredit != null) {
          print('✅ Crédito cargado desde cache local');
          return Right(cachedCredit);
        }
        return Left(CacheFailure('Crédito no encontrado en cache local'));
      } catch (cacheError) {
        return Left(CacheFailure('Error al obtener crédito del cache: $cacheError'));
      }
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
    if (await networkInfo.isConnected) {
      try {
        final credit = await remoteDataSource.createCredit(dto);

        // Cache locally
        try {
          // credit is already a CustomerCredit, cast it to CustomerCreditModel for caching
          if (credit is CustomerCreditModel) {
            await localDataSource.cacheCredit(credit);
          }
        } catch (e) {
          print('Error al guardar crédito en cache: $e');
        }

        return Right(credit);
      } on ServerException catch (e) {
        print('⚠️ [CREDIT_REPO] ServerException en create: ${e.message} - Fallback offline...');
        return _createCreditOffline(dto);
      } on ConnectionException catch (e) {
        print('⚠️ [CREDIT_REPO] ConnectionException en create: ${e.message} - Fallback offline...');
        return _createCreditOffline(dto);
      } catch (e) {
        print('⚠️ [CREDIT_REPO] Exception en create: $e - Fallback offline...');
        return _createCreditOffline(dto);
      }
    } else {
      return _createCreditOffline(dto);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> addPayment(String creditId, AddCreditPaymentDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final credit = await remoteDataSource.addPayment(creditId, dto);

        // Update cache
        try {
          // credit is already a CustomerCredit, cast it to CustomerCreditModel for caching
          if (credit is CustomerCreditModel) {
            await localDataSource.cacheCredit(credit);
          }
        } catch (e) {
          print('Error al actualizar crédito en cache: $e');
        }

        return Right(credit);
      } on ServerException catch (e) {
        print('⚠️ [CREDIT_REPO] ServerException en addPayment: ${e.message} - Fallback offline...');
        return _addPaymentOffline(creditId, dto);
      } on ConnectionException catch (e) {
        print('⚠️ [CREDIT_REPO] ConnectionException en addPayment: ${e.message} - Fallback offline...');
        return _addPaymentOffline(creditId, dto);
      } catch (e) {
        print('⚠️ [CREDIT_REPO] Exception en addPayment: $e - Fallback offline...');
        return _addPaymentOffline(creditId, dto);
      }
    } else {
      return _addPaymentOffline(creditId, dto);
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
    // Intentar obtener del servidor
    try {
      final stats = await remoteDataSource.getCreditStats();
      return Right(stats);
    } catch (e) {
      print('⚠️ Error obteniendo estadísticas del servidor: $e - calculando desde cache local...');

      // Fallback: calcular desde cache local
      try {
        final cachedCredits = await localDataSource.getCachedCredits();

        // Calcular estadísticas desde los créditos en cache
        double totalPending = 0;
        double totalOverdue = 0;
        double totalPaid = 0;
        int countPending = 0;
        int countOverdue = 0;

        for (final credit in cachedCredits) {
          totalPaid += credit.paidAmount;

          if (credit.status == CreditStatus.pending) {
            countPending++;
            totalPending += credit.balanceDue;
          }

          if (credit.dueDate != null && credit.dueDate!.isBefore(DateTime.now()) && credit.balanceDue > 0) {
            countOverdue++;
            totalOverdue += credit.balanceDue;
          }
        }

        final stats = CreditStats(
          totalPending: totalPending,
          totalOverdue: totalOverdue,
          countPending: countPending,
          countOverdue: countOverdue,
          totalPaid: totalPaid,
        );

        print('✅ Estadísticas calculadas desde cache local');
        return Right(stats);
      } catch (cacheError) {
        return Left(CacheFailure('Error al calcular estadísticas del cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> deleteCredit(String creditId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCredit(creditId);

        // Remove from cache
        await localDataSource.removeCachedCredit(creditId);

        return const Right(null);
      } on ServerException catch (e) {
        print('⚠️ [CREDIT_REPO] ServerException en delete: ${e.message} - Fallback offline...');
        return _deleteCreditOffline(creditId);
      } on ConnectionException catch (e) {
        print('⚠️ [CREDIT_REPO] ConnectionException en delete: ${e.message} - Fallback offline...');
        return _deleteCreditOffline(creditId);
      } catch (e) {
        print('⚠️ [CREDIT_REPO] Exception en delete: $e - Fallback offline...');
        return _deleteCreditOffline(creditId);
      }
    } else {
      return _deleteCreditOffline(creditId);
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

  // ==================== OFFLINE OPERATIONS ====================

  /// Create customer credit offline (used as fallback when server fails or no connection)
  Future<Either<Failure, CustomerCredit>> _createCreditOffline(
    CreateCustomerCreditDto dto,
  ) async {
    print('📱 CustomerCreditRepository: Creating credit offline');
    try {
      final now = DateTime.now();
      final tempId = 'credit_offline_${now.millisecondsSinceEpoch}_${dto.customerId.hashCode}';

      // Parse dueDate from String to DateTime if provided
      DateTime? parsedDueDate;
      if (dto.dueDate != null) {
        try {
          parsedDueDate = DateTime.parse(dto.dueDate!);
        } catch (e) {
          print('⚠️ Error parsing dueDate: $e');
        }
      }

      // Get current user info for organizationId and createdById
      final authController = Get.find<AuthController>();
      final organizationId = authController.currentUser?.organizationId ?? '';
      final createdById = authController.currentUser?.id ?? '';

      // Create temporary credit entity
      final tempCredit = CustomerCreditModel(
        id: tempId,
        originalAmount: dto.originalAmount,
        paidAmount: 0.0,
        balanceDue: dto.originalAmount,
        status: CreditStatus.pending,
        dueDate: parsedDueDate,
        description: dto.description,
        notes: dto.notes,
        customerId: dto.customerId,
        customerName: null,
        invoiceId: dto.invoiceId,
        invoiceNumber: null,
        organizationId: organizationId,
        createdById: createdById,
        createdByName: authController.currentUser?.firstName,
        payments: null,
        createdAt: now,
        updatedAt: now,
      );

      // Cache locally
      await localDataSource.cacheCredit(tempCredit);

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'CustomerCredit',
          entityId: tempId,
          operationType: SyncOperationType.create,
          data: {
            'customerId': dto.customerId,
            'originalAmount': dto.originalAmount,
            'dueDate': dto.dueDate,
            'description': dto.description,
            'notes': dto.notes,
            'invoiceId': dto.invoiceId,
            'skipAutoBalance': dto.skipAutoBalance,
          },
          priority: 1,
        );
        print('📤 CustomerCreditRepository: Operation added to sync queue');
      } catch (e) {
        print('⚠️ Error adding to sync queue: $e');
      }

      print('✅ Customer credit created offline successfully');
      return Right(tempCredit);
    } catch (e) {
      print('❌ Error creating customer credit offline: $e');
      return Left(CacheFailure('Error al crear crédito offline: $e'));
    }
  }

  /// Add payment to credit offline (used as fallback when server fails or no connection)
  Future<Either<Failure, CustomerCredit>> _addPaymentOffline(
    String creditId,
    AddCreditPaymentDto dto,
  ) async {
    print('📱 CustomerCreditRepository: Adding payment offline: $creditId');
    try {
      // Get cached credit
      final cachedCredit = await localDataSource.getCachedCredit(creditId);
      if (cachedCredit == null) {
        return Left(CacheFailure('Crédito no encontrado en cache: $creditId'));
      }

      // Calculate new amounts
      final newPaidAmount = cachedCredit.paidAmount + dto.amount;
      final newBalanceDue = cachedCredit.originalAmount - newPaidAmount;
      final newStatus = newBalanceDue <= 0 ? CreditStatus.paid : CreditStatus.pending;

      // Update credit with payment (using copyWith-like approach)
      final updatedCredit = CustomerCreditModel(
        id: cachedCredit.id,
        originalAmount: cachedCredit.originalAmount,
        paidAmount: newPaidAmount,
        balanceDue: newBalanceDue,
        status: newStatus,
        dueDate: cachedCredit.dueDate,
        description: cachedCredit.description,
        notes: cachedCredit.notes,
        customerId: cachedCredit.customerId,
        customerName: cachedCredit.customerName,
        invoiceId: cachedCredit.invoiceId,
        invoiceNumber: cachedCredit.invoiceNumber,
        organizationId: cachedCredit.organizationId,
        createdById: cachedCredit.createdById,
        createdByName: cachedCredit.createdByName,
        payments: cachedCredit.payments,
        createdAt: cachedCredit.createdAt,
        updatedAt: DateTime.now(),
        deletedAt: cachedCredit.deletedAt,
      );

      // Update cache
      await localDataSource.cacheCredit(updatedCredit);

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'CustomerCredit',
          entityId: creditId,
          operationType: SyncOperationType.update,
          data: {
            'action': 'addPayment',
            'amount': dto.amount,
            'paymentMethod': dto.paymentMethod,
            'paymentDate': dto.paymentDate,
            'reference': dto.reference,
            'notes': dto.notes,
            'bankAccountId': dto.bankAccountId,
          },
          priority: 1,
        );
        print('📤 Payment operation added to sync queue');
      } catch (e) {
        print('⚠️ Error adding to sync queue: $e');
      }

      print('✅ Payment added offline successfully');
      return Right(updatedCredit);
    } catch (e) {
      print('❌ Error adding payment offline: $e');
      return Left(CacheFailure('Error al agregar pago offline: $e'));
    }
  }

  /// Delete customer credit offline (used as fallback when server fails or no connection)
  Future<Either<Failure, void>> _deleteCreditOffline(String creditId) async {
    print('📱 CustomerCreditRepository: Deleting credit offline: $creditId');
    try {
      // Remove from cache
      await localDataSource.removeCachedCredit(creditId);

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'CustomerCredit',
          entityId: creditId,
          operationType: SyncOperationType.delete,
          data: {'id': creditId},
          priority: 1,
        );
        print('📤 Delete operation added to sync queue');
      } catch (e) {
        print('⚠️ Error adding to sync queue: $e');
      }

      print('✅ Customer credit deleted offline successfully');
      return const Right(null);
    } catch (e) {
      print('❌ Error deleting customer credit offline: $e');
      return Left(CacheFailure('Error al eliminar crédito offline: $e'));
    }
  }
}
