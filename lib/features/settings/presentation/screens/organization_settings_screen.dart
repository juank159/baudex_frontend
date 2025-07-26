// lib/features/settings/presentation/screens/organization_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/shared/widgets/loading_overlay.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';
import '../controllers/organization_controller.dart';
import '../widgets/create_organization_dialog.dart';
import '../widgets/edit_organization_dialog.dart';

class OrganizationSettingsScreen extends GetView<OrganizationController> {
  const OrganizationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuración de Organización'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ResponsiveBuilder(
            mobile: _buildMobileLayout(),
            tablet: _buildTabletLayout(),
            desktop: _buildDesktopLayout(),
          ),
          Obx(
            () => LoadingOverlay(
              isLoading: controller.isLoading,
              message: 'Cargando configuración...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentOrganizationCard(),
          const SizedBox(height: AppDimensions.spacingLarge),
          _buildCreateOrganizationCard(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentOrganizationCard(),
          const SizedBox(height: AppDimensions.spacingLarge),
          _buildCreateOrganizationCard(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: _buildCurrentOrganizationCard()),
          const SizedBox(width: AppDimensions.spacingLarge),
          Expanded(flex: 1, child: _buildCreateOrganizationCard()),
        ],
      ),
    );
  }

  Widget _buildCurrentOrganizationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: AppColors.primary, size: 24),
                const SizedBox(width: AppDimensions.spacingSmall),
                Text(
                  'Organización Actual',
                  style: Theme.of(
                    Get.context!,
                  ).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Obx(() {
              final organization = controller.currentOrganization;
              if (organization == null) {
                return _buildNoOrganizationWidget();
              }
              return _buildOrganizationDetails(organization);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOrganizationWidget() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 48,
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              Text(
                'Sin Organización',
                style: Theme.of(Get.context!).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              Text(
                'Tu usuario no tiene una organización asignada. Esto puede causar problemas de acceso.',
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.loadCurrentOrganization,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizationDetails(organization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de suscripción
        _buildSubscriptionCard(organization),
        const SizedBox(height: AppDimensions.spacingLarge),
        
        // Detalles de organización
        Text(
          'Detalles de la Organización',
          style: Theme.of(Get.context!).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        
        _buildDetailRow('Nombre', organization.name),
        _buildDetailRow('Slug', organization.slug),
        _buildDetailRow('Moneda', organization.currency),
        _buildDetailRow('Idioma', organization.locale),
        _buildDetailRow('Zona Horaria', organization.timezone),
        _buildDetailRow(
          'Estado',
          organization.isActive ? 'Activa' : 'Inactiva',
        ),
        if (organization.domain != null)
          _buildDetailRow('Dominio', organization.domain!),
        const SizedBox(height: AppDimensions.spacingMedium),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showEditOrganizationDialog(organization),
            icon: const Icon(Icons.edit),
            label: const Text('Editar Organización'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(Get.context!).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateOrganizationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_business, color: AppColors.success, size: 24),
                const SizedBox(width: AppDimensions.spacingSmall),
                Text(
                  'Crear Nueva Organización',
                  style: Theme.of(
                    Get.context!,
                  ).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Text(
              'Crea una nueva organización para gestionar un negocio diferente.',
              style: Theme.of(Get.context!).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.spacingLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCreateOrganizationDialog,
                icon: const Icon(Icons.add),
                label: const Text('Crear Organización'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOrganizationDialog() {
    Get.dialog(const CreateOrganizationDialog());
  }

  Widget _buildSubscriptionCard(organization) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getSubscriptionColor(organization.subscriptionPlan),
            _getSubscriptionColor(organization.subscriptionPlan).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSubscriptionIcon(organization.subscriptionPlan),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: AppDimensions.spacingSmall),
              Text(
                'Plan ${organization.subscriptionPlan.displayName}',
                style: Theme.of(Get.context!).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Text(
                  organization.subscriptionStatus.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          
          // Barra de progreso
          _buildSubscriptionProgress(organization),
          
          const SizedBox(height: AppDimensions.spacingMedium),
          
          // Información de fechas
          Row(
            children: [
              Expanded(
                child: _buildSubscriptionInfo(
                  'Días restantes',
                  '${organization.remainingDays}',
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              Expanded(
                child: _buildSubscriptionInfo(
                  organization.isTrialPlan ? 'Fecha fin trial' : 'Renovación',
                  _formatDate(organization.isTrialPlan 
                    ? organization.trialEndDate 
                    : organization.subscriptionEndDate),
                  Icons.event,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionProgress(organization) {
    final progress = organization.subscriptionProgress;
    final remainingDays = organization.remainingDays;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              organization.isTrialPlan ? 'Progreso del trial' : 'Progreso de suscripción',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              remainingDays <= 3 
                ? Colors.red.shade300
                : remainingDays <= 7
                  ? Colors.orange.shade300
                  : Colors.white,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionInfo(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Color _getSubscriptionColor(subscriptionPlan) {
    switch (subscriptionPlan.toString()) {
      case 'SubscriptionPlan.trial':
        return Colors.orange;
      case 'SubscriptionPlan.basic':
        return Colors.blue;
      case 'SubscriptionPlan.premium':
        return Colors.purple;
      case 'SubscriptionPlan.enterprise':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSubscriptionIcon(subscriptionPlan) {
    switch (subscriptionPlan.toString()) {
      case 'SubscriptionPlan.trial':
        return Icons.access_time;
      case 'SubscriptionPlan.basic':
        return Icons.business;
      case 'SubscriptionPlan.premium':
        return Icons.star;
      case 'SubscriptionPlan.enterprise':
        return Icons.corporate_fare;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditOrganizationDialog(organization) {
    Get.dialog(EditOrganizationDialog(organization: organization));
  }
}
