// lib/features/dashboard/presentation/widgets/quick_actions_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../app/core/navigation/cash_register_guard.dart';
import '../../../../app/core/navigation/navigation_guard.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';

class QuickActionsSection extends GetView<DashboardController> {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
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
          Text(
            'Acciones rápidas',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          ResponsiveBuilder(
            mobile: _buildMobileActions(),
            tablet: _buildTabletActions(),
            desktop: _buildDesktopActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildActionCard(
              title: 'Nueva Factura',
              icon: Icons.receipt_long,
              color: AppColors.primary,
              onTap: _openInvoiceForm,
            )),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(child: _buildActionCard(
              title: 'Nuevo Producto',
              icon: Icons.add_box,
              color: AppColors.success,
              onTap: () => AppNav.toNamed('/products/create'),
            )),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Row(
          children: [
            Expanded(child: _buildActionCard(
              title: 'Nuevo Cliente',
              icon: Icons.person_add,
              color: AppColors.info,
              onTap: () => AppNav.toNamed('/customers/create'),
            )),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(child: _buildActionCard(
              title: 'Nuevo Gasto',
              icon: Icons.money_off,
              color: AppColors.error,
              onTap: () => AppNav.toNamed('/expenses/create'),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletActions() {
    return Row(
      children: [
        Expanded(child: _buildActionCard(
          title: 'Nueva Factura',
          icon: Icons.receipt_long,
          color: AppColors.primary,
          onTap: _openInvoiceForm,
        )),
        const SizedBox(width: AppDimensions.spacingSmall),
        Expanded(child: _buildActionCard(
          title: 'Nuevo Producto',
          icon: Icons.add_box,
          color: AppColors.success,
          onTap: () => AppNav.toNamed('/products/create'),
        )),
        const SizedBox(width: AppDimensions.spacingSmall),
        Expanded(child: _buildActionCard(
          title: 'Nuevo Cliente',
          icon: Icons.person_add,
          color: AppColors.info,
          onTap: () => AppNav.toNamed('/customers/create'),
        )),
        const SizedBox(width: AppDimensions.spacingSmall),
        Expanded(child: _buildActionCard(
          title: 'Nuevo Gasto',
          icon: Icons.money_off,
          color: AppColors.error,
          onTap: () => AppNav.toNamed('/expenses/create'),
        )),
      ],
    );
  }

  Widget _buildDesktopActions() {
    return Row(
      children: [
        Expanded(child: _buildActionCard(
          title: 'Nueva Factura',
          subtitle: 'Crear factura de venta',
          icon: Icons.receipt_long,
          color: AppColors.primary,
          onTap: _openInvoiceForm,
        )),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(child: _buildActionCard(
          title: 'Nuevo Producto',
          subtitle: 'Agregar al inventario',
          icon: Icons.add_box,
          color: AppColors.success,
          onTap: () => AppNav.toNamed('/products/create'),
        )),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(child: _buildActionCard(
          title: 'Nuevo Cliente',
          subtitle: 'Registrar cliente',
          icon: Icons.person_add,
          color: AppColors.info,
          onTap: () => AppNav.toNamed('/customers/create'),
        )),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(child: _buildActionCard(
          title: 'Nuevo Gasto',
          subtitle: 'Registrar gasto',
          icon: Icons.money_off,
          color: AppColors.error,
          onTap: () => AppNav.toNamed('/expenses/create'),
        )),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(child: _buildActionCard(
          title: 'Reportes',
          subtitle: 'Ver estadísticas',
          icon: Icons.bar_chart,
          color: AppColors.warning,
          onTap: controller.navigateToReports,
        )),
      ],
    );
  }

  /// Apertura de "Nueva Factura" protegida por el guard de caja.
  /// Si la caja está cerrada, ofrece abrirla inline antes de navegar
  /// al form — así el usuario nunca empieza a agregar ítems en un
  /// contexto sin caja y termina perdiéndolos al ir a abrirla.
  Future<void> _openInvoiceForm() async {
    final ctx = Get.context;
    if (ctx == null) {
      AppNav.toNamed('/invoices/create');
      return;
    }
    final canProceed = await CashRegisterGuard.requireOpen(ctx);
    if (canProceed) AppNav.toNamed('/invoices/create');
  }

  Widget _buildActionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}