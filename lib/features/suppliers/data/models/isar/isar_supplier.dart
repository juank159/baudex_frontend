// lib/features/suppliers/data/models/isar/isar_supplier.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/suppliers/domain/entities/supplier.dart';
import 'package:isar/isar.dart';
import 'dart:convert';

part 'isar_supplier.g.dart';

@collection
class IsarSupplier {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  late String name;

  @Index()
  String? code;

  @Enumerated(EnumType.name)
  late IsarDocumentType documentType;

  @Index()
  late String documentNumber;

  String? contactPerson;
  String? email;
  String? phone;
  String? mobile;
  String? address;
  String? city;
  String? state;
  String? country;
  String? postalCode;
  String? website;

  @Enumerated(EnumType.name)
  late IsarSupplierStatus status;

  late String currency;
  late int paymentTermsDays;
  late double creditLimit;
  late double discountPercentage;

  String? notes;
  String? metadataJson;

  // Foreign Keys
  @Index()
  late String organizationId;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // ⭐ FASE 1: Campos de versionamiento para detección de conflictos
  late int version;
  DateTime? lastModifiedAt;
  String? lastModifiedBy;

  // Constructores
  IsarSupplier();

  IsarSupplier.create({
    required this.serverId,
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
    this.metadataJson,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
    this.version = 0,
    this.lastModifiedAt,
    this.lastModifiedBy,
  });

  // Mappers
  static IsarSupplier fromEntity(Supplier entity) {
    return IsarSupplier.create(
      serverId: entity.id,
      name: entity.name,
      code: entity.code,
      documentType: _mapDocumentType(entity.documentType),
      documentNumber: entity.documentNumber,
      contactPerson: entity.contactPerson,
      email: entity.email,
      phone: entity.phone,
      mobile: entity.mobile,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      country: entity.country,
      postalCode: entity.postalCode,
      website: entity.website,
      status: _mapSupplierStatus(entity.status),
      currency: entity.currency,
      paymentTermsDays: entity.paymentTermsDays,
      creditLimit: entity.creditLimit,
      discountPercentage: entity.discountPercentage,
      notes: entity.notes,
      metadataJson: entity.metadata != null ? _encodeMetadata(entity.metadata!) : null,
      organizationId: entity.organizationId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  static IsarSupplier fromModel(dynamic model) {
    return IsarSupplier.create(
      serverId: model.id,
      name: model.name,
      code: model.code,
      documentType: _mapDocumentType(model.documentType),
      documentNumber: model.documentNumber,
      contactPerson: model.contactPerson,
      email: model.email,
      phone: model.phone,
      mobile: model.mobile,
      address: model.address,
      city: model.city,
      state: model.state,
      country: model.country,
      postalCode: model.postalCode,
      website: model.website,
      status: _mapSupplierStatus(model.status),
      currency: model.currency,
      paymentTermsDays: model.paymentTermsDays,
      creditLimit: model.creditLimit,
      discountPercentage: model.discountPercentage,
      notes: model.notes,
      metadataJson: model.metadata != null ? _encodeMetadata(model.metadata) : null,
      organizationId: model.organizationId,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  void updateFromModel(dynamic model) {
    serverId = model.id;
    name = model.name;
    code = model.code;
    documentType = _mapDocumentType(model.documentType);
    documentNumber = model.documentNumber;
    contactPerson = model.contactPerson;
    email = model.email;
    phone = model.phone;
    mobile = model.mobile;
    address = model.address;
    city = model.city;
    state = model.state;
    country = model.country;
    postalCode = model.postalCode;
    website = model.website;
    status = _mapSupplierStatus(model.status);
    currency = model.currency;
    paymentTermsDays = model.paymentTermsDays;
    creditLimit = model.creditLimit;
    discountPercentage = model.discountPercentage;
    notes = model.notes;
    metadataJson = model.metadata != null ? _encodeMetadata(model.metadata) : null;
    organizationId = model.organizationId;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    deletedAt = model.deletedAt;
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  Supplier toEntity() {
    return Supplier(
      id: serverId,
      name: name,
      code: code,
      documentType: _mapIsarDocumentType(documentType),
      documentNumber: documentNumber,
      contactPerson: contactPerson,
      email: email,
      phone: phone,
      mobile: mobile,
      address: address,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      website: website,
      status: _mapIsarSupplierStatus(status),
      currency: currency,
      paymentTermsDays: paymentTermsDays,
      creditLimit: creditLimit,
      discountPercentage: discountPercentage,
      notes: notes,
      metadata: metadataJson != null ? _decodeMetadata(metadataJson!) : null,
      organizationId: organizationId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  // Helpers para mapeo de enums
  static IsarDocumentType _mapDocumentType(DocumentType type) {
    switch (type) {
      case DocumentType.nit:
        return IsarDocumentType.nit;
      case DocumentType.cc:
        return IsarDocumentType.cc;
      case DocumentType.ce:
        return IsarDocumentType.ce;
      case DocumentType.passport:
        return IsarDocumentType.passport;
      case DocumentType.rut:
        return IsarDocumentType.other; // RUT no existe en IsarDocumentType
      case DocumentType.other:
        return IsarDocumentType.other;
    }
  }

  static DocumentType _mapIsarDocumentType(IsarDocumentType type) {
    switch (type) {
      case IsarDocumentType.nit:
        return DocumentType.nit;
      case IsarDocumentType.cc:
        return DocumentType.cc;
      case IsarDocumentType.ce:
        return DocumentType.ce;
      case IsarDocumentType.passport:
        return DocumentType.passport;
      case IsarDocumentType.other:
        return DocumentType.other;
    }
  }

  static IsarSupplierStatus _mapSupplierStatus(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return IsarSupplierStatus.active;
      case SupplierStatus.inactive:
        return IsarSupplierStatus.inactive;
      case SupplierStatus.blocked:
        return IsarSupplierStatus.blocked;
    }
  }

  static SupplierStatus _mapIsarSupplierStatus(IsarSupplierStatus status) {
    switch (status) {
      case IsarSupplierStatus.active:
        return SupplierStatus.active;
      case IsarSupplierStatus.inactive:
        return SupplierStatus.inactive;
      case IsarSupplierStatus.blocked:
        return SupplierStatus.blocked;
    }
  }

  // Helpers para metadatos
  static String _encodeMetadata(Map<String, dynamic> metadata) {
    try {
      return json.encode(metadata);
    } catch (e) {
      return '{}';
    }
  }

  static Map<String, dynamic> _decodeMetadata(String metadataJson) {
    try {
      return json.decode(metadataJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Métodos de utilidad
  bool get isDeleted => deletedAt != null;
  bool get isActive => status == IsarSupplierStatus.active && !isDeleted;
  bool get isBlocked => status == IsarSupplierStatus.blocked;
  bool get needsSync => !isSynced;

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


  // ⭐ FASE 1: Métodos de versionamiento y detección de conflictos
  void incrementVersion({String? modifiedBy}) {
    version++;
    lastModifiedAt = DateTime.now();
    if (modifiedBy != null) {
      lastModifiedBy = modifiedBy;
    }
    isSynced = false;
  }

  bool hasConflictWith(IsarSupplier serverVersion) {
    if (version == serverVersion.version &&
        lastModifiedAt != null &&
        serverVersion.lastModifiedAt != null &&
        lastModifiedAt != serverVersion.lastModifiedAt) {
      return true;
    }
    if (version > serverVersion.version) {
      return true;
    }
    return false;
  }
  @override
  String toString() {
    return 'IsarSupplier{serverId: $serverId, name: $name, status: $status, version: $version, isSynced: $isSynced}';
  }
}
