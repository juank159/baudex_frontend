// lib/features/settings/data/models/isar/isar_organization.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/settings/domain/entities/organization.dart';
// import 'package:isar/isar.dart';

// part 'isar_organization.g.dart';

// @collection
class IsarOrganization {
  // Id id = Isar.autoIncrement;
  int id = 0;

  // @Index(unique: true)
  late String serverId;

  // @Index()
  late String name;

  // @Index(unique: true)
  late String slug;

  String? domain;
  String? logo;
  String? settingsJson; // Map<String, dynamic> serializado

  // @Enumerated(EnumType.name)
  late IsarSubscriptionPlan subscriptionPlan;

  // @Enumerated(EnumType.name)
  late IsarSubscriptionStatus subscriptionStatus;

  late bool isActive;

  // Configuraciones regionales
  late String currency;
  late String locale;
  late String timezone;

  // Fechas de suscripción
  DateTime? subscriptionStartDate;
  DateTime? subscriptionEndDate;
  DateTime? trialStartDate;
  DateTime? trialEndDate;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

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
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.trialStartDate,
    this.trialEndDate,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.lastSyncAt,
  });

  // Mappers
  static IsarOrganization fromEntity(Organization entity) {
    return IsarOrganization.create(
      serverId: entity.id,
      name: entity.name,
      slug: entity.slug,
      domain: entity.domain,
      logo: entity.logo,
      settingsJson:
          entity.settings != null ? _encodeSettings(entity.settings!) : null,
      subscriptionPlan: _mapSubscriptionPlan(entity.subscriptionPlan),
      subscriptionStatus: _mapSubscriptionStatus(entity.subscriptionStatus),
      isActive: entity.isActive,
      currency: entity.currency,
      locale: entity.locale,
      timezone: entity.timezone,
      subscriptionStartDate: entity.subscriptionStartDate,
      subscriptionEndDate: entity.subscriptionEndDate,
      trialStartDate: entity.trialStartDate,
      trialEndDate: entity.trialEndDate,
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
      settings: settingsJson != null ? _decodeSettings(settingsJson!) : null,
      subscriptionPlan: _mapIsarSubscriptionPlan(subscriptionPlan),
      subscriptionStatus: _mapIsarSubscriptionStatus(subscriptionStatus),
      isActive: isActive,
      currency: currency,
      locale: locale,
      timezone: timezone,
      subscriptionStartDate: subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate,
      trialStartDate: trialStartDate,
      trialEndDate: trialEndDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helpers para mapeo de enums
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

  // Helpers para serialización
  static String _encodeSettings(Map<String, dynamic> settings) {
    return settings.toString();
  }

  static Map<String, dynamic> _decodeSettings(String settingsJson) {
    return {};
  }

  // Métodos de utilidad
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

  Map<String, dynamic> get settingsMap =>
      settingsJson != null ? _decodeSettings(settingsJson!) : {};

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void updateSettings(Map<String, dynamic> newSettings) {
    settingsJson = _encodeSettings(newSettings);
    markAsUnsynced();
  }

  void updateSubscription(
    IsarSubscriptionPlan newPlan,
    IsarSubscriptionStatus newStatus,
  ) {
    subscriptionPlan = newPlan;
    subscriptionStatus = newStatus;
    markAsUnsynced();
  }

  @override
  String toString() {
    return 'IsarOrganization{serverId: $serverId, name: $name, plan: $subscriptionPlan, status: $subscriptionStatus, isSynced: $isSynced}';
  }
}
