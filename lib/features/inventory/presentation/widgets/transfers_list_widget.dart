// lib/features/inventory/presentation/widgets/transfers_list_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../domain/entities/inventory_movement.dart';
import '../controllers/inventory_transfers_controller.dart';

class TransfersListWidget extends GetView<InventoryTransfersController> {
  const TransfersListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final transfers = controller.transfers;
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transfers.length,
        itemBuilder: (context, index) {
          final transfer = transfers[index];
          return _buildTransferCard(transfer);
        },
      );
    });
  }

  Widget _buildTransferCard(InventoryMovement transfer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _showTransferDetail(transfer),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: controller.getStatusColor(transfer.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        controller.getStatusIcon(transfer.status),
                        color: controller.getStatusColor(transfer.status),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transfer.productName,
                            style: Get.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'SKU: ${transfer.productSku}',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: controller.getStatusColor(transfer.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            transfer.status.displayStatus,
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: controller.getStatusColor(transfer.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.formatDate(transfer.movementDate),
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Transfer details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // From warehouse
                      Expanded(
                        child: Column(
                          children: [
                            Icon(
                              Icons.warehouse,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Origen',
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              transfer.warehouseName ?? 'N/A',
                              style: Get.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Arrow and quantity
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.arrow_forward,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${transfer.quantity}',
                                style: Get.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // To warehouse
                      Expanded(
                        child: Column(
                          children: [
                            Icon(
                              Icons.warehouse,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Destino',
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Almacén Destino', // TODO: Get from transfer data
                              style: Get.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Notes (if any)
                if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notes,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            transfer.notes!,
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Action buttons for pending transfers
                if (transfer.status == InventoryMovementStatus.pending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showCancelDialog(transfer),
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.confirmTransfer(transfer.id),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Confirmar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showTransferDetail(InventoryMovement transfer) {
    Get.dialog(
      AlertDialog(
        title: Text('Transferencia ${transfer.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Producto', transfer.productName),
            _buildDetailRow('SKU', transfer.productSku),
            _buildDetailRow('Cantidad', '${transfer.quantity}'),
            _buildDetailRow('Estado', transfer.status.displayStatus),
            _buildDetailRow('Fecha', controller.formatDateTime(transfer.movementDate)),
            if (transfer.notes != null)
              _buildDetailRow('Notas', transfer.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
          if (transfer.status == InventoryMovementStatus.pending)
            ElevatedButton(
              onPressed: () {
                Get.back();
                controller.confirmTransfer(transfer.id);
              },
              child: const Text('Confirmar'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Get.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(InventoryMovement transfer) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar Transferencia'),
        content: Text('¿Estás seguro que deseas cancelar la transferencia de ${transfer.productName}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.cancelTransfer(transfer.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }
}