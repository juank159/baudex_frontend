// lib/features/invoices/presentation/widgets/items_scroll_math.dart

/// Desplazamiento para que la fila [index] de una lista de [itemCount] filas
/// quede a la vista, centrada; `null` si ya se ve completa. Centrada y no
/// pegada al borde: en escritorio el borde inferior de la tabla puede quedar
/// tapado por el resumen de la venta.
///
/// El alto de la fila se mide del contenido real ([contentExtent] = alto
/// total de la lista / número de filas), no de un valor fijo: las filas de
/// la factura miden ~36 px en escritorio y ~41 en celular, y con el valor
/// fijo de antes (54) la fila re-escaneada en una factura larga quedaba
/// fuera de la vista.
double? scrollOffsetToReveal({
  required int index,
  required int itemCount,
  required double contentExtent,
  required double viewportExtent,
  required double currentOffset,
}) {
  if (itemCount <= 0 || index < 0 || index >= itemCount) return null;
  if (contentExtent <= 0 || viewportExtent <= 0) return null;
  final rowExtent = contentExtent / itemCount;
  final top = index * rowExtent;
  final bottom = top + rowExtent;
  if (top >= currentOffset && bottom <= currentOffset + viewportExtent) {
    return null;
  }
  final centered = top - (viewportExtent - rowExtent) / 2;
  final maxOffset = contentExtent - viewportExtent;
  if (maxOffset <= 0) return 0;
  return centered.clamp(0.0, maxOffset);
}
