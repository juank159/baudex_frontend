// lib/features/settings/domain/entities/organization.dart
import 'package:equatable/equatable.dart';

enum SubscriptionPlan {
  trial('trial'),
  basic('basic'),
  premium('premium'),
  enterprise('enterprise');

  const SubscriptionPlan(this.value);
  final String value;

  static SubscriptionPlan fromString(String value) {
    return SubscriptionPlan.values.firstWhere(
      (plan) => plan.value == value,
      orElse: () => SubscriptionPlan.trial,
    );
  }

  String get displayName {
    switch (this) {
      case SubscriptionPlan.trial:
        return 'Prueba';
      case SubscriptionPlan.basic:
        return 'Básico';
      case SubscriptionPlan.premium:
        return 'Premium';
      case SubscriptionPlan.enterprise:
        return 'Empresarial';
    }
  }
}

enum SubscriptionStatus {
  active('active'),
  expired('expired'),
  cancelled('cancelled'),
  suspended('suspended');

  const SubscriptionStatus(this.value);
  final String value;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubscriptionStatus.active,
    );
  }

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
    }
  }
}

class Organization extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? domain;
  final String? logo;
  final Map<String, dynamic>? settings;
  final SubscriptionPlan subscriptionPlan;
  final SubscriptionStatus subscriptionStatus;
  final bool isActive;
  final String currency;
  final String locale;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Campos de suscripción
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final bool? hasValidSubscription;
  final bool? isTrialExpired;
  final int? daysUntilExpiration;
  final bool? isActivePlan;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.domain,
    this.logo,
    this.settings,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    required this.isActive,
    required this.currency,
    required this.locale,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.trialStartDate,
    this.trialEndDate,
    this.hasValidSubscription,
    this.isTrialExpired,
    this.daysUntilExpiration,
    this.isActivePlan,
  });

  // Computed properties
  bool get isTrialPlan => subscriptionPlan == SubscriptionPlan.trial;
  
  double get subscriptionProgress {
    if (subscriptionPlan == SubscriptionPlan.trial) {
      if (trialStartDate == null || trialEndDate == null) return 0.0;
      
      final now = DateTime.now();
      final totalDays = trialEndDate!.difference(trialStartDate!).inDays;
      final elapsedDays = now.difference(trialStartDate!).inDays;
      
      if (totalDays <= 0) return 1.0;
      return (elapsedDays / totalDays).clamp(0.0, 1.0);
    } else {
      if (subscriptionStartDate == null || subscriptionEndDate == null) return 0.0;
      
      final now = DateTime.now();
      final totalDays = subscriptionEndDate!.difference(subscriptionStartDate!).inDays;
      final elapsedDays = now.difference(subscriptionStartDate!).inDays;
      
      if (totalDays <= 0) return 1.0;
      return (elapsedDays / totalDays).clamp(0.0, 1.0);
    }
  }
  
  int get remainingDays {
    final now = DateTime.now();
    final expirationDate = subscriptionPlan == SubscriptionPlan.trial
        ? trialEndDate
        : subscriptionEndDate;
    
    if (expirationDate == null) return 0;
    
    final diffDays = expirationDate.difference(now).inDays;
    return diffDays > 0 ? diffDays : 0;
  }

  Organization copyWith({
    String? id,
    String? name,
    String? slug,
    String? domain,
    String? logo,
    Map<String, dynamic>? settings,
    SubscriptionPlan? subscriptionPlan,
    SubscriptionStatus? subscriptionStatus,
    bool? isActive,
    String? currency,
    String? locale,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    bool? hasValidSubscription,
    bool? isTrialExpired,
    int? daysUntilExpiration,
    bool? isActivePlan,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      domain: domain ?? this.domain,
      logo: logo ?? this.logo,
      settings: settings ?? this.settings,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      isActive: isActive ?? this.isActive,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      hasValidSubscription: hasValidSubscription ?? this.hasValidSubscription,
      isTrialExpired: isTrialExpired ?? this.isTrialExpired,
      daysUntilExpiration: daysUntilExpiration ?? this.daysUntilExpiration,
      isActivePlan: isActivePlan ?? this.isActivePlan,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        domain,
        logo,
        settings,
        subscriptionPlan,
        subscriptionStatus,
        isActive,
        currency,
        locale,
        timezone,
        createdAt,
        updatedAt,
        subscriptionStartDate,
        subscriptionEndDate,
        trialStartDate,
        trialEndDate,
        hasValidSubscription,
        isTrialExpired,
        daysUntilExpiration,
        isActivePlan,
      ];
}