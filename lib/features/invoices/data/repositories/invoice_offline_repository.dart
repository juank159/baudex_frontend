// lib/features/invoices/data/repositories/invoice_offline_repository.dart
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_item.dart';
import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_stats.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../models/isar/isar_invoice.dart';
import '../../../../app/data/local/enums/isar_enums.dart';

/// Implementación offline del repositorio de facturas usando ISAR
///
/// Proporciona todas las operaciones CRUD para facturas de forma offline-first
class InvoiceOfflineRepository implements InvoiceRepository {
  final IsarDatabase _database;

  InvoiceOfflineRepository({IsarDatabase? database})
    : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, PaginatedResult<Invoice>>> getInvoices({
    int page = 1,
    int limit = 10,
    String? search,
    InvoiceStatus? status,
    PaymentMethod? paymentMethod,
    String? customerId,
    String? createdById,
    String? bankAccountId,
    String? bankAccountName, // Filtro por nombre de método de pago (no aplica en offline)
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    try {
      final collection = _isar.isarInvoices;

      // Build base query builder for filtering
      QueryBuilder<IsarInvoice, IsarInvoice, QAfterFilterCondition> filterQuery;

      // Start with a base filter (soft delete filter)
      filterQuery = collection.filter().deletedAtIsNull();

      // Apply search filter
      if (search != null && search.isNotEmpty) {
        filterQuery = filterQuery.and().numberContains(
          search,
          caseSensitive: false,
        );
      }

      // Apply status filter
      if (status != null) {
        final isarStatus = _mapInvoiceStatus(status);
        filterQuery = filterQuery.and().statusEqualTo(isarStatus);
      }

      // Apply payment method filter
      if (paymentMethod != null) {
        final isarPaymentMethod = _mapPaymentMethod(paymentMethod);
        filterQuery = filterQuery.and().paymentMethodEqualTo(isarPaymentMethod);
      }

      // Apply customer filter
      if (customerId != null) {
        filterQuery = filterQuery.and().customerIdEqualTo(customerId);
      }

      // Apply date range filters
      if (startDate != null) {
        filterQuery = filterQuery.and().dateGreaterThan(startDate);
      }
      if (endDate != null) {
        filterQuery = filterQuery.and().dateLessThan(endDate);
      }

      // Get total count for pagination
      final totalItems = await filterQuery.count();

      // Apply sorting and pagination
      final offset = (page - 1) * limit;
      List<IsarInvoice> isarInvoices;

      switch (sortBy) {
        case 'number':
          isarInvoices =
              sortOrder == 'DESC'
                  ? await filterQuery
                      .sortByNumberDesc()
                      .offset(offset)
                      .limit(limit)
                      .findAll()
                  : await filterQuery
                      .sortByNumber()
                      .offset(offset)
                      .limit(limit)
                      .findAll();
          break;
        case 'date':
          isarInvoices =
              sortOrder == 'DESC'
                  ? await filterQuery
                      .sortByDateDesc()
                      .offset(offset)
                      .limit(limit)
                      .findAll()
                  : await filterQuery
                      .sortByDate()
                      .offset(offset)
                      .limit(limit)
                      .findAll();
          break;
        case 'dueDate':
          isarInvoices =
              sortOrder == 'DESC'
                  ? await filterQuery
                      .sortByDueDateDesc()
                      .offset(offset)
                      .limit(limit)
                      .findAll()
                  : await filterQuery
                      .sortByDueDate()
                      .offset(offset)
                      .limit(limit)
                      .findAll();
          break;
        case 'total':
          isarInvoices =
              sortOrder == 'DESC'
                  ? await filterQuery
                      .sortByTotalDesc()
                      .offset(offset)
                      .limit(limit)
                      .findAll()
                  : await filterQuery
                      .sortByTotal()
                      .offset(offset)
                      .limit(limit)
                      .findAll();
          break;
        case 'createdAt':
        default:
          isarInvoices =
              sortOrder == 'DESC'
                  ? await filterQuery
                      .sortByCreatedAtDesc()
                      .offset(offset)
                      .limit(limit)
                      .findAll()
                  : await filterQuery
                      .sortByCreatedAt()
                      .offset(offset)
                      .limit(limit)
                      .findAll();
      }

      // Convert to domain entities
      final invoices = isarInvoices.map((isar) => isar.toEntity()).toList();

      final totalPages = (totalItems / limit).ceil();
      final meta = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      );

      return Right(PaginatedResult(data: invoices, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error loading invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getOverdueInvoices() async {
    try {
      final now = DateTime.now();
      final isarInvoices =
          await _isar.isarInvoices
              .filter()
              .dueDateLessThan(now)
              .and()
              .statusEqualTo(IsarInvoiceStatus.pending)
              .and()
              .deletedAtIsNull()
              .sortByDueDateDesc()
              .limit(50)
              .findAll();

      final invoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      return Right(invoices);
    } catch (e) {
      return Left(
        CacheFailure('Error loading overdue invoices: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
    try {
      final isarInvoice =
          await _isar.isarInvoices
              .filter()
              .serverIdEqualTo(id)
              .and()
              .deletedAtIsNull()
              .findFirst();

      if (isarInvoice == null) {
        return Left(CacheFailure('Invoice not found'));
      }

      return Right(isarInvoice.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceByNumber(String number) async {
    try {
      final isarInvoice =
          await _isar.isarInvoices
              .filter()
              .numberEqualTo(number)
              .and()
              .deletedAtIsNull()
              .findFirst();

      if (isarInvoice == null) {
        return Left(CacheFailure('Invoice not found'));
      }

      return Right(isarInvoice.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> searchInvoices(String searchTerm) async {
    try {
      final isarInvoices =
          await _isar.isarInvoices
              .filter()
              .group(
                (q) => q
                    .numberContains(searchTerm, caseSensitive: false)
                    .or()
                    .notesContains(searchTerm, caseSensitive: false),
              )
              .and()
              .deletedAtIsNull()
              .sortByCreatedAtDesc()
              .limit(10)
              .findAll();

      final invoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      return Right(invoices);
    } catch (e) {
      return Left(CacheFailure('Error searching invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InvoiceStats>> getInvoiceStats() async {
    try {
      final collection = _isar.isarInvoices;

      // Get all invoices for calculations (no date filters for basic stats)
      final allInvoices = await collection.filter().deletedAtIsNull().findAll();

      // Calculate stats
      final totalInvoices = allInvoices.length;
      final paidInvoices =
          allInvoices
              .where((inv) => inv.status == IsarInvoiceStatus.paid)
              .length;
      final pendingInvoices =
          allInvoices
              .where((inv) => inv.status == IsarInvoiceStatus.pending)
              .length;
      final cancelledInvoices =
          allInvoices
              .where((inv) => inv.status == IsarInvoiceStatus.cancelled)
              .length;

      final paidAmount = allInvoices
          .where((inv) => inv.status == IsarInvoiceStatus.paid)
          .fold<double>(0, (sum, inv) => sum + inv.total);
      final pendingAmount = allInvoices
          .where((inv) => inv.status == IsarInvoiceStatus.pending)
          .fold<double>(0, (sum, inv) => sum + inv.total);

      // Count overdue invoices
      final now = DateTime.now();
      final overdueInvoices =
          allInvoices
              .where(
                (inv) =>
                    inv.status == IsarInvoiceStatus.pending &&
                    inv.dueDate.isBefore(now),
              )
              .length;

      // Calculate draft invoices
      final draftInvoices =
          allInvoices
              .where((inv) => inv.status == IsarInvoiceStatus.draft)
              .length;
      
      // Calculate partially paid invoices
      final partiallyPaidInvoices =
          allInvoices
              .where((inv) => inv.status == IsarInvoiceStatus.partiallyPaid)
              .length;
      
      // Calculate overdue amount
      final overdueAmount = allInvoices
          .where((inv) => 
              inv.status == IsarInvoiceStatus.pending &&
              inv.dueDate.isBefore(DateTime.now()))
          .fold<double>(0, (sum, inv) => sum + inv.total);

      final stats = InvoiceStats(
        total: totalInvoices,
        draft: draftInvoices,
        pending: pendingInvoices,
        paid: paidInvoices,
        overdue: overdueInvoices,
        cancelled: cancelledInvoices,
        partiallyPaid: partiallyPaidInvoices,
        totalSales: paidAmount,
        pendingAmount: pendingAmount,
        overdueAmount: overdueAmount,
      );

      return Right(stats);
    } catch (e) {
      return Left(CacheFailure('Error loading invoice stats: ${e.toString()}'));
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, Invoice>> createInvoice({
    required String customerId,
    required List<CreateInvoiceItemParams> items,
    String? number,
    DateTime? date,
    DateTime? dueDate,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    InvoiceStatus? status,
    double taxPercentage = 19,
    double discountPercentage = 0,
    double discountAmount = 0,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
    String? bankAccountId, // 🏦 ID de la cuenta bancaria para registrar el pago
  }) async {
    try {
      final now = DateTime.now();
      
      // Generate invoice number if not provided
      final invoiceNumber = number ?? await _generateInvoiceNumber();
      
      final serverId = 'inv_${now.millisecondsSinceEpoch}_${invoiceNumber.hashCode}';
      
      // Convert CreateInvoiceItemParams to InvoiceItems and calculate totals
      final invoiceItems = items.map((item) => InvoiceItem(
        id: 'item_${now.millisecondsSinceEpoch}_${item.hashCode}',
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discountPercentage: item.discountPercentage,
        discountAmount: item.discountAmount,
        subtotal: (item.quantity * item.unitPrice) - item.discountAmount,
        unit: item.unit,
        notes: item.notes,
        invoiceId: serverId,
        productId: item.productId,
        createdAt: now,
        updatedAt: now,
      )).toList();
      
      // Calculate totals
      final subtotal = invoiceItems.fold<double>(0, (sum, item) => sum + item.subtotal);
      final totalDiscountAmount = discountAmount + invoiceItems.fold<double>(0, (sum, item) => sum + item.discountAmount);
      final discountedSubtotal = subtotal - totalDiscountAmount;
      final taxAmount = discountedSubtotal * (taxPercentage / 100);
      final total = discountedSubtotal + taxAmount;

      final isarInvoice = IsarInvoice.create(
        serverId: serverId,
        number: invoiceNumber,
        date: date ?? now,
        dueDate: dueDate ?? now.add(const Duration(days: 30)),
        status: _mapInvoiceStatus(status ?? InvoiceStatus.draft),
        paymentMethod: _mapPaymentMethod(paymentMethod),
        subtotal: subtotal,
        taxPercentage: taxPercentage,
        taxAmount: taxAmount,
        discountPercentage: discountPercentage,
        discountAmount: discountAmount,
        total: total,
        paidAmount: 0.0,
        balanceDue: total,
        notes: notes,
        terms: terms,
        customerId: customerId,
        createdById: 'system', // TODO: Get from auth context
        createdAt: now,
        updatedAt: now,
        isSynced: false, // Mark as unsynced for later upload
      );

      await _isar.writeTxn(() async {
        await _isar.isarInvoices.put(isarInvoice);
      });

      return Right(isarInvoice.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> updateInvoice({
    required String id,
    String? number,
    DateTime? date,
    DateTime? dueDate,
    PaymentMethod? paymentMethod,
    InvoiceStatus? status,
    double? taxPercentage,
    double? discountPercentage,
    double? discountAmount,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
    String? customerId,
    List<CreateInvoiceItemParams>? items,
  }) async {
    try {
      final isarInvoice =
          await _isar.isarInvoices.filter().serverIdEqualTo(id).findFirst();

      if (isarInvoice == null) {
        return Left(CacheFailure('Invoice not found'));
      }

      // Update fields
      if (number != null) isarInvoice.number = number;
      if (date != null) isarInvoice.date = date;
      if (dueDate != null) isarInvoice.dueDate = dueDate;
      if (customerId != null) isarInvoice.customerId = customerId;
      if (taxPercentage != null) isarInvoice.taxPercentage = taxPercentage;
      if (status != null) isarInvoice.status = _mapInvoiceStatus(status);
      if (paymentMethod != null) {
        isarInvoice.paymentMethod = _mapPaymentMethod(paymentMethod);
      }
      if (notes != null) isarInvoice.notes = notes;
      if (terms != null) isarInvoice.terms = terms;
      
      // If items are provided, recalculate totals
      if (items != null) {
        final now = DateTime.now();
        final invoiceItems = items.map((item) => InvoiceItem(
          id: 'item_${now.millisecondsSinceEpoch}_${item.hashCode}',
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          discountPercentage: item.discountPercentage,
          discountAmount: item.discountAmount,
          subtotal: (item.quantity * item.unitPrice) - item.discountAmount,
          unit: item.unit,
          notes: item.notes,
          invoiceId: id,
          productId: item.productId,
          createdAt: now,
          updatedAt: now,
        )).toList();
        
        final subtotal = invoiceItems.fold<double>(0, (sum, item) => sum + item.subtotal);
        final totalDiscountAmount = (discountAmount ?? 0) + invoiceItems.fold<double>(0, (sum, item) => sum + item.discountAmount);
        final discountedSubtotal = subtotal - totalDiscountAmount;
        final taxAmount = discountedSubtotal * ((taxPercentage ?? isarInvoice.taxPercentage) / 100);
        final total = discountedSubtotal + taxAmount;
        
        isarInvoice.subtotal = subtotal;
        isarInvoice.discountPercentage = discountPercentage ?? isarInvoice.discountPercentage;
        isarInvoice.discountAmount = discountAmount ?? isarInvoice.discountAmount;
        isarInvoice.taxAmount = taxAmount;
        isarInvoice.total = total;
        isarInvoice.balanceDue = total - isarInvoice.paidAmount;
      }

      isarInvoice.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarInvoices.put(isarInvoice);
      });

      return Right(isarInvoice.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating invoice: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Invoice>> updateInvoiceStatus({
    required String id,
    required InvoiceStatus status,
  }) async {
    return updateInvoice(id: id, status: status);
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    try {
      final isarInvoice =
          await _isar.isarInvoices.filter().serverIdEqualTo(id).findFirst();

      if (isarInvoice == null) {
        return Left(CacheFailure('Invoice not found'));
      }

      // Soft delete
      isarInvoice.softDelete();

      await _isar.writeTxn(() async {
        await _isar.isarInvoices.put(isarInvoice);
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error deleting invoice: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> confirmInvoice(String id) async {
    return updateInvoiceStatus(id: id, status: InvoiceStatus.pending);
  }

  @override
  Future<Either<Failure, Invoice>> cancelInvoice(String id) async {
    return updateInvoiceStatus(id: id, status: InvoiceStatus.cancelled);
  }

  @override
  Future<Either<Failure, List<Invoice>>> getInvoicesByCustomer(
    String customerId,
  ) async {
    try {
      final isarInvoices =
          await _isar.isarInvoices
              .filter()
              .customerIdEqualTo(customerId)
              .and()
              .deletedAtIsNull()
              .sortByCreatedAtDesc()
              .findAll();

      final invoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      return Right(invoices);
    } catch (e) {
      return Left(CacheFailure('Error loading customer invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> addPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? bankAccountId,
    DateTime? paymentDate,
    String? reference,
    String? notes,
  }) async {
    try {
      final isarInvoice =
          await _isar.isarInvoices.filter().serverIdEqualTo(invoiceId).findFirst();

      if (isarInvoice == null) {
        return Left(CacheFailure('Invoice not found'));
      }

      // For now, we'll just mark the invoice as paid if the amount covers the total
      // In a full implementation, you'd store individual payments and track partial payments
      if (amount >= isarInvoice.total) {
        isarInvoice.status = IsarInvoiceStatus.paid;
      } else {
        isarInvoice.status = IsarInvoiceStatus.partiallyPaid;
      }

      isarInvoice.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarInvoices.put(isarInvoice);
      });

      return Right(isarInvoice.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error adding payment: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MultiplePaymentsResult>> addMultiplePayments({
    required String invoiceId,
    required List<PaymentItemData> payments,
    DateTime? paymentDate,
    bool createCreditForRemaining = false,
    String? generalNotes,
  }) async {
    try {
      final isarInvoice =
          await _isar.isarInvoices.filter().serverIdEqualTo(invoiceId).findFirst();

      if (isarInvoice == null) {
        return Left(CacheFailure('Invoice not found'));
      }

      // Calculate total payment amount
      final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
      final remainingBalance = isarInvoice.total - totalPaid;

      // Update invoice status based on payment
      if (remainingBalance <= 0) {
        isarInvoice.status = IsarInvoiceStatus.paid;
      } else {
        isarInvoice.status = IsarInvoiceStatus.partiallyPaid;
      }

      isarInvoice.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarInvoices.put(isarInvoice);
      });

      return Right(MultiplePaymentsResult(
        invoice: isarInvoice.toEntity(),
        paymentsCreated: payments.length,
        remainingBalance: remainingBalance > 0 ? remainingBalance : 0,
        creditCreated: createCreditForRemaining && remainingBalance > 0,
      ));
    } catch (e) {
      return Left(CacheFailure('Error adding multiple payments: ${e.toString()}'));
    }
  }

  // ==================== CACHE OPERATIONS ====================

  Future<Either<Failure, List<Invoice>>> getCachedInvoices() async {
    try {
      final isarInvoices =
          await _isar.isarInvoices
              .filter()
              .deletedAtIsNull()
              .sortByCreatedAtDesc()
              .findAll();

      final invoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      return Right(invoices);
    } catch (e) {
      return Left(
        CacheFailure('Error loading cached invoices: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, void>> clearInvoiceCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarInvoices.clear();
      });

      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Error clearing invoice cache: ${e.toString()}'),
      );
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Get invoices that need to be synced with the server
  Future<Either<Failure, List<Invoice>>> getUnsyncedInvoices() async {
    try {
      final isarInvoices =
          await _isar.isarInvoices.filter().isSyncedEqualTo(false).findAll();

      final invoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      return Right(invoices);
    } catch (e) {
      return Left(
        CacheFailure('Error loading unsynced invoices: ${e.toString()}'),
      );
    }
  }

  /// Mark invoices as synced after successful server sync
  Future<Either<Failure, void>> markInvoicesAsSynced(
    List<String> invoiceIds,
  ) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in invoiceIds) {
          final isarInvoice =
              await _isar.isarInvoices.filter().serverIdEqualTo(id).findFirst();

          if (isarInvoice != null) {
            isarInvoice.markAsSynced();
            await _isar.isarInvoices.put(isarInvoice);
          }
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Error marking invoices as synced: ${e.toString()}'),
      );
    }
  }

  /// Bulk insert invoices from server
  Future<Either<Failure, void>> bulkInsertInvoices(
    List<Invoice> invoices,
  ) async {
    try {
      final isarInvoices =
          invoices.map((inv) => IsarInvoice.fromEntity(inv)).toList();

      await _isar.writeTxn(() async {
        await _isar.isarInvoices.putAll(isarInvoices);
      });

      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure('Error bulk inserting invoices: ${e.toString()}'),
      );
    }
  }

  // ==================== HELPER METHODS ====================

  Future<String> _generateInvoiceNumber() async {
    try {
      // Get the count of existing invoices to generate next number
      final count = await _isar.isarInvoices.filter().deletedAtIsNull().count();
      final nextNumber = count + 1;
      return 'INV-${nextNumber.toString().padLeft(6, '0')}';
    } catch (e) {
      // Fallback to timestamp-based number
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'INV-$timestamp';
    }
  }

  IsarInvoiceStatus _mapInvoiceStatus(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return IsarInvoiceStatus.draft;
      case InvoiceStatus.pending:
        return IsarInvoiceStatus.pending;
      case InvoiceStatus.paid:
        return IsarInvoiceStatus.paid;
      case InvoiceStatus.cancelled:
        return IsarInvoiceStatus.cancelled;
      case InvoiceStatus.overdue:
        return IsarInvoiceStatus.overdue;
      case InvoiceStatus.partiallyPaid:
        return IsarInvoiceStatus.partiallyPaid;
      case InvoiceStatus.credited:
        return IsarInvoiceStatus.credited;
      case InvoiceStatus.partiallyCredited:
        return IsarInvoiceStatus.partiallyCredited;
    }
  }

  IsarPaymentMethod _mapPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return IsarPaymentMethod.cash;
      case PaymentMethod.credit:
        return IsarPaymentMethod.credit;
      case PaymentMethod.creditCard:
        return IsarPaymentMethod.creditCard;
      case PaymentMethod.debitCard:
        return IsarPaymentMethod.debitCard;
      case PaymentMethod.bankTransfer:
        return IsarPaymentMethod.bankTransfer;
      case PaymentMethod.check:
        return IsarPaymentMethod.check;
      case PaymentMethod.clientBalance:
        return IsarPaymentMethod.clientBalance;
      case PaymentMethod.other:
        return IsarPaymentMethod.other;
    }
  }

  @override
  Future<Either<Failure, List<int>>> downloadInvoicePdf(String id) async {
    return Left(ServerFailure('Download PDF not available offline'));
  }
}
