// Regla pura: ¿las teclas vienen del lector o de una persona?
import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:baudex_desktop/features/invoices/domain/scan_burst_detector.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/invoice_shortcut_keys.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Duration ms(int v) => Duration(milliseconds: v);

void main() {
  group('ScanBurstDetector', () {
    test('la primera tecla nunca es ráfaga', () {
      final d = ScanBurstDetector();
      expect(d.addKey(ms(1000)), isFalse);
      expect(d.keys, 1);
      expect(d.averageGapMs, isNull);
    });

    test('lector: 13 teclas cada 10 ms son ráfaga desde la segunda', () {
      final d = ScanBurstDetector();
      final seen = [for (var i = 0; i < 13; i++) d.addKey(ms(500 + i * 10))];
      expect(seen.first, isFalse);
      expect(seen.skip(1), everyElement(isTrue));
      expect(d.keys, 13);
      expect(d.averageGapMs, closeTo(10, 0.001));
    });

    test('lector lento (20 ms) y rápido (5 ms) también', () {
      for (final gap in [5, 20, 35]) {
        final d = ScanBurstDetector();
        d.addKey(ms(0));
        expect(d.addKey(ms(gap)), isTrue, reason: '$gap ms');
      }
    });

    test('persona: teclas cada 120 ms (o 60 ms, muy rápido) nunca son ráfaga',
        () {
      for (final gap in [36, 60, 120, 400]) {
        final d = ScanBurstDetector();
        for (var i = 0; i < 8; i++) {
          expect(d.addKey(ms(i * gap)), isFalse, reason: '$gap ms, tecla $i');
          expect(d.keys, 1, reason: 'cada tecla empieza su tanda');
        }
      }
    });

    test('en ráfaga, un cuadro lento (hasta 80 ms) no la corta', () {
      final d = ScanBurstDetector();
      d.addKey(ms(0));
      expect(d.addKey(ms(10)), isTrue);
      expect(d.addKey(ms(80)), isTrue, reason: '70 ms después, sigue');
      expect(d.addKey(ms(160)), isTrue, reason: '80 ms justos');
      expect(d.keys, 4);
    });

    test('una pausa larga termina la ráfaga: la tecla siguiente es manual', () {
      final d = ScanBurstDetector();
      d.addKey(ms(0));
      d.addKey(ms(10));
      d.addKey(ms(20));
      expect(d.addKey(ms(101)), isFalse, reason: '81 ms después');
      expect(d.inBurst, isFalse);
      expect(d.keys, 1);
      // Y una persona tecleando justo después de un escaneo no hereda nada.
      expect(d.addKey(ms(221)), isFalse);
    });

    test('dos teclas casi juntas de una persona y luego ritmo normal', () {
      final d = ScanBurstDetector();
      d.addKey(ms(0));
      expect(d.addKey(ms(25)), isTrue, reason: 'dos dedos a la vez');
      expect(d.addKey(ms(150)), isFalse, reason: 'vuelve a ser manual');
    });

    test('reset y reloj que retrocede empiezan de cero', () {
      final d = ScanBurstDetector();
      d.addKey(ms(100));
      d.addKey(ms(110));
      d.reset();
      expect(d.keys, 0);
      expect(d.inBurst, isFalse);
      expect(d.addKey(ms(115)), isFalse, reason: 'tras reset no hay anterior');
      expect(d.addKey(ms(90)), isFalse, reason: 'reloj hacia atrás');
    });
  });

  group('dígito suelto (los manejadores de atajos salen de una vez)', () {
    test('dígitos de la fila y del teclado numérico, sin modificador', () {
      for (final key in [
        LogicalKeyboardKey.digit0,
        LogicalKeyboardKey.digit7,
        LogicalKeyboardKey.numpad3,
        LogicalKeyboardKey.numpad9,
      ]) {
        expect(isPlainDigitKey(key, modifierPressed: false), isTrue);
      }
    });

    test('con Ctrl el dígito SÍ es atajo (Ctrl+1…9 suma cantidad)', () {
      expect(
          isPlainDigitKey(LogicalKeyboardKey.digit2, modifierPressed: true),
          isFalse);
    });

    test('Enter, flechas, letras, + y - siguen pasando por los atajos', () {
      for (final key in [
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.keyT,
        LogicalKeyboardKey.add,
        LogicalKeyboardKey.numpadAdd,
        LogicalKeyboardKey.minus,
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.home,
        LogicalKeyboardKey.delete,
      ]) {
        expect(isPlainDigitKey(key, modifierPressed: false), isFalse,
            reason: key.debugName);
      }
    });
  });

  group('lecturas en el reporte de diagnóstico', () {
    test('cuenta lecturas, ráfagas, ms entre teclas y cuadros por lectura', () {
      final m = InvoiceEntryMetrics();
      expect(m.report(), isNot(contains('Lecturas con el lector')));
      m.recordScan(keys: 13, avgGapMs: 10, frames: 4, burst: true);
      m.recordScan(keys: 13, avgGapMs: 30, frames: 13, burst: true);
      m.recordScan(keys: 13, avgGapMs: 12, frames: 5, burst: true);
      // Cámara o texto pegado: cuenta la lectura, sin tiempos.
      m.recordScan(keys: 0, avgGapMs: null, frames: 0, burst: false);
      m.scanKeysNotRedrawn = 18;
      m.record(EntryMetric.scanEnterToLine, 42);
      expect(m.scans, 4);
      expect(m.scansAsBurst, 3);
      expect(m.scanGapMs, (12.0, 30.0));
      expect(m.scanFrames, (5.0, 13.0));
      final report = m.report();
      expect(report, contains('Lecturas con el lector: 4 (directas por teclas, sin pasar '
          'por la caja: 0; reconocidas como ráfaga: 3; '
          'teclas que no redibujaron el buscador: 18)'));
      expect(report, contains('Entre teclas: normal 12 ms, peor 30 ms'));
      expect(report, contains('Cuadros de pantalla por lectura: normal 5, peor 13'));
      expect(report, contains('Lector: Enter → línea en la factura: 1 veces'));
      m.reset();
      expect(m.scans, 0);
      expect(m.scanGapMs, isNull);
    });
  });
}
