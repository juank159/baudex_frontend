// lib/app/core/services/audio_notification_service.dart
import 'dart:async';

import 'package:baudex_desktop/app/core/diagnostics/startup_trace.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Servicio para notificaciones de audio usando Text-to-Speech
/// Especialmente útil para sistemas POS con escaneo de códigos de barras
class AudioNotificationService {
  static final AudioNotificationService _instance =
      AudioNotificationService._internal();
  static AudioNotificationService get instance => _instance;

  AudioNotificationService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  /// Precalentamiento en curso o hecho (ver [warmUp]).
  Future<void>? _warmUp;

  /// Para el diagnóstico: cuánto tardó el precalentamiento, la primera
  /// frase y la más lenta (ms que la app esperó al motor de voz), y
  /// cuántas pasaron de 100 ms.
  double? warmUpMs;
  double? firstPhraseMs;
  double worstPhraseMs = 0;
  int phrases = 0;
  int slowPhrases = 0;

  /// Deja el motor de voz listo ANTES de que haga falta: dice una sílaba
  /// sin volumen. En Windows la primera frase carga la voz y el
  /// reproductor, y eso puede frenar la app de medio segundo a varios
  /// segundos; antes ese costo caía en el primer Enter de "Producto sin
  /// registrar" (el diálogo del nombre tardaba en salir). Se hace una vez.
  Future<void> warmUp() =>
      _warmUp ??= StartupTrace.instance.task('voz: precalentar', _doWarmUp);

  Timer? _idleTimer;
  Duration _idleQuiet = const Duration(seconds: 3);

  /// Precalienta la voz cuando el cajero lleve [quiet] sin teclear (ver
  /// [noteActivity]). Se llama al abrir la factura; nunca antes de iniciar
  /// sesión, y solo se hace una vez por sesión de la app.
  void warmUpWhenIdle({Duration quiet = const Duration(seconds: 3)}) {
    if (_warmUp != null) return;
    _idleQuiet = quiet;
    _idleTimer?.cancel();
    _idleTimer = Timer(quiet, () {
      _idleTimer = null;
      unawaited(warmUp());
    });
  }

  /// El cajero está tecleando o leyendo códigos: el precalentamiento
  /// pendiente espera otro rato quieto. No cuesta nada si ya se hizo.
  void noteActivity() {
    if (_idleTimer == null || _warmUp != null) return;
    _idleTimer!.cancel();
    _idleTimer = Timer(_idleQuiet, () {
      _idleTimer = null;
      unawaited(warmUp());
    });
  }

  /// Se salió de la factura antes del rato libre: se deja para la próxima
  /// vez que se abra.
  void cancelWarmUpWhenIdle() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// ¿Hay un precalentamiento esperando un rato libre?
  bool get warmUpPending => _idleTimer != null;

  Future<void> _doWarmUp() async {
    await initialize();
    if (!_isInitialized || !_isEnabled) return;
    final watch = Stopwatch()..start();
    final silent = _silentSyllable();
    _muted = silent;
    await silent;
    _muted = null;
    warmUpMs = watch.elapsedMicroseconds / 1000;
  }

  /// Mientras se dice la sílaba sin volumen: las frases de verdad esperan
  /// a que termine, para no salir mudas.
  Future<void>? _muted;

  Future<void> _silentSyllable() async {
    try {
      await _tts.setVolume(0);
      await _tts.speak('a');
      await _tts.stop();
    } catch (_) {
      // Sin voz en este equipo: no pasa nada.
    } finally {
      try {
        await _tts.setVolume(_volume);
      } catch (_) {}
    }
  }

  /// Texto para el reporte de diagnóstico.
  String report() {
    String f(double? v) => v == null ? 'n/d' : '${v.toStringAsFixed(0)} ms';
    return 'Voz: precalentamiento ${f(warmUpMs)}, primera frase '
        '${f(firstPhraseMs)}, frases $phrases, de más de 100 ms: '
        '$slowPhrases, peor ${f(phrases == 0 ? null : worstPhraseMs)}';
  }
  bool _isEnabled = true; // Usuario puede desactivar

  // Configuración de voz
  double _speechRate = 0.5; // Velocidad más lenta para mejor comprensión
  double _volume = 0.8; // Volumen
  double _pitch = 1.0; // Tono normal

  /// Inicializar el servicio TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {

      // Configurar idioma a español
      final trace = StartupTrace.instance;
      List<dynamic> languages =
          await trace.task('voz: lista de voces', () async => await _tts.getLanguages as List<dynamic>);

      // Intentar configurar español en orden de preferencia
      bool langSet = false;
      final spanishLanguages = ['es-ES', 'es-MX', 'es-US', 'es'];

      for (String lang in spanishLanguages) {
        if (languages.contains(lang)) {
          await trace.task('voz: elegir idioma', () => _tts.setLanguage(lang));
          langSet = true;
          break;
        }
      }

      if (!langSet) {
      }

      // Configurar parámetros de voz
      await trace.task('voz: velocidad, volumen y tono', () async {
        await _tts.setSpeechRate(_speechRate);
        await _tts.setVolume(_volume);
        await _tts.setPitch(_pitch);
      });

      // Configurar callbacks
      _tts.setStartHandler(() {
      });

      _tts.setCompletionHandler(() {
      });

      _tts.setErrorHandler((message) {
      });

      _isInitialized = true;

      // Prueba inicial silenciosa con mensaje más lento
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _speak('Bienvenido a Baúdex', priority: false);
      }
    } catch (e) {
      _isInitialized = false;
    }
  }

  /// Método interno para hablar
  Future<void> _speak(String text, {bool priority = true}) async {
    if (!_isEnabled || text.trim().isEmpty) return;
    // La voz ya no se prepara al arrancar la app: si hace falta hablar
    // antes del precalentamiento, se prepara aquí.
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    // Si el precalentamiento va en su parte sin volumen, se espera: así
    // la frase no sale muda.
    final muted = _muted;
    if (muted != null) await muted;

    final watch = Stopwatch()..start();
    try {
      // Si es prioritario, detener cualquier reproducción actual
      // Cada frase queda en la línea de tiempo: en Windows la primera
      // carga la voz y puede trabar la ventana.
      await StartupTrace.instance.task('voz: decir una frase', () async {
        if (priority) {
          await _tts.stop();
        }
        await _tts.speak(text);
      });
    } catch (e) {
    } finally {
      final ms = watch.elapsedMicroseconds / 1000;
      phrases++;
      firstPhraseMs ??= ms;
      if (ms > worstPhraseMs) worstPhraseMs = ms;
      if (ms >= 100) slowPhrases++;
    }
  }

  // ==================== MÉTODOS PÚBLICOS ====================

  /// Anunciar que un producto no fue encontrado
  Future<void> announceProductNotFound() async {
    await _speak('Producto no encontrado');
  }

  /// Anunciar que un código de barras no está registrado
  Future<void> announceProductNotRegistered() async {
    await _speak('Producto no registrado');
  }

  /// Anunciar que un producto fue agregado exitosamente
  Future<void> announceProductAdded(String productName) async {
    // Limitar longitud del nombre para que sea más claro
    String shortName =
        productName.length > 30 ? productName.substring(0, 30) : productName;
    await _speak('Producto agregado: $shortName');
  }

  /// Anunciar error de conexión
  Future<void> announceConnectionError() async {
    await _speak('Error de conexión');
  }

  /// Anunciar producto sin stock
  Future<void> announceOutOfStock() async {
    await _speak('Producto Agotado');
  }

  /// Anunciar código de barras inválido
  Future<void> announceInvalidBarcode() async {
    await _speak('Código inválido');
  }

  /// Anunciar mensaje personalizado
  Future<void> announceCustom(String message) async {
    await _speak(message);
  }

  /// Sonido de confirmación simple
  Future<void> playSuccessSound() async {
    await _speak('Listo');
  }

  /// Sonido de error simple
  Future<void> playErrorSound() async {
    await _speak('Error');
  }

  // ==================== CONFIGURACIÓN ====================

  /// Activar/desactivar notificaciones de audio
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Verificar si está activado
  bool get isEnabled => _isEnabled;

  /// Configurar velocidad de habla (0.1 - 2.0)
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) return;

    _speechRate = rate.clamp(0.1, 2.0);
    await _tts.setSpeechRate(_speechRate);
  }

  /// Configurar volumen (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;

    _volume = volume.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
  }

  /// Configurar tono de voz (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) return;

    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
  }

  /// Obtener configuración actual
  Map<String, dynamic> getSettings() {
    return {
      'isEnabled': _isEnabled,
      'speechRate': _speechRate,
      'volume': _volume,
      'pitch': _pitch,
      'isInitialized': _isInitialized,
    };
  }

  /// Detener cualquier reproducción actual
  Future<void> stop() async {
    if (_isInitialized) {
      await _tts.stop();
    }
  }

  /// Limpiar recursos
  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (e) {
    }
  }
}
