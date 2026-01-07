// lib/app/data/local/models/isar_idempotency_record.dart

import 'package:isar/isar.dart';

part 'isar_idempotency_record.g.dart';

/// Estado del procesamiento de una operación idempotente
enum IdempotencyStatus {
  pending,      // Pendiente de procesar
  processing,   // En proceso
  completed,    // Completada exitosamente
  failed,       // Falló
}

/// Registro de idempotencia para evitar duplicación de operaciones
@collection
class IsarIdempotencyRecord {
  Id id = Isar.autoIncrement;

  /// Clave única de idempotencia (usualmente: operationType_entityType_entityId_timestamp)
  @Index(unique: true)
  late String idempotencyKey;

  /// Tipo de operación (create, update, delete, sync)
  @Index()
  late String operationType;

  /// Tipo de entidad (Invoice, Customer, Product, etc.)
  @Index()
  late String entityType;

  /// ID de la entidad afectada
  @Index()
  late String entityId;

  /// Estado del procesamiento
  @Index()
  @Enumerated(EnumType.name)
  late IdempotencyStatus status;

  /// Timestamp de cuando se procesó exitosamente
  DateTime? processedAt;

  /// Datos de respuesta del servidor (JSON serializado)
  String? responseData;

  /// Mensaje de error si falló
  String? errorMessage;

  /// Número de intentos realizados
  late int retryCount;

  /// Último intento
  DateTime? lastRetryAt;

  /// Timestamp de expiración (para limpieza)
  DateTime? expiresAt;

  /// Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;

  // Constructores
  IsarIdempotencyRecord();

  IsarIdempotencyRecord.create({
    required this.idempotencyKey,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.status,
    this.processedAt,
    this.responseData,
    this.errorMessage,
    this.retryCount = 0,
    this.lastRetryAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Genera una clave de idempotencia única
  static String generateKey({
    required String operationType,
    required String entityType,
    required String entityId,
    String? suffix,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final parts = [operationType, entityType, entityId, timestamp.toString()];
    if (suffix != null && suffix.isNotEmpty) {
      parts.add(suffix);
    }
    return parts.join('_');
  }

  /// Crea un nuevo registro pendiente
  static IsarIdempotencyRecord createPending({
    required String operationType,
    required String entityType,
    required String entityId,
    String? suffix,
    int expirationHours = 24, // Expira después de 24 horas por defecto
  }) {
    final now = DateTime.now();
    return IsarIdempotencyRecord.create(
      idempotencyKey: generateKey(
        operationType: operationType,
        entityType: entityType,
        entityId: entityId,
        suffix: suffix,
      ),
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      status: IdempotencyStatus.pending,
      retryCount: 0,
      createdAt: now,
      updatedAt: now,
      expiresAt: now.add(Duration(hours: expirationHours)),
    );
  }

  // Métodos de utilidad
  bool get isPending => status == IdempotencyStatus.pending;
  bool get isProcessing => status == IdempotencyStatus.processing;
  bool get isCompleted => status == IdempotencyStatus.completed;
  bool get isFailed => status == IdempotencyStatus.failed;
  bool get canRetry => isFailed && retryCount < 3; // Máximo 3 reintentos
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Marca como en proceso
  void markAsProcessing() {
    status = IdempotencyStatus.processing;
    updatedAt = DateTime.now();
  }

  /// Marca como completado
  void markAsCompleted({String? responseData}) {
    status = IdempotencyStatus.completed;
    processedAt = DateTime.now();
    updatedAt = DateTime.now();
    if (responseData != null) {
      this.responseData = responseData;
    }
  }

  /// Marca como fallido
  void markAsFailed({required String errorMessage}) {
    status = IdempotencyStatus.failed;
    this.errorMessage = errorMessage;
    retryCount++;
    lastRetryAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Resetea para reintentar
  void resetForRetry() {
    if (canRetry) {
      status = IdempotencyStatus.pending;
      errorMessage = null;
      updatedAt = DateTime.now();
    }
  }

  @override
  String toString() {
    return 'IsarIdempotencyRecord{key: $idempotencyKey, operation: $operationType, entity: $entityType/$entityId, status: $status, retries: $retryCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IsarIdempotencyRecord &&
           other.idempotencyKey == idempotencyKey;
  }

  @override
  int get hashCode => idempotencyKey.hashCode;
}
