// Medición: abrir el diálogo de pago y elegir otra moneda (dólares,
// bolívares) / escribir la tasa. ¿Va a la red? ¿Cuánto cuesta reconstruirlo?
//
//   flutter test test/perf/payment_dialog_currency_perf_test.dart
//
// Tiempos en modo de prueba (JIT, sin GPU): sirven para comparar entre
// escenarios, no son los milisegundos de un equipo Windows en producción.
// ignore_for_file: avoid_print
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/enhanced_payment_dialog.dart';
import 'package:baudex_desktop/features/settings/domain/entities/organization.dart';
import 'package:baudex_desktop/features/settings/domain/repositories/organization_repository.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/organization_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

class _Repo implements OrganizationRepository {
  _Repo(this.current);
  Organization current;
  int calls = 0;
  @override
  Future<Either<Failure, Organization>> getCurrentOrganization() async {
    calls++;
    return Right(current);
  }

  @override
  Future<Either<Failure, Organization>> updateCurrentOrganization(Map<String, dynamic> u) async => Right(current);
  @override
  Future<Either<Failure, Organization>> getOrganizationById(String id) async => Right(current);
  @override
  Future<Either<Failure, bool>> updateProfitMargin(double m) async => const Right(true);
}

Organization _org({required bool multi}) => Organization(
      id: 'org-1',
      name: 'Tienda',
      slug: 'tienda',
      settings: {
        if (multi)
          'acceptedCurrencies': [
            {'code': 'USD', 'name': 'Dólar', 'symbol': r'$', 'defaultRate': 4000},
            {'code': 'VES', 'name': 'Bolívar', 'symbol': 'Bs', 'defaultRate': 0.011},
          ],
      },
      multiCurrencyEnabled: multi,
      subscriptionPlan: SubscriptionPlan.basic,
      subscriptionStatus: SubscriptionStatus.active,
      isActive: true,
      currency: 'COP',
      locale: 'es',
      timezone: 'America/Bogota',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

double _ms(Stopwatch w) => w.elapsedMicroseconds / 1000;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('es_CO');
  });

  Widget dialog() => GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: EnhancedPaymentDialog(
              total: 87500,
              customerName: 'Consumidor Final',
              onPaymentConfirmed: (_, __, ___, ____, _____,
                  {bankAccountId,
                  multiplePayments,
                  createCreditForRemaining,
                  balanceApplied,
                  paymentCurrency,
                  paymentCurrencyAmount,
                  exchangeRate}) {},
              onCancel: () {},
            ),
          ),
        ),
      );

  for (final multi in [false, true]) {
    testWidgets('abrir el diálogo de pago (varias monedas: $multi)', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Get.testMode = true;
      final repo = _Repo(_org(multi: multi));
      Get.put(OrganizationController(repo))
          .applyOrganization(_org(multi: multi), notifyRateChange: false);
      final callsBefore = repo.calls;

      // Calentamiento (compila el código del diálogo una vez).
      await tester.pumpWidget(dialog());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox());

      final w = Stopwatch()..start();
      await tester.pumpWidget(dialog());
      final firstFrame = _ms(w);
      await tester.pump(const Duration(milliseconds: 300));
      print('MEDICION diálogo de pago (varias monedas: $multi): primer cuadro '
          '${firstFrame.toStringAsFixed(1)} ms; consultas a la organización al abrir: '
          '${repo.calls - callsBefore}');

      if (multi) {
        expect(find.byIcon(Icons.currency_exchange), findsWidgets);
        final dd = find.byWidgetPredicate((wd) => wd is DropdownButton<String>);
        expect(dd, findsWidgets);
        await tester.tap(dd.first);
        await tester.pump(const Duration(milliseconds: 400));
        final w2 = Stopwatch()..start();
        await tester.tap(find.textContaining('VES').last);
        await tester.pump();
        final pick = _ms(w2);
        await tester.pump(const Duration(milliseconds: 400));
        // Escribir la tasa a mano, tecla por tecla (cada tecla reconstruye).
        final rateField = find.byWidgetPredicate((wd) =>
            wd is TextField && (wd.decoration?.prefixText ?? '').contains('VES'));
        double typing = 0;
        if (rateField.evaluate().isNotEmpty) {
          var text = '';
          for (final ch in '0,0125'.split('')) {
            text += ch;
            final w3 = Stopwatch()..start();
            await tester.enterText(rateField.first, text);
            await tester.pump();
            typing += _ms(w3);
          }
        }
        print('MEDICION elegir bolívares: ${pick.toStringAsFixed(1)} ms; escribir la tasa '
            '(6 teclas): ${typing.toStringAsFixed(1)} ms en total; '
            'consultas a la organización: ${repo.calls - callsBefore}');
      }
      Get.find<OrganizationController>().onClose();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      Get.reset();
    });
  }
}
