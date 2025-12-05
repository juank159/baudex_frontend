// lib/features/products/presentation/screens/products_list_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/shared/widgets/custom_text_field_safe.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/products_controller.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/product_skeleton_widget.dart';
import '../../domain/entities/product.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  ProductsController get controller => Get.find<ProductsController>();

  @override
  void initState() {
    super.initState();
    // Limpiar búsqueda cuando regresas a esta pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.clearSearchOnReturn();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(currentRoute: '/products'),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ElegantLightTheme.backgroundColor,
              ElegantLightTheme.cardColor,
            ],
          ),
        ),
        child: ResponsiveHelper.responsive(
          context,
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Gestión de Productos',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
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
      actions: [
        Obx(() => IconButton(
          icon: controller.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh, color: Colors.white),
          onPressed: controller.isLoading ? null : () async {
            await controller.refreshProducts();
            _showRefreshSuccess();
          },
          tooltip: controller.isLoading ? 'Actualizando...' : 'Actualizar productos',
        )),

        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          onPressed: () => _showFilters(context),
          tooltip: 'Filtros avanzados',
        ),

        Obx(() {
          final lowStockCount = controller.stats?.lowStock ?? 0;

          return IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: lowStockCount > 0 ? Colors.orange : Colors.white,
                ),
                if (lowStockCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$lowStockCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              if (lowStockCount > 0) {
                controller.applyStockFilter(lowStock: true);
              } else {
                Get.snackbar(
                  'Sin alertas',
                  'No hay productos con stock bajo',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green.shade100,
                  colorText: Colors.green.shade800,
                );
              }
            },
            tooltip: lowStockCount > 0
                ? 'Ver $lowStockCount productos con stock bajo'
                : 'Sin productos con stock bajo',
          );
        }),

        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return const SizedBox.shrink();
    }

    if (ResponsiveHelper.isMobile(context)) {
      return Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            ...ElegantLightTheme.glowShadow,
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => Get.toNamed('/products/create'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          ...ElegantLightTheme.glowShadow,
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () => Get.toNamed('/products/create'),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Nuevo Producto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Obx(() {
      // Mostrar skeleton en desktop también mientras carga
      if (controller.isLoading && controller.products.isEmpty) {
        return Row(
          children: [
            _DesktopSidebar(controller: controller),
            const Expanded(
              child: ProductSkeletonList(itemCount: 6),
            ),
          ],
        );
      }

      return Row(
        children: [
          _DesktopSidebar(controller: controller),
          Expanded(
            child: Column(
              children: [
                _DesktopToolbar(controller: controller),
                Expanded(child: _buildProductsList()),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _SearchField(controller: controller),
        ),
        Expanded(child: _buildProductsList()),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _SearchField(controller: controller),
        ),
        Expanded(child: _buildProductsList()),
      ],
    );
  }

  Widget _buildProductsList() {
    return Obx(() {
      // Mostrar skeleton mientras carga inicialmente
      if (controller.isLoading && controller.products.isEmpty) {
        return const ProductSkeletonList(itemCount: 8);
      }

      final productList = controller.isSearchMode
          ? controller.searchResults
          : controller.products;

      if (productList.isEmpty && !controller.isLoading) {
        return _EmptyState(isSearching: controller.isSearchMode);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshProducts,
        child: Column(
          children: [
            // Indicador de carga sutil en la parte superior cuando refresca
            if (controller.isLoading && controller.products.isNotEmpty)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(ElegantLightTheme.primaryBlue),
              ),

            if (controller.totalPages > 1) _PaginationInfo(controller: controller),

            Expanded(
              child: ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                // Optimización: cache más elementos para scroll suave
                cacheExtent: 500,
                // Optimización: agregar key para mejor reconciliación
                key: ValueKey('products_list_${productList.length}'),
                itemCount: productList.length + (controller.hasNextPage ? 1 : 0),
                itemBuilder: (context, index) {
                  // Mostrar indicador de carga al final si hay más páginas
                  if (index == productList.length) {
                    return _LoadMoreIndicator(controller: controller);
                  }

                  final product = productList[index];

                  return ProductCardWidget(
                    key: ValueKey('product_${product.id}'),
                    product: product,
                    onTap: () => Get.toNamed('/products/detail/${product.id}'),
                    onEdit: () => Get.toNamed('/products/edit/${product.id}'),
                    onDelete: () => _showDeleteDialog(product),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showDeleteDialog(Product product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar el producto "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteProduct(product.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con diseño moderno
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: ElegantLightTheme.glowShadow,
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Filtros de Productos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: ElegantLightTheme.textTertiary.withOpacity(0.1),
                          foregroundColor: ElegantLightTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FilterSection(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRefreshSuccess() {
    Get.snackbar(
      'Actualizado',
      'Los productos se han actualizado correctamente',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}

// ==================== EXTRACTED WIDGETS ====================

class _DesktopSidebar extends StatelessWidget {
  final ProductsController controller;

  const _DesktopSidebar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height - kToolbarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const _SidebarHeader(),
          _SearchField(controller: controller),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatsSection(controller: controller),
                  const SizedBox(height: 16),
                  _FilterSection(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Productos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                'Gestión y búsqueda',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ProductsController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomTextFieldSafe(
          controller: controller.searchController,
          label: '',
          hint: 'Buscar por nombre, SKU o código de barras...',
          prefixIcon: Icons.search,
          onChanged: (value) => controller.debouncedSearch(value),
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final ProductsController controller;

  const _StatsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.stats;
      if (stats == null) return const SizedBox.shrink();

      return FuturisticContainer(
        hasGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(
                    Icons.analytics,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatRow(
              label: 'Total',
              value: stats.total.toString(),
              icon: Icons.inventory_2,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Activos',
              value: stats.active.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Stock Bajo',
              value: stats.lowStock.toString(),
              icon: Icons.warning,
              color: stats.lowStock > 0 ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: 'Sin Stock',
              value: stats.outOfStock.toString(),
              icon: Icons.error,
              color: stats.outOfStock > 0 ? Colors.red : Colors.grey,
            ),
          ],
        ),
      );
    });
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [color, color.withValues(alpha: 0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final ProductsController controller;

  const _FilterSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Filtros',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Estado',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'Todos',
              isSelected: controller.currentStatus == null,
              onTap: () => controller.applyStatusFilter(null),
              color: Colors.grey,
            ),
            _FilterChip(
              label: 'Activos',
              isSelected: controller.currentStatus == ProductStatus.active,
              onTap: () => controller.applyStatusFilter(ProductStatus.active),
              color: Colors.green,
            ),
            _FilterChip(
              label: 'Inactivos',
              isSelected: controller.currentStatus == ProductStatus.inactive,
              onTap: () => controller.applyStatusFilter(ProductStatus.inactive),
              color: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Stock',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'En Stock',
              isSelected: controller.inStock == true,
              onTap: () => controller.applyStockFilter(
                inStock: controller.inStock == true ? null : true,
              ),
              color: Colors.green,
            ),
            _FilterChip(
              label: 'Stock Bajo',
              isSelected: controller.lowStock == true,
              onTap: () => controller.applyStockFilter(
                lowStock: controller.lowStock == true ? null : true,
              ),
              color: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_hasActiveFilters(controller))
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Limpiar Filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    ));
  }

  bool _hasActiveFilters(ProductsController controller) {
    return controller.currentStatus != null ||
        controller.currentType != null ||
        controller.inStock != null ||
        controller.lowStock != null ||
        controller.searchTerm.isNotEmpty;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: ElegantLightTheme.normalAnimation,
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : ElegantLightTheme.elevatedShadow,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : ElegantLightTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  final ProductsController controller;

  const _DesktopToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final searchMode = controller.isSearchMode;
              final count = searchMode
                  ? controller.searchResults.length
                  : controller.products.length;
              final label = searchMode ? 'Resultados' : 'Productos';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$label ($count)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (controller.totalPages > 1)
                    Text(
                      controller.paginationInfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (searchMode && controller.searchTerm.isNotEmpty)
                    Text(
                      'Búsqueda: "${controller.searchTerm}"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              );
            }),
          ),
          Obx(() {
            if (controller.isSearching) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Buscando...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                onSelected: (value) => _handleDesktopAction(value, context),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 12),
                        Text('Exportar Lista'),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'stats',
                    child: Row(
                      children: [
                        Icon(Icons.analytics, size: 18),
                        SizedBox(width: 12),
                        Text('Estadísticas'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.more_horiz, size: 18),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => Get.toNamed('/products/create'),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Nuevo Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleDesktopAction(String action, BuildContext context) {
    switch (action) {
      case 'export':
        Get.snackbar(
          'Próximamente',
          'La función de exportar productos estará disponible pronto',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.download, color: Colors.green),
        );
        break;
      case 'stats':
        Get.toNamed('/products/stats');
        break;
    }
  }
}

class _PaginationInfo extends StatelessWidget {
  final ProductsController controller;

  const _PaginationInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() => Column(
        children: [
          LinearProgressIndicator(
            value: controller.loadingProgress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                controller.paginationInfo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (controller.isLoadingMore)
                Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cargando...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      )),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  final ProductsController controller;

  const _LoadMoreIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingMore) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ElegantLightTheme.primaryBlue.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cargando más productos...',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      // Auto-cargar cuando el usuario llega al final
      if (controller.canLoadMore) {
        // Trigger automático de carga
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.canLoadMore) {
            controller.loadMoreProducts();
          }
        });
      }

      return const SizedBox(height: 20);
    });
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;

  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.inventory_2,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Sin resultados' : 'No hay productos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Intenta con otros términos de búsqueda'
                : 'Crea tu primer producto',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class FuturisticContainer extends StatelessWidget {
  final Widget child;
  final bool hasGlow;

  const FuturisticContainer({
    super.key,
    required this.child,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
        ),
        boxShadow: hasGlow ? ElegantLightTheme.glowShadow : ElegantLightTheme.elevatedShadow,
      ),
      child: child,
    );
  }
}
