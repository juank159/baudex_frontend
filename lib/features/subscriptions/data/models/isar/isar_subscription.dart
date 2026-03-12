// lib/features/subscriptions/data/models/isar/isar_subscription.dart

import 'dart:convert';

import 'package:isar/isar.dart';
import '../../../domain/entities/subscription.dart';
import '../../../domain/entities/subscription_enums.dart';
import '../../../domain/entities/plan_limits.dart';
import '../../../domain/entities/plan_features.dart';

part 'isar_subscription.g.dart';

@collection
class IsarSubscription {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  late String organizationId;

  // Plan y estado
  @Enumerated(EnumType.name)
  late IsarSubscriptionPlan plan;

  late String planDisplayName;

  @Enumerated(EnumType.name)
  late IsarSubscriptionStatus status;

  @Enumerated(EnumType.name)
  late IsarSubscriptionType type;

  // Fechas
  late DateTime startDate;
  late DateTime endDate;

  // Estados calculados
  late bool isActive;
  late bool isExpired;
  late bool isTrial;
  late int daysUntilExpiration;
  late double subscriptionProgress;
  late int remainingDays;

  // Configuracion
  late int maxUsers;
  late bool autoRenew;
  late int billingCycle;

  // Pago (opcionales)
  double? price;
  String? currency;
  String? paymentMethod;
  DateTime? nextBillingDate;
  DateTime? trialEndsAt;

  // Limites serializados como JSON
  late String limitsJson;

  // Campos de sincronizacion
  late bool isSynced;
  DateTime? lastSyncAt;

  // Campos de versionamiento
  late int version;
  DateTime? lastModifiedAt;
  String? lastModifiedBy;

  // Campos de gracia offline
  DateTime? offlineGraceEnd;
  late bool wasExpiredOffline;

  // Constructor vacio requerido por ISAR
  IsarSubscription();

  // Constructor con nombre
  IsarSubscription.create({
    required this.serverId,
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
    required this.billingCycle,
    this.price,
    this.currency,
    this.paymentMethod,
    this.nextBillingDate,
    this.trialEndsAt,
    required this.limitsJson,
    this.isSynced = true,
    this.lastSyncAt,
    this.version = 0,
    this.lastModifiedAt,
    this.lastModifiedBy,
    this.offlineGraceEnd,
    this.wasExpiredOffline = false,
  });

  // ==================== MAPPERS ====================

  static IsarSubscription fromEntity(Subscription entity) {
    return IsarSubscription.create(
      serverId: entity.id,
      organizationId: entity.organizationId,
      plan: _mapPlanToIsar(entity.plan),
      planDisplayName: entity.planDisplayName,
      status: _mapStatusToIsar(entity.status),
      type: _mapTypeToIsar(entity.type),
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
      billingCycle: entity.billingCycle,
      price: entity.price,
      currency: entity.currency,
      paymentMethod: entity.paymentMethod,
      nextBillingDate: entity.nextBillingDate,
      trialEndsAt: entity.trialEndsAt,
      limitsJson: _encodeLimits(entity.limits),
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  Subscription toEntity() {
    return Subscription(
      id: serverId,
      organizationId: organizationId,
      plan: _mapIsarToPlan(plan),
      planDisplayName: planDisplayName,
      status: _mapIsarToStatus(status),
      type: _mapIsarToType(type),
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
      billingCycle: billingCycle,
      price: price,
      currency: currency,
      paymentMethod: paymentMethod,
      nextBillingDate: nextBillingDate,
      trialEndsAt: trialEndsAt,
      limits: _decodeLimits(limitsJson),
    );
  }

  /// Actualizar desde entidad
  void updateFromEntity(Subscription entity) {
    plan = _mapPlanToIsar(entity.plan);
    planDisplayName = entity.planDisplayName;
    status = _mapStatusToIsar(entity.status);
    type = _mapTypeToIsar(entity.type);
    startDate = entity.startDate;
    endDate = entity.endDate;
    isActive = entity.isActive;
    isExpired = entity.isExpired;
    isTrial = entity.isTrial;
    daysUntilExpiration = entity.daysUntilExpiration;
    subscriptionProgress = entity.subscriptionProgress;
    remainingDays = entity.remainingDays;
    maxUsers = entity.maxUsers;
    autoRenew = entity.autoRenew;
    billingCycle = entity.billingCycle;
    price = entity.price;
    currency = entity.currency;
    paymentMethod = entity.paymentMethod;
    nextBillingDate = entity.nextBillingDate;
    trialEndsAt = entity.trialEndsAt;
    limitsJson = _encodeLimits(entity.limits);
    markAsSynced();
  }

  // ==================== SERIALIZATION ====================

  static String _encodeLimits(PlanLimits limits) {
    try {
      final map = {
        'maxProducts': limits.maxProducts,
        'maxCustomers': limits.maxCustomers,
        'maxInvoicesPerMonth': limits.maxInvoicesPerMonth,
        'maxUsers': limits.maxUsers,
        'maxStorageMB': limits.maxStorageMB,
        'maxExpensesPerMonth': limits.maxExpensesPerMonth,
        'maxCategoriesPerLevel': limits.maxCategoriesPerLevel,
        'features': _encodeFeatures(limits.features),
      };
      return jsonEncode(map);
    } catch (e) {
      return '{}';
    }
  }

  static Map<String, dynamic> _encodeFeatures(PlanFeatures features) {
    return {
      'canExportReports': features.canExportReports,
      'canExportPdf': features.canExportPdf,
      'canExportExcel': features.canExportExcel,
      'canUseThermalPrinter': features.canUseThermalPrinter,
      'canAccessAdvancedReports': features.canAccessAdvancedReports,
      'canUseMultipleWarehouses': features.canUseMultipleWarehouses,
      'canUseApiIntegrations': features.canUseApiIntegrations,
      'canUseBulkOperations': features.canUseBulkOperations,
      'canUseCustomBranding': features.canUseCustomBranding,
      'canAccessAuditLogs': features.canAccessAuditLogs,
      'canUseAdvancedInventory': features.canUseAdvancedInventory,
      'canUseCreditNotes': features.canUseCreditNotes,
      'canUseCustomerCredits': features.canUseCustomerCredits,
      'canUsePurchaseOrders': features.canUsePurchaseOrders,
      'canUseMultipleCurrencies': features.canUseMultipleCurrencies,
      'canUseAdvancedPricing': features.canUseAdvancedPricing,
      'canScheduleReports': features.canScheduleReports,
      'canUseEmailNotifications': features.canUseEmailNotifications,
      'prioritySupport': features.prioritySupport,
    };
  }

  static PlanLimits _decodeLimits(String? limitsJson) {
    if (limitsJson == null || limitsJson.isEmpty || limitsJson == '{}') {
      return PlanLimits.trial;
    }
    try {
      final decoded = jsonDecode(limitsJson);
      if (decoded is! Map<String, dynamic>) {
        return PlanLimits.trial;
      }

      final featuresMap = decoded['features'] as Map<String, dynamic>?;
      final features = featuresMap != null
          ? PlanFeatures(
              canExportReports: featuresMap['canExportReports'] as bool? ?? false,
              canExportPdf: featuresMap['canExportPdf'] as bool? ?? false,
              canExportExcel: featuresMap['canExportExcel'] as bool? ?? false,
              canUseThermalPrinter: featuresMap['canUseThermalPrinter'] as bool? ?? false,
              canAccessAdvancedReports: featuresMap['canAccessAdvancedReports'] as bool? ?? false,
              canUseMultipleWarehouses: featuresMap['canUseMultipleWarehouses'] as bool? ?? false,
              canUseApiIntegrations: featuresMap['canUseApiIntegrations'] as bool? ?? false,
              canUseBulkOperations: featuresMap['canUseBulkOperations'] as bool? ?? false,
              canUseCustomBranding: featuresMap['canUseCustomBranding'] as bool? ?? false,
              canAccessAuditLogs: featuresMap['canAccessAuditLogs'] as bool? ?? false,
              canUseAdvancedInventory: featuresMap['canUseAdvancedInventory'] as bool? ?? false,
              canUseCreditNotes: featuresMap['canUseCreditNotes'] as bool? ?? false,
              canUseCustomerCredits: featuresMap['canUseCustomerCredits'] as bool? ?? false,
              canUsePurchaseOrders: featuresMap['canUsePurchaseOrders'] as bool? ?? false,
              canUseMultipleCurrencies: featuresMap['canUseMultipleCurrencies'] as bool? ?? false,
              canUseAdvancedPricing: featuresMap['canUseAdvancedPricing'] as bool? ?? false,
              canScheduleReports: featuresMap['canScheduleReports'] as bool? ?? false,
              canUseEmailNotifications: featuresMap['canUseEmailNotifications'] as bool? ?? false,
              prioritySupport: featuresMap['prioritySupport'] as bool? ?? false,
            )
          : PlanFeatures.trial;

      return PlanLimits(
        maxProducts: decoded['maxProducts'] as int? ?? 0,
        maxCustomers: decoded['maxCustomers'] as int? ?? 0,
        maxInvoicesPerMonth: decoded['maxInvoicesPerMonth'] as int? ?? 0,
        maxUsers: decoded['maxUsers'] as int? ?? 0,
        maxStorageMB: decoded['maxStorageMB'] as int? ?? 0,
        maxExpensesPerMonth: decoded['maxExpensesPerMonth'] as int? ?? 0,
        maxCategoriesPerLevel: decoded['maxCategoriesPerLevel'] as int? ?? 0,
        features: features,
      );
    } catch (e) {
      return PlanLimits.trial;
    }
  }

  // ==================== ENUM MAPPERS ====================

  static IsarSubscriptionPlan _mapPlanToIsar(SubscriptionPlan plan) {
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

  static SubscriptionPlan _mapIsarToPlan(IsarSubscriptionPlan plan) {
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

  static IsarSubscriptionStatus _mapStatusToIsar(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return IsarSubscriptionStatus.active;
      case SubscriptionStatus.expired:
        return IsarSubscriptionStatus.expired;
      case SubscriptionStatus.cancelled:
        return IsarSubscriptionStatus.cancelled;
      case SubscriptionStatus.suspended:
        return IsarSubscriptionStatus.suspended;
      case SubscriptionStatus.pending:
        return IsarSubscriptionStatus.pending;
    }
  }

  static SubscriptionStatus _mapIsarToStatus(IsarSubscriptionStatus status) {
    switch (status) {
      case IsarSubscriptionStatus.active:
        return SubscriptionStatus.active;
      case IsarSubscriptionStatus.expired:
        return SubscriptionStatus.expired;
      case IsarSubscriptionStatus.cancelled:
        return SubscriptionStatus.cancelled;
      case IsarSubscriptionStatus.suspended:
        return SubscriptionStatus.suspended;
      case IsarSubscriptionStatus.pending:
        return SubscriptionStatus.pending;
    }
  }

  static IsarSubscriptionType _mapTypeToIsar(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.trial:
        return IsarSubscriptionType.trial;
      case SubscriptionType.monthly:
        return IsarSubscriptionType.monthly;
      case SubscriptionType.annual:
        return IsarSubscriptionType.annual;
      case SubscriptionType.lifetime:
        return IsarSubscriptionType.lifetime;
    }
  }

  static SubscriptionType _mapIsarToType(IsarSubscriptionType type) {
    switch (type) {
      case IsarSubscriptionType.trial:
        return SubscriptionType.trial;
      case IsarSubscriptionType.monthly:
        return SubscriptionType.monthly;
      case IsarSubscriptionType.annual:
        return SubscriptionType.annual;
      case IsarSubscriptionType.lifetime:
        return SubscriptionType.lifetime;
    }
  }

  // ==================== UTILITY METHODS ====================

  bool get needsSync => !isSynced;

  void markAsUnsynced() {
    isSynced = false;
    lastModifiedAt = DateTime.now();
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void incrementVersion({String? modifiedBy}) {
    version++;
    lastModifiedAt = DateTime.now();
    if (modifiedBy != null) {
      lastModifiedBy = modifiedBy;
    }
    isSynced = false;
  }

  /// Verificar si esta en periodo de gracia offline
  bool get isInOfflineGracePeriod {
    if (offlineGraceEnd == null) return false;
    return DateTime.now().isBefore(offlineGraceEnd!);
  }

  /// Establecer periodo de gracia offline (3 dias por defecto)
  void setOfflineGracePeriod({int days = 3}) {
    offlineGraceEnd = DateTime.now().add(Duration(days: days));
  }

  @override
  String toString() {
    return 'IsarSubscription{serverId: $serverId, plan: $plan, status: $status, isActive: $isActive, isSynced: $isSynced}';
  }
}

// ==================== ISAR ENUMS ====================

enum IsarSubscriptionPlan {
  trial,
  basic,
  premium,
  enterprise,
}

enum IsarSubscriptionStatus {
  active,
  expired,
  cancelled,
  suspended,
  pending,
}

enum IsarSubscriptionType {
  trial,
  monthly,
  annual,
  lifetime,
}
