import 'dart:async';

import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/features/credit_notes/domain/entities/credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/repositories/credit_note_repository.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/cancel_credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/confirm_credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/delete_credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/download_credit_note_pdf.dart';
import 'package:baudex_desktop/features/credit_notes/domain/usecases/get_credit_notes.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/controllers/credit_note_list_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/credit_note_fixtures.dart';

class _Get extends Mock implements GetCreditNotes {}

class _Confirm extends Mock implements ConfirmCreditNote {}

class _Cancel extends Mock implements CancelCreditNote {}

class _Delete extends Mock implements DeleteCreditNote {}

class _Pdf extends Mock implements DownloadCreditNotePdf {}

class _FakeQuery extends Fake implements QueryCreditNotesParams {}

/// "Confirmar" en la lista de notas crédito (el servidor tarda).
void main() {
  setUpAll(() => registerFallbackValue(_FakeQuery()));

  late _Get getNotes;
  late _Confirm confirm;
  late CreditNoteListController controller;
  final draft = CreditNoteFixtures.createDraftCreditNote(id: 'n1');
  final confirmed = CreditNoteFixtures.createConfirmedCreditNote(id: 'n1');

  setUp(() {
    Get.testMode = true;
    getNotes = _Get();
    confirm = _Confirm();
    when(() => getNotes(any())).thenAnswer((_) async => Right(PaginatedResult(
          data: [confirmed],
          meta: const PaginationMeta(
            page: 1, limit: 20, totalItems: 1, totalPages: 1,
            hasNextPage: false, hasPreviousPage: false,
          ),
        )));
    controller = CreditNoteListController(
      getCreditNotesUseCase: getNotes,
      deleteCreditNoteUseCase: _Delete(),
      confirmCreditNoteUseCase: confirm,
      cancelCreditNoteUseCase: _Cancel(),
      downloadCreditNotePdfUseCase: _Pdf(),
    );
  });
  tearDown(Get.reset);

  Future<void> app(WidgetTester t) =>
      t.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));

  testWidgets('dos toques mientras el servidor confirma: se confirma una sola vez',
      (t) async {
    await app(t);
    final pending = Completer<Either<Failure, CreditNote>>();
    when(() => confirm('n1')).thenAnswer((_) => pending.future);

    final first = controller.confirmCreditNote('n1');
    expect(controller.isBusy('n1'), isTrue, reason: 'la nota muestra que está trabajando');
    final second = controller.confirmCreditNote('n1');

    pending.complete(Right(confirmed));
    await t.runAsync(() => Future.wait([first, second]));
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(seconds: 1));
    }

    verify(() => confirm('n1')).called(1);
    expect(controller.isBusy('n1'), isFalse);
  });

  testWidgets('si la respuesta falla, la lista se vuelve a leer y muestra el estado real',
      (t) async {
    await app(t);
    when(() => confirm('n1')).thenAnswer(
        (_) async => const Left(ConnectionFailure('Tiempo de conexión agotado.')));

    await t.runAsync(() => controller.confirmCreditNote('n1'));
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(seconds: 1));
    }

    verify(() => getNotes(any())).called(greaterThanOrEqualTo(1));
    expect(controller.creditNotes.single.status, CreditNoteStatus.confirmed);
    expect(draft.status, CreditNoteStatus.draft);
  });
}
