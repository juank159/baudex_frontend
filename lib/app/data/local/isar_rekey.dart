// lib/app/data/local/isar_rekey.dart
import 'package:isar/isar.dart';

/// Antes de pasarle el id REAL a un registro creado sin conexión (que tenía
/// un id temporal): si la descarga automática ya trajo la copia del servidor
/// con ese mismo id, esa copia se quita.
///
/// Sin esto el cambio de id chocaba con el índice único `serverId`: el
/// guardado fallaba, el registro quedaba duplicado en pantalla y lo que venía
/// después en la sincronización (p. ej. el mapeo temporal→real que usan los
/// pagos hechos sin conexión) no se ejecutaba.
///
/// Se conserva el registro local (tiene los cambios hechos en el equipo); la
/// próxima descarga lo actualiza con lo del servidor. Debe llamarse dentro de
/// la misma `writeTxn` que guarda el registro. Nunca lanza: si algo falla,
/// deja todo como estaba y el guardado sigue su curso normal.
Future<void> dropServerCopy(
  IsarCollection<dynamic> collection,
  Id localIsarId,
  String serverId,
) async {
  try {
    final dynamic existing = await collection.getByIndex('serverId', [serverId]);
    if (existing == null) return;
    final Id existingId = existing.id as Id;
    if (existingId != localIsarId) {
      await collection.delete(existingId);
    }
  } catch (_) {}
}
