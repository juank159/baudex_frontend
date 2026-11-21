// lib/app/core/errors/server_rejection.dart
//
// ¿El servidor dijo "no" (regla del negocio, dato inválido, sin permiso) o
// simplemente no se pudo llegar a él? La diferencia decide si una operación
// se guarda para reintentar o se le muestra el motivo al usuario.

/// ¿El servidor rechazó la operación (y reintentar no la va a arreglar)?
///
/// 401, 408 y 429 no cuentan: son de sesión, tiempo de espera o límite de
/// peticiones, y sí vale la pena reintentar más tarde.
bool isServerRejection(int? statusCode) {
  if (statusCode == null) return false;
  return statusCode >= 400 &&
      statusCode < 500 &&
      statusCode != 401 &&
      statusCode != 408 &&
      statusCode != 429;
}

/// ¿El servidor se negó a ELIMINAR algo que sigue existiendo?
///
/// Ejemplos: un producto con existencias, un proveedor con órdenes abiertas,
/// un cliente con deuda. En ese caso no se elimina en este equipo ni se deja
/// en la cola: se muestra el motivo. Un 404 no cuenta (ya no existe en el
/// servidor, así que eliminarlo aquí es lo correcto).
bool isDeleteRejection(int? statusCode) =>
    statusCode != 404 && isServerRejection(statusCode);

/// Motivo para mostrarle a un cajero: sin el prefijo técnico que el cliente
/// HTTP le antepone al mensaje del servidor ("Solicitud incorrecta: …").
String reasonForUser(String message, {String fallback = 'No se pudo completar la operación.'}) {
  final clean = message
      .replaceFirst(
        RegExp(r'^(Solicitud incorrecta|Conflicto|Recurso no encontrado|'
            r'Error interno del servidor|Datos inválidos|No encontrado|Error del servidor|Error): '),
        '',
      )
      .trim();
  return clean.isEmpty ? fallback : clean;
}
