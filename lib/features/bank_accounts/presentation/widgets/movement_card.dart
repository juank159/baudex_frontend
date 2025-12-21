// lib/features/bank_accounts/presentation/widgets/movement_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/bank_account_transaction.dart';

/// Widget para mostrar una transacción/movimiento de cuenta bancaria con animaciones
class MovementCard extends StatefulWidget {
  final BankAccountTransaction transaction;

  const MovementCard({
    super.key,
    required this.transaction,
  });

  @override
  State<MovementCard> createState() => _MovementCardState();
}

class _MovementCardState extends State<MovementCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.smoothCurve,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _onHover(true),
            onExit: (_) => _onHover(false),
            child: GestureDetector(
              onTap: () => _showTransactionDetails(context),
              child: AnimatedContainer(
                duration: ElegantLightTheme.normalAnimation,
                curve: ElegantLightTheme.smoothCurve,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.cardGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isHovered
                        ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                        : ElegantLightTheme.textTertiary.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    if (_isHovered) ...ElegantLightTheme.glowShadow,
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icono según el tipo de transacción
                          _buildTypeIcon(),
                          const SizedBox(width: 12),

                          // Información principal
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tipo de transacción
                                Text(
                                  widget.transaction.type.displayName,
                                  style: const TextStyle(
                                    color: ElegantLightTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Cliente (si existe)
                                if (widget.transaction.customer != null)
                                  Text(
                                    widget.transaction.customer!.name,
                                    style: const TextStyle(
                                      color: ElegantLightTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),

                          // Monto
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormat.currency(
                                  symbol: '\$',
                                  decimalDigits: 0,
                                ).format(widget.transaction.amount),
                                style: const TextStyle(
                                  color: ElegantLightTheme.successGreen,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Fecha
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(widget.transaction.date),
                                style: const TextStyle(
                                  color: ElegantLightTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Separador si hay información adicional
                      if (_hasAdditionalInfo) ...[
                        const SizedBox(height: 10),
                        Container(
                          height: 1,
                          color:
                              ElegantLightTheme.textSecondary.withOpacity(0.1),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Información adicional
                      if (_hasAdditionalInfo)
                        Row(
                          children: [
                            // Número de factura (si existe)
                            if (widget.transaction.invoice != null)
                              Expanded(
                                child: _buildInfoChip(
                                  Icons.receipt_rounded,
                                  'Factura ${widget.transaction.invoice!.invoiceNumber}',
                                  ElegantLightTheme.primaryBlue,
                                ),
                              ),

                            if (widget.transaction.invoice != null &&
                                widget.transaction.paymentMethod.isNotEmpty)
                              const SizedBox(width: 8),

                            // Método de pago
                            if (widget.transaction.paymentMethod.isNotEmpty)
                              Expanded(
                                child: _buildInfoChip(
                                  _getPaymentMethodIcon(
                                      widget.transaction.paymentMethod),
                                  widget.transaction.paymentMethod,
                                  ElegantLightTheme.warningOrange,
                                ),
                              ),
                          ],
                        ),

                      // Descripción (si existe y no es vacía)
                      if (widget.transaction.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.transaction.description,
                          style: const TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (widget.transaction.type) {
      case TransactionType.invoicePayment:
        icon = Icons.shopping_cart_rounded;
        color = ElegantLightTheme.primaryBlue;
        break;
      case TransactionType.creditPayment:
        icon = Icons.account_balance_wallet_rounded;
        color = ElegantLightTheme.successGreen;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: color,
        size: 22,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    final methodLower = method.toLowerCase();
    if (methodLower.contains('efectivo') || methodLower.contains('cash')) {
      return Icons.payments_rounded;
    } else if (methodLower.contains('nequi')) {
      return Icons.phone_android_rounded;
    } else if (methodLower.contains('daviplata')) {
      return Icons.smartphone_rounded;
    } else if (methodLower.contains('banco') ||
        methodLower.contains('transferencia')) {
      return Icons.account_balance_rounded;
    } else if (methodLower.contains('tarjeta') ||
        methodLower.contains('card')) {
      return Icons.credit_card_rounded;
    }
    return Icons.payment_rounded;
  }

  bool get _hasAdditionalInfo =>
      widget.transaction.invoice != null ||
      widget.transaction.paymentMethod.isNotEmpty;

  void _showTransactionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ElegantLightTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildTypeIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.transaction.type.displayName,
                    style: const TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Detalles
            _buildDetailRow(
                'Monto',
                NumberFormat.currency(
                  symbol: '\$',
                  decimalDigits: 2,
                ).format(widget.transaction.amount)),
            _buildDetailRow('Fecha',
                DateFormat('dd/MM/yyyy HH:mm').format(widget.transaction.date)),
            _buildDetailRow('Método de pago', widget.transaction.paymentMethod),

            if (widget.transaction.customer != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Cliente',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              _buildDetailRow('Nombre', widget.transaction.customer!.name),
              if (widget.transaction.customer!.email != null)
                _buildDetailRow('Email', widget.transaction.customer!.email!),
              if (widget.transaction.customer!.phone != null)
                _buildDetailRow('Teléfono', widget.transaction.customer!.phone!),
            ],

            if (widget.transaction.invoice != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Factura',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              _buildDetailRow(
                  'Número', widget.transaction.invoice!.invoiceNumber),
              _buildDetailRow(
                  'Total',
                  NumberFormat.currency(
                    symbol: '\$',
                    decimalDigits: 2,
                  ).format(widget.transaction.invoice!.total)),
            ],

            if (widget.transaction.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Descripción',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.transaction.description,
                style: const TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],

            if (widget.transaction.notes != null &&
                widget.transaction.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Notas',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.transaction.notes!,
                style: const TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
