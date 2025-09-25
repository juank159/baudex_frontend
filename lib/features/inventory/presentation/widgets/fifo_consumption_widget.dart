// lib/features/inventory/presentation/widgets/fifo_consumption_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_balance.dart';

class FifoConsumptionWidget extends StatelessWidget {
  final List<FifoConsumption> consumptions;
  final String productName;
  final int totalQuantityRequested;
  final VoidCallback? onClose;

  const FifoConsumptionWidget({
    super.key,
    required this.consumptions,
    required this.productName,
    required this.totalQuantityRequested,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildSummary(),
          if (consumptions.isNotEmpty) ...[
            _buildConsumptionsList(),
          ] else ...[
            _buildEmptyState(),
          ],
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.trending_up,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proceso FIFO',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Primero en entrar, primero en salir',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final totalConsumed = consumptions.fold(0, (sum, c) => sum + c.quantityConsumed);
    final totalCost = consumptions.fold(0.0, (sum, c) => sum + c.totalCost);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Producto',
                  productName,
                  Icons.inventory_2,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Cantidad Solicitada',
                  '$totalQuantityRequested unidades',
                  Icons.request_quote,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Cantidad Procesada',
                  '$totalConsumed unidades',
                  Icons.check_circle,
                  totalConsumed >= totalQuantityRequested ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Costo Total',
                  AppFormatters.formatCurrency(totalCost),
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Consumo por Lotes (FIFO)',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Process flow indicator
          _buildProcessFlow(),
          
          const SizedBox(height: 16),
          
          // Consumptions list
          ...consumptions.asMap().entries.map((entry) => 
            _buildConsumptionItem(entry.value, entry.key + 1),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildProcessFlow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          _buildFlowStep('1', 'Lotes\nDisponibles', AppColors.primary, true),
          _buildFlowArrow(),
          _buildFlowStep('2', 'Ordenar por\nFecha', Colors.blue, true),
          _buildFlowArrow(),
          _buildFlowStep('3', 'Consumir\nPrimeros', Colors.green, true),
          _buildFlowArrow(),
          _buildFlowStep('4', 'Calcular\nCosto', Colors.orange, true),
        ],
      ),
    );
  }

  Widget _buildFlowStep(String number, String label, Color color, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Get.textTheme.bodySmall?.copyWith(
            color: isActive ? color : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFlowArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.arrow_forward,
        color: AppColors.primary,
        size: 16,
      ),
    );
  }

  Widget _buildConsumptionItem(FifoConsumption consumption, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          // Step number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Lote: ${consumption.lot.lotNumber}',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getLotStatusColor(consumption.lot).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppFormatters.formatDate(consumption.lot.entryDate),
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: _getLotStatusColor(consumption.lot),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Disponible: ${consumption.lot.quantity}',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Consumir: ${consumption.quantityConsumed}',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppFormatters.formatCurrency(consumption.totalCost),
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (consumption.lot.expiryDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        consumption.lot.isExpired 
                            ? Icons.dangerous
                            : consumption.lot.isNearExpiry 
                                ? Icons.warning
                                : Icons.schedule,
                        size: 16,
                        color: consumption.lot.isExpired 
                            ? Colors.red
                            : consumption.lot.isNearExpiry 
                                ? Colors.orange
                                : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Vence: ${AppFormatters.formatDate(consumption.lot.expiryDate!)}',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: consumption.lot.isExpired 
                              ? Colors.red
                              : consumption.lot.isNearExpiry 
                                  ? Colors.orange
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay lotes disponibles para procesamiento FIFO',
            style: Get.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Verifique que el producto tenga stock disponible',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final totalConsumed = consumptions.fold(0, (sum, c) => sum + c.quantityConsumed);
    final totalCost = consumptions.fold(0.0, (sum, c) => sum + c.totalCost);
    final isComplete = totalConsumed >= totalQuantityRequested;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.warning,
            color: isComplete ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete 
                      ? 'Procesamiento FIFO Completo'
                      : 'Procesamiento FIFO Parcial',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green : Colors.orange,
                  ),
                ),
                Text(
                  '$totalConsumed de $totalQuantityRequested unidades • ${AppFormatters.formatCurrency(totalCost)}',
                  style: Get.textTheme.bodySmall?.copyWith(
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

  Color _getLotStatusColor(InventoryLot lot) {
    if (lot.isExpired) return Colors.red;
    if (lot.isNearExpiry) return Colors.orange;
    return AppColors.primary;
  }
}

// Dialog helper for showing FIFO consumption
class FifoConsumptionDialog {
  static void show({
    required List<FifoConsumption> consumptions,
    required String productName,
    required int totalQuantityRequested,
  }) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: FifoConsumptionWidget(
          consumptions: consumptions,
          productName: productName,
          totalQuantityRequested: totalQuantityRequested,
          onClose: () => Get.back(),
        ),
      ),
    );
  }
}

// Bottom sheet helper for showing FIFO consumption
class FifoConsumptionBottomSheet {
  static void show({
    required List<FifoConsumption> consumptions,
    required String productName,
    required int totalQuantityRequested,
  }) {
    Get.bottomSheet(
      FifoConsumptionWidget(
        consumptions: consumptions,
        productName: productName,
        totalQuantityRequested: totalQuantityRequested,
        onClose: () => Get.back(),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}