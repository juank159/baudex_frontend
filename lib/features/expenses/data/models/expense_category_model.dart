// lib/features/expenses/data/models/expense_category_model.dart
import '../../domain/entities/expense_category.dart';

class ExpenseCategoryModel extends ExpenseCategory {
  const ExpenseCategoryModel({
    required super.id,
    required super.name,
    super.description,
    super.color,
    required super.status,
    required super.monthlyBudget,
    required super.isRequired,
    required super.sortOrder,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      status: _parseStatus(json['status']),
      monthlyBudget: _parseDouble(json['monthlyBudget']) ?? 0.0,
      isRequired: json['isRequired'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'status': status.name,
      'monthlyBudget': monthlyBudget,
      'isRequired': isRequired,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  static ExpenseCategoryStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'active':
          return ExpenseCategoryStatus.active;
        case 'inactive':
          return ExpenseCategoryStatus.inactive;
        default:
          return ExpenseCategoryStatus.active;
      }
    }
    return ExpenseCategoryStatus.active;
  }

  ExpenseCategory toEntity() => ExpenseCategory(
    id: id,
    name: name,
    description: description,
    color: color,
    status: status,
    monthlyBudget: monthlyBudget,
    isRequired: isRequired,
    sortOrder: sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );

  factory ExpenseCategoryModel.fromEntity(ExpenseCategory category) {
    return ExpenseCategoryModel(
      id: category.id,
      name: category.name,
      description: category.description,
      color: category.color,
      status: category.status,
      monthlyBudget: category.monthlyBudget,
      isRequired: category.isRequired,
      sortOrder: category.sortOrder,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
      deletedAt: category.deletedAt,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('⚠️ Error parsing double from string: "$value" - $e');
        return null;
      }
    }

    print(
      '⚠️ Unexpected type for numeric value: ${value.runtimeType} - $value',
    );
    return null;
  }
}