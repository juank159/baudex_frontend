// Al salir de facturación, las ~13 pantallas que esperaban para recargar lo
// hacían todas en el mismo instante, justo mientras se abría la pantalla
// nueva (el menú se quedaba pegado). Ahora toman turno.
import 'package:baudex_desktop/app/core/mixins/sync_auto_refresh_mixin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(SyncAutoRefreshMixin.debugResetDeferredSlots);

  test('13 recargas aplazadas: la primera espera a que la pantalla nueva se vea '
      'y ninguna coincide con otra', () {
    final now = DateTime(2026, 11, 28, 10);
    final delays = [
      for (var i = 0; i < 13; i++) SyncAutoRefreshMixin.claimDeferredSlot(now: now),
    ];
    expect(delays.first, SyncAutoRefreshMixin.deferredFirstDelay);
    for (var i = 1; i < delays.length; i++) {
      expect(delays[i] - delays[i - 1], SyncAutoRefreshMixin.deferredGap);
    }
    expect(delays.toSet(), hasLength(13));
  });

  test('pasada la tanda, la siguiente salida de facturación empieza de nuevo', () {
    final now = DateTime(2026, 11, 28, 10);
    SyncAutoRefreshMixin.claimDeferredSlot(now: now);
    SyncAutoRefreshMixin.claimDeferredSlot(now: now);
    final later = now.add(const Duration(minutes: 5));
    expect(SyncAutoRefreshMixin.claimDeferredSlot(now: later),
        SyncAutoRefreshMixin.deferredFirstDelay);
  });
}
