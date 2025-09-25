// lib/features/inventory/presentation/widgets/warehouse_card_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/entities/warehouse_with_stats.dart';

class WarehouseCardWidget extends StatelessWidget {
  final WarehouseWithStats warehouseWithStats;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WarehouseCardWidget({
    super.key,
    required this.warehouseWithStats,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  // Getter para acceso fácil al warehouse
  Warehouse get warehouse => warehouseWithStats.warehouse;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    return Container(
      margin: EdgeInsets.only(
        bottom: isDesktop ? 16 : isTablet ? 14 : 12,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
            boxShadow: [
              ...ElegantLightTheme.neuomorphicShadow,
              // Sombra adicional para más elegancia
              BoxShadow(
                color: warehouse.isActive 
                    ? ElegantLightTheme.primaryBlue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.05),
                blurRadius: isDesktop ? 12 : 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 18 : isTablet ? 20 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con icono y información principal
                    Row(
                      children: [
                        // Icono elegante del almacén - más compacto en desktop
                        Container(
                          padding: EdgeInsets.all(isDesktop ? 12 : 12),
                          decoration: BoxDecoration(
                            gradient: warehouse.isActive 
                                ? ElegantLightTheme.primaryGradient
                                : ElegantLightTheme.errorGradient,
                            borderRadius: BorderRadius.circular(isDesktop ? 12 : 12),
                            boxShadow: [
                              BoxShadow(
                                color: warehouse.isActive 
                                    ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.2),
                                blurRadius: 6,
                                spreadRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.warehouse,
                            color: Colors.white,
                            size: isDesktop ? 22 : isTablet ? 24 : 20,
                          ),
                        ),
                        
                        SizedBox(width: isDesktop ? 16 : 16),
                        
                        // Información principal
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre del almacén - más compacto en desktop
                              Text(
                                warehouse.name,
                                style: Get.textTheme.titleLarge?.copyWith(
                                  color: ElegantLightTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isDesktop ? 16 : isTablet ? 18 : 16,
                                ),
                                maxLines: isMobile ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              SizedBox(height: isDesktop ? 4 : 4),
                              
                              // Código con badge elegante - más compacto
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, 
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: ElegantLightTheme.infoGradient,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Código: ${warehouse.code}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isDesktop ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Estado con diseño elegante - más compacto
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 10 : 12, 
                            vertical: isDesktop ? 6 : 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: warehouse.isActive 
                                ? ElegantLightTheme.successGradient
                                : ElegantLightTheme.errorGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: warehouse.isActive 
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                                blurRadius: 3,
                                spreadRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                warehouse.isActive ? Icons.check_circle : Icons.cancel,
                                color: Colors.white,
                                size: isDesktop ? 14 : 14,
                              ),
                              SizedBox(width: isDesktop ? 4 : 4),
                              Text(
                                warehouse.isActive ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    

                    // Estadísticas de inventario (solo para almacenes activos con estadísticas)
                    if (warehouse.isActive && warehouseWithStats.hasStats) ...[
                      SizedBox(height: isDesktop ? 10 : 12),
                      _buildInventoryStats(isDesktop, isTablet, isMobile),
                    ],
                    
                    // Botones de acción elegantes y responsivos
                    SizedBox(height: isDesktop ? 14 : 16),
                    
                    if (isMobile)
                      // Móvil: Ambos botones (Detalles y Editar)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: ElegantLightTheme.glassGradient,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: onTap,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          color: ElegantLightTheme.primaryBlue,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Detalles',
                                          style: TextStyle(
                                            color: ElegantLightTheme.primaryBlue,
                                            fontSize: 12,
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
                          
                          const SizedBox(width: 8),
                          
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: ElegantLightTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: onEdit,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Editar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
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
                      )
                    else
                      // Tablet/Desktop: Dos botones
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: ElegantLightTheme.glassGradient,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: onTap,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isDesktop ? 8 : 10,
                                      horizontal: isDesktop ? 10 : 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          color: ElegantLightTheme.primaryBlue,
                                          size: isDesktop ? 14 : 16,
                                        ),
                                        SizedBox(width: isDesktop ? 6 : 6),
                                        Text(
                                          'Detalles',
                                          style: TextStyle(
                                            color: ElegantLightTheme.primaryBlue,
                                            fontSize: isDesktop ? 11 : 12,
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
                          
                          SizedBox(width: isDesktop ? 12 : 8),
                          
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
                                  onTap: onEdit,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isDesktop ? 8 : 10,
                                      horizontal: isDesktop ? 10 : 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: Colors.white,
                                          size: isDesktop ? 14 : 16,
                                        ),
                                        SizedBox(width: isDesktop ? 6 : 6),
                                        Flexible(
                                          child: Text(
                                            'Editar',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isDesktop ? 11 : 12,
                                              fontWeight: FontWeight.w600,
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
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryStats(bool isDesktop, bool isTablet, bool isMobile) {
    final stats = warehouseWithStats.stats!;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 12 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ElegantLightTheme.primaryBlue.withOpacity(0.05),
            ElegantLightTheme.primaryBlue.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: isDesktop ? 12 : 14,
                ),
              ),
              SizedBox(width: isDesktop ? 6 : 8),
              Text(
                'Inventario',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 11 : 12,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isDesktop ? 8 : 10),
          
          // Estadísticas en grid responsivo
          if (isMobile)
            // Móvil: Una columna
            Column(
              children: [
                _buildStatRow(
                  Icons.inventory_2, 
                  'Productos:', 
                  AppFormatters.formatNumber(stats.totalProducts),
                  ElegantLightTheme.primaryBlue,
                  isDesktop,
                ),
                SizedBox(height: 6),
                _buildStatRow(
                  Icons.attach_money, 
                  'Valor Total:', 
                  AppFormatters.formatCurrency(stats.totalValue),
                  Colors.green,
                  isDesktop,
                ),
              ],
            )
          else
            // Tablet/Desktop: Dos columnas
            Row(
              children: [
                Expanded(
                  child: _buildStatRow(
                    Icons.inventory_2, 
                    'Productos:', 
                    AppFormatters.formatNumber(stats.totalProducts),
                    ElegantLightTheme.primaryBlue,
                    isDesktop,
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 16),
                Expanded(
                  child: _buildStatRow(
                    Icons.attach_money, 
                    'Valor Total:', 
                    AppFormatters.formatCurrency(stats.totalValue),
                    Colors.green,
                    isDesktop,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color, bool isDesktop) {
    return Row(
      children: [
        Icon(
          icon,
          size: isDesktop ? 12 : 14,
          color: color,
        ),
        SizedBox(width: isDesktop ? 4 : 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: isDesktop ? 10 : 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isDesktop ? 10 : 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}