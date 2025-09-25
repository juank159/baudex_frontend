// lib/features/categories/presentation/screens/categories_list_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../controllers/categories_controller.dart';
import '../widgets/category_card_widget.dart';
import '../widgets/category_filter_widget.dart';
import '../widgets/category_stats_widget.dart';
import '../../domain/entities/category.dart';

class CategoriesListScreen extends GetView<CategoriesController> {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(currentRoute: '/categories'),
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
      title: const Text('Categorías'),
      elevation: 0,
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

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshCategories,
        ),

        // Menú de opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'tree_view',
                  child: Row(
                    children: [
                      Icon(Icons.account_tree),
                      SizedBox(width: 8),
                      Text('Vista de Árbol'),
                    ],
                  ),
                ),
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
        return const LoadingWidget(message: 'Cargando categorías...');
      }

      return Column(
        children: [
          // Estadísticas compactas
          if (controller.stats != null)
            Padding(
              padding: context.responsivePadding,
              child: CategoryStatsWidget(
                stats: controller.stats!,
                isCompact: true,
              ),
            ),

          // Lista de categorías
          Expanded(child: _buildCategoriesList(context)),
        ],
      );
    });
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando categorías...');
      }

      return Row(
        children: [
          // Panel lateral con filtros y estadísticas
          Container(
            width: 300,
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
                            child: CategoryStatsWidget(
                              stats: controller.stats!,
                              isCompact: false,
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Filtros
                        const CategoryFilterWidget(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista principal
          Expanded(child: _buildCategoriesList(context)),
        ],
      );
    });
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando categorías...');
      }

      return Row(
        children: [
          // Panel lateral izquierdo
          Container(
            width: 350,
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
                        Icons.filter_list,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filtros y Estadísticas',
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
                            child: CategoryStatsWidget(
                              stats: controller.stats!,
                              isCompact: false,
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Filtros
                        const CategoryFilterWidget(),

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

                // Lista de categorías
                Expanded(child: _buildCategoriesList(context)),
              ],
            ),
          ),
        ],
      );
    });
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
          // Información de resultados
          Expanded(
            child: Obx(() {
              final total = controller.totalItems;
              final current = controller.categories.length;

              return Text(
                'Mostrando $current de $total categorías',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              );
            }),
          ),

          // Acciones rápidas
          CustomButton(
            text: 'Nueva Categoría',
            icon: Icons.add,
            onPressed: controller.goToCreateCategory,
          ),

          const SizedBox(width: 12),

          CustomButton(
            text: 'Vista de Árbol',
            icon: Icons.account_tree,
            type: ButtonType.outline,
            onPressed: () => Get.toNamed('/categories/tree'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return CustomTextField(
      controller: controller.searchController,
      label: 'Buscar categorías',
      hint: 'Nombre, descripción o slug...',
      prefixIcon: Icons.search,
      suffixIcon: controller.isSearchMode ? Icons.clear : null,
      onSuffixIconPressed:
          controller.isSearchMode ? controller.clearFilters : null,
      onChanged: controller.updateSearch,
    );
  }

  Widget _buildCategoriesList(BuildContext context) {
    return Obx(() {
      final categories =
          controller.isSearchMode
              ? controller.searchResults
              : controller.categories;

      if (categories.isEmpty && !controller.isLoading) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshCategories,
        child: ListView.builder(
          controller: controller.scrollController,
          padding: context.responsivePadding,
          itemCount: categories.length + (controller.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= categories.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4), // ✅ Reducido de 6 a 4 para más compacto
              child: CategoryCardWidget(
                category: category,
                onTap: () => controller.showCategoryDetails(category.id),
                onEdit: () => controller.goToEditCategory(category.id),
                onDelete: () => controller.confirmDelete(category),
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
          Icon(Icons.category_outlined, size: 100, color: Colors.grey.shade400),
          SizedBox(height: context.verticalSpacing),
          Text(
            controller.isSearchMode
                ? 'No se encontraron categorías'
                : 'No hay categorías creadas',
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
                : 'Crea tu primera categoría para comenzar',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.verticalSpacing * 2),
          if (!controller.isSearchMode)
            CustomButton(
              text: 'Crear Primera Categoría',
              icon: Icons.add,
              onPressed: controller.goToCreateCategory,
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
        onPressed: controller.goToCreateCategory,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  // ==================== ACTION METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'tree_view':
        Get.toNamed('/categories/tree');
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
    showSearch(context: context, delegate: CategorySearchDelegate(controller));
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
              child: SingleChildScrollView(child: CategoryFilterWidget()),
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

  void _showExportDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Exportar Categorías'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecciona el formato de exportación:'),
            SizedBox(height: 16),
            // TODO: Implementar opciones de exportación
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
              // TODO: Implementar exportación
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
        title: const Text('Importar Categorías'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecciona el archivo a importar:'),
            SizedBox(height: 16),
            // TODO: Implementar opciones de importación
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
              // TODO: Implementar importación
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

class CategorySearchDelegate extends SearchDelegate<Category?> {
  final CategoriesController controller;

  CategorySearchDelegate(this.controller);

  @override
  String get searchFieldLabel => 'Buscar categorías...';

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

    controller.searchCategories(query);

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
          final category = results[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.category,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(category.name),
            subtitle: Text(category.description ?? 'Sin descripción'),
            trailing: Text(
              category.status.name.toUpperCase(),
              style: TextStyle(
                color: category.isActive ? Colors.green : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              close(context, category);
              controller.showCategoryDetails(category.id);
            },
          );
        },
      );
    });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Escribe para buscar categorías'));
    }

    return buildResults(context);
  }
}
