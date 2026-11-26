// El reporte de diagnóstico nunca queda en blanco: si una sección falla,
// sale el resto y una línea que dice cuál no está disponible.
import 'package:baudex_desktop/features/diagnostics/domain/report_sections.dart';
import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reporte por secciones', () {
    test('todas bien: se escriben en orden', () {
      final text = buildSectionedReport([
        ('uno', (b) => b.writeln('A')),
        ('dos', (b) => b.writeln('B')),
      ]);
      expect(text, 'A\nB\n');
    });

    test('una sección falla: queda lo que alcanzó a escribir, el aviso y '
        'las demás', () {
      final text = buildSectionedReport([
        ('uno', (b) => b.writeln('A')),
        (
          'Rendimiento al facturar',
          (b) {
            b.write('a medias');
            throw StateError('No element\nsegunda línea');
          },
        ),
        ('tres', (b) => b.writeln('C')),
      ]);
      expect(
          text,
          'A\na medias\n'
          'Sección "Rendimiento al facturar" no disponible: Bad state: No element\n'
          'C\n');
    });

    test('todas fallan: igual hay texto', () {
      final text = buildSectionedReport([
        ('uno', (_) => throw ArgumentError('x')),
        ('dos', (_) => <int>[].first),
      ]);
      expect(text.trim().split('\n'), hasLength(2));
      expect(text, contains('Sección "uno" no disponible'));
      expect(text, contains('Sección "dos" no disponible'));
    });

    test('un error con texto larguísimo se recorta', () {
      final text = buildSectionedReport([
        ('uno', (_) => throw Exception('x' * 5000)),
      ]);
      expect(text.length, lessThan(400));
    });
  });

  group('rendimiento al facturar en cada estado', () {
    void expectComplete(String report) {
      expect(report, startsWith('Rendimiento al facturar'));
      expect(report, contains('Teclas con un valor'));
      expect(report, contains('Cuadros de pantalla'));
      expect(report, contains('Impresión del tiquete'));
      expect(report, isNot(contains('no disponible')));
    }

    test('recién abierta la app, sin ninguna lectura', () {
      expectComplete(InvoiceEntryMetrics().report());
    });

    test('lecturas directas pero sin cuadros ni tiempos de tecla', () {
      final m = InvoiceEntryMetrics()
        ..recordScan(keys: 13, avgGapMs: 1.8, frames: 0, burst: true, direct: true)
        ..recordScan(keys: 1, avgGapMs: null, frames: 0, burst: true, direct: true)
        ..recordScan(keys: 0, avgGapMs: null, frames: 0, burst: false);
      final report = m.report();
      expectComplete(report);
      expect(report, contains('Lecturas con el lector: 3 (directas por teclas, '
          'sin pasar por la caja: 2'));
    });

    test('solo lecturas sin tiempos (cámara): sin línea de "entre teclas"', () {
      final m = InvoiceEntryMetrics()
        ..recordScan(keys: 0, avgGapMs: null, frames: 0, burst: false);
      final report = m.report();
      expectComplete(report);
      expect(report, isNot(contains('Entre teclas')));
    });

    test('presentaciones sin descargar e índice con cargas fallidas', () {
      final m = InvoiceEntryMetrics()
        ..presentationsFromServer = 26
        ..indexLoadFailures = 3
        ..lastIndexLoadError = null;
      final report = m.report();
      expectComplete(report);
      expect(report, contains('presentaciones se pidieron al servidor'));
      expect(report, contains('FALLARON: 3 (último error: null)'));
    });

    test('todas las métricas con datos, cuadros con y sin detalle, valores '
        'raros (infinito, no-número, negativos)', () {
      final m = InvoiceEntryMetrics();
      for (final metric in EntryMetric.values) {
        m
          ..record(metric, 248, const EntryContext())
          ..record(metric, double.nan)
          ..record(metric, double.infinity)
          ..record(metric, -5);
      }
      m
        ..recordFrame(20, buildMs: 5, rasterMs: 6)
        ..recordFrame(300)
        ..recordFrame(double.nan, buildMs: double.nan, rasterMs: double.infinity)
        ..recordScan(
            keys: 13, avgGapMs: double.nan, frames: -1, burst: true, direct: true)
        ..recordPrint('USB', 1200, buildMs: 20)
        ..recordPrint('Red', double.infinity, ok: false);
      expectComplete(m.report());
    });

    test('después de reiniciar las métricas', () {
      final m = InvoiceEntryMetrics()
        ..recordScan(keys: 13, avgGapMs: 2, frames: 1, burst: true, direct: true)
        ..record(EntryMetric.scanFirstKeyToSeen, 45)
        ..reset();
      final report = m.report();
      expectComplete(report);
      expect(report, isNot(contains('Lecturas con el lector')));
    });
  });
}
