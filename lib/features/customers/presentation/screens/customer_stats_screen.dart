// lib/features/customers/presentation/screens/customer_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/customer_stats_controller.dart';
import '../widgets/customer_stats_widget.dart';
import '../../domain/entities/customer_stats.dart';

class CustomerStatsScreen extends GetView<CustomerStatsController> {
  const CustomerStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget(message: 'Cargando estadísticas...');
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        );
      }),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Estadísticas de Clientes'),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      actions: [
        // Periodo de tiempo
        Obx(
          () => TextButton.icon(
            onPressed: () => _showPeriodSelector(context),
            icon: const Icon(Icons.calendar_today),
            label: Text(controller.currentPeriodLabel),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ),

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshStats,
        ),

        // Menú de opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Exportar Reporte'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Compartir'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 8),
                      Text('Imprimir'),
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
              color: Colors.grey.shade50,
              border: Border(left: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // Header del panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Panel de Control',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
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
        return const CustomCard(
          child: SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      return CustomerStatsWidget(stats: controller.stats!, isCompact: false);
    });
  }

  Widget _buildStatusStatsCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Distribución por Estado',
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

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
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
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildFinancialStatsCard(BuildContext context) {
  //   return CustomCard(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(
  //               Icons.attach_money,
  //               color: Theme.of(context).primaryColor,
  //               size: 24,
  //             ),
  //             const SizedBox(width: 8),
  //             Text(
  //               'Estadísticas Financieras',
  //               style: TextStyle(
  //                 fontSize: Responsive.getFontSize(
  //                   context,
  //                   mobile: 18,
  //                   tablet: 20,
  //                   desktop: 22,
  //                 ),
  //                 fontWeight: FontWeight.bold,
  //                 color: Theme.of(context).primaryColor,
  //               ),
  //             ),
  //           ],
  //         ),

  //         const SizedBox(height: 20),

  //         Obx(() {
  //           if (controller.stats == null) {
  //             return const Center(child: CircularProgressIndicator());
  //           }

  //           final stats = controller.stats!;
  //           return Column(
  //             children: [
  //               _buildFinancialItem(
  //                 context,
  //                 'Límite de Crédito Total',
  //                 _formatCurrency(stats.totalCreditLimit),
  //                 Icons.credit_card,
  //                 Colors.blue,
  //               ),
  //               const SizedBox(height: 16),
  //               _buildFinancialItem(
  //                 context,
  //                 'Balance Pendiente Total',
  //                 _formatCurrency(stats.totalBalance),
  //                 Icons.account_balance,
  //                 Colors.purple,
  //               ),
  //               const SizedBox(height: 16),
  //               _buildFinancialItem(
  //                 context,
  //                 'Promedio de Compra',
  //                 _formatCurrency(stats.averagePurchaseAmount),
  //                 Icons.shopping_cart,
  //                 Colors.teal,
  //               ),
  //               if (stats.customersWithOverdue > 0) ...[
  //                 const SizedBox(height: 16),
  //                 _buildFinancialItem(
  //                   context,
  //                   'Clientes con Deuda Vencida',
  //                   '${stats.customersWithOverdue}',
  //                   Icons.warning,
  //                   Colors.red,
  //                 ),
  //               ],
  //             ],
  //           );
  //         }),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildFinancialStatsCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Estadísticas Financieras',
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
                // ✅ FIX: Solo mostrar si existe el campo y es mayor a 0
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
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
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.badge,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Tipos de Documento',
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          '$count (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStatsCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
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

  // Widget _buildTopCustomersCard(BuildContext context) {
  //   return CustomCard(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Icon(Icons.star, color: Theme.of(context).primaryColor, size: 24),
  //             const SizedBox(width: 8),
  //             Text(
  //               'Top Clientes',
  //               style: TextStyle(
  //                 fontSize: Responsive.getFontSize(
  //                   context,
  //                   mobile: 18,
  //                   tablet: 20,
  //                   desktop: 22,
  //                 ),
  //                 fontWeight: FontWeight.bold,
  //                 color: Theme.of(context).primaryColor,
  //               ),
  //             ),
  //           ],
  //         ),

  //         const SizedBox(height: 20),

  //         Obx(() {
  //           if (controller.topCustomers.isEmpty) {
  //             return Center(
  //               child: Column(
  //                 children: [
  //                   Icon(
  //                     Icons.people_outline,
  //                     size: 48,
  //                     color: Colors.grey.shade400,
  //                   ),
  //                   const SizedBox(height: 12),
  //                   Text(
  //                     'Cargando top clientes...',
  //                     style: TextStyle(
  //                       color: Colors.grey.shade600,
  //                       fontSize: 14,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }

  //           return Column(
  //             children:
  //                 controller.topCustomers.asMap().entries.map((entry) {
  //                   final index = entry.key;
  //                   final customer = entry.value;

  //                   return Padding(
  //                     padding: const EdgeInsets.only(bottom: 12),
  //                     child: _buildTopCustomerItem(
  //                       context,
  //                       index + 1,
  //                       customer['name'] as String,
  //                       customer['totalPurchases'] as double,
  //                       customer['totalOrders'] as int,
  //                     ),
  //                   );
  //                 }).toList(),
  //           );
  //         }),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTopCustomersCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Theme.of(context).primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Top Clientes',
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
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay clientes disponibles',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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

                    // ✅ FIX: Extraer datos con valores por defecto seguros
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

  // Widget _buildTopCustomerItem(
  //   BuildContext context,
  //   int position,
  //   String name,
  //   double totalPurchases,
  //   int totalOrders,
  // ) {
  //   Color positionColor;
  //   IconData positionIcon;

  //   switch (position) {
  //     case 1:
  //       positionColor = Colors.amber;
  //       positionIcon = Icons.looks_one;
  //       break;
  //     case 2:
  //       positionColor = Colors.grey;
  //       positionIcon = Icons.looks_two;
  //       break;
  //     case 3:
  //       positionColor = Colors.brown;
  //       positionIcon = Icons.looks_3;
  //       break;
  //     default:
  //       positionColor = Theme.of(context).primaryColor;
  //       positionIcon = Icons.person;
  //   }

  //   return Container(
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: positionColor.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: positionColor.withOpacity(0.3)),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(6),
  //           decoration: BoxDecoration(
  //             color: positionColor,
  //             borderRadius: BorderRadius.circular(6),
  //           ),
  //           child: Icon(positionIcon, color: Colors.white, size: 16),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 name,
  //                 style: const TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //                 maxLines: 1,
  //                 overflow: TextOverflow.ellipsis,
  //               ),
  //               Text(
  //                 '${_formatCurrency(totalPurchases)} • $totalOrders órdenes',
  //                 style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTopCustomerItem(
    BuildContext context,
    int position,
    String name,
    double totalPurchases,
    int totalOrders,
  ) {
    Color positionColor;
    IconData positionIcon;

    switch (position) {
      case 1:
        positionColor = Colors.amber;
        positionIcon = Icons.looks_one;
        break;
      case 2:
        positionColor = Colors.grey;
        positionIcon = Icons.looks_two;
        break;
      case 3:
        positionColor = Colors.brown;
        positionIcon = Icons.looks_3;
        break;
      default:
        positionColor = Theme.of(context).primaryColor;
        positionIcon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: positionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: positionColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: positionColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(positionIcon, color: Colors.white, size: 16),
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
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  // ✅ FIX: Mostrar información más clara y amigable
                  totalPurchases > 0
                      ? '${_formatCurrency(totalPurchases)} • $totalOrders órdenes'
                      : 'Sin compras registradas',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        totalPurchases > 0
                            ? Colors.grey.shade600
                            : Colors.orange.shade600,
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
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Ver Todos los Clientes',
              icon: Icons.people,
              onPressed: controller.goToCustomersList,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Nuevo Cliente',
              icon: Icons.person_add,
              type: ButtonType.outline,
              onPressed: controller.goToCreateCustomer,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Exportar Reporte',
              icon: Icons.download,
              type: ButtonType.outline,
              onPressed: () => _showExportDialog(context),
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
        child: const Icon(Icons.refresh),
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
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Seleccionar Período',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),

            // Options
            ...controller.availablePeriods.map((period) {
              return ListTile(
                title: Text(
                  period['label'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                trailing: Obx(() {
                  return controller.currentPeriod == period['value']
                      ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                      : const SizedBox.shrink();
                }),
                onTap: () {
                  controller.changePeriod(period['value'] as String);
                  Get.back();
                },
              );
            }).toList(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Exportar Reporte'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecciona el formato de exportación:'),
            SizedBox(height: 16),
            Text('Funcionalidad pendiente de implementar'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.exportToCsv();
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Compartir Estadísticas'),
        content: const Text('Funcionalidad pendiente de implementar'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showPrintDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Imprimir Reporte'),
        content: const Text('Funcionalidad pendiente de implementar'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  // String _formatCurrency(double amount) {
  //   if (amount >= 1000000) {
  //     return '\${(amount / 1000000).toStringAsFixed(1)}M';
  //   } else if (amount >= 1000) {
  //     return '\${(amount / 1000).toStringAsFixed(1)}K';
  //   } else {
  //     return '\${amount.toStringAsFixed(0)}';
  //   }
  // }

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
