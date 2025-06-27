// // lib/features/customers/data/models/customer_response_model.dart
// import '../../../../app/core/models/pagination_meta.dart';
// import '../../domain/repositories/customer_repository.dart';
// import 'customer_model.dart';

// class CustomerResponseModel {
//   final List<CustomerModel> data;
//   final PaginationMeta meta;
//   final bool success;
//   final String? message;

//   const CustomerResponseModel({
//     required this.data,
//     required this.meta,
//     this.success = true,
//     this.message,
//   });

//   factory CustomerResponseModel.fromJson(Map<String, dynamic> json) {
//     return CustomerResponseModel(
//       data:
//           (json['data'] as List?)
//               ?.map(
//                 (item) => CustomerModel.fromJson(item as Map<String, dynamic>),
//               )
//               .toList() ??
//           [],
//       meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
//       success: json['success'] as bool? ?? true,
//       message: json['message'] as String?,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'data': data.map((customer) => customer.toJson()).toList(),
//       'meta': meta.toJson(),
//       'success': success,
//       'message': message,
//     };
//   }

//   /// Convertir a resultado paginado del dominio
//   PaginatedResult<CustomerModel> toPaginatedResult() {
//     return PaginatedResult<CustomerModel>(data: data, meta: meta);
//   }

//   @override
//   String toString() =>
//       'CustomerResponseModel(data: ${data.length} items, meta: $meta)';
// }

// lib/features/customers/data/models/customer_response_model.dart
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/repositories/customer_repository.dart';
import 'customer_model.dart';

class CustomerResponseModel {
  final List<CustomerModel> data;
  final PaginationMeta meta;
  final bool success;
  final String? message;

  const CustomerResponseModel({
    required this.data,
    required this.meta,
    this.success = true,
    this.message,
  });

  factory CustomerResponseModel.fromJson(Map<String, dynamic> json) {
    return CustomerResponseModel(
      data:
          (json['data'] as List?)
              ?.map(
                (item) => CustomerModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((customer) => customer.toJson()).toList(),
      'meta': meta.toJson(),
      'success': success,
      'message': message,
    };
  }

  /// Convertir a resultado paginado del dominio
  PaginatedResult<CustomerModel> toPaginatedResult() {
    return PaginatedResult<CustomerModel>(data: data, meta: meta);
  }

  @override
  String toString() =>
      'CustomerResponseModel(data: ${data.length} items, meta: $meta)';
}
