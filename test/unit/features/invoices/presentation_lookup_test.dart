// Presentaciones al agregar un producto: lo del equipo responde ya; el
// servidor nunca frena la línea.
import 'dart:async';

import 'package:baudex_desktop/features/invoices/data/presentation_lookup.dart';
import 'package:baudex_desktop/features/invoices/data/short_code_index_keeper.dart';
import 'package:baudex_desktop/features/products/domain/entities/product_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

ProductPresentation presentation(String id, {bool active = true}) =>
    ProductPresentation(
      id: id,
      name: 'Presentación $id',
      factor: 1,
      price: 1000,
      isActive: active,
      productId: 'p1',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  late Map<String, List<ProductPresentation>> local;
  late bool moduleComplete;
  late int localReads, fetches;
  late Completer<List<ProductPresentation>?> server;
  late DateTime now;

  PresentationLookup lookup() => PresentationLookup(
        readLocal: (id) async {
          localReads++;
          return local[id] ?? const [];
        },
        isModuleComplete: () async => moduleComplete,
        fetch: (id) {
          fetches++;
          return server.future;
        },
        now: () => now,
      );

  setUp(() {
    local = {};
    moduleComplete = true;
    localReads = fetches = 0;
    server = Completer();
    now = DateTime(2026, 11, 25, 10);
  });

  test('con las presentaciones en el equipo responde sin ir al servidor', () async {
    local['p1'] = [presentation('a'), presentation('b')];
    moduleComplete = false; // aunque el módulo no haya terminado de bajar
    final l = lookup();
    expect((await l.known('p1'))!.map((p) => p.id), ['a', 'b']);
    expect(fetches, 0);
  });

  test('módulo completo y nada en el equipo: no tiene (lista vacía)', () async {
    final l = lookup();
    expect(await l.known('p1'), isEmpty);
    expect(fetches, 0);
  });

  test('módulo sin terminar de bajar y nada en el equipo: "no se sabe" (null), '
      'sin esperar al servidor', () async {
    moduleComplete = false;
    final l = lookup();
    expect(await l.known('p1'), isNull);
    expect(fetches, 0, reason: 'known nunca pregunta al servidor');
  });

  test('re-leer el mismo producto no vuelve a consultar ni la base', () async {
    local['p1'] = [presentation('a')];
    final l = lookup();
    await l.known('p1');
    await l.known('p1');
    await l.known('p1');
    expect(localReads, 1);
  });

  test('la respuesta del servidor se recuerda: la lectura siguiente ya la sabe',
      () async {
    moduleComplete = false;
    final l = lookup();
    expect(await l.known('p1'), isNull);
    final asked = l.resolve('p1');
    final again = l.resolve('p1'); // otra lectura mientras tanto
    expect(fetches, 1, reason: 'una sola pregunta a la vez por producto');
    server.complete([presentation('a'), presentation('b')]);
    expect((await asked)!.length, 2);
    expect((await again)!.length, 2);
    expect((await l.known('p1'))!.length, 2);
    expect(fetches, 1);
  });

  test('si el servidor no responde, no se recuerda nada y se vuelve a preguntar',
      () async {
    moduleComplete = false;
    final l = lookup();
    final asked = l.resolve('p1');
    server.complete(null);
    expect(await asked, isNull);
    expect(await l.known('p1'), isNull);
    server = Completer()..complete([presentation('a')]);
    expect((await l.resolve('p1'))!.length, 1);
    expect(fetches, 2);
  });

  test('lo recordado vence a los 5 minutos', () async {
    local['p1'] = [presentation('a')];
    final l = lookup();
    await l.known('p1');
    local['p1'] = [presentation('a'), presentation('b')];
    now = now.add(const Duration(minutes: 4));
    expect((await l.known('p1'))!.length, 1);
    now = now.add(const Duration(minutes: 2));
    expect((await l.known('p1'))!.length, 2);
  });

  test('índice de códigos: una carga que falla se anota y no revienta', () async {
    Object? failure;
    var loads = 0;
    final keeper = ShortCodeIndexKeeper(
      loadCodes: () async {
        loads++;
        if (loads == 1) throw StateError('base ocupada');
        return [('5000', 1)];
      },
      isCatalogComplete: () async => true,
      onLoadFailed: (e) => failure = e,
    );
    await keeper.refresh();
    expect(failure, isA<StateError>());
    expect(keeper.index, isNull);
    await keeper.refresh();
    expect(keeper.index, isNotNull, reason: 'el siguiente intento sí carga');
    keeper.dispose();
  });

  test('índice de códigos: al avisar que cargó, ya figura cargado', () async {
    late ShortCodeIndexKeeper keeper;
    bool? loadedWhenNotified;
    keeper = ShortCodeIndexKeeper(
      loadCodes: () async => [('5000', 1)],
      isCatalogComplete: () async => true,
      onLoaded: (_) => loadedWhenNotified = keeper.index != null,
    );
    await keeper.refresh();
    expect(loadedWhenNotified, isTrue,
        reason: 'antes el diagnóstico decía "índice sin cargar" recién cargado');
    keeper.dispose();
  });
}
