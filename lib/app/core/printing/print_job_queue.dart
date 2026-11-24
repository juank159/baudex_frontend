// lib/app/core/printing/print_job_queue.dart
//
// Cola de impresión: los tiquetes salen uno detrás de otro, en orden, sin
// rechazar el segundo mientras sale el primero. Quien manda a imprimir no
// tiene que esperar (puede seguir facturando) y aun así recibe el resultado
// si lo quiere. Sin Flutter ni GetX.
import 'dart:async';

class PrintJobQueue {
  PrintJobQueue({this.onPendingChanged});

  /// Avisa cuántos trabajos hay sin terminar (el que sale y los que esperan).
  final void Function(int pending)? onPendingChanged;

  Future<void> _tail = Future<void>.value();
  int _pending = 0;

  int get pending => _pending;
  bool get isBusy => _pending > 0;

  /// Encola [job]. Corre cuando terminen los anteriores, aunque alguno falle.
  Future<T> add<T>(Future<T> Function() job) {
    _pending++;
    onPendingChanged?.call(_pending);
    final done = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        done.complete(await job());
      } catch (e, s) {
        done.completeError(e, s);
      } finally {
        _pending--;
        onPendingChanged?.call(_pending);
      }
    });
    return done.future;
  }
}
