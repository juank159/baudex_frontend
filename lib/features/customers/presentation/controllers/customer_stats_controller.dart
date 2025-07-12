// lib/features/customers/presentation/controllers/customer_stats_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/customer_stats.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/get_customer_stats_usecase.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerStatsController extends GetxController {
  // Dependencies
  final GetCustomerStatsUseCase _getCustomerStatsUseCase;
  final CustomerRepository _customerRepository;

  CustomerStatsController({
    required GetCustomerStatsUseCase getCustomerStatsUseCase,
    required CustomerRepository customerRepository,
  }) : _getCustomerStatsUseCase = getCustomerStatsUseCase,
       _customerRepository = customerRepository;

  // ==================== OBSERVABLES ====================

  // Estados de carga
  final _isLoading = false.obs;
  final _isRefreshing = false.obs;

  // Datos principales
  final Rxn<CustomerStats> _stats = Rxn<CustomerStats>();
  final _documentTypeStats = <String, int>{}.obs;
  final _topCustomers = <Map<String, dynamic>>[].obs;

  // Período de tiempo
  final _currentPeriod = 'month'.obs;
  final _newCustomersThisPeriod = 0.obs;
  final _activeCustomersThisPeriod = 0.obs;

  // Control de inicialización
  bool _isInitialized = false;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isRefreshing => _isRefreshing.value;
  CustomerStats? get stats => _stats.value;
  Map<String, int> get documentTypeStats => _documentTypeStats;
  List<Map<String, dynamic>> get topCustomers => _topCustomers;
  String get currentPeriod => _currentPeriod.value;
  int get newCustomersThisPeriod => _newCustomersThisPeriod.value;
  int get activeCustomersThisPeriod => _activeCustomersThisPeriod.value;

  // Períodos disponibles
  List<Map<String, String>> get availablePeriods => [
    {'value': 'today', 'label': 'Hoy'},
    {'value': 'week', 'label': 'Esta Semana'},
    {'value': 'month', 'label': 'Este Mes'},
    {'value': 'quarter', 'label': 'Este Trimestre'},
    {'value': 'year', 'label': 'Este Año'},
    {'value': 'all', 'label': 'Todo el Tiempo'},
  ];

  // Label del período actual
  String get currentPeriodLabel {
    final period = availablePeriods.firstWhere(
      (p) => p['value'] == _currentPeriod.value,
      orElse: () => {'value': 'month', 'label': 'Este Mes'},
    );
    return period['label']!;
  }

  // Días en el período actual
  int get daysInCurrentPeriod {
    switch (_currentPeriod.value) {
      case 'today':
        return 1;
      case 'week':
        return 7;
      case 'month':
        return 30;
      case 'quarter':
        return 90;
      case 'year':
        return 365;
      default:
        return 30;
    }
  }

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  // ==================== INITIALIZATION ====================

  /// Inicializar datos de forma optimizada
  Future<void> _initializeData() async {
    if (_isInitialized) {
      print('⚠️ CustomerStatsController ya inicializado, omitiendo...');
      return;
    }

    try {
      print('🚀 Inicializando CustomerStatsController...');

      await loadAllStats();

      _isInitialized = true;
      print('✅ CustomerStatsController inicializado correctamente');
    } catch (e) {
      print('❌ Error al inicializar CustomerStatsController: $e');
    }
  }

  // ==================== PUBLIC METHODS ====================

  /// Cargar todas las estadísticas
  Future<void> loadAllStats() async {
    _isLoading.value = true;

    try {
      // Cargar estadísticas principales
      await loadMainStats();

      // Cargar estadísticas por tipo de documento
      await loadDocumentTypeStats();

      // Cargar top clientes
      await loadTopCustomers();

      // Cargar estadísticas del período actual
      await loadPeriodStats();
    } catch (e) {
      print('❌ Error al cargar estadísticas: $e');
      _showError('Error', 'No se pudieron cargar las estadísticas');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cargar estadísticas principales
  Future<void> loadMainStats() async {
    try {
      print('📊 Cargando estadísticas principales...');

      final result = await _getCustomerStatsUseCase(const NoParams());

      result.fold(
        (failure) {
          print(
            '⚠️ Error al cargar estadísticas principales: ${failure.message}',
          );
          _showError('Error', failure.message);
        },
        (stats) {
          _stats.value = stats;
          print('✅ Estadísticas principales cargadas: ${stats.total} clientes');
        },
      );
    } catch (e) {
      print('❌ Error inesperado al cargar estadísticas principales: $e');
    }
  }

  /// Cargar estadísticas por tipo de documento
  // Future<void> loadDocumentTypeStats() async {
  //   try {
  //     print('📋 Cargando estadísticas por tipo de documento...');

  //     // Obtenemos todos los clientes y calculamos las estadísticas localmente
  //     final result = await _customerRepository.getCustomers(limit: 1000);

  //     result.fold(
  //       (failure) {
  //         print('⚠️ Error al cargar clientes para stats: ${failure.message}');
  //       },
  //       (paginatedResult) {
  //         final customers = paginatedResult.data;
  //         final documentStats = <String, int>{};

  //         // Contar por tipo de documento
  //         for (final customer in customers) {
  //           final docType = customer.documentType.name;
  //           documentStats[docType] = (documentStats[docType] ?? 0) + 1;
  //         }

  //         _documentTypeStats.value = documentStats;
  //         print(
  //           '✅ Estadísticas por documento cargadas: ${documentStats.length} tipos',
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     print('❌ Error inesperado al cargar stats por documento: $e');
  //   }
  // }

  Future<void> loadDocumentTypeStats() async {
    try {
      print('📋 Cargando estadísticas por tipo de documento...');

      // ✅ FIX: Cargar todos los clientes usando paginación
      List<Customer> allCustomers = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final result = await _customerRepository.getCustomers(
          page: page,
          limit: 100, // ✅ Respetar el límite máximo del backend
        );

        final success = result.fold(
          (failure) {
            print(
              '⚠️ Error al cargar clientes página $page: ${failure.message}',
            );
            return false;
          },
          (paginatedResult) {
            allCustomers.addAll(paginatedResult.data);
            hasMore = paginatedResult.meta.hasNextPage;
            page++;
            return true;
          },
        );

        if (!success) break;
      }

      if (allCustomers.isNotEmpty) {
        final documentStats = <String, int>{};

        // Contar por tipo de documento
        for (final customer in allCustomers) {
          final docType = customer.documentType.name;
          documentStats[docType] = (documentStats[docType] ?? 0) + 1;
        }

        _documentTypeStats.value = documentStats;
        print(
          '✅ Estadísticas por documento cargadas: ${documentStats.length} tipos, ${allCustomers.length} clientes',
        );
      }
    } catch (e) {
      print('❌ Error inesperado al cargar stats por documento: $e');
    }
  }

  /// Cargar top clientes
  Future<void> loadTopCustomers() async {
    try {
      print('🌟 Cargando top clientes...');

      final result = await _customerRepository.getTopCustomers(limit: 10);

      result.fold(
        (failure) {
          print('⚠️ Error al cargar top clientes: ${failure.message}');
        },
        (customers) {
          _topCustomers.value =
              customers
                  .map(
                    (customer) => {
                      'id': customer.id,
                      'name': customer.displayName,
                      'email': customer.email,
                      'totalPurchases':
                          customer.totalPurchases, // Este es el campo correcto
                      'totalOrders': customer.totalOrders,
                      'creditLimit': customer.creditLimit,
                      'currentBalance': customer.currentBalance,
                    },
                  )
                  .toList();
          print('✅ Top clientes cargados: ${customers.length} clientes');
        },
      );
    } catch (e) {
      print('❌ Error inesperado al cargar top clientes: $e');
    }
  }

  /// Cargar estadísticas del período actual
  // Future<void> loadPeriodStats() async {
  //   try {
  //     print('📅 Cargando estadísticas del período: ${_currentPeriod.value}...');

  //     // Como no tenemos el método específico, calculamos las estadísticas localmente
  //     final result = await _customerRepository.getCustomers(limit: 1000);

  //     result.fold(
  //       (failure) {
  //         print('⚠️ Error al cargar clientes para período: ${failure.message}');
  //         _newCustomersThisPeriod.value = 0;
  //         _activeCustomersThisPeriod.value = 0;
  //       },
  //       (paginatedResult) {
  //         final customers = paginatedResult.data;
  //         final now = DateTime.now();
  //         final periodStart = _getPeriodStartDate(now, _currentPeriod.value);

  //         // Contar nuevos clientes en el período
  //         final newCustomers =
  //             customers.where((customer) {
  //               return customer.createdAt.isAfter(periodStart);
  //             }).length;

  //         // Contar clientes activos en el período (que hicieron compras)
  //         final activeCustomers =
  //             customers.where((customer) {
  //               return customer.status == CustomerStatus.active &&
  //                   (customer.lastPurchaseAt?.isAfter(periodStart) ?? false);
  //             }).length;

  //         _newCustomersThisPeriod.value = newCustomers;
  //         _activeCustomersThisPeriod.value = activeCustomers;
  //         print(
  //           '✅ Estadísticas del período cargadas: $newCustomers nuevos, $activeCustomers activos',
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     print('❌ Error inesperado al cargar stats del período: $e');
  //     // Valores por defecto si falla
  //     _newCustomersThisPeriod.value = 0;
  //     _activeCustomersThisPeriod.value = _stats.value?.active ?? 0;
  //   }
  // }

  Future<void> loadPeriodStats() async {
    try {
      print('📅 Cargando estadísticas del período: ${_currentPeriod.value}...');

      // ✅ FIX: Cargar todos los clientes usando paginación
      List<Customer> allCustomers = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final result = await _customerRepository.getCustomers(
          page: page,
          limit: 100, // ✅ Respetar el límite máximo del backend
        );

        final success = result.fold(
          (failure) {
            print(
              '⚠️ Error al cargar clientes página $page: ${failure.message}',
            );
            return false;
          },
          (paginatedResult) {
            allCustomers.addAll(paginatedResult.data);
            hasMore = paginatedResult.meta.hasNextPage;
            page++;
            return true;
          },
        );

        if (!success) break;
      }

      if (allCustomers.isNotEmpty) {
        final now = DateTime.now();
        final periodStart = _getPeriodStartDate(now, _currentPeriod.value);

        // Contar nuevos clientes en el período
        final newCustomers =
            allCustomers.where((customer) {
              return customer.createdAt.isAfter(periodStart);
            }).length;

        // Contar clientes activos en el período (que hicieron compras)
        final activeCustomers =
            allCustomers.where((customer) {
              return customer.status == CustomerStatus.active &&
                  (customer.lastPurchaseAt?.isAfter(periodStart) ?? false);
            }).length;

        _newCustomersThisPeriod.value = newCustomers;
        _activeCustomersThisPeriod.value = activeCustomers;
        print(
          '✅ Estadísticas del período cargadas: $newCustomers nuevos, $activeCustomers activos de ${allCustomers.length} total',
        );
      } else {
        // Si no se pueden cargar clientes, usar valores por defecto
        _newCustomersThisPeriod.value = 0;
        _activeCustomersThisPeriod.value = _stats.value?.active ?? 0;
      }
    } catch (e) {
      print('❌ Error inesperado al cargar stats del período: $e');
      // Valores por defecto si falla
      _newCustomersThisPeriod.value = 0;
      _activeCustomersThisPeriod.value = _stats.value?.active ?? 0;
    }
  }

  /// Refrescar todas las estadísticas
  Future<void> refreshStats() async {
    if (_isRefreshing.value) {
      print('⚠️ Ya hay un refresco en progreso, ignorando...');
      return;
    }

    print('🔄 Refrescando estadísticas...');
    _isRefreshing.value = true;

    try {
      await loadAllStats();
      _showSuccess('Estadísticas actualizadas');
      print('✅ Refresco de estadísticas completado');
    } catch (e) {
      print('❌ Error durante el refresco de estadísticas: $e');
      _showError('Error', 'No se pudieron actualizar las estadísticas');
    } finally {
      _isRefreshing.value = false;
    }
  }

  /// Cambiar período de tiempo
  Future<void> changePeriod(String newPeriod) async {
    if (_currentPeriod.value == newPeriod) return;

    print('📅 Cambiando período de $currentPeriod a $newPeriod...');
    _currentPeriod.value = newPeriod;

    // Recargar estadísticas del nuevo período
    await loadPeriodStats();
  }

  // ==================== EXPORT METHODS ====================

  /// Exportar estadísticas a CSV
  Future<void> exportToCsv() async {
    try {
      print('📄 Exportando estadísticas a CSV...');

      // TODO: Implementar exportación real
      await Future.delayed(const Duration(seconds: 1));

      _showSuccess('Estadísticas exportadas a CSV');
    } catch (e) {
      print('❌ Error al exportar a CSV: $e');
      _showError('Error', 'No se pudo exportar a CSV');
    }
  }

  /// Exportar estadísticas a PDF
  Future<void> exportToPdf() async {
    try {
      print('📑 Exportando estadísticas a PDF...');

      // TODO: Implementar exportación real
      await Future.delayed(const Duration(seconds: 1));

      _showSuccess('Estadísticas exportadas a PDF');
    } catch (e) {
      print('❌ Error al exportar a PDF: $e');
      _showError('Error', 'No se pudo exportar a PDF');
    }
  }

  /// Compartir estadísticas
  Future<void> shareStats() async {
    try {
      print('📤 Compartiendo estadísticas...');

      // TODO: Implementar función de compartir real
      await Future.delayed(const Duration(seconds: 1));

      _showSuccess('Estadísticas compartidas');
    } catch (e) {
      print('❌ Error al compartir estadísticas: $e');
      _showError('Error', 'No se pudieron compartir las estadísticas');
    }
  }

  /// Imprimir estadísticas
  Future<void> printStats() async {
    try {
      print('🖨️ Preparando estadísticas para imprimir...');

      // TODO: Implementar función de impresión real
      await Future.delayed(const Duration(seconds: 1));

      _showSuccess('Estadísticas enviadas a impresora');
    } catch (e) {
      print('❌ Error al imprimir estadísticas: $e');
      _showError('Error', 'No se pudieron imprimir las estadísticas');
    }
  }

  // ==================== FILTER METHODS ====================

  /// Filtrar top clientes por criterio
  void filterTopCustomers(String criteria) {
    // TODO: Implementar filtros adicionales
    switch (criteria) {
      case 'purchases':
        _topCustomers.sort(
          (a, b) => (b['totalPurchases'] as double).compareTo(
            a['totalPurchases'] as double,
          ),
        );
        break;
      case 'orders':
        _topCustomers.sort(
          (a, b) =>
              (b['totalOrders'] as int).compareTo(a['totalOrders'] as int),
        );
        break;
      case 'credit':
        _topCustomers.sort(
          (a, b) => (b['creditLimit'] as double).compareTo(
            a['creditLimit'] as double,
          ),
        );
        break;
      default:
        loadTopCustomers();
    }
  }

  // ==================== NAVIGATION METHODS ====================

  /// Navegar a lista de clientes
  void goToCustomersList() {
    Get.toNamed('/customers');
  }

  /// Navegar a crear cliente
  void goToCreateCustomer() {
    Get.toNamed('/customers/create');
  }

  /// Navegar a detalles de cliente
  void goToCustomerDetail(String customerId) {
    Get.toNamed('/customers/detail/$customerId');
  }

  // ==================== HELPER METHODS ====================

  /// Obtener fecha de inicio del período
  DateTime _getPeriodStartDate(DateTime now, String period) {
    switch (period) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'month':
        return DateTime(now.year, now.month, 1);
      case 'quarter':
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, quarterMonth, 1);
      case 'year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  Color getChartColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  /// Formatear moneda
  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  /// Formatear porcentaje
  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Obtener estadísticas resumidas como texto
  String getStatsSummary() {
    if (_stats.value == null) return 'No hay datos disponibles';

    final stats = _stats.value!;
    return '''
Resumen de Estadísticas - ${currentPeriodLabel}

Total de Clientes: ${stats.total}
• Activos: ${stats.active} (${formatPercentage(stats.activePercentage)})
• Inactivos: ${stats.inactive}
• Suspendidos: ${stats.suspended}

Información Financiera:
• Límite de Crédito Total: ${formatCurrency(stats.totalCreditLimit)}
• Balance Pendiente: ${formatCurrency(stats.totalBalance)}
• Promedio de Compra: ${formatCurrency(stats.averagePurchaseAmount)}

Actividad del Período:
• Nuevos Clientes: $newCustomersThisPeriod
• Clientes Activos: $activeCustomersThisPeriod
''';
  }

  /// Validar si hay datos suficientes para mostrar
  bool get hasEnoughDataForCharts =>
      _stats.value != null && _stats.value!.total > 0;

  /// Obtener tendencia (mock)
  String getTrend(String metric) {
    // TODO: Implementar cálculo real de tendencias
    final trends = ['↗️ +5%', '↘️ -2%', '→ 0%', '↗️ +12%'];
    return trends[metric.hashCode % trends.length];
  }

  // ==================== UI HELPERS ====================

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

  /// Mostrar información
  void _showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
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
      'hasStats': _stats.value != null,
      'totalCustomers': _stats.value?.total ?? 0,
      'currentPeriod': _currentPeriod.value,
      'documentTypesCount': _documentTypeStats.length,
      'topCustomersCount': _topCustomers.length,
      'newCustomersThisPeriod': _newCustomersThisPeriod.value,
      'activeCustomersThisPeriod': _activeCustomersThisPeriod.value,
    };
  }

  /// Imprimir información de debugging
  void printDebugInfo() {
    final info = getDebugInfo();
    print('🐛 CustomerStatsController Debug Info:');
    info.forEach((key, value) {
      print('   $key: $value');
    });
  }
}
