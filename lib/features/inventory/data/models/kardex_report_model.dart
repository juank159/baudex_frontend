// lib/features/inventory/data/models/kardex_report_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/kardex_report.dart';

part 'kardex_report_model.g.dart';

@JsonSerializable()
class KardexReportModel {
  final KardexProductModel product;
  final KardexPeriodModel period;
  final KardexBalanceModel initialBalance;
  final List<KardexMovementModel> movements;
  final KardexBalanceModel finalBalance;
  final KardexSummaryModel summary;
  final List<KardexBatchDetailModel>? batchDetails;

  const KardexReportModel({
    required this.product,
    required this.period,
    required this.initialBalance,
    required this.movements,
    required this.finalBalance,
    required this.summary,
    this.batchDetails,
  });

  factory KardexReportModel.fromJson(Map<String, dynamic> json) =>
      _$KardexReportModelFromJson(json);

  Map<String, dynamic> toJson() => _$KardexReportModelToJson(this);

  KardexReport toEntity() {
    return KardexReport(
      product: product.toEntity(),
      period: period.toEntity(),
      initialBalance: initialBalance.toEntity(),
      movements: movements.map((m) => m.toEntity()).toList(),
      finalBalance: finalBalance.toEntity(),
      summary: summary.toEntity(),
      batchDetails: batchDetails?.map((b) => b.toEntity()).toList(),
    );
  }
}

@JsonSerializable()
class KardexProductModel {
  final String id;
  final String name;
  final String sku;
  final String? categoryName;

  const KardexProductModel({
    required this.id,
    required this.name,
    required this.sku,
    this.categoryName,
  });

  factory KardexProductModel.fromJson(Map<String, dynamic> json) =>
      _$KardexProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$KardexProductModelToJson(this);

  KardexProduct toEntity() {
    return KardexProduct(
      id: id,
      name: name,
      sku: sku,
      categoryName: categoryName,
    );
  }
}

@JsonSerializable()
class KardexPeriodModel {
  final DateTime startDate;
  final DateTime endDate;

  const KardexPeriodModel({
    required this.startDate,
    required this.endDate,
  });

  factory KardexPeriodModel.fromJson(Map<String, dynamic> json) =>
      _$KardexPeriodModelFromJson(json);

  Map<String, dynamic> toJson() => _$KardexPeriodModelToJson(this);

  KardexPeriod toEntity() {
    return KardexPeriod(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

@JsonSerializable()
class KardexBalanceModel {
  @JsonKey(fromJson: _parseDouble)
  final double quantity;
  @JsonKey(fromJson: _parseDouble)
  final double value;
  @JsonKey(fromJson: _parseDouble)
  final double averageCost;

  const KardexBalanceModel({
    required this.quantity,
    required this.value,
    required this.averageCost,
  });

  factory KardexBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$KardexBalanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$KardexBalanceModelToJson(this);

  KardexBalance toEntity() {
    return KardexBalance(
      quantity: quantity,
      value: value,
      averageCost: averageCost,
    );
  }
}

@JsonSerializable()
class KardexMovementModel {
  final DateTime date;
  final String movementNumber;
  final String movementType;
  final String? referenceType;
  final String? referenceNumber;
  final String description;
  @JsonKey(fromJson: _parseDouble)
  final double entryQuantity;
  @JsonKey(fromJson: _parseDouble)
  final double exitQuantity;
  @JsonKey(fromJson: _parseDouble)
  final double balance;
  @JsonKey(fromJson: _parseDouble)
  final double unitCost;
  @JsonKey(fromJson: _parseDouble)
  final double entryCost;
  @JsonKey(fromJson: _parseDouble)
  final double exitCost;
  @JsonKey(fromJson: _parseDouble)
  final double balanceValue;
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? unitPrice;
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? totalPrice;
  final String createdBy;
  final String? notes;

  const KardexMovementModel({
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

  factory KardexMovementModel.fromJson(Map<String, dynamic> json) =>
      _$KardexMovementModelFromJson(json);

  Map<String, dynamic> toJson() => _$KardexMovementModelToJson(this);

  KardexMovement toEntity() {
    return KardexMovement(
      date: date,
      movementNumber: movementNumber,
      movementType: movementType,
      referenceType: referenceType,
      referenceNumber: referenceNumber,
      description: description,
      entryQuantity: entryQuantity,
      exitQuantity: exitQuantity,
      balance: balance,
      unitCost: unitCost,
      entryCost: entryCost,
      exitCost: exitCost,
      balanceValue: balanceValue,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      createdBy: createdBy,
      notes: notes,
    );
  }
}

@JsonSerializable()
class KardexSummaryModel {
  final int totalEntries;
  final int totalExits;
  @JsonKey(fromJson: _parseDouble)
  final double totalPurchases;
  @JsonKey(fromJson: _parseDouble)
  final double totalSales;
  @JsonKey(fromJson: _parseDouble)
  final double averageUnitCost;
  @JsonKey(fromJson: _parseDouble)
  final double totalValue;

  const KardexSummaryModel({
    required this.totalEntries,
    required this.totalExits,
    required this.totalPurchases,
    required this.totalSales,
    required this.averageUnitCost,
    required this.totalValue,
  });

  factory KardexSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$KardexSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$KardexSummaryModelToJson(this);

  KardexSummary toEntity() {
    return KardexSummary(
      totalEntries: totalEntries,
      totalExits: totalExits,
      totalPurchases: totalPurchases,
      totalSales: totalSales,
      averageUnitCost: averageUnitCost,
      totalValue: totalValue,
    );
  }
}

@JsonSerializable()
class KardexBatchDetailModel {
  final String batchNumber;
  final DateTime purchaseDate;
  @JsonKey(fromJson: _parseDouble)
  final double quantity;
  @JsonKey(fromJson: _parseDouble)
  final double unitCost;
  @JsonKey(fromJson: _parseDouble)
  final double totalValue;
  final int daysInInventory;

  const KardexBatchDetailModel({
    required this.batchNumber,
    required this.purchaseDate,
    required this.quantity,
    required this.unitCost,
    required this.totalValue,
    required this.daysInInventory,
  });

  factory KardexBatchDetailModel.fromJson(Map<String, dynamic> json) =>
      _$KardexBatchDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$KardexBatchDetailModelToJson(this);

  KardexBatchDetail toEntity() {
    return KardexBatchDetail(
      batchNumber: batchNumber,
      purchaseDate: purchaseDate,
      quantity: quantity,
      unitCost: unitCost,
      totalValue: totalValue,
      daysInInventory: daysInInventory,
    );
  }
}

// Helper functions for parsing mixed types
double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    // Handle concatenated strings like "08.0010.0010.008.0010.0045.0075.00"
    // For now, try to parse the last valid number or return the parsed double
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
    
    // If it's a concatenated string, extract the last number
    final parts = value.split(RegExp(r'(?<=\.00)(?=\d)'));
    if (parts.isNotEmpty) {
      final lastPart = parts.last;
      final parsed = double.tryParse(lastPart);
      if (parsed != null) return parsed;
    }
    
    return 0.0; // Default fallback
  }
  return 0.0;
}

double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  return _parseDouble(value);
}