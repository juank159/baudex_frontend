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
    return Container(
      color: AppColors.darkBackground,
      child: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  // ==================== LAYOUTS RESPONSIVOS ====================

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterHeader(context),
          SizedBox(height: context.verticalSpacing),
          _buildCompactFilterSections(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterHeader(context),
          SizedBox(height: context.verticalSpacing),
          _buildTwoColumnFilterLayout(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterHeader(context),
          SizedBox(height: context.verticalSpacing),
          _buildExpandedFilterLayout(context),
        ],
      ),
    );
  }

  Widget _buildCompactFilterSections(BuildContext context) {
    return Column(
      children: [
        _buildFilterSection(
          context,
          title: 'Estado del Producto',
          icon: Icons.check_circle_outline,
          child: _buildStatusFilter(context),
        ),
        SizedBox(height: context.verticalSpacing),
        _buildFilterSection(
          context,
          title: 'Estado del Stock',
          icon: Icons.inventory_outlined,
          child: _buildStockFilter(context),
        ),
        SizedBox(height: context.verticalSpacing),
        _buildFilterSection(
          context,
          title: 'Tipo de Producto',
          icon: Icons.category_outlined,
          child: _buildTypeFilter(context),
        ),
        SizedBox(height: context.verticalSpacing),
        _buildFilterSection(
          context,
          title: 'Categoría',
          icon: Icons.folder_outlined,
          child: _buildCategoryFilter(context),
        ),
        SizedBox(height: context.verticalSpacing),
        _buildFilterSection(
          context,
          title: 'Rango de Precio',
          icon: Icons.attach_money,
          child: _buildPriceFilter(context),
        ),
        SizedBox(height: context.verticalSpacing * 1.5),
        _buildFilterActions(context),
      ],
    );
  }

  Widget _buildTwoColumnFilterLayout(BuildContext context) {
    return Column(
      children: [
        // Primera fila
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFilterSection(
                context,
                title: 'Estado del Producto',
                icon: Icons.check_circle_outline,
                child: _buildStatusFilter(context),
              ),
            ),
            SizedBox(width: context.horizontalSpacing),
            Expanded(
              child: _buildFilterSection(
                context,
                title: 'Estado del Stock',
                icon: Icons.inventory_outlined,
                child: _buildStockFilter(context),
              ),
            ),
          ],
        ),
        SizedBox(height: context.verticalSpacing),

        // Segunda fila
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFilterSection(
                context,
                title: 'Tipo de Producto',
                icon: Icons.category_outlined,
                child: _buildTypeFilter(context),
              ),
            ),
            SizedBox(width: context.horizontalSpacing),
            Expanded(
              child: _buildFilterSection(
                context,
                title: 'Categoría',
                icon: Icons.folder_outlined,
                child: _buildCategoryFilter(context),
              ),
            ),
          ],
        ),
        SizedBox(height: context.verticalSpacing),

        // Tercera fila - Precio (ancho completo)
        _buildFilterSection(
          context,
          title: 'Rango de Precio',
          icon: Icons.attach_money,
          child: _buildPriceFilter(context),
        ),
        SizedBox(height: context.verticalSpacing * 1.5),
        _buildFilterActions(context),
      ],
    );
  }

  Widget _buildExpandedFilterLayout(BuildContext context) {
    return Column(
      children: [
        // Primera fila - 3 columnas
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFilterSection(
                context,
                title: 'Estado del Producto',
                icon: Icons.check_circle_outline,
                child: _buildStatusFilter(context),
              ),
            ),
            SizedBox(width: context.horizontalSpacing),
            Expanded(
              child: _buildFilterSection(
                context,
                title: 'Estado del Stock',
                icon: Icons.inventory_outlined,
                child: _buildStockFilter(context),
              ),
            ),
            SizedBox(width: context.horizontalSpacing),
            Expanded(
              child: _buildFilterSection(
                context,
                title: 'Tipo de Producto',
                icon: Icons.category_outlined,
                child: _buildTypeFilter(context),
              ),
            ),
          ],
        ),
        SizedBox(height: context.verticalSpacing),

        // Segunda fila - 2 columnas
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildFilterSection(
                context,
                title: 'Rango de Precio',
                icon: Icons.attach_money,
                child: _buildPriceFilter(context),
              ),
            ),
            SizedBox(width: context.horizontalSpacing),
            Expanded(
              child: _buildFilterSection(
                context,
                title: 'Categoría',
                icon: Icons.folder_outlined,
                child: _buildCategoryFilter(context),
              ),
            ),
          ],
        ),
        SizedBox(height: context.verticalSpacing * 1.5),
        _buildFilterActions(context),
      ],
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getPadding(context),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(context.isMobile ? 12 : 16),
        border: Border.all(color: AppColors.darkBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_list,
                  color: AppColors.primary,
                  size: context.isMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: context.horizontalSpacing / 2),
              Text(
                'Filtros Avanzados',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const Spacer(),
              Obx(() {
                final hasActiveFilters = _hasActiveFilters();
                if (hasActiveFilters) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.isMobile ? 6 : 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Activos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.isMobile ? 10 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),

          SizedBox(height: context.verticalSpacing),

          // Resumen de inventario (adaptativo según el dispositivo)
          Container(
            padding: EdgeInsets.all(context.isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.darkBorderColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Resumen de Inventario',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      mobile: 12,
                      tablet: 14,
                      desktop: 14,
                    ),
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                SizedBox(height: context.isMobile ? 8 : 12),
                Obx(() {
                  final stats = controller.stats;
                  if (stats == null) {
                    return Text(
                      'Cargando estadísticas...',
                      style: TextStyle(
                        color: AppColors.darkTextSecondary,
                        fontSize: ResponsiveHelper.getFontSize(
                          context,
                          mobile: 11,
                          tablet: 12,
                          desktop: 12,
                        ),
                      ),
                    );
                  }

                  // Layout adaptativo para las estadísticas
                  if (context.isMobile) {
                    return Row(
                      children: [
                        _buildQuickStat(
                          'Total',
                          stats.total.toString(),
                          AppColors.primary,
                          context,
                        ),
                        Container(
                          width: 1,
                          height: 35,
                          color: AppColors.darkBorderColor,
                        ),
                        _buildQuickStat(
                          'Activos',
                          stats.active.toString(),
                          AppColors.success,
                          context,
                        ),
                        Container(
                          width: 1,
                          height: 35,
                          color: AppColors.darkBorderColor,
                        ),
                        _buildQuickStat(
                          'Stock Bajo',
                          stats.lowStock.toString(),
                          AppColors.warning,
                          context,
                        ),
                      ],
                    );
                  } else {
                    // Para tablet y desktop, agregar más estadísticas
                    return Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildQuickStatCard(
                          'Total',
                          stats.total.toString(),
                          AppColors.primary,
                          Icons.inventory_2,
                          context,
                        ),
                        _buildQuickStatCard(
                          'Activos',
                          stats.active.toString(),
                          AppColors.success,
                          Icons.check_circle,
                          context,
                        ),
                        _buildQuickStatCard(
                          'Inactivos',
                          stats.inactive.toString(),
                          AppColors.warning,
                          Icons.cancel,
                          context,
                        ),
                        _buildQuickStatCard(
                          'Stock Bajo',
                          stats.lowStock.toString(),
                          AppColors.warning,
                          Icons.warning,
                          context,
                        ),
                        _buildQuickStatCard(
                          'Sin Stock',
                          stats.outOfStock.toString(),
                          AppColors.error,
                          Icons.error,
                          context,
                        ),
                      ],
                    );
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    Color color,
    BuildContext context,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            _getIconForStat(label),
            color: color,
            size: context.isMobile ? 16 : 20,
          ),
          SizedBox(height: context.isMobile ? 2 : 4),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 18,
              ),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 9,
                tablet: 11,
                desktop: 11,
              ),
              color: AppColors.darkTextSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
    BuildContext context,
  ) {
    return Container(
      width: context.isDesktop ? 140 : 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.darkTextSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForStat(String label) {
    switch (label) {
      case 'Total':
        return Icons.inventory_2;
      case 'Activos':
        return Icons.check_circle;
      case 'Stock Bajo':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Widget _buildFilterSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: ResponsiveHelper.getPadding(context),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(context.isMobile ? 12 : 16),
        border: Border.all(color: AppColors.darkBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: context.isMobile ? 18 : 20,
                color: AppColors.primary,
              ),
              SizedBox(width: context.horizontalSpacing / 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 16,
                  ),
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: context.verticalSpacing / 2),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          _buildFilterOption(
            context,
            label: 'Todos los estados',
            count: controller.stats?.total ?? 0,
            isSelected: controller.currentStatus == null,
            onTap: () => controller.applyStatusFilter(null),
            color: AppColors.darkTextSecondary,
          ),
          const SizedBox(height: 8),
          _buildFilterOption(
            context,
            label: 'Productos Activos',
            count: controller.stats?.active ?? 0,
            isSelected: controller.currentStatus == ProductStatus.active,
            onTap: () => controller.applyStatusFilter(ProductStatus.active),
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          _buildFilterOption(
            context,
            label: 'Productos Inactivos',
            count: controller.stats?.inactive ?? 0,
            isSelected: controller.currentStatus == ProductStatus.inactive,
            onTap: () => controller.applyStatusFilter(ProductStatus.inactive),
            color: AppColors.warning,
          ),
        ],
      );
    });
  }

  Widget _buildStockFilter(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          _buildToggleOption(
            context,
            label: 'Solo productos en stock',
            count: controller.stats?.inStock ?? 0,
            isSelected: controller.inStock == true,
            onTap:
                () => controller.applyStockFilter(
                  inStock: controller.inStock == true ? null : true,
                ),
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          _buildToggleOption(
            context,
            label: 'Solo stock bajo',
            count: controller.stats?.lowStock ?? 0,
            isSelected: controller.lowStock == true,
            onTap:
                () => controller.applyStockFilter(
                  lowStock: controller.lowStock == true ? null : true,
                ),
            color: AppColors.warning,
          ),
        ],
      );
    });
  }

  Widget _buildTypeFilter(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          _buildFilterOption(
            context,
            label: 'Todos los tipos',
            count: controller.stats?.total ?? 0,
            isSelected: controller.currentType == null,
            onTap: () => controller.applyTypeFilter(null),
            color: AppColors.darkTextSecondary,
          ),
          const SizedBox(height: 8),
          _buildFilterOption(
            context,
            label: 'Productos Físicos',
            count: null,
            isSelected: controller.currentType == ProductType.product,
            onTap: () => controller.applyTypeFilter(ProductType.product),
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _buildFilterOption(
            context,
            label: 'Servicios',
            count: null,
            isSelected: controller.currentType == ProductType.service,
            onTap: () => controller.applyTypeFilter(ProductType.service),
            color: const Color(0xFF9C27B0), // Púrpura
          ),
        ],
      );
    });
  }

  Widget _buildCategoryFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorderColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.category, color: AppColors.darkTextSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrar por Categoría',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Próximamente disponible',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (controller.selectedCategoryId != null)
            TextButton(
              onPressed: () => controller.applyCategoryFilter(null),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Limpiar', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceFilter(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          // Selector de tipo de precio
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorderColor),
            ),
            child: DropdownButtonFormField<PriceType>(
              value: controller.priceType,
              dropdownColor: AppColors.darkSurface,
              style: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 13,
                  tablet: 14,
                  desktop: 14,
                ),
              ),
              decoration: InputDecoration(
                labelText: 'Tipo de Precio',
                labelStyle: TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 12,
                    tablet: 13,
                    desktop: 13,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.isMobile ? 8 : 12,
                  vertical: context.isMobile ? 6 : 8,
                ),
              ),
              items:
                  PriceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        _getPriceTypeName(type),
                        style: const TextStyle(
                          color: AppColors.darkTextPrimary,
                        ),
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
          SizedBox(height: context.verticalSpacing / 2),

          // Campos de precio - responsive layout
          if (context.isMobile)
            Column(
              children: [
                _buildPriceInput(
                  context,
                  'Precio mín.',
                  controller.minPrice,
                  true,
                ),
                SizedBox(height: context.verticalSpacing / 2),
                _buildPriceInput(
                  context,
                  'Precio máx.',
                  controller.maxPrice,
                  false,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildPriceInput(
                    context,
                    'Precio mín.',
                    controller.minPrice,
                    true,
                  ),
                ),
                SizedBox(width: context.horizontalSpacing / 2),
                Expanded(
                  child: _buildPriceInput(
                    context,
                    'Precio máx.',
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

  Widget _buildPriceInput(
    BuildContext context,
    String label,
    double? value,
    bool isMin,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorderColor),
      ),
      child: TextFormField(
        initialValue: (value ?? (isMin ? 0 : 1000)).toString(),
        style: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: ResponsiveHelper.getFontSize(
            context,
            mobile: 13,
            tablet: 14,
            desktop: 14,
          ),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: ResponsiveHelper.getFontSize(
              context,
              mobile: 12,
              tablet: 13,
              desktop: 13,
            ),
          ),
          prefixText: '\$',
          prefixStyle: const TextStyle(color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.isMobile ? 8 : 12,
            vertical: context.isMobile ? 6 : 8,
          ),
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
    );
  }

  Widget _buildFilterActions(BuildContext context) {
    return Column(
      children: [
        // Botones principales - layout responsivo
        if (context.isMobile)
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Aplicar Filtros',
                  icon: Icons.check,
                  onPressed: () {
                    controller.loadProducts();
                    if (Get.isBottomSheetOpen == true) {
                      Get.back();
                    }
                  },
                ),
              ),
              SizedBox(height: context.verticalSpacing / 2),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Limpiar Filtros',
                  type: ButtonType.outline,
                  icon: Icons.clear_all,
                  onPressed: controller.clearFilters,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Limpiar Filtros',
                  type: ButtonType.outline,
                  icon: Icons.clear_all,
                  onPressed: controller.clearFilters,
                ),
              ),
              SizedBox(width: context.horizontalSpacing),
              Expanded(
                child: CustomButton(
                  text: 'Aplicar Filtros',
                  icon: Icons.check,
                  onPressed: () {
                    controller.loadProducts();
                    if (Get.isBottomSheetOpen == true) {
                      Get.back();
                    }
                  },
                ),
              ),
            ],
          ),

        SizedBox(height: context.verticalSpacing / 2),

        // Acciones rápidas
        if (context.isMobile)
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Stock Bajo',
                  type: ButtonType.text,
                  icon: Icons.warning_outlined,
                  onPressed: () {
                    controller.clearFilters();
                    controller.loadLowStockProducts();
                    if (Get.isBottomSheetOpen == true) {
                      Get.back();
                    }
                  },
                ),
              ),
              SizedBox(height: context.verticalSpacing / 4),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Solo Activos',
                  type: ButtonType.text,
                  icon: Icons.check_circle_outline,
                  onPressed: () {
                    controller.clearFilters();
                    controller.applyStatusFilter(ProductStatus.active);
                    if (Get.isBottomSheetOpen == true) {
                      Get.back();
                    }
                  },
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Stock Bajo',
                  type: ButtonType.text,
                  icon: Icons.warning_outlined,
                  onPressed: () {
                    controller.clearFilters();
                    controller.loadLowStockProducts();
                    if (Get.isBottomSheetOpen == true) {
                      Get.back();
                    }
                  },
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Solo Activos',
                  type: ButtonType.text,
                  icon: Icons.check_circle_outline,
                  onPressed: () {
                    controller.clearFilters();
                    controller.applyStatusFilter(ProductStatus.active);
                    if (Get.isBottomSheetOpen == true) {
                      Get.back();
                    }
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFilterOption(
    BuildContext context, {
    required String label,
    required int? count,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? 12 : 16,
          vertical: context.isMobile ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? color : AppColors.darkBorderColor.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: context.isMobile ? 18 : 20,
              height: context.isMobile ? 18 : 20,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : AppColors.darkTextSecondary,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: context.isMobile ? 12 : 14,
                      )
                      : null,
            ),
            SizedBox(width: context.horizontalSpacing / 2),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 13,
                    tablet: 14,
                    desktop: 14,
                  ),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected
                          ? AppColors.darkTextPrimary
                          : AppColors.darkTextSecondary,
                ),
              ),
            ),
            if (count != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isMobile ? 6 : 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : AppColors.darkBorderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getFontSize(
                      context,
                      mobile: 10,
                      tablet: 12,
                      desktop: 12,
                    ),
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? Colors.white : AppColors.darkTextSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? 12 : 16,
          vertical: context.isMobile ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.darkBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? color : AppColors.darkBorderColor.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: context.isMobile ? 18 : 20,
              height: context.isMobile ? 18 : 20,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? color : AppColors.darkTextSecondary,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: context.isMobile ? 12 : 14,
                      )
                      : null,
            ),
            SizedBox(width: context.horizontalSpacing / 2),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 13,
                    tablet: 14,
                    desktop: 14,
                  ),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected
                          ? AppColors.darkTextPrimary
                          : AppColors.darkTextSecondary,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.isMobile ? 6 : 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.darkBorderColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 10,
                    tablet: 12,
                    desktop: 12,
                  ),
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected ? Colors.white : AppColors.darkTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ==================== HELPER METHODS ====================

  bool _hasActiveFilters() {
    return controller.currentStatus != null ||
        controller.currentType != null ||
        controller.selectedCategoryId != null ||
        controller.inStock != null ||
        controller.lowStock != null ||
        controller.minPrice != null ||
        controller.maxPrice != null ||
        controller.searchTerm.isNotEmpty;
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
