// lib/features/subscriptions/data/models/subscription_usage_model.dart

import '../../domain/entities/subscription_usage.dart';
import '../../domain/entities/subscription_enums.dart';

class ResourceUsageModel extends ResourceUsage {
  const ResourceUsageModel({
    required super.current,
    required super.limit,
    required super.isUnlimited,
    required super.percentage,
    required super.isNearLimit,
    required super.hasReachedLimit,
  });

  factory ResourceUsageModel.fromJson(Map<String, dynamic> json) {
    return ResourceUsageModel(
      current: json['current'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
      isUnlimited: json['isUnlimited'] as bool? ?? false,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      isNearLimit: json['isNearLimit'] as bool? ?? false,
      hasReachedLimit: json['hasReachedLimit'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'limit': limit,
      'isUnlimited': isUnlimited,
      'percentage': percentage,
      'isNearLimit': isNearLimit,
      'hasReachedLimit': hasReachedLimit,
    };
  }

  ResourceUsage toEntity() {
    return ResourceUsage(
      current: current,
      limit: limit,
      isUnlimited: isUnlimited,
      percentage: percentage,
      isNearLimit: isNearLimit,
      hasReachedLimit: hasReachedLimit,
    );
  }
}

class UsageWarningModel extends UsageWarning {
  const UsageWarningModel({
    required super.resource,
    required super.type,
    required super.message,
    required super.percentage,
  });

  factory UsageWarningModel.fromJson(Map<String, dynamic> json) {
    return UsageWarningModel(
      resource: json['resource'] as String? ?? '',
      type: _parseWarningType(json['type']),
      message: json['message'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resource': resource,
      'type': type.name,
      'message': message,
      'percentage': percentage,
    };
  }

  UsageWarning toEntity() {
    return UsageWarning(
      resource: resource,
      type: type,
      message: message,
      percentage: percentage,
    );
  }

  static UsageWarningType _parseWarningType(dynamic value) {
    if (value == null) return UsageWarningType.nearLimit;
    if (value is UsageWarningType) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'near_limit':
        case 'nearlimit':
          return UsageWarningType.nearLimit;
        case 'at_limit':
        case 'atlimit':
          return UsageWarningType.atLimit;
        case 'over_limit':
        case 'overlimit':
          return UsageWarningType.overLimit;
        default:
          return UsageWarningType.nearLimit;
      }
    }
    return UsageWarningType.nearLimit;
  }
}

class SubscriptionUsageModel extends SubscriptionUsage {
  const SubscriptionUsageModel({
    required super.plan,
    required super.planDisplayName,
    required super.hasUnlimitedResources,
    required super.products,
    required super.customers,
    required super.users,
    required super.invoicesThisMonth,
    required super.expensesThisMonth,
    required super.storage,
    required super.warnings,
    required super.daysUntilExpiration,
    super.nextRenewalDate,
  });

  factory SubscriptionUsageModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionUsageModel(
      plan: _parsePlan(json['plan']),
      planDisplayName: json['planDisplayName'] as String? ?? 'Plan de Prueba',
      hasUnlimitedResources: json['hasUnlimitedResources'] as bool? ?? false,
      products: json['products'] != null
          ? ResourceUsageModel.fromJson(
              json['products'] as Map<String, dynamic>)
          : const ResourceUsageModel(
              current: 0,
              limit: 0,
              isUnlimited: false,
              percentage: 0,
              isNearLimit: false,
              hasReachedLimit: false,
            ),
      customers: json['customers'] != null
          ? ResourceUsageModel.fromJson(
              json['customers'] as Map<String, dynamic>)
          : const ResourceUsageModel(
              current: 0,
              limit: 0,
              isUnlimited: false,
              percentage: 0,
              isNearLimit: false,
              hasReachedLimit: false,
            ),
      users: json['users'] != null
          ? ResourceUsageModel.fromJson(json['users'] as Map<String, dynamic>)
          : const ResourceUsageModel(
              current: 0,
              limit: 0,
              isUnlimited: false,
              percentage: 0,
              isNearLimit: false,
              hasReachedLimit: false,
            ),
      invoicesThisMonth: json['invoicesThisMonth'] != null
          ? ResourceUsageModel.fromJson(
              json['invoicesThisMonth'] as Map<String, dynamic>)
          : const ResourceUsageModel(
              current: 0,
              limit: 0,
              isUnlimited: false,
              percentage: 0,
              isNearLimit: false,
              hasReachedLimit: false,
            ),
      expensesThisMonth: json['expensesThisMonth'] != null
          ? ResourceUsageModel.fromJson(
              json['expensesThisMonth'] as Map<String, dynamic>)
          : const ResourceUsageModel(
              current: 0,
              limit: 0,
              isUnlimited: false,
              percentage: 0,
              isNearLimit: false,
              hasReachedLimit: false,
            ),
      storage: json['storage'] != null
          ? ResourceUsageModel.fromJson(json['storage'] as Map<String, dynamic>)
          : const ResourceUsageModel(
              current: 0,
              limit: 0,
              isUnlimited: false,
              percentage: 0,
              isNearLimit: false,
              hasReachedLimit: false,
            ),
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((w) =>
                  UsageWarningModel.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      daysUntilExpiration: json['daysUntilExpiration'] as int? ?? 0,
      nextRenewalDate: _parseDate(json['nextRenewalDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan.name,
      'planDisplayName': planDisplayName,
      'hasUnlimitedResources': hasUnlimitedResources,
      'products': (products as ResourceUsageModel).toJson(),
      'customers': (customers as ResourceUsageModel).toJson(),
      'users': (users as ResourceUsageModel).toJson(),
      'invoicesThisMonth': (invoicesThisMonth as ResourceUsageModel).toJson(),
      'expensesThisMonth': (expensesThisMonth as ResourceUsageModel).toJson(),
      'storage': (storage as ResourceUsageModel).toJson(),
      'warnings':
          warnings.map((w) => (w as UsageWarningModel).toJson()).toList(),
      'daysUntilExpiration': daysUntilExpiration,
      'nextRenewalDate': nextRenewalDate?.toIso8601String(),
    };
  }

  SubscriptionUsage toEntity() {
    return SubscriptionUsage(
      plan: plan,
      planDisplayName: planDisplayName,
      hasUnlimitedResources: hasUnlimitedResources,
      products: products,
      customers: customers,
      users: users,
      invoicesThisMonth: invoicesThisMonth,
      expensesThisMonth: expensesThisMonth,
      storage: storage,
      warnings: warnings,
      daysUntilExpiration: daysUntilExpiration,
      nextRenewalDate: nextRenewalDate,
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
