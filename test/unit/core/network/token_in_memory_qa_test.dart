// QA 1.0.24 (cambio C1, token en memoria): casos que la prueba del cambio no
// cubre. Almacén REAL de la app sobre un complemento simulado (nunca el
// llavero del equipo) y un servidor local.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/core/network/api_interceptor.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart'
    show FlutterSecureStoragePlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/secure_storage_lost_key_test.dart' show FakeProtector;
import 'token_in_memory_test.dart' show GateStore, jwt;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  late SecureStorageService storage;
  late Dio dio;
  final seen = <String>[];
  final expired = <String>{};
  String? refreshAnswer;
  int refreshCalls = 0;
  Completer<void>? refreshGate;

  final tA = jwt('qa-a');
  final tNew = jwt('qa-a-renovado');

  setUpAll(() async {
    HttpOverrides.global = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      await req.drain<void>();
      final auth = req.headers.value('authorization');
      seen.add('${req.uri.path} ${auth ?? '-'}');
      void reply(int status, Object body) {
        req.response.statusCode = status;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode(body));
      }

      if (req.uri.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        final g = refreshGate;
        if (g != null) await g.future;
        final answer = refreshAnswer;
        answer == null
            ? reply(401, {'message': 'refresh vencido'})
            : reply(200, {
                'success': true,
                'data': {'token': answer}
              });
      } else if (auth != null && expired.contains(auth.replaceFirst('Bearer ', ''))) {
        reply(401, {'message': 'token vencido'});
      } else {
        reply(200, {'ok': true});
      }
      await req.response.close();
    });
    dotenv.testLoad(
        fileInput: 'SERVER_IP=127.0.0.1\nSERVER_PORT=${server.port}\nAPP_ENV=development');
  });

  tearDownAll(() async => server.close(force: true));

  Future<void> start(Map<String, String> stored) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SharedPreferences.setMockInitialValues({});
    SecureStorageService.debugSimulateRestart();
    SecureStorageService.debugResetQueue();
    SessionStartupTrace.debugReset();
    SecureStorageService.debugProtector = FakeProtector();
    FlutterSecureStoragePlatform.instance = GateStore(stored);
    storage = SecureStorageService();
    seen.clear();
    expired.clear();
    refreshAnswer = null;
    refreshCalls = 0;
    refreshGate = null;
    ApiInterceptor.takeSessionExpiredFlag();
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}/api'))
      ..interceptors.add(ApiInterceptor(storage));
  }

  tearDown(() {
    refreshGate?.isCompleted == false ? refreshGate!.complete() : null;
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
    SecureStorageService.debugSimulateRestart();
    SecureStorageService.debugResetQueue();
  });

  test('arranque en frío con sesión guardada: la PRIMERA petición ya lleva el token',
      () async {
    await start({'auth_token': tA, 'refresh_token': 'r1'});
    expect(SecureStorageService.tokenInMemory.known, isFalse);
    await dio.get('/products');
    expect(seen.single, '/api/products Bearer $tA');
  });

  test('tres 401 a la vez: una sola renovación y las tres se repiten con el token nuevo',
      () async {
    await start({'auth_token': tA, 'refresh_token': 'r1'});
    await dio.get('/warmup');
    expired.add(tA);
    refreshAnswer = tNew;
    refreshGate = Completer<void>();

    final calls = [
      dio.get('/products'),
      dio.get('/customers'),
      dio.get('/invoices'),
    ];
    await Future<void>.delayed(const Duration(milliseconds: 150));
    refreshGate!.complete();
    final responses = await Future.wait(calls);

    expect(responses.map((r) => r.statusCode), [200, 200, 200]);
    expect(refreshCalls, 1, reason: 'se renovó más de una vez');
    for (final p in ['/api/products', '/api/customers', '/api/invoices']) {
      expect(seen, contains('$p Bearer $tNew'), reason: '$p no se repitió con el token nuevo');
    }
    await dio.get('/after');
    expect(seen.last, '/api/after Bearer $tNew');
    expect(SecureStorageService.tokenInMemory, (known: true, token: tNew));
  });

  test('cerrar sesión e iniciar otra vez en la misma ejecución: la petición lleva el token nuevo',
      () async {
    await start({'auth_token': tA, 'refresh_token': 'r1'});
    await dio.get('/products');
    await storage.clearAuthData();
    await dio.get('/ping');
    expect(seen.last, '/api/ping -');
    await storage.saveAuthData(
        token: tNew, refreshToken: 'r2', userData: {'id': 'qa-a', 'organizationId': 'org-a'});
    await dio.get('/products');
    expect(seen.last, '/api/products Bearer $tNew');
  });

  // Riesgo que ya existía antes de 1.0.24 (el almacén también lo guardaba):
  // una renovación que estaba en curso cuando el cajero cerró sesión.
  // Fallaba desde 1.0.23 (6d4b41d); arreglado: la renovación no guarda su
  // token si la sesión se cerró mientras se renovaba.
  test('renovación en curso mientras se cierra sesión: no revive el token',
      () async {
    await start({'auth_token': tA, 'refresh_token': 'r1'});
    await dio.get('/warmup');
    expired.add(tA);
    refreshAnswer = tNew;
    refreshGate = Completer<void>();

    final pending = dio.get('/products').catchError((Object e) => Response(
        requestOptions: RequestOptions(path: '/products'), statusCode: -1));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await storage.clearAuthData(); // el cajero cierra sesión
    refreshGate!.complete();
    await pending;
    await dio.get('/ping');
    // ignore: avoid_print
    print('MEDICION tras cerrar sesión con renovación en curso: '
        'memoria=${SecureStorageService.tokenInMemory.token == null ? 'vacía' : 'CON TOKEN'}, '
        'última petición="${seen.last}"');
    expect(seen.last, '/api/ping -',
        reason: 'tras cerrar sesión una petición salió con el token renovado');
  });
}
