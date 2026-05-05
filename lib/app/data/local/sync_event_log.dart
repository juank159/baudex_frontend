import 'package:isar/isar.dart';

part 'sync_event_log.g.dart';

/// Severidad de un evento del log
enum SyncEventSeverity {
  /// Operación informativa (sync iniciado, completado normalmente)
  info,

  /// Advertencia (reintento, fallback a cache, etc.)
  warning,

  /// Error real (sync falló tras retries, datos perdidos, excepción)
  error,
}

/// Tipo de evento para clasificar y filtrar
enum SyncEventType {
  /// FullSync (PULL desde servidor) iniciado/completado/fallido
  fullSync,

  /// Operación push individual (CREATE/UPDATE/DELETE) completada/fallida
  pushOperation,

  /// Limpieza de huérfanos
  cleanup,

  /// Error de red durante sync
  network,

  /// Diagnóstico interno (ej: integridad detectó algo)
  diagnostic,
}

/// Log persistente de eventos de sincronización para auditoría y diagnóstico.
///
/// Filosofía:
/// - **Aditivo**: nunca borra eventos antiguos automáticamente salvo via
///   `pruneOlderThan` explícito desde el módulo de diagnóstico.
/// - **Tolerante a fallas**: el escritor (sync_service) hace try/catch al
///   guardar logs. Si Isar falla escribir un log, el flujo de sync NO se
///   afecta.
/// - **Multitenant-aware**: cada evento lleva su `organizationId` para
///   poder filtrar por tenant del usuario actual.
@Collection()
class IsarSyncEventLog {
  Id id = Isar.autoIncrement;

  /// Cuándo ocurrió el evento (UTC)
  @Index()
  late DateTime timestamp;

  /// Severidad del evento
  @Enumerated(EnumType.name)
  @Index()
  late SyncEventSeverity severity;

  /// Categoría del evento
  @Enumerated(EnumType.name)
  @Index()
  late SyncEventType eventType;

  /// Tipo de entidad afectada (Product, Invoice, Customer, etc.)
  /// Vacío para eventos globales (FullSync iniciado, cleanup).
  @Index()
  late String entityType;

  /// ID de la entidad si aplica (server id o temp id)
  String entityId = '';

  /// Operación: 'create', 'update', 'delete', 'pull', 'cleanup', etc.
  late String operation;

  /// Mensaje legible para el usuario / soporte
  late String message;

  /// Detalle técnico opcional (stack trace, código de error, payload truncado)
  String? details;

  /// Número de reintento si la operación falló y se reintentó
  int retryCount = 0;

  /// ID de la organización (multitenant)
  @Index()
  late String organizationId;

  IsarSyncEventLog();

  /// Helper de construcción rápida
  factory IsarSyncEventLog.create({
    required SyncEventSeverity severity,
    required SyncEventType eventType,
    required String operation,
    required String message,
    required String organizationId,
    String entityType = '',
    String entityId = '',
    String? details,
    int retryCount = 0,
  }) {
    return IsarSyncEventLog()
      ..timestamp = DateTime.now().toUtc()
      ..severity = severity
      ..eventType = eventType
      ..operation = operation
      ..message = message
      ..organizationId = organizationId
      ..entityType = entityType
      ..entityId = entityId
      ..details = details
      ..retryCount = retryCount;
  }
}
