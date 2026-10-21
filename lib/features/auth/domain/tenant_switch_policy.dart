/// Qué hacer con los datos del equipo cuando alguien inicia sesión.
enum TenantSwitchDecision {
  /// Mismo negocio (o equipo sin datos de otro negocio): no se borra nada.
  keepLocalData,

  /// Otro negocio y nada pendiente por subir: limpiar para no mezclar datos.
  clearLocalData,

  /// Otro negocio con operaciones sin subir del anterior: no borrar nada y
  /// no dejar entrar (se perderían ventas, abonos…).
  blockedByPendingOperations,
}

/// Se compara el NEGOCIO de los datos guardados con el del usuario que
/// entra, no el usuario: un empleado del mismo negocio usa los mismos datos.
///
/// - [dataOrganization]: negocio de los datos del equipo (null si no se sabe,
///   p. ej. equipo sin nada descargado).
/// - [newOrganization]: negocio del usuario que inicia sesión.
/// - [lastUserId]/[newUserId]: solo se usan si no se sabe el negocio de los
///   datos (comportamiento anterior, para equipos sin esa información).
/// - [pendingOperations]: operaciones en cola sin subir.
TenantSwitchDecision decideTenantSwitch({
  required String? dataOrganization,
  required String newOrganization,
  required String? lastUserId,
  required String newUserId,
  required int pendingOperations,
}) {
  final bool otherBusiness;
  if (dataOrganization != null &&
      dataOrganization.isNotEmpty &&
      newOrganization.isNotEmpty) {
    otherBusiness = dataOrganization != newOrganization;
  } else {
    otherBusiness = lastUserId != null && lastUserId != newUserId;
  }
  if (!otherBusiness) return TenantSwitchDecision.keepLocalData;
  if (pendingOperations > 0) return TenantSwitchDecision.blockedByPendingOperations;
  return TenantSwitchDecision.clearLocalData;
}
