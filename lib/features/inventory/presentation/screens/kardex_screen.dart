// lib/features/inventory/presentation/screens/kardex_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/kardex_controller.dart';
import '../widgets/kardex_summary_cards.dart';
import '../widgets/kardex_entries_list.dart';
import '../widgets/kardex_filters_panel.dart';

class KardexScreen extends GetView<KardexController> {
  const KardexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildElegantAppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

            // Definir breakpoints para diseño responsivo
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
              child: Obx(() {
                if (controller.isLoading.value) {
                  return _buildLoadingState(screenWidth);
                }

                if (controller.hasError) {
                  return _buildErrorState(screenWidth);
                }

                if (!controller.hasKardex) {
                  return _buildEmptyState(screenWidth);
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // Filters panel
                    SliverToBoxAdapter(
                      child: Obx(
                        () => AnimatedContainer(
                          duration: ElegantLightTheme.normalAnimation,
                          height: controller.showFilters.value ? null : 0,
                          child:
                              controller.showFilters.value
                                  ? Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          isDesktop
                                              ? 32
                                              : isTablet
                                              ? 24
                                              : 16,
                                    ),
                                    child: const KardexFiltersPanel(),
                                  )
                                  : const SizedBox.shrink(),
                        ),
                      ),
                    ),

                    // Period display elegante
                    SliverToBoxAdapter(
                      child: _buildElegantPeriodDisplay(screenWidth),
                    ),

                    // Tab bar elegante
                    SliverToBoxAdapter(child: _buildElegantTabBar(screenWidth)),

                    // Tab content
                    SliverFillRemaining(
                      child: Obx(() {
                        switch (controller.selectedTab.value) {
                          case 0:
                            return _buildSummaryTab(screenWidth);
                          case 1:
                            return _buildMovementsTab(screenWidth);
                          default:
                            return _buildSummaryTab(screenWidth);
                        }
                      }),
                    ),
                  ],
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryTab(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final padding =
        isDesktop
            ? 32.0
            : isTablet
            ? 24.0
            : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info card elegante
          Container(
            margin: EdgeInsets.only(bottom: isDesktop ? 20 : 16),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 16,
              vertical: isDesktop ? 16 : 12,
            ),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
              boxShadow: ElegantLightTheme.elevatedShadow,
              border: Border.all(
                color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isDesktop ? 12 : 10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: isDesktop ? 20 : 18,
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12),
                Expanded(
                  child: Obx(
                    () => Text(
                      controller.hasKardex
                          ? controller.kardexSummary.value!.productName
                          : 'Producto',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 18 : 16,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Summary cards elegantes
          const KardexSummaryCards(),

          SizedBox(height: isDesktop ? 20 : 16),

          // Period summary elegante
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 20),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
              boxShadow: ElegantLightTheme.neuomorphicShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 10 : 8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
                        boxShadow: ElegantLightTheme.glowShadow,
                      ),
                      child: Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: isDesktop ? 20 : 18,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 12 : 10),
                    Text(
                      'Resumen del Período',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isDesktop ? 18 : 16,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 20 : 16),
                Obx(() {
                  if (!controller.hasKardex) return const SizedBox.shrink();

                  final report = controller.kardexReport.value!;
                  final summary = report.summary;

                  // Diseño elegante para el resumen
                  return Column(
                    children: [
                      _buildElegantSummaryRow(
                        'Total de movimientos',
                        '${report.totalMovements}',
                        Icons.swap_horiz,
                        ElegantLightTheme.infoGradient,
                        isDesktop,
                      ),
                      SizedBox(height: isDesktop ? 16 : 12),
                      _buildElegantSummaryRow(
                        'Movimiento neto',
                        '${summary.netMovement > 0 ? '+' : ''}${summary.netMovement}',
                        summary.netMovement >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        summary.netMovement >= 0
                            ? ElegantLightTheme.successGradient
                            : ElegantLightTheme.errorGradient,
                        isDesktop,
                      ),
                      SizedBox(height: isDesktop ? 16 : 12),
                      _buildElegantSummaryRow(
                        'Valor neto',
                        controller.formatCurrency(summary.netValue),
                        Icons.monetization_on,
                        summary.netValue >= 0
                            ? ElegantLightTheme.successGradient
                            : ElegantLightTheme.errorGradient,
                        isDesktop,
                      ),
                      SizedBox(height: isDesktop ? 16 : 12),
                      _buildElegantSummaryRow(
                        'Costo promedio',
                        controller.formatCurrency(summary.averageUnitCost),
                        Icons.analytics,
                        ElegantLightTheme.primaryGradient,
                        isDesktop,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsTab(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final padding =
        isDesktop
            ? 32.0
            : isTablet
            ? 24.0
            : 16.0;

    return Column(
      children: [
        // Movements count elegante
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: isDesktop ? 16 : 12,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 16,
            vertical: isDesktop ? 16 : 12,
          ),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 10 : 8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  Icons.list,
                  color: Colors.white,
                  size: isDesktop ? 20 : 18,
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Obx(
                  () => Text(
                    '${controller.totalMovements} movimientos encontrados',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: ElegantLightTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: isDesktop ? 16 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Movements list
        const Expanded(child: KardexEntriesList()),
      ],
    );
  }

  PreferredSizeWidget _buildElegantAppBar() {
    return AppBar(
      title: Obx(
        () => Text(
          controller.displayTitle,
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
      ),
      actions: [
        // Refresh button
        IconButton(
          onPressed: controller.refreshKardex,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),

        // ✅ NUEVO: More options siguiendo el patrón de lotes
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
          itemBuilder:
              (context) => [
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
    );
  }

  // Estados elegantes
  Widget _buildLoadingState(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final padding = isDesktop ? 32.0 : 16.0;

    return Center(
      child: Container(
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
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: isDesktop ? 4 : 3,
              ),
            ),
            SizedBox(height: isDesktop ? 24 : 20),
            Text(
              'Cargando kardex...',
              style: Get.textTheme.titleMedium?.copyWith(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: isDesktop ? 18 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final padding = isDesktop ? 32.0 : 16.0;

    return Center(
      child: Container(
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
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: Icon(
                Icons.error_outline,
                size: isDesktop ? 48 : 40,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isDesktop ? 24 : 20),
            Text(
              'Error al cargar kardex',
              style: Get.textTheme.titleMedium?.copyWith(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: isDesktop ? 20 : 18,
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            Text(
              controller.error.value,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: ElegantLightTheme.textSecondary,
                fontSize: isDesktop ? 16 : 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isDesktop ? 24 : 20),
            _buildElegantButton(
              text: 'Reintentar',
              icon: Icons.refresh,
              onPressed: controller.refreshKardex,
              gradient: ElegantLightTheme.primaryGradient,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final padding = isDesktop ? 32.0 : 16.0;

    return Center(
      child: Container(
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
                Icons.timeline,
                size: isDesktop ? 48 : 40,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isDesktop ? 24 : 20),
            Text(
              'Sin datos de kardex',
              style: Get.textTheme.titleMedium?.copyWith(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: isDesktop ? 20 : 18,
              ),
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            Text(
              'No se encontraron movimientos para este producto en el período seleccionado.',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: ElegantLightTheme.textSecondary,
                fontSize: isDesktop ? 16 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElegantPeriodDisplay(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final padding =
        isDesktop
            ? 32.0
            : isTablet
            ? 24.0
            : 16.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: isDesktop ? 12 : 10,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 16,
        vertical: isDesktop ? 16 : 12,
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 8 : 6),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.infoGradient,
              borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
            ),
            child: Icon(
              Icons.date_range,
              size: isDesktop ? 18 : 16,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isDesktop ? 16 : 12),
          Text(
            'Período: ',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: isDesktop ? 16 : 14,
            ),
          ),
          Expanded(
            child: Obx(
              () => Text(
                controller.dateRangeText,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 16 : 14,
                ),
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 8),
          // Botón de filtros elegante como en la pantalla de referencia
          Obx(() {
            final hasActiveFilters =
                false; // Por ahora sin filtros activos visibles
            return Container(
              decoration: BoxDecoration(
                gradient:
                    controller.showFilters.value
                        ? ElegantLightTheme.primaryGradient
                        : ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      controller.showFilters.value
                          ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                          : ElegantLightTheme.textSecondary.withOpacity(0.2),
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
                          controller.showFilters.value
                              ? Colors.white
                              : ElegantLightTheme.textSecondary,
                    ),
                    onPressed: controller.toggleFilters,
                    tooltip:
                        controller.showFilters.value
                            ? 'Ocultar filtros'
                            : 'Mostrar filtros',
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: ElegantLightTheme.errorGradient.colors.first,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '1',
                          style: TextStyle(
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

  Widget _buildElegantTabBar(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final padding =
        isDesktop
            ? 32.0
            : isTablet
            ? 24.0
            : 16.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: isDesktop ? 12 : 8,
      ),
      height: isDesktop ? 68 : 60, // Reducir altura para evitar overflow
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _buildElegantTabButton(
                title: 'Resumen',
                icon: Icons.analytics,
                index: 0,
                isSelected: controller.selectedTab.value == 0,
                screenWidth: screenWidth,
              ),
            ),
            Expanded(
              child: _buildElegantTabButton(
                title: 'Movimientos',
                icon: Icons.list,
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

  Widget _buildElegantTabButton({
    required String title,
    required IconData icon,
    required int index,
    required bool isSelected,
    required double screenWidth,
  }) {
    final isDesktop = screenWidth >= 1200;
    final margin = isDesktop ? 6.0 : 4.0; // Reducir margen
    final borderRadius = isDesktop ? 14.0 : 10.0; // Reducir border radius

    return AnimatedContainer(
      duration: ElegantLightTheme.normalAnimation,
      curve: ElegantLightTheme.smoothCurve,
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () => controller.switchTab(index),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isDesktop ? 8 : 6, // Reducir padding vertical
              horizontal: isDesktop ? 12 : 8, // Reducir padding horizontal
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Importante para evitar overflow
              children: [
                Icon(
                  icon,
                  color:
                      isSelected
                          ? Colors.white
                          : ElegantLightTheme.textSecondary,
                  size: isDesktop ? 20 : 18, // Reducir tamaño de icono
                ),
                SizedBox(height: isDesktop ? 4 : 2), // Reducir spacing
                Flexible(
                  // Importante: usar Flexible en lugar de espacio fijo
                  child: Text(
                    title,
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : ElegantLightTheme.textSecondary,
                      fontSize: isDesktop ? 12 : 10, // Reducir tamaño de fuente
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElegantSummaryRow(
    String label,
    String value,
    IconData icon,
    LinearGradient gradient,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 8 : 6),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(isDesktop ? 8 : 6),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isDesktop ? 18 : 16),
          ),
          SizedBox(width: isDesktop ? 16 : 12),
          Expanded(
            child: Text(
              label,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: isDesktop ? 15 : 14,
              ),
            ),
          ),
          Text(
            value,
            style: Get.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.textPrimary,
              fontSize: isDesktop ? 16 : 15,
            ),
          ),
        ],
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

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Get.textTheme.bodyMedium)),
          Text(
            value,
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Versión compacta para tablet/mobile
  Widget _buildCompactSummaryRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Get.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
          ),
          Text(
            value,
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Versión horizontal para desktop
  Widget _buildCompactSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== ✅ NUEVAS FUNCIONES PROFESIONALES ====================

  void _showDownloadOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Descargar Kardex',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los archivos se guardarán directamente en tu dispositivo',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.table_chart,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              title: const Text('Descargar como Excel'),
              subtitle: const Text('Archivo .xlsx guardado en tu dispositivo'),
              onTap: () {
                Get.back();
                controller.downloadKardexToExcel();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              title: const Text('Descargar como PDF'),
              subtitle: const Text('Archivo .pdf guardado en tu dispositivo'),
              onTap: () {
                Get.back();
                controller.downloadKardexToPdf();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showShareOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Compartir Kardex',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comparte los archivos por WhatsApp, Email, etc.',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.table_chart,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              title: const Text('Compartir Excel'),
              subtitle: const Text(
                'Enviar archivo .xlsx por WhatsApp, Email, etc.',
              ),
              onTap: () {
                Get.back();
                controller.exportKardexToExcel();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              title: const Text('Compartir PDF'),
              subtitle: const Text(
                'Enviar reporte .pdf por WhatsApp, Email, etc.',
              ),
              onTap: () {
                Get.back();
                controller.shareKardexToPdf();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
