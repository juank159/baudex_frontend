// lib/features/suppliers/presentation/widgets/supplier_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/supplier.dart';

class SupplierStatsWidget extends StatelessWidget {
  final SupplierStats stats;

  const SupplierStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general
          _buildSummarySection(),
          
          const SizedBox(height: AppDimensions.paddingLarge),
          
          // Estadísticas por estado
          _buildStatusSection(),
          
          const SizedBox(height: AppDimensions.paddingLarge),
          
          // Información financiera
          _buildFinancialSection(),
          
          const SizedBox(height: AppDimensions.paddingLarge),
          
          // Distribución por moneda
          _buildCurrencySection(),
          
          const SizedBox(height: AppDimensions.paddingLarge),
          
          // Top proveedores
          _buildTopSuppliersSection(),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen General',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Row(
              children: [
                _buildStatCard(
                  title: 'Total Proveedores',
                  value: stats.totalSuppliers.toString(),
                  icon: Icons.business,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                _buildStatCard(
                  title: 'Activos',
                  value: stats.activeSuppliers.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                _buildStatCard(
                  title: 'Inactivos',
                  value: stats.inactiveSuppliers.toString(),
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución por Estado',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildProgressIndicator(
              'Activos',
              stats.activeSuppliers,
              stats.totalSuppliers,
              Colors.green,
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            _buildProgressIndicator(
              'Inactivos',
              stats.inactiveSuppliers,
              stats.totalSuppliers,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Financiera',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Row(
              children: [
                _buildFinancialCard(
                  title: 'Crédito Total',
                  value: AppFormatters.formatCurrency(stats.totalCreditLimit),
                  icon: Icons.credit_card,
                  color: Colors.blue,
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                _buildFinancialCard(
                  title: 'Promedio Crédito',
                  value: AppFormatters.formatCurrency(stats.averageCreditLimit),
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Row(
              children: [
                _buildFinancialCard(
                  title: 'Con Crédito',
                  value: '${stats.suppliersWithCredit}',
                  icon: Icons.account_balance,
                  color: Colors.purple,
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                _buildFinancialCard(
                  title: 'Con Descuento',
                  value: '${stats.suppliersWithDiscount}',
                  icon: Icons.discount,
                  color: Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución por Moneda',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            ...stats.currencyDistribution.entries.map((entry) {
              final percentage = (entry.value / stats.totalSuppliers * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
                child: _buildProgressIndicator(
                  entry.key,
                  entry.value,
                  stats.totalSuppliers,
                  _getCurrencyColor(entry.key),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSuppliersSection() {
    if (stats.topSuppliersByCredit.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Proveedores por Crédito',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            ...stats.topSuppliersByCredit.asMap().entries.map((entry) {
              final index = entry.key;
              final supplier = entry.value;
              return _buildTopSupplierItem(index + 1, supplier as Map<String, dynamic>);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Text(
              value,
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    String label,
    int value,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? value / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$value (${(percentage * 100).toStringAsFixed(1)}%)',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildTopSupplierItem(int position, Map<String, dynamic> supplier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getPositionColor(position).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$position',
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getPositionColor(position),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier['name'] ?? 'N/A',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Crédito: ${AppFormatters.formatCurrency(supplier['creditLimit'] ?? 0.0)}',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCurrencyColor(String currency) {
    switch (currency.toUpperCase()) {
      case 'COP':
        return Colors.green;
      case 'USD':
        return Colors.blue;
      case 'EUR':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}