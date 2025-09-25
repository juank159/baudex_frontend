// lib/features/inventory/presentation/screens/inventory_balance_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/inventory_balance_controller.dart';
import '../widgets/inventory_balance_card.dart';
import '../widgets/inventory_alerts_cards.dart';

class InventoryBalanceScreen extends StatefulWidget {
  const InventoryBalanceScreen({super.key});

  @override
  State<InventoryBalanceScreen> createState() => _InventoryBalanceScreenState();
}

class _InventoryBalanceScreenState extends State<InventoryBalanceScreen> {
  InventoryBalanceController get controller => Get.find<InventoryBalanceController>();

  @override
  Widget build(BuildContext context) {
    // Determinar si viene de un almacén específico o desde centro general
    final args = Get.arguments as Map<String, dynamic>?;
    final isFromWarehouse = args != null && args.containsKey('warehouseId');
    final warehouseName = args?['warehouseName'] ?? 'Inventario General';
    
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          isFromWarehouse ? 'Inventario - $warehouseName' : 'Balances de Inventario',
          style: const TextStyle(
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
          onPressed: () {
            // Limpiar historial y volver atrás para refrescar datos
            Get.back();
            // Forzar limpieza del controlador para próxima navegación
            if (Get.isRegistered<InventoryBalanceController>()) {
              Get.delete<InventoryBalanceController>();
            }
          },
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isDesktop = screenWidth >= 1200;
            final isTablet = screenWidth >= 600 && screenWidth < 1200;
            
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ElegantLightTheme.backgroundColor,
                    ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
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
  }

  Widget _buildResponsiveContent(double screenWidth) {
    return Obx(() {
        if (controller.isLoading.value && !controller.hasBalances) {
          return const Center(child: LoadingWidget());
        }

        if (controller.hasError && !controller.hasBalances) {
          return _buildErrorState(screenWidth);
        }

        return _buildInventoryContent(screenWidth);
    });
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
      child: Column(
        children: [
          // Barra de búsqueda
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: controller.searchTextController,
                    onChanged: controller.updateSearchQuery,
                    style: const TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar productos en inventario...',
                      hintStyle: TextStyle(
                        color: ElegantLightTheme.textSecondary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        Icons.inventory,
                        color: ElegantLightTheme.textSecondary,
                      ),
                      suffixIcon: _buildSearchSuffixIcon(),
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
              _buildSortButton(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Alert cards
          const InventoryAlertsCards(),
          
          const SizedBox(height: 8),
          
          // Summary text
          _buildSummaryHeader(),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          gradient: controller.hasCustomSort 
              ? ElegantLightTheme.primaryGradient
              : ElegantLightTheme.glassGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.hasCustomSort 
                ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
                : ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'name_asc':
                controller.updateSort('productName', 'asc');
                break;
              case 'name_desc':
                controller.updateSort('productName', 'desc');
                break;
              case 'stock_asc':
                controller.updateSort('totalQuantity', 'asc');
                break;
              case 'stock_desc':
                controller.updateSort('totalQuantity', 'desc');
                break;
              case 'value_asc':
                controller.updateSort('totalValue', 'asc');
                break;
              case 'value_desc':
                controller.updateSort('totalValue', 'desc');
                break;
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  controller.sortOrder.value == 'asc' 
                      ? Icons.arrow_upward 
                      : Icons.arrow_downward,
                  color: controller.hasCustomSort 
                      ? Colors.white 
                      : ElegantLightTheme.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  controller.getCurrentSortLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: controller.hasCustomSort 
                        ? Colors.white 
                        : ElegantLightTheme.textSecondary,
                    fontWeight: controller.hasCustomSort 
                        ? FontWeight.w600 
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'name_asc',
              child: _buildSortMenuItem('Nombre A-Z', 'productName', 'asc'),
            ),
            PopupMenuItem(
              value: 'name_desc',
              child: _buildSortMenuItem('Nombre Z-A', 'productName', 'desc'),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'stock_desc',
              child: _buildSortMenuItem('Stock: Mayor a Menor', 'totalQuantity', 'desc'),
            ),
            PopupMenuItem(
              value: 'stock_asc',
              child: _buildSortMenuItem('Stock: Menor a Mayor', 'totalQuantity', 'asc'),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'value_desc',
              child: _buildSortMenuItem('Valor: Mayor a Menor', 'totalValue', 'desc'),
            ),
            PopupMenuItem(
              value: 'value_asc',
              child: _buildSortMenuItem('Valor: Menor a Mayor', 'totalValue', 'asc'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
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
              Icons.inventory,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryText(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuffixIcon() {
    return Obx(() => controller.searchQuery.value.isNotEmpty
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!controller.isLoading.value)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.inventoryBalances.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            IconButton(
              onPressed: controller.clearSearch,
              icon: const Icon(Icons.clear, size: 18),
            ),
          ],
        )
      : const SizedBox.shrink());
  }

  Widget _buildSummaryText() {
    return Obx(() => Text(
      controller.summaryText,
      style: Get.textTheme.bodyMedium?.copyWith(
        color: ElegantLightTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ));
  }

  Widget _buildInventoryContent(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final padding = isDesktop ? 32.0 : isTablet ? 24.0 : 16.0;

    return Obx(() {
      if (!controller.hasBalances && !controller.isLoading.value) {
        return _buildEmptyState(screenWidth);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshBalances,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= controller.inventoryBalances.length) {
                      if (controller.isLoadingMore.value) {
                        return _buildLoadMoreIndicator();
                      }
                      return const SizedBox.shrink();
                    }

                    final balance = controller.inventoryBalances[index];
                    return _buildAnimatedCard(balance, index);
                  },
                  childCount: controller.inventoryBalances.length + 
                            (controller.isLoadingMore.value ? 1 : 0),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAnimatedCard(dynamic balance, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: InventoryBalanceCard(
        balance: balance,
        onKardexTap: () => controller.goToProductKardex(balance.productId),
        onBatchesTap: () => controller.goToProductBatches(balance.productId),
        onMovementsTap: () => controller.goToInventoryMovements(
          productId: balance.productId,
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
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
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 600 : double.infinity,
          ),
          margin: EdgeInsets.all(isDesktop ? 40 : 20),
          padding: EdgeInsets.all(isDesktop ? 40 : 24),
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
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  Icons.inventory_2,
                  size: isDesktop ? 56 : 48,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isDesktop ? 20 : 16),
              Text(
                controller.searchQuery.value.isNotEmpty
                    ? 'No se encontraron productos'
                    : 'Sin productos en inventario',
                style: Get.textTheme.titleMedium?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 20 : 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isDesktop ? 12 : 8),
              Text(
                controller.searchQuery.value.isNotEmpty
                    ? 'Intenta con otros términos de búsqueda o revisa los filtros aplicados'
                    : 'No se encontraron productos que coincidan con los filtros aplicados',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: ElegantLightTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isDesktop ? 24 : 20),
              if (controller.searchQuery.value.isNotEmpty)
                _buildElegantButton(
                  text: 'Limpiar búsqueda',
                  icon: Icons.clear,
                  onPressed: controller.clearSearch,
                  gradient: ElegantLightTheme.warningGradient,
                )
              else
                _buildElegantButton(
                  text: 'Actualizar inventario',
                  icon: Icons.refresh,
                  onPressed: controller.refreshBalances,
                  gradient: ElegantLightTheme.primaryGradient,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 600 : double.infinity,
        ),
        margin: EdgeInsets.all(isDesktop ? 40 : 20),
        padding: EdgeInsets.all(isDesktop ? 40 : 24),
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
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: Icon(
                Icons.error_outline,
                size: isDesktop ? 56 : 48,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isDesktop ? 20 : 16),
            Text(
              'Error al cargar inventario',
              style: Get.textTheme.titleMedium?.copyWith(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: isDesktop ? 20 : 16,
              ),
            ),
            SizedBox(height: isDesktop ? 12 : 8),
            Obx(() => Text(
              controller.error.value,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: ElegantLightTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            )),
            SizedBox(height: isDesktop ? 24 : 20),
            _buildElegantButton(
              text: 'Reintentar',
              icon: Icons.refresh,
              onPressed: controller.refreshBalances,
              gradient: ElegantLightTheme.primaryGradient,
            ),
          ],
        ),
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
            color: gradient.colors.first.withValues(alpha: 0.3),
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
      // Botón de actualizar
      IconButton(
        onPressed: controller.refreshBalances,
        icon: const Icon(Icons.refresh),
        tooltip: 'Actualizar',
      ),
      
      // Menú de opciones
      PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'download':
              _showDownloadOptions();
              break;
            case 'share':
              _showShareOptions();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'download',
            child: Row(
              children: [
                Icon(Icons.download, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Descargar'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Compartir'),
              ],
            ),
          ),
        ],
      ),
      
      const SizedBox(width: AppDimensions.paddingSmall),
    ];
  }

  void _showDownloadOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
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
                  child: const Icon(Icons.download, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Descargar Balances',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: ElegantLightTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Los archivos se guardarán en la ubicación que selecciones',
              style: Get.textTheme.bodySmall?.copyWith(
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _buildDownloadOption(
              'Descargar como Excel',
              'Archivo .xlsx para análisis de datos',
              Icons.table_chart,
              Colors.green,
              () {
                Get.back();
                controller.downloadBalancesToExcel();
              },
            ),
            _buildDownloadOption(
              'Descargar como PDF',
              'Reporte .pdf para impresión',
              Icons.picture_as_pdf,
              Colors.red,
              () {
                Get.back();
                controller.downloadBalancesToPdf();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showShareOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
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
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Compartir Balances',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: ElegantLightTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Comparte los archivos por WhatsApp, Email, etc.',
              style: Get.textTheme.bodySmall?.copyWith(
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _buildDownloadOption(
              'Compartir Excel',
              'Enviar archivo .xlsx por WhatsApp, Email, etc.',
              Icons.table_chart,
              Colors.blue,
              () {
                Get.back();
                controller.exportBalancesToExcel();
              },
            ),
            _buildDownloadOption(
              'Compartir PDF',
              'Enviar reporte .pdf por WhatsApp, Email, etc.',
              Icons.picture_as_pdf,
              Colors.orange,
              () {
                Get.back();
                controller.exportBalancesToPdf();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: Get.textTheme.titleSmall?.copyWith(
            color: ElegantLightTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Get.textTheme.bodySmall?.copyWith(
            color: ElegantLightTheme.textSecondary,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSortMenuItem(String label, String sortBy, String sortOrder) {
    final isSelected = controller.sortBy.value == sortBy && controller.sortOrder.value == sortOrder;
    
    return Row(
      children: [
        Icon(
          sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
          color: isSelected ? AppColors.primary : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (isSelected) ...[
          const Spacer(),
          Icon(
            Icons.check,
            color: AppColors.primary,
            size: 16,
          ),
        ],
      ],
    );
  }
}