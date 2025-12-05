// lib/features/inventory/presentation/screens/inventory_dashboard_screen.dart
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_movement.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/spectacular_floating_action_button.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/inventory_controller.dart';
import '../widgets/inventory_overview_cards.dart';
import '../widgets/inventory_quick_actions.dart';
import '../widgets/inventory_recent_activity.dart';
import '../widgets/inventory_alerts_summary.dart';
import '../services/inventory_export_service.dart';

class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreen> createState() =>
      _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  InventoryController get controller => Get.find<InventoryController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Centro de Inventario',
      actions: _buildAppBarActions(context),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1200;
          if (isDesktop) return const SizedBox.shrink();

          return SpectacularFloatingActionButton(
            onPressed: () => _showQuickActionsMenu(),
            icon: Icons.add,
            text: 'Acciones',
            showText: false,
          );
        },
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

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
                  // Header con estadísticas principales
                  SliverToBoxAdapter(
                    child: _buildResponsiveHeader(screenWidth),
                  ),

                  // Alertas y resumen
                  SliverToBoxAdapter(
                    child: _buildResponsiveAlerts(screenWidth),
                  ),

                  // Contenido principal
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

  Widget _buildResponsiveHeader(double screenWidth) {
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
        vertical: isDesktop ? 16.0 : 12.0,
      ),
      padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 16 : 12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  Icons.inventory_2,
                  size:
                      isDesktop
                          ? 32
                          : isTablet
                          ? 28
                          : 24,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: isDesktop ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getResponsiveTitle(screenWidth),
                      style: _getResponsiveTitleStyle(screenWidth),
                      maxLines: screenWidth < 400 ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!screenWidth.isNaN && screenWidth > 350) ...[
                      SizedBox(height: isDesktop ? 8 : 6),
                      Text(
                        _getResponsiveSubtitle(screenWidth),
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: ElegantLightTheme.textSecondary,
                          fontSize: _getResponsiveFontSize(
                            screenWidth,
                            base: 14,
                          ),
                        ),
                        maxLines: screenWidth < 600 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveAlerts(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final padding =
        isDesktop
            ? 32.0
            : isTablet
            ? 24.0
            : 16.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: padding),
      child: const InventoryAlertsSummary(),
    );
  }

  Widget _buildResponsiveContent(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final padding = _getResponsivePadding(screenWidth);

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de estadísticas principales
            const InventoryOverviewCards(),

            SizedBox(height: isDesktop ? 28 : 24),

            // Módulos de navegación (ahora arriba)
            _buildNavigationGrid(screenWidth),

            SizedBox(height: isDesktop ? 40 : 32),

            // Divider visual entre secciones
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            SizedBox(height: isDesktop ? 32 : 24),

            // Título para la sección de actividad
            _buildSectionTitle('Centro de Actividad y Control'),
            SizedBox(height: isDesktop ? 20 : 16),

            // Layout responsivo para el contenido principal (ahora abajo)
            if (isDesktop)
              _buildDesktopLayout(screenWidth)
            else if (isTablet)
              _buildTabletLayout(screenWidth)
            else
              _buildMobileLayout(screenWidth),

            SizedBox(height: padding),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda - Acciones rápidas (más ancha)
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUniformSectionTitle('Acciones Rápidas'),
              const SizedBox(height: 16),
              const InventoryQuickActions(),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Columna central - Actividad reciente (balanceada)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUniformSectionTitle('Actividad Reciente'),
              const SizedBox(height: 16),
              const InventoryRecentActivity(),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Columna derecha - Resumen semanal (más ancha)
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUniformSectionTitle('Resumen Semanal'),
              const SizedBox(height: 16),
              _buildWeeklySummaryCard(true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(double screenWidth) {
    final isLargeTablet = screenWidth >= 900;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna izquierda - Acciones rápidas (más estrecha)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUniformSectionTitle('Acciones Rápidas'),
                  const SizedBox(height: 16),
                  const InventoryQuickActions(),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Columna derecha - Actividad reciente (más ancha)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUniformSectionTitle('Actividad Reciente'),
                  const SizedBox(height: 16),
                  const InventoryRecentActivity(),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isLargeTablet ? 24 : 20),
        // Resumen semanal de ancho completo con título
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUniformSectionTitle('Resumen Semanal'),
            const SizedBox(height: 16),
            _buildWeeklySummaryCard(isLargeTablet),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(double screenWidth) {
    final isSmallMobile = screenWidth < 360;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUniformSectionTitle('Acciones Rápidas'),
        const SizedBox(height: 16),
        const InventoryQuickActions(),

        SizedBox(height: isSmallMobile ? 20 : 24),

        _buildUniformSectionTitle('Actividad Reciente'),
        const SizedBox(height: 16),
        const InventoryRecentActivity(),

        SizedBox(height: isSmallMobile ? 20 : 24),

        _buildUniformSectionTitle('Resumen Semanal'),
        const SizedBox(height: 16),
        _buildWeeklySummaryCard(false),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool showViewAll = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isCompact = availableWidth < 300;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.textPrimary,
                  fontSize: UnifiedTypography.getSectionTitleSize(
                    MediaQuery.of(context).size.width,
                  ), // Sistema unificado
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showViewAll) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () => Get.toNamed('/inventory/movements'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 12,
                      vertical: isCompact ? 4 : 6,
                    ),
                  ),
                  child: Text(
                    isCompact ? 'Ver' : 'Ver todos',
                    style: TextStyle(fontSize: isCompact ? 12 : 14),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWeeklySummaryCard(bool isDesktop) {
    return Container(
      height: 400, // Altura fija igual a otros widgets
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: Obx(() => _buildWeeklySummaryContent(isDesktop)),
    );
  }

  Widget _buildWeeklySummaryContent(bool isDesktop) {
    final weeklyStats = _getWeeklyStats();

    return Column(
      children: [
        Expanded(
          child: _buildBasicSummaryItem(
            'Movimientos',
            '+${weeklyStats['totalMovements']}',
            Colors.blue,
            Icons.trending_up,
            isDesktop,
          ),
        ),
        Expanded(
          child: _buildBasicSummaryItem(
            'Productos nuevos',
            '${weeklyStats['newProducts']}',
            Colors.green,
            Icons.add_box,
            isDesktop,
          ),
        ),
        Expanded(
          child: _buildBasicSummaryItem(
            'Ajustes realizados',
            '${weeklyStats['adjustments']}',
            Colors.orange,
            Icons.tune,
            isDesktop,
          ),
        ),
        Expanded(
          child: _buildBasicSummaryItem(
            'Transferencias',
            '${weeklyStats['transfers']}',
            Colors.teal,
            Icons.swap_horiz,
            isDesktop,
          ),
        ),
        // Elemento adicional para desktop/tablet
        Expanded(
          child: _buildSummaryItem(
            'Valor total movido',
            '\$${_formatNumber(weeklyStats['totalValueMoved'] ?? 0.0)}',
            Colors.indigo,
            Icons.attach_money,
            isDesktop,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getWeeklyStats() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    // Filtrar movimientos de la última semana
    final weeklyMovements =
        controller.recentMovements.where((movement) {
          return movement.movementDate.isAfter(weekAgo);
        }).toList();

    // USAR TODOS LOS CONTEOS CORRECTOS desde el controlador
    final transfers = controller.weeklyTransfersCount.value;
    final adjustments = controller.weeklyAdjustmentsCount.value;
    final uniqueProductsAdded = controller.weeklyNewProductsCount.value;

    // Total de movimientos recientes (solo para display general)
    final totalMovements = weeklyMovements.length;

    // Calcular valor total movido (suma de todos los costos totales de la semana)
    final totalValueMoved = weeklyMovements.fold<double>(
      0.0,
      (sum, movement) => sum + (movement.totalCost.abs() ?? 0.0),
    );

    return {
      'totalMovements': totalMovements,
      'newProducts': uniqueProductsAdded,
      'adjustments': adjustments,
      'transfers': transfers,
      'totalValueMoved': totalValueMoved,
    };
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    Color color,
    IconData icon,
    bool isDesktop,
  ) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;

        // Alturas responsivas: desktop ligeramente reducido para balancear columnas
        final height =
            isMobile
                ? 60.0
                : isTablet
                ? 70.0
                : 68.0; // Reducción mínima: 72 a 68
        final padding =
            isMobile
                ? 12.0
                : isTablet
                ? 16.0
                : 16.0; // Reducción mínima: 18 a 16
        final iconSize =
            isMobile
                ? 16.0
                : isTablet
                ? 17.0
                : 16.0; // Reducción mínima: 17 a 16
        final spacing =
            isMobile
                ? 8.0
                : isTablet
                ? 10.0
                : 9.0; // Reducción mínima: 10 a 9

        return Container(
          height: height,
          margin: EdgeInsets.only(
            bottom: isMobile ? 4 : 6,
          ), // Reducido margen inferior card valor total
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: iconSize),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  title,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize:
                        isMobile
                            ? 12
                            : isTablet
                            ? 13
                            : 13, // Reducido desktop a 13
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                value,
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize:
                      isMobile
                          ? 12
                          : isTablet
                          ? 13
                          : 13, // Reducido desktop a 13
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationGrid(double screenWidth) {
    final gridConfig = _getGridConfiguration(screenWidth);
    final crossAxisCount = gridConfig['crossAxisCount'] as int;
    final childAspectRatio = gridConfig['childAspectRatio'] as double;
    final crossAxisSpacing = gridConfig['crossAxisSpacing'] as double;
    final mainAxisSpacing = gridConfig['mainAxisSpacing'] as double;

    final navigationItems = [
      {
        'title': 'Balances de Inventario',
        'subtitle': 'Ver stock actual y valoración',
        'icon': Icons.account_balance_wallet,
        'gradient': ElegantLightTheme.primaryGradient,
        'onTap': () => Get.toNamed('/inventory/balances'),
      },
      {
        'title': 'Movimientos',
        'subtitle': 'Historial de entradas y salidas',
        'icon': Icons.swap_horiz,
        'gradient': ElegantLightTheme.successGradient,
        'onTap': () => Get.toNamed('/inventory/movements'),
      },
      {
        'title': 'Gestión de Almacenes',
        'subtitle': 'Configurar y administrar almacenes',
        'icon': Icons.warehouse,
        'gradient': LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade800],
        ),
        'onTap': () => Get.toNamed('/warehouses'),
      },
      {
        'title': 'Ajustes de Stock',
        'subtitle': 'Correcciones de inventario',
        'icon': Icons.tune,
        'gradient': ElegantLightTheme.warningGradient,
        'onTap': () => Get.toNamed('/inventory/adjustments'),
      },
      {
        'title': 'Transferencias',
        'subtitle': 'Movimientos entre almacenes',
        'icon': Icons.swap_horizontal_circle,
        'gradient': ElegantLightTheme.infoGradient,
        'onTap': () => Get.toNamed('/inventory/transfers'),
      },
      {
        'title': 'Reportes y Analytics',
        'subtitle': 'Análisis y tendencias',
        'icon': Icons.analytics,
        'gradient': ElegantLightTheme.errorGradient,
        'onTap': () => _showReportsMenu(),
      },
      {
        'title': 'Configuración',
        'subtitle': 'Ajustes del sistema',
        'icon': Icons.settings,
        'gradient': LinearGradient(
          colors: [Colors.grey.shade600, Colors.grey.shade800],
        ),
        'onTap': () => _showConfigurationComingSoon(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Módulos de Inventario'),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: navigationItems.length,
          itemBuilder: (context, index) {
            final item = navigationItems[index];
            return _buildNavigationTile(
              title: item['title'] as String,
              subtitle: item['subtitle'] as String,
              icon: item['icon'] as IconData,
              gradient: item['gradient'] as LinearGradient,
              onTap: item['onTap'] as VoidCallback,
              screenWidth: screenWidth,
            );
          },
        ),
      ],
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(
              screenWidth >= 600 ? 6 : 14,
            ), // ULTRA REDUCIDO: desktop/tablet 10→6
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    screenWidth >= 600 ? 4 : 8,
                  ), // ULTRA REDUCIDO: desktop/tablet 6→4
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(
                      10,
                    ), // Reducido de 12 a 10
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 6, // Reducido de 8 a 6
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: screenWidth >= 600 ? 12 : 20,
                  ), // ULTRA REDUCIDO: desktop/tablet 16→12
                ),
                SizedBox(
                  width: screenWidth >= 600 ? 6 : 12,
                ), // ULTRA REDUCIDO: desktop/tablet 8→6
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: Get.textTheme.titleSmall?.copyWith(
                          // Cambiado de titleMedium a titleSmall
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textPrimary,
                          fontSize: UnifiedTypography.getModuleTitleSize(
                            screenWidth,
                          ), // Sistema unificado
                        ),
                        maxLines: screenWidth < 250 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        height: screenWidth >= 600 ? 0 : 2,
                      ), // ULTRA REDUCIDO: desktop/tablet 1→0 (sin espacio)
                      Text(
                        subtitle,
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: ElegantLightTheme.textSecondary,
                          fontSize: UnifiedTypography.getModuleDescriptionSize(
                            screenWidth,
                          ), // Sistema unificado
                        ),
                        maxLines: screenWidth < 250 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: ElegantLightTheme.textSecondary,
                    size: 14,
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
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: controller.refreshData,
        tooltip: 'Actualizar datos',
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
        itemBuilder:
            (context) => [
              PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download, color: ElegantLightTheme.primaryBlue),
                    const SizedBox(width: 8),
                    const Text('Descargar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: ElegantLightTheme.primaryBlue),
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

  void _showQuickActionsMenu() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Acciones Rápidas',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildQuickActionItem(
              icon: Icons.add_box,
              title: 'Nuevo Movimiento',
              subtitle: 'Registrar entrada o salida',
              onTap: () {
                Get.back();
                Get.toNamed('/inventory/movements/create');
              },
            ),
            _buildQuickActionItem(
              icon: Icons.tune,
              title: 'Ajuste de Stock',
              subtitle: 'Corregir inventario',
              onTap: () {
                Get.back();
                Get.toNamed('/inventory/adjustments');
              },
            ),
            _buildQuickActionItem(
              icon: Icons.swap_horiz,
              title: 'Transferencia',
              subtitle: 'Mover entre almacenes',
              onTap: () {
                Get.back();
                Get.toNamed('/inventory/transfers');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: Get.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: ElegantLightTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Get.textTheme.bodySmall?.copyWith(
          color: ElegantLightTheme.textSecondary,
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
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
            // Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Descargar Datos',
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
              'Balances Excel',
              'Archivo .xlsx con todos los balances actuales',
              Icons.table_chart,
              Colors.green,
              () {
                Get.back();
                _downloadBalancesToExcel();
              },
            ),
            _buildDownloadOption(
              'Balances PDF',
              'Reporte .pdf para impresión',
              Icons.picture_as_pdf,
              Colors.red,
              () {
                Get.back();
                _downloadBalancesToPDF();
              },
            ),
            _buildDownloadOption(
              'Movimientos Excel',
              'Archivo .xlsx con movimientos recientes',
              Icons.swap_horiz,
              Colors.orange,
              () {
                Get.back();
                _downloadMovementsToExcel();
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
            // Título
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
                  'Compartir Datos',
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
              'Compartir Balances Excel',
              'Enviar archivo .xlsx por WhatsApp, Email, etc.',
              Icons.table_chart,
              Colors.blue,
              () {
                Get.back();
                _shareBalancesToExcel();
              },
            ),
            _buildDownloadOption(
              'Compartir Balances PDF',
              'Enviar reporte .pdf por WhatsApp, Email, etc.',
              Icons.picture_as_pdf,
              Colors.orange,
              () {
                Get.back();
                _shareBalancesToPDF();
              },
            ),
            _buildDownloadOption(
              'Compartir Movimientos',
              'Enviar movimientos .xlsx por WhatsApp, Email, etc.',
              Icons.swap_horiz,
              Colors.purple,
              () {
                Get.back();
                _shareMovementsToExcel();
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
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Get.textTheme.bodySmall?.copyWith(
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: ElegantLightTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== MÉTODOS DE DESCARGA (con picker) ====================

  void _downloadBalancesToExcel() async {
    try {
      // Mostrar loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Obtener datos con filtros aplicados (si el controller tiene filtros)
      final balances =
          controller.filteredBalances.isNotEmpty
              ? controller.filteredBalances
              : controller.balances;

      if (balances.isEmpty) {
        Get.back(); // Cerrar loading
        Get.snackbar(
          'Sin datos',
          'No hay balances de inventario para descargar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Usar método download que abre picker
      final filePath = await InventoryExportService.downloadBalancesToExcel(
        balances,
      );

      Get.back(); // Cerrar loading
      Get.snackbar(
        'Descarga exitosa',
        'Archivo guardado en: $filePath',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.back(); // Cerrar loading
      Get.snackbar(
        'Error de descarga',
        'No se pudo descargar: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _downloadBalancesToPDF() async {
    try {
      // Mostrar loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Obtener datos con filtros aplicados
      final balances =
          controller.filteredBalances.isNotEmpty
              ? controller.filteredBalances
              : controller.balances;

      if (balances.isEmpty) {
        Get.back(); // Cerrar loading
        Get.snackbar(
          'Sin datos',
          'No hay balances de inventario para descargar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Usar método download que abre picker
      final filePath = await InventoryExportService.downloadBalancesToPDF(
        balances,
      );

      Get.back(); // Cerrar loading
      Get.snackbar(
        'Descarga exitosa',
        'Archivo guardado en: $filePath',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.back(); // Cerrar loading
      Get.snackbar(
        'Error de descarga',
        'No se pudo descargar: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _downloadMovementsToExcel() async {
    try {
      // Mostrar loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Obtener movimientos (aplicar filtros de fecha si es necesario)
      final movements = controller.recentMovements;

      if (movements.isEmpty) {
        Get.back(); // Cerrar loading
        Get.snackbar(
          'Sin datos',
          'No hay movimientos recientes para descargar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Crear un archivo temporal para compartir
      await InventoryExportService.exportMovementsToExcel(movements);

      Get.back(); // Cerrar loading
      Get.snackbar(
        'Descarga exitosa',
        'Movimientos guardados correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.back(); // Cerrar loading
      Get.snackbar(
        'Error de descarga',
        'No se pudo descargar: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==================== MÉTODOS DE COMPARTIR ====================

  void _shareBalancesToExcel() async {
    try {
      // Mostrar loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Obtener datos con filtros aplicados
      final balances =
          controller.filteredBalances.isNotEmpty
              ? controller.filteredBalances
              : controller.balances;

      if (balances.isEmpty) {
        Get.back(); // Cerrar loading
        Get.snackbar(
          'Sin datos',
          'No hay balances de inventario para compartir',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Usar método de compartir
      await InventoryExportService.exportBalancesToExcel(balances);

      Get.back(); // Cerrar loading
      Get.snackbar(
        'Listo para compartir',
        'Selecciona la aplicación para compartir',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        icon: const Icon(Icons.share, color: Colors.white),
      );
    } catch (e) {
      Get.back(); // Cerrar loading
      Get.snackbar(
        'Error al compartir',
        'No se pudo compartir: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _shareBalancesToPDF() async {
    try {
      // Mostrar loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Obtener datos con filtros aplicados
      final balances =
          controller.filteredBalances.isNotEmpty
              ? controller.filteredBalances
              : controller.balances;

      if (balances.isEmpty) {
        Get.back(); // Cerrar loading
        Get.snackbar(
          'Sin datos',
          'No hay balances de inventario para compartir',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Usar método de compartir
      await InventoryExportService.exportBalancesToPDF(balances);

      Get.back(); // Cerrar loading
      Get.snackbar(
        'Listo para compartir',
        'Selecciona la aplicación para compartir',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        icon: const Icon(Icons.share, color: Colors.white),
      );
    } catch (e) {
      Get.back(); // Cerrar loading
      Get.snackbar(
        'Error al compartir',
        'No se pudo compartir: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _shareMovementsToExcel() async {
    try {
      // Mostrar loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Obtener movimientos
      final movements = controller.recentMovements;

      if (movements.isEmpty) {
        Get.back(); // Cerrar loading
        Get.snackbar(
          'Sin datos',
          'No hay movimientos recientes para compartir',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Usar método de compartir
      await InventoryExportService.exportMovementsToExcel(movements);

      Get.back(); // Cerrar loading
      Get.snackbar(
        'Listo para compartir',
        'Selecciona la aplicación para compartir',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        icon: const Icon(Icons.share, color: Colors.white),
      );
    } catch (e) {
      Get.back(); // Cerrar loading
      Get.snackbar(
        'Error al compartir',
        'No se pudo compartir: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showReportsMenu() {
    // Implementación de reportes
    Get.snackbar(
      'Reportes',
      'Funcionalidad de reportes disponible pronto',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showConfigurationComingSoon() {
    Get.snackbar(
      'Configuración',
      'Funcionalidad de configuración disponible pronto',
      snackPosition: SnackPosition.TOP,
    );
  }

  // ==================== HELPER METHODS PARA RESPONSIVE DESIGN ====================

  /// Título uniforme para las secciones de actividad y control
  Widget _buildUniformSectionTitle(String title) {
    return Text(
      title,
      style: Get.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: ElegantLightTheme.textPrimary,
        fontSize: 20, // Tamaño fijo para consistencia
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getResponsiveTitle(double screenWidth) {
    if (screenWidth >= 1200) {
      return 'Centro de Control de Inventario';
    } else if (screenWidth >= 600) {
      return 'Centro de Inventario';
    } else if (screenWidth >= 400) {
      return 'Centro de Inventario';
    } else {
      return 'Inventario';
    }
  }

  TextStyle? _getResponsiveTitleStyle(double screenWidth) {
    if (screenWidth >= 1200) {
      return Get.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: ElegantLightTheme.textPrimary,
      );
    } else if (screenWidth >= 600) {
      return Get.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: ElegantLightTheme.textPrimary,
      );
    } else {
      return Get.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: ElegantLightTheme.textPrimary,
      );
    }
  }

  String _getResponsiveSubtitle(double screenWidth) {
    if (screenWidth >= 1200) {
      return 'Gestiona tu inventario con control total de lotes FIFO, movimientos y balances en tiempo real.';
    } else if (screenWidth >= 800) {
      return 'Control total de inventario con movimientos y balances en tiempo real.';
    } else if (screenWidth >= 600) {
      return 'Gestión completa de inventario y movimientos.';
    } else {
      return 'Control de inventario y stock.';
    }
  }

  double _getResponsiveFontSize(double screenWidth, {required double base}) {
    if (screenWidth >= 1200) {
      return base + 2;
    } else if (screenWidth >= 600) {
      return base;
    } else if (screenWidth >= 400) {
      return base - 1;
    } else {
      return base - 2;
    }
  }

  double _getResponsivePadding(double screenWidth) {
    if (screenWidth >= 1200) {
      return 32.0;
    } else if (screenWidth >= 800) {
      return 24.0;
    } else if (screenWidth >= 600) {
      return 20.0;
    } else if (screenWidth >= 400) {
      return 16.0;
    } else {
      return 12.0;
    }
  }

  Map<String, dynamic> _getGridConfiguration(double screenWidth) {
    if (screenWidth >= 1400) {
      return {
        'crossAxisCount': 3,
        'childAspectRatio':
            7.0, // ULTRA REDUCIDO - cards súper planas en desktop
        'crossAxisSpacing': 24.0,
        'mainAxisSpacing': 8.0, // Spacing mínimo
      };
    } else if (screenWidth >= 1200) {
      return {
        'crossAxisCount': 3,
        'childAspectRatio':
            6.0, // ULTRA REDUCIDO - cards súper planas en desktop
        'crossAxisSpacing': 20.0,
        'mainAxisSpacing': 8.0, // Spacing mínimo
      };
    } else if (screenWidth >= 900) {
      return {
        'crossAxisCount': 2,
        'childAspectRatio':
            5.5, // ULTRA REDUCIDO - cards súper planas en tablets
        'crossAxisSpacing': 20.0,
        'mainAxisSpacing': 8.0, // Spacing mínimo
      };
    } else if (screenWidth >= 600) {
      return {
        'crossAxisCount': 2,
        'childAspectRatio':
            4.5, // ULTRA REDUCIDO - cards súper planas en tablets
        'crossAxisSpacing': 16.0,
        'mainAxisSpacing': 8.0, // Spacing mínimo
      };
    } else {
      return {
        'crossAxisCount': 1,
        'childAspectRatio': screenWidth < 400 ? 3.0 : 3.5, // Mobile sin cambios
        'crossAxisSpacing': 16.0,
        'mainAxisSpacing': 16.0,
      };
    }
  }

  /// Widget para las 4 cards básicas del resumen (ligeramente más pequeñas en desktop)
  Widget _buildBasicSummaryItem(
    String title,
    String value,
    Color color,
    IconData icon,
    bool isDesktop,
  ) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;

        // Reducción mínima solo para las cards básicas en desktop
        final height =
            isMobile
                ? 60.0
                : isTablet
                ? 70.0
                : 64.0; // Más pequeñas: 68 a 64
        final padding =
            isMobile
                ? 12.0
                : isTablet
                ? 16.0
                : 14.0; // Más pequeñas: 16 a 14
        final iconSize =
            isMobile
                ? 16.0
                : isTablet
                ? 17.0
                : 15.0; // Más pequeñas: 16 a 15
        final spacing =
            isMobile
                ? 8.0
                : isTablet
                ? 10.0
                : 8.0; // Más pequeñas: 9 a 8

        return Container(
          height: height,
          margin: EdgeInsets.only(
            bottom: isMobile ? 4 : 6,
          ), // Reducido margen inferior cards básicas
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: iconSize),
              SizedBox(width: spacing),
              Expanded(
                child: Text(
                  title,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize:
                        isMobile
                            ? 12
                            : isTablet
                            ? 13
                            : 11, // Más pequeña: 12 a 11
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                value,
                style: Get.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize:
                      isMobile
                          ? 12
                          : isTablet
                          ? 13
                          : 11, // Más pequeña: 12 a 11
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Función para formatear números con separadores de miles
  String _formatNumber(double number) {
    final formatter = NumberFormat('#,##0', 'es_CO');
    return formatter.format(number);
  }
}

// ===== SISTEMA UNIFICADO DE TIPOGRAFÍA =====

/// Sistema de tamaños de fuente unificado y responsivo
class UnifiedTypography {
  // Títulos principales de secciones
  static double getSectionTitleSize(double screenWidth) {
    if (screenWidth >= 1200) return 18.0; // Desktop
    if (screenWidth >= 600) return 16.0; // Tablet
    return 15.0; // Mobile
  }

  // Títulos de cards grandes (estadísticas principales) - AUMENTADOS
  static double getCardTitleSize(double screenWidth) {
    if (screenWidth >= 1200) return 13.0; // Desktop - más legible
    if (screenWidth >= 600) return 11.0; // Tablet
    return 12.0; // Mobile
  }

  // Valores principales (números importantes) - AUMENTADOS
  static double getValueSize(double screenWidth) {
    if (screenWidth >= 1200) return 18.0; // Desktop - mucho más legible
    if (screenWidth >= 600) return 16.0; // Tablet
    return 18.0; // Mobile - más grande
  }

  // Alias para compatibilidad con inventory_overview_cards
  static double getCardValueSize(double screenWidth) =>
      getValueSize(screenWidth);

  // Subtítulos/descripciones de cards - AUMENTADOS
  static double getSubtitleSize(double screenWidth) {
    if (screenWidth >= 1200) return 11.0; // Desktop - más legible
    if (screenWidth >= 600) return 10.0; // Tablet
    return 11.0; // Mobile
  }

  // Alias para compatibilidad con inventory_overview_cards
  static double getCardSubtitleSize(double screenWidth) =>
      getSubtitleSize(screenWidth);

  // Títulos de módulos/navegación - AUMENTADOS para mejor visibilidad
  static double getModuleTitleSize(double screenWidth) {
    if (screenWidth >= 1200) return 14.0; // Desktop - más legible
    if (screenWidth >= 600) return 13.0; // Tablet - más legible
    return 13.0; // Mobile
  }

  // Descripciones de módulos - AUMENTADAS para mejor visibilidad
  static double getModuleDescriptionSize(double screenWidth) {
    if (screenWidth >= 1200) return 11.0; // Desktop - mucho más legible
    if (screenWidth >= 600) return 10.0; // Tablet - más legible
    return 10.0; // Mobile
  }

  // Texto en listas/actividades
  static double getListItemTitleSize(double screenWidth) {
    if (screenWidth >= 1200) return 12.0; // Desktop
    if (screenWidth >= 600) return 12.0; // Tablet
    return 12.0; // Mobile - consistente
  }

  static double getListItemSubtitleSize(double screenWidth) {
    if (screenWidth >= 1200) return 10.0; // Desktop
    if (screenWidth >= 600) return 10.0; // Tablet
    return 10.0; // Mobile - consistente
  }

  // Texto de botones
  static double getButtonTextSize(double screenWidth) {
    if (screenWidth >= 1200) return 13.0; // Desktop
    if (screenWidth >= 600) return 13.0; // Tablet
    return 12.0; // Mobile
  }

  // Texto de tags pequeños (cantidades, etc.)
  static double getQuantityTagSize(double screenWidth) {
    if (screenWidth >= 1200) return 8.0; // Desktop - muy pequeño
    if (screenWidth >= 600) return 9.0; // Tablet
    return 9.0; // Mobile
  }
}
