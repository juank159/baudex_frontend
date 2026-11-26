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

/// Qué hacer con un dígito que llega al buscador con la caja vacía.
enum ScanKeyAction {
  /// Se retiene (puede ser el principio de una lectura del lector).
  hold,

  /// Era una persona: lo retenido y este dígito entran YA a la caja.
  releaseAll,

  /// La ráfaga anterior ya había terminado (lector sin Enter): lo retenido
  /// entra a la caja, y este dígito se trata después como uno nuevo.
  releaseHeldFirst,
}

/// Retención de los dígitos del lector, decidida SOLO por la hora de cada
/// tecla. Sin Flutter ni temporizadores: se prueba sola.
///
/// - El primer dígito se retiene.
/// - El segundo decide: si llegó a [firstGap] o menos del primero es el
///   lector (se sigue reteniendo); si llegó después es una PERSONA y los
///   dos entran a la caja en ese mismo momento. La decisión no depende de
///   que un temporizador venza a tiempo: en un equipo lento los
///   temporizadores vencen tarde, y antes un "700" tecleado a mano se
///   quedaba retenido como si fuera una lectura.
/// - Ya en ráfaga, las teclas siguen reteniéndose mientras lleguen a
///   [burstGap] o menos.
/// - [expired] dice si ya pasó el tiempo de espera (para soltar un dígito
///   solo, o una lectura sin Enter); quien lo use debe preguntarlo en cada
///   oportunidad (temporizador, cuadro, tecla soltada), no solo en una.
class ScanKeyHold {
  ScanKeyHold({
    this.firstGap = const Duration(milliseconds: 60),
    this.burstGap = const Duration(milliseconds: 80),
    this.loneKeyHold = const Duration(milliseconds: 32),
  });

  /// Máximo entre la 1.ª y la 2.ª tecla para que sea el lector. Una persona
  /// teclea dígitos seguidos a 80–150 ms; el lector, a 1–30 ms (se deja
  /// margen por si un cuadro lento separa sus dos primeras teclas).
  final Duration firstGap;

  /// Ya en ráfaga: máximo entre teclas.
  final Duration burstGap;

  /// Cuánto se retiene un dígito solo esperando otro.
  final Duration loneKeyHold;

  final List<String> _held = [];
  Duration _first = Duration.zero;
  Duration _last = Duration.zero;

  bool get isEmpty => _held.isEmpty;
  bool get isNotEmpty => _held.isNotEmpty;
  int get length => _held.length;

  /// Dos o más teclas retenidas: es una ráfaga del lector.
  bool get inBurst => _held.length >= 2;

  Duration get firstKeyAt => _first;

  /// Milisegundos promedio entre las teclas retenidas (`null` con una).
  double? get averageGapMs => _held.length < 2
      ? null
      : (_last - _first).inMicroseconds / 1000 / (_held.length - 1);

  /// Llegó el dígito [digit] a la hora [at]. Con [ScanKeyAction.hold] ya
  /// quedó retenido; con las otras dos NO se guarda: quien llama saca lo
  /// retenido con [take] y decide qué hacer con este dígito.
  ScanKeyAction addDigit(String digit, Duration at) {
    if (_held.isEmpty) {
      _first = _last = at;
      _held.add(digit);
      return ScanKeyAction.hold;
    }
    final gap = at - _last;
    final limit = _held.length == 1 ? firstGap : burstGap;
    if (!gap.isNegative && gap <= limit) {
      _last = at;
      _held.add(digit);
      return ScanKeyAction.hold;
    }
    return _held.length == 1
        ? ScanKeyAction.releaseAll
        : ScanKeyAction.releaseHeldFirst;
  }

  /// ¿Ya pasó la espera desde la última tecla retenida?
  bool expired(Duration now) {
    if (_held.isEmpty) return false;
    final waited = now - _last;
    return waited >= (_held.length == 1 ? loneKeyHold : burstGap);
  }

  /// Cuánto falta para que venza la espera (cero si ya venció).
  Duration remaining(Duration now) {
    if (_held.isEmpty) return Duration.zero;
    final left =
        (_held.length == 1 ? loneKeyHold : burstGap) - (now - _last);
    return left.isNegative ? Duration.zero : left;
  }

  /// Saca los dígitos retenidos y queda vacía.
  String take() {
    final digits = _held.join();
    _held.clear();
    return digits;
  }
}
