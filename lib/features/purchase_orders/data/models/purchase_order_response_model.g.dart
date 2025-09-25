// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_order_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseOrderResponseModel _$PurchaseOrderResponseModelFromJson(
        Map<String, dynamic> json) =>
    PurchaseOrderResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : PurchaseOrderModel.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PurchaseOrderResponseModelToJson(
        PurchaseOrderResponseModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

PurchaseOrderListData _$PurchaseOrderListDataFromJson(
        Map<String, dynamic> json) =>
    PurchaseOrderListData(
      data: (json['data'] as List<dynamic>)
          .map((e) => PurchaseOrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$PurchaseOrderListDataToJson(
        PurchaseOrderListData instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total': instance.total,
    };

PurchaseOrderListResponseModel _$PurchaseOrderListResponseModelFromJson(
        Map<String, dynamic> json) =>
    PurchaseOrderListResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : PurchaseOrderListData.fromJson(
              json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PurchaseOrderListResponseModelToJson(
        PurchaseOrderListResponseModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

PurchaseOrderStatsResponseModel _$PurchaseOrderStatsResponseModelFromJson(
        Map<String, dynamic> json) =>
    PurchaseOrderStatsResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : PurchaseOrderStatsModel.fromJson(
              json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PurchaseOrderStatsResponseModelToJson(
        PurchaseOrderStatsResponseModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };
