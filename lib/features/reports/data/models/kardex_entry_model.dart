// lib/features/reports/data/models/kardex_entry_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/repositories/reports_repository.dart';

part 'kardex_entry_model.g.dart';

@JsonSerializable()
class KardexEntryModel {
  final String id;
  final String productId;
  final String productName;
  final DateTime date;
  final String movementType;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final int balance;
  final String? referenceId;
  final String? notes;

  const KardexEntryModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.date,
    required this.movementType,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    required this.balance,
    this.referenceId,
    this.notes,
  });

  factory KardexEntryModel.fromJson(Map<String, dynamic> json) =>
      _$KardexEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$KardexEntryModelToJson(this);

  KardexEntry toDomain() {
    return KardexEntry(
      id: id,
      productId: productId,
      productName: productName,
      date: date,
      movementType: movementType,
      quantity: quantity,
      unitCost: unitCost,
      totalCost: totalCost,
      balance: balance,
      referenceId: referenceId,
      notes: notes,
    );
  }
}