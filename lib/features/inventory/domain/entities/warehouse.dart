// lib/features/inventory/domain/entities/warehouse.dart
import 'package:equatable/equatable.dart';

class Warehouse extends Equatable {
  final String id;
  final String name;
  final String code;
  final String? description;
  final String? address;
  final bool isActive;
  final bool isMainWarehouse;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Warehouse({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.address,
    this.isActive = true,
    this.isMainWarehouse = false,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, code, description, address, isActive, isMainWarehouse, createdAt, updatedAt];

  String get displayName => '$name ($code)';
  
  String get displayNameWithMain => isMainWarehouse ? '$name ($code) - Principal' : '$name ($code)';

  Warehouse copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? address,
    bool? isActive,
    bool? isMainWarehouse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      isMainWarehouse: isMainWarehouse ?? this.isMainWarehouse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}