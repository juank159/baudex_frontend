// lib/features/inventory/presentation/screens/warehouses_screen.dart
import 'package:baudex_desktop/features/inventory/domain/entities/warehouse_with_stats.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/spectacular_floating_action_button.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/warehouses_controller.dart';
import '../widgets/warehouse_card_widget.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  WarehousesController get controller => Get.find<WarehousesController>();

  @override
  void initState() {
    super.initState();
    // Asegurar que el controlador esté disponible
    try {
      Get.find<WarehousesController>();
    } catch (e) {
      // Si no está disponible, navegar de vuelta
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final warehousesController = Get.find<WarehousesController>();
      
      return Scaffold(
        backgroundColor: ElegantLightTheme.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Gestión de Almacenes',
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
          actions: _buildAppBarActions(context),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
            tooltip: 'Volver',
          ),
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
                stops: [0.0, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: ElegantLightTheme.primaryBlue.withOpacity(0.5),
        ),
        floatingActionButton: LayoutBuilder(
          builder: (context, constraints) {
            // Solo mostrar FAB en móvil y tablet, no en desktop
            final isDesktop = constraints.maxWidth >= 1200;
            if (isDesktop) return const SizedBox.shrink();
            
            return SpectacularFloatingActionButton(
              onPressed: warehousesController.goToCreateWarehouse,
              icon: Icons.warehouse,
              text: 'Nuevo Almacén',
              showText: false, // En móvil/tablet solo icono
            );
          },
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              
              // Definir breakpoints para diseño responsive
              // final isDesktop = screenWidth >= 1200;
              // final isTablet = screenWidth >= 600 && screenWidth < 1200;
              
              return Container(
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
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // Barra de búsqueda responsiva
                    SliverToBoxAdapter(
                      child: _buildResponsiveSearchBar(screenWidth),
                    ),


                    // Contenido principal responsivo
                    SliverFillRemaining(
                      child: _buildResponsiveContent(screenWidth),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      // Si el controlador no está disponible, mostrar pantalla de error
      return _buildControllerErrorWidget(context);
    }
  }

  Widget _buildResponsiveSearchBar(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final padding = isDesktop ? 32.0 : isTablet ? 24.0 : 16.0;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: isDesktop ? 16.0 : 12.0,
      ),
      padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantLightTheme.textSecondary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                onChanged: (value) {
                  controller.updateSearchQuery(value);
                },
                style: const TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar almacenes por nombre, código...',
                  hintStyle: TextStyle(
                    color: ElegantLightTheme.textSecondary.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: ElegantLightTheme.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveContent(double screenWidth) {
    return _buildResponsiveWarehousesList(screenWidth);
  }

  Widget _buildResponsiveWarehousesList(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final padding = isDesktop ? 32.0 : isTablet ? 24.0 : 16.0;

    return GetX<WarehousesController>(
      builder: (controller) {
        if (controller.isLoading && controller.warehouses.isEmpty) {
          return const Center(child: LoadingWidget());
        }

        if (controller.error.isNotEmpty && controller.warehouses.isEmpty) {
          return _buildErrorState();
        }

        if (controller.warehouses.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshWarehouses,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header con información de resultados
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: _buildResultsHeader(),
                ),
              ),

              // Lista de almacenes - Layout responsivo
              if (isDesktop)
                // Vista de grilla para desktop - mejor diseño responsive
                SliverPadding(
                  padding: EdgeInsets.all(padding),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 600, // Máximo ancho por card
                      mainAxisExtent: 250, // Altura ajustada para cards con descripción y dirección
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final warehouse = controller.warehouses[index];
                        return _buildAnimatedCard(warehouse, index);
                      },
                      childCount: controller.warehouses.length,
                    ),
                  ),
                )
              else
                // Vista de lista para tablet y móvil
                SliverPadding(
                  padding: EdgeInsets.all(padding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final warehouse = controller.warehouses[index];
                        return _buildAnimatedCard(warehouse, index);
                      },
                      childCount: controller.warehouses.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Obx(
              () => Text(
                '${controller.warehouses.length} almacén${controller.warehouses.length != 1 ? 'es' : ''} encontrado${controller.warehouses.length != 1 ? 's' : ''}',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.sort, color: Colors.white),
                  onPressed: _showSortOptions,
                  tooltip: 'Ordenar',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ElegantLightTheme.neuomorphicShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.warehouse_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.isNotEmpty
                    ? 'No se encontraron almacenes'
                    : 'No hay almacenes registrados',
                style: Get.textTheme.titleMedium?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                controller.searchQuery.isNotEmpty
                    ? 'Intenta con otros términos de búsqueda'
                    : 'Comienza creando tu primer almacén para gestionar el inventario',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: ElegantLightTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (controller.searchQuery.isNotEmpty)
                _buildElegantButton(
                  text: 'Limpiar búsqueda',
                  icon: Icons.clear,
                  onPressed: () {
                    controller.clearSearch();
                  },
                  gradient: ElegantLightTheme.warningGradient,
                )
              else
                _buildElegantButton(
                  text: 'Crear Almacén',
                  icon: Icons.add,
                  onPressed: controller.goToCreateWarehouse,
                  gradient: ElegantLightTheme.primaryGradient,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ElegantLightTheme.neuomorphicShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Error al cargar almacenes',
              style: Get.textTheme.titleMedium?.copyWith(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
              ),
              child: Obx(
                () => Text(
                  controller.error,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: ElegantLightTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            _buildElegantButton(
              text: 'Reintentar',
              icon: Icons.refresh,
              onPressed: controller.refreshWarehouses,
              gradient: ElegantLightTheme.primaryGradient,
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  child: const Icon(Icons.sort, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ordenar almacenes por',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: ElegantLightTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildSortOption('name', 'Nombre'),
            _buildSortOption('code', 'Código'),
            _buildSortOption('createdAt', 'Fecha de creación'),
            _buildSortOption('isActive', 'Estado'),
            const SizedBox(height: AppDimensions.paddingMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String field, String label) {
    return Obx(
      () => ListTile(
        title: Text(
          label,
          style: TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontWeight: controller.sortBy == field
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        trailing: controller.sortBy == field
            ? Icon(
                controller.sortOrder == 'asc'
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: ElegantLightTheme.primaryBlue,
              )
            : null,
        selected: controller.sortBy == field,
        onTap: () {
          controller.setSortBy(field);
          Get.back();
        },
      ),
    );
  }

  Widget _buildAnimatedCard(WarehouseWithStats warehouse, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          ...ElegantLightTheme.neuomorphicShadow,
        ],
      ),
      child: WarehouseCardWidget(
        warehouseWithStats: warehouse,
        onTap: () => controller.goToWarehouseDetail(warehouse.id),
        onEdit: () => controller.goToEditWarehouse(warehouse.id),
        onDelete: () => controller.deleteWarehouse(warehouse.id),
      ),
    );
  }

  Widget _buildElegantButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required LinearGradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      // Botón de filtros principales
      Obx(() {
        final hasActiveFilters = controller.hasActiveFilters;
        return Stack(
          children: [
            IconButton(
              icon: Icon(hasActiveFilters ? Icons.filter_list_off : Icons.filter_list),
              onPressed: () => _showFiltersDialog(context),
              tooltip: hasActiveFilters ? 'Filtros activos - Toca para modificar' : 'Filtros',
            ),
            if (hasActiveFilters)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
      
      // Botón de actualizar
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: controller.refreshWarehouses,
        tooltip: 'Actualizar',
      ),
      
      // Botón de exportar
      IconButton(
        icon: const Icon(Icons.download),
        onPressed: controller.hasWarehouses ? () => _showExportDialog(context) : null,
        tooltip: 'Exportar',
      ),
      
      // Botón elegante para crear (desktop)
      LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = MediaQuery.of(context).size.width >= 1200;
          if (!isDesktop) return const SizedBox.shrink();
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _buildDesktopCreateButton(),
          );
        },
      ),
      
      const SizedBox(width: AppDimensions.paddingSmall),
    ];
  }

  Widget _buildDesktopCreateButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: controller.goToCreateWarehouse,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nuevo Almacén',
                  style: TextStyle(
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

  // ==================== FILTER DIALOGS ====================

  /// Mostrar diálogo de filtros principales
  void _showFiltersDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: isMobile ? screenWidth * 0.9 : isTablet ? 450 : 420,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.filter_list, color: Colors.white, size: isMobile ? 16 : 18),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Filtros Avanzados',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ElegantLightTheme.textPrimary,
                        fontSize: isMobile ? 14 : 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close, size: isMobile ? 20 : 24),
                    padding: EdgeInsets.all(isMobile ? 4 : 8),
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 32 : 40,
                      minHeight: isMobile ? 32 : 40,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filtro de estado
                      Text(
                        'Filtrar por estado:',
                        style: Get.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textPrimary,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      
                      Obx(() => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16, 
                          vertical: isMobile ? 6 : 8
                        ),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.glassGradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ElegantLightTheme.textSecondary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonFormField<bool?>(
                          value: controller.selectedStatus,
                          onChanged: controller.updateStatusFilter,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: ElegantLightTheme.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          items: [
                            DropdownMenuItem<bool?>(
                              value: null,
                              child: Text(
                                'Todos los almacenes',
                                style: TextStyle(fontSize: isMobile ? 12 : 14),
                              ),
                            ),
                            DropdownMenuItem<bool?>(
                              value: true,
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: isMobile ? 14 : 16),
                                  SizedBox(width: isMobile ? 6 : 8),
                                  Text(
                                    'Solo activos',
                                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem<bool?>(
                              value: false,
                              child: Row(
                                children: [
                                  Icon(Icons.cancel, color: Colors.red, size: isMobile ? 14 : 16),
                                  SizedBox(width: isMobile ? 6 : 8),
                                  Text(
                                    'Solo inactivos',
                                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                      
                      SizedBox(height: isMobile ? 16 : 20),
                      
                      // Filtros avanzados
                      Text(
                        'Filtros avanzados:',
                        style: Get.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textPrimary,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      
                      // Filtro por descripción
                      Obx(() => Container(
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.glassGradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: controller.filterWithDescription
                                ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                                : ElegantLightTheme.textSecondary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            'Solo con descripción',
                            style: TextStyle(fontSize: isMobile ? 12 : 14),
                          ),
                          subtitle: Text(
                            'Almacenes que tienen descripción definida',
                            style: TextStyle(fontSize: isMobile ? 10 : 12),
                          ),
                          value: controller.filterWithDescription,
                          onChanged: controller.toggleDescriptionFilter,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12, 
                            vertical: isMobile ? 2 : 4
                          ),
                          dense: isMobile,
                        ),
                      )),
                      
                      SizedBox(height: isMobile ? 8 : 12),
                      
                      // Filtro por dirección
                      Obx(() => Container(
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.glassGradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: controller.filterWithAddress
                                ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                                : ElegantLightTheme.textSecondary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            'Solo con dirección',
                            style: TextStyle(fontSize: isMobile ? 12 : 14),
                          ),
                          subtitle: Text(
                            'Almacenes que tienen dirección definida',
                            style: TextStyle(fontSize: isMobile ? 10 : 12),
                          ),
                          value: controller.filterWithAddress,
                          onChanged: controller.toggleAddressFilter,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12, 
                            vertical: isMobile ? 2 : 4
                          ),
                          dense: isMobile,
                        ),
                      )),
                      
                      SizedBox(height: isMobile ? 8 : 12),
                      
                      // Filtro por recientes
                      Obx(() => Container(
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.glassGradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: controller.filterRecent
                                ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                                : ElegantLightTheme.textSecondary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            'Almacenes recientes',
                            style: TextStyle(fontSize: isMobile ? 12 : 14),
                          ),
                          subtitle: Text(
                            'Creados en los últimos 30 días',
                            style: TextStyle(fontSize: isMobile ? 10 : 12),
                          ),
                          value: controller.filterRecent,
                          onChanged: controller.toggleRecentFilter,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 12, 
                            vertical: isMobile ? 2 : 4
                          ),
                          dense: isMobile,
                        ),
                      )),
                      
                      SizedBox(height: isMobile ? 16 : 20),
                      
                      // Filtro por rango de fechas
                      Text(
                        'Filtrar por fecha de creación:',
                        style: Get.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 12 : 14,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      InkWell(
                        onTap: () => _showDateRangeFilter(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.glassGradient,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: controller.hasDateFilter()
                                  ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                                  : ElegantLightTheme.textSecondary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.date_range, color: ElegantLightTheme.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Obx(() => Text(
                                  controller.getDateRangeText(),
                                  style: Get.textTheme.bodyMedium?.copyWith(
                                    color: ElegantLightTheme.textPrimary,
                                  ),
                                )),
                              ),
                              if (controller.hasDateFilter()) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: controller.clearDateFilter,
                                  child: Icon(
                                    Icons.clear,
                                    size: 16,
                                    color: ElegantLightTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.glassGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ElegantLightTheme.textSecondary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            controller.clearAllFilters();
                            Get.back();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 10 : 12,
                              horizontal: isMobile ? 8 : 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.clear, size: isMobile ? 16 : 18),
                                SizedBox(width: isMobile ? 4 : 6),
                                Flexible(
                                  child: Text(
                                    isMobile ? 'Limpiar' : 'Limpiar filtros',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 11 : isTablet ? 12 : 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 6 : 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Get.back(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 10 : 12,
                              horizontal: isMobile ? 8 : 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, color: Colors.white, size: isMobile ? 16 : 18),
                                SizedBox(width: isMobile ? 4 : 6),
                                Text(
                                  isMobile ? 'Aplicar' : 'Aplicar filtros',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostrar diálogo de ordenamiento
  /* UNUSED METHOD - Commented out to avoid warning
  void _showSortDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sort, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ordenar almacenes',
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Opciones de ordenamiento
              Text(
                'Ordenar por:',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildSortOption('name', 'Nombre del almacén'),
              _buildSortOption('code', 'Código del almacén'),
              _buildSortOption('createdAt', 'Fecha de creación'),
              _buildSortOption('isActive', 'Estado (activo/inactivo)'),
              
              const SizedBox(height: 20),
              
              // Dirección del ordenamiento
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.glassGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ElegantLightTheme.textSecondary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dirección:',
                      style: Get.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => InkWell(
                            onTap: () => controller.updateSort(controller.sortBy, 'asc'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                gradient: controller.sortOrder == 'asc'
                                    ? ElegantLightTheme.primaryGradient
                                    : ElegantLightTheme.glassGradient,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: controller.sortOrder == 'asc'
                                      ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                                      : ElegantLightTheme.textSecondary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    color: controller.sortOrder == 'asc'
                                        ? Colors.white
                                        : ElegantLightTheme.textSecondary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'A-Z',
                                    style: TextStyle(
                                      color: controller.sortOrder == 'asc'
                                          ? Colors.white
                                          : ElegantLightTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Obx(() => InkWell(
                            onTap: () => controller.updateSort(controller.sortBy, 'desc'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                gradient: controller.sortOrder == 'desc'
                                    ? ElegantLightTheme.primaryGradient
                                    : ElegantLightTheme.glassGradient,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: controller.sortOrder == 'desc'
                                      ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                                      : ElegantLightTheme.textSecondary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    color: controller.sortOrder == 'desc'
                                        ? Colors.white
                                        : ElegantLightTheme.textSecondary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Z-A',
                                    style: TextStyle(
                                      color: controller.sortOrder == 'desc'
                                          ? Colors.white
                                          : ElegantLightTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Botón aplicar
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Get.back(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Aplicar ordenamiento',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  */

  /// Mostrar diálogo de exportación
  void _showExportDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    // final isTablet = screenWidth >= 600 && screenWidth < 1200;
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Exportar almacenes',
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Información de exportación
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient.colors.first.withOpacity(0.1) != null
                      ? LinearGradient(
                          colors: [
                            ElegantLightTheme.infoGradient.colors.first.withOpacity(0.1),
                            ElegantLightTheme.infoGradient.colors.last.withOpacity(0.05),
                          ],
                        )
                      : ElegantLightTheme.glassGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ElegantLightTheme.infoGradient.colors.first.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: ElegantLightTheme.infoGradient.colors.first,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Información de exportación',
                          style: Get.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ElegantLightTheme.infoGradient.colors.first,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final stats = controller.getWarehousesStats();
                      return Text(
                        'Se exportarán ${stats['filtered']} almacenes de ${stats['total']} totales.\n'
                        'Los datos incluirán: nombre, código, descripción, dirección, estado y fechas.',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: ElegantLightTheme.textPrimary.withOpacity(0.8),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Opciones de formato
              Text(
                'Selecciona el formato de exportación:',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botones de formato - Primera fila
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.successGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Get.back();
                            controller.exportToExcel();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 10 : 12,
                              horizontal: isMobile ? 8 : 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.table_chart, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Excel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ElegantLightTheme.infoGradient.colors.first.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Get.back();
                            controller.exportToCsv();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 10 : 12,
                              horizontal: isMobile ? 8 : 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.description, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'CSV',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Botones de formato - Segunda fila
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.errorGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Get.back();
                            controller.exportToPdf();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 10 : 12,
                              horizontal: isMobile ? 8 : 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'PDF',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade700,
                            Colors.grey.shade800,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Get.back();
                            controller.printWarehouses();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 10 : 12,
                              horizontal: isMobile ? 8 : 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.print, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Imprimir',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostrar selector de rango de fechas
  void _showDateRangeFilter(BuildContext context) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: controller.hasDateFilter() 
          ? DateTimeRange(
              start: controller.dateFrom!,
              end: controller.dateTo!,
            )
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar rango de fechas',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Guardar',
      locale: const Locale('es', 'ES'),
    );

    if (pickedRange != null) {
      controller.setDateFilter(pickedRange.start, pickedRange.end);
    }
  }

  Widget _buildControllerErrorWidget(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Almacenes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: 'Volver',
        ),
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
              stops: [0.0, 0.7, 1.0],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ElegantLightTheme.neuomorphicShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.errorGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el controlador',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor, reinicia la aplicación',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _buildElegantButton(
                text: 'Volver al inicio',
                icon: Icons.home,
                onPressed: () => Get.back(),
                gradient: ElegantLightTheme.primaryGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }
}