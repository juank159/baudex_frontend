// lib/app/data/local/sync_lock.dart

import 'dart:async';

/// Mutex simple para sincronización en Dart
///
/// Garantiza que solo una operación de sincronización se ejecute
/// a la vez, previniendo race conditions.
///
/// Uso:
/// ```dart
/// final lock = SyncLock();
/// await lock.synchronized(() async {
///   // Código protegido
/// });
/// ```
class SyncLock {
  Completer<void>? _completer;
  bool _isLocked = false;
  DateTime? _lockAcquiredAt;
  String? _lockHolderInfo;

  /// Tiempo máximo que un lock puede mantenerse (para prevenir deadlocks)
  final Duration lockTimeout;

  /// Si es true, permite adquirir el lock si el anterior expiró
  final bool allowTimeoutOverride;

  SyncLock({
    this.lockTimeout = const Duration(minutes: 5),
    this.allowTimeoutOverride = true,
  });

  /// Indica si el lock está actualmente adquirido
  bool get isLocked => _isLocked;

  /// Indica si el lock ha expirado (útil para debugging)
  bool get isExpired {
    if (!_isLocked || _lockAcquiredAt == null) return false;
    return DateTime.now().difference(_lockAcquiredAt!) > lockTimeout;
  }

  /// Información de debug sobre el estado del lock
  Map<String, dynamic> get debugInfo => {
        'isLocked': _isLocked,
        'lockAcquiredAt': _lockAcquiredAt?.toIso8601String(),
        'lockHolderInfo': _lockHolderInfo,
        'isExpired': isExpired,
        'lockTimeout': lockTimeout.inSeconds,
      };

  /// Ejecuta una función de manera sincronizada
  ///
  /// Si el lock ya está adquirido, espera hasta que esté disponible.
  /// Si el lock está expirado y [allowTimeoutOverride] es true,
  /// fuerza la liberación del lock anterior.
  ///
  /// [action] es la función a ejecutar de manera protegida.
  /// [holderInfo] es información opcional sobre quién adquiere el lock (para debugging).
  ///
  /// Retorna el resultado de [action].
  Future<T> synchronized<T>(
    Future<T> Function() action, {
    String? holderInfo,
  }) async {
    await _acquireLock(holderInfo);
    try {
      return await action();
    } finally {
      _releaseLock();
    }
  }

  /// Intenta adquirir el lock sin bloquear
  ///
  /// Retorna true si el lock fue adquirido, false si ya estaba adquirido.
  bool tryAcquire({String? holderInfo}) {
    if (_isLocked && !isExpired) {
      return false;
    }

    if (_isLocked && isExpired && allowTimeoutOverride) {
      // Lock expirado, forzar liberación
      _forceRelease();
    }

    if (_isLocked) {
      return false;
    }

    _isLocked = true;
    _lockAcquiredAt = DateTime.now();
    _lockHolderInfo = holderInfo;
    return true;
  }

  /// Libera el lock manualmente (usar con cuidado)
  void release() {
    _releaseLock();
  }

  Future<void> _acquireLock(String? holderInfo) async {
    // Si el lock está expirado, forzar liberación
    if (_isLocked && isExpired && allowTimeoutOverride) {
      _forceRelease();
    }

    // Esperar si el lock está adquirido
    while (_isLocked) {
      _completer ??= Completer<void>();
      await _completer!.future;
    }

    _isLocked = true;
    _lockAcquiredAt = DateTime.now();
    _lockHolderInfo = holderInfo;
    _completer = null;
  }

  void _releaseLock() {
    _isLocked = false;
    _lockAcquiredAt = null;
    _lockHolderInfo = null;

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete();
    }
    _completer = null;
  }

  void _forceRelease() {
    // Registrar que hubo un lock expirado (útil para debugging)
    final expiredHolder = _lockHolderInfo;
    final expiredDuration = _lockAcquiredAt != null
        ? DateTime.now().difference(_lockAcquiredAt!).inSeconds
        : 0;

    print(
      '⚠️ SyncLock: Forzando liberación de lock expirado '
      '(holder: $expiredHolder, duración: ${expiredDuration}s)',
    );

    _releaseLock();
  }
}

/// Lock específico para operaciones de sincronización
///
/// Singleton que garantiza que solo una sincronización
/// se ejecute a la vez en toda la aplicación.
class SyncServiceLock {
  static final SyncServiceLock _instance = SyncServiceLock._internal();
  factory SyncServiceLock() => _instance;
  SyncServiceLock._internal();

  final SyncLock _syncAllLock = SyncLock(
    lockTimeout: const Duration(minutes: 10),
    allowTimeoutOverride: true,
  );

  final SyncLock _operationLock = SyncLock(
    lockTimeout: const Duration(minutes: 2),
    allowTimeoutOverride: true,
  );

  final SyncLock _cleanupLock = SyncLock(
    lockTimeout: const Duration(minutes: 5),
    allowTimeoutOverride: true,
  );

  /// Lock para sincronización completa (syncAll)
  SyncLock get syncAll => _syncAllLock;

  /// Lock para operaciones individuales
  SyncLock get operation => _operationLock;

  /// Lock para operaciones de limpieza
  SyncLock get cleanup => _cleanupLock;

  /// Información de debug de todos los locks
  Map<String, dynamic> get debugInfo => {
        'syncAll': _syncAllLock.debugInfo,
        'operation': _operationLock.debugInfo,
        'cleanup': _cleanupLock.debugInfo,
      };
}
