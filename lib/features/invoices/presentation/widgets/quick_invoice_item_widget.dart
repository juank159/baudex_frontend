// lib/features/invoices/presentation/widgets/quick_invoice_item_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../invoices/data/models/invoice_form_models.dart';

class QuickInvoiceItemWidget extends StatelessWidget {
  final InvoiceItemFormData item;
  final int index;
  final Function(double) onQuantityChanged;
  final VoidCallback onRemove;

  const QuickInvoiceItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Número del item
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${item.unitPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ' x ${item.unit}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Controles de cantidad
            _buildQuantityControls(context),
            const SizedBox(width: 12),

            // Subtotal y botón eliminar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón disminuir
          GestureDetector(
            onTap:
                item.quantity > 1
                    ? () => onQuantityChanged(item.quantity - 1)
                    : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    item.quantity > 1
                        ? Colors.grey.shade100
                        : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Icon(
                Icons.remove,
                size: 16,
                color:
                    item.quantity > 1
                        ? Colors.grey.shade700
                        : Colors.grey.shade400,
              ),
            ),
          ),

          // Cantidad
          Container(
            width: 40,
            height: 32,
            decoration: const BoxDecoration(color: Colors.white),
            child: Center(
              child: Text(
                item.quantity.toInt().toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Botón aumentar
          GestureDetector(
            onTap: () => onQuantityChanged(item.quantity + 1),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Icon(Icons.add, size: 16, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
