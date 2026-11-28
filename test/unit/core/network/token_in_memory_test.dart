// El token de la sesión vive en memoria durante la ejecución.
//
// Caso real (Windows, 1.0.21+): cada petición leía el token pasando por la
// fila del almacén de sesión; una escritura lenta (12 s) dejaba el botón de
// Procesar cargando 12 s aunque el servidor contestara al instante.
//
// Aquí se usa el almacén REAL de la app (SecureStorageService) sobre un
// complemento simulado (nunca el llavero del equipo) y un servidor local.
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
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart'
    show FlutterSecureStoragePlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/secure_storage_lost_key_test.dart' show FakeProtector;

/// Complemento simulado: mientras [gate] esté puesto, toda operación espera
/// (un almacén lento). `failDeletes` simula un almacén que no deja borrar.
class GateStore extends TestFlutterSecureStoragePlatform {
  GateStore(super.data);
  Completer<void>? gate;
  bool failDeletes = false;
  int operations = 0;

  Future<void> _wait() async {
    operations++;
    final g = gate;
    if (g != null) await g.future;
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async {
    await _wait();
    return super.read(key: key, options: options);
  }

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) async {
    await _wait();
    return Map<String, String>.of(data);
  }

  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) async {
    await _wait();
    return super.write(key: key, value: value, options: options);
  }

  @override
  Future<void> delete({required String key, required Map<String, String> options}) async {
    await _wait();
    if (failDeletes) throw Exception('el almacén no dejó borrar');
    return super.delete(key: key, options: options);
  }
}

String jwt(String id) =>
    'h.${base64Url.encode(utf8.encode(json.encode({'id': id})))}.firma';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  late GateStore store;
  late SecureStorageService storage;
  late Dio dio;

  /// Authorization de cada petición que llegó al servidor, en orden.
  final seen = <String?>[];
  final paths = <String>[];

  /// Tokens que el servidor considera vencidos (responde 401).
  final expired = <String>{};

  /// Lo que contesta POST /auth/refresh: token nuevo, o null = rechazado.
  String? refreshAnswer;

  final tA = jwt('usuario-a');
  final tB = jwt('usuario-b');
  final tNew = jwt('usuario-a-renovado');

  setUpAll(() async {
    HttpOverrides.global = null; // el binding de pruebas bloquea la red
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      await req.drain<void>();
      final auth = req.headers.value('authorization');
      seen.add(auth);
      paths.add(req.uri.path);
      void reply(int status, Object body) {
        req.response.statusCode = status;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode(body));
      }

      if (req.uri.path.endsWith('/auth/refresh')) {
        final answer = refreshAnswer;
        answer == null
            ? reply(401, {'message': 'refresh vencido'})
            : reply(200, {
                'success': true,
                'data': {'token': answer}
              });
      } else if (req.uri.path.endsWith('/auth/validate-password')) {
        reply(401, {'message': 'Contraseña incorrecta'});
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

  tearDownAll(() async {
    await server.close(force: true);
  });

  Future<void> start(Map<String, String> stored) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SharedPreferences.setMockInitialValues({});
    SecureStorageService.debugSimulateRestart();
    SecureStorageService.debugResetQueue();
    SessionStartupTrace.debugReset();
    SecureStorageService.debugProtector = FakeProtector();
    store = GateStore(stored);
    FlutterSecureStoragePlatform.instance = store;
    storage = SecureStorageService();
    seen.clear();
    paths.clear();
    expired.clear();
    refreshAnswer = null;
    ApiInterceptor.takeSessionExpiredFlag();
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}/api'))
      ..interceptors.add(ApiInterceptor(storage));
  }

  tearDown(() {
    store.gate?.complete();
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
    SecureStorageService.debugSimulateRestart();
    SecureStorageService.debugResetQueue();
  });

  /// Deja la fila del almacén ocupada con una escritura que no termina
  /// (hasta soltar la compuerta), como una escritura lenta de Windows.
  Future<void> holdStore() async {
    store.gate = Completer<void>();
    unawaited(storage.write('otra_clave', 'valor-${store.operations}').catchError((_) {}));
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  const quick = Duration(seconds: 2);

  test('con sesión abierta el almacén se lee una vez; con el almacén ocupado '
      'la petición sale igual, con el token, sin esperarlo', () async {
    await start({'auth_token': tA, 'refresh_token': 'r1'});
    await dio.get('/products'); // carga el token (y el id del equipo)
    expect(SecureStorageService.tokenInMemory, (known: true, token: tA));

    await holdStore();
    final before = store.operations;
    await dio.get('/products').timeout(quick);
    await dio.post('/invoices', data: {'a': 1}).timeout(quick);

    expect(seen, List.filled(3, 'Bearer $tA'));
    expect(store.operations, before, reason: 'las peticiones tocaron el almacén');
  });

  test('iniciar sesión: el token nuevo vale desde ya, aunque el almacén siga '
      'escribiéndolo; cerrar sesión: el viejo no sale más aunque no se haya '
      'terminado de borrar', () async {
    await start({});
    await dio.get('/ping'); // sin sesión: sin token
    expect(seen.single, isNull);

    await storage.saveAuthData(
        token: tA, refreshToken: 'r1', userData: {'id': 'usuario-a', 'organizationId': 'org-a'});
    await dio.get('/products');
    expect(seen.last, 'Bearer $tA');

    // Cerrar sesión con el almacén lento: no se espera a que termine.
    await holdStore();
    final closing = storage.clearAuthData().catchError((_) {});
    await Future<void>.delayed(Duration.zero);
    expect(SecureStorageService.tokenInMemory, (known: true, token: null));
    await dio.get('/products').timeout(quick);
    expect(seen.last, isNull, reason: 'salió el token de la sesión cerrada');

    store.gate!.complete();
    store.gate = null;
    await closing;
    await dio.get('/products').timeout(quick);
    expect(seen.last, isNull);

    // Entrar a otro negocio con el almacén otra vez lento: el token nuevo
    // sale en la petición siguiente sin esperar a que termine de guardarse.
    await holdStore();
    var saved = false;
    final opening = storage
        .saveAuthData(
            token: tB, refreshToken: 'r2', userData: {'id': 'usuario-b', 'organizationId': 'org-b'})
        .then((_) => saved = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await dio.get('/products').timeout(quick);
    expect(seen.last, 'Bearer $tB');
    expect(saved, isFalse, reason: 'la prueba no llegó a tener el almacén ocupado');
    store.gate!.complete();
    store.gate = null;
    await opening;
    expect(await storage.getToken(), tB, reason: 'el almacén quedó con otro token');
  });

  test('cambio de negocio: la petición siguiente lleva el token del negocio nuevo', () async {
    await start({});
    await storage.saveAuthData(
        token: tA, refreshToken: 'r1', userData: {'id': 'usuario-a', 'organizationId': 'org-a'});
    await dio.get('/products');
    await storage.saveAuthData(
        token: tB, refreshToken: 'r2', userData: {'id': 'usuario-b', 'organizationId': 'org-b'});
    await dio.get('/products');
    expect(seen, ['Bearer $tA', 'Bearer $tB']);
  });

  test('una petición pública (iniciar sesión) nunca lleva el token en memoria', () async {
    await start({'auth_token': tA});
    await dio.get('/products');
    await dio.post('/auth/login',
        data: {'email': 'a@b.co', 'password': 'x'},
        options: Options(extra: {'skip_auth_interceptor': true}));
    await dio.get('/products');
    expect(seen, ['Bearer $tA', null, 'Bearer $tA']);
  });

  test('401 con token vencido: se renueva, la petición se repite con el nuevo '
      'y las siguientes ya lo llevan', () async {
    await start({'auth_token': tA, 'refresh_token': 'r1'});
    expired.add(tA);
    refreshAnswer = tNew;

    final response = await dio.get('/products');
    expect(response.statusCode, 200);
    expect(SecureStorageService.tokenInMemory, (known: true, token: tNew));
    await dio.get('/customers');

    expect(paths, ['/api/products', '/api/auth/refresh', '/api/products', '/api/customers']);
    expect(seen, ['Bearer $tA', 'Bearer r1', 'Bearer $tNew', 'Bearer $tNew']);
    expect(await storage.getToken(), tNew);
    expect(ApiInterceptor.takeSessionExpiredFlag(), isFalse);
  });

  test('401 y el servidor rechaza la renovación: sesión cerrada, la memoria '
      'queda vacía y ninguna petición posterior lleva el token viejo', () async {
    await start({'auth_token': tA, 'refresh_token': 'r1'});
    expired.add(tA);
    refreshAnswer = null;

    await expectLater(dio.get('/products'), throwsA(isA<DioException>()));
    expect(ApiInterceptor.takeSessionExpiredFlag(), isTrue);
    expect(SecureStorageService.tokenInMemory, (known: true, token: null));

    await dio.get('/ping');
    expect(seen.last, isNull);
    expect(await storage.getToken(), isNull);
  });

  test('validar contraseña (keep_session_on_401): el 401 no renueva ni cierra '
      'la sesión; el token sigue en memoria', () async {
    await start({'auth_token': tA, 'refresh_token': 'r1'});
    await dio.get('/products');

    await expectLater(
      dio.post('/auth/validate-password',
          data: {'password': 'mala'},
          options: Options(extra: {ApiInterceptor.keepSessionOn401: true})),
      throwsA(isA<DioException>()),
    );
    expect(paths, isNot(contains('/api/auth/refresh')));
    expect(ApiInterceptor.takeSessionExpiredFlag(), isFalse);
    expect(SecureStorageService.tokenInMemory, (known: true, token: tA));
    await dio.get('/products');
    expect(seen.last, 'Bearer $tA');
  });

  test('cerrar sesión con un almacén que no deja borrar: la memoria queda '
      'vacía y una lectura posterior del almacén no revive el token', () async {
    await start({'auth_token': tA, 'refresh_token': 'r1'});
    await dio.get('/products');
    expect(seen.last, 'Bearer $tA');

    store.failDeletes = true;
    try {
      await storage.deleteToken();
    } catch (_) {}
    expect(SecureStorageService.tokenInMemory, (known: true, token: null));
    try {
      await storage.getToken(); // lo que haya quedado en el almacén
    } catch (_) {}
    expect(SecureStorageService.tokenInMemory, (known: true, token: null));
    await dio.get('/ping');
    expect(seen.last, isNull, reason: 'una petición llevó el token de la sesión cerrada');
  });

  test('una lectura que estaba en curso cuando se cerró la sesión no deja el '
      'token viejo en memoria', () async {
    await start({'auth_token': tA});
    // Lectura del token detenida en el almacén...
    store.gate = Completer<void>();
    final reading = storage.getToken().catchError((_) => null);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // ...y mientras tanto se cierra la sesión.
    final closing = storage.deleteToken().catchError((_) {});
    await Future<void>.delayed(Duration.zero);
    store.gate!.complete();
    store.gate = null;
    await reading;
    await closing;
    expect(SecureStorageService.tokenInMemory, (known: true, token: null));
    await dio.get('/ping');
    expect(seen.last, isNull);
  });

  test('guardar el token falla: la memoria vuelve a como estaba (sesión '
      'cerrada sigue cerrada)', () async {
    await start({});
    await storage.clearAuthData();
    expect(SecureStorageService.tokenInMemory, (known: true, token: null));
    await expectLater(storage.saveToken(''), throwsA(anything)); // token inválido
    expect(SecureStorageService.tokenInMemory, (known: true, token: null));
  });
}
