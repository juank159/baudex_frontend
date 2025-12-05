// lib/features/invoices/domain/repositories/invoice_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../entities/invoice.dart';
import '../entities/invoice_stats.dart';

abstract class InvoiceRepository {
  // ==================== READ OPERATIONS ====================

  /// Obtener facturas con paginación y filtros
  Future<Either<Failure, PaginatedResult<Invoice>>> getInvoices({
    int page = 1,
    int limit = 10,
    String? search,
    InvoiceStatus? status,
    PaymentMethod? paymentMethod,
    String? customerId,
    String? createdById,
    String? bankAccountId, // Filtro por ID de cuenta bancaria (legacy)
    String? bankAccountName, // ✅ NUEVO: Filtro por nombre de método de pago (Nequi, Bancolombia, etc.)
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  });

  /// Obtener factura por ID
  Future<Either<Failure, Invoice>> getInvoiceById(String id);

  /// Obtener factura por número
  Future<Either<Failure, Invoice>> getInvoiceByNumber(String number);

  /// Obtener facturas vencidas
  Future<Either<Failure, List<Invoice>>> getOverdueInvoices();

  /// Obtener estadísticas de facturas
  Future<Either<Failure, InvoiceStats>> getInvoiceStats();

  /// Obtener facturas por cliente
  Future<Either<Failure, List<Invoice>>> getInvoicesByCustomer(
    String customerId,
  );

  /// Buscar facturas
  Future<Either<Failure, List<Invoice>>> searchInvoices(String searchTerm);

  // ==================== WRITE OPERATIONS ====================

  /// Crear nueva factura
  Future<Either<Failure, Invoice>> createInvoice({
    required String customerId,
    required List<CreateInvoiceItemParams> items,
    String? number,
    DateTime? date,
    DateTime? dueDate,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    InvoiceStatus? status,
    double taxPercentage = 19,
    double discountPercentage = 0,
    double discountAmount = 0,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
    String? bankAccountId, // 🏦 ID de la cuenta bancaria para registrar el pago
  });

  /// Actualizar factura (solo si está en borrador)
  Future<Either<Failure, Invoice>> updateInvoice({
    required String id,
    String? number,
    DateTime? date,
    DateTime? dueDate,
    PaymentMethod? paymentMethod,
    InvoiceStatus? status,
    double? taxPercentage,
    double? discountPercentage,
    double? discountAmount,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
    String? customerId,
    List<CreateInvoiceItemParams>? items,
  });

  /// Confirmar factura (cambiar de borrador a pendiente)
  Future<Either<Failure, Invoice>> confirmInvoice(String id);

  /// Cancelar factura
  Future<Either<Failure, Invoice>> cancelInvoice(String id);

  /// Agregar pago a factura
  Future<Either<Failure, Invoice>> addPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? bankAccountId,
    DateTime? paymentDate,
    String? reference,
    String? notes,
  });

  /// Agregar múltiples pagos a factura (pagos divididos entre métodos)
  Future<Either<Failure, MultiplePaymentsResult>> addMultiplePayments({
    required String invoiceId,
    required List<PaymentItemData> payments,
    DateTime? paymentDate,
    bool createCreditForRemaining = false,
    String? generalNotes,
  });

  /// Eliminar factura (soft delete)
  Future<Either<Failure, void>> deleteInvoice(String id);

  /// ✅ NUEVO: Descargar PDF de factura
  Future<Either<Failure, List<int>>> downloadInvoicePdf(String id);
}

// ==================== PARÁMETROS ====================

class CreateInvoiceItemParams {
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercentage;
  final double discountAmount;
  final String? unit;
  final String? notes;
  final String? productId;

  const CreateInvoiceItemParams({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.unit,
    this.notes,
    this.productId,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      if (unit != null) 'unit': unit,
      if (notes != null) 'notes': notes,
      if (productId != null) 'productId': productId,
    };
  }
}

class InvoiceQueryParams {
  final int page;
  final int limit;
  final String? search;
  final InvoiceStatus? status;
  final PaymentMethod? paymentMethod;
  final String? customerId;
  final String? createdById;
  final String? bankAccountId; // Filtro por ID de cuenta bancaria (legacy)
  final String? bankAccountName; // ✅ NUEVO: Filtro por nombre de método de pago (Nequi, Bancolombia, etc.)
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy;
  final String sortOrder;

  const InvoiceQueryParams({
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

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (status != null) {
      params['status'] = status!.value;
    }
    if (paymentMethod != null) {
      params['paymentMethod'] = paymentMethod!.value;
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
    if (bankAccountName != null) {
      params['bankAccountName'] = bankAccountName;
    }
    if (startDate != null) {
      params['startDate'] = startDate!.toIso8601String();
    }
    if (endDate != null) {
      params['endDate'] = endDate!.toIso8601String();
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

// ==================== PAGOS MÚLTIPLES ====================

/// Datos de un ítem de pago para pagos múltiples
class PaymentItemData {
  final double amount;
  final PaymentMethod paymentMethod;
  final String? bankAccountId;
  final String? bankAccountName; // Para mostrar en UI
  final String? reference;
  final String? notes;

  const PaymentItemData({
    required this.amount,
    required this.paymentMethod,
    this.bankAccountId,
    this.bankAccountName,
    this.reference,
    this.notes,
  });

  bool get isValid => amount > 0;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'amount': amount,
      'paymentMethod': paymentMethod.value,
    };
    if (bankAccountId != null) json['bankAccountId'] = bankAccountId;
    if (reference != null) json['reference'] = reference;
    if (notes != null) json['notes'] = notes;
    return json;
  }
}

/// Resultado de agregar múltiples pagos
class MultiplePaymentsResult {
  final Invoice invoice;
  final int paymentsCreated;
  final double remainingBalance;
  final bool creditCreated;
  final String? creditId;

  const MultiplePaymentsResult({
    required this.invoice,
    required this.paymentsCreated,
    required this.remainingBalance,
    this.creditCreated = false,
    this.creditId,
  });

  factory MultiplePaymentsResult.fromJson(Map<String, dynamic> json, Invoice invoice) {
    return MultiplePaymentsResult(
      invoice: invoice,
      paymentsCreated: (json['payments'] as List?)?.length ?? 0,
      remainingBalance: (json['remainingBalance'] as num?)?.toDouble() ?? 0.0,
      creditCreated: json['creditCreated'] as bool? ?? false,
      creditId: json['creditId'] as String?,
    );
  }
}
