// lib/features/purchase_orders/presentation/widgets/purchase_order_card_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/purchase_order.dart';

class PurchaseOrderCardWidget extends StatelessWidget {
  final PurchaseOrder purchaseOrder;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onApprove;
  final bool showActions;

  const PurchaseOrderCardWidget({
    super.key,
    required this.purchaseOrder,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onApprove,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    // Determinar altura basada en el tamaño de pantalla
    double minHeight;
    double maxHeight;
    double padding;

    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1200) {
      // Desktop: reducir altura 40% para hacer cards más compactas
      minHeight = 30; // Reducción adicional del 40%
      maxHeight = 50; // Reducción adicional del 40%
      padding = 6;
    } else if (screenWidth >= 800) {
      // Tablet: reducir 40% adicional (total 64% de reducción)
      minHeight = 43; // 72 * 0.6
      maxHeight = 72; // 120 * 0.6
      padding = 8;
    } else {
      // Mobile: reducir 40% adicional (total 70% de reducción)
      minHeight = 36; // 60 * 0.6
      maxHeight = 60; // 100 * 0.6
      padding = 6;
    }

    return Container(
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Determinar tamaños de fuente basados en el tamaño de pantalla
    double titleFontSize;
    double bodyFontSize;
    double smallFontSize;
    double totalFontSize;
    double iconSize;
    double verticalSpacing;
    double horizontalSpacing;

    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1200) {
      // Desktop: reducir texto 30% y espaciado vertical 40% adicional
      titleFontSize = 10; // 14 * 0.7
      bodyFontSize = 8; // 12 * 0.7 (redondeado)
      smallFontSize = 7; // 10 * 0.7
      totalFontSize = 10; // 14 * 0.7
      iconSize = 10; // 14 * 0.7
      verticalSpacing = 1; // 3 * 0.6 (reducción 40% adicional)
      horizontalSpacing = 4; // 8 * 0.5
    } else if (screenWidth >= 800) {
      // Tablet: reducir texto 40%
      titleFontSize = 8; // 13 * 0.6 (redondeado)
      bodyFontSize = 7; // 11 * 0.6 (redondeado)
      smallFontSize = 6; // 10 * 0.6
      totalFontSize = 8; // 13 * 0.6 (redondeado)
      iconSize = 8; // 13 * 0.6 (redondeado)
      verticalSpacing = 2; // 5 * 0.4
      horizontalSpacing = 3; // 7 * 0.4 (redondeado)
    } else {
      // Mobile: reducir texto 40%
      titleFontSize = 7; // 12 * 0.6 (redondeado)
      bodyFontSize = 6; // 10 * 0.6
      smallFontSize = 5; // 9 * 0.6 (redondeado)
      totalFontSize = 7; // 12 * 0.6 (redondeado)
      iconSize = 7; // 12 * 0.6 (redondeado)
      verticalSpacing = 2; // 4 * 0.5
      horizontalSpacing = 3; // 6 * 0.5
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fila principal con información básica
        Row(
          children: [
            // Indicador de estado
            Container(
              width: iconSize - 2,
              height: iconSize - 2,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: horizontalSpacing),

            // Número de orden
            Expanded(
              child: Text(
                purchaseOrder.orderNumber ?? 'Sin número',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            // Estado
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalSpacing.clamp(2.0, 6.0),
                vertical: 1.5,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: smallFontSize,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: verticalSpacing),

        // Fila inferior con proveedor, fecha y total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Proveedor y fecha en columna
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Proveedor
                  Row(
                    children: [
                      Icon(Icons.business, size: iconSize, color: Colors.grey),
                      SizedBox(width: (horizontalSpacing - 1).clamp(1.0, 4.0)),
                      Expanded(
                        child: Text(
                          purchaseOrder.supplierName ?? 'Sin proveedor',
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: (verticalSpacing - 1).clamp(1.0, 3.0)),

                  // Fecha
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: iconSize,
                        color: Colors.grey,
                      ),
                      SizedBox(width: (horizontalSpacing - 1).clamp(1.0, 4.0)),
                      Expanded(
                        child: Text(
                          AppFormatters.formatDate(purchaseOrder.orderDate),
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Total
            Text(
              AppFormatters.formatCurrency(purchaseOrder.totalAmount),
              style: TextStyle(
                fontSize: totalFontSize,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (purchaseOrder.status) {
      case PurchaseOrderStatus.draft:
        return Colors.grey;
      case PurchaseOrderStatus.pending:
        return Colors.orange;
      case PurchaseOrderStatus.approved:
        return Colors.blue;
      case PurchaseOrderStatus.rejected:
        return Colors.red;
      case PurchaseOrderStatus.sent:
        return Colors.purple;
      case PurchaseOrderStatus.partiallyReceived:
        return Colors.amber;
      case PurchaseOrderStatus.received:
        return Colors.green;
      case PurchaseOrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (purchaseOrder.status) {
      case PurchaseOrderStatus.draft:
        return 'Borrador';
      case PurchaseOrderStatus.pending:
        return 'Pendiente';
      case PurchaseOrderStatus.approved:
        return 'Aprobada';
      case PurchaseOrderStatus.rejected:
        return 'Rechazada';
      case PurchaseOrderStatus.sent:
        return 'Enviada';
      case PurchaseOrderStatus.partiallyReceived:
        return 'Parcialmente Recibida';
      case PurchaseOrderStatus.received:
        return 'Recibida';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelada';
    }
  }
}
