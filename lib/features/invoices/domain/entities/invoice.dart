// lib/features/invoices/domain/entities/invoice.dart
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../customers/domain/entities/customer.dart';
import 'invoice_item.dart';
import 'invoice_payment.dart';

enum InvoiceStatus {
  draft('draft', 'Borrador'),
  pending('pending', 'Pendiente'),
  paid('paid', 'Pagada'),
  overdue('overdue', 'Vencida'),
  cancelled('cancelled', 'Cancelada'),
  partiallyPaid('partially_paid', 'Pagada Parcialmente'),
  // Estados para notas de crédito
  credited('credited', 'Acreditada'),
  partiallyCredited('partially_credited', 'Acreditada Parcialmente');

  const InvoiceStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static InvoiceStatus fromString(String value) {
    return InvoiceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InvoiceStatus.draft,
    );
  }

  /// Verifica si la factura tiene alguna nota de crédito aplicada
  bool get hasCreditNote =>
      this == InvoiceStatus.credited || this == InvoiceStatus.partiallyCredited;

  /// Verifica si la factura está completamente acreditada (anulada)
  bool get isFullyCredited => this == InvoiceStatus.credited;
}

enum PaymentMethod {
  cash('cash', 'Efectivo', Icons.money),
  credit('credit', 'Crédito', Icons.credit_score),
  creditCard('credit_card', 'Tarjeta de Crédito', Icons.credit_card),
  debitCard('debit_card', 'Tarjeta de Débito', Icons.payment),
  bankTransfer('bank_transfer', 'Transferencia Bancaria', Icons.account_balance),
  check('check', 'Cheque', Icons.receipt),
  clientBalance('client_balance', 'Saldo a Favor', Icons.account_balance_wallet),
  other('other', 'Otro', Icons.more_horiz);

  const PaymentMethod(this.value, this.displayName, this.icon);
  final String value;
  final String displayName;
  final IconData icon;

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
  final double creditedAmount; // Monto acreditado por notas de crédito

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
  final List<InvoicePayment> payments;

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
    this.creditedAmount = 0,
    this.notes,
    this.terms,
    this.metadata,
    required this.customerId,
    this.customer,
    required this.createdById,
    this.createdBy,
    required this.items,
    required this.payments,
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
    creditedAmount,
    notes,
    terms,
    metadata,
    customerId,
    customer,
    createdById,
    createdBy,
    items,
    payments,
    createdAt,
    updatedAt,
    deletedAt,
  ];

  // Getters útiles

  /// Verifica si la factura está vencida
  /// Reglas de negocio:
  /// - NUNCA está vencida si: paid, draft, cancelled, credited
  /// - NUNCA está vencida si balanceDue <= 0
  /// - NUNCA está vencida si es pago parcial y dueDate == fecha creación (legacy fix)
  /// - SÍ puede estar vencida si: pending o partially_paid Y pasó la fecha
  bool get isOverdue {
    // Estados que NUNCA pueden estar vencidos
    if (status == InvoiceStatus.paid ||
        status == InvoiceStatus.draft ||
        status == InvoiceStatus.cancelled ||
        status == InvoiceStatus.credited) {
      return false;
    }

    // No hay saldo pendiente = no puede estar vencida
    if (balanceDue <= 0) {
      return false;
    }

    // Comparar solo fechas (sin horas) para evitar falsos positivos
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final invoiceDateOnly = DateTime(date.year, date.month, date.day);

    // 📅 LEGACY FIX: Facturas con pago parcial donde dueDate == fecha de creación
    // Estas facturas tienen datos incorrectos de versiones anteriores
    // Les damos un plazo implícito de 30 días desde su creación
    if (status == InvoiceStatus.partiallyPaid &&
        dueDateOnly.isAtSameMomentAs(invoiceDateOnly)) {
      // Calcular fecha de vencimiento implícita (30 días desde creación)
      final implicitDueDate = invoiceDateOnly.add(const Duration(days: 30));
      // Vencida solo si hoy es DESPUÉS de la fecha implícita
      return today.isAfter(implicitDueDate);
    }

    // Vencida solo si la fecha de hoy es DESPUÉS de la fecha de vencimiento
    // (no el mismo día, sino días posteriores)
    return today.isAfter(dueDateOnly);
  }

  bool get isPaid {
    return status == InvoiceStatus.paid || balanceDue <= 0;
  }

  bool get isPartiallyPaid {
    return paidAmount > 0 && paidAmount < total;
  }

  /// Días de vencimiento (solo si está vencida)
  /// Retorna días completos transcurridos desde la fecha de vencimiento
  int get daysOverdue {
    if (!isOverdue) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final invoiceDateOnly = DateTime(date.year, date.month, date.day);

    // 📅 LEGACY FIX: Facturas con pago parcial donde dueDate == fecha de creación
    // Usar fecha implícita de 30 días
    DateTime effectiveDueDate = dueDateOnly;
    if (status == InvoiceStatus.partiallyPaid &&
        dueDateOnly.isAtSameMomentAs(invoiceDateOnly)) {
      effectiveDueDate = invoiceDateOnly.add(const Duration(days: 30));
    }

    final days = today.difference(effectiveDueDate).inDays;
    return days > 0 ? days : 0;
  }

  /// Días restantes hasta el vencimiento (si aún no está vencida)
  /// Retorna 0 si ya está vencida o pagada
  int get daysUntilDue {
    if (isOverdue || isPaid) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final invoiceDateOnly = DateTime(date.year, date.month, date.day);

    // 📅 LEGACY FIX: Facturas con pago parcial donde dueDate == fecha de creación
    // Usar fecha implícita de 30 días
    DateTime effectiveDueDate = dueDateOnly;
    if (status == InvoiceStatus.partiallyPaid &&
        dueDateOnly.isAtSameMomentAs(invoiceDateOnly)) {
      effectiveDueDate = invoiceDateOnly.add(const Duration(days: 30));
    }

    final difference = effectiveDueDate.difference(today).inDays;
    return difference > 0 ? difference : 0;
  }

  /// Indica si la factura vence pronto (dentro de 3 días)
  bool get isDueSoon {
    if (isOverdue || isPaid) return false;
    return daysUntilDue > 0 && daysUntilDue <= 3;
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

  /// Nombre para mostrar del método de pago
  /// Prioriza mostrar el nombre del banco si existe (Nequi, Daviplata, Bancolombia, etc.)
  String get paymentMethodDisplayName {
    // Si hay pagos con cuenta bancaria, mostrar directamente el nombre del banco
    if (payments.isNotEmpty) {
      final firstPayment = payments.first;
      if (firstPayment.bankAccount != null && firstPayment.bankAccount!.name.isNotEmpty) {
        return firstPayment.bankAccount!.name;
      }
    }
    return paymentMethod.displayName;
  }

  /// Nombre completo del método de pago (incluye tipo + banco si existe)
  /// Formato: "Transferencia Bancaria (Nequi)"
  String get fullPaymentMethodDisplayName {
    if (payments.isNotEmpty) {
      final firstPayment = payments.first;
      if (firstPayment.bankAccount != null && firstPayment.bankAccount!.name.isNotEmpty) {
        return '${paymentMethod.displayName} (${firstPayment.bankAccount!.name})';
      }
    }
    return paymentMethod.displayName;
  }

  /// Nombre corto del método de pago para mostrar en cards
  /// Prioriza mostrar el nombre del banco si existe (Nequi, Daviplata, etc.)
  String get shortPaymentMethodName {
    // Si hay pagos con cuenta bancaria, mostrar SOLO el nombre del banco
    if (payments.isNotEmpty) {
      final firstPayment = payments.first;
      if (firstPayment.bankAccount != null && firstPayment.bankAccount!.name.isNotEmpty) {
        return firstPayment.bankAccount!.name;
      }
    }
    // Si no hay banco, mostrar nombre corto del método
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.creditCard:
        return 'T.Crédito';
      case PaymentMethod.debitCard:
        return 'T.Débito';
      case PaymentMethod.bankTransfer:
        return 'Transferencia';
      case PaymentMethod.check:
        return 'Cheque';
      case PaymentMethod.credit:
        return 'Crédito';
      case PaymentMethod.clientBalance:
        return 'Saldo a Favor';
      case PaymentMethod.other:
        return 'Otro';
    }
  }

  /// Obtiene el ícono apropiado para el método de pago
  /// Si tiene cuenta bancaria, usa el ícono de banco
  IconData get paymentMethodIcon {
    if (payments.isNotEmpty && payments.first.bankAccount != null) {
      return Icons.account_balance;
    }
    return paymentMethod.icon;
  }

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
    double? creditedAmount,
    String? notes,
    String? terms,
    Map<String, dynamic>? metadata,
    String? customerId,
    Customer? customer,
    String? createdById,
    User? createdBy,
    List<InvoiceItem>? items,
    List<InvoicePayment>? payments,
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
      creditedAmount: creditedAmount ?? this.creditedAmount,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      metadata: metadata ?? this.metadata,
      customerId: customerId ?? this.customerId,
      customer: customer ?? this.customer,
      createdById: createdById ?? this.createdById,
      createdBy: createdBy ?? this.createdBy,
      items: items ?? this.items,
      payments: payments ?? this.payments,
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
      creditedAmount: 0,
      customerId: '',
      createdById: '',
      items: [],
      payments: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Payment-related helper methods
  double get totalPaidFromPayments {
    return payments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double get remainingBalance {
    return total - totalPaidFromPayments;
  }

  bool get hasPayments {
    return payments.isNotEmpty;
  }

  List<InvoicePayment> get sortedPayments {
    final sortedList = List<InvoicePayment>.from(payments);
    sortedList.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return sortedList;
  }
}
