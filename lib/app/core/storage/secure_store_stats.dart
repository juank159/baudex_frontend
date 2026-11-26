// lib/app/core/storage/secure_store_stats.dart
//
// Cuánto cuesta de verdad el almacén de sesión en ESTE equipo: cada lectura
// o escritura del archivo (`flutter_secure_storage.dat` en Windows) abre el
// archivo entero y lo descifra. Sale en Diagnóstico → Exportar reporte.
import 'session_startup_trace.dart';

class SecureStoreStats {
  SecureStoreStats._();

  static DateTime _since = DateTime.now();
  static int fileReads = 0;
  static int fileWrites = 0;
  static int memoryReads = 0;
  static int failedReads = 0;
  static double readMs = 0;
  static double worstReadMs = 0;
  static double writeMs = 0;
  static double worstWriteMs = 0;

  static void fileRead(Duration took, {bool failed = false}) {
    final ms = took.inMicroseconds / 1000;
    fileReads++;
    readMs += ms;
    if (ms > worstReadMs) worstReadMs = ms;
    if (failed) failedReads++;
  }

  static void fileWrite(Duration took) {
    final ms = took.inMicroseconds / 1000;
    fileWrites++;
    writeMs += ms;
    if (ms > worstWriteMs) worstWriteMs = ms;
  }

  static void memoryRead() => memoryReads++;

  static void reset() {
    _since = DateTime.now();
    fileReads = fileWrites = memoryReads = failedReads = 0;
    readMs = worstReadMs = writeMs = worstWriteMs = 0;
  }

  static String _f(double v) => v.toStringAsFixed(v < 10 ? 1 : 0);

  /// Bloque para el reporte de Diagnóstico.
  static String report({DateTime? now}) {
    final minutes =
        (now ?? DateTime.now()).difference(_since).inMilliseconds / 60000;
    final perMinute = minutes < 0.05 ? fileReads.toDouble() : fileReads / minutes;
    final each = fileReads == 0 ? 0.0 : readMs / fileReads;
    final recovered = SessionStartupTrace.recoveredKeys.length;
    return [
      'Almacén de sesión (${_f(minutes)} min de uso):',
      '  lecturas de archivo: $fileReads (${_f(perMinute)} por minuto), '
          '${_f(each)} ms cada una, peor ${_f(worstReadMs)} ms; '
          'servidas de memoria: $memoryReads',
      '  escrituras de archivo: $fileWrites, peor ${_f(worstWriteMs)} ms',
      '  veces que el archivo no se pudo leer: $failedReads; '
          'datos restaurados de la copia protegida: $recovered',
      '  guardado en: ${SessionStartupTrace.storageMode}',
      '  ${SessionStartupTrace.prefsLine()}',
    ].join('\n');
  }
}
