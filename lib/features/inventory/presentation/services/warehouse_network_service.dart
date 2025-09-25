// lib/features/inventory/presentation/services/warehouse_network_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WarehouseNetworkService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static final RxBool _isOnline = true.obs;
  static final RxBool _isRetrying = false.obs;
  static final RxInt _retryAttempts = 0.obs;
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // ==================== GETTERS ====================
  
  static bool get isOnline => _isOnline.value;
  static bool get isRetrying => _isRetrying.value;
  static int get retryAttempts => _retryAttempts.value;

  // ==================== INITIALIZATION ====================

  /// Inicializar el servicio de red
  static Future<void> initialize() async {
    await _checkInitialConnectivity();
    _startMonitoring();
  }

  /// Verificar conectividad inicial
  static Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      print('❌ Error verificando conectividad inicial: $e');
      _isOnline.value = false;
    }
  }

  /// Iniciar monitoreo de conectividad
  static void _startMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        print('❌ Error en monitoreo de conectividad: $error');
        _isOnline.value = false;
      },
    );
  }

  /// Actualizar estado de conexión
  static void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline.value;
    _isOnline.value = !results.contains(ConnectivityResult.none);
    
    if (_isOnline.value && wasOffline) {
      _showReconnectionMessage();
      _retryAttempts.value = 0;
    } else if (!_isOnline.value) {
      _showDisconnectionMessage();
    }
  }

  // ==================== RETRY MECHANISM ====================

  /// Ejecutar operación con reintentos automáticos
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    String operationName = 'Operación',
    bool showProgress = true,
  }) async {
    _retryAttempts.value = 0;
    Exception? lastException;

    while (_retryAttempts.value < maxRetryAttempts) {
      try {
        // Verificar conectividad antes del intento
        if (!await _verifyInternetAccess()) {
          throw NetworkException('Sin conexión a internet');
        }

        if (showProgress && _retryAttempts.value > 0) {
          _showRetryProgress(operationName, _retryAttempts.value);
        }

        _isRetrying.value = _retryAttempts.value > 0;
        final result = await operation();
        
        // Operación exitosa
        _isRetrying.value = false;
        if (_retryAttempts.value > 0) {
          _showSuccessAfterRetry(operationName);
        }
        
        return result;

      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        _retryAttempts.value++;

        print('❌ Intento ${_retryAttempts.value} falló para $operationName: $e');

        // Si no es el último intento, esperar antes del siguiente
        if (_retryAttempts.value < maxRetryAttempts) {
          await Future.delayed(retryDelay * _retryAttempts.value);
        }
      }
    }

    // Todos los intentos fallaron
    _isRetrying.value = false;
    _showMaxRetriesReached(operationName);
    throw lastException ?? NetworkException('Operación falló después de $maxRetryAttempts intentos');
  }

  // ==================== NETWORK VERIFICATION ====================

  /// Verificar acceso real a internet
  static Future<bool> _verifyInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Verificar conectividad específica al servidor
  static Future<bool> verifyServerAccess(String serverUrl) async {
    try {
      final uri = Uri.parse(serverUrl);
      final result = await InternetAddress.lookup(uri.host)
          .timeout(const Duration(seconds: 10));
      return result.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando acceso al servidor: $e');
      return false;
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Manejar errores de red de forma inteligente
  static String handleNetworkError(dynamic error) {
    if (error is SocketException) {
      return _handleSocketException(error);
    } else if (error is TimeoutException) {
      return 'Tiempo de espera agotado. Verifica tu conexión e intenta nuevamente.';
    } else if (error is NetworkException) {
      return error.message;
    } else if (error.toString().contains('XMLHttpRequest')) {
      return 'Error de conexión. Verifica que el servidor esté disponible.';
    } else if (error.toString().contains('Connection refused')) {
      return 'Servidor no disponible. Contacta al administrador.';
    } else if (error.toString().contains('Connection timed out')) {
      return 'Conexión muy lenta. Intenta más tarde.';
    } else {
      return 'Error de conexión: ${error.toString()}';
    }
  }

  /// Manejar excepciones de socket específicamente
  static String _handleSocketException(SocketException e) {
    switch (e.osError?.errorCode) {
      case 7: // No address associated with hostname
        return 'No se puede conectar al servidor. Verifica la URL.';
      case 61: // Connection refused
        return 'Servidor no disponible. Intenta más tarde.';
      case 64: // Host is down
        return 'Servidor temporalmente no disponible.';
      case 65: // No route to host
        return 'No se puede alcanzar el servidor. Verifica tu red.';
      default:
        return 'Error de conexión de red. Verifica tu conexión a internet.';
    }
  }

  // ==================== USER FEEDBACK ====================

  /// Mostrar mensaje de desconexión
  static void _showDisconnectionMessage() {
    Get.snackbar(
      'Sin conexión',
      'Se perdió la conexión a internet. Verifica tu red.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.wifi_off, color: Colors.red),
      duration: const Duration(seconds: 5),
      isDismissible: true,
    );
  }

  /// Mostrar mensaje de reconexión
  static void _showReconnectionMessage() {
    Get.snackbar(
      'Conectado',
      'Conexión a internet restablecida.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.wifi, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
  }

  /// Mostrar progreso de reintento
  static void _showRetryProgress(String operation, int attempt) {
    Get.snackbar(
      'Reintentando...',
      '$operation - Intento $attempt de $maxRetryAttempts',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade800,
      icon: const Icon(Icons.refresh, color: Colors.orange),
      duration: const Duration(seconds: 2),
      showProgressIndicator: true,
    );
  }

  /// Mostrar éxito después de reintentos
  static void _showSuccessAfterRetry(String operation) {
    Get.snackbar(
      'Operación exitosa',
      '$operation completada después de ${_retryAttempts.value} reintentos.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
  }

  /// Mostrar que se alcanzó el máximo de reintentos
  static void _showMaxRetriesReached(String operation) {
    Get.snackbar(
      'Operación falló',
      '$operation no pudo completarse después de $maxRetryAttempts intentos.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          Get.back(); // Cerrar snackbar
          // Aquí podrías agregar lógica para reintentar manualmente
        },
        child: const Text('Intentar de nuevo', style: TextStyle(color: Colors.red)),
      ),
    );
  }

  // ==================== MANUAL RETRY ====================

  /// Forzar reintento manual
  static Future<T?> forceRetry<T>(
    Future<T> Function() operation, {
    String operationName = 'Operación',
  }) async {
    try {
      _retryAttempts.value = 0;
      return await executeWithRetry(operation, operationName: operationName);
    } catch (e) {
      return null;
    }
  }

  // ==================== CLEANUP ====================

  /// Limpiar recursos
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  // ==================== UTILITY METHODS ====================

  /// Obtener información de estado de red
  static Map<String, dynamic> getNetworkStatus() {
    return {
      'isOnline': _isOnline.value,
      'isRetrying': _isRetrying.value,
      'retryAttempts': _retryAttempts.value,
      'maxRetryAttempts': maxRetryAttempts,
    };
  }

  /// Verificar si se debe mostrar indicador de carga
  static bool shouldShowLoading() {
    return _isRetrying.value && _retryAttempts.value > 0;
  }
}

// ==================== CUSTOM EXCEPTIONS ====================

class NetworkException implements Exception {
  final String message;
  
  const NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}