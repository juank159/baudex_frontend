import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/features/credit_notes/data/datasources/credit_note_local_datasource.dart';
import 'package:baudex_desktop/features/credit_notes/data/datasources/credit_note_remote_datasource.dart';
import 'package:baudex_desktop/features/credit_notes/data/models/credit_note_model.dart';
import 'package:baudex_desktop/features/credit_notes/data/repositories/credit_note_repository_impl.dart';
import 'package:baudex_desktop/features/credit_notes/domain/entities/credit_note.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/credit_note_fixtures.dart';

class _Remote extends Mock implements CreditNoteRemoteDataSource {}

class _Local extends Mock implements CreditNoteLocalDataSource {}

class _Net extends Mock implements NetworkInfo {}

/// Confirmar una nota con internet.
void main() {
  late _Remote remote;
  late _Local local;
  late _Net net;
  late CreditNoteRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(
      CreditNoteModel.fromEntity(CreditNoteFixtures.createConfirmedCreditNote())));

  setUp(() {
    Get.testMode = true;
    remote = _Remote();
    local = _Local();
    net = _Net();
    when(() => net.isConnected).thenAnswer((_) async => true);
    when(() => local.cacheCreditNote(any())).thenAnswer((_) async {});
    repo = CreditNoteRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: net,
    );
  });
  tearDown(Get.reset);

  const id = '3f1c2d4e-0000-4000-8000-000000000001';

  test('confirmada en el servidor: la copia del equipo queda confirmada', () async {
    final confirmed = CreditNoteModel.fromEntity(
        CreditNoteFixtures.createConfirmedCreditNote(id: id));
    when(() => remote.confirmCreditNote(id)).thenAnswer((_) async => confirmed);

    final result = await repo.confirmCreditNote(id);

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => throw 'x').status, CreditNoteStatus.confirmed);
    // Antes no se guardaba: la lista (que lee primero del equipo) la seguía
    // mostrando en borrador hasta la siguiente descarga.
    final saved = verify(() => local.cacheCreditNote(captureAny())).captured.single
        as CreditNoteModel;
    expect(saved.status, CreditNoteStatus.confirmed);
  });

  test('el servidor la rechaza: se muestra su motivo con el código', () async {
    when(() => remote.confirmCreditNote(id)).thenThrow(
        const ServerException('Solicitud incorrecta: Solo borradores', statusCode: 400));

    final result = await repo.confirmCreditNote(id);

    final failure = result.swap().getOrElse(() => throw 'x');
    expect(failure, isA<ServerFailure>());
    expect(failure.message, contains('Solo borradores'));
    verifyNever(() => local.cacheCreditNote(any()));
  });

  test('servidor anterior: 400 "Estado actual: confirmed" se consulta y se da por confirmada',
      () async {
    final confirmed = CreditNoteModel.fromEntity(
        CreditNoteFixtures.createConfirmedCreditNote(id: id));
    when(() => remote.confirmCreditNote(id)).thenThrow(const ServerException(
        'Solicitud incorrecta: Solo se pueden confirmar notas de crédito en estado DRAFT. Estado actual: confirmed',
        statusCode: 400));
    when(() => remote.getCreditNoteById(id)).thenAnswer((_) async => confirmed);

    final result = await repo.confirmCreditNote(id);

    expect(result.isRight(), isTrue, reason: 'la nota sí quedó confirmada');
    expect(result.getOrElse(() => throw 'x').status, CreditNoteStatus.confirmed);
    verify(() => local.cacheCreditNote(any())).called(1);
  });

  test('servidor nuevo (idempotente): repetir confirmar responde 200 y es éxito', () async {
    final confirmed = CreditNoteModel.fromEntity(
        CreditNoteFixtures.createConfirmedCreditNote(id: id));
    when(() => remote.confirmCreditNote(id)).thenAnswer((_) async => confirmed);
    expect((await repo.confirmCreditNote(id)).isRight(), isTrue);
    expect((await repo.confirmCreditNote(id)).isRight(), isTrue);
  });

  test('tiempo agotado pero el servidor SÍ la confirmó: es éxito, no "error"',
      () async {
    final confirmed = CreditNoteModel.fromEntity(
        CreditNoteFixtures.createConfirmedCreditNote(id: id));
    when(() => remote.confirmCreditNote(id))
        .thenThrow(const RequestTimeoutException());
    when(() => remote.getCreditNoteById(id)).thenAnswer((_) async => confirmed);

    final result = await repo.confirmCreditNote(id);

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => throw 'x').status, CreditNoteStatus.confirmed);
    verify(() => local.cacheCreditNote(any())).called(1);
  });

  test('tiempo agotado y el servidor no la tiene confirmada: se pregunta y no se inventa éxito',
      () async {
    final draft = CreditNoteModel.fromEntity(
        CreditNoteFixtures.createConfirmedCreditNote(id: id)
            .copyWith(status: CreditNoteStatus.draft));
    when(() => remote.confirmCreditNote(id))
        .thenThrow(const RequestTimeoutException());
    when(() => remote.getCreditNoteById(id)).thenAnswer((_) async => draft);

    expect(await repo.confirmedOnServer(id), isNull);
    verify(() => remote.getCreditNoteById(id)).called(1);
  });
}
