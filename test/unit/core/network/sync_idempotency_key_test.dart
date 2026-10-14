import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:baudex_desktop/app/core/network/api_interceptor.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements SecureStorageService {}

/// Adaptador HTTP falso: registra la clave de idempotencia de cada petición.
class RecordingAdapter implements HttpClientAdapter {
  final List<String?> keys = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    keys.add(options.headers[ApiInterceptor.idempotencyKeyHeader] as String?);
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Ejecuta [body] como lo hace SyncService al procesar una operación de la cola.
Future<T> asSyncOperation<T>(String operationKey, Future<T> Function() body) {
  return runZoned(
    body,
    zoneValues: <Object?, Object?>{
      ApiInterceptor.syncOperationZoneKey: operationKey,
      ApiInterceptor.syncOperationSeqZoneKey: <String, int>{},
    },
  );
}

void main() {
  late Dio dio;
  late RecordingAdapter adapter;

  setUp(() {
    final storage = MockStorage();
    when(() => storage.getToken()).thenAnswer((_) async => 'token');
    when(() => storage.getOrCreateDeviceId()).thenAnswer((_) async => 'device-1');

    adapter = RecordingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(ApiInterceptor(storage));
  });

  test('el reintento de la misma operación manda EXACTAMENTE la misma clave', () async {
    Future<void> attempt() => asSyncOperation('17_1700000000000000', () async {
          await dio.post('/expenses', data: {'amount': 5000, 'description': 'luz'});
        });

    await attempt();
    await attempt();
    await attempt();

    expect(adapter.keys.toSet().length, 1);
    expect(adapter.keys.first, startsWith('op_'));
  });

  test('operaciones distintas con el mismo contenido NO comparten clave', () async {
    final data = {'amount': 5000, 'description': 'luz'};
    await asSyncOperation('17_1700000000000000', () => dio.post('/expenses', data: data));
    await asSyncOperation('18_1700000000000001', () => dio.post('/expenses', data: data));

    expect(adapter.keys[0], isNot(adapter.keys[1]));
  });

  test('dos peticiones de la misma operación nunca comparten clave', () async {
    await asSyncOperation('20_1', () async {
      await dio.post('/inventory/movements', data: {'productId': 'a', 'quantity': 1});
      await dio.post('/inventory/movements', data: {'productId': 'b', 'quantity': 1});
      // misma ruta y mismo contenido, pero es la 2.ª vez dentro de la operación
      await dio.post('/inventory/movements', data: {'productId': 'a', 'quantity': 1});
      await dio.patch('/inventory/movements', data: {'productId': 'a', 'quantity': 1});
    });

    expect(adapter.keys.toSet().length, 4);
  });

  test('una operación con varias peticiones repite todas sus claves al reintentar', () async {
    Future<void> attempt() => asSyncOperation('21_9', () async {
          await dio.post('/invoices', data: {'number': 'INV-1'});
          await dio.post('/invoices/abc/payments', data: {'amount': 100});
          await dio.post('/invoices/abc/payments', data: {'amount': 100});
        });

    await attempt();
    final first = List<String?>.from(adapter.keys);
    adapter.keys.clear();
    await attempt();

    expect(adapter.keys, first);
  });

  test('si el contenido cambia entre reintentos, la clave cambia (nunca se confunde con otra petición)', () async {
    await asSyncOperation('22_1', () => dio.post('/customers', data: {'name': 'Ana'}));
    await asSyncOperation('22_1', () => dio.post('/customers', data: {'name': 'Ana María'}));

    expect(adapter.keys[0], isNot(adapter.keys[1]));
  });

  test('una clave explícita (abonos) tiene prioridad sobre la de la operación', () async {
    await asSyncOperation('23_1', () {
      return dio.post(
        '/customer-credits/x/payments',
        data: {'amount': 1},
        options: Options(extra: {'idempotency_key': 'clave-del-abono'}),
      );
    });

    expect(adapter.keys.single, 'clave-del-abono');
  });

  test('fuera de la cola se usa la clave automática de siempre', () async {
    await dio.post('/expenses', data: {'amount': 1});
    expect(adapter.keys.single, startsWith('idem_'));
  });

  test('las consultas (GET) no llevan clave', () async {
    await asSyncOperation('24_1', () => dio.get('/expenses'));
    expect(adapter.keys.single, isNull);
  });

  uncertainWriteTests();
}

/// Adaptador que falla sin respuesta (como un timeout) las primeras veces.
class FlakyAdapter implements HttpClientAdapter {
  final List<String?> keys = [];
  int failuresLeft;
  final int? failStatus;

  FlakyAdapter({required this.failuresLeft, this.failStatus});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    keys.add(options.headers[ApiInterceptor.idempotencyKeyHeader] as String?);
    if (failuresLeft > 0) {
      failuresLeft--;
      if (failStatus != null) {
        return ResponseBody.fromString('{"message":"x"}', failStatus!, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      }
      throw DioException.connectionTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: options,
      );
    }
    return ResponseBody.fromString('{"ok":true}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Dio buildDio(HttpClientAdapter adapter) {
  final storage = MockStorage();
  when(() => storage.getToken()).thenAnswer((_) async => 'token');
  when(() => storage.getRefreshToken()).thenAnswer((_) async => null);
  when(() => storage.getOrCreateDeviceId()).thenAnswer((_) async => 'device-1');
  return Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ApiInterceptor(storage));
}

Future<T> asSyncOperationInheriting<T>(
  String operationKey,
  List<UncertainWrite> inherited,
  Future<T> Function() body,
) {
  return runZoned(
    body,
    zoneValues: <Object?, Object?>{
      ApiInterceptor.syncOperationZoneKey: operationKey,
      ApiInterceptor.syncOperationSeqZoneKey: <String, int>{},
      ApiInterceptor.syncOperationInheritedKeysZoneKey:
          inherited.map((w) => UncertainWrite.fromJson(w.toJson())!).toList(),
    },
  );
}

void uncertainWriteTests() {
  group('intento en línea incierto → la operación encolada hereda su clave', () {
    setUp(ApiInterceptor.claimUncertainWrites); // vaciar registro entre pruebas

    test('venta en línea sin respuesta: el reenvío desde la cola usa la MISMA clave', () async {
      final adapter = FlakyAdapter(failuresLeft: 1);
      final dio = buildDio(adapter);

      // 1. Intento en línea: se pierde la respuesta
      await expectLater(
        dio.post('/invoices', data: {'customerId': 'c1', 'total': 8500}),
        throwsA(isA<DioException>()),
      );
      final onlineKey = adapter.keys.single;

      // 2. El repositorio guarda offline y encola. Las operaciones auxiliares
      //    (inventario) NO se llevan la clave; la hereda la venta.
      expect(ApiInterceptor.claimUncertainWrites(entityType: 'inventory_movement_fifo'), isEmpty);
      expect(ApiInterceptor.claimUncertainWrites(entityType: 'InventoryMovement'), isEmpty);
      final inherited = ApiInterceptor.claimUncertainWrites(entityType: 'Invoice');
      expect(inherited.single.key, onlineKey);
      expect(
        ApiInterceptor.claimUncertainWrites(entityType: 'Invoice'),
        isEmpty,
        reason: 'una venta posterior NO puede heredar la clave de esta',
      );

      // 3. La cola la sube (con otro contenido: ya tiene datos locales)
      await asSyncOperationInheriting('5_1', inherited, () {
        return dio.post('/invoices', data: {'customerId': 'c1', 'total': 8500, 'number': 'TEMP-1'});
      });
      expect(adapter.keys.last, onlineKey);

      // 4. Si ese envío también falla y se reintenta, sigue siendo la misma
      await asSyncOperationInheriting('5_1', inherited, () {
        return dio.post('/invoices', data: {'customerId': 'c1', 'total': 8500, 'number': 'TEMP-1'});
      });
      expect(adapter.keys.last, onlineKey);
    });

    test('cada tipo de operación hereda solo lo suyo', () async {
      final adapter = FlakyAdapter(failuresLeft: 3);
      final dio = buildDio(adapter);
      await expectLater(dio.post('/expenses', data: {'amount': 1}), throwsA(isA<DioException>()));
      await expectLater(dio.post('/customer-credits/abc/add-amount', data: {'amount': 1}), throwsA(isA<DioException>()));
      await expectLater(dio.patch('/products/p1', data: {'name': 'x'}), throwsA(isA<DioException>()));

      expect(ApiInterceptor.claimUncertainWrites(entityType: 'Expense').single.path, '/expenses');
      expect(ApiInterceptor.claimUncertainWrites(entityType: 'CustomerCredit').single.path, '/customer-credits/abc/add-amount');
      expect(ApiInterceptor.claimUncertainWrites(entityType: 'Product').single.path, '/products/p1');
      expect(ApiInterceptor.claimUncertainWrites(), isEmpty);
    });

    test('error 500 del servidor también cuenta como incierto', () async {
      final adapter = FlakyAdapter(failuresLeft: 1, failStatus: 500);
      final dio = buildDio(adapter);
      await expectLater(dio.post('/expenses', data: {'amount': 1}), throwsA(isA<DioException>()));
      expect(ApiInterceptor.claimUncertainWrites().single.key, adapter.keys.single);
    });

    test('un rechazo del servidor (400) NO es incierto: no se hereda nada', () async {
      final adapter = FlakyAdapter(failuresLeft: 1, failStatus: 400);
      final dio = buildDio(adapter);
      await expectLater(dio.post('/expenses', data: {'amount': 1}), throwsA(isA<DioException>()));
      expect(ApiInterceptor.claimUncertainWrites(), isEmpty);
    });

    test('la clave heredada solo se usa para el mismo método y ruta, y una sola vez', () async {
      final adapter = FlakyAdapter(failuresLeft: 1);
      final dio = buildDio(adapter);
      await expectLater(dio.post('/invoices', data: {'a': 1}), throwsA(isA<DioException>()));
      final onlineKey = adapter.keys.single;
      final inherited = ApiInterceptor.claimUncertainWrites();

      await asSyncOperationInheriting('6_1', inherited, () async {
        await dio.post('/customer-credits', data: {'a': 1}); // otra ruta
        await dio.post('/invoices', data: {'a': 1}); // el reenvío
        await dio.post('/invoices', data: {'b': 2}); // otra petición a la misma ruta
      });

      expect(adapter.keys[1], isNot(onlineKey));
      expect(adapter.keys[2], onlineKey);
      expect(adapter.keys[3], isNot(onlineKey));
    });

    test('las peticiones de la propia cola no se registran como inciertas', () async {
      final adapter = FlakyAdapter(failuresLeft: 1);
      final dio = buildDio(adapter);
      await expectLater(
        asSyncOperation('7_1', () => dio.post('/invoices', data: {'a': 1})),
        throwsA(isA<DioException>()),
      );
      expect(ApiInterceptor.claimUncertainWrites(), isEmpty);
    });
  });
}
