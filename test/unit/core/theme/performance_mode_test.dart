import 'package:baudex_desktop/app/core/theme/elegant_light_theme.dart';
import 'package:baudex_desktop/app/core/theme/performance_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo rendimiento: cuándo la app pasa sola al tema liviano, qué se guarda
/// en el equipo y qué cambia en el tema.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t0 = DateTime(2026, 11, 26, 8);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PerformanceMode.debugReset();
  });
  tearDown(PerformanceMode.debugReset);

  group('¿este equipo pinta lento?', () {
    test('cuadros lentos repetidos: sí', () {
      final detector = SlowPaintDetector();
      var slow = false;
      for (var i = 0; i < 8; i++) {
        slow = detector.record(350, t0.add(Duration(seconds: i)));
      }
      expect(slow, isTrue);
    });

    test('un cuadro lento suelto (abrir una pantalla pesada): no', () {
      final detector = SlowPaintDetector();
      expect(detector.record(900, t0), isFalse);
      for (var i = 0; i < 200; i++) {
        expect(detector.record(12, t0.add(Duration(milliseconds: 16 * i))), isFalse);
      }
    });

    test('cuadros lentos muy espaciados (uno por minuto): no', () {
      final detector = SlowPaintDetector();
      for (var i = 0; i < 30; i++) {
        expect(detector.record(400, t0.add(Duration(minutes: i))), isFalse);
      }
    });

    test('justo en el límite de 200 ms no cuenta', () {
      final detector = SlowPaintDetector();
      for (var i = 0; i < 50; i++) {
        expect(detector.record(200, t0.add(Duration(seconds: i))), isFalse);
      }
    });
  });

  test('automático: pasa a liviano solo, lo guarda y sigue así al reabrir', () async {
    await PerformanceMode.load();
    expect(PerformanceMode.isLight, isFalse);
    var changes = 0;
    void listener() => changes++;
    PerformanceMode.light.addListener(listener);
    addTearDown(() => PerformanceMode.light.removeListener(listener));

    for (var i = 0; i < 8; i++) {
      PerformanceMode.recordRaster(420, now: t0.add(Duration(seconds: i)));
    }
    expect(PerformanceMode.isLight, isTrue);
    expect(changes, 1);
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PerformanceMode.detectedKey), isTrue);

    // Reabrir la app.
    PerformanceMode.debugReset();
    await PerformanceMode.load();
    expect(PerformanceMode.isLight, isTrue);
    expect(PerformanceMode.describe(), contains('LIVIANO'));
  });

  test('elegido a mano manda: "Completo" no cambia aunque pinte lento, '
      '"Liviano" es inmediato, y volver a "Automático" mide de nuevo', () async {
    await PerformanceMode.choose(PerformanceSetting.full);
    for (var i = 0; i < 20; i++) {
      PerformanceMode.recordRaster(500, now: t0.add(Duration(seconds: i)));
    }
    expect(PerformanceMode.isLight, isFalse);

    await PerformanceMode.choose(PerformanceSetting.light);
    expect(PerformanceMode.isLight, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PerformanceMode.settingKey), 'light');

    await PerformanceMode.choose(PerformanceSetting.auto);
    expect(PerformanceMode.isLight, isFalse);
    expect(PerformanceMode.slowDeviceDetected, isFalse);
  });

  test('tema liviano: sombras duras (sin difuminado) y sin resplandor', () async {
    expect(ElegantLightTheme.elevatedShadow.any((s) => s.blurRadius > 0), isTrue);
    expect(ElegantLightTheme.glowShadow, isNotEmpty);

    await PerformanceMode.choose(PerformanceSetting.light);
    for (final shadows in [
      ElegantLightTheme.elevatedShadow,
      ElegantLightTheme.neuomorphicShadow,
      ElegantLightTheme.glassShadow,
    ]) {
      expect(shadows, isNotEmpty, reason: 'el relieve se conserva');
      expect(shadows.every((s) => s.blurRadius == 0), isTrue);
    }
    expect(ElegantLightTheme.glowShadow, isEmpty);
  });

  test('si las preferencias fallan, queda en automático y no lanza', () async {
    await PerformanceMode.load();
    expect(PerformanceMode.setting, PerformanceSetting.auto);
    expect(PerformanceSetting.fromId('basura'), PerformanceSetting.auto);
    expect(PerformanceSetting.fromId(null), PerformanceSetting.auto);
  });
}
