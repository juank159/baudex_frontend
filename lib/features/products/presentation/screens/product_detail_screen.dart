// lib/features/products/presentation/screens/product_detail_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/product_detail_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';

class ProductDetailScreen extends GetView<ProductDetailController> {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: ElegantLightTheme.backgroundColor,
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget(message: 'Cargando detalles...');
        }

        if (!controller.hasProduct) {
          return _buildErrorState(context);
        }

        return ResponsiveHelper.isMobile(context)
            ? _buildMobileLayout(context)
            : _buildDesktopLayout(context);
      }),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Obx(
        () => Text(
          controller.hasProduct ? controller.productName : 'Producto',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.offAllNamed(AppRoutes.products),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: controller.shareProduct,
          tooltip: 'Compartir producto',
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: controller.goToEditProduct,
          tooltip: 'Editar producto',
        ),
        IconButton(
          icon: const Icon(Icons.inventory, color: Colors.white),
          onPressed: controller.showStockDialog,
          tooltip: 'Gestionar stock',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) => _handleMenuAction(value, context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'print_label',
              child: Row(
                children: [
                  Icon(Icons.print, color: ElegantLightTheme.primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  Text('Imprimir Etiqueta', style: TextStyle(color: ElegantLightTheme.textPrimary, fontSize: 14)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'generate_report',
              child: Row(
                children: [
                  Icon(Icons.analytics, color: ElegantLightTheme.primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  Text('Generar Reporte', style: TextStyle(color: ElegantLightTheme.textPrimary, fontSize: 14)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 12),
                  Text('Actualizar', style: TextStyle(color: ElegantLightTheme.textPrimary, fontSize: 14)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 12),
                  Text('Eliminar', style: TextStyle(color: Colors.red.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================= MOBILE LAYOUT =============================
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildCompactHeader(context),
        _buildElegantTabs(context),
        Expanded(child: _buildTabContent(context)),
      ],
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Obx(() {
        final product = controller.product!;
        return Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: _getStockGradient(product),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _getStockColor(product).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _getProductIcon(product),
                  color: Colors.white,
                  size: 35,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ElegantLightTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${product.sku}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: _getStockGradient(product).scale(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStockText(product),
                          style: TextStyle(
                            color: _getStockColor(product),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.defaultPrice != null)
                        Text(
                          AppFormatters.formatPrice(product.defaultPrice!.finalAmount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildElegantTabs(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 65,
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _buildTabButton(
                title: 'Detalles',
                icon: Icons.info_outline,
                index: 0,
                isSelected: controller.currentTabIndex == 0,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                title: 'Precios',
                icon: Icons.sell_outlined,
                index: 1,
                isSelected: controller.currentTabIndex == 1,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                title: 'Movimientos',
                icon: Icons.swap_horiz,
                index: 2,
                isSelected: controller.currentTabIndex == 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required int index,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: ElegantLightTheme.normalAnimation,
      curve: ElegantLightTheme.smoothCurve,
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.tabController.animateTo(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                  size: 18,
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return TabBarView(
      controller: controller.tabController,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: _buildProductDetails(context),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: _buildPricesSection(context),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: _buildMovementsSection(context),
        ),
      ],
    );
  }

  // ============================= DESKTOP LAYOUT =============================
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildDesktopHeader(context),
                const SizedBox(height: 20),
                _buildProductDetails(context),
              ],
            ),
          ),
        ),
        _buildElegantSidebar(context),
      ],
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Obx(() {
        final product = controller.product!;
        return Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: _getStockGradient(product),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _getStockColor(product).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _getProductIcon(product),
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ElegantLightTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SKU: ${product.sku}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: ElegantLightTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (product.barcode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Código: ${product.barcode}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: product.isActive ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.isActive ? 'ACTIVO' : 'INACTIVO',
                          style: TextStyle(
                            color: product.isActive ? Colors.green.shade800 : Colors.orange.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: _getStockGradient(product).scale(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStockColor(product).withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStockIcon(product),
                              size: 12,
                              color: _getStockColor(product),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStockText(product),
                              style: TextStyle(
                                color: _getStockColor(product),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (product.description != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      product.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: ElegantLightTheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (product.defaultPrice != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatPrice(product.defaultPrice!.finalAmount),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  if (product.defaultPrice!.hasDiscount)
                    Text(
                      AppFormatters.formatPrice(product.defaultPrice!.amount),
                      style: const TextStyle(
                        fontSize: 15,
                        decoration: TextDecoration.lineThrough,
                        color: ElegantLightTheme.textTertiary,
                      ),
                    ),
                ],
              ),
          ],
        );
      }),
    );
  }

  Widget _buildElegantSidebar(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tabs header
          Container(
            height: 75,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _buildSidebarTab(
                      title: 'Detalles',
                      icon: Icons.info_outline,
                      index: 0,
                      isSelected: controller.currentTabIndex == 0,
                    ),
                  ),
                  Expanded(
                    child: _buildSidebarTab(
                      title: 'Precios',
                      icon: Icons.sell_outlined,
                      index: 1,
                      isSelected: controller.currentTabIndex == 1,
                    ),
                  ),
                  Expanded(
                    child: _buildSidebarTab(
                      title: 'Historial',
                      icon: Icons.history,
                      index: 2,
                      isSelected: controller.currentTabIndex == 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                _buildSidebarDetailsTab(),
                _buildSidebarPricesTab(),
                _buildSidebarMovementsTab(),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSidebarActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTab({
    required String title,
    required IconData icon,
    required int index,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: ElegantLightTheme.normalAnimation,
      curve: ElegantLightTheme.smoothCurve,
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.tabController.animateTo(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarDetailsTab() {
    return Obx(() {
      final product = controller.product!;
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSidebarSection(
              title: 'Stock',
              items: [
                _buildSidebarInfoRow(
                  'Actual',
                  '${AppFormatters.formatStock(product.stock)} ${product.unit ?? "uds"}',
                  Icons.inventory_2_outlined,
                  valueColor: _getStockColor(product),
                ),
                _buildSidebarInfoRow(
                  'Mínimo',
                  '${AppFormatters.formatStock(product.minStock)} ${product.unit ?? "uds"}',
                  Icons.warning_amber,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSidebarSection(
              title: 'Información',
              items: [
                _buildSidebarInfoRow('Tipo', product.type.name.toUpperCase(), Icons.category_outlined),
                _buildSidebarInfoRow('Categoría', product.category?.name ?? 'N/A', Icons.folder_outlined),
                _buildSidebarInfoRow('Unidad', product.unit ?? 'pcs', Icons.straighten),
              ],
            ),
            const SizedBox(height: 16),
            _buildSidebarSection(
              title: 'Impuestos',
              items: [
                _buildSidebarInfoRow(
                  'Categoría',
                  product.taxCategory.displayName,
                  Icons.receipt_long_outlined,
                ),
                _buildSidebarInfoRow(
                  'Tasa',
                  '${AppFormatters.formatNumber(product.taxRate)}%',
                  Icons.percent,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSidebarPricesTab() {
    return Obx(() {
      final product = controller.product!;
      if (product.prices == null || product.prices!.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.price_change_outlined, size: 60, color: ElegantLightTheme.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Sin precios',
                style: TextStyle(
                  fontSize: 14,
                  color: ElegantLightTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: product.prices!.length,
        itemBuilder: (context, index) {
          final price = product.prices![index];
          return _buildSidebarPriceCard(price);
        },
      );
    });
  }

  Widget _buildSidebarMovementsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: ElegantLightTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Historial de Movimientos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Funcionalidad pendiente',
              style: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ElegantLightTheme.primaryBlue,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildSidebarInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ElegantLightTheme.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? ElegantLightTheme.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarPriceCard(dynamic price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getPriceTypeDisplayName(price.type),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
              Text(
                AppFormatters.formatPrice(price.finalAmount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          if (_hasDiscount(price)) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Antes: ${AppFormatters.formatPrice(price.amount)}',
                  style: const TextStyle(
                    fontSize: 10,
                    decoration: TextDecoration.lineThrough,
                    color: ElegantLightTheme.textTertiary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '-${AppFormatters.formatNumber(price.discountPercentage)}%',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarActions() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: controller.goToEditProduct,
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Editar Producto'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ElegantLightTheme.primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: controller.showStockDialog,
          icon: const Icon(Icons.inventory, size: 18),
          label: const Text('Gestionar Stock'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ElegantLightTheme.primaryBlue,
            side: const BorderSide(color: ElegantLightTheme.primaryBlue, width: 2),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => ElevatedButton.icon(
            onPressed: controller.isDeleting ? null : controller.confirmDelete,
            icon: const Icon(Icons.delete, size: 18),
            label: Text(controller.isDeleting ? 'Eliminando...' : 'Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ============================= CONTENT SECTIONS =============================
  Widget _buildProductDetails(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información Básica
          _buildCompactInfoCard(
            title: 'Información Básica',
            icon: Icons.info_outline,
            children: [
              _buildCompactRow('Tipo', product.type.name.toUpperCase(), Icons.category),
              _buildCompactRow('Categoría', product.category?.name ?? 'N/A', Icons.folder),
              _buildCompactRow('Unidad', product.unit ?? 'pcs', Icons.straighten),
              _buildCompactRow('Creado por', product.createdBy?.fullName ?? 'N/A', Icons.person),
            ],
          ),
          const SizedBox(height: 16),

          // Gestión de Stock
          _buildCompactInfoCard(
            title: 'Gestión de Stock',
            icon: Icons.inventory_2_outlined,
            children: [
              _buildCompactRow(
                'Stock Actual',
                '${AppFormatters.formatStock(product.stock)} ${product.unit ?? "pcs"}',
                Icons.inventory,
                valueColor: _getStockColor(product),
              ),
              _buildCompactRow(
                'Stock Mínimo',
                '${AppFormatters.formatStock(product.minStock)} ${product.unit ?? "pcs"}',
                Icons.warning_amber,
              ),
              if (product.isLowStock)
                _buildCompactRow(
                  'Alerta',
                  'Stock por debajo del mínimo',
                  Icons.error,
                  valueColor: Colors.orange,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Facturación Electrónica
          _buildCompactInfoCard(
            title: 'Facturación Electrónica',
            icon: Icons.receipt_long_outlined,
            children: [
              _buildCompactRow('Categoría de Impuesto', product.taxCategory.displayName, Icons.receipt_long),
              _buildCompactRow('Tasa de Impuesto', '${AppFormatters.formatNumber(product.taxRate)}%', Icons.percent),
              _buildCompactRow(
                'Está Gravado',
                product.isTaxable ? 'Sí' : 'No',
                Icons.check_circle,
                valueColor: product.isTaxable ? Colors.green : Colors.grey,
              ),
              if (product.hasRetention) ...[
                if (product.retentionCategory != null)
                  _buildCompactRow('Retención', product.retentionCategory!.displayName, Icons.money_off),
                if (product.retentionRate != null)
                  _buildCompactRow('Tasa Retención', '${AppFormatters.formatNumber(product.retentionRate!)}%', Icons.trending_down),
              ],
            ],
          ),
        ],
      );
    });
  }

  Widget _buildCompactInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: ElegantLightTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCompactRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: ElegantLightTheme.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? ElegantLightTheme.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesSection(BuildContext context) {
    return Obx(() {
      final product = controller.product!;

      if (product.prices == null || product.prices!.isEmpty) {
        return _buildEmptyState(
          icon: Icons.price_change_outlined,
          title: 'Sin precios configurados',
          message: 'Este producto no tiene precios configurados',
          actionText: 'Configurar Precios',
          onAction: controller.goToEditProduct,
        );
      }

      return Column(
        children: product.prices!.map((price) => _buildPriceCard(price)).toList(),
      );
    });
  }

  Widget _buildPriceCard(dynamic price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getPriceTypeDisplayName(price.type),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
              const Spacer(),
              Text(
                AppFormatters.formatPrice(price.finalAmount),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          if (_hasDiscount(price)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Precio original: ${AppFormatters.formatPrice(price.amount)}',
                  style: const TextStyle(
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                    color: ElegantLightTheme.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${AppFormatters.formatNumber(price.discountPercentage)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_hasMinQuantity(price)) ...[
            const SizedBox(height: 6),
            Text(
              'Cantidad mínima: ${AppFormatters.formatNumber(price.minQuantity)}',
              style: const TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMovementsSection(BuildContext context) {
    return _buildEmptyState(
      icon: Icons.history,
      title: 'Historial de Movimientos',
      message: 'Funcionalidad pendiente de implementar',
      actionText: null,
      onAction: null,
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: ElegantLightTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: ElegantLightTheme.textTertiary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.edit, size: 16),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 100, color: ElegantLightTheme.textTertiary),
          const SizedBox(height: 20),
          const Text(
            'Producto no encontrado',
            style: TextStyle(
              fontSize: 18,
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'El producto que buscas no existe o ha sido eliminado',
            style: TextStyle(color: ElegantLightTheme.textTertiary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a Productos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ElegantLightTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: FloatingActionButton(
          onPressed: controller.goToEditProduct,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      );
    }
    return null;
  }

  // ============================= HELPER METHODS =============================
  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'print_label':
        controller.printLabel();
        break;
      case 'generate_report':
        controller.generateReport();
        break;
      case 'refresh':
        controller.refreshData();
        break;
      case 'delete':
        controller.confirmDelete();
        break;
    }
  }

  IconData _getProductIcon(Product product) {
    if (product.type == ProductType.service) {
      return Icons.handyman;
    }
    return Icons.shopping_bag;
  }

  Color _getStockColor(Product product) {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return Colors.red.shade600;
    } else if (product.isLowStock) {
      return ElegantLightTheme.accentOrange;
    } else {
      return Colors.green.shade600;
    }
  }

  LinearGradient _getStockGradient(Product product) {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return ElegantLightTheme.errorGradient;
    } else if (product.isLowStock) {
      return ElegantLightTheme.warningGradient;
    } else {
      return ElegantLightTheme.successGradient;
    }
  }

  IconData _getStockIcon(Product product) {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return Icons.remove_circle;
    } else if (product.isLowStock) {
      return Icons.warning;
    } else {
      return Icons.check_circle;
    }
  }

  String _getStockText(Product product) {
    if (product.stock <= 0 || product.status == ProductStatus.outOfStock) {
      return 'SIN STOCK';
    } else if (product.isLowStock) {
      return 'STOCK BAJO';
    } else {
      return 'EN STOCK';
    }
  }

  String _getPriceTypeDisplayName(dynamic priceType) {
    try {
      if (priceType is PriceType) {
        return priceType.displayName;
      }
      if (priceType is String) {
        return _mapStringToPriceTypeName(priceType);
      }
      final typeString = priceType.toString().split('.').last;
      return _mapStringToPriceTypeName(typeString);
    } catch (e) {
      return 'Precio';
    }
  }

  String _mapStringToPriceTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'price1':
        return 'Precio al Público';
      case 'price2':
        return 'Precio Mayorista';
      case 'price3':
        return 'Precio Distribuidor';
      case 'special':
        return 'Precio Especial';
      case 'cost':
        return 'Precio de Costo';
      default:
        return type.toUpperCase();
    }
  }

  bool _hasDiscount(dynamic productPrice) {
    try {
      if (productPrice == null) return false;
      final discountPercentage = productPrice.discountPercentage;
      if (discountPercentage != null && discountPercentage > 0) return true;
      final discountAmount = productPrice.discountAmount;
      if (discountAmount != null && discountAmount > 0) return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  bool _hasMinQuantity(dynamic productPrice) {
    try {
      if (productPrice == null) return false;
      final minQuantity = productPrice.minQuantity;
      if (minQuantity != null && minQuantity > 1) return true;
      return false;
    } catch (e) {
      return false;
    }
  }
}
