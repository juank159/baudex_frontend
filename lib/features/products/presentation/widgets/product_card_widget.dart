// lib/features/products/presentation/widgets/product_card_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';

class ProductCardWidget extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const ProductCardWidget({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  ProductPrice? get _displayPrice {
    if (product.prices != null && product.prices!.isNotEmpty) {
      try {
        return product.prices!.firstWhere(
          (p) => p.type.displayName.toLowerCase() == 'precio al público',
        );
      } catch (e) {
        return product.prices!.first;
      }
    }
    return product.defaultPrice;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.isMobile(context)
        ? _buildMobileCard(context)
        : _buildDesktopCard(context);
  }

  Widget _buildMobileCard(BuildContext context) {
    final price = _displayPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Header compacto
                Row(
                  children: [
                    // Product icon/avatar con gradiente
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: _getStockGradient(),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _getStockColor().withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _getProductIcon(),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info principal compacta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ElegantLightTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${product.sku}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ElegantLightTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Badge de stock con gradiente
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: _getStockGradient().scale(0.3),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _getStockColor().withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStockIcon(),
                            size: 10,
                            color: _getStockColor(),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _getStockText(),
                            style: TextStyle(
                              color: _getStockColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Info adicional ultra compacta
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoChip(
                        Icons.inventory_2_outlined,
                        AppFormatters.formatNumber(product.stock),
                        ElegantLightTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCompactInfoChip(
                        Icons.sell_outlined,
                        price != null
                            ? AppFormatters.formatPrice(price.finalAmount)
                            : 'N/A',
                        Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCompactInfoChip(
                        Icons.category_outlined,
                        product.category?.name ?? 'Sin cat.',
                        ElegantLightTheme.accentOrange,
                      ),
                    ),
                  ],
                ),

                if (showActions) ...[
                  const SizedBox(height: 8),
                  _buildMobileActions(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    final price = _displayPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: ElegantLightTheme.primaryBlue.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product icon con gradiente
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _getStockGradient(),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _getStockColor().withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getProductIcon(),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Info principal - Columna izquierda
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nombre del producto
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // SKU y código de barras
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Text(
                                'SKU: ${product.sku}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (product.barcode != null && product.barcode!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.barcode_reader, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Text(
                                  'Código: ${product.barcode}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Info adicional - Columna centro
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stock
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 14, color: ElegantLightTheme.primaryBlue),
                          const SizedBox(width: 4),
                          Text(
                            'Stock:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${AppFormatters.formatNumber(product.stock)} ${product.unit ?? 'uds'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ElegantLightTheme.primaryBlue,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Precio de venta
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sell_outlined, size: 13, color: Colors.green.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'Precio:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            price != null
                                ? AppFormatters.formatPrice(price.finalAmount)
                                : 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),

                      // Categoría
                      if (product.category != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.category_outlined, size: 13, color: ElegantLightTheme.accentOrange),
                            const SizedBox(width: 6),
                            Text(
                              'Cat:',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              product.category!.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ElegantLightTheme.accentOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Estado y acciones - Columna derecha
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge de estado de stock
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: _getStockGradient().scale(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStockColor().withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStockIcon(),
                            size: 14,
                            color: _getStockColor(),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStockText(),
                            style: TextStyle(
                              color: _getStockColor(),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botones de acción
                    if (showActions)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onEdit != null)
                            _buildCompactActionButton(
                              Icons.edit_outlined,
                              'Editar',
                              ElegantLightTheme.primaryBlue,
                              onEdit!,
                            ),
                          if (onDelete != null) ...[
                            const SizedBox(width: 6),
                            _buildCompactActionButton(
                              Icons.delete_outline,
                              'Eliminar',
                              Colors.red.shade600,
                              onDelete!,
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactActionButton(IconData icon, String tooltip, Color color, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActions() {
    return Row(
      children: [
        if (onEdit != null)
          Expanded(
            child: _buildActionButton(
              'Editar',
              Icons.edit,
              ElegantLightTheme.primaryBlue,
              onEdit!,
            ),
          ),
        if (onEdit != null && onDelete != null)
          const SizedBox(width: 8),
        if (onDelete != null)
          Expanded(
            child: _buildActionButton(
              'Eliminar',
              Icons.delete,
              Colors.red.shade600,
              onDelete!,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    final gradient = _getGradientForColor(color);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          gradient: gradient.scale(0.2),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  IconData _getProductIcon() {
    if (product.type == ProductType.service) {
      return Icons.handyman;
    }
    return Icons.shopping_bag;
  }

  Color _getStockColor() {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return Colors.red.shade600;
    } else if (product.isLowStock) {
      return ElegantLightTheme.accentOrange;
    } else {
      return Colors.green.shade600;
    }
  }

  LinearGradient _getStockGradient() {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return ElegantLightTheme.errorGradient;
    } else if (product.isLowStock) {
      return ElegantLightTheme.warningGradient;
    } else {
      return ElegantLightTheme.successGradient;
    }
  }

  LinearGradient _getGradientForColor(Color color) {
    if (color == ElegantLightTheme.primaryBlue) {
      return ElegantLightTheme.primaryGradient;
    } else if (color == Colors.green.shade600) {
      return ElegantLightTheme.successGradient;
    } else if (color == Colors.red.shade600) {
      return ElegantLightTheme.errorGradient;
    } else {
      return ElegantLightTheme.warningGradient;
    }
  }

  IconData _getStockIcon() {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return Icons.remove_circle;
    } else if (product.isLowStock) {
      return Icons.warning;
    } else {
      return Icons.check_circle;
    }
  }

  String _getStockText() {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return 'SIN STOCK';
    } else if (product.isLowStock) {
      return 'STOCK BAJO';
    } else {
      return 'EN STOCK';
    }
  }
}
