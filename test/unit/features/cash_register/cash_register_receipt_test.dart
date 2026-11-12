import 'package:baudex_desktop/app/core/printing/receipt_escpos.dart';
import 'package:baudex_desktop/app/core/printing/receipt_line.dart';
import 'package:baudex_desktop/features/cash_register/data/models/cash_register_model.dart';
import 'package:baudex_desktop/features/cash_register/domain/entities/cash_register.dart';
import 'package:baudex_desktop/features/cash_register/domain/services/cash_register_receipt.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _summary = CashRegisterSummary(
  cashSales: 150000,
  cashSalesCount: 7,
  cashExpenses: 20000,
  cashExpensesCount: 1,
  cashFromSales: 120000,
  cashFromSalesCount: 5,
  cashFromCreditPayments: 30000,
  cashFromCreditPaymentsCount: 2,
  otherMethods: [
    OtherMethodTotal(method: 'breb', label: 'Bre-B · Nequi tienda', total: 39999, count: 2),
    OtherMethodTotal(method: 'bank_transfer', label: 'Bancolombia', total: 50000, count: 1),
    OtherMethodTotal(method: 'credit_card', label: 'credit_card', total: 10000, count: 1),
  ],
  otherMethodsTotal: 99999,
  otherMethodsCount: 4,
  totalCollected: 249999,
  creditSalesTotal: 45000,
  creditSalesCount: 1,
  brebTotal: 39999,
  brebCount: 2,
  brebAdjustmentsTotal: 1,
  brebAdjustmentsCount: 1,
);

CashRegister _register({bool closed = false, double difference = 0}) => CashRegister(
      id: 'c1',
      status: closed ? CashRegisterStatus.closed : CashRegisterStatus.open,
      openingAmount: 100000,
      closingExpectedAmount: closed ? 230000 : null,
      closingActualAmount: closed ? 230000 + difference : null,
      closingDifference: closed ? difference : null,
      closingSummary: closed ? _summary : null,
      openedAt: DateTime(2026, 11, 12, 7, 0),
      openedById: 'u1',
      openedByName: 'María Peña',
      closedAt: closed ? DateTime(2026, 11, 12, 19, 30) : null,
      closedByName: closed ? 'María Peña' : null,
      closingNotes: closed ? 'Se entregó la base a la dueña' : null,
      organizationId: 'o1',
      createdAt: DateTime(2026, 11, 12, 7, 0),
      updatedAt: DateTime(2026, 11, 12, 7, 0),
    );

String _text(List<ReceiptLine> lines) => ReceiptLine.toPlainText(lines, width: 48);

void main() {
  final printedAt = DateTime(2026, 11, 12, 19, 31);

  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('es_CO');
  });

  group('recibo de caja', () {
    test('arqueo con la caja abierta: efectivo, otros medios con Bre-B y total', () {
      final text = _text(buildCashRegisterReceipt(
        register: _register(),
        businessName: 'Tienda Demo',
        summary: _summary,
        expected: 230000,
        printedAt: printedAt,
      ));
      // ignore: avoid_print
      print(text);

      expect(text, contains('Tienda Demo'));
      expect(text, contains('ARQUEO DE CAJA'));
      expect(text, contains('(la caja sigue abierta)'));
      expect(text, isNot(contains('CIERRE DE CAJA')));
      expect(text, matches(RegExp(r'Base inicial\s+\$\s?100[.,]000')));
      expect(text, matches(RegExp(r'\+ Ventas \(5 pagos\)\s+\$\s?120[.,]000')));
      expect(text, matches(RegExp(r'\+ Abonos a créditos \(2 abonos\)\s+\$\s?30[.,]000')));
      expect(text, matches(RegExp(r'- Gastos de caja \(1 gasto\)\s+\$\s?20[.,]000')));
      expect(text, matches(RegExp(r'= DEBE HABER\s+\$\s?230[.,]000')));
      expect(text, matches(RegExp(r'Bre-B · Nequi tienda \(2 pagos\)\s+\$\s?39[.,]999')));
      expect(text, matches(RegExp(r'Bancolombia · Transferencia \(1 pago\)\s+\$\s?50[.,]000')));
      expect(text, matches(RegExp(r'Tarjeta de crédito \(1 pago\)\s+\$\s?10[.,]000')));
      expect(text, matches(RegExp(r'Total otros medios\s+\$\s?99[.,]999')));
      expect(text, matches(RegExp(r'TOTAL COBRADO\s+\$\s?249[.,]999')));
      expect(text, matches(RegExp(r'Ventas fiadas \(1 venta\)\s+\$\s?45[.,]000')));
      expect(text, contains('Ajustes Bre-B (no cobrado)'));
      expect(text, isNot(contains('Contado')));
      expect(text, contains('Firma responsable'));
    });

    test('cierre: usa el resumen guardado, lo contado y el faltante', () {
      final text = _text(buildCashRegisterReceipt(
        register: _register(closed: true, difference: -5000),
        businessName: 'Tienda Demo',
        printedAt: printedAt,
      ));
      expect(text, contains('CIERRE DE CAJA'));
      expect(text, isNot(contains('sigue abierta')));
      expect(text, matches(RegExp(r'Contado\s+\$\s?225[.,]000')));
      expect(text, matches(RegExp(r'FALTANTE\s+\$\s?5[.,]000')));
      expect(text, contains('Se entregó la base a la dueña'));
      expect(text, contains('Bre-B · Nequi tienda'));
    });

    test('cierre que cuadra y cierre con sobrante', () {
      expect(
        _text(buildCashRegisterReceipt(register: _register(closed: true), businessName: 'X', printedAt: printedAt)),
        contains('DIFERENCIA (cuadra)'),
      );
      expect(
        _text(buildCashRegisterReceipt(
            register: _register(closed: true, difference: 3000), businessName: 'X', printedAt: printedAt)),
        matches(RegExp(r'SOBRANTE\s+\$\s?3[.,]000')),
      );
    });

    test('resumen viejo sin desglose: no inventa otros medios', () {
      const old = CashRegisterSummary(cashSales: 80000, cashSalesCount: 3);
      final text = _text(buildCashRegisterReceipt(
        register: _register(),
        businessName: '',
        summary: old,
        printedAt: printedAt,
      ));
      expect(text, contains('Baudex'));
      expect(text, matches(RegExp(r'\+ Efectivo recibido \(3 pagos\)\s+\$\s?80[.,]000')));
      expect(text, matches(RegExp(r'= DEBE HABER\s+\$\s?180[.,]000')));
      expect(text, isNot(contains('OTROS MEDIOS')));
    });
  });

  group('nombre del medio de pago', () {
    test('Bre-B nunca sale como "Bre-B · breb"', () {
      expect(otherMethodDisplayName(const OtherMethodTotal(method: 'breb', label: 'Bre-B', total: 1, count: 1)), 'Bre-B');
      expect(otherMethodDisplayName(const OtherMethodTotal(method: 'breb', label: '', total: 1, count: 1)), 'Bre-B');
      expect(otherMethodDisplayName(const OtherMethodTotal(method: 'breb', label: 'breb', total: 1, count: 1)), 'Bre-B');
      expect(
        otherMethodDisplayName(const OtherMethodTotal(method: 'breb', label: 'Bre-B · Nequi', total: 1, count: 1)),
        'Bre-B · Nequi',
      );
    });
  });

  group('resumen que llega del servidor', () {
    test('lee los campos de Bre-B y los conserva al guardar', () {
      final model = CashRegisterSummaryModel.fromJson({
        'cashSales': 10000,
        'cashSalesCount': 1,
        'cashFromSales': 10000,
        'otherMethods': [
          {'method': 'breb', 'label': 'Bre-B', 'total': 39999, 'count': 2},
        ],
        'otherMethodsTotal': 39999,
        'totalCollected': 49999,
        'brebTotal': 39999,
        'brebCount': 2,
        'brebAdjustmentsTotal': 1,
        'brebAdjustmentsCount': 1,
      });
      expect(model.brebTotal, 39999);
      expect(model.brebCount, 2);
      expect(model.brebAdjustmentsTotal, 1);
      final again = CashRegisterSummaryModel.fromJson(model.toJson());
      expect(again.brebTotal, 39999);
      expect(again.brebAdjustmentsCount, 1);
      expect(again.otherMethods!.single.method, 'breb');
    });

    test('un servidor viejo (sin Bre-B) sigue leyéndose', () {
      final model = CashRegisterSummaryModel.fromJson({'cashSales': 5000, 'cashSalesCount': 1});
      expect(model.brebTotal, isNull);
      expect(model.cashSales, 5000);
    });
  });

  group('impresión térmica', () {
    test('quita tildes y símbolos que la impresora no imprime', () {
      expect(printableAscii('Bre-B · Nequi — créditos ¡ñandú!'), 'Bre-B - Nequi - creditos nandu!');
      expect(printableAscii('\$ 1.000'), '\$ 1.000');
      expect(printableAscii('€'), '?');
    });

    test('la columna de la derecha crece con el texto y deja espacio a la izquierda', () {
      expect(receiptRightColumns('\$ 1.000', 48), 3);
      expect(receiptRightColumns('12/11/2026 19:30', 48), 5);
      expect(receiptRightColumns('x' * 60, 48), 8);
      expect(receiptRightColumns('\$ 1.250.000', 32), 5);
    });

    test('el recibo completo se convierte a comandos sin fallar (80 y 58 mm)', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final profile = await esc_pos.CapabilityProfile.load();
      final lines = buildCashRegisterReceipt(
        register: _register(closed: true, difference: -5000),
        businessName: 'Tienda Demo Ñandú',
        printedAt: printedAt,
      );
      for (final (paper, chars) in [(esc_pos.PaperSize.mm80, 48), (esc_pos.PaperSize.mm58, 32)]) {
        final bytes = receiptLinesToEscPos(esc_pos.Generator(paper, profile), lines, charsPerLine: chars);
        expect(bytes, isNotEmpty);
        final printed = String.fromCharCodes(bytes.where((b) => b >= 0x20 && b < 0x7F));
        expect(printed, contains('CIERRE DE CAJA'));
        expect(printed, contains('FALTANTE'));
        expect(printed, contains('Bre-B - Nequi tienda'));
      }
    });
  });
}
