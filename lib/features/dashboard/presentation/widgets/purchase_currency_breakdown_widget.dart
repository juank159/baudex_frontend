import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/dashboard_stats.dart';

/// Widget "Compras por moneda" — análogo a CurrencyBreakdownWidget (pagos)
/// pero leyendo `stats.purchaseCurrencyBreakdown`. Se oculta si no hay data.
/// Mantiene misma estructura visual: fila por moneda con total en extranjera
/// arriba + equivalente en base abajo, barra de %, tasa promedio, y total.
class PurchaseCurrencyBreakdownWidget extends StatelessWidget {
  final DashboardStats stats;

  const PurchaseCurrencyBreakdownWidget({super.key, required this.stats});

  static const _accent = Color(0xFFE11D48); // rose-600 (compras ≠ pagos)
  static const _accentDark = Color(0xFFBE123C);

  @override
  Widget build(BuildContext context) {
    final breakdown = stats.purchaseCurrencyBreakdown;
    if (breakdown == null || breakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: ElegantLightTheme.glassDecoration(
            borderColor: _accent.withValues(alpha: 0.3),
            gradient: ElegantLightTheme.glassGradient,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _buildHeader(),
              ),
              const Divider(height: 1, thickness: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...breakdown.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _buildCurrencyItem(item),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildTotal(breakdown),
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
              colors: [_accent, _accentDark],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.shopping_cart_checkout_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Compras por moneda',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ElegantLightTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Gastado en cada moneda del período',
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

  Widget _buildCurrencyItem(CurrencyBreakdownStats item) {
    final color = _getColorForCurrency(item.currency);
    final isBase = item.currency == stats.baseCurrency;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getFlagForCurrency(item.currency),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.currency,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.count} ${item.count == 1 ? "compra" : "compras"}',
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
                  if (!isBase) ...[
                    Text(
                      AppFormatters.formatForeignCurrency(
                        item.totalForeignAmount,
                        item.currency,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatCurrency(item.totalBaseAmount),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Text(
                      AppFormatters.formatCurrency(item.totalBaseAmount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.percentage.toStringAsFixed(1)}%',
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
          if (!isBase) ...[
            const SizedBox(height: 4),
            Text(
              AppFormatters.formatExchangeInfo(
                item.currency,
                item.avgRate,
                stats.baseCurrency,
              ),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.percentage / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotal(List<CurrencyBreakdownStats> breakdown) {
    final total = breakdown.fold<double>(
      0,
      (sum, item) => sum + item.totalBaseAmount,
    );
    final totalCount = breakdown.fold<int>(0, (sum, item) => sum + item.count);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.summarize_rounded, color: _accent, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Total gastado ($totalCount ${totalCount == 1 ? "compra" : "compras"})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ),
          Text(
            AppFormatters.formatCurrency(total),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForCurrency(String currency) {
    switch (currency.toUpperCase()) {
      case 'COP':
        return const Color(0xFF10B981);
      case 'USD':
        return const Color(0xFF3B82F6);
      case 'EUR':
        return const Color(0xFF6366F1);
      case 'VES':
        return const Color(0xFFF59E0B);
      case 'BRL':
        return const Color(0xFF22C55E);
      case 'MXN':
        return const Color(0xFFEF4444);
      default:
        return _accent;
    }
  }

  String _getFlagForCurrency(String currency) {
    switch (currency.toUpperCase()) {
      case 'COP':
        return '\u{1F1E8}\u{1F1F4}';
      case 'USD':
        return '\u{1F1FA}\u{1F1F8}';
      case 'EUR':
        return '\u{1F1EA}\u{1F1FA}';
      case 'VES':
        return '\u{1F1FB}\u{1F1EA}';
      case 'BRL':
        return '\u{1F1E7}\u{1F1F7}';
      case 'MXN':
        return '\u{1F1F2}\u{1F1FD}';
      default:
        return '\u{1F4B1}';
    }
  }
}
