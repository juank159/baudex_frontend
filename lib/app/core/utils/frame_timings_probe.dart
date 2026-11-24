import 'package:flutter/scheduler.dart';

import '../../../features/invoices/domain/invoice_entry_metrics.dart';

bool _installed = false;

/// Cuenta los cuadros de pantalla lentos con los tiempos reales del motor
/// (armar + pintar). El motor los entrega en tandas, más o menos una vez
/// por segundo: no cuesta nada medible. Sale en el reporte de diagnóstico.
void ensureFrameTimingsProbe() {
  if (_installed) return;
  _installed = true;
  SchedulerBinding.instance.addTimingsCallback((timings) {
    final metrics = InvoiceEntryMetrics.instance;
    for (final t in timings) {
      metrics.recordFrame(t.totalSpan.inMicroseconds / 1000);
    }
  });
}
