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
                'Desglose de ingresos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ElegantLightTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'De dónde viene tu dinero',
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
    final total = breakdown.total;
    double pct(double value) => total > 0 ? (value / total * 100) : 0.0;
    final hasOldPayments = breakdown.paymentsOnOldInvoices > 0;
    final hasCredits = breakdown.credits > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Origen del ingreso',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ElegantLightTheme.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),

        // Ventas nuevas del período
        _buildIncomeTypeItem(
          icon: Icons.receipt_long_rounded,
          label: 'Ventas del período',
          amount: breakdown.newInvoices,
          percentage: pct(breakdown.newInvoices),
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 6),

        // Abonos a facturas antiguas (solo si hay)
        if (hasOldPayments) ...[
          _buildIncomeTypeItem(
            icon: Icons.history_rounded,
            label: 'Abonos a facturas anteriores',
            amount: breakdown.paymentsOnOldInvoices,
            percentage: pct(breakdown.paymentsOnOldInvoices),
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 6),
        ],

        // Saldo a favor usado (solo si hay). Antes se llamaba "Créditos Aplicados"
        // pero ese término se confundía con ventas a crédito, tarjeta o notas de crédito.
        if (hasCredits) ...[
          _buildIncomeTypeItem(
            icon: Icons.savings_rounded,
            label: 'Saldo a favor usado',
            amount: breakdown.credits,
            percentage: pct(breakdown.credits),
            color: const Color(0xFF3B82F6),
            tooltip:
                'Cuando un cliente paga una factura con dinero que te había dejado antes (anticipos o devoluciones). No es efectivo nuevo que recibes.',
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 2),

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total facturado (accrual)
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: ElegantLightTheme.primaryBlue, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Total facturado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppFormatters.formatCurrency(breakdown.total),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              // Total cobrado (cash) — solo si difiere
              if (stats.totalCollected > 0 && (breakdown.total - stats.totalCollected).abs() > 1) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Dinero cobrado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppFormatters.formatCurrency(stats.totalCollected),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
              // Phase 1B: Devoluciones (NCs aplicadas) — solo si hay
              if (stats.creditNotesTotal > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.assignment_return_outlined,
                        color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Devoluciones (${stats.creditNotesCount} NC)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '−${AppFormatters.formatCurrency(stats.creditNotesTotal)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: stats.netRevenue > 0
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: stats.netRevenue > 0
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.savings_rounded,
                          color: stats.netRevenue > 0
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'INGRESO REAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: stats.netRevenue > 0
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppFormatters.formatCurrency(stats.netRevenue),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stats.netRevenue > 0
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    String? tooltip,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (tooltip != null) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: tooltip,
                        preferBelow: false,
                        triggerMode: TooltipTriggerMode.tap,
                        showDuration: const Duration(seconds: 6),
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: color.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
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
          'Forma de pago',
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
      case 'bank_transfer':
      case 'transfer':
      case 'transferencia':
        return Colors.blue;
      case 'credit_card':
      case 'card':
      case 'tarjeta':
        return Colors.purple;
      case 'debit_card':
        return Colors.indigo;
      case 'credit':
      case 'credito':
        return Colors.orange;
      case 'client_balance':
        return Colors.teal;
      case 'check':
      case 'cheque':
        return Colors.brown;
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
      case 'bank_transfer':
      case 'transfer':
      case 'transferencia':
        return Icons.swap_horiz;
      case 'credit_card':
      case 'debit_card':
      case 'card':
      case 'tarjeta':
        return Icons.credit_card;
      case 'credit':
      case 'credito':
        return Icons.account_balance_wallet;
      case 'client_balance':
        return Icons.account_balance_wallet;
      case 'check':
      case 'cheque':
        return Icons.receipt;
      default:
        return Icons.payment;
    }
  }

  String _getDisplayName(String method) {
    // Nombres canónicos. Los string ya siempre llegan como enum.value del backend.
    const names = <String, String>{
      'cash': 'Efectivo',
      'credit': 'Crédito',
      'credit_card': 'Tarjeta de Crédito',
      'debit_card': 'Tarjeta de Débito',
      'bank_transfer': 'Transferencia',
      'check': 'Cheque',
      'client_balance': 'Saldo a Favor',
      'other': 'Otro',
    };
    // Si no matchea un enum, puede ser el nombre de una cuenta bancaria
    // (Nequi, Daviplata, etc.) — devolvemos tal cual.
    return names[method.toLowerCase()] ?? method;
  }
}
