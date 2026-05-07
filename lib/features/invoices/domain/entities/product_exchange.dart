// lib/features/invoices/domain/entities/product_exchange.dart
//
// Entidades para el flujo de "Cambio de producto" (Product Exchange).
// Un cambio implica orquestar 3 operaciones existentes:
//   1) Crear una nota de crédito por los items DEVUELTOS de una factura
//      original (libera inventario y reduce el balance del cliente).
//   2) Crear una factura nueva por los items ENTREGADOS (consume inventario,
//      registra ingreso).
//   3) Conciliar la diferencia entre ambos totales según el método elegido
//      por el usuario (efectivo, crédito a favor, mixto, o cliente paga).
//
// Compatible con offline-first: cada operación interna ya soporta offline.

import '../../../credit_notes/domain/entities/credit_note.dart';
import '../repositories/invoice_repository.dart';
import 'invoice.dart';
import '../../../customer_credits/domain/entities/customer_credit.dart';

/// Cómo conciliar la diferencia cuando el cliente devuelve más de lo que
/// lleva o viceversa.
///
/// - [cashRefund]:        El comercio devuelve la diferencia en efectivo
///                        al cliente (sale dinero de caja).
/// - [storeCredit]:       Se crea un saldo a favor (CustomerCredit) que el
///                        cliente puede usar en compras futuras. Es el
///                        patrón más usado en retail moderno (Walmart,
///                        Falabella, IKEA) porque retiene al cliente.
/// - [cashPayment]:       El cliente paga la diferencia (cuando el nuevo
///                        producto es más caro que el devuelto).
/// - [exact]:             No hay diferencia. Cambio neto cero.
enum ExchangeSettlementMode {
  cashRefund,
  storeCredit,
  cashPayment,
  exact,
}

/// Item que el cliente devuelve (proviene de la factura original).
/// `invoiceItemId` es necesario para que el backend haga FIFO inverso a los
/// lotes correctos.
class ExchangeReturnedItem {
  /// ID del item original en la factura que se está devolviendo.
  final String invoiceItemId;

  /// Cantidad a devolver (puede ser parcial: ej. 2 de 5 originales).
  final double quantity;

  /// Precio unitario al que se vendió originalmente.
  final double unitPrice;

  /// Descripción del item devuelto (auto-completada desde la factura).
  final String description;

  /// ID del producto (para refrescar stock local tras la operación).
  final String? productId;

  /// Unidad ('pcs', 'kg', etc.). Se respeta del item original.
  final String? unit;

  const ExchangeReturnedItem({
    required this.invoiceItemId,
    required this.quantity,
    required this.unitPrice,
    required this.description,
    this.productId,
    this.unit,
  });

  /// Total que el comercio "devuelve" en valor por este item.
  double get subtotal => quantity * unitPrice;
}

/// Item que el cliente lleva nuevo. Se usará para crear una factura nueva.
class ExchangeNewItem {
  final String? productId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercentage;
  final double discountAmount;
  final String? unit;
  final String? notes;

  const ExchangeNewItem({
    this.productId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.unit,
    this.notes,
  });

  /// Total a cobrar por este item (sin IVA, ya con descuentos).
  double get subtotal {
    final gross = quantity * unitPrice;
    final discountFromPct = gross * (discountPercentage / 100.0);
    return gross - discountFromPct - discountAmount;
  }

  /// Convierte a `CreateInvoiceItemParams` para reutilizar el flujo
  /// existente de creación de factura.
  CreateInvoiceItemParams toCreateInvoiceItemParams() {
    return CreateInvoiceItemParams(
      productId: productId,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      unit: unit,
      notes: notes,
    );
  }
}

/// Datos de entrada para ejecutar un cambio de producto.
class ProductExchangeRequest {
  /// ID de la factura original de la cual se devuelven los items.
  final String originalInvoiceId;

  /// ID del cliente (para validar y para crear factura/crédito).
  final String customerId;

  /// Items que el cliente devuelve.
  final List<ExchangeReturnedItem> returnedItems;

  /// Items que el cliente lleva nuevos.
  final List<ExchangeNewItem> newItems;

  /// Cómo conciliar la diferencia (calculada automáticamente o impuesta
  /// por el usuario).
  final ExchangeSettlementMode settlementMode;

  /// Razón del cambio (defectuoso, no le gustó, etc.). Se guarda en la
  /// nota de crédito.
  final CreditNoteReason reason;

  /// Descripción libre adicional. Opcional.
  final String? reasonDescription;

  /// ID de la cuenta bancaria a usar para el pago/refund. Opcional.
  final String? bankAccountId;

  /// Si `true`, el inventario se restaura al hacer la nota de crédito.
  /// Casi siempre `true` excepto productos defectuosos que no se reusan.
  final bool restoreInventory;

  const ProductExchangeRequest({
    required this.originalInvoiceId,
    required this.customerId,
    required this.returnedItems,
    required this.newItems,
    required this.settlementMode,
    this.reason = CreditNoteReason.other,
    this.reasonDescription,
    this.bankAccountId,
    this.restoreInventory = true,
  });

  /// Total de lo devuelto (suma de subtotales de returnedItems).
  double get totalReturned =>
      returnedItems.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Total de lo entregado (suma de subtotales de newItems).
  double get totalDelivered =>
      newItems.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Diferencia: positiva = cliente debe pagar, negativa = se le debe.
  double get difference => totalDelivered - totalReturned;

  /// Modo recomendado según la diferencia. El usuario puede sobrescribir.
  ExchangeSettlementMode get recommendedSettlement {
    if (difference == 0) return ExchangeSettlementMode.exact;
    if (difference > 0) return ExchangeSettlementMode.cashPayment;
    // difference < 0: cliente recibe diferencia → recomendado: store credit
    return ExchangeSettlementMode.storeCredit;
  }
}

/// Resultado de un cambio exitoso.
class ProductExchangeResult {
  /// Nota de crédito creada por los items devueltos.
  final CreditNote creditNote;

  /// Factura nueva creada por los items entregados.
  /// Puede ser `null` si el cliente solo devolvió (no llevó nada nuevo).
  final Invoice? newInvoice;

  /// Crédito a favor del cliente, si se eligió `storeCredit`.
  final CustomerCredit? customerCredit;

  /// Cantidad efectivamente conciliada en efectivo (refund o cobro).
  final double settledInCash;

  /// Cantidad conciliada como saldo a favor del cliente.
  final double settledAsCredit;

  const ProductExchangeResult({
    required this.creditNote,
    this.newInvoice,
    this.customerCredit,
    this.settledInCash = 0,
    this.settledAsCredit = 0,
  });
}
