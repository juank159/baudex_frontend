import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../data/local/sync_service.dart';

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

  /// Reemplazo seguro de `Get.toNamed`.
  bool toNamed(String route, {dynamic arguments}) =>
      _enqueue(_PendingNav._to(route, arguments));

  /// Reemplazo seguro de `Get.offNamed`.
  bool offNamed(String route, {dynamic arguments}) =>
      _enqueue(_PendingNav._off(route, arguments));

  /// `Get.back()` no necesita guard pero lo exponemos para uniformidad.
  bool back({dynamic result}) {
    if (_inFlight) {
      _log('back DESCARTADO (navegación en curso a $_currentRoute)');
      return false;
    }
    Get.back<dynamic>(result: result);
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
          Get.offAllNamed(nav.route, arguments: nav.arguments);
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
    print('[NAV] $msg');
  }
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
}
