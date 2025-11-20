// lib/features/categories/presentation/screens/category_tree_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/category_tree_controller.dart';
import '../../domain/entities/category_tree.dart';

class CategoryTreeScreen extends GetView<CategoryTreeController> {
  const CategoryTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
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
        child: Obx(() {
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
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Árbol de Categorías',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
      actions: [
        // Expandir/Colapsar todo
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: PopupMenuButton<String>(
            onSelected: (value) => _handleTreeAction(value),
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Búsqueda en móvil
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: _buildFuturisticSearchField(context),
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
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Búsqueda
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildFuturisticSearchField(context),
                ),

                // Controles del árbol
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTreeControls(context),
                ),

                const SizedBox(height: 16),

                // Información seleccionada
                SizedBox(
                  height: 520, // Aumentado para dar más espacio a los botones
                  child: _buildSelectedInfo(context),
                ),

                const SizedBox(height: 16), // Espaciado adicional al final
              ],
            ),
          ),
        ),

        // Árbol principal
        Expanded(child: _buildTreeView(context)),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header con información clave
            _buildFuturisticTreeHeader(),
            const SizedBox(height: 24),

            // Tabs futuristas para diferentes vistas
            _buildFuturisticTreeTabs(),
            const SizedBox(height: 24),

            // Contenido del árbol
            _buildTreeContent(),

            // Espacio adicional al final
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }


  Widget _buildFuturisticSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        style: const TextStyle(
          color: ElegantLightTheme.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar categorías...',
          hintStyle: TextStyle(
            color: ElegantLightTheme.textSecondary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 16,
            ),
          ),
          suffixIcon: Obx(() {
            if (controller.isSearchMode) {
              return Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.errorGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.white,
                    size: 16,
                  ),
                  onPressed: controller.clearSearch,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTreeControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sección de Expansión
        _buildControlSection(
          'Expansión del Árbol',
          Icons.unfold_more,
          [
            _buildFuturisticControlButton(
              'Expandir Todo',
              Icons.unfold_more,
              ElegantLightTheme.successGradient,
              controller.expandAll,
            ),
            const SizedBox(height: 12),
            _buildFuturisticControlButton(
              'Colapsar Todo',
              Icons.unfold_less,
              ElegantLightTheme.warningGradient,
              controller.collapseAll,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Sección de Navegación
        _buildControlSection(
          'Navegación',
          Icons.navigation,
          [
            _buildFuturisticControlButton(
              'Actualizar',
              Icons.refresh,
              ElegantLightTheme.infoGradient,
              controller.refreshTree,
            ),
            const SizedBox(height: 12),
            _buildFuturisticControlButton(
              'Vista de Lista',
              Icons.list,
              ElegantLightTheme.errorGradient,
              () => Get.toNamed('/categories'),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Sección de Acciones
        _buildControlSection(
          'Acciones Rápidas',
          Icons.bolt,
          [
            _buildFuturisticControlButton(
              'Nueva Categoría',
              Icons.add,
              ElegantLightTheme.primaryGradient,
              () => Get.toNamed('/categories/create'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedInfo(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedNode;

      if (selected == null) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.warningGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.touch_app,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Selecciona una categoría',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Toca cualquier categoría del árbol para ver sus detalles',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header elegante
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Categoría Seleccionada',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Información con estilo futurístico
              _buildFuturisticInfoRow('Nombre', selected.name, Icons.label),
              _buildFuturisticInfoRow('Slug', selected.slug, Icons.link),
              _buildFuturisticInfoRow('Nivel', selected.level.toString(), Icons.layers),
              _buildFuturisticInfoRow(
                'Productos',
                (selected.productsCount ?? 0).toString(),
                Icons.inventory,
              ),
              _buildFuturisticInfoRow(
                'Hijos', 
                selected.hasChildren ? 'Sí' : 'No',
                Icons.account_tree,
              ),

              const SizedBox(height: 20),

              // Acciones con estilo futurístico
              _buildFuturisticControlButton(
                'Ver Detalles',
                Icons.visibility,
                ElegantLightTheme.infoGradient,
                () => controller.showCategoryDetails(selected),
              ),

              const SizedBox(height: 12),

              _buildFuturisticControlButton(
                'Editar',
                Icons.edit,
                ElegantLightTheme.warningGradient,
                () => controller.editCategory(selected),
              ),

              if (selected.hasChildren) ...[
                const SizedBox(height: 12),
                _buildFuturisticControlButton(
                  'Crear Subcategoría',
                  Icons.add,
                  ElegantLightTheme.successGradient,
                  () => controller.createSubcategory(selected),
                ),
              ],
            ],
          ),
        ),
      );
    });
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: [
          // Nodo principal
          Container(
            margin: EdgeInsets.only(left: depth * 24.0, bottom: 8, right: 16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? ElegantLightTheme.glassGradient
                  : ElegantLightTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.4)
                    : ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected 
                  ? [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : ElegantLightTheme.elevatedShadow,
            ),
          child: ListTile(
            leading: hasChildren
                ? Container(
                    decoration: BoxDecoration(
                      gradient: isExpanded 
                          ? ElegantLightTheme.successGradient
                          : ElegantLightTheme.infoGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (isExpanded 
                              ? ElegantLightTheme.successGradient.colors.first
                              : ElegantLightTheme.infoGradient.colors.first)
                              .withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      onPressed: () => controller.toggleNodeExpansion(category.id),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.category,
                      color: ElegantLightTheme.textSecondary,
                      size: 16,
                    ),
                  ),

            title: Text(
              category.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected 
                    ? ElegantLightTheme.primaryBlue 
                    : ElegantLightTheme.textPrimary,
                fontSize: 16,
              ),
            ),

            subtitle: Container(
              margin: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  if (category.productsCount != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.warningGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inventory,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${category.productsCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Nivel ${category.level}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            trailing: Container(
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) => _handleNodeAction(value, category),
                icon: const Icon(
                  Icons.more_vert,
                  color: ElegantLightTheme.textSecondary,
                  size: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            ),

            onTap: () => controller.selectNode(category),
          ),
        ),

        // Hijos (si están expandidos)
        if (hasChildren && isExpanded && category.children != null)
          AnimatedSlide(
            duration: const Duration(milliseconds: 400),
            offset: isExpanded ? Offset.zero : const Offset(0, -0.3),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: isExpanded ? 1.0 : 0.0,
              child: Column(
                children: category.children!.map(
                  (child) => _buildTreeNode(context, child, depth + 1),
                ).toList(),
              ),
            ),
          ),
        ],
      ),
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
      return Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => Get.toNamed('/categories/create'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 24,
          ),
        ),
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

  // ==================== FUTURISTIC COMPONENTS ====================

  Widget _buildFuturisticTreeHeader() {
    return FuturisticContainer(
      hasGlow: true,
      child: Obx(() {
        final selectedCategory = controller.selectedNode;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(
                    Icons.account_tree,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Árbol de Categorías',
                        style: TextStyle(
                          color: ElegantLightTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedCategory != null 
                            ? 'Categoría seleccionada: ${selectedCategory.name}'
                            : 'Explora la estructura jerárquica de categorías',
                        style: const TextStyle(
                          color: ElegantLightTheme.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Campo de búsqueda futurístico integrado
            _buildFuturisticSearchField(Get.context!),
          ],
        );
      }),
    );
  }



  Widget _buildFuturisticTreeTabs() {
    return Obx(() => FuturisticContainer(
      child: Row(
        children: [
          _buildTabHeader('Árbol', 0, Icons.account_tree),
          _buildTabHeader('Controles', 1, Icons.settings),
        ],
      ),
    ));
  }

  Widget _buildTabHeader(String title, int index, IconData icon) {
    final isSelected = controller.selectedTab.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreeContent() {
    return Obx(() {
      switch (controller.selectedTab.value) {
        case 0:
          return _buildTreeTab();
        case 1:
          return _buildControlsTab();
        default:
          return _buildTreeTab();
      }
    });
  }

  Widget _buildTreeTab() {
    return FuturisticContainer(
      child: SizedBox(
        height: 600, // Altura consistente para ambas pestañas
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vista de Árbol',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildTreeView(Get.context!),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildControlsTab() {
    return FuturisticContainer(
      child: SizedBox(
        height: 600, // Altura consistente para ambas pestañas
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controles del Árbol',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _buildTreeControls(Get.context!),
            const SizedBox(height: 20),
            Expanded(
              child: _buildSelectedInfo(Get.context!),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== FUTURISTIC CONTROL HELPERS ====================

  Widget _buildControlSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFuturisticControlButton(
    String text,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onPressed, {
    bool isOutline = false,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: isOutline ? null : gradient,
        borderRadius: BorderRadius.circular(12),
        border: isOutline
            ? Border.all(
                color: gradient.colors.first.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
        boxShadow: isOutline
            ? null
            : [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isOutline ? gradient.colors.first : Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    color: isOutline ? gradient.colors.first : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: ElegantLightTheme.primaryBlue,
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
