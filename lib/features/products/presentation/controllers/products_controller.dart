// lib/features/products/presentation/controllers/products_controller.dart
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/features/categories/domain/repositories/category_repository.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_stats.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/search_products_usecase.dart';
import '../../domain/usecases/get_product_stats_usecase.dart';
import '../../domain/usecases/get_low_stock_products_usecase.dart';
import '../../domain/usecases/get_products_by_category_usecase.dart';

class ProductsController extends GetxController {
  // Dependencies
  final GetProductsUseCase _getProductsUseCase;
  final DeleteProductUseCase _deleteProductUseCase;
  final SearchProductsUseCase _searchProductsUseCase;
  final GetProductStatsUseCase _getProductStatsUseCase;
  final GetLowStockProductsUseCase _getLowStockProductsUseCase;
  final GetProductsByCategoryUseCase _getProductsByCategoryUseCase;

  ProductsController({
    required GetProductsUseCase getProductsUseCase,
    required DeleteProductUseCase deleteProductUseCase,
    required SearchProductsUseCase searchProductsUseCase,
    required GetProductStatsUseCase getProductStatsUseCase,
    required GetLowStockProductsUseCase getLowStockProductsUseCase,
    required GetProductsByCategoryUseCase getProductsByCategoryUseCase,
  }) : _getProductsUseCase = getProductsUseCase,
       _deleteProductUseCase = deleteProductUseCase,
       _searchProductsUseCase = searchProductsUseCase,
       _getProductStatsUseCase = getProductStatsUseCase,
       _getLowStockProductsUseCase = getLowStockProductsUseCase,
       _getProductsByCategoryUseCase = getProductsByCategoryUseCase;

  // ==================== OBSERVABLES ====================

  // Estados de carga
  final _isLoading = false.obs;
  final _isLoadingMore = false.obs;
  final _isSearching = false.obs;
  final _isDeleting = false.obs;

  // Datos
  final _products = <Product>[].obs;
  final _searchResults = <Product>[].obs;
  final Rxn<ProductStats> _stats = Rxn<ProductStats>();

  // Paginación
  final _currentPage = 1.obs;
  final _totalPages = 1.obs;
  final _totalItems = 0.obs;
  final _hasNextPage = false.obs;
  final _hasPreviousPage = false.obs;

  // Filtros y búsqueda
  final _currentStatus = Rxn<ProductStatus>();
  final _currentType = Rxn<ProductType>();
  final _selectedCategoryId = Rxn<String>();
  final _searchTerm = ''.obs;
  final _sortBy = 'createdAt'.obs;
  final _sortOrder = 'DESC'.obs;
  final _minPrice = Rxn<double>();
  final _maxPrice = Rxn<double>();
  final _priceType = PriceType.price1.obs;
  final _inStock = Rxn<bool>();
  final _lowStock = Rxn<bool>();

  // UI Controllers
  final searchController = TextEditingController();
  final scrollController = ScrollController();

  // Configuración
  static const int _pageSize = 20;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get isSearching => _isSearching.value;
  bool get isDeleting => _isDeleting.value;

  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  ProductStats? get stats => _stats.value;

  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  int get totalItems => _totalItems.value;
  bool get hasNextPage => _hasNextPage.value;
  bool get hasPreviousPage => _hasPreviousPage.value;

  ProductStatus? get currentStatus => _currentStatus.value;
  ProductType? get currentType => _currentType.value;
  String? get selectedCategoryId => _selectedCategoryId.value;
  String get searchTerm => _searchTerm.value;
  String get sortBy => _sortBy.value;
  String get sortOrder => _sortOrder.value;
  double? get minPrice => _minPrice.value;
  double? get maxPrice => _maxPrice.value;
  PriceType get priceType => _priceType.value;
  bool? get inStock => _inStock.value;
  bool? get lowStock => _lowStock.value;

  bool get hasProducts => _products.isNotEmpty;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get isSearchMode => _searchTerm.value.isNotEmpty;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    loadProducts();
    loadStats();
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // ==================== PUBLIC METHODS ====================

  /// Cargar productos
  Future<void> loadProducts({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;

    try {
      final result = await _getProductsUseCase(
        GetProductsParams(
          page: 1,
          limit: _pageSize,
          search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
          status: _currentStatus.value,
          type: _currentType.value,
          categoryId: _selectedCategoryId.value,
          inStock: _inStock.value,
          lowStock: _lowStock.value,
          minPrice: _minPrice.value,
          maxPrice: _maxPrice.value,
          priceType: _priceType.value,
          sortBy: _sortBy.value,
          sortOrder: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar productos', failure.message);
          _products.clear();
        },
        (paginatedResult) {
          _products.value = paginatedResult.data;
          _updatePaginationInfo(paginatedResult.meta);
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cargar más productos (paginación)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore.value || !_hasNextPage.value) return;

    _isLoadingMore.value = true;

    try {
      final result = await _getProductsUseCase(
        GetProductsParams(
          page: _currentPage.value + 1,
          limit: _pageSize,
          search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
          status: _currentStatus.value,
          type: _currentType.value,
          categoryId: _selectedCategoryId.value,
          inStock: _inStock.value,
          lowStock: _lowStock.value,
          minPrice: _minPrice.value,
          maxPrice: _maxPrice.value,
          priceType: _priceType.value,
          sortBy: _sortBy.value,
          sortOrder: _sortOrder.value,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar más productos', failure.message);
        },
        (paginatedResult) {
          _products.addAll(paginatedResult.data);
          _updatePaginationInfo(paginatedResult.meta);
        },
      );
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refrescar productos
  Future<void> refreshProducts() async {
    _currentPage.value = 1;
    await loadProducts(showLoading: false);
    await loadStats();
  }

  /// Buscar productos
  Future<void> searchProducts(String query) async {
    if (query.trim().length < 2) {
      _searchResults.clear();
      return;
    }

    _isSearching.value = true;

    try {
      final result = await _searchProductsUseCase(
        SearchProductsParams(searchTerm: query.trim(), limit: 50),
      );

      result.fold(
        (failure) {
          _showError('Error en búsqueda', failure.message);
          _searchResults.clear();
        },
        (results) {
          _searchResults.value = results;
        },
      );
    } finally {
      _isSearching.value = false;
    }
  }

  /// Eliminar producto
  Future<void> deleteProduct(String productId) async {
    _isDeleting.value = true;

    try {
      final result = await _deleteProductUseCase(
        DeleteProductParams(id: productId),
      );

      result.fold(
        (failure) {
          _showError('Error al eliminar', failure.message);
        },
        (_) {
          _showSuccess('Producto eliminado exitosamente');
          // Remover de la lista local
          _products.removeWhere((product) => product.id == productId);
          // Recargar para actualizar contadores
          refreshProducts();
        },
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  /// Cargar estadísticas
  // Future<void> loadStats() async {
  //   try {
  //     final result = await _getProductStatsUseCase(const NoParams());

  //     result.fold(
  //       (failure) {
  //         print('Error al cargar estadísticas: ${failure.message}');
  //       },
  //       (stats) {
  //         _stats.value = stats;
  //       },
  //     );
  //   } catch (e) {
  //     print('Error inesperado al cargar estadísticas: $e');
  //   }
  // }

  Future<void> loadStats() async {
    print('📊 ProductsController: Iniciando carga de estadísticas...');

    try {
      final result = await _getProductStatsUseCase(const NoParams());

      result.fold(
        (failure) {
          print(
            '❌ ProductsController: Error al cargar estadísticas - ${failure.message}',
          );

          // ✅ MEJORADO: Mostrar error al usuario en lugar de solo imprimir
          _showError(
            'Error al cargar estadísticas',
            failure.message,
            duration: const Duration(seconds: 2), // Menos intrusivo
          );

          // ✅ MEJORADO: Mantener estadísticas vacías pero válidas
          _stats.value = const ProductStats(
            total: 0,
            active: 0,
            inactive: 0,
            outOfStock: 0,
            lowStock: 0,
            activePercentage: 0.0,
            totalValue: 0.0,
            averagePrice: 0.0,
          );
        },
        (stats) {
          print('✅ ProductsController: Estadísticas cargadas exitosamente');
          print(
            '📊 Stats: total=${stats.total}, active=${stats.active}, lowStock=${stats.lowStock}',
          );

          // ✅ MEJORADO: Validar estadísticas antes de asignar
          if (stats.total >= 0 && stats.active >= 0) {
            _stats.value = stats;
            print('✅ Estadísticas asignadas al observable');
          } else {
            print(
              '⚠️ Estadísticas recibidas con valores negativos, usando valores por defecto',
            );
            _stats.value = const ProductStats(
              total: 0,
              active: 0,
              inactive: 0,
              outOfStock: 0,
              lowStock: 0,
              activePercentage: 0.0,
              totalValue: 0.0,
              averagePrice: 0.0,
            );
          }
        },
      );
    } catch (e, stackTrace) {
      print(
        '💥 ProductsController: Error inesperado al cargar estadísticas - $e',
      );
      print('🔍 StackTrace: $stackTrace');

      // ✅ MEJORADO: Mostrar error detallado en desarrollo
      _showError(
        'Error inesperado',
        'No se pudieron cargar las estadísticas: ${e.toString()}',
      );

      // Asegurar que stats tenga un valor válido
      _stats.value = const ProductStats(
        total: 0,
        active: 0,
        inactive: 0,
        outOfStock: 0,
        lowStock: 0,
        activePercentage: 0.0,
        totalValue: 0.0,
        averagePrice: 0.0,
      );
    }

    print('🏁 ProductsController: Carga de estadísticas finalizada');
  }

  Future<void> refreshStats() async {
    print('🔄 ProductsController: Refrescando estadísticas...');
    await loadStats();
  }

  /// ✅ AÑADIDO: Método para verificar si las estadísticas están cargadas
  bool get hasValidStats => _stats.value != null && _stats.value!.total >= 0;

  /// ✅ MEJORADO: Mostrar mensaje de error con duración personalizable

  /// Cargar productos con stock bajo
  Future<void> loadLowStockProducts() async {
    _isLoading.value = true;

    try {
      final result = await _getLowStockProductsUseCase(const NoParams());

      result.fold(
        (failure) {
          _showError(
            'Error al cargar productos con stock bajo',
            failure.message,
          );
        },
        (products) {
          _products.value = products;
          // Actualizar meta para mostrar resultados
          _currentPage.value = 1;
          _totalItems.value = products.length;
          _totalPages.value = 1;
          _hasNextPage.value = false;
          _hasPreviousPage.value = false;
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cargar productos por categoría
  Future<void> loadProductsByCategory(String categoryId) async {
    _isLoading.value = true;

    try {
      final result = await _getProductsByCategoryUseCase(
        GetProductsByCategoryParams(categoryId: categoryId),
      );

      result.fold(
        (failure) {
          _showError(
            'Error al cargar productos por categoría',
            failure.message,
          );
        },
        (products) {
          _products.value = products;
          _selectedCategoryId.value = categoryId;
          // Actualizar meta para mostrar resultados
          _currentPage.value = 1;
          _totalItems.value = products.length;
          _totalPages.value = 1;
          _hasNextPage.value = false;
          _hasPreviousPage.value = false;
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // ==================== FILTER & SORT METHODS ====================

  /// Aplicar filtro por estado
  void applyStatusFilter(ProductStatus? status) {
    _currentStatus.value = status;
    _currentPage.value = 1;
    loadProducts();
  }

  /// Aplicar filtro por tipo
  void applyTypeFilter(ProductType? type) {
    _currentType.value = type;
    _currentPage.value = 1;
    loadProducts();
  }

  /// Aplicar filtro por categoría
  void applyCategoryFilter(String? categoryId) {
    _selectedCategoryId.value = categoryId;
    _currentPage.value = 1;
    loadProducts();
  }

  /// Aplicar filtro por rango de precios
  void applyPriceFilter(
    double? minPrice,
    double? maxPrice,
    PriceType? priceType,
  ) {
    _minPrice.value = minPrice;
    _maxPrice.value = maxPrice;
    if (priceType != null) _priceType.value = priceType;
    _currentPage.value = 1;
    loadProducts();
  }

  /// Aplicar filtro por stock
  void applyStockFilter({bool? inStock, bool? lowStock}) {
    _inStock.value = inStock;
    _lowStock.value = lowStock;
    _currentPage.value = 1;
    loadProducts();
  }

  /// Cambiar ordenamiento
  void changeSorting(String sortBy, String sortOrder) {
    _sortBy.value = sortBy;
    _sortOrder.value = sortOrder;
    _currentPage.value = 1;
    loadProducts();
  }

  /// Limpiar filtros
  void clearFilters() {
    _currentStatus.value = null;
    _currentType.value = null;
    _selectedCategoryId.value = null;
    _searchTerm.value = '';
    _minPrice.value = null;
    _maxPrice.value = null;
    _priceType.value = PriceType.price1;
    _inStock.value = null;
    _lowStock.value = null;
    searchController.clear();
    _searchResults.clear();
    _currentPage.value = 1;
    loadProducts();
  }

  /// Actualizar búsqueda
  void updateSearch(String value) {
    _searchTerm.value = value;
    if (value.trim().isEmpty) {
      _searchResults.clear();
      loadProducts();
    } else if (value.trim().length >= 2) {
      searchProducts(value);
    }
  }

  // ==================== UI HELPERS ====================

  /// Ir a crear producto
  void goToCreateProduct() {
    Get.toNamed('/products/create');
  }

  /// Ir a editar producto
  void goToEditProduct(String productId) {
    Get.toNamed('/products/edit/$productId');
  }

  /// Mostrar detalles de producto
  void showProductDetails(String productId) {
    Get.toNamed('/products/detail/$productId');
  }

  /// Confirmar eliminación
  void confirmDelete(Product product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro que deseas eliminar el producto "${product.name}"?\n\n'
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
              deleteProduct(product.id);
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
          loadMoreProducts();
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
  // void _showError(String title, String message) {
  //   Get.snackbar(
  //     title,
  //     message,
  //     snackPosition: SnackPosition.TOP,
  //     backgroundColor: Colors.red.shade100,
  //     colorText: Colors.red.shade800,
  //     icon: const Icon(Icons.error, color: Colors.red),
  //     duration: const Duration(seconds: 4),
  //   );
  // }

  void _showError(String title, String message, {Duration? duration}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: duration ?? const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
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
