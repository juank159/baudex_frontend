// lib/features/dashboard/domain/entities/dashboard_stats.dart
import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final SalesStats sales;
  final InvoiceStats invoices;  
  final ProductStats products;
  final CustomerStats customers;
  final ExpenseStats expenses;

  const DashboardStats({
    required this.sales,
    required this.invoices,
    required this.products,
    required this.customers,
    required this.expenses,
  });

  @override
  List<Object?> get props => [sales, invoices, products, customers, expenses];
}

class SalesStats extends Equatable {
  final double totalAmount;
  final int totalSales;
  final double todaySales;
  final double yesterdaySales;
  final double monthlySales;
  final double yearSales;
  final double todayGrowth;
  final double monthlyGrowth;

  const SalesStats({
    required this.totalAmount,
    required this.totalSales,
    required this.todaySales,
    required this.yesterdaySales,
    required this.monthlySales,
    required this.yearSales,
    required this.todayGrowth,
    required this.monthlyGrowth,
  });

  @override
  List<Object?> get props => [
    totalAmount,
    totalSales,
    todaySales,
    yesterdaySales,
    monthlySales,
    yearSales,
    todayGrowth,
    monthlyGrowth,
  ];
}

class InvoiceStats extends Equatable {
  final int totalInvoices;
  final int todayInvoices;
  final int pendingInvoices;
  final int paidInvoices;
  final double averageInvoiceValue;
  final double todayGrowth;

  const InvoiceStats({
    required this.totalInvoices,
    required this.todayInvoices,
    required this.pendingInvoices,
    required this.paidInvoices,
    required this.averageInvoiceValue,
    required this.todayGrowth,
  });

  @override
  List<Object?> get props => [
    totalInvoices,
    todayInvoices,
    pendingInvoices,
    paidInvoices,
    averageInvoiceValue,
    todayGrowth,
  ];
}

class ProductStats extends Equatable {
  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double totalInventoryValue;
  final int todayGrowth;

  const ProductStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.totalInventoryValue,
    required this.todayGrowth,
  });

  @override
  List<Object?> get props => [
    totalProducts,
    activeProducts,
    lowStockProducts,
    outOfStockProducts,
    totalInventoryValue,
    todayGrowth,
  ];
}

class CustomerStats extends Equatable {
  final int totalCustomers;
  final int activeCustomers;
  final int newCustomersToday;
  final int newCustomersMonth;
  final double averageOrderValue;
  final double todayGrowth;

  const CustomerStats({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.newCustomersToday,
    required this.newCustomersMonth,
    required this.averageOrderValue,
    required this.todayGrowth,
  });

  @override
  List<Object?> get props => [
    totalCustomers,
    activeCustomers,
    newCustomersToday,
    newCustomersMonth,
    averageOrderValue,
    todayGrowth,
  ];
}

class ExpenseStats extends Equatable {
  final double totalAmount;
  final int totalExpenses;
  final double monthlyExpenses;
  final double todayExpenses;
  final int pendingExpenses;
  final int approvedExpenses;
  final double monthlyGrowth;

  const ExpenseStats({
    required this.totalAmount,
    required this.totalExpenses,
    required this.monthlyExpenses,
    required this.todayExpenses,
    required this.pendingExpenses,
    required this.approvedExpenses,
    required this.monthlyGrowth,
  });

  @override
  List<Object?> get props => [
    totalAmount,
    totalExpenses,
    monthlyExpenses,
    todayExpenses,
    pendingExpenses,
    approvedExpenses,
    monthlyGrowth,
  ];
}