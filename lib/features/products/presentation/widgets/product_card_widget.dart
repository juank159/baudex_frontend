// lib/features/products/presentation/widgets/product_card_widget.dart
import 'package:flutter/material.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';

class ProductCardWidget extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool showActions;

  const ProductCardWidget({
    Key? key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
    this.showActions = true,
  }) : super(key: key);

  // ✅ NUEVO: Método para obtener el precio correcto
  ProductPrice? get _displayPrice {
    if (product.prices != null && product.prices!.isNotEmpty) {
      try {
        // Intenta encontrar el "Precio al Público"
        return product.prices!.firstWhere(
          (p) => p.type.displayName.toLowerCase() == 'precio al público',
        );
      } catch (e) {
        // Si no lo encuentra, devuelve el primer precio de la lista
        return product.prices!.first;
      }
    }
    // Si no hay lista de precios, usa el `defaultPrice`
    return product.defaultPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isSelected
                ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: ResponsiveHelper.getPadding(context),
          child:
              ResponsiveHelper.isMobile(context)
                  ? _buildMobileLayout(context)
                  : _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final price = _displayPrice;

    return Column(
      children: [
        Row(
          children: [
            // Imagen del producto
            _buildProductImage(context, 60),
            const SizedBox(width: 12),

            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${product.sku}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStockChip(context),
                      const SizedBox(width: 8),
                      _buildStatusChip(context),
                    ],
                  ),
                ],
              ),
            ),

            // ✅ PRECIO CORREGIDO Y FORMATEADO
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (price != null) ...[
                  Text(
                    AppFormatters.formatPrice(price.finalAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  if (price.hasDiscount)
                    Text(
                      AppFormatters.formatPrice(price.amount),
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ] else
                  Text(
                    'Sin precio',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ],
        ),

        // Información adicional
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                // ✅ CANTIDAD FORMATEADA
                'Stock: ${AppFormatters.formatNumber(product.stock)} ${product.unit ?? "pcs"}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            if (product.category != null)
              Text(
                product.category!.name,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),

        // Acciones
        if (showActions) ...[
          const SizedBox(height: 12),
          _buildActions(context),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final price = _displayPrice;

    return Row(
      children: [
        // Imagen del producto
        _buildProductImage(context, 80),
        const SizedBox(width: 16),

        // Información principal
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'SKU: ${product.sku}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              if (product.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  product.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStockChip(context),
                  const SizedBox(width: 8),
                  _buildStatusChip(context),
                  if (product.category != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.category!.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
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

        // Stock
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Stock Actual',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                // ✅ CANTIDAD FORMATEADA
                AppFormatters.formatNumber(product.stock),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getStockColor(),
                ),
              ),
              Text(
                product.unit ?? 'pcs',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),

        // Precio
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                // ✅ USA EL NOMBRE DEL PRECIO ENCONTRADO
                price?.type.displayName ?? 'Precio',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              // ✅ PRECIO CORREGIDO Y FORMATEADO
              if (price != null) ...[
                Text(
                  AppFormatters.formatPrice(price.finalAmount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                if (price.hasDiscount)
                  Text(
                    AppFormatters.formatPrice(price.amount),
                    style: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ] else
                Text(
                  'Sin precio',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),

        // Acciones
        if (showActions) SizedBox(width: 120, child: _buildActions(context)),
      ],
    );
  }

  Widget _buildProductImage(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        image:
            product.primaryImage != null
                ? DecorationImage(
                  image: NetworkImage(product.primaryImage!),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      child:
          product.primaryImage == null
              ? Icon(
                Icons.inventory_2,
                size: size * 0.5,
                color: Colors.grey.shade400,
              )
              : null,
    );
  }

  Widget _buildStockChip(BuildContext context) {
    Color stockColor = _getStockColor();
    String stockText = _getStockText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: stockColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        stockText,
        style: TextStyle(
          fontSize: 10,
          color: stockColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:
            product.isActive ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        product.isActive ? 'ACTIVO' : 'INACTIVO',
        style: TextStyle(
          fontSize: 10,
          color:
              product.isActive ? Colors.green.shade700 : Colors.orange.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Editar',
              icon: Icons.edit,
              type: ButtonType.outline,
              onPressed: onEdit,
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 12,
              ),
              height: ResponsiveHelper.getHeight(
                context,
                mobile: 32,
                tablet: 36,
                desktop: 36,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
          Expanded(
            child: CustomButton(
              text: 'Eliminar',
              icon: Icons.delete,
              backgroundColor: Colors.red,
              onPressed: onDelete,
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 12,
              ),
              height: ResponsiveHelper.getHeight(
                context,
                mobile: 32,
                tablet: 36,
                desktop: 36,
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Editar',
              icon: Icons.edit,
              type: ButtonType.outline,
              onPressed: onEdit,
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 12,
              ),
              height: ResponsiveHelper.getHeight(
                context,
                mobile: 28,
                tablet: 32,
                desktop: 32,
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) / 2),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Eliminar',
              icon: Icons.delete,
              backgroundColor: Colors.red,
              onPressed: onDelete,
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 12,
              ),
              height: ResponsiveHelper.getHeight(
                context,
                mobile: 28,
                tablet: 32,
                desktop: 32,
              ),
            ),
          ),
        ],
      );
    }
  }

  Color _getStockColor() {
    if (product.stock <= 0) {
      return Colors.red;
    } else if (product.isLowStock) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStockText() {
    if (product.stock <= 0) {
      return 'SIN STOCK';
    } else if (product.isLowStock) {
      return 'STOCK BAJO';
    } else {
      return 'EN STOCK';
    }
  }
}
