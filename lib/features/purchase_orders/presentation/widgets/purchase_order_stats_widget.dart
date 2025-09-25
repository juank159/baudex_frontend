// lib/features/purchase_orders/presentation/widgets/purchase_order_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/animations/stats_animations.dart';
import '../../domain/entities/purchase_order.dart';

class PurchaseOrderStatsWidget extends StatelessWidget {
  final PurchaseOrderStats stats;

  const PurchaseOrderStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSizes = _getResponsiveSizes(context);
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(responsiveSizes['padding']!),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general
          StatsAnimations.slideInFadeIn(
            child: _buildGeneralSummary(responsiveSizes),
            duration: const Duration(milliseconds: 600),
          ),
          SizedBox(height: responsiveSizes['sectionSpacing']!),
          
          // Distribución por estado
          StatsAnimations.slideInFadeIn(
            child: _buildStatusStats(responsiveSizes),
            duration: const Duration(milliseconds: 800),
            beginOffset: const Offset(0.2, 0.3),
          ),
          SizedBox(height: responsiveSizes['sectionSpacing']!),
          
          // Distribución por prioridad
          StatsAnimations.slideInFadeIn(
            child: _buildPriorityStats(responsiveSizes),
            duration: const Duration(milliseconds: 1000),
            beginOffset: const Offset(-0.2, 0.3),
          ),
          SizedBox(height: responsiveSizes['sectionSpacing']!),
          
          // Estadísticas de tiempo
          StatsAnimations.slideInFadeIn(
            child: _buildTimeStats(responsiveSizes),
            duration: const Duration(milliseconds: 1200),
            beginOffset: const Offset(0.3, 0.3),
          ),
          SizedBox(height: responsiveSizes['sectionSpacing']!),
          
          // Indicadores de rendimiento
          StatsAnimations.slideInFadeIn(
            child: _buildPerformanceIndicators(responsiveSizes),
            duration: const Duration(milliseconds: 1400),
            beginOffset: const Offset(0, 0.4),
          ),
        ],
        ),
      ),
    );
  }
  
  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      // Desktop: tamaños más grandes para mejor legibilidad
      return {
        'cardHeight': 90.0,
        'padding': 16.0,
        'titleSize': 18.0,
        'subtitleSize': 14.0,
        'bodySize': 12.0,
        'smallSize': 10.0,
        'iconSize': 20.0,
        'sectionSpacing': 24.0,
        'cardSpacing': 16.0,
        'internalPadding': 20.0,
      };
    } else if (screenWidth >= 800) {
      // Tablet: tamaños medianos
      return {
        'cardHeight': 85.0,
        'padding': 14.0,
        'titleSize': 16.0,
        'subtitleSize': 12.0,
        'bodySize': 10.0,
        'smallSize': 8.0,
        'iconSize': 18.0,
        'sectionSpacing': 20.0,
        'cardSpacing': 14.0,
        'internalPadding': 18.0,
      };
    } else {
      // Mobile: tamaños más legibles que antes
      return {
        'cardHeight': 80.0,
        'padding': 12.0,
        'titleSize': 14.0,
        'subtitleSize': 10.0,
        'bodySize': 9.0,
        'smallSize': 7.0,
        'iconSize': 16.0,
        'sectionSpacing': 16.0,
        'cardSpacing': 12.0,
        'internalPadding': 16.0,
      };
    }
  }

  Widget _buildGeneralSummary(Map<String, double> sizes) {
    return LayoutBuilder(
      builder: (context, constraints) {
    return Container(
      padding: EdgeInsets.all(sizes['internalPadding']!),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(sizes['cardSpacing']! + 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(sizes['cardSpacing']!),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(sizes['cardSpacing']!),
                ),
                child: Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: sizes['iconSize']!,
                ),
              ),
              SizedBox(width: sizes['cardSpacing']!),
              Flexible(
                child: Text(
                  'Resumen General',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: sizes['titleSize']!,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: sizes['cardSpacing']! + 4),
          
          // Cards de resumen en grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth >= 800 ? 4 : 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: sizes['cardSpacing']!,
            mainAxisSpacing: sizes['cardSpacing']!,
            children: [
              _buildSummaryCard(
                'Total',
                '${stats.totalOrders}',
                Icons.shopping_cart,
                ElegantLightTheme.primaryGradient,
                sizes,
              ),
              _buildSummaryCard(
                'Valor Total',
                AppFormatters.formatCurrency(stats.totalValue),
                Icons.monetization_on,
                ElegantLightTheme.successGradient,
                sizes,
              ),
              _buildSummaryCard(
                'Promedio',
                AppFormatters.formatCurrency(stats.averageOrderValue),
                Icons.trending_up,
                ElegantLightTheme.infoGradient,
                sizes,
              ),
              _buildSummaryCard(
                'Proveedores',
                '${stats.activeSuppliers}',
                Icons.business,
                ElegantLightTheme.warningGradient,
                sizes,
              ),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    LinearGradient gradient,
    Map<String, double> sizes,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: sizes['cardHeight']!,
      ),
      padding: EdgeInsets.all(sizes['internalPadding']! * 0.6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.colors.first.withOpacity(0.1),
            gradient.colors.last.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(sizes['cardSpacing']!),
        border: Border.all(
          color: gradient.colors.first.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(sizes['cardSpacing']! * 0.6),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: sizes['iconSize']!,
            ),
          ),
          SizedBox(height: sizes['cardSpacing']! * 0.6),
          _buildAnimatedValue(value, gradient.colors.first, sizes),
          SizedBox(height: sizes['cardSpacing']! * 0.3),
          Text(
            title,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: sizes['smallSize']!,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStats(Map<String, double> sizes) {
    return Container(
      padding: EdgeInsets.all(sizes['internalPadding']!),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(sizes['cardSpacing']! + 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(sizes['cardSpacing']!),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(sizes['cardSpacing']!),
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: Colors.white,
                  size: sizes['iconSize']!,
                ),
              ),
              SizedBox(width: sizes['cardSpacing']!),
              Flexible(
                child: Text(
                  'Distribución por Estado',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: sizes['titleSize']!,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: sizes['cardSpacing']! + 4),
          
          Column(
            children: [
              _buildStatusBar('Pendientes', stats.pendingOrders, stats.totalOrders, ElegantLightTheme.warningGradient, sizes),
              _buildStatusBar('Aprobadas', stats.approvedOrders, stats.totalOrders, ElegantLightTheme.infoGradient, sizes),
              _buildStatusBar('Enviadas', stats.sentOrders, stats.totalOrders, const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]), sizes),
              _buildStatusBar('Parcialmente Recibidas', stats.partiallyReceivedOrders, stats.totalOrders, const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]), sizes),
              _buildStatusBar('Recibidas', stats.receivedOrders, stats.totalOrders, ElegantLightTheme.successGradient, sizes),
              _buildStatusBar('Canceladas', stats.cancelledOrders, stats.totalOrders, ElegantLightTheme.errorGradient, sizes),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, int total, LinearGradient gradient, Map<String, double> sizes) {
    final percentage = total > 0 ? count / total : 0.0;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes['cardSpacing']! * 0.5),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(sizes['cardSpacing']! * 0.4),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.6),
                ),
                child: Icon(Icons.circle, size: sizes['iconSize']! * 0.6, color: Colors.white),
              ),
              SizedBox(width: sizes['cardSpacing']!),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: sizes['bodySize']!,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sizes['cardSpacing']! * 0.8,
                  vertical: sizes['cardSpacing']! * 0.3,
                ),
                decoration: BoxDecoration(
                  color: gradient.colors.first.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(sizes['cardSpacing']!),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: gradient.colors.first,
                    fontSize: sizes['smallSize']!,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: sizes['cardSpacing']! * 0.5),
              Text(
                '(${(percentage * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: sizes['smallSize']!,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: sizes['cardSpacing']! * 0.4),
          // Barra horizontal mejorada inspirada en FuturisticItemCard
          Container(
            height: sizes['cardSpacing']! * 1.2,
            decoration: BoxDecoration(
              color: ElegantLightTheme.textSecondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.6),
              border: Border.all(
                color: ElegantLightTheme.textSecondary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: percentage),
              duration: Duration(milliseconds: 1800 + (percentage * 1200).round()),
              curve: Curves.easeOutExpo,
              builder: (context, animatedValue, child) {
                return Row(
                  children: [
                    // Parte llena con destello
                    if (animatedValue > 0)
                      Flexible(
                        flex: (animatedValue * 100).round(),
                        child: Container(
                          height: sizes['cardSpacing']! * 1.0,
                          margin: EdgeInsets.all(sizes['cardSpacing']! * 0.1),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.5),
                            child: Stack(
                              children: [
                                // Efecto de destello cuando está casi completa
                                if (animatedValue >= percentage * 0.98 && percentage > 0.1)
                                  _ProgressShimmerEffect(
                                    borderRadius: sizes['cardSpacing']! * 0.5,
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
                          height: sizes['cardSpacing']! * 1.0,
                          margin: EdgeInsets.all(sizes['cardSpacing']! * 0.1),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.5),
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
  }

  Widget _buildPriorityStats(Map<String, double> sizes) {
    return LayoutBuilder(
      builder: (context, constraints) {
    return Container(
      padding: EdgeInsets.all(sizes['internalPadding']!),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(sizes['cardSpacing']! + 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(sizes['cardSpacing']!),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(sizes['cardSpacing']!),
                ),
                child: Icon(
                  Icons.priority_high,
                  color: Colors.white,
                  size: sizes['iconSize']!,
                ),
              ),
              SizedBox(width: sizes['cardSpacing']!),
              Flexible(
                child: Text(
                  'Distribución por Prioridad',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: sizes['titleSize']!,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: sizes['cardSpacing']! + 4),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth >= 800 ? 4 : 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: sizes['cardSpacing']!,
            mainAxisSpacing: sizes['cardSpacing']!,
            children: [
              _buildPriorityCard('Urgente', stats.urgentOrders, const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]), Icons.priority_high, sizes),
              _buildPriorityCard('Alta', stats.highPriorityOrders, ElegantLightTheme.errorGradient, Icons.keyboard_arrow_up, sizes),
              _buildPriorityCard('Media', stats.mediumPriorityOrders, ElegantLightTheme.warningGradient, Icons.remove, sizes),
              _buildPriorityCard('Baja', stats.lowPriorityOrders, ElegantLightTheme.successGradient, Icons.keyboard_arrow_down, sizes),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildPriorityCard(String label, int count, LinearGradient gradient, IconData icon, Map<String, double> sizes) {
    return Container(
      constraints: BoxConstraints(maxHeight: sizes['cardHeight']!),
      padding: EdgeInsets.all(sizes['internalPadding']! * 0.6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.colors.first.withOpacity(0.1),
            gradient.colors.last.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(sizes['cardSpacing']!),
        border: Border.all(
          color: gradient.colors.first.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(sizes['cardSpacing']! * 0.6),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.6),
            ),
            child: Icon(icon, color: Colors.white, size: sizes['iconSize']! * 0.8),
          ),
          SizedBox(height: sizes['cardSpacing']! * 0.6),
          StatsAnimations.animatedCounter(
            value: count,
            style: TextStyle(
              color: gradient.colors.first,
              fontSize: sizes['bodySize']! + 3,
              fontWeight: FontWeight.w700,
            ),
            duration: Duration(milliseconds: 1000 + (count * 50).clamp(0, 800)),
          ),
          SizedBox(height: sizes['cardSpacing']! * 0.3),
          Text(
            label,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: sizes['smallSize']!,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStats(Map<String, double> sizes) {
    return LayoutBuilder(
      builder: (context, constraints) {
    return Container(
      padding: EdgeInsets.all(sizes['internalPadding']!),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(sizes['cardSpacing']! + 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(sizes['cardSpacing']!),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(sizes['cardSpacing']!),
                ),
                child: Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: sizes['iconSize']!,
                ),
              ),
              SizedBox(width: sizes['cardSpacing']!),
              Flexible(
                child: Text(
                  'Estadísticas de Tiempo',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: sizes['titleSize']!,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: sizes['cardSpacing']! + 4),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth >= 800 ? 2 : 1,
            childAspectRatio: constraints.maxWidth >= 800 ? 2.5 : 2.8,
            crossAxisSpacing: sizes['cardSpacing']!,
            mainAxisSpacing: sizes['cardSpacing']!,
            children: [
              _buildTimeCard('Órdenes Vencidas', '${stats.overdueOrders}', 'han pasado su fecha', ElegantLightTheme.errorGradient, Icons.warning, sizes),
              _buildTimeCard('Tiempo Promedio', '${stats.averageDeliveryDays.toStringAsFixed(1)} días', 'orden hasta entrega', ElegantLightTheme.infoGradient, Icons.access_time, sizes),
              _buildTimeCard('Entrega Puntual', '${(stats.onTimeDeliveryRate * 100).toStringAsFixed(1)}%', 'entregas fueron puntuales', ElegantLightTheme.successGradient, Icons.check_circle, sizes),
              _buildTimeCard('Pendientes Urgentes', '${stats.pendingUrgentOrders}', 'órdenes sin procesar', const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]), Icons.priority_high, sizes),
            ],
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildTimeCard(String title, String value, String subtitle, LinearGradient gradient, IconData icon, Map<String, double> sizes) {
    return Container(
      constraints: BoxConstraints(maxHeight: sizes['cardHeight']!),
      padding: EdgeInsets.all(sizes['internalPadding']! * 0.8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.colors.first.withOpacity(0.1),
            gradient.colors.last.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(sizes['cardSpacing']!),
        border: Border.all(
          color: gradient.colors.first.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(sizes['cardSpacing']! * 0.6),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.6),
            ),
            child: Icon(icon, color: Colors.white, size: sizes['iconSize']!),
          ),
          SizedBox(width: sizes['cardSpacing']!),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: sizes['bodySize']!,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: sizes['cardSpacing']! * 0.3),
                Text(
                  value,
                  style: TextStyle(
                    color: gradient.colors.first,
                    fontSize: sizes['bodySize']! + 2,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: sizes['cardSpacing']! * 0.2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: sizes['smallSize']!,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicators(Map<String, double> sizes) {
    return Container(
      padding: EdgeInsets.all(sizes['internalPadding']!),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(sizes['cardSpacing']! + 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(sizes['cardSpacing']!),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient,
                  borderRadius: BorderRadius.circular(sizes['cardSpacing']!),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: sizes['iconSize']!,
                ),
              ),
              SizedBox(width: sizes['cardSpacing']!),
              Flexible(
                child: Text(
                  'Indicadores de Rendimiento',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: sizes['titleSize']!,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: sizes['cardSpacing']! + 4),
          
          _buildPerformanceIndicator('Tasa de Aprobación', stats.approvalRate, 'Órdenes aprobadas vs rechazadas', ElegantLightTheme.successGradient, sizes),
          SizedBox(height: sizes['cardSpacing']!),
          _buildPerformanceIndicator('Eficiencia de Entrega', stats.onTimeDeliveryRate, 'Entregas puntuales', ElegantLightTheme.infoGradient, sizes),
          SizedBox(height: sizes['cardSpacing']!),
          _buildPerformanceIndicator('Tasa de Cancelación', stats.cancellationRate, 'Órdenes canceladas', ElegantLightTheme.errorGradient, sizes),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(String title, double rate, String description, LinearGradient gradient, Map<String, double> sizes) {
    final percentage = rate * 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: sizes['bodySize']!,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: sizes['cardSpacing']!,
                vertical: sizes['cardSpacing']! * 0.3,
              ),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(sizes['cardSpacing']!),
              ),
              child: StatsAnimations.animatedPercentage(
                value: rate,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: sizes['smallSize']! + 1,
                  fontWeight: FontWeight.w700,
                ),
                duration: Duration(milliseconds: 1200 + (rate * 600).round()),
              ),
            ),
          ],
        ),
        SizedBox(height: sizes['cardSpacing']! * 0.6),
        // Barra horizontal mejorada para indicadores de rendimiento
        Container(
          height: sizes['cardSpacing']! * 1.4,
          decoration: BoxDecoration(
            color: ElegantLightTheme.textSecondary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.7),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: rate),
            duration: Duration(milliseconds: 2000 + (rate * 1500).round()),
            curve: Curves.easeOutExpo,
            builder: (context, animatedValue, child) {
              return Row(
                children: [
                  // Parte llena con destello
                  if (animatedValue > 0)
                    Flexible(
                      flex: (animatedValue * 100).round(),
                      child: Container(
                        height: sizes['cardSpacing']! * 1.2,
                        margin: EdgeInsets.all(sizes['cardSpacing']! * 0.1),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.6),
                          child: Stack(
                            children: [
                              // Efecto de destello cuando está casi completa
                              if (animatedValue >= rate * 0.98 && rate > 0.1)
                                _ProgressShimmerEffect(
                                  borderRadius: sizes['cardSpacing']! * 0.6,
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
                        height: sizes['cardSpacing']! * 1.2,
                        margin: EdgeInsets.all(sizes['cardSpacing']! * 0.1),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(sizes['cardSpacing']! * 0.6),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: sizes['cardSpacing']! * 0.4),
        Text(
          description,
          style: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: sizes['smallSize']!,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAnimatedValue(String value, Color color, Map<String, double> sizes) {
    // Check if value is a number (for counter animation)
    final numericValue = int.tryParse(value.replaceAll(RegExp(r'[^\d]'), ''));
    if (numericValue != null && !value.contains('\$') && !value.contains('%')) {
      return StatsAnimations.animatedCounter(
        value: numericValue,
        style: TextStyle(
          color: color,
          fontSize: sizes['bodySize']! + 3,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    
    // Check if value is a percentage
    if (value.contains('%')) {
      final percentValue = double.tryParse(value.replaceAll('%', ''));
      if (percentValue != null) {
        return StatsAnimations.animatedPercentage(
          value: percentValue / 100,
          style: TextStyle(
            color: color,
            fontSize: sizes['bodySize']! + 3,
            fontWeight: FontWeight.w700,
          ),
        );
      }
    }
    
    // Check if value is currency
    if (value.contains('\$') || value.contains('COP')) {
      final currencyValue = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
      if (currencyValue != null) {
        return StatsAnimations.animatedCurrency(
          value: currencyValue,
          style: TextStyle(
            color: color,
            fontSize: sizes['bodySize']! + 3,
            fontWeight: FontWeight.w700,
          ),
          symbol: '\$',
        );
      }
    }
    
    // Default: just animated text
    return StatsAnimations.slideInFadeIn(
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: sizes['bodySize']! + 3,
          fontWeight: FontWeight.w700,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

/// Efecto de destello para la barra de progreso
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
                Colors.white.withOpacity(0.4),
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