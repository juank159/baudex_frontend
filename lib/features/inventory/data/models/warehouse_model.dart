// lib/features/inventory/data/models/warehouse_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/warehouse.dart';

part 'warehouse_model.g.dart';

@JsonSerializable()
class WarehouseModel extends Warehouse {
  const WarehouseModel({
    required super.id,
    required super.name,
    required super.code,
    super.description,
    super.address,
    super.isActive = true,
    super.isMainWarehouse = false,
    super.createdAt,
    super.updatedAt,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseModelFromJson(json);

  Map<String, dynamic> toJson() => _$WarehouseModelToJson(this);

  factory WarehouseModel.fromEntity(Warehouse warehouse) {
    return WarehouseModel(
      id: warehouse.id,
      name: warehouse.name,
      code: warehouse.code,
      description: warehouse.description,
      address: warehouse.address,
      isActive: warehouse.isActive,
      isMainWarehouse: warehouse.isMainWarehouse,
      createdAt: warehouse.createdAt,
      updatedAt: warehouse.updatedAt,
    );
  }

  Warehouse toEntity() {
    return Warehouse(
      id: id,
      name: name,
      code: code,
      description: description,
      address: address,
      isActive: isActive,
      isMainWarehouse: isMainWarehouse,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}