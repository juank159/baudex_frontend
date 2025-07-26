// lib/features/expenses/data/models/expense_stats_model.dart
import '../../domain/entities/expense_stats.dart';

class ExpenseStatsModel extends ExpenseStats {
  const ExpenseStatsModel({
    required super.totalExpenses,
    required super.totalAmount,
    required super.monthlyAmount,
    required super.weeklyAmount,
    required super.dailyAmount,
    required super.pendingExpenses,
    required super.pendingAmount,
    required super.approvedExpenses,
    required super.approvedAmount,
    required super.paidExpenses,
    required super.paidAmount,
    required super.rejectedExpenses,
    required super.rejectedAmount,
    required super.averageExpenseAmount,
    required super.expensesByCategory,
    required super.expensesByType,
    required super.expensesByStatus,
    required super.monthlyTrends,
  });

  factory ExpenseStatsModel.fromJson(Map<String, dynamic> json) {
    return ExpenseStatsModel(
      totalExpenses: (json['totalExpenses'] as num?)?.toInt() ?? 0,
      totalAmount: _parseDouble(json['totalAmount']) ?? 0.0,
      monthlyAmount: _parseDouble(json['monthlyAmount']) ?? 0.0,
      weeklyAmount: _parseDouble(json['weeklyAmount']) ?? 0.0,
      dailyAmount: _parseDouble(json['dailyAmount']) ?? 0.0,
      pendingExpenses: (json['pendingExpenses'] as num?)?.toInt() ?? 0,
      pendingAmount: _parseDouble(json['pendingAmount']) ?? 0.0,
      approvedExpenses: (json['approvedExpenses'] as num?)?.toInt() ?? 0,
      approvedAmount: _parseDouble(json['approvedAmount']) ?? 0.0,
      paidExpenses: (json['paidExpenses'] as num?)?.toInt() ?? 0,
      paidAmount: _parseDouble(json['paidAmount']) ?? 0.0,
      rejectedExpenses: (json['rejectedExpenses'] as num?)?.toInt() ?? 0,
      rejectedAmount: _parseDouble(json['rejectedAmount']) ?? 0.0,
      averageExpenseAmount: _parseDouble(json['averageExpenseAmount']) ?? 0.0,
      expensesByCategory: Map<String, double>.from(
        json['expensesByCategory']?.map((key, value) => 
          MapEntry(key as String, _parseDouble(value) ?? 0.0)) ?? {}
      ),
      expensesByType: Map<String, double>.from(
        json['expensesByType']?.map((key, value) => 
          MapEntry(key as String, _parseDouble(value) ?? 0.0)) ?? {}
      ),
      expensesByStatus: Map<String, int>.from(
        json['expensesByStatus']?.map((key, value) => 
          MapEntry(key as String, (value as num?)?.toInt() ?? 0)) ?? {}
      ),
      monthlyTrends: (json['monthlyTrends'] as List<dynamic>?)
          ?.map((trend) => MonthlyExpenseTrendModel.fromJson(trend))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalExpenses': totalExpenses,
      'totalAmount': totalAmount,
      'monthlyAmount': monthlyAmount,
      'weeklyAmount': weeklyAmount,
      'dailyAmount': dailyAmount,
      'pendingExpenses': pendingExpenses,
      'pendingAmount': pendingAmount,
      'approvedExpenses': approvedExpenses,
      'approvedAmount': approvedAmount,
      'paidExpenses': paidExpenses,
      'paidAmount': paidAmount,
      'rejectedExpenses': rejectedExpenses,
      'rejectedAmount': rejectedAmount,
      'averageExpenseAmount': averageExpenseAmount,
      'expensesByCategory': expensesByCategory,
      'expensesByType': expensesByType,
      'expensesByStatus': expensesByStatus,
      'monthlyTrends': monthlyTrends.map((trend) => 
        MonthlyExpenseTrendModel.fromEntity(trend).toJson()).toList(),
    };
  }

  ExpenseStats toEntity() => ExpenseStats(
    totalExpenses: totalExpenses,
    totalAmount: totalAmount,
    monthlyAmount: monthlyAmount,
    weeklyAmount: weeklyAmount,
    dailyAmount: dailyAmount,
    pendingExpenses: pendingExpenses,
    pendingAmount: pendingAmount,
    approvedExpenses: approvedExpenses,
    approvedAmount: approvedAmount,
    paidExpenses: paidExpenses,
    paidAmount: paidAmount,
    rejectedExpenses: rejectedExpenses,
    rejectedAmount: rejectedAmount,
    averageExpenseAmount: averageExpenseAmount,
    expensesByCategory: expensesByCategory,
    expensesByType: expensesByType,
    expensesByStatus: expensesByStatus,
    monthlyTrends: monthlyTrends,
  );

  factory ExpenseStatsModel.fromEntity(ExpenseStats stats) {
    return ExpenseStatsModel(
      totalExpenses: stats.totalExpenses,
      totalAmount: stats.totalAmount,
      monthlyAmount: stats.monthlyAmount,
      weeklyAmount: stats.weeklyAmount,
      dailyAmount: stats.dailyAmount,
      pendingExpenses: stats.pendingExpenses,
      pendingAmount: stats.pendingAmount,
      approvedExpenses: stats.approvedExpenses,
      approvedAmount: stats.approvedAmount,
      paidExpenses: stats.paidExpenses,
      paidAmount: stats.paidAmount,
      rejectedExpenses: stats.rejectedExpenses,
      rejectedAmount: stats.rejectedAmount,
      averageExpenseAmount: stats.averageExpenseAmount,
      expensesByCategory: stats.expensesByCategory,
      expensesByType: stats.expensesByType,
      expensesByStatus: stats.expensesByStatus,
      monthlyTrends: stats.monthlyTrends,
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

class MonthlyExpenseTrendModel extends MonthlyExpenseTrend {
  const MonthlyExpenseTrendModel({
    required super.year,
    required super.month,
    required super.amount,
    required super.count,
  });

  factory MonthlyExpenseTrendModel.fromJson(Map<String, dynamic> json) {
    return MonthlyExpenseTrendModel(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      amount: ExpenseStatsModel._parseDouble(json['amount']) ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'amount': amount,
      'count': count,
    };
  }

  MonthlyExpenseTrend toEntity() => MonthlyExpenseTrend(
    year: year,
    month: month,
    amount: amount,
    count: count,
  );

  factory MonthlyExpenseTrendModel.fromEntity(MonthlyExpenseTrend trend) {
    return MonthlyExpenseTrendModel(
      year: trend.year,
      month: trend.month,
      amount: trend.amount,
      count: trend.count,
    );
  }
}