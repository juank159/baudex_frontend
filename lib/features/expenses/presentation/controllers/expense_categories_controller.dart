// lib/features/expenses/presentation/controllers/expense_categories_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/usecases/get_expense_categories_usecase.dart';
import '../../domain/usecases/create_expense_category_usecase.dart';
import '../../domain/usecases/update_expense_category_usecase.dart';
import '../../domain/usecases/delete_expense_category_usecase.dart';
import '../../../../app/core/utils/formatters.dart';

class ExpenseCategoriesController extends GetxController {
  // Dependencies
  final GetExpenseCategoriesUseCase _getExpenseCategoriesUseCase;
  final CreateExpenseCategoryUseCase _createExpenseCategoryUseCase;
  final UpdateExpenseCategoryUseCase _updateExpenseCategoryUseCase;
  final DeleteExpenseCategoryUseCase _deleteExpenseCategoryUseCase;

  ExpenseCategoriesController({
    required GetExpenseCategoriesUseCase getExpenseCategoriesUseCase,
    required CreateExpenseCategoryUseCase createExpenseCategoryUseCase,
    required UpdateExpenseCategoryUseCase updateExpenseCategoryUseCase,
    required DeleteExpenseCategoryUseCase deleteExpenseCategoryUseCase,
  }) : _getExpenseCategoriesUseCase = getExpenseCategoriesUseCase,
       _createExpenseCategoryUseCase = createExpenseCategoryUseCase,
       _updateExpenseCategoryUseCase = updateExpenseCategoryUseCase,
       _deleteExpenseCategoryUseCase = deleteExpenseCategoryUseCase;

  // Observable state
  final _isLoading = false.obs;
  final _isCreating = false.obs;
  final _isUpdating = false.obs;
  final _isDeleting = false.obs;
  final categories = <ExpenseCategory>[].obs;
  final filteredCategories = <ExpenseCategory>[].obs;
  final searchQuery = ''.obs;
  final selectedCategory = Rxn<ExpenseCategory>();

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isCreating => _isCreating.value;
  bool get isUpdating => _isUpdating.value;
  bool get isDeleting => _isDeleting.value;

  @override
  void onInit() {
    super.onInit();
    loadCategories();

    // Listen to search query changes
    debounce(
      searchQuery,
      (_) => _filterCategories(),
      time: const Duration(milliseconds: 300),
    );
  }

  // Load all categories with statistics
  Future<void> loadCategories({bool withStats = true}) async {
    _isLoading.value = true;

    try {
      final result = await _getExpenseCategoriesUseCase(
        GetExpenseCategoriesParams(limit: 100, withStats: withStats),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar categorías', failure.message);
          categories.clear();
          filteredCategories.clear();
        },
        (paginatedResult) {
          categories.value = paginatedResult.data;
          _filterCategories();
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // Create new category
  Future<bool> createCategory({
    required String name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
  }) async {
    _isCreating.value = true;

    try {
      final result = await _createExpenseCategoryUseCase(
        CreateExpenseCategoryParams(
          name: name,
          description: description,
          color: color,
          monthlyBudget: monthlyBudget,
          sortOrder: sortOrder,
        ),
      );

      return result.fold(
        (failure) {
          _showError('Error al crear categoría', failure.message);
          return false;
        },
        (category) {
          categories.add(category);
          _filterCategories();
          _showSuccess('Categoría creada exitosamente');
          return true;
        },
      );
    } finally {
      _isCreating.value = false;
    }
  }

  // Update existing category
  Future<bool> updateCategory({
    required String id,
    String? name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
    ExpenseCategoryStatus? status,
  }) async {
    _isUpdating.value = true;

    try {
      final result = await _updateExpenseCategoryUseCase(
        UpdateExpenseCategoryParams(
          id: id,
          name: name,
          description: description,
          color: color,
          monthlyBudget: monthlyBudget,
          sortOrder: sortOrder,
          status: status,
        ),
      );

      return result.fold(
        (failure) {
          _showError('Error al actualizar categoría', failure.message);
          return false;
        },
        (updatedCategory) {
          final index = categories.indexWhere((cat) => cat.id == id);
          if (index != -1) {
            categories[index] = updatedCategory;
            _filterCategories();
          }
          _showSuccess('Categoría actualizada exitosamente');
          return true;
        },
      );
    } finally {
      _isUpdating.value = false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String id) async {
    _isDeleting.value = true;

    try {
      final result = await _deleteExpenseCategoryUseCase(
        DeleteExpenseCategoryParams(id: id),
      );

      return result.fold(
        (failure) {
          _showError('Error al eliminar categoría', failure.message);
          return false;
        },
        (_) {
          categories.removeWhere((cat) => cat.id == id);
          _filterCategories();
          selectedCategory.value = null;
          _showSuccess('Categoría eliminada exitosamente');
          return true;
        },
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  // Toggle category status
  Future<void> toggleCategoryStatus(ExpenseCategory category) async {
    final newStatus =
        category.status == ExpenseCategoryStatus.active
            ? ExpenseCategoryStatus.inactive
            : ExpenseCategoryStatus.active;

    await updateCategory(id: category.id, status: newStatus);
  }

  // Search functionality
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void _filterCategories() {
    if (searchQuery.value.isEmpty) {
      filteredCategories.value = categories.toList();
    } else {
      filteredCategories.value =
          categories.where((category) {
            final searchLower = searchQuery.value.toLowerCase();
            return category.name.toLowerCase().contains(searchLower) ||
                (category.description?.toLowerCase().contains(searchLower) ??
                    false);
          }).toList();
    }
  }

  // Category selection
  void selectCategory(ExpenseCategory? category) {
    selectedCategory.value = category;
  }

  // Refresh data
  Future<void> refreshCategories() async {
    await loadCategories();
  }

  // Helper methods
  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
  }

  // Statistics
  int get totalCategories => categories.length;
  int get activeCategories => categories.where((cat) => cat.isActive).length;
  int get inactiveCategories => categories.where((cat) => !cat.isActive).length;
  double get totalBudget =>
      categories.fold(0.0, (sum, cat) => sum + cat.monthlyBudget);
  String get formattedTotalBudget => AppFormatters.formatCurrency(totalBudget);
}
