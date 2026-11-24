import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/shared/services/subscription_validation_service.dart';
import 'package:baudex_desktop/app/shared/utils/subscription_error_handler.dart';
import 'package:baudex_desktop/features/subscriptions/domain/entities/subscription.dart';
import 'package:baudex_desktop/features/subscriptions/domain/rules/subscription_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regla: "vencida" solo si el servidor lo dijo o la fecha guardada ya pasó.
void main() {
  final now = DateTime(2026, 11, 23, 10);

  test('sin fecha no se puede afirmar que venció', () {
    expect(subscriptionEndDatePassed(null, now: now), isFalse);
    expect(subscriptionDaysRemaining(null, now: now), isNull);
    expect(
      subscriptionAlertLevel(explicitlyExpired: false, endDate: null, now: now),
      SubscriptionAlertLevel.normal,
    );
  });

  test('quedan horas: es el último día, no vencida', () {
    final end = now.add(const Duration(hours: 5));
    expect(subscriptionDaysRemaining(end, now: now), 1);
    expect(
      subscriptionAlertLevel(explicitlyExpired: false, endDate: end, now: now),
      SubscriptionAlertLevel.critical,
    );
  });

  test('la fecha ya pasó o el servidor lo dijo: vencida', () {
    final past = now.subtract(const Duration(minutes: 1));
    expect(subscriptionEndDatePassed(past, now: now), isTrue);
    expect(subscriptionDaysRemaining(past, now: now), 0);
    expect(
      subscriptionAlertLevel(explicitlyExpired: false, endDate: past, now: now),
      SubscriptionAlertLevel.expired,
    );
    expect(
      subscriptionAlertLevel(
          explicitlyExpired: true,
          endDate: now.add(const Duration(days: 30)),
          now: now),
      SubscriptionAlertLevel.expired,
    );
  });

  test('La Granada: vence el 1 de diciembre, hoy 23 de noviembre', () {
    final end = DateTime.utc(2026, 12, 1);
    expect(subscriptionDaysRemaining(end, now: now), greaterThan(7));
    expect(
      subscriptionAlertLevel(explicitlyExpired: false, endDate: end, now: now),
      SubscriptionAlertLevel.normal,
    );
  });

  test('la organización sin fecha de vencimiento no avisa "vencida"', () {
    final data = SubscriptionData(
      status: 'active',
      endDate: null,
      hasValidSubscription: false,
      isTrialExpired: false,
      planName: 'premium',
      source: 'controller',
    );
    expect(SubscriptionValidationService.alertLevelFor(data),
        SubscriptionAlertLevel.normal);
  });

  test('de varias copias locales vale la última que confirmó el servidor', () {
    final old = (sync: DateTime(2026, 10, 1), end: DateTime(2026, 11, 1));
    final cur = (sync: DateTime(2026, 11, 20), end: DateTime(2026, 12, 1));
    for (final list in [
      [old, cur],
      [cur, old],
    ]) {
      expect(
        pickCurrentSubscription(list,
            lastSyncAt: (s) => s.sync, endDate: (s) => s.end),
        cur,
      );
    }
  });

  group('un 403 solo es de suscripción si el servidor lo dice', () {
    test('mensajes del servidor sobre la suscripción', () {
      for (final m in [
        'Tu suscripción ha expirado. Para continuar creando facturas, necesitas renovar tu suscripción.',
        'Su suscripción ha expirado. Por favor, actualice su plan para continuar creando productos.',
        'No tienes una suscripción activa.',
        'SUBSCRIPTION_EXPIRED',
      ]) {
        expect(
          SubscriptionErrorHandler.isSubscriptionFailure(
              ServerFailure(m, code: 403)),
          isTrue,
          reason: m,
        );
      }
    });

    test('permisos, dispositivo, sesión vencida y límite de intentos: no', () {
      for (final f in const [
        ServerFailure('No tienes permisos para realizar esta acción', code: 403),
        ServerFailure('Acceso prohibido.', code: 403),
        ServerFailure('Este dispositivo no está autorizado', code: 403),
        ServerFailure('Unauthorized', code: 401),
        ServerFailure('ThrottlerException: Too Many Requests', code: 429),
        ServerFailure('Error interno del servidor.', code: 500),
      ]) {
        expect(SubscriptionErrorHandler.isSubscriptionFailure(f), isFalse,
            reason: f.message);
        expect(SubscriptionErrorHandler.handleFailure(f), isFalse,
            reason: f.message);
      }
    });
  });
}
