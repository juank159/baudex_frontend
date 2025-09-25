// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kardex_movement_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KardexMovementSummaryModel _$KardexMovementSummaryModelFromJson(
        Map<String, dynamic> json) =>
    KardexMovementSummaryModel(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalMovements: (json['totalMovements'] as num).toInt(),
      totalInboundValue: (json['totalInboundValue'] as num).toDouble(),
      totalOutboundValue: (json['totalOutboundValue'] as num).toDouble(),
      netValue: (json['netValue'] as num).toDouble(),
      movementsByType: Map<String, int>.from(json['movementsByType'] as Map),
      valuesByType: (json['valuesByType'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      dailySummaries: (json['dailySummaries'] as List<dynamic>)
          .map((e) =>
              DailyMovementSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$KardexMovementSummaryModelToJson(
        KardexMovementSummaryModel instance) =>
    <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'totalMovements': instance.totalMovements,
      'totalInboundValue': instance.totalInboundValue,
      'totalOutboundValue': instance.totalOutboundValue,
      'netValue': instance.netValue,
      'movementsByType': instance.movementsByType,
      'valuesByType': instance.valuesByType,
      'dailySummaries': instance.dailySummaries,
    };

DailyMovementSummaryModel _$DailyMovementSummaryModelFromJson(
        Map<String, dynamic> json) =>
    DailyMovementSummaryModel(
      date: DateTime.parse(json['date'] as String),
      movementCount: (json['movementCount'] as num).toInt(),
      inboundValue: (json['inboundValue'] as num).toDouble(),
      outboundValue: (json['outboundValue'] as num).toDouble(),
      netValue: (json['netValue'] as num).toDouble(),
    );

Map<String, dynamic> _$DailyMovementSummaryModelToJson(
        DailyMovementSummaryModel instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'movementCount': instance.movementCount,
      'inboundValue': instance.inboundValue,
      'outboundValue': instance.outboundValue,
      'netValue': instance.netValue,
    };
