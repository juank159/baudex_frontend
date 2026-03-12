import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../config/env/env_config.dart';

/// Contrato para verificar conexión a internet
abstract class NetworkInfo {
  Future<bool> get isConnected;

  /// Verificar si el servidor está realmente accesible (con timeout rápido)
  Future<bool> canReachServer({Duration timeout});

  /// Solo verificar conectividad física (WiFi/móvil)
  Future<bool> get hasPhysicalConnection;

  /// ✅ NUEVO: Obtener estado cacheado de alcanzabilidad (sync, para validaciones rápidas)
  bool get isServerReachable;

  /// Marcar servidor como no alcanzable temporalmente (para fallback rápido)
  void markServerUnreachable();

  /// Resetear estado de alcanzabilidad del servidor
  void resetServerReachability();

  /// Iniciar monitoreo activo de conectividad
  void startMonitoring();

  /// Detener monitoreo
  void dispose();
}

/// Implementación de NetworkInfo usando connectivity_plus con verificación real de servidor
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  // Cache de alcanzabilidad del servidor
  bool _serverReachable = true;
  DateTime? _lastServerCheck;
  static const Duration _serverCheckCooldown = Duration(seconds: 10);
  static const Duration _defaultTimeout = Duration(milliseconds: 1500);

  // ✅ Control para verificación inicial rápida
  bool _initialReachabilityChecked = false;
  // ✅ Mutex para evitar múltiples pings concurrentes
  Future<bool>? _pendingReachabilityCheck;

  // ✅ Monitoreo activo de conectividad
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _recoveryTimer;

  NetworkInfoImpl(this._connectivity) {
    startMonitoring();
  }

  /// ✅ NUEVO: Getter sync para obtener estado cacheado de alcanzabilidad
  @override
  bool get isServerReachable => _serverReachable;

  @override
  Future<bool> get hasPhysicalConnection async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isWifi = connectivityResult.contains(ConnectivityResult.wifi);
      final isMobile = connectivityResult.contains(ConnectivityResult.mobile);
      final isEthernet = connectivityResult.contains(ConnectivityResult.ethernet);
      return isWifi || isMobile || isEthernet;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> get isConnected async {
    try {
      // ✅ FAST PATH: Si el servidor fue marcado como no alcanzable y el cooldown
      // sigue activo, retornar false inmediatamente SIN hacer llamada de plataforma.
      // Esto evita el await costoso de checkConnectivity() en cada llamada.
      if (!_serverReachable && _lastServerCheck != null) {
        final elapsed = DateTime.now().difference(_lastServerCheck!);
        if (elapsed < _serverCheckCooldown) {
          return false;
        }
      }

      // Verificar conexión física (llamada de plataforma - solo cuando es necesario)
      final connectivityResult = await _connectivity.checkConnectivity();

      final isWifi = connectivityResult.contains(ConnectivityResult.wifi);
      final isMobile = connectivityResult.contains(ConnectivityResult.mobile);
      final isEthernet = connectivityResult.contains(ConnectivityResult.ethernet);

      final hasConnection = isWifi || isMobile || isEthernet;

      if (!hasConnection) {
        return false;
      }

      // Primera verificación: ping rápido al servidor
      // ✅ FIX: Si hay un check pendiente, esperar su resultado (evita race condition)
      if (!_initialReachabilityChecked || _pendingReachabilityCheck != null) {
        _initialReachabilityChecked = true;
        final reachable = await _quickReachabilityCheck();
        if (!reachable) {
          return false;
        }
      }

      // Si el servidor fue marcado como no alcanzable pero el cooldown expiró,
      // verificar antes de permitir llamadas al servidor
      if (!_serverReachable && _lastServerCheck != null) {
        final elapsed = DateTime.now().difference(_lastServerCheck!);
        if (elapsed >= _serverCheckCooldown) {
          final reachable = await _quickReachabilityCheck();
          if (!reachable) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> canReachServer({Duration timeout = _defaultTimeout}) async {
    try {
      final baseUrl = _getBaseUrl();
      if (baseUrl == null) {
        return _serverReachable;
      }

      // ⚡ Ping directo al servidor - un solo intento con timeout corto
      final dio = Dio(BaseOptions(
        connectTimeout: timeout,
        receiveTimeout: timeout,
      ));

      try {
        final response = await dio.head('$baseUrl/health').timeout(timeout);
        _serverReachable = response.statusCode == 200;
      } catch (e) {
        // /health no existe, intentar HEAD a raíz
        try {
          final response = await dio.head(baseUrl).timeout(timeout);
          _serverReachable = response.statusCode != null && response.statusCode! < 500;
        } catch (_) {
          _serverReachable = false;
        }
      }

      _lastServerCheck = DateTime.now();
      return _serverReachable;
    } catch (e) {
      _serverReachable = false;
      _lastServerCheck = DateTime.now();
      return false;
    }
  }

  @override
  void markServerUnreachable() {
    _serverReachable = false;
    _lastServerCheck = DateTime.now();
    print('🌐 NetworkInfo: Servidor marcado como no alcanzable');
  }

  @override
  void resetServerReachability() {
    _serverReachable = true;
    _lastServerCheck = null;
    print('🌐 NetworkInfo: Estado de alcanzabilidad del servidor reseteado');
  }

  /// ✅ Verificación rápida de alcanzabilidad del servidor (con mutex para evitar pings concurrentes)
  Future<bool> _quickReachabilityCheck() async {
    // Si ya hay un ping en progreso, reusar el resultado
    if (_pendingReachabilityCheck != null) {
      return _pendingReachabilityCheck!;
    }

    _pendingReachabilityCheck = canReachServer(timeout: const Duration(milliseconds: 1500));
    try {
      final result = await _pendingReachabilityCheck!;
      return result;
    } finally {
      _pendingReachabilityCheck = null;
    }
  }

  String? _getBaseUrl() {
    try {
      return EnvConfig.baseUrl;
    } catch (e) {
      return null;
    }
  }

  // ==================== MONITOREO ACTIVO ====================

  @override
  void startMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final hasConnection = results.any(
          (r) =>
              r == ConnectivityResult.wifi ||
              r == ConnectivityResult.mobile ||
              r == ConnectivityResult.ethernet,
        );

        if (hasConnection && !_serverReachable) {
          // Conexión física restaurada pero servidor marcado como inalcanzable
          // Verificar proactivamente si el servidor ya responde
          print('🌐 NetworkInfo: Conectividad física restaurada, verificando servidor...');
          _scheduleServerRecoveryCheck();
        }

        if (!hasConnection) {
          // Sin conexión física - marcar servidor como inalcanzable
          _cancelRecoveryTimer();
          _serverReachable = false;
          _lastServerCheck = DateTime.now();
          print('🌐 NetworkInfo: Conexión física perdida');
        }
      },
    );

    // Timer periódico de recuperación: cuando el servidor está caído,
    // verificar cada 10 segundos si ya responde (más agresivo que el cooldown de 30s)
    _startRecoveryTimerIfNeeded();
  }

  /// Programa una verificación del servidor después de un breve delay
  void _scheduleServerRecoveryCheck() {
    _cancelRecoveryTimer();
    // Esperar 2 segundos para que la conexión se estabilice, luego verificar
    _recoveryTimer = Timer(const Duration(seconds: 2), () async {
      print('🌐 NetworkInfo: Intentando reconexión con servidor...');
      final reachable = await canReachServer(timeout: const Duration(seconds: 2));
      if (reachable) {
        print('🌐 NetworkInfo: ¡Servidor recuperado!');
        resetServerReachability();
      } else {
        _startRecoveryTimerIfNeeded();
      }
    });
  }

  /// Inicia un timer periódico que verifica el servidor cada 10 segundos
  /// cuando está marcado como inalcanzable
  void _startRecoveryTimerIfNeeded() {
    if (_serverReachable) return;
    _cancelRecoveryTimer();
    _recoveryTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_serverReachable) {
        timer.cancel();
        return;
      }
      // Solo verificar si hay conexión física
      final hasConnection = await hasPhysicalConnection;
      if (!hasConnection) return;

      final reachable = await canReachServer(timeout: const Duration(seconds: 2));
      if (reachable) {
        print('🌐 NetworkInfo: ¡Servidor recuperado automáticamente!');
        resetServerReachability();
        timer.cancel();
      }
    });
  }

  void _cancelRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _cancelRecoveryTimer();
  }
}
