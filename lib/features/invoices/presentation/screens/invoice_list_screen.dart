// lib/features/invoices/presentation/screens/invoice_list_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/invoice_list_controller.dart';
import '../bindings/invoice_binding.dart';
import '../widgets/invoice_card_widget.dart';
import '../widgets/invoice_filter_widget.dart';
import '../widgets/invoice_stats_widget.dart';
import '../../domain/entities/invoice.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ SOLUCIÓN: Registro más robusto del controlador
    return _buildScreenWithController(context);
  }

  /// ✅ NUEVO: Método para manejar el registro del controlador de forma robusta
  Widget _buildScreenWithController(BuildContext context) {
    return FutureBuilder<InvoiceListController>(
      future: _ensureControllerRegistration(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error al inicializar',
                    style: TextStyle(fontSize: 18, color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
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

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('No se pudo inicializar el controlador')),
          );
        }

        final controller = snapshot.data!;
        return _buildMainScreen(context, controller);
      },
    );
  }

  /// ✅ NUEVO: Asegurar que el controlador esté registrado
  Future<InvoiceListController> _ensureControllerRegistration() async {
    try {
      // Paso 1: Verificar si ya está registrado
      if (Get.isRegistered<InvoiceListController>()) {
        print('✅ InvoiceListController ya está registrado');
        return Get.find<InvoiceListController>();
      }

      // Paso 2: Verificar dependencias base
      if (!InvoiceBinding.areBaseDependenciesRegistered()) {
        print('❌ Dependencias base no están registradas, inicializando...');
        // Inicializar binding completo si las dependencias no están
        InvoiceBinding().dependencies();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Paso 3: Registrar el controlador específico
      print('🔧 Registrando InvoiceListController...');
      InvoiceBinding.registerListController();

      // Paso 4: Verificar que se registró correctamente
      if (!Get.isRegistered<InvoiceListController>()) {
        throw Exception(
          'No se pudo registrar InvoiceListController después del intento',
        );
      }

      // Paso 5: Debug información
      InvoiceBinding.debugControllerRegistration();

      return Get.find<InvoiceListController>();
    } catch (e) {
      print('❌ Error en _ensureControllerRegistration: $e');
      rethrow;
    }
  }

  /// Widget principal de la pantalla
  Widget _buildMainScreen(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Scaffold(
      appBar: _buildAppBar(context, controller),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context, controller),
        tablet: _buildTabletLayout(context, controller),
        desktop: _buildDesktopLayout(context, controller),
      ),
      floatingActionButton: _buildFloatingActionButton(context, controller),
      bottomNavigationBar: _buildBottomBar(context, controller),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return AppBar(
      title: const Text('Facturas'),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Navega directamente al dashboard y elimina el historial
          Get.offAllNamed(AppRoutes.dashboard);
        },
      ),
      actions: [
        // Buscar
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(context, controller),
          tooltip: 'Buscar',
        ),

        // Filtros
        GetBuilder<InvoiceListController>(
          builder:
              (controller) => Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed:
                        () => _showFiltersBottomSheet(context, controller),
                    tooltip: 'Filtros',
                  ),
                  if (controller.hasFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
        ),

        // Modo selección múltiple
        GetBuilder<InvoiceListController>(
          builder:
              (controller) => IconButton(
                icon: Icon(
                  controller.isMultiSelectMode ? Icons.close : Icons.checklist,
                ),
                onPressed: controller.toggleMultiSelectMode,
                tooltip:
                    controller.isMultiSelectMode
                        ? 'Salir de selección'
                        : 'Selección múltiple',
              ),
        ),

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => controller.refreshAllData(),
          tooltip: 'Refrescar',
        ),

        // Menú de opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context, controller),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Exportar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.analytics),
                      SizedBox(width: 8),
                      Text('Estadísticas'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Configuración'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildMobileLayout(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Column(
      children: [
        // Estadísticas compactas
        _buildCompactStats(context, controller),

        // Barra de búsqueda
        _buildSearchBar(context, controller),

        // Lista de facturas
        Expanded(child: _buildInvoiceList(context, controller)),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Row(
      children: [
        // Lista principal
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildSearchBar(context, controller),
              Expanded(child: _buildInvoiceList(context, controller)),
            ],
          ),
        ),

        // Panel lateral
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              // Estadísticas
              _buildSidebarStats(context, controller),

              // Filtros rápidos
              _buildQuickFilters(context, controller),

              // Acciones rápidas
              _buildQuickActions(context, controller),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Row(
      children: [
        // Barra lateral izquierda
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              _buildSidebarStats(context, controller),
              _buildQuickFilters(context, controller),
              _buildQuickActions(context, controller),
            ],
          ),
        ),

        // Contenido principal
        Expanded(
          child: Column(
            children: [
              // Toolbar
              _buildDesktopToolbar(context, controller),

              // Lista con grid/tabla opcional
              Expanded(child: _buildInvoiceList(context, controller)),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== COMPONENTS ====================

  Widget _buildCompactStats(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return GetBuilder<InvoiceListController>(
      builder: (controller) {
        // Calcular estadísticas financieras
        final totalInvoices = controller.filteredInvoices.length;
        final pendingInvoices = controller.filteredInvoices
            .where((i) => i.status == InvoiceStatus.pending)
            .length;
        final overdueInvoices = controller.filteredInvoices
            .where((i) => i.isOverdue)
            .length;
        
        // Calcular totales monetarios
        final totalAmount = controller.filteredInvoices
            .fold<double>(0.0, (sum, invoice) => sum + invoice.total);
        final pendingAmount = controller.filteredInvoices
            .where((i) => i.status == InvoiceStatus.pending)
            .fold<double>(0.0, (sum, invoice) => sum + invoice.total);
        final overdueAmount = controller.filteredInvoices
            .where((i) => i.isOverdue)
            .fold<double>(0.0, (sum, invoice) => sum + invoice.total);

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Primera fila - Contadores
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      totalInvoices.toString(),
                      Icons.receipt,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Pendientes',
                      pendingInvoices.toString(),
                      Icons.schedule,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Vencidas',
                      overdueInvoices.toString(),
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              
              // Segunda fila - Montos (solo si hay facturas)
              if (totalInvoices > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMoneyStatCard(
                        'Valor Total',
                        totalAmount,
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMoneyStatCard(
                        'Pendiente',
                        pendingAmount,
                        Icons.hourglass_bottom,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMoneyStatCard(
                        'Vencido',
                        overdueAmount,
                        Icons.warning_amber,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyStatCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CustomTextField(
        controller: controller.searchController,
        label: 'Buscar facturas...',
        hint: 'Número, cliente, monto...',
        prefixIcon: Icons.search,
        suffixIcon: controller.searchQuery.isNotEmpty ? Icons.clear : null,
        onSuffixIconPressed:
            controller.searchQuery.isNotEmpty
                ? () => controller.searchController.clear()
                : null,
      ),
    );
  }

  // Widget _buildInvoiceList(
  //   BuildContext context,
  //   InvoiceListController controller,
  // ) {
  //   return GetBuilder<InvoiceListController>(
  //     builder: (controller) {
  //       if (controller.isLoading) {
  //         return const LoadingWidget(message: 'Cargando facturas...');
  //       }

  //       if (controller.filteredInvoices.isEmpty) {
  //         return _buildEmptyState(context, controller);
  //       }

  //       return RefreshIndicator(
  //         onRefresh: controller.refreshInvoices,
  //         child: ListView.builder(
  //           controller: controller.scrollController,
  //           padding: const EdgeInsets.all(16),
  //           itemCount:
  //               controller.filteredInvoices.length +
  //               (controller.isLoadingMore ? 1 : 0),
  //           itemBuilder: (context, index) {
  //             // Loading indicator para paginación
  //             if (index >= controller.filteredInvoices.length) {
  //               return const Padding(
  //                 padding: EdgeInsets.all(16),
  //                 child: Center(child: CircularProgressIndicator()),
  //               );
  //             }

  //             final invoice = controller.filteredInvoices[index];
  //             return InvoiceCardWidget(
  //               invoice: invoice,
  //               isSelected: controller.selectedInvoices.contains(invoice.id),
  //               isMultiSelectMode: controller.isMultiSelectMode,
  //               onTap: () => _handleInvoiceTap(invoice, controller),
  //               onLongPress: () => _handleInvoiceLongPress(invoice, controller),
  //               onActionTap:
  //                   (action) =>
  //                       _handleInvoiceAction(action, invoice, controller),
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildInvoiceList(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return GetBuilder<InvoiceListController>(
      builder: (controller) {
        print('🔍 UI DEBUG: _buildInvoiceList ejecutándose');
        print('🔍 UI DEBUG: isLoading: ${controller.isLoading}');
        print(
          '🔍 UI DEBUG: filteredInvoices.length: ${controller.filteredInvoices.length}',
        );

        if (controller.isLoading) {
          print('🔍 UI DEBUG: Mostrando loading...');
          return const LoadingWidget(message: 'Cargando facturas...');
        }

        if (controller.filteredInvoices.isEmpty) {
          print('🔍 UI DEBUG: Mostrando empty state...');
          return _buildEmptyState(context, controller);
        }

        print('🔍 UI DEBUG: Mostrando lista de facturas...');
        return RefreshIndicator(
          onRefresh: controller.refreshAllData,
          child: ListView.builder(
            controller: controller.scrollController,
            padding: const EdgeInsets.all(16),
            itemCount:
                controller.filteredInvoices.length +
                (controller.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading indicator para paginación
              if (index >= controller.filteredInvoices.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final invoice = controller.filteredInvoices[index];
              print(
                '🔍 UI DEBUG: Renderizando factura ${index}: ${invoice.number}',
              );
              return InvoiceCardWidget(
                invoice: invoice,
                isSelected: controller.selectedInvoices.contains(invoice.id),
                isMultiSelectMode: controller.isMultiSelectMode,
                onTap: () => _handleInvoiceTap(invoice, controller),
                onLongPress: () => _handleInvoiceLongPress(invoice, controller),
                onActionTap:
                    (action) =>
                        _handleInvoiceAction(action, invoice, controller),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.isNotEmpty || controller.hasFilters
                ? 'No se encontraron facturas'
                : 'No hay facturas aún',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.searchQuery.isNotEmpty || controller.hasFilters
                ? 'Intenta cambiar los filtros de búsqueda'
                : 'Crea tu primera factura para comenzar',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          if (controller.searchQuery.isNotEmpty || controller.hasFilters)
            CustomButton(
              text: 'Limpiar Filtros',
              type: ButtonType.outline,
              onPressed: controller.clearFilters,
            )
          else
            CustomButton(
              text: 'Crear Primera Factura',
              icon: Icons.add,
              onPressed: controller.goToCreateInvoice,
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarStats(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const InvoiceStatsWidget(),
    );
  }

  Widget _buildQuickFilters(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros Rápidos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          // Filtros por estado
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                InvoiceStatus.values.map((status) {
                  final isSelected = controller.selectedStatus == status;
                  return FilterChip(
                    label: Text(status.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      controller.filterByStatus(selected ? status : null);
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),

          CustomButton(
            text: 'Nueva Factura',
            icon: Icons.add,
            onPressed: controller.goToCreateInvoice,
            width: double.infinity,
          ),
          const SizedBox(height: 8),

          CustomButton(
            text: 'Ver Vencidas',
            icon: Icons.warning,
            type: ButtonType.outline,
            onPressed: () => controller.filterByStatus(InvoiceStatus.overdue),
            width: double.infinity,
          ),
          const SizedBox(height: 8),

          CustomButton(
            text: 'Estadísticas',
            icon: Icons.analytics,
            type: ButtonType.outline,
            onPressed: () => Get.toNamed('/invoices/stats'),
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopToolbar(
    BuildContext context,
    InvoiceListController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Barra de búsqueda expandida
          Expanded(
            child: CustomTextField(
              controller: controller.searchController,
              label: 'Buscar facturas...',
              hint: 'Número, cliente, monto...',
              prefixIcon: Icons.search,
            ),
          ),
          const SizedBox(width: 16),

          // Botones de acción
          CustomButton(
            text: 'Filtros',
            icon: Icons.filter_list,
            type: ButtonType.outline,
            onPressed: () => _showFiltersBottomSheet(context, controller),
          ),
          const SizedBox(width: 8),

          CustomButton(
            text: 'Nueva Factura',
            icon: Icons.add,
            onPressed: controller.goToCreateInvoice,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    InvoiceListController controller,
  ) {
    if (!context.isMobile) return const SizedBox.shrink();

    return GetBuilder<InvoiceListController>(
      builder: (controller) {
        if (controller.isMultiSelectMode && controller.hasSelection) {
          return FloatingActionButton.extended(
            onPressed: () => _showBulkActionsDialog(context, controller),
            icon: const Icon(Icons.more_horiz),
            label: Text('${controller.selectedInvoices.length} seleccionadas'),
          );
        }

        return FloatingActionButton(
          onPressed: controller.goToCreateInvoice,
          child: const Icon(Icons.add),
        );
      },
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    InvoiceListController controller,
  ) {
    if (!context.isMobile) return null;

    return GetBuilder<InvoiceListController>(
      builder: (controller) {
        if (!controller.isMultiSelectMode) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${controller.selectedInvoices.length} facturas seleccionadas',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (controller.hasSelection) ...[
                  TextButton(
                    onPressed: controller.clearSelection,
                    child: const Text('Limpiar'),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    text: 'Acciones',
                    onPressed:
                        () => _showBulkActionsDialog(context, controller),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== EVENT HANDLERS ====================

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

  void _handleInvoiceAction(
    String action,
    Invoice invoice,
    InvoiceListController controller,
  ) {
    switch (action) {
      case 'edit':
        controller.goToEditInvoice(invoice.id);
        break;
      case 'print':
        controller.goToPrintInvoice(invoice.id);
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

  void _handleMenuAction(
    String action,
    BuildContext context,
    InvoiceListController controller,
  ) {
    switch (action) {
      case 'export':
        _showInfo('Próximamente', 'Función de exportar en desarrollo');
        break;
      case 'stats':
        Get.toNamed('/invoices/stats');
        break;
      case 'settings':
        Get.toNamed('/settings/invoices');
        break;
    }
  }

  // ==================== DIALOGS ====================

  void _showSearchDialog(
    BuildContext context,
    InvoiceListController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Buscar Facturas'),
            content: CustomTextField(
              controller: controller.searchController,
              label: 'Término de búsqueda',
              hint: 'Número, cliente, monto...',
              prefixIcon: Icons.search,
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Buscar'),
              ),
            ],
          ),
    );
  }

  void _showFiltersBottomSheet(
    BuildContext context,
    InvoiceListController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => InvoiceFilterWidget(controller: controller),
    );
  }

  void _showBulkActionsDialog(
    BuildContext context,
    InvoiceListController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Acciones en Lote'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.print),
                  title: const Text('Imprimir Seleccionadas'),
                  onTap: () {
                    Get.back();
                    _showInfo(
                      'Próximamente',
                      'Impresión en lote en desarrollo',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Exportar Seleccionadas'),
                  onTap: () {
                    Get.back();
                    _showInfo(
                      'Próximamente',
                      'Exportación en lote en desarrollo',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Eliminar Seleccionadas'),
                  onTap: () {
                    Get.back();
                    _showBulkDeleteConfirmation(controller);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  void _showCancelConfirmation(
    Invoice invoice,
    InvoiceListController controller,
  ) {
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

  void _showDeleteConfirmation(
    Invoice invoice,
    InvoiceListController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Factura'),
        content: Text(
          '¿Eliminar la factura ${invoice.number}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
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

  void _showBulkDeleteConfirmation(InvoiceListController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Facturas'),
        content: Text(
          '¿Eliminar ${controller.selectedInvoices.length} facturas seleccionadas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // TODO: Implementar eliminación en lote
              _showInfo('Próximamente', 'Eliminación en lote en desarrollo');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

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
}
