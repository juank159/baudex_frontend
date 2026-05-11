import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/dashboard_stats.dart';

/// Widget "Cuentas por Cobrar" con semáforo de urgencia.
/// Diseño justificado: las 3 tarjetas (Vigente / Por vencer / Vencidas)
/// tienen el MISMO ancho, alineadas en una grilla simétrica.
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
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: dominantColor.withValues(alpha: 0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: dominantColor.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(dominantColor),
                  const SizedBox(height: 16),
                  _totalRow(dominantColor),
                  const SizedBox(height: 14),
                  _urgencyBar(),
                  const SizedBox(height: 14),
                  _urgencyGrid(),
                  if (receivables.topDebtors.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _divider(),
                    const SizedBox(height: 12),
                    _topDebtors(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================ HEADER ============================

  Widget _header(Color color) {
    final statusLabel = receivables.hasOverdue
        ? 'Hay facturas vencidas'
        : receivables.hasDueSoon
            ? 'Próximas a vencer'
            : 'Cartera al día';

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.18),
                color.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cuentas por Cobrar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ElegantLightTheme.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // El label puede ser más ancho que el espacio
                  // disponible cuando la columna está apretada — Flexible
                  // con ellipsis lo recorta limpio sin reventar el flex.
                  Flexible(
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            '${receivables.count} ${receivables.count == 1 ? "factura" : "facturas"}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  // ============================ TOTAL ============================

  Widget _totalRow(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo total',
                  style: TextStyle(
                    fontSize: 11,
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.formatCurrency(receivables.total),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // Indicador del peor caso (días vencido más antiguo)
          if (receivables.hasOverdue && receivables.overdue.maxDaysOverdue > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _red.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PEOR',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: _red.withValues(alpha: 0.7),
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    '${receivables.overdue.maxDaysOverdue}d',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _red,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================ BARRA URGENCIA ============================

  Widget _urgencyBar() {
    final total = receivables.total;
    if (total <= 0) return const SizedBox.shrink();
    final currentFlex = (receivables.current.total / total * 1000).round();
    final dueSoonFlex = (receivables.dueSoon.total / total * 1000).round();
    final overdueFlex = (receivables.overdue.total / total * 1000).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                if (currentFlex > 0)
                  Expanded(
                    flex: currentFlex,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_green, _green.withValues(alpha: 0.7)],
                        ),
                      ),
                    ),
                  ),
                if (dueSoonFlex > 0)
                  Expanded(
                    flex: dueSoonFlex,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_amber, _amber.withValues(alpha: 0.7)],
                        ),
                      ),
                    ),
                  ),
                if (overdueFlex > 0)
                  Expanded(
                    flex: overdueFlex,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_red, _red.withValues(alpha: 0.7)],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================ GRID 3 CELDAS JUSTIFICADAS ============================

  /// Grilla de 3 celdas con ancho IDÉNTICO (Expanded flex:1). Antes era
  /// `Wrap` con `mainAxisSize.min` por celda — eso causaba que cada
  /// tarjeta tomara distinto ancho según el largo del texto interno y se
  /// veía desbalanceado.
  Widget _urgencyGrid() {
    // IntrinsicHeight permite que las 3 celdas tengan la MISMA altura
    // (la del contenido más alto) sin pedir altura infinita. Sin esto,
    // el `crossAxisAlignment.stretch` dentro de un SingleChildScrollView
    // pedía altura infinita y disparaba "BoxConstraints forces an
    // infinite height".
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Expanded(
          child: _urgencyCell(
            color: _green,
            label: 'Vigente',
            icon: Icons.check_circle_rounded,
            bucket: receivables.current,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _urgencyCell(
            color: _amber,
            label: 'Por vencer',
            icon: Icons.schedule_rounded,
            bucket: receivables.dueSoon,
            subtitle: receivables.dueSoon.count > 0 ? '≤ 7 días' : '—',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _urgencyCell(
            color: _red,
            label: 'Vencidas',
            icon: Icons.warning_rounded,
            bucket: receivables.overdue,
            subtitle: receivables.overdue.count > 0
                ? '${receivables.overdue.maxDaysOverdue}d atrás'
                : '—',
            urgent: receivables.overdue.count > 0,
          ),
        ),
        ],
      ),
    );
  }

  Widget _urgencyCell({
    required Color color,
    required String label,
    required IconData icon,
    required ReceivablesBucket bucket,
    String? subtitle,
    bool urgent = false,
  }) {
    final dim = bucket.count == 0;
    final bgGradient = dim
        ? LinearGradient(
            colors: [
              color.withValues(alpha: 0.03),
              color.withValues(alpha: 0.01),
            ],
          )
        : LinearGradient(
            colors: [
              color.withValues(alpha: 0.14),
              color.withValues(alpha: 0.05),
            ],
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dim
              ? color.withValues(alpha: 0.1)
              : color.withValues(alpha: urgent ? 0.55 : 0.25),
          width: urgent ? 1.4 : 1,
        ),
        boxShadow: urgent
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila superior: icono pequeño + label
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: dim
                    ? color.withValues(alpha: 0.5)
                    : color,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: dim
                        ? ElegantLightTheme.textTertiary
                        : color,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Conteo grande
          Text(
            '${bucket.count}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: dim
                  ? ElegantLightTheme.textTertiary
                  : ElegantLightTheme.textPrimary,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          // Monto bajo el conteo
          Text(
            bucket.count > 0
                ? AppFormatters.formatCurrency(bucket.total)
                : '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: dim
                  ? ElegantLightTheme.textTertiary
                  : ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: dim
                    ? color.withValues(alpha: 0.06)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: dim
                      ? ElegantLightTheme.textTertiary
                      : color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================ DIVISOR ============================

  Widget _divider() => Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              ElegantLightTheme.textTertiary.withValues(alpha: 0.25),
              Colors.transparent,
            ],
          ),
        ),
      );

  // ============================ TOP DEUDORES ============================

  Widget _topDebtors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person_pin_rounded,
              size: 14,
              color: ElegantLightTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Principales deudores',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: ElegantLightTheme.textPrimary,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...receivables.topDebtors.map(_debtorRow),
      ],
    );
  }

  Widget _debtorRow(TopDebtor d) {
    final isOverdue = d.maxDaysOverdue > 0;
    final accentColor = isOverdue ? _red : _green;
    final initial = d.customerName.isNotEmpty
        ? d.customerName[0].toUpperCase()
        : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          // Avatar circular con inicial
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.25),
                  accentColor.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
              border:
                  Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              d.customerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isOverdue)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _red.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${d.maxDaysOverdue}d',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: _red,
                ),
              ),
            ),
          Text(
            AppFormatters.formatCurrency(d.totalBalance),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isOverdue ? _red : ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
