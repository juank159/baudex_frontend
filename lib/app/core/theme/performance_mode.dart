// lib/app/core/theme/performance_mode.dart
//
// Modo rendimiento. En equipos donde pintar la pantalla es lento (tarjeta
// gráfica floja o sin ella), la app pasa sola a un tema LIVIANO: mismos
// colores y tipografía, pero sin desenfoques, con sombras duras en vez de
// difusas, sin animaciones decorativas y con cambios de pantalla al
// instante. Se queda así en ese equipo y se puede cambiar a mano en
// Configuración (Automático / Liviano / Completo).
//
// El tema lo consulta en un solo sitio (`PerformanceMode.isLight`): nada de
// `if` regados por las pantallas.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lo que eligió el usuario.
enum PerformanceSetting {
  /// La app decide según cómo pinta este equipo.
  auto('auto', 'Automático'),

  /// Siempre liviano.
  light('light', 'Liviano'),

  /// Siempre con todos los efectos.
  full('full', 'Completo');

  const PerformanceSetting(this.id, this.label);
  final String id;
  final String label;

  static PerformanceSetting fromId(String? id) => PerformanceSetting.values
      .firstWhere((s) => s.id == id, orElse: () => PerformanceSetting.auto);
}

/// Regla pura: ¿este equipo pinta lento? Se le avisa de cada cuadro que la
/// tarjeta gráfica tardó en pintar más de [slowMs]; si hay [threshold] en
/// [window], sí. Un cuadro lento suelto (abrir una pantalla pesada) no
/// cuenta: tienen que repetirse.
class SlowPaintDetector {
  SlowPaintDetector({
    this.slowMs = 200,
    this.threshold = 8,
    this.window = const Duration(seconds: 30),
  });

  final double slowMs;
  final int threshold;
  final Duration window;
  final List<DateTime> _slow = [];

  /// Devuelve true cuando ya se juntaron suficientes cuadros lentos.
  bool record(double rasterMs, DateTime at) {
    if (rasterMs <= slowMs) return false;
    _slow.add(at);
    _slow.removeWhere((t) => at.difference(t) > window);
    return _slow.length >= threshold;
  }

  int get recent => _slow.length;
}

class PerformanceMode {
  PerformanceMode._();

  static const String settingKey = 'performance_setting_v1';
  static const String detectedKey = 'performance_slow_device_v1';

  static PerformanceSetting _setting = PerformanceSetting.auto;
  static bool _slowDevice = false;
  static final SlowPaintDetector _detector = SlowPaintDetector();

  /// Cambia cuando el tema pasa de completo a liviano o al revés (la app
  /// se vuelve a dibujar entera al cambiar).
  static final ValueNotifier<bool> light = ValueNotifier<bool>(false);

  /// ¿Tema liviano ahora?
  static bool get isLight => light.value;

  static PerformanceSetting get setting => _setting;

  /// En automático: ¿ya se vio que este equipo pinta lento?
  static bool get slowDeviceDetected => _slowDevice;

  static void _apply() {
    light.value = switch (_setting) {
      PerformanceSetting.light => true,
      PerformanceSetting.full => false,
      PerformanceSetting.auto => _slowDevice,
    };
  }

  /// Lee lo guardado en este equipo. Si las preferencias fallan, queda en
  /// automático.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _setting = PerformanceSetting.fromId(prefs.getString(settingKey));
      _slowDevice = prefs.getBool(detectedKey) ?? false;
    } catch (_) {}
    _apply();
  }

  /// Elección a mano desde Configuración. Volver a "Automático" olvida lo
  /// detectado: el equipo se vuelve a medir.
  static Future<void> choose(PerformanceSetting value) async {
    _setting = value;
    if (value == PerformanceSetting.auto) _slowDevice = false;
    _apply();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(settingKey, value.id);
      if (value == PerformanceSetting.auto) await prefs.setBool(detectedKey, false);
    } catch (_) {}
  }

  /// Un cuadro pintado (lo llama el medidor de cuadros). En automático, si
  /// los cuadros lentos se repiten, el equipo queda en liviano.
  static void recordRaster(double rasterMs, {DateTime? now}) {
    if (_setting != PerformanceSetting.auto || _slowDevice) return;
    if (!_detector.record(rasterMs, now ?? DateTime.now())) return;
    _slowDevice = true;
    _apply();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(detectedKey, true))
        .catchError((_) => false);
  }

  /// Texto para el reporte de Diagnóstico.
  static String describe() =>
      'Rendimiento: ${_setting.label}; tema ${isLight ? 'LIVIANO' : 'completo'}'
      '${_setting == PerformanceSetting.auto ? ' (equipo que pinta lento: ${_slowDevice ? 'sí' : 'no'}; cuadros lentos recientes: ${_detector.recent})' : ''}';

  /// Solo para pruebas.
  @visibleForTesting
  static void debugReset() {
    _setting = PerformanceSetting.auto;
    _slowDevice = false;
    _detector._slow.clear();
    light.value = false;
  }
}
