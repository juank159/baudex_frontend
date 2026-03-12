// lib/features/subscriptions/data/models/subscription_model.dart

import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';
import '../../domain/entities/plan_limits.dart';
import 'plan_limits_model.dart';

class SubscriptionModel extends Subscription {
  const SubscriptionModel({
    required super.id,
    required super.organizationId,
    required super.plan,
    required super.planDisplayName,
    required super.status,
    required super.type,
    required super.startDate,
    required super.endDate,
    required super.isActive,
    required super.isExpired,
    required super.isTrial,
    required super.daysUntilExpiration,
    required super.subscriptionProgress,
    required super.remainingDays,
    required super.maxUsers,
    required super.autoRenew,
    super.price,
    super.currency,
    super.paymentMethod,
    super.nextBillingDate,
    super.trialEndsAt,
    required super.billingCycle,
    required super.limits,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      plan: _parsePlan(json['plan']),
      planDisplayName:
          json['planDisplayName'] as String? ?? 'Plan de Prueba',
      status: _parseStatus(json['status']),
      type: _parseType(json['type']),
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate']) ??
          DateTime.now().add(const Duration(days: 30)),
      isActive: json['isActive'] as bool? ?? false,
      isExpired: json['isExpired'] as bool? ?? false,
      isTrial: json['isTrial'] as bool? ?? true,
      daysUntilExpiration: json['daysUntilExpiration'] as int? ?? 0,
      subscriptionProgress:
          (json['subscriptionProgress'] as num?)?.toDouble() ?? 0.0,
      remainingDays: json['remainingDays'] as int? ?? 0,
      maxUsers: json['maxUsers'] as int? ?? 2,
      autoRenew: json['autoRenew'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      nextBillingDate: _parseDate(json['nextBillingDate']),
      trialEndsAt: _parseDate(json['trialEndsAt']),
      billingCycle: json['billingCycle'] as int? ?? 0,
      limits: json['limits'] != null
          ? PlanLimitsModel.fromJson(json['limits'] as Map<String, dynamic>)
          : PlanLimits.trial,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'plan': plan.name,
      'planDisplayName': planDisplayName,
      'status': status.name,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'isExpired': isExpired,
      'isTrial': isTrial,
      'daysUntilExpiration': daysUntilExpiration,
      'subscriptionProgress': subscriptionProgress,
      'remainingDays': remainingDays,
      'maxUsers': maxUsers,
      'autoRenew': autoRenew,
      'price': price,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'nextBillingDate': nextBillingDate?.toIso8601String(),
      'trialEndsAt': trialEndsAt?.toIso8601String(),
      'billingCycle': billingCycle,
      'limits': PlanLimitsModel.fromEntity(limits).toJson(),
    };
  }

  Subscription toEntity() {
    return Subscription(
      id: id,
      organizationId: organizationId,
      plan: plan,
      planDisplayName: planDisplayName,
      status: status,
      type: type,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      isExpired: isExpired,
      isTrial: isTrial,
      daysUntilExpiration: daysUntilExpiration,
      subscriptionProgress: subscriptionProgress,
      remainingDays: remainingDays,
      maxUsers: maxUsers,
      autoRenew: autoRenew,
      price: price,
      currency: currency,
      paymentMethod: paymentMethod,
      nextBillingDate: nextBillingDate,
      trialEndsAt: trialEndsAt,
      billingCycle: billingCycle,
      limits: limits,
    );
  }

  factory SubscriptionModel.fromEntity(Subscription entity) {
    return SubscriptionModel(
      id: entity.id,
      organizationId: entity.organizationId,
      plan: entity.plan,
      planDisplayName: entity.planDisplayName,
      status: entity.status,
      type: entity.type,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isActive: entity.isActive,
      isExpired: entity.isExpired,
      isTrial: entity.isTrial,
      daysUntilExpiration: entity.daysUntilExpiration,
      subscriptionProgress: entity.subscriptionProgress,
      remainingDays: entity.remainingDays,
      maxUsers: entity.maxUsers,
      autoRenew: entity.autoRenew,
      price: entity.price,
      currency: entity.currency,
      paymentMethod: entity.paymentMethod,
      nextBillingDate: entity.nextBillingDate,
      trialEndsAt: entity.trialEndsAt,
      billingCycle: entity.billingCycle,
      limits: entity.limits,
    );
  }

  static SubscriptionPlan _parsePlan(dynamic value) {
    if (value == null) return SubscriptionPlan.trial;
    if (value is SubscriptionPlan) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'trial':
          return SubscriptionPlan.trial;
        case 'basic':
          return SubscriptionPlan.basic;
        case 'premium':
          return SubscriptionPlan.premium;
        case 'enterprise':
          return SubscriptionPlan.enterprise;
        default:
          return SubscriptionPlan.trial;
      }
    }
    return SubscriptionPlan.trial;
  }

  static SubscriptionStatus _parseStatus(dynamic value) {
    if (value == null) return SubscriptionStatus.pending;
    if (value is SubscriptionStatus) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'active':
          return SubscriptionStatus.active;
        case 'expired':
          return SubscriptionStatus.expired;
        case 'cancelled':
          return SubscriptionStatus.cancelled;
        case 'suspended':
          return SubscriptionStatus.suspended;
        case 'pending':
          return SubscriptionStatus.pending;
        default:
          return SubscriptionStatus.pending;
      }
    }
    return SubscriptionStatus.pending;
  }

  static SubscriptionType _parseType(dynamic value) {
    if (value == null) return SubscriptionType.trial;
    if (value is SubscriptionType) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'trial':
          return SubscriptionType.trial;
        case 'monthly':
          return SubscriptionType.monthly;
        case 'annual':
          return SubscriptionType.annual;
        case 'lifetime':
          return SubscriptionType.lifetime;
        default:
          return SubscriptionType.trial;
      }
    }
    return SubscriptionType.trial;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
