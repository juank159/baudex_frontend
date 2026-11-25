import 'dart:convert';
import 'dart:typed_data';

import 'package:baudex_desktop/app/core/network/api_interceptor.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/core/network/tenant_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorage extends Mock implements SecureStorageService {}

/// Adaptador HTTP falso: registra la cabecera Authorization de cada petición.
class AuthRecordingAdapter implements HttpClientAdapter {
  final List<Object?> auth = [];
  final List<Object?> slug = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    auth.add(options.headers['Authorization']);
    slug.add(options.headers['X-Tenant-Slug']);
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

/// En un equipo donde quedó guardado el token de OTRO negocio, el inicio de
/// sesión lo mandaba y el servidor buscaba el correo solo en ese negocio:
/// "credenciales inválidas" con cualquier usuario (Windows del CEO, 2026-11-25).
void main() {
  late Dio dio;
  late AuthRecordingAdapter adapter;

  setUp(() {
    final storage = MockStorage();
    when(() => storage.getToken())
        .thenAnswer((_) async => 'token-viejo-de-otro-negocio');
    when(() => storage.getOrCreateDeviceId())
        .thenAnswer((_) async => 'device-1');
    when(() => storage.getTenantSlug())
        .thenAnswer((_) async => 'otro-negocio');
    TenantInterceptor.invalidateCache();
    adapter = AuthRecordingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(ApiInterceptor(storage))
      ..interceptors.add(TenantInterceptor(storage));
  });

  final public = Options(extra: {'skip_auth_interceptor': true});

  test('iniciar sesión NO manda el token guardado', () async {
    await dio.post('/auth/login',
        data: {'email': 'a@b.co', 'password': 'x'}, options: public);
    // Segunda vez: ya con la caché del interceptor inicializada.
    await dio.post('/auth/login',
        data: {'email': 'a@b.co', 'password': 'x'}, options: public);
    expect(adapter.auth, [null, null]);
    expect(adapter.slug, [null, null]);
  });

  test('una petición normal sí lleva el token', () async {
    await dio.get('/products');
    expect(adapter.auth.single, 'Bearer token-viejo-de-otro-negocio');
    expect(adapter.slug.single, 'otro-negocio');
  });
}
