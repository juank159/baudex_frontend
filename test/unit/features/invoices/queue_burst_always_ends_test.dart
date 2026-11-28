// test/unit/features/invoices/queue_burst_always_ends_test.dart
//
// QA 1.0.24 (cambio E): la venta guardada en el equipo abre una "ráfaga" de
// la cola (beginQueueBurst) para contar las pendientes una sola vez. Si el
// guardado falla, la ráfaga DEBE cerrarse igual; si no, el conteo de la cola
// queda congelado para todo lo que se encole después.
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_sync_service.dart';

class _BrokenIsarDatabase extends Mock implements IsarDatabase {}

class _CountingSync extends FakeSyncService {
  int begins = 0;
  int ends = 0;

  @override
  void beginQueueBurst() {
    begins++;
    super.beginQueueBurst();
  }

  @override
  Future<void> endQueueBurst() async {
    ends++;
    await super.endQueueBurst();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CountingSync sync;

  setUp(() {
    Get.testMode = true;
    sync = _CountingSync();
    Get.put<SyncService>(sync);
  });

  tearDown(Get.reset);

  test('si el guardado en el equipo falla, la ráfaga de la cola se cierra igual',
      () async {
    final db = _BrokenIsarDatabase();
    when(() => db.database).thenThrow(StateError('base del equipo rota'));
    final repo = InvoiceOfflineRepositorySimple(database: db);

    Object? thrown;
    try {
      final result = await repo.createInvoice(
        customerId: 'cust-1',
        items: const [],
      );
      expect(result.isLeft(), isTrue,
          reason: 'con la base rota la venta no puede quedar guardada');
    } catch (e) {
      thrown = e;
    }

    expect(sync.begins, 1, reason: 'la venta abrió una ráfaga ($thrown)');
    expect(sync.ends, 1, reason: 'la ráfaga se cerró aunque el guardado falló');
  });

  test('dos ventas a la vez: el conteo se aplaza hasta que terminan las dos',
      () async {
    sync.beginQueueBurst();
    sync.beginQueueBurst();
    await sync.endQueueBurst();
    await sync.endQueueBurst();
    // Un cierre de más (no debería pasar) no deja la profundidad negativa:
    await sync.endQueueBurst();
    sync.beginQueueBurst();
    await sync.endQueueBurst();
    expect(sync.begins, 3);
    expect(sync.ends, 4);
  });
}
