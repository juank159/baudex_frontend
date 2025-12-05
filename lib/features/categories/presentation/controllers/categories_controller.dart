// // lib/features/categories/presentation/controllers/categories_controller.dart
// import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
// import 'package:baudex_desktop/features/categories/domain/entities/category_stats.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../../app/core/usecases/usecase.dart';
// import '../../domain/entities/category.dart';
// import '../../domain/repositories/category_repository.dart';
// import '../../domain/usecases/get_categories_usecase.dart';
// import '../../domain/usecases/delete_category_usecase.dart';
// import '../../domain/usecases/search_categories_usecase.dart';
// import '../../domain/usecases/get_category_stats_usecase.dart';

// class CategoriesController extends GetxController {
//   // Dependencies
//   final GetCategoriesUseCase _getCategoriesUseCase;
//   final DeleteCategoryUseCase _deleteCategoryUseCase;
//   final SearchCategoriesUseCase _searchCategoriesUseCase;
//   final GetCategoryStatsUseCase _getCategoryStatsUseCase;

//   CategoriesController({
//     required GetCategoriesUseCase getCategoriesUseCase,
//     required DeleteCategoryUseCase deleteCategoryUseCase,
//     required SearchCategoriesUseCase searchCategoriesUseCase,
//     required GetCategoryStatsUseCase getCategoryStatsUseCase,
//   }) : _getCategoriesUseCase = getCategoriesUseCase,
//        _deleteCategoryUseCase = deleteCategoryUseCase,
//        _searchCategoriesUseCase = searchCategoriesUseCase,
//        _getCategoryStatsUseCase = getCategoryStatsUseCase;

//   // ==================== OBSERVABLES ====================

//   // Estados de carga
//   final _isLoading = false.obs;
//   final _isLoadingMore = false.obs;
//   final _isSearching = false.obs;
//   final _isDeleting = false.obs;

//   // Datos
//   final _categories = <Category>[].obs;
//   final _searchResults = <Category>[].obs;
//   final Rxn<CategoryStats> _stats = Rxn<CategoryStats>();

//   // Paginación
//   final _currentPage = 1.obs;
//   final _totalPages = 1.obs;
//   final _totalItems = 0.obs;
//   final _hasNextPage = false.obs;
//   final _hasPreviousPage = false.obs;

//   // Filtros y búsqueda
//   final _currentStatus = Rxn<CategoryStatus>();
//   final _searchTerm = ''.obs;
//   final _sortBy = 'sortOrder'.obs;
//   final _sortOrder = 'ASC'.obs;
//   final _selectedParentId = Rxn<String>();

//   // UI Controllers
//   final searchController = TextEditingController();
//   final scrollController = ScrollController();

//   // Configuración
//   static const int _pageSize = 20;

//   // ==================== GETTERS ====================

//   bool get isLoading => _isLoading.value;
//   bool get isLoadingMore => _isLoadingMore.value;
//   bool get isSearching => _isSearching.value;
//   bool get isDeleting => _isDeleting.value;

//   List<Category> get categories => _categories;
//   List<Category> get searchResults => _searchResults;
//   CategoryStats? get stats => _stats.value;

//   int get currentPage => _currentPage.value;
//   int get totalPages => _totalPages.value;
//   int get totalItems => _totalItems.value;
//   bool get hasNextPage => _hasNextPage.value;
//   bool get hasPreviousPage => _hasPreviousPage.value;

//   CategoryStatus? get currentStatus => _currentStatus.value;
//   String get searchTerm => _searchTerm.value;
//   String get sortBy => _sortBy.value;
//   String get sortOrder => _sortOrder.value;
//   String? get selectedParentId => _selectedParentId.value;

//   bool get hasCategories => _categories.isNotEmpty;
//   bool get hasSearchResults => _searchResults.isNotEmpty;
//   bool get isSearchMode => _searchTerm.value.isNotEmpty;

//   // ==================== LIFECYCLE ====================

//   @override
//   void onInit() {
//     super.onInit();
//     _setupScrollListener();
//     loadCategories();
//     loadStats();
//   }

//   @override
//   void onClose() {
//     searchController.dispose();
//     scrollController.dispose();
//     super.onClose();
//   }

//   // ==================== PUBLIC METHODS ====================

//   /// Cargar categorías
//   Future<void> loadCategories({bool showLoading = true}) async {
//     if (showLoading) _isLoading.value = true;

//     try {
//       final result = await _getCategoriesUseCase(
//         GetCategoriesParams(
//           page: 1,
//           limit: _pageSize,
//           search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
//           status: _currentStatus.value,
//           parentId: _selectedParentId.value,
//           sortBy: _sortBy.value,
//           sortOrder: _sortOrder.value,
//         ),
//       );

//       result.fold(
//         (failure) {
//           _showError('Error al cargar categorías', failure.message);
//           _categories.clear();
//         },
//         (paginatedResult) {
//           _categories.value = paginatedResult.data;
//           _updatePaginationInfo(paginatedResult.meta);
//         },
//       );
//     } finally {
//       _isLoading.value = false;
//     }
//   }

//   /// Cargar más categorías (paginación)
//   Future<void> loadMoreCategories() async {
//     if (_isLoadingMore.value || !_hasNextPage.value) return;

//     _isLoadingMore.value = true;

//     try {
//       final result = await _getCategoriesUseCase(
//         GetCategoriesParams(
//           page: _currentPage.value + 1,
//           limit: _pageSize,
//           search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
//           status: _currentStatus.value,
//           parentId: _selectedParentId.value,
//           sortBy: _sortBy.value,
//           sortOrder: _sortOrder.value,
//         ),
//       );

//       result.fold(
//         (failure) {
//           _showError('Error al cargar más categorías', failure.message);
//         },
//         (paginatedResult) {
//           _categories.addAll(paginatedResult.data);
//           _updatePaginationInfo(paginatedResult.meta);
//         },
//       );
//     } finally {
//       _isLoadingMore.value = false;
//     }
//   }

//   /// Refrescar categorías
//   Future<void> refreshCategories() async {
//     _currentPage.value = 1;
//     await loadCategories(showLoading: false);
//     await loadStats();
//   }

//   /// Buscar categorías
//   Future<void> searchCategories(String query) async {
//     if (query.trim().length < 2) {
//       _searchResults.clear();
//       return;
//     }

//     _isSearching.value = true;

//     try {
//       final result = await _searchCategoriesUseCase(
//         SearchCategoriesParams(searchTerm: query.trim(), limit: 50),
//       );

//       result.fold(
//         (failure) {
//           _showError('Error en búsqueda', failure.message);
//           _searchResults.clear();
//         },
//         (results) {
//           _searchResults.value = results;
//         },
//       );
//     } finally {
//       _isSearching.value = false;
//     }
//   }

//   /// Eliminar categoría
//   Future<void> deleteCategory(String categoryId) async {
//     _isDeleting.value = true;

//     try {
//       final result = await _deleteCategoryUseCase(
//         DeleteCategoryParams(id: categoryId),
//       );

//       result.fold(
//         (failure) {
//           _showError('Error al eliminar', failure.message);
//         },
//         (_) {
//           _showSuccess('Categoría eliminada exitosamente');
//           // Remover de la lista local
//           _categories.removeWhere((category) => category.id == categoryId);
//           // Recargar para actualizar contadores
//           refreshCategories();
//         },
//       );
//     } finally {
//       _isDeleting.value = false;
//     }
//   }

//   /// Cargar estadísticas
//   Future<void> loadStats() async {
//     try {
//       final result = await _getCategoryStatsUseCase(const NoParams());

//       result.fold(
//         (failure) {
//           print('Error al cargar estadísticas: ${failure.message}');
//         },
//         (stats) {
//           _stats.value = stats;
//         },
//       );
//     } catch (e) {
//       print('Error inesperado al cargar estadísticas: $e');
//     }
//   }

//   // ==================== FILTER & SORT METHODS ====================

//   /// Aplicar filtro por estado
//   void applyStatusFilter(CategoryStatus? status) {
//     _currentStatus.value = status;
//     _currentPage.value = 1;
//     loadCategories();
//   }

//   /// Aplicar filtro por categoría padre
//   void applyParentFilter(String? parentId) {
//     _selectedParentId.value = parentId;
//     _currentPage.value = 1;
//     loadCategories();
//   }

//   /// Cambiar ordenamiento
//   void changeSorting(String sortBy, String sortOrder) {
//     _sortBy.value = sortBy;
//     _sortOrder.value = sortOrder;
//     _currentPage.value = 1;
//     loadCategories();
//   }

//   /// Limpiar filtros
//   void clearFilters() {
//     _currentStatus.value = null;
//     _selectedParentId.value = null;
//     _searchTerm.value = '';
//     searchController.clear();
//     _searchResults.clear();
//     _currentPage.value = 1;
//     loadCategories();
//   }

//   /// Actualizar búsqueda
//   void updateSearch(String value) {
//     _searchTerm.value = value;
//     if (value.trim().isEmpty) {
//       _searchResults.clear();
//       loadCategories();
//     } else if (value.trim().length >= 2) {
//       searchCategories(value);
//     }
//   }

//   // ==================== UI HELPERS ====================

//   /// Ir a crear categoría
//   void goToCreateCategory() {
//     Get.toNamed('/categories/create');
//   }

//   /// Ir a editar categoría
//   void goToEditCategory(String categoryId) {
//     Get.toNamed('/categories/edit/$categoryId');
//   }

//   /// Mostrar detalles de categoría
//   void showCategoryDetails(String categoryId) {
//     Get.toNamed('/categories/detail/$categoryId');
//   }

//   /// Confirmar eliminación
//   void confirmDelete(Category category) {
//     Get.dialog(
//       AlertDialog(
//         title: const Text('Eliminar Categoría'),
//         content: Text(
//           '¿Estás seguro que deseas eliminar la categoría "${category.name}"?\n\n'
//           'Esta acción no se puede deshacer.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text('Cancelar'),
//           ),
//           TextButton(
//             onPressed: () {
//               Get.back();
//               deleteCategory(category.id);
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Eliminar'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ==================== PRIVATE METHODS ====================

//   /// Configurar listener del scroll para paginación infinita
//   void _setupScrollListener() {
//     scrollController.addListener(() {
//       if (scrollController.position.pixels >=
//           scrollController.position.maxScrollExtent - 200) {
//         if (!_isLoadingMore.value && _hasNextPage.value) {
//           loadMoreCategories();
//         }
//       }
//     });
//   }

//   /// Actualizar información de paginación
//   void _updatePaginationInfo(PaginationMeta meta) {
//     _currentPage.value = meta.page;
//     _totalPages.value = meta.totalPages;
//     _totalItems.value = meta.totalItems;
//     _hasNextPage.value = meta.hasNextPage;
//     _hasPreviousPage.value = meta.hasPreviousPage;
//   }

//   /// Mostrar mensaje de error
//   void _showError(String title, String message) {
//     Get.snackbar(
//       title,
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.red.shade100,
//       colorText: Colors.red.shade800,
//       icon: const Icon(Icons.error, color: Colors.red),
//       duration: const Duration(seconds: 4),
//     );
//   }

//   /// Mostrar mensaje de éxito
//   void _showSuccess(String message) {
//     Get.snackbar(
//       'Éxito',
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.green.shade100,
//       colorText: Colors.green.shade800,
//       icon: const Icon(Icons.check_circle, color: Colors.green),
//       duration: const Duration(seconds: 3),
//     );
//   }
// }

// lib/features/categories/presentation/controllers/categories_controller.dart
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category_stats.dart';
import 'package:baudex_desktop/app/core/widgets/safe_text_editing_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/search_categories_usecase.dart';
import '../../domain/usecases/get_category_stats_usecase.dart';

class CategoriesController extends GetxController {
  // Dependencies
  final GetCategoriesUseCase _getCategoriesUseCase;
  final DeleteCategoryUseCase _deleteCategoryUseCase;
  final SearchCategoriesUseCase _searchCategoriesUseCase;
  final GetCategoryStatsUseCase _getCategoryStatsUseCase;

  CategoriesController({
    required GetCategoriesUseCase getCategoriesUseCase,
    required DeleteCategoryUseCase deleteCategoryUseCase,
    required SearchCategoriesUseCase searchCategoriesUseCase,
    required GetCategoryStatsUseCase getCategoryStatsUseCase,
  }) : _getCategoriesUseCase = getCategoriesUseCase,
       _deleteCategoryUseCase = deleteCategoryUseCase,
       _searchCategoriesUseCase = searchCategoriesUseCase,
       _getCategoryStatsUseCase = getCategoryStatsUseCase;

  // ==================== OBSERVABLES ====================

  // Estados de carga
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _isSearching = false.obs;
  final _isDeleting = false.obs;
  final _isRefreshing = false.obs;

  // Datos
  final _categories = <Category>[].obs;
  final _searchResults = <Category>[].obs;
  final Rxn<CategoryStats> _stats = Rxn<CategoryStats>();

  // Paginación
  final _currentPage = 1.obs;
  final _totalPages = 1.obs;
  final _totalItems = 0.obs;
  final _hasNextPage = false.obs;
  final _hasPreviousPage = false.obs;

  // Filtros y búsqueda
  final _currentStatus = Rxn<CategoryStatus>();
  final _searchTerm = ''.obs;
  final _sortBy = 'sortOrder'.obs;
  final _sortOrder = 'ASC'.obs;
  final _selectedParentId = Rxn<String>();

  // UI Controllers - usando SafeTextEditingController
  final searchController = SafeTextEditingController();
  final scrollController = ScrollController();

  // Configuración
  static const int _pageSize = 20;

  // Control de llamadas duplicadas
  bool _isInitialized = false;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get isSearching => _isSearching.value;
  bool get isDeleting => _isDeleting.value;
  bool get isRefreshing => _isRefreshing.value;

  List<Category> get categories => _categories;
  List<Category> get searchResults => _searchResults;
  CategoryStats? get stats => _stats.value;

  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  int get totalItems => _totalItems.value;
  bool get hasNextPage => _hasNextPage.value;
  bool get hasPreviousPage => _hasPreviousPage.value;

  CategoryStatus? get currentStatus => _currentStatus.value;
  String get searchTerm => _searchTerm.value;
  String get sortBy => _sortBy.value;
  String get sortOrder => _sortOrder.value;
  String? get selectedParentId => _selectedParentId.value;

  bool get hasCategories => _categories.isNotEmpty;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get isSearchMode => _searchTerm.value.isNotEmpty;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    _initializeData();
  }

  @override
  void onClose() {
    print('🔧 CategoriesController: Iniciando dispose...');

    // Dispose seguro del searchController
    if (!searchController.isDisposed) {
      searchController.dispose();
      print('✅ CategoriesController: searchController disposed');
    } else {
      print('⚠️ CategoriesController: searchController ya estaba disposed');
    }

    // Dispose del scrollController
    scrollController.dispose();
    print('✅ CategoriesController: scrollController disposed');

    super.onClose();
    print('✅ CategoriesController: Dispose completado');
  }

  // ==================== INITIALIZATION ====================

  /// Inicializar datos de forma optimizada
  Future<void> _initializeData() async {
    if (_isInitialized) {
      print('⚠️ CategoriesController ya inicializado, omitiendo...');
      return;
    }

    try {
      print('🚀 Inicializando CategoriesController...');

      // Cargar estadísticas primero (son más rápidas y menos críticas)
      await loadStats();

      // Luego cargar categorías
      await loadCategories();

      _isInitialized = true;
      print('✅ CategoriesController inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar CategoriesController: $e');
    }
  }

  // ==================== PUBLIC METHODS ====================

  /// Cargar categorías
  // Future<void> loadCategories({bool showLoading = true}) async {
  //   // Evitar múltiples llamadas simultáneas
  //   if (_isLoading.value) {
  //     print('⚠️ Ya hay una carga en progreso, ignorando...');
  //     return;
  //   }

  //   if (showLoading) _isLoading.value = true;

  //   try {
  //     print('📦 Cargando categorías...');

  //     final result = await _getCategoriesUseCase(
  //       GetCategoriesParams(
  //         page: 1,
  //         limit: _pageSize,
  //         search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
  //         status: _currentStatus.value,
  //         parentId: _selectedParentId.value,
  //         sortBy: _sortBy.value,
  //         sortOrder: _sortOrder.value,
  //       ),
  //     );

  //     result.fold(
  //       (failure) {
  //         _showError('Error al cargar categorías', failure.message);
  //         _categories.clear();
  //       },
  //       (paginatedResult) {
  //         _categories.value = paginatedResult.data;
  //         _updatePaginationInfo(paginatedResult.meta);
  //         print('✅ Categorías cargadas: ${paginatedResult.data.length}');
  //       },
  //     );
  //   } catch (e) {
  //     print('❌ Error inesperado al cargar categorías: $e');
  //     _showError('Error inesperado', 'Error al cargar categorías');
  //   } finally {
  //     _isLoading.value = false;
  //   }
  // }

  /// Cargar categorías
  Future<void> loadCategories({bool showLoading = true}) async {
    // Evitar múltiples llamadas simultáneas
    if (_isLoading.value) {
      print('⚠️ Ya hay una carga en progreso, ignorando...');
      return;
    }

    if (showLoading) _isLoading.value = true;

    try {
      print('📦 Cargando categorías...');

      // ✅ CORRECCIÓN: Determinar si usar onlyParents
      final bool useOnlyParents = _selectedParentId.value == 'parents_only';
      final String? actualParentId =
          useOnlyParents ? null : _selectedParentId.value;

      print(
        '🔧 UseOnlyParents: $useOnlyParents, ActualParentId: $actualParentId',
      );

      final result = await _getCategoriesUseCase(
        GetCategoriesParams(
          page: 1,
          limit: _pageSize,
          search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
          status: _currentStatus.value,
          parentId: actualParentId,
          onlyParents: useOnlyParents, // ✅ CORRECCIÓN CRÍTICA
          includeChildren: false,
          sortBy: _sortBy.value,
          sortOrder: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar categorías', failure.message);
          _categories.clear();
        },
        (paginatedResult) {
          _categories.value = paginatedResult.data;
          _updatePaginationInfo(paginatedResult.meta);
          print('✅ Categorías cargadas: ${paginatedResult.data.length}');
        },
      );
    } catch (e) {
      print('❌ Error inesperado al cargar categorías: $e');
      _showError('Error inesperado', 'Error al cargar categorías');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cargar más categorías (paginación)
  // Future<void> loadMoreCategories() async {
  //   if (_isLoadingMore.value || !_hasNextPage.value) return;

  //   _isLoadingMore.value = true;

  //   try {
  //     print('📄 Cargando más categorías (página ${_currentPage.value + 1})...');

  //     final result = await _getCategoriesUseCase(
  //       GetCategoriesParams(
  //         page: _currentPage.value + 1,
  //         limit: _pageSize,
  //         search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
  //         status: _currentStatus.value,
  //         parentId: _selectedParentId.value,
  //         sortBy: _sortBy.value,
  //         sortOrder: _sortOrder.value,
  //       ),
  //     );

  //     result.fold(
  //       (failure) {
  //         _showError('Error al cargar más categorías', failure.message);
  //       },
  //       (paginatedResult) {
  //         _categories.addAll(paginatedResult.data);
  //         _updatePaginationInfo(paginatedResult.meta);
  //         print('✅ Más categorías cargadas: ${paginatedResult.data.length}');
  //       },
  //     );
  //   } finally {
  //     _isLoadingMore.value = false;
  //   }
  // }

  /// Cargar más categorías (paginación)
  Future<void> loadMoreCategories() async {
    if (_isLoadingMore.value || !_hasNextPage.value) return;

    _isLoadingMore.value = true;

    try {
      print('📄 Cargando más categorías (página ${_currentPage.value + 1})...');

      // ✅ CORRECCIÓN: Aplicar la misma lógica para onlyParents
      final bool useOnlyParents = _selectedParentId.value == 'parents_only';
      final String? actualParentId =
          useOnlyParents ? null : _selectedParentId.value;

      final result = await _getCategoriesUseCase(
        GetCategoriesParams(
          page: _currentPage.value + 1,
          limit: _pageSize,
          search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
          status: _currentStatus.value,
          parentId: actualParentId,
          onlyParents: useOnlyParents, // ✅ CORRECCIÓN CRÍTICA
          includeChildren: false,
          sortBy: _sortBy.value,
          sortOrder: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar más categorías', failure.message);
        },
        (paginatedResult) {
          _categories.addAll(paginatedResult.data);
          _updatePaginationInfo(paginatedResult.meta);
          print('✅ Más categorías cargadas: ${paginatedResult.data.length}');
        },
      );
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refrescar categorías
  Future<void> refreshCategories() async {
    if (_isRefreshing.value) {
      print('⚠️ Ya hay un refresco en progreso, ignorando...');
      return;
    }

    print('🔄 Refrescando categorías...');
    _isRefreshing.value = true;
    _currentPage.value = 1;

    try {
      // Cargar en paralelo pero de forma controlada
      final futures = <Future>[loadCategories(showLoading: false), loadStats()];

      await Future.wait(futures);
      print('✅ Refresco completado exitosamente');
    } catch (e) {
      print('❌ Error durante el refresco: $e');
    } finally {
      _isRefreshing.value = false;
    }
  }

  /// Buscar categorías
  Future<void> searchCategories(String query) async {
    if (query.trim().length < 2) {
      _searchResults.clear();
      return;
    }

    _isSearching.value = true;

    try {
      print('🔍 Buscando categorías: "$query"');

      final result = await _searchCategoriesUseCase(
        SearchCategoriesParams(searchTerm: query.trim(), limit: 50),
      );

      result.fold(
        (failure) {
          _showError('Error en búsqueda', failure.message);
          _searchResults.clear();
        },
        (results) {
          _searchResults.value = results;
          print('✅ Búsqueda completada: ${results.length} resultados');
        },
      );
    } finally {
      _isSearching.value = false;
    }
  }

  /// Eliminar categoría
  Future<void> deleteCategory(String categoryId) async {
    _isDeleting.value = true;

    try {
      print('🗑️ Eliminando categoría: $categoryId');

      final result = await _deleteCategoryUseCase(
        DeleteCategoryParams(id: categoryId),
      );

      result.fold(
        (failure) {
          _showError('Error al eliminar', failure.message);
        },
        (_) {
          _showSuccess('Categoría eliminada exitosamente');
          // Remover de la lista local
          _categories.removeWhere((category) => category.id == categoryId);
          // Recargar para actualizar contadores
          refreshCategories();
          print('✅ Categoría eliminada exitosamente');
        },
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  /// Cargar estadísticas
  Future<void> loadStats() async {
    try {
      print('📊 Cargando estadísticas...');

      final result = await _getCategoryStatsUseCase(const NoParams());

      result.fold(
        (failure) {
          print('⚠️ Error al cargar estadísticas: ${failure.message}');
          // No mostrar error al usuario, las stats no son críticas
        },
        (stats) {
          _stats.value = stats;
          print('✅ Estadísticas cargadas: ${stats.total} categorías');
        },
      );
    } catch (e) {
      print('⚠️ Error inesperado al cargar estadísticas: $e');
    }
  }

  // ==================== FILTER & SORT METHODS ====================

  /// Aplicar filtro por estado
  void applyStatusFilter(CategoryStatus? status) {
    if (_currentStatus.value == status) return; // Evitar refrescos innecesarios

    _currentStatus.value = status;
    _currentPage.value = 1;
    loadCategories();
  }

  /// Aplicar filtro por categoría padre
  // void applyParentFilter(String? parentId) {
  //   if (_selectedParentId.value == parentId)
  //     return; // Evitar refrescos innecesarios

  //   _selectedParentId.value = parentId;
  //   _currentPage.value = 1;
  //   loadCategories();
  // }

  /// Aplicar filtro por categoría padre
  void applyParentFilter(String? parentId) {
    if (_selectedParentId.value == parentId) {
      return; // Evitar refrescos innecesarios
    }

    // ✅ CORRECCIÓN CRÍTICA: Manejar el caso especial 'parents_only'
    if (parentId == 'parents_only') {
      // Activar filtro de solo categorías padre
      _selectedParentId.value = 'parents_only'; // Usar como flag interno
      print('🔧 Activando filtro de solo categorías padre');
    } else {
      _selectedParentId.value = parentId;
      print('🔧 Aplicando filtro por parentId: $parentId');
    }

    _currentPage.value = 1;
    loadCategories();
  }

  /// Cambiar ordenamiento
  void changeSorting(String sortBy, String sortOrder) {
    if (_sortBy.value == sortBy && _sortOrder.value == sortOrder) {
      return; // Evitar refrescos innecesarios
    }

    _sortBy.value = sortBy;
    _sortOrder.value = sortOrder;
    _currentPage.value = 1;
    loadCategories();
  }

  /// Limpiar filtros
  void clearFilters() {
    print('🧹 Limpiando filtros...');

    _currentStatus.value = null;
    _selectedParentId.value = null;
    _searchTerm.value = '';

    // Clear seguro del searchController
    if (searchController.isSafeToUse) {
      searchController.clear();
      print('✅ SearchController limpiado');
    } else {
      print('⚠️ SearchController no es seguro para limpiar');
    }

    _searchResults.clear();
    _currentPage.value = 1;
    loadCategories();

    print('✅ Filtros limpiados');
  }

  /// Actualizar búsqueda
  void updateSearch(String value) {
    print('🔍 Actualizando búsqueda: "$value"');

    _searchTerm.value = value;

    if (value.trim().isEmpty) {
      print('🔍 Búsqueda vacía, limpiando resultados');
      _searchResults.clear();
      loadCategories();
    } else if (value.trim().length >= 2) {
      print('🔍 Iniciando búsqueda de categorías');
      searchCategories(value);
    } else {
      print('🔍 Término de búsqueda muy corto (${value.length} caracteres)');
    }
  }

  // ==================== UI HELPERS ====================

  /// Ir a crear categoría
  void goToCreateCategory() {
    Get.toNamed('/categories/create');
  }

  /// Ir a editar categoría
  void goToEditCategory(String categoryId) {
    Get.toNamed('/categories/edit/$categoryId');
  }

  /// Mostrar detalles de categoría
  void showCategoryDetails(String categoryId) {
    Get.toNamed('/categories/detail/$categoryId');
  }

  /// Confirmar eliminación
  void confirmDelete(Category category) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
          '¿Estás seguro que deseas eliminar la categoría "${category.name}"?\n\n'
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
              deleteCategory(category.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ==================== PRIVATE METHODS ====================

  /// Configurar listener del scroll para paginación infinita
  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore.value && _hasNextPage.value) {
          loadMoreCategories();
        }
      }
    });
  }

  /// Actualizar información de paginación
  void _updatePaginationInfo(PaginationMeta meta) {
    _currentPage.value = meta.page;
    _totalPages.value = meta.totalPages;
    _totalItems.value = meta.totalItems;
    _hasNextPage.value = meta.hasNextPage;
    _hasPreviousPage.value = meta.hasPreviousPage;
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

  // ==================== DEBUGGING METHODS ====================

  /// Obtener información de estado para debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isLoading': _isLoading.value,
      'isRefreshing': _isRefreshing.value,
      'categoriesCount': _categories.length,
      'currentPage': _currentPage.value,
      'totalItems': _totalItems.value,
      'searchTerm': _searchTerm.value,
      'currentStatus': _currentStatus.value?.name,
      'sortBy': _sortBy.value,
      'sortOrder': _sortOrder.value,
      'searchControllerStatus': {
        'isDisposed': searchController.isDisposed,
        'isSafeToUse': searchController.isSafeToUse,
        'textLength':
            searchController.isSafeToUse ? searchController.text.length : -1,
      },
    };
  }

  /// Imprimir información de debugging
  void printDebugInfo() {
    final info = getDebugInfo();
    print('🐛 CategoriesController Debug Info:');
    info.forEach((key, value) {
      print('   $key: $value');
    });
  }
}
