// lib/features/cash_register/presentation/screens/cash_register_history_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/presentation/widgets/sync_status_indicator.dart';
import '../../domain/entities/cash_register.dart';
import '../controllers/cash_register_controller.dart';

/// Pantalla de historial de cajas registradoras (turnos cerrados).
///
/// Muestra una lista de turnos con resumen rápido (apertura, cierre,
/// total cobrado, diferencia). Tap en un item → bottom sheet con el
/// detalle completo del cierre.
///
/// Estilo: ElegantLightTheme con AppBar gradient + cards glass.
class CashRegisterHistoryScreen extends GetView<CashRegisterController> {
  const CashRegisterHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.history.isEmpty) {
          return _buildEmptyState();
        }
        return RefreshIndicator(
          onRefresh: controller.loadHistory,
          color: ElegantLightTheme.primaryBlue,
          backgroundColor: ElegantLightTheme.surfaceColor,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            itemCount: controller.history.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.spacingSmall),
            itemBuilder: (context, index) {
              final reg = controller.history[index];
              return _buildHistoryCard(context, reg);
            },
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(Icons.history_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Historial de cajas',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 19,
              shadows: [
                Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2)),
              ],
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Get.back(),
        tooltip: 'Volver',
      ),
      actions: [
        const SyncStatusIcon(),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refrescar',
          onPressed: controller.loadHistory,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color:
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.cardGradient,
                shape: BoxShape.circle,
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: Icon(
                Icons.history_toggle_off_rounded,
                size: 64,
                color: ElegantLightTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin cajas en el historial',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando cierres tu primera caja, el resumen del turno '
              'aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refrescar'),
              style: FilledButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              onPressed: controller.loadHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, CashRegister reg) {
    final isClosed = reg.isClosed;
    final difference = reg.closingDifference ?? 0;
    final isPerfect = isClosed && difference.abs() < 0.01;
    final isShort = isClosed && difference < -0.01;

    final accentGradient = !isClosed
        ? ElegantLightTheme.successGradient
        : isPerfect
            ? ElegantLightTheme.infoGradient
            : isShort
                ? ElegantLightTheme.errorGradient
                : ElegantLightTheme.warningGradient;
    final accentColor = !isClosed
        ? ElegantLightTheme.successGreen
        : isPerfect
            ? ElegantLightTheme.primaryBlue
            : isShort
                ? ElegantLightTheme.errorRed
                : ElegantLightTheme.warningOrange;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDetailSheet(context, reg),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: ElegantLightTheme.glassDecoration(
                borderColor: accentColor.withValues(alpha: 0.25),
                gradient: ElegantLightTheme.glassGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: accentGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isClosed
                              ? Icons.lock_outline_rounded
                              : Icons.lock_open_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppFormatters.formatDateTime(reg.openedAt),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color:
                                    ElegantLightTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 11,
                                    color: ElegantLightTheme
                                        .textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(reg.duration),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ElegantLightTheme
                                        .textSecondary,
                                  ),
                                ),
                                if (reg.openedByName != null) ...[
                                  const SizedBox(width: 10),
                                  Icon(Icons.person_outline,
                                      size: 11,
                                      color: ElegantLightTheme
                                          .textTertiary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      reg.openedByName!,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: ElegantLightTheme
                                            .textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(reg, isPerfect, isShort),
                    ],
                  ),
                  if (isClosed) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildMiniStat(
                            label: 'Saldo inicial',
                            value: AppFormatters.formatCurrency(
                                reg.openingAmount),
                            color: ElegantLightTheme.textSecondary,
                          ),
                          _buildDivider(),
                          _buildMiniStat(
                            label: 'Cobrado',
                            value: AppFormatters.formatCurrency(
                                reg.closingSummary?.cashSales ?? 0),
                            color: ElegantLightTheme.successGreen,
                          ),
                          _buildDivider(),
                          _buildMiniStat(
                            label: isPerfect
                                ? 'Cuadre'
                                : isShort
                                    ? 'Faltante'
                                    : 'Sobrante',
                            value: isPerfect
                                ? '✓'
                                : '${difference > 0 ? '+' : ''}${AppFormatters.formatCurrency(difference)}',
                            color: accentColor,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
    bool bold = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textTertiary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 14 : 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
    );
  }

  Widget _buildStatusChip(
      CashRegister reg, bool isPerfect, bool isShort) {
    final isOpen = reg.isOpen;
    final color = isOpen
        ? ElegantLightTheme.successGreen
        : isPerfect
            ? ElegantLightTheme.primaryBlue
            : isShort
                ? ElegantLightTheme.errorRed
                : ElegantLightTheme.warningOrange;
    final label = isOpen
        ? 'Activa'
        : isPerfect
            ? 'Cuadre'
            : isShort
                ? 'Faltante'
                : 'Sobrante';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  // ═══════════════════════════════════════════════════════════════
  // BOTTOM SHEET DETAIL
  // ═══════════════════════════════════════════════════════════════
  void _showDetailSheet(BuildContext context, CashRegister reg) {
    Get.bottomSheet(
      _CashRegisterDetailSheet(reg: reg),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _CashRegisterDetailSheet extends StatelessWidget {
  final CashRegister reg;

  const _CashRegisterDetailSheet({required this.reg});

  @override
  Widget build(BuildContext context) {
    final isClosed = reg.isClosed;
    final summary = reg.closingSummary ?? CashRegisterSummary.empty;
    final difference = reg.closingDifference ?? 0;
    final isPerfect = isClosed && difference.abs() < 0.01;
    final isShort = isClosed && difference < -0.01;

    final accentGradient = !isClosed
        ? ElegantLightTheme.successGradient
        : isPerfect
            ? ElegantLightTheme.infoGradient
            : isShort
                ? ElegantLightTheme.errorGradient
                : ElegantLightTheme.warningGradient;
    final accentColor = !isClosed
        ? ElegantLightTheme.successGreen
        : isPerfect
            ? ElegantLightTheme.primaryBlue
            : isShort
                ? ElegantLightTheme.errorRed
                : ElegantLightTheme.warningOrange;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: ElegantLightTheme.backgroundColor,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.textTertiary
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // ─── Header con resultado del cierre ───
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: accentGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    accentColor.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.22),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Icon(
                                  !isClosed
                                      ? Icons.lock_open_rounded
                                      : isPerfect
                                          ? Icons.check_circle_outline
                                          : isShort
                                              ? Icons
                                                  .warning_amber_rounded
                                              : Icons.add_circle_outline,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                !isClosed
                                    ? 'Caja activa'
                                    : isPerfect
                                        ? '¡Cuadre perfecto!'
                                        : isShort
                                            ? 'Faltante en caja'
                                            : 'Sobrante en caja',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (isClosed) ...[
                                const SizedBox(height: 4),
                                Text(
                                  isPerfect
                                      ? 'El efectivo contado coincide con el sistema'
                                      : '${difference > 0 ? '+' : ''}${AppFormatters.formatCurrency(difference)}',
                                  style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.95),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ─── Datos generales ───
                        _buildSectionHeader('Datos del turno'),
                        _buildDetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Apertura',
                          value:
                              AppFormatters.formatDateTime(reg.openedAt),
                          gradient: ElegantLightTheme.infoGradient,
                        ),
                        if (reg.openedByName != null)
                          _buildDetailRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Abierto por',
                            value: reg.openedByName!,
                            gradient: ElegantLightTheme.infoGradient,
                          ),
                        if (reg.closedAt != null)
                          _buildDetailRow(
                            icon: Icons.event_available_rounded,
                            label: 'Cierre',
                            value: AppFormatters.formatDateTime(
                                reg.closedAt!),
                            gradient: ElegantLightTheme.warningGradient,
                          ),
                        if (reg.closedByName != null)
                          _buildDetailRow(
                            icon: Icons.person_pin_circle_outlined,
                            label: 'Cerrado por',
                            value: reg.closedByName!,
                            gradient: ElegantLightTheme.warningGradient,
                          ),
                        _buildDetailRow(
                          icon: Icons.timer_rounded,
                          label: 'Duración',
                          value: _formatDuration(reg.duration),
                          gradient: ElegantLightTheme.primaryGradient,
                        ),

                        if (isClosed) ...[
                          const SizedBox(height: 16),
                          _buildSectionHeader('Resumen del turno'),
                          _buildDetailRow(
                            icon: Icons.savings_rounded,
                            label: 'Saldo inicial',
                            value: AppFormatters.formatCurrency(
                                reg.openingAmount),
                            gradient: ElegantLightTheme.infoGradient,
                          ),
                          _buildDetailRow(
                            icon: Icons.point_of_sale_rounded,
                            label:
                                'Ventas en efectivo (${summary.cashSalesCount})',
                            value: AppFormatters.formatCurrency(
                                summary.cashSales),
                            gradient: ElegantLightTheme.successGradient,
                          ),
                          if (summary.cashExpenses > 0)
                            _buildDetailRow(
                              icon: Icons.receipt_long_rounded,
                              label:
                                  'Gastos pagados (${summary.cashExpensesCount})',
                              value:
                                  '−${AppFormatters.formatCurrency(summary.cashExpenses)}',
                              gradient: ElegantLightTheme.warningGradient,
                              isNegative: true,
                            ),
                          if (summary.creditNotesTotal > 0)
                            _buildDetailRow(
                              icon: Icons.assignment_return_outlined,
                              label:
                                  'Notas de crédito (${summary.creditNotesCount})',
                              value:
                                  '−${AppFormatters.formatCurrency(summary.creditNotesTotal)}',
                              gradient: ElegantLightTheme.errorGradient,
                              isNegative: true,
                            ),
                          const SizedBox(height: 12),
                          _buildHighlightRow(
                            label: 'EFECTIVO ESPERADO',
                            value: AppFormatters.formatCurrency(
                                reg.closingExpectedAmount ?? 0),
                            gradient: ElegantLightTheme.primaryGradient,
                          ),
                          const SizedBox(height: 8),
                          _buildHighlightRow(
                            label: 'EFECTIVO CONTADO',
                            value: AppFormatters.formatCurrency(
                                reg.closingActualAmount ?? 0),
                            gradient: accentGradient,
                          ),
                        ],

                        if (reg.openingNotes?.isNotEmpty == true ||
                            reg.closingNotes?.isNotEmpty == true) ...[
                          const SizedBox(height: 16),
                          _buildSectionHeader('Notas'),
                          if (reg.openingNotes?.isNotEmpty == true)
                            _buildNoteCard(
                              title: 'Notas de apertura',
                              content: reg.openingNotes!,
                            ),
                          if (reg.closingNotes?.isNotEmpty == true)
                            _buildNoteCard(
                              title: 'Notas de cierre',
                              content: reg.closingNotes!,
                            ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: ElegantLightTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required LinearGradient gradient,
    bool isNegative = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ElegantLightTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gradient.colors.first.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isNegative
                  ? ElegantLightTheme.errorRed
                  : ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightRow({
    required String label,
    required String value,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 1.2,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ElegantLightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: ElegantLightTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}
