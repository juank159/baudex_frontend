// QA 1.0.25 — Lectura compartida de créditos (5c63f51).
//
// `_localCredits()` guarda la lectura en curso con `??=` y la suelta en el
// `finally` del cuerpo async. Si la fuente local lanza ANTES de su primer
// await (error síncrono), el `finally` corre antes de que `??=` asigne, y la
// lectura ya terminada (lista vacía) queda guardada PARA SIEMPRE: Créditos
// no vuelve a leer la base en toda la ejecución.
//
// Hoy la fuente Isar es `async` (no lanza síncrono), así que en producción
// es latente; cualquier cambio futuro de la fuente lo activaría.
// Esta prueba FALLA con el código actual.
// Arreglo propuesto: soltar con `running.whenComplete(() { if
// (identical(_localCreditsInFlight, running)) _localCreditsInFlight = null; })`
// fuera del cuerpo, o envolver la llamada en `Future.sync`.
import 'dart:io';

import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:isar/isar.dart';

import '../../../helpers/isar_core.dart';
import 'package:baudex_desktop/features/customer_credits/data/datasources/customer_credit_local_datasource.dart';
import 'package:baudex_desktop/features/customer_credits/data/datasources/customer_credit_remote_datasource.dart';
import 'package:baudex_desktop/features/customer_credits/data/models/customer_credit_model.dart';
import 'package:baudex_desktop/features/customer_credits/data/repositories/customer_credit_repository_impl.dart';
import 'package:baudex_desktop/features/customer_credits/domain/entities/customer_credit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Remote extends Mock implements CustomerCreditRemoteDataSource {}

class _Local extends Mock implements CustomerCreditLocalDataSource {}

class _Network extends Mock implements NetworkInfo {}

CustomerCreditModel _credit(String id, double amount) => CustomerCreditModel(
      id: id,
      originalAmount: amount,
      paidAmount: 0,
      balanceDue: amount,
      status: CreditStatus.pending,
      customerId: 'cli-1',
      organizationId: 'org',
      createdById: 'u',
      createdAt: DateTime(2026, 10, 10),
      updatedAt: DateTime(2026, 10, 10),
    );

void main() {
  late Directory dir;
  late Isar isar;

  setUpAll(initIsarCore);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('baudex_qa_creditos');
    isar = await Isar.open(IsarDatabase.schemas, directory: dir.path);
    IsarDatabase.debugSetDatabase(isar);
  });
  tearDown(() async {
    IsarDatabase.debugSetDatabase(null);
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('un error síncrono de la fuente no deja la lista vacía para siempre', () async {
    final local = _Local();
    final network = _Network();
    var fail = true;
    when(() => local.getCachedCredits()).thenAnswer((_) {
      if (fail) throw StateError('fuente local no lista');
      return Future.value([_credit('a', 5000)]);
    });
    when(() => network.isConnected).thenAnswer((_) async => false);
    final repo = CustomerCreditRepositoryImpl(
      remoteDataSource: _Remote(),
      localDataSource: local,
      networkInfo: network,
    );

    await repo.getCredits(null); // falla: lista vacía (correcto)
    fail = false;
    final second = await repo.getCredits(null);
    final ids = second.getOrElse(() => []).map((c) => c.id).toList();
    expect(ids, ['a'], reason: 'quedó pegada la lectura vacía de la primera vez');
  });
}
