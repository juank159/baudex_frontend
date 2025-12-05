// lib/features/expenses/presentation/widgets/modern_expense_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/expense.dart';
import '../controllers/enhanced_expenses_controller.dart';

class ModernExpenseFilterWidget extends GetView<EnhancedExpensesController> {
  const ModernExpenseFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header compacto
        _buildFilterHeader(context),
        const SizedBox(height: 16),

        // Filtros principales
        _buildStatusFilter(context),
        const SizedBox(height: 12),
        _buildTypeFilter(context),
        const SizedBox(height: 12),
        _buildSortingOptions(context),
      ],
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.primaryBlue.withOpacity(0.05),
            ElegantLightTheme.primaryBlueLight.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(6),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Filtros de Búsqueda',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              controller.clearFilters();
              Get.snackbar(
                'Filtros limpiados',
                'Se han restablecido todos los filtros',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
                backgroundColor: ElegantLightTheme.surfaceColor,
                colorText: ElegantLightTheme.textPrimary,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient.scale(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ElegantLightTheme.accentOrange.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.clear,
                    size: 12,
                    color: ElegantLightTheme.accentOrange,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Limpiar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ElegantLightTheme.accentOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.traffic,
                  size: 16,
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Estado del Gasto',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseStatus.values.map((status) {
                final isSelected = controller.currentStatus == status;
                return _buildStatusChip(status, isSelected);
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ExpenseStatus status, bool isSelected) {
    Color color;
    LinearGradient gradient;
    String text;
    IconData icon;

    switch (status) {
      case ExpenseStatus.draft:
        color = Colors.grey.shade600;
        gradient = LinearGradient(colors: [Colors.grey.shade500, Colors.grey.shade700]);
        text = 'Borrador';
        icon = Icons.edit;
        break;
      case ExpenseStatus.pending:
        color = ElegantLightTheme.accentOrange;
        gradient = ElegantLightTheme.warningGradient;
        text = 'Pendiente';
        icon = Icons.pending_actions;
        break;
      case ExpenseStatus.approved:
        color = Colors.green.shade600;
        gradient = ElegantLightTheme.successGradient;
        text = 'Aprobado';
        icon = Icons.check_circle;
        break;
      case ExpenseStatus.rejected:
        color = Colors.red.shade600;
        gradient = ElegantLightTheme.errorGradient;
        text = 'Rechazado';
        icon = Icons.cancel;
        break;
      case ExpenseStatus.paid:
        color = Colors.blue.shade600;
        gradient = ElegantLightTheme.infoGradient;
        text = 'Pagado';
        icon = Icons.payment;
        break;
    }

    return GestureDetector(
      onTap: () {
        // Toggle: si ya está seleccionado, lo deselecciona
        if (isSelected) {
          controller.applyStatusFilter(null);
        } else {
          controller.applyStatusFilter(status);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient.scale(0.2) : null,
          color: isSelected ? null : ElegantLightTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : ElegantLightTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : ElegantLightTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.category,
                  size: 16,
                  color: ElegantLightTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tipo de Gasto',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseType.values.map((type) {
                final isSelected = controller.currentType == type;
                return _buildTypeChip(type, isSelected);
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypeChip(ExpenseType type, bool isSelected) {
    final color = ElegantLightTheme.primaryBlue;
    final gradient = ElegantLightTheme.primaryGradient;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          controller.applyTypeFilter(null);
        } else {
          controller.applyTypeFilter(type);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient.scale(0.2) : null,
          color: isSelected ? null : ElegantLightTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTypeIcon(type),
              size: 14,
              color: isSelected ? color : ElegantLightTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : ElegantLightTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(ExpenseType type) {
    switch (type) {
      case ExpenseType.operating:
        return Icons.business_center;
      case ExpenseType.administrative:
        return Icons.admin_panel_settings;
      case ExpenseType.sales:
        return Icons.point_of_sale;
      case ExpenseType.financial:
        return Icons.account_balance;
      case ExpenseType.extraordinary:
        return Icons.warning_amber;
    }
  }

  Widget _buildSortingOptions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.sort,
                  size: 16,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Ordenar Por',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final currentSort = '${controller.sortBy}_${controller.sortOrder}';
            return Column(
              children: [
                _buildSortOption(
                  'Fecha (Recientes)',
                  'createdAt',
                  'DESC',
                  Icons.access_time,
                  currentSort == 'createdAt_DESC',
                ),
                _buildSortOption(
                  'Fecha (Antiguos)',
                  'createdAt',
                  'ASC',
                  Icons.access_time,
                  currentSort == 'createdAt_ASC',
                ),
                _buildSortOption(
                  'Monto (Mayor)',
                  'amount',
                  'DESC',
                  Icons.trending_up,
                  currentSort == 'amount_DESC',
                ),
                _buildSortOption(
                  'Monto (Menor)',
                  'amount',
                  'ASC',
                  Icons.trending_down,
                  currentSort == 'amount_ASC',
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    String text,
    String sortBy,
    String sortOrder,
    IconData icon,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        controller.changeSorting(sortBy, sortOrder);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? ElegantLightTheme.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? ElegantLightTheme.primaryBlue
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? ElegantLightTheme.primaryBlue
                      : Colors.grey.shade700,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: ElegantLightTheme.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }
}
