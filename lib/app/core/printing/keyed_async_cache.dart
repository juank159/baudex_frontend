// lib/app/core/printing/keyed_async_cache.dart
//
// Guarda UN valor costoso de preparar (el logo del tiquete ya decodificado)
// junto con la "llave" de dónde salió (archivo + fecha de cambio + tamaño, o
// la dirección web). Mientras la llave no cambie, no se vuelve a preparar;
// si cambia (el negocio subió otro logo), se prepara de nuevo solo.
//
// Si prepararlo falla (sin internet para bajar el logo), no se reintenta en
// cada tiquete: se espera [retryFailedAfter]. Sin Flutter ni GetX.
import 'dart:async';

class KeyedAsyncCache<T extends Object> {
  KeyedAsyncCache({
    this.retryFailedAfter = const Duration(minutes: 10),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration retryFailedAfter;
  final DateTime Function() _now;

  String? _key;
  T? _value;
  DateTime? _failedAt;
  String? _loadingKey;
  Future<T?>? _loading;

  /// Cuántas veces se preparó el valor de verdad (para pruebas y medición).
  int loads = 0;

  /// Devuelve el valor de [key]; solo llama a [load] si la llave cambió, si
  /// nunca se cargó, o si la carga anterior falló hace más de
  /// [retryFailedAfter]. Dos pedidos a la vez comparten una sola carga.
  Future<T?> get(String? key, Future<T?> Function() load) {
    if (key == null) return Future<T?>.value(null);
    if (key == _key) {
      if (_value != null) return Future<T?>.value(_value);
      final failedAt = _failedAt;
      if (failedAt != null && _now().difference(failedAt) < retryFailedAfter) {
        return Future<T?>.value(null);
      }
    }
    final inFlight = _loading;
    if (inFlight != null && _loadingKey == key) return inFlight;
    final future = _load(key, load);
    _loadingKey = key;
    _loading = future;
    return future;
  }

  Future<T?> _load(String key, Future<T?> Function() load) async {
    T? value;
    try {
      loads++;
      value = await load();
    } catch (_) {
      value = null;
    }
    _key = key;
    _value = value;
    _failedAt = value == null ? _now() : null;
    if (_loadingKey == key) {
      _loadingKey = null;
      _loading = null;
    }
    return value;
  }

  void clear() {
    _key = null;
    _value = null;
    _failedAt = null;
  }
}
