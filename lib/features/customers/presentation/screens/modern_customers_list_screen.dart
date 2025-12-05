// lib/features/customers/presentation/screens/modern_customers_list_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/customers_controller.dart';
import '../controllers/customer_stats_controller.dart';
import '../widgets/modern_customer_card_widget.dart';
import '../../domain/entities/customer.dart';

class ModernCustomersListScreen extends GetView<CustomersController> {
  const ModernCustomersListScreen({super.key});

  CustomerStatsController get statsController => Get.find<CustomerStatsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(currentRoute: '/customers'),
      backgroundColor: ElegantLightTheme.backgroundColor,
      body: ResponsiveHelper.responsive(
        context,
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.people_alt_rounded,
              color: Colors.white,
              size: isMobile ? 18 : 20,
            ),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Text(
            'Gestión de Clientes',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      actions: [
        Obx(() => _buildAppBarButton(
          icon: controller.isLoading
              ? null
              : Icons.refresh_rounded,
          isLoading: controller.isLoading,
          onTap: controller.isLoading ? null : () async {
            await controller.refreshCustomers();
            await statsController.refreshStats();
            _showRefreshSuccess();
          },
          tooltip: 'Actualizar',
        )),
        const SizedBox(width: 6),
        _buildAppBarButton(
          icon: Icons.tune_rounded,
          onTap: () => _showFilters(context),
          tooltip: 'Filtros',
        ),
        if (!isMobile) ...[
          const SizedBox(width: 6),
          _buildAppBarButton(
            icon: Icons.bar_chart_rounded,
            onTap: () => controller.goToCustomerStats(),
            tooltip: 'Estadísticas',
          ),
        ],
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildAppBarButton({
    IconData? icon,
    bool isLoading = false,
    VoidCallback? onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.successGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.goToCreateCustomer,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.isMobile(context) ? 16 : 20,
              vertical: ResponsiveHelper.isMobile(context) ? 14 : 14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                if (!ResponsiveHelper.isMobile(context)) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Nuevo Cliente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildMobileLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading && controller.customers.isEmpty) {
        return const LoadingWidget(message: 'Cargando clientes...');
      }

      return Column(
        children: [
          // Búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SearchField(controller: controller),
          ),
          // Lista
          Expanded(child: _buildCustomersList(context)),
        ],
      );
    });
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading && controller.customers.isEmpty) {
        return const LoadingWidget(message: 'Cargando clientes...');
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SearchField(controller: controller),
          ),
          Expanded(child: _buildCustomersList(context)),
        ],
      );
    });
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading && controller.customers.isEmpty) {
        return Row(
          children: [
            _DesktopSidebar(controller: controller, statsController: statsController),
            const Expanded(
              child: LoadingWidget(message: 'Cargando clientes...'),
            ),
          ],
        );
      }

      return Row(
        children: [
          _DesktopSidebar(controller: controller, statsController: statsController),
          Expanded(
            child: Column(
              children: [
                _DesktopToolbar(controller: controller),
                Expanded(child: _buildCustomersList(context)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCustomersList(BuildContext context) {
    return Obx(() {
      // Siempre usar customers - el API devuelve resultados filtrados cuando hay búsqueda
      final customers = controller.customers;

      if (customers.isEmpty && !controller.isLoading) {
        return _EmptyState(isSearching: controller.isSearchMode);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshCustomers,
        color: ElegantLightTheme.primaryBlue,
        child: Column(
          children: [
            if (controller.isLoading && controller.customers.isNotEmpty)
              LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.7),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                cacheExtent: 500,
                itemCount: customers.length + (controller.hasNextPage ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == customers.length) {
                    return _LoadMoreIndicator(controller: controller);
                  }

                  final customer = customers[index];
                  return ModernCustomerCardWidget(
                    key: ValueKey('customer_${customer.id}'),
                    customer: customer,
                    onTap: () => controller.showCustomerDetails(customer.id),
                    onEdit: () => controller.goToEditCustomer(customer.id),
                    onDelete: () => _showDeleteDialog(customer),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showDeleteDialog(Customer customer) {
    Get.dialog(
      _DeleteDialog(
        customer: customer,
        onDelete: () {
          Get.back();
          controller.deleteCustomer(customer.id);
        },
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Filtros de Clientes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _FilterSection(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRefreshSuccess() {
    Get.snackbar(
      'Actualizado',
      'La lista de clientes se ha actualizado',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
      colorText: const Color(0xFF065F46),
      icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}

// ==================== DESKTOP SIDEBAR ====================

class _DesktopSidebar extends StatelessWidget {
  final CustomersController controller;
  final CustomerStatsController statsController;

  const _DesktopSidebar({
    required this.controller,
    required this.statsController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _SidebarHeader(),
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SearchField(controller: controller),
          ),
          // Content scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _StatsSection(statsController: statsController),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
            ElegantLightTheme.primaryBlue.withValues(alpha: 0.03),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Clientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              Text(
                'Gestión y búsqueda',
                style: TextStyle(
                  fontSize: 13,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== SEARCH FIELD ====================

class _SearchField extends StatefulWidget {
  final CustomersController controller;

  const _SearchField({required this.controller});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.searchController.text.isNotEmpty;
    widget.controller.searchController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.searchController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.searchController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller.searchController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, email o documento...',
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade500),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                  onPressed: () {
                    widget.controller.searchController.clear();
                  },
                )
              : const SizedBox.shrink(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

// ==================== STATS SECTION ====================

class _StatsSection extends StatelessWidget {
  final CustomerStatsController statsController;

  const _StatsSection({required this.statsController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = statsController.stats;
      if (stats == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics_rounded, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats rows
            _StatRow(
              label: 'Total',
              value: '${stats.total}',
              icon: Icons.people_rounded,
              color: ElegantLightTheme.primaryBlue,
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'Activos',
              value: '${stats.active}',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'Inactivos',
              value: '${stats.inactive}',
              icon: Icons.pause_circle_rounded,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'En Riesgo',
              value: '${stats.customersWithOverdue}',
              icon: Icons.warning_rounded,
              color: const Color(0xFFEF4444),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== FILTER SECTION ====================

class _FilterSection extends StatelessWidget {
  final CustomersController controller;

  const _FilterSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  size: 16,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estado
          Text(
            'Estado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'Todos',
                isSelected: controller.currentStatus == null,
                onTap: () => controller.applyStatusFilter(null),
                color: ElegantLightTheme.textSecondary,
              ),
              _FilterChip(
                label: 'Activos',
                isSelected: controller.currentStatus == CustomerStatus.active,
                onTap: () => controller.applyStatusFilter(CustomerStatus.active),
                color: const Color(0xFF10B981),
              ),
              _FilterChip(
                label: 'Inactivos',
                isSelected: controller.currentStatus == CustomerStatus.inactive,
                onTap: () => controller.applyStatusFilter(CustomerStatus.inactive),
                color: const Color(0xFFF59E0B),
              ),
              _FilterChip(
                label: 'Suspendidos',
                isSelected: controller.currentStatus == CustomerStatus.suspended,
                onTap: () => controller.applyStatusFilter(CustomerStatus.suspended),
                color: const Color(0xFFEF4444),
              ),
            ],
          ),

          // Limpiar filtros
          if (_hasActiveFilters(controller)) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.clearFilters,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.clear_all_rounded,
                          size: 18,
                          color: const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Limpiar Filtros',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ));
  }

  bool _hasActiveFilters(CustomersController controller) {
    return controller.currentStatus != null || controller.searchTerm.isNotEmpty;
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== DESKTOP TOOLBAR ====================

class _DesktopToolbar extends StatelessWidget {
  final CustomersController controller;

  const _DesktopToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.12),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Info de resultados
          Expanded(
            child: Obx(() {
              final searchMode = controller.isSearchMode;
              // Siempre usar customers.length - el API devuelve resultados filtrados
              final count = controller.customers.length;
              final total = controller.totalItems;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    searchMode ? 'Resultados ($count)' : 'Lista de Clientes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    searchMode
                        ? 'Búsqueda: "${controller.searchTerm}"'
                        : 'Mostrando $count de $total clientes',
                    style: TextStyle(
                      fontSize: 13,
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),

          // Indicador de búsqueda
          Obx(() {
            if (controller.isSearching) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
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
                          ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Buscando...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Botones
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Estadísticas
              _ToolbarButton(
                icon: Icons.bar_chart_rounded,
                label: 'Estadísticas',
                onTap: () => Get.toNamed('/customers/stats'),
                isOutline: true,
              ),
              const SizedBox(width: 12),
              // Nuevo Cliente
              _ToolbarButton(
                icon: Icons.person_add_rounded,
                label: 'Nuevo Cliente',
                onTap: () => Get.toNamed('/customers/create'),
                gradient: ElegantLightTheme.successGradient,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isOutline;
  final LinearGradient? gradient;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isOutline = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: isOutline ? null : gradient,
            borderRadius: BorderRadius.circular(12),
            border: isOutline
                ? Border.all(color: ElegantLightTheme.primaryBlue, width: 2)
                : null,
            boxShadow: isOutline
                ? null
                : [
                    BoxShadow(
                      color: (gradient?.colors.first ?? Colors.blue).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isOutline ? ElegantLightTheme.primaryBlue : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isOutline ? ElegantLightTheme.primaryBlue : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== OTHER WIDGETS ====================

class _LoadMoreIndicator extends StatelessWidget {
  final CustomersController controller;

  const _LoadMoreIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingMore) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ElegantLightTheme.primaryBlue.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cargando más clientes...',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      final canLoadMore = !controller.isLoadingMore && controller.currentPage < controller.totalPages;
      if (canLoadMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!controller.isLoadingMore && controller.currentPage < controller.totalPages) {
            controller.loadMoreCustomers();
          }
        });
      }

      return const SizedBox(height: 20);
    });
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 48,
              color: ElegantLightTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearching ? 'Sin resultados' : 'No hay clientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Intenta con otros términos de búsqueda'
                : 'Crea tu primer cliente',
            style: TextStyle(
              fontSize: 14,
              color: ElegantLightTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  final Customer customer;
  final VoidCallback onDelete;

  const _DeleteDialog({
    required this.customer,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_forever_rounded, size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eliminar Cliente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Esta acción no se puede deshacer',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '¿Estás seguro que deseas eliminar al cliente "${customer.displayName}"?',
                    style: const TextStyle(
                      fontSize: 15,
                      color: ElegantLightTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Get.back(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ElegantLightTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: ElegantLightTheme.errorGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Eliminar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
