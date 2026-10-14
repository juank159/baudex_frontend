import 'package:baudex_desktop/features/customer_credits/data/credit_limit_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreditLimitCheck (deuda pendiente + nuevo <= límite)', () {
    test('debe 2.900.000, límite 3.000.000, agregar 200.000 → bloqueado', () {
      const check = CreditLimitCheck(
        creditLimit: 3000000,
        pendingDebt: 2900000,
        amount: 200000,
      );
      expect(check.allowed, isFalse);
      expect(check.availableCredit, 100000);
      expect(check.excess, 100000);
      expect(check.message, contains('No se guardó nada'));
    });

    test('agregar exactamente lo disponible → permitido', () {
      const check = CreditLimitCheck(
        creditLimit: 3000000,
        pendingDebt: 2900000,
        amount: 100000,
      );
      expect(check.allowed, isTrue);
    });

    test('un peso por encima → bloqueado', () {
      const check = CreditLimitCheck(
        creditLimit: 3000000,
        pendingDebt: 2900000,
        amount: 100001,
      );
      expect(check.allowed, isFalse);
    });

    test('sin deuda pendiente (todo el historial pagado) → cupo completo', () {
      const check = CreditLimitCheck(
        creditLimit: 3000000,
        pendingDebt: 0,
        amount: 3000000,
      );
      expect(check.allowed, isTrue);
      expect(check.availableCredit, 3000000);
    });

    test('residuos de centavos no bloquean por error de punto flotante', () {
      const check = CreditLimitCheck(
        creditLimit: 100000,
        pendingDebt: 22999.99,
        amount: 77000.01,
      );
      expect(check.allowed, isTrue);
    });

    test('deuda ya por encima del límite → disponible 0, nunca negativo', () {
      const check = CreditLimitCheck(
        creditLimit: 1000,
        pendingDebt: 5000,
        amount: 1,
      );
      expect(check.allowed, isFalse);
      expect(check.availableCredit, 0);
    });
  });
}
