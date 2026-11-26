// lib/features/settings/data/printer_diagnostics.dart
//
// Los fallos al cargar, guardar o eliminar impresoras no se pueden quedar
// callados: van al registro de eventos de Diagnóstico y al reporte de
// errores, con el motivo real.
import '../../../app/core/ops/ops_reporter.dart';
import '../../../app/data/local/sync_event_log.dart';
import '../../../app/data/local/sync_event_log_service.dart';

/// Reemplazable en pruebas.
typedef PrinterProblemSink =
    void Function(String operation, Object error, StackTrace? stack);

PrinterProblemSink printerProblemSink = _defaultSink;

/// Deja constancia de un fallo de impresoras. Nunca lanza.
void reportPrinterProblem(String operation, Object error, [StackTrace? stack]) {
  try {
    printerProblemSink(operation, error, stack);
  } catch (_) {}
}

/// El motivo en una línea, para mostrarlo en el aviso.
String printerProblemDetail(Object error) {
  final text = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  return text.length > 220 ? '${text.substring(0, 220)}…' : text;
}

void _defaultSink(String operation, Object error, StackTrace? stack) {
  try {
    OpsReporter.capture(
      error,
      stack,
      errorType: 'PrinterSettings',
      fingerprint: 'printer_settings|$operation|${error.runtimeType}',
      context: {'operation': operation},
    );
  } catch (_) {}
  try {
    SyncEventLogService().log(
      severity: SyncEventSeverity.error,
      eventType: SyncEventType.diagnostic,
      operation: operation,
      message: 'Impresoras: ${printerProblemDetail(error)}',
      entityType: 'printer_settings',
      details: stack?.toString(),
    );
  } catch (_) {}
}
