// lib/features/invoices/data/repositories/invoice_offline_repository_simple.dart
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

/// Implementación offline simplificada del repositorio de facturas usando ISAR
/// 
/// Implementa solo los métodos esenciales para funcionar offline
class InvoiceOfflineRepositorySimple implements InvoiceRepository {
  final IsarDatabase _database;

  InvoiceOfflineRepositorySimple({IsarDatabase? database}) 
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
      print('📱 ISAR: Cargando facturas offline...');
      
      final collection = _isar.isarInvoices;
      
      // Build base query (exclude deleted items)
      var query = collection.filter().deletedAtIsNull();
      
      // Apply search filter
      if (search != null && search.isNotEmpty) {
        query = query.numberContains(search, caseSensitive: false);
      }
      
      // Apply status filter
      if (status != null) {
        final isarStatus = _mapInvoiceStatusToIsar(status);
        query = query.statusEqualTo(isarStatus);
      }
      
      // Apply customer filter
      if (customerId != null) {
        query = query.customerIdEqualTo(customerId);
      }
      
      // Apply date range filters
      if (startDate != null) {
        query = query.dateGreaterThan(startDate);
      }
      if (endDate != null) {
        query = query.dateLessThan(endDate);
      }
      
      // Get total count for pagination first
      final totalItems = await query.build().count();
      
      // Apply sorting and pagination
      final offset = (page - 1) * limit;
      List<IsarInvoice> isarInvoices;
      
      switch (sortBy) {
        case 'number':
          if (sortOrder == 'DESC') {
            isarInvoices = await query.sortByNumberDesc().offset(offset).limit(limit).findAll();
          } else {
            isarInvoices = await query.sortByNumber().offset(offset).limit(limit).findAll();
          }
          break;
        case 'date':
          if (sortOrder == 'DESC') {
            isarInvoices = await query.sortByDateDesc().offset(offset).limit(limit).findAll();
          } else {
            isarInvoices = await query.sortByDate().offset(offset).limit(limit).findAll();
          }
          break;
        case 'total':
          if (sortOrder == 'DESC') {
            isarInvoices = await query.sortByTotalDesc().offset(offset).limit(limit).findAll();
          } else {
            isarInvoices = await query.sortByTotal().offset(offset).limit(limit).findAll();
          }
          break;
        case 'createdAt':
        default:
          if (sortOrder == 'DESC') {
            isarInvoices = await query.sortByCreatedAtDesc().offset(offset).limit(limit).findAll();
          } else {
            isarInvoices = await query.sortByCreatedAt().offset(offset).limit(limit).findAll();
          }
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

      print('✅ ISAR: ${invoices.length} facturas cargadas');
      return Right(PaginatedResult(data: invoices, meta: meta));
    } catch (e) {
      print('❌ ISAR: Error loading invoices: $e');
      return Left(CacheFailure('Error loading invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getOverdueInvoices() async {
    try {
      print('📱 ISAR: Cargando facturas vencidas offline...');
      
      final now = DateTime.now();
      final isarInvoices = await _isar.isarInvoices
          .filter()
          .deletedAtIsNull()
          .and()
          .dueDateLessThan(now)
          .and()
          .statusEqualTo(IsarInvoiceStatus.pending)
          .sortByDueDateDesc()
          .limit(50)
          .findAll();
      
      final invoices = isarInvoices.map((isar) => isar.toEntity()).toList();
      print('✅ ISAR: ${invoices.length} facturas vencidas cargadas');
      return Right(invoices);
    } catch (e) {
      print('❌ ISAR: Error loading overdue invoices: $e');
      return Left(CacheFailure('Error loading overdue invoices: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
    try {
      final isarInvoice = await _isar.isarInvoices
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
      final isarInvoice = await _isar.isarInvoices
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
      final isarInvoices = await _isar.isarInvoices
          .filter()
          .deletedAtIsNull()
          .and()
          .group((q) => q
            .numberContains(searchTerm, caseSensitive: false)
            .or()
            .notesContains(searchTerm, caseSensitive: false)
          )
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
      print('📱 ISAR: Cargando estadísticas offline...');
      
      final collection = _isar.isarInvoices;
      
      // Get all invoices for calculations
      final allInvoices = await collection.filter().deletedAtIsNull().findAll();
      
      // Calculate stats
      final totalInvoices = allInvoices.length;
      final paidInvoices = allInvoices.where((inv) => inv.status == IsarInvoiceStatus.paid).length;
      final pendingInvoices = allInvoices.where((inv) => inv.status == IsarInvoiceStatus.pending).length;
      final cancelledInvoices = allInvoices.where((inv) => inv.status == IsarInvoiceStatus.cancelled).length;
      
      final totalAmount = allInvoices.fold<double>(0, (sum, inv) => sum + inv.total);
      final paidAmount = allInvoices
          .where((inv) => inv.status == IsarInvoiceStatus.paid)
          .fold<double>(0, (sum, inv) => sum + inv.total);
      final pendingAmount = allInvoices
          .where((inv) => inv.status == IsarInvoiceStatus.pending)
          .fold<double>(0, (sum, inv) => sum + inv.total);
      
      // Count overdue invoices
      final now = DateTime.now();
      final overdueInvoices = allInvoices
          .where((inv) => inv.status == IsarInvoiceStatus.pending && inv.dueDate.isBefore(now))
          .length;

      final stats = InvoiceStats(
        total: totalInvoices,
        draft: 0, // Not tracked in current implementation
        pending: pendingInvoices,
        paid: paidInvoices,
        overdue: overdueInvoices,
        cancelled: cancelledInvoices,
        partiallyPaid: 0, // Not tracked in current implementation
        totalSales: totalAmount,
        pendingAmount: pendingAmount,
        overdueAmount: allInvoices
            .where((inv) => inv.status == IsarInvoiceStatus.pending && inv.dueDate.isBefore(now))
            .fold<double>(0, (sum, inv) => sum + inv.total),
      );

      print('✅ ISAR: Estadísticas cargadas');
      return Right(stats);
    } catch (e) {
      print('❌ ISAR: Error loading invoice stats: $e');
      return Left(CacheFailure('Error loading invoice stats: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getInvoicesByCustomer(String customerId) async {
    try {
      final isarInvoices = await _isar.isarInvoices
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

  // ==================== WRITE OPERATIONS (STUB IMPLEMENTATIONS) ====================
  // For offline mode, these return errors since they require server operations

  @override
  Future<Either<Failure, Invoice>> createInvoice({
    required String customerId,
    required List items, // Using dynamic to avoid type issues
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
    return Left(ServerFailure('Create invoice not available offline'));
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
    List? items,
  }) async {
    return Left(ServerFailure('Update invoice not available offline'));
  }

  @override
  Future<Either<Failure, Invoice>> confirmInvoice(String id) async {
    return Left(ServerFailure('Confirm invoice not available offline'));
  }

  @override
  Future<Either<Failure, Invoice>> cancelInvoice(String id) async {
    return Left(ServerFailure('Cancel invoice not available offline'));
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
    return Left(ServerFailure('Add payment not available offline'));
  }

  @override
  Future<Either<Failure, MultiplePaymentsResult>> addMultiplePayments({
    required String invoiceId,
    required List<PaymentItemData> payments,
    DateTime? paymentDate,
    bool createCreditForRemaining = false,
    String? generalNotes,
  }) async {
    return Left(ServerFailure('Add multiple payments not available offline'));
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    return Left(ServerFailure('Delete invoice not available offline'));
  }

  @override
  Future<Either<Failure, List<int>>> downloadInvoicePdf(String id) async {
    return Left(ServerFailure('Download PDF not available offline'));
  }

  // ==================== CACHE OPERATIONS ====================

  Future<Either<Failure, Unit>> bulkInsertInvoices(List<Invoice> invoices) async {
    try {
      final isarInvoices = invoices.map((inv) => IsarInvoice.fromEntity(inv)).toList();
      
      await _isar.writeTxn(() async {
        await _isar.isarInvoices.putAll(isarInvoices);
      });
      
      return Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error bulk inserting invoices: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Unit>> clearInvoiceCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarInvoices.clear();
      });
      
      return Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error clearing invoice cache: ${e.toString()}'));
    }
  }

  // ==================== HELPER METHODS ====================

  IsarInvoiceStatus _mapInvoiceStatusToIsar(InvoiceStatus status) {
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
}