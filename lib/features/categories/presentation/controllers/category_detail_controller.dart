// lib/features/categories/presentation/controllers/category_detail_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_category_by_id_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';

class CategoryDetailController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Dependencies
  final GetCategoryByIdUseCase _getCategoryByIdUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;
  final DeleteCategoryUseCase _deleteCategoryUseCase;
  final UpdateCategoryUseCase _updateCategoryUseCase;

  CategoryDetailController({
    required GetCategoryByIdUseCase getCategoryByIdUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
    required DeleteCategoryUseCase deleteCategoryUseCase,
    required UpdateCategoryUseCase updateCategoryUseCase,
  }) : _getCategoryByIdUseCase = getCategoryByIdUseCase,
       _getCategoriesUseCase = getCategoriesUseCase,
       _deleteCategoryUseCase = deleteCategoryUseCase,
       _updateCategoryUseCase = updateCategoryUseCase;

  // ==================== OBSERVABLES ====================

  // Estados de carga
  final _isLoading = false.obs;
  final _isUpdatingStatus = false.obs;
  final _isDeleting = false.obs;

  // Datos
  final Rxn<Category> _category = Rxn<Category>();
  final _subcategories = <Category>[].obs;
  final _breadcrumbs = <Category>[].obs;

  // Tab controller para las pestañas
  late TabController tabController;
  
  // Tab management for futuristic interface
  final _selectedTab = 0.obs;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isUpdatingStatus => _isUpdatingStatus.value;
  bool get isDeleting => _isDeleting.value;

  Category? get category => _category.value;
  List<Category> get subcategories => _subcategories;
  List<Category> get breadcrumbs => _breadcrumbs;

  bool get hasCategory => _category.value != null;
  bool get hasSubcategories => _subcategories.isNotEmpty;
  
  // Tab getters
  RxInt get selectedTab => _selectedTab;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    // Inicializar TabController
    tabController = TabController(length: 3, vsync: this);

    final categoryId = Get.parameters['id'];
    if (categoryId != null) {
      loadCategoryDetail(categoryId);
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  /// Switch between tabs in futuristic interface
  void switchTab(int tabIndex) {
    if (tabIndex >= 0 && tabIndex <= 3) {
      _selectedTab.value = tabIndex;
    }
  }

  // ==================== PUBLIC METHODS ====================

  /// Cargar detalles de la categoría
  Future<void> loadCategoryDetail(String categoryId) async {
    _isLoading.value = true;

    try {
      final result = await _getCategoryByIdUseCase(
        GetCategoryByIdParams(id: categoryId),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar categoría', failure.message);
        },
        (category) {
          _category.value = category;
          _buildBreadcrumbs();
          _loadSubcategories(categoryId);
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Actualizar estado de la categoría
  Future<void> updateCategoryStatus(CategoryStatus newStatus) async {
    if (_category.value == null) return;

    _isUpdatingStatus.value = true;

    try {
      final currentCategory = _category.value!;
      final result = await _updateCategoryUseCase(
        UpdateCategoryParams(
          id: currentCategory.id,
          name: currentCategory.name,
          description: currentCategory.description,
          slug: currentCategory.slug,
          image: currentCategory.image,
          status: newStatus,
          sortOrder: currentCategory.sortOrder,
          parentId: currentCategory.parentId,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al actualizar estado', failure.message);
        },
        (updatedCategory) {
          _category.value = updatedCategory;
          _showSuccess('Estado actualizado exitosamente');
        },
      );
    } finally {
      _isUpdatingStatus.value = false;
    }
  }

  /// Eliminar categoría
  Future<void> deleteCategory() async {
    if (_category.value == null) return;

    _isDeleting.value = true;

    try {
      final result = await _deleteCategoryUseCase(
        DeleteCategoryParams(id: _category.value!.id),
      );

      result.fold(
        (failure) {
          _showError('Error al eliminar', failure.message);
        },
        (_) {
          _showSuccess('Categoría eliminada exitosamente');
          Get.back();
        },
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  /// Refrescar datos
  Future<void> refreshData() async {
    if (_category.value != null) {
      await loadCategoryDetail(_category.value!.id);
    }
  }

  // ==================== UI ACTIONS ====================

  /// Ir a editar categoría
  void goToEditCategory() {
    if (_category.value != null) {
      Get.toNamed('/categories/edit/${_category.value!.id}');
    }
  }

  /// Ir a crear subcategoría
  void goToCreateSubcategory() {
    if (_category.value != null) {
      Get.toNamed(
        '/categories/create',
        arguments: {
          'parentId': _category.value!.id,
          'parentName': _category.value!.name,
        },
      );
    }
  }

  /// Mostrar confirmación de eliminación
  void confirmDelete() {
    if (_category.value == null) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
          '¿Estás seguro que deseas eliminar la categoría "${_category.value!.name}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              deleteCategory();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de cambio de estado
  void showStatusDialog() {
    if (_category.value == null) return;

    final currentStatus = _category.value!.status;
    final newStatus =
        currentStatus == CategoryStatus.active
            ? CategoryStatus.inactive
            : CategoryStatus.active;

    Get.dialog(
      AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Text(
          '¿Deseas cambiar el estado de la categoría a ${newStatus.name.toUpperCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              updateCategoryStatus(newStatus);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  /// Navegar a categoría padre
  void goToParentCategory() {
    if (_category.value?.parent != null) {
      Get.offNamed('/categories/detail/${_category.value!.parent!.id}');
    }
  }

  /// Navegar a subcategoría
  void goToSubcategory(String subcategoryId) {
    Get.toNamed('/categories/detail/$subcategoryId');
  }

  // ==================== PRIVATE METHODS ====================

  /// Cargar subcategorías
  Future<void> _loadSubcategories(String parentId) async {
    try {
      final result = await _getCategoriesUseCase(
        GetCategoriesParams(
          parentId: parentId,
          limit: 100, // Cargar todas las subcategorías
        ),
      );

      result.fold(
        (failure) {
          print('Error al cargar subcategorías: ${failure.message}');
          _subcategories.clear();
        },
        (paginatedResult) {
          _subcategories.value = paginatedResult.data;
        },
      );
    } catch (e) {
      print('Error inesperado al cargar subcategorías: $e');
      _subcategories.clear();
    }
  }

  /// Construir breadcrumbs
  void _buildBreadcrumbs() {
    _breadcrumbs.clear();

    if (_category.value != null) {
      final breadcrumbList = <Category>[];
      Category? current = _category.value;

      // Construir la cadena de categorías padre
      while (current != null) {
        breadcrumbList.insert(0, current);
        current = current.parent;
      }

      _breadcrumbs.value = breadcrumbList;
    }
  }

  /// Mostrar mensaje de error
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

  /// Mostrar mensaje de éxito
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
}
