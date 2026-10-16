import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';

import '../../core/errors/failures.dart';

/// Lectura local-first: las pantallas muestran lo que hay en el equipo al
/// instante, con o sin internet. El servidor no se espera para pintar: la
/// descarga automática (cada minuto, solo lo que cambió) mantiene la base
/// local al día y avisa a las pantallas cuando llegan cambios.
///
/// Devuelve el resultado local, o `null` para que el repositorio siga con
/// su camino de siempre (servidor y respaldo) cuando:
/// - el módulo todavía no se ha descargado al equipo (instalación nueva),
/// - la lectura local falló o no encontró el registro pedido,
/// - [accept] lo rechaza (p. ej. un filtro que solo sabe aplicar el servidor).
Future<Either<Failure, T>?> readLocalFirst<T>({
  required Future<bool> Function() hasLocalData,
  required Future<Either<Failure, T>> Function() read,
  bool Function(T value)? accept,
}) async {
  try {
    if (!await hasLocalData()) return null;
    final result = await read();
    return result.fold(
      (_) => null,
      (value) => (accept == null || accept(value)) ? result : null,
    );
  } catch (_) {
    return null;
  }
}

/// ¿La colección ya tiene datos en el equipo? Una vez que sí, se recuerda
/// para no volver a contar en cada lectura.
final Set<String> _readyCollections = {};

Future<bool> localCollectionReady(IsarCollection<dynamic> collection) async {
  final key = collection.name;
  if (_readyCollections.contains(key)) return true;
  final ready = await collection.count() > 0;
  if (ready) _readyCollections.add(key);
  return ready;
}

/// Al cambiar de negocio o cerrar sesión la base local se vacía: olvidar.
void resetLocalCollectionsReady() => _readyCollections.clear();
