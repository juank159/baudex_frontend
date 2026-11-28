// Al abrir Créditos la lista y las estadísticas se piden a la vez, y cada
// una leía (y decodificaba) TODOS los créditos del equipo: tres lecturas
// completas en el hilo de la pantalla. Las que coinciden comparten lectura.
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
    dir = await Directory.systemTemp.createTemp('baudex_creditos_test');
    isar = await Isar.open(IsarDatabase.schemas, directory: dir.path);
    IsarDatabase.debugSetDatabase(isar);
  });
  tearDown(() async {
    IsarDatabase.debugSetDatabase(null);
    await isar.close(deleteFromDisk: true);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('lista y estadísticas a la vez: comparten la lectura de créditos y dan lo mismo', () async {
    final local = _Local();
    final network = _Network();
    var reads = 0;
    when(() => local.getCachedCredits()).thenAnswer((_) async {
      reads++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return [_credit('a', 5000), _credit('b', 7000)];
    });
    when(() => network.isConnected).thenAnswer((_) async => false);
    final repo = CustomerCreditRepositoryImpl(
      remoteDataSource: _Remote(),
      localDataSource: local,
      networkInfo: network,
    );

    final results = await Future.wait([
      repo.getCredits(null),
      repo.getCreditStats(),
    ]);

    // Antes: 3 lecturas completas. (Sin la descarga completa confirmada las
    // estadísticas releen una vez; con ella, queda en 1.)
    expect(reads, lessThanOrEqualTo(2));
    final credits = results[0].getOrElse(() => throw StateError('lista')) as List;
    expect(credits.map((c) => (c as CustomerCredit).id), ['a', 'b']);
    final stats = results[1].getOrElse(() => throw StateError('stats')) as CreditStats;
    expect(stats.totalPending, 12000);
  });

  test('cada quien recibe su propia lista (ordenar una no cambia la otra)', () async {
    final local = _Local();
    final network = _Network();
    when(() => local.getCachedCredits()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return [_credit('a', 1), _credit('b', 2)];
    });
    when(() => network.isConnected).thenAnswer((_) async => false);
    final repo = CustomerCreditRepositoryImpl(
      remoteDataSource: _Remote(),
      localDataSource: local,
      networkInfo: network,
    );
    final lists = await Future.wait([repo.getCredits(null), repo.getCredits(null)]);
    final first = lists[0].getOrElse(() => []);
    final second = lists[1].getOrElse(() => []);
    expect(identical(first, second), isFalse);
    first.clear();
    expect(second, hasLength(2));
  });
}
