// lib/app/core/navigation/getx_route_janitor.dart
import 'dart:async';

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
/// Este observador, cuando las pantallas cerradas ya terminaron de cerrarse,
/// vacía ese mapa y vuelve a anotar SOLO las pantallas abiertas con sus
/// controladores (los lee del propio GetX). Si algo no cuadra (una pantalla
/// del mapa que no conoce, un texto ambiguo), no toca nada: en el peor caso
/// queda como antes, nunca se pierde el borrado de un controlador.
class GetxRouteJanitor extends NavigatorObserver {
  GetxRouteJanitor._();
  static final GetxRouteJanitor instance = GetxRouteJanitor._();

  /// Espera tras la última navegación antes de limpiar (deja terminar la
  /// animación de salida y el borrado de controladores).
  static const Duration settleDelay = Duration(seconds: 2);

  final List<Route<dynamic>> _live = [];
  final List<Route<dynamic>> _closing = [];
  Timer? _timer;

  /// Cuántas limpiezas se hicieron y cuántas se descartaron (diagnóstico).
  int sweeps = 0;
  int skipped = 0;

  /// Último motivo de no limpiar (diagnóstico).
  String? lastSkip;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _live.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _closed(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _closed(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
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

  /// Limpia el mapa de GetX si es seguro hacerlo.
  @visibleForTesting
  SweepResult sweep() {
    // Una pantalla cerrada que aún no se desecha todavía necesita su anotación
    // (GetX borra sus controladores al desecharla).
    if (_closing.any((r) => r.navigator != null)) return SweepResult.waiting;

    final dump = _readRegistry();
    if (dump == null) {
      skipped++;
      return SweepResult.skipped;
    }
    final closed = List<Route<dynamic>>.of(_closing);
    final plan = planRelink(
      dump: dump,
      live: [for (final r in _live) r.toString()],
      closed: [for (final r in closed) r.toString()],
    );
    if (plan == null) {
      skipped++;
      final why = 'mapa=$dump · abiertas=${_live.length} · cerradas=${closed.length}';
      lastSkip = why.length > 2000 ? why.substring(0, 2000) : why;
      return SweepResult.skipped;
    }
    _closing.removeWhere(closed.contains);
    if (plan.isEmpty && !dump.contains(': [')) return SweepResult.clean;

    RouterReportManager.clearRouteKeys();
    for (var i = 0; i < _live.length; i++) {
      final keys = plan[i];
      if (keys == null || keys.isEmpty) continue;
      RouterReportManager.reportCurrentRoute(_live[i]);
      for (final key in keys) {
        RouterReportManager.reportDependencyLinkedToRoute(key);
      }
    }
    if (_live.isNotEmpty) RouterReportManager.reportCurrentRoute(_live.last);
    sweeps++;
    return SweepResult.swept;
  }

  /// Texto del mapa de GetX (`{ruta: [llaves], ...}`), o null si no se pudo.
  String? _readRegistry() {
    final previous = Get.log;
    String? dump;
    Get.log = (String text, {bool isError = false}) => dump = text;
    try {
      RouterReportManager().printInstanceStack();
    } catch (_) {
      dump = null;
    } finally {
      Get.log = previous;
    }
    return dump;
  }

  /// Solo para pruebas.
  @visibleForTesting
  void reset() {
    _timer?.cancel();
    _live.clear();
    _closing.clear();
    sweeps = 0;
    skipped = 0;
  }

  @visibleForTesting
  int get liveCount => _live.length;
}

enum SweepResult { swept, clean, waiting, skipped }

/// Del texto del mapa de GetX ([dump]), las llaves de cada pantalla abierta
/// ([live], el texto de cada ruta en orden). Devuelve índice de [live] →
/// llaves, o `null` si no es seguro: una ruta aparece más de una vez o hay en
/// el mapa entradas que no son ni de [live] ni de [closed] (no se sabe de
/// quién son, así que no se borran).
@visibleForTesting
Map<int, List<String>>? planRelink({
  required String dump,
  required List<String> live,
  required List<String> closed,
}) {
  final body = dump.trim();
  if (body == '{}' || body.isEmpty) return const {};
  final plan = <int, List<String>>{};
  var accounted = 0;
  for (var i = 0; i < live.length; i++) {
    final marker = '${live[i]}: [';
    final first = body.indexOf(marker);
    if (first == -1) continue;
    if (body.indexOf(marker, first + 1) != -1) return null;
    final start = first + marker.length;
    final end = body.indexOf(']', start);
    if (end == -1) return null;
    plan[i] = splitRegistryKeys(body.substring(start, end));
    accounted++;
  }
  for (final c in closed) {
    final marker = '$c: [';
    var at = body.indexOf(marker);
    while (at != -1) {
      accounted++;
      at = body.indexOf(marker, at + 1);
    }
  }
  final entries = ': ['.allMatches(body).length;
  if (entries != accounted) return null;
  return plan;
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
