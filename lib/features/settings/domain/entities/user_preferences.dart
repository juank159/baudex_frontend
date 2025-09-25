import 'package:equatable/equatable.dart';

class UserPreferences extends Equatable {
  final String id;
  final String userId;
  final String organizationId;
  final bool autoDeductInventory;
  final bool useFifoCosting;
  final bool validateStockBeforeInvoice;
  final bool allowOverselling;
  final bool showStockWarnings;
  final bool showConfirmationDialogs;
  final bool useCompactMode;
  final bool enableExpiryNotifications;
  final bool enableLowStockNotifications;
  final String? defaultWarehouseId;
  final Map<String, dynamic>? additionalSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPreferences({
    required this.id,
    required this.userId,
    required this.organizationId,
    required this.autoDeductInventory,
    required this.useFifoCosting,
    required this.validateStockBeforeInvoice,
    required this.allowOverselling,
    required this.showStockWarnings,
    required this.showConfirmationDialogs,
    required this.useCompactMode,
    required this.enableExpiryNotifications,
    required this.enableLowStockNotifications,
    this.defaultWarehouseId,
    this.additionalSettings,
    required this.createdAt,
    required this.updatedAt,
  });

  UserPreferences copyWith({
    String? id,
    String? userId,
    String? organizationId,
    bool? autoDeductInventory,
    bool? useFifoCosting,
    bool? validateStockBeforeInvoice,
    bool? allowOverselling,
    bool? showStockWarnings,
    bool? showConfirmationDialogs,
    bool? useCompactMode,
    bool? enableExpiryNotifications,
    bool? enableLowStockNotifications,
    String? defaultWarehouseId,
    Map<String, dynamic>? additionalSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      autoDeductInventory: autoDeductInventory ?? this.autoDeductInventory,
      useFifoCosting: useFifoCosting ?? this.useFifoCosting,
      validateStockBeforeInvoice: validateStockBeforeInvoice ?? this.validateStockBeforeInvoice,
      allowOverselling: allowOverselling ?? this.allowOverselling,
      showStockWarnings: showStockWarnings ?? this.showStockWarnings,
      showConfirmationDialogs: showConfirmationDialogs ?? this.showConfirmationDialogs,
      useCompactMode: useCompactMode ?? this.useCompactMode,
      enableExpiryNotifications: enableExpiryNotifications ?? this.enableExpiryNotifications,
      enableLowStockNotifications: enableLowStockNotifications ?? this.enableLowStockNotifications,
      defaultWarehouseId: defaultWarehouseId ?? this.defaultWarehouseId,
      additionalSettings: additionalSettings ?? this.additionalSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        organizationId,
        autoDeductInventory,
        useFifoCosting,
        validateStockBeforeInvoice,
        allowOverselling,
        showStockWarnings,
        showConfirmationDialogs,
        useCompactMode,
        enableExpiryNotifications,
        enableLowStockNotifications,
        defaultWarehouseId,
        additionalSettings,
        createdAt,
        updatedAt,
      ];

  @override
  bool get stringify => true;
}