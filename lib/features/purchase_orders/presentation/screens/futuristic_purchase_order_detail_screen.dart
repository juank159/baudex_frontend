// lib/features/purchase_orders/presentation/screens/futuristic_purchase_order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/theme/futuristic_notifications.dart';
import '../controllers/purchase_order_detail_controller.dart';
import '../widgets/futuristic_purchase_order_widgets.dart';
import '../widgets/smart_workflow_widget.dart';
import '../widgets/advanced_stats_widget.dart';
import '../widgets/custom_receive_dialog.dart';
import '../widgets/purchase_order_skeleton_widget.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../../../../app/presentation/widgets/sync_status_indicator.dart';

class FuturisticPurchaseOrderDetailScreen
    extends GetView<PurchaseOrderDetailController> {
  const FuturisticPurchaseOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () =>
          controller.isLoading.value
              ? _buildLoadingState()
              : controller.error.value.isNotEmpty
              ? _buildErrorState()
              : controller.hasPurchaseOrder
              ? MainLayout(
                title: controller.displayTitle,
                showBackButton: true,
                showDrawer: false,
                actions: _buildAppBarActions(context),
                body: _buildFuturisticContent(context),
              )
              : _buildNotFoundState(),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      const SyncStatusIcon(),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: controller.refreshPurchaseOrder,
        tooltip: 'Actualizar',
      ),
      const SizedBox(width: AppDimensions.paddingSmall),
    ];
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      body: PurchaseOrderDetailSkeleton(),
    );
  }

  Widget _buildFuturisticContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withOpacity(0.95),
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header con información clave
            _buildFuturisticHeader(),
            const SizedBox(height: 12),

            // Workflow inteligente
            SmartWorkflowWidget(
              order: controller.purchaseOrder.value!,
              onAction: _handleWorkflowAction,
            ),
            const SizedBox(height: 12),

            // Tabs futuristas
            _buildFuturisticTabs(),
            const SizedBox(height: 12),

            // Contenido del tab seleccionado
            Obx(() => _buildFuturisticTabContent()),

            // Espacio adicional al final
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticHeader() {
    return FuturisticContainer(
      hasGlow: true,
      child: Obx(() {
        final order = controller.purchaseOrder.value!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isDesktop = screenWidth >= 800;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título + Estado en una fila compacta
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: ElegantLightTheme.glowShadow,
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: ElegantLightTheme.textPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.orderNumber ?? 'Sin número',
                            style: TextStyle(
                              color: ElegantLightTheme.textPrimary,
                              fontSize: isDesktop ? 20 : 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.supplierName ?? 'Sin proveedor',
                            style: TextStyle(
                              color: ElegantLightTheme.textSecondary,
                              fontSize: isDesktop ? 14 : 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FuturisticStatusChip(
                      status: order.status,
                      size: isDesktop ? 0.9 : 0.8,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Métricas como chips inline compactos
                _buildCompactMetrics(order, isDesktop),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildCompactMetrics(PurchaseOrder order, bool isDesktop) {
    final metrics = [
      _MetricData(
        'Items',
        '${order.itemsCount}',
        Icons.inventory_2,
        ElegantLightTheme.infoGradient.colors.first,
      ),
      _MetricData(
        'Cantidad',
        '${order.totalQuantity}',
        Icons.format_list_numbered,
        ElegantLightTheme.warningGradient.colors.first,
      ),
      _MetricData(
        'Progreso',
        controller.progressPercentage,
        Icons.trending_up,
        ElegantLightTheme.successGradient.colors.first,
      ),
      _MetricData(
        'Prioridad',
        order.priority.displayPriority,
        Icons.priority_high,
        controller.getPriorityColor(order.priority),
      ),
    ];

    return Row(
      children: metrics
          .map((m) => Expanded(
                child: _buildMetricChip(m, isDesktop),
              ))
          .toList(),
    );
  }

  Widget _buildMetricChip(_MetricData metric, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 10 : 6,
        vertical: isDesktop ? 10 : 8,
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: metric.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(metric.icon, color: metric.color, size: isDesktop ? 18 : 15),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: isDesktop ? 14 : 12,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            metric.label,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: isDesktop ? 10 : 9,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticTabs() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Row(
          children: [
            _buildTabHeader('General', 0, Icons.info_outline),
            _buildTabHeader('Items', 1, Icons.inventory_2_outlined),
            _buildTabHeader('Cronología', 2, Icons.timeline),
            _buildTabHeader('Análisis', 3, Icons.analytics_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildTabHeader(String title, int index, IconData icon) {
    final isSelected = controller.selectedTab.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchTab(index),
        child: AnimatedContainer(
          duration: ElegantLightTheme.normalAnimation,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : ElegantLightTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticTabContent() {
    switch (controller.selectedTab.value) {
      case 0:
        return _buildGeneralTab();
      case 1:
        return _buildItemsTab();
      case 2:
        return _buildTimelineTab();
      case 3:
        return _buildStatsTab();
      default:
        return _buildGeneralTab();
    }
  }

  Widget _buildGeneralTab() {
    return FuturisticContainer(
      child: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información General',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...controller.purchaseOrderSummary.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildInfoRow(
                  item['label'],
                  item['value'],
                  item['icon'],
                  item['color'],
                  item['action'],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildItemsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items de la Orden',
          style: TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Column(
            children:
                controller.purchaseOrder.value!.items
                    .map(
                      (item) => FuturisticItemCard(
                        item: item,
                        onTap: null,
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTab() {
    return Obx(
      () => FuturisticWorkflowTimeline(order: controller.purchaseOrder.value!),
    );
  }

  Widget _buildStatsTab() {
    return Obx(
      () => AdvancedStatsWidget(order: controller.purchaseOrder.value!),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    Color? color,
    VoidCallback? action,
  ) {
    return GestureDetector(
      onTap: action,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ElegantLightTheme.textSecondary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFF6366F1)).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color ?? const Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: ElegantLightTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null)
              Icon(
                Icons.arrow_forward_ios,
                color: ElegantLightTheme.textSecondary.withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: FuturisticContainer(
        margin: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline,
                color: ElegantLightTheme.textPrimary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Text(
                controller.error.value,
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            FuturisticButton(
              text: 'Reintentar',
              icon: Icons.refresh,
              onPressed: controller.refreshPurchaseOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: FuturisticContainer(
        margin: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.search_off,
                color: ElegantLightTheme.textPrimary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Orden no encontrada',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La orden de compra solicitada no existe o ha sido eliminada',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FuturisticButton(
              text: 'Volver al listado',
              icon: Icons.arrow_back,
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  void _handleWorkflowAction(String action, {Map<String, dynamic>? data}) {
    switch (action) {
      case 'submit_for_review':
        controller.submitForReview();
        break;
      case 'approve_and_send':
        _approveAndSend();
        break;
      case 'approve':
        controller.approvePurchaseOrder();
        break;
      case 'send':
        controller.sendPurchaseOrder();
        break;
      case 'quick_receive':
        _quickReceive();
        break;
      case 'custom_receive':
        _showCustomReceiveDialog();
        break;
      case 'edit':
        controller.goToEdit();
        break;
      case 'view_batches':
        controller.goToGeneratedBatches();
        break;
      case 'cancel':
        controller.cancelPurchaseOrder();
        break;
      case 'duplicate':
        _duplicateOrder();
        break;
    }
  }

  void _approveAndSend() async {
    FuturisticNotifications.showProcessing(
      'Procesando Orden',
      'Aprobando y enviando automáticamente...',
    );

    // Aprobar primero
    await controller.approvePurchaseOrder();
    // Luego enviar
    await controller.sendPurchaseOrder();

    FuturisticNotifications.showSuccess(
      '¡Acción Completada!',
      'La orden ha sido aprobada y enviada al proveedor exitosamente',
    );
  }

  void _quickReceive() {
    _showWarehouseSelectionDialog(
      title: 'Recepción Rápida',
      subtitle: 'Recibir automáticamente todos los items al 100%',
      onWarehouseSelected: () {
        FuturisticNotifications.showProcessing(
          'Recibiendo Items',
          'Procesando recepción automática...',
        );
        controller.receivePurchaseOrder();
      },
    );
  }

  void _duplicateOrder() {
    FuturisticNotifications.showInfo(
      'Función Próximamente',
      'La duplicación de órdenes estará disponible en la próxima actualización',
    );
  }

  void _showMoreOptions(BuildContext context) {
    // Mostrar menú de opciones adicionales
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => FuturisticContainer(
            margin: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.canDelete)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Eliminar orden',
                      style: TextStyle(color: ElegantLightTheme.textPrimary),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      controller.deletePurchaseOrder();
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.share,
                    color: ElegantLightTheme.textSecondary,
                  ),
                  title: const Text(
                    'Compartir',
                    style: TextStyle(color: ElegantLightTheme.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar compartir
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.print,
                    color: ElegantLightTheme.textSecondary,
                  ),
                  title: const Text(
                    'Imprimir',
                    style: TextStyle(color: ElegantLightTheme.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar imprimir
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showCustomReceiveDialog() {
    _showWarehouseSelectionDialog(
      title: 'Recepción Personalizada',
      subtitle: 'Seleccionar almacén y especificar cantidades',
      onWarehouseSelected: () {
        Get.dialog(
          CustomReceiveDialog(
            items: controller.purchaseOrder.value!.items,
            onConfirm: (Map<String, CustomReceiveQuantities> quantities) {
              _processCustomReceive(quantities);
            },
          ),
        );
      },
    );
  }

  void _processCustomReceive(Map<String, CustomReceiveQuantities> quantities) {
    // Actualizar los receivingItems del controller con las cantidades personalizadas
    for (var entry in quantities.entries) {
      final itemId = entry.key;
      final quantity = entry.value;

      // Encontrar el item en receivingItems
      final receivingItemIndex = controller.receivingItems.indexWhere(
        (item) => item.itemId == itemId,
      );

      if (receivingItemIndex != -1) {
        final currentItem = controller.receivingItems[receivingItemIndex];
        // Crear nueva instancia con cantidades personalizadas incluyendo trazabilidad
        final customNotes = [
          quantity.notes,
          quantity.damagedQuantity > 0
              ? 'Dañados: ${quantity.damagedQuantity}'
              : null,
          quantity.missingQuantity > 0
              ? 'Faltantes: ${quantity.missingQuantity}'
              : null,
        ].where((note) => note != null && note.isNotEmpty).join(' | ');

        controller.receivingItems[receivingItemIndex] =
            ReceivePurchaseOrderItemParams(
              itemId: itemId, // Este es el ID del PurchaseOrderItem
              receivedQuantity:
                  quantity
                      .receivedQuantity, // Solo los recibidos en buen estado
              damagedQuantity: quantity.damagedQuantity,
              missingQuantity: quantity.missingQuantity,
              actualUnitCost: currentItem.actualUnitCost,
              supplierLotNumber: quantity.supplierLotNumber,
              expirationDate: quantity.expirationDate?.toIso8601String(),
              notes: customNotes.isNotEmpty ? customNotes : null,
            );
      }
    }

    // Proceder con la recepción usando las cantidades personalizadas
    FuturisticNotifications.showProcessing(
      'Procesando Recepción',
      'Recibiendo mercancía con cantidades personalizadas...',
    );

    controller.receivePurchaseOrder();
  }

  void _showWarehouseSelectionDialog({
    required String title,
    required String subtitle,
    required VoidCallback onWarehouseSelected,
  }) async {
    // Ensure warehouses are loaded
    if (controller.availableWarehouses.isEmpty) {
      await controller.loadAvailableWarehouses();
    }

    // If still no warehouses, show error
    if (controller.availableWarehouses.isEmpty) {
      Get.snackbar(
        'Sin Almacenes',
        'No se encontraron almacenes disponibles',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    // If only one warehouse, auto-select and proceed
    if (controller.availableWarehouses.length == 1) {
      controller.selectWarehouse(controller.availableWarehouses.first);
      onWarehouseSelected();
      return;
    }

    // Show warehouse selection dialog
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warehouse, color: ElegantLightTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿A qué almacén llega esta mercancía?'),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children:
                      controller.availableWarehouses
                          .map(
                            (warehouse) => Obx(
                              () => RadioListTile<String>(
                                title: Text(
                                  warehouse.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${warehouse.code} - ${warehouse.description ?? 'Sin descripción'}',
                                ),
                                value: warehouse.id,
                                groupValue:
                                    controller.selectedWarehouse.value?.id,
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.selectWarehouse(warehouse);
                                  }
                                },
                                activeColor: ElegantLightTheme.primaryBlue,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              if (controller.selectedWarehouse.value != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: ElegantLightTheme.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Almacén seleccionado: ${controller.selectedWarehouse.value!.name}',
                          style: TextStyle(
                            color: ElegantLightTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: ElegantLightTheme.textSecondary),
            ),
          ),
          Obx(
            () => ElevatedButton(
              onPressed:
                  controller.selectedWarehouse.value != null
                      ? () {
                        Get.back();
                        onWarehouseSelected();
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar'),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricData(this.label, this.value, this.icon, this.color);
}

// Painter para efectos de partículas en el fondo
class ParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = ElegantLightTheme.textSecondary.withOpacity(0.1)
          ..style = PaintingStyle.fill;

    // Dibujar partículas flotantes
    for (int i = 0; i < 20; i++) {
      final x = (i * 50.0 + 25) % size.width;
      final y = (i * 30.0 + 15) % size.height;
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
