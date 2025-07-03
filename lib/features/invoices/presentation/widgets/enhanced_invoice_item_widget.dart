// lib/features/invoices/presentation/widgets/compact_invoice_item_widget.dart
import 'package:baudex_desktop/app/core/utils/responsive.dart';
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
  final Product? product;
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildDesktopLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Primera fila: Nombre del producto y eliminar
        Row(
          children: [
            Expanded(child: _buildProductName(context)),
            _buildRemoveButton(context),
          ],
        ),
        const SizedBox(height: 8),
        // Segunda fila: Controles
        Row(
          children: [
            Expanded(flex: 2, child: _buildQuantityControl(context)),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: _buildPriceControl(context)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: _buildSubtotalDisplay(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Nombre del producto
        Expanded(flex: 4, child: _buildProductName(context)),
        const SizedBox(width: 12),

        // Cantidad
        SizedBox(width: 120, child: _buildQuantityControl(context)),
        const SizedBox(width: 12),

        // Precio unitario
        SizedBox(width: 140, child: _buildPriceControl(context)),
        const SizedBox(width: 12),

        // Subtotal
        SizedBox(width: 120, child: _buildSubtotalDisplay(context)),
        const SizedBox(width: 8),

        // Eliminar
        _buildRemoveButton(context),
      ],
    );
  }

  Widget _buildProductName(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
          maxLines: context.isMobile ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildUnitBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        item.unit ?? 'pcs', // ✅ Valor por defecto si es null
        style: TextStyle(
          fontSize: 10,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStockBadge() {
    final isLowStock = product?.isLowStock ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Stock: ${product!.stock.toInt()}',
        style: TextStyle(
          fontSize: 10,
          color: isLowStock ? Colors.red.shade700 : Colors.green.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildQuantityControl(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Botón menos
          _buildQuantityButton(
            icon: Icons.remove,
            onTap:
                item.quantity > 1
                    ? () => _updateQuantity(item.quantity - 1)
                    : null,
            enabled: item.quantity > 1,
            isLeft: true,
          ),

          // Cantidad
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                '${item.quantity.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // Botón más
          _buildQuantityButton(
            icon: Icons.add,
            onTap: () => _updateQuantity(item.quantity + 1),
            enabled: true,
            isLeft: false,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool enabled,
    required bool isLeft,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.only(
        topLeft: isLeft ? const Radius.circular(6) : Radius.zero,
        bottomLeft: isLeft ? const Radius.circular(6) : Radius.zero,
        topRight: !isLeft ? const Radius.circular(6) : Radius.zero,
        bottomRight: !isLeft ? const Radius.circular(6) : Radius.zero,
      ),
      child: Container(
        width: 32,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? Colors.grey.shade100 : Colors.grey.shade50,
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? const Radius.circular(6) : Radius.zero,
            bottomLeft: isLeft ? const Radius.circular(6) : Radius.zero,
            topRight: !isLeft ? const Radius.circular(6) : Radius.zero,
            bottomRight: !isLeft ? const Radius.circular(6) : Radius.zero,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.grey.shade700 : Colors.grey.shade400,
        ),
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
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          color:
              showPriceSelector && product != null
                  ? Colors.blue.shade50
                  : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${item.unitPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          showPriceSelector && product != null
                              ? Colors.blue.shade700
                              : Colors.black87,
                    ),
                  ),
                  if (product?.prices?.isNotEmpty == true && !context.isMobile)
                    Text(
                      _getCurrentPriceType(),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            if (showPriceSelector && product != null)
              Icon(Icons.edit, size: 14, color: Colors.blue.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtotalDisplay(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!context.isMobile)
            Text(
              'Subtotal',
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          Text(
            '\$${item.subtotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: context.isMobile ? 14 : 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context) {
    return IconButton(
      onPressed: onRemove,
      icon: const Icon(Icons.delete_outline),
      color: Colors.red.shade600,
      tooltip: 'Eliminar',
      iconSize: context.isMobile ? 20 : 18,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }

  String _getCurrentPriceType() {
    if (product?.prices?.isEmpty == true) return 'Sin precios';

    final matchingPrice = product?.prices?.firstWhereOrNull(
      (price) => price.finalAmount == item.unitPrice,
    );

    if (matchingPrice != null) {
      return matchingPrice.type.displayName;
    }

    return 'Personalizado';
  }

  void _updateQuantity(double newQuantity) {
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

              Get.snackbar(
                'Precio Actualizado',
                '${item.description}: \$${newPrice.toStringAsFixed(0)}',
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
