// lib/features/customers/presentation/screens/customer_detail_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/customer_detail_controller.dart';
import '../../domain/entities/customer.dart';

class CustomerDetailScreen extends GetView<CustomerDetailController> {
  const CustomerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
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
      title: Obx(
        () => Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person,
                size: isMobile ? 18 : 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                controller.hasCustomer
                    ? controller.customer!.displayName
                    : 'Detalles del Cliente',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 16 : 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Get.offAllNamed(AppRoutes.customers);
        },
      ),
      actions: [
        // Editar
        if (controller.hasCustomer)
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: controller.goToEditCustomer,
            tooltip: 'Editar cliente',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
            ),
          ),

        // Menú de opciones
        if (controller.hasCustomer)
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
                value: 'status',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.toggle_on,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cambiar Estado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'purchase',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.successGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Verificar Compra',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        size: 18,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Actualizar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.errorGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Eliminar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
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
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        children: [
          _buildCustomerHeader(context),
          SizedBox(height: context.verticalSpacing),
          _buildPersonalInfoCard(context),
          SizedBox(height: context.verticalSpacing),
          _buildContactInfoCard(context),
          SizedBox(height: context.verticalSpacing),
          _buildFinancialInfoCard(context),
          SizedBox(height: context.verticalSpacing),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: AdaptiveContainer(
        maxWidth: 800,
        child: Column(
          children: [
            SizedBox(height: context.verticalSpacing),
            _buildCustomerHeader(context),
            SizedBox(height: context.verticalSpacing * 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildPersonalInfoCard(context),
                      SizedBox(height: context.verticalSpacing),
                      _buildContactInfoCard(context),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildFinancialInfoCard(context),
                      SizedBox(height: context.verticalSpacing),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información principal
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  _buildCustomerHeader(context),
                  const SizedBox(height: 32),
                  _buildPersonalInfoCard(context),
                  const SizedBox(height: 24),
                  _buildContactInfoCard(context),
                ],
              ),
            ),
          ),

          // Panel lateral
          Container(
            width: 400,
            padding: const EdgeInsets.fromLTRB(0, 32, 32, 32),
            child: Column(
              children: [
                _buildFinancialInfoCard(context),
                const SizedBox(height: 24),
                _buildActionButtons(context),
                const SizedBox(height: 24),
                _buildActivityCard(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerHeader(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;

      return CustomCard(
        child: Column(
          children: [
            Row(
              children: [
                // Avatar del cliente con gradiente
                Container(
                  width: context.isMobile ? 80 : 100,
                  height: context.isMobile ? 80 : 100,
                  decoration: BoxDecoration(
                    gradient: customer.isActive
                        ? ElegantLightTheme.primaryGradient
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade400,
                              Colors.grey.shade300,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(
                      context.isMobile ? 40 : 50,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (customer.isActive
                                ? ElegantLightTheme.primaryBlue
                                : Colors.grey)
                            .withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    customer.companyName != null
                        ? Icons.business
                        : Icons.person,
                    size: context.isMobile ? 40 : 50,
                    color: Colors.white,
                  ),
                ),

                SizedBox(width: context.horizontalSpacing),

                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.displayName,
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 24,
                            tablet: 28,
                            desktop: 32,
                          ),
                          fontWeight: FontWeight.bold,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (customer.companyName != null) ...[
                        Text(
                          customer.companyName!,
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(
                              context,
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                            color: ElegantLightTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      Text(
                        customer.email,
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context),
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Estado del cliente con gradiente
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: _getStatusGradient(customer.status).scale(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getStatusColor(customer.status)
                                .withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(customer.status)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _getStatusLabel(customer.status),
                          style: TextStyle(
                            color: _getStatusColor(customer.status),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (!context.isMobile) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Métricas rápidas
              Row(
                children: [
                  Expanded(
                    child: _buildQuickMetric(
                      context,
                      'Límite de Crédito',
                      controller.formatCurrency(customer.creditLimit),
                      Icons.credit_card,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickMetric(
                      context,
                      'Balance Actual',
                      controller.formatCurrency(customer.currentBalance),
                      Icons.account_balance_wallet,
                      customer.currentBalance > 0
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickMetric(
                      context,
                      'Total Órdenes',
                      customer.totalOrders.toString(),
                      Icons.shopping_cart,
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildQuickMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final gradient = color == ElegantLightTheme.primaryBlue ||
            color == Theme.of(context).primaryColor
        ? ElegantLightTheme.primaryGradient
        : color == ElegantLightTheme.accentOrange || color == Colors.orange
            ? ElegantLightTheme.warningGradient
            : ElegantLightTheme.successGradient;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: gradient.scale(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: ElegantLightTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;

      return CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient.scale(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: ElegantLightTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildInfoRow(
              context,
              'Nombre Completo',
              '${customer.firstName} ${customer.lastName}',
              Icons.person,
            ),

            _buildInfoRow(
              context,
              'Tipo de Documento',
              _getDocumentTypeLabel(customer.documentType),
              Icons.badge,
            ),

            _buildInfoRow(
              context,
              'Número de Documento',
              customer.documentNumber,
              Icons.numbers,
            ),

            if (customer.birthDate != null)
              _buildInfoRow(
                context,
                'Fecha de Nacimiento',
                _formatDate(customer.birthDate!),
                Icons.calendar_today,
              ),

            if (customer.companyName != null)
              _buildInfoRow(
                context,
                'Empresa',
                customer.companyName!,
                Icons.business,
              ),
          ],
        ),
      );
    });
  }

  Widget _buildContactInfoCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;

      return CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de Contacto',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 20),

            _buildInfoRow(context, 'Email', customer.email, Icons.email),

            if (customer.phone != null)
              _buildInfoRow(context, 'Teléfono', customer.phone!, Icons.phone),

            if (customer.mobile != null)
              _buildInfoRow(
                context,
                'Móvil',
                customer.mobile!,
                Icons.phone_android,
              ),

            if (customer.address != null)
              _buildInfoRow(
                context,
                'Dirección',
                customer.address!,
                Icons.location_on,
              ),

            if (customer.city != null)
              _buildInfoRow(
                context,
                'Ciudad',
                customer.city!,
                Icons.location_city,
              ),

            if (customer.state != null)
              _buildInfoRow(
                context,
                'Departamento',
                customer.state!,
                Icons.map,
              ),

            if (customer.zipCode != null)
              _buildInfoRow(
                context,
                'Código Postal',
                customer.zipCode!,
                Icons.local_post_office,
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFinancialInfoCard(BuildContext context) {
    return Obx(() {
      final customer = controller.customer!;

      return CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Financiera',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 20),

            _buildInfoRow(
              context,
              'Límite de Crédito',
              controller.formatCurrency(customer.creditLimit),
              Icons.credit_card,
            ),

            _buildInfoRow(
              context,
              'Balance Actual',
              controller.formatCurrency(customer.currentBalance),
              Icons.account_balance_wallet,
              valueColor:
                  customer.currentBalance > 0 ? Colors.orange : Colors.green,
            ),

            _buildInfoRow(
              context,
              'Crédito Disponible',
              controller.formatCurrency(
                customer.creditLimit - customer.currentBalance,
              ),
              Icons.monetization_on,
              valueColor: Colors.green,
            ),

            _buildInfoRow(
              context,
              'Términos de Pago',
              '${customer.paymentTerms} días',
              Icons.schedule,
            ),

            _buildInfoRow(
              context,
              'Total de Órdenes',
              customer.totalOrders.toString(),
              Icons.shopping_cart,
            ),

            if (customer.notes != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Notas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customer.notes!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildActivityCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad Reciente',
            style: TextStyle(
              fontSize: Responsive.getFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(height: 20),

          // Placeholder para actividad reciente
          Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Historial de actividad',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  'Próximamente',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey.shade800,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          Text(
            'Acciones',
            style: TextStyle(
              fontSize: Responsive.getFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(height: 20),

          // Botón de editar
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Editar Cliente',
              icon: Icons.edit,
              onPressed: controller.goToEditCustomer,
            ),
          ),

          const SizedBox(height: 12),

          // Botón de cambiar estado
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => CustomButton(
                text:
                    controller.isUpdatingStatus
                        ? 'Actualizando...'
                        : 'Cambiar Estado',
                icon: Icons.toggle_on,
                type: ButtonType.outline,
                onPressed:
                    controller.isUpdatingStatus
                        ? null
                        : controller.showStatusChangeDialog,
                isLoading: controller.isUpdatingStatus,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botón de verificar compra
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Verificar Compra',
              icon: Icons.credit_card,
              type: ButtonType.outline,
              onPressed: controller.showPurchaseCheckDialog,
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Botón de eliminar
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => CustomButton(
                text:
                    controller.isDeleting
                        ? 'Eliminando...'
                        : 'Eliminar Cliente',
                icon: Icons.delete,
                backgroundColor: Colors.red,
                onPressed:
                    controller.isDeleting
                        ? null
                        : controller.confirmDeleteCustomer,
                isLoading: controller.isDeleting,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 100, color: Colors.grey.shade400),
          SizedBox(height: context.verticalSpacing),
          Text(
            'Cliente no encontrado',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.verticalSpacing / 2),
          Text(
            'El cliente que buscas no existe o ha sido eliminado',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.verticalSpacing * 2),
          CustomButton(
            text: 'Volver a Clientes',
            icon: Icons.arrow_back,
            onPressed: () => Get.offAllNamed('/customers'),
          ),
        ],
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
        return Colors.green.shade600;
      case CustomerStatus.inactive:
        return ElegantLightTheme.accentOrange;
      case CustomerStatus.suspended:
        return Colors.red.shade600;
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
