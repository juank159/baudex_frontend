// lib/features/inventory/presentation/widgets/inventory_batch_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_batch.dart';

class InventoryBatchCard extends StatelessWidget {
  final InventoryBatch batch;
  final VoidCallback? onTap;
  final VoidCallback? onPurchaseOrderTap;
  final VoidCallback? onSupplierTap;

  const InventoryBatchCard({
    super.key,
    required this.batch,
    this.onTap,
    this.onPurchaseOrderTap,
    this.onSupplierTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(
        vertical: 2,
        horizontal: 0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 6 : (isTablet ? 8 : 10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with batch number and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lote: ${batch.batchNumber}',
                          style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 11 : (isTablet ? 12 : 13),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Entrada: ${_formatDate(batch.entryDate)}',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: isMobile ? 8 : 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status indicator
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 10, 
                      vertical: isMobile ? 4 : 6
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.12),
                      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: isMobile ? 14 : 16,
                        ),
                        SizedBox(width: isMobile ? 4 : 6),
                        Text(
                          batch.displayStatus,
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: isMobile ? 6 : 8),

              // Quantities section
              Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn(
                      'Cantidad Original',
                      '${batch.originalQuantity}',
                      Icons.inventory_2,
                      AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Cantidad Actual',
                      '${batch.currentQuantity}',
                      Icons.inventory,
                      _getQuantityColor(),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoColumn(
                      'Consumido',
                      '${batch.consumedQuantity}',
                      Icons.trending_down,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isMobile ? 4 : 6),

              // Costs section - Condensed for mobile
              isMobile ? 
                // Mobile: Single row with most important values
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        'Costo Unit.',
                        AppFormatters.formatCurrency(batch.unitCost),
                        Icons.monetization_on,
                        AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        'Valor Actual',
                        AppFormatters.formatCurrency(batch.currentValue),
                        Icons.account_balance_wallet,
                        AppColors.primary,
                      ),
                    ),
                  ],
                ) :
                // Desktop/Tablet: Full row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        'Costo Unitario',
                        AppFormatters.formatCurrency(batch.unitCost),
                        Icons.monetization_on,
                        AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        'Valor Actual',
                        AppFormatters.formatCurrency(batch.currentValue),
                        Icons.account_balance_wallet,
                        AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        'Valor Consumido',
                        AppFormatters.formatCurrency(batch.consumedValue),
                        Icons.payments,
                        Colors.grey,
                      ),
                    ),
                  ],
                ),

              // Progress bar for consumption - Compact for mobile
              if (batch.originalQuantity > 0) ...[
                SizedBox(height: isMobile ? 4 : 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isMobile ? 'Consumo' : 'Progreso de Consumo',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: isMobile ? 11 : 12,
                          ),
                        ),
                        Text(
                          '${batch.consumptionPercentage.toStringAsFixed(1)}%',
                          style: Get.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getConsumptionColor(),
                            fontSize: isMobile ? 11 : 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: LinearProgressIndicator(
                        value: batch.consumptionPercentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(_getConsumptionColor()),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ],

              // Expiry information - Compact design
              if (batch.hasExpiry && (batch.isExpiredByDate || batch.isNearExpiry)) ...[
                SizedBox(height: isMobile ? 4 : 6),
                Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: _getExpiryColor().withOpacity(0.08),
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    border: Border.all(
                      color: _getExpiryColor().withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getExpiryIcon(),
                        color: _getExpiryColor(),
                        size: isMobile ? 16 : 20,
                      ),
                      SizedBox(width: isMobile ? 6 : 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMobile 
                                ? 'Vence: ${_formatDate(batch.expiryDate!)}' 
                                : 'Vencimiento: ${_formatDate(batch.expiryDate!)}',
                              style: Get.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
                            if (!isMobile) ...[
                              const SizedBox(height: 2),
                              Text(
                                _getExpiryText(),
                                style: Get.textTheme.bodySmall?.copyWith(
                                  color: _getExpiryColor(),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Reference information - Only show on desktop/tablet or when tapped
              if (!isMobile && (batch.hasReference || batch.hasSupplier)) ...[
                SizedBox(height: isTablet ? 4 : 6),
                Container(
                  padding: EdgeInsets.all(isTablet ? 6 : 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (batch.hasReference) ...[
                        InkWell(
                          onTap: onPurchaseOrderTap,
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                color: AppColors.primary,
                                size: isTablet ? 16 : 18,
                              ),
                              SizedBox(width: isTablet ? 6 : 8),
                              Expanded(
                                child: Text(
                                  'Orden: ${batch.purchaseOrderNumber ?? batch.purchaseOrderId}',
                                  style: Get.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: isTablet ? 12 : 14,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                color: AppColors.primary,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      if (batch.hasSupplier) ...[
                        if (batch.hasReference) SizedBox(height: isTablet ? 6 : 8),
                        InkWell(
                          onTap: onSupplierTap,
                          child: Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: AppColors.primary,
                                size: isTablet ? 16 : 18,
                              ),
                              SizedBox(width: isTablet ? 6 : 8),
                              Expanded(
                                child: Text(
                                  'Proveedor: ${batch.supplierName ?? batch.supplierId}',
                                  style: Get.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: isTablet ? 12 : 14,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.open_in_new,
                                color: AppColors.primary,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon, 
                  color: color, 
                  size: isMobile ? 11 : 13
                ),
                SizedBox(width: isMobile ? 2 : 3),
                Expanded(
                  child: Text(
                    label,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: isMobile ? 8 : 9,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 1 : 2),
            Text(
              value,
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: isMobile ? 10 : 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }
    );
  }

  Color _getStatusColor() {
    if (batch.isExpiredByDate) return Colors.red;
    if (batch.isNearExpiry) return Colors.orange;
    if (batch.isConsumed) return Colors.grey;
    if (batch.isActive) return Colors.green;
    return Colors.blue;
  }

  IconData _getStatusIcon() {
    if (batch.isExpiredByDate) return Icons.dangerous;
    if (batch.isNearExpiry) return Icons.warning;
    if (batch.isConsumed) return Icons.inventory_2;
    if (batch.isActive) return Icons.check_circle;
    return Icons.help;
  }

  Color _getQuantityColor() {
    if (batch.currentQuantity == 0) return Colors.red;
    if (batch.currentQuantity < batch.originalQuantity * 0.3) return Colors.orange;
    return Colors.green;
  }

  Color _getConsumptionColor() {
    final percentage = batch.consumptionPercentage;
    if (percentage >= 90) return Colors.red;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 50) return Colors.blue;
    return Colors.green;
  }

  Color _getExpiryColor() {
    if (batch.isExpiredByDate) return Colors.red;
    if (batch.isNearExpiry) return Colors.orange;
    return Colors.blue;
  }

  IconData _getExpiryIcon() {
    if (batch.isExpiredByDate) return Icons.dangerous;
    if (batch.isNearExpiry) return Icons.warning;
    return Icons.schedule;
  }

  String _getExpiryText() {
    if (batch.isExpiredByDate) {
      final days = batch.daysUntilExpiry.abs();
      return 'Vencido hace $days día${days == 1 ? '' : 's'}';
    }
    if (batch.isNearExpiry) {
      final days = batch.daysUntilExpiry;
      if (days == 0) return 'Vence hoy';
      if (days == 1) return 'Vence mañana';
      return 'Vence en $days días';
    }
    final days = batch.daysUntilExpiry;
    if (days == 1) return 'Vence en 1 día';
    return 'Vence en $days días';
  }

  String _formatDate(DateTime date) {
    return AppFormatters.formatDate(date);
  }
}