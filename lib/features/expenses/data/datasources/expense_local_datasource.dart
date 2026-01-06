// lib/features/expenses/data/datasources/expense_local_datasource.dart
import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../models/expense_model.dart';
import '../models/expense_category_model.dart';
import '../models/isar/isar_expense.dart';

abstract class ExpenseLocalDataSource {
  Future<List<ExpenseModel>> getCachedExpenses();
  Future<void> cacheExpenses(List<ExpenseModel> expenses);
  Future<ExpenseModel?> getCachedExpenseById(String id);
  Future<void> cacheExpense(ExpenseModel expense);
  Future<void> removeCachedExpense(String id);
  Future<void> clearExpensesCache();
  
  Future<List<ExpenseCategoryModel>> getCachedExpenseCategories();
  Future<void> cacheExpenseCategories(List<ExpenseCategoryModel> categories);
  Future<ExpenseCategoryModel?> getCachedExpenseCategoryById(String id);
  Future<void> cacheExpenseCategory(ExpenseCategoryModel category);
  Future<void> removeCachedExpenseCategory(String id);
  Future<void> clearExpenseCategoriesCache();
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final SecureStorageService secureStorage;

  ExpenseLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<List<ExpenseModel>> getCachedExpenses() async {
    try {
      final cached = await secureStorage.read(ApiConstants.expensesCacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = json.decode(cached);
        return jsonList.map((json) => ExpenseModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error al obtener gastos cacheados: $e');
      return [];
    }
  }

  @override
  Future<void> cacheExpenses(List<ExpenseModel> expenses) async {
    try {
      final jsonList = expenses.map((expense) => expense.toJson()).toList();
      await secureStorage.write(
        ApiConstants.expensesCacheKey,
        json.encode(jsonList),
      );
    } catch (e) {
      print('⚠️ Error al cachear gastos: $e');
    }
  }

  @override
  Future<ExpenseModel?> getCachedExpenseById(String id) async {
    try {
      final expenses = await getCachedExpenses();
      return expenses.firstWhere(
        (expense) => expense.id == id,
        orElse: () => throw StateError('Expense not found'),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheExpense(ExpenseModel expense) async {
    try {
      // ✅ GUARDAR EN ISAR PRIMERO (persistencia offline real)
      try {
        final isar = IsarDatabase.instance.database;
        await isar.writeTxn(() async {
          // Buscar si existe
          var isarExpense = await isar.isarExpenses
              .filter()
              .serverIdEqualTo(expense.id)
              .findFirst();

          if (isarExpense != null) {
            // Actualizar existente - copiar todos los campos del expense
            isarExpense.serverId = expense.id;
            isarExpense.description = expense.description;
            isarExpense.amount = expense.amount;
            isarExpense.date = expense.date;
            isarExpense.status = _mapExpenseStatus(expense.status);
            isarExpense.type = _mapExpenseType(expense.type);
            isarExpense.paymentMethod = _mapPaymentMethod(expense.paymentMethod);
            isarExpense.vendor = expense.vendor;
            isarExpense.invoiceNumber = expense.invoiceNumber;
            isarExpense.reference = expense.reference;
            isarExpense.notes = expense.notes;
            isarExpense.attachmentsJson = expense.attachments?.isNotEmpty == true
                ? expense.attachments!.join('|')
                : null;
            isarExpense.tagsJson = expense.tags?.isNotEmpty == true
                ? expense.tags!.join('|')
                : null;
            isarExpense.metadataJson = expense.metadata?.toString();
            isarExpense.approvedById = expense.approvedById;
            isarExpense.approvedAt = expense.approvedAt;
            isarExpense.rejectionReason = expense.rejectionReason;
            isarExpense.categoryId = expense.categoryId;
            isarExpense.createdById = expense.createdById;
            isarExpense.createdAt = expense.createdAt;
            isarExpense.updatedAt = expense.updatedAt;
            isarExpense.deletedAt = expense.deletedAt;
            isarExpense.isSynced = true;
            isarExpense.lastSyncAt = DateTime.now();
          } else {
            // Crear nuevo desde entity
            isarExpense = IsarExpense.fromEntity(expense.toEntity());
          }

          await isar.isarExpenses.put(isarExpense);
        });
        print('✅ Expense guardado en ISAR: ${expense.id}');
      } catch (e) {
        print('⚠️ Error guardando en ISAR (continuando...): $e');
      }

      // Guardar en SecureStorage (fallback legacy)
      final expenses = await getCachedExpenses();
      final existingIndex = expenses.indexWhere((e) => e.id == expense.id);

      if (existingIndex != -1) {
        expenses[existingIndex] = expense;
      } else {
        expenses.add(expense);
      }

      await cacheExpenses(expenses);
    } catch (e) {
      // Fallar silenciosamente en lugar de lanzar excepción
      // Esto permite que la app funcione aunque el cache no esté disponible
      print('⚠️ Cache no disponible (continuando sin cache): $e');
    }
  }

  // Helper methods for enum mapping
  IsarExpenseStatus _mapExpenseStatus(dynamic status) {
    if (status is IsarExpenseStatus) return status;
    final statusStr = status.toString().split('.').last;
    switch (statusStr) {
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
        return IsarExpenseStatus.draft;
    }
  }

  IsarExpenseType _mapExpenseType(dynamic type) {
    if (type is IsarExpenseType) return type;
    final typeStr = type.toString().split('.').last;
    switch (typeStr) {
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
        return IsarExpenseType.operating;
    }
  }

  IsarPaymentMethod _mapPaymentMethod(dynamic method) {
    if (method is IsarPaymentMethod) return method;
    final methodStr = method.toString().split('.').last;
    switch (methodStr) {
      case 'cash':
        return IsarPaymentMethod.cash;
      case 'creditCard':
        return IsarPaymentMethod.creditCard;
      case 'debitCard':
        return IsarPaymentMethod.debitCard;
      case 'bankTransfer':
        return IsarPaymentMethod.bankTransfer;
      case 'check':
        return IsarPaymentMethod.check;
      case 'other':
        return IsarPaymentMethod.other;
      default:
        return IsarPaymentMethod.cash;
    }
  }

  @override
  Future<void> removeCachedExpense(String id) async {
    try {
      final expenses = await getCachedExpenses();
      expenses.removeWhere((expense) => expense.id == id);
      await cacheExpenses(expenses);
    } catch (e) {
      print('⚠️ Error al remover gasto del cache: $e');
    }
  }

  @override
  Future<void> clearExpensesCache() async {
    try {
      await secureStorage.delete(ApiConstants.expensesCacheKey);
    } catch (e) {
      print('⚠️ Error al limpiar cache de gastos: $e');
    }
  }

  @override
  Future<List<ExpenseCategoryModel>> getCachedExpenseCategories() async {
    try {
      final cached = await secureStorage.read(ApiConstants.expenseCategoriesCacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = json.decode(cached);
        return jsonList.map((json) => ExpenseCategoryModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error al obtener categorías cacheadas: $e');
      return [];
    }
  }

  @override
  Future<void> cacheExpenseCategories(List<ExpenseCategoryModel> categories) async {
    try {
      final jsonList = categories.map((category) => category.toJson()).toList();
      await secureStorage.write(
        ApiConstants.expenseCategoriesCacheKey,
        json.encode(jsonList),
      );
    } catch (e) {
      print('⚠️ Error al cachear categorías: $e');
    }
  }

  @override
  Future<ExpenseCategoryModel?> getCachedExpenseCategoryById(String id) async {
    try {
      final categories = await getCachedExpenseCategories();
      return categories.firstWhere(
        (category) => category.id == id,
        orElse: () => throw StateError('Category not found'),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheExpenseCategory(ExpenseCategoryModel category) async {
    try {
      final categories = await getCachedExpenseCategories();
      final existingIndex = categories.indexWhere((c) => c.id == category.id);
      
      if (existingIndex != -1) {
        categories[existingIndex] = category;
      } else {
        categories.add(category);
      }
      
      await cacheExpenseCategories(categories);
    } catch (e) {
      print('⚠️ Error al cachear categoría: $e');
    }
  }

  @override
  Future<void> removeCachedExpenseCategory(String id) async {
    try {
      final categories = await getCachedExpenseCategories();
      categories.removeWhere((category) => category.id == id);
      await cacheExpenseCategories(categories);
    } catch (e) {
      print('⚠️ Error al remover categoría del cache: $e');
    }
  }

  @override
  Future<void> clearExpenseCategoriesCache() async {
    try {
      await secureStorage.delete(ApiConstants.expenseCategoriesCacheKey);
    } catch (e) {
      print('⚠️ Error al limpiar cache de categorías: $e');
    }
  }
}