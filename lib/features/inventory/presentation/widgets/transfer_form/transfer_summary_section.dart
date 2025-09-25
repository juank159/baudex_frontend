// lib/features/inventory/presentation/widgets/transfer_form/transfer_summary_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../app/config/themes/app_dimensions.dart';
import '../../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../../app/core/utils/formatters.dart';
import '../../controllers/create_transfer_controller.dart';

class TransferSummarySection extends GetView<CreateTransferController> {
  const TransferSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasValidData = controller.transferItems.isNotEmpty &&
                          controller.selectedFromWarehouseId.value.isNotEmpty &&
                          controller.selectedToWarehouseId.value.isNotEmpty;

      if (!hasValidData) {
        return _buildEmptyState();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Resumen de la Transferencia'),
          const SizedBox(height: AppDimensions.paddingMedium),
          _buildSummaryCard(),
          const SizedBox(height: AppDimensions.paddingMedium),
          _buildValidationStatus(),
        ],
      );
    });
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade100, Colors.grey.shade200.withValues(alpha: 0.5)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.preview,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Vista Previa',
              style: Get.textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa el formulario para ver\nel resumen de la transferencia',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.swap_horizontal_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Detalles de la Transferencia',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProductsSummary(),
                const SizedBox(height: 16),
                _buildTransferFlow(),
                const SizedBox(height: 16),
                _buildQuantitySummary(),
                if (controller.notesController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesSummary(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100.withValues(alpha: 0.3)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productos a transferir',
                      style: Get.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      '${controller.transferItems.length} productos seleccionados',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (controller.transferItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...controller.transferItems.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.product.name,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'x${item.quantity}',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTransferFlow() {
    return Row(
      children: [
        // From warehouse
        Expanded(
          child: _buildWarehouseInfo(
            title: 'Origen',
            warehouseId: controller.selectedFromWarehouseId.value,
            icon: Icons.outbox,
            color: Colors.orange,
          ),
        ),
        
        // Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        
        // To warehouse
        Expanded(
          child: _buildWarehouseInfo(
            title: 'Destino',
            warehouseId: controller.selectedToWarehouseId.value,
            icon: Icons.inbox,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseInfo({
    required String title,
    required String warehouseId,
    required IconData icon,
    required MaterialColor color,
  }) {
    final warehouseName = controller.getWarehouseName(warehouseId);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade50, color.shade100.withValues(alpha: 0.3)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color.shade600, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: color.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            warehouseName,
            style: Get.textTheme.titleSmall?.copyWith(
              color: color.shade800,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySummary() {
    final totalQuantity = controller.transferItems.fold<int>(0, (sum, item) => sum + item.quantity);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.purple.shade100.withValues(alpha: 0.3)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total a transferir',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Colors.purple.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${AppFormatters.formatNumber(totalQuantity.toDouble())} unidades',
                style: Get.textTheme.titleMedium?.copyWith(
                  color: Colors.purple.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.amber.shade100.withValues(alpha: 0.3)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: Colors.amber.shade600, size: 16),
              const SizedBox(width: 4),
              Text(
                'Notas',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Colors.amber.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            controller.notesController.text.trim(),
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.amber.shade800,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildValidationStatus() {
    return Obx(() {
      final isValid = controller.isFormValid.value;
      final hasStockError = controller.quantityError.value.contains('Stock insuficiente');
      
      if (isValid) {
        return _buildStatusCard(
          icon: Icons.check_circle,
          title: 'Transferencia lista',
          message: 'Todos los datos son válidos. Puedes proceder con la transferencia.',
          color: Colors.green,
        );
      } else if (hasStockError) {
        return _buildStatusCard(
          icon: Icons.warning,
          title: 'Stock insuficiente',
          message: 'La cantidad solicitada excede el stock disponible en el almacén de origen.',
          color: Colors.red,
        );
      } else {
        return _buildStatusCard(
          icon: Icons.info,
          title: 'Formulario incompleto',
          message: 'Completa todos los campos requeridos para continuar.',
          color: Colors.orange,
        );
      }
    });
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String message,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade50, color.shade100.withValues(alpha: 0.3)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Get.textTheme.titleSmall?.copyWith(
                    color: color.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  message,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: color.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Get.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: ElegantLightTheme.textPrimary,
      ),
    );
  }
}