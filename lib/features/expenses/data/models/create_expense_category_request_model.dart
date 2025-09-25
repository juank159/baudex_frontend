// lib/features/expenses/data/models/create_expense_category_request_model.dart
class CreateExpenseCategoryRequestModel {
  final String name;
  final String? description;
  final String? color;
  final double? monthlyBudget;
  final int? sortOrder;

  const CreateExpenseCategoryRequestModel({
    required this.name,
    this.description,
    this.color,
    this.monthlyBudget,
    this.sortOrder,
  });

  factory CreateExpenseCategoryRequestModel.fromParams({
    required String name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
  }) {
    return CreateExpenseCategoryRequestModel(
      name: name,
      description: description,
      color: color,
      monthlyBudget: monthlyBudget ?? 0.0,
      sortOrder: sortOrder ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
    };

    if (description?.isNotEmpty == true) data['description'] = description;
    if (color?.isNotEmpty == true) data['color'] = color;
    if (monthlyBudget != null) data['monthlyBudget'] = monthlyBudget;
    if (sortOrder != null) data['sortOrder'] = sortOrder;

    return data;
  }
}