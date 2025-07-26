import 'package:equatable/equatable.dart';

enum SubscriptionPlan {
  basic,
  premium,
  enterprise,
}

class Organization extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? domain;
  final String? logo;
  final SubscriptionPlan subscriptionPlan;
  final bool isActive;
  final String currency;
  final String locale;
  final String timezone;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String displayName;
  final bool isActivePlan;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.domain,
    this.logo,
    required this.subscriptionPlan,
    required this.isActive,
    required this.currency,
    required this.locale,
    required this.timezone,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
    required this.displayName,
    required this.isActivePlan,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        domain,
        logo,
        subscriptionPlan,
        isActive,
        currency,
        locale,
        timezone,
        settings,
        createdAt,
        updatedAt,
        displayName,
        isActivePlan,
      ];

  Organization copyWith({
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
    return Organization(
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