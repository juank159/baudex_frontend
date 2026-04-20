import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/dashboard_stats.dart';

/// Widget "Resumen de caja": muestra los 3 orígenes del dinero que entró al
/// negocio en el período (ventas, abonos a préstamos, anticipos). Separa los
/// conceptos para no inflar las ventas con recuperación de cartera o pasivos.
///
/// Se oculta cuando no hay movimientos en ningún concepto.
class CashFlowSummaryWidget extends StatelessWidget {
  final CashFlowStats cashFlow;

  const CashFlowSummaryWidget({super.key, required this.cashFlow});

  static const _salesColor = Color(0xFF10B981);
  static const _loanColor = Color(0xFFF59E0B);
  static const _depositColor = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    if (!cashFlow.hasAny) return const SizedBox.shrink();

    final total = cashFlow.totalCashIn;
    double pct(double v) => total > 0 ? (v / total * 100) : 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: ElegantLightTheme.glassDecoration(
            borderColor: _salesColor.withValues(alpha: 0.25),
            gradient: ElegantLightTheme.glassGradient,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _buildHeader(total),
              ),
              const Divider(height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    _buildRow(
                      icon: Icons.point_of_sale_rounded,
                      label: 'Cobros por ventas',
                      subtitle: _countLabel(cashFlow.salesCollectedCount, 'pago', 'pagos'),
                      amount: cashFlow.salesCollected,
                      percentage: pct(cashFlow.salesCollected),
                      color: _salesColor,
                      tooltip:
                          'Dinero que entró por cobrar facturas. Es tu ingreso operativo real.',
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      icon: Icons.history_edu_rounded,
                      label: 'Abonos a préstamos',
                      subtitle: _countLabel(cashFlow.loanPaymentsCount, 'abono', 'abonos'),
                      amount: cashFlow.loanPayments,
                      percentage: pct(cashFlow.loanPayments),
                      color: _loanColor,
                      tooltip:
                          'Cuando un cliente te paga dinero que le habías prestado (crédito directo sin factura). No es venta nueva, es recuperación de cartera.',
                      breakdown: cashFlow.loanPaymentsBreakdown,
                    ),
                    const SizedBox(height: 8),
                    _buildRow(
                      icon: Icons.savings_rounded,
                      label: 'Anticipos recibidos',
                      subtitle: _countLabel(cashFlow.customerDepositsCount, 'depósito', 'depósitos'),
                      amount: cashFlow.customerDeposits,
                      percentage: pct(cashFlow.customerDeposits),
                      color: _depositColor,
                      tooltip:
                          'Dinero que un cliente te deja como saldo a favor antes de facturar. Es un pasivo (lo debes) hasta que se aplique a una factura futura.',
                      breakdown: cashFlow.customerDepositsBreakdown,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double total) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _salesColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de caja',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ElegantLightTheme.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Todo el dinero que entró en el período',
                style: TextStyle(
                  fontSize: 12,
                  color: ElegantLightTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 10,
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              AppFormatters.formatCurrency(total.toInt()),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _salesColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required double amount,
    required double percentage,
    required Color color,
    required String tooltip,
    List<CashFlowMethodRow> breakdown = const [],
  }) {
    final hasBreakdown = breakdown.isNotEmpty && amount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainRow(
            icon: icon,
            label: label,
            subtitle: subtitle,
            amount: amount,
            percentage: percentage,
            color: color,
            tooltip: tooltip,
          ),
          if (hasBreakdown) ...[
            const SizedBox(height: 8),
            _buildBreakdownList(breakdown, color),
          ],
        ],
      ),
    );
  }

  Widget _buildMainRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required double amount,
    required double percentage,
    required Color color,
    required String tooltip,
  }) {
    return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: tooltip,
                      preferBelow: false,
                      triggerMode: TooltipTriggerMode.tap,
                      showDuration: const Duration(seconds: 6),
                      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
                AppFormatters.formatCurrency(amount.toInt()),
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
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
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
    );
  }

  Widget _buildBreakdownList(List<CashFlowMethodRow> rows, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dónde se recibió',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.85),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _friendlyMethodName(r.method),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${r.count} ${r.count == 1 ? "mov" : "movs"}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppFormatters.formatCurrency(r.total.toInt()),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Convierte valores crudos de paymentMethod (ej. 'cash') en labels amigables.
  /// Los nombres de cuentas bancarias pasan tal cual.
  String _friendlyMethodName(String raw) {
    const map = <String, String>{
      'cash': 'Efectivo',
      'credit': 'Saldo a favor',
      'credit_card': 'Tarjeta de crédito',
      'debit_card': 'Tarjeta de débito',
      'bank_transfer': 'Transferencia',
      'check': 'Cheque',
      'client_balance': 'Saldo a favor',
      'other': 'Otro',
      'Sin especificar': 'Sin cuenta asignada',
    };
    return map[raw.toLowerCase()] ?? map[raw] ?? raw;
  }

  String _countLabel(int count, String singular, String plural) {
    if (count == 0) return 'Sin movimientos';
    return '$count ${count == 1 ? singular : plural}';
  }
}
