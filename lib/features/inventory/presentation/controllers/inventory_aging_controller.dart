// lib/features/inventory/presentation/controllers/inventory_aging_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../domain/usecases/get_inventory_aging_usecase.dart';
import '../services/inventory_export_service.dart';
import 'package:baudex_desktop/app/core/errors/automatic_work.dart';
import 'package:baudex_desktop/app/core/theme/futuristic_notifications.dart';

class InventoryAgingController extends GetxController {
  final GetInventoryAgingUseCase getInventoryAgingUseCase;

  InventoryAgingController({required this.getInventoryAgingUseCase});

  // ==================== REACTIVE VARIABLES ====================

  final RxList<Map<String, dynamic>> agingData = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<AgingSummary?> agingSummary = Rx<AgingSummary?>(null);

  // Filters
  final RxString selectedWarehouseId = ''.obs;
  final RxString selectedCategoryId = ''.obs;
  final RxInt minAgeDays = 0.obs;
  final RxInt maxAgeDays = 365.obs;

  @override
  void onInit() {
    super.onInit();
    loadAgingReport();
  }

  // ==================== DATA LOADING ====================

  Future<void> loadAgingReport() async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await getInventoryAgingUseCase(
        warehouseId:
            selectedWarehouseId.value.isNotEmpty
                ? selectedWarehouseId.value
                : null,
      );

      result.fold(
        (failure) {
          error.value = failure.message;
          if (!AutomaticWork.swallow('Error al cargar reporte', failure.message)) FuturisticNotifications.showError(
            'Error al cargar reporte',
            failure.message,
          );
        },
        (data) {
          agingData.value = data;
          _calculateSummary(data);
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
      if (!AutomaticWork.swallow('Error al cargar reporte', 'Error inesperado: $e')) FuturisticNotifications.showError(
        'Error al cargar reporte',
        'Error inesperado: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateSummary(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      agingSummary.value = null;
      return;
    }

    int totalProducts = data.length;
    double totalValue = 0.0;
    int totalAgeDays = 0;

    for (final item in data) {
      totalValue += (item['totalValue'] ?? 0.0).toDouble();
      totalAgeDays += (item['averageAgeDays'] as num?)?.toInt() ?? 0;
    }

    final averageAgeDays =
        totalProducts > 0 ? (totalAgeDays / totalProducts).round() : 0;

    agingSummary.value = AgingSummary(
      totalProducts: totalProducts,
      totalValue: totalValue,
      averageAgeDays: averageAgeDays,
    );
  }

  // ==================== UI HELPERS ====================

  Future<void> refreshReport() async {
    await loadAgingReport();
  }

  void updateWarehouse(String? warehouseId) {
    selectedWarehouseId.value = warehouseId ?? '';
    loadAgingReport();
  }

  void updateCategory(String? categoryId) {
    selectedCategoryId.value = categoryId ?? '';
    loadAgingReport();
  }

  void updateAgeRange(int minDays, int maxDays) {
    minAgeDays.value = minDays;
    maxAgeDays.value = maxDays;
  }

  void applyFilters() {
    loadAgingReport();
  }

  void clearFilters() {
    selectedWarehouseId.value = '';
    selectedCategoryId.value = '';
    minAgeDays.value = 0;
    maxAgeDays.value = 365;
    loadAgingReport();
  }

  // ==================== EXPORT METHODS ====================

  Future<void> exportToExcel() async {
    try {
      if (agingData.isEmpty) {
        FuturisticNotifications.showWarning(
          'Sin datos',
          'No hay datos de antigüedad para exportar',
        );
        return;
      }

      isLoading.value = true;
      await _createAgingExcelReport();

      FuturisticNotifications.showSuccess(
        'Éxito',
        'Reporte de antigüedad exportado a Excel correctamente',
      );
    } catch (e) {
      if (!AutomaticWork.swallow('Error', 'Error exportando a Excel: $e')) FuturisticNotifications.showError(
        'Error',
        'Error exportando a Excel: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportToPdf() async {
    try {
      if (agingData.isEmpty) {
        FuturisticNotifications.showWarning(
          'Sin datos',
          'No hay datos de antigüedad para exportar',
        );
        return;
      }

      isLoading.value = true;
      await _createAgingPdfReport();

      FuturisticNotifications.showSuccess(
        'Éxito',
        'Reporte de antigüedad exportado a PDF correctamente',
      );
    } catch (e) {
      if (!AutomaticWork.swallow('Error', 'Error exportando a PDF: $e')) FuturisticNotifications.showError(
        'Error',
        'Error exportando a PDF: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createAgingExcelReport() async {
    // Create a custom export for aging data since it's different from standard inventory
    // This will use the InventoryExportService pattern but customized for aging data
    await InventoryExportService.exportAgingDataToExcel(agingData);
  }

  Future<void> _createAgingPdfReport() async {
    // Create a custom export for aging data
    await InventoryExportService.exportAgingDataToPDF(
      agingData,
      agingSummary.value,
    );
  }

  void showExportOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Exportar Reporte de Antigüedad',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                    title: const Text('Exportar a PDF'),
                    subtitle: const Text('Formato para impresión'),
                    onTap: () {
                      Get.back();
                      exportToPdf();
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.table_chart, color: Colors.green),
                    title: const Text('Exportar a Excel'),
                    subtitle: const Text('Formato para análisis'),
                    onTap: () {
                      Get.back();
                      exportToExcel();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ==================== COMPUTED PROPERTIES ====================

  bool get hasData => agingData.isNotEmpty;
  bool get hasError => error.value.isNotEmpty;
  bool get hasSummary => agingSummary.value != null;
}

class AgingSummary {
  final int totalProducts;
  final double totalValue;
  final int averageAgeDays;

  AgingSummary({
    required this.totalProducts,
    required this.totalValue,
    required this.averageAgeDays,
  });
}
