// lib/features/cash_register/presentation/widgets/cash_register_movements_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/cash_register_movement.dart';
import '../../domain/services/cash_register_movements.dart';
import '../controllers/cash_register_controller.dart';

/// Abre el detalle (trazabilidad) de una línea del desglose de la caja:
/// cada pago con su hora, quién pagó, banco, factura y valor.
Future<void> showCashRegisterMovements(
  BuildContext context, {
  required String cashRegisterId,
  required CashMovementFilter filter,
  required IconData icon,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => CashRegisterMovementsDialog(
      cashRegisterId: cashRegisterId,
      filter: filter,
      icon: icon,
    ),
  );
}

class CashRegisterMovementsDialog extends StatefulWidget {
  final String cashRegisterId;
  final CashMovementFilter filter;
  final IconData icon;

  const CashRegisterMovementsDialog({
    super.key,
    required this.cashRegisterId,
    required this.filter,
    required this.icon,
  });

  @override
  State<CashRegisterMovementsDialog> createState() => _CashRegisterMovementsDialogState();
}

class _CashRegisterMovementsDialogState extends State<CashRegisterMovementsDialog> {
  bool _loading = true;
  String? _error;
  List<CashRegisterMovement> _items = const [];
  DateTime? _savedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await Get.find<CashRegisterController>().loadMovements(widget.cashRegisterId);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (movements) => setState(() {
        _loading = false;
        _items = movementsFor(movements.items, widget.filter);
        _savedAt = movements.savedAt;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context),
            Flexible(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final count = _items.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.12))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.filter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _loading || _error != null
                      ? 'Detalle del turno'
                      : '$count ${count == 1 ? 'movimiento' : 'movimientos'} · '
                          '${AppFormatters.formatCurrency(movementsTotal(_items))}',
                  style: const TextStyle(fontSize: 12.5, color: ElegantLightTheme.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: ElegantLightTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }
    if (_error != null) {
      return _message(
        icon: Icons.cloud_off_rounded,
        text: _error!,
        action: TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Intentar de nuevo'),
          style: TextButton.styleFrom(foregroundColor: ElegantLightTheme.primaryBlue),
        ),
      );
    }
    if (_items.isEmpty) {
      return _message(
        icon: Icons.inbox_outlined,
        text: _savedAt != null
            ? 'No hay movimientos guardados en este equipo para esta línea.'
            : 'No hay movimientos en esta línea.',
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      children: [
        if (_savedAt != null) _savedNotice(_savedAt!),
        for (final m in _items) _MovementTile(movement: m),
      ],
    );
  }

  Widget _savedNotice(DateTime savedAt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ElegantLightTheme.warningOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ElegantLightTheme.warningOrange.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: ElegantLightTheme.warningOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin conexión: se muestra lo guardado (${AppFormatters.formatDateTime(savedAt)}). '
              'Lo cobrado después aparecerá cuando vuelva el internet.',
              style: const TextStyle(fontSize: 12, color: ElegantLightTheme.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message({required IconData icon, required String text, Widget? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: ElegantLightTheme.textTertiary),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: ElegantLightTheme.textSecondary, height: 1.35),
          ),
          if (action != null) ...[const SizedBox(height: 10), action],
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final CashRegisterMovement movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final m = movement;
    final isExpense = m.kind == CashMovementKind.expense;
    final color = isExpense ? ElegantLightTheme.warningOrange : ElegantLightTheme.primaryBlue;
    final details = movementDetails(m);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hora y fecha
          SizedBox(
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movementTime(m.at),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                Text(
                  AppFormatters.formatDate(m.at),
                  style: const TextStyle(fontSize: 10.5, color: ElegantLightTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movementTitle(m),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    details.join(' · '),
                    style: const TextStyle(fontSize: 11.5, color: ElegantLightTheme.textSecondary, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isExpense ? '−' : ''}${AppFormatters.formatCurrency(m.amount)}',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isExpense ? ElegantLightTheme.errorRed : ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
