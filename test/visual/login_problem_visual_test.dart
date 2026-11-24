// Imágenes del diálogo de problemas de inicio de sesión. Solo corre si se
// indica dónde guardar:
//
//   BAUDEX_VISUAL_OUT=/ruta/de/salida flutter test test/visual/login_problem_visual_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/theme/elegant_light_theme.dart';
import 'package:baudex_desktop/features/auth/domain/rules/login_failure_rules.dart';
import 'package:baudex_desktop/features/auth/presentation/widgets/login_problem_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _out = Platform.environment['BAUDEX_VISUAL_OUT'];
const _fonts = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

void main() {
  if (_out == null) {
    test('imágenes del diálogo de login (omitida: falta BAUDEX_VISUAL_OUT)', () {},
        skip: 'Solo para revisión visual');
    return;
  }

  final boundaryKey = GlobalKey();

  setUpAll(() async {
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

  Future<void> shot(WidgetTester tester, String name, Failure failure, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RepaintBoundary(
      key: boundaryKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
        home: Scaffold(
          backgroundColor: ElegantLightTheme.backgroundColor,
          body: Container(
            color: Colors.black38,
            child: LoginProblemDialog(
              view: describeLoginFailure(failure),
              onClose: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  const tls = AuthFailure(
    message: 'x',
    errorCode: 'NO_OFFLINE_CREDENTIALS',
    detail: 'No se pudo establecer una conexión segura con el servidor (certificado). '
        'Revisa la fecha y la hora del equipo, las actualizaciones de Windows y el antivirus. '
        'Detalle: HandshakeException: Handshake error in client (OS Error: '
        'CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate(handshake.cc:393))',
  );
  const mismatch = AuthFailure(
    message: 'x',
    errorCode: 'OFFLINE_PASSWORD_MISMATCH',
    detail: "Sin conexión con el servidor (https://servidor/api). Detalle: SocketException: Failed host lookup: 'servidor'",
  );
  const local = LocalSessionSaveFailure(
      'CacheException: Error al guardar datos de autenticación: PlatformException(Exception occurred, write, null, null)');

  testWidgets('sin conexión (certificado), escritorio', (t) async {
    await shot(t, 'login_sin_conexion_escritorio', tls, const Size(1280, 800));
  });
  testWidgets('sin conexión (certificado), celular', (t) async {
    await shot(t, 'login_sin_conexion_celular', tls, const Size(390, 780));
  });
  testWidgets('sin conexión y clave distinta a la guardada', (t) async {
    await shot(t, 'login_sin_conexion_clave_guardada', mismatch, const Size(1280, 800));
  });
  testWidgets('no se pudo guardar la sesión', (t) async {
    await shot(t, 'login_no_guardo_sesion', local, const Size(1280, 800));
  });
  testWidgets('no se pudo guardar la sesión, celular', (t) async {
    await shot(t, 'login_no_guardo_sesion_celular', local, const Size(390, 780));
  });
}
