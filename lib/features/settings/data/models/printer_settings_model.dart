// lib/features/settings/data/models/printer_settings_model.dart
import 'package:isar/isar.dart';
import '../../domain/entities/printer_settings.dart';

part 'printer_settings_model.g.dart';

@collection
class PrinterSettingsModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  late String name;

  @Enumerated(EnumType.name)
  late PrinterConnectionType connectionType;

  String? ipAddress;
  int? port;
  String? usbPath;

  @Enumerated(EnumType.name)
  late PaperSize paperSize;

  late bool autoCut;
  late bool cashDrawer;

  @Index()
  late bool isDefault;

  @Index()
  late bool isActive;

  // Foreign Keys
  @Index()
  late String organizationId;

  // Auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Versionamiento
  late int version;
  DateTime? lastModifiedAt;
  String? lastModifiedBy;

  PrinterSettingsModel();

  PrinterSettingsModel.create({
    required this.serverId,
    required this.name,
    required this.connectionType,
    this.ipAddress,
    this.port,
    this.usbPath,
    required this.paperSize,
    required this.autoCut,
    required this.cashDrawer,
    required this.isDefault,
    required this.isActive,
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

  /// Crear desde entidad (para guardar localmente)
  static PrinterSettingsModel fromEntity(PrinterSettings entity, {String organizationId = ''}) {
    return PrinterSettingsModel.create(
      serverId: entity.id,
      name: entity.name,
      connectionType: entity.connectionType,
      ipAddress: entity.ipAddress,
      port: entity.port,
      usbPath: entity.usbPath,
      paperSize: entity.paperSize,
      autoCut: entity.autoCut,
      cashDrawer: entity.cashDrawer,
      isDefault: entity.isDefault,
      isActive: entity.isActive,
      organizationId: organizationId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Crear desde JSON del servidor (para full sync)
  static PrinterSettingsModel fromServerJson(Map<String, dynamic> json) {
    return PrinterSettingsModel.create(
      serverId: json['id'] ?? '',
      name: json['name'] ?? '',
      connectionType: _parseConnectionType(json['connectionType'] ?? json['connection_type']),
      ipAddress: json['ipAddress'] ?? json['ip_address'],
      port: json['port'],
      usbPath: json['usbPath'] ?? json['usb_path'],
      paperSize: _parsePaperSize(json['paperSize'] ?? json['paper_size']),
      autoCut: json['autoCut'] ?? json['auto_cut'] ?? true,
      cashDrawer: json['cashDrawer'] ?? json['cash_drawer'] ?? false,
      isDefault: json['isDefault'] ?? json['is_default'] ?? false,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      organizationId: json['organizationId'] ?? json['organization_id'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now()),
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  /// Convertir a entidad
  PrinterSettings toEntity() {
    return PrinterSettings(
      id: serverId,
      name: name,
      connectionType: connectionType,
      ipAddress: ipAddress,
      port: port,
      usbPath: usbPath,
      paperSize: paperSize,
      autoCut: autoCut,
      cashDrawer: cashDrawer,
      isDefault: isDefault,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convertir a JSON para enviar al servidor
  Map<String, dynamic> toServerJson() {
    return {
      'name': name,
      'connectionType': connectionType.name,
      'ipAddress': ipAddress,
      'port': port,
      'usbPath': usbPath,
      'paperSize': paperSize.name,
      'autoCut': autoCut,
      'cashDrawer': cashDrawer,
      'isDefault': isDefault,
      'isActive': isActive,
    };
  }

  /// Actualizar desde entidad (mantiene id ISAR)
  void updateFromEntity(PrinterSettings entity) {
    serverId = entity.id;
    name = entity.name;
    connectionType = entity.connectionType;
    ipAddress = entity.ipAddress;
    port = entity.port;
    usbPath = entity.usbPath;
    paperSize = entity.paperSize;
    autoCut = entity.autoCut;
    cashDrawer = entity.cashDrawer;
    isDefault = entity.isDefault;
    isActive = entity.isActive;
    updatedAt = DateTime.now();
  }

  // Métodos de sincronización
  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void incrementVersion({String? modifiedBy}) {
    version++;
    lastModifiedAt = DateTime.now();
    if (modifiedBy != null) {
      lastModifiedBy = modifiedBy;
    }
    isSynced = false;
  }

  void softDelete() {
    deletedAt = DateTime.now();
    markAsUnsynced();
  }

  bool get isDeleted => deletedAt != null;
  bool get needsSync => !isSynced;

  // Helpers estáticos
  static PrinterConnectionType _parseConnectionType(String? value) {
    switch (value) {
      case 'usb':
        return PrinterConnectionType.usb;
      default:
        return PrinterConnectionType.network;
    }
  }

  static PaperSize _parsePaperSize(String? value) {
    switch (value) {
      case 'mm58':
        return PaperSize.mm58;
      default:
        return PaperSize.mm80;
    }
  }

  @override
  String toString() {
    return 'PrinterSettingsModel{serverId: $serverId, name: $name, type: $connectionType, isSynced: $isSynced}';
  }
}
