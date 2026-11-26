// lib/app/core/session/user_activity.dart
//
// Semáforo de interacción: ¿el usuario está usando la app AHORA (tecla,
// clic, rueda)? El trabajo de fondo (descarga, mantenimiento de la cola) lo
// consulta para no arrancar tandas mientras se teclea o se factura, y
// seguir en los ratos libres. Solo memoria; consultar no cuesta nada.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

class UserActivity {
  UserActivity._();

  static DateTime? _lastInput;
  static bool _installed = false;

  /// Solo para pruebas: reloj de reemplazo.
  static DateTime Function() debugNow = DateTime.now;

  /// Empieza a escuchar teclado y ratón. Llamar una vez, con la app montada.
  static void install() {
    if (_installed) return;
    _installed = true;
    HardwareKeyboard.instance.addHandler((event) {
      if (event is KeyDownEvent) note();
      return false;
    });
    GestureBinding.instance.pointerRouter.addGlobalRoute((event) {
      if (event is PointerDownEvent || event is PointerSignalEvent) note();
    });
  }

  /// Hubo una entrada del usuario ahora.
  static void note() => _lastInput = debugNow();

  /// Tiempo desde la última entrada (muy grande si nunca hubo).
  static Duration get idleFor {
    final last = _lastInput;
    return last == null ? const Duration(days: 1) : debugNow().difference(last);
  }

  /// ¿Hubo una entrada hace menos de [within]?
  static bool busy([Duration within = const Duration(seconds: 3)]) => idleFor < within;

  /// Espera a que pasen [quiet] sin entradas. Devuelve `true` si se logró
  /// y `false` si se agotó [maxWait] (el llamador decide si sigue igual).
  static Future<bool> waitForQuiet(
    Duration quiet, {
    Duration maxWait = const Duration(minutes: 2),
    Duration poll = const Duration(milliseconds: 250),
  }) async {
    final deadline = debugNow().add(maxWait);
    while (idleFor < quiet) {
      if (!debugNow().isBefore(deadline)) return false;
      await Future<void>.delayed(poll);
    }
    return true;
  }

  /// Solo para pruebas.
  static void debugReset() {
    _lastInput = null;
    debugNow = DateTime.now;
  }
}
