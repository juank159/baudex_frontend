// lib/app/data/local/sync_failure_policy.dart
import '../../core/errors/exceptions.dart';

/// Por qué falló una operación de la cola de sincronización. Define qué se
/// hace con ella.
///
/// REGLA DE ORO: una operación solo sale de la cola cuando el servidor
/// confirmó que la tiene. Un error nunca la borra ni la da por hecha.
enum SyncFailureKind {
  /// Red, timeout, servidor caído, sesión vencida, dependencia que aún no
  /// sube: se reintenta sola, siempre, sin límite.
  transient,

  /// El servidor la rechazó por una regla de negocio o validación: se
  /// conserva como "requiere atención", se avisa al usuario y se reintenta
  /// cada cierto tiempo por si la causa ya se resolvió.
  rejected,

  /// El servidor ya la tenía (reenvío de algo que sí llegó): es la única
  /// falla que cuenta como confirmación.
  alreadyOnServer,

  /// Suscripción vencida: se pausa el sync y la operación se conserva.
  subscription,
}

/// Clasifica el error de una operación de la cola.
///
/// [isPermanentValidation]: el handler de la entidad ya determinó que el
/// servidor rechazó los datos.
SyncFailureKind classifySyncFailure({
  required String entityType,
  required Object error,
  bool isPermanentValidation = false,
}) {
  final msg = error.toString().toLowerCase();

  bool hasAny(List<String> needles) => needles.any(msg.contains);

  final isSubscriptionText = hasAny(const [
    'suscripción ha expirado',
    'suscripcion ha expirado',
    'subscription has expired',
    'subscription expired',
    'actualice su plan',
  ]);
  final isDuplicateText = hasAny(const [
    'ya existe',
    'already exists',
    'duplicate key',
    'unique constraint',
    'violates unique',
  ]);
  // movementNumber/batchNumber duplicado por carrera: el backend genera un
  // número nuevo en el reintento → transitorio.
  final isInventorySequenceError =
      (entityType == 'InventoryMovement' || entityType == 'inventory_movement') &&
          isDuplicateText;

  if (isPermanentValidation) return SyncFailureKind.rejected;
  if (isSubscriptionText) return SyncFailureKind.subscription;
  if (isInventorySequenceError) return SyncFailureKind.transient;
  if (error is ConnectionException) return SyncFailureKind.transient;

  if (error is ServerException && error.statusCode != null) {
    final code = error.statusCode!;
    // Sesión vencida, timeouts, límite de peticiones, servidor caído.
    if (code == 401 || code == 408 || code == 425 || code == 429 || code >= 500) {
      return SyncFailureKind.transient;
    }
    if (isDuplicateText) return SyncFailureKind.alreadyOnServer;
    if (code >= 400 && code < 500) return SyncFailureKind.rejected;
    return SyncFailureKind.transient;
  }

  // Excepciones sin código HTTP: decidir por el texto.
  if (isDuplicateText) return SyncFailureKind.alreadyOnServer;

  final isValidationText = hasAny(const [
    'solicitud incorrecta',
    'bad request',
    'must be a valid',
    'debe ser un',
    'violates not-null',
    'violates foreign key',
    'violates check constraint',
    'invalid input syntax',
    'cannot be modified',
  ]);
  if (isValidationText) return SyncFailureKind.rejected;

  // Todo lo demás (red, timeout, dependencia que aún no sincroniza, error
  // inesperado) es transitorio: se reintenta, nunca se pierde.
  return SyncFailureKind.transient;
}

/// Un DELETE que el servidor responde con 404 ya cumplió su objetivo: el
/// registro no existe allá. Cuenta como confirmación, no como rechazo.
///
/// No aplica si el 404 es porque la ruta no existe ("Cannot DELETE /api/…"):
/// eso es un problema de versión, no un registro ya borrado.
bool isDeleteAlreadyGone({required bool isDelete, required Object error}) {
  if (!isDelete) return false;
  if (error is! ServerException || error.statusCode != 404) return false;
  return !_isMissingRoute(error.message);
}

/// Igual que [isDeleteAlreadyGone] para una operación que ya quedó en la cola
/// como fallida y solo conserva el texto del error.
bool isFailedDeleteAlreadyGone({
  required bool isDelete,
  required String? storedError,
}) {
  if (!isDelete || storedError == null) return false;
  final msg = storedError.toLowerCase();
  if (_isMissingRoute(msg)) return false;
  return msg.contains('recurso no encontrado') ||
      msg.contains('(http 404)') ||
      msg.contains('statuscode: 404');
}

bool _isMissingRoute(String message) =>
    message.toLowerCase().contains('cannot delete');
