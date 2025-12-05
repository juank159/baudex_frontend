// lib/features/expenses/presentation/widgets/modern_expense_card_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/expense.dart';

class ModernExpenseCardWidget extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onApprove;
  final VoidCallback? onSubmit;

  const ModernExpenseCardWidget({
    super.key,
    required this.expense,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onApprove,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.isMobile(context)
        ? _buildMobileCard(context)
        : _buildDesktopCard(context);
  }

  Widget _buildMobileCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Header compacto
                Row(
                  children: [
                    // Avatar con gradiente circular
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: _getStatusGradient(),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getExpenseTypeIcon(),
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info principal compacta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.description,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ElegantLightTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(expense.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: ElegantLightTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Badge de estado con gradiente
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: _getStatusGradient().scale(0.3),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Info adicional ultra compacta
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoChip(
                        Icons.attach_money,
                        expense.formattedAmount,
                        ElegantLightTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCompactInfoChip(
                        Icons.category,
                        expense.type.displayName,
                        ElegantLightTheme.accentOrange,
                      ),
                    ),
                    ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildCompactInfoChip(
                          Icons.payment,
                          expense.paymentMethod!.displayName,
                          Colors.green.shade600,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Acciones compactas con gradiente
                Row(
                  children: [
                    if (onEdit != null && expense.canBeEdited)
                      Expanded(
                        child: _buildActionButton(
                          'Editar',
                          Icons.edit,
                          ElegantLightTheme.primaryBlue,
                          onEdit!,
                        ),
                      ),
                    if (onEdit != null &&
                        expense.canBeEdited &&
                        (onSubmit != null && expense.canBeSubmitted ||
                            onApprove != null && expense.canBeApproved ||
                            onDelete != null))
                      const SizedBox(width: 8),
                    if (onSubmit != null && expense.canBeSubmitted)
                      Expanded(
                        child: _buildActionButton(
                          'Enviar',
                          Icons.send,
                          Colors.blue.shade600,
                          onSubmit!,
                        ),
                      ),
                    if (onSubmit != null &&
                        expense.canBeSubmitted &&
                        (onApprove != null && expense.canBeApproved ||
                            onDelete != null))
                      const SizedBox(width: 8),
                    if (onApprove != null && expense.canBeApproved)
                      Expanded(
                        child: _buildActionButton(
                          'Aprobar',
                          Icons.check_circle,
                          Colors.green.shade600,
                          onApprove!,
                        ),
                      ),
                    if (onApprove != null &&
                        expense.canBeApproved &&
                        onDelete != null)
                      const SizedBox(width: 8),
                    if (onDelete != null)
                      Expanded(
                        child: _buildActionButton(
                          'Eliminar',
                          Icons.delete,
                          Colors.red.shade600,
                          onDelete!,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: ElegantLightTheme.primaryBlue.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar con gradiente
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _getStatusGradient(),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getExpenseTypeIcon(),
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),

                // Info principal - Columna izquierda
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Descripción y estado
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              expense.description,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ElegantLightTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Fecha y vendor
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(expense.date),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (expense.vendor != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.store,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  expense.vendor!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Info adicional - Columna centro
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Monto - destacado
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: ElegantLightTheme.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Monto:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            expense.formattedAmount,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ElegantLightTheme.primaryBlue,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Tipo
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category,
                            size: 13,
                            color: ElegantLightTheme.accentOrange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tipo:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            expense.type.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ElegantLightTheme.accentOrange,
                            ),
                          ),
                        ],
                      ),

                      // Pago
                      ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payment,
                              size: 13,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pago:',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              expense.paymentMethod!.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Estado y acciones - Columna derecha
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge de estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: _getStatusGradient().scale(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor().withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botones de acción
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null && expense.canBeEdited)
                          _buildCompactActionButton(
                            Icons.edit_outlined,
                            'Editar',
                            ElegantLightTheme.primaryBlue,
                            onEdit!,
                          ),
                        if (onSubmit != null && expense.canBeSubmitted) ...[
                          const SizedBox(width: 6),
                          _buildCompactActionButton(
                            Icons.send_outlined,
                            'Enviar',
                            Colors.blue.shade600,
                            onSubmit!,
                          ),
                        ],
                        if (onApprove != null && expense.canBeApproved) ...[
                          const SizedBox(width: 6),
                          _buildCompactActionButton(
                            Icons.check_circle_outline,
                            'Aprobar',
                            Colors.green.shade600,
                            onApprove!,
                          ),
                        ],
                        if (onDelete != null) ...[
                          const SizedBox(width: 6),
                          _buildCompactActionButton(
                            Icons.delete_outline,
                            'Eliminar',
                            Colors.red.shade600,
                            onDelete!,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactActionButton(
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    final gradient = _getGradientForColor(color);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          gradient: gradient.scale(0.2),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (expense.status) {
      case ExpenseStatus.draft:
        return Colors.grey.shade600;
      case ExpenseStatus.pending:
        return ElegantLightTheme.accentOrange;
      case ExpenseStatus.approved:
        return Colors.green.shade600;
      case ExpenseStatus.rejected:
        return Colors.red.shade600;
      case ExpenseStatus.paid:
        return Colors.blue.shade600;
    }
  }

  LinearGradient _getStatusGradient() {
    switch (expense.status) {
      case ExpenseStatus.draft:
        return LinearGradient(
          colors: [Colors.grey.shade500, Colors.grey.shade700],
        );
      case ExpenseStatus.pending:
        return ElegantLightTheme.warningGradient;
      case ExpenseStatus.approved:
        return ElegantLightTheme.successGradient;
      case ExpenseStatus.rejected:
        return ElegantLightTheme.errorGradient;
      case ExpenseStatus.paid:
        return ElegantLightTheme.infoGradient;
    }
  }

  LinearGradient _getGradientForColor(Color color) {
    if (color == ElegantLightTheme.primaryBlue) {
      return ElegantLightTheme.primaryGradient;
    } else if (color == Colors.green.shade600) {
      return ElegantLightTheme.successGradient;
    } else if (color == Colors.blue.shade600) {
      return ElegantLightTheme.infoGradient;
    } else if (color == Colors.red.shade600) {
      return ElegantLightTheme.errorGradient;
    } else {
      return ElegantLightTheme.warningGradient;
    }
  }

  String _getStatusText() {
    switch (expense.status) {
      case ExpenseStatus.draft:
        return 'BORRADOR';
      case ExpenseStatus.pending:
        return 'PENDIENTE';
      case ExpenseStatus.approved:
        return 'APROBADO';
      case ExpenseStatus.rejected:
        return 'RECHAZADO';
      case ExpenseStatus.paid:
        return 'PAGADO';
    }
  }

  IconData _getExpenseTypeIcon() {
    switch (expense.type) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
