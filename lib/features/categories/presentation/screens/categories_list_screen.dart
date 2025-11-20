// lib/features/categories/presentation/screens/categories_list_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../controllers/categories_controller.dart';
import '../widgets/category_card_widget.dart';
import '../widgets/category_filter_widget.dart';
import '../widgets/category_stats_widget.dart';
import '../../domain/entities/category.dart';

class CategoriesListScreen extends GetWidget<CategoriesController> {
  const CategoriesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildFuturisticAppBar(context),
      drawer: const AppDrawer(currentRoute: '/categories'),
      body: Container(
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
        child: Stack(
          children: [
            // Fondo con patrón de partículas
            Positioned.fill(
              child: CustomPaint(
                painter: FuturisticParticlesPainter(),
              ),
            ),
            // Contenido principal
            SafeArea(
              child: ResponsiveLayout(
                mobile: _buildFuturisticMobileLayout(context),
                tablet: _buildFuturisticTabletLayout(context),
                desktop: _buildFuturisticDesktopLayout(context),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFuturisticFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildFuturisticAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(
              Icons.category,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Categorías',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Menú',
        ),
      ),
      actions: [
        _buildFuturisticActionButton(
          icon: Icons.filter_list,
          onPressed: () => _showFilters(context),
          tooltip: 'Filtros',
        ),
        _buildFuturisticActionButton(
          icon: Icons.refresh,
          onPressed: controller.refreshCategories,
          tooltip: 'Actualizar',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ElegantLightTheme.primaryGradient.colors.first,
              ElegantLightTheme.primaryGradient.colors.last,
              ElegantLightTheme.primaryBlue,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: ElegantLightTheme.primaryBlue.withValues(alpha: 0.5),
    );
  }

  Widget _buildFuturisticActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFuturisticMobileLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return _buildFuturisticLoadingState();
      }

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header futurístico con estadísticas
            _buildFuturisticStatsHeader(isCompact: true),
            const SizedBox(height: 24),

            // Búsqueda futurística
            _buildFuturisticSearchField(),
            const SizedBox(height: 24),

            // Lista de categorías con animaciones
            _buildFuturisticCategoriesList(context),
          ],
        ),
      );
    });
  }

  Widget _buildFuturisticTabletLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return _buildFuturisticLoadingState();
      }

      return Row(
        children: [
          // Panel lateral futurístico - ancho optimizado para tablet
          Container(
            width: 350, // Aumentado de 320 a 350 para más espacio en las tarjetas
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient,
              border: Border(
                right: BorderSide(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header del panel
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                        ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.infoGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Panel de Control',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ElegantLightTheme.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Búsqueda
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildFuturisticSearchField(),
                ),

                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Estadísticas
                        _buildFuturisticStatsHeader(isCompact: false),
                        const SizedBox(height: 24),

                        // Filtros futurísticos
                        _buildFuturisticFilterSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildFuturisticCategoriesList(context),
            ),
          ),
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
                    child: Container(
                      height: 48, // Altura unificada
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.glassGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => Get.back(),
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: ElegantLightTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48, // Altura unificada
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => Get.back(),
                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Text(
                              'Aplicar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
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

// ==================== FUTURISTIC WIDGETS ====================

extension FuturisticCategoriesWidgets on CategoriesListScreen {
  Widget _buildFuturisticLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(
                Icons.category,
                color: ElegantLightTheme.textPrimary,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cargando categorías...',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Preparando la experiencia futurista',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticDesktopLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return _buildFuturisticLoadingState();
      }

      return Row(
        children: [
          // Panel lateral avanzado
          Container(
            width: 380,
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient,
              border: Border(
                right: BorderSide(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header avanzado
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ElegantLightTheme.primaryBlue.withValues(alpha: 0.15),
                        ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.warningGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: ElegantLightTheme.glowShadow,
                        ),
                        child: const Icon(
                          Icons.dashboard,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Centro de Control',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: ElegantLightTheme.textPrimary,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Gestión avanzada de categorías',
                              style: TextStyle(
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

                // Búsqueda avanzada
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildFuturisticSearchField(),
                ),

                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Estadísticas avanzadas
                        _buildFuturisticStatsHeader(isCompact: false),
                        const SizedBox(height: 32),

                        // Herramientas rápidas
                        _buildQuickToolsSection(),
                        const SizedBox(height: 24),

                        // Filtros avanzados
                        _buildFuturisticFilterSection(),
                        const SizedBox(height: 24),
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
                // Toolbar futurístico
                _buildFuturisticToolbar(context),

                // Lista de categorías
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildFuturisticCategoriesList(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFuturisticStatsHeader({required bool isCompact}) {
    return Obx(() {
      if (controller.stats == null) return const SizedBox.shrink();

      return FuturisticContainer(
        hasGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Estadísticas',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Grid de métricas responsive
            _buildStatsGrid(isCompact: isCompact),
          ],
        ),
      );
    });
  }

  Widget _buildStatsGrid({required bool isCompact}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Configuración responsive más conservadora para evitar overflow
        int crossAxisCount;
        double childAspectRatio;
        
        if (screenWidth >= 1200) {
          // Desktop: 3 columnas con ratio más alto para evitar overflow
          crossAxisCount = 3;
          childAspectRatio = 1.6; // Aumentado de 1.2 a 1.6
        } else if (screenWidth >= 800) {
          // Tablet: 3 columnas más compactas
          crossAxisCount = 3;
          childAspectRatio = 1.4; // Más espacio vertical
        } else {
          // Mobile: 3 columnas en una sola fila
          crossAxisCount = 3;
          childAspectRatio = 0.9; // Más compacto para que quepan las 3 cards
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: screenWidth < 800 ? 6 : 10, // Más compacto en móvil
          crossAxisSpacing: screenWidth < 800 ? 6 : 10, // Más compacto en móvil
          children: [
            _buildResponsiveMetricCard(
              'Total',
              '${controller.stats?.total ?? 0}',
              Icons.category,
              ElegantLightTheme.primaryBlue,
              screenWidth,
            ),
            _buildResponsiveMetricCard(
              'Activas',
              '${controller.stats?.active ?? 0}',
              Icons.check_circle,
              ElegantLightTheme.successGradient.colors.first,
              screenWidth,
            ),
            _buildResponsiveMetricCard(
              'Inactivas',
              '${controller.stats?.inactive ?? 0}',
              Icons.pause_circle,
              ElegantLightTheme.warningGradient.colors.first,
              screenWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveMetricCard(
    String label, 
    String value, 
    IconData icon, 
    Color color, 
    double screenWidth
  ) {
    // Tamaños responsivos para evitar overflow
    double iconSize;
    double valueFontSize;
    double labelFontSize;
    double verticalSpacing;
    double horizontalPadding;
    
    if (screenWidth >= 1200) {
      // Desktop: tamaños más pequeños para evitar overflow
      iconSize = 18; // Reducido de 24 a 18
      valueFontSize = 14; // Reducido de 18 a 14
      labelFontSize = 10; // Reducido de 12 a 10
      verticalSpacing = 4; // Reducido de 8 a 4
      horizontalPadding = 8; // Padding más compacto
    } else if (screenWidth >= 800) {
      // Tablet: tamaños intermedios
      iconSize = 20; 
      valueFontSize = 15;
      labelFontSize = 11;
      verticalSpacing = 5;
      horizontalPadding = 10;
    } else {
      // Mobile: tamaños más pequeños para 3 columnas en una fila
      iconSize = 16; // Reducido de 22 a 16
      valueFontSize = 12; // Reducido de 16 a 12
      labelFontSize = 9; // Reducido de 11 a 9
      verticalSpacing = 3; // Reducido de 6 a 3
      horizontalPadding = 6; // Reducido de 12 a 6
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding, 
        vertical: horizontalPadding
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 6, // Reducido de 8 a 6
            offset: const Offset(0, 3), // Reducido de 4 a 3
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Importante para evitar overflow
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(height: verticalSpacing),
          FittedBox( // Usar FittedBox para escalar automáticamente si es necesario
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: valueFontSize,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: verticalSpacing / 2),
          FittedBox( // Usar FittedBox para el label también
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticSearchField() {
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.updateSearch,
        style: const TextStyle(
          color: ElegantLightTheme.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar categorías...',
          hintStyle: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 20,
            ),
          ),
          suffixIcon: controller.isSearchMode
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: ElegantLightTheme.textSecondary,
                  ),
                  onPressed: controller.clearFilters,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickToolsSection() {
    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.build,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Herramientas Rápidas',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildQuickToolButton(
                'Nueva Categoría',
                Icons.add_circle,
                ElegantLightTheme.successGradient,
                controller.goToCreateCategory,
              ),
              const SizedBox(height: 8),
              _buildQuickToolButton(
                'Vista de Árbol',
                Icons.account_tree,
                ElegantLightTheme.infoGradient,
                () => Get.toNamed('/categories/tree'),
              ),
              const SizedBox(height: 8),
              _buildQuickToolButton(
                'Exportar Datos',
                Icons.download,
                ElegantLightTheme.warningGradient,
                () => _showExportDialog(Get.context!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToolButton(
    String title,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.colors.first.withValues(alpha: 0.1),
            gradient.colors.last.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gradient.colors.first.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: gradient.colors.first,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: gradient.colors.first.withValues(alpha: 0.5),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticFilterSection() {
    return _buildFilterWidgetWithoutHeader();
  }

  Widget _buildFilterWidgetWithoutHeader() {
    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de Filtros Avanzados sin contenedor
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filtros Avanzados',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Botón limpiar con ícono de escobita
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.errorGradient, // Cambiado a rojo
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.errorGradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: controller.clearFilters,
                    borderRadius: BorderRadius.circular(8),
                    child: const Icon(
                      Icons.cleaning_services, // Ícono de escobita
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Filtros con diseño elegante
          _buildStatusFilterCard(),
          const SizedBox(height: 16),
          _buildParentFilterCard(),
          const SizedBox(height: 16),
          _buildSortingCard(),
          const SizedBox(height: 16),
          _buildQuickFiltersCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusFilterCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ElegantLightTheme.successGradient.colors.first.withValues(alpha: 0.1),
                  ElegantLightTheme.successGradient.colors.last.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.successGradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.toggle_on, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  'Estado',
                  style: TextStyle(
                    color: ElegantLightTheme.successGradient.colors.first,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Contenido de la card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              return Column(
                children: [
                  _buildStatusOption(
                    Get.context!,
                    'Todas',
                    null,
                    controller.currentStatus == null,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusOption(
                    Get.context!,
                    'Activas',
                    CategoryStatus.active,
                    controller.currentStatus == CategoryStatus.active,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusOption(
                    Get.context!,
                    'Inactivas',
                    CategoryStatus.inactive,
                    controller.currentStatus == CategoryStatus.inactive,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildParentFilterCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.1),
                  ElegantLightTheme.infoGradient.colors.last.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.account_tree, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  'Jerarquía',
                  style: TextStyle(
                    color: ElegantLightTheme.infoGradient.colors.first,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Contenido de la card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              return Column(
                children: [
                  _buildHierarchyOption(
                    Get.context!,
                    'Todas las categorías',
                    null,
                    controller.selectedParentId == null,
                  ),
                  const SizedBox(height: 8),
                  _buildHierarchyOption(
                    Get.context!,
                    'Solo categorías padre',
                    'parents_only',
                    controller.selectedParentId == 'parents_only',
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSortingCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.1),
                  ElegantLightTheme.warningGradient.colors.last.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.warningGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.sort, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ordenar por',
                  style: TextStyle(
                    color: ElegantLightTheme.warningGradient.colors.first,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Contenido de la card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              return Column(
                children: [
                  _buildSortOption(
                    Get.context!,
                    'Orden personalizado',
                    'sortOrder',
                    'ASC',
                    controller.sortBy == 'sortOrder' &&
                        controller.sortOrder == 'ASC',
                  ),
                  const SizedBox(height: 8),
                  _buildSortOption(
                    Get.context!,
                    'Nombre (A-Z)',
                    'name',
                    'ASC',
                    controller.sortBy == 'name' && controller.sortOrder == 'ASC',
                  ),
                  const SizedBox(height: 8),
                  _buildSortOption(
                    Get.context!,
                    'Nombre (Z-A)',
                    'name',
                    'DESC',
                    controller.sortBy == 'name' && controller.sortOrder == 'DESC',
                  ),
                  const SizedBox(height: 8),
                  _buildSortOption(
                    Get.context!,
                    'Más recientes',
                    'createdAt',
                    'DESC',
                    controller.sortBy == 'createdAt' &&
                        controller.sortOrder == 'DESC',
                  ),
                  const SizedBox(height: 8),
                  _buildSortOption(
                    Get.context!,
                    'Más antiguos',
                    'createdAt',
                    'ASC',
                    controller.sortBy == 'createdAt' &&
                        controller.sortOrder == 'ASC',
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFiltersCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ElegantLightTheme.primaryGradient.colors.first.withValues(alpha: 0.1),
                  ElegantLightTheme.primaryGradient.colors.last.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.primaryGradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  'Filtros Rápidos',
                  style: TextStyle(
                    color: ElegantLightTheme.primaryGradient.colors.first,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Contenido de la card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickFilterChip(
                  Get.context!,
                  'Con productos',
                  Icons.inventory,
                  ElegantLightTheme.successGradient,
                  () {
                    Get.snackbar('Info', 'Filtro pendiente de implementar');
                  },
                ),
                _buildQuickFilterChip(
                  Get.context!,
                  'Sin productos',
                  Icons.inventory_2_outlined,
                  ElegantLightTheme.errorGradient,
                  () {
                    Get.snackbar('Info', 'Filtro pendiente de implementar');
                  },
                ),
                _buildQuickFilterChip(
                  Get.context!,
                  'Con subcategorías',
                  Icons.account_tree,
                  ElegantLightTheme.infoGradient,
                  () {
                    Get.snackbar('Info', 'Filtro pendiente de implementar');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods para los filtros
  Widget _buildStatusOption(
    BuildContext context,
    String label,
    CategoryStatus? status,
    bool isSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected 
          ? ElegantLightTheme.glassGradient
          : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
              : ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.applyStatusFilter(status),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? ElegantLightTheme.primaryGradient
                        : ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? ElegantLightTheme.textPrimary
                          : ElegantLightTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (status != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: status == CategoryStatus.active
                          ? ElegantLightTheme.successGradient
                          : ElegantLightTheme.warningGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      status == CategoryStatus.active
                          ? Icons.check_circle
                          : Icons.pause_circle,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHierarchyOption(
    BuildContext context,
    String label,
    String? parentId,
    bool isSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected 
          ? ElegantLightTheme.glassGradient
          : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.3)
              : ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.applyParentFilter(parentId),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? ElegantLightTheme.infoGradient
                        : ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    parentId == 'parents_only' ? Icons.folder : Icons.folder_open,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? ElegantLightTheme.textPrimary
                          : ElegantLightTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
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
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String label,
    String sortBy,
    String sortOrder,
    bool isSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected 
          ? ElegantLightTheme.glassGradient
          : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.3)
              : ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.changeSorting(sortBy, sortOrder),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? ElegantLightTheme.warningGradient
                        : ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    sortOrder == 'ASC' ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? ElegantLightTheme.textPrimary
                          : ElegantLightTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sortOrder == 'ASC' ? 'A-Z' : 'Z-A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(
    BuildContext context,
    String label,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return Container(
      width: 175,
      height: 40,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        border: Border(
          bottom: BorderSide(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final total = controller.totalItems;
              final current = controller.categories.length;

              return Text(
                'Mostrando $current de $total categorías',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              );
            }),
          ),
          _buildFuturisticButton(
            'Nueva Categoría',
            Icons.add,
            ElegantLightTheme.successGradient,
            controller.goToCreateCategory,
          ),
          const SizedBox(width: 12),
          _buildFuturisticButton(
            'Vista de Árbol',
            Icons.account_tree,
            ElegantLightTheme.infoGradient,
            () => Get.toNamed('/categories/tree'),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticButton(
    String text,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
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

  Widget _buildFuturisticCategoriesList(BuildContext context) {
    return Obx(() {
      final categories = controller.isSearchMode
          ? controller.searchResults
          : controller.categories;

      if (categories.isEmpty && !controller.isLoading) {
        return _buildFuturisticEmptyState(context);
      }

      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: RefreshIndicator(
          onRefresh: controller.refreshCategories,
          backgroundColor: ElegantLightTheme.backgroundColor,
          color: ElegantLightTheme.primaryBlue,
          child: ListView.builder(
            controller: controller.scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length + (controller.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= categories.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final category = categories[index];
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FuturisticCategoryCard(
                          category: category,
                          onTap: () => controller.showCategoryDetails(category.id),
                          onEdit: () => controller.goToEditCategory(category.id),
                          onDelete: () => controller.confirmDelete(category),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildFuturisticEmptyState(BuildContext context) {
    return Center(
      child: FuturisticContainer(
        margin: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.infoGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(
                Icons.category_outlined,
                color: Colors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              controller.isSearchMode
                  ? 'No se encontraron categorías'
                  : 'No hay categorías creadas',
              style: const TextStyle(
                fontSize: 20,
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              controller.isSearchMode
                  ? 'Intenta con otros términos de búsqueda'
                  : 'Crea tu primera categoría para comenzar',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!controller.isSearchMode)
              _buildFuturisticButton(
                'Crear Primera Categoría',
                Icons.add,
                ElegantLightTheme.successGradient,
                controller.goToCreateCategory,
              )
            else
              _buildFuturisticButton(
                'Limpiar Búsqueda',
                Icons.clear,
                ElegantLightTheme.warningGradient,
                controller.clearFilters,
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFuturisticFloatingActionButton(BuildContext context) {
    if (context.isMobile) {
      return Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            ...ElegantLightTheme.glowShadow,
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: controller.goToCreateCategory,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      );
    }
    return null;
  }
}

// ==================== FUTURISTIC CONTAINER ====================

class FuturisticContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final bool hasGlow;

  const FuturisticContainer({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          ...ElegantLightTheme.elevatedShadow,
          if (hasGlow)
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: child,
    );
  }
}

// ==================== FUTURISTIC CATEGORY CARD ====================

class FuturisticCategoryCard extends StatefulWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FuturisticCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<FuturisticCategoryCard> createState() => _FuturisticCategoryCardState();
}

class _FuturisticCategoryCardState extends State<FuturisticCategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: ElegantLightTheme.normalAnimation,
        decoration: BoxDecoration(
          gradient: _isHovered
              ? LinearGradient(
                  colors: [
                    ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
                    ElegantLightTheme.primaryBlue.withValues(alpha: 0.02),
                  ],
                )
              : ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
                : ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Ícono de categoría
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: widget.category.isActive
                          ? ElegantLightTheme.successGradient
                          : ElegantLightTheme.warningGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.category.isActive
                                  ? ElegantLightTheme.successGradient.colors.first
                                  : ElegantLightTheme.warningGradient.colors.first)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.category,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Información de la categoría
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.name,
                          style: const TextStyle(
                            color: ElegantLightTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (widget.category.description?.isNotEmpty == true)
                          Text(
                            widget.category.description!,
                            style: TextStyle(
                              color: ElegantLightTheme.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (widget.category.isActive
                                        ? ElegantLightTheme.successGradient.colors.first
                                        : ElegantLightTheme.warningGradient.colors.first)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.category.status.name.toUpperCase(),
                                style: TextStyle(
                                  color: widget.category.isActive
                                      ? ElegantLightTheme.successGradient.colors.first
                                      : ElegantLightTheme.warningGradient.colors.first,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Acciones
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: ElegantLightTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: widget.onEdit,
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: ElegantLightTheme.errorGradient.colors.first,
                          size: 20,
                        ),
                        onPressed: widget.onDelete,
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== FUTURISTIC PARTICLES PAINTER ====================

class FuturisticParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ElegantLightTheme.textSecondary.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Dibujar partículas flotantes en patrón diagonal
    for (int i = 0; i < 30; i++) {
      final x = (i * 80.0 + 40) % size.width;
      final y = (i * 60.0 + 30) % size.height;
      final radius = (i % 3) + 1.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Líneas conectoras sutiles
    final linePaint = Paint()
      ..color = ElegantLightTheme.primaryBlue.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    for (int i = 0; i < 10; i++) {
      final startX = (i * 120.0) % size.width;
      final startY = (i * 80.0) % size.height;
      final endX = ((i + 1) * 120.0) % size.width;
      final endY = ((i + 1) * 80.0) % size.height;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
