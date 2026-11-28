// QA 1.0.25 — Sesión en equipo con almacén lento (b0c2f7c).
//
// Caso: equipo SANO con la sesión del negocio A en el almacén seguro. UN
// arranque lento aislado lo marca; mientras está marcado se entra con el
// negocio B (sin refresh token ni organización en la respuesta). Luego el
// almacén vuelve a responder, pasan 3 arranques sanos y el equipo vuelve al
// almacén. La sesión que queda debe ser SOLO la de B: nada de A (refresh
// token, negocio, organización) puede revivir al volver.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';

import 'package:baudex_desktop/app/config/constants/api_constants.dart';
import 'package:baudex_desktop/app/core/storage/local_cache_store.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_lost_key_test.dart' show FakeProtector;
import 'secure_storage_slow_device_test.dart' show SlowStore;

void _restart() {
  SecureStorageService.debugSimulateRestart();
  SessionStartupTrace.debugReset();
  SecureStorageService.debugResetQueue();
}

void _run(FakeAsync async, Future<void> f) {
  var done = false;
  Object? error;
  f.then((_) => done = true, onError: (Object e) {
    error = e;
    done = true;
  });
  var waited = Duration.zero;
  while (!done && waited < const Duration(minutes: 2)) {
    async.elapse(const Duration(milliseconds: 100));
    waited += const Duration(milliseconds: 100);
  }
  if (error != null) throw error!;
  expect(done, isTrue, reason: 'no terminó');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SlowStore store;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SecureStorageService.debugSimulateRestart();
    SessionStartupTrace.debugReset();
    SecureStorageService.debugProtector = FakeProtector();
    LocalCacheStore.debugForgetLegacyChecks();
    store = SlowStore({
      ApiConstants.tokenKey: 'jwt.A',
      ApiConstants.refreshTokenKey: 'refresh.A',
      ApiConstants.userKey: jsonEncode({'id': 'uA', 'organizationId': 'oA'}),
      'tenant_slug': 'negocio-a',
      'current_organization': jsonEncode({'id': 'oA', 'slug': 'negocio-a'}),
    });
    FlutterSecureStoragePlatform.instance = store;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
    SecureStorageService.debugSimulateRestart();
  });

  test('arranque lento aislado + cambio a negocio B: al volver al almacén no revive nada de A', () {
    fakeAsync((async) {
      SecureStorageService.debugResetQueue();
      // Arranque 1: el almacén tarda 15 s (un solo arranque malo).
      _run(async, () async {
        final s = SecureStorageService();
        await s.getToken();
        await s.clearAuthData(); // cerrar sesión de A
        await s.saveAuthData(
          token: 'jwt.B',
          userData: {'id': 'uB', 'organizationId': 'oB'},
          tenantSlug: 'negocio-b',
        );
      }());
      async.elapse(const Duration(minutes: 3));
      late SharedPreferences prefs;
      SharedPreferences.getInstance().then((p) => prefs = p);
      async.flushMicrotasks();
      expect(prefs.getBool(SecureStorageService.storeSlowKey), isTrue);

      // El almacén vuelve a ser rápido: 3 arranques sanos con la app abierta.
      store.delay = const Duration(milliseconds: 5);
      for (var i = 0; i < SecureStorageService.slowStoreHealthyBoots; i++) {
        _restart();
        _run(async, SecureStorageService().getToken().then((_) {}));
        async.elapse(const Duration(minutes: 3));
      }
      expect(prefs.getBool(SecureStorageService.storeSlowKey), isNull);

      // Arranque que vuelve al almacén.
      _restart();
      String? token, refresh, slug;
      Map<String, dynamic>? user, org;
      _run(async, () async {
        final s = SecureStorageService();
        token = await s.getToken();
        refresh = await s.getRefreshToken();
        slug = await s.getTenantSlug();
        user = await s.getUserData();
        org = await s.getCurrentOrganization();
      }());
      expect(token, 'jwt.B');
      expect(user?['id'], 'uB');
      expect(slug, 'negocio-b');
      expect(refresh, isNull, reason: 'revivió el refresh token del negocio A');
      expect(org?['id'], isNot('oA'), reason: 'revivió la organización del negocio A');
    });
  });

  test('arranque lento aislado SIN cerrar sesión: entra B encima de A y al volver no queda refresh de A', () {
    fakeAsync((async) {
      SecureStorageService.debugResetQueue();
      _run(async, () async {
        final s = SecureStorageService();
        await s.getToken();
        await s.saveAuthData(
          token: 'jwt.B',
          userData: {'id': 'uB', 'organizationId': 'oB'},
          tenantSlug: 'negocio-b',
        );
      }());
      async.elapse(const Duration(minutes: 3));
      store.delay = const Duration(milliseconds: 5);
      for (var i = 0; i < SecureStorageService.slowStoreHealthyBoots; i++) {
        _restart();
        _run(async, SecureStorageService().getToken().then((_) {}));
        async.elapse(const Duration(minutes: 3));
      }
      _restart();
      String? token, refresh;
      _run(async, () async {
        final s = SecureStorageService();
        token = await s.getToken();
        refresh = await s.getRefreshToken();
      }());
      expect(token, 'jwt.B');
      expect(refresh, isNot('refresh.A'), reason: 'el refresh token de A quedó junto al token de B');
    });
  });
}
