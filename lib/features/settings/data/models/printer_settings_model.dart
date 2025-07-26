// lib/features/settings/data/models/printer_settings_model.dart
import 'package:isar/isar.dart';
import '../../domain/entities/printer_settings.dart';

part 'printer_settings_model.g.dart';

@collection
class PrinterSettingsModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String settingsId;
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
  late DateTime createdAt;
  late DateTime updatedAt;

  PrinterSettingsModel();

  PrinterSettingsModel.fromEntity(PrinterSettings entity) {
    settingsId = entity.id;
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
    createdAt = entity.createdAt;
    updatedAt = entity.updatedAt;
  }

  PrinterSettings toEntity() {
    return PrinterSettings(
      id: settingsId,
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

  void updateFromEntity(PrinterSettings entity) {
    settingsId = entity.id;
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
}