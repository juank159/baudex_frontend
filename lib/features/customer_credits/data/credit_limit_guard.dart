// lib/features/customer_credits/data/credit_limit_guard.dart
import 'package:isar/isar.dart';

import '../../../app/core/utils/formatters.dart';
import '../../../app/data/local/isar_database.dart';
import '../../customers/data/models/isar/isar_customer.dart';
import 'models/isar/isar_customer_credit.dart';

/// Resultado de comparar una deuda nueva contra el límite de crédito.
class CreditLimitCheck {
  final double creditLimit;

  /// Lo que el cliente debe HOY (saldo de sus créditos activos). No incluye
  /// lo que ya pagó: el historial de compras no cuenta para el límite.
  final double pendingDebt;

  /// Deuda nueva que se quiere agregar.
  final double amount;

  const CreditLimitCheck({
    required this.creditLimit,
    required this.pendingDebt,
    required this.amount,
  });

  static double _round(double value) => (value * 100).roundToDouble() / 100;

  double get availableCredit {
    final available = _round(creditLimit - pendingDebt);
    return available < 0 ? 0 : available;
  }

  double get excess => _round(pendingDebt + amount - creditLimit);

  /// Regla: deuda pendiente + deuda nueva <= límite de crédito.
  bool get allowed => _round(pendingDebt + amount) <= _round(creditLimit);

  String get message =>
      'El cliente debe actualmente ${AppFormatters.formatCurrency(pendingDebt)} '
      'y su límite de crédito es ${AppFormatters.formatCurrency(creditLimit)}.\n\n'
      'Solo puede fiar ${AppFormatters.formatCurrency(availableCredit)} más y se '
      'intentó agregar ${AppFormatters.formatCurrency(amount)} '
      '(se pasa por ${AppFormatters.formatCurrency(excess)}).\n\n'
      'No se guardó nada. Registra un abono, aumenta el cupo del cliente o '
      'cobra de contado.';
}

/// Valida el límite de crédito con los datos LOCALES (ISAR), para que el aviso
/// salga en el momento de guardar aunque no haya internet. El servidor aplica
/// la misma regla al sincronizar.
class CreditLimitGuard {
  CreditLimitGuard._();

  /// Deuda pendiente real del cliente según los créditos locales (incluye los
  /// creados sin conexión que aún no se han subido).
  static Future<double> pendingDebt(String customerId) async {
    final isar = IsarDatabase.instance.database;
    final credits = await isar.isarCustomerCredits
        .filter()
        .customerIdEqualTo(customerId)
        .findAll();

    double total = 0;
    for (final credit in credits) {
      if (credit.deletedAt != null) continue;
      final isActive = credit.status == IsarCreditStatus.pending ||
          credit.status == IsarCreditStatus.partiallyPaid ||
          credit.status == IsarCreditStatus.overdue;
      if (isActive && credit.balanceDue > 0) total += credit.balanceDue;
    }
    return (total * 100).roundToDouble() / 100;
  }

  /// Compara `amount` de deuda nueva contra el cupo del cliente.
  ///
  /// Devuelve `null` si no se pudo leer la información local (en ese caso no
  /// se bloquea aquí; el servidor valida al recibir la operación).
  static Future<CreditLimitCheck?> check({
    required String customerId,
    required double amount,
    double? fallbackCreditLimit,
  }) async {
    try {
      final isar = IsarDatabase.instance.database;
      final customer = await isar.isarCustomers
          .filter()
          .serverIdEqualTo(customerId)
          .findFirst();
      final creditLimit = customer?.creditLimit ?? fallbackCreditLimit;
      if (creditLimit == null) return null;

      return CreditLimitCheck(
        creditLimit: creditLimit,
        pendingDebt: await pendingDebt(customerId),
        amount: amount,
      );
    } catch (_) {
      return null;
    }
  }
}
