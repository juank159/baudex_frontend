// lib/features/invoices/data/models/invoice_response_models.dart
import '../../../../app/core/models/pagination_meta.dart';
import 'invoice_model.dart';

/// Modelo de respuesta para las facturas paginadas
class InvoiceResponseModel {
  final List<InvoiceModel> data;
  final PaginationMeta meta;

  const InvoiceResponseModel({required this.data, required this.meta});

  factory InvoiceResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      return InvoiceResponseModel(
        data:
            (json['data'] as List? ?? [])
                .map(
                  (invoice) =>
                      InvoiceModel.fromJson(invoice as Map<String, dynamic>),
                )
                .toList(),
        meta: PaginationMeta.fromJson(
          json['meta'] as Map<String, dynamic>? ?? {},
        ),
      );
    } catch (e) {
      print('❌ Error parsing InvoiceResponseModel: $e');
      print('📄 JSON data: $json');

      // Retornar respuesta vacía en caso de error
      return InvoiceResponseModel(data: [], meta: PaginationMeta.fromJson({}));
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((invoice) => invoice.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }

  /// Convierte a PaginatedResult para el dominio
  PaginatedResult<InvoiceModel> toPaginatedResult() {
    return PaginatedResult<InvoiceModel>(data: data, meta: meta);
  }

  /// Validar que la respuesta sea válida
  bool get isValid {
    return data.isNotEmpty || meta.totalItems == 0;
  }

  @override
  String toString() {
    return 'InvoiceResponseModel(data: ${data.length} items, meta: $meta)';
  }
}

/// Modelo de respuesta para una sola factura
class SingleInvoiceResponseModel {
  final InvoiceModel data;
  final bool success;
  final String? message;

  const SingleInvoiceResponseModel({
    required this.data,
    this.success = true,
    this.message,
  });

  factory SingleInvoiceResponseModel.fromJson(Map<String, dynamic> json) {
    return SingleInvoiceResponseModel(
      data: InvoiceModel.fromJson(json['data'] as Map<String, dynamic>),
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
      'success': success,
      if (message != null) 'message': message,
    };
  }
}

/// Modelo de respuesta para lista de facturas (sin paginación)
class InvoiceListResponseModel {
  final List<InvoiceModel> data;
  final bool success;
  final String? message;

  const InvoiceListResponseModel({
    required this.data,
    this.success = true,
    this.message,
  });

  factory InvoiceListResponseModel.fromJson(Map<String, dynamic> json) {
    return InvoiceListResponseModel(
      data:
          (json['data'] as List? ?? [])
              .map(
                (invoice) =>
                    InvoiceModel.fromJson(invoice as Map<String, dynamic>),
              )
              .toList(),
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((invoice) => invoice.toJson()).toList(),
      'success': success,
      if (message != null) 'message': message,
    };
  }
}
