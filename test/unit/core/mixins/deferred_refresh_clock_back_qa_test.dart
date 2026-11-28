// QA 1.0.25 — Recarga por turnos (5c63f51).
//
// El turno se calcula con la hora de pared (DateTime.now). Si el reloj de
// Windows se atrasa (sincronización de hora, el cajero corrige la hora,
// cambio de zona) DESPUÉS de una tanda, el "próximo turno" guardado queda en
// el futuro y todas las recargas aplazadas esperan esa diferencia: las
// listas (facturas, tablero, créditos…) quedan viejas ese tiempo.
//
// Esta prueba FALLA con el código actual: muestra la espera de ~1 h.
// Arreglo propuesto: medir con un Stopwatch monotónico, o reiniciar el turno
// si el guardado queda más lejos que deferredFirstDelay + N * deferredGap.
import 'package:baudex_desktop/app/core/mixins/sync_auto_refresh_mixin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(SyncAutoRefreshMixin.debugResetDeferredSlots);

  test('si el reloj se atrasa 1 h, la siguiente recarga aplazada no espera 1 h', () {
    final now = DateTime(2026, 11, 28, 10);
    SyncAutoRefreshMixin.claimDeferredSlot(now: now);
    // El reloj del equipo se corrige una hora hacia atrás.
    final afterClockFix = now.subtract(const Duration(hours: 1));
    final delay = SyncAutoRefreshMixin.claimDeferredSlot(now: afterClockFix);
    // Con 13 pantallas la última no debería pasar de unos 8 s.
    expect(delay, lessThan(const Duration(seconds: 10)),
        reason: 'la recarga quedó aplazada ${delay.inMinutes} min por el reloj');
  });
}
