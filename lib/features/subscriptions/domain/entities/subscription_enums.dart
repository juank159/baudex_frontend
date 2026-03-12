// lib/features/subscriptions/domain/entities/subscription_enums.dart

/// Plan de suscripcion
enum SubscriptionPlan {
  trial,
  basic,
  premium,
  enterprise,
}

/// Estado de la suscripcion
enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  suspended,
  pending,
}

/// Tipo de suscripcion
enum SubscriptionType {
  trial,
  monthly,
  annual,
  lifetime,
}

/// Extension para obtener nombres legibles de los planes
extension SubscriptionPlanExtension on SubscriptionPlan {
  String get displayName {
    switch (this) {
      case SubscriptionPlan.trial:
        return 'Plan de Prueba';
      case SubscriptionPlan.basic:
        return 'Plan Basico';
      case SubscriptionPlan.premium:
        return 'Plan Premium';
      case SubscriptionPlan.enterprise:
        return 'Plan Empresarial';
    }
  }

  bool get isUnlimited => this == SubscriptionPlan.enterprise;

  bool get hasPrioritySupport => this == SubscriptionPlan.enterprise;
}

/// Extension para obtener nombres legibles de los estados
extension SubscriptionStatusExtension on SubscriptionStatus {
  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Activa';
      case SubscriptionStatus.expired:
        return 'Expirada';
      case SubscriptionStatus.cancelled:
        return 'Cancelada';
      case SubscriptionStatus.suspended:
        return 'Suspendida';
      case SubscriptionStatus.pending:
        return 'Pendiente';
    }
  }

  bool get isValid =>
      this == SubscriptionStatus.active || this == SubscriptionStatus.pending;
}

/// Extension para obtener nombres legibles de los tipos
extension SubscriptionTypeExtension on SubscriptionType {
  String get displayName {
    switch (this) {
      case SubscriptionType.trial:
        return 'Prueba';
      case SubscriptionType.monthly:
        return 'Mensual';
      case SubscriptionType.annual:
        return 'Anual';
      case SubscriptionType.lifetime:
        return 'Vitalicio';
    }
  }

  int get billingCycleMonths {
    switch (this) {
      case SubscriptionType.trial:
        return 0;
      case SubscriptionType.monthly:
        return 1;
      case SubscriptionType.annual:
        return 12;
      case SubscriptionType.lifetime:
        return -1;
    }
  }
}
