// lib/features/customer_credits/data/repositories/customer_credit_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/customer_credit.dart';
import '../../domain/repositories/customer_credit_repository.dart';
import '../datasources/customer_credit_local_datasource.dart';
import '../datasources/customer_credit_remote_datasource.dart';
import '../models/customer_credit_model.dart';
import '../../../invoices/data/models/isar/isar_invoice.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/domain/entities/invoice_payment.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart' show IsarInvoiceStatus;

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

  /// Helper para detectar errores de timeout/conexión
  bool _isTimeoutError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('timeout') || msg.contains('tiempo') ||
        msg.contains('socketexception') || msg.contains('conexión') ||
        msg.contains('connection') || error is ConnectionException;
  }

  @override
  Future<Either<Failure, List<CustomerCredit>>> getCredits(CustomerCreditQueryParams? query) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final credits = await remoteDataSource.getCredits(query);
        // ✅ Resetear estado de conectividad
        networkInfo.resetServerReachability();
        // Cachear en local
        await localDataSource.cacheCredits(credits.cast<CustomerCreditModel>());
        return Right(credits);
      } catch (e) {
        AppLogger.w('Error obteniendo créditos del servidor: $e - intentando cache local...', tag: 'CREDIT');
        // ✅ Marcar servidor como no alcanzable si es timeout
        if (_isTimeoutError(e)) {
          networkInfo.markServerUnreachable();
        }
        return _getCreditsFromCache();
      }
    } else {
      AppLogger.d('📴 Sin conexión, cargando créditos desde cache local...', tag: 'CREDIT');
      return _getCreditsFromCache();
    }
  }

  /// Obtener créditos desde cache local (ISAR)
  Future<Either<Failure, List<CustomerCredit>>> _getCreditsFromCache() async {
    try {
      final cachedCredits = await localDataSource.getCachedCredits();
      if (cachedCredits.isNotEmpty) {
        AppLogger.i('Créditos cargados desde cache local (${cachedCredits.length} registros)', tag: 'CREDIT');
        return Right(cachedCredits);
      }
      return const Right(<CustomerCredit>[]);
    } catch (cacheError) {
      AppLogger.w('Error al obtener créditos del cache: $cacheError', tag: 'CREDIT');
      return const Right(<CustomerCredit>[]);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> getCreditById(String id) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final credit = await remoteDataSource.getCreditById(id);
        networkInfo.resetServerReachability();
        await localDataSource.cacheCredit(credit as CustomerCreditModel);
        return Right(credit);
      } catch (e) {
        AppLogger.w('Error obteniendo crédito del servidor: $e - intentando cache local...', tag: 'CREDIT');
        if (_isTimeoutError(e)) {
          networkInfo.markServerUnreachable();
        }
        return _getCreditFromCache(id);
      }
    } else {
      return _getCreditFromCache(id);
    }
  }

  Future<Either<Failure, CustomerCredit>> _getCreditFromCache(String id) async {
    try {
      final cachedCredit = await localDataSource.getCachedCredit(id);
      if (cachedCredit != null) {
        AppLogger.i('Crédito cargado desde cache local', tag: 'CREDIT');
        return Right(cachedCredit);
      }
      return Left(CacheFailure('Crédito no encontrado en cache local'));
    } catch (cacheError) {
      return Left(CacheFailure('Error al obtener crédito del cache: $cacheError'));
    }
  }

  @override
  Future<Either<Failure, List<CustomerCredit>>> getCreditsByCustomer(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final credits = await remoteDataSource.getCreditsByCustomer(customerId);
        networkInfo.resetServerReachability();
        return Right(credits);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        // Fallback: filtrar desde cache local
        return _getCreditsByCustomerFromCache(customerId);
      }
    } else {
      return _getCreditsByCustomerFromCache(customerId);
    }
  }

  Future<Either<Failure, List<CustomerCredit>>> _getCreditsByCustomerFromCache(String customerId) async {
    try {
      final cachedCredits = await localDataSource.getCachedCredits();
      final filtered = cachedCredits.where((c) => c.customerId == customerId).toList();
      AppLogger.d('Cache: ${filtered.length} créditos del cliente $customerId', tag: 'CREDIT');
      return Right(filtered);
    } catch (e) {
      return const Right(<CustomerCredit>[]);
    }
  }

  @override
  Future<Either<Failure, List<CustomerCredit>>> getPendingCreditsByCustomer(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final credits = await remoteDataSource.getPendingCreditsByCustomer(customerId);
        networkInfo.resetServerReachability();
        return Right(credits);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        return _getPendingCreditsByCustomerFromCache(customerId);
      }
    } else {
      return _getPendingCreditsByCustomerFromCache(customerId);
    }
  }

  Future<Either<Failure, List<CustomerCredit>>> _getPendingCreditsByCustomerFromCache(String customerId) async {
    try {
      final cachedCredits = await localDataSource.getCachedCredits();
      final filtered = cachedCredits.where((c) =>
        c.customerId == customerId &&
        (c.status == CreditStatus.pending || c.status == CreditStatus.partiallyPaid)
      ).toList();
      return Right(filtered);
    } catch (e) {
      return const Right(<CustomerCredit>[]);
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
          AppLogger.w('Error al guardar crédito en cache: $e', tag: 'CREDIT');
        }

        return Right(credit);
      } on ServerException catch (e) {
        AppLogger.w('[CREDIT_REPO] ServerException en create: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _createCreditOffline(dto);
      } on ConnectionException catch (e) {
        AppLogger.w('[CREDIT_REPO] ConnectionException en create: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _createCreditOffline(dto);
      } catch (e) {
        AppLogger.w('[CREDIT_REPO] Exception en create: $e - Fallback offline...', tag: 'CREDIT');
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
          AppLogger.w('Error al actualizar crédito en cache: $e', tag: 'CREDIT');
        }

        return Right(credit);
      } on ServerException catch (e) {
        AppLogger.w('[CREDIT_REPO] ServerException en addPayment: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _addPaymentOffline(creditId, dto);
      } on ConnectionException catch (e) {
        AppLogger.w('[CREDIT_REPO] ConnectionException en addPayment: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _addPaymentOffline(creditId, dto);
      } catch (e) {
        AppLogger.w('[CREDIT_REPO] Exception en addPayment: $e - Fallback offline...', tag: 'CREDIT');
        return _addPaymentOffline(creditId, dto);
      }
    } else {
      return _addPaymentOffline(creditId, dto);
    }
  }

  @override
  Future<Either<Failure, List<CreditPayment>>> getCreditPayments(String creditId) async {
    if (await networkInfo.isConnected) {
      try {
        final payments = await remoteDataSource.getCreditPayments(creditId);
        networkInfo.resetServerReachability();
        return Right(payments);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo pagos: $e - intentando cache...', tag: 'CREDIT');
        return _getCreditPaymentsFromCache(creditId);
      }
    } else {
      return _getCreditPaymentsFromCache(creditId);
    }
  }

  /// Obtener pagos desde el crédito cacheado localmente
  Future<Either<Failure, List<CreditPayment>>> _getCreditPaymentsFromCache(String creditId) async {
    try {
      final cachedCredit = await localDataSource.getCachedCredit(creditId);
      if (cachedCredit != null && cachedCredit.payments != null) {
        AppLogger.d('Pagos obtenidos desde cache (${cachedCredit.payments!.length})', tag: 'CREDIT');
        return Right(cachedCredit.payments!);
      }
      return const Right(<CreditPayment>[]);
    } catch (e) {
      return const Right(<CreditPayment>[]);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> cancelCredit(String creditId) async {
    if (await networkInfo.isConnected) {
      try {
        final credit = await remoteDataSource.cancelCredit(creditId);
        networkInfo.resetServerReachability();
        if (credit is CustomerCreditModel) {
          await localDataSource.cacheCredit(credit);
        }
        return Right(credit);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en cancelCredit: $e - Fallback offline...', tag: 'CREDIT');
        return _cancelCreditOffline(creditId);
      }
    } else {
      return _cancelCreditOffline(creditId);
    }
  }

  @override
  Future<Either<Failure, int>> markOverdueCredits() async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.markOverdueCredits();
        networkInfo.resetServerReachability();
        return Right(count);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        // Calcular localmente desde cache
        return _markOverdueCreditsLocally();
      }
    } else {
      return _markOverdueCreditsLocally();
    }
  }

  @override
  Future<Either<Failure, CreditStats>> getCreditStats() async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final stats = await remoteDataSource.getCreditStats();
        networkInfo.resetServerReachability();
        return Right(stats);
      } catch (e) {
        AppLogger.w('Error obteniendo estadísticas del servidor: $e - calculando desde cache local...', tag: 'CREDIT');
        if (_isTimeoutError(e)) {
          networkInfo.markServerUnreachable();
        }
        return _getStatsFromCache();
      }
    } else {
      AppLogger.d('📴 Sin conexión, calculando stats desde cache...', tag: 'CREDIT');
      return _getStatsFromCache();
    }
  }

  /// Calcular estadísticas desde créditos en cache local con desglose por tipo
  /// Consistente con el backend: totalPaid = originalAmount de créditos PAID
  Future<Either<Failure, CreditStats>> _getStatsFromCache() async {
    try {
      final cachedCredits = await localDataSource.getCachedCredits();

      double totalPending = 0, totalOverdue = 0, totalPaid = 0;
      int countPending = 0, countOverdue = 0;
      double directPending = 0, directOverdue = 0, directPaid = 0;
      double invoicePending = 0, invoiceOverdue = 0, invoicePaid = 0;
      int directCountPending = 0, directCountOverdue = 0;
      int invoiceCountPending = 0, invoiceCountOverdue = 0;

      for (final credit in cachedCredits) {
        final isInvoice = credit.invoiceId != null && credit.invoiceId!.isNotEmpty;

        if (credit.status == CreditStatus.paid) {
          totalPaid += credit.originalAmount;
          if (isInvoice) { invoicePaid += credit.originalAmount; }
          else { directPaid += credit.originalAmount; }
          continue;
        }

        if (credit.status == CreditStatus.cancelled) continue;

        // Verificar overdue: status explícito O fecha vencida con saldo pendiente
        if ((credit.status == CreditStatus.overdue) ||
            (credit.dueDate != null && credit.dueDate!.isBefore(DateTime.now()) && credit.balanceDue > 0)) {
          countOverdue++;
          totalOverdue += credit.balanceDue;
          if (isInvoice) { invoiceOverdue += credit.balanceDue; invoiceCountOverdue++; }
          else { directOverdue += credit.balanceDue; directCountOverdue++; }
        } else if (credit.status == CreditStatus.pending || credit.status == CreditStatus.partiallyPaid) {
          countPending++;
          totalPending += credit.balanceDue;
          if (isInvoice) { invoicePending += credit.balanceDue; invoiceCountPending++; }
          else { directPending += credit.balanceDue; directCountPending++; }
        }
      }

      final stats = CreditStats(
        totalPending: totalPending,
        totalOverdue: totalOverdue,
        countPending: countPending,
        countOverdue: countOverdue,
        totalPaid: totalPaid,
        directPending: directPending,
        directOverdue: directOverdue,
        directPaid: directPaid,
        directCountPending: directCountPending,
        directCountOverdue: directCountOverdue,
        invoicePending: invoicePending,
        invoiceOverdue: invoiceOverdue,
        invoicePaid: invoicePaid,
        invoiceCountPending: invoiceCountPending,
        invoiceCountOverdue: invoiceCountOverdue,
      );

      AppLogger.i('Estadísticas calculadas desde cache local (${cachedCredits.length} créditos)', tag: 'CREDIT');
      return Right(stats);
    } catch (cacheError) {
      // Retornar stats vacías en vez de error
      return Right(CreditStats(
        totalPending: 0, totalOverdue: 0,
        countPending: 0, countOverdue: 0, totalPaid: 0,
      ));
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
        AppLogger.w('[CREDIT_REPO] ServerException en delete: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _deleteCreditOffline(creditId);
      } on ConnectionException catch (e) {
        AppLogger.w('[CREDIT_REPO] ConnectionException en delete: ${e.message} - Fallback offline...', tag: 'CREDIT');
        return _deleteCreditOffline(creditId);
      } catch (e) {
        AppLogger.w('[CREDIT_REPO] Exception en delete: $e - Fallback offline...', tag: 'CREDIT');
        return _deleteCreditOffline(creditId);
      }
    } else {
      return _deleteCreditOffline(creditId);
    }
  }

  // ==================== CREDIT TRANSACTIONS ====================

  @override
  Future<Either<Failure, List<CreditTransactionModel>>> getCreditTransactions(String creditId) async {
    if (await networkInfo.isConnected) {
      try {
        final transactions = await remoteDataSource.getCreditTransactions(creditId);
        networkInfo.resetServerReachability();
        return Right(transactions);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo transacciones: $e - retornando lista vacía', tag: 'CREDIT');
        return const Right(<CreditTransactionModel>[]);
      }
    } else {
      AppLogger.d('📴 Sin conexión, retornando transacciones vacías', tag: 'CREDIT');
      return const Right(<CreditTransactionModel>[]);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> addAmountToCredit(String creditId, AddAmountToCreditDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final credit = await remoteDataSource.addAmountToCredit(creditId, dto);
        networkInfo.resetServerReachability();
        // Actualizar cache local
        if (credit is CustomerCreditModel) {
          await localDataSource.cacheCredit(credit);
        }
        return Right(credit);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en addAmountToCredit: $e - Fallback offline...', tag: 'CREDIT');
        return _addAmountToCreditOffline(creditId, dto);
      }
    } else {
      return _addAmountToCreditOffline(creditId, dto);
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> applyBalanceToCredit(String creditId, ApplyBalanceToCreditDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final credit = await remoteDataSource.applyBalanceToCredit(creditId, dto);
        networkInfo.resetServerReachability();
        if (credit is CustomerCreditModel) {
          await localDataSource.cacheCredit(credit);
        }
        return Right(credit);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en applyBalanceToCredit: $e - Fallback offline...', tag: 'CREDIT');
        return _applyBalanceToCreditOffline(creditId, dto);
      }
    } else {
      return _applyBalanceToCreditOffline(creditId, dto);
    }
  }

  // ==================== CLIENT BALANCE ====================

  @override
  Future<Either<Failure, List<ClientBalanceModel>>> getAllClientBalances() async {
    if (await networkInfo.isConnected) {
      try {
        final balances = await remoteDataSource.getAllClientBalances();
        networkInfo.resetServerReachability();
        return Right(balances);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo saldos: $e - retornando lista vacía', tag: 'CREDIT');
        return const Right(<ClientBalanceModel>[]);
      }
    } else {
      return const Right(<ClientBalanceModel>[]);
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel?>> getClientBalance(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await remoteDataSource.getClientBalance(customerId);
        networkInfo.resetServerReachability();
        return Right(balance);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo saldo del cliente: $e - retornando null', tag: 'CREDIT');
        return const Right(null);
      }
    } else {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, List<ClientBalanceTransactionModel>>> getClientBalanceTransactions(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final transactions = await remoteDataSource.getClientBalanceTransactions(customerId);
        networkInfo.resetServerReachability();
        return Right(transactions);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo transacciones de saldo: $e - retornando lista vacía', tag: 'CREDIT');
        return const Right(<ClientBalanceTransactionModel>[]);
      }
    } else {
      return const Right(<ClientBalanceTransactionModel>[]);
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> depositBalance(DepositBalanceDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await remoteDataSource.depositBalance(dto);
        networkInfo.resetServerReachability();
        return Right(balance);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en depositBalance: $e - Fallback offline...', tag: 'CREDIT');
        return _depositBalanceOffline(dto);
      }
    } else {
      return _depositBalanceOffline(dto);
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> useBalance(UseBalanceDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await remoteDataSource.useBalance(dto);
        networkInfo.resetServerReachability();
        return Right(balance);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en useBalance: $e - Fallback offline...', tag: 'CREDIT');
        return _useBalanceOffline(dto);
      }
    } else {
      return _useBalanceOffline(dto);
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> refundBalance(RefundBalanceDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await remoteDataSource.refundBalance(dto);
        networkInfo.resetServerReachability();
        return Right(balance);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en refundBalance: $e - Fallback offline...', tag: 'CREDIT');
        return _refundBalanceOffline(dto);
      }
    } else {
      return _refundBalanceOffline(dto);
    }
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> adjustBalance(AdjustBalanceDto dto) async {
    if (await networkInfo.isConnected) {
      try {
        final balance = await remoteDataSource.adjustBalance(dto);
        networkInfo.resetServerReachability();
        return Right(balance);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('[CREDIT_REPO] Error en adjustBalance: $e - Fallback offline...', tag: 'CREDIT');
        return _adjustBalanceOffline(dto);
      }
    } else {
      return _adjustBalanceOffline(dto);
    }
  }

  // ==================== CUSTOMER ACCOUNT ====================

  @override
  Future<Either<Failure, CustomerAccountModel>> getCustomerAccount(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final account = await remoteDataSource.getCustomerAccount(customerId);
        networkInfo.resetServerReachability();
        return Right(account);
      } catch (e) {
        if (_isTimeoutError(e)) networkInfo.markServerUnreachable();
        AppLogger.w('Error obteniendo cuenta corriente: $e - construyendo desde cache...', tag: 'CREDIT');
        return _getCustomerAccountFromCache(customerId);
      }
    } else {
      AppLogger.d('📴 Sin conexión, construyendo cuenta corriente desde cache...', tag: 'CREDIT');
      return _getCustomerAccountFromCache(customerId);
    }
  }

  // ==================== SYNC QUEUE HELPER ====================

  /// Helper para agregar operaciones a la cola de sincronización de forma segura
  /// Usa addOperation directamente con organizationId del AuthController o del crédito
  Future<void> _addToSyncQueue({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    String? fallbackOrganizationId,
    int priority = 1,
  }) async {
    try {
      final syncService = Get.find<SyncService>();
      final authController = Get.find<AuthController>();

      // Obtener organizationId: primero del usuario, luego del fallback
      String organizationId = authController.currentUser?.organizationId ?? '';
      if (organizationId.isEmpty && fallbackOrganizationId != null) {
        organizationId = fallbackOrganizationId;
      }

      if (organizationId.isEmpty) {
        AppLogger.w('No se pudo obtener organizationId para sync queue', tag: 'CREDIT');
        return;
      }

      await syncService.addOperation(
        entityType: entityType,
        entityId: entityId,
        operationType: operationType,
        data: data,
        organizationId: organizationId,
        priority: priority,
      );
      AppLogger.d('Operación $operationType agregada a sync queue: $entityType/$entityId', tag: 'CREDIT');
    } catch (e) {
      AppLogger.w('Error adding to sync queue: $e', tag: 'CREDIT');
    }
  }

  // ==================== OFFLINE OPERATIONS ====================

  /// Create customer credit offline (used as fallback when server fails or no connection)
  Future<Either<Failure, CustomerCredit>> _createCreditOffline(
    CreateCustomerCreditDto dto,
  ) async {
    AppLogger.d('CustomerCreditRepository: Creating credit offline', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final now = DateTime.now();
      final tempId = 'customercredit_offline_${now.millisecondsSinceEpoch}_${dto.customerId.hashCode}';

      // Parse dueDate from String to DateTime if provided
      DateTime? parsedDueDate;
      if (dto.dueDate != null) {
        try {
          parsedDueDate = DateTime.parse(dto.dueDate!);
        } catch (e) {
          AppLogger.w('Error parsing dueDate: $e', tag: 'CREDIT');
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
      await _addToSyncQueue(
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
        fallbackOrganizationId: organizationId,
      );

      AppLogger.i('Customer credit created offline successfully', tag: 'CREDIT');
      return Right(tempCredit);
    } catch (e) {
      AppLogger.e('Error creating customer credit offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al crear crédito offline: $e'));
    }
  }

  /// Add payment to credit offline (used as fallback when server fails or no connection)
  Future<Either<Failure, CustomerCredit>> _addPaymentOffline(
    String creditId,
    AddCreditPaymentDto dto,
  ) async {
    AppLogger.d('CustomerCreditRepository: Adding payment offline: $creditId', tag: 'CREDIT');
    // Asegurar que el cooldown quede activo para evitar timeouts en lecturas posteriores
    networkInfo.markServerUnreachable();
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
      await _addToSyncQueue(
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
        fallbackOrganizationId: cachedCredit.organizationId,
      );

      // ✅ Cross-update: actualizar factura asociada en ISAR
      if (cachedCredit.invoiceId != null && cachedCredit.invoiceId!.isNotEmpty) {
        await _crossUpdateInvoiceFromCreditPayment(
          invoiceId: cachedCredit.invoiceId!,
          paymentAmount: dto.amount,
          paymentMethod: dto.paymentMethod,
        );
      }

      AppLogger.i('Payment added offline successfully', tag: 'CREDIT');
      return Right(updatedCredit);
    } catch (e) {
      AppLogger.e('Error adding payment offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al agregar pago offline: $e'));
    }
  }

  /// Cross-update: actualizar factura en ISAR cuando se paga un crédito asociado.
  /// NO encola a sync queue - el backend maneja la cross-update.
  Future<void> _crossUpdateInvoiceFromCreditPayment({
    required String invoiceId,
    required double paymentAmount,
    required String paymentMethod,
  }) async {
    try {
      final isar = IsarDatabase.instance.database;
      final isarInvoice = await isar.isarInvoices
          .filter()
          .serverIdEqualTo(invoiceId)
          .findFirst();

      if (isarInvoice == null) {
        AppLogger.d('CustomerCreditRepo: No hay factura asociada en ISAR: $invoiceId', tag: 'CREDIT');
        return;
      }

      final now = DateTime.now();
      final newPaidAmount = isarInvoice.paidAmount + paymentAmount;
      final newBalanceDue = (isarInvoice.total - newPaidAmount).clamp(0.0, double.infinity);

      // Actualizar status
      if (newBalanceDue <= 0) {
        isarInvoice.status = IsarInvoiceStatus.paid;
      } else if (newPaidAmount > 0) {
        isarInvoice.status = IsarInvoiceStatus.partiallyPaid;
      }

      isarInvoice.paidAmount = newPaidAmount;
      isarInvoice.balanceDue = newBalanceDue;
      isarInvoice.updatedAt = now;

      // Append payment al paymentsJson
      final existingPayments = IsarInvoice.decodePayments(isarInvoice.paymentsJson);
      String createdById = '';
      String organizationId = '';
      try {
        final authController = Get.find<AuthController>();
        if (authController.currentUser != null) {
          createdById = authController.currentUser!.id;
          organizationId = authController.currentUser!.organizationId;
        }
      } catch (_) {}

      existingPayments.add(InvoicePayment(
        id: 'payment_credit_${now.millisecondsSinceEpoch}_${invoiceId.hashCode}',
        amount: paymentAmount,
        paymentMethod: PaymentMethod.fromString(paymentMethod),
        paymentDate: now,
        reference: 'Pago desde crédito',
        notes: 'Pago registrado desde pantalla de créditos (offline)',
        invoiceId: invoiceId,
        createdById: createdById,
        organizationId: organizationId,
        createdAt: now,
        updatedAt: now,
      ));

      isarInvoice.paymentsJson = IsarInvoice.encodePayments(existingPayments);

      await isar.writeTxn(() async {
        await isar.isarInvoices.put(isarInvoice);
      });

      AppLogger.i(
        'CustomerCreditRepo: Factura $invoiceId cross-updated: paidAmount=\$$newPaidAmount, balanceDue=\$$newBalanceDue',
        tag: 'CREDIT',
      );
    } catch (e) {
      AppLogger.w('CustomerCreditRepo: Error en cross-update factura: $e', tag: 'CREDIT');
    }
  }

  /// Agregar monto a crédito offline
  Future<Either<Failure, CustomerCredit>> _addAmountToCreditOffline(
    String creditId,
    AddAmountToCreditDto dto,
  ) async {
    AppLogger.d('CustomerCreditRepository: Adding amount offline: $creditId', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final cachedCredit = await localDataSource.getCachedCredit(creditId);
      if (cachedCredit == null) {
        return Left(CacheFailure('Crédito no encontrado en cache: $creditId'));
      }

      // Actualizar montos localmente
      final newOriginalAmount = cachedCredit.originalAmount + dto.amount;
      final newBalanceDue = cachedCredit.balanceDue + dto.amount;
      final newStatus = newBalanceDue > 0
          ? (cachedCredit.paidAmount > 0 ? CreditStatus.partiallyPaid : CreditStatus.pending)
          : CreditStatus.paid;

      final updatedCredit = CustomerCreditModel(
        id: cachedCredit.id,
        originalAmount: newOriginalAmount,
        paidAmount: cachedCredit.paidAmount,
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

      await localDataSource.cacheCredit(updatedCredit);

      // Encolar para sincronización
      await _addToSyncQueue(
        entityType: 'CustomerCredit',
        entityId: creditId,
        operationType: SyncOperationType.update,
        data: {
          'action': 'addAmount',
          'creditId': creditId,
          'amount': dto.amount,
          'description': dto.description,
        },
        fallbackOrganizationId: cachedCredit.organizationId,
      );

      AppLogger.i('Amount added offline successfully', tag: 'CREDIT');
      return Right(updatedCredit);
    } catch (e) {
      AppLogger.e('Error adding amount offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al agregar monto offline: $e'));
    }
  }

  /// Aplicar saldo a favor a crédito offline
  Future<Either<Failure, CustomerCredit>> _applyBalanceToCreditOffline(
    String creditId,
    ApplyBalanceToCreditDto dto,
  ) async {
    AppLogger.d('CustomerCreditRepository: Applying balance offline: $creditId', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final cachedCredit = await localDataSource.getCachedCredit(creditId);
      if (cachedCredit == null) {
        return Left(CacheFailure('Crédito no encontrado en cache: $creditId'));
      }

      final amountToApply = dto.amount ?? cachedCredit.balanceDue;
      final newPaidAmount = cachedCredit.paidAmount + amountToApply;
      final newBalanceDue = cachedCredit.originalAmount - newPaidAmount;
      final newStatus = newBalanceDue <= 0 ? CreditStatus.paid : CreditStatus.partiallyPaid;

      final updatedCredit = CustomerCreditModel(
        id: cachedCredit.id,
        originalAmount: cachedCredit.originalAmount,
        paidAmount: newPaidAmount,
        balanceDue: newBalanceDue < 0 ? 0 : newBalanceDue,
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

      await localDataSource.cacheCredit(updatedCredit);

      await _addToSyncQueue(
        entityType: 'CustomerCredit',
        entityId: creditId,
        operationType: SyncOperationType.update,
        data: {
          'action': 'applyBalance',
          'creditId': creditId,
          'amount': dto.amount,
        },
        fallbackOrganizationId: cachedCredit.organizationId,
      );

      AppLogger.i('Balance applied offline successfully', tag: 'CREDIT');
      return Right(updatedCredit);
    } catch (e) {
      AppLogger.e('Error applying balance offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al aplicar saldo offline: $e'));
    }
  }

  /// Cancelar crédito offline
  Future<Either<Failure, CustomerCredit>> _cancelCreditOffline(String creditId) async {
    AppLogger.d('CustomerCreditRepository: Cancelling credit offline: $creditId', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final cachedCredit = await localDataSource.getCachedCredit(creditId);
      if (cachedCredit == null) {
        return Left(CacheFailure('Crédito no encontrado en cache: $creditId'));
      }

      final updatedCredit = CustomerCreditModel(
        id: cachedCredit.id,
        originalAmount: cachedCredit.originalAmount,
        paidAmount: cachedCredit.paidAmount,
        balanceDue: cachedCredit.balanceDue,
        status: CreditStatus.cancelled,
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

      await localDataSource.cacheCredit(updatedCredit);

      await _addToSyncQueue(
        entityType: 'CustomerCredit',
        entityId: creditId,
        operationType: SyncOperationType.update,
        data: {
          'action': 'cancel',
          'creditId': creditId,
        },
        fallbackOrganizationId: cachedCredit.organizationId,
      );

      AppLogger.i('Credit cancelled offline successfully', tag: 'CREDIT');
      return Right(updatedCredit);
    } catch (e) {
      AppLogger.e('Error cancelling credit offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al cancelar crédito offline: $e'));
    }
  }

  /// Marcar créditos vencidos localmente
  Future<Either<Failure, int>> _markOverdueCreditsLocally() async {
    try {
      final cachedCredits = await localDataSource.getCachedCredits();
      final now = DateTime.now();
      int count = 0;

      for (final credit in cachedCredits) {
        if (credit.dueDate != null &&
            credit.dueDate!.isBefore(now) &&
            credit.balanceDue > 0 &&
            credit.status != CreditStatus.overdue &&
            credit.status != CreditStatus.cancelled &&
            credit.status != CreditStatus.paid) {
          count++;
        }
      }

      AppLogger.d('Créditos vencidos calculados localmente: $count', tag: 'CREDIT');
      return Right(count);
    } catch (e) {
      return const Right(0);
    }
  }

  /// Depositar saldo offline
  Future<Either<Failure, ClientBalanceModel>> _depositBalanceOffline(DepositBalanceDto dto) async {
    AppLogger.d('CustomerCreditRepository: Depositing balance offline', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final authController = Get.find<AuthController>();
      final now = DateTime.now();
      final tempBalance = ClientBalanceModel(
        id: 'balance_offline_${now.millisecondsSinceEpoch}',
        balance: dto.amount,
        customerId: dto.customerId,
        organizationId: authController.currentUser?.organizationId ?? '',
        createdById: authController.currentUser?.id ?? '',
        createdAt: now,
        updatedAt: now,
      );

      await _addToSyncQueue(
        entityType: 'ClientBalance',
        entityId: dto.customerId,
        operationType: SyncOperationType.create,
        data: {
          'action': 'deposit',
          'customerId': dto.customerId,
          'amount': dto.amount,
          'description': dto.description,
          'relatedCreditId': dto.relatedCreditId,
        },
        fallbackOrganizationId: authController.currentUser?.organizationId,
      );

      AppLogger.i('Balance deposited offline successfully', tag: 'CREDIT');
      return Right(tempBalance);
    } catch (e) {
      return Left(CacheFailure('Error al depositar saldo offline: $e'));
    }
  }

  /// Usar saldo offline
  Future<Either<Failure, ClientBalanceModel>> _useBalanceOffline(UseBalanceDto dto) async {
    AppLogger.d('CustomerCreditRepository: Using balance offline', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final authController = Get.find<AuthController>();
      final now = DateTime.now();
      final tempBalance = ClientBalanceModel(
        id: 'balance_offline_${now.millisecondsSinceEpoch}',
        balance: 0,
        customerId: dto.clientId,
        organizationId: authController.currentUser?.organizationId ?? '',
        createdById: authController.currentUser?.id ?? '',
        createdAt: now,
        updatedAt: now,
      );

      await _addToSyncQueue(
        entityType: 'ClientBalance',
        entityId: dto.clientId,
        operationType: SyncOperationType.update,
        data: {
          'action': 'use',
          'clientId': dto.clientId,
          'amount': dto.amount,
          'description': dto.description,
          'relatedCreditId': dto.relatedCreditId,
        },
        fallbackOrganizationId: authController.currentUser?.organizationId,
      );

      AppLogger.i('Balance used offline successfully', tag: 'CREDIT');
      return Right(tempBalance);
    } catch (e) {
      return Left(CacheFailure('Error al usar saldo offline: $e'));
    }
  }

  /// Reembolsar saldo offline
  Future<Either<Failure, ClientBalanceModel>> _refundBalanceOffline(RefundBalanceDto dto) async {
    AppLogger.d('CustomerCreditRepository: Refunding balance offline', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final authController = Get.find<AuthController>();
      final now = DateTime.now();
      final tempBalance = ClientBalanceModel(
        id: 'balance_offline_${now.millisecondsSinceEpoch}',
        balance: 0,
        customerId: dto.clientId,
        organizationId: authController.currentUser?.organizationId ?? '',
        createdById: authController.currentUser?.id ?? '',
        createdAt: now,
        updatedAt: now,
      );

      await _addToSyncQueue(
        entityType: 'ClientBalance',
        entityId: dto.clientId,
        operationType: SyncOperationType.update,
        data: {
          'action': 'refund',
          'clientId': dto.clientId,
          'amount': dto.amount,
          'description': dto.description,
          'paymentMethod': dto.paymentMethod,
        },
        fallbackOrganizationId: authController.currentUser?.organizationId,
      );

      AppLogger.i('Balance refunded offline successfully', tag: 'CREDIT');
      return Right(tempBalance);
    } catch (e) {
      return Left(CacheFailure('Error al reembolsar saldo offline: $e'));
    }
  }

  /// Ajustar saldo offline
  Future<Either<Failure, ClientBalanceModel>> _adjustBalanceOffline(AdjustBalanceDto dto) async {
    AppLogger.d('CustomerCreditRepository: Adjusting balance offline', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      final authController = Get.find<AuthController>();
      final now = DateTime.now();
      final tempBalance = ClientBalanceModel(
        id: 'balance_offline_${now.millisecondsSinceEpoch}',
        balance: dto.amount,
        customerId: dto.clientId,
        organizationId: authController.currentUser?.organizationId ?? '',
        createdById: authController.currentUser?.id ?? '',
        createdAt: now,
        updatedAt: now,
      );

      await _addToSyncQueue(
        entityType: 'ClientBalance',
        entityId: dto.clientId,
        operationType: SyncOperationType.update,
        data: {
          'action': 'adjust',
          'clientId': dto.clientId,
          'amount': dto.amount,
          'description': dto.description,
        },
        fallbackOrganizationId: authController.currentUser?.organizationId,
      );

      AppLogger.i('Balance adjusted offline successfully', tag: 'CREDIT');
      return Right(tempBalance);
    } catch (e) {
      return Left(CacheFailure('Error al ajustar saldo offline: $e'));
    }
  }

  /// Construir cuenta corriente desde cache local
  Future<Either<Failure, CustomerAccountModel>> _getCustomerAccountFromCache(String customerId) async {
    try {
      final cachedCredits = await localDataSource.getCachedCredits();
      final customerCredits = cachedCredits.where((c) => c.customerId == customerId).toList();

      // Separar créditos por tipo
      final invoiceCredits = customerCredits
          .where((c) => c.invoiceId != null && c.invoiceId!.isNotEmpty)
          .cast<CustomerCreditModel>()
          .toList();
      final directCredits = customerCredits
          .where((c) => c.invoiceId == null || c.invoiceId!.isEmpty)
          .cast<CustomerCreditModel>()
          .toList();

      // Calcular deudas
      double invoiceDebt = 0;
      double directDebt = 0;
      for (final c in invoiceCredits) {
        if (c.status != CreditStatus.cancelled && c.status != CreditStatus.paid) {
          invoiceDebt += c.balanceDue;
        }
      }
      for (final c in directCredits) {
        if (c.status != CreditStatus.cancelled && c.status != CreditStatus.paid) {
          directDebt += c.balanceDue;
        }
      }

      final totalDebt = invoiceDebt + directDebt;
      final customerName = customerCredits.isNotEmpty ? (customerCredits.first.customerName ?? '') : '';

      final account = CustomerAccountModel(
        customer: CustomerAccountCustomer(
          id: customerId,
          name: customerName,
          currentBalance: 0,
        ),
        summary: CustomerAccountSummary(
          totalDebt: totalDebt,
          invoiceDebt: invoiceDebt,
          directCreditDebt: directDebt,
          availableBalance: 0,
          netBalance: -totalDebt,
        ),
        invoiceCredits: invoiceCredits,
        directCredits: directCredits,
        clientBalance: const CustomerAccountBalance(balance: 0),
      );

      AppLogger.i('Cuenta corriente construida desde cache (${customerCredits.length} créditos)', tag: 'CREDIT');
      return Right(account);
    } catch (e) {
      AppLogger.w('Error construyendo cuenta corriente desde cache: $e', tag: 'CREDIT');
      // Retornar cuenta vacía en vez de error
      return Right(CustomerAccountModel(
        customer: CustomerAccountCustomer(id: customerId, name: '', currentBalance: 0),
        summary: const CustomerAccountSummary(
          totalDebt: 0, invoiceDebt: 0, directCreditDebt: 0,
          availableBalance: 0, netBalance: 0,
        ),
        invoiceCredits: const [],
        directCredits: const [],
        clientBalance: const CustomerAccountBalance(balance: 0),
      ));
    }
  }

  /// Delete customer credit offline (used as fallback when server fails or no connection)
  Future<Either<Failure, void>> _deleteCreditOffline(String creditId) async {
    AppLogger.d('CustomerCreditRepository: Deleting credit offline: $creditId', tag: 'CREDIT');
    networkInfo.markServerUnreachable();
    try {
      // Remove from cache
      await localDataSource.removeCachedCredit(creditId);

      // Add to sync queue
      await _addToSyncQueue(
        entityType: 'CustomerCredit',
        entityId: creditId,
        operationType: SyncOperationType.delete,
        data: {'id': creditId},
      );

      AppLogger.i('Customer credit deleted offline successfully', tag: 'CREDIT');
      return const Right(null);
    } catch (e) {
      AppLogger.e('Error deleting customer credit offline: $e', tag: 'CREDIT');
      return Left(CacheFailure('Error al eliminar crédito offline: $e'));
    }
  }
}
