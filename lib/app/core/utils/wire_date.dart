// lib/app/core/utils/wire_date.dart

/// Convierte una fecha/hora a como debe viajar al servidor: instante exacto
/// en UTC (`...Z`).
///
/// La app guarda y muestra la hora del reloj del dispositivo. Si esa hora se
/// envía SIN zona horaria (`2026-10-13T08:22:11.243`), el servidor no puede
/// saber de qué zona es y la toma varias horas corrida; por eso un abono
/// hecho a las 08:22 quedaba guardado como si fuera de las 04:22 y la caja
/// del turno lo dejaba por fuera.
///
/// - `DateTime` local o texto sin zona → se interpreta en la zona del
///   dispositivo y se convierte a UTC.
/// - Texto que ya trae zona (`Z` u `±hh:mm`) → se respeta el instante.
/// - Texto que no es una fecha → se devuelve tal cual (lo valida el servidor).
String? toWireDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc().toIso8601String();

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  return parsed.toUtc().toIso8601String();
}

final RegExp _naiveDateTime = RegExp(
  r'^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(:\d{2})?(\.\d{1,9})?$',
);

/// `true` si el texto es una fecha-hora SIN zona horaria
/// (`2026-10-13T08:22:11.243`).
bool isNaiveDateTimeString(Object? value) =>
    value is String && _naiveDateTime.hasMatch(value.trim());

/// Le pone a una fecha-hora sin zona el desfase del dispositivo, SIN cambiar
/// lo que marca el reloj: `2026-10-13T08:22:11.243` → `2026-10-13T08:22:11.243-04:00`.
///
/// Con el desfase explícito el servidor recibe el instante exacto (ya no
/// tiene que adivinar la zona) y, como el reloj no cambia, la parte de la
/// fecha sigue siendo el día que ve el usuario.
String withDeviceOffset(String naive) {
  final text = naive.trim().replaceFirst(' ', 'T');
  final parsed = DateTime.tryParse(text);
  if (parsed == null || parsed.isUtc) return naive;

  final offset = parsed.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  final hh = (minutes ~/ 60).toString().padLeft(2, '0');
  final mm = (minutes % 60).toString().padLeft(2, '0');

  String two(int n) => n.toString().padLeft(2, '0');
  final wallClock = '${parsed.year.toString().padLeft(4, '0')}-${two(parsed.month)}-${two(parsed.day)}'
      'T${two(parsed.hour)}:${two(parsed.minute)}:${two(parsed.second)}'
      '.${parsed.millisecond.toString().padLeft(3, '0')}';
  return '$wallClock$sign$hh:$mm';
}

/// Recorre el cuerpo o los parámetros de una petición y devuelve una copia en
/// la que toda fecha-hora sin zona lleva el desfase del dispositivo. Lo demás
/// (fechas solas, textos, números, fechas que ya traen zona) queda igual.
dynamic withExplicitOffsets(dynamic node, [int depth = 0]) {
  if (node == null || depth > 12) return node;
  if (node is String) return isNaiveDateTimeString(node) ? withDeviceOffset(node) : node;
  if (node is DateTime) return node.toUtc().toIso8601String();
  if (node is Map) {
    final copy = <String, dynamic>{};
    node.forEach((key, value) {
      copy[key.toString()] = withExplicitOffsets(value, depth + 1);
    });
    return copy;
  }
  if (node is List) {
    return node.map((item) => withExplicitOffsets(item, depth + 1)).toList();
  }
  return node;
}

