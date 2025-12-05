// lib/features/inventory/presentation/widgets/inventory_movement_card_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_movement.dart';

class InventoryMovementCardWidget extends StatelessWidget {
  final InventoryMovement movement;
  final VoidCallback? onTap;

  const InventoryMovementCardWidget({
    super.key,
    required this.movement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    final cardPadding =
        isDesktop
            ? 16.0
            : isTablet
            ? 14.0
            : 12.0;

    return Card(
      margin: EdgeInsets.only(bottom: isDesktop ? 8 : 6),
      elevation: isDesktop ? 2 : 1,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FILA 1: Header con tipo de movimiento, motivo y estado
            Row(
              children: [
                _buildMovementTypeIcon(isDesktop),
                SizedBox(width: isDesktop ? 12 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.displayMovementType,
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize:
                              isDesktop
                                  ? 16
                                  : isTablet
                                  ? 15
                                  : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        movement.displayReason,
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: Get.theme.colorScheme.onSurfaceVariant,
                          fontSize:
                              isDesktop
                                  ? 13
                                  : isTablet
                                  ? 12
                                  : 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(isDesktop),
              ],
            ),

            SizedBox(height: isDesktop ? 12 : 8),

            // FILA 2: Información del producto y detalles principales
            Row(
              children: [
                // Producto
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.all(isDesktop ? 8 : 6),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2, size: isDesktop ? 16 : 14),
                        SizedBox(width: isDesktop ? 8 : 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movement.productName,
                                style: Get.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      isDesktop
                                          ? 14
                                          : isTablet
                                          ? 13
                                          : 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (movement.productSku.isNotEmpty)
                                Text(
                                  'SKU: ${movement.productSku}',
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    color:
                                        Get.theme.colorScheme.onSurfaceVariant,
                                    fontSize: isDesktop ? 11 : 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: isDesktop ? 12 : 8),

                // Cantidad
                Expanded(
                  flex: 2,
                  child: _buildInfoItem(
                    icon: Icons.swap_horiz,
                    label: 'Cantidad',
                    value: _formatQuantity(),
                    color: _getQuantityColor(),
                    isCompact: !isDesktop,
                  ),
                ),

                SizedBox(width: isDesktop ? 12 : 8),

                // Fecha
                Expanded(
                  flex: 2,
                  child: _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: 'Fecha',
                    value: AppFormatters.formatDate(movement.movementDate),
                    color: Get.theme.colorScheme.secondary,
                    isCompact: !isDesktop,
                  ),
                ),
              ],
            ),

            SizedBox(height: isDesktop ? 10 : 8),

            // FILA 3: Información adicional (costo, almacén, referencia, notas)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Precio/Costo (si existe)
                if (_shouldShowPrice()) ...[
                  Expanded(
                    flex: 2,
                    child: _buildInfoItem(
                      icon: Icons.attach_money,
                      label: _getPriceLabel(),
                      value: AppFormatters.formatCurrency(_getPriceValue()),
                      color: Get.theme.colorScheme.primary,
                      isCompact: !isDesktop,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 12 : 8),
                ],

                // Almacén (si existe)
                if (movement.warehouseName != null) ...[
                  Expanded(
                    flex: 2,
                    child: _buildInfoItem(
                      icon: Icons.warehouse,
                      label: 'Almacén',
                      value: movement.warehouseName!,
                      color: Get.theme.colorScheme.tertiary,
                      isCompact: !isDesktop,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 12 : 8),
                ],

                // Referencia (si existe)
                if (movement.referenceType != null &&
                    movement.referenceId != null) ...[
                  _buildReferenceInfo(isDesktop),
                  SizedBox(width: isDesktop ? 12 : 8),
                ],

                // Notas (si existen)
                if (movement.notes != null && movement.notes!.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.all(isDesktop ? 6 : 4),
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: isDesktop ? 14 : 12,
                            color: Get.theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: isDesktop ? 6 : 4),
                          Expanded(
                            child: Text(
                              movement.notes!,
                              style: Get.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                fontSize: isDesktop ? 11 : 10,
                                color: Get.theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Spacer si no hay elementos en la tercera fila
                if (movement.unitCost <= 0 &&
                    movement.warehouseName == null &&
                    (movement.referenceType == null ||
                        movement.referenceId == null) &&
                    (movement.notes == null || movement.notes!.isEmpty))
                  Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementTypeIcon(bool isDesktop) {
    IconData icon;
    Color color;

    switch (movement.type) {
      case InventoryMovementType.inbound:
        icon = Icons.arrow_downward;
        color = Colors.green;
        break;
      case InventoryMovementType.outbound:
        icon = Icons.arrow_upward;
        color = Colors.red;
        break;
      case InventoryMovementType.adjustment:
        icon = Icons.tune;
        color = Colors.blue;
        break;
      case InventoryMovementType.transfer:
      case InventoryMovementType.transferIn:
      case InventoryMovementType.transferOut:
        icon = Icons.swap_horiz;
        color = Colors.orange;
        break;
    }

    final iconSize = isDesktop ? 20.0 : 18.0;
    final iconPadding = isDesktop ? 8.0 : 6.0;

    return Container(
      padding: EdgeInsets.all(iconPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }

  Widget _buildStatusBadge(bool isDesktop) {
    Color statusColor;
    String statusText;

    switch (movement.status) {
      case InventoryMovementStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        break;
      case InventoryMovementStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Confirmado';
        break;
      case InventoryMovementStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelado';
        break;
    }

    final fontSize = isDesktop ? 11.0 : 10.0;
    final horizontalPadding = isDesktop ? 8.0 : 6.0;
    final verticalPadding = isDesktop ? 4.0 : 3.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: Get.textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isCompact,
  }) {
    final iconSize = isCompact ? 14.0 : 16.0;
    final labelFontSize = isCompact ? 10.0 : 11.0;
    final valueFontSize = isCompact ? 12.0 : 13.0;

    return Row(
      children: [
        Icon(icon, size: iconSize, color: color),
        SizedBox(width: isCompact ? 3 : 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.colorScheme.onSurfaceVariant,
                  fontSize: labelFontSize,
                ),
              ),
              Text(
                value,
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: valueFontSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatQuantity() {
    String sign = '';
    if (movement.type == InventoryMovementType.inbound ||
        movement.type == InventoryMovementType.transferIn) {
      sign = '+';
    } else if (movement.type == InventoryMovementType.outbound ||
        movement.type == InventoryMovementType.transferOut) {
      sign = '-';
    }

    return '$sign${movement.quantity}';
  }

  Color _getQuantityColor() {
    switch (movement.type) {
      case InventoryMovementType.inbound:
      case InventoryMovementType.transferIn:
        return Colors.green;
      case InventoryMovementType.outbound:
      case InventoryMovementType.transferOut:
        return Colors.red;
      case InventoryMovementType.adjustment:
        return Colors.blue;
      case InventoryMovementType.transfer:
        return Colors.orange;
    }
  }

  // Helper methods for price/cost display
  bool _shouldShowPrice() {
    // Show price for sales, cost for other movements
    if (movement.reason == InventoryMovementReason.sale &&
        movement.unitPrice != null &&
        movement.unitPrice! > 0) {
      return true;
    }
    return movement.unitCost > 0;
  }

  String _getPriceLabel() {
    if (movement.reason == InventoryMovementReason.sale &&
        movement.unitPrice != null &&
        movement.unitPrice! > 0) {
      return 'Precio venta';
    }
    return 'Costo';
  }

  double _getPriceValue() {
    if (movement.reason == InventoryMovementReason.sale &&
        movement.unitPrice != null &&
        movement.unitPrice! > 0) {
      return movement.unitPrice!;
    }
    return movement.unitCost;
  }

  Widget _buildReferenceInfo(bool isDesktop) {
    final iconSize = isDesktop ? 16.0 : 14.0;
    final textSize = isDesktop ? 12.0 : 11.0;
    final containerPadding = isDesktop ? 8.0 : 6.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToReference(),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Get.theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getReferenceIcon(),
                size: iconSize,
                color: Get.theme.colorScheme.primary,
              ),
              SizedBox(width: isDesktop ? 8 : 6),
              Text(
                _getReferenceText(),
                style: Get.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.primary,
                  fontSize: textSize,
                ),
              ),
              SizedBox(width: isDesktop ? 6 : 4),
              Icon(
                Icons.arrow_forward_ios,
                size: isDesktop ? 12 : 10,
                color: Get.theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getReferenceIcon() {
    switch (movement.referenceType?.toLowerCase()) {
      case 'purchase_order':
        return Icons.shopping_cart;
      case 'sale':
      case 'invoice_paid':
        return Icons.receipt_long;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.link;
    }
  }

  String _getReferenceText() {
    switch (movement.referenceType?.toLowerCase()) {
      case 'purchase_order':
        return 'Orden de compra';
      case 'sale':
      case 'invoice_paid':
        return 'Ver factura';
      case 'transfer':
        return 'Transferencia: ${_formatReferenceId()}';
      default:
        return 'Ref: ${movement.referenceType!.toUpperCase()}';
    }
  }

  String _formatReferenceId() {
    final ref = movement.referenceId!;
    return ref.length > 8 ? '#${ref.substring(ref.length - 8)}' : '#$ref';
  }

  void _navigateToReference() {
    switch (movement.referenceType?.toLowerCase()) {
      case 'purchase_order':
        Get.toNamed(
          '/purchase-orders/detail/${movement.referenceId}',
          arguments: {'purchaseOrderId': movement.referenceId},
        );
        break;
      case 'sale':
      case 'invoice_paid':
        Get.toNamed(
          '/invoices/detail/${movement.referenceId}',
          arguments: {'invoiceId': movement.referenceId},
        );
        break;
      default:
        Get.snackbar(
          'Información',
          'Referencia: ${movement.referenceType} - ${movement.referenceId}',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;
    }
  }
}
