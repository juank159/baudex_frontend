// Abrir el diálogo de pago con un cliente registrado creaba el controlador
// de la pantalla de Créditos, que al nacer carga TODOS los créditos y sus
// estadísticas (lecturas completas y decodificación en el hilo de la
// pantalla). El saldo a favor ahora se pide directo al repositorio.
import 'package:baudex_desktop/features/customer_credits/data/models/customer_credit_model.dart';
import 'package:baudex_desktop/features/customer_credits/domain/repositories/customer_credit_repository.dart';
import 'package:baudex_desktop/features/customer_credits/presentation/controllers/customer_credit_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/enhanced_payment_dialog.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements CustomerCreditRepository {}

class _Balance extends Mock implements ClientBalanceModel {}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('pide el saldo sin crear el controlador de Créditos', () async {
    final repo = _Repo();
    final balance = _Balance();
    when(() => balance.balance).thenReturn(25000);
    when(() => repo.getClientBalance('cli-1')).thenAnswer((_) async => Right(balance));
    Get.put<CustomerCreditRepository>(repo);
    var created = 0;
    // Como lo deja el binding: registrado, pero sin crear todavía.
    Get.lazyPut<CustomerCreditController>(() {
      created++;
      return CustomerCreditController(repository: repo);
    }, fenix: true);

    final result = await loadClientBalanceForPayment('cli-1');

    expect(result?.balance, 25000);
    expect(created, 0, reason: 'se creó el controlador de Créditos (carga todos los créditos)');
    verify(() => repo.getClientBalance('cli-1')).called(1);
  });

  test('si el servidor no responde, no hay saldo y no se rompe nada', () async {
    final repo = _Repo();
    when(() => repo.getClientBalance(any()))
        .thenAnswer((_) async => const Right<Never, ClientBalanceModel?>(null));
    Get.put<CustomerCreditRepository>(repo);
    expect(await loadClientBalanceForPayment('cli-2'), isNull);
  });
}
