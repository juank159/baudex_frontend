//lib/features/settings/presentation/screens/user_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../controllers/user_preferences_controller.dart';

class UserPreferencesScreen extends StatelessWidget {
  const UserPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserPreferencesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias de Usuario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Configuraciones de Inventario
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Configuraciones de Inventario',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      context,
                      title: 'Descuento automático de inventario',
                      subtitle:
                          'Descuenta el stock automáticamente al crear facturas',
                      value: controller.autoDeductInventory,
                      onChanged: () => controller.toggleAutoDeductInventory(),
                      icon: Icons.remove_circle_outline,
                    ),
                    _buildSwitchTile(
                      context,
                      title: 'Usar costos FIFO',
                      subtitle: 'Calcular costos usando First In, First Out',
                      value: controller.useFifoCosting,
                      onChanged: () => controller.toggleUseFifoCosting(),
                      icon: Icons.timeline_outlined,
                    ),
                    _buildSwitchTile(
                      context,
                      title: 'Validar stock antes de facturar',
                      subtitle:
                          'Verificar disponibilidad antes de crear facturas',
                      value: controller.validateStockBeforeInvoice,
                      onChanged: () => controller.toggleValidateStockBeforeInvoice(),
                      icon: Icons.verified_outlined,
                    ),
                    _buildSwitchTile(
                      context,
                      title: 'Permitir sobreventa',
                      subtitle: 'Permitir ventas con stock negativo',
                      value: controller.allowOverselling,
                      onChanged: () => controller.toggleAllowOverselling(),
                      icon: Icons.warning_outlined,
                    ),
                    _buildSwitchTile(
                      context,
                      title: 'Mostrar alertas de stock',
                      subtitle: 'Alertas cuando el stock esté bajo',
                      value: controller.showStockWarnings,
                      onChanged: () => controller.toggleShowStockWarnings(),
                      icon: Icons.notification_important_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Configuraciones de Interfaz
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Configuraciones de Interfaz',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      context,
                      title: 'Mostrar confirmaciones',
                      subtitle: 'Confirmar acciones críticas antes de ejecutar',
                      value: controller.showConfirmationDialogs,
                      onChanged: () => controller.toggleShowConfirmationDialogs(),
                      icon: Icons.help_outline,
                    ),
                    _buildSwitchTile(
                      context,
                      title: 'Modo compacto',
                      subtitle: 'Usar vistas compactas en listas',
                      value: controller.useCompactMode,
                      onChanged: () => controller.toggleUseCompactMode(),
                      icon: Icons.compress_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Configuraciones de Notificaciones
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Configuraciones de Notificaciones',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      context,
                      title: 'Notificaciones de vencimiento',
                      subtitle: 'Alertas sobre productos próximos a vencer',
                      value: controller.enableExpiryNotifications,
                      onChanged: () => controller.toggleEnableExpiryNotifications(),
                      icon: Icons.schedule_outlined,
                    ),
                    _buildSwitchTile(
                      context,
                      title: 'Notificaciones de stock bajo',
                      subtitle: 'Alertas cuando el stock esté por agotarse',
                      value: controller.enableLowStockNotifications,
                      onChanged: () => controller.toggleEnableLowStockNotifications(),
                      icon: Icons.inventory_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuración por Usuario',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estas configuraciones son específicas para tu usuario y organización. Los cambios se aplican inmediatamente.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required Future<void> Function() onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: (_) async => await onChanged(),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
