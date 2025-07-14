// lib/features/customers/presentation/widgets/modern_customer_card_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../domain/entities/customer.dart';

class ModernCustomerCardWidget extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ModernCustomerCardWidget({
    super.key,
    required this.customer,
    this.onTap,
    this.onEdit,
    this.onDelete,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12), // Reducido de 16 a 12
            child: Column(
              children: [
                // Header compacto
                Row(
                  children: [
                    // Avatar ultra compacto
                    Container(
                      width: 36, // Reducido de 40 a 36
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _getStatusColor().withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        customer.companyName != null ? Icons.business : Icons.person,
                        size: 18, // Reducido de 20 a 18
                        color: _getStatusColor(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Info principal compacta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.displayName,
                            style: const TextStyle(
                              fontSize: 14, // Reducido de 16 a 14
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer.email,
                            style: TextStyle(
                              fontSize: 12, // Reducido de 14 a 12
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Badge de estado compacto
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Más compacto
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 10, // Reducido de 12 a 10
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8), // Reducido de 12 a 8
                
                // Info adicional ultra compacta
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInfoChip(
                        Icons.credit_card,
                        _formatCurrency(customer.creditLimit),
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildCompactInfoChip(
                        Icons.shopping_cart,
                        '${customer.totalOrders}',
                        Colors.orange,
                      ),
                    ),
                    if (customer.currentBalance > 0) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildCompactInfoChip(
                          Icons.account_balance_wallet,
                          _formatCurrency(customer.currentBalance),
                          customer.currentBalance > customer.creditLimit * 0.8
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Acciones compactas
                Row(
                  children: [
                    if (onEdit != null)
                      Expanded(
                        child: _buildActionButton(
                          'Editar',
                          Icons.edit,
                          Theme.of(context).primaryColor,
                          onEdit!,
                        ),
                      ),
                    if (onEdit != null && onDelete != null) const SizedBox(width: 8),
                    if (onDelete != null)
                      Expanded(
                        child: _buildActionButton(
                          'Eliminar',
                          Icons.delete,
                          Colors.red,
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16), // Reducido de 24 a 16
            child: Row(
              children: [
                // Avatar compacto
                Container(
                  width: 44, // Reducido de 56 a 44
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    customer.companyName != null ? Icons.business : Icons.person,
                    size: 22, // Reducido de 28 a 22
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info principal
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.displayName,
                              style: const TextStyle(
                                fontSize: 16, // Reducido de 20 a 16
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              customer.email,
                              style: TextStyle(
                                fontSize: 13, // Reducido de 14 a 13
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.badge, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            customer.formattedDocument,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Info adicional compacta
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDesktopInfoRow(
                        Icons.credit_card,
                        'Crédito',
                        _formatCurrency(customer.creditLimit),
                        Colors.blue,
                      ),
                      const SizedBox(height: 4),
                      _buildDesktopInfoRow(
                        Icons.shopping_cart,
                        'Órdenes',
                        '${customer.totalOrders}',
                        Colors.orange,
                      ),
                      if (customer.currentBalance > 0) ...[
                        const SizedBox(height: 4),
                        _buildDesktopInfoRow(
                          Icons.account_balance_wallet,
                          'Balance',
                          _formatCurrency(customer.currentBalance),
                          customer.currentBalance > customer.creditLimit * 0.8
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Acciones
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: 'Editar cliente',
                        color: Theme.of(context).primaryColor,
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 18),
                        tooltip: 'Eliminar cliente',
                        color: Colors.red,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
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

  Widget _buildCompactInfoChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
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
                fontWeight: FontWeight.w600,
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

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
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
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
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
    switch (customer.status) {
      case CustomerStatus.active:
        return Colors.green;
      case CustomerStatus.inactive:
        return Colors.orange;
      case CustomerStatus.suspended:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (customer.status) {
      case CustomerStatus.active:
        return 'ACTIVO';
      case CustomerStatus.inactive:
        return 'INACTIVO';
      case CustomerStatus.suspended:
        return 'SUSPENDIDO';
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null || amount.isNaN || amount.isInfinite) {
      return '\$0';
    }

    final absoluteAmount = amount.abs();
    final isNegative = amount < 0;
    String result;

    if (absoluteAmount >= 1000000) {
      result = '\$${(absoluteAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absoluteAmount >= 1000) {
      result = '\$${(absoluteAmount / 1000).toStringAsFixed(1)}K';
    } else {
      result = '\$${absoluteAmount.toStringAsFixed(0)}';
    }

    return isNegative ? '-$result' : result;
  }
}