// ✅ VERSIÓN CORREGIDA CON APPBAR Y BÚSQUEDA PROFESIONAL
// lib/features/invoices/presentation/screens/invoice_list_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/shared/widgets/safe_text_editing_controller.dart';
import '../../../../app/shared/widgets/custom_text_field_safe.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../controllers/invoice_list_controller.dart';
import '../controllers/invoice_stats_controller.dart';
import '../bindings/invoice_binding.dart';
import '../widgets/invoice_card_widget.dart';
import '../widgets/invoice_filter_widget.dart';
import '../widgets/invoice_stats_widget.dart';
import '../../domain/entities/invoice.dart';

class InvoiceListScreen extends GetView<InvoiceListController> {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InvoiceListController>(
      future: _ensureControllerRegistration(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error.toString());
        }

        final controller = snapshot.data;
        if (controller == null) {
          return _buildErrorScreen('No se pudo inicializar el controlador');
        }
        
        return _buildMainScreen(context, controller);
      },
    );
  }

  /// Registro seguro del controlador
  Future<InvoiceListController> _ensureControllerRegistration() async {
    try {
      // Verificar si ya existe
      if (Get.isRegistered<InvoiceListController>()) {
        return Get.find<InvoiceListController>();
      }

      // Registrar dependencias
      final binding = InvoiceBinding();
      binding.dependencies();
      await Future.delayed(const Duration(milliseconds: 100));

      return Get.find<InvoiceListController>();
    } catch (e) {
      print('❌ Error registrando controlador: $e');
      rethrow;
    }
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error al cargar facturas', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  /// Pantalla principal con layout responsive
  Widget _buildMainScreen(BuildContext context, InvoiceListController controller) {
    return Scaffold(
      appBar: _buildAppBar(context, controller),
      drawer: const AppDrawer(currentRoute: '/invoices'),
      backgroundColor: Colors.grey.shade50,
      body: ResponsiveHelper.responsive(
        context,
        mobile: _buildMobileLayout(context, controller),
        tablet: _buildTabletLayout(context, controller),
        desktop: _buildFixedDesktopLayout(context, controller),
      ),
      floatingActionButton: _buildFloatingActionButton(context, controller),
    );
  }

  // ✅ APPBAR RESTAURADO
  PreferredSizeWidget _buildAppBar(BuildContext context, InvoiceListController controller) {
    return AppBar(
      title: const Text('Gestión de Facturas'),
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      actions: [
        // Búsqueda rápida en móvil
        if (ResponsiveHelper.isMobile(context))
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showMobileSearch(context, controller),
          ),

        // Refresh profesional
        Obx(() => IconButton(
          icon: controller.isLoading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh),
          onPressed: controller.isLoading ? null : () async {
            await controller.refreshAllData();
            _showRefreshSuccess();
          },
          tooltip: controller.isLoading ? 'Actualizando...' : 'Actualizar facturas',
        )),

        // Filtros
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilters(context, controller),
        ),

        // Facturas vencidas con indicador
        Obx(() {
          final overdueCount = controller.filteredInvoices.where((i) => i.isOverdue).length;

          return IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: overdueCount > 0 ? Colors.orange : Colors.white,
                ),
                if (overdueCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$overdueCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              if (overdueCount > 0) {
                controller.filterByStatus(InvoiceStatus.overdue);
              } else {
                Get.snackbar(
                  'Sin alertas',
                  'No hay facturas vencidas',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green.shade100,
                  colorText: Colors.green.shade800,
                );
              }
            },
            tooltip:
                overdueCount > 0
                    ? 'Ver $overdueCount facturas vencidas'
                    : 'Sin facturas vencidas',
          );
        }),

        const SizedBox(width: 8),
      ],
    );
  }

  // ✅ FLOATING ACTION BUTTON - Solo para móvil y tablet
  Widget _buildFloatingActionButton(BuildContext context, InvoiceListController controller) {
    // Solo mostrar FAB en dispositivos móviles y tablet
    if (ResponsiveHelper.isDesktop(context)) {
      return const SizedBox.shrink(); // No mostrar en desktop
    }

    // En móvil usar FAB normal, en tablet usar extended
    if (ResponsiveHelper.isMobile(context)) {
      return FloatingActionButton(
        onPressed: () => controller.goToCreateInvoice(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      );
    }

    // En tablet usar extended con label
    return FloatingActionButton.extended(
      onPressed: () => controller.goToCreateInvoice(),
      icon: const Icon(Icons.add),
      label: const Text('Nueva factura'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
    );
  }

  // ✅ NUEVO LAYOUT DESKTOP CON BÚSQUEDA PROFESIONAL
  Widget _buildFixedDesktopLayout(BuildContext context, InvoiceListController controller) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando facturas...');
      }

      return Row(
        children: [
          // ✅ SIDEBAR FIJO SIN OVERFLOW
          Container(
            width: 300,
            height: MediaQuery.of(context).size.height - kToolbarHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header fijo
                _buildFixedHeader(context),

                // Búsqueda profesional con debounce
                _buildProfessionalSearch(context, controller),

                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFixedStats(context, controller),
                        const SizedBox(height: 16),
                        _buildFixedFilters(context, controller),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ CONTENIDO PRINCIPAL
          Expanded(
            child: Column(
              children: [
                // Toolbar superior
                _buildFixedToolbar(context, controller),

                // Lista de facturas
                Expanded(child: _buildInvoicesList(controller)),
              ],
            ),
          ),
        ],
      );
    });
  }

  /// Layout móvil simplificado
  Widget _buildMobileLayout(BuildContext context, InvoiceListController controller) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: ProfessionalSearchField(
            controller: controller.searchController,
            onChanged: (value) => _performDebouncedSearch(value, controller),
            onClear: controller.clearFilters,
          ),
        ),
        Expanded(child: _buildInvoicesList(controller)),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, InvoiceListController controller) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: ProfessionalSearchField(
            controller: controller.searchController,
            onChanged: (value) => _performDebouncedSearch(value, controller),
            onClear: controller.clearFilters,
          ),
        ),
        Expanded(child: _buildInvoicesList(controller)),
      ],
    );
  }

  Widget _buildFixedHeader(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Facturas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  'Gestión y búsqueda',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ BÚSQUEDA PROFESIONAL CON DEBOUNCE
  Widget _buildProfessionalSearch(BuildContext context, InvoiceListController controller) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Búsqueda Inteligente',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ProfessionalSearchField(
              controller: controller.searchController,
              onChanged: (value) => _performDebouncedSearch(value, controller),
              onClear: controller.clearFilters,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DEBOUNCED SEARCH IMPLEMENTATION
  void _performDebouncedSearch(String query, InvoiceListController controller) {
    controller.searchInvoices(query);
  }

  Widget _buildFixedStats(BuildContext context, InvoiceListController controller) {
    return Obx(() {
      // ✅ USAR ESTADÍSTICAS REALES DEL CONTROLADOR DE STATS
      // Asegurar que el controlador esté registrado antes de buscarlo
      if (!Get.isRegistered<InvoiceStatsController>()) {
        InvoiceBinding().dependencies(); // Forzar registro de dependencias
      }
      final statsController = Get.find<InvoiceStatsController>();
      final total = statsController.totalInvoices;
      final paid = statsController.paidInvoices;
      final pending = statsController.pendingInvoices;
      final overdue = statsController.overdueCount;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats en lista vertical
            _buildStatRow(
              'Total',
              total.toString(),
              Icons.receipt_long,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Pagadas',
              paid.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Pendientes',
              pending.toString(),
              Icons.schedule,
              pending > 0 ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Vencidas',
              overdue.toString(),
              Icons.warning,
              overdue > 0 ? Colors.red : Colors.grey,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedFilters(BuildContext context, InvoiceListController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Filtros',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),

        // Filtros de estado
        _buildFilterSection('Estado', [
          _buildFilterChip(
            'Todos',
            controller.selectedStatus == null,
            () => controller.filterByStatus(null),
            Colors.grey,
          ),
          _buildFilterChip(
            'Pagadas',
            controller.selectedStatus == InvoiceStatus.paid,
            () => controller.filterByStatus(InvoiceStatus.paid),
            Colors.green,
          ),
          _buildFilterChip(
            'Pendientes',
            controller.selectedStatus == InvoiceStatus.pending,
            () => controller.filterByStatus(InvoiceStatus.pending),
            Colors.orange,
          ),
          _buildFilterChip(
            'Canceladas',
            controller.selectedStatus == InvoiceStatus.cancelled,
            () => controller.filterByStatus(InvoiceStatus.cancelled),
            Colors.red,
          ),
        ]),

        const SizedBox(height: 16),

        // Botón limpiar filtros
        if (_hasActiveFilters(controller))
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Limpiar Filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterSection(String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? color : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFixedToolbar(BuildContext context, InvoiceListController controller) {
    return Container(
      height: 90, // ✅ Aumentado de 70 a 90 para evitar overflow
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Información de facturas con paginación
          Expanded(
            child: Obx(() {
              final searchMode = controller.searchQuery.isNotEmpty;
              final count = controller.filteredInvoices.length;
              final label = searchMode ? 'Resultados' : 'Facturas';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$label ($count)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // ✅ PAGINACIÓN: Mostrar información de página
                  if (controller.totalPages > 1) ...[
                    Text(
                      controller.paginationInfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (searchMode && controller.searchQuery.isNotEmpty)
                    Text(
                      'Búsqueda: "${controller.searchQuery}"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              );
            }),
          ),

          // Indicador de búsqueda activa
          Obx(() {
            if (controller.isSearching) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Buscando...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // ✅ BOTONES PROFESIONALES PARA DESKTOP
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón de acciones secundarias
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: PopupMenuButton<String>(
                  onSelected: (value) => _handleDesktopAction(value, context, controller),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 18),
                              SizedBox(width: 12),
                              Text('Exportar Lista'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'stats',
                          child: Row(
                            children: [
                              Icon(Icons.analytics, size: 18),
                              SizedBox(width: 12),
                              Text('Estadísticas'),
                            ],
                          ),
                        ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Botón principal - Nueva Factura
              Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => controller.goToCreateInvoice(),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Nueva Factura',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters(InvoiceListController controller) {
    return controller.selectedStatus != null ||
        controller.selectedPaymentMethod != null ||
        controller.startDate != null ||
        controller.endDate != null ||
        controller.minAmount != null ||
        controller.maxAmount != null ||
        controller.searchQuery.isNotEmpty;
  }

  Widget _buildInvoicesList(InvoiceListController controller) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando facturas...');
      }

      final invoiceList = controller.filteredInvoices;

      if (invoiceList.isEmpty) {
        final isSearching = controller.searchQuery.isNotEmpty;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSearching ? Icons.search_off : Icons.receipt_long,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                isSearching ? 'Sin resultados' : 'No hay facturas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearching
                    ? 'Intenta con otros términos de búsqueda'
                    : 'Crea tu primera factura',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshAllData,
        child: Column(
          children: [
            // ✅ PAGINACIÓN PROFESIONAL: Indicador de progreso de carga
            if (controller.totalPages > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Obx(() {
                  return Column(
                    children: [
                      LinearProgressIndicator(
                        value: controller.loadingProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(Get.context!).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.paginationInfo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                'Mostrando: ${invoiceList.length} facturas',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (controller.isLoadingMore)
                            Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(Get.context!).primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cargando...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(Get.context!).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Obx(() {
                return Text(
                  '🔍 DEBUG: ${invoiceList.length} facturas en lista | Página ${controller.currentPage}/${controller.totalPages}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade700,
                    fontFamily: 'monospace',
                  ),
                );
              }),
            ),
            
            Expanded(
              child: ListView.builder(
                controller: controller.mainScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: invoiceList.length,
                itemBuilder: (context, index) {
                  final invoice = invoiceList[index];
                  
                  return Column(
                    children: [
                      InvoiceCardWidget(
                        invoice: invoice,
                        isSelected: controller.selectedInvoices.contains(invoice.id),
                        isMultiSelectMode: controller.isMultiSelectMode,
                        onTap: () => _handleInvoiceTap(invoice, controller),
                        onLongPress: () => _handleInvoiceLongPress(invoice, controller),
                        onActionTap: (action) => _handleInvoiceAction(action, invoice, controller),
                      ),
                      
                      if (index == invoiceList.length - 1 && 
                          controller.hasNextPage)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Obx(() {
                            if (controller.isLoadingMore) {
                              return Column(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cargando más facturas...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                            }
                            
                            return TextButton(
                              onPressed: controller.canLoadMore ? controller.loadMoreInvoices : null,
                              child: Text(
                                controller.canLoadMore 
                                    ? 'Cargar más facturas' 
                                    : 'No hay más facturas',
                              ),
                            );
                          }),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  void _handleInvoiceTap(Invoice invoice, InvoiceListController controller) {
    if (controller.isMultiSelectMode) {
      controller.toggleInvoiceSelection(invoice.id);
    } else {
      controller.goToInvoiceDetail(invoice.id);
    }
  }

  void _handleInvoiceLongPress(
    Invoice invoice,
    InvoiceListController controller,
  ) {
    if (!controller.isMultiSelectMode) {
      controller.toggleMultiSelectMode();
    }
    controller.toggleInvoiceSelection(invoice.id);
  }

  void _handleInvoiceAction(String action, Invoice invoice, InvoiceListController controller) {
    switch (action) {
      case 'edit':
        controller.goToEditInvoice(invoice.id);
        break;
      case 'print':
        controller.printInvoice(invoice.id);
        break;
      case 'confirm':
        controller.confirmInvoice(invoice.id);
        break;
      case 'cancel':
        _showCancelConfirmation(invoice, controller);
        break;
      case 'delete':
        _showDeleteConfirmation(invoice, controller);
        break;
    }
  }

  void _showMobileSearch(BuildContext context, InvoiceListController controller) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Búsqueda de Facturas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                ProfessionalSearchField(
                  controller: controller.searchController,
                  onChanged: (value) => _performDebouncedSearch(value, controller),
                  onClear: controller.clearFilters,
                  autofocus: true,
                ),
              ],
            ),
          ),
    );
  }

  void _showFilters(BuildContext context, InvoiceListController controller) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filtros de Facturas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFixedFilters(context, controller),
              ],
            ),
          ),
    );
  }

  // ✅ MANEJA ACCIONES DEL MENÚ DESKTOP
  void _handleDesktopAction(String action, BuildContext context, InvoiceListController controller) {
    switch (action) {
      case 'export':
        _showInfoSnackbar(
          'Próximamente',
          'La función de exportar facturas estará disponible pronto',
          Icons.download,
          Colors.green,
        );
        break;
      case 'stats':
        Get.toNamed('/invoices/stats');
        break;
    }
  }

  void _showInfoSnackbar(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color.withOpacity(0.1),
      colorText: color,
      icon: Icon(icon, color: color),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showRefreshSuccess() {
    Get.snackbar(
      'Actualizado',
      'Las facturas se han actualizado correctamente',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withOpacity(0.1),
      colorText: Colors.green.shade800,
      icon: Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showFiltersBottomSheet(BuildContext context, InvoiceListController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => InvoiceFilterWidget(controller: controller),
    );
  }

  void _showCancelConfirmation(Invoice invoice, InvoiceListController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar Factura'),
        content: Text('¿Cancelar la factura ${invoice.number}?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelInvoice(invoice.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Invoice invoice, InvoiceListController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Factura'),
        content: Text('¿Eliminar la factura ${invoice.number}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteInvoice(invoice.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ✅ WIDGET DE BÚSQUEDA ULTRA-SEGURO - NUNCA CRASHEA
class ProfessionalSearchField extends StatefulWidget {
  final SafeTextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final bool autofocus;

  const ProfessionalSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.autofocus = false,
  });

  @override
  State<ProfessionalSearchField> createState() =>
      _ProfessionalSearchFieldState();
}

class _ProfessionalSearchFieldState extends State<ProfessionalSearchField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildUltraSafeTextField(),
    );
  }

  Widget _buildUltraSafeTextField() {
    try {
      return CustomTextFieldSafe(
        controller: widget.controller.isSafeToUse ? widget.controller : null,
        label: '',
        hint: 'Buscar por número, cliente o monto...',
        prefixIcon: Icons.search,
        suffixIcon: widget.controller.text.isNotEmpty ? Icons.clear : null,
        onSuffixIconPressed: widget.controller.text.isNotEmpty ? () {
          widget.controller.clear();
          widget.onChanged('');
        } : null,
        onChanged: (value) {
          if (mounted) {
            try {
              widget.onChanged(value);
            } catch (e) {
              print('⚠️ Error in search onChanged: $e');
            }
          }
        },
      );
    } catch (e) {
      print('⚠️ Error building ultra-safe TextField: $e');
      return _buildBasicFallback();
    }
  }


  Widget _buildBasicFallback() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Buscar por número, cliente o monto...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceSearchDelegate extends SearchDelegate<Invoice?> {
  final InvoiceListController controller;

  InvoiceSearchDelegate(this.controller);

  @override
  String get searchFieldLabel => 'Buscar facturas...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(child: Text('Ingresa al menos 2 caracteres para buscar'));
    }

    final results = controller.filteredInvoices.where((invoice) {
      final searchLower = query.toLowerCase();
      return invoice.number.toLowerCase().contains(searchLower) ||
          invoice.customerName.toLowerCase().contains(searchLower);
    }).toList();

    if (results.isEmpty) {
      return const Center(child: Text('No se encontraron facturas'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final invoice = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(Icons.receipt_long, color: Theme.of(context).primaryColor),
          ),
          title: Text(invoice.number),
          subtitle: Text(invoice.customerName),
          trailing: Text(
            AppFormatters.formatCurrency(invoice.total),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () {
            close(context, invoice);
            controller.goToInvoiceDetail(invoice.id);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}