// Inicio de sesión REAL de la app (AuthController + caso de uso +
// repositorio + DioClient con sus interceptores + almacén de sesión como en
// Windows) contra un servidor de PRUEBAS.
//
//   BAUDEX_E2E_URL=http://127.0.0.1:3990/api \
//   BAUDEX_E2E_USERS='admin=correo|clave|Negocio;gerente=...;cajero=...;otro=...' \
//   flutter test test/e2e_local/login_app_server_e2e_test.dart
//
// Usa una base Isar temporal (nunca la del equipo) y no toca el llavero.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:baudex_desktop/app/core/diagnostics/startup_trace.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/services/permissions_service.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/session_startup_trace.dart';
import 'package:baudex_desktop/app/core/storage/value_protector.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/core/network/tenant_interceptor.dart';
import 'package:baudex_desktop/core/storage/tenant_storage.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_local_datasource_isar.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:baudex_desktop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/is_authenticated_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/login_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/logout_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/register_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/register_with_onboarding_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/resend_verification_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_isar.dart';

final _env = Platform.environment;
final _base = _env['BAUDEX_E2E_URL'];

class _Protector implements ValueProtector {
  @override
  String? protect(String plain) => 'fake:${base64Encode(utf8.encode(plain))}';
  @override
  String? unprotect(String stored) =>
      stored.startsWith('fake:') ? utf8.decode(base64Decode(stored.substring(5))) : null;
}

class _User {
  _User(this.email, this.password, this.business);
  final String email, password, business;
}

Map<String, _User> _users() {
  final out = <String, _User>{};
  for (final part in (_env['BAUDEX_E2E_USERS'] ?? '').split(';')) {
    final eq = part.indexOf('=');
    if (eq <= 0) continue;
    final f = part.substring(eq + 1).split('|');
    if (f.length == 3) out[part.substring(0, eq)] = _User(f[0], f[1], f[2]);
  }
  return out;
}

void main() {
  if (_base == null) {
    test('inicio de sesión contra el servidor (omitida: falta BAUDEX_E2E_URL)', () {},
        skip: 'Requiere el servidor de pruebas');
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  final uri = Uri.parse(_base!);
  final users = _users();
  late Isar isar;
  late Map<String, String> secureData;
  var mounted = false;

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'SERVER_IP=${uri.host}\nSERVER_PORT=${uri.port}\n'
        'APP_ENV=development\nAPI_TIMEOUT=30000\nDEBUG_MODE=false\nSHOW_LOGS=false');
    isar = await openTestIsar();
    if (_env['BAUDEX_E2E_NO_ISAR'] == '1') IsarDatabase.debugSetDatabase(null);
  });
  tearDownAll(() async {
    await closeTestIsar(isar).timeout(const Duration(seconds: 10), onTimeout: () {});
  });

  /// "Abrir la app": mismo equipo (almacén, preferencias y base se
  /// conservan), memoria nueva.
  AuthController openApp() {
    Get.delete<AuthController>(force: true);
    Get.delete<PermissionsService>(force: true);
    Get.delete<DioClient>(force: true);
    Get.delete<SecureStorageService>(force: true);
    Get.delete<IsarDatabase>(force: true);
    SecureStorageService.debugSimulateRestart();
    SessionStartupTrace.debugReset();
    TenantInterceptor.invalidateCache();
    TenantInterceptor.updateCachedSlug(null);
    final storage = SecureStorageService();
    Get.put<SecureStorageService>(storage);
    Get.put<IsarDatabase>(IsarDatabase.instance);
    final dio = Get.put<DioClient>(DioClient());
    Get.put<PermissionsService>(PermissionsService(dio));
    final repo = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(dioClient: dio),
      localDataSource: AuthLocalDataSourceIsar(storage),
      networkInfo: NetworkInfoImpl(Connectivity()),
    );
    return Get.put<AuthController>(AuthController(
      loginUseCase: LoginUseCase(repo),
      registerUseCase: RegisterUseCase(repo),
      registerWithOnboardingUseCase: RegisterWithOnboardingUseCase(repo),
      getProfileUseCase: GetProfileUseCase(repo),
      logoutUseCase: LogoutUseCase(repo),
      changePasswordUseCase: ChangePasswordUseCase(repo),
      isAuthenticatedUseCase: IsAuthenticatedUseCase(repo),
      verifyEmailUseCase: VerifyEmailUseCase(repo),
      resendVerificationUseCase: ResendVerificationUseCase(repo),
      forgotPasswordUseCase: ForgotPasswordUseCase(repo),
      resetPasswordUseCase: ResetPasswordUseCase(repo),
      tenantStorage: TenantStorageImpl(storage),
      secureStorageService: storage,
    ));
  }

  Future<void> tick(WidgetTester tester, [int ms = 50]) async {
    await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
    await tester.pump(Duration(milliseconds: ms));
  }

  /// Pulsa "Iniciar sesión" y devuelve (ms hasta que el botón deja de
  /// cargar, ms hasta entrar a la pantalla principal o null si no entró).
  Future<(int?, int?)> pressLogin(WidgetTester tester, AuthController auth, _User user,
      {int maxSeconds = 45}) async {
    if (!mounted) {
      mounted = true;
      await tester.pumpWidget(GetMaterialApp(
        initialRoute: AppRoutes.login,
        getPages: [
          GetPage(
            name: AppRoutes.login,
            page: () {
              final current = Get.find<AuthController>();
              return Scaffold(
                body: Form(
                  key: current.loginFormKey,
                  child: Obx(() => Text(current.isLoginLoading ? 'CARGANDO' : 'LISTO')),
                ),
              );
            },
          ),
          GetPage(name: AppRoutes.dashboard, page: () => const Scaffold(body: Text('PRINCIPAL'))),
        ],
      ));
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
    for (var i = 0; i < 10; i++) {
      await tick(tester);
    }
    auth.loginBusinessController.text = user.business;
    auth.loginEmailController.text = user.email;
    auth.loginPasswordController.text = user.password;
    final watch = Stopwatch()..start();
    int? stoppedMs, enteredMs;
    await tester.runAsync(() async {
      // ignore: unawaited_futures
      auth.login();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    while (watch.elapsed.inSeconds < maxSeconds) {
      await tick(tester);
      if (stoppedMs == null && !auth.isLoginLoading) stoppedMs = watch.elapsedMilliseconds;
      if (enteredMs == null && Get.currentRoute == AppRoutes.dashboard) {
        enteredMs = watch.elapsedMilliseconds;
      }
      if (stoppedMs != null && (enteredMs != null || watch.elapsedMilliseconds - stoppedMs > 6000)) break;
    }
    return (stoppedMs, enteredMs);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tick(tester, 100);
    }
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    // Relojes de diagnóstico del arranque: no deben quedar vivos en la prueba.
    SessionStartupTrace.debugReset();
    StartupTrace.instance.phases.clear();
    StartupTrace.instance.tick();
  }

  void asWindows() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SecureStorageService.debugProtector = _Protector();
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(secureData);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => ['wifi'],
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (args, events) => events.success(['wifi'])),
    );
  }

  void restore() {
    debugDefaultTargetPlatformOverride = null;
    SecureStorageService.debugProtector = null;
  }

  Future<void> emptyDevice(WidgetTester tester) async {
    secureData = {};
    mounted = false;
    SharedPreferences.setMockInitialValues({});
    if (_env['BAUDEX_E2E_NO_ISAR'] != '1') await tester.runAsync(() => isar.writeTxn(() => isar.clear()));
  }

  for (final role in ['admin', 'gerente', 'cajero']) {
    testWidgets('$role: equipo limpio → entra y el botón deja de cargar', (tester) async {
      final user = users[role];
      if (user == null) return markTestSkipped('falta $role en BAUDEX_E2E_USERS');
      await emptyDevice(tester);
      asWindows();
      try {
        final auth = openApp();
        final (stopped, entered) = await pressLogin(tester, auth, user);
        // ignore: avoid_print
        print('LOGIN $role limpio: botón libre a los $stopped ms, principal a los $entered ms');
        expect(stopped, isNotNull, reason: 'el botón se quedó cargando');
        expect(entered, isNotNull, reason: 'no entró a la pantalla principal');

        await settle(tester);
      } finally {
        restore();
      }
    });
  }

  /// Deja en el equipo la sesión abierta de OTRO negocio (token real del
  /// servidor de pruebas), como si no se hubiera cerrado sesión.
  Future<void> seedOtherBusiness(WidgetTester tester, _User other, {bool withQueue = false}) async {
    await tester.runAsync(() async {
      final raw = Dio(BaseOptions(baseUrl: _base!, headers: {'X-Device-Id': 'app-e2e-login'}));
      final res = await raw.post('/auth/login', data: {'email': other.email, 'password': other.password});
      dynamic data = res.data;
      while (data is Map && data.containsKey('data') && data.containsKey('success')) {
        data = data['data'];
      }
      final user = Map<String, dynamic>.from(data['user'] as Map);
      final storage = SecureStorageService();
      await storage.saveAuthData(
        token: data['token'] as String,
        userData: user,
        tenantSlug: user['organizationSlug'] as String,
      );
      await storage.setLastUserId(user['id'] as String);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('full_sync_business_v1', user['organizationId'] as String);
      if (withQueue) {
        await isar.writeTxn(() => isar.syncOperations.put(SyncOperation.create(
              entityType: 'InventoryMovement',
              entityId: 'mov_offline_1',
              operationType: SyncOperationType.create,
              payload: '{}',
              organizationId: user['organizationId'] as String,
            )));
      }
    });
  }

  testWidgets('sesión guardada de OTRO negocio (sin cerrar) → entra con el nuevo', (tester) async {
    final other = users['otro'], admin = users['admin'];
    if (other == null || admin == null) return markTestSkipped('faltan usuarios');
    await emptyDevice(tester);
    asWindows();
    try {
      await seedOtherBusiness(tester, other);
      final auth = openApp();
      final (stopped, entered) = await pressLogin(tester, auth, admin);
      // ignore: avoid_print
      print('LOGIN con token de otro negocio: botón libre a los $stopped ms, principal a los $entered ms');
      expect(stopped, isNotNull, reason: 'el botón se quedó cargando');
      expect(entered, isNotNull, reason: 'no entró a la pantalla principal');
      await settle(tester);
    } finally {
      restore();
    }
  });

  testWidgets('cola pendiente de OTRO negocio → avisa y el botón queda libre', (tester) async {
    final other = users['otro'], admin = users['admin'];
    if (other == null || admin == null) return markTestSkipped('faltan usuarios');
    await emptyDevice(tester);
    asWindows();
    try {
      await seedOtherBusiness(tester, other, withQueue: true);
      final auth = openApp();
      final (stopped, entered) = await pressLogin(tester, auth, admin);
      // ignore: avoid_print
      print('LOGIN con cola de otro negocio: botón libre a los $stopped ms, principal a los $entered ms, '
          'diálogo=${Get.isDialogOpen}');
      expect(stopped, isNotNull, reason: 'el botón se quedó cargando');
      expect(entered, isNull, reason: 'no debía entrar con ventas sin subir de otro negocio');
      expect(find.text('Hay ventas sin subir de otro negocio'), findsOneWidget);
      // El aviso queda a la vista (al cerrarlo la app cierra la sesión y
      // vuelve a iniciar sesión; eso ya no es de esta prueba).
      await settle(tester);
    } finally {
      restore();
    }
  });
}
