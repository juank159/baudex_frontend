// lib/features/customer_credits/presentation/pages/customer_credits_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../data/models/customer_credit_model.dart';
import '../../domain/entities/customer_credit.dart';
import '../controllers/customer_credit_controller.dart';
import '../widgets/create_credit_dialog.dart';
import 'customer_account_unified_page.dart';

/// Página principal de gestión de créditos de clientes
class CustomerCreditsPage extends StatefulWidget {
  const CustomerCreditsPage({super.key});

  @override
  State<CustomerCreditsPage> createState() => _CustomerCreditsPageState();
}

class _CustomerCreditsPageState extends State<CustomerCreditsPage> with WidgetsBindingObserver {
  late CustomerCreditController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CustomerCreditController>();
    WidgetsBinding.instance.addObserver(this);

    // Asegurar que los datos se carguen al iniciar la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.ensureDataLoaded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recargar datos cuando la app vuelve al foreground
    if (state == AppLifecycleState.resumed) {
      controller.refreshAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(currentRoute: '/customer-credits'),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
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
            mobile: _buildMobileLayout(context),
            tablet: _buildTabletLayout(context),
            desktop: _buildDesktopLayout(context),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Créditos de Clientes',
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
        Obx(() => IconButton(
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      controller.loadCredits();
                      controller.loadStats();
                    },
              tooltip: 'Actualizar',
            )),
        if (!ResponsiveHelper.isMobile(context))
          IconButton(
            icon: const Icon(Icons.warning_amber, color: Colors.white),
            onPressed: () => controller.markOverdueCredits(),
            tooltip: 'Marcar vencidos',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return const SizedBox.shrink();
    }

    if (ResponsiveHelper.isMobile(context)) {
      return Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            ...ElegantLightTheme.glowShadow,
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showCreateCreditDialog(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      );
    }

    // Tablet
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          ...ElegantLightTheme.glowShadow,
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () => _showCreateCreditDialog(context),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Nuevo Crédito',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _DesktopSidebar(controller: controller),
        Expanded(
          child: Column(
            children: [
              _DesktopToolbar(controller: controller, onCreateCredit: () => _showCreateCreditDialog(context)),
              Expanded(child: _buildCreditsList(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _buildSummaryCards(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _buildSearchBar(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _buildMobileFilters(),
        ),
        Expanded(child: _buildCreditsList(context)),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _buildSummaryCards(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _buildSearchBar(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _buildMobileFilters(),
        ),
        Expanded(child: _buildCreditsList(context)),
      ],
    );
  }

  /// Summary cards con Total Pendiente y Total Pagado
  Widget _buildSummaryCards() {
    return Obx(() {
      final stats = controller.stats.value;
      final totalPending = stats?.totalPending ?? 0;
      final totalPaid = stats?.totalPaid ?? 0;

      return Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Total Pendiente',
              value: AppFormatters.formatCurrency(totalPending),
              icon: Icons.pending_outlined,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Total Pagado',
              value: AppFormatters.formatCurrency(totalPaid),
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => TextField(
            onChanged: controller.updateSearchQuery,
            decoration: InputDecoration(
              hintText: 'Buscar por cliente, descripción o factura...',
              hintStyle: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: ElegantLightTheme.textSecondary,
              ),
              suffixIcon: controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: ElegantLightTheme.textSecondary,
                      ),
                      onPressed: controller.clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          )),
    );
  }

  Widget _buildMobileFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 360;
        final isMediumScreen = constraints.maxWidth < 400;
        final spacing = isSmallScreen ? 4.0 : (isMediumScreen ? 6.0 : 8.0);

        return Obx(() => Row(
              children: [
                Expanded(
                  child: _MobileFilterChip(
                    label: 'Todos',
                    count: controller.allCreditsCount,
                    isSelected: !controller.hasActiveFilters,
                    onTap: () => controller.clearFilters(),
                    color: ElegantLightTheme.primaryBlue,
                    isCompact: isSmallScreen,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _MobileFilterChip(
                    label: isSmallScreen ? 'Pend.' : 'Pendientes',
                    count: controller.pendingCreditsCount,
                    isSelected: controller.selectedStatus.value == CreditStatus.pending ||
                        controller.selectedStatus.value == CreditStatus.partiallyPaid,
                    onTap: () => controller.filterByStatus(CreditStatus.pending),
                    color: Colors.orange,
                    isCompact: isSmallScreen,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _MobileFilterChip(
                    label: isSmallScreen ? 'Venc.' : 'Vencidos',
                    count: controller.overdueCreditsCount,
                    isSelected: controller.showOverdueOnly.value,
                    onTap: () => controller.filterByOverdue(),
                    color: Colors.red,
                    isCompact: isSmallScreen,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _MobileFilterChip(
                    label: isSmallScreen ? 'Pag.' : 'Pagados',
                    count: controller.paidCreditsCount,
                    isSelected: controller.selectedStatus.value == CreditStatus.paid,
                    onTap: () => controller.filterByStatus(CreditStatus.paid),
                    color: Colors.green,
                    isCompact: isSmallScreen,
                  ),
                ),
              ],
            ));
      },
    );
  }

  Widget _buildCreditsList(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Obx(() {
      if (controller.isLoading.value && controller.credits.isEmpty) {
        return _buildLoadingState();
      }

      if (controller.errorMessage.isNotEmpty) {
        return _buildErrorState();
      }

      if (controller.credits.isEmpty) {
        return _buildEmptyState();
      }

      // Usar créditos agrupados por cliente
      final groupedCredits = controller.filteredCreditsByCustomer;

      if (groupedCredits.isEmpty && controller.searchQuery.value.isNotEmpty) {
        return _buildNoResultsState();
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadCredits();
          await controller.loadStats();
        },
        color: ElegantLightTheme.primaryGradient.colors.first,
        child: ListView.builder(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          itemCount: groupedCredits.length,
          itemBuilder: (context, index) {
            final summary = groupedCredits[index];
            return _CustomerSummaryCard(
              summary: summary,
              isMobile: isMobile,
              onTap: () => _showCustomerAccountUnified(context, summary),
            );
          },
        ),
      );
    });
  }

  Widget _buildNoResultsState() {
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
              Icons.search_off,
              size: 50,
              color: ElegantLightTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
                'No hay créditos que coincidan con "${controller.searchQuery.value}"',
                textAlign: TextAlign.center,
                style: TextStyle(color: ElegantLightTheme.textSecondary),
              )),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: controller.clearSearch,
            icon: const Icon(Icons.clear),
            label: const Text('Limpiar búsqueda'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(
              Icons.credit_card,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cargando créditos...',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.errorGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            controller.errorMessage.value,
            textAlign: TextAlign.center,
            style: TextStyle(color: ElegantLightTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => controller.loadCredits(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.credit_card_off,
              size: 50,
              color: ElegantLightTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay créditos registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los créditos se crean automáticamente\ncuando hay saldo pendiente',
            textAlign: TextAlign.center,
            style: TextStyle(color: ElegantLightTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showCreateCreditDialog(BuildContext context) {
    Get.dialog(const CreateCreditDialog(), barrierDismissible: false);
  }

  void _showCustomerAccountUnified(BuildContext context, CustomerCreditSummary summary) async {
    await Get.to<void>(
      () => CustomerAccountUnifiedPage(
        customerId: summary.customerId,
        customerName: summary.customerName,
        initialSummary: summary,
      ),
      transition: Transition.rightToLeft,
    );
    // Recargar datos al volver para reflejar cualquier cambio
    await controller.refreshAllData();
  }
}

// ==================== DESKTOP SIDEBAR ====================

class _DesktopSidebar extends StatelessWidget {
  final CustomerCreditController controller;

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
          _buildSidebarHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DesktopSearchBar(controller: controller),
                  const SizedBox(height: 16),
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

  Widget _buildSidebarHeader() {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.primaryGradient.colors.first.withValues(alpha: 0.15),
            ElegantLightTheme.primaryGradient.colors.last.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
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
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.credit_card, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      ElegantLightTheme.primaryGradient.createShader(bounds),
                  child: const Text(
                    'Créditos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.successGradient,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Gestión de cartera',
                      style: TextStyle(
                        fontSize: 12,
                        color: ElegantLightTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SUMMARY CARD ====================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
}

// ==================== DESKTOP SEARCH BAR ====================

class _DesktopSearchBar extends StatelessWidget {
  final CustomerCreditController controller;

  const _DesktopSearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Obx(() => TextField(
            onChanged: controller.updateSearchQuery,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              hintStyle: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: ElegantLightTheme.textSecondary,
                size: 20,
              ),
              suffixIcon: controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: ElegantLightTheme.textSecondary,
                        size: 18,
                      ),
                      onPressed: controller.clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          )),
    );
  }
}

// ==================== STATS SECTION ====================

class _StatsSection extends StatelessWidget {
  final CustomerCreditController controller;

  const _StatsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.stats.value;

      return _FuturisticContainer(
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
                  child: const Icon(Icons.analytics, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Resumen',
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
              label: 'Total Pendiente',
              value: AppFormatters.formatCurrency(stats?.totalPending ?? 0),
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Total Vencido',
              value: AppFormatters.formatCurrency(stats?.totalOverdue ?? 0),
              icon: Icons.warning,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Total Cobrado',
              value: AppFormatters.formatCurrency(stats?.totalPaid ?? 0),
              icon: Icons.check_circle,
              color: Colors.green,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
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
          ),
        ],
      ),
    );
  }
}

// ==================== FILTER SECTION ====================

class _FilterSection extends StatelessWidget {
  final CustomerCreditController controller;

  const _FilterSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'Todos',
                  count: controller.allCreditsCount,
                  isSelected: !controller.hasActiveFilters,
                  onTap: () => controller.clearFilters(),
                  color: ElegantLightTheme.primaryBlue,
                ),
                _FilterChip(
                  label: 'Pendientes',
                  count: controller.pendingCreditsCount,
                  isSelected: controller.selectedStatus.value == CreditStatus.pending ||
                      controller.selectedStatus.value == CreditStatus.partiallyPaid,
                  onTap: () => controller.filterByStatus(CreditStatus.pending),
                  color: Colors.orange,
                ),
                _FilterChip(
                  label: 'Vencidos',
                  count: controller.overdueCreditsCount,
                  isSelected: controller.showOverdueOnly.value,
                  onTap: () => controller.filterByOverdue(),
                  color: Colors.red,
                ),
                _FilterChip(
                  label: 'Pagados',
                  count: controller.paidCreditsCount,
                  isSelected: controller.selectedStatus.value == CreditStatus.paid,
                  onTap: () => controller.filterByStatus(CreditStatus.paid),
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controller.hasActiveFilters)
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    this.count,
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
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
              : ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.5) : ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : ElegantLightTheme.elevatedShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : ElegantLightTheme.textPrimary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MobileFilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final bool isCompact;

  const _MobileFilterChip({
    required this.label,
    this.count,
    required this.isSelected,
    required this.onTap,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isCompact ? 6.0 : 10.0;
    final verticalPadding = isCompact ? 8.0 : 10.0;
    final labelFontSize = isCompact ? 10.0 : 12.0;
    final countFontSize = isCompact ? 9.0 : 10.0;
    final spaceBetween = isCompact ? 3.0 : 5.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
              : null,
          color: isSelected ? null : ElegantLightTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : ElegantLightTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (count != null) ...[
              SizedBox(width: spaceBetween),
              Container(
                constraints: BoxConstraints(minWidth: isCompact ? 16 : 20),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 4 : 5,
                  vertical: isCompact ? 1 : 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: countFontSize,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== DESKTOP TOOLBAR ====================

class _DesktopToolbar extends StatelessWidget {
  final CustomerCreditController controller;
  final VoidCallback onCreateCredit;

  const _DesktopToolbar({required this.controller, required this.onCreateCredit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15)),
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final count = controller.credits.length;

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.credit_card, size: 20, color: ElegantLightTheme.primaryBlue),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Créditos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: ElegantLightTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: ElegantLightTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestión de créditos de clientes',
                        style: TextStyle(
                          fontSize: 12,
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                ...ElegantLightTheme.glowShadow,
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onCreateCredit,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Nuevo Crédito',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SHARED WIDGETS ====================

class _FuturisticContainer extends StatelessWidget {
  final Widget child;
  final bool hasGlow;

  const _FuturisticContainer({required this.child, this.hasGlow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2)),
        boxShadow: hasGlow ? ElegantLightTheme.glowShadow : ElegantLightTheme.elevatedShadow,
      ),
      child: child,
    );
  }
}

/// Efecto shimmer animado para barras de progreso
class _ShimmerEffect extends StatefulWidget {
  final Color color;
  final double height;

  const _ShimmerEffect({
    required this.color,
    required this.height,
  });

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== CUSTOMER SUMMARY CARD (AGRUPADO POR CLIENTE) ====================

/// Card que muestra el resumen de todos los créditos de un cliente
class _CustomerSummaryCard extends StatelessWidget {
  final CustomerCreditSummary summary;
  final bool isMobile;
  final VoidCallback onTap;

  const _CustomerSummaryCard({
    required this.summary,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasOverdue = summary.hasOverdueCredits;
    final padding = isMobile ? 14.0 : 18.0;

    // Color principal basado en estado
    Color mainColor;
    if (hasOverdue) {
      mainColor = Colors.red;
    } else if (summary.totalBalanceDue > 0) {
      mainColor = Colors.orange;
    } else {
      mainColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasOverdue
              ? Colors.red.withValues(alpha: 0.4)
              : ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
          width: hasOverdue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasOverdue
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con avatar y nombre
                Row(
                  children: [
                    // Avatar con gradiente
                    Container(
                      width: isMobile ? 50 : 56,
                      height: isMobile ? 50 : 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [mainColor, mainColor.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: mainColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          summary.customerInitials,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 18 : 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.customerName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: isMobile ? 16 : 18,
                              color: ElegantLightTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Badges de estado
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildBadge(
                                '${summary.totalCredits} crédito${summary.totalCredits != 1 ? "s" : ""}',
                                ElegantLightTheme.primaryBlue,
                              ),
                              if (summary.overdueCredits > 0)
                                _buildBadge(
                                  '${summary.overdueCredits} vencido${summary.overdueCredits != 1 ? "s" : ""}',
                                  Colors.red,
                                  isWarning: true,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Flecha indicadora
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Resumen de montos
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        mainColor.withValues(alpha: 0.08),
                        mainColor.withValues(alpha: 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: mainColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildAmountItem(
                        'Total',
                        AppFormatters.formatCurrency(summary.totalOriginalAmount),
                        ElegantLightTheme.textPrimary,
                        isMobile,
                      ),
                      _buildDivider(),
                      _buildAmountItem(
                        'Pagado',
                        AppFormatters.formatCurrency(summary.totalPaidAmount),
                        Colors.green,
                        isMobile,
                      ),
                      _buildDivider(),
                      _buildAmountItem(
                        'Pendiente',
                        AppFormatters.formatCurrency(summary.totalBalanceDue),
                        mainColor,
                        isMobile,
                        isBold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Barra de progreso
                _buildProgressSection(mainColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isWarning ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: isWarning ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWarning) ...[
            Icon(Icons.warning, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountItem(String label, String value, Color color, bool isMobile, {bool isBold = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: ElegantLightTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 13 : 15,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
    );
  }

  Widget _buildProgressSection(Color color) {
    final progress = summary.paymentProgress;
    final percentage = (progress * 100).clamp(0.0, 100.0);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    'Progreso de pago',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Barra de progreso con fondo visible
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, child) {
                  return Stack(
                    children: [
                      // FONDO - Muestra lo que FALTA por pagar
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE4EF),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      // BARRA DE PROGRESO - Muestra lo PAGADO
                      FractionallySizedBox(
                        widthFactor: animatedProgress.clamp(0.0, 1.0),
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.85)],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
