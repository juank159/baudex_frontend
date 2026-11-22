// lib/app/data/local/sync_enum_parse.dart
//
// Lectura tolerante de enums que vienen de la cola de sincronización, de Isar
// o del servidor. Nunca lanza `Bad state: No element`.

/// Busca el enum cuyo nombre coincide con [raw], sin distinguir mayúsculas ni
/// guiones bajos: `'noGravado'`, `'NO_GRAVADO'` y `'nogravado'` son lo mismo.
/// Si [raw] ya es del tipo, lo devuelve. `null`, vacío o desconocido → `null`.
T? enumFromQueue<T extends Enum>(List<T> values, Object? raw) {
  if (raw is T) return raw;
  if (raw == null) return null;
  final key = _normalize(raw.toString());
  if (key.isEmpty) return null;
  for (final e in values) {
    if (_normalize(e.name) == key) return e;
  }
  return null;
}

/// Igual que [enumFromQueue] para un campo obligatorio: si no se reconoce,
/// lanza un error que la política de la cola clasifica como rechazo visible
/// ("Solicitud incorrecta"), en vez de inventar un valor que cambie el dato.
T requiredEnumFromQueue<T extends Enum>(
  List<T> values,
  Object? raw, {
  required String field,
}) {
  final parsed = enumFromQueue(values, raw);
  if (parsed != null) return parsed;
  throw FormatException(
    'Solicitud incorrecta: valor no reconocido en "$field": "$raw"',
  );
}

String _normalize(String s) => s.trim().replaceAll('_', '').toLowerCase();
