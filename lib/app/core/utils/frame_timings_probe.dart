import 'package:flutter/scheduler.dart';

import '../../../features/invoices/domain/invoice_entry_metrics.dart';

bool _installed = false;

/// Cuadros de pantalla dibujados desde que se instaló la medición. Sirve
/// para contar cuántos cuadros tomó algo (p. ej. una lectura del lector):
/// se resta el valor del principio al del final.
int get drawnFrameCount => _drawnFrames;
int _drawnFrames = 0;

/// Cuenta los cuadros de pantalla lentos con los tiempos reales del motor
/// (armar + pintar). El motor los entrega en tandas, más o menos una vez
/// por segundo: no cuesta nada medible. Sale en el reporte de diagnóstico.
void ensureFrameTimingsProbe() {
  if (_installed) return;
  _installed = true;
  SchedulerBinding.instance.addPersistentFrameCallback((_) => _drawnFrames++);
  SchedulerBinding.instance.addTimingsCallback((timings) {
    final metrics = InvoiceEntryMetrics.instance;
    for (final t in timings) {
      metrics.recordFrame(t.totalSpan.inMicroseconds / 1000);
    }
  });
}
