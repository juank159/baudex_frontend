// lib/features/subscriptions/domain/entities/subscription_usage.dart

import 'package:equatable/equatable.dart';
import 'subscription_enums.dart';

/// Uso de un recurso individual
class ResourceUsage extends Equatable {
  final int current;
  final int limit;
  final bool isUnlimited;
  final double percentage;
  final bool isNearLimit;
  final bool hasReachedLimit;

  const ResourceUsage({
    required this.current,
    required this.limit,
    required this.isUnlimited,
    required this.percentage,
    required this.isNearLimit,
    required this.hasReachedLimit,
  });

  /// Crear ResourceUsage desde valores
  factory ResourceUsage.fromValues(int current, int limit) {
    final unlimited = limit == -1;
    final pct = unlimited ? 0.0 : (limit > 0 ? (current / limit * 100) : 100.0);

    return ResourceUsage(
      current: current,
      limit: limit,
      isUnlimited: unlimited,
      percentage: pct.clamp(0.0, 100.0),
      isNearLimit: !unlimited && pct >= 80,
      hasReachedLimit: !unlimited && current >= limit,
    );
  }

  /// Cantidad disponible
  int get available => isUnlimited ? -1 : (limit - current).clamp(0, limit);

  /// Texto de uso formateado
  String get usageText {
    if (isUnlimited) return '$current / Ilimitado';
    return '$current / $limit';
  }

  @override
  List<Object?> get props => [
        current,
        limit,
        isUnlimited,
        percentage,
        isNearLimit,
        hasReachedLimit,
      ];
}

/// Advertencia de uso
class UsageWarning extends Equatable {
  final String resource;
  final UsageWarningType type;
  final String message;
  final double percentage;

  const UsageWarning({
    required this.resource,
    required this.type,
    required this.message,
    required this.percentage,
  });

  @override
  List<Object?> get props => [resource, type, message, percentage];
}

enum UsageWarningType {
  nearLimit,
  atLimit,
  overLimit,
}

extension UsageWarningTypeExtension on UsageWarningType {
  String get displayName {
    switch (this) {
      case UsageWarningType.nearLimit:
        return 'Cerca del limite';
      case UsageWarningType.atLimit:
        return 'Limite alcanzado';
      case UsageWarningType.overLimit:
        return 'Limite excedido';
    }
  }
}

/// Uso completo de la suscripcion
class SubscriptionUsage extends Equatable {
  final SubscriptionPlan plan;
  final String planDisplayName;
  final bool hasUnlimitedResources;
  final ResourceUsage products;
  final ResourceUsage customers;
  final ResourceUsage users;
  final ResourceUsage invoicesThisMonth;
  final ResourceUsage expensesThisMonth;
  final ResourceUsage storage;
  final List<UsageWarning> warnings;
  final int daysUntilExpiration;
  final DateTime? nextRenewalDate;

  const SubscriptionUsage({
    required this.plan,
    required this.planDisplayName,
    required this.hasUnlimitedResources,
    required this.products,
    required this.customers,
    required this.users,
    required this.invoicesThisMonth,
    required this.expensesThisMonth,
    required this.storage,
    required this.warnings,
    required this.daysUntilExpiration,
    this.nextRenewalDate,
  });

  /// Verificar si hay advertencias
  bool get hasWarnings => warnings.isNotEmpty;

  /// Verificar si hay advertencias criticas (at_limit o over_limit)
  bool get hasCriticalWarnings => warnings.any(
        (w) =>
            w.type == UsageWarningType.atLimit ||
            w.type == UsageWarningType.overLimit,
      );

  /// Obtener el recurso mas usado (mayor porcentaje)
  ResourceUsage get mostUsedResource {
    final resources = [
      products,
      customers,
      users,
      invoicesThisMonth,
      expensesThisMonth,
      storage,
    ];

    return resources.reduce((a, b) {
      if (a.isUnlimited && b.isUnlimited) return a;
      if (a.isUnlimited) return b;
      if (b.isUnlimited) return a;
      return a.percentage >= b.percentage ? a : b;
    });
  }

  /// Obtener porcentaje de uso global (promedio de recursos con limite)
  double get overallUsagePercentage {
    final limitedResources = [
      products,
      customers,
      users,
      invoicesThisMonth,
      expensesThisMonth,
      storage,
    ].where((r) => !r.isUnlimited).toList();

    if (limitedResources.isEmpty) return 0.0;

    final total = limitedResources.fold<double>(
      0.0,
      (sum, r) => sum + r.percentage,
    );
    return total / limitedResources.length;
  }

  @override
  List<Object?> get props => [
        plan,
        planDisplayName,
        hasUnlimitedResources,
        products,
        customers,
        users,
        invoicesThisMonth,
        expensesThisMonth,
        storage,
        warnings,
        daysUntilExpiration,
        nextRenewalDate,
      ];

  SubscriptionUsage copyWith({
    SubscriptionPlan? plan,
    String? planDisplayName,
    bool? hasUnlimitedResources,
    ResourceUsage? products,
    ResourceUsage? customers,
    ResourceUsage? users,
    ResourceUsage? invoicesThisMonth,
    ResourceUsage? expensesThisMonth,
    ResourceUsage? storage,
    List<UsageWarning>? warnings,
    int? daysUntilExpiration,
    DateTime? nextRenewalDate,
  }) {
    return SubscriptionUsage(
      plan: plan ?? this.plan,
      planDisplayName: planDisplayName ?? this.planDisplayName,
      hasUnlimitedResources:
          hasUnlimitedResources ?? this.hasUnlimitedResources,
      products: products ?? this.products,
      customers: customers ?? this.customers,
      users: users ?? this.users,
      invoicesThisMonth: invoicesThisMonth ?? this.invoicesThisMonth,
      expensesThisMonth: expensesThisMonth ?? this.expensesThisMonth,
      storage: storage ?? this.storage,
      warnings: warnings ?? this.warnings,
      daysUntilExpiration: daysUntilExpiration ?? this.daysUntilExpiration,
      nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
    );
  }
}
