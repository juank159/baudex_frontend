// lib/features/cash_register/domain/services/cash_register_movements.dart
import '../entities/cash_register.dart';
import '../entities/cash_register_movement.dart';

/// Qué línea del desglose de la caja se quiere ver en detalle.
class CashMovementFilter {
  final String title;
  final bool Function(CashRegisterMovement m) matches;

  const CashMovementFilter._(this.title, this.matches);

  /// "Ventas en efectivo".
  factory CashMovementFilter.cashSales() => CashMovementFilter._(
        'Ventas en efectivo',
        (m) => m.isCash && m.kind == CashMovementKind.sale,
      );

  /// "Abonos de crédito en efectivo".
  factory CashMovementFilter.cashCreditPayments() => CashMovementFilter._(
        'Abonos de crédito en efectivo',
        (m) => m.isCash && m.kind == CashMovementKind.creditPayment,
      );

  /// Todo el efectivo recibido (resúmenes viejos sin desglose).
  factory CashMovementFilter.cashReceived() => CashMovementFilter._(
        'Efectivo recibido',
        (m) => m.isCash && m.kind != CashMovementKind.expense,
      );

  /// "Gastos pagados de caja".
  factory CashMovementFilter.expenses() => CashMovementFilter._(
        'Gastos pagados de caja',
        (m) => m.kind == CashMovementKind.expense,
      );

  /// Una línea de "Otros medios de pago" (Bre-B, una cuenta, tarjetas…).
  factory CashMovementFilter.otherMethod(OtherMethodTotal line, String displayName) => CashMovementFilter._(
        displayName,
        (m) => m.kind != CashMovementKind.expense && m.method == line.method && m.label == line.label,
      );
}

/// Movimientos de una línea del desglose, del más reciente al más antiguo.
List<CashRegisterMovement> movementsFor(List<CashRegisterMovement> all, CashMovementFilter filter) {
  final list = all.where(filter.matches).toList()..sort((a, b) => b.at.compareTo(a.at));
  return list;
}

double movementsTotal(List<CashRegisterMovement> list) => list.fold(0.0, (sum, m) => sum + m.amount);

/// Línea principal de un movimiento: quién pagó o de qué es.
String movementTitle(CashRegisterMovement m) {
  if (m.kind == CashMovementKind.expense) return m.description ?? 'Gasto';
  if (m.isBreb && m.payerName != null) return m.payerName!;
  return m.customerName ?? m.description ?? (m.invoiceNumber != null ? 'Factura ${m.invoiceNumber}' : 'Pago');
}

/// Datos de apoyo de un movimiento, en el orden en que se leen.
List<String> movementDetails(CashRegisterMovement m) => [
      if (m.kind == CashMovementKind.creditPayment) 'Abono a crédito',
      if (m.bankLabel != null) m.bankLabel!,
      if (m.llave != null) 'Llave ${m.llave}',
      if (m.invoiceNumber != null) 'Factura ${m.invoiceNumber}',
      if (m.isBreb && m.payerName != null && m.customerName != null) 'Cliente ${m.customerName}',
      if (m.kind == CashMovementKind.creditPayment && m.invoiceNumber == null && m.description != null) m.description!,
      if (m.bankReference != null) 'Ref. ${m.bankReference}',
    ];

/// Hora del movimiento como se lee en un reloj: "3:29 p. m.".
String movementTime(DateTime at) {
  final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final minute = at.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${at.hour < 12 ? 'a. m.' : 'p. m.'}';
}
