// lib/features/products/presentation/widgets/product_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../controllers/products_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';

class ProductFilterWidget extends GetView<ProductsController> {
  const ProductFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.responsive(
      context,
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopCompactLayout(context), // ✅ Nueva versión compacta
    );
  }

  // ==================== LAYOUT DESKTOP COMPACTO ====================

  Widget _buildDesktopCompactLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Header compacto de filtros
        _buildCompactFilterHeader(context),
        
        const SizedBox(height: 12),
        
        // ✅ Filtros organizados en cards compactas
        _buildCompactFilterSections(context),
      ],
    );
  }

  Widget _buildCompactFilterHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtros Avanzados',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Obx(() {
                  final activeCount = _getActiveFilterCount();
                  return Text(
                    activeCount > 0 ? '$activeCount filtro${activeCount > 1 ? 's' : ''} activo${activeCount > 1 ? 's' : ''}' : 'Sin filtros activos',
                    style: TextStyle(
                      fontSize: 10,
                      color: activeCount > 0 ? Colors.orange.shade700 : Colors.grey.shade600,
                      fontWeight: activeCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                  );
                }),
              ],
            ),
          ),
          // Botón limpiar si hay filtros activos
          Obx(() {
            final hasActiveFilters = _getActiveFilterCount() > 0;
            if (!hasActiveFilters) return const SizedBox.shrink();
            
            return IconButton(
              icon: Icon(
                Icons.clear_all,
                size: 16,
                color: Colors.orange.shade700,
              ),
              onPressed: controller.clearFilters,
              tooltip: 'Limpiar todos los filtros',
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              padding: EdgeInsets.zero,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompactFilterSections(BuildContext context) {
    return Column(
      children: [
        // Estado del producto
        _buildCompactFilterCard(
          context,
          title: 'Estado',
          icon: Icons.toggle_on,
          child: _buildCompactStatusFilters(context),
        ),
        
        const SizedBox(height: 10),
        
        // Estado del stock
        _buildCompactFilterCard(
          context,
          title: 'Stock',
          icon: Icons.inventory,
          child: _buildCompactStockFilters(context),
        ),
        
        const SizedBox(height: 10),
        
        // Tipo de producto
        _buildCompactFilterCard(
          context,
          title: 'Tipo',
          icon: Icons.category,
          child: _buildCompactTypeFilters(context),
        ),
        
        const SizedBox(height: 10),
        
        // Rango de precios (expandible)
        _buildExpandablePriceFilter(context),
      ],
    );
  }

  Widget _buildCompactFilterCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  // ==================== FILTROS COMPACTOS ====================

  Widget _buildCompactStatusFilters(BuildContext context) {
    return Obx(() {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _buildCompactChip(
            'Todos',
            controller.currentStatus == null,
            () => controller.applyStatusFilter(null),
            Colors.grey.shade600,
          ),
          _buildCompactChip(
            'Activos',
            controller.currentStatus == ProductStatus.active,
            () => controller.applyStatusFilter(ProductStatus.active),
            Colors.green,
          ),
          _buildCompactChip(
            'Inactivos',
            controller.currentStatus == ProductStatus.inactive,
            () => controller.applyStatusFilter(ProductStatus.inactive),
            Colors.orange,
          ),
        ],
      );
    });
  }

  Widget _buildCompactStockFilters(BuildContext context) {
    return Obx(() {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _buildCompactToggleChip(
            'En Stock',
            controller.inStock == true,
            () => controller.applyStockFilter(
              inStock: controller.inStock == true ? null : true,
            ),
            Colors.green,
          ),
          _buildCompactToggleChip(
            'Stock Bajo',
            controller.lowStock == true,
            () => controller.applyStockFilter(
              lowStock: controller.lowStock == true ? null : true,
            ),
            Colors.orange,
          ),
        ],
      );
    });
  }

  Widget _buildCompactTypeFilters(BuildContext context) {
    return Obx(() {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _buildCompactChip(
            'Todos',
            controller.currentType == null,
            () => controller.applyTypeFilter(null),
            Colors.grey.shade600,
          ),
          _buildCompactChip(
            'Productos',
            controller.currentType == ProductType.product,
            () => controller.applyTypeFilter(ProductType.product),
            Colors.blue,
          ),
          _buildCompactChip(
            'Servicios',
            controller.currentType == ProductType.service,
            () => controller.applyTypeFilter(ProductType.service),
            const Color(0xFF9C27B0),
          ),
        ],
      );
    });
  }

  // ==================== CHIPS COMPACTOS ====================

  Widget _buildCompactChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactToggleChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade400,
                  width: 1,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 8,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== FILTRO DE PRECIO EXPANDIBLE ====================

  Widget _buildExpandablePriceFilter(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Row(
          children: [
            Icon(
              Icons.attach_money,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Rango de Precio',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            Obx(() {
              final hasRange = controller.minPrice != null || controller.maxPrice != null;
              if (!hasRange) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Activo',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ],
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        children: [
          _buildCompactPriceFilter(context),
        ],
      ),
    );
  }

  Widget _buildCompactPriceFilter(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          // Selector de tipo de precio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PriceType>(
                value: controller.priceType,
                isDense: true,
                isExpanded: true,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade800,
                ),
                items: PriceType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      _getPriceTypeName(type),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.applyPriceFilter(
                      controller.minPrice,
                      controller.maxPrice,
                      value,
                    );
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Campos de precio
          Row(
            children: [
              Expanded(
                child: _buildCompactPriceInput(
                  context,
                  'Mín.',
                  controller.minPrice,
                  true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactPriceInput(
                  context,
                  'Máx.',
                  controller.maxPrice,
                  false,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildCompactPriceInput(
    BuildContext context,
    String label,
    double? value,
    bool isMin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            initialValue: value?.toString() ?? '',
            style: const TextStyle(fontSize: 11),
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixText: '\$',
              prefixStyle: TextStyle(fontSize: 11, color: Colors.grey),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final price = double.tryParse(value);
              if (isMin) {
                controller.applyPriceFilter(
                  price,
                  controller.maxPrice,
                  controller.priceType,
                );
              } else {
                controller.applyPriceFilter(
                  controller.minPrice,
                  price,
                  controller.priceType,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // ==================== LAYOUTS ORIGINALES ====================

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getPadding(context, paddingContext: PaddingContext.compact),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterHeader(context),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
          _buildMobileFilterSections(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getPadding(context, paddingContext: PaddingContext.compact),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterHeader(context),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
          _buildTabletFilterSections(context),
        ],
      ),
    );
  }

  // ==================== MÉTODOS AUXILIARES ====================

  Widget _buildFilterHeader(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getPadding(context, paddingContext: PaddingContext.card),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getBorderRadius(context, radiusContext: BorderRadiusContext.card),
        ),
        border: Border.all(color: AppColors.darkBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_list,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Filtros Avanzados',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    fontContext: FontContext.title,
                  ),
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const Spacer(),
              Obx(() {
                final hasActiveFilters = _getActiveFilterCount() > 0;
                if (hasActiveFilters) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Activos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterSections(BuildContext context) {
    return Column(
      children: [
        // Implementación para móvil - simplificada
        Text('Filtros móviles (implementar según diseño compacto)'),
      ],
    );
  }

  Widget _buildTabletFilterSections(BuildContext context) {
    return Column(
      children: [
        // Implementación para tablet - intermedia
        Text('Filtros tablet (implementar según diseño intermedio)'),
      ],
    );
  }

  // ==================== HELPER METHODS ====================

  int _getActiveFilterCount() {
    int count = 0;
    if (controller.currentStatus != null) count++;
    if (controller.currentType != null) count++;
    if (controller.selectedCategoryId != null) count++;
    if (controller.inStock != null) count++;
    if (controller.lowStock != null) count++;
    if (controller.minPrice != null || controller.maxPrice != null) count++;
    if (controller.searchTerm.isNotEmpty) count++;
    return count;
  }

  String _getPriceTypeName(PriceType type) {
    switch (type) {
      case PriceType.price1:
        return 'Precio al Público';
      case PriceType.price2:
        return 'Precio Mayorista';
      case PriceType.price3:
        return 'Precio Distribuidor';
      case PriceType.special:
        return 'Precio Especial';
      case PriceType.cost:
        return 'Precio de Costo';
      default:
        return type.toString();
    }
  }
}