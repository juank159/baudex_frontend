import 'package:get/get.dart';

import '../../core/storage/secure_storage_service.dart';
import '../../../features/subscriptions/domain/entities/subscription.dart';

/// Fuente única de verdad para "¿puedo mostrar un aviso de suscripción
/// ahora mismo?".
///
/// Antes había 8 puntos en la app que disparaban diálogos de suscripción
/// sin coordinarse — el cliente veía hasta 3 avisos seguidos al intentar
/// crear varios productos con suscripción expirada. Este servicio
/// resuelve eso aplicando dos reglas estrictas:
///
/// **Regla 1 — Sólo avisar cuando queda poco tiempo.**
/// Avisos `warning` y `critical` se muestran únicamente cuando
/// `daysUntilExpiration <= 1`. Antes de eso el usuario tiene tiempo de
/// sobra y los recordatorios son ruido.
///
/// **Regla 2 — Cooldown de 2 horas entre avisos de un mismo nivel.**
/// Si ya mostramos el aviso "warning" hace 30 min, no lo repetimos hasta
/// que pasen 2 horas — independiente de cuántos puntos de la app
/// intenten dispararlo. El cooldown se PERSISTE en `SecureStorage`, así
/// que si el usuario cierra y vuelve a abrir la app, el cooldown sigue
/// vigente (antes la flag vivía solo en memoria y se reseteaba con
/// cada apertura).
///
/// Excepción: `SubscriptionAlertLevel.expired` no tiene cooldown — es
/// bloqueante, queremos que el usuario lo vea siempre que entre a la
/// app, pero sólo una vez por sesión (flag en memoria).
class SubscriptionAlertService extends GetxService {
  static const String _kPrefix = 'sub_alert_last_shown_';
  static const Duration _cooldown = Duration(hours: 2);
  static const int _daysThreshold = 1;

  /// Flag por sesión para "expired" — no persistido, se resetea al
  /// abrir la app. Eso es deliberado: al usuario expirado siempre le
  /// mostramos el dialog la primera vez que entra a la app.
  bool _expiredShownThisSession = false;

  SecureStorageService get _storage => Get.find<SecureStorageService>();

  /// Consulta si se puede mostrar un aviso de `level`. Aplica
  /// el threshold de días + cooldown persistente.
  ///
  /// El caller debe pasar el `daysUntilExpiration` actual de la
  /// suscripción para que apliquemos el filtro de "≤1 día".
  Future<bool> canShow({
    required SubscriptionAlertLevel level,
    required int daysUntilExpiration,
  }) async {
    // normal = sin alerta. Nunca mostrar nada.
    if (level == SubscriptionAlertLevel.normal) return false;

    // expired = bloqueante. Una vez por sesión.
    if (level == SubscriptionAlertLevel.expired) {
      return !_expiredShownThisSession;
    }

    // warning/critical: solo cuando queda ≤ 1 día de gracia.
    // Es la regla explícita del cliente — antes de eso, silencio.
    if (daysUntilExpiration > _daysThreshold) return false;

    // Cooldown de 2 horas entre avisos del mismo nivel.
    final lastShown = await _readLastShown(level);
    if (lastShown == null) return true;
    return DateTime.now().difference(lastShown) >= _cooldown;
  }

  /// Marca el aviso como mostrado. Lo guarda en storage para
  /// persistir el cooldown entre sesiones (excepto expired, que es
  /// sólo flag en memoria).
  Future<void> markShown(SubscriptionAlertLevel level) async {
    if (level == SubscriptionAlertLevel.normal) return;
    if (level == SubscriptionAlertLevel.expired) {
      _expiredShownThisSession = true;
      return;
    }
    await _storage.write(
      _keyFor(level),
      DateTime.now().toIso8601String(),
    );
  }

  /// Limpia todos los cooldowns guardados. Útil cuando la suscripción
  /// se renueva — para que el siguiente vencimiento empiece con
  /// reloj limpio en vez de heredar el cooldown viejo.
  Future<void> resetAll() async {
    _expiredShownThisSession = false;
    for (final l in SubscriptionAlertLevel.values) {
      if (l == SubscriptionAlertLevel.normal) continue;
      if (l == SubscriptionAlertLevel.expired) continue;
      try {
        await _storage.write(_keyFor(l), '');
      } catch (_) {
        // ignorar si no existía
      }
    }
  }

  /// Helper: combo de `canShow` + `markShown`. Patrón típico para
  /// callers que quieren disparar el aviso si está permitido.
  /// Retorna `true` si el aviso DEBE mostrarse ahora (y queda marcado);
  /// `false` si se debe omitir.
  Future<bool> tryShow({
    required SubscriptionAlertLevel level,
    required int daysUntilExpiration,
  }) async {
    final allowed = await canShow(
      level: level,
      daysUntilExpiration: daysUntilExpiration,
    );
    if (allowed) await markShown(level);
    return allowed;
  }

  Future<DateTime?> _readLastShown(SubscriptionAlertLevel level) async {
    try {
      final raw = await _storage.read(_keyFor(level));
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  String _keyFor(SubscriptionAlertLevel level) => '$_kPrefix${level.name}';
}
