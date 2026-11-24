// lib/features/subscriptions/domain/rules/subscription_rules.dart
//
// Reglas puras para decidir si una suscripción está vencida.
//
// REGLA DE LA CASA: solo se dice "vencida" cuando el servidor lo dijo de forma
// explícita o cuando la fecha guardada de verdad ya pasó. Un dato ausente, un
// error de red, una sesión vencida (401) o un límite de intentos (429) NUNCA
// cuentan como vencida.

import '../entities/subscription.dart' show SubscriptionAlertLevel;

/// `true` solo si hay fecha y ya pasó. Sin fecha no se puede afirmar nada.
bool subscriptionEndDatePassed(DateTime? endDate, {DateTime? now}) {
  if (endDate == null) return false;
  return (now ?? DateTime.now()).isAfter(endDate);
}

/// Días que faltan, contados igual que el servidor (hacia arriba): si quedan
/// 3 horas, queda 1 día; 0 solo cuando la fecha ya pasó. `null` sin fecha.
int? subscriptionDaysRemaining(DateTime? endDate, {DateTime? now}) {
  if (endDate == null) return null;
  final left = endDate.difference(now ?? DateTime.now());
  if (left <= Duration.zero) return 0;
  return (left.inSeconds / Duration.secondsPerDay).ceil();
}

/// Nivel de aviso. [explicitlyExpired]: el servidor (o el estado guardado que
/// envió el servidor) dice que está vencida, cancelada o suspendida.
SubscriptionAlertLevel subscriptionAlertLevel({
  required bool explicitlyExpired,
  required DateTime? endDate,
  DateTime? now,
}) {
  if (explicitlyExpired || subscriptionEndDatePassed(endDate, now: now)) {
    return SubscriptionAlertLevel.expired;
  }
  final days = subscriptionDaysRemaining(endDate, now: now);
  if (days == null) return SubscriptionAlertLevel.normal; // dato ausente
  if (days <= 3) return SubscriptionAlertLevel.critical;
  if (days <= 7) return SubscriptionAlertLevel.warning;
  return SubscriptionAlertLevel.normal;
}

/// ¿El servidor rechazó la petición POR LA SUSCRIPCIÓN? Un 403 también llega
/// por permisos, por dispositivo no autorizado, etc.: solo es de suscripción
/// si el mensaje (o el código `SUBSCRIPTION_*`) lo dice.
bool isSubscriptionRejectionMessage(String? message) {
  if (message == null) return false;
  final m = message.toLowerCase();
  return m.contains('suscripci') || m.contains('subscription');
}

/// De varias copias locales, la que vale: la última que confirmó el servidor.
/// (Cada renovación crea una suscripción NUEVA en el servidor; las viejas
/// quedaban guardadas y se leía la primera, o sea la más antigua.)
T? pickCurrentSubscription<T>(
  Iterable<T> all, {
  required DateTime? Function(T) lastSyncAt,
  required DateTime Function(T) endDate,
}) {
  T? best;
  for (final s in all) {
    if (best == null) {
      best = s;
      continue;
    }
    final a = lastSyncAt(s), b = lastSyncAt(best);
    final cmp = (a == null || b == null)
        ? (a == null ? (b == null ? 0 : -1) : 1)
        : a.compareTo(b);
    if (cmp > 0 || (cmp == 0 && endDate(s).isAfter(endDate(best)))) best = s;
  }
  return best;
}
