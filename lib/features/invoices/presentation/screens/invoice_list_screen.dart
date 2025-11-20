// lib/features/invoices/presentation/screens/invoice_list_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/shared/widgets/custom_text_field_safe.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/invoice_list_controller.dart';
import '../controllers/invoice_stats_controller.dart';
import '../bindings/invoice_binding.dart';
import '../widgets/invoice_card_widget.dart';
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
            body: _LoadingView(),
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

  Future<InvoiceListController> _ensureControllerRegistration() async {
    try {
      if (Get.isRegistered<InvoiceListController>()) {
        return Get.find<InvoiceListController>();
      }

      final binding = InvoiceBinding();
      binding.dependencies();
      await Future.delayed(const Duration(milliseconds: 100));

      return Get.find<InvoiceListController>();
    } catch (e) {
      debugPrint('Error registrando controlador: $e');
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
            const Text(
              'Error al cargar facturas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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

  Widget _buildMainScreen(BuildContext context, InvoiceListController controller) {
    return Scaffold(
      appBar: _buildAppBar(context, controller),
      drawer: const AppDrawer(currentRoute: '/invoices'),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ElegantLightTheme.backgroundColor,
              ElegantLightTheme.cardColor,
            ],
          ),
        ),
        child: ResponsiveHelper.responsive(
          context,
          mobile: _buildMobileLayout(context, controller),
          tablet: _buildTabletLayout(context, controller),
          desktop: _buildDesktopLayout(context, controller),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context, controller),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, InvoiceListController controller) {
    return AppBar(
      title: const Text(
        'Gestión de Facturas',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
      ),
      actions: [
        if (ResponsiveHelper.isMobile(context))
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showMobileSearch(context, controller),
            tooltip: 'Búsqueda avanzada',
          ),

        Obx(() => IconButton(
          icon: controller.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh, color: Colors.white),
          onPressed: controller.isLoading ? null : () async {
            await controller.refreshAllData();
            _showRefreshSuccess();
          },
          tooltip: controller.isLoading ? 'Actualizando...' : 'Actualizar facturas',
        )),

        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: () => _showFilters(context, controller),
          tooltip: 'Filtros avanzados',
        ),

        Obx(() {
          final overdueCount = controller.filteredInvoices
              .where((i) => i.isOverdue)
              .length;

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
            tooltip: overdueCount > 0
                ? 'Ver $overdueCount facturas vencidas'
                : 'Sin facturas vencidas',
          );
        }),

        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, InvoiceListController controller) {
    if (ResponsiveHelper.isDesktop(context)) {
      return const SizedBox.shrink();
    }

    if (ResponsiveHelper.isMobile(context)) {
      return FloatingActionButton(
        onPressed: () => controller.goToCreateInvoice(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () => controller.goToCreateInvoice(),
      icon: const Icon(Icons.add),
      label: const Text('Nueva factura'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildDesktopLayout(BuildContext context, InvoiceListController controller) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando facturas...');
      }

      return Row(
        children: [
          _DesktopSidebar(controller: controller),
          Expanded(
            child: Column(
              children: [
                _DesktopToolbar(controller: controller),
                Expanded(child: _buildInvoicesList(controller)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMobileLayout(BuildContext context, InvoiceListController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _SearchField(controller: controller),
        ),
        Expanded(child: _buildInvoicesList(controller)),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, InvoiceListController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _SearchField(controller: controller),
        ),
        Expanded(child: _buildInvoicesList(controller)),
      ],
    );
  }

  Widget _buildInvoicesList(InvoiceListController controller) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando facturas...');
      }

      final invoiceList = controller.filteredInvoices;

      if (invoiceList.isEmpty) {
        return _EmptyState(isSearching: controller.searchQuery.isNotEmpty);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshAllData,
        child: Column(
          children: [
            if (controller.totalPages > 1) _PaginationInfo(controller: controller),

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

                      if (index == invoiceList.length - 1 && controller.hasNextPage)
                        _LoadMoreButton(controller: controller),
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

  void _handleInvoiceLongPress(Invoice invoice, InvoiceListController controller) {
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
      builder: (context) => Padding(
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
            _SearchField(controller: controller),
          ],
        ),
      ),
    );
  }

  void _showFilters(BuildContext context, InvoiceListController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
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
            _FilterSection(controller: controller),
          ],
        ),
      ),
    );
  }

  void _showRefreshSuccess() {
    Get.snackbar(
      'Actualizado',
      'Las facturas se han actualizado correctamente',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showCancelConfirmation(Invoice invoice, InvoiceListController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar Factura'),
        content: Text('¿Cancelar la factura ${invoice.number}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
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
}

// ==================== EXTRACTED WIDGETS ====================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.cardColor,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cargando facturas...',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Preparando la experiencia futurista',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final InvoiceListController controller;

  const _DesktopSidebar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height - kToolbarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const _SidebarHeader(),
          _SearchField(controller: controller),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatsSection(controller: controller),
                  const SizedBox(height: 16),
                  _FilterSection(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
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
          Column(
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
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final InvoiceListController controller;

  const _SearchField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomTextFieldSafe(
          controller: controller.searchController,
          label: '',
          hint: 'Buscar por número, cliente o monto...',
          prefixIcon: Icons.search,
          suffixIcon: controller.searchController.text.isNotEmpty ? Icons.clear : null,
          onSuffixIconPressed: controller.searchController.text.isNotEmpty
              ? controller.clearFilters
              : null,
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final InvoiceListController controller;

  const _StatsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final statsController = Get.find<InvoiceStatsController>();

      return FuturisticContainer(
        hasGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(
                    Icons.analytics,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Total',
              value: statsController.totalInvoices.toString(),
              icon: Icons.receipt_long,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Pagadas',
              value: statsController.paidInvoices.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Pendientes',
              value: statsController.pendingInvoices.toString(),
              icon: Icons.schedule,
              color: statsController.pendingInvoices > 0 ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Vencidas',
              value: statsController.overdueCount.toString(),
              icon: Icons.warning,
              color: statsController.overdueCount > 0 ? Colors.red : Colors.grey,
            ),
          ],
        ),
      );
    });
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [color, color.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final InvoiceListController controller;

  const _FilterSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
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
        Text(
          'Estado',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'Todos',
              isSelected: controller.selectedStatus == null,
              onTap: () => controller.filterByStatus(null),
              color: Colors.grey,
            ),
            _FilterChip(
              label: 'Pagadas',
              isSelected: controller.selectedStatus == InvoiceStatus.paid,
              onTap: () => controller.filterByStatus(InvoiceStatus.paid),
              color: Colors.green,
            ),
            _FilterChip(
              label: 'Pendientes',
              isSelected: controller.selectedStatus == InvoiceStatus.pending,
              onTap: () => controller.filterByStatus(InvoiceStatus.pending),
              color: Colors.orange,
            ),
            _FilterChip(
              label: 'Canceladas',
              isSelected: controller.selectedStatus == InvoiceStatus.cancelled,
              onTap: () => controller.filterByStatus(InvoiceStatus.cancelled),
              color: Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 16),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    ));
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: ElegantLightTheme.normalAnimation,
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : ElegantLightTheme.elevatedShadow,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : ElegantLightTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  final InvoiceListController controller;

  const _DesktopToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
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
                  if (controller.totalPages > 1)
                    Text(
                      controller.paginationInfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
          Obx(() {
            if (controller.isSearching) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                onSelected: (value) => _handleDesktopAction(value, context, controller),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 12),
                        Text('Exportar Lista'),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
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
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.more_horiz, size: 18),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => controller.goToCreateInvoice(),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Nueva Factura'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleDesktopAction(String action, BuildContext context, InvoiceListController controller) {
    switch (action) {
      case 'export':
        Get.snackbar(
          'Próximamente',
          'La función de exportar facturas estará disponible pronto',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.download, color: Colors.green),
        );
        break;
      case 'stats':
        Get.toNamed('/invoices/stats');
        break;
    }
  }
}

class _PaginationInfo extends StatelessWidget {
  final InvoiceListController controller;

  const _PaginationInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() => Column(
        children: [
          LinearProgressIndicator(
            value: controller.loadingProgress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.paginationInfo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
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
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cargando...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      )),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final InvoiceListController controller;

  const _LoadMoreButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        if (controller.isLoadingMore) {
          return const Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text(
                'Cargando más facturas...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          );
        }

        return TextButton(
          onPressed: controller.canLoadMore ? controller.loadMoreInvoices : null,
          child: Text(
            controller.canLoadMore ? 'Cargar más facturas' : 'No hay más facturas',
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;

  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
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
}

class FuturisticContainer extends StatelessWidget {
  final Widget child;
  final bool hasGlow;

  const FuturisticContainer({
    super.key,
    required this.child,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
        ),
        boxShadow: hasGlow ? ElegantLightTheme.glowShadow : ElegantLightTheme.elevatedShadow,
      ),
      child: child,
    );
  }
}
