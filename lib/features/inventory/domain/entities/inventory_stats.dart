// lib/features/inventory/domain/entities/inventory_stats.dart
import 'package:equatable/equatable.dart';

class InventoryStats extends Equatable {
  final int totalProducts;
  final int totalBatches;
  final int totalMovements;
  final double totalValue;
  final Map<String, dynamic> movementsByType;

  const InventoryStats({
    required this.totalProducts,
    required this.totalBatches,
    required this.totalMovements,
    required this.totalValue,
    required this.movementsByType,
  });

  @override
  List<Object?> get props => [
        totalProducts,
        totalBatches,
        totalMovements,
        totalValue,
        movementsByType,
      ];

  // Computed properties
  int get totalMovementsCount => totalMovements;
  
  double get averageValuePerProduct {
    if (totalProducts == 0) return 0.0;
    return totalValue / totalProducts;
  }

  String get inventoryStatus {
    if (totalProducts == 0) return 'Sin productos';
    if (totalProducts < 10) return 'Inventario bajo';
    if (totalProducts < 50) return 'Inventario normal';
    return 'Inventario alto';
  }

  // Missing getters needed by widgets
  int get movementsToday {
    // This would typically be calculated from actual data
    // For now, returning a placeholder value
    return (movementsByType['today'] as int?) ?? 0;
  }

  int get lowStockCount {
    // This would typically come from actual low stock data
    // For now, returning a placeholder value
    return (movementsByType['lowStock'] as int?) ?? 0;
  }

  int get expiredCount {
    // This would typically come from actual expired products data
    // For now, returning a placeholder value
    return (movementsByType['expired'] as int?) ?? 0;
  }
}

