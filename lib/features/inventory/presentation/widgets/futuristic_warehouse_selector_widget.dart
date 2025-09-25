// lib/features/inventory/presentation/widgets/futuristic_warehouse_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/theme/futuristic_notifications.dart';
import '../../domain/entities/warehouse.dart';

class FuturisticWarehouseSelectorWidget extends StatefulWidget {
  final String label;
  final Warehouse? selectedWarehouse;
  final Function(Warehouse) onWarehouseSelected;
  final List<Warehouse> availableWarehouses;
  final bool isRequired;
  final IconData icon;
  final Color iconColor;

  const FuturisticWarehouseSelectorWidget({
    Key? key,
    required this.label,
    this.selectedWarehouse,
    required this.onWarehouseSelected,
    required this.availableWarehouses,
    this.isRequired = false,
    this.icon = Icons.warehouse,
    this.iconColor = Colors.blue,
  }) : super(key: key);

  @override
  State<FuturisticWarehouseSelectorWidget> createState() => _FuturisticWarehouseSelectorWidgetState();
}

class _FuturisticWarehouseSelectorWidgetState extends State<FuturisticWarehouseSelectorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ElegantLightTheme.smoothCurve,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;
        
        // Responsive values
        final labelFontSize = isMobile ? 13.0 : 14.0;
        final spacing = isMobile ? 6.0 : 8.0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.isRequired) ...[
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: spacing),
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: MouseRegion(
                onEnter: (_) => _onHover(true),
                onExit: (_) => _onHover(false),
                child: GestureDetector(
                  onTap: _showWarehouseSelector,
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 14.0 : 16.0),
                    decoration: BoxDecoration(
                      gradient: widget.selectedWarehouse != null
                          ? LinearGradient(
                              colors: [
                                widget.iconColor.withOpacity(0.1),
                                widget.iconColor.withOpacity(0.05),
                              ],
                            )
                          : ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(isMobile ? 10.0 : 12.0),
                      border: Border.all(
                        color: widget.selectedWarehouse != null
                            ? widget.iconColor.withOpacity(0.3)
                            : ElegantLightTheme.textSecondary.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: widget.iconColor.withOpacity(0.2),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 6.0 : 8.0),
                          decoration: BoxDecoration(
                            color: widget.selectedWarehouse != null
                                ? widget.iconColor
                                : ElegantLightTheme.textSecondary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.selectedWarehouse != null
                                    ? widget.iconColor
                                    : ElegantLightTheme.textSecondary).withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: isMobile ? 14.0 : 16.0,
                          ),
                        ),
                        SizedBox(width: isMobile ? 10.0 : 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.selectedWarehouse?.name ?? 'Seleccionar almacén',
                                style: TextStyle(
                                  color: widget.selectedWarehouse != null
                                      ? ElegantLightTheme.textPrimary
                                      : ElegantLightTheme.textSecondary,
                                  fontSize: isMobile ? 13.0 : 14.0,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                              if (widget.selectedWarehouse != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.selectedWarehouse!.code}${widget.selectedWarehouse!.isMainWarehouse ? ' (Principal)' : ''}',
                                  style: TextStyle(
                                    color: widget.selectedWarehouse!.isMainWarehouse
                                        ? Colors.green
                                        : ElegantLightTheme.textTertiary,
                                    fontSize: isMobile ? 11.0 : 12.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: ElegantLightTheme.textSecondary,
                          size: isMobile ? 18.0 : 20.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
            ),
          ],
        );
      },
    );
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _showWarehouseSelector() {
    if (widget.availableWarehouses.isEmpty) {
      FuturisticNotifications.showError(
        'Sin Almacenes',
        'No hay almacenes disponibles para seleccionar',
      );
      return;
    }

    Get.dialog(
      Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isMobile = screenWidth < 600;
            final isTablet = screenWidth >= 600 && screenWidth < 1200;
            
            // Responsive values
            final dialogMargin = isMobile ? 20.0 : isTablet ? 30.0 : 40.0;
            final headerIconSize = isMobile ? 20.0 : 24.0;
            final headerFontSize = isMobile ? 16.0 : isTablet ? 18.0 : 20.0;
            final maxDialogHeight = screenHeight * (isMobile ? 0.8 : 0.7);
            final maxListHeight = maxDialogHeight - 150; // Reserve space for header
            
            return Center(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: maxDialogHeight,
                  maxWidth: isMobile ? screenWidth - (dialogMargin * 2) : 500,
                ),
                margin: EdgeInsets.all(dialogMargin),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.cardGradient,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ElegantLightTheme.textSecondary.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: ElegantLightTheme.elevatedShadow,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isMobile ? 10.0 : 12.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [widget.iconColor, widget.iconColor.withOpacity(0.8)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  widget.icon, 
                                  color: Colors.white, 
                                  size: headerIconSize,
                                ),
                              ),
                              SizedBox(width: isMobile ? 12.0 : 16.0),
                              Expanded(
                                child: Text(
                                  widget.label,
                                  style: TextStyle(
                                    color: ElegantLightTheme.textPrimary,
                                    fontSize: headerFontSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Get.back(),
                                icon: Icon(
                                  Icons.close,
                                  size: isMobile ? 20.0 : 24.0,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 16.0 : 24.0),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: maxListHeight),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: widget.availableWarehouses.map((warehouse) => 
                                    _buildWarehouseOption(warehouse, isMobile, isTablet)
                                  ).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWarehouseOption(Warehouse warehouse, bool isMobile, bool isTablet) {
    final isSelected = widget.selectedWarehouse?.id == warehouse.id;
    
    // Responsive values
    final marginBottom = isMobile ? 6.0 : 8.0;
    final padding = isMobile ? 12.0 : 16.0;
    final iconPadding = isMobile ? 6.0 : 8.0;
    final iconSize = isMobile ? 14.0 : 16.0;
    final spacing = isMobile ? 10.0 : 12.0;
    final titleFontSize = isMobile ? 14.0 : 16.0;
    final codeFontSize = isMobile ? 12.0 : 14.0;
    final descriptionFontSize = isMobile ? 11.0 : 12.0;
    final badgeFontSize = isMobile ? 9.0 : 10.0;
    final checkIconSize = isMobile ? 14.0 : 16.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      child: GestureDetector(
        onTap: () {
          // Immediately close dialog and execute callback
          _closeDialogAndSelectWarehouse(warehouse);
        },
        child: AnimatedContainer(
          duration: ElegantLightTheme.fastAnimation,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [widget.iconColor.withOpacity(0.2), widget.iconColor.withOpacity(0.1)],
                  )
                : ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(isMobile ? 10.0 : 12.0),
            border: Border.all(
              color: isSelected
                  ? widget.iconColor.withOpacity(0.5)
                  : ElegantLightTheme.textSecondary.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  gradient: warehouse.isMainWarehouse
                      ? ElegantLightTheme.successGradient
                      : LinearGradient(
                          colors: [widget.iconColor, widget.iconColor.withOpacity(0.8)],
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  warehouse.isMainWarehouse ? Icons.star : widget.icon,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            warehouse.name,
                            style: TextStyle(
                              color: ElegantLightTheme.textPrimary,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                        if (warehouse.isMainWarehouse) ...[
                          SizedBox(width: spacing / 2),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 6.0 : 8.0, 
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: ElegantLightTheme.successGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Principal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: badgeFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      warehouse.code,
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: codeFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    if (warehouse.description != null && warehouse.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: double.infinity),
                        child: Text(
                          warehouse.description!,
                          style: TextStyle(
                            color: ElegantLightTheme.textTertiary,
                            fontSize: descriptionFontSize,
                          ),
                          maxLines: isMobile ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: spacing / 2),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: checkIconSize,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isProcessing = false;

  void _closeDialogAndSelectWarehouse(Warehouse warehouse) {
    // Prevenir múltiples ejecuciones
    if (_isProcessing) {
      print('⚠️ Ya procesando selección, ignorando tap adicional');
      return;
    }
    
    _isProcessing = true;
    print('🔧 SUPER FAST DIALOG CLOSE for warehouse: ${warehouse.name}');
    
    try {
      // STEP 1: Cerrar dialog INMEDIATAMENTE - ANTES del callback
      if (Navigator.canPop(Get.context!)) {
        Navigator.of(Get.context!).pop();
        print('✅ Dialog closed with Navigator.pop()');
      } else if (Get.isDialogOpen == true) {
        Get.back();
        print('✅ Dialog closed with Get.back()');
      }
      
      // STEP 2: Ejecutar callback DESPUÉS de cerrar
      Future.microtask(() {
        widget.onWarehouseSelected(warehouse);
        print('✅ Callback executed for: ${warehouse.name}');
        
        // Mostrar notificación breve
        FuturisticNotifications.showSuccess(
          'Seleccionado',
          warehouse.name,
          duration: const Duration(milliseconds: 1500),
        );
      });
      
    } catch (e) {
      print('⚠️ Error closing dialog: $e');
      // Fallback: forzar cierre con Get.back()
      Get.back();
    } finally {
      // Reset flag inmediatamente
      Future.delayed(const Duration(milliseconds: 200), () {
        _isProcessing = false;
      });
    }
  }

}