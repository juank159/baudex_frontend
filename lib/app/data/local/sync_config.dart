// lib/app/data/local/sync_config.dart

/// Configuración centralizada del sistema de sincronización
///
/// Este archivo contiene todas las constantes y configuraciones
/// utilizadas por el sistema de sincronización offline-first.
class SyncConfig {
  SyncConfig._();

  // ==================== REINTENTOS ====================

  /// Número máximo de reintentos antes de marcar una operación como
  /// permanentemente fallida. Después de este límite, la operación
  /// será eliminada de la cola y notificada al usuario.
  static const int maxRetries = 10;

  /// Delay base para exponential backoff (en segundos)
  /// Fórmula: min(2^retryCount, maxBackoffSeconds)
  static const int baseBackoffSeconds = 1;

  /// Delay máximo de backoff (5 minutos)
  static const int maxBackoffSeconds = 300;

  // ==================== TIMERS ====================

  /// Intervalo de verificación de sincronización periódica (10 segundos)
  static const Duration periodicSyncInterval = Duration(seconds: 10);

  /// Intervalo mínimo entre sincronizaciones completas (2 minutos)
  static const Duration minSyncInterval = Duration(minutes: 2);

  /// Timeout para operaciones de red individuales (15 segundos)
  static const Duration networkTimeout = Duration(seconds: 15);

  // ==================== LIMPIEZA ====================

  /// Días después de los cuales una operación completada puede ser eliminada
  static const int completedOperationRetentionDays = 7;

  /// Número máximo de operaciones completadas a mantener
  static const int maxCompletedOperationsToKeep = 1000;

  // ==================== PRIORIDADES DE ENTIDADES ====================
  /// Las entidades se sincronizan en este orden para mantener
  /// integridad referencial (dependencias primero)

  static const Map<String, int> entityPriorities = {
    // Prioridad 1: Entidades sin dependencias
    'Organization': 1,
    'organization': 1,
    'organization_profit_margin': 1,
    'User': 1,
    'user': 1,
    'user_profile': 1,

    // Prioridad 2: Entidades base
    'Category': 2,
    'category': 2,
    'BankAccount': 2,
    'bank_account': 2,
    'BankAccountMovement': 5,
    'bank_account_movement': 5,
    'BankAccountTransfer': 5,
    'bank_account_transfer': 5,
    'PrinterSettings': 2,
    'printer_settings': 2,
    'ExpenseCategory': 2,
    'expense_category': 2,

    // Prioridad 3: Entidades con dependencias simples
    'Product': 3,
    'product': 3,
    'ProductPresentation': 3,
    'product_presentation': 3,
    'Customer': 3,
    'customer': 3,
    'Supplier': 3,
    'supplier': 3,

    // Prioridad 4: Entidades transaccionales
    'Invoice': 4,
    'invoice': 4,
    'Expense': 4,
    'expense': 4,
    'PurchaseOrder': 4,
    'purchase_order': 4,
    'CreditNote': 4,
    'credit_note': 4,

    // Prioridad 5: Entidades derivadas
    'Payment': 5,
    'payment': 5,
    'InventoryMovement': 5,
    'inventory_movement': 5,
    'inventory_movement_fifo': 5,
    'CustomerCredit': 5,
    'customer_credit': 5,
    'ProductWaste': 5,
    'product_waste': 5,

    // Prioridad 6: Entidades auxiliares
    'Notification': 6,
    'notification': 6,
    'UserPreferences': 6,
    'user_preferences': 6,
  };

  /// Obtiene la prioridad de una entidad (menor número = mayor prioridad)
  static int getEntityPriority(String entityType) {
    return entityPriorities[entityType] ?? 99;
  }

  // ==================== TIPOS DE NOTIFICACIONES DINÁMICAS ====================
  /// Prefijos de IDs de notificaciones que son generadas dinámicamente
  /// y no deben sincronizarse

  static const List<String> dynamicNotificationPrefixes = [
    'stock_',
    'invoice_',
    'payment_',
    'expense_',
    'customer_',
    'product_',
    'welcome_',
    'reminder_',
  ];

  /// Verifica si un entityId corresponde a una notificación dinámica
  static bool isDynamicNotificationId(String? entityId) {
    if (entityId == null) return false;
    return dynamicNotificationPrefixes.any((prefix) => entityId.startsWith(prefix));
  }

  // ==================== VALIDACIONES ====================

  /// Longitud mínima de un entityId válido
  static const int minEntityIdLength = 1;

  /// Longitud máxima de un entityId válido
  static const int maxEntityIdLength = 255;

  /// Longitud máxima del payload JSON (10MB)
  static const int maxPayloadSizeBytes = 10 * 1024 * 1024;

  /// Tipos de entidad soportados
  static const Set<String> supportedEntityTypes = {
    'Product',
    'product',
    'ProductPresentation',
    'product_presentation',
    'ProductWaste',
    'product_waste',
    'Category',
    'category',
    'Customer',
    'customer',
    'Supplier',
    'supplier',
    'Invoice',
    'invoice',
    'Expense',
    'expense',
    'BankAccount',
    'bank_account',
    'BankAccountMovement',
    'bank_account_movement',
    'BankAccountTransfer',
    'bank_account_transfer',
    'PurchaseOrder',
    'purchase_order',
    'InventoryMovement',
    'inventory_movement',
    'inventory_movement_fifo',
    'CreditNote',
    'credit_note',
    'CustomerCredit',
    'customer_credit',
    'ClientBalance',
    'client_balance',
    'ExpenseCategory',
    'expense_category',
    'Notification',
    'notification',
    'Organization',
    'organization',
    'organization_profit_margin',
    'User',
    'user',
    'user_profile',
    'UserPreferences',
    'user_preferences',
    'PrinterSettings',
    'printer_settings',
  };

  /// Verifica si un tipo de entidad es soportado
  static bool isEntityTypeSupported(String entityType) {
    return supportedEntityTypes.contains(entityType);
  }

  // ==================== ESTADOS DE SALUD ====================

  /// Umbral de operaciones fallidas para considerar el sistema "degradado"
  static const int degradedThresholdFailedOps = 5;

  /// Umbral de operaciones pendientes para considerar el sistema "sobrecargado"
  static const int overloadedThresholdPendingOps = 100;

  /// Umbral de operaciones permanentemente fallidas para requerir atención
  static const int criticalThresholdPermanentlyFailed = 1;
}

/// Estados de salud del sistema de sincronización
enum SyncHealthStatus {
  /// Sistema funcionando normalmente
  healthy,

  /// Sistema funcionando pero con operaciones fallidas pendientes
  degraded,

  /// Sistema con muchas operaciones pendientes
  overloaded,

  /// Sistema con operaciones que requieren atención del usuario
  critical,

  /// Sistema sin conexión
  offline,

  /// Error desconocido en el sistema
  error,
}

/// Información detallada de salud del sistema de sincronización
class SyncHealthInfo {
  final SyncHealthStatus status;
  final int pendingCount;
  final int failedCount;
  final int permanentlyFailedCount;
  final int completedCount;
  final DateTime? lastSyncTime;
  final bool isOnline;
  final String? errorMessage;
  final List<String> warnings;
  final List<SyncIssue> issues;

  const SyncHealthInfo({
    required this.status,
    required this.pendingCount,
    required this.failedCount,
    required this.permanentlyFailedCount,
    required this.completedCount,
    this.lastSyncTime,
    required this.isOnline,
    this.errorMessage,
    this.warnings = const [],
    this.issues = const [],
  });

  bool get hasIssues => issues.isNotEmpty;
  bool get needsUserAttention =>
      status == SyncHealthStatus.critical ||
      permanentlyFailedCount > 0 ||
      issues.any((i) => i.severity == IssueSeverity.critical);

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'pendingCount': pendingCount,
        'failedCount': failedCount,
        'permanentlyFailedCount': permanentlyFailedCount,
        'completedCount': completedCount,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
        'isOnline': isOnline,
        'errorMessage': errorMessage,
        'warnings': warnings,
        'issues': issues.map((i) => i.toJson()).toList(),
      };
}

/// Severidad de un problema de sincronización
enum IssueSeverity {
  /// Problema informativo, no requiere acción
  info,

  /// Advertencia, puede requerir atención
  warning,

  /// Error, requiere atención
  error,

  /// Crítico, requiere acción inmediata
  critical,
}

/// Problema específico de sincronización
class SyncIssue {
  final String code;
  final String message;
  final IssueSeverity severity;
  final String? entityType;
  final String? entityId;
  final DateTime detectedAt;
  final Map<String, dynamic>? metadata;

  SyncIssue({
    required this.code,
    required this.message,
    required this.severity,
    this.entityType,
    this.entityId,
    DateTime? detectedAt,
    this.metadata,
  }) : detectedAt = detectedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'severity': severity.name,
        'entityType': entityType,
        'entityId': entityId,
        'detectedAt': detectedAt.toIso8601String(),
        'metadata': metadata,
      };
}

/// Códigos de error de sincronización
class SyncErrorCodes {
  SyncErrorCodes._();

  // Errores de conexión
  static const String connectionLost = 'SYNC_CONNECTION_LOST';
  static const String connectionTimeout = 'SYNC_CONNECTION_TIMEOUT';
  static const String serverUnavailable = 'SYNC_SERVER_UNAVAILABLE';

  // Errores de datos
  static const String invalidPayload = 'SYNC_INVALID_PAYLOAD';
  static const String entityNotFound = 'SYNC_ENTITY_NOT_FOUND';
  static const String referenceNotFound = 'SYNC_REFERENCE_NOT_FOUND';
  static const String duplicateEntity = 'SYNC_DUPLICATE_ENTITY';

  // Errores de autenticación
  static const String authExpired = 'SYNC_AUTH_EXPIRED';
  static const String subscriptionExpired = 'SYNC_SUBSCRIPTION_EXPIRED';
  static const String insufficientPermissions = 'SYNC_INSUFFICIENT_PERMISSIONS';

  // Errores de conflicto
  static const String versionConflict = 'SYNC_VERSION_CONFLICT';
  static const String concurrentModification = 'SYNC_CONCURRENT_MODIFICATION';

  // Errores internos
  static const String databaseError = 'SYNC_DATABASE_ERROR';
  static const String maxRetriesExceeded = 'SYNC_MAX_RETRIES_EXCEEDED';
  static const String unknownError = 'SYNC_UNKNOWN_ERROR';
}
