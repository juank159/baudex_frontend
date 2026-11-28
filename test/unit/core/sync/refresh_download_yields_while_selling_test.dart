// Tras instalar una versión la app vuelve a bajar todos los módulos en
// segundo plano. Esa re-descarga no trae nada urgente: mientras el cajero
// está facturando debe ceder el disco a la venta mucho más que una
// descarga normal (que no puede quedarse sin terminar).
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la re-descarga tras actualizar cede más mientras se factura', () {
    final yielding = FullSyncService.pageMaxWait(refresh: true, selling: true);
    final normal = FullSyncService.pageMaxWait(refresh: false, selling: true);
    expect(yielding, greaterThan(normal));
    expect(yielding, const Duration(seconds: 45));
  });

  test('la descarga normal y la re-descarga fuera de facturación no cambian', () {
    const before = Duration(seconds: 8);
    expect(FullSyncService.pageMaxWait(refresh: false, selling: true), before);
    expect(FullSyncService.pageMaxWait(refresh: false, selling: false), before);
    expect(FullSyncService.pageMaxWait(refresh: true, selling: false), before);
  });
}
