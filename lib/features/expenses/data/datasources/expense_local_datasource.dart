// lib/features/expenses/data/datasources/expense_local_datasource.dart
import 'dart:convert';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../models/expense_model.dart';
import '../models/expense_category_model.dart';

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
      final expenses = await getCachedExpenses();
      final existingIndex = expenses.indexWhere((e) => e.id == expense.id);
      
      if (existingIndex != -1) {
        expenses[existingIndex] = expense;
      } else {
        expenses.add(expense);
      }
      
      await cacheExpenses(expenses);
    } catch (e) {
      print('⚠️ Error al cachear gasto: $e');
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