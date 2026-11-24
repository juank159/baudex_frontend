import 'dart:async';

import 'package:baudex_desktop/app/core/printing/print_job_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los tiquetes salen en orden, de uno en uno, sin rechazar el segundo',
      () async {
    final queue = PrintJobQueue();
    final log = <String>[];
    final first = Completer<bool>();

    final a = queue.add(() async {
      log.add('A empieza');
      final r = await first.future;
      log.add('A termina');
      return r;
    });
    final b = queue.add(() async {
      log.add('B empieza');
      return true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(log, ['A empieza']); // B espera, no se rechaza ni se cruza
    expect(queue.pending, 2);

    first.complete(true);
    expect(await a, isTrue);
    expect(await b, isTrue);
    expect(log, ['A empieza', 'A termina', 'B empieza']);
    expect(queue.isBusy, isFalse);
  });

  test('quien encola no espera: add devuelve de una vez', () async {
    final queue = PrintJobQueue();
    final never = Completer<bool>();
    final sw = Stopwatch()..start();
    final pending = queue.add(() => never.future);
    expect(sw.elapsedMilliseconds, lessThan(5));
    never.complete(true);
    await pending;
  });

  test('un tiquete que falla no tranca los siguientes', () async {
    final queue = PrintJobQueue();
    final failed = queue.add<bool>(() async => throw StateError('sin papel'));
    final next = queue.add(() async => true);
    await expectLater(failed, throwsStateError);
    expect(await next, isTrue);
    expect(queue.pending, 0);
  });

  test('avisa cuántos hay pendientes (para el indicador de impresión)',
      () async {
    final seen = <int>[];
    final queue = PrintJobQueue(onPendingChanged: seen.add);
    await Future.wait([
      queue.add(() async => true),
      queue.add(() async => true),
    ]);
    expect(seen, [1, 2, 1, 0]);
  });
}
