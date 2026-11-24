import 'dart:async';

import 'package:baudex_desktop/app/core/printing/keyed_async_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mientras la llave no cambie, el logo se prepara una sola vez',
      () async {
    final cache = KeyedAsyncCache<String>();
    for (var i = 0; i < 50; i++) {
      expect(await cache.get('archivo:logo.png:100:2048', () async => 'logo'),
          'logo');
    }
    expect(cache.loads, 1);
  });

  test('si cambia el logo (otra fecha o tamaño), se prepara de nuevo',
      () async {
    final cache = KeyedAsyncCache<String>();
    expect(await cache.get('archivo:logo.png:100:2048', () async => 'viejo'),
        'viejo');
    expect(await cache.get('archivo:logo.png:200:4096', () async => 'nuevo'),
        'nuevo');
    expect(await cache.get('archivo:logo.png:200:4096', () async => 'otro'),
        'nuevo');
    expect(cache.loads, 2);
  });

  test('si no se pudo bajar, no se reintenta en cada tiquete sino a los 10 min',
      () async {
    var now = DateTime(2026, 11, 24, 10);
    final cache = KeyedAsyncCache<String>(now: () => now);
    Future<String?> fail() async => throw TimeoutException('sin internet');

    expect(await cache.get('url:https://x/logo.png', fail), isNull);
    for (var i = 0; i < 20; i++) {
      expect(await cache.get('url:https://x/logo.png', fail), isNull);
    }
    expect(cache.loads, 1);

    now = now.add(const Duration(minutes: 11));
    expect(await cache.get('url:https://x/logo.png', () async => 'logo'),
        'logo');
    expect(cache.loads, 2);
  });

  test('dos pedidos a la vez comparten una sola carga', () async {
    final cache = KeyedAsyncCache<String>();
    final gate = Completer<String>();
    final a = cache.get('k', () => gate.future);
    final b = cache.get('k', () => gate.future);
    gate.complete('logo');
    expect(await a, 'logo');
    expect(await b, 'logo');
    expect(cache.loads, 1);
  });

  test('sin llave (sin logo) no carga nada', () async {
    final cache = KeyedAsyncCache<String>();
    expect(await cache.get(null, () async => 'x'), isNull);
    expect(cache.loads, 0);
  });
}
