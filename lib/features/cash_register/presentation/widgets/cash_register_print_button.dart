// lib/features/cash_register/presentation/widgets/cash_register_print_button.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/theme/futuristic_notifications.dart';
import '../../../invoices/presentation/controllers/thermal_printer_controller.dart';
import '../../domain/entities/cash_register.dart';
import '../../domain/services/cash_register_receipt.dart';

/// Imprime el recibo de la caja (arqueo si está abierta, cierre si ya se
/// cerró) en la impresora térmica configurada y avisa el resultado.
Future<bool> printCashRegisterReceipt({
  required CashRegister register,
  CashRegisterSummary? summary,
  double? expected,
}) async {
  final printer = Get.isRegistered<ThermalPrinterController>()
      ? Get.find<ThermalPrinterController>()
      : Get.put(ThermalPrinterController());
  final lines = buildCashRegisterReceipt(
    register: register,
    businessName: await printer.businessNameForReceipts(),
    summary: summary,
    expected: expected,
  );
  final closed = register.closedAt != null;
  final ok = await printer.printReceiptLines(
    closed ? 'Cierre de caja' : 'Arqueo de caja',
    lines,
  );
  if (ok) {
    FuturisticNotifications.showSuccess(
      'Recibo impreso',
      closed ? 'Se imprimió el cierre de caja.' : 'Se imprimió el arqueo de caja.',
    );
  } else {
    FuturisticNotifications.showError(
      'No se pudo imprimir',
      printer.lastError ?? 'Revisa la impresora en Configuración.',
    );
  }
  return ok;
}

/// Botón "Imprimir recibo" de la caja, con el tema elegante.
class CashRegisterPrintButton extends StatefulWidget {
  final CashRegister register;
  final CashRegisterSummary? summary;
  final double? expected;
  final String? label;

  const CashRegisterPrintButton({
    super.key,
    required this.register,
    this.summary,
    this.expected,
    this.label,
  });

  @override
  State<CashRegisterPrintButton> createState() => _CashRegisterPrintButtonState();
}

class _CashRegisterPrintButtonState extends State<CashRegisterPrintButton> {
  bool _printing = false;

  Future<void> _print() async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      await printCashRegisterReceipt(
        register: widget.register,
        summary: widget.summary,
        expected: widget.expected,
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final closed = widget.register.closedAt != null;
    final text = _printing
        ? 'Imprimiendo...'
        : widget.label ?? (closed ? 'Imprimir recibo del cierre' : 'Imprimir arqueo');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.35),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('cash_register_print_button'),
          onTap: _printing ? null : _print,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_printing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.print_rounded,
                      color: ElegantLightTheme.primaryBlue, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
