import 'package:baudex_desktop/features/purchase_orders/domain/entities/purchase_order.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/services/purchase_order_receipt_rules.dart';
import 'package:flutter_test/flutter_test.dart';

PurchaseOrderItem line({required int quantity, int? received, int? damaged, int? missing}) =>
    PurchaseOrderItem(
      id: 'l1',
      productId: 'p1',
      productName: 'Arroz',
      unit: 'und',
      quantity: quantity,
      receivedQuantity: received,
      damagedQuantity: damaged,
      missingQuantity: missing,
      unitPrice: 2000,
      discountPercentage: 0,
      discountAmount: 0,
      subtotal: 2000.0 * quantity,
      taxPercentage: 0,
      taxAmount: 0,
      totalAmount: 2000.0 * quantity,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

/// Recepción parcial de una orden de compra: qué falta por recibir de cada
/// línea y cuándo la orden ya no espera nada.
void main() {
  group('línea de la orden', () {
    test('recibida a medias: lo pendiente es lo que falta, no lo pedido', () {
      final l = line(quantity: 100, received: 40);
      expect(l.pendingQuantity, 60);
      expect(l.isPartiallyReceived, isTrue);
      expect(l.isFullyReceived, isFalse);
    });

    test('80 buenas + 15 dañadas + 5 que no llegaron: ya no espera nada', () {
      final l = line(quantity: 100, received: 80, damaged: 15, missing: 5);
      expect(l.processedQuantity, 100);
      expect(l.pendingQuantity, 0);
      expect(l.isFullyReceived, isTrue);
    });

    test('sin recibir nada: todo pendiente', () {
      final l = line(quantity: 100);
      expect(l.pendingQuantity, 100);
      expect(l.isPendingDelivery, isTrue);
    });

    test('lo pendiente nunca es negativo', () {
      expect(line(quantity: 10, received: 12).pendingQuantity, 0);
    });
  });

  group('recepción sin conexión', () {
    test('las recepciones se acumulan: 40 y luego 60 son 100', () {
      expect(accumulateReceipt(40, 60), 100);
      expect(accumulateReceipt(null, 40), 40);
      expect(accumulateReceipt(40, null), 40);
    });

    test('la línea está completa contando dañados y faltantes', () {
      expect(isLineFullyProcessed(ordered: 100, received: 40), isFalse);
      expect(isLineFullyProcessed(ordered: 100, received: 80, damaged: 15, missing: 5), isTrue);
    });

    test('las cantidades llegan como número o como texto', () {
      expect(parseQuantity('40.00'), 40);
      expect(parseQuantity(40), 40);
      expect(parseQuantity(null), 0);
      expect(parseQuantity('x'), 0);
    });
  });
}
