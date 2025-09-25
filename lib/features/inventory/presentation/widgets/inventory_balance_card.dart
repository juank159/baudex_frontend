// lib/features/inventory/presentation/widgets/inventory_balance_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/inventory_balance.dart';

class InventoryBalanceCard extends StatelessWidget {
  final InventoryBalance balance;
  final bool isCompact;
  final VoidCallback? onKardexTap;
  final VoidCallback? onBatchesTap;
  final VoidCallback? onMovementsTap;

  const InventoryBalanceCard({
    super.key,
    required this.balance,
    this.isCompact = false,
    this.onKardexTap,
    this.onBatchesTap,
    this.onMovementsTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    
    // Altura ajustada para evitar overflow de 66 pixels
    double cardHeight;
    
    if (isDesktop) {
      cardHeight = 120; // 50 + 66 + buffer = funcional
    } else if (isTablet) {
      cardHeight = 140; // 72 + 66 + buffer = funcional
    } else {
      cardHeight = 130; // 60 + 66 + buffer = funcional
    }
    
    return Container(
      height: cardHeight,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
        border: Border.all(
          color: _getStockStatusColor().withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // Para efectos de hover
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 6 : 8),
            child: isCompact ? _buildCompactView() : _buildThreeRowLayout(isDesktop, isTablet),
          ),
        ),
      ),
    );
  }

  Widget _buildThreeRowLayout(bool isDesktop, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FILA 1: Nombre del producto y estado
        _buildNameAndStatusRow(isDesktop, isTablet),
        
        const SizedBox(height: 4),
        
        // FILA 2: Información de valores
        _buildValuesCardsRow(isDesktop, isTablet),
        
        const SizedBox(height: 4),
        
        // FILA 3: Botones de acción
        _buildActionButtonsRow(isDesktop, isTablet),
      ],
    );
  }

  Widget _buildNameAndStatusRow(bool isDesktop, bool isTablet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Indicador de estado
          Container(
            width: isDesktop ? 8 : isTablet ? 7 : 6,
            height: isDesktop ? 8 : isTablet ? 7 : 6,
            decoration: BoxDecoration(
              color: _getStockStatusColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          
          // Nombre del producto
          Expanded(
            child: Text(
              balance.productName,
              style: TextStyle(
                fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          
          // Status badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 6 : 4,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: _getStockStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              balance.stockStatus,
              style: TextStyle(
                fontSize: isDesktop ? 10 : isTablet ? 9 : 8,
                fontWeight: FontWeight.w600,
                color: _getStockStatusColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuesCardsRow(bool isDesktop, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Stock con icono
          Expanded(
            child: Row(
              children: [
                Icon(Icons.inventory_2, size: isDesktop ? 14 : isTablet ? 13 : 12, color: Colors.grey),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Stock',
                      style: TextStyle(
                        fontSize: isDesktop ? 10 : isTablet ? 9 : 8,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '${balance.totalQuantity}',
                      style: TextStyle(
                        fontSize: isDesktop ? 12 : isTablet ? 11 : 10,
                        fontWeight: FontWeight.bold,
                        color: _getStockStatusColor(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Mínimo con icono
          Expanded(
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: isDesktop ? 14 : isTablet ? 13 : 12, color: Colors.grey),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Mínimo',
                      style: TextStyle(
                        fontSize: isDesktop ? 10 : isTablet ? 9 : 8,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '${balance.minStock}',
                      style: TextStyle(
                        fontSize: isDesktop ? 12 : isTablet ? 11 : 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Valor
          Text(
            AppFormatters.formatCurrency(balance.totalValue),
            style: TextStyle(
              fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
              fontWeight: FontWeight.bold,
              color: _getStockStatusColor(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtonsRow(bool isDesktop, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Kardex',
              Icons.timeline_rounded,
              AppColors.primary,
              onKardexTap,
              isDesktop,
              isTablet,
            ),
          ),
          Expanded(
            child: _buildActionButton(
              'Lotes',
              Icons.inventory_rounded,
              Colors.orange.shade600,
              onBatchesTap,
              isDesktop,
              isTablet,
            ),
          ),
          Expanded(
            child: _buildActionButton(
              'Movtos',
              Icons.swap_horiz_rounded,
              Colors.grey.shade600,
              onMovementsTap,
              isDesktop,
              isTablet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
    bool isDesktop,
    bool isTablet,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: isDesktop ? 14 : isTablet ? 13 : 12,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: isDesktop ? 11 : isTablet ? 10 : 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildCompactView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name and SKU
        Text(
          balance.productName,
          style: Get.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 8),

        // Stock quantity with indicator
        Row(
          children: [
            Icon(
              _getStockStatusIcon(),
              color: _getStockStatusColor(),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '${balance.totalQuantity}',
              style: Get.textTheme.titleSmall?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getStockStatusColor(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Value
        Text(
          AppFormatters.formatCurrency(balance.totalValue),
          style: Get.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
            fontSize: 10,
          ),
        ),

        const SizedBox(height: 8),

        // Progress bar
        LinearProgressIndicator(
          value: balance.stockLevel.clamp(0.0, 1.0),
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(_getStockStatusColor()),
        ),

        const SizedBox(height: 6),

        // Status text
        Text(
          balance.stockStatus,
          style: Get.textTheme.bodySmall?.copyWith(
            color: _getStockStatusColor(),
            fontWeight: FontWeight.w500,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Color _getStockStatusColor() {
    if (balance.isOutOfStock) return Colors.red;
    if (balance.isLowStock) return Colors.orange;
    if (balance.isOverStock) return Colors.blue;
    return Colors.green;
  }

  IconData _getStockStatusIcon() {
    if (balance.isOutOfStock) return Icons.error;
    if (balance.isLowStock) return Icons.warning;
    if (balance.isOverStock) return Icons.trending_up;
    return Icons.check_circle;
  }
}