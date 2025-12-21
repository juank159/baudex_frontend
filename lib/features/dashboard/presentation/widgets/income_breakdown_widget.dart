import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/dashboard_stats.dart';

class IncomeBreakdownWidget extends StatelessWidget {
  final DashboardStats stats;

  const IncomeBreakdownWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: ElegantLightTheme.glassDecoration(
            borderColor: ElegantLightTheme.primaryBlue.withOpacity(0.3),
            gradient: ElegantLightTheme.glassGradient,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header fijo (fuera del ScrollView)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _buildHeader(),
              ),
              const Divider(height: 1, thickness: 1),
              // Contenido con scroll
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIncomeTypeSection(),
                      const Divider(height: 16, thickness: 0.5),
                      _buildPaymentMethodsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF10B981), // Green-500
                Color(0xFF059669), // Green-600
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Desglose de Ingresos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ElegantLightTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Análisis detallado de ingresos',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeTypeSection() {
    final breakdown = stats.incomeTypeBreakdown;
    final invoicesPercent = breakdown.total > 0
        ? (breakdown.invoices / breakdown.total * 100).toDouble()
        : 0.0;
    final creditsPercent = breakdown.total > 0
        ? (breakdown.credits / breakdown.total * 100).toDouble()
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Por Tipo de Ingreso',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ElegantLightTheme.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),

        // Facturas
        _buildIncomeTypeItem(
          icon: Icons.receipt_long_rounded,
          label: 'Facturas Pagadas',
          amount: breakdown.invoices,
          percentage: invoicesPercent,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 6),

        // Créditos
        _buildIncomeTypeItem(
          icon: Icons.credit_card_rounded,
          label: 'Créditos Aplicados',
          amount: breakdown.credits,
          percentage: creditsPercent,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 8),

        // Total
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.paid, color: ElegantLightTheme.primaryBlue, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Total Ingresos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                AppFormatters.formatCurrency(breakdown.total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeTypeItem({
    required IconData icon,
    required String label,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      AppFormatters.formatCurrency(amount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    final methods = stats.paymentMethodsBreakdown;

    if (methods.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos de métodos de pago',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Por Método de Pago',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ElegantLightTheme.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        ...methods.map((method) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildPaymentMethodItem(method),
        )),
      ],
    );
  }

  Widget _buildPaymentMethodItem(PaymentMethodStats method) {
    final color = _getColorForMethod(method.method);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getIconForMethod(method.method), color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayName(method.method),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${method.count} ${method.count == 1 ? "transacción" : "transacciones"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatCurrency(method.totalAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${method.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: method.percentage / 100,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
      case 'efectivo':
        return Colors.green;
      case 'nequi':
        return const Color(0xFFFF0090);
      case 'bancolombia':
        return const Color(0xFFFFDD00);
      case 'daviplata':
        return const Color(0xFFED1C24);
      case 'transfer':
      case 'transferencia':
        return Colors.blue;
      case 'card':
      case 'tarjeta':
        return Colors.purple;
      case 'credit':
      case 'credito':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
      case 'efectivo':
        return Icons.payments;
      case 'nequi':
      case 'bancolombia':
      case 'daviplata':
        return Icons.account_balance;
      case 'transfer':
      case 'transferencia':
        return Icons.swap_horiz;
      case 'card':
      case 'tarjeta':
        return Icons.credit_card;
      case 'credit':
      case 'credito':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  String _getDisplayName(String method) {
    final names = {
      'cash': 'Efectivo',
      'nequi': 'Nequi',
      'bancolombia': 'Bancolombia',
      'daviplata': 'Daviplata',
      'transfer': 'Transferencia',
      'card': 'Tarjeta',
      'credit': 'Crédito',
    };
    return names[method.toLowerCase()] ?? method.toUpperCase();
  }
}
