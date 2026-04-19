// lib/features/customer_credits/data/repositories/customer_credit_offline_repository.dart

import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/customer_credit.dart';
import '../../domain/repositories/customer_credit_repository.dart';
import '../models/customer_credit_model.dart';
import '../models/isar/isar_customer_credit.dart';

/// Implementación offline del repositorio de créditos de clientes usando ISAR
///
/// Proporciona todas las operaciones CRUD para créditos de clientes de forma offline-first
class CustomerCreditOfflineRepository implements CustomerCreditRepository {
  final IsarDatabase _database;

  CustomerCreditOfflineRepository({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  // ==================== CREDIT OPERATIONS ====================

  @override
  Future<Either<Failure, List<CustomerCredit>>> getCredits(CustomerCreditQueryParams? query) async {
    try {
      var queryBuilder = _isar.isarCustomerCredits.filter().deletedAtIsNull();

      if (query != null) {
        // Apply filters
        if (query.customerId != null) {
          queryBuilder = queryBuilder.and().customerIdEqualTo(query.customerId!);
        }

        if (query.status != null) {
          final creditStatus = CreditStatus.fromValue(query.status!);
          final isarStatus = _mapCreditStatus(creditStatus);
          queryBuilder = queryBuilder.and().statusEqualTo(isarStatus);
        }

        // Filter by overdueOnly
        if (query.overdueOnly == true) {
          queryBuilder = queryBuilder.and().statusEqualTo(IsarCreditStatus.overdue);
        }

        // Filter by includeCancelled is handled after query (not all ISAR builds support notEqualTo)
      }

      final results = await queryBuilder.findAll() as List<IsarCustomerCredit>;

      // Apply additional filters in Dart
      var filteredResults = results.toList();

      // Filter out cancelled credits unless includeCancelled is true
      if (query?.includeCancelled != true) {
        filteredResults = filteredResults
            .where((c) => c.status != IsarCreditStatus.cancelled)
            .toList();
      }

      if (query?.startDate != null) {
        final startDateTime = DateTime.tryParse(query!.startDate!);
        if (startDateTime != null) {
          filteredResults = filteredResults.where((c) => c.createdAt.isAfter(startDateTime)).toList();
        }
      }
      if (query?.endDate != null) {
        final endDateTime = DateTime.tryParse(query!.endDate!);
        if (endDateTime != null) {
          filteredResults = filteredResults.where((c) => c.createdAt.isBefore(endDateTime)).toList();
        }
      }

      // Sort by creation date (newest first)
      filteredResults.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final credits = filteredResults.map((isar) => _toEntity(isar)).toList();
      return Right(credits);
    } catch (e) {
      return Left(CacheFailure('Error loading credits: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> getCreditById(String id) async {
    try {
      final isarCredit = await _isar.isarCustomerCredits
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarCredit == null) {
        return Left(CacheFailure('Credit not found'));
      }

      return Right(_toEntity(isarCredit));
    } catch (e) {
      return Left(CacheFailure('Error loading credit: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CustomerCredit>>> getCreditsByCustomer(String customerId) async {
    try {
      final results = await _isar.isarCustomerCredits
          .filter()
          .customerIdEqualTo(customerId)
          .and()
          .deletedAtIsNull()
          .findAll() as List<IsarCustomerCredit>;

      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final credits = results.map((isar) => _toEntity(isar)).toList();
      return Right(credits);
    } catch (e) {
      return Left(CacheFailure('Error loading credits by customer: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CustomerCredit>>> getPendingCreditsByCustomer(String customerId) async {
    try {
      final results = await _isar.isarCustomerCredits
          .filter()
          .customerIdEqualTo(customerId)
          .and()
          .deletedAtIsNull()
          .group((q) => q
              .statusEqualTo(IsarCreditStatus.pending)
              .or()
              .statusEqualTo(IsarCreditStatus.partiallyPaid)
              .or()
              .statusEqualTo(IsarCreditStatus.overdue))
          .findAll() as List<IsarCustomerCredit>;

      results.sort((a, b) => a.dueDate?.compareTo(b.dueDate ?? DateTime(2099)) ?? 0);

      final credits = results.map((isar) => _toEntity(isar)).toList();
      return Right(credits);
    } catch (e) {
      return Left(CacheFailure('Error loading pending credits: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> createCredit(CreateCustomerCreditDto dto) async {
    try {
      final now = DateTime.now();
      final serverId = 'customercredit_offline_${now.millisecondsSinceEpoch}_${dto.customerId.hashCode}';

      // Parse dueDate from String to DateTime
      DateTime? dueDateParsed;
      if (dto.dueDate != null) {
        dueDateParsed = DateTime.tryParse(dto.dueDate!);
      }

      final isarCredit = IsarCustomerCredit(
        serverId: serverId,
        originalAmount: dto.originalAmount,
        paidAmount: 0,
        balanceDue: dto.originalAmount,
        status: IsarCreditStatus.pending,
        dueDate: dueDateParsed,
        description: dto.description,
        notes: dto.notes,
        customerId: dto.customerId,
        customerName: null, // Will be enriched when synced
        invoiceId: dto.invoiceId,
        invoiceNumber: null, // Will be enriched when synced
        organizationId: '', // Will be set during sync
        createdById: 'offline',
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      await _isar.writeTxn(() async {
        await _isar.isarCustomerCredits.put(isarCredit);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'CustomerCredit',
          entityId: serverId,
          operationType: SyncOperationType.create,
          data: {
            'customerId': dto.customerId,
            'originalAmount': dto.originalAmount,
            'dueDate': dto.dueDate, // Already a String
            'description': dto.description,
            'notes': dto.notes,
            'invoiceId': dto.invoiceId,
          },
        );
      } catch (e) {
        // Log pero no fallar
      }

      return Right(_toEntity(isarCredit));
    } catch (e) {
      return Left(CacheFailure('Error creating credit: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> addPayment(String creditId, AddCreditPaymentDto dto) async {
    try {
      final isarCredit = await _isar.isarCustomerCredits
          .filter()
          .serverIdEqualTo(creditId)
          .findFirst();

      if (isarCredit == null) {
        return Left(CacheFailure('Credit not found'));
      }

      // Actualizar montos
      isarCredit.paidAmount += dto.amount;
      isarCredit.balanceDue = isarCredit.originalAmount - isarCredit.paidAmount;

      // Actualizar estado
      if (isarCredit.balanceDue <= 0) {
        isarCredit.status = IsarCreditStatus.paid;
        isarCredit.balanceDue = 0;
      } else {
        isarCredit.status = IsarCreditStatus.partiallyPaid;
      }

      isarCredit.updatedAt = DateTime.now();
      isarCredit.isSynced = false;
      isarCredit.incrementVersion();

      // Guardar el pago en metadatos. El paymentTempId también servirá como idempotencyKey
      // para evitar duplicados en reintentos de sync.
      final paymentTempId = 'payment_${DateTime.now().millisecondsSinceEpoch}';
      final payments = _parsePayments(isarCredit.metadataJson);
      payments.add({
        'id': paymentTempId,
        'amount': dto.amount,
        'paymentMethod': dto.paymentMethod,
        'paymentDate': dto.paymentDate ?? DateTime.now().toIso8601String(), // paymentDate is String?
        'reference': dto.reference,
        'notes': dto.notes,
        'bankAccountId': dto.bankAccountId,
      });
      isarCredit.metadataJson = jsonEncode({'payments': payments});

      await _isar.writeTxn(() async {
        await _isar.isarCustomerCredits.put(isarCredit);
      });

      // Add to sync queue
      if (!creditId.startsWith('customercredit_offline_')) {
        try {
          final syncService = Get.find<SyncService>();
          await syncService.addOperationForCurrentUser(
            entityType: 'CustomerCredit',
            entityId: creditId,
            operationType: SyncOperationType.update,
            data: {
              'action': 'addPayment',
              'idempotencyKey': paymentTempId,
              'amount': dto.amount,
              'paymentMethod': dto.paymentMethod,
              'paymentDate': dto.paymentDate ?? DateTime.now().toIso8601String(),
              'bankAccountId': dto.bankAccountId,
              'reference': dto.reference,
              'notes': dto.notes,
            },
          );
        } catch (e) {
          // Log pero no fallar
        }
      }

      return Right(_toEntity(isarCredit));
    } catch (e) {
      return Left(CacheFailure('Error adding payment: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CreditPayment>>> getCreditPayments(String creditId) async {
    try {
      final isarCredit = await _isar.isarCustomerCredits
          .filter()
          .serverIdEqualTo(creditId)
          .findFirst();

      if (isarCredit == null) {
        return Left(CacheFailure('Credit not found'));
      }

      final payments = _parsePayments(isarCredit.metadataJson);
      final creditPayments = payments.map((p) => CreditPayment(
        id: p['id'] ?? '',
        amount: (p['amount'] as num?)?.toDouble() ?? 0,
        paymentMethod: p['paymentMethod'] ?? 'cash',
        paymentDate: p['paymentDate'] != null ? DateTime.parse(p['paymentDate']) : DateTime.now(),
        reference: p['reference'],
        notes: p['notes'],
        creditId: creditId,
        bankAccountId: p['bankAccountId'],
        organizationId: isarCredit.organizationId,
        createdById: isarCredit.createdById,
        createdAt: p['paymentDate'] != null ? DateTime.parse(p['paymentDate']) : DateTime.now(),
        updatedAt: p['paymentDate'] != null ? DateTime.parse(p['paymentDate']) : DateTime.now(),
      )).toList();

      return Right(creditPayments);
    } catch (e) {
      return Left(CacheFailure('Error loading payments: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> cancelCredit(String creditId) async {
    try {
      final isarCredit = await _isar.isarCustomerCredits
          .filter()
          .serverIdEqualTo(creditId)
          .findFirst();

      if (isarCredit == null) {
        return Left(CacheFailure('Credit not found'));
      }

      isarCredit.status = IsarCreditStatus.cancelled;
      isarCredit.updatedAt = DateTime.now();
      isarCredit.isSynced = false;
      isarCredit.incrementVersion();

      await _isar.writeTxn(() async {
        await _isar.isarCustomerCredits.put(isarCredit);
      });

      return Right(_toEntity(isarCredit));
    } catch (e) {
      return Left(CacheFailure('Error cancelling credit: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> markOverdueCredits() async {
    try {
      final now = DateTime.now();
      final results = await _isar.isarCustomerCredits
          .filter()
          .deletedAtIsNull()
          .group((q) => q
              .statusEqualTo(IsarCreditStatus.pending)
              .or()
              .statusEqualTo(IsarCreditStatus.partiallyPaid))
          .findAll() as List<IsarCustomerCredit>;

      int count = 0;
      await _isar.writeTxn(() async {
        for (final credit in results) {
          if (credit.dueDate != null && credit.dueDate!.isBefore(now)) {
            credit.status = IsarCreditStatus.overdue;
            credit.updatedAt = now;
            credit.isSynced = false;
            await _isar.isarCustomerCredits.put(credit);
            count++;
          }
        }
      });

      return Right(count);
    } catch (e) {
      return Left(CacheFailure('Error marking overdue credits: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CreditStats>> getCreditStats() async {
    try {
      final results = await _isar.isarCustomerCredits
          .filter()
          .deletedAtIsNull()
          .findAll() as List<IsarCustomerCredit>;

      double totalPending = 0, totalOverdue = 0, totalPaid = 0;
      int countPending = 0, countOverdue = 0;
      double directPending = 0, directOverdue = 0, directPaid = 0;
      double invoicePending = 0, invoiceOverdue = 0, invoicePaid = 0;
      int directCountPending = 0, directCountOverdue = 0;
      int invoiceCountPending = 0, invoiceCountOverdue = 0;

      for (final credit in results) {
        final isInvoice = credit.invoiceId != null && credit.invoiceId!.isNotEmpty;

        if (credit.status == IsarCreditStatus.paid) {
          totalPaid += credit.originalAmount;
          if (isInvoice) { invoicePaid += credit.originalAmount; }
          else { directPaid += credit.originalAmount; }
          continue;
        }

        if (credit.status == IsarCreditStatus.cancelled) continue;

        // Detectar overdue: status explícito O fecha vencida con saldo pendiente
        final isOverdue = credit.status == IsarCreditStatus.overdue ||
            (credit.dueDate != null && credit.dueDate!.isBefore(DateTime.now()) && credit.balanceDue > 0);

        if (isOverdue) {
          totalOverdue += credit.balanceDue;
          countOverdue++;
          if (isInvoice) { invoiceOverdue += credit.balanceDue; invoiceCountOverdue++; }
          else { directOverdue += credit.balanceDue; directCountOverdue++; }
        } else {
          totalPending += credit.balanceDue;
          countPending++;
          if (isInvoice) { invoicePending += credit.balanceDue; invoiceCountPending++; }
          else { directPending += credit.balanceDue; directCountPending++; }
        }
      }

      return Right(CreditStats(
        totalPending: totalPending,
        totalOverdue: totalOverdue,
        totalPaid: totalPaid,
        countPending: countPending,
        countOverdue: countOverdue,
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
      ));
    } catch (e) {
      return Left(CacheFailure('Error loading credit stats: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCredit(String creditId) async {
    try {
      final isarCredit = await _isar.isarCustomerCredits
          .filter()
          .serverIdEqualTo(creditId)
          .findFirst();

      if (isarCredit == null) {
        return Left(CacheFailure('Credit not found'));
      }

      isarCredit.deletedAt = DateTime.now();
      isarCredit.isSynced = false;
      isarCredit.incrementVersion();

      await _isar.writeTxn(() async {
        await _isar.isarCustomerCredits.put(isarCredit);
      });

      // Add to sync queue
      if (!creditId.startsWith('customercredit_offline_')) {
        try {
          final syncService = Get.find<SyncService>();
          await syncService.addOperationForCurrentUser(
            entityType: 'CustomerCredit',
            entityId: creditId,
            operationType: SyncOperationType.delete,
            data: {'deleted': true},
          );
        } catch (e) {
          // Log pero no fallar
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error deleting credit: ${e.toString()}'));
    }
  }

  // ==================== CREDIT TRANSACTIONS ====================

  @override
  Future<Either<Failure, List<CreditTransactionModel>>> getCreditTransactions(String creditId) async {
    // Las transacciones detalladas requieren datos del servidor
    return Right([]);
  }

  @override
  Future<Either<Failure, CustomerCredit>> addAmountToCredit(String creditId, AddAmountToCreditDto dto) async {
    try {
      final isarCredit = await _isar.isarCustomerCredits
          .filter()
          .serverIdEqualTo(creditId)
          .findFirst();

      if (isarCredit == null) {
        return Left(CacheFailure('Credit not found'));
      }

      isarCredit.originalAmount += dto.amount;
      isarCredit.balanceDue = isarCredit.originalAmount - isarCredit.paidAmount;
      isarCredit.updatedAt = DateTime.now();
      isarCredit.isSynced = false;
      isarCredit.incrementVersion();

      if (isarCredit.balanceDue > 0 && isarCredit.status == IsarCreditStatus.paid) {
        isarCredit.status = IsarCreditStatus.partiallyPaid;
      }

      await _isar.writeTxn(() async {
        await _isar.isarCustomerCredits.put(isarCredit);
      });

      return Right(_toEntity(isarCredit));
    } catch (e) {
      return Left(CacheFailure('Error adding amount to credit: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CustomerCredit>> applyBalanceToCredit(String creditId, ApplyBalanceToCreditDto dto) async {
    try {
      final isarCredit = await _isar.isarCustomerCredits
          .filter()
          .serverIdEqualTo(creditId)
          .findFirst();

      if (isarCredit == null) {
        return Left(CacheFailure('Credit not found'));
      }

      isarCredit.paidAmount += dto.amount ?? 0;
      isarCredit.balanceDue = isarCredit.originalAmount - isarCredit.paidAmount;

      if (isarCredit.balanceDue <= 0) {
        isarCredit.status = IsarCreditStatus.paid;
        isarCredit.balanceDue = 0;
      } else {
        isarCredit.status = IsarCreditStatus.partiallyPaid;
      }

      isarCredit.updatedAt = DateTime.now();
      isarCredit.isSynced = false;
      isarCredit.incrementVersion();

      await _isar.writeTxn(() async {
        await _isar.isarCustomerCredits.put(isarCredit);
      });

      return Right(_toEntity(isarCredit));
    } catch (e) {
      return Left(CacheFailure('Error applying balance to credit: ${e.toString()}'));
    }
  }

  // ==================== CLIENT BALANCE ====================
  // Estas operaciones requieren funcionalidad del servidor para saldos a favor

  @override
  Future<Either<Failure, List<ClientBalanceModel>>> getAllClientBalances() async {
    return Right([]);
  }

  @override
  Future<Either<Failure, ClientBalanceModel?>> getClientBalance(String customerId) async {
    return Right(null);
  }

  @override
  Future<Either<Failure, List<ClientBalanceTransactionModel>>> getClientBalanceTransactions(String customerId) async {
    return Right([]);
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> depositBalance(DepositBalanceDto dto) async {
    return Left(CacheFailure('Balance operations require server connection'));
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> useBalance(UseBalanceDto dto) async {
    return Left(CacheFailure('Balance operations require server connection'));
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> refundBalance(RefundBalanceDto dto) async {
    return Left(CacheFailure('Balance operations require server connection'));
  }

  @override
  Future<Either<Failure, ClientBalanceModel>> adjustBalance(AdjustBalanceDto dto) async {
    return Left(CacheFailure('Balance operations require server connection'));
  }

  // ==================== CUSTOMER ACCOUNT ====================

  @override
  Future<Either<Failure, CustomerAccountModel>> getCustomerAccount(String customerId) async {
    try {
      final creditsResult = await getCreditsByCustomer(customerId);

      return creditsResult.fold(
        (failure) => Left(failure),
        (credits) {
          double totalDebt = 0;
          double invoiceDebt = 0;
          double directCreditDebt = 0;

          // Separate credits by type and calculate totals
          final invoiceCredits = <CustomerCreditModel>[];
          final directCredits = <CustomerCreditModel>[];

          for (final credit in credits) {
            if (credit.status != CreditStatus.cancelled) {
              totalDebt += credit.balanceDue;

              // Convert entity to model for the response
              final creditModel = CustomerCreditModel(
                id: credit.id,
                originalAmount: credit.originalAmount,
                paidAmount: credit.paidAmount,
                balanceDue: credit.balanceDue,
                status: credit.status,
                dueDate: credit.dueDate,
                description: credit.description,
                notes: credit.notes,
                customerId: credit.customerId,
                customerName: credit.customerName,
                invoiceId: credit.invoiceId,
                invoiceNumber: credit.invoiceNumber,
                organizationId: credit.organizationId,
                createdById: credit.createdById,
                createdByName: credit.createdByName,
                payments: credit.payments,
                createdAt: credit.createdAt,
                updatedAt: credit.updatedAt,
                deletedAt: credit.deletedAt,
              );

              if (credit.invoiceId != null) {
                invoiceCredits.add(creditModel);
                invoiceDebt += credit.balanceDue;
              } else {
                directCredits.add(creditModel);
                directCreditDebt += credit.balanceDue;
              }
            }
          }

          return Right(CustomerAccountModel(
            customer: CustomerAccountCustomer(
              id: customerId,
              name: credits.isNotEmpty ? (credits.first.customerName ?? 'Cliente') : 'Cliente',
              currentBalance: 0, // Requires server
            ),
            summary: CustomerAccountSummary(
              totalDebt: totalDebt,
              invoiceDebt: invoiceDebt,
              directCreditDebt: directCreditDebt,
              availableBalance: 0, // Requires server
              netBalance: -totalDebt, // Simplified offline calculation
            ),
            invoiceCredits: invoiceCredits,
            directCredits: directCredits,
            clientBalance: CustomerAccountBalance(
              balance: 0, // Requires server
              lastTransaction: null,
            ),
          ));
        },
      );
    } catch (e) {
      return Left(CacheFailure('Error loading customer account: ${e.toString()}'));
    }
  }

  // ==================== SYNC OPERATIONS ====================

  Future<Either<Failure, List<CustomerCredit>>> getUnsyncedCredits() async {
    try {
      final results = await _isar.isarCustomerCredits
          .filter()
          .isSyncedEqualTo(false)
          .findAll() as List<IsarCustomerCredit>;

      final credits = results.map((isar) => _toEntity(isar)).toList();
      return Right(credits);
    } catch (e) {
      return Left(CacheFailure('Error loading unsynced credits: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Unit>> markCreditsAsSynced(List<String> ids) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in ids) {
          final credit = await _isar.isarCustomerCredits
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (credit != null) {
            credit.isSynced = true;
            credit.lastSyncAt = DateTime.now();
            await _isar.isarCustomerCredits.put(credit);
          }
        }
      });

      return Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error marking credits as synced: ${e.toString()}'));
    }
  }

  // ==================== HELPER METHODS ====================

  CustomerCredit _toEntity(IsarCustomerCredit isar) {
    return CustomerCredit(
      id: isar.serverId,
      originalAmount: isar.originalAmount,
      paidAmount: isar.paidAmount,
      balanceDue: isar.balanceDue,
      status: _mapIsarCreditStatus(isar.status),
      dueDate: isar.dueDate,
      description: isar.description,
      notes: isar.notes,
      customerId: isar.customerId,
      customerName: isar.customerName,
      invoiceId: isar.invoiceId,
      invoiceNumber: isar.invoiceNumber,
      organizationId: isar.organizationId,
      createdById: isar.createdById,
      createdByName: isar.createdByName,
      createdAt: isar.createdAt,
      updatedAt: isar.updatedAt,
      deletedAt: isar.deletedAt,
    );
  }

  static IsarCreditStatus _mapCreditStatus(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
        return IsarCreditStatus.pending;
      case CreditStatus.partiallyPaid:
        return IsarCreditStatus.partiallyPaid;
      case CreditStatus.paid:
        return IsarCreditStatus.paid;
      case CreditStatus.cancelled:
        return IsarCreditStatus.cancelled;
      case CreditStatus.overdue:
        return IsarCreditStatus.overdue;
    }
  }

  static CreditStatus _mapIsarCreditStatus(IsarCreditStatus status) {
    switch (status) {
      case IsarCreditStatus.pending:
        return CreditStatus.pending;
      case IsarCreditStatus.partiallyPaid:
        return CreditStatus.partiallyPaid;
      case IsarCreditStatus.paid:
        return CreditStatus.paid;
      case IsarCreditStatus.cancelled:
        return CreditStatus.cancelled;
      case IsarCreditStatus.overdue:
        return CreditStatus.overdue;
    }
  }

  List<Map<String, dynamic>> _parsePayments(String? metadataJson) {
    if (metadataJson == null || metadataJson.isEmpty) return [];
    try {
      final metadata = jsonDecode(metadataJson);
      if (metadata is Map && metadata['payments'] != null) {
        return List<Map<String, dynamic>>.from(metadata['payments']);
      }
    } catch (e) {
      // Ignore parse errors
    }
    return [];
  }
}
