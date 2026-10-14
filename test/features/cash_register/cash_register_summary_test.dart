import 'package:baudex_desktop/features/cash_register/data/models/cash_register_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Turno real de Mercaexpress (13 oct): base 150.000, efectivo 2.055.800
  // (2.017.800 de ventas + 38.000 de abonos), Nequi 70.200, fiado 212.700.
  final json = {
    'cashSales': 2055800,
    'cashSalesCount': 183,
    'cashExpenses': 0,
    'cashExpensesCount': 0,
    'cashDeposits': 0,
    'cashWithdrawals': 0,
    'invoicesCount': 180,
    'creditNotesCount': 0,
    'creditNotesTotal': 0,
    'cashFromSales': 2017800,
    'cashFromSalesCount': 180,
    'cashFromCreditPayments': 38000,
    'cashFromCreditPaymentsCount': 3,
    'otherMethods': [
      {'method': 'bank_transfer', 'label': 'Nequi', 'total': 70200, 'count': 4},
    ],
    'otherMethodsTotal': 70200,
    'otherMethodsCount': 4,
    'totalCollected': 2126000,
    'creditSalesTotal': 212700,
    'creditSalesCount': 17,
  };

  test('lee el desglose completo del turno', () {
    final s = CashRegisterSummaryModel.fromJson(json);
    expect(s.hasBreakdown, isTrue);
    expect(s.cashFromSales, 2017800);
    expect(s.cashFromCreditPayments, 38000);
    expect(s.otherMethods!.single.label, 'Nequi');
    expect(s.otherMethods!.single.total, 70200);
    expect(s.totalCollected, 2126000);
    expect(s.creditSalesTotal, 212700);
  });

  test('el dinero esperado en caja es SOLO efectivo: base + efectivo − gastos', () {
    final s = CashRegisterSummaryModel.fromJson(json);
    expect(s.expectedCash(150000), 2205800);
    // Los otros medios y el fiado no entran a la caja
    expect(s.expectedCash(150000), isNot(150000 + s.totalCollected!));
  });

  test('efectivo de ventas + abonos = efectivo recibido; efectivo + otros = total cobrado', () {
    final s = CashRegisterSummaryModel.fromJson(json);
    expect(s.cashFromSales! + s.cashFromCreditPayments!, s.cashSales);
    expect(s.cashSales + s.otherMethodsTotal!, s.totalCollected);
  });

  test('gastos de caja y retiros restan; ingresos suman', () {
    final s = CashRegisterSummaryModel.fromJson({
      ...json,
      'cashExpenses': 50000,
      'cashDeposits': 20000,
      'cashWithdrawals': 100000,
    });
    expect(s.expectedCash(150000), 150000 + 2055800 + 20000 - 50000 - 100000);
  });

  test('un servidor o cierre anterior (sin desglose) sigue funcionando', () {
    final s = CashRegisterSummaryModel.fromJson({
      'cashSales': 2054800,
      'cashSalesCount': 182,
      'cashExpenses': 0,
      'cashExpensesCount': 0,
      'cashDeposits': 0,
      'cashWithdrawals': 0,
      'invoicesCount': 179,
      'creditNotesCount': 0,
      'creditNotesTotal': 0,
    });
    expect(s.hasBreakdown, isFalse);
    expect(s.otherMethods, isNull);
    expect(s.expectedCash(150000), 2204800);
  });

  test('el desglose se conserva al guardar y volver a leer', () {
    final again = CashRegisterSummaryModel.fromJson(
      CashRegisterSummaryModel.fromJson(json).toJson(),
    );
    expect(again, CashRegisterSummaryModel.fromJson(json));
  });
}
