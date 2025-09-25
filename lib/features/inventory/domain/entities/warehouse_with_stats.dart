// lib/features/inventory/domain/entities/warehouse_with_stats.dart
import 'package:equatable/equatable.dart';
import 'warehouse.dart';

class WarehouseStats extends Equatable {
  final int totalProducts;
  final double totalValue;
  final double totalQuantity;
  final int lowStockProducts;
  final int outOfStockProducts;

  const WarehouseStats({
    required this.totalProducts,
    required this.totalValue,
    required this.totalQuantity,
    required this.lowStockProducts,
    required this.outOfStockProducts,
  });

  @override
  List<Object?> get props => [
    totalProducts,
    totalValue,
    totalQuantity,
    lowStockProducts,
    outOfStockProducts,
  ];

  int get withStockProducts => totalProducts - outOfStockProducts;

  String get formattedTotalValue {
    return '\$${totalValue.toStringAsFixed(2)}';
  }

  String get formattedTotalQuantity {
    return totalQuantity.toStringAsFixed(0);
  }
}

class WarehouseWithStats extends Equatable {
  final Warehouse warehouse;
  final WarehouseStats? stats;

  const WarehouseWithStats({
    required this.warehouse,
    this.stats,
  });

  @override
  List<Object?> get props => [warehouse, stats];

  // Delegación de propiedades de Warehouse
  String get id => warehouse.id;
  String get name => warehouse.name;
  String get code => warehouse.code;
  String? get description => warehouse.description;
  String? get address => warehouse.address;
  bool get isActive => warehouse.isActive;
  DateTime? get createdAt => warehouse.createdAt;
  DateTime? get updatedAt => warehouse.updatedAt;
  String get displayName => warehouse.displayName;

  bool get hasStats => stats != null;
}