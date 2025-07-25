// lib/features/products/presentation/screens/products_list_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/products_controller.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/product_filter_widget.dart';
import '../widgets/product_stats_widget.dart';
import '../../domain/entities/product.dart';

class ProductsListScreen extends GetView<ProductsController> {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Gestión de Productos'),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Get.offAllNamed(AppRoutes.dashboard);
        },
      ),
      actions: [
        // Búsqueda rápida en móvil
        if (ResponsiveHelper.isMobile(context))
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showMobileSearch(context),
          ),

        // Filtros
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilters(context),
        ),

        // ✅ OPTIMIZADO: Stock bajo con mejor indicador
        Obx(() {
          final lowStockCount = controller.stats?.lowStock ?? 0;

          return IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: lowStockCount > 0 ? Colors.orange : null,
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
                controller.loadLowStockProducts();
              } else {
                Get.snackbar(
                  'Sin alertas',
                  'No hay productos con stock bajo',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green.shade100,
                  colorText: Colors.green.shade800,
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  duration: const Duration(seconds: 2),
                );
              }
            },
            tooltip:
                lowStockCount > 0
                    ? 'Ver $lowStockCount productos con stock bajo'
                    : 'No hay productos con stock bajo',
          );
        }),

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshProducts,
        ),

        // ✅ OPTIMIZADO: Menú con información de estado
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      const Icon(Icons.analytics),
                      const SizedBox(width: 8),
                      const Text('Estadísticas'),
                      const Spacer(),
                      Obx(() {
                        final total = controller.stats?.total ?? 0;
                        return Text(
                          '($total)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'low_stock',
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('Stock Bajo'),
                      const Spacer(),
                      Obx(() {
                        final lowStock = controller.stats?.lowStock ?? 0;
                        return Text(
                          '($lowStock)',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                lowStock > 0
                                    ? Colors.orange
                                    : Colors.grey.shade600,
                            fontWeight:
                                lowStock > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'out_of_stock',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      const Text('Sin Stock'),
                      const Spacer(),
                      Obx(() {
                        final outOfStock = controller.stats?.outOfStock ?? 0;
                        return Text(
                          '($outOfStock)',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                outOfStock > 0
                                    ? Colors.red
                                    : Colors.grey.shade600,
                            fontWeight:
                                outOfStock > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Exportar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.upload),
                      SizedBox(width: 8),
                      Text('Importar'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando productos...');
      }

      return Column(
        children: [
          // Estadísticas compactas
          if (controller.stats != null)
            Padding(
              padding: ResponsiveHelper.getPadding(context),
              child: ProductStatsWidget(
                stats: controller.stats!,
                isCompact: true,
              ),
            ),

          // Lista de productos
          Expanded(
            child: _buildProductsList(context),
          ),
        ],
      );
    });
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando productos...');
      }

      return Row(
        children: [
          // Panel lateral con filtros y estadísticas
          Container(
            width: ResponsiveHelper.getWidth(
              context,
              mobile: 300,
              tablet: 320,
              desktop: 340,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // Búsqueda
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSearchField(context),
                ),

                // Filtros
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Estadísticas
                        if (controller.stats != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ProductStatsWidget(
                              stats: controller.stats!,
                              isCompact: false,
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Filtros
                        const ProductFilterWidget(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista principal
          Expanded(
            child: _buildProductsList(context),
          ),
        ],
      );
    });
  }

  // ✅ CORREGIDO: El problema principal estaba aquí
 Widget _buildDesktopLayout(BuildContext context) {
  return Obx(() {
    if (controller.isLoading) {
      return const LoadingWidget(message: 'Cargando productos...');
    }

    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      children: [
        // ✅ PANEL LATERAL OPTIMIZADO - Más compacto y proporcional
        Container(
          width: _getOptimalSidebarWidth(screenWidth),
          constraints: const BoxConstraints(
            minWidth: 280,
            maxWidth: 380,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              right: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // ✅ HEADER COMPACTO
              _buildCompactSidebarHeader(context),
              
              // ✅ BÚSQUEDA COMPACTA
              _buildCompactSearchSection(context),
              
              // ✅ CONTENIDO SCROLLEABLE OPTIMIZADO
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      // ✅ ESTADÍSTICAS COMPACTAS
                      _buildCompactStatsSection(context),
                      
                      const SizedBox(height: 16),
                      
                      // ✅ FILTROS COMPACTOS
                      _buildCompactFiltersSection(context),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ✅ ÁREA PRINCIPAL - Más espacio para contenido
        Expanded(
          child: Column(
            children: [
              // Toolbar superior mejorado
              _buildEnhancedDesktopToolbar(context),

              // Lista de productos
              Expanded(
                child: _buildProductsList(context),
              ),
            ],
          ),
        ),
      ],
    );
  });
}

double _getOptimalSidebarWidth(double screenWidth) {
  if (screenWidth < 1200) {
    return 280; // Pantallas pequeñas
  } else if (screenWidth < 1600) {
    return 320; // Pantallas medianas
  } else {
    return 350; // Pantallas grandes
  }
}

// ✅ HEADER COMPACTO DEL SIDEBAR
Widget _buildCompactSidebarHeader(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).primaryColor.withOpacity(0.1),
          Theme.of(context).primaryColor.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border(
        bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.filter_list,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtros y Búsqueda',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                ),
              ),
              Obx(() {
                final hasFilters = _hasActiveFilters();
                return Text(
                  hasFilters ? 'Filtros activos' : 'Sin filtros',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasFilters ? Colors.orange : Colors.grey.shade600,
                    fontWeight: hasFilters ? FontWeight.w500 : FontWeight.normal,
                  ),
                );
              }),
            ],
          ),
        ),
        // Botón para colapsar filtros (funcionalidad futura)
        IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 18,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            // TODO: Implementar colapso del sidebar
            Get.snackbar(
              'Función futura',
              'Colapsar sidebar próximamente',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
            );
          },
          tooltip: 'Colapsar panel',
        ),
      ],
    ),
  );
}

Widget _buildCompactSearchSection(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(12),
    child: CustomTextField(
      controller: controller.searchController,
      label: 'Buscar',
      hint: 'Nombre, SKU, código...',
      prefixIcon: Icons.search,
      suffixIcon: controller.isSearchMode ? Icons.clear : null,
      onSuffixIconPressed: controller.isSearchMode ? controller.clearFilters : null,
      onChanged: controller.updateSearch,
    ),
  );
}

Widget _buildCompactStatsSection(BuildContext context) {
  return Obx(() {
    final stats = controller.stats;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
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
                Icons.analytics,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Resumen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Grid de estadísticas 2x2
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildCompactStatItem(
                'Total',
                stats.total.toString(),
                Icons.inventory_2,
                Colors.blue,
              ),
              _buildCompactStatItem(
                'Activos',
                stats.active.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildCompactStatItem(
                'Stock Bajo',
                stats.lowStock.toString(),
                Icons.warning,
                stats.lowStock > 0 ? Colors.orange : Colors.grey,
              ),
              _buildCompactStatItem(
                'Sin Stock',
                stats.outOfStock.toString(),
                Icons.error,
                stats.outOfStock > 0 ? Colors.red : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  });
}


Widget _buildCompactStatItem(
  String label,
  String value,
  IconData icon,
  Color color,
) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // 🎯 RESPONSIVE DESIGN PROFESIONAL PARA DESKTOP
      final screenWidth = MediaQuery.of(context).size.width;
      final cardWidth = constraints.maxWidth;
      final cardHeight = constraints.maxHeight;
      
      // Escalado inteligente basado en tamaño de pantalla
      final scale = (screenWidth / 1920).clamp(0.7, 1.5); // Base 1920px
      
      // Tamaños responsivos profesionales
      final iconSize = (cardWidth * 0.14 * scale).clamp(16.0, 20.0);
      final fontSize = (cardWidth * 0.22 * scale).clamp(14.0, 16.0);
      final labelSize = (cardWidth * 0.12 * scale).clamp(10.0, 11.0);
      final padding = (cardWidth * 0.12).clamp(8.0, 12.0);
      final spacing = (cardHeight * 0.06).clamp(2.0, 4.0);
      
      return Container(
        width: cardWidth,
        height: cardHeight,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Icono con fondo elegante
            Container(
              padding: EdgeInsets.all(spacing * 0.8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon, 
                color: color, 
                size: iconSize,
              ),
            ),
            
            SizedBox(height: spacing),
            
            // Número prominente con auto-escalado
            Expanded(
              flex: 2,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: spacing * 0.5),
            
            // Label elegante
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: labelSize,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}


Widget _buildCompactFiltersSection(BuildContext context) {
  return Column(
    children: [
      // Filtros de estado
      _buildCompactFilterCard(
        'Estado del Producto',
        Icons.toggle_on,
        _buildStatusFilters(),
      ),
      
      const SizedBox(height: 12),
      
      // Filtros de stock
      _buildCompactFilterCard(
        'Estado del Stock',
        Icons.inventory,
        _buildStockFilters(),
      ),
      
      const SizedBox(height: 12),
      
      // Filtros de tipo
      _buildCompactFilterCard(
        'Tipo de Producto',
        Icons.category,
        _buildTypeFilters(),
      ),
      
      const SizedBox(height: 12),
      
      // Acciones rápidas
      _buildQuickActionsCard(),
    ],
  );
}

Widget _buildCompactFilterCard(
  String title,
  IconData icon,
  Widget content,
) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        content,
      ],
    ),
  );
}

Widget _buildStatusFilters() {
  return Obx(() {
    return Column(
      children: [
        _buildCompactFilterOption(
          'Todos',
          controller.currentStatus == null,
          () => controller.applyStatusFilter(null),
          Colors.grey,
        ),
        const SizedBox(height: 6),
        _buildCompactFilterOption(
          'Activos',
          controller.currentStatus == ProductStatus.active,
          () => controller.applyStatusFilter(ProductStatus.active),
          Colors.green,
        ),
        const SizedBox(height: 6),
        _buildCompactFilterOption(
          'Inactivos',
          controller.currentStatus == ProductStatus.inactive,
          () => controller.applyStatusFilter(ProductStatus.inactive),
          Colors.orange,
        ),
      ],
    );
  });
}

Widget _buildStockFilters() {
  return Obx(() {
    return Column(
      children: [
        _buildCompactToggleOption(
          'Solo en stock',
          controller.inStock == true,
          () => controller.applyStockFilter(
            inStock: controller.inStock == true ? null : true,
          ),
          Colors.green,
        ),
        const SizedBox(height: 6),
        _buildCompactToggleOption(
          'Stock bajo',
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

Widget _buildTypeFilters() {
  return Obx(() {
    return Column(
      children: [
        _buildCompactFilterOption(
          'Todos',
          controller.currentType == null,
          () => controller.applyTypeFilter(null),
          Colors.grey,
        ),
        const SizedBox(height: 6),
        _buildCompactFilterOption(
          'Productos',
          controller.currentType == ProductType.product,
          () => controller.applyTypeFilter(ProductType.product),
          Colors.blue,
        ),
        const SizedBox(height: 6),
        _buildCompactFilterOption(
          'Servicios',
          controller.currentType == ProductType.service,
          () => controller.applyTypeFilter(ProductType.service),
          Colors.purple,
        ),
      ],
    );
  });
}

Widget _buildCompactFilterOption(
  String label,
  bool isSelected,
  VoidCallback onTap,
  Color color,
) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade400,
                width: 1.5,
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCompactToggleOption(
  String label,
  bool isSelected,
  VoidCallback onTap,
  Color color,
) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade400,
                width: 1.5,
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildQuickActionsCard() {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flash_on,
              size: 14,
              color: Colors.amber.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Botón limpiar filtros
        if (_hasActiveFilters())
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Limpiar Filtros',
              icon: Icons.clear_all,
              type: ButtonType.outline,
              onPressed: controller.clearFilters,
              fontSize: 11,
              height: 32,
            ),
          ),
        
        if (_hasActiveFilters()) const SizedBox(height: 8),
        
        // Botón stock bajo
        Obx(() {
          final lowStockCount = controller.stats?.lowStock ?? 0;
          return SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: lowStockCount > 0 ? 'Stock Bajo ($lowStockCount)' : 'Stock Bajo',
              icon: Icons.warning,
              type: lowStockCount > 0 ? ButtonType.primary : ButtonType.text,
              onPressed: lowStockCount > 0 
                  ? controller.loadLowStockProducts 
                  : null,
              fontSize: 11,
              height: 32,
            ),
          );
        }),
      ],
    ),
  );
}

Widget _buildEnhancedDesktopToolbar(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(
        bottom: BorderSide(color: Colors.grey.shade200),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        // Información de resultados
        Expanded(
          child: Obx(() {
            final total = controller.totalItems;
            final current = controller.products.length;
            final stats = controller.stats;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mostrando $current de $total productos',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (controller.isSearchMode)
                  Text(
                    'Búsqueda: "${controller.searchTerm}"',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                if (stats != null && !controller.isSearchMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _buildQuickStat('Activos', stats.active, Colors.green),
                        if (stats.lowStock > 0)
                          _buildQuickStat('Stock Bajo', stats.lowStock, Colors.orange),
                        if (stats.outOfStock > 0)
                          _buildQuickStat('Sin Stock', stats.outOfStock, Colors.red),
                      ],
                    ),
                  ),
              ],
            );
          }),
        ),

        // Acciones principales
        Row(
          children: [
            CustomButton(
              text: 'Nuevo Producto',
              icon: Icons.add,
              onPressed: controller.goToCreateProduct,
              height: 44,
            ),
            const SizedBox(width: 12),
            Obx(() {
              final lowStockCount = controller.stats?.lowStock ?? 0;
              return CustomButton(
                text: lowStockCount > 0 ? 'Ver Alertas ($lowStockCount)' : 'Sin Alertas',
                icon: Icons.notifications,
                type: lowStockCount > 0 ? ButtonType.outline : ButtonType.text,
                onPressed: lowStockCount > 0 ? controller.loadLowStockProducts : null,
                height: 44,
              );
            }),
          ],
        ),
      ],
    ),
  );
}

bool _hasActiveFilters() {
  return controller.currentStatus != null ||
      controller.currentType != null ||
      controller.selectedCategoryId != null ||
      controller.inStock != null ||
      controller.lowStock != null ||
      controller.searchTerm.isNotEmpty;
}


  Widget _buildDesktopToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // ✅ MEJORADO: Información de resultados más detallada
          Expanded(
            child: Obx(() {
              final total = controller.totalItems;
              final current = controller.products.length;
              final stats = controller.stats;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mostrando $current de $total productos',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (controller.isSearchMode)
                    Text(
                      'Búsqueda: "${controller.searchTerm}"',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  // ✅ AÑADIDO: Resumen de estado del inventario
                  if (stats != null && !controller.isSearchMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          _buildQuickStat(
                            'Activos',
                            stats.active,
                            Colors.green,
                          ),
                          const SizedBox(width: 12),
                          if (stats.lowStock > 0)
                            _buildQuickStat(
                              'Stock Bajo',
                              stats.lowStock,
                              Colors.orange,
                            ),
                          if (stats.outOfStock > 0) ...[
                            const SizedBox(width: 12),
                            _buildQuickStat(
                              'Sin Stock',
                              stats.outOfStock,
                              Colors.red,
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            }),
          ),

          // Acciones rápidas
          CustomButton(
            text: 'Nuevo Producto',
            icon: Icons.add,
            onPressed: controller.goToCreateProduct,
          ),

          const SizedBox(width: 12),

          // ✅ MEJORADO: Botón de stock bajo con estado dinámico
          Obx(() {
            final lowStockCount = controller.stats?.lowStock ?? 0;

            return CustomButton(
              text:
                  lowStockCount > 0
                      ? 'Stock Bajo ($lowStockCount)'
                      : 'Stock Bajo',
              icon: Icons.warning,
              type: lowStockCount > 0 ? ButtonType.primary : ButtonType.outline,
              onPressed:
                  lowStockCount > 0
                      ? controller.loadLowStockProducts
                      : () {
                        Get.snackbar(
                          'Sin alertas',
                          'No hay productos con stock bajo',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.green.shade100,
                          colorText: Colors.green.shade800,
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          duration: const Duration(seconds: 2),
                        );
                      },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return CustomTextField(
      controller: controller.searchController,
      label: 'Buscar productos',
      hint: 'Nombre, SKU, código de barras...',
      prefixIcon: Icons.search,
      suffixIcon: controller.isSearchMode ? Icons.clear : null,
      onSuffixIconPressed:
          controller.isSearchMode ? controller.clearFilters : null,
      onChanged: controller.updateSearch,
    );
  }

  Widget _buildProductsList(BuildContext context) {
    return Obx(() {
      final products =
          controller.isSearchMode
              ? controller.searchResults
              : controller.products;

      if (products.isEmpty && !controller.isLoading) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshProducts,
        child: ListView.builder(
          controller: controller.scrollController,
          padding: ResponsiveHelper.getPadding(context),
          itemCount: products.length + (controller.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= products.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final product = products[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProductCardWidget(
                product: product,
                onTap: () => controller.showProductDetails(product.id),
                onEdit: () => controller.goToEditProduct(product.id),
                onDelete: () => controller.confirmDelete(product),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            controller.isSearchMode
                ? Icons.search_off
                : Icons.inventory_2_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
          Text(
            controller.isSearchMode
                ? 'No se encontraron productos'
                : 'No hay productos registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) / 2),
          Text(
            controller.isSearchMode
                ? 'Intenta con otros términos de búsqueda'
                : 'Registra tu primer producto para comenzar',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context) * 2),
          if (!controller.isSearchMode)
            CustomButton(
              text: 'Registrar Primer Producto',
              icon: Icons.add,
              onPressed: controller.goToCreateProduct,
            )
          else
            CustomButton(
              text: 'Limpiar Búsqueda',
              icon: Icons.clear,
              type: ButtonType.outline,
              onPressed: controller.clearFilters,
            ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return FloatingActionButton(
        onPressed: controller.goToCreateProduct,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  // ==================== ACTION METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'stats':
        _showStatsDialog(context);
        break;
      case 'low_stock':
        controller.loadLowStockProducts();
        break;
      case 'out_of_stock':
        controller.applyStockFilter(inStock: false);
        break;
      case 'export':
        _showExportDialog(context);
        break;
      case 'import':
        _showImportDialog(context);
        break;
    }
  }

  void _showMobileSearch(BuildContext context) {
    showSearch(context: context, delegate: ProductSearchDelegate(controller));
  }

  void _showFilters(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      controller.clearFilters();
                      Get.back();
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),

            // Filters content
            Flexible(
              child: SingleChildScrollView(child: ProductFilterWidget()),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      type: ButtonType.outline,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Aplicar',
                      onPressed: () => Get.back(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showStatsDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Estadistica de Productos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text('Funcionalidad pendiente de implementar')],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Estadisticas',
                'Funcionalidad pendiente de implementar',
                snackPosition: SnackPosition.TOP,
              );
            },
            child: const Text('Ver Estadísticas'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Exportar Productos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecciona el formato de exportación:'),
            SizedBox(height: 16),
            Text('Funcionalidad pendiente de implementar'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Exportar',
                'Funcionalidad pendiente de implementar',
                snackPosition: SnackPosition.TOP,
              );
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Importar Productos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecciona el archivo a importar:'),
            SizedBox(height: 16),
            Text('Funcionalidad pendiente de implementar'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Importar',
                'Funcionalidad pendiente de implementar',
                snackPosition: SnackPosition.TOP,
              );
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }
}

// ==================== SEARCH DELEGATE ====================

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final ProductsController controller;

  ProductSearchDelegate(this.controller);

  @override
  String get searchFieldLabel => 'Buscar productos...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 2) {
      return const Center(
        child: Text('Ingresa al menos 2 caracteres para buscar'),
      );
    }
    controller.searchProducts(query);

    return Obx(() {
      if (controller.isSearching) {
        return const Center(child: CircularProgressIndicator());
      }

      final results = controller.searchResults;
      if (results.isEmpty) {
        return const Center(child: Text('No se encontraron resultados'));
      }

      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final product = results[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.inventory_2,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(product.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SKU: ${product.sku}'),
                Text('Stock: ${product.stock.toStringAsFixed(2)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.status.name.toUpperCase(),
                  style: TextStyle(
                    color: product.isActive ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.defaultPrice != null)
                  Text(
                    '\$${product.defaultPrice!.finalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            onTap: () {
              close(context, product);
              controller.showProductDetails(product.id);
            },
          );
        },
      );
    });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Escribe para buscar productos'));
    }

    return buildResults(context);
  }
}