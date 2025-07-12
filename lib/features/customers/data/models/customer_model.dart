// lib/features/customers/data/models/customer_model.dart
import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.companyName,
    required super.email,
    super.phone,
    super.mobile,
    required super.documentType,
    required super.documentNumber,
    super.address,
    super.city,
    super.state,
    super.zipCode,
    super.country,
    required super.status,
    required super.creditLimit,
    required super.currentBalance,
    required super.paymentTerms,
    super.birthDate,
    super.notes,
    super.metadata,
    super.lastPurchaseAt,
    required super.totalPurchases,
    required super.totalOrders,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      companyName: json['companyName'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      mobile: json['mobile'] as String?,
      documentType: _parseDocumentType(json['documentType']),
      documentNumber: json['documentNumber'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      country: json['country'] as String?,
      status: _parseStatus(json['status']),

      // ✅ FIX: Manejar conversión de String a double correctamente
      creditLimit: _parseDouble(json['creditLimit']) ?? 0.0,
      currentBalance: _parseDouble(json['currentBalance']) ?? 0.0,
      totalPurchases: _parseDouble(json['totalPurchases']) ?? 0.0,

      paymentTerms: (json['paymentTerms'] as num?)?.toInt() ?? 30,
      birthDate:
          json['birthDate'] != null
              ? DateTime.parse(json['birthDate'] as String)
              : null,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      lastPurchaseAt:
          json['lastPurchaseAt'] != null
              ? DateTime.parse(json['lastPurchaseAt'] as String)
              : null,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt:
          json['deletedAt'] != null
              ? DateTime.parse(json['deletedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'companyName': companyName,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'documentType': documentType.name,
      'documentNumber': documentNumber,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'status': status.name,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'paymentTerms': paymentTerms,
      'birthDate': birthDate?.toIso8601String(),
      'notes': notes,
      'metadata': metadata,
      'lastPurchaseAt': lastPurchaseAt?.toIso8601String(),
      'totalPurchases': totalPurchases,
      'totalOrders': totalOrders,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  static DocumentType _parseDocumentType(dynamic type) {
    if (type is String) {
      switch (type.toLowerCase()) {
        case 'cc':
          return DocumentType.cc;
        case 'nit':
          return DocumentType.nit;
        case 'ce':
          return DocumentType.ce;
        case 'passport':
          return DocumentType.passport;
        case 'other':
          return DocumentType.other;
        default:
          return DocumentType.cc;
      }
    }
    return DocumentType.cc;
  }

  static CustomerStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'active':
          return CustomerStatus.active;
        case 'inactive':
          return CustomerStatus.inactive;
        case 'suspended':
          return CustomerStatus.suspended;
        default:
          return CustomerStatus.active;
      }
    }
    return CustomerStatus.active;
  }

  Customer toEntity() => Customer(
    id: id,
    firstName: firstName,
    lastName: lastName,
    companyName: companyName,
    email: email,
    phone: phone,
    mobile: mobile,
    documentType: documentType,
    documentNumber: documentNumber,
    address: address,
    city: city,
    state: state,
    zipCode: zipCode,
    country: country,
    status: status,
    creditLimit: creditLimit,
    currentBalance: currentBalance,
    paymentTerms: paymentTerms,
    birthDate: birthDate,
    notes: notes,
    metadata: metadata,
    lastPurchaseAt: lastPurchaseAt,
    totalPurchases: totalPurchases,
    totalOrders: totalOrders,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );

  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      firstName: customer.firstName,
      lastName: customer.lastName,
      companyName: customer.companyName,
      email: customer.email,
      phone: customer.phone,
      mobile: customer.mobile,
      documentType: customer.documentType,
      documentNumber: customer.documentNumber,
      address: customer.address,
      city: customer.city,
      state: customer.state,
      zipCode: customer.zipCode,
      country: customer.country,
      status: customer.status,
      creditLimit: customer.creditLimit,
      currentBalance: customer.currentBalance,
      paymentTerms: customer.paymentTerms,
      birthDate: customer.birthDate,
      notes: customer.notes,
      metadata: customer.metadata,
      lastPurchaseAt: customer.lastPurchaseAt,
      totalPurchases: customer.totalPurchases,
      totalOrders: customer.totalOrders,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
      deletedAt: customer.deletedAt,
    );
  }
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('⚠️ Error parsing double from string: "$value" - $e');
        return null;
      }
    }

    print(
      '⚠️ Unexpected type for numeric value: ${value.runtimeType} - $value',
    );
    return null;
  }
}
