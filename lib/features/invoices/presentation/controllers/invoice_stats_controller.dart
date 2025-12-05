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
  
  /// Facturas que requieren atención (pendientes + parcialmente pagadas)
  int get pendingAndPartialInvoices => (stats?.pending ?? 0) + (stats?.partiallyPaid ?? 0);
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
  Future<void> refreshAllData({bool showSuccessMessage = false}) async {
    try {
      _isRefreshing.value = true;
      print('🔄 Refrescando datos de estadísticas...');

      await loadAllData();

      // ✅ Solo mostrar mensaje si se solicita explícitamente (refresh manual)
      if (showSuccessMessage) {
        _showSuccess('Datos actualizados');
      }
    } catch (e) {
      print('💥 Error al refrescar datos: $e');
    } finally {
      _isRefreshing.value = false;
    }
  }

  // ==================== UI METHODS ====================

  /// Cambiar período de estadísticas
  /// El filtrado se hace localmente en la UI, no necesita recargar del backend
  void changePeriod(StatsPeriod period) {
    if (_selectedPeriod.value == period) return;

    _selectedPeriod.value = period;

    final range = period.getDateRange();
    print('📊 Período cambiado a: ${period.name}');
    print('   📅 Desde: ${range.start}');
    print('   📅 Hasta: ${range.end}');

    // Solo actualizar la UI - el filtrado se hace localmente en _calculateLocalStats y _calculateLocalAmounts
    update();
  }

  /// Obtener el rango de fechas del período actual
  DateTimeRange get currentPeriodRange => _selectedPeriod.value.getDateRange();

  /// Obtener descripción del período actual
  String get currentPeriodDescription => _selectedPeriod.value.getDateRangeDescription();

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
      ChartData('Pendientes', pendingAndPartialInvoices.toDouble(), Colors.orange),
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

  /// Navegar a lista de facturas
  void goToInvoiceList() {
    Get.toNamed('/invoices');
  }

  /// Navegar a facturas vencidas
  void goToOverdueInvoices() {
    Get.toNamed('/invoices/overdue');
  }

  /// Navegar a facturas por estado específico
  void goToInvoicesByStatus(InvoiceStatus status) {
    Get.toNamed('/invoices/status/${status.value}');
  }

  /// Navegar a facturas pendientes
  void goToPendingInvoices() {
    Get.toNamed('/invoices/status/pending');
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
  today('Hoy', 'Hoy'),
  thisWeek('Semana', 'Esta Semana'),
  thisMonth('Mes', 'Este Mes'),
  thisQuarter('Trimestre', 'Este Trimestre'),
  thisYear('Año', 'Este Año'),
  allTime('Todo', 'Todo el Tiempo');

  const StatsPeriod(this.shortName, this.displayName);
  final String shortName;
  final String displayName;

  /// Obtiene el rango de fechas para este período
  DateTimeRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case StatsPeriod.today:
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)),
        );
      case StatsPeriod.thisWeek:
        // Lunes de esta semana
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return DateTimeRange(start: startOfWeek, end: endOfWeek);
      case StatsPeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case StatsPeriod.thisQuarter:
        final quarter = ((now.month - 1) ~/ 3);
        final startMonth = quarter * 3 + 1;
        final startOfQuarter = DateTime(now.year, startMonth, 1);
        final endOfQuarter = DateTime(now.year, startMonth + 3, 0, 23, 59, 59);
        return DateTimeRange(start: startOfQuarter, end: endOfQuarter);
      case StatsPeriod.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: startOfYear, end: endOfYear);
      case StatsPeriod.allTime:
        // Un rango muy amplio para "todo el tiempo"
        return DateTimeRange(
          start: DateTime(2000, 1, 1),
          end: today.add(const Duration(days: 1)),
        );
    }
  }

  /// Obtiene una descripción corta del rango de fechas
  String getDateRangeDescription() {
    final range = getDateRange();
    final now = DateTime.now();

    switch (this) {
      case StatsPeriod.today:
        return _formatDate(range.start);
      case StatsPeriod.thisWeek:
        return '${_formatShortDate(range.start)} - ${_formatShortDate(range.end)}';
      case StatsPeriod.thisMonth:
        return _getMonthName(now.month);
      case StatsPeriod.thisQuarter:
        final quarter = ((now.month - 1) ~/ 3) + 1;
        return 'Q$quarter ${now.year}';
      case StatsPeriod.thisYear:
        return '${now.year}';
      case StatsPeriod.allTime:
        return 'Histórico';
    }
  }

  static String _formatDate(DateTime date) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  static String _getMonthName(int month) {
    final months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return months[month - 1];
  }

  /// Icono asociado al período
  IconData get icon {
    switch (this) {
      case StatsPeriod.today:
        return Icons.today;
      case StatsPeriod.thisWeek:
        return Icons.view_week;
      case StatsPeriod.thisMonth:
        return Icons.calendar_month;
      case StatsPeriod.thisQuarter:
        return Icons.date_range;
      case StatsPeriod.thisYear:
        return Icons.calendar_today;
      case StatsPeriod.allTime:
        return Icons.all_inclusive;
    }
  }
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
