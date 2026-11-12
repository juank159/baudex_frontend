// lib/features/breb/presentation/widgets/breb_credit_charge_button.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/theme/futuristic_notifications.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../settings/presentation/controllers/organization_controller.dart';
import '../../domain/breb_charge.dart';
import 'breb_payment_dialog.dart';

/// ¿Se puede cobrar este crédito por Bre-B? El negocio debe tener llaves y el
/// crédito ya debe estar en el servidor (uno creado sin conexión y aún sin
/// subir no se puede cobrar así: lo confirma el banco a través del servidor).
bool canChargeCreditWithBreb(String creditId) {
  final synced = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F-]{27}$').hasMatch(creditId);
  if (!synced || !Get.isRegistered<OrganizationController>()) return false;
  return brebEnabled(Get.find<OrganizationController>().currentOrganization?.settings);
}

/// Motivo por el que no se puede cobrar ese valor por Bre-B, o `null` si sí.
/// [amount] `null` (campo vacío) significa "todo el saldo".
String? brebCreditAmountProblem({required double? amount, required double balance}) {
  if (balance <= 0) return 'Este crédito no tiene saldo por cobrar.';
  if (amount == null) return null;
  if (amount <= 0) return 'Escribe un valor mayor que cero.';
  if (amount > balance) {
    return 'El valor (${AppFormatters.formatCurrency(amount)}) es mayor que el saldo '
        '(${AppFormatters.formatCurrency(balance)}).';
  }
  return null;
}

/// Opción "Cobrar con Bre-B (QR)" para un abono o el pago total de un crédito.
///
/// Va dentro de los formularios de abono: toma el valor que el cajero escribió
/// (o todo el saldo si está vacío), muestra el QR y espera el aviso del banco.
/// El abono lo registra el servidor al confirmarse; aquí solo se refresca.
class BrebCreditChargeButton extends StatelessWidget {
  final String creditId;
  final double balance;

  /// Valor escrito en el formulario; `null` si está vacío (= todo el saldo).
  final double? Function() amount;

  /// Se llama cuando el banco confirmó y el abono quedó registrado.
  final Future<void> Function() onPaid;

  const BrebCreditChargeButton({
    super.key,
    required this.creditId,
    required this.balance,
    required this.amount,
    required this.onPaid,
  });

  Future<void> _charge(BuildContext context) async {
    final value = amount();
    final problem = brebCreditAmountProblem(amount: value, balance: balance);
    if (problem != null) {
      FuturisticNotifications.showError('No se puede cobrar por Bre-B', problem);
      return;
    }
    // Sin valor o con el saldo exacto: se cobra el saldo completo.
    final paid = await BrebPaymentDialog.showForCredit(
      context,
      creditId,
      amount: (value == null || value >= balance) ? null : value,
    );
    if (paid == null) return;
    await onPaid();
  }

  @override
  Widget build(BuildContext context) {
    if (!canChargeCreditWithBreb(creditId)) return const SizedBox.shrink();
    final radius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('breb-credit-charge'),
        borderRadius: radius,
        onTap: () => _charge(context),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
            border: Border.all(color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.45), width: 1.5),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_2, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cobrar con Bre-B (QR)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Usa el valor escrito arriba, o todo el saldo si está vacío',
                      style: TextStyle(fontSize: 12, color: ElegantLightTheme.textTertiary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ElegantLightTheme.primaryBlue),
            ],
          ),
        ),
      ),
    );
  }
}
