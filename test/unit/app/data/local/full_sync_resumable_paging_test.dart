import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simula un módulo paginado de [totalPages] páginas. Cada página "tarda"
/// [perPage]; registra qué páginas pidió.
Future<int> Function() _pagedModule(
  FullSyncService sync,
  int totalPages,
  List<int> requested, {
  Duration perPage = Duration.zero,
}) {
  return () async {
    var page = sync.debugStartPage();
    var hasMore = true;
    var total = 0;
    while (hasMore && sync.debugContinuePaging(page)) {
      if (page > totalPages) break; // respuesta vacía
      requested.add(page);
      if (perPage > Duration.zero) await Future.delayed(perPage);
      total++;
      hasMore = page < totalPages;
      page = sync.debugNextPage(page);
    }
    return total;
  };
}

void main() {
  late FullSyncService sync;

  setUp(() => sync = FullSyncService(IsarDatabase.instance));

  test('sin tiempo límite (descarga inicial) baja todas las páginas', () async {
    final requested = <int>[];
    final count = await sync.debugSyncEntity(
      'Facturas',
      _pagedModule(sync, 5, requested),
    );
    expect(count, 5);
    expect(requested, [1, 2, 3, 4, 5]);
  });

  test('en pull periódico se detiene al agotar el tiempo y sigue donde quedó',
      () async {
    final first = <int>[];
    await sync.debugSyncEntity(
      'Facturas',
      _pagedModule(sync, 10, first, perPage: const Duration(milliseconds: 30)),
      deadline: DateTime.now().add(const Duration(milliseconds: 100)),
    );
    expect(first.length, lessThan(10));
    final stoppedAfter = first.last;

    // Segundo pull: refresca la página 1 y salta a donde quedó.
    final second = <int>[];
    await sync.debugSyncEntity(
      'Facturas',
      _pagedModule(sync, 10, second),
      deadline: DateTime.now().add(const Duration(seconds: 5)),
    );
    expect(second.first, 1);
    expect(second[1], stoppedAfter + 1);
    expect(second.last, 10);

    // Llegó al final: el tercer pull vuelve a empezar desde la 1, sin saltos.
    final third = <int>[];
    await sync.debugSyncEntity(
      'Facturas',
      _pagedModule(sync, 10, third),
      deadline: DateTime.now().add(const Duration(seconds: 5)),
    );
    expect(third, List.generate(10, (i) => i + 1));
  });

  test('módulos que reemplazan la lista completa nunca se cortan por tiempo',
      () async {
    final requested = <int>[];
    final count = await sync.debugSyncEntity(
      'Categorías de Gastos',
      _pagedModule(sync, 6, requested, perPage: const Duration(milliseconds: 30)),
      deadline: DateTime.now().add(const Duration(milliseconds: 40)),
    );
    expect(count, 6);
    expect(requested, [1, 2, 3, 4, 5, 6]);
  });

  test('si la posición guardada ya no existe, termina y reinicia', () async {
    final first = <int>[];
    await sync.debugSyncEntity(
      'Productos',
      _pagedModule(sync, 10, first, perPage: const Duration(milliseconds: 30)),
      deadline: DateTime.now().add(const Duration(milliseconds: 100)),
    );
    // Ahora el catálogo es más corto que la posición guardada.
    final second = <int>[];
    final count = await sync.debugSyncEntity(
      'Productos',
      _pagedModule(sync, 1, second),
      deadline: DateTime.now().add(const Duration(seconds: 5)),
    );
    expect(second, [1]);
    expect(count, 1);
    final third = <int>[];
    await sync.debugSyncEntity(
      'Productos',
      _pagedModule(sync, 3, third),
      deadline: DateTime.now().add(const Duration(seconds: 5)),
    );
    expect(third, [1, 2, 3]);
  });
}
