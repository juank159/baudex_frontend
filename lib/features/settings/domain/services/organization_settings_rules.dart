// lib/features/settings/domain/services/organization_settings_rules.dart
//
// Reglas puras (sin Isar ni red) para que la configuración del negocio sea
// consistente entre equipos. Son puras para poder probarlas con tests.

/// Tipos de operación de la cola que modifican la configuración del negocio.
const Set<String> organizationOperationTypes = {
  'organization',
  'organization_profit_margin',
};

/// Combina los ajustes (`settings`) del negocio con un cambio PARCIAL.
///
/// Cada equipo envía solo lo que cambió (p. ej. solo `acceptedCurrencies` al
/// cambiar la tasa). Lo demás se conserva, igual que hace el servidor. Así un
/// equipo con una copia vieja no puede devolver la tasa que otro acaba de
/// guardar.
///
/// - Solo se tocan las claves que vienen en [incoming].
/// - Un valor `null` borra esa clave.
Map<String, dynamic> mergeOrganizationSettings(
  Map<String, dynamic>? current,
  Map<String, dynamic>? incoming,
) {
  final result = Map<String, dynamic>.from(current ?? const {});
  if (incoming == null) return result;
  incoming.forEach((key, value) {
    if (value == null) {
      result.remove(key);
    } else {
      result[key] = value;
    }
  });
  return result;
}

/// ¿Esta operación de la cola debe impedir que se aplique la versión del
/// servidor? Solo si es un cambio de configuración que TODAVÍA puede subir.
///
/// Una operación que el servidor ya rechazó definitivamente (agotó los
/// reintentos) NO debe congelar la configuración del equipo: antes, un solo
/// rechazo dejaba a ese equipo sin recibir nunca más la tasa de cambio.
bool blocksServerOrganization({
  required String entityType,
  required int retryCount,
  required int maxRetries,
}) {
  return organizationOperationTypes.contains(entityType) &&
      retryCount < maxRetries;
}
