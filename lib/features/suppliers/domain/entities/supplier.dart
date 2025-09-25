// lib/features/suppliers/domain/entities/supplier.dart
import 'package:equatable/equatable.dart';

enum SupplierStatus { active, inactive, blocked }

enum DocumentType { nit, cc, ce, passport, rut, other }

class Supplier extends Equatable {
  final String id;
  final String name;
  final String? code;
  final DocumentType documentType;
  final String documentNumber;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? website;
  final SupplierStatus status;
  final String currency;
  final int paymentTermsDays;
  final double creditLimit;
  final double discountPercentage;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Supplier({
    required this.id,
    required this.name,
    this.code,
    required this.documentType,
    required this.documentNumber,
    this.contactPerson,
    this.email,
    this.phone,
    this.mobile,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.website,
    required this.status,
    required this.currency,
    required this.paymentTermsDays,
    required this.creditLimit,
    required this.discountPercentage,
    this.notes,
    this.metadata,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        documentType,
        documentNumber,
        contactPerson,
        email,
        phone,
        mobile,
        address,
        city,
        state,
        country,
        postalCode,
        website,
        status,
        currency,
        paymentTermsDays,
        creditLimit,
        discountPercentage,
        notes,
        metadata,
        organizationId,
        createdAt,
        updatedAt,
        deletedAt,
      ];

  // Getters útiles
  bool get isActive => status == SupplierStatus.active;
  bool get isBlocked => status == SupplierStatus.blocked;
  bool get isDeleted => deletedAt != null;
  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasPhone => phone != null && phone!.isNotEmpty;
  bool get hasMobile => mobile != null && mobile!.isNotEmpty;
  bool get hasContactInfo => hasEmail || hasPhone || hasMobile;
  bool get hasAddress => address != null && address!.isNotEmpty;
  bool get hasWebsite => website != null && website!.isNotEmpty;
  bool get hasCreditLimit => creditLimit > 0;
  bool get hasDiscount => discountPercentage > 0;
  
  String get displayName => name;
  String get displayContact => contactPerson ?? 'Sin contacto asignado';
  String get displayPhone => mobile ?? phone ?? 'Sin teléfono';
  String get displayEmail => email ?? 'Sin email';
  String get displayDocument => '${documentType.name.toUpperCase()}: $documentNumber';

  // Método copyWith
  Supplier copyWith({
    String? id,
    String? name,
    String? code,
    DocumentType? documentType,
    String? documentNumber,
    String? contactPerson,
    String? email,
    String? phone,
    String? mobile,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? website,
    SupplierStatus? status,
    String? currency,
    int? paymentTermsDays,
    double? creditLimit,
    double? discountPercentage,
    String? notes,
    Map<String, dynamic>? metadata,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      website: website ?? this.website,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      paymentTermsDays: paymentTermsDays ?? this.paymentTermsDays,
      creditLimit: creditLimit ?? this.creditLimit,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

// Entidad para estadísticas de proveedores
class SupplierStats extends Equatable {
  final int totalSuppliers;
  final int activeSuppliers;
  final int inactiveSuppliers;
  final double totalCreditLimit;
  final double averageCreditLimit;
  final double averagePaymentTerms;
  final int suppliersWithDiscount;
  final int suppliersWithCredit;
  final Map<String, int> currencyDistribution;
  final List<Map<String, dynamic>> topSuppliersByCredit;
  final double totalPurchasesAmount;
  final int totalPurchaseOrders;

  const SupplierStats({
    required this.totalSuppliers,
    required this.activeSuppliers,
    required this.inactiveSuppliers,
    required this.totalCreditLimit,
    required this.averageCreditLimit,
    required this.averagePaymentTerms,
    required this.suppliersWithDiscount,
    required this.suppliersWithCredit,
    required this.currencyDistribution,
    required this.topSuppliersByCredit,
    required this.totalPurchasesAmount,
    required this.totalPurchaseOrders,
  });

  @override
  List<Object> get props => [
        totalSuppliers,
        activeSuppliers,
        inactiveSuppliers,
        totalCreditLimit,
        averageCreditLimit,
        averagePaymentTerms,
        suppliersWithDiscount,
        suppliersWithCredit,
        currencyDistribution,
        topSuppliersByCredit,
        totalPurchasesAmount,
        totalPurchaseOrders,
      ];

  double get activePercentage => totalSuppliers > 0 ? (activeSuppliers / totalSuppliers) * 100 : 0;
  double get discountPercentage => totalSuppliers > 0 ? (suppliersWithDiscount / totalSuppliers) * 100 : 0;
  double get averagePurchasePerSupplier => activeSuppliers > 0 ? totalPurchasesAmount / activeSuppliers : 0;
}