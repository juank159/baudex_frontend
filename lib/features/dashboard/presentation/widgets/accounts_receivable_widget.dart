import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/dashboard_stats.dart';

/// Widget "Cuentas por Cobrar" con semáforo de urgencia.
/// Siempre visible cuando hay facturas pendientes; escondido en caso contrario.
class AccountsReceivableWidget extends StatelessWidget {
  final ReceivablesStats receivables;
  final VoidCallback? onTap;

  const AccountsReceivableWidget({
    super.key,
    required this.receivables,
    this.onTap,
  });

  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    if (!receivables.hasAny) return const SizedBox.shrink();

    final dominantColor = receivables.hasOverdue
        ? _red
        : receivables.hasDueSoon
            ? _amber
            : _green;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dominantColor.withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: dominantColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(dominantColor),
                const SizedBox(height: 14),
                _totalRow(dominantColor),
                const SizedBox(height: 14),
                _urgencyBar(),
                const SizedBox(height: 12),
                _urgencyChips(),
                if (receivables.topDebtors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _divider(),
                  const SizedBox(height: 12),
                  _topDebtors(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(Color color) {
    final statusLabel = receivables.hasOverdue
        ? 'Hay facturas vencidas'
        : receivables.hasDueSoon
            ? 'Próximas a vencer'
            : 'Cartera al día';

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.account_balance_wallet_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cuentas por Cobrar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${receivables.count} ${receivables.count == 1 ? "factura" : "facturas"}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _totalRow(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Saldo total',
          style: TextStyle(
            fontSize: 12,
            color: ElegantLightTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          AppFormatters.formatCurrency(receivables.total),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Barra segmentada estilo "stacked" con proporciones verde/amarillo/rojo.
  Widget _urgencyBar() {
    final total = receivables.total;
    if (total <= 0) return const SizedBox.shrink();
    final currentFlex = (receivables.current.total / total * 1000).round();
    final dueSoonFlex = (receivables.dueSoon.total / total * 1000).round();
    final overdueFlex = (receivables.overdue.total / total * 1000).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (currentFlex > 0) Expanded(flex: currentFlex, child: Container(color: _green)),
            if (dueSoonFlex > 0) Expanded(flex: dueSoonFlex, child: Container(color: _amber)),
            if (overdueFlex > 0) Expanded(flex: overdueFlex, child: Container(color: _red)),
          ],
        ),
      ),
    );
  }

  Widget _urgencyChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          color: _green,
          label: 'Vigente',
          bucket: receivables.current,
        ),
        _chip(
          color: _amber,
          label: 'Por vencer',
          bucket: receivables.dueSoon,
          subtitle: receivables.dueSoon.count > 0 ? '≤ 7 días' : null,
        ),
        _chip(
          color: _red,
          label: 'Vencidas',
          bucket: receivables.overdue,
          subtitle: receivables.overdue.count > 0
              ? '${receivables.overdue.maxDaysOverdue}d atrás'
              : null,
          urgent: receivables.overdue.count > 0,
        ),
      ],
    );
  }

  Widget _chip({
    required Color color,
    required String label,
    required ReceivablesBucket bucket,
    String? subtitle,
    bool urgent = false,
  }) {
    final dim = bucket.count == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: dim ? color.withOpacity(0.05) : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: urgent
            ? Border.all(color: color.withOpacity(0.6), width: 1.2)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dim ? color.withOpacity(0.4) : color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label · ${bucket.count}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: dim ? ElegantLightTheme.textSecondary : color,
                ),
              ),
              if (bucket.count > 0) ...[
                const SizedBox(height: 1),
                Text(
                  AppFormatters.formatCurrency(bucket.total),
                  style: const TextStyle(
                    fontSize: 10,
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        color: ElegantLightTheme.textSecondary.withOpacity(0.1),
      );

  Widget _topDebtors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Principales deudores',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ElegantLightTheme.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        ...receivables.topDebtors.map(_debtorRow),
      ],
    );
  }

  Widget _debtorRow(TopDebtor d) {
    final isOverdue = d.maxDaysOverdue > 0;
    final color = isOverdue ? _red : ElegantLightTheme.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOverdue ? _red : _green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              d.customerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isOverdue) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${d.maxDaysOverdue}d',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _red,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            AppFormatters.formatCurrency(d.totalBalance),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
