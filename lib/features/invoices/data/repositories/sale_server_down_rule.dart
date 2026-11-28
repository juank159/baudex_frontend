// lib/features/invoices/data/repositories/sale_server_down_rule.dart
import '../../../../app/core/errors/exceptions.dart';

/// ¿El fallo al crear una factura en el servidor indica que el servidor NO
/// está disponible (y no que rechazó la venta)?
///
/// Sí: se agotó el tiempo o no hubo conexión ([ConnectionException], que
/// incluye los topes de conectar, enviar y esperar respuesta), un error 5xx
/// o un 408.
///
/// No: cualquier rechazo de negocio (400, 401, 403, 404, 409, 422: cupo,
/// existencias, validación), un 429 (el servidor sí contesta) o una
/// respuesta que no se pudo interpretar.
///
/// Cuando es sí, el repositorio marca el servidor como no disponible para
/// que las ventas siguientes se guarden en el equipo de inmediato en vez de
/// volver a esperar el tope de tiempo.
bool saleFailureMeansServerDown(Object error) {
  if (error is ConnectionException) return true;
  if (error is ServerException) {
    final status = error.statusCode;
    return status != null && (status >= 500 || status == 408);
  }
  return false;
}
