// lib/features/subscriptions/data/models/action_validation_model.dart

import '../../domain/entities/action_validation.dart';
import '../../domain/entities/subscription_enums.dart';

class ActionValidationModel extends ActionValidation {
  const ActionValidationModel({
    required super.allowed,
    super.reason,
    super.requiredPlan,
    super.currentLimit,
    super.currentUsage,
  });

  factory ActionValidationModel.fromJson(Map<String, dynamic> json) {
    return ActionValidationModel(
      allowed: json['allowed'] as bool? ?? false,
      reason: json['reason'] as String?,
      requiredPlan: _parsePlan(json['requiredPlan']),
      currentLimit: json['currentLimit'] as int?,
      currentUsage: json['currentUsage'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowed': allowed,
      'reason': reason,
      'requiredPlan': requiredPlan?.name,
      'currentLimit': currentLimit,
      'currentUsage': currentUsage,
    };
  }

  ActionValidation toEntity() {
    return ActionValidation(
      allowed: allowed,
      reason: reason,
      requiredPlan: requiredPlan,
      currentLimit: currentLimit,
      currentUsage: currentUsage,
    );
  }

  static SubscriptionPlan? _parsePlan(dynamic value) {
    if (value == null) return null;
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
          return null;
      }
    }
    return null;
  }
}
