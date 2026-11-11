// lib/features/products/domain/services/product_deletion_rules.dart
//
// Reglas para borrar un producto. Son las mismas que aplica el servidor
// (backend: src/products/product-deletion.rules.ts): aquí se revisan antes,
// con lo que el equipo ya sabe, para que la app no borre en local algo que el
// servidor va a rechazar.

/// Motivo por el que el producto NO se puede borrar, o `null` si sí se puede.
///
/// Un producto con existencias no se borra: sus lotes y su costo quedarían
/// huérfanos. Primero hay que dejarlo en cero (venta, ajuste o traslado).
/// Las órdenes de compra abiertas las revisa el servidor, que es quien las
/// conoce todas.
String? productDeletionBlockReason({
  required String name,
  required double stock,
}) {
  if (stock > 0) {
    return 'No se puede eliminar "$name": tiene ${_formatQuantity(stock)} en existencias. '
        'Deja el inventario en cero (venta o ajuste) o desactiva el producto.';
  }
  return null;
}

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

String _formatQuantity(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
