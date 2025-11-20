// lib/features/customers/presentation/screens/customer_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/customer_stats_controller.dart';
import '../widgets/customer_stats_widget.dart';

class CustomerStatsScreen extends GetView<CustomerStatsController> {
  const CustomerStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading) {
            return const LoadingWidget(message: 'Cargando estadísticas...');
          }

          return ResponsiveLayout(
            mobile: _buildMobileLayout(context),
            tablet: _buildTabletLayout(context),
            desktop: _buildDesktopLayout(context),
          );
        }),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.analytics,
              size: isMobile ? 18 : 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Estadísticas de Clientes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 16 : 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      actions: [
        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: controller.refreshStats,
          tooltip: 'Actualizar',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
          ),
        ),

        // Periodo de tiempo
        if (!isMobile)
          Obx(
            () => TextButton.icon(
              onPressed: () => _showPeriodSelector(context),
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(controller.currentPeriodLabel),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

        // Menú de opciones
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20, color: Colors.white),
          onSelected: (value) => _handleMenuAction(value, context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
          ),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.download,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Exportar Reporte',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.share,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Compartir',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.print,
                      size: 18,
                      color: ElegantLightTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Imprimir',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshStats,
      child: SingleChildScrollView(
        padding: context.responsivePadding,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Resumen principal
            _buildMainStatsCard(context),
            SizedBox(height: context.verticalSpacing),

            // Estadísticas por estado
            _buildStatusStatsCard(context),
            SizedBox(height: context.verticalSpacing),

            // Estadísticas financieras
            _buildFinancialStatsCard(context),
            SizedBox(height: context.verticalSpacing),

            // Distribución por tipo de documento
            _buildDocumentTypeStatsCard(context),
            SizedBox(height: context.verticalSpacing),

            // Estadísticas de actividad
            _buildActivityStatsCard(context),
            SizedBox(height: context.verticalSpacing),

            // Top clientes
            _buildTopCustomersCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshStats,
      child: SingleChildScrollView(
        child: AdaptiveContainer(
          maxWidth: 1000,
          child: Column(
            children: [
              SizedBox(height: context.verticalSpacing),

              // Resumen principal
              _buildMainStatsCard(context),
              SizedBox(height: context.verticalSpacing * 2),

              // Primera fila: Estados y Financiera
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildStatusStatsCard(context)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildFinancialStatsCard(context)),
                ],
              ),

              SizedBox(height: context.verticalSpacing * 2),

              // Segunda fila: Documentos y Actividad
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDocumentTypeStatsCard(context)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildActivityStatsCard(context)),
                ],
              ),

              SizedBox(height: context.verticalSpacing * 2),

              // Top clientes
              _buildTopCustomersCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshStats,
      child: Row(
        children: [
          // Panel principal
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Resumen principal
                  _buildMainStatsCard(context),
                  const SizedBox(height: 32),

                  // Primera fila
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildStatusStatsCard(context)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildFinancialStatsCard(context)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Segunda fila
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDocumentTypeStatsCard(context)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildActivityStatsCard(context)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Panel lateral
          Container(
            width: 400,
            padding: const EdgeInsets.fromLTRB(0, 32, 32, 32),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient.scale(0.3),
              border: Border(
                left: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                // Header del panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.cardGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                    ),
                    boxShadow: ElegantLightTheme.elevatedShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.primaryGradient.scale(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          size: 20,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Panel de Control',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Top clientes
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildTopCustomersCard(context),
                  ),
                ),

                const SizedBox(height: 24),

                // Acciones rápidas
                _buildQuickActionsCard(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatsCard(BuildContext context) {
    return Obx(() {
      if (controller.stats == null) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      return CustomerStatsWidget(stats: controller.stats!, isCompact: false);
    });
  }

  Widget _buildStatusStatsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: ElegantLightTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Distribución por Estado',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 16,
                      tablet: 16,
                      desktop: 20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Obx(() {
            if (controller.stats == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = controller.stats!;
            return Column(
              children: [
                _buildStatusItem(
                  context,
                  'Activos',
                  stats.active,
                  stats.total,
                  Colors.green,
                  Icons.check_circle,
                ),
                const SizedBox(height: 16),
                _buildStatusItem(
                  context,
                  'Inactivos',
                  stats.inactive,
                  stats.total,
                  Colors.orange,
                  Icons.pause_circle,
                ),
                const SizedBox(height: 16),
                _buildStatusItem(
                  context,
                  'Suspendidos',
                  stats.suspended,
                  stats.total,
                  Colors.red,
                  Icons.block,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
    IconData icon,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    final gradient = _getGradientForColor(color);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: gradient.scale(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '$count (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor:
                      ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  LinearGradient _getGradientForColor(Color color) {
    if (color == Colors.green || color == Colors.green.shade600) {
      return ElegantLightTheme.successGradient;
    } else if (color == Colors.orange || color == ElegantLightTheme.accentOrange) {
      return ElegantLightTheme.warningGradient;
    } else if (color == Colors.red || color == Colors.red.shade600) {
      return ElegantLightTheme.errorGradient;
    } else if (color == Colors.blue) {
      return ElegantLightTheme.infoGradient;
    } else if (color == Colors.purple) {
      return ElegantLightTheme.primaryGradient;
    } else if (color == Colors.teal) {
      return ElegantLightTheme.successGradient;
    } else {
      return ElegantLightTheme.primaryGradient;
    }
  }

  Widget _buildFinancialStatsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Estadísticas Financieras',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 16,
                      tablet: 16,
                      desktop: 20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Obx(() {
            if (controller.stats == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = controller.stats!;
            return Column(
              children: [
                _buildFinancialItem(
                  context,
                  'Límite de Crédito Total',
                  _formatCurrency(stats.totalCreditLimit),
                  Icons.credit_card,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildFinancialItem(
                  context,
                  'Balance Pendiente Total',
                  _formatCurrency(stats.totalBalance),
                  Icons.account_balance,
                  Colors.purple,
                ),
                const SizedBox(height: 16),
                _buildFinancialItem(
                  context,
                  'Promedio de Compra',
                  _formatCurrency(stats.averagePurchaseAmount ?? 0.0),
                  Icons.shopping_cart,
                  Colors.teal,
                ),
                if ((stats.customersWithOverdue ?? 0) > 0) ...[
                  const SizedBox(height: 16),
                  _buildFinancialItem(
                    context,
                    'Clientes con Deuda Vencida',
                    '${stats.customersWithOverdue}',
                    Icons.warning,
                    Colors.red,
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final gradient = _getGradientForColor(color);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: gradient.scale(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
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
    );
  }

  Widget _buildDocumentTypeStatsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.badge,
                  color: ElegantLightTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tipos de Documento',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Obx(() {
            if (controller.documentTypeStats.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children:
                  controller.documentTypeStats.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildDocumentTypeItem(
                        context,
                        _getDocumentTypeLabel(entry.key),
                        entry.value,
                        controller.stats?.total ?? 0,
                      ),
                    );
                  }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeItem(
    BuildContext context,
    String label,
    int count,
    int total,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient.scale(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient.scale(0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: ElegantLightTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStatsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: ElegantLightTheme.accentOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Actividad Reciente',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Obx(() {
            return Column(
              children: [
                _buildActivityItem(
                  context,
                  'Clientes Registrados (${controller.currentPeriodLabel})',
                  '${controller.newCustomersThisPeriod}',
                  Icons.person_add,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildActivityItem(
                  context,
                  'Clientes Activos (${controller.currentPeriodLabel})',
                  '${controller.activeCustomersThisPeriod}',
                  Icons.check_circle,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildActivityItem(
                  context,
                  'Promedio Diario',
                  (controller.newCustomersThisPeriod /
                          controller.daysInCurrentPeriod)
                      .toStringAsFixed(1),
                  Icons.timeline,
                  Colors.orange,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final gradient = _getGradientForColor(color);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: gradient.scale(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
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
    );
  }

  Widget _buildTopCustomersCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: ElegantLightTheme.accentOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Top Clientes',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Obx(() {
            if (controller.topCustomers.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: ElegantLightTheme.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay clientes disponibles',
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children:
                  controller.topCustomers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final customer = entry.value;

                    final name =
                        customer['name'] as String? ?? 'Cliente sin nombre';
                    final totalPurchases =
                        (customer['totalPurchases'] as num?)?.toDouble() ?? 0.0;
                    final totalOrders =
                        (customer['totalOrders'] as num?)?.toInt() ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTopCustomerItem(
                        context,
                        index + 1,
                        name,
                        totalPurchases,
                        totalOrders,
                      ),
                    );
                  }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopCustomerItem(
    BuildContext context,
    int position,
    String name,
    double totalPurchases,
    int totalOrders,
  ) {
    Color positionColor;
    IconData positionIcon;
    LinearGradient positionGradient;

    switch (position) {
      case 1:
        positionColor = Colors.amber;
        positionIcon = Icons.looks_one;
        positionGradient = ElegantLightTheme.warningGradient;
        break;
      case 2:
        positionColor = Colors.grey;
        positionIcon = Icons.looks_two;
        positionGradient = ElegantLightTheme.glassGradient;
        break;
      case 3:
        positionColor = Colors.brown;
        positionIcon = Icons.looks_3;
        positionGradient = ElegantLightTheme.errorGradient.scale(0.5);
        break;
      default:
        positionColor = ElegantLightTheme.primaryBlue;
        positionIcon = Icons.person;
        positionGradient = ElegantLightTheme.primaryGradient;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: positionGradient.scale(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: positionColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: positionColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: positionGradient,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: positionColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(positionIcon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  totalPurchases > 0
                      ? '${_formatCurrency(totalPurchases)} • $totalOrders órdenes'
                      : 'Sin compras registradas',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        totalPurchases > 0
                            ? ElegantLightTheme.textSecondary
                            : ElegantLightTheme.accentOrange,
                    fontStyle:
                        totalPurchases > 0
                            ? FontStyle.normal
                            : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Botón Ver Todos los Clientes
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.goToCustomersList,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ElegantLightTheme.elevatedShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.people, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Ver Todos los Clientes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botón Nuevo Cliente
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.goToCreateCustomer,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.person_add, size: 20, color: ElegantLightTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'Nuevo Cliente',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botón Exportar Reporte
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showExportDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.download, size: 20, color: ElegantLightTheme.primaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'Exportar Reporte',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.primaryBlue,
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

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (context.isMobile) {
      return FloatingActionButton(
        onPressed: controller.refreshStats,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ElegantLightTheme.glowShadow,
          ),
          child: const Icon(Icons.refresh, color: Colors.white, size: 24),
        ),
      );
    }
    return null;
  }

  // ==================== ACTION METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'export':
        _showExportDialog(context);
        break;
      case 'share':
        _showShareDialog(context);
        break;
      case 'print':
        _showPrintDialog(context);
        break;
    }
  }

  void _showPeriodSelector(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient.scale(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Seleccionar Período',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Options - Wrapped in Flexible to prevent overflow
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: controller.availablePeriods.map((period) {
                      return ListTile(
                        title: Text(
                          period['label'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: ElegantLightTheme.textPrimary,
                          ),
                        ),
                        trailing: Obx(() {
                          final isSelected = controller.currentPeriod == period['value'];
                          return isSelected
                              ? Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: ElegantLightTheme.successGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : const SizedBox.shrink();
                        }),
                        onTap: () {
                          controller.changePeriod(period['value'] as String);
                          Get.back();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient.scale(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.download,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Exportar Reporte',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Selecciona el formato de exportación:',
                style: TextStyle(
                  fontSize: 14,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Funcionalidad pendiente de implementar',
                style: TextStyle(
                  fontSize: 13,
                  color: ElegantLightTheme.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
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
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Get.back();
                        controller.exportToCsv();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.successGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: ElegantLightTheme.elevatedShadow,
                        ),
                        child: const Text(
                          'Exportar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient.scale(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.share,
                      color: ElegantLightTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Compartir Estadísticas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Funcionalidad pendiente de implementar',
                style: TextStyle(
                  fontSize: 14,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: ElegantLightTheme.elevatedShadow,
                      ),
                      child: const Text(
                        'Cerrar',
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
            ],
          ),
        ),
      ),
    );
  }

  void _showPrintDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient.scale(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.print,
                      color: ElegantLightTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Imprimir Reporte',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Funcionalidad pendiente de implementar',
                style: TextStyle(
                  fontSize: 14,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: ElegantLightTheme.elevatedShadow,
                      ),
                      child: const Text(
                        'Cerrar',
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
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  String _formatCurrency(double amount) {
    // Formateo en pesos colombianos
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  String _getDocumentTypeLabel(String type) {
    switch (type) {
      case 'cc':
        return 'Cédula de Ciudadanía';
      case 'nit':
        return 'NIT';
      case 'ce':
        return 'Cédula de Extranjería';
      case 'passport':
        return 'Pasaporte';
      case 'other':
        return 'Otro';
      default:
        return type;
    }
  }
}
