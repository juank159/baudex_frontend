// test/unit/features/invoices/barcode_scan_queue_test.dart
import 'dart:async';

import 'package:baudex_desktop/features/invoices/presentation/widgets/barcode_scan_queue.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/product_fixtures.dart';

void main() {
  late List<String> events;
  late Map<String, Completer<Product?>> lookups;
  late BarcodeScanQueue queue;

  setUp(() {
    events = [];
    lookups = {};
    queue = BarcodeScanQueue(
      find: (code) => (lookups[code] = Completer<Product?>()).future,
      onFound: (product, code) => events.add('found:$code:${product.id}'),
      onNotFound: (code) => events.add('notfound:$code'),
    );
  });

  Product product(String id) => ProductFixtures.createProductEntity(id: id);

  test('procesa escaneos rápidos en orden sin perder ninguno', () async {
    final done = queue.add('11111111');
    queue.add('22222222');
    queue.add('33333333');
    expect(queue.pendingCount, 3);

    // Solo se busca uno a la vez.
    await Future<void>.delayed(Duration.zero);
    expect(lookups.keys, ['11111111']);

    lookups['11111111']!.complete(product('a'));
    await Future<void>.delayed(Duration.zero);
    lookups['22222222']!.complete(null);
    await Future<void>.delayed(Duration.zero);
    lookups['33333333']!.complete(product('c'));
    await done;

    expect(events, [
      'found:11111111:a',
      'notfound:22222222',
      'found:33333333:c',
    ]);
    expect(queue.pendingCount, 0);
  });

  test('un error al buscar cuenta como no encontrado y sigue la cola',
      () async {
    final q = BarcodeScanQueue(
      find: (code) async =>
          code == 'malo' ? throw Exception('x') : product('ok'),
      onFound: (p, code) => events.add('found:$code'),
      onNotFound: (code) => events.add('notfound:$code'),
    );
    q.add('malo');
    await q.add('bueno');
    expect(events, ['notfound:malo', 'found:bueno']);
  });

  test('ignora códigos vacíos', () async {
    await queue.add('   ');
    expect(lookups, isEmpty);
    expect(events, isEmpty);
  });

  test('después de cerrar la pantalla no avisa nada', () async {
    final done = queue.add('11111111');
    queue.add('22222222');
    await Future<void>.delayed(Duration.zero);
    queue.dispose();
    lookups['11111111']!.complete(product('a'));
    await done;
    expect(events, isEmpty);
    expect(lookups.keys, ['11111111']);
  });
}
