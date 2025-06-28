// lib/features/products/presentation/screens/products_list_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
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
        if (context.isMobile)
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

                // PopupMenuItem(
                //   value: 'out_of_stock',
                //   child: Row(
                //     children: [
                //       const Icon(Icons.error, color: Colors.red),
                //       const SizedBox(width: 8),
                //       const Text('Sin Stock'),
                //       const Spacer(),
                //       Obx(() {
                //         final outOfStock = controller.stats?.outOfStock ?? 0;
                //         return Text(
                //           '($outOfStock)',
                //           style: TextStyle(
                //             fontSize: 12,
                //             color:
                //                 outOfStock > 0
                //                     ? Colors.red
                //                     : Colors.grey.shade600,
                //             fontWeight:
                //                 outOfStock > 0
                //                     ? FontWeight.bold
                //                     : FontWeight.normal,
                //           ),
                //         );
                //       }),
                //     ],
                //   ),
                // ),
                PopupMenuItem(
                  value:
                      'out_of_stock', // ✅ CAMBIO: usar 'out_of_stock' en lugar de 'low_stock'
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error,
                        color: Colors.red,
                      ), // ✅ CAMBIO: ícono rojo para sin stock
                      const SizedBox(width: 8),
                      const Text('Sin Stock'), // ✅ CAMBIO: texto correcto
                      const Spacer(),
                      Obx(() {
                        final outOfStock =
                            controller.stats?.outOfStock ??
                            0; // ✅ CAMBIO: usar outOfStock
                        return Text(
                          '($outOfStock)',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                outOfStock > 0
                                    ? Colors.red
                                    : Colors
                                        .grey
                                        .shade600, // ✅ CAMBIO: color rojo
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
              padding: context.responsivePadding,
              child: ProductStatsWidget(
                stats: controller.stats!,
                isCompact: true,
              ),
            ),

          // Lista de productos
          Expanded(child: _buildProductsList(context)),
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
            width: 320,
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
          Expanded(child: _buildProductsList(context)),
        ],
      );
    });
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando productos...');
      }

      return Row(
        children: [
          // Panel lateral izquierdo
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                // Header del panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Inventario y Filtros',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Búsqueda
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSearchField(context),
                ),

                // Contenido scrolleable
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

                        const SizedBox(height: 24),

                        // Filtros
                        const ProductFilterWidget(),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Área principal
          Expanded(
            child: Column(
              children: [
                // Toolbar superior
                _buildDesktopToolbar(context),

                // Lista de productos
                Expanded(child: _buildProductsList(context)),
              ],
            ),
          ),
        ],
      );
    });
  }

  // Widget _buildDesktopToolbar(BuildContext context) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
  //     ),
  //     child: Row(
  //       children: [
  //         // Información de resultados
  //         Expanded(
  //           child: Obx(() {
  //             final total = controller.totalItems;
  //             final current = controller.products.length;

  //             return Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Mostrando $current de $total productos',
  //                   style: TextStyle(
  //                     color: Colors.grey.shade600,
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //                 if (controller.isSearchMode)
  //                   Text(
  //                     'Búsqueda: "${controller.searchTerm}"',
  //                     style: TextStyle(
  //                       color: Theme.of(context).primaryColor,
  //                       fontSize: 12,
  //                     ),
  //                   ),
  //               ],
  //             );
  //           }),
  //         ),

  //         // Acciones rápidas
  //         CustomButton(
  //           text: 'Nuevo Producto',
  //           icon: Icons.add,
  //           onPressed: controller.goToCreateProduct,
  //         ),

  //         const SizedBox(width: 12),

  //         CustomButton(
  //           text: 'Stock Bajo',
  //           icon: Icons.warning,
  //           type: ButtonType.outline,
  //           onPressed: controller.loadLowStockProducts,
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
          padding: context.responsivePadding,
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
          SizedBox(height: context.verticalSpacing),
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
          SizedBox(height: context.verticalSpacing / 2),
          Text(
            controller.isSearchMode
                ? 'Intenta con otros términos de búsqueda'
                : 'Registra tu primer producto para comenzar',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.verticalSpacing * 2),
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
    if (context.isMobile) {
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
        // TODO: Implementar carga de productos sin stock
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
            const Expanded(
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
