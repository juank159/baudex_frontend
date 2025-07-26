// lib/features/settings/data/models/organization_model.dart
import '../../domain/entities/organization.dart';

class OrganizationModel extends Organization {
  const OrganizationModel({
    required super.id,
    required super.name,
    required super.slug,
    super.domain,
    super.logo,
    super.settings,
    required super.subscriptionPlan,
    required super.subscriptionStatus,
    required super.isActive,
    required super.currency,
    required super.locale,
    required super.timezone,
    required super.createdAt,
    required super.updatedAt,
    super.subscriptionStartDate,
    super.subscriptionEndDate,
    super.trialStartDate,
    super.trialEndDate,
    super.hasValidSubscription,
    super.isTrialExpired,
    super.daysUntilExpiration,
    super.isActivePlan,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      domain: json['domain'],
      logo: json['logo'],
      settings: json['settings'] != null 
        ? Map<String, dynamic>.from(json['settings'])
        : null,
      subscriptionPlan: SubscriptionPlan.fromString(json['subscriptionPlan'] ?? 'trial'),
      subscriptionStatus: SubscriptionStatus.fromString(json['subscriptionStatus'] ?? 'active'),
      isActive: json['isActive'] ?? true,
      currency: json['currency'] ?? 'EUR',
      locale: json['locale'] ?? 'es',
      timezone: json['timezone'] ?? 'Europe/Madrid',
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'])
        : DateTime.now(),
      subscriptionStartDate: json['subscriptionStartDate'] != null 
        ? DateTime.parse(json['subscriptionStartDate'])
        : null,
      subscriptionEndDate: json['subscriptionEndDate'] != null 
        ? DateTime.parse(json['subscriptionEndDate'])
        : null,
      trialStartDate: json['trialStartDate'] != null 
        ? DateTime.parse(json['trialStartDate'])
        : null,
      trialEndDate: json['trialEndDate'] != null 
        ? DateTime.parse(json['trialEndDate'])
        : null,
      hasValidSubscription: json['hasValidSubscription'],
      isTrialExpired: json['isTrialExpired'],
      daysUntilExpiration: json['daysUntilExpiration'],
      isActivePlan: json['isActivePlan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'domain': domain,
      'logo': logo,
      'settings': settings,
      'subscriptionPlan': subscriptionPlan.value,
      'subscriptionStatus': subscriptionStatus.value,
      'isActive': isActive,
      'currency': currency,
      'locale': locale,
      'timezone': timezone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'trialStartDate': trialStartDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
      'hasValidSubscription': hasValidSubscription,
      'isTrialExpired': isTrialExpired,
      'daysUntilExpiration': daysUntilExpiration,
      'isActivePlan': isActivePlan,
    };
  }
}