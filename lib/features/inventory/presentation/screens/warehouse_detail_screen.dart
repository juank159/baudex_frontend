// lib/features/inventory/presentation/screens/warehouse_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/warehouse_detail_controller.dart';

class WarehouseDetailScreen extends StatefulWidget {
  const WarehouseDetailScreen({super.key});

  @override
  State<WarehouseDetailScreen> createState() => _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState extends State<WarehouseDetailScreen> {
  WarehouseDetailController get controller => Get.find<WarehouseDetailController>();

  @override
  void initState() {
    super.initState();
    // Asegurar que el controlador esté disponible
    try {
      Get.find<WarehouseDetailController>();
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
      final warehouseDetailController = Get.find<WarehouseDetailController>();
      
      return Scaffold(
        backgroundColor: ElegantLightTheme.backgroundColor,
        appBar: AppBar(
          title: Obx(() => Text(
            warehouseDetailController.hasWarehouse 
                ? warehouseDetailController.warehouseName 
                : 'Detalles del Almacén',
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
          )),
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
                child: Obx(() {
                  if (warehouseDetailController.isLoading && !warehouseDetailController.hasWarehouse) {
                    return const Center(child: LoadingWidget());
                  }

                  if (warehouseDetailController.error.isNotEmpty && !warehouseDetailController.hasWarehouse) {
                    return _buildErrorState();
                  }

                  if (!warehouseDetailController.hasWarehouse) {
                    return _buildNotFoundState();
                  }

                  return _buildResponsiveContent(screenWidth, isDesktop, isTablet);
                }),
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

  Widget _buildResponsiveContent(double screenWidth, bool isDesktop, bool isTablet) {
    final padding = isDesktop ? 24.0 : isTablet ? 20.0 : 16.0;
    final maxWidth = isDesktop ? screenWidth * 0.85 : double.infinity; // Usar 85% del ancho en desktop
    
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header principal del almacén
            SliverToBoxAdapter(
              child: _buildWarehouseHeader(padding, isDesktop),
            ),

            // Información detallada
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    if (isDesktop)
                      // Layout de 2 columnas para desktop - mejor distribución del espacio
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3, // Más espacio para la información principal
                            child: Column(
                              children: [
                                _buildBasicInfoCard(isDesktop),
                                SizedBox(height: isDesktop ? 20 : 16),
                                _buildStatusCard(isDesktop),
                              ],
                            ),
                          ),
                          SizedBox(width: isDesktop ? 20 : 16),
                          Expanded(
                            flex: 2, // Espacio adecuado para acciones y stats
                            child: Column(
                              children: [
                                _buildStatsCard(isDesktop),
                                SizedBox(height: isDesktop ? 20 : 16),
                                _buildActionsCard(isDesktop),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      // Layout de columna única para tablet/móvil
                      Column(
                        children: [
                          _buildBasicInfoCard(isDesktop),
                          SizedBox(height: isTablet ? 18 : 16),
                          _buildStatusCard(isDesktop),
                          SizedBox(height: isTablet ? 18 : 16),
                          _buildStatsCard(isDesktop),
                          SizedBox(height: isTablet ? 18 : 16),
                          _buildActionsCard(isDesktop),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseHeader(double padding, bool isDesktop) {
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      margin: EdgeInsets.all(padding),
      padding: EdgeInsets.all(isDesktop ? 28.0 : isTablet ? 20.0 : 16.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Obx(() {
        final warehouse = controller.warehouse;
        if (warehouse == null) return const SizedBox.shrink();
        
        if (isMobile) {
          // Layout vertical para móviles
          return Column(
            children: [
              // Icono y nombre
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: warehouse.isActive 
                          ? ElegantLightTheme.primaryGradient
                          : ElegantLightTheme.errorGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Icon(
                      Icons.warehouse,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      warehouse.name,
                      style: Get.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Badges en columna para móvil
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Código: ${warehouse.code}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: warehouse.isActive 
                          ? ElegantLightTheme.successGradient
                          : ElegantLightTheme.errorGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      warehouse.isActive ? 'ACTIVO' : 'INACTIVO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (warehouse.description != null && warehouse.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  warehouse.description!,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          );
        }
        
        // Layout horizontal para tablet/desktop
        return Row(
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : 20),
              decoration: BoxDecoration(
                gradient: warehouse.isActive 
                    ? ElegantLightTheme.primaryGradient
                    : ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: Icon(
                Icons.warehouse,
                color: Colors.white,
                size: isDesktop ? 48 : 40,
              ),
            ),
            SizedBox(width: isDesktop ? 24 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouse.name,
                    style: Get.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                      fontSize: isDesktop ? 28 : 22,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 8 : 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.infoGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Código: ${warehouse.code}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 14 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: warehouse.isActive 
                              ? ElegantLightTheme.successGradient
                              : ElegantLightTheme.errorGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          warehouse.isActive ? 'ACTIVO' : 'INACTIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 14 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (warehouse.description != null && warehouse.description!.isNotEmpty) ...[
                    SizedBox(height: isDesktop ? 12 : 8),
                    Text(
                      warehouse.description!,
                      style: Get.textTheme.bodyLarge?.copyWith(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: isDesktop ? 16 : 14,
                      ),
                      maxLines: isTablet ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBasicInfoCard(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
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
                child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Información Básica',
                style: Get.textTheme.titleLarge?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 20 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          
          Obx(() {
            final warehouse = controller.warehouse;
            if (warehouse == null) return const SizedBox.shrink();
            
            return Column(
              children: [
                _buildInfoRow(
                  icon: Icons.warehouse,
                  label: 'Nombre',
                  value: warehouse.name,
                  isDesktop: isDesktop,
                ),
                _buildInfoRow(
                  icon: Icons.code,
                  label: 'Código',
                  value: warehouse.code,
                  isDesktop: isDesktop,
                ),
                if (warehouse.description != null && warehouse.description!.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.description,
                    label: 'Descripción',
                    value: warehouse.description!,
                    isDesktop: isDesktop,
                  ),
                if (warehouse.address != null && warehouse.address!.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Dirección',
                    value: warehouse.address!,
                    isDesktop: isDesktop,
                  ),
                if (warehouse.createdAt != null)
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha de Creación',
                    value: _formatDate(warehouse.createdAt!),
                    isDesktop: isDesktop,
                  ),
                if (warehouse.updatedAt != null && warehouse.createdAt != null && warehouse.updatedAt != warehouse.createdAt)
                  _buildInfoRow(
                    icon: Icons.update,
                    label: 'Última Actualización',
                    value: _formatDate(warehouse.updatedAt!),
                    isDesktop: isDesktop,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isDesktop) {
    return Obx(() {
      final warehouse = controller.warehouse;
      if (warehouse == null) return const SizedBox.shrink();
      
      return Container(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
        decoration: BoxDecoration(
          gradient: warehouse.isActive 
              ? ElegantLightTheme.successGradient
              : ElegantLightTheme.errorGradient,
          borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
          boxShadow: ElegantLightTheme.glowShadow,
        ),
        child: Row(
          children: [
            Icon(
              warehouse.isActive ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: isDesktop ? 32 : 28,
            ),
            SizedBox(width: isDesktop ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouse.isActive ? 'Almacén Activo' : 'Almacén Inactivo',
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: isDesktop ? 20 : 18,
                    ),
                  ),
                  SizedBox(height: isDesktop ? 6 : 4),
                  Text(
                    warehouse.isActive 
                        ? 'Este almacén está disponible para todas las operaciones de inventario'
                        : 'Este almacén no está disponible para nuevas operaciones de inventario',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isDesktop ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsCard(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Estadísticas',
                style: Get.textTheme.titleLarge?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 20 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          
          // Placeholder para estadísticas futuras
          Container(
            padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ElegantLightTheme.textSecondary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: isDesktop ? 48 : 40,
                  color: ElegantLightTheme.textSecondary.withOpacity(0.5),
                ),
                SizedBox(height: isDesktop ? 12 : 10),
                Text(
                  'Estadísticas Próximamente',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isDesktop ? 6 : 4),
                Text(
                  'Movimientos, inventario y reportes',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: ElegantLightTheme.textSecondary.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
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
                ),
                child: const Icon(Icons.settings, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Acciones',
                style: Get.textTheme.titleLarge?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 20 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          
          Column(
            children: [
              _buildActionButton(
                icon: Icons.edit,
                label: 'Editar Almacén',
                gradient: ElegantLightTheme.primaryGradient,
                onPressed: controller.goToEditWarehouse,
                isDesktop: isDesktop,
              ),
              SizedBox(height: isDesktop ? 12 : 10),
              
              _buildActionButton(
                icon: Icons.swap_horiz,
                label: 'Ver Movimientos',
                gradient: ElegantLightTheme.infoGradient,
                onPressed: () => _handleMenuAction('movements'),
                isDesktop: isDesktop,
              ),
              SizedBox(height: isDesktop ? 12 : 10),
              
              _buildActionButton(
                icon: Icons.inventory,
                label: 'Ver Inventario',
                gradient: ElegantLightTheme.warningGradient,
                onPressed: () => _handleMenuAction('inventory'),
                isDesktop: isDesktop,
              ),
              SizedBox(height: isDesktop ? 12 : 10),
              
              Obx(() => _buildActionButton(
                icon: controller.isActive ? Icons.pause : Icons.play_arrow,
                label: controller.isActive ? 'Desactivar' : 'Activar',
                gradient: controller.isActive 
                    ? ElegantLightTheme.errorGradient
                    : ElegantLightTheme.successGradient,
                onPressed: () => _handleMenuAction('toggle_status'),
                isDesktop: isDesktop,
              )),
              SizedBox(height: isDesktop ? 16 : 12),
              
              _buildActionButton(
                icon: Icons.delete_forever,
                label: 'Eliminar Almacén',
                gradient: ElegantLightTheme.errorGradient,
                onPressed: () => _handleMenuAction('delete'),
                isDesktop: isDesktop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDesktop,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isDesktop ? 16 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            size: isDesktop ? 20 : 18,
            color: ElegantLightTheme.textSecondary,
          ),
          SizedBox(width: isDesktop ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Get.textTheme.labelMedium?.copyWith(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: isDesktop ? 14 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isDesktop ? 4 : 2),
                Text(
                  value,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onPressed,
    required bool isDesktop,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isDesktop ? 14 : 12,
              horizontal: isDesktop ? 20 : 16,
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: isDesktop ? 20 : 18),
                SizedBox(width: isDesktop ? 12 : 10),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: isDesktop ? 16 : 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
              'Error al cargar almacén',
              style: Get.textTheme.titleMedium?.copyWith(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Obx(() => Text(
              controller.error,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: ElegantLightTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            )),
            const SizedBox(height: AppDimensions.paddingLarge),
            Container(
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: controller.refreshWarehouse,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Reintentar',
                          style: TextStyle(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
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
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(
                Icons.search_off,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Text(
              'Almacén no encontrado',
              style: Get.textTheme.titleMedium?.copyWith(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              'El almacén solicitado no existe o ha sido eliminado',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: ElegantLightTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            Container(
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Get.back(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Volver',
                          style: TextStyle(
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
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      // Botón de editar
      Obx(() => IconButton(
        onPressed: controller.hasWarehouse ? controller.goToEditWarehouse : null,
        icon: const Icon(Icons.edit),
        tooltip: 'Editar Almacén',
      )),
      
      // Botón de refrescar
      IconButton(
        onPressed: controller.refreshWarehouse,
        icon: const Icon(Icons.refresh),
        tooltip: 'Actualizar',
      ),
      
      const SizedBox(width: AppDimensions.paddingSmall),
    ];
  }

  void _handleMenuAction(String action) {
    final warehouse = controller.warehouse;
    if (warehouse == null) {
      Get.snackbar(
        'Error',
        'No se pudo obtener la información del almacén',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    switch (action) {
      case 'movements':
        // Navegar a movimientos del almacén específico
        print('🚀 Navegando a movimientos del almacén: ${warehouse.id} (${warehouse.name})');
        Get.toNamed('/inventory/movements', arguments: {
          'warehouseId': warehouse.id,
          'warehouseName': warehouse.name,
        });
        break;
      case 'inventory':
        // Navegar a inventario del almacén específico
        print('🚀 Navegando a inventario del almacén: ${warehouse.id} (${warehouse.name})');
        Get.toNamed('/inventory/balances', arguments: {
          'warehouseId': warehouse.id,
          'warehouseName': warehouse.name,
        });
        break;
      case 'toggle_status':
        // TODO: Implementar cambio de estado
        Get.snackbar(
          'Próximamente',
          'Funcionalidad de cambio de estado en desarrollo',
          snackPosition: SnackPosition.TOP,
          backgroundColor: ElegantLightTheme.primaryBlue.withOpacity(0.1),
          colorText: ElegantLightTheme.primaryBlue,
        );
        break;
      case 'delete':
        // TODO: Implementar eliminación con confirmación
        controller.deleteWarehouse();
        break;
    }
  }

  Widget _buildControllerErrorWidget(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Error - Detalle de Almacén',
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
                'Error al cargar el detalle',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No se pudo inicializar el controlador de detalle',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Get.back(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Volver',
                            style: TextStyle(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}