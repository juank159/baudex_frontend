// lib/app/config/env_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

/// Clase para manejar toda la configuración de la aplicación
/// basada en variables de entorno
class EnvConfig {
  static bool _isInitialized = false;

  /// Inicializar la configuración de entorno
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Determinar qué archivo .env cargar
      String envFile = _getEnvFileName();

      print('🔧 Cargando configuración desde: $envFile');

      // Cargar el archivo de entorno
      await dotenv.load(fileName: envFile);

      _isInitialized = true;

      // Mostrar configuración cargada
      printCurrentConfig();
    } catch (e) {
      print('❌ Error cargando configuración: $e');
      print('📋 Usando configuración por defecto');
      _setDefaultValues();
      _isInitialized = true;
    }
  }

  /// Determinar qué archivo .env usar según el entorno
  static String _getEnvFileName() {
    if (kDebugMode) {
      return '.env.development';
    } else {
      return '.env.production';
    }
  }

  /// Establecer valores por defecto si no se puede cargar .env
  static void _setDefaultValues() {
    // Solo para casos de emergencia
    print('⚠️ Usando valores por defecto');
  }

  // ===========================================
  // GETTERS PARA CONFIGURACIÓN DE SERVIDOR
  // ===========================================

  /// IP del servidor
  static String get serverIP {
    final ip = dotenv.env['SERVER_IP'] ?? _getDefaultServerIP();
    print('🌐 Usando Server IP: $ip');
    return ip;
  }

  /// Puerto del servidor
  static int get serverPort {
    final portStr = dotenv.env['SERVER_PORT'] ?? '3000';
    return int.tryParse(portStr) ?? 3000;
  }

  /// URL base completa del API
  static String get baseUrl {
    final protocol = isProduction ? 'https' : 'http';
    return '$protocol://$serverIP:$serverPort/api';
  }

  /// URL base sin /api (para WebSocket, etc.)
  static String get serverUrl {
    final protocol = isProduction ? 'https' : 'http';
    return '$protocol://$serverIP:$serverPort';
  }

  // ===========================================
  // GETTERS PARA CONFIGURACIÓN DE APLICACIÓN
  // ===========================================

  /// Entorno actual
  static String get environment {
    return dotenv.env['APP_ENV'] ?? 'development';
  }

  /// Es entorno de producción
  static bool get isProduction {
    return environment == 'production';
  }

  /// Es entorno de desarrollo
  static bool get isDevelopment {
    return environment == 'development';
  }

  /// Timeout para APIs
  static int get apiTimeout {
    final timeoutStr = dotenv.env['API_TIMEOUT'] ?? '30000';
    return int.tryParse(timeoutStr) ?? 30000;
  }

  /// Nombre de la aplicación
  static String get appName {
    return dotenv.env['APP_NAME'] ?? 'Baudex Desktop';
  }

  /// Versión de la aplicación
  static String get appVersion {
    return dotenv.env['APP_VERSION'] ?? '1.0.0';
  }

  // ===========================================
  // GETTERS PARA DEBUG Y LOGS
  // ===========================================

  /// Modo debug habilitado
  static bool get debugMode {
    final debugStr = dotenv.env['DEBUG_MODE'] ?? 'true';
    return debugStr.toLowerCase() == 'true';
  }

  /// Mostrar logs detallados
  static bool get showLogs {
    final logsStr = dotenv.env['SHOW_LOGS'] ?? 'true';
    return logsStr.toLowerCase() == 'true' && kDebugMode;
  }

  // ===========================================
  // MÉTODOS DE UTILIDAD
  // ===========================================

  /// Obtener IP por defecto según la plataforma
  static String _getDefaultServerIP() {
    if (kIsWeb) {
      return 'localhost';
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'localhost';
    } else if (Platform.isAndroid) {
      // Detectar si es emulador
      return _isAndroidEmulator() ? '10.0.2.2' : '192.168.1.100';
    } else if (Platform.isIOS) {
      return '192.168.1.100';
    }
    return 'localhost';
  }

  /// Detectar si es emulador Android
  static bool _isAndroidEmulator() {
    try {
      return Platform.environment.containsKey('ANDROID_EMULATOR') ||
          Platform.environment['ANDROID_DEVICE']?.contains('emulator') == true;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar IP del servidor en tiempo de ejecución
  static void updateServerIP(String newIP) {
    dotenv.env['SERVER_IP'] = newIP;
    print('🔄 IP del servidor actualizada a: $newIP');
    print('🌐 Nueva URL base: $baseUrl');
  }

  /// Verificar si la configuración está inicializada
  static bool get isInitialized => _isInitialized;

  /// Imprimir configuración actual
  static void printCurrentConfig() {
    if (!showLogs) return;

    print('');
    print('🚀 ============================================');
    print('📱 CONFIGURACIÓN BAUDEX DESKTOP');
    print('🚀 ============================================');
    print('🌐 Servidor:');
    print('   • IP: $serverIP');
    print('   • Puerto: $serverPort');
    print('   • URL Base: $baseUrl');
    print('   • URL Servidor: $serverUrl');
    print('');
    print('⚙️  Aplicación:');
    print('   • Nombre: $appName');
    print('   • Versión: $appVersion');
    print('   • Entorno: $environment');
    print('   • Plataforma: ${Platform.operatingSystem}');
    print('');
    print('🔧 Configuración:');
    print('   • Debug Mode: $debugMode');
    print('   • Show Logs: $showLogs');
    print('   • API Timeout: ${apiTimeout}ms');
    print('   • Es Producción: $isProduction');
    print('🚀 ============================================');
    print('');
  }

  /// Validar que la configuración sea correcta
  static bool validateConfig() {
    try {
      // Verificar que los valores esenciales estén presentes
      if (serverIP.isEmpty) {
        print('❌ Error: SERVER_IP no está configurado');
        return false;
      }

      if (serverPort <= 0 || serverPort > 65535) {
        print('❌ Error: SERVER_PORT inválido ($serverPort)');
        return false;
      }

      print('✅ Configuración válida');
      return true;
    } catch (e) {
      print('❌ Error validando configuración: $e');
      return false;
    }
  }

  /// Obtener toda la configuración como Map (para debug)
  static Map<String, dynamic> getAllConfig() {
    return {
      'serverIP': serverIP,
      'serverPort': serverPort,
      'baseUrl': baseUrl,
      'serverUrl': serverUrl,
      'environment': environment,
      'isProduction': isProduction,
      'isDevelopment': isDevelopment,
      'apiTimeout': apiTimeout,
      'appName': appName,
      'appVersion': appVersion,
      'debugMode': debugMode,
      'showLogs': showLogs,
      'platform': Platform.operatingSystem,
      'isInitialized': isInitialized,
    };
  }
}
