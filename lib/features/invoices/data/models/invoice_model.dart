// // lib/features/invoices/data/models/invoice_model.dart
// import 'package:baudex_desktop/features/auth/data/models/user_model.dart';

// import '../../domain/entities/invoice.dart';
// import '../../domain/entities/invoice_item.dart';
// import '../../../customers/data/models/customer_model.dart';

// import 'invoice_item_model.dart';

// class InvoiceModel extends Invoice {
//   const InvoiceModel({
//     required super.id,
//     required super.number,
//     required super.date,
//     required super.dueDate,
//     required super.status,
//     required super.paymentMethod,
//     required super.subtotal,
//     required super.taxPercentage,
//     required super.taxAmount,
//     required super.discountPercentage,
//     required super.discountAmount,
//     required super.total,
//     required super.paidAmount,
//     required super.balanceDue,
//     super.notes,
//     super.terms,
//     super.metadata,
//     required super.customerId,
//     super.customer,
//     required super.createdById,
//     super.createdBy,
//     required super.items,
//     required super.createdAt,
//     required super.updatedAt,
//     super.deletedAt,
//   });

//   factory InvoiceModel.fromJson(Map<String, dynamic> json) {
//     return InvoiceModel(
//       id: json['id'] as String,
//       number: json['number'] as String,
//       date: DateTime.parse(json['date'] as String),
//       dueDate: DateTime.parse(json['dueDate'] as String),
//       status: InvoiceStatus.fromString(json['status'] as String),
//       paymentMethod: PaymentMethod.fromString(json['paymentMethod'] as String),
//       subtotal: (json['subtotal'] as num).toDouble(),
//       taxPercentage: (json['taxPercentage'] as num).toDouble(),
//       taxAmount: (json['taxAmount'] as num).toDouble(),
//       discountPercentage: (json['discountPercentage'] as num).toDouble(),
//       discountAmount: (json['discountAmount'] as num).toDouble(),
//       total: (json['total'] as num).toDouble(),
//       paidAmount: (json['paidAmount'] as num).toDouble(),
//       balanceDue: (json['balanceDue'] as num).toDouble(),
//       notes: json['notes'] as String?,
//       terms: json['terms'] as String?,
//       metadata: json['metadata'] as Map<String, dynamic>?,
//       customerId: json['customerId'] as String,
//       customer:
//           json['customer'] != null
//               ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
//               : null,
//       createdById: json['createdById'] as String,
//       createdBy:
//           json['createdBy'] != null
//               ? UserModel.fromJson(json['createdBy'] as Map<String, dynamic>)
//               : null,
//       items:
//           (json['items'] as List?)
//               ?.map(
//                 (item) =>
//                     InvoiceItemModel.fromJson(item as Map<String, dynamic>),
//               )
//               .toList() ??
//           [],
//       createdAt: DateTime.parse(json['createdAt'] as String),
//       updatedAt: DateTime.parse(json['updatedAt'] as String),
//       deletedAt:
//           json['deletedAt'] != null
//               ? DateTime.parse(json['deletedAt'] as String)
//               : null,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'number': number,
//       'date': date.toIso8601String(),
//       'dueDate': dueDate.toIso8601String(),
//       'status': status.value,
//       'paymentMethod': paymentMethod.value,
//       'subtotal': subtotal,
//       'taxPercentage': taxPercentage,
//       'taxAmount': taxAmount,
//       'discountPercentage': discountPercentage,
//       'discountAmount': discountAmount,
//       'total': total,
//       'paidAmount': paidAmount,
//       'balanceDue': balanceDue,
//       if (notes != null) 'notes': notes,
//       if (terms != null) 'terms': terms,
//       if (metadata != null) 'metadata': metadata,
//       'customerId': customerId,
//       if (customer != null) 'customer': (customer as CustomerModel).toJson(),
//       'createdById': createdById,
//       if (createdBy != null) 'createdBy': (createdBy as UserModel).toJson(),
//       'items':
//           items.map((item) => (item as InvoiceItemModel).toJson()).toList(),
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//       if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
//     };
//   }

//   factory InvoiceModel.fromEntity(Invoice invoice) {
//     return InvoiceModel(
//       id: invoice.id,
//       number: invoice.number,
//       date: invoice.date,
//       dueDate: invoice.dueDate,
//       status: invoice.status,
//       paymentMethod: invoice.paymentMethod,
//       subtotal: invoice.subtotal,
//       taxPercentage: invoice.taxPercentage,
//       taxAmount: invoice.taxAmount,
//       discountPercentage: invoice.discountPercentage,
//       discountAmount: invoice.discountAmount,
//       total: invoice.total,
//       paidAmount: invoice.paidAmount,
//       balanceDue: invoice.balanceDue,
//       notes: invoice.notes,
//       terms: invoice.terms,
//       metadata: invoice.metadata,
//       customerId: invoice.customerId,
//       customer: invoice.customer,
//       createdById: invoice.createdById,
//       createdBy: invoice.createdBy,
//       items: invoice.items,
//       createdAt: invoice.createdAt,
//       updatedAt: invoice.updatedAt,
//       deletedAt: invoice.deletedAt,
//     );
//   }
// }

// lib/features/invoices/data/models/invoice_model.dart
import 'package:baudex_desktop/features/auth/data/models/user_model.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/invoice_payment.dart';
import '../../../customers/data/models/customer_model.dart';

import 'invoice_item_model.dart';
import 'invoice_payment_model.dart';

class InvoiceModel extends Invoice {
  const InvoiceModel({
    required super.id,
    required super.number,
    required super.date,
    required super.dueDate,
    required super.status,
    required super.paymentMethod,
    required super.subtotal,
    required super.taxPercentage,
    required super.taxAmount,
    required super.discountPercentage,
    required super.discountAmount,
    required super.total,
    required super.paidAmount,
    required super.balanceDue,
    super.notes,
    super.terms,
    super.metadata,
    required super.customerId,
    super.customer,
    required super.createdById,
    super.createdBy,
    required super.items,
    required super.payments,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  /// ✅ MÉTODO HELPER ROBUSTO PARA CONVERTIR CUALQUIER VALOR A DOUBLE
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;

    // Si ya es un número, convertir directamente
    if (value is num) return value.toDouble();

    // Si es string, limpiar y convertir
    if (value is String) {
      // Remover espacios en blanco
      String cleanedValue = value.trim();

      // Si está vacío después de limpiar, retornar 0
      if (cleanedValue.isEmpty) return 0.0;

      // Remover ceros innecesarios al inicio (ej: "0195000.00" -> "195000.00")
      cleanedValue = cleanedValue.replaceFirst(RegExp(r'^0+(?=\d)'), '');

      // Si quedó vacío, significa que era solo "0" o "00", etc.
      if (cleanedValue.isEmpty) return 0.0;

      // Intentar parsear
      final parsed = double.tryParse(cleanedValue);
      if (parsed != null) return parsed;

      // Si no se pudo parsear, intentar como int y luego convertir
      final parsedInt = int.tryParse(cleanedValue);
      if (parsedInt != null) return parsedInt.toDouble();
    }

    // Si todo falla, retornar 0
    print('⚠️ No se pudo convertir a double: $value (${value.runtimeType})');
    return 0.0;
  }

  /// ✅ MÉTODO HELPER PARA FECHAS
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Error parsing date: $value - $e');
        return DateTime.now();
      }
    }

    if (value is DateTime) return value;

    return DateTime.now();
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    print('🔍 InvoiceModel.fromJson: Procesando factura ${json['id']}');

    try {
      return InvoiceModel(
        id: json['id']?.toString() ?? '',
        number: json['number']?.toString() ?? '',
        date: _parseDateTime(json['date']),
        dueDate: _parseDateTime(json['dueDate']),
        status: InvoiceStatus.fromString(json['status']?.toString() ?? 'draft'),
        paymentMethod: PaymentMethod.fromString(
          json['paymentMethod']?.toString() ?? 'cash',
        ),

        // ✅ USAR EL MÉTODO HELPER ROBUSTO PARA TODOS LOS CAMPOS NUMÉRICOS
        subtotal: _parseToDouble(json['subtotal']),
        taxPercentage: _parseToDouble(json['taxPercentage']),
        taxAmount: _parseToDouble(json['taxAmount']),
        discountPercentage: _parseToDouble(json['discountPercentage']),
        discountAmount: _parseToDouble(json['discountAmount']),
        total: _parseToDouble(json['total']),
        paidAmount: _parseToDouble(json['paidAmount']),
        balanceDue: _parseToDouble(json['balanceDue']),

        // Campos opcionales
        notes: json['notes']?.toString(),
        terms: json['terms']?.toString(),
        metadata: json['metadata'] as Map<String, dynamic>?,

        // IDs y relaciones
        customerId: json['customerId']?.toString() ?? '',
        customer:
            json['customer'] != null
                ? CustomerModel.fromJson(
                  json['customer'] as Map<String, dynamic>,
                )
                : null,
        createdById: json['createdById']?.toString() ?? '',
        createdBy:
            json['createdBy'] != null
                ? UserModel.fromJson(json['createdBy'] as Map<String, dynamic>)
                : null,

        // ✅ ITEMS CON MANEJO DE ERRORES
        items: _parseItems(json['items']),

        // ✅ PAYMENTS CON MANEJO DE ERRORES
        payments: _parsePayments(json['payments']),

        // Timestamps
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
        deletedAt:
            json['deletedAt'] != null
                ? _parseDateTime(json['deletedAt'])
                : null,
      );
    } catch (e) {
      print('❌ Error en InvoiceModel.fromJson: $e');
      print('📋 JSON data: $json');
      rethrow;
    }
  }

  /// ✅ MÉTODO HELPER PARA PARSEAR ITEMS DE FORMA SEGURA
  static List<InvoiceItem> _parseItems(dynamic itemsData) {
    if (itemsData == null) return [];

    if (itemsData is! List) {
      print('⚠️ Items no es una lista: ${itemsData.runtimeType}');
      return [];
    }

    final items = <InvoiceItem>[];

    for (int i = 0; i < itemsData.length; i++) {
      try {
        final itemJson = itemsData[i];
        if (itemJson is Map<String, dynamic>) {
          final item = InvoiceItemModel.fromJson(itemJson);
          items.add(item);
        } else {
          print('⚠️ Item $i no es un Map válido');
        }
      } catch (e) {
        print('❌ Error parseando item $i: $e');
        // Continuar con los demás items
      }
    }

    print('✅ Items parseados: ${items.length} de ${itemsData.length}');
    return items;
  }

  /// ✅ MÉTODO HELPER PARA PARSEAR PAYMENTS DE FORMA SEGURA
  static List<InvoicePayment> _parsePayments(dynamic paymentsData) {
    if (paymentsData == null) return [];

    if (paymentsData is! List) {
      print('⚠️ Payments no es una lista: ${paymentsData.runtimeType}');
      return [];
    }

    final payments = <InvoicePayment>[];

    for (int i = 0; i < paymentsData.length; i++) {
      try {
        final paymentJson = paymentsData[i];
        if (paymentJson is Map<String, dynamic>) {
          final paymentModel = InvoicePaymentModel.fromJson(paymentJson);
          payments.add(paymentModel.toEntity());
        } else {
          print('⚠️ Payment $i no es un Map válido');
        }
      } catch (e) {
        print('❌ Error parseando payment $i: $e');
        // Continuar con los demás payments
      }
    }

    print('✅ Payments parseados: ${payments.length} de ${paymentsData.length}');
    return payments;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.value,
      'paymentMethod': paymentMethod.value,
      'subtotal': subtotal,
      'taxPercentage': taxPercentage,
      'taxAmount': taxAmount,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'total': total,
      'paidAmount': paidAmount,
      'balanceDue': balanceDue,
      if (notes != null) 'notes': notes,
      if (terms != null) 'terms': terms,
      if (metadata != null) 'metadata': metadata,
      'customerId': customerId,
      if (customer != null) 'customer': (customer as CustomerModel).toJson(),
      'createdById': createdById,
      if (createdBy != null) 'createdBy': (createdBy as UserModel).toJson(),
      'items':
          items.map((item) => (item as InvoiceItemModel).toJson()).toList(),
      'payments':
          payments.map((payment) => InvoicePaymentModel.fromEntity(payment).toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    };
  }

  factory InvoiceModel.fromEntity(Invoice invoice) {
    return InvoiceModel(
      id: invoice.id,
      number: invoice.number,
      date: invoice.date,
      dueDate: invoice.dueDate,
      status: invoice.status,
      paymentMethod: invoice.paymentMethod,
      subtotal: invoice.subtotal,
      taxPercentage: invoice.taxPercentage,
      taxAmount: invoice.taxAmount,
      discountPercentage: invoice.discountPercentage,
      discountAmount: invoice.discountAmount,
      total: invoice.total,
      paidAmount: invoice.paidAmount,
      balanceDue: invoice.balanceDue,
      notes: invoice.notes,
      terms: invoice.terms,
      metadata: invoice.metadata,
      customerId: invoice.customerId,
      customer: invoice.customer,
      createdById: invoice.createdById,
      createdBy: invoice.createdBy,
      items: invoice.items,
      payments: invoice.payments,
      createdAt: invoice.createdAt,
      updatedAt: invoice.updatedAt,
      deletedAt: invoice.deletedAt,
    );
  }

  /// Convierte el modelo a entidad de dominio
  Invoice toEntity() {
    return Invoice(
      id: id,
      number: number,
      date: date,
      dueDate: dueDate,
      status: status,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      taxPercentage: taxPercentage,
      taxAmount: taxAmount,
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      total: total,
      paidAmount: paidAmount,
      balanceDue: balanceDue,
      notes: notes,
      terms: terms,
      metadata: metadata,
      customerId: customerId,
      customer: customer,
      createdById: createdById,
      createdBy: createdBy,
      items: items,
      payments: payments,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}
