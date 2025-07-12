// lib/features/customers/data/models/create_customer_request_model.dart
import '../../domain/entities/customer.dart';

class CreateCustomerRequestModel {
  final String firstName;
  final String lastName;
  final String? companyName;
  final String email;
  final String? phone;
  final String? mobile;
  final String documentType;
  final String documentNumber;
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

  const CreateCustomerRequestModel({
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
    this.status,
    this.creditLimit,
    this.paymentTerms,
    this.birthDate,
    this.notes,
    this.metadata,
  });

  factory CreateCustomerRequestModel.fromParams({
    required String firstName,
    required String lastName,
    String? companyName,
    required String email,
    String? phone,
    String? mobile,
    required DocumentType documentType,
    required String documentNumber,
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
    return CreateCustomerRequestModel(
      firstName: firstName,
      lastName: lastName,
      companyName: companyName,
      email: email,
      phone: phone,
      mobile: mobile,
      documentType: documentType.name,
      documentNumber: documentNumber,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      country: country ?? 'Colombia',
      status: status?.name ?? 'active',
      creditLimit: creditLimit ?? 0,
      paymentTerms: paymentTerms ?? 30,
      birthDate: birthDate?.toIso8601String(),
      notes: notes,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'documentType': documentType,
      'documentNumber': documentNumber,
    };

    // Agregar campos opcionales solo si no son null
    if (companyName?.isNotEmpty == true) data['companyName'] = companyName;
    if (phone?.isNotEmpty == true) data['phone'] = phone;
    if (mobile?.isNotEmpty == true) data['mobile'] = mobile;
    if (address?.isNotEmpty == true) data['address'] = address;
    if (city?.isNotEmpty == true) data['city'] = city;
    if (state?.isNotEmpty == true) data['state'] = state;
    if (zipCode?.isNotEmpty == true) data['zipCode'] = zipCode;
    if (country?.isNotEmpty == true) data['country'] = country;
    if (status?.isNotEmpty == true) data['status'] = status;
    if (creditLimit != null) data['creditLimit'] = creditLimit;
    if (paymentTerms != null) data['paymentTerms'] = paymentTerms;
    if (birthDate?.isNotEmpty == true) data['birthDate'] = birthDate;
    if (notes?.isNotEmpty == true) data['notes'] = notes;
    if (metadata?.isNotEmpty == true) data['metadata'] = metadata;

    return data;
  }
}
