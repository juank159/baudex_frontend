// lib/features/categories/presentation/screens/category_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/category_detail_controller.dart';

class CategoryDetailScreen extends GetView<CategoryDetailController> {
  const CategoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.isLoading
          ? _buildLoadingState()
          : !controller.hasCategory
              ? _buildErrorState()
              : Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: _buildFuturisticAppBar(context),
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
                    child: ResponsiveLayout(
                      mobile: _buildMobileLayout(context),
                      tablet: _buildTabletLayout(context),
                      desktop: _buildDesktopLayout(context),
                    ),
                  ),
                  floatingActionButton: _buildFloatingActionButton(context),
                ),
    );
  }

  PreferredSizeWidget _buildFuturisticAppBar(BuildContext context) {
    return AppBar(
      title: Obx(() => Text(
        controller.hasCategory ? controller.category!.name : 'Categoría',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      )),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
      ),
      actions: [
        // Editar
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
          onPressed: controller.goToEditCategory,
          tooltip: 'Editar categoría',
        ),

        // Cambiar estado
        Obx(() => IconButton(
          icon: Icon(
            controller.category?.isActive == true
                ? Icons.toggle_on
                : Icons.toggle_off,
            color: Colors.white,
            size: 24,
          ),
          onPressed: controller.showStatusDialog,
          tooltip: 'Cambiar estado',
        )),

        // Menú de opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'create_subcategory',
              child: Row(
                children: [
                  Icon(Icons.add, color: ElegantLightTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Crear Subcategoría'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: ElegantLightTheme.primaryBlue),
                  SizedBox(width: 8),
                  Text('Actualizar'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ElegantLightTheme.backgroundColor, ElegantLightTheme.cardColor],
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
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cargando detalles de categoría...',
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

  Widget _buildMobileLayout(BuildContext context) {
    return _buildDesktopLayout(context); // Use same futuristic design for mobile
  }

  Widget _buildTabletLayout(BuildContext context) {
    return _buildDesktopLayout(context); // Use same futuristic design
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 140, // Account for AppBar and padding
          ),
          child: Column(
            children: [
              // Header futurístico con información clave
              _buildFuturisticHeader(),
              const SizedBox(height: 24),

              // Tabs futurísticos
              _buildFuturisticTabs(),
              const SizedBox(height: 24),

              // Contenido del tab seleccionado
              Obx(() => _buildFuturisticTabContent()),

              // Espacio adicional al final
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }





  Widget _buildErrorState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ElegantLightTheme.backgroundColor, ElegantLightTheme.cardColor],
        ),
      ),
      child: Center(
        child: FuturisticContainer(
          margin: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.errorGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.category_outlined,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Categoría no encontrada',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La categoría que buscas no existe o ha sido eliminada',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FuturisticButton(
                text: 'Volver a Categorías',
                icon: Icons.arrow_back,
                onPressed: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    // No floating action button - actions are available in tabs
    return null;
  }

  // ==================== ACTION METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'create_subcategory':
        controller.goToCreateSubcategory();
        break;
      case 'refresh':
        controller.refreshData();
        break;
      case 'delete':
        controller.confirmDelete();
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ==================== FUTURISTIC COMPONENTS ====================

  Widget _buildFuturisticHeader() {
    return FuturisticContainer(
      hasGlow: true,
      child: Obx(() {
        final category = controller.category!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Imagen de categoría futurística
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: category.image != null 
                        ? null 
                        : ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: ElegantLightTheme.glowShadow,
                    image: category.image != null
                        ? DecorationImage(
                            image: NetworkImage(category.image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: category.image == null
                      ? const Icon(
                          Icons.category,
                          color: Colors.white,
                          size: 40,
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          color: ElegantLightTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: category.isActive
                              ? ElegantLightTheme.successGradient
                              : ElegantLightTheme.warningGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (category.isActive
                                  ? ElegantLightTheme.successGradient.colors.first
                                  : ElegantLightTheme.warningGradient.colors.first)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          category.status.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (category.description != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.glassGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.description!,
                        style: const TextStyle(
                          color: ElegantLightTheme.textSecondary,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildFuturisticTabs() {
    return Obx(() => FuturisticContainer(
      child: Row(
        children: [
          _buildTabHeader('Detalles', 0, Icons.info),
          _buildTabHeader('Subcategorías', 1, Icons.account_tree),
          _buildTabHeader('Estadísticas', 2, Icons.analytics),
          _buildTabHeader('Acciones', 3, Icons.settings),
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
          duration: ElegantLightTheme.normalAnimation,
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

  Widget _buildFuturisticTabContent() {
    switch (controller.selectedTab.value) {
      case 0:
        return _buildDetailsTab();
      case 1:
        return _buildSubcategoriesTab();
      case 2:
        return _buildStatsTab();
      case 3:
        return _buildActionsTab();
      default:
        return _buildDetailsTab();
    }
  }

  Widget _buildDetailsTab() {
    return FuturisticContainer(
      child: Obx(() {
        final category = controller.category!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Detallada',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _buildFuturisticDetailRow('Slug', category.slug, Icons.link),
            _buildFuturisticDetailRow('Orden', category.sortOrder.toString(), Icons.sort),
            _buildFuturisticDetailRow('Productos', (category.productsCount ?? 0).toString(), Icons.inventory),
            _buildFuturisticDetailRow('Nivel', category.level.toString(), Icons.layers),
            _buildFuturisticDetailRow('Creado', _formatDate(category.createdAt), Icons.calendar_today),
            _buildFuturisticDetailRow('Actualizado', _formatDate(category.updatedAt), Icons.update),
          ],
        );
      }),
    );
  }

  Widget _buildSubcategoriesTab() {
    return Obx(() {
      if (!controller.hasSubcategories) {
        return _buildEmptySubcategoriesFuturistic();
      }

      return FuturisticContainer(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 400, // Ensure minimum height to fill space
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Subcategorías',
                    style: TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  FuturisticButton(
                    text: 'Nueva',
                    icon: Icons.add,
                    onPressed: controller.goToCreateSubcategory,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Fix layout issue with proper ListView
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.subcategories.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final subcategory = controller.subcategories[index];
                  return _buildFuturisticSubcategoryCard(subcategory);
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatsTab() {
    return FuturisticContainer(
      child: Obx(() {
        final category = controller.category!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas Avanzadas',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                int crossAxisCount = screenWidth >= 800 ? 2 : 1;
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: screenWidth >= 800 ? 3.5 : 4.0, // Reduced height for better proportions
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildFuturisticStatCard(
                      'Productos Totales',
                      (category.productsCount ?? 0).toString(),
                      Icons.inventory,
                      ElegantLightTheme.infoGradient,
                    ),
                    _buildFuturisticStatCard(
                      'Subcategorías',
                      controller.subcategories.length.toString(),
                      Icons.account_tree,
                      ElegantLightTheme.successGradient,
                    ),
                    _buildFuturisticStatCard(
                      'Nivel de Profundidad',
                      category.level.toString(),
                      Icons.layers,
                      ElegantLightTheme.warningGradient,
                    ),
                    _buildFuturisticStatCard(
                      'Orden de Clasificación',
                      category.sortOrder.toString(),
                      Icons.sort,
                      ElegantLightTheme.errorGradient,
                    ),
                  ],
                );
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildActionsTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return FuturisticContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acciones Disponibles',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              _buildFuturisticActionCard(
                'Editar Categoría',
                'Modificar nombre, descripción y configuración',
                Icons.edit,
                ElegantLightTheme.infoGradient,
                controller.goToEditCategory,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Obx(() => _buildFuturisticActionCard(
                controller.category?.isActive == true ? 'Desactivar' : 'Activar',
                'Cambiar el estado de disponibilidad de la categoría',
                controller.category?.isActive == true ? Icons.toggle_off : Icons.toggle_on,
                controller.category?.isActive == true 
                    ? ElegantLightTheme.warningGradient 
                    : ElegantLightTheme.successGradient,
                controller.showStatusDialog,
              )),
              SizedBox(height: isMobile ? 12 : 16),
              _buildFuturisticActionCard(
                'Nueva Subcategoría',
                'Crear una nueva categoría hija',
                Icons.add,
                ElegantLightTheme.primaryGradient,
                controller.goToCreateSubcategory,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              _buildFuturisticActionCard(
                'Actualizar Datos',
                'Refrescar la información desde el servidor',
                Icons.refresh,
                ElegantLightTheme.glassGradient,
                controller.refreshData,
                isOutline: true,
              ),
              SizedBox(height: isMobile ? 16 : 24),
              _buildFuturisticActionCard(
                'Eliminar Categoría',
                'Eliminar permanentemente esta categoría',
                Icons.delete,
                ElegantLightTheme.errorGradient,
                controller.confirmDelete,
                isDangerous: true,
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper Widgets
  Widget _buildFuturisticDetailRow(String label, String value, IconData icon) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Determine device type
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1024;
        
        // Define sizes based on device type
        double margin = isMobile ? 6 : isTablet ? 8 : 12;
        double padding = isMobile ? 8 : isTablet ? 10 : 12;
        double borderRadius = isMobile ? 8 : isTablet ? 10 : 12;
        double iconPadding = isMobile ? 3 : isTablet ? 4 : 6;
        double iconBorderRadius = isMobile ? 3 : isTablet ? 4 : 6;
        double iconSize = isMobile ? 12 : isTablet ? 14 : 16;
        double spacing = isMobile ? 6 : isTablet ? 8 : 12;
        double labelWidth = isMobile ? 70 : isTablet ? 85 : 100;
        double labelSize = isMobile ? 9 : isTablet ? 10 : 12;
        double valueSize = isMobile ? 11 : isTablet ? 12 : 14;
        
        return Container(
          margin: EdgeInsets.only(bottom: margin),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(iconBorderRadius),
                ),
                child: Icon(
                  icon,
                  color: ElegantLightTheme.primaryBlue,
                  size: iconSize,
                ),
              ),
              SizedBox(width: spacing),
              SizedBox(
                width: labelWidth,
                child: Text(
                  '$label:',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticStatCard(
    String title,
    String value,
    IconData icon,
    LinearGradient gradient,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Determine device type
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1024;
        
        // Define sizes based on device type
        double padding = isMobile ? 10 : isTablet ? 14 : 16;
        double borderRadius = isMobile ? 10 : isTablet ? 12 : 16;
        double iconPadding = isMobile ? 6 : isTablet ? 8 : 12;
        double iconBorderRadius = isMobile ? 6 : isTablet ? 8 : 12;
        double iconSize = isMobile ? 16 : isTablet ? 20 : 24;
        double spacing = isMobile ? 10 : isTablet ? 12 : 16;
        double titleSize = isMobile ? 9 : isTablet ? 10 : 12;
        double valueSize = isMobile ? 14 : isTablet ? 17 : 20;
        double spacingText = isMobile ? 1 : isTablet ? 2 : 4;
        double blurRadius = isMobile ? 3 : isTablet ? 6 : 8;
        
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: gradient.colors.first.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(iconBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: blurRadius,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: iconSize),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: isMobile ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: spacingText),
                    Text(
                      value,
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: valueSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticActionCard(
    String title,
    String description,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onPressed, {
    bool isOutline = false,
    bool isDangerous = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Determine device type
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1024;
        
        // Define sizes based on device type
        double borderRadius = isMobile ? 10 : isTablet ? 12 : 16;
        double padding = isMobile ? 10 : isTablet ? 12 : 16;
        double iconPadding = isMobile ? 6 : isTablet ? 8 : 12;
        double iconBorderRadius = isMobile ? 6 : isTablet ? 8 : 12;
        double iconSize = isMobile ? 14 : isTablet ? 16 : 20;
        double spacing = isMobile ? 10 : isTablet ? 12 : 16;
        double titleSize = isMobile ? 12 : isTablet ? 14 : 16;
        double descriptionSize = isMobile ? 10 : isTablet ? 11 : 12;
        double arrowSize = isMobile ? 12 : isTablet ? 14 : 16;
        double spacingText = isMobile ? 1 : isTablet ? 2 : 4;
        double blurRadius = isMobile ? 3 : isTablet ? 6 : 8;
        
        return Container(
          decoration: BoxDecoration(
            gradient: isOutline ? null : ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: gradient.colors.first.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconPadding),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(iconBorderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.colors.first.withValues(alpha: 0.3),
                            blurRadius: blurRadius,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: iconSize),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isDangerous ? Colors.red : ElegantLightTheme.textPrimary,
                              fontSize: titleSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: spacingText),
                          Text(
                            description,
                            style: TextStyle(
                              color: ElegantLightTheme.textSecondary,
                              fontSize: descriptionSize,
                            ),
                            maxLines: isMobile ? 1 : isTablet ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: ElegantLightTheme.textSecondary,
                      size: arrowSize,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptySubcategoriesFuturistic() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Determine device type
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1024;
        
        // Define sizes based on device type
        double iconSize = isMobile ? 24 : isTablet ? 32 : 40;
        double iconPadding = isMobile ? 12 : isTablet ? 16 : 20;
        double borderRadius = isMobile ? 10 : isTablet ? 12 : 16;
        double titleSize = isMobile ? 14 : isTablet ? 16 : 18;
        double subtitleSize = isMobile ? 11 : isTablet ? 12 : 14;
        double spacing1 = isMobile ? 10 : isTablet ? 12 : 16;
        double spacing2 = isMobile ? 6 : isTablet ? 6 : 8;
        double spacing3 = isMobile ? 12 : isTablet ? 16 : 20;
        double minHeight = isMobile ? 200 : isTablet ? 300 : 400;
        
        return FuturisticContainer(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: minHeight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.warningGradient,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                SizedBox(height: spacing1),
                Text(
                  'No hay subcategorías',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing2),
                Text(
                  isMobile 
                    ? 'Crea la primera subcategoría'
                    : 'Crea la primera subcategoría para esta categoría',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: subtitleSize,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing3),
                FuturisticButton(
                  text: isMobile ? 'Crear' : 'Crear Subcategoría',
                  icon: Icons.add,
                  onPressed: controller.goToCreateSubcategory,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFuturisticSubcategoryCard(category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.goToSubcategory(category.id),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (category.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description!,
                        style: TextStyle(
                          color: ElegantLightTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: category.isActive
                      ? ElegantLightTheme.successGradient
                      : ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.productsCount ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
