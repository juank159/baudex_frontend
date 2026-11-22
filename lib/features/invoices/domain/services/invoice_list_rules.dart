// lib/features/invoices/domain/services/invoice_list_rules.dart

/// ¿Hay que traer otra página para llenar la lista visible?
///
/// El filtro "Pendientes" (pendientes + pagadas en parte) se aplica en la
/// pantalla sobre las páginas ya cargadas, no en la consulta. Si las
/// facturas más recientes están pagadas, la primera página filtrada queda
/// vacía y la pantalla decía "No hay facturas" aunque sí las hubiera más
/// abajo (y sin lista no se puede bajar para cargar más). Mientras falten
/// filas visibles se traen más páginas, con un tope por acción para no
/// recorrer todo el historial de un golpe.
bool shouldFetchMoreToFillList({
  required bool localFilterActive,
  required int visible,
  required int target,
  required bool hasNextPage,
  required int extraPagesSoFar,
  int maxExtraPages = 15,
}) =>
    localFilterActive &&
    hasNextPage &&
    visible < target &&
    extraPagesSoFar < maxExtraPages;
