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
    );
  }

  @override
  String toString() =>
      'ExpenseCategory(id: $id, name: $name, status: $statusDisplayName)';
}
