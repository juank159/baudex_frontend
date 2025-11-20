// lib/features/suppliers/presentation/controllers/suppliers_controller.dart
import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/get_suppliers_usecase.dart';
import '../../domain/usecases/delete_supplier_usecase.dart';
import '../../domain/usecases/search_suppliers_usecase.dart';
import '../../domain/usecases/get_supplier_stats_usecase.dart';

class SuppliersController extends GetxController {
  final GetSuppliersUseCase getSuppliersUseCase;
  final DeleteSupplierUseCase deleteSupplierUseCase;
  final SearchSuppliersUseCase searchSuppliersUseCase;
  final GetSupplierStatsUseCase getSupplierStatsUseCase;

  SuppliersController({
    required this.getSuppliersUseCase,
    required this.deleteSupplierUseCase,
    required this.searchSuppliersUseCase,
    required this.getSupplierStatsUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================

  final RxList<Supplier> suppliers = <Supplier>[].obs;
  final RxList<Supplier> filteredSuppliers = <Supplier>[].obs;
  final Rx<SupplierStats?> stats = Rx<SupplierStats?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;

  // Filtros
  final Rx<SupplierStatus?> statusFilter = Rx<SupplierStatus?>(null);
  final Rx<DocumentType?> documentTypeFilter = Rx<DocumentType?>(null);
  final RxString currencyFilter = ''.obs;
  final RxBool hasEmailFilter = false.obs;
  final RxBool hasPhoneFilter = false.obs;
  final RxBool hasCreditLimitFilter = false.obs;
  final RxBool hasDiscountFilter = false.obs;

  // Paginación
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPrevPage = false.obs;
  static const int pageSize = 20;

  // Ordenamiento
  final RxString sortBy = 'name'.obs;
  final RxString sortOrder = 'asc'.obs;

  // UI State
  final RxBool isRefreshing = false.obs;
  final RxBool showFilters = false.obs;
  final RxInt selectedTab = 0.obs; // 0: Lista, 1: Estadísticas

  // Controllers para búsqueda
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupSearchListener();

    // Check if we need to refresh data
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['refresh'] == true) {
      refreshSuppliers();
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Siempre refrescar cuando la pantalla esté lista
    Future.delayed(const Duration(milliseconds: 100), () {
      refreshSuppliers();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeData() {
    loadSuppliers();
    loadStats();
  }

  void _setupSearchListener() {
    searchController.addListener(() {
      if (searchController.text != searchQuery.value) {
        searchQuery.value = searchController.text;
        _debounceSearch();
      }
    });
  }

  void _debounceSearch() {
    // Cancelar timer anterior si existe
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();

    // Crear nuevo timer
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (searchQuery.value.isNotEmpty) {
        searchSuppliers(searchQuery.value);
      } else {
        filteredSuppliers.value = suppliers;
      }
    });
  }

  Timer? _searchTimer;

  // ==================== DATA LOADING ====================

  Future<void> loadSuppliers({bool showLoading = true}) async {
    try {
      if (showLoading) isLoading.value = true;
      error.value = '';

      final params = SupplierQueryParams(
        page: currentPage.value,
        limit: pageSize,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        status: statusFilter.value,
        documentType: documentTypeFilter.value,
        currency: currencyFilter.value.isNotEmpty ? currencyFilter.value : null,
        hasEmail: hasEmailFilter.value ? true : null,
        hasPhone: hasPhoneFilter.value ? true : null,
        hasCreditLimit: hasCreditLimitFilter.value ? true : null,
        hasDiscount: hasDiscountFilter.value ? true : null,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
      );

      final result = await getSuppliersUseCase(params);

      result.fold(
        (failure) {
          error.value = failure.message;
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (paginatedResult) {
          if (currentPage.value == 1) {
            suppliers.value = paginatedResult.data;
          } else {
            suppliers.addAll(paginatedResult.data);
          }

          // Actualizar metadatos de paginación
          if (paginatedResult.meta != null) {
            totalPages.value = paginatedResult.meta!.totalPages;
            totalItems.value = paginatedResult.meta!.total;
            hasNextPage.value = paginatedResult.meta!.hasNext;
            hasPrevPage.value = paginatedResult.meta!.hasPrev;
          }

          // Si no hay búsqueda activa, actualizar lista filtrada
          if (searchQuery.value.isEmpty) {
            filteredSuppliers.value = suppliers;
          }
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> searchSuppliers(String query) async {
    if (query.isEmpty) {
      filteredSuppliers.value = suppliers;
      return;
    }

    try {
      isSearching.value = true;

      final params = SearchSuppliersParams(searchTerm: query, limit: 20);

      final result = await searchSuppliersUseCase(params);

      result.fold(
        (failure) {
          error.value = failure.message;
          filteredSuppliers.value = suppliers;
        },
        (searchResults) {
          filteredSuppliers.value = searchResults;
        },
      );
    } catch (e) {
      error.value = 'Error en búsqueda: $e';
      filteredSuppliers.value = suppliers;
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> loadStats() async {
    try {
      final result = await getSupplierStatsUseCase(const NoParams());

      result.fold(
        (failure) {
          print('Error cargando estadísticas: ${failure.message}');
        },
        (supplierStats) {
          stats.value = supplierStats;
        },
      );
    } catch (e) {
      print('Error inesperado cargando estadísticas: $e');
    }
  }

  // ==================== PAGINATION ====================

  Future<void> loadNextPage() async {
    if (!isLoadingMore.value && hasNextPage.value) {
      isLoadingMore.value = true;
      currentPage.value++;
      await loadSuppliers(showLoading: false);
    }
  }

  Future<void> loadPreviousPage() async {
    if (!isLoadingMore.value && hasPrevPage.value) {
      isLoadingMore.value = true;
      currentPage.value--;
      await loadSuppliers(showLoading: false);
    }
  }

  void goToFirstPage() {
    if (currentPage.value != 1) {
      currentPage.value = 1;
      suppliers.clear();
      loadSuppliers();
    }
  }

  void goToLastPage() {
    if (currentPage.value != totalPages.value) {
      currentPage.value = totalPages.value;
      suppliers.clear();
      loadSuppliers();
    }
  }

  // ==================== REFRESH & RELOAD ====================

  Future<void> refreshSuppliers() async {
    // Evitar múltiples refrescos simultáneos
    if (isRefreshing.value || isLoading.value) {
      return;
    }

    isRefreshing.value = true;
    currentPage.value = 1;
    suppliers.clear();
    await loadSuppliers(showLoading: false);
    await loadStats();
    isRefreshing.value = false;
  }

  void reloadSuppliers() {
    currentPage.value = 1;
    suppliers.clear();
    loadSuppliers();
  }

  // ==================== FILTERING ====================

  void applyFilters() {
    currentPage.value = 1;
    suppliers.clear();
    loadSuppliers();
  }

  void clearFilters() {
    statusFilter.value = null;
    documentTypeFilter.value = null;
    currencyFilter.value = '';
    hasEmailFilter.value = false;
    hasPhoneFilter.value = false;
    hasCreditLimitFilter.value = false;
    hasDiscountFilter.value = false;
    searchController.clear();
    searchQuery.value = '';

    currentPage.value = 1;
    suppliers.clear();
    loadSuppliers();
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  // ==================== SORTING ====================

  void sortSuppliers(String field) {
    if (sortBy.value == field) {
      // Cambiar orden si es el mismo campo
      sortOrder.value = sortOrder.value == 'asc' ? 'desc' : 'asc';
    } else {
      // Nuevo campo, empezar con ascendente
      sortBy.value = field;
      sortOrder.value = 'asc';
    }

    currentPage.value = 1;
    suppliers.clear();
    loadSuppliers();
  }

  // ==================== SUPPLIER ACTIONS ====================

  Future<void> deleteSupplier(String id) async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
            '¿Está seguro de que desea eliminar este proveedor?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (result == true) {
        isLoading.value = true;

        final deleteResult = await deleteSupplierUseCase(id);

        deleteResult.fold(
          (failure) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red.shade100,
              colorText: Colors.red.shade800,
            );
          },
          (_) {
            Get.snackbar(
              'Éxito',
              'Proveedor eliminado correctamente',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade800,
            );

            // Recargar lista
            refreshSuppliers();
          },
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== NAVIGATION ====================

  void goToSupplierDetail(String supplierId) {
    Get.toNamed('/suppliers/detail/$supplierId');
  }

  void goToSupplierEdit(String supplierId) {
    Get.toNamed('/suppliers/edit/$supplierId');
  }

  void goToCreateSupplier() {
    Get.toNamed('/suppliers/create');
  }

  // ==================== UI HELPERS ====================

  void switchTab(int index) {
    selectedTab.value = index;
    if (index == 1 && stats.value == null) {
      loadStats();
    }
  }

  String getStatusText(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return 'Activo';
      case SupplierStatus.inactive:
        return 'Inactivo';
      case SupplierStatus.blocked:
        return 'Bloqueado';
    }
  }

  Color getStatusColor(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return Colors.green;
      case SupplierStatus.inactive:
        return Colors.orange;
      case SupplierStatus.blocked:
        return Colors.red;
    }
  }

  String getDocumentTypeText(DocumentType? type) {
    if (type == null) return 'Sin documento';

    switch (type) {
      case DocumentType.nit:
        return 'NIT';
      case DocumentType.cc:
        return 'Cédula de Ciudadanía';
      case DocumentType.ce:
        return 'Cédula de Extranjería';
      case DocumentType.passport:
        return 'Pasaporte';
      case DocumentType.rut:
        return 'RUT';
      case DocumentType.other:
        return 'Otro';
    }
  }

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  String formatDate(DateTime date) {
    return AppFormatters.formatDate(date);
  }

  String formatDateTime(DateTime dateTime) {
    return AppFormatters.formatDateTime(dateTime);
  }

  // ==================== COMPUTED PROPERTIES ====================

  List<Supplier> get displayedSuppliers => filteredSuppliers;

  bool get hasSuppliers => suppliers.isNotEmpty;

  bool get hasResults => filteredSuppliers.isNotEmpty;

  String get resultsText {
    if (searchQuery.value.isNotEmpty) {
      return '${filteredSuppliers.length} resultados para "${searchQuery.value}"';
    } else {
      return '${totalItems.value} proveedores';
    }
  }

  bool get canLoadMore =>
      hasNextPage.value && !isLoadingMore.value && !isLoading.value;

  Map<String, dynamic> get activeFiltersCount {
    int count = 0;
    final List<String> activeFilters = [];

    if (statusFilter.value != null) {
      count++;
      activeFilters.add('Estado: ${getStatusText(statusFilter.value!)}');
    }
    if (documentTypeFilter.value != null) {
      count++;
      activeFilters.add(
        'Documento: ${getDocumentTypeText(documentTypeFilter.value)}',
      );
    }
    if (currencyFilter.value.isNotEmpty) {
      count++;
      activeFilters.add('Moneda: ${currencyFilter.value}');
    }
    if (hasEmailFilter.value) {
      count++;
      activeFilters.add('Con email');
    }
    if (hasPhoneFilter.value) {
      count++;
      activeFilters.add('Con teléfono');
    }
    if (hasCreditLimitFilter.value) {
      count++;
      activeFilters.add('Con crédito');
    }
    if (hasDiscountFilter.value) {
      count++;
      activeFilters.add('Con descuento');
    }

    return {'count': count, 'filters': activeFilters};
  }
}
