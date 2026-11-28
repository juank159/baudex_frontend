// La caja se consulta tras cada venta y cada minuto. Antes cada consulta
// reescribía su copia en el almacén de sesión (aunque nada hubiera cambiado,
// por la hora dentro del dato) y ESPERABA a esa escritura. En un equipo con
// disco o almacén lento, eso era una espera más en cada venta.
import 'dart:async';

import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/features/cash_register/data/datasources/cash_register_remote_datasource.dart';
import 'package:baudex_desktop/features/cash_register/data/models/cash_register_model.dart';
import 'package:baudex_desktop/features/cash_register/data/repositories/cash_register_repository_impl.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Remote extends Mock implements CashRegisterRemoteDataSource {}

class _Network extends Mock implements NetworkInfo {}

class _Storage extends Mock implements SecureStorageService {}

void main() {
  late _Remote remote;
  late _Network network;
  late _Storage storage;
  late CashRegisterRepositoryImpl repo;
  late List<String> written;

  setUp(() {
    remote = _Remote();
    network = _Network();
    storage = _Storage();
    written = [];
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => storage.write(any(), any())).thenAnswer((invocation) async {
      // Almacén lento: 5 s por escritura.
      await Future<void>.delayed(const Duration(seconds: 5));
      written.add(invocation.positionalArguments[1] as String);
    });
    repo = CashRegisterRepositoryImpl(
      remoteDataSource: remote,
      networkInfo: network,
      secureStorage: storage,
    );
  });

  test('consultar la caja no espera a la escritura del almacén (5 s)', () {
    fakeAsync((async) {
      when(() => remote.getCurrent())
          .thenAnswer((_) async => const CashRegisterCurrentStateModel(expectedAmount: 1000));
      var done = false;
      repo.getCurrent().then((r) => done = r.isRight());
      async.elapse(const Duration(milliseconds: 200));
      expect(done, isTrue, reason: 'la consulta se quedó esperando al almacén');
      async.elapse(const Duration(seconds: 6));
      expect(written, hasLength(1), reason: 'la copia igual debe quedar guardada');
    });
  });

  test('si la caja no cambió, no se reescribe; si cambió (una venta), sí', () {
    fakeAsync((async) {
      var expected = 1000.0;
      when(() => remote.getCurrent())
          .thenAnswer((_) async => CashRegisterCurrentStateModel(expectedAmount: expected));
      for (var i = 0; i < 5; i++) {
        repo.getCurrent();
        async.elapse(const Duration(seconds: 60));
      }
      expect(written, hasLength(1), reason: '5 revisiones sin cambios = 1 escritura');

      expected = 1500; // una venta en efectivo
      repo.getCurrent();
      async.elapse(const Duration(seconds: 10));
      expect(written, hasLength(2));
      expect(written.last, contains('1500'));
    });
  });
}
