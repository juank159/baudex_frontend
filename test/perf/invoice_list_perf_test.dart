
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'invoice_perf_fixture.dart';

/// Medición de la lista de facturas leída del equipo, con una base grande
/// (20.000 facturas con sus ítems, 3.000 clientes). Base temporal, nunca la
/// real. Correr con: flutter test test/perf/invoice_list_perf_test.dart
void main() {
  late Isar isar;
  late InvoiceOfflineRepositorySimple repo;
  const invoiceCount = 20000;

  setUpAll(() async {
    isar = await openBigInvoiceDb(invoices: invoiceCount);
    repo = InvoiceOfflineRepositorySimple();
  });

  tearDownAll(() => closeBigInvoiceDb(isar));

  Future<int> ms(Future<void> Function() f, {int runs = 5}) async {
    await f(); // calentar
    final times = <int>[];
    for (var i = 0; i < runs; i++) {
      final w = Stopwatch()..start();
      await f();
      times.add(w.elapsedMilliseconds);
    }
    times.sort();
    return times[times.length ~/ 2];
  }

  test('medición: primera página, siguientes, filtros, búsqueda y estadísticas', () async {
    final results = <String, int>{};
    List<Invoice> first = const [];
    results['primera página (30)'] = await ms(() async {
      first = (await repo.getInvoices(page: 1, limit: 30, sortOrder: 'DESC'))
          .getOrElse(() => throw 'falló')
          .data;
    });
    results['página 50 (30)'] = await ms(() async {
      await repo.getInvoices(page: 50, limit: 30, sortOrder: 'DESC');
    });
    results['filtro estado pendiente'] = await ms(() async {
      await repo.getInvoices(page: 1, limit: 30, status: InvoiceStatus.pending);
    });
    results['filtro fechas (1 mes)'] = await ms(() async {
      await repo.getInvoices(
          page: 1, limit: 30, startDate: DateTime(2025, 3, 1), endDate: DateTime(2025, 3, 31));
    });
    results['búsqueda "FV-0123"'] = await ms(() async {
      await repo.getInvoices(page: 1, limit: 30, search: 'FV-0123');
    });
    results['búsqueda cliente "Cliente12"'] = await ms(() async {
      await repo.getInvoices(page: 1, limit: 30, search: 'Cliente12');
    });
    results['búsqueda amplia "Cliente1" (1.111 clientes)'] = await ms(() async {
      await repo.getInvoices(page: 1, limit: 30, search: 'Cliente1');
    }, runs: 3);
    results['orden por número'] = await ms(() async {
      await repo.getInvoices(page: 1, limit: 30, sortBy: 'number');
    });
    results['estadísticas'] = await ms(() async {
      await repo.getInvoiceStats();
    });
    // ignore: avoid_print
    results.forEach((k, v) => print('PERF lista facturas | $k: $v ms'));
    expect(first, hasLength(30));
    expect(first.first.id, 'inv-${invoiceCount - 1}');
    expect(first[1].id, 'inv-${invoiceCount - 2}');
    expect(first.first.customer, isNotNull);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
