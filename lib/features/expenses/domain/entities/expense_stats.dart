// lib/features/expenses/domain/entities/expense_stats.dart
import 'package:equatable/equatable.dart';

class ExpenseStats extends Equatable {
  final int totalExpenses;
  final double totalAmount;
  final double monthlyAmount;
  final double weeklyAmount;
  final double dailyAmount;
  final int pendingExpenses;
  final double pendingAmount;
  final int approvedExpenses;
  final double approvedAmount;
  final int paidExpenses;
  final double paidAmount;
  final int rejectedExpenses;
  final double rejectedAmount;
  final double averageExpenseAmount;
  final Map<String, double> expensesByCategory;
  final Map<String, double> expensesByType;
  final Map<String, int> expensesByStatus;
  final List<MonthlyExpenseTrend> monthlyTrends;
  
  // ✅ NUEVAS PROPIEDADES PARA ESTADÍSTICAS MEJORADAS
  final int? dailyCount;
  final int? weeklyCount;
  final int monthlyCount;
  final double? previousMonthAmount;
  final int? previousMonthCount;

  const ExpenseStats({
    required this.totalExpenses,
    required this.totalAmount,
    required this.monthlyAmount,
    required this.weeklyAmount,
    required this.dailyAmount,
    required this.pendingExpenses,
    required this.pendingAmount,
    required this.approvedExpenses,
    required this.approvedAmount,
    required this.paidExpenses,
    required this.paidAmount,
    required this.rejectedExpenses,
    required this.rejectedAmount,
    required this.averageExpenseAmount,
    required this.expensesByCategory,
    required this.expensesByType,
    required this.expensesByStatus,
    required this.monthlyTrends,
    this.dailyCount,
    this.weeklyCount,
    required this.monthlyCount,
    this.previousMonthAmount,
    this.previousMonthCount,
  });

  @override
  List<Object?> get props => [
        totalExpenses,
        totalAmount,
        monthlyAmount,
        weeklyAmount,
        dailyAmount,
        pendingExpenses,
        pendingAmount,
        approvedExpenses,
        approvedAmount,
        paidExpenses,
        paidAmount,
        rejectedExpenses,
        rejectedAmount,
        averageExpenseAmount,
        expensesByCategory,
        expensesByType,
        expensesByStatus,
        monthlyTrends,
        dailyCount,
        weeklyCount,
        monthlyCount,
        previousMonthAmount,
        previousMonthCount,
      ];

  // Getters útiles
  String get formattedTotalAmount {
    return '\$${totalAmount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  String get formattedMonthlyAmount {
    return '\$${monthlyAmount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  String get formattedAverageAmount {
    return '\$${averageExpenseAmount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  double get approvalRate {
    if (totalExpenses == 0) return 0;
    return (approvedExpenses / totalExpenses) * 100;
  }

  double get rejectionRate {
    if (totalExpenses == 0) return 0;
    return (rejectedExpenses / totalExpenses) * 100;
  }

  @override
  String toString() =>
      'ExpenseStats(total: $formattedTotalAmount, count: $totalExpenses)';
}

class MonthlyExpenseTrend extends Equatable {
  final int year;
  final int month;
  final double amount;
  final int count;

  const MonthlyExpenseTrend({
    required this.year,
    required this.month,
    required this.amount,
    required this.count,
  });

  @override
  List<Object?> get props => [year, month, amount, count];

  String get monthName {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month - 1];
  }

  String get formattedAmount {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}