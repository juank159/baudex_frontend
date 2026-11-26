// lib/app/core/storage/prefs_startup_report.dart
import '../../data/local/sync_event_log.dart';
import '../../data/local/sync_event_log_service.dart';
import '../ops/ops_reporter.dart';
import 'durable_prefs_store.dart';

/// Si al arrancar las preferencias del equipo estaban dañadas, deja dicho
/// qué pasó y de dónde se recuperaron (Diagnóstico + central de errores).
/// Llamar después de iniciar la central de errores y la base local.
/// Nunca lanza.
void reportDurablePrefsStartup() {
  final report = durablePrefsStartupReport;
  if (report == null || !report.recovered) return;
  final lost = report.source == PrefsLoadSource.empty;
  try {
    OpsReporter.capture(
      StateError('Preferencias del equipo dañadas — $report'),
      null,
      level: lost ? 'error' : 'warning',
      errorType: 'DevicePreferences',
      fingerprint: 'device_prefs|startup|${report.source.name}',
      context: {
        'source': report.source.name,
        'keys': report.keys,
        'problem': report.problem,
      },
    );
  } catch (_) {}
  try {
    SyncEventLogService().log(
      severity: lost ? SyncEventSeverity.error : SyncEventSeverity.warning,
      eventType: SyncEventType.diagnostic,
      operation: 'preferencias del equipo',
      message: switch (report.source) {
        PrefsLoadSource.backup =>
          'El archivo de preferencias estaba dañado; se restauró de la copia (${report.keys} datos).',
        PrefsLoadSource.pendingWrite =>
          'El archivo de preferencias faltaba; se recuperó la última escritura (${report.keys} datos).',
        PrefsLoadSource.salvaged =>
          'El archivo de preferencias estaba dañado y sin copia; se rescataron ${report.keys} datos.',
        _ =>
          'El archivo de preferencias estaba dañado y no se pudo recuperar: se empezó de cero.',
      },
      details: report.toString(),
    );
  } catch (_) {}
}
