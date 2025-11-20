// lib/features/products/presentation/widgets/product_card_widget.dart
import 'package:flutter/material.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive_helper.dart';
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
      elevation: isSelected ? 4 : 0.5,
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.isMobile(context) ? 1 : 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side:
            isSelected
                ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: ResponsiveHelper.isMobile(context) 
              ? const EdgeInsets.all(4)  // 75% reducción para móviles
              : const EdgeInsets.all(7),  // 40% reducción para desktop
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
            _buildProductImage(context, ResponsiveHelper.isMobile(context) ? 25 : 45),
            SizedBox(width: ResponsiveHelper.isMobile(context) ? 4 : 8),

            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.isMobile(context) ? 12 : 13,  // Aumentado para móvil, mantenido desktop
                      fontWeight: FontWeight.bold,
                      color: Colors.black,  // Asegurar color negro en ambos
                    ),
                    maxLines: ResponsiveHelper.isMobile(context) ? 2 : 1,  // Más líneas en móvil
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveHelper.isMobile(context) ? 2 : 3),  // Más espacio
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
                      fontSize: ResponsiveHelper.isMobile(context) ? 8 : 13,  // 50% vs 20% reducción
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  if (price.hasDiscount)
                    Text(
                      AppFormatters.formatPrice(price.amount),
                      style: TextStyle(
                        fontSize: ResponsiveHelper.isMobile(context) ? 5 : 8,  // 50% vs 20% reducción
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ] else
                  Text(
                    'Sin precio',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.isMobile(context) ? 5 : 8, 
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Información adicional
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                // ✅ CANTIDAD FORMATEADA
                'Stock: ${AppFormatters.formatNumber(product.stock)} ${product.unit ?? "pcs"}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ),
            if (product.category != null)
              Text(
                product.category!.name,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
          ],
        ),

        // Acciones
        if (showActions) ...[
          const SizedBox(height: 8),
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
        _buildProductImage(context, 48),  // 40% menos que 80
        const SizedBox(width: 10),  // 40% menos que 16

        // Información principal
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 13,  // Aumentado para mejor visibilidad
                  fontWeight: FontWeight.bold,
                  color: Colors.black,  // Asegurar color negro en desktop
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),  // Más espacio sin SKU
              if (product.description != null) ...[
                const SizedBox(height: 2),  // 50% menos que 4
                Text(
                  product.description!,
                  style: TextStyle(fontSize: 7, color: Colors.grey.shade500),  // 40% menos que 12
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 5),  // 40% menos que 8
              Row(
                children: [
                  _buildStockChip(context),
                  const SizedBox(width: 8),
                  _buildStatusChip(context),
                  if (product.category != null) ...[
                    const SizedBox(width: 5),  // 40% menos que 8
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
                          fontSize: 6,  // 40% menos que 10
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
                  fontSize: 7,  // 40% menos que 12
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                // ✅ CANTIDAD FORMATEADA
                AppFormatters.formatNumber(product.stock),
                style: TextStyle(
                  fontSize: 14,
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
                  fontSize: 7,  // 40% menos que 12
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
                      fontSize: 10,
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
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isMobile(context) ? 3 : 6, 
        vertical: ResponsiveHelper.isMobile(context) ? 1 : 1.5,
      ),
      decoration: BoxDecoration(
        color: stockColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveHelper.isMobile(context) ? 6 : 8),
      ),
      child: Text(
        stockText,
        style: TextStyle(
          fontSize: ResponsiveHelper.isMobile(context) ? 5 : 8,  // 50% vs 20% reducción
          color: stockColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isMobile(context) ? 3 : 6, 
        vertical: ResponsiveHelper.isMobile(context) ? 1 : 1.5,
      ),
      decoration: BoxDecoration(
        color:
            product.isActive ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(ResponsiveHelper.isMobile(context) ? 6 : 8),
      ),
      child: Text(
        product.isActive ? 'ACTIVO' : 'INACTIVO',
        style: TextStyle(
          fontSize: ResponsiveHelper.isMobile(context) ? 5 : 8,  // 50% vs 20% reducción
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
            child: IconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: onEdit,
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade700,
                minimumSize: Size(ResponsiveHelper.isMobile(context) ? 24 : 28, ResponsiveHelper.isMobile(context) ? 24 : 28),
                padding: EdgeInsets.zero,
              ),
              tooltip: 'Editar',
            ),
          ),
          SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
          Expanded(
            child: IconButton(
              icon: const Icon(Icons.delete, size: 16),
              onPressed: onDelete,
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
                minimumSize: Size(ResponsiveHelper.isMobile(context) ? 24 : 28, ResponsiveHelper.isMobile(context) ? 24 : 28),
                padding: EdgeInsets.zero,
              ),
              tooltip: 'Eliminar',
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade700,
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
              tooltip: 'Editar',
            ),
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) / 2),
          SizedBox(
            width: double.infinity,
            child: IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: onDelete,
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
              tooltip: 'Eliminar',
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
