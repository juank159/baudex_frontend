// lib/features/invoices/presentation/controllers/invoice_stats_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_stats.dart';
import '../../domain/usecases/get_invoice_stats_usecase.dart';
import '../../domain/usecases/get_overdue_invoices_usecase.dart';

class InvoiceStatsController extends GetxController {
  // Dependencies
  final GetInvoiceStatsUseCase _getInvoiceStatsUseCase;
  final GetOverdueInvoicesUseCase _getOverdueInvoicesUseCase;

  InvoiceStatsController({
    required GetInvoiceStatsUseCase getInvoiceStatsUseCase,
    required GetOverdueInvoicesUseCase getOverdueInvoicesUseCase,
  }) : _getInvoiceStatsUseCase = getInvoiceStatsUseCase,
       _getOverdueInvoicesUseCase = getOverdueInvoicesUseCase {
    print('🎮 InvoiceStatsController: Instancia creada correctamente');
  }

  // ==================== OBSERVABLES ====================

  // Estados
  final _isLoadingStats = false.obs;
  final _isLoadingOverdue = false.obs;
  final _isRefreshing = false.obs;

  // Datos
  final Rxn<InvoiceStats> _stats = Rxn<InvoiceStats>();
  final _overdueInvoices = <Invoice>[].obs;

  // UI States
  final _selectedPeriod = StatsPeriod.thisMonth.obs;
  final _showOverdueDetails = false.obs;

  // ==================== GETTERS ====================

  bool get isLoadingStats => _isLoadingStats.value;
  bool get isLoadingOverdue => _isLoadingOverdue.value;
  bool get isRefreshing => _isRefreshing.value;
  bool get isLoading => _isLoadingStats.value || _isLoadingOverdue.value;

  InvoiceStats? get stats => _stats.value;
  List<Invoice> get overdueInvoices => _overdueInvoices;
  StatsPeriod get selectedPeriod => _selectedPeriod.value;
  bool get showOverdueDetails => _showOverdueDetails.value;

  bool get hasStats => _stats.value != null;
  bool get hasOverdueInvoices => _overdueInvoices.isNotEmpty;

  // Stats helpers
  int get totalInvoices => stats?.total ?? 0;
  int get draftInvoices => stats?.draft ?? 0;
  int get pendingInvoices => stats?.pending ?? 0;
  int get paidInvoices => stats?.paid ?? 0;
  int get overdueCount => stats?.overdue ?? 0;
  int get cancelledInvoices => stats?.cancelled ?? 0;
  int get partiallyPaidInvoices => stats?.partiallyPaid ?? 0;

  double get totalSales => stats?.totalSales ?? 0;
  double get pendingAmount => stats?.pendingAmount ?? 0;
  double get overdueAmount => stats?.overdueAmount ?? 0;

  double get paidPercentage => stats?.paidPercentage ?? 0;
  double get pendingPercentage => stats?.pendingPercentage ?? 0;
  double get overduePercentage => stats?.overduePercentage ?? 0;
  double get collectionRate => stats?.collectionRate ?? 0;

  int get activeInvoices => stats?.activeInvoices ?? 0;
  double get activeAmount => stats?.activeAmount ?? 0;

  bool get hasOverdueIssues => stats?.hasOverdueIssues ?? false;
  bool get hasCollectionIssues => stats?.hasCollectionIssues ?? false;
  bool get isHealthy => stats?.isHealthy ?? true;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    print('🚀 InvoiceStatsController: Inicializando...');
    loadAllData();
  }

  // ==================== CORE METHODS ====================

  /// Cargar todos los datos
  Future<void> loadAllData() async {
    await Future.wait([loadStats(), loadOverdueInvoices()]);
  }

  /// Cargar estadísticas
  Future<void> loadStats() async {
    try {
      _isLoadingStats.value = true;
      print('📊 Cargando estadísticas de facturas...');

      final result = await _getInvoiceStatsUseCase(NoParams());

      result.fold(
        (failure) {
          print('❌ Error al cargar estadísticas: ${failure.message}');
          _showError('Error al cargar estadísticas', failure.message);
        },
        (loadedStats) {
          _stats.value = loadedStats;
          print('✅ Estadísticas cargadas exitosamente');
          _logStatsInfo(loadedStats);
        },
      );
    } catch (e) {
      print('💥 Error inesperado al cargar estadísticas: $e');
      _showError('Error inesperado', 'No se pudieron cargar las estadísticas');
    } finally {
      _isLoadingStats.value = false;
    }
  }

  /// Cargar facturas vencidas
  Future<void> loadOverdueInvoices() async {
    try {
      _isLoadingOverdue.value = true;
      print('📅 Cargando facturas vencidas...');

      final result = await _getOverdueInvoicesUseCase(NoParams());

      result.fold(
        (failure) {
          print('❌ Error al cargar facturas vencidas: ${failure.message}');
          _showError('Error al cargar facturas vencidas', failure.message);
        },
        (invoices) {
          _overdueInvoices.value = invoices;
          print('✅ ${invoices.length} facturas vencidas cargadas');
        },
      );
    } catch (e) {
      print('💥 Error inesperado al cargar facturas vencidas: $e');
      _showError(
        'Error inesperado',
        'No se pudieron cargar las facturas vencidas',
      );
    } finally {
      _isLoadingOverdue.value = false;
    }
  }

  /// Refrescar todos los datos
  Future<void> refreshAllData() async {
    try {
      _isRefreshing.value = true;
      print('🔄 Refrescando datos de estadísticas...');

      await loadAllData();
      _showSuccess('Datos actualizados');
    } catch (e) {
      print('💥 Error al refrescar datos: $e');
    } finally {
      _isRefreshing.value = false;
    }
  }

  // ==================== UI METHODS ====================

  /// Cambiar período de estadísticas
  void changePeriod(StatsPeriod period) {
    _selectedPeriod.value = period;
    print('📊 Período cambiado a: ${period.name}');
    // TODO: Implementar filtro por período cuando el backend lo soporte
    loadStats();
  }

  /// Mostrar/ocultar detalles de facturas vencidas
  void toggleOverdueDetails() {
    _showOverdueDetails.value = !_showOverdueDetails.value;
    print('👁️ Detalles de vencidas: ${_showOverdueDetails.value}');
  }

  // ==================== CHART DATA METHODS ====================

  /// Obtener datos para gráfico de estado de facturas
  List<ChartData> getStatusChartData() {
    if (!hasStats) return [];

    return [
      ChartData('Borradores', draftInvoices.toDouble(), Colors.grey),
      ChartData('Pendientes', pendingInvoices.toDouble(), Colors.orange),
      ChartData('Pagadas', paidInvoices.toDouble(), Colors.green),
      ChartData('Vencidas', overdueCount.toDouble(), Colors.red),
      ChartData('Pago Parcial', partiallyPaidInvoices.toDouble(), Colors.blue),
      ChartData(
        'Canceladas',
        cancelledInvoices.toDouble(),
        Colors.grey.shade400,
      ),
    ].where((data) => data.value > 0).toList();
  }

  /// Obtener datos para gráfico de montos
  List<ChartData> getAmountChartData() {
    if (!hasStats) return [];

    final collectedAmount = totalSales - pendingAmount;

    return [
      ChartData('Cobrado', collectedAmount, Colors.green),
      ChartData('Pendiente', pendingAmount - overdueAmount, Colors.orange),
      ChartData('Vencido', overdueAmount, Colors.red),
    ].where((data) => data.value > 0).toList();
  }

  /// Obtener datos para indicadores de rendimiento
  List<PerformanceIndicator> getPerformanceIndicators() {
    if (!hasStats) return [];

    return [
      PerformanceIndicator(
        title: 'Tasa de Cobro',
        value: collectionRate,
        unit: '%',
        target: 85,
        isGood: collectionRate >= 85,
        icon: Icons.trending_up,
      ),
      PerformanceIndicator(
        title: 'Facturas Pagadas',
        value: paidPercentage,
        unit: '%',
        target: 80,
        isGood: paidPercentage >= 80,
        icon: Icons.check_circle_outline,
      ),
      PerformanceIndicator(
        title: 'Facturas Vencidas',
        value: overduePercentage,
        unit: '%',
        target: 5,
        isGood: overduePercentage <= 5,
        icon: Icons.warning_outlined,
        isInverted: true, // Menor es mejor
      ),
    ];
  }

  // ==================== NAVIGATION METHODS ====================

  /// Navegar a lista de facturas con filtro
  void goToInvoiceList({InvoiceStatus? status}) {
    if (status != null) {
      Get.toNamed('/invoices', parameters: {'status': status.value});
    } else {
      Get.toNamed('/invoices');
    }
  }

  /// Navegar a facturas vencidas
  void goToOverdueInvoices() {
    Get.toNamed('/invoices', parameters: {'status': 'overdue'});
  }

  /// Navegar a crear factura
  void goToCreateInvoice() {
    Get.toNamed('/invoices/create');
  }

  /// Navegar a detalles de factura
  void goToInvoiceDetail(String invoiceId) {
    Get.toNamed('/invoices/detail/$invoiceId');
  }

  // ==================== HELPER METHODS ====================

  /// Obtener color para indicador de salud
  Color getHealthColor() {
    if (!hasStats) return Colors.grey;

    if (isHealthy) {
      return Colors.green;
    } else if (hasOverdueIssues && hasCollectionIssues) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  /// Obtener icono para indicador de salud
  IconData getHealthIcon() {
    if (!hasStats) return Icons.help;

    if (isHealthy) {
      return Icons.check_circle;
    } else if (hasOverdueIssues && hasCollectionIssues) {
      return Icons.error;
    } else {
      return Icons.warning;
    }
  }

  /// Obtener mensaje de salud
  String getHealthMessage() {
    if (!hasStats) return 'Datos no disponibles';

    if (isHealthy) {
      return 'Estado financiero saludable';
    } else {
      List<String> issues = [];
      if (hasOverdueIssues) {
        issues.add('muchas facturas vencidas');
      }
      if (hasCollectionIssues) {
        issues.add('problemas de cobro');
      }
      return 'Atención: ${issues.join(' y ')}';
    }
  }

  /// Log de información de estadísticas
  void _logStatsInfo(InvoiceStats stats) {
    print('📊 === ESTADÍSTICAS DE FACTURAS ===');
    print('   Total: ${stats.total}');
    print(
      '   Pagadas: ${stats.paid} (${stats.paidPercentage.toStringAsFixed(1)}%)',
    );
    print(
      '   Pendientes: ${stats.pending} (${stats.pendingPercentage.toStringAsFixed(1)}%)',
    );
    print(
      '   Vencidas: ${stats.overdue} (${stats.overduePercentage.toStringAsFixed(1)}%)',
    );
    print('   Ventas totales: \$${stats.totalSales.toStringAsFixed(2)}');
    print('   Monto pendiente: \$${stats.pendingAmount.toStringAsFixed(2)}');
    print('   Monto vencido: \$${stats.overdueAmount.toStringAsFixed(2)}');
    print('   Tasa de cobro: ${stats.collectionRate.toStringAsFixed(1)}%');
    print('   Estado: ${stats.isHealthy ? "Saludable" : "Requiere atención"}');
    print('================================');
  }

  // ==================== MESSAGE HELPERS ====================

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
}

// ==================== DATA CLASSES ====================

enum StatsPeriod {
  today('Hoy'),
  thisWeek('Esta Semana'),
  thisMonth('Este Mes'),
  thisQuarter('Este Trimestre'),
  thisYear('Este Año'),
  allTime('Todo el Tiempo');

  const StatsPeriod(this.displayName);
  final String displayName;
}

class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}

class PerformanceIndicator {
  final String title;
  final double value;
  final String unit;
  final double target;
  final bool isGood;
  final IconData icon;
  final bool isInverted;

  PerformanceIndicator({
    required this.title,
    required this.value,
    required this.unit,
    required this.target,
    required this.isGood,
    required this.icon,
    this.isInverted = false,
  });

  Color get color => isGood ? Colors.green : Colors.red;

  String get displayValue => '${value.toStringAsFixed(1)}$unit';

  String get targetText =>
      '${isInverted ? "≤" : "≥"} ${target.toStringAsFixed(0)}$unit';
}
