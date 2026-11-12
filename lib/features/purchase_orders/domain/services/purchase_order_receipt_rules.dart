// lib/features/purchase_orders/domain/services/purchase_order_receipt_rules.dart
//
// Reglas de una recepción de orden de compra, las mismas del servidor
// (backend: purchase-order-item.entity.ts). Se usan cuando la recepción se
// registra sin conexión, para que el equipo muestre lo mismo que mostrará el
// servidor al sincronizar.

/// Suma una recepción a lo que ya llevaba la línea. Las recepciones se
/// acumulan: recibir 40 y luego 60 son 100, no 60.
int accumulateReceipt(int? previous, int? added) =>
    (previous ?? 0) + (added ?? 0);

/// ¿La línea ya no espera nada? Cuenta lo recibido en buen estado, lo que
/// llegó dañado y lo que el proveedor no entregó.
bool isLineFullyProcessed({
  required num ordered,
  int? received,
  int? damaged,
  int? missing,
}) =>
    (received ?? 0) + (damaged ?? 0) + (missing ?? 0) >= ordered;

/// Lee una cantidad que puede venir como número o como texto ("40", "40.00").
int parseQuantity(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return double.tryParse(value.toString())?.toInt() ?? 0;
}
