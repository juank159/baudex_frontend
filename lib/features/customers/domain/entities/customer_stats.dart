// // lib/features/customers/domain/entities/customer_stats.dart
// import 'package:equatable/equatable.dart';

// class CustomerStats extends Equatable {
//   final int total;
//   final int active;
//   final int inactive;
//   final int suspended;
//   final double totalCreditLimit;
//   final double totalBalance;
//   final double activePercentage;
//   final int customersWithOverdue;
//   final double averagePurchaseAmount;

//   const CustomerStats({
//     required this.total,
//     required this.active,
//     required this.inactive,
//     required this.suspended,
//     required this.totalCreditLimit,
//     required this.totalBalance,
//     required this.activePercentage,
//     required this.customersWithOverdue,
//     required this.averagePurchaseAmount,
//   });

//   @override
//   List<Object?> get props => [
//     total,
//     active,
//     inactive,
//     suspended,
//     totalCreditLimit,
//     totalBalance,
//     activePercentage,
//     customersWithOverdue,
//     averagePurchaseAmount,
//   ];

//   // Getters útiles
//   double get totalCreditUsage =>
//       totalCreditLimit > 0 ? (totalBalance / totalCreditLimit) * 100 : 0;

//   int get totalInactive => inactive + suspended;

//   bool get hasRiskCustomers => customersWithOverdue > 0;

//   String get healthStatus {
//     if (activePercentage >= 90) return 'excellent';
//     if (activePercentage >= 75) return 'good';
//     if (activePercentage >= 50) return 'fair';
//     return 'poor';
//   }

//   CustomerStats copyWith({
//     int? total,
//     int? active,
//     int? inactive,
//     int? suspended,
//     double? totalCreditLimit,
//     double? totalBalance,
//     double? activePercentage,
//     int? customersWithOverdue,
//     double? averagePurchaseAmount,
//   }) {
//     return CustomerStats(
//       total: total ?? this.total,
//       active: active ?? this.active,
//       inactive: inactive ?? this.inactive,
//       suspended: suspended ?? this.suspended,
//       totalCreditLimit: totalCreditLimit ?? this.totalCreditLimit,
//       totalBalance: totalBalance ?? this.totalBalance,
//       activePercentage: activePercentage ?? this.activePercentage,
//       customersWithOverdue: customersWithOverdue ?? this.customersWithOverdue,
//       averagePurchaseAmount:
//           averagePurchaseAmount ?? this.averagePurchaseAmount,
//     );
//   }

//   @override
//   String toString() =>
//       'CustomerStats(total: $total, active: $active, inactive: $inactive)';
// }

// lib/features/customers/domain/entities/customer_stats.dart
import 'package:equatable/equatable.dart';

class CustomerStats extends Equatable {
  final int total;
  final int active;
  final int inactive;
  final int suspended;
  final double totalCreditLimit;
  final double totalBalance;
  final double activePercentage;
  final int customersWithOverdue;
  final double averagePurchaseAmount;

  const CustomerStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.suspended,
    required this.totalCreditLimit,
    required this.totalBalance,
    required this.activePercentage,
    required this.customersWithOverdue,
    required this.averagePurchaseAmount,
  });

  @override
  List<Object?> get props => [
    total,
    active,
    inactive,
    suspended,
    totalCreditLimit,
    totalBalance,
    activePercentage,
    customersWithOverdue,
    averagePurchaseAmount,
  ];

  // ==================== LÓGICA DE NEGOCIO (SOLO EN ENTIDAD) ====================

  /// Porcentaje de crédito utilizado
  double get totalCreditUsage =>
      totalCreditLimit > 0 ? (totalBalance / totalCreditLimit) * 100 : 0;

  /// Total de clientes inactivos (incluyendo suspendidos)
  int get totalInactive => inactive + suspended;

  /// Indica si hay clientes con riesgo crediticio
  bool get hasRiskCustomers => customersWithOverdue > 0;

  /// Estado general de salud de la cartera
  String get healthStatus {
    if (activePercentage >= 90) return 'excellent';
    if (activePercentage >= 75) return 'good';
    if (activePercentage >= 50) return 'fair';
    return 'poor';
  }

  /// Crédito disponible total
  double get availableCredit => totalCreditLimit - totalBalance;

  /// Porcentaje de clientes con deuda vencida
  double get overduePercentage {
    if (total <= 0) return 0.0;
    return (customersWithOverdue / total) * 100;
  }

  /// Indica si la situación crediticia es saludable
  bool get isCreditHealthy => totalCreditUsage < 80;

  /// Indica si hay muchos clientes inactivos
  bool get hasManyInactiveCustomers => totalInactive > (total * 0.2);

  /// Validar si los datos son consistentes
  bool get isValid {
    return total >= 0 &&
        active >= 0 &&
        inactive >= 0 &&
        suspended >= 0 &&
        total == (active + inactive + suspended) &&
        totalCreditLimit >= 0 &&
        totalBalance >= 0 &&
        activePercentage >= 0 &&
        activePercentage <= 100 &&
        customersWithOverdue >= 0 &&
        averagePurchaseAmount >= 0;
  }

  /// Obtener errores de validación
  List<String> get validationErrors {
    final errors = <String>[];

    if (total < 0) errors.add('Total no puede ser negativo');
    if (active < 0) errors.add('Clientes activos no puede ser negativo');
    if (inactive < 0) errors.add('Clientes inactivos no puede ser negativo');
    if (suspended < 0) errors.add('Clientes suspendidos no puede ser negativo');
    if (total != (active + inactive + suspended)) {
      errors.add('La suma de estados no coincide con el total');
    }
    if (totalCreditLimit < 0) {
      errors.add('Límite de crédito no puede ser negativo');
    }
    if (totalBalance < 0) errors.add('Balance no puede ser negativo');
    if (activePercentage < 0 || activePercentage > 100) {
      errors.add('Porcentaje activo debe estar entre 0 y 100');
    }
    if (customersWithOverdue < 0) {
      errors.add('Clientes con deuda vencida no puede ser negativo');
    }
    if (averagePurchaseAmount < 0) {
      errors.add('Promedio de compra no puede ser negativo');
    }

    return errors;
  }

  // ==================== COPYSWITH ====================

  CustomerStats copyWith({
    int? total,
    int? active,
    int? inactive,
    int? suspended,
    double? totalCreditLimit,
    double? totalBalance,
    double? activePercentage,
    int? customersWithOverdue,
    double? averagePurchaseAmount,
  }) {
    return CustomerStats(
      total: total ?? this.total,
      active: active ?? this.active,
      inactive: inactive ?? this.inactive,
      suspended: suspended ?? this.suspended,
      totalCreditLimit: totalCreditLimit ?? this.totalCreditLimit,
      totalBalance: totalBalance ?? this.totalBalance,
      activePercentage: activePercentage ?? this.activePercentage,
      customersWithOverdue: customersWithOverdue ?? this.customersWithOverdue,
      averagePurchaseAmount:
          averagePurchaseAmount ?? this.averagePurchaseAmount,
    );
  }

  @override
  String toString() =>
      'CustomerStats(total: $total, active: $active, inactive: $inactive, '
      'suspended: $suspended, creditLimit: \$${totalCreditLimit.toStringAsFixed(0)}, '
      'balance: \$${totalBalance.toStringAsFixed(0)}, activePercentage: ${activePercentage.toStringAsFixed(1)}%)';
}
