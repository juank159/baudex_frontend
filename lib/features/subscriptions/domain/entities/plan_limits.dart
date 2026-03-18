// lib/features/subscriptions/domain/entities/plan_limits.dart

import 'package:equatable/equatable.dart';
import 'plan_features.dart';
import 'subscription_enums.dart';

/// Limites de recursos por plan de suscripcion
/// -1 significa ilimitado
class PlanLimits extends Equatable {
  final int maxProducts;
  final int maxCustomers;
  final int maxInvoicesPerMonth;
  final int maxUsers;
  final int maxDevices;
  final int maxStorageMB;
  final int maxExpensesPerMonth;
  final int maxCategoriesPerLevel;
  final PlanFeatures features;

  const PlanLimits({
    required this.maxProducts,
    required this.maxCustomers,
    required this.maxInvoicesPerMonth,
    required this.maxUsers,
    this.maxDevices = 2,
    required this.maxStorageMB,
    required this.maxExpensesPerMonth,
    required this.maxCategoriesPerLevel,
    required this.features,
  });

  /// Limites para plan trial (2 dispositivos)
  static const trial = PlanLimits(
    maxProducts: -1,
    maxCustomers: -1,
    maxInvoicesPerMonth: -1,
    maxUsers: -1,
    maxDevices: 2,
    maxStorageMB: -1,
    maxExpensesPerMonth: -1,
    maxCategoriesPerLevel: -1,
    features: PlanFeatures.allEnabled,
  );

  /// Limites para plan basico (5 dispositivos)
  static const basic = PlanLimits(
    maxProducts: -1,
    maxCustomers: -1,
    maxInvoicesPerMonth: -1,
    maxUsers: -1,
    maxDevices: 5,
    maxStorageMB: -1,
    maxExpensesPerMonth: -1,
    maxCategoriesPerLevel: -1,
    features: PlanFeatures.allEnabled,
  );

  /// Limites para plan premium (10 dispositivos)
  static const premium = PlanLimits(
    maxProducts: -1,
    maxCustomers: -1,
    maxInvoicesPerMonth: -1,
    maxUsers: -1,
    maxDevices: 10,
    maxStorageMB: -1,
    maxExpensesPerMonth: -1,
    maxCategoriesPerLevel: -1,
    features: PlanFeatures.allEnabled,
  );

  /// Limites para plan enterprise (todo ilimitado)
  static const enterprise = PlanLimits(
    maxProducts: -1,
    maxCustomers: -1,
    maxInvoicesPerMonth: -1,
    maxUsers: -1,
    maxDevices: -1,
    maxStorageMB: -1,
    maxExpensesPerMonth: -1,
    maxCategoriesPerLevel: -1,
    features: PlanFeatures.allEnabled,
  );

  /// Obtener limites para un plan especifico
  static PlanLimits forPlan(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.trial:
        return trial;
      case SubscriptionPlan.basic:
        return basic;
      case SubscriptionPlan.premium:
        return premium;
      case SubscriptionPlan.enterprise:
        return enterprise;
    }
  }

  /// Verificar si un limite es ilimitado
  static bool isUnlimited(int limit) => limit == -1;

  /// Verificar si el limite de productos es ilimitado
  bool get hasUnlimitedProducts => isUnlimited(maxProducts);

  /// Verificar si el limite de clientes es ilimitado
  bool get hasUnlimitedCustomers => isUnlimited(maxCustomers);

  /// Verificar si el limite de facturas es ilimitado
  bool get hasUnlimitedInvoices => isUnlimited(maxInvoicesPerMonth);

  /// Verificar si el limite de usuarios es ilimitado
  bool get hasUnlimitedUsers => isUnlimited(maxUsers);

  /// Verificar si el limite de dispositivos es ilimitado
  bool get hasUnlimitedDevices => isUnlimited(maxDevices);

  /// Verificar si el almacenamiento es ilimitado
  bool get hasUnlimitedStorage => isUnlimited(maxStorageMB);

  /// Verificar si todos los recursos principales son ilimitados
  bool get isFullyUnlimited =>
      hasUnlimitedProducts &&
      hasUnlimitedCustomers &&
      hasUnlimitedInvoices &&
      hasUnlimitedUsers &&
      hasUnlimitedStorage;

  /// Obtener el porcentaje de uso
  static double getUsagePercentage(int current, int limit) {
    if (isUnlimited(limit)) return 0.0;
    if (limit == 0) return 100.0;
    return (current / limit * 100).clamp(0.0, 100.0);
  }

  /// Verificar si esta cerca del limite (>= 80%)
  static bool isNearLimit(int current, int limit) {
    if (isUnlimited(limit)) return false;
    return getUsagePercentage(current, limit) >= 80;
  }

  /// Verificar si ha alcanzado el limite
  static bool hasReachedLimit(int current, int limit) {
    if (isUnlimited(limit)) return false;
    return current >= limit;
  }

  /// Verificar si puede agregar un elemento mas
  bool canAddProduct(int currentCount) =>
      hasUnlimitedProducts || currentCount < maxProducts;

  bool canAddCustomer(int currentCount) =>
      hasUnlimitedCustomers || currentCount < maxCustomers;

  bool canAddInvoice(int currentMonthCount) =>
      hasUnlimitedInvoices || currentMonthCount < maxInvoicesPerMonth;

  bool canAddUser(int currentCount) =>
      hasUnlimitedUsers || currentCount < maxUsers;

  bool canAddExpense(int currentMonthCount) =>
      isUnlimited(maxExpensesPerMonth) ||
      currentMonthCount < maxExpensesPerMonth;

  @override
  List<Object?> get props => [
        maxProducts,
        maxCustomers,
        maxInvoicesPerMonth,
        maxUsers,
        maxDevices,
        maxStorageMB,
        maxExpensesPerMonth,
        maxCategoriesPerLevel,
        features,
      ];

  PlanLimits copyWith({
    int? maxProducts,
    int? maxCustomers,
    int? maxInvoicesPerMonth,
    int? maxUsers,
    int? maxDevices,
    int? maxStorageMB,
    int? maxExpensesPerMonth,
    int? maxCategoriesPerLevel,
    PlanFeatures? features,
  }) {
    return PlanLimits(
      maxProducts: maxProducts ?? this.maxProducts,
      maxCustomers: maxCustomers ?? this.maxCustomers,
      maxInvoicesPerMonth: maxInvoicesPerMonth ?? this.maxInvoicesPerMonth,
      maxUsers: maxUsers ?? this.maxUsers,
      maxDevices: maxDevices ?? this.maxDevices,
      maxStorageMB: maxStorageMB ?? this.maxStorageMB,
      maxExpensesPerMonth: maxExpensesPerMonth ?? this.maxExpensesPerMonth,
      maxCategoriesPerLevel:
          maxCategoriesPerLevel ?? this.maxCategoriesPerLevel,
      features: features ?? this.features,
    );
  }
}
