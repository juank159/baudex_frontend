// lib/features/invoices/data/models/invoice_request_models.dart
import '../../../../app/core/models/pagination_meta.dart';
import 'invoice_model.dart';
import 'invoice_item_model.dart';

// ==================== INVOICE RESPONSE MODEL ====================

class InvoiceResponseModel {
  final List<InvoiceModel> data;
  final PaginationMeta meta;

  const InvoiceResponseModel({required this.data, required this.meta});

  factory InvoiceResponseModel.fromJson(Map<String, dynamic> json) {
    return InvoiceResponseModel(
      data:
          (json['data'] as List)
              .map(
                (invoice) =>
                    InvoiceModel.fromJson(invoice as Map<String, dynamic>),
              )
              .toList(),
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((invoice) => invoice.toJson()).toList(),
      'meta': meta.toJson(),
    };
  }

  PaginatedResult<InvoiceModel> toPaginatedResult() {
    return PaginatedResult<InvoiceModel>(data: data, meta: meta);
  }
}

// ==================== CREATE INVOICE REQUEST MODEL ====================

class CreateInvoiceRequestModel {
  final String customerId;
  final List<CreateInvoiceItemRequestModel> items;
  final String? number;
  final String? date;
  final String? dueDate;
  final String paymentMethod;
  final double taxPercentage;
  final double discountPercentage;
  final double discountAmount;
  final String? notes;
  final String? terms;
  final Map<String, dynamic>? metadata;

  const CreateInvoiceRequestModel({
    required this.customerId,
    required this.items,
    this.number,
    this.date,
    this.dueDate,
    this.paymentMethod = 'cash',
    this.taxPercentage = 19,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.notes,
    this.terms,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      if (number != null) 'number': number,
      if (date != null) 'date': date,
      if (dueDate != null) 'dueDate': dueDate,
      'paymentMethod': paymentMethod,
      'taxPercentage': taxPercentage,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      if (notes != null) 'notes': notes,
      if (terms != null) 'terms': terms,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

// ==================== UPDATE INVOICE REQUEST MODEL ====================

class UpdateInvoiceRequestModel {
  final String? number;
  final String? date;
  final String? dueDate;
  final String? paymentMethod;
  final double? taxPercentage;
  final double? discountPercentage;
  final double? discountAmount;
  final String? notes;
  final String? terms;
  final Map<String, dynamic>? metadata;
  final String? customerId;
  final List<CreateInvoiceItemRequestModel>? items;

  const UpdateInvoiceRequestModel({
    this.number,
    this.date,
    this.dueDate,
    this.paymentMethod,
    this.taxPercentage,
    this.discountPercentage,
    this.discountAmount,
    this.notes,
    this.terms,
    this.metadata,
    this.customerId,
    this.items,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (number != null) json['number'] = number;
    if (date != null) json['date'] = date;
    if (dueDate != null) json['dueDate'] = dueDate;
    if (paymentMethod != null) json['paymentMethod'] = paymentMethod;
    if (taxPercentage != null) json['taxPercentage'] = taxPercentage;
    if (discountPercentage != null)
      json['discountPercentage'] = discountPercentage;
    if (discountAmount != null) json['discountAmount'] = discountAmount;
    if (notes != null) json['notes'] = notes;
    if (terms != null) json['terms'] = terms;
    if (metadata != null) json['metadata'] = metadata;
    if (customerId != null) json['customerId'] = customerId;
    if (items != null)
      json['items'] = items!.map((item) => item.toJson()).toList();

    return json;
  }
}

// ==================== ADD PAYMENT REQUEST MODEL ====================

class AddPaymentRequestModel {
  final double amount;
  final String paymentMethod;
  final String? paymentDate;
  final String? reference;
  final String? notes;

  const AddPaymentRequestModel({
    required this.amount,
    required this.paymentMethod,
    this.paymentDate,
    this.reference,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentMethod': paymentMethod,
      if (paymentDate != null) 'paymentDate': paymentDate,
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
    };
  }
}

// ==================== INVOICE QUERY PARAMS MODEL ====================

class InvoiceQueryParamsModel {
  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? paymentMethod;
  final String? customerId;
  final String? createdById;
  final String? startDate;
  final String? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy;
  final String sortOrder;

  const InvoiceQueryParamsModel({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.paymentMethod,
    this.customerId,
    this.createdById,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.sortBy = 'createdAt',
    this.sortOrder = 'DESC',
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (status != null) {
      params['status'] = status;
    }
    if (paymentMethod != null) {
      params['paymentMethod'] = paymentMethod;
    }
    if (customerId != null) {
      params['customerId'] = customerId;
    }
    if (createdById != null) {
      params['createdById'] = createdById;
    }
    if (startDate != null) {
      params['startDate'] = startDate;
    }
    if (endDate != null) {
      params['endDate'] = endDate;
    }
    if (minAmount != null) {
      params['minAmount'] = minAmount;
    }
    if (maxAmount != null) {
      params['maxAmount'] = maxAmount;
    }

    return params;
  }
}
