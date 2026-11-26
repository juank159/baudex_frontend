// Trabajo automático: sus errores no avisan en pantalla; quedan anotados
// con ruta, código y mensaje.
import 'dart:async';

import 'package:baudex_desktop/app/core/errors/automatic_work.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(BackgroundFailureLog.instance.clear);

  group('marca de trabajo automático', () {
    test('fuera de un trabajo automático los avisos SÍ se muestran', () {
      expect(AutomaticWork.current, isNull);
      expect(AutomaticWork.swallow('Error', 'x'), isFalse);
      expect(BackgroundFailureLog.instance.silencedNotices, 0);
    });

    test('dentro, el aviso se calla y queda anotado', () {
      final swallowed = AutomaticWork.run('clientes: carga al abrir',
          () => AutomaticWork.swallow('Error al cargar clientes', 'Error del servidor'));
      expect(swallowed, isTrue);
      final log = BackgroundFailureLog.instance;
      expect(log.silencedNotices, 1);
      expect(log.entries.single.source, 'clientes: carga al abrir');
      expect(log.entries.single.message,
          'aviso no mostrado: Error al cargar clientes — Error del servidor');
    });

    test('la marca sigue al trabajo después de cada espera, temporizador y '
        'en funciones de otros archivos', () async {
      Future<bool> deepInside() async {
        await Future<void>.delayed(const Duration(milliseconds: 1));
        final viaTimer = Completer<bool>();
        Timer(Duration.zero,
            () => viaTimer.complete(AutomaticWork.swallow('Error', 'tarde')));
        return await viaTimer.future;
      }

      expect(await AutomaticWork.run('negocio: recarga automática', deepInside),
          isTrue);
      // Y lo que el usuario pide a la vez no queda marcado.
      expect(AutomaticWork.swallow('Error', 'del usuario'), isFalse);
    });
  });

  group('peticiones fallidas', () {
    test('se anotan con ruta, código y mensaje; la ruta sin los valores de '
        'la consulta', () {
      final log = BackgroundFailureLog();
      AutomaticWork.run('clientes: carga al abrir', () {
        // (la instancia global es la que usa el cliente HTTP; aquí una propia)
        log.noteRequest(
          method: 'GET',
          route: '/api/customers?page=1&limit=20&search=Juan Perez 1098',
          statusCode: 400,
          message: 'Solicitud incorrecta: property foo should not exist',
        );
      });
      final e = log.entries.single;
      expect(e.source, 'clientes: carga al abrir');
      expect(e.route, '/api/customers?page&limit&search',
          reason: 'sin datos del negocio');
      expect(e.statusCode, 400);
      expect(e.line, contains('GET /api/customers?page&limit&search → 400 — '
          'Solicitud incorrecta: property foo should not exist'));
    });

    test('lo que pidió el usuario también queda anotado, como tal', () {
      final log = BackgroundFailureLog();
      log.noteRequest(
          method: 'POST', route: '/api/invoices', statusCode: 409, message: 'x');
      expect(log.entries.single.source, BackgroundFailureLog.userAction);
    });

    test('un 5xx de trabajo automático se reporta; uno del usuario o un 4xx, no',
        () {
      final log = BackgroundFailureLog();
      final reported = <String>[];
      log.onServerError = (f) => reported.add('${f.route} ${f.statusCode}');
      AutomaticWork.run('negocio', () {
        log.noteRequest(
            method: 'GET', route: '/api/organizations/current', statusCode: 500, message: 'x');
        log.noteRequest(
            method: 'GET', route: '/api/customers', statusCode: 404, message: 'x');
      });
      log.noteRequest(
          method: 'GET', route: '/api/products', statusCode: 500, message: 'x');
      expect(reported, ['/api/organizations/current 500']);
    });

    test('sin respuesta (sin internet): queda como "sin respuesta"', () {
      final log = BackgroundFailureLog();
      log.noteRequest(method: 'GET', route: '/api/health', message: 'Sin conexión');
      expect(log.entries.single.line, contains('→ sin respuesta — Sin conexión'));
    });

    test('guarda solo las últimas y el reporte nunca falla', () {
      final log = BackgroundFailureLog(capacity: 3);
      expect(log.report(), contains('(ninguna)'));
      for (var i = 0; i < 10; i++) {
        log.noteRequest(
            method: 'GET', route: '/r$i', statusCode: 500, message: 'm\n' * 200);
      }
      expect(log.entries, hasLength(3));
      expect(log.failedRequests, 10);
      final report = log.report();
      expect(report, contains('Peticiones fallidas: 10'));
      expect(report, contains('/r9'));
      expect(report, isNot(contains('/r0 ')));
    });
  });

  group('una sola petición por entrada (SharedRequest)', () {
    test('varias llamadas a la vez comparten una sola petición', () async {
      var calls = 0;
      final gate = Completer<void>();
      final shared = SharedRequest(minInterval: const Duration(seconds: 10));
      Future<void> body() {
        calls++;
        return gate.future;
      }

      final all = [for (var i = 0; i < 6; i++) shared.run(body)];
      gate.complete();
      await Future.wait(all);
      expect(calls, 1);
      expect(shared.skipped, 5);
    });

    test('recién respondida no se repite; pasado el rato o con force, sí',
        () async {
      var now = DateTime(2026, 11, 26, 10);
      var calls = 0;
      final shared = SharedRequest(
          minInterval: const Duration(seconds: 10), now: () => now);
      Future<void> body() async => calls++;
      await shared.run(body);
      await shared.run(body);
      expect(calls, 1);
      await shared.run(body, force: true);
      expect(calls, 2);
      now = now.add(const Duration(seconds: 11));
      await shared.run(body);
      expect(calls, 3);
      shared.reset();
      await shared.run(body);
      expect(calls, 4, reason: 'sesión nueva: se pide ya');
    });

    test('si la petición falla, la siguiente se puede hacer', () async {
      var calls = 0;
      final shared = SharedRequest(minInterval: Duration.zero);
      Future<void> body() async {
        calls++;
        throw StateError('x');
      }

      await expectLater(shared.run(body), throwsStateError);
      await expectLater(shared.run(body), throwsStateError);
      expect(calls, 2);
    });
  });
}
