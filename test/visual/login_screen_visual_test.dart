// Pantalla de iniciar sesión (escritorio) con el negocio y el correo
// recordados. Dos cosas:
//
// 1. Siempre: al escribir la contraseña, el fondo animado NO se repinta y
//    no queda ningún desenfoque (`BackdropFilter`) en la pantalla. En
//    equipos modestos eso volvía lento el tecleo del login.
// 2. Con BAUDEX_VISUAL_OUT: guarda la imagen para revisión de diseño.
//
//   BAUDEX_VISUAL_OUT=/ruta/de/salida flutter test test/visual/login_screen_visual_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/config/constants/api_constants.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/core/storage/tenant_storage.dart';
import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:baudex_desktop/features/auth/presentation/screens/login_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _out = Platform.environment['BAUDEX_VISUAL_OUT'];
const _fonts = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

/// Caso de uso que nunca responde bien (sin servidor): basta para pintar.
class _None<T, P> implements UseCase<T, P> {
  @override
  Future<Either<Failure, T>> call(P params) async =>
      const Left(ServerFailure('sin servidor en la prueba'));
}

void main() {
  final boundaryKey = GlobalKey();

  setUpAll(() async {
    if (!Directory(_fonts).existsSync()) return;
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final file in files) {
        final bytes = File('$_fonts/$file').readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    }

    await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
    await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  Future<void> mount(WidgetTester tester, {Size size = const Size(1366, 768)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Get.reset();
    Get.testMode = true;
    SecureStorageService.debugSimulateRestart();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({
      ApiConstants.savedEmailsKey: '["caja@granada.co"]',
      ApiConstants.lastEmailKey: 'caja@granada.co',
      'last_business_name': 'Granada',
    });
    final storage = SecureStorageService();
    Get.put<AuthController>(AuthController(
      loginUseCase: _None(),
      registerUseCase: _None(),
      registerWithOnboardingUseCase: _None(),
      getProfileUseCase: _None(),
      logoutUseCase: _None(),
      changePasswordUseCase: _None(),
      isAuthenticatedUseCase: _None(),
      verifyEmailUseCase: _None(),
      resendVerificationUseCase: _None(),
      forgotPasswordUseCase: _None(),
      resetPasswordUseCase: _None(),
      tenantStorage: TenantStorageImpl(storage),
      secureStorageService: storage,
    ));
    // Sin el logo ni fuentes reales hay avisos de imagen: no son de esta prueba.
    final previous = FlutterError.onError;
    FlutterError.onError = (_) {};
    await tester.pumpWidget(RepaintBoundary(
      key: boundaryKey,
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
        home: const LoginScreen(),
      ),
    ));
    // Lo recordado se lee del almacén de sesión.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 400));
    FlutterError.onError = previous;
  }

  /// Desmonta y deja vencer los temporizadores (cursor, avisos).
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // El rastro de arranque de la sesión revisa cada 3 s durante 10 min.
    await tester.pump(const Duration(minutes: 11));
  }

  Finder passwordField() => find.byWidgetPredicate(
        (w) => w is EditableText && w.obscureText,
      );

  testWidgets('al escribir la contraseña el fondo no se repinta y no hay '
      'desenfoques', (tester) async {
    await mount(tester);
    expect(find.text('¡Bienvenido de vuelta!'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing,
        reason: 'un desenfoque bajo campos de texto se recalcula con cada tecla');

    // Sin nadie escribiendo, el fondo se mueve.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 50));
    var before = debugLoginBackgroundPaints;
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(debugLoginBackgroundPaints - before, greaterThan(0),
        reason: 'en reposo el fondo sigue animado');

    // Escribiendo la contraseña: ni un repintado del fondo.
    await tester.tap(passwordField());
    await tester.pump(const Duration(milliseconds: 50));
    before = debugLoginBackgroundPaints;
    for (final ch in 'Clave#2026'.split('')) {
      final field = tester.widget<EditableText>(passwordField());
      await tester.enterText(passwordField(), field.controller.text + ch);
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(debugLoginBackgroundPaints - before, 0,
        reason: 'repintados del fondo mientras se teclea');
    expect(tester.widget<EditableText>(passwordField()).controller.text, 'Clave#2026');
    await unmount(tester);
  });

  // El enlace del medidor va justo debajo de "Regístrate" (antes del © y la
  // versión). En una ventana baja (1280×720) el formulario entero ya pide
  // bajar: al llegar al botón de entrar, el enlace queda a la vista.
  for (final (name, size) in const [
    ('login_1280x720', Size(1280, 720)),
    ('login_celular', Size(390, 844)),
  ]) {
    testWidgets('el enlace de la prueba de velocidad va debajo de Regístrate ($name)',
        (tester) async {
      await mount(tester, size: size);
      Future<void> save(String file) async {
        if (_out == null) return;
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$_out/$file.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data!.buffer.asUint8List());
        });
      }

      await save(name);
      final link = find.text('¿La app va lenta? Probar la velocidad de este equipo');
      expect(link, findsOneWidget);
      final register = tester.getRect(find.text('Regístrate'));
      final linkRect = tester.getRect(link);
      expect(linkRect.top, greaterThan(register.top),
          reason: 'el enlace debe ir después de "Regístrate"');
      expect(linkRect.top - register.bottom, lessThan(60),
          reason: 'el enlace debe ir pegado a "Regístrate"');
      final copyright = find.textContaining('© 2026 Baudex');
      if (copyright.evaluate().isNotEmpty) {
        expect(linkRect.bottom, lessThanOrEqualTo(tester.getRect(copyright).top),
            reason: 'el enlace debe ir antes del ©');
      }
      // Bajando hasta "Regístrate", el enlace también se ve.
      await tester.ensureVisible(find.text('Regístrate'));
      await tester.pump(const Duration(milliseconds: 300));
      final after = tester.getRect(link);
      expect(after.bottom, lessThanOrEqualTo(size.height),
          reason: 'con "Regístrate" a la vista, el enlace queda bajo el borde');
      await save('${name}_abajo');
      await unmount(tester);
    });
  }

  testWidgets('imagen de la pantalla de iniciar sesión', (tester) async {
    await mount(tester);
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/login_escritorio.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
    await unmount(tester);
  }, skip: _out == null); // solo para revisión visual (BAUDEX_VISUAL_OUT)
}
