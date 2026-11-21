import 'package:baudex_desktop/features/credit_notes/domain/repositories/credit_note_repository.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/cancel_credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/confirm_credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/delete_credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/download_credit_note_pdf.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/get_credit_note_by_id.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/bindings/credit_note_binding.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/controllers/credit_note_detail_controller.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/screens/credit_note_detail_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/credit_note_fixtures.dart';

class _Repo extends Mock implements CreditNoteRepository {}

class _GetById extends Mock implements GetCreditNoteById {}

class _Confirm extends Mock implements ConfirmCreditNote {}

class _Cancel extends Mock implements CancelCreditNote {}

class _Delete extends Mock implements DeleteCreditNote {}

class _Pdf extends Mock implements DownloadCreditNotePdf {}

/// Muestra qué nota tiene el controlador que encuentra la pantalla.
class _Probe extends StatelessWidget {
  _Probe() : screen = CreditNoteDetailScreen();
  final CreditNoteDetailScreen screen;
  @override
  Widget build(BuildContext context) => Obx(() => Text(
      'nota:${screen.controller.creditNote?.id ?? '-'}',
      textDirection: TextDirection.ltr));
}

void main() {
  setUp(() {
    Get.reset();
    final getById = _GetById();
    when(() => getById(any())).thenAnswer((inv) async => Right(
        CreditNoteFixtures.createConfirmedCreditNote(id: inv.positionalArguments.first as String)));
    Get.put<CreditNoteRepository>(_Repo());
    Get.put<GetCreditNoteById>(getById);
    Get.put<ConfirmCreditNote>(_Confirm());
    Get.put<CancelCreditNote>(_Cancel());
    Get.put<DeleteCreditNote>(_Delete());
    Get.put<DownloadCreditNotePdf>(_Pdf());
  });

  testWidgets('abrir otra nota con la anterior abierta muestra la nueva', (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SizedBox()),
        GetPage(
          name: '/credit-notes/detail/:id',
          page: () => _Probe(),
          binding: CreditNoteDetailBinding(),
        ),
      ],
    ));
    Get.toNamed('/credit-notes/detail/nota-A');
    await tester.pumpAndSettle();
    expect(find.text('nota:nota-A'), findsOneWidget);

    // "Volver" no llegó a cerrar A (aviso encima) y se abre B encima.
    Get.toNamed('/credit-notes/detail/nota-B');
    await tester.pumpAndSettle();
    // Antes: un solo controlador sin etiqueta → B mostraba A.
    expect(find.text('nota:nota-B'), findsOneWidget);
    expect(Get.find<CreditNoteDetailController>(tag: 'nota-A').creditNoteId, 'nota-A');

    Get.back();
    await tester.pumpAndSettle();
    expect(find.text('nota:nota-A'), findsOneWidget);
    expect(Get.isRegistered<CreditNoteDetailController>(tag: 'nota-B'), isFalse,
        reason: 'el controlador de B se libera al cerrarla');
  });
}
