// lib/features/settings/data/organization_write_clock.dart

/// Marca cada vez que ESTE equipo guarda la configuración del negocio.
///
/// Sirve para descartar respuestas viejas del servidor: una consulta que
/// salió antes de un guardado (el refresco periódico, la descarga completa)
/// puede volver después con el valor anterior. Sin esto, esa respuesta
/// pisaba lo recién guardado y, por ejemplo, la tasa de cambio volvía al
/// valor viejo en facturación hasta el siguiente refresco.
///
/// Uso: tomar [mark] antes de consultar al servidor y, al recibir la
/// respuesta, descartarla si [changedSince] dice que hubo un guardado.
class OrganizationWriteClock {
  const OrganizationWriteClock._();

  static int _writes = 0;

  /// Punto de referencia para una consulta que está por salir.
  static int get mark => _writes;

  /// Registrar que la configuración se está guardando (o se acaba de guardar).
  static void tick() => _writes++;

  /// ¿Se guardó algo desde que se tomó [mark]?
  static bool changedSince(int mark) => _writes != mark;
}
