import 'package:baudex_desktop/features/cash_register/domain/entities/cash_register.dart';
import 'package:baudex_desktop/features/cash_register/domain/entities/cash_register_movement.dart';
import 'package:baudex_desktop/features/cash_register/domain/services/cash_register_movements.dart';
import 'package:flutter_test/flutter_test.dart';

CashRegisterMovement _m(
  String id, {
  CashMovementKind kind = CashMovementKind.sale,
  String method = 'cash',
  String label = 'Efectivo',
  double amount = 1000,
  int minute = 0,
  String? payer,
  String? bank,
  String? customer,
  String? invoice,
  String? description,
  String? reference,
  String? llave,
}) =>
    CashRegisterMovement(
      id: id,
      kind: kind,
      method: method,
      label: label,
      amount: amount,
      at: DateTime(2026, 11, 12, 15, minute),
      payerName: payer,
      bankLabel: bank,
      customerName: customer,
      invoiceNumber: invoice,
      description: description,
      bankReference: reference,
      llave: llave,
    );

void main() {
  final all = [
    _m('v1', amount: 5000, minute: 1, customer: 'Consumidor Final', invoice: 'INV-1'),
    _m('a1', kind: CashMovementKind.creditPayment, amount: 3000, minute: 2, customer: 'Ana Ruiz', invoice: 'INV-9'),
    _m('g1', kind: CashMovementKind.expense, amount: 2000, minute: 3, description: 'Bolsas'),
    _m('b1', method: 'breb', label: 'Bre-B', amount: 20000, minute: 4, payer: 'MARIA PEREZ', bank: 'Nequi', customer: 'Consumidor Final', invoice: 'INV-2', reference: 'M123'),
    _m('b2', method: 'breb', label: 'Bre-B', amount: 19999, minute: 9, payer: 'ROSA MORA', bank: 'Bancolombia', invoice: 'INV-3'),
    _m('t1', method: 'bank_transfer', label: 'Bancolombia', amount: 50000, minute: 5, customer: 'Luis', invoice: 'INV-4'),
    _m('t2', method: 'bank_transfer', label: 'Nequi', amount: 7000, minute: 6, customer: 'Eva', invoice: 'INV-5'),
  ];

  group('qué movimientos van en cada línea del desglose', () {
    test('ventas en efectivo: solo ventas, sin abonos ni gastos', () {
      expect(movementsFor(all, CashMovementFilter.cashSales()).map((m) => m.id), ['v1']);
    });

    test('abonos de crédito en efectivo', () {
      expect(movementsFor(all, CashMovementFilter.cashCreditPayments()).map((m) => m.id), ['a1']);
    });

    test('efectivo recibido (cierres viejos): ventas y abonos, no gastos', () {
      expect(movementsFor(all, CashMovementFilter.cashReceived()).map((m) => m.id), ['a1', 'v1']);
    });

    test('gastos pagados de caja', () {
      expect(movementsFor(all, CashMovementFilter.expenses()).map((m) => m.id), ['g1']);
    });

    test('Bre-B: todos sus pagos, del más reciente al más antiguo, y suman la línea', () {
      const line = OtherMethodTotal(method: 'breb', label: 'Bre-B', total: 39999, count: 2);
      final list = movementsFor(all, CashMovementFilter.otherMethod(line, 'Bre-B'));
      expect(list.map((m) => m.id), ['b2', 'b1']);
      expect(movementsTotal(list), line.total);
      expect(list.length, line.count);
    });

    test('dos cuentas del mismo método no se mezclan', () {
      const line = OtherMethodTotal(method: 'bank_transfer', label: 'Nequi', total: 7000, count: 1);
      expect(movementsFor(all, CashMovementFilter.otherMethod(line, 'Nequi · Transferencia')).map((m) => m.id), ['t2']);
    });
  });

  group('cómo se lee cada movimiento', () {
    test('Bre-B: el título es quien pagó; debajo banco, factura, cliente y referencia', () {
      final m = all.firstWhere((m) => m.id == 'b1');
      expect(movementTitle(m), 'MARIA PEREZ');
      expect(movementDetails(m), ['Nequi', 'Factura INV-2', 'Cliente Consumidor Final', 'Ref. M123']);
    });

    test('Bre-B con llave informada por el banco', () {
      final m = _m('b3', method: 'breb', label: 'Bre-B', payer: 'JUAN', bank: 'Bancolombia', llave: '@tiendademo');
      expect(movementDetails(m), ['Bancolombia', 'Llave @tiendademo']);
    });

    test('venta en efectivo: el cliente y la factura', () {
      final m = all.firstWhere((m) => m.id == 'v1');
      expect(movementTitle(m), 'Consumidor Final');
      expect(movementDetails(m), ['Factura INV-1']);
    });

    test('abono: se marca como abono a crédito', () {
      final m = all.firstWhere((m) => m.id == 'a1');
      expect(movementDetails(m).first, 'Abono a crédito');
    });

    test('abono a crédito directo: muestra la descripción del crédito', () {
      final m = _m('a2', kind: CashMovementKind.creditPayment, customer: 'Ana', description: 'Préstamo directo');
      expect(movementDetails(m), ['Abono a crédito', 'Préstamo directo']);
    });

    test('gasto: su descripción', () {
      expect(movementTitle(all.firstWhere((m) => m.id == 'g1')), 'Bolsas');
    });

    test('la hora se lee como en un reloj', () {
      expect(movementTime(DateTime(2026, 11, 12, 15, 29)), '3:29 p. m.');
      expect(movementTime(DateTime(2026, 11, 12, 0, 5)), '12:05 a. m.');
      expect(movementTime(DateTime(2026, 11, 12, 12, 0)), '12:00 p. m.');
    });
  });

  group('lo que llega del servidor', () {
    test('se lee y se puede guardar y volver a leer igual', () {
      final m = CashRegisterMovement.fromJson({
        'id': 'p1',
        'kind': 'credit_payment',
        'method': 'breb',
        'label': 'Bre-B · Nequi tienda',
        'amount': '12000.00',
        'at': '2026-11-12T22:39:58.734Z',
        'invoiceId': 'i1',
        'invoiceNumber': 'INV-2026-1',
        'customerName': 'Ana Ruiz',
        'description': null,
        'payerName': 'ROSA MORA',
        'bankLabel': 'Nequi',
        'llave': null,
        'bankReference': 'M9',
      });
      expect(m.kind, CashMovementKind.creditPayment);
      expect(m.isBreb, isTrue);
      expect(m.amount, 12000);
      expect(m.at.toUtc(), DateTime.utc(2026, 11, 12, 22, 39, 58, 734));
      expect(m.payerName, 'ROSA MORA');
      expect(m.llave, isNull);

      final again = CashRegisterMovement.fromJson(m.toJson());
      expect(again.at, m.at);
      expect(again.bankReference, 'M9');
      expect(again.label, 'Bre-B · Nequi tienda');
      expect(again.kind, CashMovementKind.creditPayment);
    });

    test('textos vacíos se tratan como ausentes', () {
      final m = CashRegisterMovement.fromJson({'id': 'x', 'kind': 'sale', 'method': 'cash', 'label': 'Efectivo', 'amount': 1, 'at': '2026-11-12T10:00:00Z', 'payerName': '  '});
      expect(m.payerName, isNull);
    });
  });
}
