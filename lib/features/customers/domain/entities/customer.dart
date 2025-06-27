// lib/features/customers/domain/entities/customer.dart
import 'package:equatable/equatable.dart';

enum CustomerStatus { active, inactive, suspended }

enum DocumentType {
  cc, // Cédula de ciudadanía
  nit, // Número de identificación tributaria
  ce, // Cédula de extranjería
  passport, // Pasaporte
  other, // Otro
}

class Customer extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? companyName;
  final String email;
  final String? phone;
  final String? mobile;
  final DocumentType documentType;
  final String documentNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final CustomerStatus status;
  final double creditLimit;
  final double currentBalance;
  final int paymentTerms;
  final DateTime? birthDate;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final DateTime? lastPurchaseAt;
  final double totalPurchases;
  final int totalOrders;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.companyName,
    required this.email,
    this.phone,
    this.mobile,
    required this.documentType,
    required this.documentNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    required this.status,
    required this.creditLimit,
    required this.currentBalance,
    required this.paymentTerms,
    this.birthDate,
    this.notes,
    this.metadata,
    this.lastPurchaseAt,
    required this.totalPurchases,
    required this.totalOrders,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    companyName,
    email,
    phone,
    mobile,
    documentType,
    documentNumber,
    address,
    city,
    state,
    zipCode,
    country,
    status,
    creditLimit,
    currentBalance,
    paymentTerms,
    birthDate,
    notes,
    metadata,
    lastPurchaseAt,
    totalPurchases,
    totalOrders,
    createdAt,
    updatedAt,
    deletedAt,
  ];

  // Getters útiles
  String get fullName => '$firstName $lastName';

  String get displayName =>
      companyName?.isNotEmpty == true ? companyName! : fullName;

  bool get isActive => status == CustomerStatus.active && deletedAt == null;

  double get availableCredit => creditLimit - currentBalance;

  bool get isWithinCreditLimit => currentBalance <= creditLimit;

  String get formattedDocument =>
      '${documentType.name.toUpperCase()}: $documentNumber';

  bool get hasOverdueBalance => currentBalance > 0;

  String get riskLevel {
    final balanceRatio = creditLimit > 0 ? currentBalance / creditLimit : 0;
    if (balanceRatio > 0.9) return 'high';
    if (balanceRatio > 0.7) return 'medium';
    return 'low';
  }

  Customer copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? companyName,
    String? email,
    String? phone,
    String? mobile,
    DocumentType? documentType,
    String? documentNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    CustomerStatus? status,
    double? creditLimit,
    double? currentBalance,
    int? paymentTerms,
    DateTime? birthDate,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? lastPurchaseAt,
    double? totalPurchases,
    int? totalOrders,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      status: status ?? this.status,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      birthDate: birthDate ?? this.birthDate,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() =>
      'Customer(id: $id, name: $displayName, email: $email, status: $status)';
}
