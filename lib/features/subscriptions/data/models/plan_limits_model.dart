// lib/features/subscriptions/data/models/plan_limits_model.dart

import '../../domain/entities/plan_limits.dart';
import '../../domain/entities/plan_features.dart';
import 'plan_features_model.dart';

class PlanLimitsModel extends PlanLimits {
  const PlanLimitsModel({
    required super.maxProducts,
    required super.maxCustomers,
    required super.maxInvoicesPerMonth,
    required super.maxUsers,
    super.maxDevices = 2,
    required super.maxStorageMB,
    required super.maxExpensesPerMonth,
    required super.maxCategoriesPerLevel,
    required super.features,
  });

  factory PlanLimitsModel.fromJson(Map<String, dynamic> json) {
    return PlanLimitsModel(
      maxProducts: json['maxProducts'] as int? ?? 0,
      maxCustomers: json['maxCustomers'] as int? ?? 0,
      maxInvoicesPerMonth: json['maxInvoicesPerMonth'] as int? ?? 0,
      maxUsers: json['maxUsers'] as int? ?? 0,
      maxDevices: json['maxDevices'] as int? ?? 2,
      maxStorageMB: json['maxStorageMB'] as int? ?? 0,
      maxExpensesPerMonth: json['maxExpensesPerMonth'] as int? ?? 0,
      maxCategoriesPerLevel: json['maxCategoriesPerLevel'] as int? ?? 0,
      features: json['features'] != null
          ? PlanFeaturesModel.fromJson(
              json['features'] as Map<String, dynamic>,
            )
          : PlanFeatures.trial,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxProducts': maxProducts,
      'maxCustomers': maxCustomers,
      'maxInvoicesPerMonth': maxInvoicesPerMonth,
      'maxUsers': maxUsers,
      'maxDevices': maxDevices,
      'maxStorageMB': maxStorageMB,
      'maxExpensesPerMonth': maxExpensesPerMonth,
      'maxCategoriesPerLevel': maxCategoriesPerLevel,
      'features': PlanFeaturesModel.fromEntity(features).toJson(),
    };
  }

  PlanLimits toEntity() {
    return PlanLimits(
      maxProducts: maxProducts,
      maxCustomers: maxCustomers,
      maxInvoicesPerMonth: maxInvoicesPerMonth,
      maxUsers: maxUsers,
      maxDevices: maxDevices,
      maxStorageMB: maxStorageMB,
      maxExpensesPerMonth: maxExpensesPerMonth,
      maxCategoriesPerLevel: maxCategoriesPerLevel,
      features: features,
    );
  }

  factory PlanLimitsModel.fromEntity(PlanLimits entity) {
    return PlanLimitsModel(
      maxProducts: entity.maxProducts,
      maxCustomers: entity.maxCustomers,
      maxInvoicesPerMonth: entity.maxInvoicesPerMonth,
      maxUsers: entity.maxUsers,
      maxDevices: entity.maxDevices,
      maxStorageMB: entity.maxStorageMB,
      maxExpensesPerMonth: entity.maxExpensesPerMonth,
      maxCategoriesPerLevel: entity.maxCategoriesPerLevel,
      features: entity.features,
    );
  }
}
