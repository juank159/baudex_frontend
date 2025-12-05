// lib/features/invoices/data/models/invoice_query_models.dart
import '../../domain/entities/invoice.dart';

/// Modelo para parámetros de consulta de facturas
class InvoiceQueryParamsModel {
  final int page;
  final int limit;
  final String? search;
  final String? status;
  final String? paymentMethod;
  final String? customerId;
  final String? createdById;
  final String? bankAccountId;
  final String? bankAccountName; // Filtro por nombre de método de pago (Nequi, Bancolombia, etc.)
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
    this.bankAccountId,
    this.bankAccountName,
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

    // Solo incluir parámetros que no sean null o vacíos
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
    if (bankAccountId != null) {
      params['bankAccountId'] = bankAccountId;
    }
    if (bankAccountName != null && bankAccountName!.isNotEmpty) {
      params['bankAccountName'] = bankAccountName;
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

  factory InvoiceQueryParamsModel.fromDomainParams({
    int page = 1,
    int limit = 10,
    String? search,
    InvoiceStatus? status,
    PaymentMethod? paymentMethod,
    String? customerId,
    String? createdById,
    String? bankAccountId,
    String? bankAccountName,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) {
    return InvoiceQueryParamsModel(
      page: page,
      limit: limit,
      search: search,
      status: status?.value,
      paymentMethod: paymentMethod?.value,
      customerId: customerId,
      createdById: createdById,
      bankAccountId: bankAccountId,
      bankAccountName: bankAccountName,
      startDate: startDate?.toIso8601String(),
      endDate: endDate?.toIso8601String(),
      minAmount: minAmount,
      maxAmount: maxAmount,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  /// Validar que los parámetros sean válidos
  bool get isValid {
    return page > 0 &&
        limit > 0 &&
        limit <= 100 && // Límite máximo razonable
        (minAmount == null || minAmount! >= 0) &&
        (maxAmount == null || maxAmount! >= 0) &&
        (minAmount == null || maxAmount == null || minAmount! <= maxAmount!) &&
        ['ASC', 'DESC'].contains(sortOrder.toUpperCase());
  }

  /// Crear una copia con nuevos valores
  InvoiceQueryParamsModel copyWith({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? paymentMethod,
    String? customerId,
    String? createdById,
    String? bankAccountId,
    String? bankAccountName,
    String? startDate,
    String? endDate,
    double? minAmount,
    double? maxAmount,
    String? sortBy,
    String? sortOrder,
  }) {
    return InvoiceQueryParamsModel(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerId: customerId ?? this.customerId,
      createdById: createdById ?? this.createdById,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Limpiar filtros pero mantener paginación y ordenamiento
  InvoiceQueryParamsModel clearFilters() {
    return InvoiceQueryParamsModel(
      page: page,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  /// Verificar si tiene filtros aplicados
  bool get hasFilters {
    return search != null ||
        status != null ||
        paymentMethod != null ||
        customerId != null ||
        createdById != null ||
        bankAccountId != null ||
        bankAccountName != null ||
        startDate != null ||
        endDate != null ||
        minAmount != null ||
        maxAmount != null;
  }

  @override
  String toString() {
    final filters = <String>[];
    if (search != null) filters.add('search: $search');
    if (status != null) filters.add('status: $status');
    if (paymentMethod != null) filters.add('paymentMethod: $paymentMethod');
    if (customerId != null) filters.add('customerId: $customerId');
    if (bankAccountId != null) filters.add('bankAccountId: $bankAccountId');
    if (bankAccountName != null) filters.add('bankAccountName: $bankAccountName');
    if (startDate != null) filters.add('startDate: $startDate');
    if (endDate != null) filters.add('endDate: $endDate');
    if (minAmount != null) filters.add('minAmount: $minAmount');
    if (maxAmount != null) filters.add('maxAmount: $maxAmount');

    return 'InvoiceQueryParamsModel(page: $page, limit: $limit, sortBy: $sortBy, sortOrder: $sortOrder${filters.isNotEmpty ? ', filters: [${filters.join(', ')}]' : ''})';
  }
}

/// Modelo específico para búsqueda de facturas
class InvoiceSearchParamsModel {
  final String searchTerm;
  final int limit;
  final List<String>? searchFields;

  const InvoiceSearchParamsModel({
    required this.searchTerm,
    this.limit = 50,
    this.searchFields,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{'search': searchTerm, 'limit': limit};

    if (searchFields != null && searchFields!.isNotEmpty) {
      params['searchFields'] = searchFields!.join(',');
    }

    return params;
  }

  bool get isValid {
    return searchTerm.isNotEmpty && limit > 0 && limit <= 100;
  }
}
