// lib/features/inventory/presentation/controllers/kardex_controller.dart
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/kardex_report.dart';
import '../../domain/usecases/get_kardex_report_usecase.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../services/inventory_export_service.dart';

class KardexController extends GetxController {
  final GetKardexReportUseCase getKardexReportUseCase;

  KardexController({required this.getKardexReportUseCase});

  // ==================== REACTIVE VARIABLES ====================

  final Rx<KardexReport?> kardexReport = Rx<KardexReport?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;
  final RxString productId = ''.obs;

  // Filter parameters - Default to current month
  final Rx<DateTime> startDate =
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1,
      ).obs; // Start of current month
  final Rx<DateTime> endDate = DateTime.now().obs;
  final RxString warehouseId = ''.obs;

  // UI State
  final RxBool showFilters = false.obs;
  final RxInt selectedTab = 0.obs; // 0: Resumen, 1: Movimientos

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  // ==================== INITIALIZATION ====================

  void _initializeData() {
    // Obtener el productId desde los argumentos
    final args = Get.arguments as Map<String, dynamic>?;
    final paramId = Get.parameters['productId'];

    if (args != null && args.containsKey('productId')) {
      productId.value = args['productId'] as String;
    } else if (paramId != null) {
      productId.value = paramId;
    }

    if (productId.value.isNotEmpty) {
      loadKardex();
    } else {
      error.value = 'ID de producto no válido';
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> loadKardex() async {
    try {
      isLoading.value = true;
      error.value = '';
      print(
        '🔍 KardexController: Cargando kardex para producto ${productId.value}',
      );

      final params = KardexReportParams(
        productId: productId.value,
        startDate: startDate.value,
        endDate: endDate.value,
        warehouseId: warehouseId.value.isNotEmpty ? warehouseId.value : null,
      );

      final result = await getKardexReportUseCase(params);

      result.fold(
        (failure) {
          print('❌ KardexController: Error - ${failure.message}');
          error.value = failure.message;
          Get.snackbar(
            'Error al cargar kardex',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (report) {
          print(
            '✅ KardexController: Kardex cargado - ${report.totalMovements} movimientos',
          );
          kardexReport.value = report;
        },
      );
    } catch (e) {
      print('❌ KardexController: Exception - $e');
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error al cargar kardex',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshKardex() async {
    await loadKardex();
  }

  // ==================== FILTER MANAGEMENT ====================

  void updateDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    loadKardex();
  }

  void updateWarehouse(String? warehouse) {
    warehouseId.value = warehouse ?? '';
    loadKardex();
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  void resetFilters() {
    startDate.value = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    ); // Start of current month
    endDate.value = DateTime.now();
    warehouseId.value = '';
    loadKardex();
  }

  // ==================== UI HELPERS ====================

  void switchTab(int index) {
    selectedTab.value = index;
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

  Color getMovementColor(KardexMovement movement) {
    if (movement.isEntry) return Colors.green;
    if (movement.isExit) return Colors.red;
    return Colors.grey;
  }

  IconData getMovementIcon(KardexMovement movement) {
    if (movement.isEntry) return Icons.arrow_upward;
    if (movement.isExit) return Icons.arrow_downward;
    return Icons.remove;
  }

  // ==================== NAVIGATION ====================

  void goToMovementDetail(String movementId) {
    Get.toNamed(
      '/inventory/movements/detail/$movementId',
      arguments: {'movementId': movementId},
    );
  }

  void goToProductDetail() {
    if (productId.value.isNotEmpty) {
      Get.toNamed(
        '/products/detail/${productId.value}',
        arguments: {'productId': productId.value},
      );
    }
  }

  // ==================== EXPORT FUNCTIONS ====================

  Future<void> exportKardexToPdf() async {
    try {
      if (kardexReport.value == null || !kardexReport.value!.hasMovements) {
        Get.snackbar(
          'Sin datos',
          'No hay datos de kardex para exportar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      isLoading.value = true;
      await InventoryExportService.exportKardexReportToPDF(kardexReport.value!);

      Get.snackbar(
        'Éxito',
        'Kardex exportado a PDF correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error exportando kardex a PDF: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportKardexToExcel() async {
    try {
      if (kardexReport.value == null || !kardexReport.value!.hasMovements) {
        Get.snackbar(
          'Sin datos',
          'No hay datos de kardex para exportar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      isLoading.value = true;
      await InventoryExportService.exportKardexReportToExcel(
        kardexReport.value!,
      );

      Get.snackbar(
        'Éxito',
        'Kardex exportado a Excel correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error exportando kardex a Excel: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== ✅ NUEVOS MÉTODOS PROFESIONALES ====================

  /// Descarga de kardex a Excel con picker de ubicación
  Future<void> downloadKardexToExcel() async {
    try {
      if (kardexReport.value == null || !kardexReport.value!.hasMovements) {
        Get.snackbar(
          'Sin datos',
          'No hay datos de kardex para descargar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      isLoading.value = true;
      final filePath = await InventoryExportService.downloadKardexToExcel(
        kardexReport.value!,
      );

      // Extraer solo el nombre del archivo para notificación más limpia
      final fileName = filePath.split('/').last;

      Get.snackbar(
        'Descarga completada',
        'Archivo "$fileName" guardado exitosamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (e.toString().contains('cancelada por el usuario')) {
        Get.snackbar('Cancelado', 'Descarga cancelada');
      } else {
        Get.snackbar(
          'Error',
          'Error descargando Excel: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Descarga de kardex a PDF con picker de ubicación
  Future<void> downloadKardexToPdf() async {
    try {
      if (kardexReport.value == null || !kardexReport.value!.hasMovements) {
        Get.snackbar(
          'Sin datos',
          'No hay datos de kardex para descargar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      isLoading.value = true;
      final filePath = await InventoryExportService.downloadKardexToPdf(
        kardexReport.value!,
      );

      // Extraer solo el nombre del archivo para notificación más limpia
      final fileName = filePath.split('/').last;

      Get.snackbar(
        'Descarga completada',
        'Archivo "$fileName" guardado exitosamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (e.toString().contains('cancelada por el usuario')) {
        Get.snackbar('Cancelado', 'Descarga cancelada');
      } else {
        Get.snackbar(
          'Error',
          'Error descargando PDF: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Compartir kardex como PDF
  Future<void> shareKardexToPdf() async {
    try {
      if (kardexReport.value == null || !kardexReport.value!.hasMovements) {
        Get.snackbar(
          'Sin datos',
          'No hay datos de kardex para compartir',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
        return;
      }

      isLoading.value = true;
      await InventoryExportService.shareKardexToPdf(kardexReport.value!);
    } catch (e) {
      Get.snackbar(
        'Error al compartir',
        'No se pudo compartir el archivo PDF: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
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
              'Exportar Kardex',
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
                      exportKardexToPdf();
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
                      exportKardexToExcel();
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

  bool get hasKardex => kardexReport.value != null;
  bool get hasMovements => kardexReport.value?.hasMovements ?? false;
  bool get hasEntries => hasMovements; // Alias for backward compatibility
  bool get hasError => error.value.isNotEmpty;

  // Backward compatibility - return movements as entries
  List<KardexMovement> get kardexEntries => kardexReport.value?.movements ?? [];

  // Backward compatibility - provide access to summary via old interface
  dynamic get kardexSummary =>
      kardexReport.value != null
          ? _KardexSummaryWrapper(kardexReport.value!)
          : null;

  String get displayTitle =>
      hasKardex
          ? 'Kardex - ${kardexReport.value!.product.name}'
          : 'Kardex de Producto';

  int get totalMovements => kardexReport.value?.totalMovements ?? 0;
  int get entriesCount => kardexReport.value?.entriesCount ?? 0;
  int get exitsCount => kardexReport.value?.exitsCount ?? 0;

  String get dateRangeText {
    final start = startDate.value;
    final end = endDate.value;

    // Check for common ranges
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    if (start.isAtSameMomentAs(startOfMonth) &&
        end.isAtSameMomentAs(DateTime(end.year, end.month, end.day)) &&
        end.month == now.month &&
        end.year == now.year) {
      return 'Este mes';
    } else if (start.isAtSameMomentAs(startOfYear) &&
        end.isAtSameMomentAs(DateTime(end.year, end.month, end.day)) &&
        end.year == now.year) {
      return 'Este año';
    } else if (start.isAtSameMomentAs(DateTime(2020, 1, 1))) {
      return 'Todo el historial';
    } else {
      return '${formatDate(start)} - ${formatDate(end)}';
    }
  }

  List<Map<String, dynamic>> get summaryCards {
    if (!hasKardex) return [];

    final report = kardexReport.value!;
    final summary = report.summary;
    return [
      {
        'title': 'Existencia Inicial',
        'value': '${report.initialBalance.quantity.toInt()}',
        'subtitle': 'Costo: ${formatCurrency(report.initialBalance.value)}',
        'icon': Icons.inventory_2,
        'color': Colors.blue,
      },
      {
        'title': 'Entradas del Período',
        'value': '+${summary.totalEntries}',
        'subtitle': 'Costo: ${formatCurrency(summary.totalPurchases)}',
        'icon': Icons.arrow_upward,
        'color': Colors.green,
      },
      {
        'title': 'Salidas del Período',
        'value': '-${summary.totalExits}',
        'subtitle': 'Costo: ${formatCurrency(summary.totalSales)}',
        'icon': Icons.arrow_downward,
        'color': Colors.red,
      },
      {
        'title': 'Existencia Actual',
        'value': '${report.finalBalance.quantity.toInt()}',
        'subtitle': 'Costo: ${formatCurrency(report.finalBalance.value)}',
        'icon': Icons.account_balance,
        'color': Colors.purple,
      },
    ];
  }
}

// Backward compatibility wrapper
class _KardexSummaryWrapper {
  final KardexReport _report;

  _KardexSummaryWrapper(this._report);

  dynamic get value => this;
  String get productName => _report.product.name;
  String get productSku => _report.product.sku;

  // Summary properties
  int get entriesCount => _report.entriesCount;
  int get exitsCount => _report.exitsCount;
  int get totalEntries => _report.summary.totalEntries;
  int get totalExits => _report.summary.totalExits;
  int get totalMovements => _report.totalMovements;

  // Balance properties
  int get initialBalance => _report.initialBalance.quantity.toInt();
  int get finalBalance => _report.finalBalance.quantity.toInt();
  double get initialValue => _report.initialBalance.value;
  double get finalValue => _report.finalBalance.value;

  // Value properties
  double get totalInboundValue => _report.summary.totalPurchases;
  double get totalOutboundValue => _report.summary.totalSales;
  double get totalPurchases => _report.summary.totalPurchases;
  double get totalSales => _report.summary.totalSales;
  double get averageCost => _report.summary.averageUnitCost;

  // Date properties
  DateTime get fromDate => _report.period.startDate;
  DateTime get toDate => _report.period.endDate;

  // Calculated properties
  int get netMovement => _report.summary.netMovement;
  double get netValue => _report.summary.netValue;
  double get turnoverRatio => _report.summary.turnoverRatio;
}
