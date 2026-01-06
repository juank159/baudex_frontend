// lib/app/core/services/conflict_resolver.dart

import 'package:get/get.dart';

/// Estrategias de resolución de conflictos
enum ConflictResolutionStrategy {
  /// El servidor siempre gana
  serverWins,

  /// El cliente siempre gana
  clientWins,

  /// Gana la versión más reciente (por timestamp)
  newerWins,

  /// Intenta hacer merge automático de campos
  merge,

  /// Requiere resolución manual
  manual,
}

/// Resultado de la resolución de conflicto
class ConflictResolution<T> {
  /// Datos resueltos
  final T resolvedData;

  /// Estrategia usada
  final ConflictResolutionStrategy strategy;

  /// Hubo conflicto?
  final bool hadConflict;

  /// Mensaje descriptivo
  final String? message;

  ConflictResolution({
    required this.resolvedData,
    required this.strategy,
    required this.hadConflict,
    this.message,
  });
}

/// Servicio para detectar y resolver conflictos de sincronización
class ConflictResolver extends GetxService {
  /// Resuelve un conflicto entre versión local y del servidor
  ///
  /// [localData] - Datos locales (Isar)
  /// [serverData] - Datos del servidor
  /// [strategy] - Estrategia de resolución a usar
  /// [hasConflictWith] - Función que detecta si hay conflicto
  /// [getVersion] - Función que obtiene la versión del dato
  /// [getLastModifiedAt] - Función que obtiene el timestamp de modificación
  ConflictResolution<T> resolveConflict<T>({
    required T localData,
    required T serverData,
    required ConflictResolutionStrategy strategy,
    required bool Function(T local, T server) hasConflictWith,
    required int Function(T data) getVersion,
    required DateTime? Function(T data) getLastModifiedAt,
  }) {
    // 1. Detectar si hay conflicto
    final hasConflict = hasConflictWith(localData, serverData);

    if (!hasConflict) {
      // No hay conflicto, usar datos del servidor
      _logInfo('No conflict detected, using server data');
      return ConflictResolution<T>(
        resolvedData: serverData,
        strategy: strategy,
        hadConflict: false,
        message: 'No conflict detected',
      );
    }

    // 2. Resolver según estrategia
    _logWarning('Conflict detected! Using strategy: ${strategy.name}');

    switch (strategy) {
      case ConflictResolutionStrategy.serverWins:
        return _resolveServerWins(localData, serverData, strategy);

      case ConflictResolutionStrategy.clientWins:
        return _resolveClientWins(localData, serverData, strategy);

      case ConflictResolutionStrategy.newerWins:
        return _resolveNewerWins(
          localData,
          serverData,
          strategy,
          getLastModifiedAt,
        );

      case ConflictResolutionStrategy.merge:
        // Por ahora, merge usa newerWins como fallback
        // En el futuro se puede implementar merge field-by-field
        _logWarning('Merge strategy not fully implemented, using newerWins');
        return _resolveNewerWins(
          localData,
          serverData,
          strategy,
          getLastModifiedAt,
        );

      case ConflictResolutionStrategy.manual:
        // Manual requiere intervención del usuario
        // Por ahora, retornamos datos locales y marcamos para revisión
        _logError('Manual resolution required! Keeping local data for review');
        return ConflictResolution<T>(
          resolvedData: localData,
          strategy: strategy,
          hadConflict: true,
          message: 'Manual resolution required - conflict kept for user review',
        );
    }
  }

  /// Estrategia: Servidor gana
  ConflictResolution<T> _resolveServerWins<T>(
    T localData,
    T serverData,
    ConflictResolutionStrategy strategy,
  ) {
    _logInfo('Resolution: Server wins');
    return ConflictResolution<T>(
      resolvedData: serverData,
      strategy: strategy,
      hadConflict: true,
      message: 'Server data took precedence',
    );
  }

  /// Estrategia: Cliente gana
  ConflictResolution<T> _resolveClientWins<T>(
    T localData,
    T serverData,
    ConflictResolutionStrategy strategy,
  ) {
    _logInfo('Resolution: Client wins');
    return ConflictResolution<T>(
      resolvedData: localData,
      strategy: strategy,
      hadConflict: true,
      message: 'Client data took precedence',
    );
  }

  /// Estrategia: El más reciente gana (por timestamp)
  ConflictResolution<T> _resolveNewerWins<T>(
    T localData,
    T serverData,
    ConflictResolutionStrategy strategy,
    DateTime? Function(T data) getLastModifiedAt,
  ) {
    final localTimestamp = getLastModifiedAt(localData);
    final serverTimestamp = getLastModifiedAt(serverData);

    // Si alguno no tiene timestamp, usar servidor por defecto
    if (localTimestamp == null || serverTimestamp == null) {
      _logWarning('Missing timestamp, defaulting to server data');
      return ConflictResolution<T>(
        resolvedData: serverData,
        strategy: strategy,
        hadConflict: true,
        message: 'Missing timestamp - server data used',
      );
    }

    // Comparar timestamps
    if (localTimestamp.isAfter(serverTimestamp)) {
      _logInfo('Resolution: Local is newer, keeping local data');
      return ConflictResolution<T>(
        resolvedData: localData,
        strategy: strategy,
        hadConflict: true,
        message: 'Local data is newer',
      );
    } else {
      _logInfo('Resolution: Server is newer, using server data');
      return ConflictResolution<T>(
        resolvedData: serverData,
        strategy: strategy,
        hadConflict: true,
        message: 'Server data is newer',
      );
    }
  }

  // Logging helpers
  void _logInfo(String message) {
    // ignore: avoid_print
    print('[ConflictResolver] ℹ️  $message');
  }

  void _logWarning(String message) {
    // ignore: avoid_print
    print('[ConflictResolver] ⚠️  $message');
  }

  void _logError(String message) {
    // ignore: avoid_print
    print('[ConflictResolver] ❌ $message');
  }
}
