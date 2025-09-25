// lib/features/inventory/presentation/screens/inventory_bulk_adjustments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/inventory_bulk_adjustments_controller.dart';
import '../widgets/product_search_widget.dart';

class InventoryBulkAdjustmentsScreen extends GetView<InventoryBulkAdjustmentsController> {
  const InventoryBulkAdjustmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Ajustes Masivos de Inventario',
      showBackButton: true,
      showDrawer: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobile = screenWidth < 600;
          final isTablet = screenWidth >= 600 && screenWidth < 1200;
          final isDesktop = screenWidth >= 1200;

          return Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: LoadingWidget());
            }

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ElegantLightTheme.backgroundColor,
                    ElegantLightTheme.backgroundColor.withOpacity(0.95),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Header with instructions and add product
                  _buildResponsiveHeader(isMobile, isTablet),
                  
                  // Content area with scroll
                  Expanded(
                    child: _buildScrollableContent(isMobile, isTablet, isDesktop),
                  ),
                  
                  // Summary and submit (if items exist) - Fixed at bottom
                  if (controller.hasItems) 
                    _buildResponsiveFooter(isMobile, isTablet),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildResponsiveHeader(bool isMobile, bool isTablet) {
    final padding = isMobile ? 12.0 : isTablet ? 16.0 : 20.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        border: Border(
          bottom: BorderSide(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Instructions (solo en tablet/desktop)
          if (!isMobile) ...[
            _buildInstructionsCard(isMobile, padding),
            SizedBox(height: 16),
          ],
          
          // Warehouse Selection
          _buildResponsiveWarehouseSelector(isMobile, isTablet),
          
          SizedBox(height: isMobile ? 8 : 16),
          
          // Product search
          _buildResponsiveProductSearch(isMobile),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(bool isMobile, double padding) {
    // En móvil, no mostrar la card de instrucciones para ahorrar espacio
    if (isMobile) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ElegantLightTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.infoGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.info_outline, 
              color: Colors.white, 
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ajuste múltiples productos a la vez. Busque y agregue productos, ajuste las cantidades y aplique los cambios.',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: ElegantLightTheme.textPrimary,
                fontSize: 13,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveProductSearch(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ProductSearchWidget(
        hintText: 'Buscar productos para ajustar...',
        onProductSelected: controller.addProductToAdjustment,
        searchFunction: controller.searchProducts,
      ),
    );
  }

  Widget _buildScrollableContent(bool isMobile, bool isTablet, bool isDesktop) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Bulk actions toolbar (if items exist)
        if (controller.hasItems) 
          SliverToBoxAdapter(
            child: _buildResponsiveBulkActionsToolbar(isMobile, isTablet),
          ),
        
        // Items list or empty state
        controller.hasItems 
            ? _buildResponsiveAdjustmentsList(isMobile, isTablet, isDesktop)
            : SliverFillRemaining(
                child: _buildResponsiveEmptyState(isMobile),
              ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Text(
                    'Ajuste múltiples productos a la vez. Busque y agregue productos, ajuste las cantidades y aplique los cambios.',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Warehouse Selection - PROMINENTE Y VISIBLE
          _buildWarehouseSelector(),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Product search
          Row(
            children: [
              Expanded(
                child: ProductSearchWidget(
                  hintText: 'Buscar productos para ajustar...',
                  onProductSelected: controller.addProductToAdjustment,
                  searchFunction: controller.searchProducts,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveWarehouseSelector(bool isMobile, bool isTablet) {
    final padding = isMobile ? 12.0 : 16.0;
    
    return Obx(() => Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
        border: Border.all(
          color: controller.selectedWarehouseId.value.isEmpty 
              ? ElegantLightTheme.errorGradient.colors.first.withOpacity(0.3)
              : ElegantLightTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (controller.selectedWarehouseId.value.isEmpty 
                ? ElegantLightTheme.errorGradient.colors.first
                : ElegantLightTheme.primaryBlue).withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: controller.selectedWarehouseId.value.isEmpty 
                      ? ElegantLightTheme.errorGradient
                      : ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.warehouse,
                  color: Colors.white,
                  size: isMobile ? 16 : 18,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Text(
                  'Almacén de Destino',
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: controller.selectedWarehouseId.value.isEmpty 
                        ? ElegantLightTheme.errorGradient.colors.first
                        : ElegantLightTheme.primaryBlue,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
              if (controller.selectedWarehouseId.value.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6 : 8, 
                    vertical: isMobile ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.errorGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'REQUERIDO',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 8 : 9,
                    ),
                  ),
                ),
            ],
          ),
          
          // Descripción más corta en móvil
          if (!isMobile) ...[
            SizedBox(height: 10),
            Text(
              'Seleccione el almacén donde se aplicarán los ajustes de inventario',
              style: Get.textTheme.bodySmall?.copyWith(
                color: ElegantLightTheme.textSecondary,
                fontSize: 12,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          SizedBox(height: isMobile ? 6 : 12),
          
          // Dropdown de almacenes
          _buildResponsiveWarehouseDropdown(isMobile),
          
          // Mostrar almacén seleccionado (solo en tablet/desktop)
          if (controller.selectedWarehouseId.value.isNotEmpty && !isMobile) ...[
            SizedBox(height: 10),
            _buildSelectedWarehouseIndicator(isMobile),
          ],
        ],
      ),
    ));
  }

  Widget _buildResponsiveWarehouseDropdown(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedWarehouseId.value.isEmpty 
              ? null 
              : controller.selectedWarehouseId.value,
          hint: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_arrow_down, 
                  color: ElegantLightTheme.textSecondary,
                  size: isMobile ? 18 : 20,
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Text(
                  controller.selectedWarehouseName.value,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: controller.selectedWarehouseId.value.isEmpty
                        ? ElegantLightTheme.errorGradient.colors.first
                        : ElegantLightTheme.textPrimary,
                    fontWeight: controller.selectedWarehouseId.value.isEmpty
                        ? FontWeight.w500
                        : FontWeight.bold,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ],
            ),
          ),
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              final selectedWarehouse = controller.warehouses
                  .firstWhere((w) => w.id == newValue);
              controller.setSelectedWarehouse(newValue, selectedWarehouse.name);
            }
          },
          items: controller.warehouses.map<DropdownMenuItem<String>>((warehouse) {
            return DropdownMenuItem<String>(
              value: warehouse.id,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.warehouse, 
                        size: isMobile ? 14 : 16, 
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            warehouse.name,
                            style: Get.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 13 : 14,
                            ),
                          ),
                          if (warehouse.description?.isNotEmpty == true)
                            Text(
                              warehouse.description!,
                              style: Get.textTheme.bodySmall?.copyWith(
                                color: ElegantLightTheme.textSecondary,
                                fontSize: isMobile ? 11 : 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSelectedWarehouseIndicator(bool isMobile) {
    // En móvil, no mostrar este indicador para ahorrar espacio
    if (isMobile) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ElegantLightTheme.successGradient.colors.first.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.successGradient.colors.first.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle, 
            color: ElegantLightTheme.successGradient.colors.first, 
            size: 18,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Los ajustes se aplicarán en: ${controller.selectedWarehouseName.value}',
              style: Get.textTheme.bodySmall?.copyWith(
                color: ElegantLightTheme.successGradient.colors.first,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveBulkActionsToolbar(bool isMobile, bool isTablet) {
    final padding = isMobile ? 10.0 : 14.0;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 6 : 10,
      ),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.tune,
                  color: Colors.white,
                  size: isMobile ? 14 : 16,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Expanded(
                child: Text(
                  'Acciones Masivas',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
              Obx(() => Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 8, 
                  vertical: isMobile ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  controller.summaryText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 8 : 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
            ],
          ),
          
          SizedBox(height: isMobile ? 8 : 12),
          
          // Actions row - responsive layout
          isMobile ? _buildMobileBulkActions() : _buildDesktopBulkActions(),
        ],
      ),
    );
  }

  Widget _buildMobileBulkActions() {
    return Column(
      children: [
        // Row 1: Selection actions
        Row(
          children: [
            Expanded(
              child: _buildBulkActionButton(
                icon: Icons.select_all,
                label: 'Todos',
                onPressed: controller.selectAllItems,
                isMobile: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBulkActionButton(
                icon: Icons.deselect,
                label: 'Ninguno',
                onPressed: controller.deselectAllItems,
                isMobile: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: Quantity actions
        Row(
          children: [
            Expanded(
              child: _buildBulkActionButton(
                icon: Icons.restore,
                label: 'Restaurar',
                onPressed: controller.resetQuantityForAllSelected,
                isMobile: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBulkActionButton(
                icon: Icons.clear_all,
                label: 'Cero',
                onPressed: () => controller.setQuantityForAllSelected(0),
                isMobile: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopBulkActions() {
    return Row(
      children: [
        Expanded(
          child: _buildBulkActionButton(
            icon: Icons.select_all,
            label: 'Seleccionar Todos',
            onPressed: controller.selectAllItems,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBulkActionButton(
            icon: Icons.deselect,
            label: 'Deseleccionar',
            onPressed: controller.deselectAllItems,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBulkActionButton(
            icon: Icons.restore,
            label: 'Restaurar Original',
            onPressed: controller.resetQuantityForAllSelected,
            isMobile: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBulkActionButton(
            icon: Icons.clear_all,
            label: 'Poner en Cero',
            onPressed: () => controller.setQuantityForAllSelected(0),
            isMobile: false,
          ),
        ),
      ],
    );
  }

  Widget _buildBulkActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 8 : 12,
              horizontal: isMobile ? 6 : 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: ElegantLightTheme.primaryBlue,
                  size: isMobile ? 16 : 18,
                ),
                SizedBox(height: isMobile ? 4 : 6),
                Text(
                  label,
                  style: TextStyle(
                    color: ElegantLightTheme.primaryBlue,
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: isMobile ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveAdjustmentsList(bool isMobile, bool isTablet, bool isDesktop) {
    final padding = isMobile ? 16.0 : isTablet ? 20.0 : 24.0;
    
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = controller.adjustmentItems[index];
            return _buildResponsiveAdjustmentItem(item, isMobile, isTablet);
          },
          childCount: controller.adjustmentItems.length,
        ),
      ),
    );
  }

  Widget _buildResponsiveEmptyState(bool isMobile) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 400,
        ),
        margin: EdgeInsets.all(isMobile ? 12 : 32),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          boxShadow: ElegantLightTheme.neuomorphicShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              decoration: BoxDecoration(
                color: ElegantLightTheme.infoGradient.colors.first.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                border: Border.all(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.inventory_2,
                size: isMobile ? 32 : 48,
                color: ElegantLightTheme.primaryBlue.withOpacity(0.7),
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'No hay productos agregados',
              style: Get.textTheme.titleMedium?.copyWith(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 14 : 16,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isMobile ? 6 : 10),
            Text(
              'Use el buscador de arriba para agregar productos y crear ajustes masivos de inventario.',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: ElegantLightTheme.textSecondary,
                fontSize: isMobile ? 11 : 13,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: isMobile ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveAdjustmentItem(BulkAdjustmentItem item, bool isMobile, bool isTablet) {
    final cardPadding = isMobile ? 10.0 : isTablet ? 14.0 : 16.0;
    final borderRadius = isMobile ? 10.0 : isTablet ? 12.0 : 14.0;
    
    return Obx(() => Container(
      margin: EdgeInsets.only(bottom: isMobile ? 6 : 10),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: item.isSelected.value 
              ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
              : ElegantLightTheme.primaryBlue.withOpacity(0.1),
          width: item.isSelected.value ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (item.isSelected.value 
                ? ElegantLightTheme.primaryBlue
                : Colors.black).withOpacity(0.1),
            blurRadius: item.isSelected.value ? 12 : 8,
            offset: Offset(0, item.isSelected.value ? 4 : 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with product info and selection
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.isSelected.value 
                          ? ElegantLightTheme.primaryBlue
                          : ElegantLightTheme.textSecondary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Checkbox(
                    value: item.isSelected.value,
                    onChanged: (value) => controller.toggleItemSelection(item.id),
                    activeColor: ElegantLightTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 10 : 12),
                
                // Product icon
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: isMobile ? 16 : 18,
                  ),
                ),
                SizedBox(width: isMobile ? 10 : 12),
                
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: Get.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ElegantLightTheme.textPrimary,
                          fontSize: isMobile ? 13 : isTablet ? 14 : 15,
                        ),
                        maxLines: isMobile ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.product.sku.isNotEmpty && !isMobile)
                        Text(
                          'SKU: ${item.product.sku}',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: isMobile ? 10 : 11,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Remove button
                Container(
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.errorGradient.colors.first.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                  ),
                  child: IconButton(
                    onPressed: () => controller.removeAdjustmentItem(item.id),
                    icon: Icon(
                      Icons.delete_outline,
                      size: isMobile ? 18 : 20,
                    ),
                    color: ElegantLightTheme.errorGradient.colors.first,
                    tooltip: 'Remover producto',
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 32 : 36,
                      minHeight: isMobile ? 32 : 36,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isMobile ? 8 : 12),
            
            // Stock info and adjustment - responsive layout
            isMobile 
                ? _buildMobileStockLayout(item, isMobile)
                : _buildDesktopStockLayout(item, isMobile, isTablet),
            
            // Notes for this item (if selected)
            if (item.isSelected.value) ...[
              SizedBox(height: isMobile ? 8 : 12),
              Container(
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.glassGradient,
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Notas específicas para este producto...',
                    hintStyle: TextStyle(
                      color: ElegantLightTheme.textSecondary.withOpacity(0.7),
                      fontSize: isMobile ? 12 : 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      child: Icon(
                        Icons.note_add,
                        size: isMobile ? 16 : 18,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: ElegantLightTheme.textPrimary,
                  ),
                  maxLines: 2,
                  onChanged: (value) => item.notes.value = value,
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }

  Widget _buildMobileStockLayout(BulkAdjustmentItem item, bool isMobile) {
    return Row(
      children: [
        // Stock Actual
        Expanded(
          child: _buildCompactStockCard(
            'Stock Actual',
            '${item.currentQuantity}',
            Icons.inventory,
            ElegantLightTheme.infoGradient.colors.first,
          ),
        ),
        const SizedBox(width: 4),
        // Nueva Cantidad (input)
        Expanded(
          child: _buildCompactQuantityInputCard(item),
        ),
        const SizedBox(width: 4),
        // Diferencia de Ajuste
        Expanded(
          child: _buildCompactStockCard(
            'Ajuste',
            item.adjustmentDifference > 0 
                ? '+${item.adjustmentDifference}'
                : '${item.adjustmentDifference}',
            item.adjustmentIcon,
            item.adjustmentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStockLayout(BulkAdjustmentItem item, bool isMobile, bool isTablet) {
    return Row(
      children: [
        // Current stock
        Expanded(
          child: _buildResponsiveStockCard(
            'Stock Actual',
            '${item.currentQuantity}',
            Icons.inventory,
            ElegantLightTheme.infoGradient.colors.first,
            isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        
        // New quantity input
        Expanded(
          child: _buildQuantityInputCard(item, isMobile),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        
        // Adjustment preview
        Expanded(
          child: _buildResponsiveStockCard(
            'Ajuste',
            item.adjustmentDifference > 0 
                ? '+${item.adjustmentDifference}'
                : '${item.adjustmentDifference}',
            item.adjustmentIcon,
            item.adjustmentColor,
            isMobile,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityInputCard(BulkAdjustmentItem item, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit,
                size: isMobile ? 14 : 16,
                color: ElegantLightTheme.primaryBlue,
              ),
              SizedBox(width: isMobile ? 4 : 6),
              Text(
                'Nueva Cantidad',
                style: Get.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.primaryBlue,
                  fontSize: isMobile ? 10 : 11,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 4 : 6),
          TextFormField(
            initialValue: item.newQuantity.value.toString(),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                borderSide: BorderSide(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                borderSide: BorderSide(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                borderSide: BorderSide(
                  color: ElegantLightTheme.primaryBlue,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 6 : 8,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              item.newQuantity.value = int.tryParse(value) ?? 0;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStockCard(String label, String value, IconData icon, Color color) {
    return Container(
      height: 70, // Altura fija para consistencia
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Get.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: Get.textTheme.bodySmall?.copyWith(
              color: ElegantLightTheme.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactQuantityInputCard(BulkAdjustmentItem item) {
    return Container(
      height: 70, // Misma altura que las otras cards
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit,
            size: 14,
            color: ElegantLightTheme.primaryBlue,
          ),
          const SizedBox(height: 2),
          Expanded(
            child: TextFormField(
              initialValue: item.newQuantity.value.toString(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.primaryBlue,
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: ElegantLightTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                item.newQuantity.value = int.tryParse(value) ?? 0;
              },
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'Nueva Cantidad',
            style: Get.textTheme.bodySmall?.copyWith(
              color: ElegantLightTheme.primaryBlue,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveStockCard(String label, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: isMobile ? 16 : 18,
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            value,
            style: Get.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          SizedBox(height: isMobile ? 1 : 3),
          Text(
            label,
            style: Get.textTheme.bodySmall?.copyWith(
              color: ElegantLightTheme.textSecondary,
              fontSize: isMobile ? 9 : 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: isMobile ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveFooter(bool isMobile, bool isTablet) {
    final padding = isMobile ? 12.0 : 16.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            Obx(() => Container(
              padding: EdgeInsets.all(isMobile ? 10 : 14),
              decoration: BoxDecoration(
                color: ElegantLightTheme.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                border: Border.all(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.summarize,
                    color: ElegantLightTheme.primaryBlue,
                    size: isMobile ? 16 : 18,
                  ),
                  SizedBox(width: isMobile ? 6 : 10),
                  Expanded(
                    child: Text(
                      controller.summaryText,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: ElegantLightTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 10 : 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
            
            SizedBox(height: isMobile ? 10 : 14),
            
            // Action button
            SizedBox(
              width: double.infinity,
              child: _buildSubmitButton(isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isMobile) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        gradient: controller.isFormValid 
            ? ElegantLightTheme.successGradient
            : ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
        boxShadow: controller.isFormValid ? [
          BoxShadow(
            color: ElegantLightTheme.successGradient.colors.first.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.isFormValid && !controller.isCreating.value
              ? controller.createBulkAdjustments
              : null,
          borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (controller.isCreating.value)
                  SizedBox(
                    width: isMobile ? 14 : 16,
                    height: isMobile ? 14 : 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        controller.isFormValid ? Colors.white : ElegantLightTheme.textSecondary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.save,
                    color: controller.isFormValid ? Colors.white : ElegantLightTheme.textSecondary,
                    size: isMobile ? 16 : 18,
                  ),
                SizedBox(width: isMobile ? 6 : 10),
                Flexible(
                  child: Text(
                    controller.isCreating.value 
                        ? 'Aplicando Ajustes...' 
                        : 'Aplicar Ajustes Masivos',
                    style: TextStyle(
                      color: controller.isFormValid ? Colors.white : ElegantLightTheme.textSecondary,
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildWarehouseSelector() {
    return Obx(() => Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: controller.selectedWarehouseId.value.isEmpty 
              ? Colors.red.withOpacity(0.5) 
              : AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (controller.selectedWarehouseId.value.isEmpty 
                ? Colors.red 
                : AppColors.primary).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warehouse,
                color: controller.selectedWarehouseId.value.isEmpty 
                    ? Colors.red 
                    : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Text(
                'Almacén de Destino',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: controller.selectedWarehouseId.value.isEmpty 
                      ? Colors.red 
                      : AppColors.primary,
                ),
              ),
              const Spacer(),
              if (controller.selectedWarehouseId.value.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'REQUERIDO',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingSmall),
          
          Text(
            'Seleccione el almacén donde se aplicarán los ajustes de inventario',
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Dropdown de almacenes
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedWarehouseId.value.isEmpty 
                    ? null 
                    : controller.selectedWarehouseId.value,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        controller.selectedWarehouseName.value,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: controller.selectedWarehouseId.value.isEmpty
                              ? Colors.red
                              : AppColors.textPrimary,
                          fontWeight: controller.selectedWarehouseId.value.isEmpty
                              ? FontWeight.w500
                              : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                isExpanded: true,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    final selectedWarehouse = controller.warehouses
                        .firstWhere((w) => w.id == newValue);
                    controller.setSelectedWarehouse(newValue, selectedWarehouse.name);
                  }
                },
                items: controller.warehouses.map<DropdownMenuItem<String>>((warehouse) {
                  return DropdownMenuItem<String>(
                    value: warehouse.id,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.warehouse, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  warehouse.name,
                                  style: Get.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (warehouse.description?.isNotEmpty == true)
                                  Text(
                                    warehouse.description!,
                                    style: Get.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Mostrar almacén seleccionado
          if (controller.selectedWarehouseId.value.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingSmall),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Los ajustes se aplicarán en: ${controller.selectedWarehouseName.value}',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ));
  }

  Widget _buildBulkActionsToolbar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Column(
        children: [
          // Selection controls
          Row(
            children: [
              Text(
                'Acciones Masivas:',
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              TextButton.icon(
                onPressed: controller.selectAllItems,
                icon: const Icon(Icons.select_all, size: 16),
                label: const Text('Seleccionar Todos'),
              ),
              TextButton.icon(
                onPressed: controller.deselectAllItems,
                icon: const Icon(Icons.deselect, size: 16),
                label: const Text('Deseleccionar Todos'),
              ),
              TextButton.icon(
                onPressed: controller.resetQuantityForAllSelected,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Restaurar Cantidades'),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingSmall),
          
          // Quick adjustment controls
          Row(
            children: [
              Text('Ajustes Rápidos:', style: Get.textTheme.bodyMedium),
              const SizedBox(width: AppDimensions.paddingMedium),
              _buildQuickAdjustButton('Cero', 0, Icons.clear, Colors.red),
              _buildQuickAdjustButton('+1', 1, Icons.add, Colors.green),
              _buildQuickAdjustButton('+5', 5, Icons.add, Colors.green),
              _buildQuickAdjustButton('+10', 10, Icons.add, Colors.green),
              _buildQuickAdjustButton('-1', -1, Icons.remove, Colors.red),
              _buildQuickAdjustButton('-5', -5, Icons.remove, Colors.red),
              _buildQuickAdjustButton('-10', -10, Icons.remove, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAdjustButton(String label, int adjustment, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          if (adjustment == 0) {
            controller.setQuantityForAllSelected(0);
          } else {
            controller.adjustQuantityForAllSelected(adjustment);
          }
        },
        icon: Icon(icon, size: 14),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildAdjustmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      itemCount: controller.adjustmentItems.length,
      itemBuilder: (context, index) {
        final item = controller.adjustmentItems[index];
        return _buildAdjustmentItem(item);
      },
    );
  }

  Widget _buildAdjustmentItem(BulkAdjustmentItem item) {
    return Obx(() => Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          children: [
            // Header with product info and selection
            Row(
              children: [
                Checkbox(
                  value: item.isSelected.value,
                  onChanged: (value) => controller.toggleItemSelection(item.id),
                ),
                const SizedBox(width: AppDimensions.paddingSmall),
                Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.paddingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: Get.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.product.sku.isNotEmpty)
                        Text(
                          'SKU: ${item.product.sku}',
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => controller.removeAdjustmentItem(item.id),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: 'Remover producto',
                ),
              ],
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Stock info and adjustment
            Row(
              children: [
                // Current stock
                Expanded(
                  child: _buildStockCard(
                    'Stock Actual',
                    '${item.currentQuantity}',
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                
                const SizedBox(width: AppDimensions.paddingSmall),
                
                // New quantity input
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nueva Cantidad',
                        style: Get.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: item.newQuantity.value.toString(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          item.newQuantity.value = int.tryParse(value) ?? 0;
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: AppDimensions.paddingSmall),
                
                // Adjustment preview
                Expanded(
                  child: _buildStockCard(
                    'Ajuste',
                    item.adjustmentDifference > 0 
                        ? '+${item.adjustmentDifference}'
                        : '${item.adjustmentDifference}',
                    item.adjustmentIcon,
                    item.adjustmentColor,
                  ),
                ),
              ],
            ),
            
            // Notes for this item
            if (item.isSelected.value) ...[
              const SizedBox(height: AppDimensions.paddingMedium),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Notas específicas para este producto...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 2,
                onChanged: (value) => item.notes.value = value,
              ),
            ],
          ],
        ),
      ),
    ));
  }

  Widget _buildStockCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: Get.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Get.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_box_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'No hay productos para ajustar',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Use el buscador de arriba para agregar productos',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Summary
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen',
                      style: Get.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                      controller.summaryText,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )),
                    Obx(() {
                      if (controller.totalValueImpact == 0) return const SizedBox.shrink();
                      return Text(
                        'Impacto estimado: ${controller.formatCurrency(controller.totalValueImpact)}',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: controller.totalValueImpact > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Global notes
          CustomTextField(
            controller: controller.globalNotesController,
            label: 'Notas Globales (Aplicadas a todos los ajustes)',
            hint: 'Razón general para estos ajustes...',
            maxLines: 2,
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Submit button
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancelar',
                  onPressed: () => Get.back(),
                  type: ButtonType.outline,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                flex: 2,
                child: Obx(() => CustomButton(
                  text: 'Aplicar ${controller.totalAdjustments} Ajustes',
                  onPressed: controller.isFormValid 
                      ? controller.createBulkAdjustments 
                      : null,
                  isLoading: controller.isCreating.value,
                  icon: Icons.check,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}