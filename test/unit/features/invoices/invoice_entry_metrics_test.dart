import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:baudex_desktop/features/invoices/domain/price_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guessValueEntry (lo que se pinta en la misma tecla)', () {
    final index = ShortCodeIndex.build([('5000', 7)], complete: true);

    test('índice completo y al día: seguro', () {
      final g = guessValueEntry('3500', index);
      expect(g.existingLocalId, isNull);
      expect(g.certain, isTrue);
    });

    test('producto con ese código corto gana', () {
      expect(guessValueEntry('5000', index).existingLocalId, 7);
      expect(guessValueEntry('5000', index, stale: true).existingLocalId, 7);
    });

    test('sin índice, incompleto o pendiente: se pinta igual, por confirmar', () {
      for (final g in [
        guessValueEntry('3500', null),
        guessValueEntry('3500', ShortCodeIndex.build(const [], complete: false)),
        guessValueEntry('3500', index, stale: true),
      ]) {
        expect(g.existingLocalId, isNull);
        expect(g.certain, isFalse);
      }
    });
  });

  group('InvoiceEntryMetrics', () {
    test('resume normal, 95 % y peor; guarda solo las últimas', () {
      final m = InvoiceEntryMetrics(capacity: 100);
      for (var i = 1; i <= 150; i++) {
        m.record(EntryMetric.keyToOption, i.toDouble());
      }
      final s = m.summary(EntryMetric.keyToOption)!;
      expect(s.count, 150, reason: 'el total cuenta todas');
      expect(s.maxMs, 150);
      expect(s.lastMs, 150);
      expect(s.medianMs, closeTo(100, 1), reason: 'de las últimas 100 (51..150)');
      expect(m.summary(EntryMetric.enterToDialog), isNull);
    });

    test('el reporte dice el estado del índice y la sincronización en las lentas', () {
      final m = InvoiceEntryMetrics(now: () => DateTime(2026, 11, 23, 10));
      m.valueKeysUnconfirmed = 3;
      m.record(EntryMetric.keyToOption, 4);
      m.record(
        EntryMetric.enterToDialog,
        850,
        const EntryContext(
          indexLoaded: true,
          indexComplete: false,
          indexSize: 12,
          syncRunning: true,
          fullDownloadPending: true,
          queueSize: 41,
        ),
      );
      m.recordFrame(16);
      m.recordFrame(320);
      final text = m.report();
      expect(text, contains('por confirmar: 3'));
      expect(text, contains('Enter → diálogo del nombre: 1 veces'));
      expect(text, contains('índice INCOMPLETO (12)'));
      expect(text, contains('sync corriendo'));
      expect(text, contains('descarga completa pendiente'));
      expect(text, contains('cola 41'));
      expect(text, contains('de más de 200 ms: 1'));
      expect(text, contains('peor: 320 ms'));
    });

    test('sin muestras lo dice claro', () {
      expect(InvoiceEntryMetrics().report(),
          contains('todavía no se ha facturado'));
    });
  });

  group('Impresión del tiquete en el reporte', () {
    test('sin impresiones lo dice', () {
      final m = InvoiceEntryMetrics();
      expect(m.report(), contains('Impresión del tiquete'));
      expect(m.report(), contains('todavía no se ha impreso'));
    });

    test('resume por tipo de impresora y cuenta lentas y fallidas', () {
      final m = InvoiceEntryMetrics();
      for (final ms in [40.0, 60.0, 80.0]) {
        m.recordPrint('USB Windows (directo)', ms, buildMs: 5);
      }
      m.recordPrint('USB Windows (PowerShell; el directo falló: código 5)', 2600,
          buildMs: 6);
      m.recordPrint('Red', 5003, ok: false);
      m.recordPrint('Red', 30, buildMs: 4);

      final usb = m.printSummary('USB Windows (directo)')!;
      expect(usb.count, 3);
      expect(usb.medianMs, 60);
      expect(usb.maxMs, 80);
      expect(m.printFailures('Red'), 1);
      expect(m.printSummary('Red')!.count, 1); // la fallida no entra al tiempo

      final r = m.report();
      expect(r, contains('USB Windows (directo): 3 veces, normal 60 ms'));
      expect(r, contains('armar el tiquete: normal 5.0 ms'));
      expect(r, contains('PowerShell; el directo falló: código 5): 1 veces'));
      expect(r, contains('de 1000 ms o más: 1'));
      expect(r, contains('Red: 2 veces'));
      expect(r, contains('fallidas: 1 (última falla tras 5003 ms'));
    });

    test('reset borra también las impresiones', () {
      final m = InvoiceEntryMetrics()..recordPrint('Red', 30);
      m.reset();
      expect(m.printerKinds, isEmpty);
    });
  });
}
