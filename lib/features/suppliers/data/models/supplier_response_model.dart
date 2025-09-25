// lib/features/suppliers/data/models/supplier_response_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../../../app/core/models/pagination_meta.dart';
import 'supplier_model.dart';

part 'supplier_response_model.g.dart';

@JsonSerializable()
class SupplierResponseModel {
  final bool success;
  final SupplierModel? data;
  final String? message;
  final DateTime timestamp;

  const SupplierResponseModel({
    required this.success,
    this.data,
    this.message,
    required this.timestamp,
  });

  factory SupplierResponseModel.fromJson(Map<String, dynamic> json) =>
      _$SupplierResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$SupplierResponseModelToJson(this);
}

@JsonSerializable()
class SuppliersListResponseModel {
  final bool success;
  final List<SupplierModel> data;
  final PaginationMeta? meta;
  final String? message;
  final DateTime timestamp;

  const SuppliersListResponseModel({
    required this.success,
    required this.data,
    this.meta,
    this.message,
    required this.timestamp,
  });

  factory SuppliersListResponseModel.fromJson(Map<String, dynamic> json) {
    // Manejar diferentes estructuras de respuesta
    final responseData = json['data'];
    
    if (responseData is Map<String, dynamic>) {
      // Estructura paginada: { data: { data: [...], meta: {...} } }
      return SuppliersListResponseModel(
        success: json['success'] as bool? ?? true,
        data: (responseData['data'] as List<dynamic>?)
                ?.map((item) => SupplierModel.fromJson(item as Map<String, dynamic>))
                .toList() ?? [],
        meta: responseData['meta'] != null 
            ? PaginationMeta.fromJson(responseData['meta'] as Map<String, dynamic>)
            : null,
        message: json['message'] as String?,
        timestamp: json['timestamp'] != null 
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
      );
    } else {
      // Estructura simple: { data: [...] }
      return SuppliersListResponseModel(
        success: json['success'] as bool? ?? true,
        data: (responseData as List<dynamic>?)
                ?.map((item) => SupplierModel.fromJson(item as Map<String, dynamic>))
                .toList() ?? [],
        meta: null,
        message: json['message'] as String?,
        timestamp: json['timestamp'] != null 
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() => _$SuppliersListResponseModelToJson(this);
}