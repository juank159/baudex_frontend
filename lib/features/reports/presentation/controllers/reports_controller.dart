// lib/features/reports/presentation/controllers/reports_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_valuation_report.dart';
import '../../domain/entities/profitability_report.dart';
import '../../domain/usecases/get_inventory_valuation_by_categories_usecase.dart';
import '../../domain/usecases/get_inventory_valuation_by_products_usecase.dart';
import '../../domain/usecases/get_inventory_valuation_summary_usecase.dart';
import '../../domain/usecases/get_profitability_by_categories_usecase.dart';
import '../../domain/usecases/get_profitability_by_products_usecase.dart';
import '../../domain/usecases/get_profitability_trends_usecase.dart';
import '../../domain/usecases/get_top_profitable_products_usecase.dart';
import '../../domain/usecases/get_valuation_variances_usecase.dart';
import '../../domain/repositories/reports_repository.dart';

class ReportsController extends GetxController {
  final GetProfitabilityByProductsUseCase getProfitabilityByProductsUseCase;
  final GetProfitabilityByCategoriesUseCase getProfitabilityByCategoriesUseCase;
  final GetTopProfitableProductsUseCase getTopProfitableProductsUseCase;
  final GetInventoryValuationSummaryUseCase getInventoryValuationSummaryUseCase;
  final GetInventoryValuationByProductsUseCase
  getInventoryValuationByProductsUseCase;
  final GetInventoryValuationByCategoriesUseCase
  getInventoryValuationByCategoriesUseCase;
  final GetProfitabilityTrendsUseCase getProfitabilityTrendsUseCase;
  final GetValuationVariancesUseCase getValuationVariancesUseCase;

  ReportsController({
    required this.getProfitabilityByProductsUseCase,
    required this.getProfitabilityByCategoriesUseCase,
    required this.getTopProfitableProductsUseCase,
    required this.getInventoryValuationSummaryUseCase,
    required this.getInventoryValuationByProductsUseCase,
    required this.getInventoryValuationByCategoriesUseCase,
    required this.getProfitabilityTrendsUseCase,
    required this.getValuationVariancesUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================

  // Profitability Reports
  final RxList<ProfitabilityReport> profitabilityByProducts =
      <ProfitabilityReport>[].obs;
  final RxList<ProfitabilityReport> profitabilityByCategories =
      <ProfitabilityReport>[].obs;
  final RxList<CategoryProfitabilityReport> profitabilityCategoriesData =
      <CategoryProfitabilityReport>[].obs;
  final RxList<ProfitabilityReport> topProfitableProducts =
      <ProfitabilityReport>[].obs;
  final RxList<ProfitabilityTrend> profitabilityTrends =
      <ProfitabilityTrend>[].obs;

  // Valuation Reports
  final Rx<InventoryValuationSummary?> valuationSummary =
      Rx<InventoryValuationSummary?>(null);
  final RxList<InventoryValuationReport> valuationByProducts =
      <InventoryValuationReport>[].obs;
  final RxList<CategoryValuationBreakdown> valuationByCategories =
      <CategoryValuationBreakdown>[].obs;
  final RxList<InventoryValuationVariance> valuationVariances =
      <InventoryValuationVariance>[].obs;

  // Loading states
  final RxBool isLoadingProfitability = false.obs;
  final RxBool isLoadingValuation = false.obs;
  final RxBool isLoadingTrends = false.obs;
  final RxBool isLoadingVariances = false.obs;
  final RxString error = ''.obs;

  // Filters
  final Rx<DateTime?> startDate = Rx<DateTime?>(
    DateTime.now().subtract(const Duration(days: 30)),
  );
  final Rx<DateTime?> endDate = Rx<DateTime?>(DateTime.now());
  final Rx<DateTime?> asOfDate = Rx<DateTime?>(DateTime.now());
  final RxString selectedCategoryId = ''.obs;
  final RxString selectedWarehouseId = ''.obs;
  final RxString valuationMethod = 'FIFO'.obs;
  final RxInt topProductsLimit = 10.obs;
  final RxString profitabilitySortBy = 'grossProfit'.obs;
  final RxString trendsGranularity = 'daily'.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  void _initializeData() {
    // Load initial dashboard data
    loadProfitabilityDashboard();
    loadValuationDashboard();
  }

  // ==================== PROFITABILITY REPORTS ====================

  Future<void> loadProfitabilityDashboard() async {
    await Future.wait([
      loadProfitabilityByProducts(),
      loadTopProfitableProducts(),
    ]);
  }

  Future<void> loadProfitabilityByProducts() async {
    try {
      isLoadingProfitability.value = true;
      error.value = '';

      final params = ProfitabilityReportParams(
        startDate:
            startDate.value ??
            DateTime.now().subtract(const Duration(days: 30)),
        endDate: endDate.value ?? DateTime.now(),
        categoryId:
            selectedCategoryId.value.isNotEmpty
                ? selectedCategoryId.value
                : null,
      );

      final result = await getProfitabilityByProductsUseCase(params);

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
          profitabilityByProducts.value = paginatedResult.data;
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoadingProfitability.value = false;
    }
  }

  Future<void> loadProfitabilityByCategories() async {
    try {
      isLoadingProfitability.value = true;
      error.value = '';

      final params = ProfitabilityReportParams(
        startDate:
            startDate.value ??
            DateTime.now().subtract(const Duration(days: 30)),
        endDate: endDate.value ?? DateTime.now(),
      );

      final result = await getProfitabilityByCategoriesUseCase(params);

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
          profitabilityByCategories.value =
              paginatedResult.data
                  .map(
                    (cat) => ProfitabilityReport(
                      productId: cat.categoryId,
                      productName: cat.categoryName,
                      productSku: '',
                      quantitySold: cat.quantitySold,
                      totalRevenue: cat.totalRevenue,
                      totalCost: cat.totalCost,
                      grossProfit: cat.grossProfit,
                      profitMargin: cat.profitMargin,
                      profitPercentage: cat.profitPercentage,
                      averageSellingPrice: 0,
                      averageCostPrice: 0,
                      periodStart: cat.periodStart,
                      periodEnd: cat.periodEnd,
                    ),
                  )
                  .toList();
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoadingProfitability.value = false;
    }
  }

  Future<void> loadTopProfitableProducts() async {
    try {
      isLoadingProfitability.value = true;
      error.value = '';

      final params = TopProfitableProductsParams(
        startDate:
            startDate.value ??
            DateTime.now().subtract(const Duration(days: 30)),
        endDate: endDate.value ?? DateTime.now(),
        categoryId:
            selectedCategoryId.value.isNotEmpty
                ? selectedCategoryId.value
                : null,
        limit: topProductsLimit.value,
      );

      final result = await getTopProfitableProductsUseCase(params);

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
        (reports) {
          topProfitableProducts.value = reports;
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoadingProfitability.value = false;
    }
  }

  Future<void> loadProfitabilityTrends() async {
    try {
      isLoadingTrends.value = true;
      error.value = '';

      final params = ProfitabilityTrendsParams(
        startDate: startDate.value!,
        endDate: endDate.value!,
        period: trendsGranularity.value,
        categoryId:
            selectedCategoryId.value.isNotEmpty
                ? selectedCategoryId.value
                : null,
      );

      final result = await getProfitabilityTrendsUseCase(params);

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
        (trends) {
          profitabilityTrends.value = trends;
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoadingTrends.value = false;
    }
  }

  // ==================== VALUATION REPORTS ====================

  Future<void> loadValuationDashboard() async {
    await Future.wait([loadValuationSummary(), loadValuationByProducts()]);
  }

  Future<void> loadValuationSummary() async {
    try {
      isLoadingValuation.value = true;
      error.value = '';

      final params = InventoryValuationParams(
        asOfDate: asOfDate.value,
        warehouseId:
            selectedWarehouseId.value.isNotEmpty
                ? selectedWarehouseId.value
                : null,
        categoryId:
            selectedCategoryId.value.isNotEmpty
                ? selectedCategoryId.value
                : null,
      );

      final result = await getInventoryValuationSummaryUseCase(params);

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
        (summary) {
          valuationSummary.value = summary;
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoadingValuation.value = false;
    }
  }

  Future<void> loadValuationByProducts() async {
    try {
      isLoadingValuation.value = true;
      error.value = '';

      final params = InventoryValuationParams(
        asOfDate: asOfDate.value,
        warehouseId:
            selectedWarehouseId.value.isNotEmpty
                ? selectedWarehouseId.value
                : null,
        categoryId:
            selectedCategoryId.value.isNotEmpty
                ? selectedCategoryId.value
                : null,
      );

      final result = await getInventoryValuationByProductsUseCase(params);

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
          valuationByProducts.value = paginatedResult.data;
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoadingValuation.value = false;
    }
  }

  Future<void> loadValuationByCategories() async {
    try {
      isLoadingValuation.value = true;
      error.value = '';

      final params = InventoryValuationParams(
        asOfDate: asOfDate.value,
        warehouseId:
            selectedWarehouseId.value.isNotEmpty
                ? selectedWarehouseId.value
                : null,
      );

      final result = await getInventoryValuationByCategoriesUseCase(params);

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
          valuationByCategories.value = paginatedResult.data;
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoadingValuation.value = false;
    }
  }

  Future<void> loadValuationVariances() async {
    try {
      isLoadingVariances.value = true;
      error.value = '';

      final params = ValuationVariancesParams(
        asOfDate: asOfDate.value,
        warehouseId:
            selectedWarehouseId.value.isNotEmpty
                ? selectedWarehouseId.value
                : null,
        categoryId:
            selectedCategoryId.value.isNotEmpty
                ? selectedCategoryId.value
                : null,
      );

      final result = await getValuationVariancesUseCase(params);

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
          valuationVariances.value = paginatedResult.data;
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
    } finally {
      isLoadingVariances.value = false;
    }
  }

  // ==================== FILTERS & ACTIONS ====================

  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    refreshProfitabilityReports();
  }

  void setAsOfDate(DateTime? date) {
    asOfDate.value = date;
    refreshValuationReports();
  }

  void setCategoryFilter(String categoryId) {
    selectedCategoryId.value = categoryId;
    refreshAllReports();
  }

  void setWarehouseFilter(String warehouseId) {
    selectedWarehouseId.value = warehouseId;
    refreshAllReports();
  }

  void setValuationMethod(String method) {
    valuationMethod.value = method;
    refreshValuationReports();
  }

  void setTopProductsLimit(int limit) {
    topProductsLimit.value = limit;
    loadTopProfitableProducts();
  }

  void setProfitabilitySortBy(String sortBy) {
    profitabilitySortBy.value = sortBy;
    loadTopProfitableProducts();
  }

  void setTrendsGranularity(String granularity) {
    trendsGranularity.value = granularity;
    loadProfitabilityTrends();
  }

  void clearFilters() {
    selectedCategoryId.value = '';
    selectedWarehouseId.value = '';
    startDate.value = DateTime.now().subtract(const Duration(days: 30));
    endDate.value = DateTime.now();
    asOfDate.value = DateTime.now();
    refreshAllReports();
  }

  Future<void> refreshAllReports() async {
    await Future.wait([
      refreshProfitabilityReports(),
      refreshValuationReports(),
    ]);
  }

  Future<void> refreshProfitabilityReports() async {
    await Future.wait([
      loadProfitabilityByProducts(),
      loadTopProfitableProducts(),
    ]);
  }

  Future<void> refreshValuationReports() async {
    await Future.wait([loadValuationSummary(), loadValuationByProducts()]);
  }

  // ==================== EXPORT METHODS ====================

  Future<void> exportProfitabilityReport() async {
    Get.snackbar(
      'Exportar Reporte',
      'Generando reporte de rentabilidad...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  Future<void> exportValuationReport() async {
    Get.snackbar(
      'Exportar Reporte',
      'Generando reporte de valoración...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  Future<void> exportCompleteReport() async {
    Get.snackbar(
      'Exportar Reporte',
      'Generando reporte completo...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
    );
  }

  // ==================== UI HELPERS ====================

  String formatCurrency(double amount) {
    return AppFormatters.formatCurrency(amount);
  }

  String formatDate(DateTime date) {
    return AppFormatters.formatDate(date);
  }

  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // ==================== COMPUTED PROPERTIES ====================

  bool get hasData =>
      profitabilityByProducts.isNotEmpty ||
      valuationByProducts.isNotEmpty ||
      valuationSummary.value != null;

  bool get isLoading =>
      isLoadingProfitability.value ||
      isLoadingValuation.value ||
      isLoadingTrends.value ||
      isLoadingVariances.value;

  double get totalProfitability => profitabilityByProducts.fold(
    0.0,
    (sum, report) => sum + report.grossProfit,
  );

  double get totalInventoryValue =>
      valuationSummary.value?.totalInventoryValue ?? 0.0;

  int get totalProducts => valuationSummary.value?.totalProducts ?? 0;
}
