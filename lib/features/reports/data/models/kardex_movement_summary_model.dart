// lib/features/reports/data/models/kardex_movement_summary_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/repositories/reports_repository.dart';

part 'kardex_movement_summary_model.g.dart';

@JsonSerializable()
class KardexMovementSummaryModel {
  final DateTime startDate;
  final DateTime endDate;
  final int totalMovements;
  final double totalInboundValue;
  final double totalOutboundValue;
  final double netValue;
  final Map<String, int> movementsByType;
  final Map<String, double> valuesByType;
  final List<DailyMovementSummaryModel> dailySummaries;

  const KardexMovementSummaryModel({
    required this.startDate,
    required this.endDate,
    required this.totalMovements,
    required this.totalInboundValue,
    required this.totalOutboundValue,
    required this.netValue,
    required this.movementsByType,
    required this.valuesByType,
    required this.dailySummaries,
  });

  factory KardexMovementSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$KardexMovementSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$KardexMovementSummaryModelToJson(this);

  KardexMovementSummary toDomain() {
    return KardexMovementSummary(
      startDate: startDate,
      endDate: endDate,
      totalMovements: totalMovements,
      totalInboundValue: totalInboundValue,
      totalOutboundValue: totalOutboundValue,
      netValue: netValue,
      movementsByType: movementsByType,
      valuesByType: valuesByType,
      dailySummaries: dailySummaries.map((d) => d.toDomain()).toList(),
    );
  }
}

@JsonSerializable()
class DailyMovementSummaryModel {
  final DateTime date;
  final int movementCount;
  final double inboundValue;
  final double outboundValue;
  final double netValue;

  const DailyMovementSummaryModel({
    required this.date,
    required this.movementCount,
    required this.inboundValue,
    required this.outboundValue,
    required this.netValue,
  });

  factory DailyMovementSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$DailyMovementSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyMovementSummaryModelToJson(this);

  DailyMovementSummary toDomain() {
    return DailyMovementSummary(
      date: date,
      movementCount: movementCount,
      inboundValue: inboundValue,
      outboundValue: outboundValue,
      netValue: netValue,
    );
  }
}