import '../../domain/entities/user_preferences.dart';

class UserPreferencesModel extends UserPreferences {
  const UserPreferencesModel({
    required super.id,
    required super.userId,
    required super.organizationId,
    required super.autoDeductInventory,
    required super.useFifoCosting,
    required super.validateStockBeforeInvoice,
    required super.allowOverselling,
    required super.showStockWarnings,
    required super.showConfirmationDialogs,
    required super.useCompactMode,
    required super.enableExpiryNotifications,
    required super.enableLowStockNotifications,
    super.defaultWarehouseId,
    super.additionalSettings,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      id: json['id'],
      userId: json['userId'],
      organizationId: json['organizationId'],
      autoDeductInventory: json['autoDeductInventory'] ?? true,
      useFifoCosting: json['useFifoCosting'] ?? true,
      validateStockBeforeInvoice: json['validateStockBeforeInvoice'] ?? true,
      allowOverselling: json['allowOverselling'] ?? false,
      showStockWarnings: json['showStockWarnings'] ?? true,
      showConfirmationDialogs: json['showConfirmationDialogs'] ?? true,
      useCompactMode: json['useCompactMode'] ?? false,
      enableExpiryNotifications: json['enableExpiryNotifications'] ?? true,
      enableLowStockNotifications: json['enableLowStockNotifications'] ?? true,
      defaultWarehouseId: json['defaultWarehouseId'],
      additionalSettings: json['additionalSettings'] != null
          ? Map<String, dynamic>.from(json['additionalSettings'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'organizationId': organizationId,
      'autoDeductInventory': autoDeductInventory,
      'useFifoCosting': useFifoCosting,
      'validateStockBeforeInvoice': validateStockBeforeInvoice,
      'allowOverselling': allowOverselling,
      'showStockWarnings': showStockWarnings,
      'showConfirmationDialogs': showConfirmationDialogs,
      'useCompactMode': useCompactMode,
      'enableExpiryNotifications': enableExpiryNotifications,
      'enableLowStockNotifications': enableLowStockNotifications,
      'defaultWarehouseId': defaultWarehouseId,
      'additionalSettings': additionalSettings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> toUpdateJson(Map<String, dynamic> preferences) {
    // Solo incluir campos que pueden ser actualizados
    final updateMap = <String, dynamic>{};
    
    preferences.forEach((key, value) {
      if (_isUpdatableField(key) && value != null) {
        updateMap[key] = value;
      }
    });
    
    return updateMap;
  }

  static bool _isUpdatableField(String key) {
    const updatableFields = {
      'autoDeductInventory',
      'useFifoCosting',
      'validateStockBeforeInvoice',
      'allowOverselling',
      'showStockWarnings',
      'showConfirmationDialogs',
      'useCompactMode',
      'enableExpiryNotifications',
      'enableLowStockNotifications',
      'defaultWarehouseId',
      'additionalSettings',
    };
    
    return updatableFields.contains(key);
  }
}