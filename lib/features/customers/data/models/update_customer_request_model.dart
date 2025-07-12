import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';

class UpdateCustomerRequestModel {
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? documentType;
  final String? documentNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? status;
  final double? creditLimit;
  final int? paymentTerms;
  final String? birthDate;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const UpdateCustomerRequestModel({
    this.firstName,
    this.lastName,
    this.companyName,
    this.email,
    this.phone,
    this.mobile,
    this.documentType,
    this.documentNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.status,
    this.creditLimit,
    this.paymentTerms,
    this.birthDate,
    this.notes,
    this.metadata,
  });

  factory UpdateCustomerRequestModel.fromParams({
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
    int? paymentTerms,
    DateTime? birthDate,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return UpdateCustomerRequestModel(
      firstName: firstName,
      lastName: lastName,
      companyName: companyName,
      email: email,
      phone: phone,
      mobile: mobile,
      documentType: documentType?.name,
      documentNumber: documentNumber,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      country: country,
      status: status?.name,
      creditLimit: creditLimit,
      paymentTerms: paymentTerms,
      birthDate: birthDate?.toIso8601String(),
      notes: notes,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // Solo agregar campos que no son null
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (companyName != null) data['companyName'] = companyName;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (mobile != null) data['mobile'] = mobile;
    if (documentType != null) data['documentType'] = documentType;
    if (documentNumber != null) data['documentNumber'] = documentNumber;
    if (address != null) data['address'] = address;
    if (city != null) data['city'] = city;
    if (state != null) data['state'] = state;
    if (zipCode != null) data['zipCode'] = zipCode;
    if (country != null) data['country'] = country;
    if (status != null) data['status'] = status;
    if (creditLimit != null) data['creditLimit'] = creditLimit;
    if (paymentTerms != null) data['paymentTerms'] = paymentTerms;
    if (birthDate != null) data['birthDate'] = birthDate;
    if (notes != null) data['notes'] = notes;
    if (metadata != null) data['metadata'] = metadata;

    return data;
  }

  /// Verificar si hay campos para actualizar
  bool get hasUpdates => toJson().isNotEmpty;
}
