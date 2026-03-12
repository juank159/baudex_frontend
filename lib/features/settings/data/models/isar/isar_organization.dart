// lib/features/settings/data/models/isar/isar_organization.dart
import 'dart:convert';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/settings/domain/entities/organization.dart';
import 'package:isar/isar.dart';

part 'isar_organization.g.dart';

@collection
class IsarOrganization {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  late String name;

  @Index(unique: true)
  late String slug;

  String? domain;
  String? logo;
  String? settingsJson; // Map<String, dynamic> serializado

  @Enumerated(EnumType.name)
  late IsarSubscriptionPlan subscriptionPlan;

  @Enumerated(EnumType.name)
  late IsarSubscriptionStatus subscriptionStatus;

  late bool isActive;

  // Configuraciones regionales
  late String currency;
  late String locale;
  late String timezone;

  // Margen de ganancia por defecto
  double? defaultProfitMarginPercentage;

  // Fechas de suscripción
  DateTime? subscriptionStartDate;
  DateTime? subscriptionEndDate;
  DateTime? trialStartDate;
  DateTime? trialEndDate;

  // Campos computados de suscripción (cacheo)
  bool? hasValidSubscription;
  bool? isTrialExpired;
  int? daysUntilExpirationCached;
  bool? isActivePlan;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Campos de versionamiento para detección de conflictos
  late int version;
  DateTime? lastModifiedAt;
  String? lastModifiedBy;

  // Constructores
  IsarOrganization();

  IsarOrganization.create({
    required this.serverId,
    required this.name,
    required this.slug,
    this.domain,
    this.logo,
    this.settingsJson,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    required this.isActive,
    required this.currency,
    required this.locale,
    required this.timezone,
    this.defaultProfitMarginPercentage,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.trialStartDate,
    this.trialEndDate,
    this.hasValidSubscription,
    this.isTrialExpired,
    this.daysUntilExpirationCached,
    this.isActivePlan,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
    this.version = 0,
    this.lastModifiedAt,
    this.lastModifiedBy,
  });

  // ==================== MAPPERS ====================

  static IsarOrganization fromEntity(Organization entity) {
    return IsarOrganization.create(
      serverId: entity.id,
      name: entity.name,
      slug: entity.slug,
      domain: entity.domain,
      logo: entity.logo,
      settingsJson: _encodeSettings(entity.settings),
      subscriptionPlan: _mapSubscriptionPlan(entity.subscriptionPlan),
      subscriptionStatus: _mapSubscriptionStatus(entity.subscriptionStatus),
      isActive: entity.isActive,
      currency: entity.currency,
      locale: entity.locale,
      timezone: entity.timezone,
      defaultProfitMarginPercentage: entity.defaultProfitMarginPercentage,
      subscriptionStartDate: entity.subscriptionStartDate,
      subscriptionEndDate: entity.subscriptionEndDate,
      trialStartDate: entity.trialStartDate,
      trialEndDate: entity.trialEndDate,
      hasValidSubscription: entity.hasValidSubscription,
      isTrialExpired: entity.isTrialExpired,
      daysUntilExpirationCached: entity.daysUntilExpiration,
      isActivePlan: entity.isActivePlan,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  Organization toEntity() {
    return Organization(
      id: serverId,
      name: name,
      slug: slug,
      domain: domain,
      logo: logo,
      settings: _decodeSettings(settingsJson),
      subscriptionPlan: _mapIsarSubscriptionPlan(subscriptionPlan),
      subscriptionStatus: _mapIsarSubscriptionStatus(subscriptionStatus),
      isActive: isActive,
      currency: currency,
      locale: locale,
      timezone: timezone,
      defaultProfitMarginPercentage: defaultProfitMarginPercentage,
      subscriptionStartDate: subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate,
      trialStartDate: trialStartDate,
      trialEndDate: trialEndDate,
      hasValidSubscription: hasValidSubscription,
      isTrialExpired: isTrialExpired,
      daysUntilExpiration: daysUntilExpirationCached,
      isActivePlan: isActivePlan,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Actualizar desde entidad
  void updateFromEntity(Organization entity) {
    name = entity.name;
    slug = entity.slug;
    domain = entity.domain;
    logo = entity.logo;
    settingsJson = _encodeSettings(entity.settings);
    subscriptionPlan = _mapSubscriptionPlan(entity.subscriptionPlan);
    subscriptionStatus = _mapSubscriptionStatus(entity.subscriptionStatus);
    isActive = entity.isActive;
    currency = entity.currency;
    locale = entity.locale;
    timezone = entity.timezone;
    defaultProfitMarginPercentage = entity.defaultProfitMarginPercentage;
    subscriptionStartDate = entity.subscriptionStartDate;
    subscriptionEndDate = entity.subscriptionEndDate;
    trialStartDate = entity.trialStartDate;
    trialEndDate = entity.trialEndDate;
    hasValidSubscription = entity.hasValidSubscription;
    isTrialExpired = entity.isTrialExpired;
    daysUntilExpirationCached = entity.daysUntilExpiration;
    isActivePlan = entity.isActivePlan;
    updatedAt = entity.updatedAt;
    markAsSynced();
  }

  // ==================== ENUM MAPPERS ====================

  static IsarSubscriptionPlan _mapSubscriptionPlan(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.trial:
        return IsarSubscriptionPlan.trial;
      case SubscriptionPlan.basic:
        return IsarSubscriptionPlan.basic;
      case SubscriptionPlan.premium:
        return IsarSubscriptionPlan.premium;
      case SubscriptionPlan.enterprise:
        return IsarSubscriptionPlan.enterprise;
    }
  }

  static SubscriptionPlan _mapIsarSubscriptionPlan(IsarSubscriptionPlan plan) {
    switch (plan) {
      case IsarSubscriptionPlan.trial:
        return SubscriptionPlan.trial;
      case IsarSubscriptionPlan.basic:
        return SubscriptionPlan.basic;
      case IsarSubscriptionPlan.premium:
        return SubscriptionPlan.premium;
      case IsarSubscriptionPlan.enterprise:
        return SubscriptionPlan.enterprise;
    }
  }

  static IsarSubscriptionStatus _mapSubscriptionStatus(
    SubscriptionStatus status,
  ) {
    switch (status) {
      case SubscriptionStatus.active:
        return IsarSubscriptionStatus.active;
      case SubscriptionStatus.expired:
        return IsarSubscriptionStatus.expired;
      case SubscriptionStatus.cancelled:
        return IsarSubscriptionStatus.cancelled;
      case SubscriptionStatus.suspended:
        return IsarSubscriptionStatus.suspended;
    }
  }

  static SubscriptionStatus _mapIsarSubscriptionStatus(
    IsarSubscriptionStatus status,
  ) {
    switch (status) {
      case IsarSubscriptionStatus.active:
        return SubscriptionStatus.active;
      case IsarSubscriptionStatus.expired:
        return SubscriptionStatus.expired;
      case IsarSubscriptionStatus.cancelled:
        return SubscriptionStatus.cancelled;
      case IsarSubscriptionStatus.suspended:
        return SubscriptionStatus.suspended;
    }
  }

  // ==================== SETTINGS SERIALIZATION ====================
  // FIX: Usar JSON correcto en lugar de toString()

  static String _encodeSettings(Map<String, dynamic>? settings) {
    if (settings == null || settings.isEmpty) return '{}';
    try {
      return jsonEncode(settings);
    } catch (e) {
      return '{}';
    }
  }

  static Map<String, dynamic> _decodeSettings(String? settingsJson) {
    if (settingsJson == null || settingsJson.isEmpty || settingsJson == '{}') {
      return {};
    }
    try {
      final decoded = jsonDecode(settingsJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ==================== UTILITY METHODS ====================

  bool get isDeleted => deletedAt != null;
  bool get needsSync => !isSynced;
  bool get isTrialActive =>
      subscriptionPlan == IsarSubscriptionPlan.trial &&
      trialEndDate != null &&
      DateTime.now().isBefore(trialEndDate!);
  bool get isSubscriptionActive =>
      subscriptionStatus == IsarSubscriptionStatus.active;
  bool get isExpired =>
      subscriptionStatus == IsarSubscriptionStatus.expired ||
      (subscriptionEndDate != null &&
          DateTime.now().isAfter(subscriptionEndDate!));

  int? get daysUntilExpiration {
    if (subscriptionEndDate == null) return null;
    final diff = subscriptionEndDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  @ignore
  Map<String, dynamic> get settingsMap => _decodeSettings(settingsJson);

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void softDelete() {
    deletedAt = DateTime.now();
    markAsUnsynced();
  }

  void restore() {
    deletedAt = null;
    markAsUnsynced();
  }

  void updateSettings(Map<String, dynamic> newSettings) {
    settingsJson = _encodeSettings(newSettings);
    incrementVersion(modifiedBy: 'local');
  }

  void updateSubscription(
    IsarSubscriptionPlan newPlan,
    IsarSubscriptionStatus newStatus,
  ) {
    subscriptionPlan = newPlan;
    subscriptionStatus = newStatus;
    incrementVersion(modifiedBy: 'local');
  }

  void updateProfitMargin(double margin, {String? modifiedBy}) {
    defaultProfitMarginPercentage = margin;
    incrementVersion(modifiedBy: modifiedBy ?? 'local');
  }

  // Métodos de versionamiento y detección de conflictos
  void incrementVersion({String? modifiedBy}) {
    version++;
    lastModifiedAt = DateTime.now();
    if (modifiedBy != null) {
      lastModifiedBy = modifiedBy;
    }
    isSynced = false;
  }

  bool hasConflictWith(IsarOrganization serverVersion) {
    if (version == serverVersion.version &&
        lastModifiedAt != null &&
        serverVersion.lastModifiedAt != null &&
        lastModifiedAt != serverVersion.lastModifiedAt) {
      return true;
    }
    if (version > serverVersion.version) {
      return true;
    }
    return false;
  }

  @override
  String toString() {
    return 'IsarOrganization{serverId: $serverId, name: $name, plan: $subscriptionPlan, status: $subscriptionStatus, version: $version, isSynced: $isSynced}';
  }
}
