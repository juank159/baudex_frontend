// lib/features/products/domain/entities/product_stats.dart
import 'package:equatable/equatable.dart';

class ProductStats extends Equatable {
  final int total;
  final int active;
  final int inactive;
  final int outOfStock;
  final int lowStock;
  final double activePercentage;
  final double totalValue;
  final double averagePrice;

  const ProductStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.outOfStock,
    required this.lowStock,
    required this.activePercentage,
    this.totalValue = 0.0,
    this.averagePrice = 0.0,
  });

  // Propiedades calculadas adicionales
  int get inStock => total - outOfStock;
  double get inactivePercentage => total > 0 ? (inactive / total) * 100 : 0;
  double get lowStockPercentage => total > 0 ? (lowStock / total) * 100 : 0;
  double get outOfStockPercentage => total > 0 ? (outOfStock / total) * 100 : 0;
  double get inStockPercentage => total > 0 ? (inStock / total) * 100 : 0;

  @override
  List<Object?> get props => [
    total,
    active,
    inactive,
    outOfStock,
    lowStock,
    activePercentage,
    totalValue,
    averagePrice,
  ];

  factory ProductStats.fromJson(Map<String, dynamic> json) {
    return ProductStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      inactive: json['inactive'] ?? 0,
      outOfStock: json['outOfStock'] ?? 0,
      lowStock: json['lowStock'] ?? 0,
      activePercentage: (json['activePercentage'] ?? 0).toDouble(),
      totalValue: (json['totalValue'] ?? 0).toDouble(),
      averagePrice: (json['averagePrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'active': active,
      'inactive': inactive,
      'outOfStock': outOfStock,
      'lowStock': lowStock,
      'activePercentage': activePercentage,
      'totalValue': totalValue,
      'averagePrice': averagePrice,
    };
  }

  ProductStats copyWith({
    int? total,
    int? active,
    int? inactive,
    int? outOfStock,
    int? lowStock,
    double? activePercentage,
    double? totalValue,
    double? averagePrice,
  }) {
    return ProductStats(
      total: total ?? this.total,
      active: active ?? this.active,
      inactive: inactive ?? this.inactive,
      outOfStock: outOfStock ?? this.outOfStock,
      lowStock: lowStock ?? this.lowStock,
      activePercentage: activePercentage ?? this.activePercentage,
      totalValue: totalValue ?? this.totalValue,
      averagePrice: averagePrice ?? this.averagePrice,
    );
  }

  factory ProductStats.empty() {
    return const ProductStats(
      total: 0,
      active: 0,
      inactive: 0,
      outOfStock: 0,
      lowStock: 0,
      activePercentage: 0.0,
      totalValue: 0.0,
      averagePrice: 0.0,
    );
  }
}
