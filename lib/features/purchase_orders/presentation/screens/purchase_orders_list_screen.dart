// lib/features/purchase_orders/presentation/screens/purchase_orders_list_screen.dart
import 'package:baudex_desktop/app/ui/layouts/main_layout.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/entities/purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/spectacular_floating_action_button.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/purchase_orders_controller.dart';
import '../widgets/purchase_order_card_widget.dart';
import '../widgets/purchase_order_filter_widget.dart';
import '../widgets/purchase_order_stats_widget.dart';

class PurchaseOrdersListScreen extends StatefulWidget {
  const PurchaseOrdersListScreen({super.key});

  @override
  State<PurchaseOrdersListScreen> createState() =>
      _PurchaseOrdersListScreenState();
}

class _PurchaseOrdersListScreenState extends State<PurchaseOrdersListScreen> {
  // Todas las animaciones eliminadas para mejor rendimiento

  PurchaseOrdersController get controller =>
      Get.find<PurchaseOrdersController>();

  @override
  void initState() {
    super.initState();

    // Sin animaciones molestas
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Órdenes de Compra',
      actions: _buildAppBarActions(context),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          // Solo mostrar FAB en móvil y tablet, no en desktop
          final isDesktop = constraints.maxWidth >= 1200;
          if (isDesktop) return const SizedBox.shrink();
          
          return SpectacularFloatingActionButton(
            onPressed: controller.goToCreatePurchaseOrder,
            icon: Icons.add,
            text: 'Nueva Orden',
            showText: false, // En móvil/tablet solo icono
          );
        },
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            
            // Definir breakpoints para diseño responsive
            final isDesktop = screenWidth >= 1200;
            final isTablet = screenWidth >= 600 && screenWidth < 1200;
            
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

                  // Tabs responsivos
                  SliverToBoxAdapter(
                    child: _buildResponsiveTabs(screenWidth),
                  ),

                  // Filtros colapsables
                  SliverToBoxAdapter(
                    child: Obx(
                      () => AnimatedContainer(
                        duration: ElegantLightTheme.normalAnimation,
                        height: controller.showFilters.value ? null : 0,
                        child: controller.showFilters.value
                            ? Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 32 : isTablet ? 24 : 16,
                                ),
                                child: const PurchaseOrderFilterWidget(),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // Contenido principal responsivo
                  SliverFillRemaining(
                    child: Obx(() => _buildResponsiveContent(screenWidth)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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
                controller: controller.searchController,
                onChanged: (value) {
                  controller.searchQuery.value = value;
                },
                style: const TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar órdenes de compra...',
                  hintStyle: TextStyle(
                    color: ElegantLightTheme.textSecondary.withOpacity(
                      0.6,
                    ),
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
          const SizedBox(width: AppDimensions.paddingSmall),
          Obx(() {
            final filtersInfo = controller.activeFiltersCount;
            return Container(
              decoration: BoxDecoration(
                gradient:
                    filtersInfo['count'] > 0
                        ? ElegantLightTheme.primaryGradient
                        : ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      filtersInfo['count'] > 0
                          ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                          : ElegantLightTheme.textSecondary.withOpacity(
                            0.2,
                          ),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      controller.showFilters.value
                          ? Icons.filter_list_off
                          : Icons.filter_list,
                      color:
                          filtersInfo['count'] > 0
                              ? Colors.white
                              : ElegantLightTheme.textSecondary,
                    ),
                    onPressed: controller.toggleFilters,
                    tooltip:
                        controller.showFilters.value
                            ? 'Ocultar filtros'
                            : 'Mostrar filtros',
                  ),
                  if (filtersInfo['count'] > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              ElegantLightTheme
                                  .errorGradient
                                  .colors
                                  .first,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${filtersInfo['count']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }


  Widget _buildResponsiveTabs(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final padding = isDesktop ? 32.0 : isTablet ? 24.0 : 16.0;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: isDesktop ? 12.0 : 10.0,
      ),
      height: isDesktop ? 75 : 72, // Reducir altura para evitar overflow
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 600 : double.infinity,
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _buildResponsiveTabButton(
                title: 'Lista',
                icon: Icons.list,
                index: 0,
                isSelected: controller.selectedTab.value == 0,
                screenWidth: screenWidth,
              ),
            ),
            Expanded(
              child: _buildResponsiveTabButton(
                title: 'Estadísticas',
                icon: Icons.analytics,
                index: 1,
                isSelected: controller.selectedTab.value == 1,
                screenWidth: screenWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveTabButton({
    required String title,
    required IconData icon,
    required int index,
    required bool isSelected,
    required double screenWidth,
  }) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    
    // Ajustar márgenes para evitar overflow - reducir para desktop
    final margin = isDesktop ? 6.0 : isTablet ? 6.0 : 5.0;
    final borderRadius = isDesktop ? 16.0 : 12.0;
    
    return AnimatedContainer(
      duration: ElegantLightTheme.normalAnimation,
      curve: ElegantLightTheme.smoothCurve,
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        gradient: isSelected 
            ? ElegantLightTheme.primaryGradient 
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isSelected 
            ? ElegantLightTheme.glowShadow 
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () => controller.switchTab(index),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isDesktop ? 10 : 8, // Reducir padding vertical
              horizontal: isDesktop ? 10 : 6, // Reducir padding horizontal
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Evitar overflow
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : ElegantLightTheme.textSecondary,
                  size: isDesktop ? 20 : 18, // Reducir icono en desktop
                ),
                SizedBox(height: isDesktop ? 4 : 3), // Reducir spacing
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : ElegantLightTheme.textSecondary,
                    fontSize: isDesktop ? 12 : 10, // Reducir más el texto
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveContent(double screenWidth) {
    if (controller.selectedTab.value == 0) {
      return _buildResponsivePurchaseOrdersList(screenWidth);
    } else {
      return _buildResponsiveStatsView(screenWidth);
    }
  }

  Widget _buildResponsivePurchaseOrdersList(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final padding = isDesktop ? 32.0 : isTablet ? 24.0 : 16.0;

    if (controller.isLoading.value && controller.purchaseOrders.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (controller.error.value.isNotEmpty && controller.purchaseOrders.isEmpty) {
      return _buildErrorState();
    }

    if (!controller.hasResults) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: controller.refreshPurchaseOrders,
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

          // Lista de órdenes - Layout responsivo
          if (isDesktop)
            // Vista de grilla para desktop
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 8.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == controller.displayedPurchaseOrders.length) {
                      return _buildLoadMoreButton();
                    }
                    final purchaseOrder = controller.displayedPurchaseOrders[index];
                    return _buildAnimatedCard(purchaseOrder, index);
                  },
                  childCount: controller.displayedPurchaseOrders.length + 
                            (controller.canLoadMore ? 1 : 0),
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
                    if (index == controller.displayedPurchaseOrders.length) {
                      return _buildLoadMoreButton();
                    }
                    final purchaseOrder = controller.displayedPurchaseOrders[index];
                    return _buildAnimatedCard(purchaseOrder, index);
                  },
                  childCount: controller.displayedPurchaseOrders.length + 
                            (controller.canLoadMore ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResponsiveStatsView(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final padding = isDesktop ? 32.0 : 16.0;
    
    return Obx(() {
      if (controller.stats.value == null && controller.isLoading.value) {
        return const Center(child: LoadingWidget());
      }

      if (controller.stats.value == null) {
        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 600 : double.infinity,
            ),
            margin: EdgeInsets.all(padding),
            padding: EdgeInsets.all(padding + 8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
              boxShadow: ElegantLightTheme.neuomorphicShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 24 : 20),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.warningGradient,
                    borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    size: isDesktop ? 56 : 48,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isDesktop ? 20 : 16),
                Text(
                  'No hay estadísticas disponibles',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: ElegantLightTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: isDesktop ? 20 : 16,
                  ),
                ),
                SizedBox(height: isDesktop ? 20 : 16),
                _buildElegantButton(
                  text: 'Recargar',
                  icon: Icons.refresh,
                  onPressed: controller.loadStats,
                  gradient: ElegantLightTheme.primaryGradient,
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.all(padding),
        child: PurchaseOrderStatsWidget(stats: controller.stats.value!),
      );
    });
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
                controller.resultsText,
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
              Obx(
                () => Text(
                  'Página ${controller.currentPage.value} de ${controller.totalPages.value}',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      height: 80, // Altura fija para mantener consistencia con las cards
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Obx(
          () =>
              controller.isLoadingMore.value
                  ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  )
                  : _buildElegantButton(
                    text: 'Cargar más',
                    icon: Icons.expand_more,
                    onPressed: controller.loadNextPage,
                    gradient: ElegantLightTheme.infoGradient,
                  ),
        ),
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
                  Icons.shopping_cart_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                controller.searchQuery.value.isNotEmpty
                    ? 'No se encontraron órdenes de compra'
                    : 'No hay órdenes de compra registradas',
                style: Get.textTheme.titleMedium?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                controller.searchQuery.value.isNotEmpty
                    ? 'Intenta con otros términos de búsqueda'
                    : 'Comienza creando tu primera orden de compra',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: ElegantLightTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (controller.searchQuery.value.isNotEmpty)
                _buildElegantButton(
                  text: 'Limpiar búsqueda',
                  icon: Icons.clear,
                  onPressed: () {
                    controller.searchController.clear();
                    controller.searchQuery.value = '';
                  },
                  gradient: ElegantLightTheme.warningGradient,
                )
              else
                _buildElegantButton(
                  text: 'Crear Orden de Compra',
                  icon: Icons.add,
                  onPressed: controller.goToCreatePurchaseOrder,
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
              'Error al cargar órdenes de compra',
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
                  controller.error.value,
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
              onPressed: controller.reloadPurchaseOrders,
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
                  'Ordenar por',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: ElegantLightTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildSortOption('orderDate', 'Fecha de orden'),
            _buildSortOption('expectedDeliveryDate', 'Fecha de entrega'),
            _buildSortOption('orderNumber', 'Número de orden'),
            _buildSortOption('supplierName', 'Proveedor'),
            _buildSortOption('status', 'Estado'),
            _buildSortOption('priority', 'Prioridad'),
            _buildSortOption('totalAmount', 'Valor total'),
            _buildSortOption('createdAt', 'Fecha de creación'),
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
            fontWeight:
                controller.sortBy.value == field
                    ? FontWeight.w600
                    : FontWeight.w500,
          ),
        ),
        trailing:
            controller.sortBy.value == field
                ? Icon(
                  controller.sortOrder.value == 'asc'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: ElegantLightTheme.primaryBlue,
                )
                : null,
        selected: controller.sortBy.value == field,
        onTap: () {
          controller.sortPurchaseOrders(field);
          Get.back();
        },
      ),
    );
  }

  Widget _buildAnimatedCard(PurchaseOrder purchaseOrder, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          ...ElegantLightTheme.neuomorphicShadow,
        ],
      ),
      child: PurchaseOrderCardWidget(
        purchaseOrder: purchaseOrder,
        onTap: () => controller.goToPurchaseOrderDetail(purchaseOrder.id),
        onEdit: () => controller.goToPurchaseOrderEdit(purchaseOrder.id),
        onDelete: () => controller.deletePurchaseOrder(purchaseOrder.id),
        onApprove: purchaseOrder.canApprove
            ? () => controller.approvePurchaseOrder(purchaseOrder.id)
            : null,
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
      // Botones estándar del AppBar
      IconButton(
        icon: const Icon(Icons.filter_list),
        onPressed: controller.toggleFilters,
        tooltip: 'Filtros',
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: controller.refreshPurchaseOrders,
        tooltip: 'Actualizar',
      ),
      
      // Botón elegante para desktop
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
          onTap: controller.goToCreatePurchaseOrder,
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
                  'Nueva Orden',
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

}
