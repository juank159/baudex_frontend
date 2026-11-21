// lib/app/core/navigation/route_stack_observer.dart
import 'package:flutter/widgets.dart';

/// Lleva la cuenta de las pantallas abiertas (nombres de ruta, de abajo hacia
/// arriba) para que la navegación sepa si una pantalla YA está abierta debajo.
///
/// Por qué importa: con GetX, abrir de nuevo una pantalla que sigue viva más
/// abajo (p. ej. Facturación → Productos encima → menú "Facturación") crea un
/// segundo controlador con la misma llave; al cerrarse la copia vieja, GetX
/// borra esa llave y cierra el controlador de la pantalla NUEVA. La pantalla
/// quedaba "cargando" para siempre y no respondía.
class RouteStackObserver extends NavigatorObserver {
  RouteStackObserver._();
  static final RouteStackObserver instance = RouteStackObserver._();

  final List<Route<dynamic>> _stack = [];

  /// Nombres de las pantallas abiertas, de abajo hacia arriba.
  List<String?> get names => [for (final r in _stack) r.settings.name];

  /// Pantallas abiertas llamadas [name] (de abajo hacia arriba).
  List<Route<dynamic>> routesNamed(String name) =>
      [for (final r in _stack) if (r.settings.name == name) r];

  /// ¿Hay una pantalla [name] abierta (no necesariamente arriba)?
  bool contains(String name) => _stack.any((r) => r.settings.name == name);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _stack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index == -1) {
      if (newRoute is PageRoute) _stack.add(newRoute);
      return;
    }
    if (newRoute is PageRoute) {
      _stack[index] = newRoute;
    } else {
      _stack.removeAt(index);
    }
  }

  /// Solo para pruebas.
  @visibleForTesting
  void reset() => _stack.clear();
}
