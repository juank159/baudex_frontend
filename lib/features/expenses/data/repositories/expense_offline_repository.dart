// lib/features/expenses/data/repositories/expense_offline_repository.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/services/file_service.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_stats.dart';
import '../../domain/repositories/expense_repository.dart';
import '../models/isar/isar_expense.dart';
import '../models/isar/isar_expense_category.dart';

/// Implementacion offline del repositorio de gastos usando ISAR
class ExpenseOfflineRepository implements ExpenseRepository {
  final IsarDatabase _database;

  ExpenseOfflineRepository({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  /// YYYY-MM-DD usando componentes locales del DateTime. Si es TZDateTime del
  /// tenant, preserva el día correcto. toIso8601String() convierte a UTC y
  /// puede correr el día al siguiente.
  static String _ymd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // ==================== EXPENSE READ OPERATIONS ====================

  @override
  Future<Either<Failure, PaginatedResponse<Expense>>> getExpenses({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? orderBy,
    String? orderDirection,
  }) async {
    try {
      var query = _isar.isarExpenses.filter().deletedAtIsNull();

      // Apply filters
      if (search != null && search.isNotEmpty) {
        query = query.and().group((q) => q
            .descriptionContains(search, caseSensitive: false)
            .or()
            .vendorContains(search, caseSensitive: false));
      }

      if (status != null) {
        final isarStatus = _mapExpenseStatusString(status);
        if (isarStatus != null) {
          query = query.and().statusEqualTo(isarStatus);
        }
      }

      if (type != null) {
        final isarType = _mapExpenseTypeString(type);
        if (isarType != null) {
          query = query.and().typeEqualTo(isarType);
        }
      }

      if (categoryId != null) {
        query = query.and().categoryIdEqualTo(categoryId);
      }

      if (startDate != null) {
        query = query.and().dateGreaterThan(startDate);
      }

      if (endDate != null) {
        query = query.and().dateLessThan(endDate);
      }

      // Obtener todos los resultados (ordenar y paginar en Dart)
      final allResults = await query.findAll();
      final total = allResults.length;

      // Ordenar en Dart
      allResults.sort((a, b) {
        final comparison = a.date.compareTo(b.date);
        return orderDirection == 'desc' ? -comparison : comparison;
      });

      // Paginar manualmente
      final offset = (page - 1) * limit;
      final start = offset.clamp(0, allResults.length);
      final end = (start + limit).clamp(0, allResults.length);
      final isarExpenses = allResults.sublist(start, end);

      final expenses = isarExpenses.map((e) => e.toEntity()).toList();

      final meta = PaginationMeta(
        page: page,
        limit: limit,
        total: total,
        totalPages: (total / limit).ceil(),
        hasNext: page * limit < total,
        hasPrev: page > 1,
      );

      return Right(PaginatedResponse(data: expenses, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error loading expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> getExpenseById(String id) async {
    try {
      final isarExpense = await _isar.isarExpenses
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarExpense == null) {
        return Left(CacheFailure('Expense not found'));
      }

      return Right(isarExpense.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading expense: ${e.toString()}'));
    }
  }

  // ==================== EXPENSE WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, Expense>> createExpense({
    required String description,
    required double amount,
    required DateTime date,
    required String categoryId,
    required ExpenseType type,
    required PaymentMethod paymentMethod,
    String? vendor,
    String? invoiceNumber,
    String? reference,
    String? notes,
    List<String>? attachments,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    ExpenseStatus? status,
    String? createdById,
  }) async {
    try {
      final now = DateTime.now();
      final serverId = 'expense_${now.millisecondsSinceEpoch}_${description.hashCode}';

      final isarExpense = IsarExpense.create(
        serverId: serverId,
        description: description,
        amount: amount,
        date: date,
        status: _mapExpenseStatus(status ?? ExpenseStatus.draft),
        type: _mapExpenseType(type),
        paymentMethod: _mapPaymentMethod(paymentMethod),
        vendor: vendor,
        invoiceNumber: invoiceNumber,
        reference: reference,
        notes: notes,
        attachmentsJson: attachments?.isNotEmpty == true
            ? attachments!.join('|')
            : null,
        tagsJson: tags?.isNotEmpty == true ? tags!.join('|') : null,
        metadataJson: metadata?.toString(),
        categoryId: categoryId,
        createdById: createdById ?? 'offline',
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      await _isar.writeTxn(() async {
        await _isar.isarExpenses.put(isarExpense);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Expense',
          entityId: serverId,
          operationType: SyncOperationType.create,
          data: {
            'description': description,
            'amount': amount,
            // YYYY-MM-DD en TZ del tenant (ver nota en _ymd abajo).
            'date': _ymd(date),
            'categoryId': categoryId,
            'type': type.name,
            'paymentMethod': paymentMethod.name,
            'status': status?.name,
          },
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarExpense.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense({
    required String id,
    String? description,
    double? amount,
    DateTime? date,
    String? categoryId,
    ExpenseType? type,
    PaymentMethod? paymentMethod,
    String? vendor,
    String? invoiceNumber,
    String? reference,
    String? notes,
    List<String>? attachments,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final isarExpense = await _isar.isarExpenses
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarExpense == null) {
        return Left(CacheFailure('Expense not found'));
      }

      if (description != null) isarExpense.description = description;
      if (amount != null) isarExpense.amount = amount;
      if (date != null) isarExpense.date = date;
      if (categoryId != null) isarExpense.categoryId = categoryId;
      if (type != null) isarExpense.type = _mapExpenseType(type);
      if (paymentMethod != null) {
        isarExpense.paymentMethod = _mapPaymentMethod(paymentMethod);
      }
      if (vendor != null) isarExpense.vendor = vendor;
      if (invoiceNumber != null) isarExpense.invoiceNumber = invoiceNumber;
      if (reference != null) isarExpense.reference = reference;
      if (notes != null) isarExpense.notes = notes;
      if (attachments != null) {
        isarExpense.attachmentsJson = attachments.isNotEmpty ? attachments.join('|') : null;
      }
      if (tags != null) {
        isarExpense.tagsJson = tags.isNotEmpty ? tags.join('|') : null;
      }
      if (metadata != null) {
        isarExpense.metadataJson = metadata.toString();
      }

      isarExpense.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarExpenses.put(isarExpense);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Expense',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'updated': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarExpense.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    try {
      final isarExpense = await _isar.isarExpenses
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarExpense == null) {
        return Left(CacheFailure('Expense not found'));
      }

      isarExpense.softDelete();

      await _isar.writeTxn(() async {
        await _isar.isarExpenses.put(isarExpense);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Expense',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'deleted': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error deleting expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> submitExpense(String id) async {
    try {
      final isarExpense = await _isar.isarExpenses
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarExpense == null) {
        return Left(CacheFailure('Expense not found'));
      }

      isarExpense.status = IsarExpenseStatus.pending;
      isarExpense.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarExpenses.put(isarExpense);
      });

      return Right(isarExpense.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error submitting expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> approveExpense({
    required String id,
    String? notes,
  }) async {
    try {
      final isarExpense = await _isar.isarExpenses
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarExpense == null) {
        return Left(CacheFailure('Expense not found'));
      }

      isarExpense.approve('offline_user'); // TODO: Get actual user ID

      await _isar.writeTxn(() async {
        await _isar.isarExpenses.put(isarExpense);
      });

      return Right(isarExpense.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error approving expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> rejectExpense({
    required String id,
    required String reason,
  }) async {
    try {
      final isarExpense = await _isar.isarExpenses
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarExpense == null) {
        return Left(CacheFailure('Expense not found'));
      }

      isarExpense.reject(reason);

      await _isar.writeTxn(() async {
        await _isar.isarExpenses.put(isarExpense);
      });

      return Right(isarExpense.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error rejecting expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> markAsPaid(String id) async {
    try {
      final isarExpense = await _isar.isarExpenses
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarExpense == null) {
        return Left(CacheFailure('Expense not found'));
      }

      isarExpense.markAsPaid();

      await _isar.writeTxn(() async {
        await _isar.isarExpenses.put(isarExpense);
      });

      return Right(isarExpense.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error marking expense as paid: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> searchExpenses(String query) async {
    try {
      final isarExpenses = await _isar.isarExpenses
          .filter()
          .deletedAtIsNull()
          .and()
          .group((q) => q
              .descriptionContains(query, caseSensitive: false)
              .or()
              .vendorContains(query, caseSensitive: false))
          .findAll();

      return Right(isarExpenses.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Error searching expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ExpenseStats>> getExpenseStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _isar.isarExpenses.filter().deletedAtIsNull();

      if (startDate != null) {
        query = query.and().dateGreaterThan(startDate);
      }

      if (endDate != null) {
        query = query.and().dateLessThan(endDate);
      }

      final expenses = await query.findAll();

      final totalExpenses = expenses.length;
      final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);

      final approvedExpenses = expenses.where((e) => e.isApproved).length;
      final pendingExpenses = expenses.where((e) => e.isPending).length;
      final rejectedExpenses = expenses.where((e) => e.isRejected).length;
      final paidExpenses = expenses.where((e) => e.isPaid).length;

      final approvedAmount = expenses
          .where((e) => e.isApproved)
          .fold(0.0, (sum, e) => sum + e.amount);

      final pendingAmount = expenses
          .where((e) => e.isPending)
          .fold(0.0, (sum, e) => sum + e.amount);

      final rejectedAmount = expenses
          .where((e) => e.isRejected)
          .fold(0.0, (sum, e) => sum + e.amount);

      final paidAmount = expenses
          .where((e) => e.isPaid)
          .fold(0.0, (sum, e) => sum + e.amount);

      // Group by category
      final expensesByCategory = <String, double>{};
      for (var expense in expenses) {
        expensesByCategory[expense.categoryId] =
            (expensesByCategory[expense.categoryId] ?? 0.0) + expense.amount;
      }

      // Group by type
      final expensesByType = <String, double>{};
      for (var expense in expenses) {
        final typeKey = expense.type.name;
        expensesByType[typeKey] =
            (expensesByType[typeKey] ?? 0.0) + expense.amount;
      }

      // Group by status
      final expensesByStatus = <String, int>{};
      for (var expense in expenses) {
        final statusKey = expense.status.name;
        expensesByStatus[statusKey] =
            (expensesByStatus[statusKey] ?? 0) + 1;
      }

      final stats = ExpenseStats(
        totalExpenses: totalExpenses,
        totalAmount: totalAmount,
        approvedExpenses: approvedExpenses,
        pendingExpenses: pendingExpenses,
        rejectedExpenses: rejectedExpenses,
        averageExpenseAmount: totalExpenses > 0 ? totalAmount / totalExpenses : 0.0,
        approvedAmount: approvedAmount,
        pendingAmount: pendingAmount,
        rejectedAmount: rejectedAmount,
        paidAmount: paidAmount,
        paidExpenses: paidExpenses,
        dailyAmount: 0.0, // TODO: Calculate
        weeklyAmount: 0.0, // TODO: Calculate
        monthlyAmount: 0.0, // TODO: Calculate
        monthlyCount: 0, // TODO: Calculate
        expensesByStatus: expensesByStatus,
        expensesByType: expensesByType,
        expensesByCategory: expensesByCategory,
        monthlyTrends: const [], // TODO: Calculate
      );

      return Right(stats);
    } catch (e) {
      return Left(CacheFailure('Error getting expense stats: ${e.toString()}'));
    }
  }

  // ==================== EXPENSE CATEGORY OPERATIONS ====================

  @override
  Future<Either<Failure, PaginatedResponse<ExpenseCategory>>> getExpenseCategories({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? orderBy,
    String? orderDirection,
  }) async {
    try {
      // Note: IsarExpenseCategory is not a proper Isar collection
      // This is a stub implementation
      final meta = PaginationMeta(
        page: page,
        limit: limit,
        total: 0,
        totalPages: 0,
        hasNext: false,
        hasPrev: false,
      );

      return Right(PaginatedResponse(data: <ExpenseCategory>[], meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error loading expense categories: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<ExpenseCategory>>> getExpenseCategoriesWithStats({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? orderBy,
    String? orderDirection,
  }) async {
    return getExpenseCategories(
      page: page,
      limit: limit,
      search: search,
      status: status,
      orderBy: orderBy,
      orderDirection: orderDirection,
    );
  }

  @override
  Future<Either<Failure, ExpenseCategory>> getExpenseCategoryById(String id) async {
    return Left(CacheFailure('Expense category not found'));
  }

  @override
  Future<Either<Failure, ExpenseCategory>> createExpenseCategory({
    required String name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
  }) async {
    return Left(ServerFailure('Create expense category not supported offline'));
  }

  @override
  Future<Either<Failure, ExpenseCategory>> updateExpenseCategory({
    required String id,
    String? name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
    ExpenseCategoryStatus? status,
  }) async {
    return Left(ServerFailure('Update expense category not supported offline'));
  }

  @override
  Future<Either<Failure, void>> deleteExpenseCategory(String id) async {
    return Left(ServerFailure('Delete expense category not supported offline'));
  }

  @override
  Future<Either<Failure, List<ExpenseCategory>>> searchExpenseCategories(String query) async {
    try {
      return Right(<ExpenseCategory>[]);
    } catch (e) {
      return Left(CacheFailure('Error searching expense categories: ${e.toString()}'));
    }
  }

  // ==================== ATTACHMENT OPERATIONS ====================

  @override
  Future<Either<Failure, List<String>>> uploadAttachments(
    String expenseId,
    List<AttachmentFile> files,
  ) async {
    return Left(ServerFailure('Upload attachments not supported offline'));
  }

  @override
  Future<Either<Failure, void>> deleteAttachment(
    String expenseId,
    String filename,
  ) async {
    return Left(ServerFailure('Delete attachment not supported offline'));
  }

  // ==================== SYNC OPERATIONS ====================

  Future<List<Expense>> getUnsyncedExpenses() async {
    try {
      final isarExpenses = await _isar.isarExpenses
          .filter()
          .isSyncedEqualTo(false)
          .findAll();

      return isarExpenses.map((e) => e.toEntity()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markAsSynced(List<String> ids) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in ids) {
          final isarExpense = await _isar.isarExpenses
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarExpense != null) {
            isarExpense.markAsSynced();
            await _isar.isarExpenses.put(isarExpense);
          }
        }
      });
    } catch (e) {
      print('Error marking expenses as synced: $e');
    }
  }

  Future<void> bulkInsertExpenses(List<Expense> expenses) async {
    try {
      final isarExpenses = expenses
          .map((expense) => IsarExpense.fromEntity(expense))
          .toList();

      await _isar.writeTxn(() async {
        await _isar.isarExpenses.putAll(isarExpenses);
      });
    } catch (e) {
      print('Error bulk inserting expenses: $e');
    }
  }

  // ==================== EXTRA METHODS ====================

  /// Get expenses by category
  Future<Either<Failure, List<Expense>>> getByCategory(String categoryId) async {
    try {
      final isarExpenses = await _isar.isarExpenses
          .filter()
          .deletedAtIsNull()
          .and()
          .categoryIdEqualTo(categoryId)
          .sortByDateDesc()
          .findAll();

      return Right(isarExpenses.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Error loading expenses by category: ${e.toString()}'));
    }
  }

  /// Get expenses by date range
  Future<Either<Failure, List<Expense>>> getByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final isarExpenses = await _isar.isarExpenses
          .filter()
          .deletedAtIsNull()
          .and()
          .dateBetween(startDate, endDate)
          .sortByDateDesc()
          .findAll();

      return Right(isarExpenses.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Error loading expenses by date range: ${e.toString()}'));
    }
  }

  // ==================== HELPER METHODS ====================

  IsarExpenseStatus _mapExpenseStatus(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return IsarExpenseStatus.draft;
      case ExpenseStatus.pending:
        return IsarExpenseStatus.pending;
      case ExpenseStatus.approved:
        return IsarExpenseStatus.approved;
      case ExpenseStatus.rejected:
        return IsarExpenseStatus.rejected;
      case ExpenseStatus.paid:
        return IsarExpenseStatus.paid;
    }
  }

  IsarExpenseStatus? _mapExpenseStatusString(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return IsarExpenseStatus.draft;
      case 'pending':
        return IsarExpenseStatus.pending;
      case 'approved':
        return IsarExpenseStatus.approved;
      case 'rejected':
        return IsarExpenseStatus.rejected;
      case 'paid':
        return IsarExpenseStatus.paid;
      default:
        return null;
    }
  }

  IsarExpenseType _mapExpenseType(ExpenseType type) {
    switch (type) {
      case ExpenseType.operating:
        return IsarExpenseType.operating;
      case ExpenseType.administrative:
        return IsarExpenseType.administrative;
      case ExpenseType.sales:
        return IsarExpenseType.sales;
      case ExpenseType.financial:
        return IsarExpenseType.financial;
      case ExpenseType.extraordinary:
        return IsarExpenseType.extraordinary;
    }
  }

  IsarExpenseType? _mapExpenseTypeString(String type) {
    switch (type.toLowerCase()) {
      case 'operating':
        return IsarExpenseType.operating;
      case 'administrative':
        return IsarExpenseType.administrative;
      case 'sales':
        return IsarExpenseType.sales;
      case 'financial':
        return IsarExpenseType.financial;
      case 'extraordinary':
        return IsarExpenseType.extraordinary;
      default:
        return null;
    }
  }

  IsarPaymentMethod _mapPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return IsarPaymentMethod.cash;
      case PaymentMethod.creditCard:
        return IsarPaymentMethod.creditCard;
      case PaymentMethod.debitCard:
        return IsarPaymentMethod.debitCard;
      case PaymentMethod.bankTransfer:
        return IsarPaymentMethod.bankTransfer;
      case PaymentMethod.check:
        return IsarPaymentMethod.check;
      case PaymentMethod.other:
        return IsarPaymentMethod.other;
    }
  }
}
