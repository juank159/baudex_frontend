// lib/features/customers/presentation/widgets/customer_stats_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../domain/entities/customer_stats.dart';

class CustomerStatsWidget extends StatelessWidget {
  final CustomerStats stats;
  final bool isCompact;

  const CustomerStatsWidget({
    super.key,
    required this.stats,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactStats(context);
    }

    return ResponsiveLayout(
      mobile: _buildMobileStats(context),
      tablet: _buildTabletStats(context),
      desktop: _buildDesktopStats(context),
    );
  }

  Widget _buildCompactStats(BuildContext context) {
    return CustomCard(
      padding: ResponsiveHelper.getPadding(context, paddingContext: PaddingContext.compact),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribución uniforme
        children: [
          _buildCompactStatItem(
            context,
            'Total',
            stats.total.toString(),
            Icons.people,
            Theme.of(context).primaryColor,
          ),
          _buildVerticalDivider(),
          _buildCompactStatItem(
            context,
            'Activos',
            stats.active.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          _buildVerticalDivider(),
          _buildCompactStatItem(
            context,
            'Riesgo',
            stats.customersWithOverdue.toString(),
            Icons.warning,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStats(BuildContext context) {
    return Column(
      children: [
        // Fila 1: Total y Activos
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total de Clientes',
                stats.total.toString(),
                Icons.people,
                Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
            Expanded(
              child: _buildStatCard(
                context,
                'Clientes Activos',
                stats.active.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),

        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

        // Fila 2: Inactivos y Suspendidos
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Inactivos',
                stats.inactive.toString(),
                Icons.pause_circle,
                Colors.orange,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
            Expanded(
              child: _buildStatCard(
                context,
                'Suspendidos',
                stats.suspended.toString(),
                Icons.block,
                Colors.red,
              ),
            ),
          ],
        ),

        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),

        // Fila 3: Información financiera
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Límite de Crédito',
                _formatCurrency(stats.totalCreditLimit),
                Icons.credit_card,
                Colors.blue,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context)),
            Expanded(
              child: _buildStatCard(
                context,
                'Balance Pendiente',
                _formatCurrency(stats.totalBalance),
                Icons.account_balance,
                Colors.purple,
              ),
            ),
          ],
        ),

        if (stats.customersWithOverdue > 0) ...[
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context)),
          _buildStatCard(
            context,
            'Clientes con Facturas Vencidas',
            stats.customersWithOverdue.toString(),
            Icons.warning,
            Colors.red,
          ),
        ],
      ],
    );
  }

  Widget _buildTabletStats(BuildContext context) {
    return Column(
      children: [
        // Estadísticas principales en una fila
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total de Clientes',
                stats.total.toString(),
                Icons.people,
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Clientes Activos',
                stats.active.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Inactivos',
                stats.inactive.toString(),
                Icons.pause_circle,
                Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Estadísticas financieras
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Límite de Crédito Total',
                _formatCurrency(stats.totalCreditLimit),
                Icons.credit_card,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Balance Pendiente',
                _formatCurrency(stats.totalBalance),
                Icons.account_balance,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Promedio de Compra',
                _formatCurrency(stats.averagePurchaseAmount),
                Icons.shopping_cart,
                Colors.teal,
              ),
            ),
          ],
        ),

        if (stats.customersWithOverdue > 0) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Clientes con Facturas Vencidas',
                  stats.customersWithOverdue.toString(),
                  Icons.warning,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPercentageCard(
                  context,
                  'Porcentaje Activos',
                  stats.activePercentage,
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopStats(BuildContext context) {
    return Column(
      children: [
        // Primera fila: Estadísticas generales
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total de Clientes',
                stats.total.toString(),
                Icons.people,
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                context,
                'Clientes Activos',
                stats.active.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                context,
                'Inactivos',
                stats.inactive.toString(),
                Icons.pause_circle,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                context,
                'Suspendidos',
                stats.suspended.toString(),
                Icons.block,
                Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Segunda fila: Estadísticas financieras
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Límite de Crédito Total',
                _formatCurrency(stats.totalCreditLimit),
                Icons.credit_card,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                context,
                'Balance Pendiente',
                _formatCurrency(stats.totalBalance),
                Icons.account_balance,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                context,
                'Promedio de Compra',
                _formatCurrency(stats.averagePurchaseAmount),
                Icons.shopping_cart,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildPercentageCard(
                context,
                'Porcentaje Activos',
                stats.activePercentage,
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),

        if (stats.customersWithOverdue > 0) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Clientes con Facturas Vencidas',
                  stats.customersWithOverdue.toString(),
                  Icons.warning,
                  Colors.red,
                ),
              ),
              const Expanded(flex: 3, child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    // 🎯 TAMAÑOS MUY OPTIMIZADOS PARA SIDEBAR ESTRECHO
    final iconSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 16.0, // Más pequeño para sidebar
    );

    final valueSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 22.0, // Reducido significativamente
    );

    final titleSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 10.0,
      tablet: 11.0,
      desktop: 11.0, // Muy pequeño pero legible
    );

    final cardPadding = ResponsiveHelper.responsiveValue(
      context,
      mobile: 10.0,
      tablet: 12.0,
      desktop: 12.0, // Padding más compacto
    );

    return CustomCard(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconSize * 0.3), // Padding más pequeño
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(iconSize * 0.3),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              ),
              SizedBox(width: cardPadding * 0.5), // Espaciado reducido
              Expanded( // 🔥 CRITICAL: Usar Expanded en lugar de Spacer
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: cardPadding * 0.4), // Espaciado más compacto
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageCard(
    BuildContext context,
    String title,
    double percentage,
    IconData icon,
    Color color,
  ) {
    // 🎯 TAMAÑOS OPTIMIZADOS PARA PORCENTAJES
    final iconSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 16.0, // Más pequeño
    );

    final percentageSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 22.0, // Reducido
    );

    final titleSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 10.0,
      tablet: 11.0,
      desktop: 11.0, // Muy pequeño
    );

    final cardPadding = ResponsiveHelper.responsiveValue(
      context,
      mobile: 10.0,
      tablet: 12.0,
      desktop: 12.0, // Compacto
    );

    return CustomCard(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconSize * 0.3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(iconSize * 0.3),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              ),
              SizedBox(width: cardPadding * 0.5),
              Expanded( // 🔥 CRITICAL: Usar Expanded
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: percentageSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: cardPadding * 0.4),
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: cardPadding * 0.3),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: ResponsiveHelper.responsiveValue(
              context,
              mobile: 2.0,
              tablet: 3.0,
              desktop: 3.0, // Más delgado
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    // 🎯 TAMAÑOS ULTRA-COMPACTOS PARA EVITAR OVERFLOW
    final iconSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 12.0,
      tablet: 14.0,
      desktop: 14.0, // Muy pequeño
    );

    final valueSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 16.0, // Muy controlado
    );

    final labelSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 8.0,
      tablet: 9.0,
      desktop: 9.0, // Mínimo legible
    );

    return Flexible( // 🔥 CRITICAL: Usar Flexible en lugar de Column
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(iconSize * 0.25), // Padding mínimo
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(iconSize * 0.25),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(height: 3), // Espaciado fijo mínimo
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40, // Fixed height instead of responsive to avoid layout conflicts
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  String _formatCurrency(double amount) {
    // Formateo compacto y optimizado
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }
}