// lib/features/categories/presentation/screens/category_tree_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/category_tree_controller.dart';
import '../../domain/entities/category_tree.dart';

class CategoryTreeScreen extends GetView<CategoryTreeController> {
  const CategoryTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget(
            message: 'Cargando árbol de categorías...',
          );
        }

        if (!controller.hasCategories) {
          return _buildEmptyState(context);
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        );
      }),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Árbol de Categorías'),
      elevation: 0,
      actions: [
        // Búsqueda en desktop
        if (Responsive.isDesktop(context))
          Container(
            width: 300,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: _buildSearchField(context),
          ),

        // Expandir/Colapsar todo
        PopupMenuButton<String>(
          onSelected: (value) => _handleTreeAction(value),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'expand_all',
                  child: Row(
                    children: [
                      Icon(Icons.unfold_more),
                      SizedBox(width: 8),
                      Text('Expandir Todo'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'collapse_all',
                  child: Row(
                    children: [
                      Icon(Icons.unfold_less),
                      SizedBox(width: 8),
                      Text('Colapsar Todo'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Actualizar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'list_view',
                  child: Row(
                    children: [
                      Icon(Icons.list),
                      SizedBox(width: 8),
                      Text('Vista de Lista'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Búsqueda en móvil
        Container(
          padding: context.responsivePadding,
          color: Colors.grey.shade50,
          child: _buildSearchField(context),
        ),

        // Árbol
        Expanded(child: _buildTreeView(context)),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        // Panel lateral con controles
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

              // Controles del árbol
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTreeControls(context),
              ),

              const SizedBox(height: 16),

              // Información seleccionada
              Expanded(child: _buildSelectedInfo(context)),
            ],
          ),
        ),

        // Árbol principal
        Expanded(child: _buildTreeView(context)),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
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
                      Icons.account_tree,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Controles del Árbol',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Controles
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildTreeControls(context),
              ),

              const SizedBox(height: 16),

              // Información de categoría seleccionada
              Expanded(child: _buildSelectedInfo(context)),
            ],
          ),
        ),

        // Área principal del árbol
        Expanded(
          child: Column(
            children: [
              // Toolbar superior
              _buildDesktopToolbar(context),

              // Árbol
              Expanded(child: _buildTreeView(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return CustomTextField(
      controller: controller.searchController,
      label: 'Buscar categorías',
      hint: 'Nombre de categoría...',
      prefixIcon: Icons.search,
      suffixIcon: controller.isSearchMode ? Icons.clear : null,
      onSuffixIconPressed:
          controller.isSearchMode ? controller.clearSearch : null,
    );
  }

  Widget _buildTreeControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          text: 'Expandir Todo',
          icon: Icons.unfold_more,
          type: ButtonType.outline,
          onPressed: controller.expandAll,
          width: double.infinity,
        ),

        const SizedBox(height: 8),

        CustomButton(
          text: 'Colapsar Todo',
          icon: Icons.unfold_less,
          type: ButtonType.outline,
          onPressed: controller.collapseAll,
          width: double.infinity,
        ),

        const SizedBox(height: 8),

        CustomButton(
          text: 'Actualizar',
          icon: Icons.refresh,
          type: ButtonType.outline,
          onPressed: controller.refreshTree,
          width: double.infinity,
        ),

        const SizedBox(height: 16),

        const Divider(),

        const SizedBox(height: 8),

        CustomButton(
          text: 'Nueva Categoría',
          icon: Icons.add,
          onPressed: () => Get.toNamed('/categories/create'),
          width: double.infinity,
        ),

        const SizedBox(height: 8),

        CustomButton(
          text: 'Vista de Lista',
          icon: Icons.list,
          type: ButtonType.outline,
          onPressed: () => Get.toNamed('/categories'),
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildSelectedInfo(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedNode;

      if (selected == null) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Selecciona una categoría para ver sus detalles',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return CustomCard(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categoría Seleccionada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 16),

            _buildInfoRow('Nombre', selected.name),
            _buildInfoRow('Slug', selected.slug),
            _buildInfoRow('Nivel', selected.level.toString()),
            _buildInfoRow(
              'Productos',
              (selected.productsCount ?? 0).toString(),
            ),
            _buildInfoRow('Hijos', selected.hasChildren ? 'Sí' : 'No'),

            const SizedBox(height: 16),

            // Acciones
            CustomButton(
              text: 'Ver Detalles',
              icon: Icons.visibility,
              onPressed: () => controller.showCategoryDetails(selected),
              width: double.infinity,
            ),

            const SizedBox(height: 8),

            CustomButton(
              text: 'Editar',
              icon: Icons.edit,
              type: ButtonType.outline,
              onPressed: () => controller.editCategory(selected),
              width: double.infinity,
            ),

            if (selected.hasChildren) ...[
              const SizedBox(height: 8),
              CustomButton(
                text: 'Crear Subcategoría',
                icon: Icons.add,
                type: ButtonType.outline,
                onPressed: () => controller.createSubcategory(selected),
                width: double.infinity,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
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
          // Información del árbol
          Expanded(
            child: Obx(() {
              final total = controller.categoryTree.length;
              final searchTerm = controller.searchTerm;

              return Text(
                searchTerm.isNotEmpty
                    ? 'Resultados para "$searchTerm"'
                    : 'Total: $total categorías principales',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              );
            }),
          ),

          // Acciones rápidas
          CustomButton(
            text: 'Nueva Categoría',
            icon: Icons.add,
            onPressed: () => Get.toNamed('/categories/create'),
          ),

          const SizedBox(width: 12),

          CustomButton(
            text: 'Vista de Lista',
            icon: Icons.list,
            type: ButtonType.outline,
            onPressed: () => Get.toNamed('/categories'),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeView(BuildContext context) {
    return Obx(() {
      final tree =
          controller.isSearchMode
              ? controller.filteredTree
              : controller.categoryTree;

      if (tree.isEmpty) {
        return _buildEmptySearchResults(context);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshTree,
        child: ListView(
          padding: context.responsivePadding,
          children:
              tree
                  .map((category) => _buildTreeNode(context, category, 0))
                  .toList(),
        ),
      );
    });
  }

  Widget _buildTreeNode(
    BuildContext context,
    CategoryTree category,
    int depth,
  ) {
    final isExpanded = controller.isNodeExpanded(category.id);
    final isSelected = controller.isNodeSelected(category.id);
    final hasChildren = category.hasChildren;

    return Column(
      children: [
        // Nodo principal
        Container(
          margin: EdgeInsets.only(left: depth * 24.0, bottom: 4),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected
                    ? Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    )
                    : null,
          ),
          child: ListTile(
            leading:
                hasChildren
                    ? IconButton(
                      icon: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed:
                          () => controller.toggleNodeExpansion(category.id),
                    )
                    : const SizedBox(
                      width: 48,
                      child: Icon(Icons.circle, size: 6),
                    ),

            title: Text(
              category.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),

            subtitle: Row(
              children: [
                if (category.productsCount != null) ...[
                  Icon(Icons.inventory, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${category.productsCount}'),
                  const SizedBox(width: 12),
                ],
                Text(
                  'Nivel ${category.level}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),

            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleNodeAction(value, category),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text('Ver Detalles'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'create_sub',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 8),
                          Text('Crear Subcategoría'),
                        ],
                      ),
                    ),
                  ],
            ),

            onTap: () => controller.selectNode(category),
          ),
        ),

        // Hijos (si están expandidos)
        if (hasChildren && isExpanded && category.children != null)
          ...category.children!.map(
            (child) => _buildTreeNode(context, child, depth + 1),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: context.verticalSpacing),
          Text(
            'No hay categorías',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.verticalSpacing / 2),
          Text(
            'Crea tu primera categoría para comenzar',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.verticalSpacing * 2),
          CustomButton(
            text: 'Crear Primera Categoría',
            icon: Icons.add,
            onPressed: () => Get.toNamed('/categories/create'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
          SizedBox(height: context.verticalSpacing),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.verticalSpacing / 2),
          Text(
            'Intenta con otros términos de búsqueda',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.verticalSpacing * 2),
          CustomButton(
            text: 'Limpiar Búsqueda',
            icon: Icons.clear,
            type: ButtonType.outline,
            onPressed: controller.clearSearch,
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return FloatingActionButton(
        onPressed: () => Get.toNamed('/categories/create'),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  // ==================== ACTION METHODS ====================

  void _handleTreeAction(String action) {
    switch (action) {
      case 'expand_all':
        controller.expandAll();
        break;
      case 'collapse_all':
        controller.collapseAll();
        break;
      case 'refresh':
        controller.refreshTree();
        break;
      case 'list_view':
        Get.toNamed('/categories');
        break;
    }
  }

  void _handleNodeAction(String action, CategoryTree category) {
    switch (action) {
      case 'details':
        controller.showCategoryDetails(category);
        break;
      case 'edit':
        controller.editCategory(category);
        break;
      case 'create_sub':
        controller.createSubcategory(category);
        break;
    }
  }
}
