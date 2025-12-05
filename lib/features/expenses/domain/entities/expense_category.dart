// lib/features/expenses/domain/entities/expense_category.dart
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:equatable/equatable.dart';

enum ExpenseCategoryStatus { active, inactive }

class ExpenseCategory extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? color; // Código hexadecimal para UI
  final ExpenseCategoryStatus status;
  final double monthlyBudget; // Presupuesto mensual para esta categoría
  final bool isRequired; // Categoría obligatoria que no se puede eliminar
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Estadísticas (opcionales, solo cuando se carga con stats)
  final double? monthlySpent; // Gasto del mes actual
  final double? budgetUtilization; // Porcentaje de utilización del presupuesto

  const ExpenseCategory({
    required this.id,
    required this.name,
    this.description,
    this.color,
    required this.status,
    required this.monthlyBudget,
    required this.isRequired,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.monthlySpent,
    this.budgetUtilization,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    color,
    status,
    monthlyBudget,
    isRequired,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
    monthlySpent,
    budgetUtilization,
  ];

  // Getters útiles
  bool get isActive =>
      status == ExpenseCategoryStatus.active && deletedAt == null;

  String get statusDisplayName {
    switch (status) {
      case ExpenseCategoryStatus.active:
        return 'Activa';
      case ExpenseCategoryStatus.inactive:
        return 'Inactiva';
    }
  }

  String get formattedBudget {
    return AppFormatters.formatCurrency(monthlyBudget);
  }

  String get formattedMonthlySpent {
    return AppFormatters.formatCurrency(monthlySpent ?? 0);
  }

  double get utilizationPercentage {
    return budgetUtilization ?? 0;
  }

  bool get hasStats {
    return monthlySpent != null && budgetUtilization != null;
  }

  bool get isOverBudget {
    return hasStats && (monthlySpent! > monthlyBudget);
  }

  bool get isNearBudgetLimit {
    return hasStats && utilizationPercentage >= 80 && utilizationPercentage < 100;
  }

  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    ExpenseCategoryStatus? status,
    double? monthlyBudget,
    bool? isRequired,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    double? monthlySpent,
    double? budgetUtilization,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      isRequired: isRequired ?? this.isRequired,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      monthlySpent: monthlySpent ?? this.monthlySpent,
      budgetUtilization: budgetUtilization ?? this.budgetUtilization,
    );
  }

  @override
  String toString() =>
      'ExpenseCategory(id: $id, name: $name, status: $statusDisplayName)';
}
