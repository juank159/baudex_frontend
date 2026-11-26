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

/// Fila que debe quedar elegida en la factura según cuántos productos hay.
///
/// Regla del negocio: mientras la factura tenga productos SIEMPRE hay una
/// fila elegida, para que los atajos (Ctrl+número, +, -) funcionen sin tener
/// que bajar con las flechas.
/// - Sin productos: ninguna (-1).
/// - Con productos y ninguna elegida: la primera (el último producto
///   agregado entra arriba).
/// - Elegida una que ya no existe: la última que queda.
int normalizeSelectedIndex(int selected, int itemCount) {
  if (itemCount <= 0) return -1;
  if (selected < 0) return 0;
  if (selected >= itemCount) return itemCount - 1;
  return selected;
}
