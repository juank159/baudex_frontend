// lib/features/invoices/domain/scan_burst_detector.dart
//
// ¿Las teclas vienen del lector de código de barras o de una persona?
// Sin Flutter ni GetX: se prueba sola.

/// Detecta la ráfaga del lector por el tiempo entre teclas.
///
/// El lector (pistola USB que escribe como teclado) manda un dígito cada
/// 5–20 ms; una persona rápida en el teclado numérico, uno cada 80–150 ms.
/// - Una tecla que llega a [burstGap] o menos de la anterior: es ráfaga.
/// - Ya en ráfaga, se sostiene mientras las teclas sigan llegando a
///   [holdGap] o menos (un cuadro lento de la pantalla puede separar dos
///   teclas del lector más de [burstGap]).
/// - Una pausa mayor termina la tanda: la tecla siguiente empieza otra y,
///   sola, nunca es ráfaga (la primera tecla siempre se trata como manual).
class ScanBurstDetector {
  ScanBurstDetector({
    this.burstGap = const Duration(milliseconds: 35),
    this.holdGap = const Duration(milliseconds: 80),
  });

  final Duration burstGap;
  final Duration holdGap;

  Duration? _first;
  Duration? _last;
  bool _inBurst = false;
  int _keys = 0;

  /// ¿La tanda actual es una ráfaga del lector?
  bool get inBurst => _inBurst;

  /// Teclas de la tanda actual.
  int get keys => _keys;

  /// Milisegundos promedio entre teclas de la tanda actual (`null` con
  /// menos de dos teclas).
  double? get averageGapMs {
    final first = _first, last = _last;
    if (first == null || last == null || _keys < 2) return null;
    return (last - first).inMicroseconds / 1000 / (_keys - 1);
  }

  /// Llegó una tecla en el instante [now] (reloj que solo avanza).
  /// Devuelve si esa tecla es parte de una ráfaga.
  bool addKey(Duration now) {
    final last = _last;
    final gap = last == null ? null : now - last;
    final continues = gap != null &&
        !gap.isNegative &&
        (gap <= burstGap || (_inBurst && gap <= holdGap));
    if (!continues) {
      _first = now;
      _keys = 0;
      _inBurst = false;
    } else if (gap <= burstGap) {
      _inBurst = true;
    }
    _last = now;
    _keys++;
    return _inBurst;
  }

  /// La caja se vació, se pegó un texto o se confirmó: empezar de cero.
  void reset() {
    _first = null;
    _last = null;
    _inBurst = false;
    _keys = 0;
  }
}
