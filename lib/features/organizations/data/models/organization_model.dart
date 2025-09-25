// lib/features/organizations/data/models/organization_model.dart
import '../../domain/entities/organization.dart';

class OrganizationModel extends Organization {
  const OrganizationModel({
    required super.id,
    required super.name,
    required super.slug,
    super.domain,
    super.logo,
    required super.subscriptionPlan,
    required super.isActive,
    required super.currency,
    required super.locale,
    required super.timezone,
    required super.settings,
    required super.createdAt,
    required super.updatedAt,
    required super.displayName,
    required super.isActivePlan,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      domain: json['domain'] as String?,
      logo: json['logo'] as String?,
      subscriptionPlan: _parseSubscriptionPlan(json['subscriptionPlan']),
      isActive: json['isActive'] as bool? ?? true,
      currency: json['currency'] as String? ?? 'USD',
      locale: json['locale'] as String? ?? 'en',
      timezone: json['timezone'] as String? ?? 'UTC',
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'])
          : <String, dynamic>{},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      displayName: json['displayName'] as String? ?? json['name'] as String,
      isActivePlan: json['isActivePlan'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'domain': domain,
      'logo': logo,
      'subscriptionPlan': subscriptionPlan.name,
      'isActive': isActive,
      'currency': currency,
      'locale': locale,
      'timezone': timezone,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'displayName': displayName,
      'isActivePlan': isActivePlan,
    };
  }

  static SubscriptionPlan _parseSubscriptionPlan(dynamic value) {
    if (value == null) return SubscriptionPlan.basic;
    if (value is SubscriptionPlan) return value;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'basic':
          return SubscriptionPlan.basic;
        case 'premium':
          return SubscriptionPlan.premium;
        case 'enterprise':
          return SubscriptionPlan.enterprise;
        default:
          return SubscriptionPlan.basic;
      }
    }
    return SubscriptionPlan.basic;
  }

  Organization toEntity() {
    return Organization(
      id: id,
      name: name,
      slug: slug,
      domain: domain,
      logo: logo,
      subscriptionPlan: subscriptionPlan,
      isActive: isActive,
      currency: currency,
      locale: locale,
      timezone: timezone,
      settings: settings,
      createdAt: createdAt,
      updatedAt: updatedAt,
      displayName: displayName,
      isActivePlan: isActivePlan,
    );
  }

  factory OrganizationModel.fromEntity(Organization organization) {
    return OrganizationModel(
      id: organization.id,
      name: organization.name,
      slug: organization.slug,
      domain: organization.domain,
      logo: organization.logo,
      subscriptionPlan: organization.subscriptionPlan,
      isActive: organization.isActive,
      currency: organization.currency,
      locale: organization.locale,
      timezone: organization.timezone,
      settings: organization.settings,
      createdAt: organization.createdAt,
      updatedAt: organization.updatedAt,
      displayName: organization.displayName,
      isActivePlan: organization.isActivePlan,
    );
  }

  @override
  OrganizationModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? domain,
    String? logo,
    SubscriptionPlan? subscriptionPlan,
    bool? isActive,
    String? currency,
    String? locale,
    String? timezone,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? displayName,
    bool? isActivePlan,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      domain: domain ?? this.domain,
      logo: logo ?? this.logo,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      isActive: isActive ?? this.isActive,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      displayName: displayName ?? this.displayName,
      isActivePlan: isActivePlan ?? this.isActivePlan,
    );
  }
}