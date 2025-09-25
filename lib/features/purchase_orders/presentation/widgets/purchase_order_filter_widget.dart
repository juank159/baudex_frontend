// lib/features/purchase_orders/presentation/widgets/purchase_order_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/purchase_orders_controller.dart';
import '../../domain/entities/purchase_order.dart';

class PurchaseOrderFilterWidget extends GetView<PurchaseOrdersController> {
  const PurchaseOrderFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth >= 1200;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;
        
        // Padding responsivo
        final padding = isDesktop ? 24.0 : isTablet ? 20.0 : 16.0;
        
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            boxShadow: ElegantLightTheme.elevatedShadow,
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con número de filtros activos
              _buildResponsiveFilterHeader(screenWidth),
              
              SizedBox(height: padding),
              
              // Grid de filtros responsivo
              _buildResponsiveFiltersGrid(screenWidth),
              
              SizedBox(height: padding),
              
              // Botones de acción responsivos
              _buildResponsiveActionButtons(screenWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsiveFilterHeader(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    
    // Tamaños responsivos
    final iconSize = isDesktop ? 22.0 : isTablet ? 20.0 : 18.0;
    final titleSize = isDesktop ? 18.0 : isTablet ? 16.0 : 14.0;
    final badgeSize = isDesktop ? 12.0 : isTablet ? 11.0 : 10.0;
    final buttonSize = isDesktop ? 14.0 : isTablet ? 12.0 : 11.0;
    final spacing = isDesktop ? 12.0 : isTablet ? 10.0 : 8.0;
    
    return Obx(() {
      final filtersInfo = controller.activeFiltersCount;
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: spacing / 2,
        runSpacing: spacing / 2,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 8 : 6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  Icons.filter_list,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(width: spacing),
              Text(
                'Filtros',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (filtersInfo['count'] > 0) 
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.infoGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Text(
                '${filtersInfo['count']} activo${filtersInfo['count'] > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: badgeSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (filtersInfo['count'] > 0)
            Container(
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: controller.clearFilters,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing,
                      vertical: 6,
                    ),
                    child: Text(
                      screenWidth < 500 ? 'Limpiar' : 'Limpiar todo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: buttonSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildResponsiveFiltersGrid(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isMobile = screenWidth < 600;
    
    final spacing = isDesktop ? 16.0 : isTablet ? 14.0 : 12.0;
    
    if (isMobile) {
      // En móvil: Layout vertical (1 columna)
      return Column(
        children: [
          _buildResponsiveStatusFilter(screenWidth),
          SizedBox(height: spacing),
          _buildResponsivePriorityFilter(screenWidth),
          SizedBox(height: spacing),
          _buildResponsiveStartDateFilter(screenWidth),
          SizedBox(height: spacing),
          _buildResponsiveEndDateFilter(screenWidth),
          SizedBox(height: spacing),
          _buildResponsiveSwitchFilters(screenWidth),
        ],
      );
    } else {
      // En tablet/desktop: Layout en filas
      return Column(
        children: [
          // Primera fila: Estado y Prioridad
          Row(
            children: [
              Expanded(child: _buildResponsiveStatusFilter(screenWidth)),
              SizedBox(width: spacing),
              Expanded(child: _buildResponsivePriorityFilter(screenWidth)),
            ],
          ),
          
          SizedBox(height: spacing),
          
          // Segunda fila: Fechas
          Row(
            children: [
              Expanded(child: _buildResponsiveStartDateFilter(screenWidth)),
              SizedBox(width: spacing),
              Expanded(child: _buildResponsiveEndDateFilter(screenWidth)),
            ],
          ),
          
          SizedBox(height: spacing),
          
          // Tercera fila: Switches
          _buildResponsiveSwitchFilters(screenWidth),
        ],
      );
    }
  }

  Widget _buildResponsiveStatusFilter(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isMobile = screenWidth < 600;
    
    // Tamaños responsivos
    final labelSize = isDesktop ? 14.0 : isTablet ? 13.0 : 12.0;
    final textSize = isDesktop ? 14.0 : isTablet ? 13.0 : 12.0;
    final iconSize = isDesktop ? 18.0 : isTablet ? 16.0 : 14.0;
    final padding = isDesktop ? 16.0 : isTablet ? 14.0 : 12.0;
    final spacing = isDesktop ? 8.0 : isTablet ? 6.0 : 4.0;
    
    // Textos responsivos
    final allStatesText = isMobile ? 'Todos' : isTablet ? 'Todos estados' : 'Todos los estados';
    
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado',
          style: TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing),
        Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<PurchaseOrderStatus?>(
            value: controller.statusFilter.value,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding * 0.75,
              ),
            ),
            hint: Text(
              allStatesText,
              style: TextStyle(
                fontSize: textSize,
                color: ElegantLightTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            style: TextStyle(
              fontSize: textSize,
              color: ElegantLightTheme.textPrimary,
            ),
            isExpanded: true,
            items: [
              DropdownMenuItem<PurchaseOrderStatus?>(
                value: null,
                child: Text(
                  allStatesText,
                  style: TextStyle(fontSize: textSize),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...PurchaseOrderStatus.values.map((status) => 
                DropdownMenuItem<PurchaseOrderStatus?>(
                  value: status,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: iconSize,
                        color: _getStatusColor(status),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(fontSize: textSize),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              controller.statusFilter.value = value;
            },
          ),
        ),
      ],
    ));
  }

  Widget _buildResponsivePriorityFilter(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isMobile = screenWidth < 600;
    
    // Tamaños responsivos
    final labelSize = isDesktop ? 14.0 : isTablet ? 13.0 : 12.0;
    final textSize = isDesktop ? 14.0 : isTablet ? 13.0 : 12.0;
    final iconSize = isDesktop ? 18.0 : isTablet ? 16.0 : 14.0;
    final padding = isDesktop ? 16.0 : isTablet ? 14.0 : 12.0;
    final spacing = isDesktop ? 8.0 : isTablet ? 6.0 : 4.0;
    
    // Textos responsivos
    final allPrioritiesText = isMobile ? 'Todas' : isTablet ? 'Todas prioridades' : 'Todas las prioridades';
    
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridad',
          style: TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing),
        Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<PurchaseOrderPriority?>(
            value: controller.priorityFilter.value,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding * 0.75,
              ),
            ),
            hint: Text(
              allPrioritiesText,
              style: TextStyle(
                fontSize: textSize,
                color: ElegantLightTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            style: TextStyle(
              fontSize: textSize,
              color: ElegantLightTheme.textPrimary,
            ),
            isExpanded: true,
            items: [
              DropdownMenuItem<PurchaseOrderPriority?>(
                value: null,
                child: Text(
                  allPrioritiesText,
                  style: TextStyle(fontSize: textSize),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...PurchaseOrderPriority.values.map((priority) => 
                DropdownMenuItem<PurchaseOrderPriority?>(
                  value: priority,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        size: iconSize,
                        color: _getPriorityColor(priority),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: Text(
                          _getPriorityText(priority),
                          style: TextStyle(fontSize: textSize),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              controller.priorityFilter.value = value;
            },
          ),
        ),
      ],
    ));
  }

  Widget _buildResponsiveStartDateFilter(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isMobile = screenWidth < 600;
    
    // Tamaños responsivos
    final labelSize = isDesktop ? 14.0 : isTablet ? 13.0 : 12.0;
    final textSize = isDesktop ? 14.0 : isTablet ? 13.0 : 12.0;
    final iconSize = isDesktop ? 18.0 : isTablet ? 16.0 : 14.0;
    final padding = isDesktop ? 16.0 : isTablet ? 14.0 : 12.0;
    final spacing = isDesktop ? 8.0 : isTablet ? 6.0 : 4.0;
    
    // Textos responsivos
    final placeholderText = isMobile ? 'Desde' : isTablet ? 'Fecha desde' : 'Seleccionar fecha desde';
    final labelText = isMobile ? 'Desde' : 'Fecha desde';
    
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _selectStartDate(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantLightTheme.textSecondary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: iconSize,
                    color: controller.startDateFilter.value != null 
                        ? ElegantLightTheme.primaryBlue
                        : ElegantLightTheme.textSecondary,
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      controller.startDateFilter.value != null
                          ? AppFormatters.formatDate(controller.startDateFilter.value!)
                          : placeholderText,
                      style: TextStyle(
                        fontSize: textSize,
                        color: controller.startDateFilter.value != null
                            ? ElegantLightTheme.textPrimary
                            : ElegantLightTheme.textSecondary,
                        fontWeight: controller.startDateFilter.value != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (controller.startDateFilter.value != null)
                    GestureDetector(
                      onTap: () => controller.startDateFilter.value = null,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: ElegantLightTheme.errorGradient.colors.first,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.clear,
                          size: iconSize * 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildResponsiveEndDateFilter(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isMobile = screenWidth < 600;
    
    // Tamaños responsivos
    final labelSize = isDesktop ? 14.0 : isTablet ? 13.0 : 12.0;
    final textSize = isDesktop ? 14.0 : isTablet ? 13.0 : 12.0;
    final iconSize = isDesktop ? 18.0 : isTablet ? 16.0 : 14.0;
    final padding = isDesktop ? 16.0 : isTablet ? 14.0 : 12.0;
    final spacing = isDesktop ? 8.0 : isTablet ? 6.0 : 4.0;
    
    // Textos responsivos
    final placeholderText = isMobile ? 'Hasta' : isTablet ? 'Fecha hasta' : 'Seleccionar fecha hasta';
    final labelText = isMobile ? 'Hasta' : 'Fecha hasta';
    
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _selectEndDate(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantLightTheme.textSecondary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: iconSize,
                    color: controller.endDateFilter.value != null 
                        ? ElegantLightTheme.primaryBlue
                        : ElegantLightTheme.textSecondary,
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      controller.endDateFilter.value != null
                          ? AppFormatters.formatDate(controller.endDateFilter.value!)
                          : placeholderText,
                      style: TextStyle(
                        fontSize: textSize,
                        color: controller.endDateFilter.value != null
                            ? ElegantLightTheme.textPrimary
                            : ElegantLightTheme.textSecondary,
                        fontWeight: controller.endDateFilter.value != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (controller.endDateFilter.value != null)
                    GestureDetector(
                      onTap: () => controller.endDateFilter.value = null,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: ElegantLightTheme.errorGradient.colors.first,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.clear,
                          size: iconSize * 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildResponsiveSwitchFilters(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isMobile = screenWidth < 600;
    
    // Tamaños responsivos
    final titleSize = isDesktop ? 14.0 : isTablet ? 13.0 : 12.0;
    final subtitleSize = isDesktop ? 12.0 : isTablet ? 11.0 : 10.0;
    final spacing = isDesktop ? 12.0 : isTablet ? 10.0 : 8.0;
    
    // Textos responsivos
    final overdueTitle = isMobile ? 'Órdenes vencidas' : 'Solo órdenes vencidas';
    final overdueSubtitle = isMobile ? 'Con fecha vencida' : isTablet ? 'Con fecha de entrega vencida' : 'Mostrar únicamente órdenes con fecha de entrega vencida';
    
    final pendingTitle = isMobile ? 'Pendientes aprobación' : 'Solo pendientes de aprobación';
    final pendingSubtitle = isMobile ? 'Requieren aprobación' : isTablet ? 'Que requieren aprobación' : 'Mostrar únicamente órdenes que requieren aprobación';
    
    return Column(
      children: [
        Obx(() => Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: controller.showOverdueOnly.value 
                  ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                  : ElegantLightTheme.textSecondary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: SwitchListTile(
            title: Text(
              overdueTitle,
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              overdueSubtitle,
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: subtitleSize,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: isMobile ? 1 : 2,
            ),
            value: controller.showOverdueOnly.value,
            onChanged: (value) {
              controller.showOverdueOnly.value = value;
            },
            activeColor: ElegantLightTheme.primaryBlue,
            contentPadding: EdgeInsets.symmetric(
              horizontal: spacing,
              vertical: spacing / 2,
            ),
          ),
        )),
        
        SizedBox(height: spacing),
        
        Obx(() => Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: controller.showPendingApprovalOnly.value 
                  ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                  : ElegantLightTheme.textSecondary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: SwitchListTile(
            title: Text(
              pendingTitle,
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              pendingSubtitle,
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: subtitleSize,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: isMobile ? 1 : 2,
            ),
            value: controller.showPendingApprovalOnly.value,
            onChanged: (value) {
              controller.showPendingApprovalOnly.value = value;
            },
            activeColor: ElegantLightTheme.primaryBlue,
            contentPadding: EdgeInsets.symmetric(
              horizontal: spacing,
              vertical: spacing / 2,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildResponsiveActionButtons(double screenWidth) {
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isMobile = screenWidth < 600;
    
    final buttonHeight = isDesktop ? 50.0 : isTablet ? 45.0 : 42.0;
    final fontSize = isDesktop ? 16.0 : isTablet ? 14.0 : 13.0;
    final spacing = isDesktop ? 16.0 : isTablet ? 14.0 : 12.0;
    final iconSize = isDesktop ? 20.0 : isTablet ? 18.0 : 16.0;
    
    // Textos responsivos
    final applyText = isMobile ? 'Aplicar' : 'Aplicar filtros';
    final cancelText = 'Cancelar';
    
    if (isMobile) {
      // En móvil: Botones verticales
      return Column(
        children: [
          _buildResponsiveButton(
            text: applyText,
            icon: Icons.check,
            onPressed: () {
              controller.applyFilters();
              controller.toggleFilters();
            },
            gradient: ElegantLightTheme.primaryGradient,
            height: buttonHeight,
            fontSize: fontSize,
            iconSize: iconSize,
          ),
          SizedBox(height: spacing / 2),
          _buildResponsiveButton(
            text: cancelText,
            icon: Icons.close,
            onPressed: controller.toggleFilters,
            gradient: ElegantLightTheme.glassGradient,
            textColor: ElegantLightTheme.textSecondary,
            height: buttonHeight,
            fontSize: fontSize,
            iconSize: iconSize,
            isOutline: true,
          ),
        ],
      );
    } else {
      // En tablet/desktop: Botones horizontales
      return Row(
        children: [
          Expanded(
            child: _buildResponsiveButton(
              text: applyText,
              icon: Icons.check,
              onPressed: () {
                controller.applyFilters();
                controller.toggleFilters();
              },
              gradient: ElegantLightTheme.primaryGradient,
              height: buttonHeight,
              fontSize: fontSize,
              iconSize: iconSize,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _buildResponsiveButton(
              text: cancelText,
              icon: Icons.close,
              onPressed: controller.toggleFilters,
              gradient: ElegantLightTheme.glassGradient,
              textColor: ElegantLightTheme.textSecondary,
              height: buttonHeight,
              fontSize: fontSize,
              iconSize: iconSize,
              isOutline: true,
            ),
          ),
        ],
      );
    }
  }
  
  Widget _buildResponsiveButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required LinearGradient gradient,
    required double height,
    required double fontSize,
    required double iconSize,
    Color textColor = Colors.white,
    bool isOutline = false,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        border: isOutline ? Border.all(
          color: ElegantLightTheme.textSecondary.withOpacity(0.3),
          width: 1,
        ) : null,
        boxShadow: !isOutline ? [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ] : null,
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
                  color: textColor,
                  size: iconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods para fechas
  void _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: Get.context!,
      initialDate: controller.startDateFilter.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: controller.endDateFilter.value ?? DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      controller.startDateFilter.value = selectedDate;
    }
  }

  void _selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: Get.context!,
      initialDate: controller.endDateFilter.value ?? DateTime.now(),
      firstDate: controller.startDateFilter.value ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      controller.endDateFilter.value = selectedDate;
    }
  }

  // Helper methods para obtener colores, iconos y textos
  Color _getStatusColor(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return Colors.grey;
      case PurchaseOrderStatus.pending:
        return Colors.orange;
      case PurchaseOrderStatus.approved:
        return Colors.blue;
      case PurchaseOrderStatus.rejected:
        return Colors.red;
      case PurchaseOrderStatus.sent:
        return Colors.purple;
      case PurchaseOrderStatus.partiallyReceived:
        return Colors.amber;
      case PurchaseOrderStatus.received:
        return Colors.green;
      case PurchaseOrderStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return Icons.edit_note;
      case PurchaseOrderStatus.pending:
        return Icons.schedule;
      case PurchaseOrderStatus.approved:
        return Icons.check_circle;
      case PurchaseOrderStatus.rejected:
        return Icons.cancel;
      case PurchaseOrderStatus.sent:
        return Icons.send;
      case PurchaseOrderStatus.partiallyReceived:
        return Icons.pending_actions;
      case PurchaseOrderStatus.received:
        return Icons.inventory;
      case PurchaseOrderStatus.cancelled:
        return Icons.block;
    }
  }

  String _getStatusText(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return 'Borrador';
      case PurchaseOrderStatus.pending:
        return 'Pendiente';
      case PurchaseOrderStatus.approved:
        return 'Aprobada';
      case PurchaseOrderStatus.rejected:
        return 'Rechazada';
      case PurchaseOrderStatus.sent:
        return 'Enviada';
      case PurchaseOrderStatus.partiallyReceived:
        return 'Parcialmente Recibida';
      case PurchaseOrderStatus.received:
        return 'Recibida';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelada';
    }
  }

  Color _getPriorityColor(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return Colors.green;
      case PurchaseOrderPriority.medium:
        return Colors.orange;
      case PurchaseOrderPriority.high:
        return Colors.red;
      case PurchaseOrderPriority.urgent:
        return Colors.deepPurple;
    }
  }

  IconData _getPriorityIcon(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return Icons.keyboard_arrow_down;
      case PurchaseOrderPriority.medium:
        return Icons.remove;
      case PurchaseOrderPriority.high:
        return Icons.keyboard_arrow_up;
      case PurchaseOrderPriority.urgent:
        return Icons.priority_high;
    }
  }

  String _getPriorityText(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return 'Baja';
      case PurchaseOrderPriority.medium:
        return 'Media';
      case PurchaseOrderPriority.high:
        return 'Alta';
      case PurchaseOrderPriority.urgent:
        return 'Urgente';
    }
  }
}