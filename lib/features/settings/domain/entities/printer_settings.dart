// lib/features/settings/domain/entities/printer_settings.dart
import 'package:equatable/equatable.dart';

enum PrinterConnectionType { usb, network }

enum PaperSize { mm58, mm80 }

class PrinterSettings extends Equatable {
  final String id;
  final String name;
  final PrinterConnectionType connectionType;
  final String? ipAddress;
  final int? port;
  final String? usbPath;
  final PaperSize paperSize;
  final bool autoCut;
  final bool cashDrawer;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrinterSettings({
    required this.id,
    required this.name,
    required this.connectionType,
    this.ipAddress,
    this.port,
    this.usbPath,
    this.paperSize = PaperSize.mm80,
    this.autoCut = true,
    this.cashDrawer = false,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        connectionType,
        ipAddress,
        port,
        usbPath,
        paperSize,
        autoCut,
        cashDrawer,
        isDefault,
        isActive,
        createdAt,
        updatedAt,
      ];

  PrinterSettings copyWith({
    String? id,
    String? name,
    PrinterConnectionType? connectionType,
    String? ipAddress,
    int? port,
    String? usbPath,
    PaperSize? paperSize,
    bool? autoCut,
    bool? cashDrawer,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrinterSettings(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      usbPath: usbPath ?? this.usbPath,
      paperSize: paperSize ?? this.paperSize,
      autoCut: autoCut ?? this.autoCut,
      cashDrawer: cashDrawer ?? this.cashDrawer,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isNetworkPrinter => connectionType == PrinterConnectionType.network;
  bool get isUsbPrinter => connectionType == PrinterConnectionType.usb;

  String get connectionInfo {
    switch (connectionType) {
      case PrinterConnectionType.network:
        return '${ipAddress ?? 'N/A'}:${port ?? 9100}';
      case PrinterConnectionType.usb:
        return usbPath ?? 'USB';
    }
  }

  factory PrinterSettings.networkPrinter({
    required String id,
    required String name,
    required String ipAddress,
    int port = 9100,
    PaperSize paperSize = PaperSize.mm80,
    bool autoCut = true,
    bool cashDrawer = false,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return PrinterSettings(
      id: id,
      name: name,
      connectionType: PrinterConnectionType.network,
      ipAddress: ipAddress,
      port: port,
      paperSize: paperSize,
      autoCut: autoCut,
      cashDrawer: cashDrawer,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory PrinterSettings.usbPrinter({
    required String id,
    required String name,
    required String usbPath,
    PaperSize paperSize = PaperSize.mm80,
    bool autoCut = true,
    bool cashDrawer = false,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return PrinterSettings(
      id: id,
      name: name,
      connectionType: PrinterConnectionType.usb,
      usbPath: usbPath,
      paperSize: paperSize,
      autoCut: autoCut,
      cashDrawer: cashDrawer,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }
}