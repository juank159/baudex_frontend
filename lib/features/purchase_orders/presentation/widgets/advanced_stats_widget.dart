// lib/features/purchase_orders/presentation/widgets/advanced_stats_widget.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/animations/stats_animations.dart';
import '../../domain/entities/purchase_order.dart';

class AdvancedStatsWidget extends StatefulWidget {
  final PurchaseOrder order;

  const AdvancedStatsWidget({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<AdvancedStatsWidget> createState() => _AdvancedStatsWidgetState();
}

class _AdvancedStatsWidgetState extends State<AdvancedStatsWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controllers = List.generate(
      4,
      (index) => AnimationController(
        duration: Duration(milliseconds: 1000 + (index * 200)),
        vsync: this,
      ),
    );
    
    _animations = _controllers.map((controller) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: controller,
          curve: ElegantLightTheme.elasticCurve,
        ))).toList();
    
    // Animar secuencialmente
    _animateCharts();
  }

  void _animateCharts() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 150));
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Tamaños responsive para el análisis
    double titleFontSize = screenWidth >= 1200 ? 20 : screenWidth >= 800 ? 18 : 16;
    double iconContainerSize = screenWidth >= 1200 ? 24 : screenWidth >= 800 ? 22 : 20;
    double iconPadding = screenWidth >= 1200 ? 12 : screenWidth >= 800 ? 10 : 8;
    
    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: iconContainerSize,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  'Análisis Avanzado',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Gráfico circular de progreso responsive
          _buildProgressCircle(),
          const SizedBox(height: 24),
          
          // Métricas de rendimiento responsive
          _buildPerformanceMetrics(),
          const SizedBox(height: 24),
          
          // Distribución de costos
          _buildCostDistribution(),
          const SizedBox(height: 24),
          
          // Timeline de eficiencia
          _buildEfficiencyTimeline(),
        ],
      ),
    );
  }

  Widget _buildProgressCircle() {
    // Calcular cantidades por unidades, no por items
    final totalQuantity = widget.order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final receivedQuantity = widget.order.items.fold<int>(0, (sum, item) => sum + (item.receivedQuantity ?? 0));
    final damagedQuantity = widget.order.items.fold<int>(0, (sum, item) => sum + (item.damagedQuantity ?? 0));
    final missingQuantity = widget.order.items.fold<int>(0, (sum, item) => sum + (item.missingQuantity ?? 0));
    final pendingQuantity = totalQuantity - receivedQuantity - damagedQuantity - missingQuantity;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Tamaños responsive
        double containerHeight = screenWidth >= 1200 ? 450 : screenWidth >= 800 ? 420 : 380;
        double donutSize = screenWidth >= 1200 ? 320 : screenWidth >= 800 ? 280 : 240;
        double spacing = screenWidth >= 1200 ? 40 : screenWidth >= 800 ? 32 : 24;
        
        return SizedBox(
          height: containerHeight,
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth >= 1200 ? 1200 : double.infinity,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth >= 1200 ? 48 : screenWidth >= 800 ? 40 : 16,
                vertical: 24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Gráfico 3D personalizado con iconos
                  Expanded(
                    flex: screenWidth < 600 ? 1 : 2,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _animations[0],
                        builder: (context, child) {
                          return _True3DDonutChart(
                            receivedQuantity: receivedQuantity,
                            damagedQuantity: damagedQuantity,
                            missingQuantity: missingQuantity,
                            pendingQuantity: pendingQuantity,
                            totalQuantity: totalQuantity,
                            size: donutSize,
                            animationValue: _animations[0].value,
                          );
                        },
                      ),
                    ),
                  ),
                  
                  SizedBox(width: spacing),
                  
                  // Leyenda mejorada
                  Expanded(
                    flex: screenWidth < 600 ? 1 : 3,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _build3DLegendItem(
                            'Recibidas',
                            '$receivedQuantity unidades (${totalQuantity > 0 ? ((receivedQuantity / totalQuantity) * 100).toStringAsFixed(1) : '0'}%)',
                            Icons.check_circle,
                            const Color(0xFF10B981),
                            screenWidth,
                          ),
                          SizedBox(height: screenWidth < 600 ? 12 : 16),
                          _build3DLegendItem(
                            'Dañadas',
                            '$damagedQuantity unidades (${totalQuantity > 0 ? ((damagedQuantity / totalQuantity) * 100).toStringAsFixed(1) : '0'}%)',
                            Icons.warning_amber,
                            const Color(0xFFF59E0B),
                            screenWidth,
                          ),
                          SizedBox(height: screenWidth < 600 ? 12 : 16),
                          _build3DLegendItem(
                            'Faltantes',
                            '$missingQuantity unidades (${totalQuantity > 0 ? ((missingQuantity / totalQuantity) * 100).toStringAsFixed(1) : '0'}%)',
                            Icons.remove_circle,
                            const Color(0xFFEF4444),
                            screenWidth,
                          ),
                          SizedBox(height: screenWidth < 600 ? 12 : 16),
                          _build3DLegendItem(
                            'Pendientes',
                            '$pendingQuantity unidades (${totalQuantity > 0 ? ((pendingQuantity / totalQuantity) * 100).toStringAsFixed(1) : '0'}%)',
                            Icons.schedule,
                            const Color(0xFF8B5CF6),
                            screenWidth,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _build3DLegendItem(String label, String value, IconData icon, Color color, double screenWidth) {
    // Tamaños responsive ultra compactos
    double containerHeight = screenWidth >= 1200 ? 50 : screenWidth >= 800 ? 45 : 40;
    double iconSize = screenWidth >= 1200 ? 18 : screenWidth >= 800 ? 16 : 14;
    double labelFontSize = screenWidth >= 1200 ? 11 : screenWidth >= 800 ? 10 : 9;
    double valueFontSize = screenWidth >= 1200 ? 9 : screenWidth >= 800 ? 8 : 7;
    double padding = screenWidth >= 1200 ? 6 : screenWidth >= 800 ? 5 : 4;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: ElegantLightTheme.elasticCurve,
      builder: (context, animatedValue, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - animatedValue), 0),
          child: Opacity(
            opacity: animatedValue.clamp(0.0, 1.0),
            child: Container(
              height: containerHeight,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icono 3D con múltiples capas de sombra
                  Container(
                    width: iconSize + 16,
                    height: iconSize + 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          color.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular((iconSize + 16) / 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          offset: const Offset(0, 8),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  
                  SizedBox(width: screenWidth >= 800 ? 8 : 6),
                  
                  // Texto con efecto de profundidad
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: ElegantLightTheme.textPrimary,
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: color.withValues(alpha: 0.3),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1),
                        Text(
                          value,
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: valueFontSize,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceMetrics() {
    final efficiency = _calculateEfficiency();
    final velocity = _calculateVelocity();
    final accuracy = _calculateAccuracy();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // SIEMPRE mostrar en fila (3 columnas) para todas las pantallas
        return AnimatedBuilder(
          animation: _animations[1],
          builder: (context, child) {
            return Row(
              children: [
                Expanded(
                  child: StatsAnimations.floatingParticle(
                    duration: const Duration(seconds: 8),
                    amplitude: 2.0,
                    repeat: true,
                    child: _buildMetricGauge(
                      'Eficiencia',
                      efficiency,
                      Icons.speed,
                      ElegantLightTheme.successGradient,
                      _animations[1].value,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth >= 800 ? 16 : 8),
                Expanded(
                  child: StatsAnimations.floatingParticle(
                    duration: const Duration(seconds: 10),
                    amplitude: 1.5,
                    repeat: true,
                    child: _buildMetricGauge(
                      'Velocidad',
                      velocity,
                      Icons.timer,
                      ElegantLightTheme.infoGradient,
                      _animations[1].value,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth >= 800 ? 16 : 8),
                Expanded(
                  child: StatsAnimations.floatingParticle(
                    duration: const Duration(seconds: 12),
                    amplitude: 1.0,
                    repeat: true,
                    child: _buildMetricGauge(
                      'Precisión',
                      accuracy,
                      Icons.gps_fixed,
                      ElegantLightTheme.warningGradient,
                      _animations[1].value,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetricGauge(
    String label,
    double value,
    IconData icon,
    LinearGradient gradient,
    double animationValue,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Tamaños responsive para las cards de métricas
        double padding = screenWidth >= 1200 ? 16 : screenWidth >= 800 ? 14 : 12;
        double iconSize = screenWidth >= 1200 ? 24 : screenWidth >= 800 ? 22 : 20;
        double labelFontSize = screenWidth >= 1200 ? 12 : screenWidth >= 800 ? 11 : 10;
        double circleSize = screenWidth >= 1200 ? 60 : screenWidth >= 800 ? 55 : 50;
        double percentFontSize = screenWidth >= 1200 ? 14 : screenWidth >= 800 ? 13 : 12;
        double strokeWidth = screenWidth >= 1200 ? 6 : screenWidth >= 800 ? 5 : 4;
        
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradient.colors.first.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: gradient.colors.first,
                size: iconSize,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: CircularProgressIndicator(
                      value: value * animationValue,
                      strokeWidth: strokeWidth,
                      backgroundColor: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(gradient.colors.first),
                    ),
                  ),
                  Text(
                    '${(value * 100 * animationValue).toInt()}%',
                    style: TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: percentFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCostDistribution() {
    return AnimatedBuilder(
      animation: _animations[2],
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distribución de Costos',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...widget.order.items.take(3).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final percentage = (item.totalAmount / widget.order.totalAmount);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: const TextStyle(
                                color: ElegantLightTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(percentage * 100).toInt()}%',
                            style: const TextStyle(
                              color: ElegantLightTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Barra horizontal mejorada estilo estadísticas
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: percentage),
                          duration: Duration(milliseconds: 1000 + (index * 200)),
                          curve: Curves.easeOutExpo,
                          builder: (context, animatedValue, child) {
                            return Row(
                              children: [
                                // Parte llena con destello
                                if (animatedValue > 0)
                                  Flexible(
                                    flex: (animatedValue * 100).round(),
                                    child: Container(
                                      height: 10,
                                      margin: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        gradient: ElegantLightTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: Stack(
                                          children: [
                                            // Efecto de destello cuando está casi completa
                                            if (animatedValue >= percentage * 0.98 && percentage > 0.1)
                                              _ProgressShimmerEffect(
                                                borderRadius: 5,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                // Parte vacía
                                if (animatedValue < 1.0)
                                  Flexible(
                                    flex: ((1.0 - animatedValue) * 100).round(),
                                    child: Container(
                                      height: 10,
                                      margin: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEfficiencyTimeline() {
    return AnimatedBuilder(
      animation: _animations[3],
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            
            // Tamaños responsive
            double padding = screenWidth >= 1200 ? 20 : screenWidth >= 800 ? 16 : 12;
            double titleFontSize = screenWidth >= 1200 ? 16 : screenWidth >= 800 ? 15 : 14;
            double itemSpacing = screenWidth >= 1200 ? 16 : screenWidth >= 800 ? 12 : 8;
            double productFontSize = screenWidth >= 1200 ? 14 : screenWidth >= 800 ? 13 : 12;
            double percentageFontSize = screenWidth >= 1200 ? 12 : screenWidth >= 800 ? 11 : 10;
            double progressHeight = screenWidth >= 1200 ? 12 : screenWidth >= 800 ? 10 : 8;
            
            return Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progreso de Recepción por Producto',
                    style: TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: itemSpacing),
                  
                  // Lista de productos con progreso real
                  ...widget.order.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final receivedQty = item.receivedQuantity ?? 0;
                    final totalQty = item.quantity;
                    final progressPercentage = totalQty > 0 ? receivedQty / totalQty : 0.0;
                    
                    // Determinar gradient basado en progreso
                    LinearGradient gradient;
                    if (progressPercentage >= 1.0) {
                      gradient = ElegantLightTheme.successGradient; // Verde - Completo
                    } else if (progressPercentage > 0.0) {
                      gradient = ElegantLightTheme.warningGradient; // Amarillo - Parcial
                    } else {
                      gradient = ElegantLightTheme.infoGradient; // Azul - Pendiente
                    }
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: itemSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fila superior: Nombre del producto y porcentaje
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Nombre del producto (responsive)
                              Expanded(
                                flex: screenWidth < 600 ? 2 : 3,
                                child: Text(
                                  item.productName,
                                  style: TextStyle(
                                    color: ElegantLightTheme.textPrimary,
                                    fontSize: productFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              
                              SizedBox(width: screenWidth < 600 ? 4 : 8),
                              
                              // Cantidad y porcentaje (responsive)
                              Expanded(
                                flex: 1,
                                child: Text(
                                  screenWidth < 600 
                                    ? '${(progressPercentage * 100).toInt()}%'
                                    : '$receivedQty/$totalQty (${(progressPercentage * 100).toInt()}%)',
                                  style: TextStyle(
                                    color: ElegantLightTheme.textSecondary,
                                    fontSize: percentageFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          // Fila inferior: Cantidad en móvil (si no se mostró arriba)
                          if (screenWidth < 600) ...[
                            const SizedBox(height: 2),
                            Text(
                              '$receivedQty de $totalQty recibidos',
                              style: TextStyle(
                                color: ElegantLightTheme.textTertiary,
                                fontSize: percentageFontSize - 1,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 8),
                          
                          // Barra de progreso mejorada
                          Container(
                            height: progressHeight,
                            decoration: BoxDecoration(
                              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(progressHeight / 2),
                              border: Border.all(
                                color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: progressPercentage),
                              duration: Duration(milliseconds: 1000 + (index * 200)),
                              curve: Curves.easeOutExpo,
                              builder: (context, animatedValue, child) {
                                return Row(
                                  children: [
                                    // Parte llena con destello
                                    if (animatedValue > 0)
                                      Flexible(
                                        flex: (animatedValue * 100).round(),
                                        child: Container(
                                          height: progressHeight - 2,
                                          margin: const EdgeInsets.all(1),
                                          decoration: BoxDecoration(
                                            gradient: gradient,
                                            borderRadius: BorderRadius.circular((progressHeight - 2) / 2),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular((progressHeight - 2) / 2),
                                            child: Stack(
                                              children: [
                                                // Efecto de destello cuando está casi completa
                                                if (animatedValue >= progressPercentage * 0.98 && progressPercentage > 0.1)
                                                  _ProgressShimmerEffect(
                                                    borderRadius: (progressHeight - 2) / 2,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Parte vacía
                                    if (animatedValue < 1.0)
                                      Flexible(
                                        flex: ((1.0 - animatedValue) * 100).round(),
                                        child: Container(
                                          height: progressHeight - 2,
                                          margin: const EdgeInsets.all(1),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular((progressHeight - 2) / 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  double _calculateEfficiency() {
    final totalItems = widget.order.items.length;
    final completedItems = widget.order.items.where((item) => item.isFullyReceived).length;
    return totalItems > 0 ? completedItems / totalItems : 0.0;
  }

  double _calculateVelocity() {
    // Simulación basada en el estado de la orden
    switch (widget.order.status) {
      case PurchaseOrderStatus.received:
        return 0.95;
      case PurchaseOrderStatus.partiallyReceived:
        return 0.85;
      case PurchaseOrderStatus.sent:
        return 0.75;
      case PurchaseOrderStatus.approved:
        return 0.60;
      case PurchaseOrderStatus.pending:
        return 0.40;
      case PurchaseOrderStatus.draft:
      case PurchaseOrderStatus.rejected:
      case PurchaseOrderStatus.cancelled:
        return 0.20;
    }
  }

  double _calculateAccuracy() {
    final totalQuantity = widget.order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final receivedQuantity = widget.order.items.fold<int>(0, (sum, item) => sum + (item.receivedQuantity ?? 0));
    return totalQuantity > 0 ? receivedQuantity / totalQuantity : 0.0;
  }
}

// Widget que replica EXACTAMENTE la gráfica de referencia grafico_dona.jpeg
class _True3DDonutChart extends StatelessWidget {
  final int receivedQuantity;
  final int damagedQuantity;
  final int missingQuantity;
  final int pendingQuantity;
  final int totalQuantity;
  final double size;
  final double animationValue;

  const _True3DDonutChart({
    required this.receivedQuantity,
    required this.damagedQuantity,
    required this.missingQuantity,
    required this.pendingQuantity,
    required this.totalQuantity,
    required this.size,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          
          // Gráfico 3D principal
          Positioned.fill(
            child: CustomPaint(
              painter: _ExactReferencePainter(
                receivedQuantity: receivedQuantity,
                damagedQuantity: damagedQuantity,
                missingQuantity: missingQuantity,
                pendingQuantity: pendingQuantity,
                totalQuantity: totalQuantity,
                animationValue: animationValue,
              ),
            ),
          ),
          
        ],
      ),
    );
  }


}

// CustomPainter que replica EXACTAMENTE grafico_dona.jpeg
class _ExactReferencePainter extends CustomPainter {
  final int receivedQuantity;
  final int damagedQuantity;
  final int missingQuantity;
  final int pendingQuantity;
  final int totalQuantity;
  final double animationValue;

  _ExactReferencePainter({
    required this.receivedQuantity,
    required this.damagedQuantity,
    required this.missingQuantity,
    required this.pendingQuantity,
    required this.totalQuantity,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalQuantity == 0) return;

    // Configuración para dona más esférica como grafico_dona.jpeg
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2.8;
    final innerRadius = outerRadius * 0.45; // Agujero un poco más pequeño
    final depth3D = outerRadius * 0.4; // Más profundidad para efecto esférico
    
    // Segmentos con colores por estado
    final segments = <({int quantity, Color color})>[];
    
    if (receivedQuantity > 0) {
      segments.add((quantity: receivedQuantity, color: const Color(0xFF10B981))); // Verde
    }
    if (damagedQuantity > 0) {
      segments.add((quantity: damagedQuantity, color: const Color(0xFFF59E0B))); // Naranja
    }
    if (missingQuantity > 0) {
      segments.add((quantity: missingQuantity, color: const Color(0xFFEF4444))); // Rojo
    }
    if (pendingQuantity > 0) {
      segments.add((quantity: pendingQuantity, color: const Color(0xFF3B82F6))); // Azul
    }

    if (segments.isEmpty) return;

    // Dibujar en orden: traseros primero, frontales último
    double currentAngle = -math.pi / 2;
    const gapAngle = 0.1;
    final totalGaps = segments.length * gapAngle;
    final availableAngle = (2 * math.pi) - totalGaps;
    
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final percentage = segment.quantity / totalQuantity;
      final segmentAngle = (availableAngle * percentage) * animationValue;
      
      if (segmentAngle > 0.01) {
        _drawDonutSegment3D(
          canvas,
          center,
          outerRadius,
          innerRadius,
          currentAngle,
          segmentAngle,
          segment.color,
          depth3D,
        );
      }
      
      currentAngle += segmentAngle + gapAngle;
    }
  }

  void _drawDonutSegment3D(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
    double depth,
  ) {
    // Offset 3D hacia atrás y arriba como en la referencia
    final depthOffset = Offset(-depth * 0.6, -depth * 0.8);
    
    // 1. Superficie trasera (base)
    _drawDonutSegment(canvas, 
      Offset(center.dx + depthOffset.dx, center.dy + depthOffset.dy),
      outerRadius, innerRadius, startAngle, sweepAngle, 
      _darkenColor(color, 0.4));
    
    // 2. Paredes laterales 3D
    _drawSegmentWalls(canvas, center, outerRadius, innerRadius, 
      startAngle, sweepAngle, color, depthOffset);
    
    // 3. Superficie frontal (la más visible)
    _drawDonutSegment(canvas, center, outerRadius, innerRadius, 
      startAngle, sweepAngle, _lightenColor(color, 0.1));
  }

  void _drawDonutSegment(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
  ) {
    // Gradiente radial para efecto más esférico
    final gradient = RadialGradient(
      center: Alignment(-0.3, -0.3), // Luz desde arriba izquierda
      radius: 1.0,
      colors: [
        _lightenColor(color, 0.3),
        color,
        _darkenColor(color, 0.2),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCenter(
        center: center,
        width: outerRadius * 2,
        height: outerRadius * 2,
      ));
    
    final path = Path();
    
    // Segmento de dona con bordes redondeados
    path.addArc(
      Rect.fromCenter(center: center, width: outerRadius * 2, height: outerRadius * 2),
      startAngle,
      sweepAngle,
    );
    
    path.arcTo(
      Rect.fromCenter(center: center, width: innerRadius * 2, height: innerRadius * 2),
      startAngle + sweepAngle,
      -sweepAngle,
      false,
    );
    
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSegmentWalls(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double innerRadius,
    double startAngle,
    double sweepAngle,
    Color color,
    Offset depthOffset,
  ) {
    // Pared exterior curva
    final outerWallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_lightenColor(color, 0.1), _darkenColor(color, 0.3)],
      ).createShader(Rect.fromLTWH(0, 0, outerRadius * 2, depthOffset.dy.abs()));
    
    final steps = 20;
    final angleStep = sweepAngle / steps;
    
    for (int i = 0; i < steps; i++) {
      final currentAngle = startAngle + (i * angleStep);
      final nextAngle = startAngle + ((i + 1) * angleStep);
      
      // Puntos del arco exterior
      final p1Front = Offset(
        center.dx + outerRadius * math.cos(currentAngle),
        center.dy + outerRadius * math.sin(currentAngle),
      );
      final p2Front = Offset(
        center.dx + outerRadius * math.cos(nextAngle),
        center.dy + outerRadius * math.sin(nextAngle),
      );
      
      final p1Back = Offset(p1Front.dx + depthOffset.dx, p1Front.dy + depthOffset.dy);
      final p2Back = Offset(p2Front.dx + depthOffset.dx, p2Front.dy + depthOffset.dy);
      
      final wallPath = Path()
        ..moveTo(p1Front.dx, p1Front.dy)
        ..lineTo(p2Front.dx, p2Front.dy)
        ..lineTo(p2Back.dx, p2Back.dy)
        ..lineTo(p1Back.dx, p1Back.dy)
        ..close();
      
      canvas.drawPath(wallPath, outerWallPaint);
    }
    
    // Pared interior curva (más oscura)
    final innerWallPaint = Paint()..color = _darkenColor(color, 0.5);
    
    for (int i = 0; i < steps; i++) {
      final currentAngle = startAngle + (i * angleStep);
      final nextAngle = startAngle + ((i + 1) * angleStep);
      
      final p1Front = Offset(
        center.dx + innerRadius * math.cos(currentAngle),
        center.dy + innerRadius * math.sin(currentAngle),
      );
      final p2Front = Offset(
        center.dx + innerRadius * math.cos(nextAngle),
        center.dy + innerRadius * math.sin(nextAngle),
      );
      
      final p1Back = Offset(p1Front.dx + depthOffset.dx, p1Front.dy + depthOffset.dy);
      final p2Back = Offset(p2Front.dx + depthOffset.dx, p2Front.dy + depthOffset.dy);
      
      final innerWallPath = Path()
        ..moveTo(p1Front.dx, p1Front.dy)
        ..lineTo(p1Back.dx, p1Back.dy)
        ..lineTo(p2Back.dx, p2Back.dy)
        ..lineTo(p2Front.dx, p2Front.dy)
        ..close();
      
      canvas.drawPath(innerWallPath, innerWallPaint);
    }
    
    // Paredes laterales de los extremos
    final sideWallPaint = Paint()
      ..shader = LinearGradient(
        colors: [_lightenColor(color, 0.05), _darkenColor(color, 0.25)],
      ).createShader(Rect.fromLTWH(0, 0, outerRadius - innerRadius, depthOffset.dy.abs()));
    
    // Lado inicio
    final startOuterFront = Offset(
      center.dx + outerRadius * math.cos(startAngle),
      center.dy + outerRadius * math.sin(startAngle),
    );
    final startInnerFront = Offset(
      center.dx + innerRadius * math.cos(startAngle),
      center.dy + innerRadius * math.sin(startAngle),
    );
    final startOuterBack = Offset(startOuterFront.dx + depthOffset.dx, startOuterFront.dy + depthOffset.dy);
    final startInnerBack = Offset(startInnerFront.dx + depthOffset.dx, startInnerFront.dy + depthOffset.dy);
    
    final startSidePath = Path()
      ..moveTo(startOuterFront.dx, startOuterFront.dy)
      ..lineTo(startInnerFront.dx, startInnerFront.dy)
      ..lineTo(startInnerBack.dx, startInnerBack.dy)
      ..lineTo(startOuterBack.dx, startOuterBack.dy)
      ..close();
    
    canvas.drawPath(startSidePath, sideWallPaint);
    
    // Lado final
    final endAngle = startAngle + sweepAngle;
    final endOuterFront = Offset(
      center.dx + outerRadius * math.cos(endAngle),
      center.dy + outerRadius * math.sin(endAngle),
    );
    final endInnerFront = Offset(
      center.dx + innerRadius * math.cos(endAngle),
      center.dy + innerRadius * math.sin(endAngle),
    );
    final endOuterBack = Offset(endOuterFront.dx + depthOffset.dx, endOuterFront.dy + depthOffset.dy);
    final endInnerBack = Offset(endInnerFront.dx + depthOffset.dx, endInnerFront.dy + depthOffset.dy);
    
    final endSidePath = Path()
      ..moveTo(endOuterFront.dx, endOuterFront.dy)
      ..lineTo(endOuterBack.dx, endOuterBack.dy)
      ..lineTo(endInnerBack.dx, endInnerBack.dy)
      ..lineTo(endInnerFront.dx, endInnerFront.dy)
      ..close();
    
    canvas.drawPath(endSidePath, sideWallPaint);
  }


  Color _lightenColor(Color color, double factor) {
    return Color.fromRGBO(
      math.min(255, (color.r * 255 + (255 - color.r * 255) * factor).round()),
      math.min(255, (color.g * 255 + (255 - color.g * 255) * factor).round()),
      math.min(255, (color.b * 255 + (255 - color.b * 255) * factor).round()),
      color.a,
    );
  }

  Color _darkenColor(Color color, double factor) {
    return Color.fromRGBO(
      (color.r * 255 * (1 - factor)).round(),
      (color.g * 255 * (1 - factor)).round(),
      (color.b * 255 * (1 - factor)).round(),
      color.a,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Efecto de destello para las barras de progreso mejoradas
class _ProgressShimmerEffect extends StatefulWidget {
  final double borderRadius;

  const _ProgressShimmerEffect({
    required this.borderRadius,
  });

  @override
  State<_ProgressShimmerEffect> createState() => _ProgressShimmerEffectState();
}

class _ProgressShimmerEffectState extends State<_ProgressShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _shimmerAnimation.value * 2, 0),
              end: Alignment(1.0 + _shimmerAnimation.value * 2, 0),
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.4),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}