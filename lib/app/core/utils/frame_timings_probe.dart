import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';

import '../../../features/invoices/domain/invoice_entry_metrics.dart';

bool _installed = false;

/// Cuadros de pantalla dibujados desde que se instaló la medición. Sirve
/// para contar cuántos cuadros tomó algo (p. ej. una lectura del lector):
/// se resta el valor del principio al del final.
int get drawnFrameCount => _drawnFrames;
int _drawnFrames = 0;

/// Reloj del motor en microsegundos: el mismo de los tiempos de cuadro.
int engineClockMicros() => developer.Timeline.now;

/// Número del cuadro que se está dibujando (dentro de un cuadro).
int currentFrameNumber() =>
    ui.PlatformDispatcher.instance.frameData.frameNumber;

final Map<int, List<void Function(int shownAtMicros)>> _waiting = {};

/// Avisa cuando el cuadro [frameNumber] ya quedó EN PANTALLA (pintado por
/// la tarjeta gráfica), con el instante en el reloj del motor. Es lo que
/// el usuario ve; el motor lo informa hasta un segundo después.
void whenFrameShown(int frameNumber, void Function(int shownAtMicros) then) {
  if (_waiting.length > 200) _waiting.clear(); // cuadros que nunca llegaron
  _waiting.putIfAbsent(frameNumber, () => []).add(then);
}

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
      metrics.recordFrame(
        t.totalSpan.inMicroseconds / 1000,
        buildMs: t.buildDuration.inMicroseconds / 1000,
        rasterMs: t.rasterDuration.inMicroseconds / 1000,
      );
      final waiting = _waiting.remove(t.frameNumber);
      if (waiting == null) continue;
      final shownAt = t.timestampInMicroseconds(ui.FramePhase.rasterFinish);
      for (final then in waiting) {
        then(shownAt);
      }
    }
  });
}
