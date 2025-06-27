// lib/features/invoices/domain/entities/invoice.dart
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:equatable/equatable.dart';
import '../../../customers/domain/entities/customer.dart';
import 'invoice_item.dart';

enum InvoiceStatus {
  draft('draft', 'Borrador'),
  pending('pending', 'Pendiente'),
  paid('paid', 'Pagada'),
  overdue('overdue', 'Vencida'),
  cancelled('cancelled', 'Cancelada'),
  partiallyPaid('partially_paid', 'Pagada Parcialmente');

  const InvoiceStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static InvoiceStatus fromString(String value) {
    return InvoiceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InvoiceStatus.draft,
    );
  }
}

enum PaymentMethod {
  cash('cash', 'Efectivo'),
  creditCard('credit_card', 'Tarjeta de Crédito'),
  debitCard('debit_card', 'Tarjeta de Débito'),
  bankTransfer('bank_transfer', 'Transferencia Bancaria'),
  check('check', 'Cheque'),
  credit('credit', 'Crédito'),
  other('other', 'Otro');

  const PaymentMethod(this.value, this.displayName);
  final String value;
  final String displayName;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

class Invoice extends Equatable {
  final String id;
  final String number;
  final DateTime date;
  final DateTime dueDate;
  final InvoiceStatus status;
  final PaymentMethod paymentMethod;

  // Totales calculados
  final double subtotal;
  final double taxPercentage;
  final double taxAmount;
  final double discountPercentage;
  final double discountAmount;
  final double total;
  final double paidAmount;
  final double balanceDue;

  // Información adicional
  final String? notes;
  final String? terms;
  final Map<String, dynamic>? metadata;

  // Relaciones
  final String customerId;
  final Customer? customer;
  final String createdById;
  final User? createdBy;
  final List<InvoiceItem> items;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Invoice({
    required this.id,
    required this.number,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.paymentMethod,
    required this.subtotal,
    required this.taxPercentage,
    required this.taxAmount,
    required this.discountPercentage,
    required this.discountAmount,
    required this.total,
    required this.paidAmount,
    required this.balanceDue,
    this.notes,
    this.terms,
    this.metadata,
    required this.customerId,
    this.customer,
    required this.createdById,
    this.createdBy,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
    id,
    number,
    date,
    dueDate,
    status,
    paymentMethod,
    subtotal,
    taxPercentage,
    taxAmount,
    discountPercentage,
    discountAmount,
    total,
    paidAmount,
    balanceDue,
    notes,
    terms,
    metadata,
    customerId,
    customer,
    createdById,
    createdBy,
    items,
    createdAt,
    updatedAt,
    deletedAt,
  ];

  // Getters útiles
  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && status != InvoiceStatus.paid;
  }

  bool get isPaid {
    return status == InvoiceStatus.paid || balanceDue <= 0;
  }

  bool get isPartiallyPaid {
    return paidAmount > 0 && paidAmount < total;
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    final difference = DateTime.now().difference(dueDate);
    return difference.inDays;
  }

  bool get canBeEdited {
    return status == InvoiceStatus.draft;
  }

  bool get canBeCancelled {
    return status != InvoiceStatus.paid && status != InvoiceStatus.cancelled;
  }

  bool get canAddPayment {
    return status != InvoiceStatus.paid &&
        status != InvoiceStatus.cancelled &&
        balanceDue > 0;
  }

  String get statusDisplayName => status.displayName;
  String get paymentMethodDisplayName => paymentMethod.displayName;

  // Customer info helpers
  String get customerName {
    if (customer != null) {
      if (customer!.companyName?.isNotEmpty == true) {
        return customer!.companyName!;
      }
      return '${customer!.firstName} ${customer!.lastName}';
    }
    return 'Cliente no encontrado';
  }

  String? get customerEmail => customer?.email;
  String? get customerPhone => customer?.phone;

  Invoice copyWith({
    String? id,
    String? number,
    DateTime? date,
    DateTime? dueDate,
    InvoiceStatus? status,
    PaymentMethod? paymentMethod,
    double? subtotal,
    double? taxPercentage,
    double? taxAmount,
    double? discountPercentage,
    double? discountAmount,
    double? total,
    double? paidAmount,
    double? balanceDue,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
    String? customerId,
    Customer? customer,
    String? createdById,
    User? createdBy,
    List<InvoiceItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxAmount: taxAmount ?? this.taxAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      metadata: metadata ?? this.metadata,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      createdById: createdById ?? this.createdById,
      createdBy: createdBy ?? this.createdBy,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory Invoice.empty() {
    return Invoice(
      id: '',
      number: '',
      date: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      status: InvoiceStatus.draft,
      paymentMethod: PaymentMethod.cash,
      subtotal: 0,
      taxPercentage: 19,
      taxAmount: 0,
      discountPercentage: 0,
      discountAmount: 0,
      total: 0,
      paidAmount: 0,
      balanceDue: 0,
      customerId: '',
      createdById: '',
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
