// lib/features/settings/data/models/isar/isar_user_preferences.dart
import 'dart:convert';

import 'package:isar/isar.dart';
import '../../../domain/entities/user_preferences.dart';

part 'isar_user_preferences.g.dart';

@collection
class IsarUserPreferences {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  late String userId;

  @Index()
  late String organizationId;

  // Preferencias de inventario
  late bool autoDeductInventory;
  late bool useFifoCosting;
  late bool validateStockBeforeInvoice;
  late bool allowOverselling;
  late bool showStockWarnings;

  // Preferencias de UI
  late bool showConfirmationDialogs;
  late bool useCompactMode;

  // Preferencias de notificaciones
  late bool enableExpiryNotifications;
  late bool enableLowStockNotifications;

  // Configuraciones adicionales
  String? defaultWarehouseId;
  String? additionalSettingsJson;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Campos de versionamiento
  late int version;
  DateTime? lastModifiedAt;
  String? lastModifiedBy;

  // Constructor vacío requerido por ISAR
  IsarUserPreferences();

  // Constructor con nombre
  IsarUserPreferences.create({
    required this.serverId,
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
    this.additionalSettingsJson,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
    this.lastSyncAt,
    this.version = 0,
    this.lastModifiedAt,
    this.lastModifiedBy,
  });

  // ==================== MAPPERS ====================

  static IsarUserPreferences fromEntity(UserPreferences entity) {
    return IsarUserPreferences.create(
      serverId: entity.id,
      userId: entity.userId,
      organizationId: entity.organizationId,
      autoDeductInventory: entity.autoDeductInventory,
      useFifoCosting: entity.useFifoCosting,
      validateStockBeforeInvoice: entity.validateStockBeforeInvoice,
      allowOverselling: entity.allowOverselling,
      showStockWarnings: entity.showStockWarnings,
      showConfirmationDialogs: entity.showConfirmationDialogs,
      useCompactMode: entity.useCompactMode,
      enableExpiryNotifications: entity.enableExpiryNotifications,
      enableLowStockNotifications: entity.enableLowStockNotifications,
      defaultWarehouseId: entity.defaultWarehouseId,
      additionalSettingsJson: _encodeAdditionalSettings(entity.additionalSettings),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  UserPreferences toEntity() {
    return UserPreferences(
      id: serverId,
      userId: userId,
      organizationId: organizationId,
      autoDeductInventory: autoDeductInventory,
      useFifoCosting: useFifoCosting,
      validateStockBeforeInvoice: validateStockBeforeInvoice,
      allowOverselling: allowOverselling,
      showStockWarnings: showStockWarnings,
      showConfirmationDialogs: showConfirmationDialogs,
      useCompactMode: useCompactMode,
      enableExpiryNotifications: enableExpiryNotifications,
      enableLowStockNotifications: enableLowStockNotifications,
      defaultWarehouseId: defaultWarehouseId,
      additionalSettings: _decodeAdditionalSettings(additionalSettingsJson),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Actualizar desde entidad
  void updateFromEntity(UserPreferences entity) {
    userId = entity.userId;
    organizationId = entity.organizationId;
    autoDeductInventory = entity.autoDeductInventory;
    useFifoCosting = entity.useFifoCosting;
    validateStockBeforeInvoice = entity.validateStockBeforeInvoice;
    allowOverselling = entity.allowOverselling;
    showStockWarnings = entity.showStockWarnings;
    showConfirmationDialogs = entity.showConfirmationDialogs;
    useCompactMode = entity.useCompactMode;
    enableExpiryNotifications = entity.enableExpiryNotifications;
    enableLowStockNotifications = entity.enableLowStockNotifications;
    defaultWarehouseId = entity.defaultWarehouseId;
    additionalSettingsJson = _encodeAdditionalSettings(entity.additionalSettings);
    updatedAt = entity.updatedAt;
    markAsSynced();
  }

  /// Aplicar actualizaciones parciales
  void applyUpdates(Map<String, dynamic> updates) {
    if (updates.containsKey('autoDeductInventory')) {
      autoDeductInventory = updates['autoDeductInventory'] as bool;
    }
    if (updates.containsKey('useFifoCosting')) {
      useFifoCosting = updates['useFifoCosting'] as bool;
    }
    if (updates.containsKey('validateStockBeforeInvoice')) {
      validateStockBeforeInvoice = updates['validateStockBeforeInvoice'] as bool;
    }
    if (updates.containsKey('allowOverselling')) {
      allowOverselling = updates['allowOverselling'] as bool;
    }
    if (updates.containsKey('showStockWarnings')) {
      showStockWarnings = updates['showStockWarnings'] as bool;
    }
    if (updates.containsKey('showConfirmationDialogs')) {
      showConfirmationDialogs = updates['showConfirmationDialogs'] as bool;
    }
    if (updates.containsKey('useCompactMode')) {
      useCompactMode = updates['useCompactMode'] as bool;
    }
    if (updates.containsKey('enableExpiryNotifications')) {
      enableExpiryNotifications = updates['enableExpiryNotifications'] as bool;
    }
    if (updates.containsKey('enableLowStockNotifications')) {
      enableLowStockNotifications = updates['enableLowStockNotifications'] as bool;
    }
    if (updates.containsKey('defaultWarehouseId')) {
      defaultWarehouseId = updates['defaultWarehouseId'] as String?;
    }
    if (updates.containsKey('additionalSettings')) {
      additionalSettingsJson = _encodeAdditionalSettings(
        updates['additionalSettings'] as Map<String, dynamic>?,
      );
    }
    incrementVersion(modifiedBy: 'offline');
  }

  // ==================== SERIALIZATION ====================

  static String _encodeAdditionalSettings(Map<String, dynamic>? settings) {
    if (settings == null || settings.isEmpty) return '{}';
    try {
      return jsonEncode(settings);
    } catch (e) {
      return '{}';
    }
  }

  static Map<String, dynamic>? _decodeAdditionalSettings(String? settingsJson) {
    if (settingsJson == null || settingsJson.isEmpty || settingsJson == '{}') {
      return null;
    }
    try {
      final decoded = jsonDecode(settingsJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== UTILITY METHODS ====================

  bool get needsSync => !isSynced;

  @ignore
  Map<String, dynamic>? get additionalSettingsMap =>
      _decodeAdditionalSettings(additionalSettingsJson);

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void incrementVersion({String? modifiedBy}) {
    version++;
    lastModifiedAt = DateTime.now();
    if (modifiedBy != null) {
      lastModifiedBy = modifiedBy;
    }
    isSynced = false;
    updatedAt = DateTime.now();
  }

  bool hasConflictWith(IsarUserPreferences serverVersion) {
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
    return 'IsarUserPreferences{serverId: $serverId, userId: $userId, version: $version, isSynced: $isSynced}';
  }
}
