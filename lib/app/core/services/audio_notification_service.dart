// lib/app/core/services/audio_notification_service.dart
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
  bool _isEnabled = true; // Usuario puede desactivar

  // Configuración de voz
  double _speechRate = 0.5; // Velocidad más lenta para mejor comprensión
  double _volume = 0.8; // Volumen
  double _pitch = 1.0; // Tono normal

  /// Inicializar el servicio TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔊 AudioNotificationService: Inicializando TTS...');

      // Configurar idioma a español
      List<dynamic> languages = await _tts.getLanguages;
      print('🌐 Idiomas disponibles: $languages');

      // Intentar configurar español en orden de preferencia
      bool langSet = false;
      final spanishLanguages = ['es-ES', 'es-MX', 'es-US', 'es'];

      for (String lang in spanishLanguages) {
        if (languages.contains(lang)) {
          await _tts.setLanguage(lang);
          print('✅ Idioma configurado: $lang');
          langSet = true;
          break;
        }
      }

      if (!langSet) {
        print('⚠️ No se encontró español, usando idioma por defecto');
      }

      // Configurar parámetros de voz
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(_volume);
      await _tts.setPitch(_pitch);

      // Configurar callbacks
      _tts.setStartHandler(() {
        print('🔊 TTS: Iniciando reproducción');
      });

      _tts.setCompletionHandler(() {
        print('✅ TTS: Reproducción completada');
      });

      _tts.setErrorHandler((message) {
        print('❌ TTS Error: $message');
      });

      _isInitialized = true;
      print('✅ AudioNotificationService: TTS inicializado correctamente');

      // Prueba inicial silenciosa con mensaje más lento
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _speak('Bienvenido a Baúdex', priority: false);
      }
    } catch (e) {
      print('❌ AudioNotificationService: Error al inicializar TTS: $e');
      _isInitialized = false;
    }
  }

  /// Método interno para hablar
  Future<void> _speak(String text, {bool priority = true}) async {
    if (!_isEnabled || !_isInitialized || text.trim().isEmpty) {
      return;
    }

    try {
      // Si es prioritario, detener cualquier reproducción actual
      if (priority) {
        await _tts.stop();
      }

      print('🗣️ TTS: "$text"');
      await _tts.speak(text);
    } catch (e) {
      print('❌ TTS Error al hablar: $e');
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
    print(
      '🔊 AudioNotificationService: ${enabled ? 'Activado' : 'Desactivado'}',
    );
  }

  /// Verificar si está activado
  bool get isEnabled => _isEnabled;

  /// Configurar velocidad de habla (0.1 - 2.0)
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) return;

    _speechRate = rate.clamp(0.1, 2.0);
    await _tts.setSpeechRate(_speechRate);
    print('🔊 Velocidad de voz: $_speechRate');
  }

  /// Configurar volumen (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;

    _volume = volume.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
    print('🔊 Volumen: $_volume');
  }

  /// Configurar tono de voz (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) return;

    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
    print('🔊 Tono: $_pitch');
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
      print('🔊 AudioNotificationService: Recursos liberados');
    } catch (e) {
      print('⚠️ Error al liberar recursos TTS: $e');
    }
  }
}
