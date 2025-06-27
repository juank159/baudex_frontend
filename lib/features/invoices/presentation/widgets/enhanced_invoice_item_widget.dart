// lib/features/invoices/presentation/widgets/enhanced_invoice_item_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/invoice_form_models.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_price.dart';
import 'price_selector_widget.dart';

class EnhancedInvoiceItemWidget extends StatelessWidget {
  final InvoiceItemFormData item;
  final int index;
  final Function(InvoiceItemFormData) onUpdate;
  final VoidCallback onRemove;
  final Product? product; // ✅ Agregar producto para acceder a precios
  final bool showPriceSelector;

  const EnhancedInvoiceItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.onUpdate,
    required this.onRemove,
    this.product,
    this.showPriceSelector = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con producto y acciones
          Row(
            children: [
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.unit}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (product != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  product!.isLowStock
                                      ? Colors.red.shade50
                                      : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Stock: ${product!.stock.toInt()}',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    product!.isLowStock
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Botón eliminar
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle),
                color: Colors.red.shade600,
                tooltip: 'Eliminar producto',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Controles de cantidad y precio
          Row(
            children: [
              // Cantidad
              Expanded(flex: 2, child: _buildQuantityControl(context)),

              const SizedBox(width: 12),

              // Precio unitario
              Expanded(flex: 3, child: _buildPriceControl(context)),

              const SizedBox(width: 12),

              // Subtotal
              Expanded(flex: 2, child: _buildSubtotalDisplay(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Botón menos
          InkWell(
            onTap:
                item.quantity > 1
                    ? () => _updateQuantity(item.quantity - 1)
                    : null,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    item.quantity > 1
                        ? Colors.grey.shade100
                        : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${item.quantity.toInt()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // Botón más
          InkWell(
            onTap: () => _updateQuantity(item.quantity + 1),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Icon(Icons.add, size: 16, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceControl(BuildContext context) {
    return InkWell(
      onTap:
          showPriceSelector && product != null
              ? () => _showPriceSelector(context)
              : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          color:
              showPriceSelector && product != null
                  ? Colors.blue.shade50
                  : Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Precio Unit.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showPriceSelector && product != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.edit, size: 12, color: Colors.blue.shade600),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '\$${item.unitPrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    showPriceSelector && product != null
                        ? Colors.blue.shade700
                        : Colors.black,
              ),
            ),

            // Mostrar tipo de precio si está disponible
            if (product?.prices?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(
                _getCurrentPriceType(),
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubtotalDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subtotal',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '\$${item.subtotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentPriceType() {
    if (product?.prices?.isEmpty == true) return 'Sin precios';

    // Buscar el precio que coincide con el precio actual
    final matchingPrice = product?.prices?.firstWhereOrNull(
      (price) => price.finalAmount == item.unitPrice,
    );

    if (matchingPrice != null) {
      return matchingPrice.type.displayName;
    }

    return 'Precio personalizado';
  }

  void _updateQuantity(double newQuantity) {
    // Verificar stock máximo si tenemos el producto
    if (product != null && newQuantity > product!.stock) {
      Get.snackbar(
        'Stock Insuficiente',
        'Solo hay ${product!.stock} unidades disponibles',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.warning, color: Colors.red),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final updatedItem = item.copyWith(quantity: newQuantity);
    onUpdate(updatedItem);
  }

  void _showPriceSelector(BuildContext context) {
    if (product == null) return;

    showDialog(
      context: context,
      builder:
          (context) => PriceSelectorWidget(
            product: product!,
            currentPrice: item.unitPrice,
            onPriceChanged: (newPrice) {
              final updatedItem = item.copyWith(unitPrice: newPrice);
              onUpdate(updatedItem);

              // Mostrar confirmación
              Get.snackbar(
                'Precio Actualizado',
                '${item.description}: \$${newPrice.toStringAsFixed(2)}',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.green.shade100,
                colorText: Colors.green.shade800,
                icon: const Icon(Icons.check_circle, color: Colors.green),
                duration: const Duration(seconds: 2),
              );
            },
          ),
    );
  }
}
