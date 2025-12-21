// lib/features/customers/presentation/screens/customer_detail_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/customer_detail_controller.dart';
import '../../domain/entities/customer.dart';

class CustomerDetailScreen extends GetView<CustomerDetailController> {
  const CustomerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: _buildElegantAppBar(context),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget(
            message: 'Cargando detalles del cliente...',
          );
        }

        if (!controller.hasCustomer) {
          return _buildErrorState(context);
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        );
      }),
      floatingActionButton: _buildMobileFAB(context),
    );
  }

  // ==================== ELEGANT APP BAR ====================

  PreferredSizeWidget _buildElegantAppBar(BuildContext context) {
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
      title: Obx(
        () => Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                controller.hasCustomer && controller.customer!.companyName != null
                    ? Icons.business
                    : Icons.person,
                size: isMobile ? 18 : 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.hasCustomer
                        ? controller.customer!.displayName
                        : 'Detalles del Cliente',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (controller.hasCustomer)
                    Text(
                      controller.customer!.email,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => Get.offAllNamed(AppRoutes.customers),
      ),
      actions: [
        if (controller.hasCustomer) ...[
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: controller.goToEditCustomer,
            tooltip: 'Editar cliente',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.white),
            onSelected: (value) => _handleMenuAction(value, context),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            itemBuilder: (context) => [
              _buildPopupMenuItem('status', Icons.toggle_on, 'Cambiar Estado', ElegantLightTheme.infoGradient),
              _buildPopupMenuItem('purchase', Icons.credit_card, 'Verificar Compra', ElegantLightTheme.successGradient),
              _buildPopupMenuItem('refresh', Icons.refresh, 'Actualizar', ElegantLightTheme.primaryGradient),
              const PopupMenuDivider(),
              _buildPopupMenuItem('delete', Icons.delete, 'Eliminar', ElegantLightTheme.errorGradient, isDestructive: true),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String label,
    LinearGradient gradient, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDestructive ? Colors.red.shade600 : ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MOBILE LAYOUT ====================

  Widget _buildMobileLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshCustomer,
      color: ElegantLightTheme.primaryBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildCustomerProfileCard(context),
            const SizedBox(height: 12),
            _buildQuickMetricsRow(context),
            const SizedBox(height: 12),
            _buildPersonalInfoCard(context),
            const SizedBox(height: 12),
            _buildContactInfoCard(context),
            const SizedBox(height: 12),
            _buildFinancialCard(context),
            const SizedBox(height: 12),
            _buildActivityCard(context),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================

  Widget _buildTabletLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshCustomer,
      color: ElegantLightTheme.primaryBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                // Header compacto
                _buildCompactHeader(context),
                const SizedBox(height: 12),

                // Fila 1: Info Personal y Contacto (columnas iguales)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildCompactPersonalCard(context)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCompactContactCard(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Fila 2: Financiero y Acciones (columnas iguales)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildCompactFinancialCard(context)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCompactActionsCard(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Actividad (ancho completo)
                _buildCompactActivityCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Main Content Area - similar a móvil pero más espacioso
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.refreshCustomer,
            color: ElegantLightTheme.primaryBlue,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Card - igual que móvil
                  _buildCustomerProfileCard(context),
                  const SizedBox(height: 16),

                  // Quick Metrics Row - Balance, Crédito, Órdenes
                  _buildQuickMetricsRow(context),
                  const SizedBox(height: 16),

                  // Info Personal y Contacto en una fila
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildPersonalInfoCard(context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildContactInfoCard(context)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Financial Card - ancho completo
                  _buildFinancialCard(context),
                  const SizedBox(height: 16),

                  // Activity Card
                  _buildActivityCard(context),
                ],
              ),
            ),
          ),
        ),

        // Right Sidebar
        Container(
          width: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ElegantLightTheme.cardColor,
                ElegantLightTheme.backgroundColor,
              ],
            ),
            border: Border(
              left: BorderSide(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.12),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSidebarStatusSection(context),
                const SizedBox(height: 16),
                _buildActionsCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Status section para la sidebar de desktop
  Widget _buildSidebarStatusSection(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;
      final status = customer.status;
      final color = _getStatusColor(status);

      return FuturisticContainer(
        padding: const EdgeInsets.all(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.04),
          ],
        ),
        child: Column(
          children: [
            // Icono grande con estado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _getStatusGradient(status),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                status == CustomerStatus.active
                    ? Icons.check_circle
                    : status == CustomerStatus.inactive
                        ? Icons.pause_circle
                        : Icons.block,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Estado label
            Text(
              _getStatusLabel(status),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _getStatusDescription(status),
              style: const TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Info rápida del cliente
            _buildSidebarInfoRow(
              icon: Icons.calendar_today,
              label: 'Cliente desde',
              value: AppFormatters.formatDate(customer.createdAt),
            ),
            const SizedBox(height: 12),
            _buildSidebarInfoRow(
              icon: Icons.receipt_long,
              label: 'Total órdenes',
              value: '${customer.totalOrders}',
            ),
            const SizedBox(height: 12),
            _buildSidebarInfoRow(
              icon: Icons.account_balance_wallet,
              label: 'Balance actual',
              value: AppFormatters.formatCurrency(customer.currentBalance),
              valueColor: customer.currentBalance > 0
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSidebarInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: ElegantLightTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: ElegantLightTheme.textTertiary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== COMPACT COMPONENTS ====================

  Widget _buildCompactHeader(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;

      return FuturisticContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar compacto
            _buildAnimatedAvatar(customer, true, size: 56),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ElegantLightTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(customer.status),
                    ],
                  ),
                  if (customer.companyName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      customer.companyName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ElegantLightTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 12, color: ElegantLightTheme.textTertiary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          customer.email,
                          style: const TextStyle(fontSize: 11, color: ElegantLightTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (customer.phone != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.phone_outlined, size: 12, color: ElegantLightTheme.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone!,
                          style: const TextStyle(fontSize: 11, color: ElegantLightTheme.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Quick metrics compactos
            const SizedBox(width: 16),
            _buildCompactMetric(
              AppFormatters.formatCompactCurrency(customer.creditLimit),
              'Crédito',
              ElegantLightTheme.primaryBlue,
            ),
            const SizedBox(width: 12),
            _buildCompactMetric(
              AppFormatters.formatCompactCurrency(customer.currentBalance),
              'Balance',
              customer.currentBalance > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
            ),
            const SizedBox(width: 12),
            _buildCompactMetric(
              '${customer.totalOrders}',
              'Órdenes',
              const Color(0xFF8B5CF6),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCompactMetric(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: ElegantLightTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPersonalCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;

      return FuturisticContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactCardHeader('Personal', Icons.person, ElegantLightTheme.primaryGradient),
            const SizedBox(height: 12),
            _buildCompactInfoRow('Nombre', '${customer.firstName} ${customer.lastName}'),
            _buildCompactInfoRow('Documento', '${_getDocumentTypeLabel(customer.documentType).split(' ').first}: ${customer.documentNumber}'),
            if (customer.birthDate != null)
              _buildCompactInfoRow('Nacimiento', _formatDate(customer.birthDate!)),
            if (customer.companyName != null)
              _buildCompactInfoRow('Empresa', customer.companyName!),
          ],
        ),
      );
    });
  }

  Widget _buildCompactContactCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;

      return FuturisticContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactCardHeader('Contacto', Icons.contact_mail, ElegantLightTheme.infoGradient),
            const SizedBox(height: 12),
            _buildCompactInfoRow('Email', customer.email),
            if (customer.phone != null)
              _buildCompactInfoRow('Teléfono', customer.phone!),
            if (customer.mobile != null)
              _buildCompactInfoRow('Móvil', customer.mobile!),
            if (customer.address != null)
              _buildCompactInfoRow('Dirección', customer.address!),
            if (customer.city != null)
              _buildCompactInfoRow('Ciudad', '${customer.city}${customer.state != null ? ', ${customer.state}' : ''}'),
          ],
        ),
      );
    });
  }

  Widget _buildCompactFinancialCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;
      final creditAvailable = customer.creditLimit - customer.currentBalance;
      final creditUsagePercent = customer.creditLimit > 0
          ? (customer.currentBalance / customer.creditLimit).clamp(0.0, 1.0)
          : 0.0;

      return FuturisticContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactCardHeader('Financiero', Icons.account_balance_wallet, ElegantLightTheme.successGradient),
            const SizedBox(height: 12),

            // Barra de uso de crédito compacta
            if (customer.creditLimit > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Uso crédito', style: TextStyle(fontSize: 11, color: ElegantLightTheme.textSecondary)),
                  Text(
                    '${(creditUsagePercent * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getCreditUsageColor(creditUsagePercent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: creditUsagePercent,
                  minHeight: 6,
                  backgroundColor: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(_getCreditUsageColor(creditUsagePercent)),
                ),
              ),
              const SizedBox(height: 10),
            ],

            _buildCompactFinancialRow('Límite', customer.creditLimit, ElegantLightTheme.primaryBlue),
            _buildCompactFinancialRow('Balance', customer.currentBalance, const Color(0xFFF59E0B)),
            _buildCompactFinancialRow('Disponible', creditAvailable, const Color(0xFF10B981)),
            _buildCompactInfoRow('Pago', '${customer.paymentTerms} días'),
          ],
        ),
      );
    });
  }

  Widget _buildCompactActionsCard(BuildContext context) {
    return FuturisticContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactCardHeader('Acciones', Icons.flash_on, ElegantLightTheme.warningGradient),
          const SizedBox(height: 12),

          // Grid de acciones 2x2
          Row(
            children: [
              Expanded(
                child: _buildCompactActionButton(
                  icon: Icons.edit,
                  label: 'Editar',
                  color: ElegantLightTheme.primaryBlue,
                  onTap: controller.goToEditCustomer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactActionButton(
                  icon: Icons.swap_horiz,
                  label: 'Estado',
                  color: const Color(0xFF3B82F6),
                  onTap: controller.showStatusChangeDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactActionButton(
                  icon: Icons.credit_card,
                  label: 'Verificar',
                  color: const Color(0xFF10B981),
                  onTap: controller.showPurchaseCheckDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactActionButton(
                  icon: Icons.delete_outline,
                  label: 'Eliminar',
                  color: const Color(0xFFEF4444),
                  onTap: controller.confirmDeleteCustomer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActivityCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer;

      return FuturisticContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactCardHeader('Actividad', Icons.history, ElegantLightTheme.infoGradient),
            const SizedBox(height: 12),
            Row(
              children: [
                if (customer != null) ...[
                  Expanded(
                    child: _buildCompactActivityItem(
                      icon: Icons.person_add,
                      label: 'Registrado',
                      value: AppFormatters.formatDate(customer.createdAt),
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (customer.updatedAt != customer.createdAt)
                    Expanded(
                      child: _buildCompactActivityItem(
                        icon: Icons.edit,
                        label: 'Actualizado',
                        value: AppFormatters.formatDate(customer.updatedAt),
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  if (customer.totalOrders > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactActivityItem(
                        icon: Icons.shopping_cart,
                        label: 'Órdenes',
                        value: '${customer.totalOrders} total',
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      );
    });
  }

  // ==================== COMPACT HELPER WIDGETS ====================

  Widget _buildCompactCardHeader(String title, IconData icon, LinearGradient gradient) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFinancialRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          Text(
            AppFormatters.formatCompactCurrency(value),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactActivityItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PROFILE CARDS ====================

  Widget _buildCustomerProfileCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;
      final isMobile = context.isMobile;

      return FuturisticContainer(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with animated gradient
                _buildAnimatedAvatar(customer, isMobile),
                SizedBox(width: isMobile ? 14 : 18),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.displayName,
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                      if (customer.companyName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 14,
                              color: ElegantLightTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                customer.companyName!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ElegantLightTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildStatusBadge(customer.status),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAnimatedAvatar(Customer customer, bool isMobile, {double? size}) {
    final avatarSize = size ?? (isMobile ? 70 : 80);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              gradient: customer.isActive
                  ? ElegantLightTheme.primaryGradient
                  : LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade500],
                    ),
              borderRadius: BorderRadius.circular(avatarSize / 2),
              boxShadow: [
                BoxShadow(
                  color: (customer.isActive
                          ? ElegantLightTheme.primaryBlue
                          : Colors.grey)
                      .withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              customer.companyName != null ? Icons.business : Icons.person,
              size: avatarSize * 0.5,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(CustomerStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: _getStatusGradient(status).scale(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(status).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(status).withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetricsRow(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;
      final isMobile = context.isMobile;

      return Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              'Límite Crédito',
              AppFormatters.formatCompactCurrency(customer.creditLimit),
              Icons.credit_card,
              ElegantLightTheme.primaryBlue,
              isMobile,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: _buildMetricCard(
              'Balance',
              AppFormatters.formatCompactCurrency(customer.currentBalance),
              Icons.account_balance_wallet,
              customer.currentBalance > 0
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
              isMobile,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: _buildMetricCard(
              'Órdenes',
              customer.totalOrders.toString(),
              Icons.shopping_cart,
              const Color(0xFF8B5CF6),
              isMobile,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isMobile,
  ) {
    return FuturisticContainer(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.03),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 22),
          ),
          SizedBox(height: isMobile ? 8 : 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return Opacity(
                opacity: animValue,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== INFO CARDS ====================

  Widget _buildPersonalInfoCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;

      return _buildInfoSection(
        title: 'Información Personal',
        icon: Icons.person,
        gradient: ElegantLightTheme.primaryGradient,
        children: [
          _buildInfoRow('Nombre Completo', '${customer.firstName} ${customer.lastName}', Icons.person_outline),
          _buildInfoRow('Tipo Documento', _getDocumentTypeLabel(customer.documentType), Icons.badge_outlined),
          _buildInfoRow('Número Documento', customer.documentNumber, Icons.numbers),
          if (customer.birthDate != null)
            _buildInfoRow('Fecha Nacimiento', _formatDate(customer.birthDate!), Icons.calendar_today_outlined),
          if (customer.companyName != null)
            _buildInfoRow('Empresa', customer.companyName!, Icons.business_outlined),
        ],
      );
    });
  }

  Widget _buildContactInfoCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;

      return _buildInfoSection(
        title: 'Información de Contacto',
        icon: Icons.contact_mail,
        gradient: ElegantLightTheme.infoGradient,
        children: [
          _buildInfoRow('Email', customer.email, Icons.email_outlined),
          if (customer.phone != null)
            _buildInfoRow('Teléfono', customer.phone!, Icons.phone_outlined),
          if (customer.mobile != null)
            _buildInfoRow('Móvil', customer.mobile!, Icons.phone_android_outlined),
          if (customer.address != null)
            _buildInfoRow('Dirección', customer.address!, Icons.location_on_outlined),
          if (customer.city != null)
            _buildInfoRow('Ciudad', customer.city!, Icons.location_city_outlined),
          if (customer.state != null)
            _buildInfoRow('Departamento', customer.state!, Icons.map_outlined),
          if (customer.zipCode != null)
            _buildInfoRow('Código Postal', customer.zipCode!, Icons.local_post_office_outlined),
        ],
      );
    });
  }

  Widget _buildFinancialCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;
      final creditAvailable = customer.creditLimit - customer.currentBalance;
      final creditUsagePercent = customer.creditLimit > 0
          ? (customer.currentBalance / customer.creditLimit).clamp(0.0, 1.0)
          : 0.0;

      return FuturisticContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Información Financiera',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Credit Usage Progress
            if (customer.creditLimit > 0) ...[
              _buildCreditUsageBar(creditUsagePercent, customer.currentBalance, creditAvailable),
              const SizedBox(height: 20),
            ],

            // Financial Details
            _buildFinancialRow('Límite de Crédito', customer.creditLimit, ElegantLightTheme.primaryBlue),
            const SizedBox(height: 12),
            _buildFinancialRow(
              'Balance Actual',
              customer.currentBalance,
              customer.currentBalance > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildFinancialRow(
              'Crédito Disponible',
              creditAvailable,
              creditAvailable > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            _buildInfoRowSimple('Términos de Pago', '${customer.paymentTerms} días', Icons.schedule),
            _buildInfoRowSimple('Total de Órdenes', '${customer.totalOrders}', Icons.shopping_cart_outlined),

            if (customer.notes != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.notes, size: 18, color: ElegantLightTheme.textSecondary),
                  const SizedBox(width: 8),
                  const Text(
                    'Notas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  customer.notes!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildCreditUsageBar(double percent, double used, double available) {
    final color = _getCreditUsageColor(percent);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Uso del Crédito',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: _getCreditUsageGradient(percent).scale(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percent),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return Container(
                height: 12,
                decoration: BoxDecoration(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    if (animValue > 0)
                      Flexible(
                        flex: (animValue * 100).round().clamp(1, 100),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.8)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (animValue < 1.0)
                      Flexible(
                        flex: ((1.0 - animValue) * 100).round().clamp(1, 100),
                        child: Container(),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usado: ${AppFormatters.formatCurrency(used)}',
                style: TextStyle(
                  fontSize: 12,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              Text(
                'Disponible: ${AppFormatters.formatCurrency(available)}',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, child) {
            return Text(
              AppFormatters.formatCurrency(animValue),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required List<Widget> children,
  }) {
    return FuturisticContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.7)),
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
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowSimple(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ElegantLightTheme.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SIDEBAR COMPONENTS ====================

  Widget _buildActionsCard(BuildContext context) {
    return FuturisticContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(Icons.flash_on, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Edit Button - Primary Action
          _buildElegantActionButton(
            icon: Icons.edit,
            label: 'Editar Cliente',
            description: 'Modificar información',
            gradient: ElegantLightTheme.primaryGradient,
            onTap: controller.goToEditCustomer,
          ),
          const SizedBox(height: 10),

          // Change Status Button
          Obx(() => _buildElegantActionButton(
            icon: Icons.toggle_on,
            label: controller.isUpdatingStatus ? 'Actualizando...' : 'Cambiar Estado',
            description: 'Activar, inactivar o suspender',
            gradient: ElegantLightTheme.infoGradient,
            onTap: controller.isUpdatingStatus ? null : controller.showStatusChangeDialog,
            isLoading: controller.isUpdatingStatus,
          )),
          const SizedBox(height: 10),

          // Verify Purchase Button
          _buildElegantActionButton(
            icon: Icons.credit_card,
            label: 'Verificar Compra',
            description: 'Comprobar capacidad de crédito',
            gradient: ElegantLightTheme.successGradient,
            onTap: controller.showPurchaseCheckDialog,
          ),

          const SizedBox(height: 16),

          // Divider with gradient
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Delete Button - Danger Action
          Obx(() => _buildElegantActionButton(
            icon: Icons.delete_outline,
            label: controller.isDeleting ? 'Eliminando...' : 'Eliminar Cliente',
            description: 'Eliminar permanentemente',
            gradient: ElegantLightTheme.errorGradient,
            onTap: controller.isDeleting ? null : controller.confirmDeleteCustomer,
            isLoading: controller.isDeleting,
            isDanger: true,
          )),
        ],
      ),
    );
  }

  Widget _buildElegantActionButton({
    required IconData icon,
    required String label,
    required String description,
    required LinearGradient gradient,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isDanger = false,
  }) {
    final isEnabled = onTap != null && !isLoading;
    final primaryColor = gradient.colors.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withValues(alpha: isEnabled ? 0.08 : 0.04),
                primaryColor.withValues(alpha: isEnabled ? 0.03 : 0.01),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryColor.withValues(alpha: isEnabled ? 0.25 : 0.1),
              width: 1,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Icon Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isEnabled ? gradient : null,
                  color: isEnabled ? null : primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isEnabled ? Colors.white : primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        size: 18,
                        color: isEnabled ? Colors.white : primaryColor.withValues(alpha: 0.5),
                      ),
              ),
              const SizedBox(width: 14),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isEnabled
                            ? (isDanger ? primaryColor : ElegantLightTheme.textPrimary)
                            : ElegantLightTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: isEnabled
                            ? ElegantLightTheme.textSecondary
                            : ElegantLightTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isEnabled ? 0.1 : 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: isEnabled ? primaryColor : primaryColor.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer;

      return FuturisticContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Actividad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (customer != null) ...[
              _buildActivityItem(
                icon: Icons.person_add,
                title: 'Registrado',
                subtitle: AppFormatters.formatDateTime(customer.createdAt),
                gradient: ElegantLightTheme.successGradient,
              ),
              if (customer.updatedAt != customer.createdAt) ...[
                const SizedBox(height: 10),
                _buildActivityItem(
                  icon: Icons.edit,
                  title: 'Actualizado',
                  subtitle: AppFormatters.formatDateTime(customer.updatedAt),
                  gradient: ElegantLightTheme.infoGradient,
                ),
              ],
              if (customer.totalOrders > 0) ...[
                const SizedBox(height: 10),
                _buildActivityItem(
                  icon: Icons.shopping_cart,
                  title: 'Compras',
                  subtitle: '${customer.totalOrders} órdenes registradas',
                  gradient: ElegantLightTheme.primaryGradient,
                ),
              ],
            ],
          ],
        ),
      );
    });
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient.scale(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: gradient.colors.first.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MOBILE FAB ====================

  Widget? _buildMobileFAB(BuildContext context) {
    if (!context.isMobile) return null;

    return FloatingActionButton(
      onPressed: controller.goToEditCustomer,
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
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  // ==================== ERROR STATE ====================

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: FuturisticContainer(
        width: 400,
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient.scale(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cliente no encontrado',
              style: TextStyle(
                fontSize: 20,
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El cliente que buscas no existe o ha sido eliminado',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Volver a Clientes',
              icon: Icons.arrow_back,
              onPressed: () => Get.offAllNamed('/customers'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'status':
        controller.showStatusChangeDialog();
        break;
      case 'purchase':
        controller.showPurchaseCheckDialog();
        break;
      case 'refresh':
        controller.refreshCustomer();
        break;
      case 'delete':
        controller.confirmDeleteCustomer();
        break;
    }
  }

  Color _getStatusColor(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return const Color(0xFF10B981);
      case CustomerStatus.inactive:
        return const Color(0xFFF59E0B);
      case CustomerStatus.suspended:
        return const Color(0xFFEF4444);
    }
  }

  LinearGradient _getStatusGradient(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return ElegantLightTheme.successGradient;
      case CustomerStatus.inactive:
        return ElegantLightTheme.warningGradient;
      case CustomerStatus.suspended:
        return ElegantLightTheme.errorGradient;
    }
  }

  String _getStatusLabel(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'ACTIVO';
      case CustomerStatus.inactive:
        return 'INACTIVO';
      case CustomerStatus.suspended:
        return 'SUSPENDIDO';
    }
  }

  String _getStatusDescription(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'Cliente habilitado para realizar compras';
      case CustomerStatus.inactive:
        return 'Cliente temporalmente inactivo';
      case CustomerStatus.suspended:
        return 'Cliente suspendido - No puede comprar';
    }
  }

  Color _getCreditUsageColor(double percent) {
    if (percent >= 0.9) return const Color(0xFFEF4444);
    if (percent >= 0.7) return const Color(0xFFF59E0B);
    if (percent >= 0.5) return const Color(0xFFF59E0B).withValues(alpha: 0.8);
    return const Color(0xFF10B981);
  }

  LinearGradient _getCreditUsageGradient(double percent) {
    if (percent >= 0.9) return ElegantLightTheme.errorGradient;
    if (percent >= 0.7) return ElegantLightTheme.warningGradient;
    return ElegantLightTheme.successGradient;
  }

  String _getDocumentTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.cc:
        return 'Cédula de Ciudadanía';
      case DocumentType.nit:
        return 'NIT';
      case DocumentType.ce:
        return 'Cédula de Extranjería';
      case DocumentType.passport:
        return 'Pasaporte';
      case DocumentType.other:
        return 'Otro';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
