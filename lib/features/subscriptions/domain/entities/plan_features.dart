// lib/features/subscriptions/domain/entities/plan_features.dart

import 'package:equatable/equatable.dart';

/// Caracteristicas habilitadas por plan
class PlanFeatures extends Equatable {
  final bool canExportReports;
  final bool canExportPdf;
  final bool canExportExcel;
  final bool canUseThermalPrinter;
  final bool canAccessAdvancedReports;
  final bool canUseMultipleWarehouses;
  final bool canUseApiIntegrations;
  final bool canUseBulkOperations;
  final bool canUseCustomBranding;
  final bool canAccessAuditLogs;
  final bool canUseAdvancedInventory;
  final bool canUseCreditNotes;
  final bool canUseCustomerCredits;
  final bool canUsePurchaseOrders;
  final bool canUseMultipleCurrencies;
  final bool canUseAdvancedPricing;
  final bool canScheduleReports;
  final bool canUseEmailNotifications;
  final bool prioritySupport;

  const PlanFeatures({
    required this.canExportReports,
    required this.canExportPdf,
    required this.canExportExcel,
    required this.canUseThermalPrinter,
    required this.canAccessAdvancedReports,
    required this.canUseMultipleWarehouses,
    required this.canUseApiIntegrations,
    required this.canUseBulkOperations,
    required this.canUseCustomBranding,
    required this.canAccessAuditLogs,
    required this.canUseAdvancedInventory,
    required this.canUseCreditNotes,
    required this.canUseCustomerCredits,
    required this.canUsePurchaseOrders,
    required this.canUseMultipleCurrencies,
    required this.canUseAdvancedPricing,
    required this.canScheduleReports,
    required this.canUseEmailNotifications,
    required this.prioritySupport,
  });

  /// Features para plan trial
  static const trial = PlanFeatures(
    canExportReports: false,
    canExportPdf: true,
    canExportExcel: false,
    canUseThermalPrinter: false,
    canAccessAdvancedReports: false,
    canUseMultipleWarehouses: false,
    canUseApiIntegrations: false,
    canUseBulkOperations: false,
    canUseCustomBranding: false,
    canAccessAuditLogs: false,
    canUseAdvancedInventory: false,
    canUseCreditNotes: true,
    canUseCustomerCredits: true,
    canUsePurchaseOrders: false,
    canUseMultipleCurrencies: false,
    canUseAdvancedPricing: false,
    canScheduleReports: false,
    canUseEmailNotifications: false,
    prioritySupport: false,
  );

  /// Features para plan basico
  static const basic = PlanFeatures(
    canExportReports: true,
    canExportPdf: true,
    canExportExcel: true,
    canUseThermalPrinter: true,
    canAccessAdvancedReports: false,
    canUseMultipleWarehouses: false,
    canUseApiIntegrations: false,
    canUseBulkOperations: true,
    canUseCustomBranding: false,
    canAccessAuditLogs: false,
    canUseAdvancedInventory: true,
    canUseCreditNotes: true,
    canUseCustomerCredits: true,
    canUsePurchaseOrders: true,
    canUseMultipleCurrencies: false,
    canUseAdvancedPricing: false,
    canScheduleReports: false,
    canUseEmailNotifications: true,
    prioritySupport: false,
  );

  /// Features para plan premium
  static const premium = PlanFeatures(
    canExportReports: true,
    canExportPdf: true,
    canExportExcel: true,
    canUseThermalPrinter: true,
    canAccessAdvancedReports: true,
    canUseMultipleWarehouses: true,
    canUseApiIntegrations: false,
    canUseBulkOperations: true,
    canUseCustomBranding: true,
    canAccessAuditLogs: true,
    canUseAdvancedInventory: true,
    canUseCreditNotes: true,
    canUseCustomerCredits: true,
    canUsePurchaseOrders: true,
    canUseMultipleCurrencies: true,
    canUseAdvancedPricing: true,
    canScheduleReports: true,
    canUseEmailNotifications: true,
    prioritySupport: false,
  );

  /// Features para plan enterprise (todas las features)
  static const enterprise = PlanFeatures(
    canExportReports: true,
    canExportPdf: true,
    canExportExcel: true,
    canUseThermalPrinter: true,
    canAccessAdvancedReports: true,
    canUseMultipleWarehouses: true,
    canUseApiIntegrations: true,
    canUseBulkOperations: true,
    canUseCustomBranding: true,
    canAccessAuditLogs: true,
    canUseAdvancedInventory: true,
    canUseCreditNotes: true,
    canUseCustomerCredits: true,
    canUsePurchaseOrders: true,
    canUseMultipleCurrencies: true,
    canUseAdvancedPricing: true,
    canScheduleReports: true,
    canUseEmailNotifications: true,
    prioritySupport: true,
  );

  /// Verifica si una caracteristica especifica esta habilitada
  bool isFeatureEnabled(String featureName) {
    switch (featureName) {
      case 'export_reports':
        return canExportReports;
      case 'export_pdf':
        return canExportPdf;
      case 'export_excel':
        return canExportExcel;
      case 'thermal_printer':
        return canUseThermalPrinter;
      case 'advanced_reports':
        return canAccessAdvancedReports;
      case 'multiple_warehouses':
        return canUseMultipleWarehouses;
      case 'api_integrations':
        return canUseApiIntegrations;
      case 'bulk_operations':
        return canUseBulkOperations;
      case 'custom_branding':
        return canUseCustomBranding;
      case 'audit_logs':
        return canAccessAuditLogs;
      case 'advanced_inventory':
        return canUseAdvancedInventory;
      case 'credit_notes':
        return canUseCreditNotes;
      case 'customer_credits':
        return canUseCustomerCredits;
      case 'purchase_orders':
        return canUsePurchaseOrders;
      case 'multiple_currencies':
        return canUseMultipleCurrencies;
      case 'advanced_pricing':
        return canUseAdvancedPricing;
      case 'schedule_reports':
        return canScheduleReports;
      case 'email_notifications':
        return canUseEmailNotifications;
      default:
        return false;
    }
  }

  /// Obtener lista de features habilitadas
  List<String> get enabledFeatures {
    final features = <String>[];
    if (canExportReports) features.add('export_reports');
    if (canExportPdf) features.add('export_pdf');
    if (canExportExcel) features.add('export_excel');
    if (canUseThermalPrinter) features.add('thermal_printer');
    if (canAccessAdvancedReports) features.add('advanced_reports');
    if (canUseMultipleWarehouses) features.add('multiple_warehouses');
    if (canUseApiIntegrations) features.add('api_integrations');
    if (canUseBulkOperations) features.add('bulk_operations');
    if (canUseCustomBranding) features.add('custom_branding');
    if (canAccessAuditLogs) features.add('audit_logs');
    if (canUseAdvancedInventory) features.add('advanced_inventory');
    if (canUseCreditNotes) features.add('credit_notes');
    if (canUseCustomerCredits) features.add('customer_credits');
    if (canUsePurchaseOrders) features.add('purchase_orders');
    if (canUseMultipleCurrencies) features.add('multiple_currencies');
    if (canUseAdvancedPricing) features.add('advanced_pricing');
    if (canScheduleReports) features.add('schedule_reports');
    if (canUseEmailNotifications) features.add('email_notifications');
    return features;
  }

  @override
  List<Object?> get props => [
        canExportReports,
        canExportPdf,
        canExportExcel,
        canUseThermalPrinter,
        canAccessAdvancedReports,
        canUseMultipleWarehouses,
        canUseApiIntegrations,
        canUseBulkOperations,
        canUseCustomBranding,
        canAccessAuditLogs,
        canUseAdvancedInventory,
        canUseCreditNotes,
        canUseCustomerCredits,
        canUsePurchaseOrders,
        canUseMultipleCurrencies,
        canUseAdvancedPricing,
        canScheduleReports,
        canUseEmailNotifications,
        prioritySupport,
      ];

  PlanFeatures copyWith({
    bool? canExportReports,
    bool? canExportPdf,
    bool? canExportExcel,
    bool? canUseThermalPrinter,
    bool? canAccessAdvancedReports,
    bool? canUseMultipleWarehouses,
    bool? canUseApiIntegrations,
    bool? canUseBulkOperations,
    bool? canUseCustomBranding,
    bool? canAccessAuditLogs,
    bool? canUseAdvancedInventory,
    bool? canUseCreditNotes,
    bool? canUseCustomerCredits,
    bool? canUsePurchaseOrders,
    bool? canUseMultipleCurrencies,
    bool? canUseAdvancedPricing,
    bool? canScheduleReports,
    bool? canUseEmailNotifications,
    bool? prioritySupport,
  }) {
    return PlanFeatures(
      canExportReports: canExportReports ?? this.canExportReports,
      canExportPdf: canExportPdf ?? this.canExportPdf,
      canExportExcel: canExportExcel ?? this.canExportExcel,
      canUseThermalPrinter: canUseThermalPrinter ?? this.canUseThermalPrinter,
      canAccessAdvancedReports:
          canAccessAdvancedReports ?? this.canAccessAdvancedReports,
      canUseMultipleWarehouses:
          canUseMultipleWarehouses ?? this.canUseMultipleWarehouses,
      canUseApiIntegrations:
          canUseApiIntegrations ?? this.canUseApiIntegrations,
      canUseBulkOperations: canUseBulkOperations ?? this.canUseBulkOperations,
      canUseCustomBranding: canUseCustomBranding ?? this.canUseCustomBranding,
      canAccessAuditLogs: canAccessAuditLogs ?? this.canAccessAuditLogs,
      canUseAdvancedInventory:
          canUseAdvancedInventory ?? this.canUseAdvancedInventory,
      canUseCreditNotes: canUseCreditNotes ?? this.canUseCreditNotes,
      canUseCustomerCredits:
          canUseCustomerCredits ?? this.canUseCustomerCredits,
      canUsePurchaseOrders: canUsePurchaseOrders ?? this.canUsePurchaseOrders,
      canUseMultipleCurrencies:
          canUseMultipleCurrencies ?? this.canUseMultipleCurrencies,
      canUseAdvancedPricing:
          canUseAdvancedPricing ?? this.canUseAdvancedPricing,
      canScheduleReports: canScheduleReports ?? this.canScheduleReports,
      canUseEmailNotifications:
          canUseEmailNotifications ?? this.canUseEmailNotifications,
      prioritySupport: prioritySupport ?? this.prioritySupport,
    );
  }
}
