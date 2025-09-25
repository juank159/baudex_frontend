// lib/features/inventory/domain/entities/kardex_entry.dart
import 'package:equatable/equatable.dart';

class KardexEntry extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String productSku;
  final DateTime date;
  final String documentType;
  final String documentNumber;
  final String description;
  final int quantityIn;
  final int quantityOut;
  final int balance;
  final double unitCostIn;
  final double unitCostOut;
  final double averageCost;
  final double totalValue;
  final String? lotNumber;
  final String? referenceId;
  final String? referenceType;

  const KardexEntry({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.date,
    required this.documentType,
    required this.documentNumber,
    required this.description,
    required this.quantityIn,
    required this.quantityOut,
    required this.balance,
    required this.unitCostIn,
    required this.unitCostOut,
    required this.averageCost,
    required this.totalValue,
    this.lotNumber,
    this.referenceId,
    this.referenceType,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productSku,
        date,
        documentType,
        documentNumber,
        description,
        quantityIn,
        quantityOut,
        balance,
        unitCostIn,
        unitCostOut,
        averageCost,
        totalValue,
        lotNumber,
        referenceId,
        referenceType,
      ];

  // Computed properties
  bool get isInbound => quantityIn > 0;
  bool get isOutbound => quantityOut > 0;
  bool get hasLot => lotNumber != null && lotNumber!.isNotEmpty;
  bool get hasReference => referenceId != null && referenceId!.isNotEmpty;

  int get netQuantity => quantityIn - quantityOut;

  String get movementType {
    if (isInbound) return 'Entrada';
    if (isOutbound) return 'Salida';
    return 'Sin movimiento';
  }

  String get displayQuantity {
    if (isInbound) return '+$quantityIn';
    if (isOutbound) return '-$quantityOut';
    return '0';
  }

  KardexEntry copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productSku,
    DateTime? date,
    String? documentType,
    String? documentNumber,
    String? description,
    int? quantityIn,
    int? quantityOut,
    int? balance,
    double? unitCostIn,
    double? unitCostOut,
    double? averageCost,
    double? totalValue,
    String? lotNumber,
    String? referenceId,
    String? referenceType,
  }) {
    return KardexEntry(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      date: date ?? this.date,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      description: description ?? this.description,
      quantityIn: quantityIn ?? this.quantityIn,
      quantityOut: quantityOut ?? this.quantityOut,
      balance: balance ?? this.balance,
      unitCostIn: unitCostIn ?? this.unitCostIn,
      unitCostOut: unitCostOut ?? this.unitCostOut,
      averageCost: averageCost ?? this.averageCost,
      totalValue: totalValue ?? this.totalValue,
      lotNumber: lotNumber ?? this.lotNumber,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
    );
  }
}

class KardexSummary extends Equatable {
  final String productId;
  final String productName;
  final String productSku;
  final DateTime fromDate;
  final DateTime toDate;
  final int initialBalance;
  final int totalInbound;
  final int totalOutbound;
  final int finalBalance;
  final double initialValue;
  final double totalInboundValue;
  final double totalOutboundValue;
  final double finalValue;
  final double averageCost;
  final List<KardexEntry> entries;

  const KardexSummary({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.fromDate,
    required this.toDate,
    required this.initialBalance,
    required this.totalInbound,
    required this.totalOutbound,
    required this.finalBalance,
    required this.initialValue,
    required this.totalInboundValue,
    required this.totalOutboundValue,
    required this.finalValue,
    required this.averageCost,
    required this.entries,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        productSku,
        fromDate,
        toDate,
        initialBalance,
        totalInbound,
        totalOutbound,
        finalBalance,
        initialValue,
        totalInboundValue,
        totalOutboundValue,
        finalValue,
        averageCost,
        entries,
      ];

  // Computed properties
  int get netMovement => totalInbound - totalOutbound;
  double get netValue => totalInboundValue - totalOutboundValue;
  bool get hasMovements => entries.isNotEmpty;
  int get entriesCount => entries.length;

  double get turnoverRatio {
    if (averageCost <= 0) return 0.0;
    return totalOutboundValue / averageCost;
  }

  KardexSummary copyWith({
    String? productId,
    String? productName,
    String? productSku,
    DateTime? fromDate,
    DateTime? toDate,
    int? initialBalance,
    int? totalInbound,
    int? totalOutbound,
    int? finalBalance,
    double? initialValue,
    double? totalInboundValue,
    double? totalOutboundValue,
    double? finalValue,
    double? averageCost,
    List<KardexEntry>? entries,
  }) {
    return KardexSummary(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      initialBalance: initialBalance ?? this.initialBalance,
      totalInbound: totalInbound ?? this.totalInbound,
      totalOutbound: totalOutbound ?? this.totalOutbound,
      finalBalance: finalBalance ?? this.finalBalance,
      initialValue: initialValue ?? this.initialValue,
      totalInboundValue: totalInboundValue ?? this.totalInboundValue,
      totalOutboundValue: totalOutboundValue ?? this.totalOutboundValue,
      finalValue: finalValue ?? this.finalValue,
      averageCost: averageCost ?? this.averageCost,
      entries: entries ?? this.entries,
    );
  }
}