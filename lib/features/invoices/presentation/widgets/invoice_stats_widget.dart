// lib/features/invoices/presentation/widgets/invoice_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/invoice_stats_controller.dart';
import '../../domain/entities/invoice.dart';

class InvoiceStatsWidget extends StatelessWidget {
  final bool isCompact;
  final bool showHeader;

  const InvoiceStatsWidget({
    super.key,
    this.isCompact = false,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InvoiceStatsController>(
      builder: (controller) {
        if (controller.isLoading) {
          return LoadingWidget(
            message: 'Cargando estadísticas...',
            size: isCompact ? 30 : null,
          );
        }

        if (!controller.hasStats) {
          return _buildErrorState(context);
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(context, controller),
          tablet: _buildTabletLayout(context, controller),
          desktop: _buildDesktopLayout(context, controller),
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    if (isCompact) {
      return _buildCompactStats(context, controller);
    }

    return Column(
      children: [
        if (showHeader) _buildHeader(context, controller),
        _buildOverviewCards(context, controller),
        const SizedBox(height: 16),
        _buildHealthIndicator(context, controller),
        const SizedBox(height: 16),
        _buildDetailedStats(context, controller),
        if (controller.hasOverdueInvoices) ...[
          const SizedBox(height: 16),
          _buildOverdueSection(context, controller),
        ],
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return Column(
      children: [
        if (showHeader) _buildHeader(context, controller),
        Row(
          children: [
            Expanded(child: _buildOverviewCards(context, controller)),
            const SizedBox(width: 16),
            Expanded(child: _buildHealthIndicator(context, controller)),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailedStats(context, controller),
        if (controller.hasOverdueInvoices) ...[
          const SizedBox(height: 16),
          _buildOverdueSection(context, controller),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return Column(
      children: [
        if (showHeader) _buildHeader(context, controller),
        Row(
          children: [
            Expanded(flex: 2, child: _buildOverviewCards(context, controller)),
            const SizedBox(width: 16),
            Expanded(child: _buildHealthIndicator(context, controller)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildDetailedStats(context, controller)),
            if (controller.hasOverdueInvoices) ...[
              const SizedBox(width: 16),
              Expanded(child: _buildOverdueSection(context, controller)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, InvoiceStatsController controller) {
    return Row(
      children: [
        Icon(Icons.analytics, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(width: 8),
        Text(
          'Estadísticas de Facturas',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshAllData,
          tooltip: 'Actualizar',
        ),
      ],
    );
  }

  Widget _buildCompactStats(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            controller.totalInvoices.toString(),
            Icons.receipt,
            Colors.blue,
            context,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Pendientes',
            controller.pendingInvoices.toString(),
            Icons.schedule,
            Colors.orange,
            context,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Vencidas',
            controller.overdueCount.toString(),
            Icons.warning,
            Colors.red,
            context,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return GridView.count(
      crossAxisCount: context.isMobile ? 2 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: context.isMobile ? 1.2 : 1.5,
      children: [
        _buildStatCard(
          'Total Facturas',
          controller.totalInvoices.toString(),
          Icons.receipt_long,
          Colors.blue,
          context,
        ),
        _buildStatCard(
          'Pagadas',
          controller.paidInvoices.toString(),
          Icons.check_circle,
          Colors.green,
          context,
          subtitle: '${controller.paidPercentage.toStringAsFixed(1)}%',
        ),
        _buildStatCard(
          'Pendientes',
          controller.pendingInvoices.toString(),
          Icons.schedule,
          Colors.orange,
          context,
          subtitle: '${controller.pendingPercentage.toStringAsFixed(1)}%',
        ),
        _buildStatCard(
          'Vencidas',
          controller.overdueCount.toString(),
          Icons.error,
          Colors.red,
          context,
          subtitle: '${controller.overduePercentage.toStringAsFixed(1)}%',
        ),
        _buildStatCard(
          'Borradores',
          controller.draftInvoices.toString(),
          Icons.edit,
          Colors.grey,
          context,
        ),
        _buildStatCard(
          'Total Ventas',
          '\$${_formatCurrency(controller.totalSales)}',
          Icons.attach_money,
          Colors.purple,
          context,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return CustomCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.isMobile ? 18 : 20,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: context.isMobile ? 12 : 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  controller.getHealthIcon(),
                  color: controller.getHealthColor(),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado Financiero',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        controller.getHealthMessage(),
                        style: TextStyle(
                          color: controller.getHealthColor(),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildIndicatorRow(
              'Tasa de Cobro',
              controller.collectionRate,
              '%',
              85,
              controller.collectionRate >= 85,
            ),
            const SizedBox(height: 8),
            _buildIndicatorRow(
              'Facturas Vencidas',
              controller.overduePercentage,
              '%',
              5,
              controller.overduePercentage <= 5,
              isInverted: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorRow(
    String label,
    double value,
    String unit,
    double target,
    bool isGood, {
    bool isInverted = false,
  }) {
    final progress =
        isInverted
            ? (target - value).clamp(0, target) / target
            : (value / target).clamp(0, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isGood ? Colors.green.shade600 : Colors.red.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.toDouble(),
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            isGood ? Colors.green.shade600 : Colors.red.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Meta: ${isInverted ? "≤" : "≥"} $target$unit',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildDetailedStats(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles Financieros',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Monto Total en Ventas',
              '\$${_formatCurrency(controller.totalSales)}',
              Icons.trending_up,
              Colors.green,
            ),
            _buildDetailRow(
              'Monto Pendiente',
              '\$${_formatCurrency(controller.pendingAmount)}',
              Icons.schedule,
              Colors.orange,
            ),
            _buildDetailRow(
              'Monto Vencido',
              '\$${_formatCurrency(controller.overdueAmount)}',
              Icons.warning,
              Colors.red,
            ),
            const Divider(),
            _buildDetailRow(
              'Facturas Activas',
              controller.activeInvoices.toString(),
              Icons.receipt,
              Colors.blue,
            ),
            _buildDetailRow(
              'Monto Activo',
              '\$${_formatCurrency(controller.activeAmount)}',
              Icons.account_balance,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueSection(
    BuildContext context,
    InvoiceStatsController controller,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Text(
                  'Facturas Vencidas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red.shade800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: controller.goToOverdueInvoices,
                  child: const Text('Ver Todas'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (controller.overdueInvoices.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text('¡No hay facturas vencidas!'),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${controller.overdueInvoices.length} facturas vencidas por un total de \$${_formatCurrency(controller.overdueAmount)}',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (controller.overdueInvoices.length <= 3) ...[
                    const SizedBox(height: 8),
                    ...controller.overdueInvoices
                        .take(3)
                        .map(
                          (invoice) => _buildOverdueInvoiceItem(
                            context,
                            invoice,
                            controller,
                          ),
                        ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueInvoiceItem(
    BuildContext context,
    Invoice invoice,
    InvoiceStatsController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => controller.goToInvoiceDetail(invoice.id),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.number,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    invoice.customerName,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${invoice.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                ),
                Text(
                  '${invoice.daysOverdue} días',
                  style: TextStyle(fontSize: 10, color: Colors.red.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Error al cargar estadísticas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se pudieron cargar los datos',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () => Get.find<InvoiceStatsController>().refreshAllData(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }
}

// // lib/features/invoices/presentation/widgets/invoice_stats_widget.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../../app/core/utils/responsive.dart';
// import '../../../../app/shared/widgets/custom_card.dart';
// import '../../../../app/shared/widgets/loading_widget.dart';
// import '../controllers/invoice_stats_controller.dart';
// import '../../domain/entities/invoice.dart';

// class InvoiceStatsWidget extends StatelessWidget {
//   final bool isCompact;
//   final bool showHeader;

//   const InvoiceStatsWidget({
//     super.key,
//     this.isCompact = false,
//     this.showHeader = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<InvoiceStatsController>(
//       builder: (controller) {
//         if (controller.isLoading) {
//           return _buildLoadingState(context);
//         }

//         if (controller.hasError) {
//           return _buildErrorState(context, controller);
//         }

//         if (!controller.hasStats) {
//           return _buildNoDataState(context, controller);
//         }

//         return ResponsiveLayout(
//           mobile: _buildMobileLayout(context, controller),
//           tablet: _buildTabletLayout(context, controller),
//           desktop: _buildDesktopLayout(context, controller),
//         );
//       },
//     );
//   }

//   // ==================== LOADING & ERROR STATES ====================

//   Widget _buildLoadingState(BuildContext context) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: context.responsivePadding,
//         constraints: BoxConstraints(minHeight: isCompact ? 100 : 200),
//         child: Center(
//           child: LoadingWidget(
//             message: 'Cargando estadísticas...',
//             size: isCompact ? 30 : null,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: context.responsivePadding,
//         constraints: const BoxConstraints(minHeight: 200),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: context.isMobile ? 48 : 64,
//               color: Colors.red.shade400,
//             ),
//             SizedBox(height: context.verticalSpacing / 2),
//             Text(
//               'Error al cargar estadísticas',
//               style: TextStyle(
//                 fontSize: context.isMobile ? 16 : 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.red.shade700,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: context.verticalSpacing / 4),
//             Flexible(
//               child: Text(
//                 controller.errorMessage.isNotEmpty
//                     ? controller.errorMessage
//                     : 'No se pudieron cargar los datos',
//                 style: TextStyle(
//                   color: Colors.grey.shade600,
//                   fontSize: context.isMobile ? 12 : 14,
//                 ),
//                 textAlign: TextAlign.center,
//                 maxLines: 3,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             SizedBox(height: context.verticalSpacing),
//             ElevatedButton.icon(
//               onPressed: controller.refreshAllData,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Reintentar'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNoDataState(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: context.responsivePadding,
//         constraints: const BoxConstraints(minHeight: 200),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.analytics_outlined,
//               size: context.isMobile ? 48 : 64,
//               color: Colors.grey.shade400,
//             ),
//             SizedBox(height: context.verticalSpacing / 2),
//             Text(
//               'Sin datos disponibles',
//               style: TextStyle(
//                 fontSize: context.isMobile ? 16 : 18,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             SizedBox(height: context.verticalSpacing / 4),
//             Text(
//               'No hay estadísticas para mostrar',
//               style: TextStyle(
//                 color: Colors.grey.shade500,
//                 fontSize: context.isMobile ? 12 : 14,
//               ),
//             ),
//             SizedBox(height: context.verticalSpacing),
//             ElevatedButton.icon(
//               onPressed: controller.refreshAllData,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Actualizar'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ==================== RESPONSIVE LAYOUTS ====================

//   Widget _buildMobileLayout(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     if (isCompact) {
//       return _buildCompactStats(context, controller);
//     }

//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (showHeader) ...[
//             _buildHeader(context, controller),
//             SizedBox(height: context.verticalSpacing),
//           ],
//           _buildOverviewCards(context, controller),
//           SizedBox(height: context.verticalSpacing),
//           _buildHealthIndicator(context, controller),
//           SizedBox(height: context.verticalSpacing),
//           _buildDetailedStats(context, controller),
//           if (controller.hasOverdueInvoices) ...[
//             SizedBox(height: context.verticalSpacing),
//             _buildOverdueSection(context, controller),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildTabletLayout(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           if (showHeader) ...[
//             _buildHeader(context, controller),
//             SizedBox(height: context.verticalSpacing),
//           ],
//           IntrinsicHeight(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: _buildOverviewCards(context, controller),
//                 ),
//                 SizedBox(width: context.horizontalSpacing),
//                 Expanded(child: _buildHealthIndicator(context, controller)),
//               ],
//             ),
//           ),
//           SizedBox(height: context.verticalSpacing),
//           _buildDetailedStats(context, controller),
//           if (controller.hasOverdueInvoices) ...[
//             SizedBox(height: context.verticalSpacing),
//             _buildOverdueSection(context, controller),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildDesktopLayout(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           if (showHeader) ...[
//             _buildHeader(context, controller),
//             SizedBox(height: context.verticalSpacing),
//           ],
//           IntrinsicHeight(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: _buildOverviewCards(context, controller),
//                 ),
//                 SizedBox(width: context.horizontalSpacing),
//                 Expanded(child: _buildHealthIndicator(context, controller)),
//               ],
//             ),
//           ),
//           SizedBox(height: context.verticalSpacing),
//           IntrinsicHeight(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: _buildDetailedStats(context, controller),
//                 ),
//                 if (controller.hasOverdueInvoices) ...[
//                   SizedBox(width: context.horizontalSpacing),
//                   Expanded(child: _buildOverdueSection(context, controller)),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ==================== COMPONENTS ====================

//   Widget _buildHeader(BuildContext context, InvoiceStatsController controller) {
//     return Row(
//       children: [
//         Icon(Icons.analytics, color: Theme.of(context).primaryColor, size: 24),
//         const SizedBox(width: 8),
//         Expanded(
//           child: Text(
//             'Estadísticas de Facturas',
//             style: TextStyle(
//               fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).primaryColor,
//             ),
//           ),
//         ),
//         IconButton(
//           icon: const Icon(Icons.refresh),
//           onPressed: controller.refreshAllData,
//           tooltip: 'Actualizar',
//         ),
//       ],
//     );
//   }

//   Widget _buildCompactStats(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildStatCard(
//             'Total',
//             controller.totalInvoices.toString(),
//             Icons.receipt,
//             Colors.blue,
//             context,
//             isCompact: true,
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: _buildStatCard(
//             'Pendientes',
//             controller.pendingInvoices.toString(),
//             Icons.schedule,
//             Colors.orange,
//             context,
//             isCompact: true,
//           ),
//         ),
//         const SizedBox(width: 8),
//         Expanded(
//           child: _buildStatCard(
//             'Vencidas',
//             controller.overdueCount.toString(),
//             Icons.warning,
//             Colors.red,
//             context,
//             isCompact: true,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildOverviewCards(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     final crossAxisCount = context.isMobile ? 2 : (context.isTablet ? 3 : 4);
//     final aspectRatio = context.isMobile ? 1.1 : (context.isTablet ? 1.3 : 1.4);

//     return CustomCard(
//       child: Padding(
//         padding: EdgeInsets.all(context.isMobile ? 12 : 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Resumen General',
//               style: TextStyle(
//                 fontSize: context.isMobile ? 16 : 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             SizedBox(height: context.isMobile ? 12 : 16),
//             LayoutBuilder(
//               builder: (context, constraints) {
//                 return GridView.count(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   crossAxisCount: crossAxisCount,
//                   crossAxisSpacing: 8,
//                   mainAxisSpacing: 8,
//                   childAspectRatio: aspectRatio,
//                   children: [
//                     _buildStatCard(
//                       'Total Facturas',
//                       controller.totalInvoices.toString(),
//                       Icons.receipt_long,
//                       Colors.blue,
//                       context,
//                     ),
//                     _buildStatCard(
//                       'Pagadas',
//                       controller.paidInvoices.toString(),
//                       Icons.check_circle,
//                       Colors.green,
//                       context,
//                       subtitle:
//                           '${controller.paidPercentage.toStringAsFixed(1)}%',
//                     ),
//                     _buildStatCard(
//                       'Pendientes',
//                       controller.pendingInvoices.toString(),
//                       Icons.schedule,
//                       Colors.orange,
//                       context,
//                       subtitle:
//                           '${controller.pendingPercentage.toStringAsFixed(1)}%',
//                     ),
//                     _buildStatCard(
//                       'Vencidas',
//                       controller.overdueCount.toString(),
//                       Icons.error,
//                       Colors.red,
//                       context,
//                       subtitle:
//                           '${controller.overduePercentage.toStringAsFixed(1)}%',
//                     ),
//                     if (!context.isMobile) ...[
//                       _buildStatCard(
//                         'Borradores',
//                         controller.draftInvoices.toString(),
//                         Icons.edit,
//                         Colors.grey,
//                         context,
//                       ),
//                       _buildStatCard(
//                         'Total Ventas',
//                         '\$${_formatCurrency(controller.totalSales)}',
//                         Icons.attach_money,
//                         Colors.purple,
//                         context,
//                       ),
//                     ],
//                   ],
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatCard(
//     String title,
//     String value,
//     IconData icon,
//     Color color,
//     BuildContext context, {
//     String? subtitle,
//     VoidCallback? onTap,
//     bool isCompact = false,
//   }) {
//     final cardPadding = isCompact ? 8.0 : (context.isMobile ? 12.0 : 16.0);
//     final iconSize = isCompact ? 16.0 : (context.isMobile ? 20.0 : 24.0);
//     final valueSize = isCompact ? 14.0 : (context.isMobile ? 16.0 : 18.0);
//     final titleSize = isCompact ? 10.0 : (context.isMobile ? 11.0 : 12.0);

//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(8),
//       elevation: 1,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           padding: EdgeInsets.all(cardPadding),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: EdgeInsets.all(isCompact ? 6 : 8),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Icon(icon, color: color, size: iconSize),
//               ),
//               SizedBox(height: isCompact ? 4 : 8),
//               Flexible(
//                 child: Text(
//                   value,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: valueSize,
//                     color: color,
//                   ),
//                   textAlign: TextAlign.center,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               Flexible(
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: titleSize,
//                     color: Colors.grey.shade600,
//                   ),
//                   textAlign: TextAlign.center,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               if (subtitle != null && !isCompact) ...[
//                 const SizedBox(height: 2),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: color.withOpacity(0.8),
//                     fontWeight: FontWeight.w500,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHealthIndicator(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: EdgeInsets.all(context.isMobile ? 12 : 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Estado Financiero',
//               style: TextStyle(
//                 fontSize: context.isMobile ? 16 : 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             SizedBox(height: context.isMobile ? 12 : 16),
//             Row(
//               children: [
//                 Icon(
//                   controller.getHealthIcon(),
//                   color: controller.getHealthColor(),
//                   size: 24,
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Estado General',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: context.isMobile ? 13 : 14,
//                         ),
//                       ),
//                       Text(
//                         controller.getHealthMessage(),
//                         style: TextStyle(
//                           color: controller.getHealthColor(),
//                           fontSize: context.isMobile ? 11 : 12,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: context.isMobile ? 12 : 16),
//             _buildIndicatorRow(
//               'Tasa de Cobro',
//               controller.collectionRate,
//               '%',
//               85,
//               controller.collectionRate >= 85,
//               context,
//             ),
//             const SizedBox(height: 8),
//             _buildIndicatorRow(
//               'Facturas Vencidas',
//               controller.overduePercentage,
//               '%',
//               5,
//               controller.overduePercentage <= 5,
//               context,
//               isInverted: true,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildIndicatorRow(
//     String label,
//     double value,
//     String unit,
//     double target,
//     bool isGood,
//     BuildContext context, {
//     bool isInverted = false,
//   }) {
//     final progress =
//         isInverted
//             ? (target - value).clamp(0, target) / target
//             : (value / target).clamp(0, 1);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Expanded(
//               child: Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: context.isMobile ? 11 : 12,
//                   color: Colors.grey.shade600,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             Text(
//               '${value.toStringAsFixed(1)}$unit',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: context.isMobile ? 12 : 13,
//                 color: isGood ? Colors.green.shade600 : Colors.red.shade600,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         LinearProgressIndicator(
//           value: progress.toDouble(),
//           backgroundColor: Colors.grey.shade300,
//           valueColor: AlwaysStoppedAnimation<Color>(
//             isGood ? Colors.green.shade600 : Colors.red.shade600,
//           ),
//         ),
//         const SizedBox(height: 2),
//         Text(
//           'Meta: ${isInverted ? "≤" : "≥"} $target$unit',
//           style: TextStyle(
//             fontSize: context.isMobile ? 9 : 10,
//             color: Colors.grey.shade500,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDetailedStats(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: EdgeInsets.all(context.isMobile ? 12 : 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Detalles Financieros',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: context.isMobile ? 16 : 18,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             SizedBox(height: context.isMobile ? 12 : 16),
//             _buildDetailRow(
//               'Monto Total en Ventas',
//               '\$${_formatCurrency(controller.totalSales)}',
//               Icons.trending_up,
//               Colors.green,
//               context,
//             ),
//             _buildDetailRow(
//               'Monto Pendiente',
//               '\$${_formatCurrency(controller.pendingAmount)}',
//               Icons.schedule,
//               Colors.orange,
//               context,
//             ),
//             _buildDetailRow(
//               'Monto Vencido',
//               '\$${_formatCurrency(controller.overdueAmount)}',
//               Icons.warning,
//               Colors.red,
//               context,
//             ),
//             const Divider(),
//             _buildDetailRow(
//               'Facturas Activas',
//               controller.activeInvoices.toString(),
//               Icons.receipt,
//               Colors.blue,
//               context,
//             ),
//             _buildDetailRow(
//               'Monto Activo',
//               '\$${_formatCurrency(controller.activeAmount)}',
//               Icons.account_balance,
//               Colors.blue,
//               context,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//     BuildContext context,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: color),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               label,
//               style: TextStyle(
//                 color: Colors.grey.shade700,
//                 fontSize: context.isMobile ? 13 : 14,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               color: color,
//               fontSize: context.isMobile ? 13 : 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOverdueSection(
//     BuildContext context,
//     InvoiceStatsController controller,
//   ) {
//     return CustomCard(
//       child: Container(
//         width: double.infinity,
//         padding: EdgeInsets.all(context.isMobile ? 12 : 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.warning, color: Colors.red.shade600),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Facturas Vencidas',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: context.isMobile ? 16 : 18,
//                       color: Colors.red.shade800,
//                     ),
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: controller.goToOverdueInvoices,
//                   child: Text(
//                     'Ver Todas',
//                     style: TextStyle(fontSize: context.isMobile ? 12 : 14),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: context.isMobile ? 8 : 12),

//             if (controller.overdueInvoices.isEmpty)
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(context.isMobile ? 12 : 16),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.check_circle, color: Colors.green.shade600),
//                     const SizedBox(width: 8),
//                     const Expanded(child: Text('¡No hay facturas vencidas!')),
//                   ],
//                 ),
//               )
//             else
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(context.isMobile ? 10 : 12),
//                     decoration: BoxDecoration(
//                       color: Colors.red.shade50,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.red.shade200),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.error, color: Colors.red.shade600),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             '${controller.overdueInvoices.length} facturas vencidas por un total de \$${_formatCurrency(controller.overdueAmount)}',
//                             style: TextStyle(
//                               color: Colors.red.shade800,
//                               fontWeight: FontWeight.w500,
//                               fontSize: context.isMobile ? 12 : 13,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   if (controller.overdueInvoices.length <= 3) ...[
//                     SizedBox(height: context.isMobile ? 6 : 8),
//                     ...controller.overdueInvoices
//                         .take(3)
//                         .map(
//                           (invoice) => _buildOverdueInvoiceItem(
//                             context,
//                             invoice,
//                             controller,
//                           ),
//                         ),
//                   ],
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOverdueInvoiceItem(
//     BuildContext context,
//     Invoice invoice,
//     InvoiceStatsController controller,
//   ) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 4),
//       child: Material(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(6),
//         elevation: 0.5,
//         child: InkWell(
//           onTap: () => controller.goToInvoiceDetail(invoice.id),
//           borderRadius: BorderRadius.circular(6),
//           child: Container(
//             padding: EdgeInsets.all(context.isMobile ? 8 : 10),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey.shade300),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         invoice.number,
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: context.isMobile ? 11 : 12,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         invoice.customerName,
//                         style: TextStyle(
//                           fontSize: context.isMobile ? 10 : 11,
//                           color: Colors.grey.shade600,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       '\$${invoice.total.toStringAsFixed(2)}',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: context.isMobile ? 11 : 12,
//                         color: Colors.red.shade600,
//                       ),
//                     ),
//                     Text(
//                       '${invoice.daysOverdue} días',
//                       style: TextStyle(
//                         fontSize: context.isMobile ? 9 : 10,
//                         color: Colors.red.shade600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   String _formatCurrency(double amount) {
//     if (amount >= 1000000) {
//       return '${(amount / 1000000).toStringAsFixed(1)}M';
//     } else if (amount >= 1000) {
//       return '${(amount / 1000).toStringAsFixed(1)}K';
//     } else {
//       return amount.toStringAsFixed(2);
//     }
//   }
// }
