// lib/features/invoices/data/models/invoice_payment_model.dart
import 'package:isar/isar.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_payment.dart';
import '../../../bank_accounts/data/models/bank_account_model.dart';
import '../../../bank_accounts/domain/entities/bank_account.dart';

part 'invoice_payment_model.g.dart';

@collection
class InvoicePaymentModel {
  Id get isarId => fastHash(id);

  late String id;
  late double amount;

  @enumerated
  late PaymentMethod paymentMethod;

  late DateTime paymentDate;
  String? reference;
  String? notes;
  late String invoiceId;
  late String createdById;
  late String organizationId;

  // Cuenta bancaria asociada (opcional)
  String? bankAccountId;
  @ignore
  BankAccount? bankAccount;

  late DateTime createdAt;
  late DateTime updatedAt;

  InvoicePaymentModel();

  InvoicePaymentModel._({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.reference,
    this.notes,
    required this.invoiceId,
    required this.createdById,
    required this.organizationId,
    this.bankAccountId,
    this.bankAccount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper methods for parsing data safely
  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      String cleanedValue = value.trim();
      if (cleanedValue.isEmpty) return 0.0;
      cleanedValue = cleanedValue.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      if (cleanedValue.isEmpty) return 0.0;
      final parsed = double.tryParse(cleanedValue);
      if (parsed != null) return parsed;
      final parsedInt = int.tryParse(cleanedValue);
      if (parsedInt != null) return parsedInt.toDouble();
    }
    print('⚠️ No se pudo convertir a double: $value (${value.runtimeType})');
    return 0.0;
  }

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

  factory InvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    print('🔍 InvoicePaymentModel.fromJson: Procesando payment ${json['id']}');

    try {
      // Parsear bankAccount si viene en el JSON
      BankAccount? bankAccount;
      if (json['bankAccount'] != null && json['bankAccount'] is Map) {
        bankAccount = BankAccountModel.fromJson(
          json['bankAccount'] as Map<String, dynamic>,
        ).toEntity();
      }

      return InvoicePaymentModel._(
        id: json['id']?.toString() ?? '',
        amount: _parseToDouble(json['amount']),
        paymentMethod: PaymentMethod.fromString(
          json['paymentMethod']?.toString() ?? 'cash',
        ),
        paymentDate: _parseDateTime(json['paymentDate']),
        reference: json['reference']?.toString(),
        notes: json['notes']?.toString(),
        invoiceId: json['invoiceId']?.toString() ?? '',
        createdById: json['createdById']?.toString() ?? '',
        organizationId: json['organizationId']?.toString() ?? '',
        bankAccountId: json['bankAccountId']?.toString(),
        bankAccount: bankAccount,
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      print('❌ Error en InvoicePaymentModel.fromJson: $e');
      print('📋 JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'paymentMethod': paymentMethod.value,
      'paymentDate': paymentDate.toIso8601String(),
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
      'invoiceId': invoiceId,
      'createdById': createdById,
      'organizationId': organizationId,
      if (bankAccountId != null) 'bankAccountId': bankAccountId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InvoicePaymentModel.fromEntity(InvoicePayment payment) {
    return InvoicePaymentModel._(
      id: payment.id,
      amount: payment.amount,
      paymentMethod: payment.paymentMethod,
      paymentDate: payment.paymentDate,
      reference: payment.reference,
      notes: payment.notes,
      invoiceId: payment.invoiceId,
      createdById: payment.createdById,
      organizationId: payment.organizationId,
      bankAccountId: payment.bankAccountId,
      bankAccount: payment.bankAccount,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
    );
  }

  /// Convierte el modelo a entidad de dominio
  InvoicePayment toEntity() {
    return InvoicePayment(
      id: id,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate,
      reference: reference,
      notes: notes,
      invoiceId: invoiceId,
      createdById: createdById,
      organizationId: organizationId,
      bankAccountId: bankAccountId,
      bankAccount: bankAccount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Indexes for better query performance
  @Index()
  String get invoiceIdIndex => invoiceId;

  @Index()
  String get organizationIdIndex => organizationId;

  @Index()
  DateTime get paymentDateIndex => paymentDate;

  @Index()
  DateTime get createdAtIndex => createdAt;
}

/// Fast hash function for Isar ID generation
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;
  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }
  return hash;
}