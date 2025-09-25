// lib/features/purchase_orders/data/models/purchase_order_response_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../../../app/core/models/pagination_meta.dart';
import 'purchase_order_model.dart';

part 'purchase_order_response_model.g.dart';

@JsonSerializable()
class PurchaseOrderResponseModel {
  final bool success;
  final String? message;
  final PurchaseOrderModel? data;
  final String? error;

  const PurchaseOrderResponseModel({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory PurchaseOrderResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseOrderResponseModelToJson(this);
}

@JsonSerializable()
class PurchaseOrderListData {
  final List<PurchaseOrderModel> data;
  final int total;

  const PurchaseOrderListData({
    required this.data,
    required this.total,
  });

  factory PurchaseOrderListData.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderListDataFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseOrderListDataToJson(this);
}

@JsonSerializable()
class PurchaseOrderListResponseModel {
  final bool success;
  final String? message;
  final PurchaseOrderListData? data;
  final String? error;

  const PurchaseOrderListResponseModel({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory PurchaseOrderListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderListResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseOrderListResponseModelToJson(this);
}

@JsonSerializable()
class PurchaseOrderStatsResponseModel {
  final bool success;
  final String? message;
  final PurchaseOrderStatsModel? data;
  final String? error;

  const PurchaseOrderStatsResponseModel({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory PurchaseOrderStatsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderStatsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseOrderStatsResponseModelToJson(this);
}