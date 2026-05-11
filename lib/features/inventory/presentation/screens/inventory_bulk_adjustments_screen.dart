// lib/features/inventory/presentation/screens/inventory_bulk_adjustments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/services/password_validation_service.dart';
import '../controllers/inventory_bulk_adjustments_controller.dart';
import '../widgets/product_search_widget.dart';

class InventoryBulkAdjustmentsScreen
    extends GetView<InventoryBulkAdjustmentsController> {
  const InventoryBulkAdjustmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Ajustes Masivos de Inventario',
      showBackButton: true,
      showDrawer: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet =
                constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
            final isDesktop = constraints.maxWidth >= 1200;

            return Obx(() {
              if (controller.isLoading.value &&
                  controller.warehouses.isEmpty) {
                return const Center(child: LoadingWidget());
              }

              return Column(
                children: [
                  _buildHeader(isMobile, isTablet),
                  Expanded(
                    child: _buildScrollableContent(
                      isMobile,
                      isTablet,
                      isDesktop,
                    ),
                  ),
                  if (controller.hasItems)
                    _buildFooter(isMobile, context),
                ],
              );
            });
          },
        ),
      ),
    );
  }

  // ──────────────────────── HEADER FIJO ────────────────────────

  Widget _buildHeader(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        border: Border(
          bottom: BorderSide(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
          ),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMobile) ...[
            _buildInstructionsBanner(),
            const SizedBox(height: 12),
          ],
          _buildWarehouseSection(isMobile),
          SizedBox(height: isMobile ? 8 : 12),
          _buildProductSearchSection(isMobile),
        ],
      ),
    );
  }

  Widget _buildInstructionsBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ElegantLightTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.infoGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Ajuste múltiples productos a la vez. Busque y agregue productos, '
              'ajuste las cantidades y aplique todos los cambios.',
              style: TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
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

  // ──────────────────────── SELECTOR DE ALMACÉN ────────────────────────

  Widget _buildWarehouseSection(bool isMobile) {
    return Obx(() => Container(
          padding: EdgeInsets.all(isMobile ? 12.0 : 14.0),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
            border: Border.all(
              color: controller.selectedWarehouseId.value.isEmpty
                  ? ElegantLightTheme.errorRed.withOpacity(0.3)
                  : ElegantLightTheme.primaryBlue.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: (controller.selectedWarehouseId.value.isEmpty
                        ? ElegantLightTheme.errorRed
                        : ElegantLightTheme.primaryBlue)
                    .withOpacity(0.1),
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
                    padding: EdgeInsets.all(isMobile ? 6 : 7),
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
                  SizedBox(width: isMobile ? 8 : 10),
                  Expanded(
                    child: Text(
                      'Almacén de Destino',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 12 : 13,
                        color: controller.selectedWarehouseId.value.isEmpty
                            ? ElegantLightTheme.errorRed
                            : ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (controller.selectedWarehouseId.value.isEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6 : 8,
                        vertical: isMobile ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.errorGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'REQUERIDO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 8 : 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.check_circle,
                      color: ElegantLightTheme.successGreen,
                      size: 18,
                    ),
                ],
              ),

              SizedBox(height: isMobile ? 8 : 10),

              // Auto-seleccionado con un solo almacén
              if (controller.warehouses.length == 1 &&
                  controller.selectedWarehouseId.value.isNotEmpty)
                _buildAutoSelectedWarehouse(isMobile)
              else
                _buildWarehouseDropdown(isMobile),
            ],
          ),
        ));
  }

  Widget _buildAutoSelectedWarehouse(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 14,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: ElegantLightTheme.successGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.successGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: ElegantLightTheme.successGreen,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              controller.selectedWarehouseName.value,
              style: const TextStyle(
                color: ElegantLightTheme.successGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ElegantLightTheme.successGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Auto-seleccionado',
              style: TextStyle(
                color: ElegantLightTheme.successGreen,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseDropdown(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedWarehouseId.value.isEmpty
              ? null
              : controller.selectedWarehouseId.value,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_arrow_down,
                  color: ElegantLightTheme.textSecondary,
                  size: isMobile ? 18 : 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Seleccione un almacén',
                  style: TextStyle(
                    color: ElegantLightTheme.textTertiary,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ],
            ),
          ),
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              final w =
                  controller.warehouses.firstWhere((w) => w.id == newValue);
              controller.setSelectedWarehouse(newValue, w.name);
            }
          },
          items: controller.warehouses.map<DropdownMenuItem<String>>((w) {
            return DropdownMenuItem<String>(
              value: w.id,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Icon(
                        Icons.warehouse,
                        size: isMobile ? 14 : 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            w.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 13 : 14,
                              color: ElegantLightTheme.textPrimary,
                            ),
                          ),
                          if (w.description?.isNotEmpty == true)
                            Text(
                              w.description!,
                              style: const TextStyle(
                                color: ElegantLightTheme.textSecondary,
                                fontSize: 12,
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

  // ──────────────────────── BÚSQUEDA DE PRODUCTO ────────────────────────

  Widget _buildProductSearchSection(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: ProductSearchWidget(
        hintText: 'Buscar productos para ajustar...',
        onProductSelected: controller.addProductToAdjustment,
        searchFunction: controller.searchProducts,
      ),
    );
  }

  // ──────────────────────── CONTENIDO SCROLLEABLE ────────────────────────

  Widget _buildScrollableContent(
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Obx(() {
      if (!controller.hasItems) {
        return _buildEmptyState(isMobile);
      }

      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildBulkActionsToolbar(isMobile),
          ),
          isDesktop
              ? _buildDesktopGrid()
              : isTablet
                  ? _buildTabletGrid()
                  : _buildMobileList(),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      );
    });
  }

  Widget _buildEmptyState(bool isMobile) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 400,
        ),
        margin: EdgeInsets.all(isMobile ? 16 : 32),
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ElegantLightTheme.neuomorphicShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              decoration: BoxDecoration(
                color: ElegantLightTheme.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                ),
              ),
              child: Icon(
                Icons.inventory_2,
                size: isMobile ? 36 : 52,
                color: ElegantLightTheme.primaryBlue.withOpacity(0.7),
              ),
            ),
            SizedBox(height: isMobile ? 14 : 18),
            Text(
              'No hay productos agregados',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isMobile ? 15 : 17,
                color: ElegantLightTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 8 : 10),
            Text(
              'Use el buscador de arriba para agregar productos y '
              'crear ajustes masivos de inventario.',
              style: const TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── BARRA DE ACCIONES MASIVAS ────────────────────────

  Widget _buildBulkActionsToolbar(bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 12,
      ),
      padding: EdgeInsets.all(isMobile ? 10 : 14),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 12 : 13,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
              Obx(() => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 6 : 8,
                      vertical: isMobile ? 2 : 3,
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
          SizedBox(height: isMobile ? 10 : 12),
          isMobile
              ? _buildMobileBulkActions()
              : _buildDesktopBulkActions(),
        ],
      ),
    );
  }

  Widget _buildMobileBulkActions() {
    return Column(
      children: [
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────── CUADRÍCULAS ADAPTATIVAS ────────────────────────

  Widget _buildMobileList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = controller.adjustmentItems[index];
            return _buildItemCard(item, isMobile: true);
          },
          childCount: controller.adjustmentItems.length,
        ),
      ),
    );
  }

  Widget _buildTabletGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = controller.adjustmentItems[index];
            return _buildItemCard(item, isMobile: false);
          },
          childCount: controller.adjustmentItems.length,
        ),
      ),
    );
  }

  Widget _buildDesktopGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.05,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = controller.adjustmentItems[index];
            return _buildItemCard(item, isMobile: false);
          },
          childCount: controller.adjustmentItems.length,
        ),
      ),
    );
  }

  // ──────────────────────── CARD DE CADA ITEM ────────────────────────

  Widget _buildItemCard(BulkAdjustmentItem item, {required bool isMobile}) {
    return Obx(() => Container(
          margin: isMobile ? const EdgeInsets.only(bottom: 8) : EdgeInsets.zero,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isSelected.value
                  ? ElegantLightTheme.primaryBlue.withOpacity(0.4)
                  : ElegantLightTheme.primaryBlue.withOpacity(0.1),
              width: item.isSelected.value ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (item.isSelected.value
                        ? ElegantLightTheme.primaryBlue
                        : Colors.black)
                    .withOpacity(0.1),
                blurRadius: item.isSelected.value ? 12 : 6,
                offset: Offset(0, item.isSelected.value ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera: checkbox + info producto + botón eliminar
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: item.isSelected.value,
                      onChanged: (_) =>
                          controller.toggleItemSelection(item.id),
                      activeColor: ElegantLightTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
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
                          item.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: ElegantLightTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.product.sku.isNotEmpty)
                          Text(
                            'SKU: ${item.product.sku}',
                            style: const TextStyle(
                              color: ElegantLightTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.errorRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () =>
                          controller.removeAdjustmentItem(item.id),
                      icon: const Icon(Icons.delete_outline, size: 17),
                      color: ElegantLightTheme.errorRed,
                      tooltip: 'Remover producto',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Métricas de stock
              Row(
                children: [
                  Expanded(
                    child: _buildMiniMetric(
                      'Stock Actual',
                      '${item.currentQuantity}',
                      Icons.inventory,
                      ElegantLightTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Botones +/- y campo cantidad
                  Expanded(
                    flex: 2,
                    child: _buildItemQuantityControl(item),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Obx(() => _buildMiniMetric(
                          'Ajuste',
                          item.adjustmentDifference > 0
                              ? '+${item.adjustmentDifference}'
                              : '${item.adjustmentDifference}',
                          item.adjustmentIcon,
                          item.adjustmentColor,
                        )),
                  ),
                ],
              ),

              // Notas del item (si está seleccionado)
              if (item.isSelected.value) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                    ),
                  ),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Notas para este producto...',
                      hintStyle: TextStyle(
                        color:
                            ElegantLightTheme.textTertiary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(10),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.note_add,
                          size: 15,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: ElegantLightTheme.textPrimary,
                    ),
                    maxLines: 2,
                    onChanged: (value) => item.notes.value = value,
                  ),
                ),
              ],
            ],
          ),
        ));
  }

  Widget _buildMiniMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: ElegantLightTheme.textSecondary,
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

  Widget _buildItemQuantityControl(BulkAdjustmentItem item) {
    // Widget separado con su propio State para que el TextField y los
    // botones +/- compartan la misma fuente de verdad (`item.newQuantity`)
    // sin desfases visuales — el bug histórico era que `TextFormField`
    // con `initialValue` cacheaba el valor original en su FormFieldState
    // interno y los clicks en +/- actualizaban el Rx pero el texto
    // mostrado en pantalla no.
    return _ItemQuantityControl(item: item);
  }

  // ──────────────────────── FOOTER FIJO ────────────────────────

  Widget _buildFooter(bool isMobile, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resumen
          Obx(() => Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
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
                        style: TextStyle(
                          color: ElegantLightTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 11 : 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),

          SizedBox(height: isMobile ? 10 : 14),

          // Botón aplicar
          SizedBox(
            width: double.infinity,
            child: _buildSubmitButton(isMobile, context),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isMobile, BuildContext context) {
    return Obx(() {
      final valid = controller.isFormValid;
      final submitting = controller.isCreating.value;

      return Container(
        height: isMobile ? 48 : 52,
        decoration: BoxDecoration(
          gradient: valid && !submitting
              ? ElegantLightTheme.successGradient
              : null,
          color: valid && !submitting ? null : ElegantLightTheme.cardColor,
          borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
          boxShadow: valid && !submitting
              ? [
                  BoxShadow(
                    color: ElegantLightTheme.successGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: valid && !submitting
                ? () => _onApplyPressed(context)
                : null,
            borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (submitting)
                  SizedBox(
                    width: isMobile ? 14 : 16,
                    height: isMobile ? 14 : 16,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    Icons.save,
                    color:
                        valid ? Colors.white : ElegantLightTheme.textTertiary,
                    size: isMobile ? 16 : 18,
                  ),
                SizedBox(width: isMobile ? 6 : 10),
                Flexible(
                  child: Text(
                    submitting ? 'Aplicando Ajustes...' : 'Aplicar Ajustes Masivos',
                    style: TextStyle(
                      color: valid
                          ? Colors.white
                          : ElegantLightTheme.textTertiary,
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ──────────────────────── CONFIRMACIÓN CON CONTRASEÑA ────────────────────────

  Future<void> _onApplyPressed(BuildContext context) async {
    final itemCount = controller.itemsWithChanges.length;

    final confirmed = await Get.dialog<bool>(
      barrierDismissible: false,
      _BulkConfirmPasswordDialog(
        itemCount: itemCount,
        warehouseName: controller.selectedWarehouseName.value,
      ),
    );

    if (confirmed == true) {
      controller.createBulkAdjustments();
    }
  }
}

// ──────────────────────── DIALOG DE CONFIRMACIÓN CON PASSWORD ────────────────────────

/// Dialog separado como StatefulWidget para manejar el TextEditingController
/// correctamente (dispose dentro del State) y evitar "used after disposed" en macOS.
class _BulkConfirmPasswordDialog extends StatefulWidget {
  final int itemCount;
  final String warehouseName;

  const _BulkConfirmPasswordDialog({
    required this.itemCount,
    required this.warehouseName,
  });

  @override
  State<_BulkConfirmPasswordDialog> createState() =>
      _BulkConfirmPasswordDialogState();
}

class _BulkConfirmPasswordDialogState
    extends State<_BulkConfirmPasswordDialog> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Ingrese su contraseña');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = Get.find<PasswordValidationService>();
      final valid = await service.validatePassword(password);

      if (!mounted) return;

      if (valid) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'Contraseña incorrecta. Verifique e intente de nuevo.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al validar: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera con gradiente warning
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Confirmar cambios masivos',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info de cuántos items se modifican
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.warningOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            ElegantLightTheme.warningOrange.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: ElegantLightTheme.warningOrange,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Se modificarán ${widget.itemCount} producto(s) '
                            'en ${widget.warehouseName}. '
                            'Esta acción no se puede deshacer.',
                            style: const TextStyle(
                              color: ElegantLightTheme.warningOrange,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Campo contraseña
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    autofocus: true,
                    onSubmitted: (_) => _isLoading ? null : _confirm(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: ElegantLightTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Contraseña del administrador',
                      labelStyle: const TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: ElegantLightTheme.primaryBlue,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                          color: ElegantLightTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _errorMessage != null
                              ? ElegantLightTheme.errorRed
                              : ElegantLightTheme.primaryBlue.withOpacity(0.3),
                          width: _errorMessage != null ? 2 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _errorMessage != null
                              ? ElegantLightTheme.errorRed
                              : ElegantLightTheme.primaryBlue.withOpacity(0.25),
                          width: _errorMessage != null ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _errorMessage != null
                              ? ElegantLightTheme.errorRed
                              : ElegantLightTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  // Error inline (sin cerrar el dialog)
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.errorRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ElegantLightTheme.errorRed.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: ElegantLightTheme.errorRed,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: ElegantLightTheme.errorRed,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Botones
                  Row(
                    children: [
                      // Cancelar
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: ElegantLightTheme.textTertiary
                                    .withOpacity(0.4),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Confirmar y aplicar
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : ElegantLightTheme.warningGradient,
                            color: _isLoading
                                ? ElegantLightTheme.cardColor
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _confirm,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              ElegantLightTheme.textSecondary,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Confirmar y aplicar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Control de cantidad de un item del ajuste masivo.
///
/// Tiene su propio `TextEditingController` y un `Worker.ever()` que
/// mantiene el texto en sync con el observable `item.newQuantity`.
/// Es la única forma confiable de que **tanto el teclado como los
/// botones +/-** se mantengan visualmente sincronizados — el patrón
/// anterior (`TextFormField` con `initialValue` dentro de `Obx`) no
/// funcionaba porque el FormFieldState cachea el valor inicial y no
/// reacciona a rebuilds del Obx.
class _ItemQuantityControl extends StatefulWidget {
  final BulkAdjustmentItem item;
  const _ItemQuantityControl({required this.item});

  @override
  State<_ItemQuantityControl> createState() => _ItemQuantityControlState();
}

class _ItemQuantityControlState extends State<_ItemQuantityControl> {
  late final TextEditingController _ctrl;
  Worker? _rxWorker;

  /// Lock para evitar loop infinito: Rx → controller → onChanged → Rx.
  bool _syncingFromRx = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.item.newQuantity.value.toString(),
    );
    // Cuando el Rx cambia (por +/- u otra fuente externa), reflejarlo
    // en el TextField sin retrigger el onChanged.
    _rxWorker = ever<int>(widget.item.newQuantity, (val) {
      final str = val.toString();
      if (_ctrl.text == str) return;
      _syncingFromRx = true;
      _ctrl.value = TextEditingValue(
        text: str,
        selection: TextSelection.collapsed(offset: str.length),
      );
      _syncingFromRx = false;
    });
  }

  @override
  void dispose() {
    _rxWorker?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nueva Cantidad',
            style: TextStyle(
              fontSize: 9,
              color: ElegantLightTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón − (con Obx para que su color/gradient reaccione
              // al valor actual)
              Obx(() {
                final enabled = item.newQuantity.value > 0;
                return GestureDetector(
                  onTap: enabled
                      ? () => item.newQuantity.value--
                      : null,
                  onLongPress: enabled
                      ? () {
                          final v = item.newQuantity.value - 10;
                          item.newQuantity.value = v < 0 ? 0 : v;
                        }
                      : null,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: enabled
                          ? ElegantLightTheme.primaryGradient
                          : null,
                      color: enabled
                          ? null
                          : ElegantLightTheme.cardColor,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 14,
                      color: enabled
                          ? Colors.white
                          : ElegantLightTheme.textTertiary,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              // TextField conectado al controller — el controller se
              // mantiene en sync con el Rx vía el Worker en initState.
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            ElegantLightTheme.primaryBlue.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            ElegantLightTheme.primaryBlue.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: ElegantLightTheme.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    // Skip si el cambio viene del Rx (evita loop).
                    if (_syncingFromRx) return;
                    final parsed = int.tryParse(value) ?? 0;
                    if (item.newQuantity.value != parsed) {
                      item.newQuantity.value = parsed;
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              // Botón +
              GestureDetector(
                onTap: () => item.newQuantity.value++,
                onLongPress: () => item.newQuantity.value += 10,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
