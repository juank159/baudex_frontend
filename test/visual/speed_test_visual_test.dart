// Imágenes de la "Prueba de velocidad de este equipo". Solo corre si se
// indica dónde guardar:
//
//   BAUDEX_VISUAL_OUT=/ruta/de/salida flutter test test/visual/speed_test_visual_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baudex_desktop/app/core/diagnostics/speed_test.dart';
import 'package:baudex_desktop/app/core/theme/elegant_light_theme.dart';
import 'package:baudex_desktop/features/diagnostics/presentation/widgets/speed_test_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _out = Platform.environment['BAUDEX_VISUAL_OUT'];
const _fonts = '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts';

const _titles = <(String, String, int, int, int)>[
  ('disk_write', 'Guardar un archivo en el disco', 40, 250, 20),
  ('disk_read', 'Leer un archivo del disco', 20, 150, 20),
  ('prefs_write', 'Guardar un ajuste de la app', 80, 500, 5),
  ('prefs_read', 'Leer un ajuste de la app', 20, 150, 5),
  ('secure_write', 'Guardar en el almacén seguro del sistema', 150, 1000, 1),
  ('secure_read', 'Leer del almacén seguro del sistema', 150, 1000, 1),
  ('isar_open', 'Abrir la base de datos local', 300, 1500, 1),
  ('isar_write', 'Guardar y leer en la base de datos local', 60, 400, 5),
  ('server', 'Respuesta del servidor', 800, 3000, 3),
];

SpeedTestRunner _runner(List<double?> ms, DeviceFacts facts, {int hangFrom = 99}) {
  var i = 0;
  return SpeedTestRunner(
    appVersion: '1.0.24 (25)',
    facts: () async => facts,
    checks: [
      for (final (id, title, fast, slow, repeat) in _titles)
        () {
          final index = i++;
          final value = ms[index];
          return SpeedCheck(
            id: id,
            title: title,
            hint: 'El disco de este equipo tarda en guardar: suele ser un disco viejo o lleno, '
                'un antivirus revisando cada archivo o una carpeta que se sincroniza con la nube.',
            fastMs: fast,
            slowMs: slow,
            repeat: repeat,
            timeout: const Duration(milliseconds: 20),
            run: () {
              if (index >= hangFrom) return Completer<double?>().future;
              if (value == null) return Completer<double?>().future;
              // Peor caso distinto del normal, como en un equipo real.
              return Future.value(value);
            },
          );
        }(),
    ],
  );
}

const _goodFacts = DeviceFacts([
  ('Sistema', 'windows "Windows 11 Pro" 10.0 (Build 22631)', false),
  ('Núcleos del procesador', '8', false),
  ('Carpeta de datos', r'C:\Users\<usuario>\AppData\Roaming\com.baudex\baudex_desktop', false),
  ('Programa', r'C:\Program Files\Baudex\baudex_desktop.exe', false),
  ('Espacio libre en el disco', '212.4 GB', false),
  ('Sesión guardada en', 'almacén seguro de Windows + copia protegida', false),
]);

const _badFacts = DeviceFacts([
  ('Sistema', 'windows "Windows 10 Home" 10.0 (Build 19045)', false),
  ('Núcleos del procesador', '2', true),
  (
    'Carpeta de datos',
    r'C:\Users\<usuario>\OneDrive\Documentos\baudex_desktop — DENTRO DE OneDrive (se sincroniza con la nube)',
    true,
  ),
  (
    'Programa',
    r'C:\Users\<usuario>\Downloads\Baudex 1.0.24\baudex_desktop.exe — se abre desde la carpeta de Descargas',
    true,
  ),
  ('Espacio libre en el disco', '3.1 GB — queda poco', true),
  (
    'Sesión guardada en',
    'preferencias del equipo (el almacén seguro de Windows no respondió a tiempo)',
    false,
  ),
]);

void main() {
  if (_out == null) {
    test('imágenes de la prueba de velocidad (omitida: falta BAUDEX_VISUAL_OUT)', () {},
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

  Future<void> shot(
    WidgetTester tester,
    String name,
    SpeedTestRunner Function() runner,
    Size size, {
    bool settle = true,
    bool tapCopy = false,
  }) async {
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
            child: SpeedTestDialog(
              buildRunner: runner,
              extraText: () => 'Tiempos reales de las acciones…',
            ),
          ),
        ),
      ),
    ));
    if (settle) {
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
    } else {
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 10));
    }
    if (tapCopy) {
      // Portapapeles simulado: en la prueba no hay sistema que lo reciba y,
      // sin esto, el aviso "Reporte copiado" no aparecía en la imagen.
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
          (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.tap(find.text('Copiar reporte'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(copied, contains('Prueba de velocidad de este equipo'));
      expect(find.textContaining('Reporte copiado'), findsOneWidget);
    }
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

  final fast = <double?>[6, 1.2, 14, 0.4, 38, 12, 120, 9, 240];
  final slow = <double?>[1850, 420, 2300, 0.6, null, null, 4100, 1300, 310];

  testWidgets('equipo rápido, escritorio', (t) async {
    await shot(t, 'velocidad_rapido_escritorio', () => _runner(fast, _goodFacts),
        const Size(1280, 900));
  });
  testWidgets('equipo muy lento, escritorio', (t) async {
    await shot(t, 'velocidad_muy_lento_escritorio', () => _runner(slow, _badFacts),
        const Size(1280, 900));
  });
  testWidgets('equipo muy lento, celular', (t) async {
    await shot(t, 'velocidad_muy_lento_celular', () => _runner(slow, _badFacts),
        const Size(390, 800));
  });
  testWidgets('midiendo', (t) async {
    await shot(
      t,
      'velocidad_midiendo',
      () => _runner(fast, _goodFacts, hangFrom: 4),
      const Size(1280, 900),
      settle: false,
    );
    // Deja terminar los topes pendientes.
    await t.pump(const Duration(seconds: 1));
  });
  testWidgets('reporte copiado', (t) async {
    await shot(t, 'velocidad_copiado', () => _runner(fast, _goodFacts), const Size(1280, 900),
        tapCopy: true);
  });
}
