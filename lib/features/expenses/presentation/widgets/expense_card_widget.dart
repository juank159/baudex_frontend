// lib/features/expenses/presentation/widgets/expense_card_widget.dart
import 'package:flutter/material.dart';
import '../../domain/entities/expense.dart';

class ExpenseCardWidget extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onApprove;
  final VoidCallback? onSubmit;
  final bool compact;

  const ExpenseCardWidget({
    super.key,
    required this.expense,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onApprove,
    this.onSubmit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6), // Reducido de 8 a 6
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6), // Reducido de 8 a 6
        child: Padding(
          padding: const EdgeInsets.all(10), // Reducido de 16 a 10 (37% menos)
          child: compact ? _buildCompactLayout(context) : _buildFullLayout(context),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Row(
      children: [
        // Indicador de estado más pequeño
        Container(
          width: 8, // Reducido de ~12 a 8
          height: 8, // Reducido de ~12 a 8
          decoration: BoxDecoration(
            color: _getStatusColor(context),
            shape: BoxShape.circle,
          ),
        ),
        
        const SizedBox(width: 8), // Reducido de 12 a 8
        
        // Información principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                expense.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 13, // Reducido 
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // Reducido de 4 a 2
              Row(
                children: [
                  Text(
                    expense.formattedAmount,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Reducido
                    ),
                  ),
                  const SizedBox(width: 6), // Reducido de 8 a 6
                  Text(
                    _formatDate(expense.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: 11, // Reducido
                    ),
                  ),
                  const Spacer(),
                  // Status chip más pequeño
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(context),
                        fontSize: 9, // Muy pequeño
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 4), // Reducido
        
        // Menú de acciones más pequeño
        _buildCompactActionsMenu(context),
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con estado y acciones
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(context),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            _buildActionsMenu(context),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Información principal
        Row(
          children: [
            // Monto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                expense.formattedAmount,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Fecha
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(expense.date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Información adicional
        Row(
          children: [
            // Tipo
            _buildInfoChip(
              context,
              Icons.category,
              expense.type.displayName,
            ),
            
            const SizedBox(width: 8),
            
            // Método de pago
            _buildInfoChip(
              context,
              Icons.payment,
              expense.paymentMethod.displayName,
            ),
          ],
        ),
        
        // Información del proveedor si existe
        if (expense.vendor != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.store,
                size: 16,
                color: Theme.of(context).hintColor,
              ),
              const SizedBox(width: 4),
              Text(
                expense.vendor!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ],
        
        // Etiquetas si existen
        if (expense.tags?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: expense.tags!.take(3).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  tag,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        
        // Botones de acción si están disponibles
        if (_hasQuickActions()) ...[
          const SizedBox(height: 12),
          _buildQuickActions(context),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    return Container(
      width: 4,
      height: 60,
      decoration: BoxDecoration(
        color: _getStatusColor(context),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        expense.status.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _getStatusColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (action) => _handleAction(action),
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).hintColor,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 16),
              SizedBox(width: 8),
              Text('Ver Detalles'),
            ],
          ),
        ),
        
        if (expense.canBeEdited) ...[
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text('Editar'),
              ],
            ),
          ),
        ],
        
        if (expense.canBeSubmitted) ...[
          const PopupMenuItem(
            value: 'submit',
            child: Row(
              children: [
                Icon(Icons.send, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text('Enviar para Aprobación', style: TextStyle(color: Colors.blue)),
              ],
            ),
          ),
        ],
        
        if (expense.canBeApproved) ...[
          const PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text('Aprobar', style: TextStyle(color: Colors.green)),
              ],
            ),
          ),
        ],
        
        if (expense.canBeDeleted) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Eliminar', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = <Widget>[];
    
    if (expense.canBeSubmitted) {
      actions.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Enviar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      );
    }
    
    if (expense.canBeApproved) {
      if (actions.isNotEmpty) actions.add(const SizedBox(width: 8));
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Aprobar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }
    
    if (actions.isEmpty) return const SizedBox.shrink();
    
    return Row(children: actions);
  }

  bool _hasQuickActions() {
    return expense.canBeSubmitted || expense.canBeApproved;
  }

  Color _getStatusColor(BuildContext context) {
    switch (expense.status) {
      case ExpenseStatus.draft:
        return Colors.grey;
      case ExpenseStatus.pending:
        return Colors.orange;
      case ExpenseStatus.approved:
        return Colors.green;
      case ExpenseStatus.rejected:
        return Colors.red;
      case ExpenseStatus.paid:
        return Colors.blue;
    }
  }

  String _getStatusText() {
    switch (expense.status) {
      case ExpenseStatus.draft:
        return 'Borrador';
      case ExpenseStatus.pending:
        return 'Pendiente';
      case ExpenseStatus.approved:
        return 'Aprobado';
      case ExpenseStatus.rejected:
        return 'Rechazado';
      case ExpenseStatus.paid:
        return 'Pagado';
    }
  }

  Widget _buildCompactActionsMenu(BuildContext context) {
    if (onEdit == null && onDelete == null && onApprove == null && onSubmit == null) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 16, // Más pequeño
        color: Theme.of(context).hintColor,
      ),
      iconSize: 16,
      padding: EdgeInsets.zero,
      onSelected: _handleAction,
      itemBuilder: (context) => [
        if (onEdit != null && expense.canBeEdited)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 14),
                SizedBox(width: 6),
                Text('Editar', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        if (onSubmit != null && expense.canBeSubmitted)
          const PopupMenuItem(
            value: 'submit',
            child: Row(
              children: [
                Icon(Icons.send, size: 14, color: Colors.blue),
                SizedBox(width: 6),
                Text('Enviar', style: TextStyle(color: Colors.blue, fontSize: 12)),
              ],
            ),
          ),
        if (onApprove != null && expense.canBeApproved)
          const PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green),
                SizedBox(width: 6),
                Text('Aprobar', style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 14, color: Colors.red),
                SizedBox(width: 6),
                Text('Eliminar', style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'view':
        onTap?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
      case 'approve':
        onApprove?.call();
        break;
      case 'submit':
        onSubmit?.call();
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}