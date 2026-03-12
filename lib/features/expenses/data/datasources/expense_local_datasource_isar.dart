// lib/features/expenses/data/datasources/expense_local_datasource_isar.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/data/local/isar_database.dart';
import '../models/expense_model.dart';
import '../models/expense_category_model.dart';
import '../models/isar/isar_expense.dart';
import 'expense_local_datasource.dart';

class ExpenseLocalDataSourceIsar implements ExpenseLocalDataSource {
  ExpenseLocalDataSourceIsar();

  Isar get _isar => IsarDatabase.instance.database;

  SecureStorageService get _secureStorage => Get.find<SecureStorageService>();

  /// Cache en memoria para acceso rápido (se carga desde SecureStorage al inicio)
  final Map<String, ExpenseCategoryModel> _categoriesCache = {};
  bool _categoriesCacheLoaded = false;

  @override
  Future<List<ExpenseModel>> getCachedExpenses() async {
    try {
      final isarExpenses = await _isar.isarExpenses.where().findAll();

      return isarExpenses.map((isarExpense) {
        final entity = isarExpense.toEntity();
        return ExpenseModel.fromEntity(entity);
      }).toList();
    } catch (e) {
      throw CacheException('Failed to get cached expenses: $e');
    }
  }

  @override
  Future<void> cacheExpenses(List<ExpenseModel> expenses) async {
    try {
      await _isar.writeTxn(() async {
        final isarExpenses = expenses.map((expense) {
          return IsarExpense.fromEntity(expense);
        }).toList();

        await _isar.isarExpenses.putAllByServerId(isarExpenses);
      });
    } catch (e) {
      throw CacheException('Failed to cache expenses: $e');
    }
  }

  @override
  Future<ExpenseModel?> getCachedExpenseById(String id) async {
    try {
      final isarExpense = await _isar.isarExpenses
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarExpense == null) {
        return null;
      }

      final entity = isarExpense.toEntity();
      return ExpenseModel.fromEntity(entity);
    } catch (e) {
      throw CacheException('Failed to get cached expense by id: $e');
    }
  }

  @override
  Future<void> cacheExpense(ExpenseModel expense) async {
    try {
      await _isar.writeTxn(() async {
        final isarExpense = IsarExpense.fromEntity(expense);
        await _isar.isarExpenses.putByServerId(isarExpense);
      });
    } catch (e) {
      throw CacheException('Failed to cache expense: $e');
    }
  }

  @override
  Future<void> removeCachedExpense(String id) async {
    try {
      await _isar.writeTxn(() async {
        final isarExpense = await _isar.isarExpenses
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (isarExpense != null) {
          await _isar.isarExpenses.delete(isarExpense.id);
        }
      });
    } catch (e) {
      throw CacheException('Failed to remove cached expense: $e');
    }
  }

  @override
  Future<void> clearExpensesCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarExpenses.clear();
      });
    } catch (e) {
      throw CacheException('Failed to clear expenses cache: $e');
    }
  }

  /// Carga categorías desde SecureStorage al cache en memoria si no se ha hecho
  Future<void> _ensureCategoriesCacheLoaded() async {
    if (_categoriesCacheLoaded) return;
    try {
      final cached = await _secureStorage.read(ApiConstants.expenseCategoriesCacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = json.decode(cached);
        _categoriesCache.clear();
        for (final jsonItem in jsonList) {
          final cat = ExpenseCategoryModel.fromJson(jsonItem);
          _categoriesCache[cat.id] = cat;
        }
      }
      _categoriesCacheLoaded = true;
    } catch (e) {
      print('⚠️ Error cargando categorías desde SecureStorage: $e');
      _categoriesCacheLoaded = true;
    }
  }

  /// Persiste el cache en memoria a SecureStorage
  Future<void> _persistCategoriesToStorage() async {
    try {
      final jsonList = _categoriesCache.values
          .map((category) => category.toJson())
          .toList();
      await _secureStorage.write(
        ApiConstants.expenseCategoriesCacheKey,
        json.encode(jsonList),
      );
    } catch (e) {
      print('⚠️ Error persistiendo categorías a SecureStorage: $e');
    }
  }

  @override
  Future<List<ExpenseCategoryModel>> getCachedExpenseCategories() async {
    try {
      await _ensureCategoriesCacheLoaded();
      return _categoriesCache.values.toList();
    } catch (e) {
      throw CacheException('Failed to get cached expense categories: $e');
    }
  }

  @override
  Future<void> cacheExpenseCategories(
    List<ExpenseCategoryModel> categories,
  ) async {
    try {
      _categoriesCache.clear();
      for (final category in categories) {
        _categoriesCache[category.id] = category;
      }
      _categoriesCacheLoaded = true;
      await _persistCategoriesToStorage();
    } catch (e) {
      throw CacheException('Failed to cache expense categories: $e');
    }
  }

  @override
  Future<ExpenseCategoryModel?> getCachedExpenseCategoryById(String id) async {
    try {
      await _ensureCategoriesCacheLoaded();
      return _categoriesCache[id];
    } catch (e) {
      throw CacheException('Failed to get cached expense category by id: $e');
    }
  }

  @override
  Future<void> cacheExpenseCategory(ExpenseCategoryModel category) async {
    try {
      await _ensureCategoriesCacheLoaded();
      _categoriesCache[category.id] = category;
      await _persistCategoriesToStorage();
    } catch (e) {
      throw CacheException('Failed to cache expense category: $e');
    }
  }

  @override
  Future<void> removeCachedExpenseCategory(String id) async {
    try {
      await _ensureCategoriesCacheLoaded();
      _categoriesCache.remove(id);
      await _persistCategoriesToStorage();
    } catch (e) {
      throw CacheException('Failed to remove cached expense category: $e');
    }
  }

  @override
  Future<void> clearExpenseCategoriesCache() async {
    try {
      _categoriesCache.clear();
      _categoriesCacheLoaded = false;
      await _secureStorage.delete(ApiConstants.expenseCategoriesCacheKey);
    } catch (e) {
      throw CacheException('Failed to clear expense categories cache: $e');
    }
  }
}
