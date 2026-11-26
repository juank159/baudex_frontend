// lib/app/core/diagnostics/paint_probe.dart
//
// Una capa propia (como `RepaintBoundary`) que además cuenta cuántas veces
// se pinta y de qué tamaño es. Sirve para dos cosas:
//  - aislar una parte de la pantalla: lo que cambia adentro no obliga a
//    repintar lo de afuera, y al revés;
//  - saber, en un equipo real y en release, qué partes se repintan con cada
//    tecla (la medición de Windows lee estos contadores).
// Contar cuesta una suma por pintada: nada medible.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Contadores de pintadas por nombre de capa.
class PaintCounters {
  PaintCounters._();

  static final Map<String, int> paints = {};

  /// Área (px²) de la última pintada de cada capa.
  static final Map<String, double> area = {};

  static void record(String name, Size size) {
    paints[name] = (paints[name] ?? 0) + 1;
    area[name] = size.width * size.height;
  }

  /// Copia de los contadores (para restar después).
  static Map<String, int> snapshot() => Map.of(paints);

  /// Capas pintadas desde [before], de la más pintada a la menos:
  /// `nombre ×veces (ancho²·alto en miles de px²)`.
  static String since(Map<String, int> before) {
    final rows = <(String, int)>[
      for (final e in paints.entries)
        if (e.value - (before[e.key] ?? 0) > 0) (e.key, e.value - (before[e.key] ?? 0)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    if (rows.isEmpty) return 'ninguna capa medida';
    return rows
        .map((r) => '${r.$1} ×${r.$2} (${((area[r.$1] ?? 0) / 1000).round()} mil px²)')
        .join(', ');
  }
}

/// Capa propia con contador. Úsese donde iría un `RepaintBoundary` en las
/// partes de una pantalla que conviene vigilar.
class PaintProbe extends SingleChildRenderObjectWidget {
  const PaintProbe({super.key, required this.name, super.child});

  final String name;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPaintProbe(name);

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderPaintProbe).name = name;
  }
}

class _RenderPaintProbe extends RenderProxyBox {
  _RenderPaintProbe(this.name);

  String name;

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    PaintCounters.record(name, size);
    super.paint(context, offset);
  }
}
