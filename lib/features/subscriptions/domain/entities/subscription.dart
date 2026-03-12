// lib/features/subscriptions/domain/entities/subscription.dart

import 'package:equatable/equatable.dart';
import 'subscription_enums.dart';
import 'plan_limits.dart';

/// Entidad principal de suscripcion
class Subscription extends Equatable {
  final String id;
  final String organizationId;
  final SubscriptionPlan plan;
  final String planDisplayName;
  final SubscriptionStatus status;
  final SubscriptionType type;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isExpired;
  final bool isTrial;
  final int daysUntilExpiration;
  final double subscriptionProgress;
  final int remainingDays;
  final int maxUsers;
  final bool autoRenew;
  final double? price;
  final String? currency;
  final String? paymentMethod;
  final DateTime? nextBillingDate;
  final DateTime? trialEndsAt;
  final int billingCycle;
  final PlanLimits limits;

  const Subscription({
    required this.id,
    required this.organizationId,
    required this.plan,
    required this.planDisplayName,
    required this.status,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isExpired,
    required this.isTrial,
    required this.daysUntilExpiration,
    required this.subscriptionProgress,
    required this.remainingDays,
    required this.maxUsers,
    required this.autoRenew,
    this.price,
    this.currency,
    this.paymentMethod,
    this.nextBillingDate,
    this.trialEndsAt,
    required this.billingCycle,
    required this.limits,
  });

  /// Crear suscripcion trial por defecto
  factory Subscription.defaultTrial(String organizationId) {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 30));

    return Subscription(
      id: '',
      organizationId: organizationId,
      plan: SubscriptionPlan.trial,
      planDisplayName: 'Plan de Prueba',
      status: SubscriptionStatus.active,
      type: SubscriptionType.trial,
      startDate: now,
      endDate: endDate,
      isActive: true,
      isExpired: false,
      isTrial: true,
      daysUntilExpiration: 30,
      subscriptionProgress: 0.0,
      remainingDays: 30,
      maxUsers: 2,
      autoRenew: false,
      billingCycle: 0,
      limits: PlanLimits.trial,
    );
  }

  /// Verificar si la suscripcion esta por expirar (< 7 dias)
  bool get isExpiringSoon => daysUntilExpiration > 0 && daysUntilExpiration <= 7;

  /// Verificar si esta en el ultimo dia
  bool get isLastDay => daysUntilExpiration == 1;

  /// Verificar si esta en periodo critico (< 3 dias)
  bool get isCritical => daysUntilExpiration > 0 && daysUntilExpiration <= 3;

  /// Obtener nivel de alerta segun dias restantes
  SubscriptionAlertLevel get alertLevel {
    if (isExpired || daysUntilExpiration <= 0) {
      return SubscriptionAlertLevel.expired;
    }
    if (daysUntilExpiration <= 3) {
      return SubscriptionAlertLevel.critical;
    }
    if (daysUntilExpiration <= 7) {
      return SubscriptionAlertLevel.warning;
    }
    return SubscriptionAlertLevel.normal;
  }

  /// Verificar si puede realizar una accion
  bool canPerformAction(String action) {
    if (!isActive) return false;
    return limits.features.isFeatureEnabled(action);
  }

  /// Verificar si puede agregar recursos
  bool canAddProduct(int currentCount) => limits.canAddProduct(currentCount);
  bool canAddCustomer(int currentCount) => limits.canAddCustomer(currentCount);
  bool canAddInvoice(int currentMonthCount) =>
      limits.canAddInvoice(currentMonthCount);
  bool canAddUser(int currentCount) => limits.canAddUser(currentCount);
  bool canAddExpense(int currentMonthCount) =>
      limits.canAddExpense(currentMonthCount);

  @override
  List<Object?> get props => [
        id,
        organizationId,
        plan,
        planDisplayName,
        status,
        type,
        startDate,
        endDate,
        isActive,
        isExpired,
        isTrial,
        daysUntilExpiration,
        subscriptionProgress,
        remainingDays,
        maxUsers,
        autoRenew,
        price,
        currency,
        paymentMethod,
        nextBillingDate,
        trialEndsAt,
        billingCycle,
        limits,
      ];

  Subscription copyWith({
    String? id,
    String? organizationId,
    SubscriptionPlan? plan,
    String? planDisplayName,
    SubscriptionStatus? status,
    SubscriptionType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isExpired,
    bool? isTrial,
    int? daysUntilExpiration,
    double? subscriptionProgress,
    int? remainingDays,
    int? maxUsers,
    bool? autoRenew,
    double? price,
    String? currency,
    String? paymentMethod,
    DateTime? nextBillingDate,
    DateTime? trialEndsAt,
    int? billingCycle,
    PlanLimits? limits,
  }) {
    return Subscription(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      plan: plan ?? this.plan,
      planDisplayName: planDisplayName ?? this.planDisplayName,
      status: status ?? this.status,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isExpired: isExpired ?? this.isExpired,
      isTrial: isTrial ?? this.isTrial,
      daysUntilExpiration: daysUntilExpiration ?? this.daysUntilExpiration,
      subscriptionProgress: subscriptionProgress ?? this.subscriptionProgress,
      remainingDays: remainingDays ?? this.remainingDays,
      maxUsers: maxUsers ?? this.maxUsers,
      autoRenew: autoRenew ?? this.autoRenew,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      billingCycle: billingCycle ?? this.billingCycle,
      limits: limits ?? this.limits,
    );
  }
}

/// Niveles de alerta de suscripcion
enum SubscriptionAlertLevel {
  normal,
  warning,
  critical,
  expired,
}

extension SubscriptionAlertLevelExtension on SubscriptionAlertLevel {
  String get message {
    switch (this) {
      case SubscriptionAlertLevel.normal:
        return '';
      case SubscriptionAlertLevel.warning:
        return 'Tu suscripcion vence pronto';
      case SubscriptionAlertLevel.critical:
        return 'Tu suscripcion vence en menos de 3 dias';
      case SubscriptionAlertLevel.expired:
        return 'Tu suscripcion ha expirado';
    }
  }

  bool get shouldShowAlert => this != SubscriptionAlertLevel.normal;
}
