// lib/app/shared/services/subscription_offline_policy.dart

import 'package:get/get.dart';

import '../../../features/subscriptions/domain/entities/subscription.dart';
import '../../../features/subscriptions/domain/entities/subscription_enums.dart';
import '../../../features/subscriptions/presentation/controllers/subscription_controller.dart';

/// Servicio para manejar la politica de suscripciones en modo offline
///
/// Define reglas para:
/// - Periodo de gracia (grace period) cuando la suscripcion expira offline
/// - Que operaciones estan permitidas durante el periodo de gracia
/// - Validacion de acciones considerando el estado offline
class SubscriptionOfflinePolicy extends GetxService {
  /// Dias de gracia despues de que expire la suscripcion offline
  static const int gracePeriodDays = 3;

  /// Si el modo de solo lectura esta activo durante el periodo de gracia
  static const bool readOnlyDuringGrace = true;

  /// Acciones que siempre estan permitidas en modo offline
  static const List<String> alwaysAllowedOfflineActions = [
    'view',
    'read',
    'list',
    'search',
    'filter',
  ];

  /// Acciones de solo lectura permitidas durante periodo de gracia
  static const List<String> gracePeriodAllowedActions = [
    'view',
    'read',
    'list',
    'search',
    'filter',
    'export_pdf', // Permitir exportar lo que ya tienen
  ];

  /// Acciones de escritura bloqueadas durante periodo de gracia
  static const List<String> gracePeriodBlockedActions = [
    'create',
    'update',
    'delete',
    'create_product',
    'create_customer',
    'create_invoice',
    'create_expense',
    'create_user',
  ];

  /// Validar si una accion esta permitida considerando el estado offline
  SubscriptionValidationResult validateAction(
    String action,
    Subscription? cachedSubscription, {
    bool isOffline = false,
  }) {
    // Si no hay suscripcion cacheada
    if (cachedSubscription == null) {
      return SubscriptionValidationResult(
        allowed: false,
        reason: 'No hay informacion de suscripcion disponible. Conectate para validar.',
        isGracePeriod: false,
      );
    }

    // Si la suscripcion esta activa y no ha expirado
    if (cachedSubscription.isActive && !cachedSubscription.isExpired) {
      // Verificar si la accion esta permitida por el plan
      if (!cachedSubscription.canPerformAction(action)) {
        return SubscriptionValidationResult(
          allowed: false,
          reason: 'Esta accion no esta disponible en tu plan ${cachedSubscription.planDisplayName}',
          isGracePeriod: false,
        );
      }

      return SubscriptionValidationResult(
        allowed: true,
        isGracePeriod: false,
      );
    }

    // Si la suscripcion ha expirado
    if (cachedSubscription.isExpired) {
      // Verificar si estamos en periodo de gracia
      final gracePeriodEnd = cachedSubscription.endDate.add(
        const Duration(days: gracePeriodDays),
      );
      final isInGrace = DateTime.now().isBefore(gracePeriodEnd);
      final daysRemaining = gracePeriodEnd.difference(DateTime.now()).inDays;

      if (isInGrace) {
        // En periodo de gracia - verificar si la accion esta permitida
        if (_isActionAllowedInGracePeriod(action)) {
          return SubscriptionValidationResult(
            allowed: true,
            reason: 'Suscripcion expirada - Periodo de gracia activo',
            isGracePeriod: true,
            daysRemaining: daysRemaining,
          );
        }

        return SubscriptionValidationResult(
          allowed: false,
          reason: 'Solo lectura durante el periodo de gracia. '
              'Te quedan $daysRemaining dias para renovar.',
          isGracePeriod: true,
          daysRemaining: daysRemaining,
        );
      }

      // Periodo de gracia terminado
      return SubscriptionValidationResult(
        allowed: false,
        reason: 'Tu suscripcion ha expirado. Renueva para continuar usando la aplicacion.',
        isGracePeriod: false,
      );
    }

    // Si la suscripcion esta suspendida o cancelada
    if (cachedSubscription.status == SubscriptionStatus.suspended) {
      return SubscriptionValidationResult(
        allowed: false,
        reason: 'Tu suscripcion esta suspendida. Contacta soporte para reactivarla.',
        isGracePeriod: false,
      );
    }

    if (cachedSubscription.status == SubscriptionStatus.cancelled) {
      return SubscriptionValidationResult(
        allowed: false,
        reason: 'Tu suscripcion fue cancelada. Adquiere un nuevo plan para continuar.',
        isGracePeriod: false,
      );
    }

    // Por defecto, permitir si no hay condiciones especiales
    return SubscriptionValidationResult(
      allowed: true,
      isGracePeriod: false,
    );
  }

  /// Verificar si una accion esta permitida durante el periodo de gracia
  bool _isActionAllowedInGracePeriod(String action) {
    if (!readOnlyDuringGrace) {
      return true; // Todo permitido si no hay restriccion de solo lectura
    }

    // Verificar si es una accion de solo lectura
    for (final allowed in gracePeriodAllowedActions) {
      if (action.toLowerCase().contains(allowed.toLowerCase())) {
        return true;
      }
    }

    // Verificar si es una accion bloqueada
    for (final blocked in gracePeriodBlockedActions) {
      if (action.toLowerCase().contains(blocked.toLowerCase())) {
        return false;
      }
    }

    // Por defecto, permitir acciones no explicitamente bloqueadas
    return true;
  }

  /// Determinar el modo de operacion actual basado en la suscripcion
  OfflineOperationMode getOperationMode(Subscription? subscription) {
    if (subscription == null) {
      return OfflineOperationMode.blocked;
    }

    if (subscription.isActive && !subscription.isExpired) {
      return OfflineOperationMode.full;
    }

    if (subscription.isExpired) {
      final gracePeriodEnd = subscription.endDate.add(
        const Duration(days: gracePeriodDays),
      );

      if (DateTime.now().isBefore(gracePeriodEnd)) {
        return readOnlyDuringGrace
            ? OfflineOperationMode.readOnly
            : OfflineOperationMode.full;
      }

      return OfflineOperationMode.blocked;
    }

    if (subscription.status == SubscriptionStatus.suspended ||
        subscription.status == SubscriptionStatus.cancelled) {
      return OfflineOperationMode.blocked;
    }

    return OfflineOperationMode.full;
  }

  /// Verificar si la suscripcion cacheada esta en periodo de gracia
  bool isInGracePeriod(DateTime? expirationDate, DateTime? lastSync) {
    if (expirationDate == null) return false;

    final now = DateTime.now();
    final gracePeriodEnd = expirationDate.add(
      const Duration(days: gracePeriodDays),
    );

    return now.isAfter(expirationDate) && now.isBefore(gracePeriodEnd);
  }

  /// Obtener dias restantes de periodo de gracia
  int getGracePeriodDaysRemaining(DateTime? expirationDate) {
    if (expirationDate == null) return 0;

    final gracePeriodEnd = expirationDate.add(
      const Duration(days: gracePeriodDays),
    );

    if (DateTime.now().isAfter(gracePeriodEnd)) return 0;

    return gracePeriodEnd.difference(DateTime.now()).inDays;
  }

  /// Metodo estatico para validar rapidamente (sin instancia)
  static bool quickValidate(String action) {
    try {
      if (!Get.isRegistered<SubscriptionController>()) {
        return true; // Si no hay controller, permitir por defecto
      }

      final controller = Get.find<SubscriptionController>();
      return controller.canPerformAction(action);
    } catch (e) {
      return true; // En caso de error, permitir por defecto
    }
  }
}

/// Resultado de validacion de suscripcion
class SubscriptionValidationResult {
  final bool allowed;
  final String? reason;
  final bool isGracePeriod;
  final int daysRemaining;

  const SubscriptionValidationResult({
    required this.allowed,
    this.reason,
    required this.isGracePeriod,
    this.daysRemaining = 0,
  });

  @override
  String toString() {
    return 'SubscriptionValidationResult{allowed: $allowed, reason: $reason, isGracePeriod: $isGracePeriod, daysRemaining: $daysRemaining}';
  }
}

/// Modos de operacion offline
enum OfflineOperationMode {
  /// Todas las operaciones permitidas
  full,

  /// Solo operaciones de lectura
  readOnly,

  /// Completamente bloqueado
  blocked,
}

extension OfflineOperationModeExtension on OfflineOperationMode {
  String get displayName {
    switch (this) {
      case OfflineOperationMode.full:
        return 'Acceso completo';
      case OfflineOperationMode.readOnly:
        return 'Solo lectura';
      case OfflineOperationMode.blocked:
        return 'Bloqueado';
    }
  }

  bool get canRead => this != OfflineOperationMode.blocked;
  bool get canWrite => this == OfflineOperationMode.full;
}
