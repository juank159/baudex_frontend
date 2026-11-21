// lib/app/core/navigation/getx_route_janitor.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
// GetX no exporta este archivo; es el único modo de llegar al registro.
// ignore: implementation_imports
import 'package:get/get_navigation/src/router_report.dart';

/// Libera las pantallas cerradas que GetX 4.7 retiene para siempre.
///
/// GetX anota en un mapa estático (`RouterReportManager._routesKey`) qué
/// controladores pertenecen a cada pantalla, para borrarlos al cerrarla. Al
/// cerrarla borra los controladores pero NUNCA quita la pantalla del mapa:
/// cada pantalla visitada quedaba viva con su animación y su árbol (398 rutas
/// tras una hora de navegar por el menú, memoria de 36 a 63 MB).
///
/// Este observador, cuando las pantallas cerradas ya se desecharon, vacía ese
/// mapa y vuelve a anotar SOLO las pantallas abiertas (y las que se están
/// cerrando) con sus controladores.
///
/// Cómo sabe de quién es cada entrada del mapa: GetX anota cada controlador
/// nuevo en "la pantalla actual" y agrega las entradas en orden. Este
/// observador lleva la misma cuenta de cuál es la pantalla actual (GetX la
/// cambia al instalar, apilar, volver y reemplazar) y, en cada navegación,
/// asigna las entradas nuevas a la pantalla que era la actual. No depende del
/// texto de cada pantalla: en las versiones compiladas todas se imprimen igual
/// ("Instance of 'GetPageRoute<dynamic>'") y la versión anterior nunca podía
/// limpiar en el equipo del cliente. Si algo no cuadra, no toca nada.
class GetxRouteJanitor extends NavigatorObserver {
  GetxRouteJanitor._();
  static final GetxRouteJanitor instance = GetxRouteJanitor._();

  /// Espera tras la última navegación antes de limpiar (deja terminar la
  /// animación de salida y el borrado de controladores).
  static const Duration settleDelay = Duration(seconds: 2);

  final List<Route<dynamic>> _live = [];
  final List<Route<dynamic>> _closing = [];
  Timer? _timer;

  /// Pantalla de cada entrada del mapa de GetX, en el mismo orden (`null` si
  /// no se sabe de quién es).
  final List<Route<dynamic>?> _order = [];

  /// La pantalla "actual" de GetX (a la que anota los controladores nuevos).
  Route<dynamic>? _current;

  /// Cuántas limpiezas se hicieron y cuántas se descartaron (diagnóstico).
  int sweeps = 0;
  int skipped = 0;

  /// Último motivo de no limpiar (diagnóstico).
  String? lastSkip;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _catchUp();
    _current = route;
    _live.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _catchUp();
    if (previousRoute != null) _current = previousRoute;
    _closed(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _catchUp();
    _closed(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _catchUp();
    if (newRoute != null) _current = newRoute;
    final index = oldRoute == null ? -1 : _live.indexOf(oldRoute);
    if (newRoute != null) {
      if (index == -1) {
        _live.add(newRoute);
      } else {
        _live[index] = newRoute;
      }
    } else if (index != -1) {
      _live.removeAt(index);
    }
    if (oldRoute != null) {
      _closing.add(oldRoute);
      _schedule();
    }
  }

  void _closed(Route<dynamic> route) {
    _live.remove(route);
    _closing.add(route);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(settleDelay, () {
      final result = sweep();
      // Alguna pantalla aún se está cerrando: reintentar más tarde.
      if (result == SweepResult.waiting) _schedule();
    });
  }

  /// Las entradas nuevas del mapa son de la pantalla que era la actual.
  /// Devuelve las llaves de cada entrada, o `null` si no se pudo leer.
  List<List<String>>? _catchUp() {
    final dump = _readRegistry();
    final entries = dump == null ? null : parseRegistryEntries(dump);
    if (entries == null) return null;
    if (entries.length < _order.length) {
      // Alguien vació el mapa por fuera: ya no se sabe de quién es cada una.
      _order
        ..clear()
        ..addAll(List<Route<dynamic>?>.filled(entries.length, null));
      return entries;
    }
    while (_order.length < entries.length) {
      _order.add(_current);
    }
    return entries;
  }

  /// Limpia el mapa de GetX si es seguro hacerlo.
  @visibleForTesting
  SweepResult sweep() {
    // Ya desechadas: no hace falta recordarlas.
    _closing.removeWhere((r) => r.navigator == null);
    final keep = <Route<dynamic>>{
      ..._live,
      for (final r in _closing) r,
    };

    final entries = _catchUp();
    if (entries == null) {
      skipped++;
      _noteSkip('no se pudo leer el mapa de GetX: $_readError');
      return SweepResult.skipped;
    }
    // Entradas de pantallas desconocidas: no se sabe si siguen abiertas.
    final unknown = _order.where((r) => r == null).length;
    if (unknown > 0) {
      skipped++;
      _noteSkip('$unknown entrada(s) sin dueño conocido de ${_order.length}');
      return _closing.isEmpty ? SweepResult.skipped : SweepResult.waiting;
    }
    final dead = [
      for (final r in _order)
        if (!keep.contains(r)) r,
    ];
    if (dead.isEmpty) {
      return _closing.isEmpty ? SweepResult.clean : SweepResult.waiting;
    }

    final plan = relinkPlan(
      owners: _order.cast<Object>(),
      keys: entries,
      keep: keep.cast<Object>().toSet(),
    );
    RouterReportManager.clearRouteKeys();
    final newOrder = <Route<dynamic>?>[];
    for (final step in plan) {
      final route = step.owner as Route<dynamic>;
      RouterReportManager.reportCurrentRoute(route);
      for (final key in step.keys) {
        RouterReportManager.reportDependencyLinkedToRoute(key);
      }
      if (step.keys.isNotEmpty) newOrder.add(route);
    }
    _order
      ..clear()
      ..addAll(newOrder);
    final current = _current ?? (_live.isNotEmpty ? _live.last : null);
    if (current != null) RouterReportManager.reportCurrentRoute(current);
    sweeps++;
    return _closing.isEmpty ? SweepResult.swept : SweepResult.waiting;
  }

  void _noteSkip(String why) {
    lastSkip = why.length > 2000 ? why.substring(0, 2000) : why;
    // Las primeras veces queda en el registro (diagnóstico en el equipo).
    if (skipped <= 3) {
      debugPrint('[NAV] limpieza de pantallas omitida: '
          '${lastSkip!.substring(0, lastSkip!.length.clamp(0, 600))}');
    }
  }

  Object? _readError;

  /// Texto del mapa de GetX (`{ruta: [llaves], ...}`), o null si no se pudo.
  String? _readRegistry() {
    final previous = Get.log;
    String? dump;
    Get.log = (String text, {bool isError = false}) => dump = text;
    try {
      RouterReportManager().printInstanceStack();
    } catch (e) {
      _readError = e;
      dump = null;
    } finally {
      Get.log = previous;
    }
    return dump;
  }

  /// Pantallas cerradas que este observador aún recuerda (diagnóstico).
  @visibleForTesting
  int get closingCount => _closing.length;

  /// Solo para pruebas.
  @visibleForTesting
  void reset() {
    _timer?.cancel();
    _live.clear();
    _closing.clear();
    _order.clear();
    _current = null;
    sweeps = 0;
    skipped = 0;
  }

  @visibleForTesting
  int get liveCount => _live.length;
}

enum SweepResult { swept, clean, waiting, skipped }

/// Un dueño y las llaves que se le vuelven a anotar.
class RelinkStep {
  final Object owner;
  final List<String> keys;
  const RelinkStep(this.owner, this.keys);
}

/// Qué volver a anotar: de cada entrada (dueño [owners] y llaves [keys], en
/// el orden del mapa), solo las de dueños que se conservan ([keep]); las
/// llaves de un mismo dueño se juntan en el orden en que aparecen.
@visibleForTesting
List<RelinkStep> relinkPlan({
  required List<Object> owners,
  required List<List<String>> keys,
  required Set<Object> keep,
}) {
  final byOwner = <Object, List<String>>{};
  for (var i = 0; i < owners.length && i < keys.length; i++) {
    final owner = owners[i];
    if (!keep.contains(owner)) continue;
    byOwner.putIfAbsent(owner, () => <String>[]).addAll(keys[i]);
  }
  return [for (final e in byOwner.entries) RelinkStep(e.key, e.value)];
}

/// Llaves de cada entrada del texto del mapa de GetX
/// (`{ruta: [A, B], ruta: [], ...}`), en orden, o `null` si no se entiende.
/// No usa el texto de la ruta (en las versiones compiladas es igual para
/// todas).
@visibleForTesting
List<List<String>>? parseRegistryEntries(String dump) {
  final body = dump.trim();
  if (!body.startsWith('{') || !body.endsWith('}')) return null;
  final out = <List<String>>[];
  var at = 0;
  while (true) {
    final open = body.indexOf(': [', at);
    if (open == -1) break;
    final start = open + 3;
    final end = body.indexOf(']', start);
    if (end == -1) return null;
    out.add(splitRegistryKeys(body.substring(start, end)));
    at = end + 1;
  }
  return out;
}

/// "A, B<C, D>, E" → [A, B<C, D>, E] (respeta los tipos genéricos).
@visibleForTesting
List<String> splitRegistryKeys(String list) {
  final out = <String>[];
  if (list.trim().isEmpty) return out;
  var depth = 0;
  var current = StringBuffer();
  for (var i = 0; i < list.length; i++) {
    final ch = list[i];
    if (ch == '<') depth++;
    if (ch == '>') depth--;
    if (ch == ',' && depth == 0) {
      out.add(current.toString().trim());
      current = StringBuffer();
      continue;
    }
    current.write(ch);
  }
  out.add(current.toString().trim());
  return out;
}
