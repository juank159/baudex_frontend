// lib/features/products/presentation/controllers/products_controller.dart
import 'dart:async';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/features/categories/domain/repositories/category_repository.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_stats.dart';
import 'package:baudex_desktop/app/core/widgets/safe_text_editing_controller.dart';
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
import '../../domain/usecases/get_low_stock_products_usecase.dart' as products_usecases;
import '../../domain/usecases/get_products_by_category_usecase.dart';

class ProductsController extends GetxController {
  // Dependencies
  final GetProductsUseCase _getProductsUseCase;
  final DeleteProductUseCase _deleteProductUseCase;
  final SearchProductsUseCase _searchProductsUseCase;
  final GetProductStatsUseCase _getProductStatsUseCase;
  final products_usecases.GetLowStockProductsUseCase _getLowStockProductsUseCase;
  final GetProductsByCategoryUseCase _getProductsByCategoryUseCase;

  ProductsController({
    required GetProductsUseCase getProductsUseCase,
    required DeleteProductUseCase deleteProductUseCase,
    required SearchProductsUseCase searchProductsUseCase,
    required GetProductStatsUseCase getProductStatsUseCase,
    required products_usecases.GetLowStockProductsUseCase getLowStockProductsUseCase,
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
  
  // Estados de UI
  final _isFabExpanded = false.obs;

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

  // ✅ Contador para forzar reconstrucción del campo de búsqueda solo cuando se limpia
  final _searchFieldRebuildKey = 0.obs;

  // UI Controllers - usando SafeTextEditingController
  final searchController = SafeTextEditingController();
  final scrollController = ScrollController();
  
  // Debounce timer for search
  Timer? _searchDebounceTimer;

  // Configuración
  static const int _pageSize = 20;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get isSearching => _isSearching.value;
  bool get isDeleting => _isDeleting.value;
  Rx<bool> get isFabExpanded => _isFabExpanded;

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

  // ✅ NUEVOS GETTERS PARA PAGINACIÓN PROFESIONAL
  String get paginationInfo => 'Página $currentPage de $totalPages ($totalItems productos)';
  double get loadingProgress => totalPages > 0 ? currentPage / totalPages : 0.0;
  bool get canLoadMore => hasNextPage && !_isLoadingMore.value && !_isLoading.value;

  // ✅ Getter para el contador de reconstrucción del campo de búsqueda
  int get searchFieldRebuildKey => _searchFieldRebuildKey.value;

  // ==================== LIFECYCLE ====================

  // @override
  // void onInit() {
  //   super.onInit();
  //   _setupScrollListener();
  //   loadProducts();
  //   loadStats();
  // }

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    // ❌ NO cargar datos automáticamente - esperar a que esté autenticado
    // loadInitialData(); // Se llamará cuando sea necesario
  }

  @override
  void onReady() {
    super.onReady();
    print('🔄 ProductsController: onReady - Controller listo');
    // ✅ Cargar datos cuando el controller esté completamente listo
    ensureDataLoaded();
  }

  /// Método para limpiar búsqueda cuando regresas a la pantalla
  void clearSearchOnReturn() {
    if (searchController.text.isNotEmpty) {
      print('🧹 Limpiando campo de búsqueda anterior: "${searchController.text}"');
      searchController.clear();
      _searchTerm.value = '';
      _searchResults.clear();

      // Si estábamos mostrando resultados de búsqueda, volver a cargar todos los productos
      print('🔄 Recargando lista completa de productos...');
      loadProducts();
    }
  }

  /// Asegurar que los datos estén cargados (llamar solo cuando esté autenticado)
  Future<void> ensureDataLoaded() async {
    // Solo cargar si no hay datos y no está cargando
    if (_products.isEmpty && !_isLoading.value && !isLoading) {
      print('🔄 ProductsController: Cargando datos por primera vez...');
      await loadInitialData();
    } else {
      print('🔄 ProductsController: Datos ya cargados o cargando...');
    }
  }

  @override
  void onClose() {
    try {
      print('🔚 ProductsController: Iniciando proceso de dispose...');
      
      // Cancel debounce timer first
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = null;
      print('  ✅ Timer de búsqueda cancelado');
      
      // Safe disposal of SafeTextEditingController
      try {
        if (!searchController.isDisposed && searchController.isSafeToUse) {
          searchController.dispose();
          print('  ✅ SafeSearchController disposed');
        } else {
          print('  ⚠️ SafeSearchController already disposed or unsafe');
        }
      } catch (e) {
        print('  ⚠️ SafeSearchController disposal error: $e');
      }
      
      try {
        scrollController.dispose();
        print('  ✅ ScrollController disposed');
      } catch (e) {
        print('  ⚠️ Error al dispose scrollController: $e');
      }
      
      print('✅ ProductsController: Controllers and timers disposed safely');
    } catch (e) {
      print('⚠️ ProductsController: Error during disposal - $e');
    }
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  // ==================== PUBLIC METHODS ====================

  /// Toggle FAB expansion state
  void toggleFabExpanded() {
    _isFabExpanded.value = !_isFabExpanded.value;
  }

  /// Close FAB if expanded
  void closeFab() {
    if (_isFabExpanded.value) {
      _isFabExpanded.value = false;
    }
  }

  Future<void> loadInitialData() async {
    print('🚀 ProductsController: Iniciando carga inicial unificada...');

    _isLoading.value = true;

    try {
      // ✅ OPTIMIZACIÓN: Ejecutar ambas operaciones en paralelo
      final results = await Future.wait([
        _loadProductsInternal(),
        _loadStatsInternal(),
      ]);

      print('✅ Carga inicial completada exitosamente');
    } catch (e) {
      print('❌ Error en carga inicial: $e');
      _showError('Error de carga', 'No se pudo cargar la información inicial');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadProductsInternal() async {
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
          print('❌ Error al cargar productos: ${failure.message}');
          _products.clear();
        },
        (paginatedResult) {
          _products.value = paginatedResult.data;
          _updatePaginationInfo(paginatedResult.meta);
          print('✅ Productos cargados: ${paginatedResult.data.length}');
        },
      );
    } catch (e) {
      print('❌ Error inesperado cargando productos: $e');
      _products.clear();
    }
  }

  Future<void> _loadStatsInternal() async {
    try {
      print('📊 Cargando estadísticas...');

      final result = await _getProductStatsUseCase(const NoParams());

      result.fold(
        (failure) {
          print('❌ Error al cargar estadísticas: ${failure.message}');

          // Solo mostrar error crítico si no hay estadísticas previas
          if (_stats.value == null) {
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
        (stats) {
          print('✅ Estadísticas cargadas: $stats');

          if (stats.total >= 0 && stats.active >= 0) {
            _stats.value = stats;

            // ✅ OPTIMIZACIÓN: Solo verificar consistencia si hay productos con stock bajo
            if (stats.lowStock > 0) {
              print('🔍 Detectados ${stats.lowStock} productos con stock bajo');
              // NO hacer verificación adicional aquí para evitar consultas extra
            }
          } else {
            print('⚠️ Estadísticas con valores inválidos');
            if (_stats.value == null) {
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
          }
        },
      );
    } catch (e) {
      print('❌ Error inesperado cargando estadísticas: $e');
      if (_stats.value == null) {
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
    }
  }

  /// Cargar productos
  // Future<void> loadProducts({bool showLoading = true}) async {
  //   if (showLoading) _isLoading.value = true;

  //   try {
  //     final result = await _getProductsUseCase(
  //       GetProductsParams(
  //         page: 1,
  //         limit: _pageSize,
  //         search: _searchTerm.value.isEmpty ? null : _searchTerm.value,
  //         status: _currentStatus.value,
  //         type: _currentType.value,
  //         categoryId: _selectedCategoryId.value,
  //         inStock: _inStock.value,
  //         lowStock: _lowStock.value,
  //         minPrice: _minPrice.value,
  //         maxPrice: _maxPrice.value,
  //         priceType: _priceType.value,
  //         sortBy: _sortBy.value,
  //         sortOrder: _sortOrder.value,
  //       ),
  //     );

  //     result.fold(
  //       (failure) {
  //         _showError('Error al cargar productos', failure.message);
  //         _products.clear();
  //       },
  //       (paginatedResult) {
  //         _products.value = paginatedResult.data;
  //         _updatePaginationInfo(paginatedResult.meta);
  //       },
  //     );
  //   } finally {
  //     _isLoading.value = false;
  //   }
  // }

  Future<void> loadProducts({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;

    try {
      await _loadProductsInternal();
    } finally {
      if (showLoading) _isLoading.value = false;
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
          // ✅ PREVENIR DUPLICADOS: Solo agregar productos que no existan ya
          final existingIds = _products.map((p) => p.id).toSet();
          final newProducts = paginatedResult.data.where(
            (product) => !existingIds.contains(product.id)
          ).toList();
          
          if (newProducts.isNotEmpty) {
            _products.addAll(newProducts);
            print('✅ ProductsController: Agregados ${newProducts.length} productos nuevos');
          } else {
            print('⚠️ ProductsController: No hay productos nuevos para agregar');
          }
          
          _updatePaginationInfo(paginatedResult.meta);
        },
      );
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Refrescar productos
  // Future<void> refreshProducts() async {
  //   _currentPage.value = 1;
  //   await loadProducts(showLoading: false);
  //   await loadStats();
  // }

  Future<void> refreshProducts() async {
    print('🔄 ProductsController: Refrescando datos...');

    _currentPage.value = 1;

    // ✅ OPTIMIZACIÓN: Recargar productos y estadísticas en paralelo
    await Future.wait([_loadProductsInternal(), _loadStatsInternal()]);

    print('✅ Datos refrescados exitosamente');
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

  // Future<void> loadStats() async {
  //   print('📊 ProductsController: Iniciando carga de estadísticas...');

  //   try {
  //     final result = await _getProductStatsUseCase(const NoParams());

  //     result.fold(
  //       (failure) {
  //         print(
  //           '❌ ProductsController: Error al cargar estadísticas - ${failure.message}',
  //         );

  //         // ✅ MEJORADO: Solo mostrar error si no hay estadísticas previas
  //         if (_stats.value == null) {
  //           _showError(
  //             'Error al cargar estadísticas',
  //             failure.message,
  //             duration: const Duration(seconds: 3),
  //           );
  //         } else {
  //           print('⚠️ Manteniendo estadísticas anteriores debido al error');
  //         }

  //         // ✅ MEJORADO: Solo resetear si no hay estadísticas previas
  //         if (_stats.value == null) {
  //           _stats.value = const ProductStats(
  //             total: 0,
  //             active: 0,
  //             inactive: 0,
  //             outOfStock: 0,
  //             lowStock: 0,
  //             activePercentage: 0.0,
  //             totalValue: 0.0,
  //             averagePrice: 0.0,
  //           );
  //         }
  //       },
  //       (stats) {
  //         print('✅ ProductsController: Estadísticas cargadas exitosamente');
  //         print(
  //           '📊 Stats: total=${stats.total}, active=${stats.active}, lowStock=${stats.lowStock}',
  //         );

  //         // ✅ MEJORADO: Validación y logs más detallados
  //         if (stats.total >= 0 && stats.active >= 0) {
  //           _stats.value = stats;
  //           print('✅ Estadísticas asignadas al observable');

  //           // ✅ AÑADIDO: Debug adicional para stock bajo
  //           if (stats.lowStock > 0) {
  //             print('🔍 Detectados ${stats.lowStock} productos con stock bajo');

  //             // ✅ OPCIONAL: Cargar productos con stock bajo para verificar
  //             _verifyLowStockProducts();
  //           } else {
  //             print('✅ No hay productos con stock bajo');
  //           }
  //         } else {
  //           print(
  //             '⚠️ Estadísticas recibidas con valores negativos: total=${stats.total}, active=${stats.active}',
  //           );

  //           // ✅ MANTENER estadísticas anteriores si las nuevas son inválidas
  //           if (_stats.value == null) {
  //             _stats.value = const ProductStats(
  //               total: 0,
  //               active: 0,
  //               inactive: 0,
  //               outOfStock: 0,
  //               lowStock: 0,
  //               activePercentage: 0.0,
  //               totalValue: 0.0,
  //               averagePrice: 0.0,
  //             );
  //           }
  //         }
  //       },
  //     );
  //   } catch (e, stackTrace) {
  //     print(
  //       '💥 ProductsController: Error inesperado al cargar estadísticas - $e',
  //     );
  //     print('🔍 StackTrace: $stackTrace');

  //     // ✅ MEJORADO: Solo mostrar error si es crítico
  //     if (_stats.value == null) {
  //       _showError(
  //         'Error inesperado',
  //         'No se pudieron cargar las estadísticas: ${e.toString()}',
  //       );

  //       _stats.value = const ProductStats(
  //         total: 0,
  //         active: 0,
  //         inactive: 0,
  //         outOfStock: 0,
  //         lowStock: 0,
  //         activePercentage: 0.0,
  //         totalValue: 0.0,
  //         averagePrice: 0.0,
  //       );
  //     }
  //   }

  //   print('🏁 ProductsController: Carga de estadísticas finalizada');
  // }

  Future<void> loadStats() async {
    await _loadStatsInternal();
  }

  Future<void> _verifyLowStockProducts() async {
    try {
      print('🔍 Verificando productos con stock bajo...');

      final result = await _getLowStockProductsUseCase(const NoParams());

      result.fold(
        (failure) {
          print(
            '❌ Error al verificar productos con stock bajo: ${failure.message}',
          );
        },
        (products) {
          print('📋 Productos con stock bajo verificados: ${products.length}');

          for (final product in products) {
            print(
              '   - ${product.name}: stock=${product.stock}, minStock=${product.minStock}',
            );
          }

          // ✅ Verificar consistencia con estadísticas
          final statsLowStock = _stats.value?.lowStock ?? 0;
          if (products.length != statsLowStock) {
            print(
              '⚠️ INCONSISTENCIA: Stats=${statsLowStock}, Productos encontrados=${products.length}',
            );

            // ✅ OPCIONAL: Actualizar estadísticas con el valor correcto
            if (_stats.value != null) {
              _stats.value = _stats.value!.copyWith(lowStock: products.length);
              print('🔄 Estadísticas corregidas: lowStock=${products.length}');
            }
          }
        },
      );
    } catch (e) {
      print('❌ Error inesperado al verificar productos con stock bajo: $e');
    }
  }

  Future<void> verifyLowStockConsistency() async {
    if (_stats.value == null || _stats.value!.lowStock == 0) {
      print('ℹ️ No hay productos con stock bajo según estadísticas');
      return;
    }

    try {
      print('🔍 Verificando consistencia de productos con stock bajo...');

      final result = await _getLowStockProductsUseCase(const NoParams());

      result.fold(
        (failure) {
          print(
            '❌ Error al verificar productos con stock bajo: ${failure.message}',
          );
        },
        (products) {
          print('📋 Productos con stock bajo verificados: ${products.length}');

          final statsLowStock = _stats.value?.lowStock ?? 0;
          if (products.length != statsLowStock) {
            print(
              '⚠️ INCONSISTENCIA: Stats=${statsLowStock}, Productos encontrados=${products.length}',
            );

            // Actualizar estadísticas con el valor correcto
            if (_stats.value != null) {
              _stats.value = _stats.value!.copyWith(lowStock: products.length);
              print('🔄 Estadísticas corregidas: lowStock=${products.length}');
            }
          } else {
            print('✅ Consistencia verificada correctamente');
          }
        },
      );
    } catch (e) {
      print('❌ Error inesperado al verificar consistencia: $e');
    }
  }

  // Future<void> refreshStats() async {
  //   print('🔄 ProductsController: Refrescando estadísticas...');
  //   await loadStats();
  // }

  Future<void> refreshStats() async {
    print('🔄 ProductsController: Refrescando solo estadísticas...');
    await _loadStatsInternal();
  }

  /// ✅ AÑADIDO: Método para verificar si las estadísticas están cargadas
  bool get hasValidStats => _stats.value != null && _stats.value!.total >= 0;

  // Future<void> loadLowStockProducts() async {
  //   print('📋 ProductsController: Cargando productos con stock bajo...');
  //   _isLoading.value = true;

  //   try {
  //     final result = await _getLowStockProductsUseCase(const NoParams());

  //     result.fold(
  //       (failure) {
  //         print(
  //           '❌ Error al cargar productos con stock bajo: ${failure.message}',
  //         );
  //         _showError(
  //           'Error al cargar productos con stock bajo',
  //           failure.message,
  //         );
  //       },
  //       (products) {
  //         print('✅ Productos con stock bajo cargados: ${products.length}');

  //         _products.value = products;

  //         // Actualizar meta para mostrar resultados
  //         _currentPage.value = 1;
  //         _totalItems.value = products.length;
  //         _totalPages.value = 1;
  //         _hasNextPage.value = false;
  //         _hasPreviousPage.value = false;

  //         // ✅ AÑADIDO: Mensaje informativo
  //         if (products.isNotEmpty) {
  //           _showSuccess(
  //             'Se encontraron ${products.length} productos con stock bajo',
  //           );
  //         } else {
  //           _showSuccess('¡Excelente! No hay productos con stock bajo');
  //         }

  //         // ✅ AÑADIDO: Debug de productos encontrados
  //         for (final product in products) {
  //           print(
  //             '   - ${product.name}: stock=${product.stock}, minStock=${product.minStock}',
  //           );
  //         }
  //       },
  //     );
  //   } finally {
  //     _isLoading.value = false;
  //   }
  // }

  Future<void> loadLowStockProducts() async {
    print('📋 ProductsController: Cargando productos con stock bajo...');
    _isLoading.value = true;

    try {
      final result = await _getLowStockProductsUseCase(const NoParams());

      result.fold(
        (failure) {
          print(
            '❌ Error al cargar productos con stock bajo: ${failure.message}',
          );
          _showError(
            'Error al cargar productos con stock bajo',
            failure.message,
          );
        },
        (products) {
          print('✅ Productos con stock bajo cargados: ${products.length}');

          _products.value = products;

          // Actualizar meta para mostrar resultados
          _currentPage.value = 1;
          _totalItems.value = products.length;
          _totalPages.value = 1;
          _hasNextPage.value = false;
          _hasPreviousPage.value = false;

          // ✅ MENSAJE MÁS INFORMATIVO
          if (products.isNotEmpty) {
            _showSuccess(
              'Se encontraron ${products.length} productos con stock bajo',
            );
          } else {
            _showSuccess('¡Excelente! No hay productos con stock bajo');
          }
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

  /// Limpiar todos los filtros y refrescar lista completamente
  Future<void> clearFiltersAndRefresh() async {
    print('🔄 ProductsController: Limpiando filtros y refrescando lista...');

    // Limpiar todos los filtros
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

    // Refrescar datos completamente
    await refreshProducts();

    print('✅ ProductsController: Filtros limpiados y lista refrescada');
  }

  /// Búsqueda con debounce profesional
  void debouncedSearch(String query) {
    print('🔍 debouncedSearch LLAMADO con: "$query"');

    // Cancelar timer anterior si existe
    _searchDebounceTimer?.cancel();

    // Actualizar el campo de búsqueda inmediatamente para UI responsiva
    _searchTerm.value = query;
    print('   ✅ _searchTerm actualizado a: "$query"');

    // Si está vacío, limpiar inmediatamente
    if (query.trim().isEmpty) {
      print('   🧹 Query vacío, limpiando resultados');
      _searchResults.clear();
      loadProducts();
      return;
    }

    // Para queries válidas, crear timer con delay
    if (query.trim().length >= 2) {
      print('   ⏱️ Creando timer de 500ms para buscar: "$query"');
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        print('   🚀 Timer expiró, ejecutando searchProducts("$query")');
        searchProducts(query);
      });
    } else {
      print('   ⚠️ Query demasiado corto (${query.trim().length} chars), mínimo 2');
    }
  }

  /// Actualizar búsqueda (método legacy mantenido para compatibilidad)
  void updateSearch(String value) {
    _searchTerm.value = value;
    if (value.trim().isEmpty) {
      _searchResults.clear();
      // ✅ Notificar al widget de búsqueda que debe reconstruirse
      update(['search_field']);
      loadProducts();
    } else if (value.trim().length >= 2) {
      searchProducts(value);
    }
  }

  // ==================== NAVEGACIÓN DE PAGINACIÓN ====================

  /// Ir a una página específica
  Future<void> goToPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > totalPages || pageNumber == currentPage) {
      return;
    }

    print('🔄 ProductsController: Navegando a página $pageNumber');
    _currentPage.value = pageNumber;
    await loadProducts();
  }

  /// Ir a la primera página
  Future<void> goToFirstPage() async {
    if (currentPage == 1) return;
    await goToPage(1);
  }

  /// Ir a la última página
  Future<void> goToLastPage() async {
    if (currentPage == totalPages) return;
    await goToPage(totalPages);
  }

  /// Ir a la página siguiente
  Future<void> goToNextPage() async {
    if (!hasNextPage) return;
    await goToPage(currentPage + 1);
  }

  /// Ir a la página anterior
  Future<void> goToPreviousPage() async {
    if (!hasPreviousPage) return;
    await goToPage(currentPage - 1);
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

extension ProductStatsExtension on ProductStats {
  ProductStats copyWith({
    int? total,
    int? active,
    int? inactive,
    int? outOfStock,
    int? lowStock,
    double? activePercentage,
    double? totalValue,
    double? averagePrice,
  }) {
    return ProductStats(
      total: total ?? this.total,
      active: active ?? this.active,
      inactive: inactive ?? this.inactive,
      outOfStock: outOfStock ?? this.outOfStock,
      lowStock: lowStock ?? this.lowStock,
      activePercentage: activePercentage ?? this.activePercentage,
      totalValue: totalValue ?? this.totalValue,
      averagePrice: averagePrice ?? this.averagePrice,
    );
  }
}
