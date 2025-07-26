// lib/features/settings/presentation/screens/settings_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';

class SettingsOverviewScreen extends StatelessWidget {
  const SettingsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: ResponsiveBuilder(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: AppDimensions.spacingLarge),
          _buildConfigurationGrid(1),
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
          _buildWelcomeCard(),
          const SizedBox(height: AppDimensions.spacingLarge),
          _buildConfigurationGrid(2),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: AppDimensions.spacingLarge),
          _buildConfigurationGrid(3),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Centro de Configuración',
                        style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Personaliza tu experiencia y configura el sistema según tus necesidades',
                        style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
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

  Widget _buildConfigurationGrid(int crossAxisCount) {
    final configurations = _getConfigurationItems();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppDimensions.spacingMedium,
        mainAxisSpacing: AppDimensions.spacingMedium,
        childAspectRatio: crossAxisCount == 1 ? 4.0 : 1.2,
      ),
      itemCount: configurations.length,
      itemBuilder: (context, index) {
        return _buildConfigurationCard(configurations[index]);
      },
    );
  }

  Widget _buildConfigurationCard(ConfigurationItem item) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => Get.toNamed(item.route),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              Text(
                item.title,
                style: Theme.of(Get.context!).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              Text(
                item.description,
                style: Theme.of(Get.context!).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.badge != null) ...[
                const SizedBox(height: AppDimensions.spacingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<ConfigurationItem> _getConfigurationItems() {
    return [
      ConfigurationItem(
        title: 'Organización',
        description: 'Configurar datos de la empresa y organización',
        icon: Icons.business,
        color: AppColors.primary,
        route: AppRoutes.settingsOrganization,
        badge: 'Nuevo',
      ),
      ConfigurationItem(
        title: 'Usuario',
        description: 'Perfil personal y preferencias de usuario',
        icon: Icons.person_outline,
        color: Colors.blue,
        route: AppRoutes.settingsUser,
      ),
      ConfigurationItem(
        title: 'Facturas',
        description: 'Configuración de facturación y numeración',
        icon: Icons.receipt_long_outlined,
        color: Colors.green,
        route: AppRoutes.settingsInvoice,
      ),
      ConfigurationItem(
        title: 'Impresoras',
        description: 'Configuración de impresoras y tickets',
        icon: Icons.print,
        color: Colors.purple,
        route: AppRoutes.settingsPrinter,
      ),
      ConfigurationItem(
        title: 'Aplicación',
        description: 'Configuración general del sistema',
        icon: Icons.tune,
        color: Colors.orange,
        route: AppRoutes.settingsApp,
      ),
      ConfigurationItem(
        title: 'Respaldos',
        description: 'Copias de seguridad y restauración',
        icon: Icons.backup,
        color: Colors.teal,
        route: AppRoutes.settingsBackup,
      ),
      ConfigurationItem(
        title: 'Seguridad',
        description: 'Configuración de seguridad y permisos',
        icon: Icons.security,
        color: Colors.red,
        route: AppRoutes.settingsSecurity,
      ),
      ConfigurationItem(
        title: 'Notificaciones',
        description: 'Gestión de alertas y notificaciones',
        icon: Icons.notifications_outlined,
        color: Colors.indigo,
        route: AppRoutes.settingsNotifications,
      ),
    ];
  }
}

class ConfigurationItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  final String? badge;

  ConfigurationItem({
    required this.title,
    required this.description, 
    required this.icon,
    required this.color,
    required this.route,
    this.badge,
  });
}