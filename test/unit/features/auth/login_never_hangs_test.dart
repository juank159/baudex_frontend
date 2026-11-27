// El botón "Iniciar sesión" nunca se queda cargando para siempre.
//
// Reporte (2026-11-27, Windows de un cliente, 1.0.20): negocio + correo +
// contraseña, Iniciar sesión, y el botón queda cargando sin fin y sin
// mensaje. Toda espera del inicio de sesión tiene ahora un tope y un mensaje.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:baudex_desktop/app/core/diagnostics/startup_trace.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/network/api_interceptor.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/core/network/tenant_interceptor.dart';
import 'package:baudex_desktop/core/storage/tenant_storage.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:baudex_desktop/features/auth/data/models/auth_response_model.dart';
import 'package:baudex_desktop/features/auth/data/models/login_request_model.dart';
import 'package:baudex_desktop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:baudex_desktop/features/auth/domain/entities/auth_result.dart';
import 'package:baudex_desktop/features/auth/domain/rules/login_failure_rules.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/login_usecase.dart';
import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:baudex_desktop/features/auth/presentation/widgets/login_problem_dialog.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/auth_fixtures.dart';

class _Storage extends Mock implements SecureStorageService {}

class _Tenant extends Mock implements TenantStorage {}

class _Remote extends Mock implements AuthRemoteDataSource {}

class _Local extends Mock implements AuthLocalDataSource {}

class _Network extends Mock implements NetworkInfo {}

class _FakeLoginRequest extends Fake implements LoginRequestModel {}

class _FakeAuthResponse extends Fake implements AuthResponseModel {}

/// Una espera que nunca termina (almacén del equipo o red colgados).
Future<T> _never<T>() => Completer<T>().future;

class _UseCase<T, P> implements UseCase<T, P> {
  _UseCase(this.answer);
  final Future<Either<Failure, T>> Function() answer;
  int calls = 0;
  @override
  Future<Either<Failure, T>> call(P params) {
    calls++;
    return answer();
  }
}

class _OkAdapter implements HttpClientAdapter {
  final List<RequestOptions> sent = [];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    sent.add(options);
    return ResponseBody.fromString(jsonEncode({'ok': true}), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeLoginRequest());
    registerFallbackValue(_FakeAuthResponse());
  });

  group('mensajes', () {
    test('cada espera cortada dice qué pasó, en español y sin tecnicismos', () {
      final general = describeLoginFailure(
          const LoginTimeoutFailure(LoginWaitStage.unknown, detail: 'Sin respuesta en 90 s.'));
      expect(general.kind, LoginFailureKind.tookTooLong);
      expect(general.title, 'El inicio de sesión tardó demasiado');
      expect(general.message, contains('antivirus o cortafuegos'));
      expect(general.detail, 'Sin respuesta en 90 s.');

      final save = describeLoginFailure(const LoginTimeoutFailure(LoginWaitStage.saveSession));
      expect(save.message, contains('correo y contraseña son correctos'));
      expect(save.message, contains('guardar la sesión'));

      final offline = describeLoginFailure(const LoginTimeoutFailure(LoginWaitStage.offlineSession));
      expect(offline.message, contains('no logró conectarse con Baudex'));
    });

    test('los topes de red del inicio de sesión son más cortos que los generales (30 s)', () {
      final options = AuthRemoteDataSourceImpl.loginOptions;
      expect(options.extra![ApiInterceptor.connectTimeoutExtra], LoginDeadlines.connect);
      expect(options.extra!['skip_auth_interceptor'], true);
      expect(options.sendTimeout, LoginDeadlines.send);
      expect(options.receiveTimeout, LoginDeadlines.response);
      expect(LoginDeadlines.connect.inSeconds, lessThanOrEqualTo(15));
      expect(
        LoginDeadlines.overall,
        greaterThan(LoginDeadlines.connect +
            LoginDeadlines.send +
            LoginDeadlines.response +
            LoginDeadlines.saveSession +
            LoginDeadlines.saveOfflineAccess),
        reason: 'el tope general solo actúa si falla un tope particular',
      );
    });
  });

  group('petición de iniciar sesión', () {
    test('si el almacén de sesión del equipo no responde, la petición sale igual', () {
      fakeAsync((async) {
        final storage = _Storage();
        when(() => storage.getToken()).thenAnswer((_) => _never());
        when(() => storage.getOrCreateDeviceId()).thenAnswer((_) => _never());
        when(() => storage.getTenantSlug()).thenAnswer((_) => _never());
        TenantInterceptor.invalidateCache();
        final adapter = _OkAdapter();
        final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..httpClientAdapter = adapter
          ..interceptors.add(ApiInterceptor(storage))
          ..interceptors.add(TenantInterceptor(storage));

        Response<dynamic>? response;
        dio
            .post('/auth/login',
                data: {'email': 'a@b.co', 'password': 'x'},
                options: AuthRemoteDataSourceImpl.loginOptions)
            .then((r) => response = r);
        async.elapse(ApiInterceptor.publicStorageWait + const Duration(seconds: 1));

        expect(response, isNotNull, reason: 'la petición se quedó esperando al almacén');
        expect(adapter.sent.single.headers['Authorization'], isNull);
        expect(adapter.sent.single.connectTimeout, LoginDeadlines.connect);
      });
    });
  });

  group('repositorio', () {
    late _Remote remote;
    late _Local local;
    late AuthRepositoryImpl repository;

    setUp(() {
      remote = _Remote();
      local = _Local();
      final network = _Network();
      when(() => network.resetServerReachability()).thenReturn(null);
      repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        networkInfo: network,
      );
    });

    test('el servidor acepta y el equipo no termina de guardar la sesión: se corta y se dice', () {
      fakeAsync((async) {
        when(() => remote.login(any())).thenAnswer((_) async => AuthFixtures.createAuthResponseModel());
        when(() => local.saveAuthData(any())).thenAnswer((_) => _never());

        Either<Failure, AuthResult>? result;
        repository.login(email: 'a@b.co', password: 'secreta1').then((r) => result = r);
        async.elapse(LoginDeadlines.saveSession - const Duration(seconds: 1));
        expect(result, isNull);
        async.elapse(const Duration(seconds: 2));

        expect(result, isNotNull, reason: 'el inicio de sesión se quedó esperando al almacén');
        final failure = result!.fold((f) => f, (_) => null);
        expect(failure, isA<LoginTimeoutFailure>());
        expect((failure as LoginTimeoutFailure).stage, LoginWaitStage.saveSession);
      });
    });

    test('sin conexión y el equipo no termina de leer la sesión guardada: se corta y se dice', () {
      fakeAsync((async) {
        when(() => remote.login(any())).thenThrow(const ConnectionFailureTrigger());
        when(() => local.hasOfflineCredentials()).thenAnswer((_) => _never());

        Either<Failure, AuthResult>? result;
        repository.login(email: 'a@b.co', password: 'secreta1').then((r) => result = r);
        async.elapse(LoginDeadlines.offlineSession + const Duration(seconds: 1));

        expect(result, isNotNull);
        final failure = result!.fold((f) => f, (_) => null);
        expect(failure, isA<LoginTimeoutFailure>());
        expect((failure as LoginTimeoutFailure).stage, LoginWaitStage.offlineSession);
        expect(failure.detail, contains('SocketException'));
      });
    });
  });

  group('botón', () {
    late _Storage storage;

    AuthController controller(_UseCase<AuthResult, LoginParams> login) {
      storage = _Storage();
      when(() => storage.getSavedEmails()).thenAnswer((_) async => <String>[]);
      when(() => storage.getLastEmail()).thenAnswer((_) async => null);
      when(() => storage.getLastBusiness()).thenAnswer((_) async => null);
      when(() => storage.getLastUserId()).thenAnswer((_) => _never());
      when(() => storage.setLastUserId(any())).thenAnswer((_) => _never());
      when(() => storage.saveLastBusiness(any())).thenAnswer((_) => _never());
      when(() => storage.addSavedEmail(any())).thenAnswer((_) => _never());
      when(() => storage.saveLastEmail(any())).thenAnswer((_) => _never());
      when(() => storage.clearTenantBusinessCaches()).thenAnswer((_) => _never());
      final tenant = _Tenant();
      when(() => tenant.getTenantSlug()).thenAnswer((_) async => null);
      when(() => tenant.setTenantSlug(any())).thenAnswer((_) => _never());
      Get.put<SecureStorageService>(storage);
      _UseCase<T, P> unused<T, P>() => _UseCase<T, P>(() => _never());
      return Get.put(
        AuthController(
          loginUseCase: login,
          registerUseCase: unused(),
          registerWithOnboardingUseCase: unused(),
          getProfileUseCase: unused(),
          logoutUseCase: unused(),
          changePasswordUseCase: unused(),
          isAuthenticatedUseCase: _UseCase<bool, NoParams>(() async => const Right(false)),
          verifyEmailUseCase: unused(),
          resendVerificationUseCase: unused(),
          forgotPasswordUseCase: unused(),
          resetPasswordUseCase: unused(),
          tenantStorage: tenant,
          secureStorageService: storage,
        ),
        permanent: true,
      );
    }

    Future<void> screen(WidgetTester tester, AuthController auth) async {
      await tester.pumpWidget(GetMaterialApp(
        initialRoute: AppRoutes.login,
        getPages: [
          GetPage(
            name: AppRoutes.login,
            page: () => Scaffold(
              body: Form(
                key: auth.loginFormKey,
                child: Obx(() => Text(auth.isLoginLoading ? 'CARGANDO' : 'LISTO')),
              ),
            ),
          ),
          GetPage(name: AppRoutes.dashboard, page: () => const Scaffold(body: Text('PRINCIPAL'))),
        ],
      ));
      await tester.pump();
      auth.loginBusinessController.text = 'Tienda Uno';
      auth.loginEmailController.text = 'a@b.co';
      auth.loginPasswordController.text = 'secreta1';
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TenantInterceptor.updateCachedSlug(null);
    });
    tearDown(() {
      SessionStartupTrace.debugReset();
      Get.reset();
    });

    testWidgets('si el inicio de sesión nunca responde, el botón deja de cargar y sale el aviso',
        (tester) async {
      final login = _UseCase<AuthResult, LoginParams>(() => _never());
      final auth = controller(login);
      await screen(tester, auth);

      unawaited(auth.login());
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('CARGANDO'), findsOneWidget);

      await tester.pump(LoginDeadlines.overall);
      await tester.pump(const Duration(seconds: 1));
      expect(auth.isLoginLoading, isFalse, reason: 'el botón se quedó cargando');
      expect(find.byType(LoginProblemDialog), findsOneWidget);
      expect(find.text('El inicio de sesión tardó demasiado'), findsOneWidget);
      expect(login.calls, 1);
      Get.back();
      await tester.pump(const Duration(seconds: 1));
      SessionStartupTrace.debugReset();
    });

    testWidgets('el servidor acepta y el almacén del equipo no responde en ningún paso: '
        'igual entra a la pantalla principal y el botón queda libre', (tester) async {
      final accepted = AuthFixtures.createAuthResponseModel().toAuthResult();
      final login = _UseCase<AuthResult, LoginParams>(() async => Right(accepted));
      final auth = controller(login);
      await screen(tester, auth);
      auth.loginBusinessController.text = accepted.user.organizationName ?? '';

      unawaited(auth.login());
      await tester.pump(const Duration(seconds: 1));
      // Mientras prepara la sesión el botón sigue cargando (no queda quieto).
      expect(find.text('CARGANDO'), findsOneWidget);

      for (var i = 0; i < 90 && Get.currentRoute != AppRoutes.dashboard; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump(const Duration(seconds: 1));
      expect(Get.currentRoute, AppRoutes.dashboard, reason: 'no entró a la pantalla principal');
      expect(auth.isLoginLoading, isFalse);
      expect(TenantInterceptor.cachedSlug, accepted.user.organizationSlug);
      // Deja cerrar el aviso de bienvenida.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 2));
      SessionStartupTrace.debugReset();
      // Apaga el reloj de trabas de la fase "tras iniciar sesión".
      StartupTrace.instance.phases.clear();
      StartupTrace.instance.tick();
    });
  });
}

/// Lo que lanza el cliente HTTP cuando no hay conexión (sin tipo propio).
class ConnectionFailureTrigger implements Exception {
  const ConnectionFailureTrigger();
  @override
  String toString() => 'SocketException: Connection refused';
}
