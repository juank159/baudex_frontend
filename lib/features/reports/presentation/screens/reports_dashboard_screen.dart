// lib/features/reports/presentation/screens/reports_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            _buildWelcomeSection(),

            const SizedBox(height: 32),

            // Profitability Reports Section
            _buildReportSection(
              title: 'Reportes de Rentabilidad',
              subtitle:
                  'Análisis de márgenes y ganancias por producto y categoría',
              icon: Icons.trending_up,
              color: Colors.green,
              reports: [
                {
                  'title': 'Rentabilidad por Productos',
                  'subtitle': 'Análisis detallado de ganancia por producto',
                  'icon': Icons.inventory_2,
                  'onTap': () => Get.toNamed('/reports/profitability/products'),
                },
                {
                  'title': 'Rentabilidad por Categorías',
                  'subtitle': 'Comparación de márgenes entre categorías',
                  'icon': Icons.category,
                  'onTap':
                      () => Get.toNamed('/reports/profitability/categories'),
                },
                {
                  'title': 'Top Productos Rentables',
                  'subtitle': 'Los productos con mayor margen de ganancia',
                  'icon': Icons.star,
                  'onTap': () => Get.toNamed('/reports/profitability/top'),
                },
              ],
            ),

            const SizedBox(height: 32),

            // Inventory Valuation Reports Section
            _buildReportSection(
              title: 'Reportes de Valoración',
              subtitle:
                  'Valoración de inventario con diferentes métodos (FIFO, LIFO, Promedio)',
              icon: Icons.account_balance_wallet,
              color: Colors.blue,
              reports: [
                {
                  'title': 'Resumen de Valoración',
                  'subtitle': 'Vista general del valor total del inventario',
                  'icon': Icons.analytics,
                  'onTap': () => Get.toNamed('/reports/valuation/summary'),
                },
                {
                  'title': 'Valoración por Productos',
                  'subtitle': 'Detalle de valoración FIFO por producto',
                  'icon': Icons.list_alt,
                  'onTap': () => Get.toNamed('/reports/valuation/products'),
                },
                {
                  'title': 'Valoración por Categorías',
                  'subtitle': 'Comparación de valores entre categorías',
                  'icon': Icons.pie_chart,
                  'onTap': () => Get.toNamed('/reports/valuation/categories'),
                },
              ],
            ),

            const SizedBox(height: 32),

            // Inventory Reports Section
            _buildReportSection(
              title: 'Reportes de Inventario',
              subtitle: 'Análisis avanzados de movimientos, kardex y rotación',
              icon: Icons.inventory,
              color: Colors.orange,
              reports: [
                {
                  'title': 'Kardex Multi-Producto',
                  'subtitle': 'Kardex comparativo de múltiples productos',
                  'icon': Icons.timeline,
                  'onTap': () => Get.toNamed('/reports/kardex/multi-product'),
                },
                {
                  'title': 'Resumen de Movimientos',
                  'subtitle': 'Estadísticas de entradas y salidas por período',
                  'icon': Icons.swap_horiz,
                  'onTap': () => Get.toNamed('/reports/movements/summary'),
                },
                {
                  'title': 'Antigüedad de Inventario',
                  'subtitle': 'Análisis de productos por tiempo en stock',
                  'icon': Icons.schedule,
                  'onTap': () => Get.toNamed('/reports/inventory/aging'),
                },
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, size: 48, color: AppColors.primary),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centro de Reportes Avanzados',
                  style: Get.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Análisis detallados de rentabilidad, valoración de inventario y tendencias de negocio.',
                  style: Get.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> reports,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(
              title: report['title'],
              subtitle: report['subtitle'],
              icon: report['icon'],
              onTap: report['onTap'],
            );
          },
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 24),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: Get.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: 'Exportar Todo',
                subtitle: 'Descargar todos los reportes',
                icon: Icons.download,
                color: Colors.blue,
                onTap: () => _showExportDialog(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                title: 'Programar Reportes',
                subtitle: 'Automatizar generación',
                icon: Icons.schedule_send,
                color: Colors.purple,
                onTap:
                    () => Get.snackbar(
                      'Programar',
                      'Funcionalidad en desarrollo',
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                title: 'Configurar Alertas',
                subtitle: 'Notificaciones automáticas',
                icon: Icons.notifications_active,
                color: Colors.orange,
                onTap:
                    () =>
                        Get.snackbar('Alertas', 'Funcionalidad en desarrollo'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Exportar Reportes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Reporte Completo PDF'),
              subtitle: const Text('Todos los análisis en un documento'),
              onTap: () {
                Get.back();
                Get.snackbar('Exportar', 'Generando reporte PDF...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Datos en Excel'),
              subtitle: const Text('Datos tabulares para análisis externo'),
              onTap: () {
                Get.back();
                Get.snackbar('Exportar', 'Generando archivo Excel...');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Centro de Reportes'),
      actions: [
        IconButton(
          onPressed:
              () => Get.snackbar(
                'Ayuda',
                'Documentación de reportes disponible próximamente',
              ),
          icon: const Icon(Icons.help_outline),
          tooltip: 'Ayuda',
        ),
      ],
    );
  }
}
