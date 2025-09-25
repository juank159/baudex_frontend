// ✅ VERSIÓN CORREGIDA CON APPBAR Y BÚSQUEDA PROFESIONAL
// lib/features/products/presentation/screens/products_list_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/core/widgets/safe_text_editing_controller.dart';
import '../../../../app/core/widgets/safe_text_field.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../controllers/products_controller.dart';
import '../widgets/product_card_widget.dart';
import '../../domain/entities/product.dart';

class ProductsListScreen extends GetView<ProductsController> {
  // Timer no puede ser final en widget inmutable, usar controlador para debounce
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(currentRoute: '/products'),
      backgroundColor: Colors.grey.shade50,
      body: ResponsiveHelper.responsive(
        context,
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildFixedDesktopLayout(context),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  // ✅ APPBAR RESTAURADO
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Gestión de Productos'),
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      actions: [
        // Búsqueda rápida en móvil
        if (ResponsiveHelper.isMobile(context))
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showMobileSearch(context),
          ),

        // Refresh profesional
        Obx(() => IconButton(
          icon: controller.isLoading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh),
          onPressed: controller.isLoading ? null : () async {
            await controller.refreshProducts();
            _showRefreshSuccess();
          },
          tooltip: controller.isLoading ? 'Actualizando...' : 'Actualizar productos',
        )),

        // Filtros
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilters(context),
        ),

        // Stock bajo con indicador
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
            tooltip:
                lowStockCount > 0
                    ? 'Ver $lowStockCount productos con stock bajo'
                    : 'Sin productos con stock bajo',
          );
        }),

        const SizedBox(width: 8),
      ],
    );
  }

  // ✅ FLOATING ACTION BUTTON - Solo para móvil y tablet
  Widget _buildFloatingActionButton(BuildContext context) {
    // Solo mostrar FAB en dispositivos móviles y tablet
    if (ResponsiveHelper.isDesktop(context)) {
      return const SizedBox.shrink(); // No mostrar en desktop
    }

    return Obx(() {
      final isExpanded = controller.isFabExpanded.value;
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed Dial Options (mostrar cuando está expandido)
          if (isExpanded) ...[
            _buildFabOption(
              context,
              icon: Icons.analytics,
              label: 'Estadísticas',
              backgroundColor: Colors.blue,
              onPressed: () => Get.toNamed('/products/stats'),
            ),
            const SizedBox(height: 16),
            _buildFabOption(
              context,
              icon: Icons.warning_amber,
              label: 'Stock Bajo',
              backgroundColor: Colors.orange,
              onPressed: () => Get.toNamed('/products/low-stock'),
            ),
            const SizedBox(height: 16),
            _buildFabOption(
              context,
              icon: Icons.search,
              label: 'Buscar',
              backgroundColor: Colors.green,
              onPressed: () => _showMobileSearch(context),
            ),
            const SizedBox(height: 16),
          ],

          // Main FAB
          FloatingActionButton(
            onPressed: () {
              if (isExpanded) {
                // Si está expandido, ir a crear producto
                Get.toNamed('/products/create');
              } else {
                // Si no está expandido, expandir el speed dial
                controller.toggleFabExpanded();
              }
            },
            backgroundColor: isExpanded ? Colors.red : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            child: AnimatedRotation(
              turns: isExpanded ? 0.125 : 0.0, // 45 grados cuando expandido
              duration: const Duration(milliseconds: 200),
              child: Icon(isExpanded ? Icons.close : Icons.add),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFabOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    if (ResponsiveHelper.isMobile(context)) {
      // En móvil solo mostrar el FAB pequeño
      return FloatingActionButton.small(
        onPressed: () {
          controller.toggleFabExpanded(); // Cerrar el speed dial
          onPressed();
        },
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        child: Icon(icon),
      );
    } else {
      // En tablet mostrar con etiqueta
      return FloatingActionButton.extended(
        onPressed: () {
          controller.toggleFabExpanded(); // Cerrar el speed dial
          onPressed();
        },
        icon: Icon(icon),
        label: Text(label),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
      );
    }
  }

  // ✅ NUEVO LAYOUT DESKTOP CON BÚSQUEDA PROFESIONAL
  Widget _buildFixedDesktopLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando productos...');
      }

      return Row(
        children: [
          // ✅ SIDEBAR FIJO SIN OVERFLOW
          Container(
            width: 300,
            height: MediaQuery.of(context).size.height - kToolbarHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
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
                // Header fijo
                _buildFixedHeader(context),

                // Quick Actions para Desktop
                _buildDesktopQuickActions(context),

                // Búsqueda profesional con debounce
                _buildProfessionalSearch(context),

                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFixedStats(context),
                        const SizedBox(height: 16),
                        _buildFixedFilters(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ CONTENIDO PRINCIPAL
          Expanded(
            child: Column(
              children: [
                // Toolbar superior
                _buildFixedToolbar(context),

                // Lista de productos
                Expanded(child: _buildProductsList(context)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDesktopQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.add_box,
                  label: 'Crear',
                  color: Colors.green,
                  onPressed: () => Get.toNamed('/products/create'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.analytics,
                  label: 'Estadísticas',
                  color: Colors.blue,
                  onPressed: () => Get.toNamed('/products/stats'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.warning_amber,
                  label: 'Stock Bajo',
                  color: Colors.orange,
                  onPressed: () => Get.toNamed('/products/low-stock'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 1,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildFixedHeader(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
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
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }

  // ✅ BÚSQUEDA PROFESIONAL CON DEBOUNCE
  Widget _buildProfessionalSearch(BuildContext context) {
    return Container(
      height: 110, // ✅ AJUSTADO: Aumentado para dar más espacio al hintText
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // ✅ AJUSTADO: Menos padding vertical
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Búsqueda Inteligente',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10), // ✅ AJUSTADO: Más espacio entre título y campo
          Expanded( // ✅ AJUSTADO: Permite que el campo use todo el espacio disponible
            child: ProfessionalSearchField(
              controller: controller.searchController,
              onChanged: (value) => _performDebouncedSearch(value),
              onClear: controller.clearFilters,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DEBOUNCED SEARCH IMPLEMENTATION
  void _performDebouncedSearch(String query) {
    // Usar el método debounced del controller que maneja su propio timer
    controller.debouncedSearch(query);
  }

  Widget _buildFixedStats(BuildContext context) {
    return Obx(() {
      final stats = controller.stats;
      if (stats == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  Icons.analytics,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats en lista vertical - SIN GRID COMPLEJO
            _buildStatRow(
              'Total',
              stats.total.toString(),
              Icons.inventory_2,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Activos',
              stats.active.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Stock Bajo',
              stats.lowStock.toString(),
              Icons.warning,
              stats.lowStock > 0 ? Colors.orange : Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Sin Stock',
              stats.outOfStock.toString(),
              Icons.error,
              stats.outOfStock > 0 ? Colors.red : Colors.grey,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedFilters(BuildContext context) {
    return Column(
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

        // Filtros de estado
        _buildFilterSection('Estado', [
          _buildFilterChip(
            'Todos',
            controller.currentStatus == null,
            () => controller.applyStatusFilter(null),
            Colors.grey,
          ),
          _buildFilterChip(
            'Activos',
            controller.currentStatus == ProductStatus.active,
            () => controller.applyStatusFilter(ProductStatus.active),
            Colors.green,
          ),
          _buildFilterChip(
            'Inactivos',
            controller.currentStatus == ProductStatus.inactive,
            () => controller.applyStatusFilter(ProductStatus.inactive),
            Colors.orange,
          ),
        ]),

        const SizedBox(height: 16),

        // Filtros de stock
        _buildFilterSection('Stock', [
          _buildFilterChip(
            'En Stock',
            controller.inStock == true,
            () => controller.applyStockFilter(
              inStock: controller.inStock == true ? null : true,
            ),
            Colors.green,
          ),
          _buildFilterChip(
            'Stock Bajo',
            controller.lowStock == true,
            () => controller.applyStockFilter(
              lowStock: controller.lowStock == true ? null : true,
            ),
            Colors.orange,
          ),
        ]),

        const SizedBox(height: 16),

        // Botón limpiar filtros
        if (_hasActiveFilters())
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Limpiar Filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterSection(String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? color : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFixedToolbar(BuildContext context) {
    return Container(
      height: 90, // ✅ Aumentado de 70 a 90 para evitar overflow en búsqueda
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
          // Información de productos con paginación
          Expanded(
            child: Obx(() {
              final searchMode = controller.isSearchMode;
              final count =
                  searchMode
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
                  // ✅ PAGINACIÓN: Mostrar información de página
                  if (controller.totalPages > 1) ...[
                    Text(
                      controller.paginationInfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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

          // Indicador de búsqueda activa
          Obx(() {
            if (controller.isSearching) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
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

          // ✅ BOTONES PROFESIONALES PARA DESKTOP
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón de acciones secundarias
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: PopupMenuButton<String>(
                  onSelected: (value) => _handleDesktopAction(value, context),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'import',
                          child: Row(
                            children: [
                              Icon(Icons.upload_file, size: 18),
                              SizedBox(width: 12),
                              Text('Importar Productos'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 18),
                              SizedBox(width: 12),
                              Text('Exportar Lista'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'categories',
                          child: Row(
                            children: [
                              Icon(Icons.category, size: 18),
                              SizedBox(width: 12),
                              Text('Gestionar Categorías'),
                            ],
                          ),
                        ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Botón principal - Nuevo Producto
              Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/products/create'),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Nuevo Producto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mantener layouts móvil y tablet simples
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: ProfessionalSearchField(
            controller: controller.searchController,
            onChanged: (value) => _performDebouncedSearch(value),
            onClear: controller.clearFilters,
          ),
        ),
        Expanded(child: _buildProductsList(context)),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: ProfessionalSearchField(
            controller: controller.searchController,
            onChanged: (value) => _performDebouncedSearch(value),
            onClear: controller.clearFilters,
          ),
        ),
        Expanded(child: _buildProductsList(context)),
      ],
    );
  }

  Widget _buildProductsList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando productos...');
      }

      // Usar searchResults si estamos en modo búsqueda, sino products normales
      final productList =
          controller.isSearchMode
              ? controller.searchResults
              : controller.products;

      if (productList.isEmpty) {
        final isSearching = controller.isSearchMode;
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
                    : 'Agrega tu primer producto',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshProducts,
        child: Column(
          children: [
            // ✅ PAGINACIÓN PROFESIONAL: Indicador de progreso de carga
            if (controller.totalPages > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Obx(() {
                  return Column(
                    children: [
                      // Barra de progreso de carga
                      LinearProgressIndicator(
                        value: controller.loadingProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Información de paginación
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.paginationInfo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              // ✅ DEBUG: Mostrar conteo real de productos
                              Text(
                                'Mostrando: ${productList.length} productos',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                  );
                }),
              ),
            
            // ✅ DEBUG: Mostrar información de debugging
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Obx(() {
                return Text(
                  '🔍 DEBUG: ${productList.length} productos en lista | Página ${controller.currentPage}/${controller.totalPages}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade700,
                    fontFamily: 'monospace',
                  ),
                );
              }),
            ),
            
            // Lista principal con scroll infinito
            Expanded(
              child: ListView.builder(
                controller: controller.scrollController, // ✅ Usar el controlador de scroll del controller
                padding: const EdgeInsets.all(16),
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  final product = productList[index];
                  
                  return Column(
                    children: [
                      ProductCardWidget(
                        product: product,
                        onTap: () => Get.toNamed('/products/detail/${product.id}'),
                        onEdit: () => Get.toNamed('/products/edit/${product.id}'),
                        onDelete: () => _showDeleteDialog(product),
                      ),
                      
                      // ✅ Indicador de carga al final de la lista
                      if (index == productList.length - 1 && 
                          controller.hasNextPage)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Obx(() {
                            if (controller.isLoadingMore) {
                              return Column(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cargando más productos...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                            }
                            
                            return TextButton(
                              onPressed: controller.canLoadMore ? controller.loadMoreProducts : null,
                              child: Text(
                                controller.canLoadMore 
                                    ? 'Cargar más productos' 
                                    : 'No hay más productos',
                              ),
                            );
                          }),
                        ),
                    ],
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
        content: Text(
          '¿Estás seguro de que deseas eliminar "${product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteProduct(product.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return controller.currentStatus != null ||
        controller.currentType != null ||
        controller.inStock != null ||
        controller.lowStock != null ||
        controller.searchTerm.isNotEmpty;
  }

  void _showMobileSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Búsqueda de Productos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                ProfessionalSearchField(
                  controller: controller.searchController,
                  onChanged: (value) => _performDebouncedSearch(value),
                  onClear: controller.clearFilters,
                  autofocus: true,
                ),
              ],
            ),
          ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filtros de Productos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFixedFilters(context),
              ],
            ),
          ),
    );
  }

  // ✅ MANEJA ACCIONES DEL MENÚ DESKTOP
  void _handleDesktopAction(String action, BuildContext context) {
    switch (action) {
      case 'import':
        _showInfoSnackbar(
          'Próximamente',
          'La función de importar productos estará disponible pronto',
          Icons.upload_file,
          Colors.blue,
        );
        break;
      case 'export':
        _showInfoSnackbar(
          'Próximamente',
          'La función de exportar productos estará disponible pronto',
          Icons.download,
          Colors.green,
        );
        break;
      case 'categories':
        _showInfoSnackbar(
          'Próximamente',
          'La gestión de categorías estará disponible pronto',
          Icons.category,
          Colors.orange,
        );
        break;
    }
  }

  void _showInfoSnackbar(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color.withOpacity(0.1),
      colorText: color,
      icon: Icon(icon, color: color),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showRefreshSuccess() {
    Get.snackbar(
      'Actualizado',
      'Los productos se han actualizado correctamente',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withOpacity(0.1),
      colorText: Colors.green.shade800,
      icon: Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}

// ✅ WIDGET DE BÚSQUEDA ULTRA-SEGURO - NUNCA CRASHEA
class ProfessionalSearchField extends StatefulWidget {
  final SafeTextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final bool autofocus;

  const ProfessionalSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.autofocus = false,
  });

  @override
  State<ProfessionalSearchField> createState() =>
      _ProfessionalSearchFieldState();
}

class _ProfessionalSearchFieldState extends State<ProfessionalSearchField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildUltraSafeTextField(),
    );
  }

  Widget _buildUltraSafeTextField() {
    try {
      // Usar SafeTextField para máxima protección
      return SafeTextField(
        controller: widget.controller.isSafeToUse ? widget.controller : null,
        autofocus: widget.autofocus,
        hintText: 'Buscar por nombre, SKU o código de barras...',
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, SKU o código de barras...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
          suffixIcon: _buildSuffixIcon(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16, // ✅ AJUSTADO: Aumentado de 12 a 16 para mejor visualización del hintText
          ),
        ),
        style: const TextStyle(fontSize: 14),
        onChanged: (value) {
          if (mounted) {
            try {
              widget.onChanged(value);
            } catch (e) {
              print('⚠️ Error in search onChanged: $e');
            }
          }
        },
      );
    } catch (e) {
      print('⚠️ Error building ultra-safe TextField: $e');
      return _buildBasicFallback();
    }
  }

  Widget _buildSuffixIcon() {
    try {
      final hasText =
          widget.controller.isSafeToUse && widget.controller.text.isNotEmpty;

      if (hasText) {
        return IconButton(
          icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
          onPressed: () {
            if (mounted && widget.controller.isSafeToUse) {
              try {
                widget.onClear();
              } catch (e) {
                print('⚠️ Error clearing search: $e');
              }
            }
          },
        );
      } else {
        return Icon(
          Icons.qr_code_scanner,
          color: Colors.grey.shade400,
          size: 20,
        );
      }
    } catch (e) {
      print('⚠️ Error building suffix icon: $e');
      return Icon(Icons.search, color: Colors.grey.shade400, size: 20);
    }
  }

  Widget _buildBasicFallback() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Buscar por nombre, SKU o código de barras...',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
