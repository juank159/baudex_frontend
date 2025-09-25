// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupplierResponseModel _$SupplierResponseModelFromJson(
        Map<String, dynamic> json) =>
    SupplierResponseModel(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : SupplierModel.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$SupplierResponseModelToJson(
        SupplierResponseModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
    };

SuppliersListResponseModel _$SuppliersListResponseModelFromJson(
        Map<String, dynamic> json) =>
    SuppliersListResponseModel(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => SupplierModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] == null
          ? null
          : PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
      message: json['message'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$SuppliersListResponseModelToJson(
        SuppliersListResponseModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'meta': instance.meta,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
    };
