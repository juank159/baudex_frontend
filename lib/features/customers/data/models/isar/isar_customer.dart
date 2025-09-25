// lib/features/customers/data/models/isar/isar_customer.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:isar/isar.dart';

part 'isar_customer.g.dart';

@collection
class IsarCustomer {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  late String firstName;

  @Index()
  late String lastName;

  String? companyName;

  @Index(unique: true)
  late String email;

  String? phone;
  String? mobile;

  @Enumerated(EnumType.name)
  late IsarDocumentType documentType;

  @Index()
  late String documentNumber;

  // Dirección
  String? address;
  String? city;
  String? state;
  String? zipCode;
  String? country;

  @Enumerated(EnumType.name)
  late IsarCustomerStatus status;

  // Datos financieros
  late double creditLimit;
  late double currentBalance;
  late int paymentTerms;

  // Información personal
  DateTime? birthDate;
  String? notes;
  String? metadataJson;

  // Estadísticas
  DateTime? lastPurchaseAt;
  late double totalPurchases;
  late int totalOrders;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Constructores
  IsarCustomer();

  IsarCustomer.create({
    required this.serverId,
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
    this.metadataJson,
    this.lastPurchaseAt,
    required this.totalPurchases,
    required this.totalOrders,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
  });

  // Mappers
  static IsarCustomer fromEntity(Customer entity) {
    return IsarCustomer.create(
      serverId: entity.id,
      firstName: entity.firstName,
      lastName: entity.lastName,
      companyName: entity.companyName,
      email: entity.email,
      phone: entity.phone,
      mobile: entity.mobile,
      documentType: _mapDocumentType(entity.documentType),
      documentNumber: entity.documentNumber,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      zipCode: entity.zipCode,
      country: entity.country,
      status: _mapCustomerStatus(entity.status),
      creditLimit: entity.creditLimit,
      currentBalance: entity.currentBalance,
      paymentTerms: entity.paymentTerms,
      birthDate: entity.birthDate,
      notes: entity.notes,
      metadataJson:
          entity.metadata != null ? _encodeMetadata(entity.metadata!) : null,
      lastPurchaseAt: entity.lastPurchaseAt,
      totalPurchases: entity.totalPurchases,
      totalOrders: entity.totalOrders,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  Customer toEntity() {
    return Customer(
      id: serverId,
      firstName: firstName,
      lastName: lastName,
      companyName: companyName,
      email: email,
      phone: phone,
      mobile: mobile,
      documentType: _mapIsarDocumentType(documentType),
      documentNumber: documentNumber,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      country: country,
      status: _mapIsarCustomerStatus(status),
      creditLimit: creditLimit,
      currentBalance: currentBalance,
      paymentTerms: paymentTerms,
      birthDate: birthDate,
      notes: notes,
      metadata: metadataJson != null ? _decodeMetadata(metadataJson!) : null,
      lastPurchaseAt: lastPurchaseAt,
      totalPurchases: totalPurchases,
      totalOrders: totalOrders,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  // Helpers para mapeo de enums
  static IsarDocumentType _mapDocumentType(DocumentType type) {
    switch (type) {
      case DocumentType.cc:
        return IsarDocumentType.cc;
      case DocumentType.nit:
        return IsarDocumentType.nit;
      case DocumentType.ce:
        return IsarDocumentType.ce;
      case DocumentType.passport:
        return IsarDocumentType.passport;
      case DocumentType.other:
        return IsarDocumentType.other;
    }
  }

  static DocumentType _mapIsarDocumentType(IsarDocumentType type) {
    switch (type) {
      case IsarDocumentType.cc:
        return DocumentType.cc;
      case IsarDocumentType.nit:
        return DocumentType.nit;
      case IsarDocumentType.ce:
        return DocumentType.ce;
      case IsarDocumentType.passport:
        return DocumentType.passport;
      case IsarDocumentType.other:
        return DocumentType.other;
    }
  }

  static IsarCustomerStatus _mapCustomerStatus(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return IsarCustomerStatus.active;
      case CustomerStatus.inactive:
        return IsarCustomerStatus.inactive;
      case CustomerStatus.suspended:
        return IsarCustomerStatus.suspended;
    }
  }

  static CustomerStatus _mapIsarCustomerStatus(IsarCustomerStatus status) {
    switch (status) {
      case IsarCustomerStatus.active:
        return CustomerStatus.active;
      case IsarCustomerStatus.inactive:
        return CustomerStatus.inactive;
      case IsarCustomerStatus.suspended:
        return CustomerStatus.suspended;
    }
  }

  // Helpers para metadatos
  static String _encodeMetadata(Map<String, dynamic> metadata) {
    return metadata.toString();
  }

  static Map<String, dynamic> _decodeMetadata(String metadataJson) {
    return {};
  }

  // Métodos de utilidad
  bool get isDeleted => deletedAt != null;
  bool get isActive => status == IsarCustomerStatus.active && !isDeleted;
  bool get needsSync => !isSynced;
  bool get hasCredit => creditLimit > 0;
  bool get isOverCreditLimit => currentBalance > creditLimit;

  String get fullName => '$firstName $lastName'.trim();
  String get displayName =>
      companyName?.isNotEmpty == true ? companyName! : fullName;

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void softDelete() {
    deletedAt = DateTime.now();
    markAsUnsynced();
  }

  void updateBalance(double amount) {
    currentBalance += amount;
    markAsUnsynced();
  }

  void recordPurchase(double amount) {
    totalPurchases += amount;
    totalOrders += 1;
    lastPurchaseAt = DateTime.now();
    markAsUnsynced();
  }

  @override
  String toString() {
    return 'IsarCustomer{serverId: $serverId, name: $fullName, email: $email, isSynced: $isSynced}';
  }
}
