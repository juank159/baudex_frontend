// lib/features/inventory/domain/entities/kardex_report.dart
import 'package:equatable/equatable.dart';

class KardexReport extends Equatable {
  final KardexProduct product;
  final KardexPeriod period;
  final KardexBalance initialBalance;
  final List<KardexMovement> movements;
  final KardexBalance finalBalance;
  final KardexSummary summary;
  final List<KardexBatchDetail>? batchDetails;

  const KardexReport({
    required this.product,
    required this.period,
    required this.initialBalance,
    required this.movements,
    required this.finalBalance,
    required this.summary,
    this.batchDetails,
  });

  @override
  List<Object?> get props => [
    product,
    period,
    initialBalance,
    movements,
    finalBalance,
    summary,
    batchDetails,
  ];

  bool get hasMovements => movements.isNotEmpty;
  bool get hasBatchDetails => batchDetails?.isNotEmpty ?? false;
  
  int get totalMovements => movements.length;
  int get entriesCount => movements.where((m) => m.entryQuantity > 0).length;
  int get exitsCount => movements.where((m) => m.exitQuantity > 0).length;
}

class KardexProduct extends Equatable {
  final String id;
  final String name;
  final String sku;
  final String? categoryName;

  const KardexProduct({
    required this.id,
    required this.name,
    required this.sku,
    this.categoryName,
  });

  @override
  List<Object?> get props => [id, name, sku, categoryName];
}

class KardexPeriod extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const KardexPeriod({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [startDate, endDate];
  
  int get daysInPeriod => endDate.difference(startDate).inDays + 1;
}

class KardexBalance extends Equatable {
  final double quantity;
  final double value;
  final double averageCost;

  const KardexBalance({
    required this.quantity,
    required this.value,
    required this.averageCost,
  });

  @override
  List<Object> get props => [quantity, value, averageCost];
  
  bool get hasStock => quantity > 0;
  bool get hasValue => value > 0;
}

class KardexMovement extends Equatable {
  final DateTime date;
  final String movementNumber;
  final String movementType;
  final String? referenceType;
  final String? referenceNumber;
  final String description;
  final double entryQuantity;
  final double exitQuantity;
  final double balance;
  final double unitCost;
  final double entryCost;
  final double exitCost;
  final double balanceValue;
  final double? unitPrice;
  final double? totalPrice;
  final String createdBy;
  final String? notes;

  const KardexMovement({
    required this.date,
    required this.movementNumber,
    required this.movementType,
    this.referenceType,
    this.referenceNumber,
    required this.description,
    required this.entryQuantity,
    required this.exitQuantity,
    required this.balance,
    required this.unitCost,
    required this.entryCost,
    required this.exitCost,
    required this.balanceValue,
    this.unitPrice,
    this.totalPrice,
    required this.createdBy,
    this.notes,
  });

  @override
  List<Object?> get props => [
    date,
    movementNumber,
    movementType,
    referenceType,
    referenceNumber,
    description,
    entryQuantity,
    exitQuantity,
    balance,
    unitCost,
    entryCost,
    exitCost,
    balanceValue,
    unitPrice,
    totalPrice,
    createdBy,
    notes,
  ];

  bool get isEntry => entryQuantity > 0;
  bool get isExit => exitQuantity > 0;
  
  double get netQuantity => entryQuantity - exitQuantity;
  double get netCost => entryCost - exitCost;
  
  String get displayType {
    switch (movementType.toLowerCase()) {
      case 'purchase':
        return 'Compra';
      case 'sale':
        return 'Venta';
      case 'adjustment':
        return 'Ajuste';
      case 'transfer_in':
        return 'Transferencia Entrada';
      case 'transfer_out':
        return 'Transferencia Salida';
      case 'return_in':
        return 'Devolución Entrada';
      case 'return_out':
        return 'Devolución Salida';
      default:
        return movementType;
    }
  }
}

class KardexSummary extends Equatable {
  final int totalEntries;
  final int totalExits;
  final double totalPurchases;
  final double totalSales;
  final double averageUnitCost;
  final double totalValue;

  const KardexSummary({
    required this.totalEntries,
    required this.totalExits,
    required this.totalPurchases,
    required this.totalSales,
    required this.averageUnitCost,
    required this.totalValue,
  });

  @override
  List<Object> get props => [
    totalEntries,
    totalExits,
    totalPurchases,
    totalSales,
    averageUnitCost,
    totalValue,
  ];
  
  int get netMovement => totalEntries - totalExits;
  double get netValue => totalPurchases - totalSales;
  
  double get turnoverRatio {
    if (totalValue <= 0) return 0.0;
    return totalSales / totalValue;
  }
}

class KardexBatchDetail extends Equatable {
  final String batchNumber;
  final DateTime purchaseDate;
  final double quantity;
  final double unitCost;
  final double totalValue;
  final int daysInInventory;

  const KardexBatchDetail({
    required this.batchNumber,
    required this.purchaseDate,
    required this.quantity,
    required this.unitCost,
    required this.totalValue,
    required this.daysInInventory,
  });

  @override
  List<Object> get props => [
    batchNumber,
    purchaseDate,
    quantity,
    unitCost,
    totalValue,
    daysInInventory,
  ];
}