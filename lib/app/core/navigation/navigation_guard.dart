import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../data/local/sync_service.dart';
import 'route_stack_observer.dart';
import '../utils/snackbar_policy.dart';
import 'cash_register_guard.dart';
import '../../config/routes/app_routes.dart';

/// Guard centralizado de navegación.
///
/// Resuelve los tres problemas crónicos de navegación que bloquean la
/// app cuando el usuario va y viene rápido entre pantallas (dashboard
/// → caja → dashboard → caja en menos de un segundo):
///
///   1. **Doble navegación al mismo destino** — tap-tap accidental en
///      un item del drawer dispara dos `offAllNamed`, dos rondas de
///      `onDelete` corren en paralelo y los futures pendientes terminan
///      escribiendo `.value` en observables ya disposed.
///
///   2. **Navegación encadenada antes de que la anterior termine** —
///      cada `offAllNamed` arranca teardown de controllers + creación
///      de Bindings. Si la siguiente entra antes de que la anterior
///      termine, GetX puede dejar instancias zombi (registradas pero
///      con `isClosed=true`) o instancias duplicadas con el mismo tag.
///
///   3. **Drawer abierto durante teardown** — al cerrar el drawer en
///      el mismo frame que arranca la navegación, el árbol viejo
///      (drawer + scaffold actual) sigue vivo a la vez que arrancan
///      controllers nuevos.
///
/// La estrategia es:
///
/// - **Lock global** con cola FIFO: una sola navegación corriendo a la
///   vez, las siguientes esperan.
/// - **Cooldown por ruta**: misma ruta dentro de [_sameRouteCooldown]
///   se descarta como doble-tap.
/// - **Frame fence**: cuando se reemplaza una ruta (`offAllNamed`/
///   `offNamed`), esperamos al menos un frame antes de liberar el lock
///   para que el teardown del árbol viejo complete.
/// - **Watchdog**: si una navegación tarda más de [_warnThreshold],
///   log de advertencia para diagnosticar Bindings lentos. Si pasa de
///   [_maxLockHold], liberamos el lock por la fuerza para que la app
///   no quede bloqueada permanentemente.
///
/// Logs prefijo `[NAV]` — fácil de greppear en producción.
class NavigationGuard {
  NavigationGuard._();
  static final NavigationGuard instance = NavigationGuard._();

  /// Lock activo: hay una navegación en curso.
  bool _inFlight = false;

  /// Ruta destino de la navegación actual (para logging).
  String? _currentRoute;

  /// Cuándo comenzó la navegación actual (para watchdog).
  DateTime? _currentStartedAt;

  /// Última ruta navegada (para cooldown de doble-tap).
  String? _lastRoute;
  DateTime? _lastNavAt;

  /// Cola FIFO de navegaciones pendientes. Se procesa al liberar el
  /// lock. Si el usuario hace tap-tap-tap rápido, sólo entra la
  /// primera que pase el cooldown; las repetidas se descartan.
  final List<_PendingNav> _queue = [];

  /// Watchdogs activos. Los cancelamos al liberar el lock para no
  /// disparar el panic release si la navegación terminó OK.
  Timer? _warnTimer;
  Timer? _panicTimer;

  /// Mismo destino dentro de esta ventana → descarta el segundo intento.
  static const Duration _sameRouteCooldown = Duration(milliseconds: 700);

  /// Si una navegación tarda más que esto, log de advertencia.
  /// Útil para detectar Bindings lentos en producción.
  static const Duration _warnThreshold = Duration(milliseconds: 1500);

  /// Si el lock no se libera en este tiempo, lo forzamos a abrir
  /// (panic release) para que la app no quede bloqueada para siempre
  /// si un Binding crashea silenciosamente sin completar.
  static const Duration _maxLockHold = Duration(seconds: 5);

  /// Reemplazo seguro de `Get.offAllNamed`.
  ///
  /// Devuelve `true` si la navegación se ejecutó o se encoló, `false`
  /// si fue descartada por cooldown.
  bool offAllNamed(String route, {dynamic arguments}) =>
      _enqueue(_PendingNav._offAll(route, arguments));

  /// Abrir un módulo (menú, atajos Alt+número, paleta): reemplaza la pila
  /// pero conserva las pantallas con trabajo sin guardar (ver
  /// [registerKeepAlive]).
  bool openModule(String route) =>
      _enqueue(_PendingNav._raw('openModule', route, null));

  /// Pantallas que no se cierran al abrir otro módulo mientras [keep]
  /// devuelva `true` (p. ej. Facturación con una venta a medias).
  final Map<String, bool Function()> _keepAlive = {};

  void registerKeepAlive(String route, bool Function() keep) =>
      _keepAlive[route] = keep;

  void unregisterKeepAlive(String route, bool Function() keep) {
    if (_keepAlive[route] == keep) _keepAlive.remove(route);
  }

  /// Reemplazo seguro de `Get.toNamed`.
  bool toNamed(String route, {dynamic arguments}) =>
      _enqueue(_PendingNav._to(route, arguments));

  /// Reemplazo seguro de `Get.offNamed`.
  bool offNamed(String route, {dynamic arguments}) =>
      _enqueue(_PendingNav._off(route, arguments));

  /// Volver (botón "Volver" de las pantallas).
  ///
  /// `Get.back()` de GetX 4.7, si hay un aviso (snackbar) en pantalla, SOLO
  /// cierra el aviso y no vuelve: con avisos en fila el botón "no hacía nada"
  /// durante minutos (volver a la factura tardó 42 s). Aquí se cierran los
  /// avisos y se vuelve de una vez.
  bool back({dynamic result}) {
    if (_inFlight) {
      _log('back DESCARTADO (navegación en curso a $_currentRoute)');
      return false;
    }
    dismissAllSnackbars();
    final navigator = Get.key.currentState;
    if (navigator == null || !navigator.canPop()) return false;
    navigator.pop<dynamic>(result);
    return true;
  }

  bool _enqueue(_PendingNav nav) {
    final now = DateTime.now();

    // Cooldown de doble-tap: misma ruta inmediatamente repetida.
    if (_lastRoute == nav.route &&
        _lastNavAt != null &&
        now.difference(_lastNavAt!) < _sameRouteCooldown) {
      _log('${nav.kind}(${nav.route}) DESCARTADO — cooldown doble-tap');
      return false;
    }

    // De-dup contra cola: si ya hay un destino igual encolado, ignora.
    if (_queue.any((p) => p.route == nav.route)) {
      _log('${nav.kind}(${nav.route}) DESCARTADO — ya en cola');
      return false;
    }
    // De-dup contra actual: si la navegación EN CURSO va al mismo
    // destino, ignora el duplicado.
    if (_inFlight && _currentRoute == nav.route) {
      _log('${nav.kind}(${nav.route}) DESCARTADO — ya navegando ahí');
      return false;
    }

    _queue.add(nav);
    _drain();
    return true;
  }

  void _drain() {
    if (_inFlight) return;
    if (_queue.isEmpty) return;
    final nav = _queue.removeAt(0);
    _execute(nav);
  }

  void _execute(_PendingNav nav) {
    _inFlight = true;
    _currentRoute = nav.route;
    _currentStartedAt = DateTime.now();
    _lastRoute = nav.route;
    _lastNavAt = _currentStartedAt;
    _log('→ ${nav.kind}(${nav.route})');

    // Aviso al SyncService: el isolate va a estar ocupado armando la
    // nueva pantalla. El sync periódico debe postergarse para no
    // descargar 273 registros + parsearlos mientras Flutter intenta
    // desmontar el árbol viejo y montar el nuevo. Sin esto, la UI se
    // siente "congelada" aunque técnicamente no esté bloqueada.
    try {
      if (Get.isRegistered<SyncService>()) {
        Get.find<SyncService>().markNavigationActivity();
      }
    } catch (_) {
      // SyncService no disponible (ej: bootstrap temprano) — no es crítico.
    }

    // Llamamos a Get.xxx dentro de un microtask para que el caller
    // (típicamente un onTap del drawer) pueda completar su frame —
    // esto es importante cuando además se hace Navigator.pop justo
    // antes de navegar; queremos que el pop se procese primero.
    scheduleMicrotask(() {
      switch (nav.kind) {
        case 'offAllNamed':
          if (shouldReturnToOpenScreen(
            route: nav.route,
            currentRoute: Get.currentRoute,
            hasArguments: nav.arguments != null,
            isOpen: RouteStackObserver.instance.contains,
          )) {
            // La pantalla ya está abierta debajo: se vuelve a ELLA (con su
            // estado) en vez de crear otra copia. Con dos copias, GetX
            // cerraba el controlador de la nueva al cerrar la vieja.
            Get.until((r) => r.settings.name == nav.route);
          } else {
            Get.offAllNamed(nav.route, arguments: nav.arguments);
          }
          break;
        case 'openModule':
          final action = moduleNavigation(
            route: nav.route,
            currentRoute: Get.currentRoute,
            openRoutes: RouteStackObserver.instance.names.whereType<String>().toList(),
            mustKeep: (r) {
              final keep = _keepAlive[r];
              if (keep == null) return false;
              try {
                return keep();
              } catch (_) {
                return false;
              }
            },
          );
          switch (action.kind) {
            case ModuleNavKind.returnToOpen:
              Get.until((r) => r.settings.name == nav.route);
            case ModuleNavKind.pushKeeping:
              // Se cierra lo de encima de la pantalla que se conserva y se
              // abre el módulo sobre ella (la venta a medias sigue viva).
              // Si el módulo ya estaba abierto DEBAJO, esa copia se quita:
              // dos copias de la misma pantalla se pisan los controladores.
              final navigator = Get.key.currentState;
              if (navigator != null) {
                for (final old
                    in RouteStackObserver.instance.routesNamed(nav.route)) {
                  if (!old.isCurrent) navigator.removeRoute(old);
                }
              }
              Get.offNamedUntil(
                nav.route,
                (r) => r.settings.name == action.keep,
              );
            case ModuleNavKind.replaceAll:
              Get.offAllNamed(nav.route);
          }
          break;
        case 'toNamed':
          Get.toNamed(nav.route, arguments: nav.arguments);
          break;
        case 'offNamed':
          Get.offNamed(nav.route, arguments: nav.arguments);
          break;
      }
    });

    _armWatchdogs();
    // Liberamos el lock cuando el frame de la nueva pantalla pinta —
    // garantiza que el teardown del árbol anterior completó.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // postFrameCallback se dispara en el siguiente frame TRAS el
      // anuncio de navegación. Damos un frame extra para que GetX
      // dispare los `onClose` de los controllers viejos.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _release(reason: 'frame fence');
      });
    });
  }

  void _armWatchdogs() {
    _warnTimer?.cancel();
    _panicTimer?.cancel();

    _warnTimer = Timer(_warnThreshold, () {
      if (!_inFlight) return;
      final elapsed = DateTime.now().difference(_currentStartedAt!);
      _log('⚠️ navegación a $_currentRoute lleva ${elapsed.inMilliseconds}ms — '
          'Binding lento o teardown atascado');
    });

    _panicTimer = Timer(_maxLockHold, () {
      if (!_inFlight) return;
      final elapsed = DateTime.now().difference(_currentStartedAt!);
      _log('🚨 PANIC RELEASE — navegación a $_currentRoute llevaba '
          '${elapsed.inMilliseconds}ms sin liberar. Forzando apertura del lock '
          'para no bloquear la app.');
      _release(reason: 'panic');
    });
  }

  void _release({required String reason}) {
    if (!_inFlight) return;
    _warnTimer?.cancel();
    _panicTimer?.cancel();
    _warnTimer = null;
    _panicTimer = null;
    final elapsed = _currentStartedAt != null
        ? DateTime.now().difference(_currentStartedAt!)
        : Duration.zero;
    _log('✓ liberado ($reason, ${elapsed.inMilliseconds}ms)');
    _inFlight = false;
    _currentRoute = null;
    _currentStartedAt = null;
    // Procesar siguiente en cola (si la hay).
    if (_queue.isNotEmpty) {
      scheduleMicrotask(_drain);
    }
  }

  void _log(String msg) {
    // Tag uniforme [NAV] para grepear logs de navegación.
    // ignore: avoid_print
  }
}

/// ¿Ir a [route] debe volver a la pantalla que ya está abierta más abajo?
/// Solo sin argumentos (con argumentos es otra consulta de esa pantalla) y si
/// no es la pantalla de arriba (ahí no hay nada que hacer).
bool shouldReturnToOpenScreen({
  required String route,
  required String currentRoute,
  required bool hasArguments,
  required bool Function(String route) isOpen,
}) =>
    !hasArguments && currentRoute != route && isOpen(route);

enum ModuleNavKind { returnToOpen, pushKeeping, replaceAll }

class ModuleNav {
  final ModuleNavKind kind;

  /// Pantalla que se conserva debajo (solo con [ModuleNavKind.pushKeeping]).
  final String? keep;
  const ModuleNav(this.kind, [this.keep]);

  @override
  String toString() => 'ModuleNav($kind, $keep)';
}

/// Qué hacer al abrir el módulo [route] desde el menú o un atajo.
///
/// - Si ya está abierto más abajo: volver a él (con su estado).
/// - Si hay abierta una pantalla que [mustKeep] (Facturación con una venta a
///   medias): abrir el módulo encima de ella, cerrando lo que haya en medio.
///   Antes Alt+6 → Alt+2 reemplazaba la pila y la venta en curso se perdía.
/// - Si no: reemplazar la pila, como el menú (no se acumulan pantallas).
///
/// [openRoutes] van de abajo hacia arriba.
ModuleNav moduleNavigation({
  required String route,
  required String currentRoute,
  required List<String> openRoutes,
  required bool Function(String route) mustKeep,
}) {
  // La pantalla a conservar más alta (volver a algo que está DEBAJO de ella
  // la cerraría).
  String? keep;
  var keepIndex = -1;
  for (var i = openRoutes.length - 1; i >= 0; i--) {
    if (openRoutes[i] != route && mustKeep(openRoutes[i])) {
      keep = openRoutes[i];
      keepIndex = i;
      break;
    }
  }
  final targetIndex = openRoutes.lastIndexOf(route);
  if (currentRoute != route && targetIndex != -1 && targetIndex > keepIndex) {
    return const ModuleNav(ModuleNavKind.returnToOpen);
  }
  if (keep != null) return ModuleNav(ModuleNavKind.pushKeeping, keep);
  return const ModuleNav(ModuleNavKind.replaceAll);
}

class _PendingNav {
  final String kind;
  final String route;
  final dynamic arguments;
  _PendingNav._raw(this.kind, this.route, this.arguments);
  factory _PendingNav._offAll(String r, dynamic a) =>
      _PendingNav._raw('offAllNamed', r, a);
  factory _PendingNav._to(String r, dynamic a) =>
      _PendingNav._raw('toNamed', r, a);
  factory _PendingNav._off(String r, dynamic a) =>
      _PendingNav._raw('offNamed', r, a);
}

/// Atajos cortos para usar en la UI. Equivalentes 1:1 a Get.xxx pero
/// pasando por el guard.
class AppNav {
  AppNav._();
  static bool offAllNamed(String r, {dynamic arguments}) =>
      NavigationGuard.instance.offAllNamed(r, arguments: arguments);
  static bool toNamed(String r, {dynamic arguments}) =>
      NavigationGuard.instance.toNamed(r, arguments: arguments);
  static bool offNamed(String r, {dynamic arguments}) =>
      NavigationGuard.instance.offNamed(r, arguments: arguments);
  static bool back({dynamic result}) =>
      NavigationGuard.instance.back(result: result);

  /// Abrir un módulo (menú lateral, paleta de comandos, atajos Alt+número):
  /// siempre reemplaza la pila, como el menú. Antes la paleta y los atajos
  /// apilaban pantallas (Get.toNamed): cada módulo visitado quedaba vivo
  /// debajo, con sus controladores, escuchas de teclado y recargas por
  /// sincronización, y volver a uno abierto creaba una segunda copia.
  static Future<void> openModule(String route) async {
    if (Get.currentRoute == route) return;
    if (_routeRequiresOpenCashRegister(route)) {
      final ctx = Get.context;
      if (ctx != null && !await CashRegisterGuard.requireOpen(ctx)) return;
    }
    NavigationGuard.instance.openModule(route);
  }

  /// Rutas que exigen una caja abierta antes de entrar: arrancar una venta
  /// sin caja perdía el carrito al ir a abrirla.
  static bool _routeRequiresOpenCashRegister(String route) =>
      route == AppRoutes.invoicesWithTabs || route == AppRoutes.invoicesCreate;
}
