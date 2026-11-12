import 'package:baudex_desktop/features/breb/presentation/widgets/breb_credit_charge_button.dart';
import 'package:flutter_test/flutter_test.dart';

/// Abonar o pagar un crédito por Bre-B: qué valores se pueden cobrar.
void main() {
  test('campo vacío: se cobra todo el saldo', () {
    expect(brebCreditAmountProblem(amount: null, balance: 30000), isNull);
  });

  test('un abono menor o igual al saldo es válido', () {
    expect(brebCreditAmountProblem(amount: 12000, balance: 30000), isNull);
    expect(brebCreditAmountProblem(amount: 30000, balance: 30000), isNull);
  });

  test('más que el saldo no se puede cobrar', () {
    expect(brebCreditAmountProblem(amount: 30001, balance: 30000), contains('mayor que el saldo'));
  });

  test('cero o negativo no se puede cobrar', () {
    expect(brebCreditAmountProblem(amount: 0, balance: 30000), isNotNull);
    expect(brebCreditAmountProblem(amount: -5, balance: 30000), isNotNull);
  });

  test('un crédito sin saldo no se cobra', () {
    expect(brebCreditAmountProblem(amount: null, balance: 0), isNotNull);
  });
}
