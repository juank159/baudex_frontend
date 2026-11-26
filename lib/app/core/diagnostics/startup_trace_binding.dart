// lib/app/core/diagnostics/startup_trace_binding.dart
//
// Le entrega a la línea de tiempo del arranque los tiempos reales de cada
// cuadro (armar en la app + pintar en la tarjeta gráfica). El motor los
// informa en tandas, una vez por segundo: no cuesta nada medible. Se quita
// solo cuando ya no hay ningún tramo midiendo.
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';

import 'startup_trace.dart';

bool _installed = false;

void _onTimings(List<ui.FrameTiming> timings) {
  final trace = StartupTrace.instance;
  for (final t in timings) {
    trace.recordFrame(
      buildMs: t.buildDuration.inMicroseconds / 1000,
      rasterMs: t.rasterDuration.inMicroseconds / 1000,
    );
  }
  if (!trace.measuring) {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _installed = false;
  }
}

/// Empieza un tramo ("al abrir", "tras iniciar sesión") y cuenta sus cuadros.
void startStartupPhase(String name) {
  StartupTrace.instance.startPhase(name);
  if (_installed) return;
  _installed = true;
  SchedulerBinding.instance.addTimingsCallback(_onTimings);
}
