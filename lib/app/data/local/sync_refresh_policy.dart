// lib/app/data/local/sync_refresh_policy.dart

/// Cada cuánto, como máximo, se recargan las pantallas mientras el equipo
/// baja el catálogo completo (equipo nuevo o versión nueva).
const Duration refreshEveryDuringFullDownload = Duration(seconds: 30);

/// Sin descarga completa: una recarga aunque los conteos no cambien, por si
/// algo cambió sin cambiar la cantidad.
const Duration refreshOverdueAfter = Duration(minutes: 3);

/// ¿Avisar a las pantallas que recarguen después de un pull?
///
/// Durante una descarga completa hay un pull cada 2 s y cada uno trae
/// registros nuevos: antes cada uno recargaba todas las pantallas abiertas
/// (tablero, listas, factura) y la caja se trababa mientras bajaba el
/// catálogo. Ahora, mientras dure la descarga, a lo sumo una recarga cada
/// [refreshEveryDuringFullDownload]; y una más al terminar.
///
/// - [broughtChanges]: el pull trajo registros nuevos o cambiados.
/// - [sinceLastRefresh]: tiempo desde la última recarga (`null` = nunca).
/// - [fullDownloadPending]: la descarga completa sigue (habrá más pulls).
/// - [refreshPostponed]: se omitió alguna recarga durante la descarga.
bool shouldRefreshScreensAfterPull({
  required bool broughtChanges,
  required Duration? sinceLastRefresh,
  required bool fullDownloadPending,
  required bool refreshPostponed,
}) {
  if (fullDownloadPending) {
    return broughtChanges &&
        (sinceLastRefresh == null ||
            sinceLastRefresh >= refreshEveryDuringFullDownload);
  }
  if (refreshPostponed) return true;
  return broughtChanges ||
      sinceLastRefresh == null ||
      sinceLastRefresh >= refreshOverdueAfter;
}
