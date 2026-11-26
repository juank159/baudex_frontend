// lib/app/core/storage/session_startup_trace.dart
//
// Qué pasó con la sesión y las preferencias en este arranque, en un par de
// renglones de Diagnóstico: "entró directo" o "pidió iniciar sesión porque
// …". Con una foto de esa pantalla se sabe el motivo sin adivinar.
import 'dart:async';

import '../../data/local/sync_event_log.dart';
import '../../data/local/sync_event_log_service.dart';
import '../ops/ops_reporter.dart';
import 'durable_prefs_store.dart';

class SessionStartupTrace {
  SessionStartupTrace._();

  /// Dónde decidió la app guardar la sesión en este arranque.
  static String storageMode = 'sin decidir';

  /// De dónde salió el token la primera vez que se leyó.
  static String? tokenSource;

  /// Claves que el almacén seguro había perdido y se recuperaron de la
  /// copia protegida.
  static final Set<String> recoveredKeys = <String>{};

  /// Había archivo del token en el almacén seguro aunque no se pudo leer.
  static bool? secureFileExists;

  static bool? _enteredDirectly;
  static String? _serverRejection;
  static bool _logged = false;
  static bool _rejectionLogged = false;
  static Timer? _timer;

  /// Reemplazable en pruebas: escribe un renglón de Diagnóstico.
  static Future<void> Function(String message, {bool warning}) sink = _log;

  /// Reemplazable en pruebas: ¿ya se sabe de qué negocio es el equipo?
  /// (los renglones de Diagnóstico se guardan por negocio).
  static bool Function() organizationKnown = () => true;

  static void authChecked(bool authenticated) {
    _enteredDirectly ??= authenticated;
    _schedule();
  }

  static void serverRejected(String reason) {
    _serverRejection = reason;
    _schedule();
  }

  /// Renglón de sesión de este arranque.
  static String sessionLine() {
    final rejected = _serverRejection;
    if (_enteredDirectly == true) {
      final from = tokenSource == null ? '' : ' (token leído de: $tokenSource)';
      final healed = recoveredKeys.isEmpty
          ? ''
          : '. El almacén seguro de Windows había perdido ${recoveredKeys.length} '
                'dato(s) y se recuperaron de la copia protegida';
      return 'Sesión: entró directo$from$healed. Guardado en: $storageMode.';
    }
    if (rejected != null && _enteredDirectly == null) {
      return 'Sesión: pidió iniciar sesión porque $rejected.';
    }
    final String why;
    if (secureFileExists == true) {
      why = 'el almacén seguro de Windows no devolvió el token que tenía '
          'guardado (perdió su llave) y no había copia protegida';
    } else {
      why = 'no había ninguna sesión guardada en este equipo';
    }
    return 'Sesión: pidió iniciar sesión porque $why. Guardado en: $storageMode.';
  }

  /// Renglón de preferencias de este arranque.
  static String prefsLine() {
    final report = durablePrefsStartupReport;
    if (report == null) return 'Preferencias: las maneja el sistema.';
    return switch (report.source) {
      PrefsLoadSource.file => 'Preferencias: sanas (${report.keys} datos).',
      PrefsLoadSource.backup =>
        'Preferencias: restauradas de la copia (${report.keys} datos; ${report.problem}).',
      PrefsLoadSource.pendingWrite =>
        'Preferencias: recuperadas de la última escritura (${report.keys} datos).',
      PrefsLoadSource.salvaged =>
        'Preferencias: dañadas y sin copia; se rescataron ${report.keys} datos.',
      PrefsLoadSource.empty =>
        'Preferencias: vacías — estaban dañadas y no se pudo recuperar nada (${report.problem}).',
    };
  }

  static void _schedule() {
    _timer ??= Timer.periodic(const Duration(seconds: 3), (timer) {
      if (timer.tick > 200) {
        timer.cancel();
        return;
      }
      flush();
    });
  }

  /// Escribe lo pendiente si ya se conoce el negocio. Nunca lanza.
  static Future<void> flush() async {
    try {
      if (!organizationKnown()) return;
      if (!_logged && _enteredDirectly != null) {
        _logged = true;
        final ok = _enteredDirectly == true && recoveredKeys.isEmpty;
        await sink(sessionLine(), warning: !ok);
        final report = durablePrefsStartupReport;
        await sink(prefsLine(), warning: report?.recovered ?? false);
      }
      final rejected = _serverRejection;
      if (!_rejectionLogged && rejected != null) {
        _rejectionLogged = true;
        await sink(
          'Sesión: el servidor la cerró ($rejected) y hubo que iniciar sesión de nuevo.',
          warning: true,
        );
      }
    } catch (_) {}
  }

  /// Solo para pruebas.
  static void debugReset() {
    _timer?.cancel();
    _timer = null;
    storageMode = 'sin decidir';
    tokenSource = null;
    recoveredKeys.clear();
    secureFileExists = null;
    _enteredDirectly = null;
    _serverRejection = null;
    _logged = false;
    _rejectionLogged = false;
    sink = _log;
    organizationKnown = () => true;
  }

  static Future<void> _log(String message, {bool warning = false}) async {
    if (warning) {
      try {
        OpsReporter.capture(
          StateError(message),
          null,
          level: 'warning',
          errorType: 'SessionStartup',
          fingerprint: 'session_startup|${message.length > 60 ? message.substring(0, 60) : message}',
        );
      } catch (_) {}
    }
    await SyncEventLogService().log(
      severity: warning ? SyncEventSeverity.warning : SyncEventSeverity.info,
      eventType: SyncEventType.diagnostic,
      operation: 'arranque',
      message: message,
    );
  }
}
