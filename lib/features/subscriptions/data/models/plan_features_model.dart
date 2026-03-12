// lib/features/subscriptions/data/models/plan_features_model.dart

import '../../domain/entities/plan_features.dart';

class PlanFeaturesModel extends PlanFeatures {
  const PlanFeaturesModel({
    required super.canExportReports,
    required super.canExportPdf,
    required super.canExportExcel,
    required super.canUseThermalPrinter,
    required super.canAccessAdvancedReports,
    required super.canUseMultipleWarehouses,
    required super.canUseApiIntegrations,
    required super.canUseBulkOperations,
    required super.canUseCustomBranding,
    required super.canAccessAuditLogs,
    required super.canUseAdvancedInventory,
    required super.canUseCreditNotes,
    required super.canUseCustomerCredits,
    required super.canUsePurchaseOrders,
    required super.canUseMultipleCurrencies,
    required super.canUseAdvancedPricing,
    required super.canScheduleReports,
    required super.canUseEmailNotifications,
    required super.prioritySupport,
  });

  factory PlanFeaturesModel.fromJson(Map<String, dynamic> json) {
    return PlanFeaturesModel(
      canExportReports: json['canExportReports'] as bool? ?? false,
      canExportPdf: json['canExportPdf'] as bool? ?? false,
      canExportExcel: json['canExportExcel'] as bool? ?? false,
      canUseThermalPrinter: json['canUseThermalPrinter'] as bool? ?? false,
      canAccessAdvancedReports:
          json['canAccessAdvancedReports'] as bool? ?? false,
      canUseMultipleWarehouses:
          json['canUseMultipleWarehouses'] as bool? ?? false,
      canUseApiIntegrations: json['canUseApiIntegrations'] as bool? ?? false,
      canUseBulkOperations: json['canUseBulkOperations'] as bool? ?? false,
      canUseCustomBranding: json['canUseCustomBranding'] as bool? ?? false,
      canAccessAuditLogs: json['canAccessAuditLogs'] as bool? ?? false,
      canUseAdvancedInventory:
          json['canUseAdvancedInventory'] as bool? ?? false,
      canUseCreditNotes: json['canUseCreditNotes'] as bool? ?? false,
      canUseCustomerCredits: json['canUseCustomerCredits'] as bool? ?? false,
      canUsePurchaseOrders: json['canUsePurchaseOrders'] as bool? ?? false,
      canUseMultipleCurrencies:
          json['canUseMultipleCurrencies'] as bool? ?? false,
      canUseAdvancedPricing: json['canUseAdvancedPricing'] as bool? ?? false,
      canScheduleReports: json['canScheduleReports'] as bool? ?? false,
      canUseEmailNotifications:
          json['canUseEmailNotifications'] as bool? ?? false,
      prioritySupport: json['prioritySupport'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canExportReports': canExportReports,
      'canExportPdf': canExportPdf,
      'canExportExcel': canExportExcel,
      'canUseThermalPrinter': canUseThermalPrinter,
      'canAccessAdvancedReports': canAccessAdvancedReports,
      'canUseMultipleWarehouses': canUseMultipleWarehouses,
      'canUseApiIntegrations': canUseApiIntegrations,
      'canUseBulkOperations': canUseBulkOperations,
      'canUseCustomBranding': canUseCustomBranding,
      'canAccessAuditLogs': canAccessAuditLogs,
      'canUseAdvancedInventory': canUseAdvancedInventory,
      'canUseCreditNotes': canUseCreditNotes,
      'canUseCustomerCredits': canUseCustomerCredits,
      'canUsePurchaseOrders': canUsePurchaseOrders,
      'canUseMultipleCurrencies': canUseMultipleCurrencies,
      'canUseAdvancedPricing': canUseAdvancedPricing,
      'canScheduleReports': canScheduleReports,
      'canUseEmailNotifications': canUseEmailNotifications,
      'prioritySupport': prioritySupport,
    };
  }

  PlanFeatures toEntity() {
    return PlanFeatures(
      canExportReports: canExportReports,
      canExportPdf: canExportPdf,
      canExportExcel: canExportExcel,
      canUseThermalPrinter: canUseThermalPrinter,
      canAccessAdvancedReports: canAccessAdvancedReports,
      canUseMultipleWarehouses: canUseMultipleWarehouses,
      canUseApiIntegrations: canUseApiIntegrations,
      canUseBulkOperations: canUseBulkOperations,
      canUseCustomBranding: canUseCustomBranding,
      canAccessAuditLogs: canAccessAuditLogs,
      canUseAdvancedInventory: canUseAdvancedInventory,
      canUseCreditNotes: canUseCreditNotes,
      canUseCustomerCredits: canUseCustomerCredits,
      canUsePurchaseOrders: canUsePurchaseOrders,
      canUseMultipleCurrencies: canUseMultipleCurrencies,
      canUseAdvancedPricing: canUseAdvancedPricing,
      canScheduleReports: canScheduleReports,
      canUseEmailNotifications: canUseEmailNotifications,
      prioritySupport: prioritySupport,
    );
  }

  factory PlanFeaturesModel.fromEntity(PlanFeatures entity) {
    return PlanFeaturesModel(
      canExportReports: entity.canExportReports,
      canExportPdf: entity.canExportPdf,
      canExportExcel: entity.canExportExcel,
      canUseThermalPrinter: entity.canUseThermalPrinter,
      canAccessAdvancedReports: entity.canAccessAdvancedReports,
      canUseMultipleWarehouses: entity.canUseMultipleWarehouses,
      canUseApiIntegrations: entity.canUseApiIntegrations,
      canUseBulkOperations: entity.canUseBulkOperations,
      canUseCustomBranding: entity.canUseCustomBranding,
      canAccessAuditLogs: entity.canAccessAuditLogs,
      canUseAdvancedInventory: entity.canUseAdvancedInventory,
      canUseCreditNotes: entity.canUseCreditNotes,
      canUseCustomerCredits: entity.canUseCustomerCredits,
      canUsePurchaseOrders: entity.canUsePurchaseOrders,
      canUseMultipleCurrencies: entity.canUseMultipleCurrencies,
      canUseAdvancedPricing: entity.canUseAdvancedPricing,
      canScheduleReports: entity.canScheduleReports,
      canUseEmailNotifications: entity.canUseEmailNotifications,
      prioritySupport: entity.prioritySupport,
    );
  }
}
