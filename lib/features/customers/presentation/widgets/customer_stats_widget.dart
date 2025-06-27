// lib/features/customers/presentation/widgets/customer_stats_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
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
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
            const SizedBox(width: 12),
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

        const SizedBox(height: 12),

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
            const SizedBox(width: 12),
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

        const SizedBox(height: 12),

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
            const SizedBox(width: 12),
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
          const SizedBox(height: 12),
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
    return CustomCard(
      padding: EdgeInsets.all(context.isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: context.isMobile ? 20 : 24,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: context.isMobile ? 8 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getFontSize(
                context,
                mobile: 12,
                tablet: 14,
                desktop: 16,
              ),
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
    return CustomCard(
      padding: EdgeInsets.all(context.isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: context.isMobile ? 20 : 24,
                ),
              ),
              const Spacer(),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: context.isMobile ? 8 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getFontSize(
                context,
                mobile: 12,
                tablet: 14,
                desktop: 16,
              ),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade300);
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }
}
