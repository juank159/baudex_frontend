// Confirmar con contraseña (Inventario → Ajustes masivos, Configuración):
// el dueño escribía su contraseña CORRECTA y salía "Error inesperado al
// validar contraseña". La petición salía marcada como pública
// (`skip_auth_interceptor`): sin token ni negocio, y el servidor respondía
// 401 siempre (2026-11-27).
import 'dart:convert';
import 'dart:typed_data';

import 'package:baudex_desktop/app/core/network/api_interceptor.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/core/security/offline_password_hasher.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/services/password_validation_service.dart';
import 'package:baudex_desktop/core/network/tenant_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements SecureStorageService {}

/// Adaptador HTTP falso: anota cabeceras y responde lo que diga [reply].
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.reply);
  ResponseBody Function(RequestOptions o) reply;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late MockStorage storage;
  late DioClient client;
  late FakeAdapter adapter;
  late int sessionExpiredCalls;

  setUpAll(() {
    dotenv.testLoad(
        fileInput: 'SERVER_IP=servidor.prueba\nSERVER_PORT=443\nAPP_ENV=production');
  });

  setUp(() {
    Get.reset();
    storage = MockStorage();
    when(() => storage.getToken()).thenAnswer((_) async => 'token-del-dueno');
    when(() => storage.getRefreshToken())
        .thenAnswer((_) async => 'refresh-del-dueno');
    when(() => storage.getOrCreateDeviceId())
        .thenAnswer((_) async => 'device-1');
    when(() => storage.getTenantSlug()).thenAnswer((_) async => 'mi-negocio');
    when(() => storage.deleteToken()).thenAnswer((_) async {});
    when(() => storage.deleteRefreshToken()).thenAnswer((_) async {});
    when(() => storage.deleteUserData()).thenAnswer((_) async {});
    Get.put<SecureStorageService>(storage);
    TenantInterceptor.invalidateCache();
    ApiInterceptor.takeSessionExpiredFlag();

    client = DioClient();
    sessionExpiredCalls = 0;
    ApiInterceptor.setSessionExpiredCallback(() => sessionExpiredCalls++);
    adapter = FakeAdapter(
        (_) => json(200, {
              'success': true,
              'data': {'valid': true, 'message': 'Contraseña válida'}
            }));
    client.dio.httpClientAdapter = adapter;
  });

  tearDown(Get.reset);

  PasswordValidationService service() =>
      PasswordValidationService(client, storage: storage);

  test('la validación lleva el token y el negocio del usuario', () async {
    expect(await service().validatePassword('Clave Segura 1'), isTrue);
    final req = adapter.requests.single;
    expect(req.path, '/auth/validate-password');
    expect(req.headers['Authorization'], 'Bearer token-del-dueno');
    expect(req.headers['X-Tenant-Slug'], 'mi-negocio');
    // Los espacios de la contraseña se mandan tal cual.
    expect((req.data as Map)['password'], 'Clave Segura 1');
  });

  test('contraseña incorrecta (401) → false, sin refresh ni cerrar sesión',
      () async {
    adapter.reply = (_) =>
        json(401, {'statusCode': 401, 'message': 'Contraseña incorrecta'});

    expect(await service().validatePassword('mala'), isFalse);

    // Solo la petición de validación: no intentó refrescar el token.
    expect(adapter.requests.map((r) => r.path), ['/auth/validate-password']);
    verifyNever(() => storage.getRefreshToken());
    verifyNever(() => storage.deleteToken());
    verifyNever(() => storage.deleteUserData());
    expect(sessionExpiredCalls, 0);
    expect(ApiInterceptor.takeSessionExpiredFlag(), isFalse);
  });

  test('otro error del servidor → mensaje claro, sin "Exception:"', () async {
    adapter.reply =
        (_) => json(500, {'statusCode': 500, 'message': 'boom'});
    try {
      await service().validatePassword('x');
      fail('debió lanzar');
    } catch (e) {
      final msg = passwordValidationErrorMessage(e);
      expect(msg, isNot(contains('Exception')));
      expect(msg, startsWith('No se pudo validar la contraseña'));
    }
  });

  test('el inicio de sesión sigue saliendo sin token ni negocio', () async {
    await client.post('/auth/login',
        data: {'email': 'a@b.co', 'password': 'x'},
        options: Options(extra: {'skip_auth_interceptor': true}));
    final req = adapter.requests.single;
    expect(req.headers['Authorization'], isNull);
    expect(req.headers['X-Tenant-Slug'], isNull);
  });

  group('sin conexión', () {
    setUp(() {
      adapter.reply = (o) => throw DioException.connectionError(
            requestOptions: o,
            reason: 'Failed host lookup',
          );
      when(() => storage.getUserData())
          .thenAnswer((_) async => {'email': 'Dueno@Negocio.co'});
      when(() => storage.getOfflineCredentials())
          .thenAnswer((_) async => {'email': 'dueno@negocio.co'});
    });

    test('sin huella guardada → error claro de conexión', () async {
      when(() => storage.hasOfflineCredentials())
          .thenAnswer((_) async => false);
      try {
        await service().validatePassword('x');
        fail('debió lanzar');
      } catch (e) {
        expect(passwordValidationErrorMessage(e),
            'No se pudo validar la contraseña: sin conexión con el servidor');
      }
    });

    test('huella de OTRO usuario → error claro, no "incorrecta"', () async {
      when(() => storage.hasOfflineCredentials()).thenAnswer((_) async => true);
      when(() => storage.getOfflineCredentials())
          .thenAnswer((_) async => {'email': 'otro@negocio.co'});
      expect(
          () => service().validatePassword('x'),
          throwsA(isA<PasswordValidationException>().having((e) => e.message,
              'message', contains('sin conexión'))));
    });

    test('con huella guardada → compara en el equipo', () async {
      final stored =
          OfflinePasswordHasher.hashWithSalt('Clave Segura 1', [1, 2, 3, 4], 10);
      when(() => storage.hasOfflineCredentials()).thenAnswer((_) async => true);
      when(() => storage.verifyOfflineCredentials(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((inv) async {
        final pw = inv.namedArguments[#password] as String;
        return OfflinePasswordHasher.verify(
            password: pw, email: 'dueno@negocio.co', stored: stored);
      });

      expect(await service().validatePassword('Clave Segura 1'), isTrue);
      expect(await service().validatePassword('otra'), isFalse);
      verify(() => storage.verifyOfflineCredentials(
            email: 'Dueno@Negocio.co',
            password: 'Clave Segura 1',
          )).called(1);
    });
  });

  group('mensajes del diálogo', () {
    test('sin "Exception:" ni prefijo de 400', () {
      expect(
          passwordValidationErrorMessage(
              Exception('Error inesperado al validar contraseña')),
          isNot(contains('Exception')));
      expect(
          passwordValidationErrorMessage(const PasswordValidationException(
              'No se pudo validar la contraseña: sin conexión con el servidor')),
          'No se pudo validar la contraseña: sin conexión con el servidor');
    });

    test('contraseña incorrecta', () {
      expect(wrongPasswordMessage,
          'Contraseña incorrecta. Verifique e intente de nuevo.');
    });
  });
}
