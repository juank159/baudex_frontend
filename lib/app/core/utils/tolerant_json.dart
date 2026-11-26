// lib/app/core/utils/tolerant_json.dart
//
// Lectura TOLERANTE de lo que responde el servidor. Sin Flutter ni GetX.
//
// Un campo opcional que llega nulo, con otro tipo (un número como texto,
// un entero donde se esperaba decimal) o con una fecha rara NO puede
// tumbar la lectura de todo el registro: se usa el valor por defecto y se
// anota QUÉ campo y QUÉ tipo llegó (nunca el valor, que puede ser un dato
// del negocio).

/// Un campo que no llegó como se esperaba.
class JsonIssue {
  const JsonIssue(this.field, this.expected, this.got);
  final String field;
  final String expected;

  /// Tipo de lo que llegó (p. ej. `String`, `List<dynamic>`, `null`).
  final String got;

  @override
  String toString() => '$field: se esperaba $expected y llegó $got';
}

/// Lee campos de un mapa sin fallar nunca.
class TolerantJson {
  TolerantJson(Object? source, {this.prefix = ''})
      : _map = source is Map ? source : const {} {
    if (source is! Map) {
      issues.add(JsonIssue(prefix.isEmpty ? '(respuesta)' : prefix, 'objeto',
          _typeOf(source)));
    }
  }

  final Map<dynamic, dynamic> _map;
  final String prefix;
  final List<JsonIssue> issues = [];

  static String _typeOf(Object? value) =>
      value == null ? 'null' : value.runtimeType.toString();

  void _note(String field, String expected, Object? value) => issues
      .add(JsonIssue(prefix.isEmpty ? field : '$prefix.$field', expected, _typeOf(value)));

  bool has(String field) => _map[field] != null;

  /// Texto. Un número o un sí/no se aceptan como texto.
  String? string(String field) {
    final v = _map[field];
    if (v == null) return null;
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    _note(field, 'texto', v);
    return null;
  }

  /// Decimal. Acepta entero, decimal o un número escrito como texto.
  double? decimal(String field) {
    final v = _map[field];
    if (v == null) return null;
    if (v is num) return v.isFinite ? v.toDouble() : null;
    if (v is String) {
      final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
      if (parsed != null && parsed.isFinite) return parsed;
    }
    _note(field, 'número', v);
    return null;
  }

  /// Entero. Acepta decimal (se trunca) o un número escrito como texto.
  int? integer(String field) {
    final v = _map[field];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.isFinite ? v.truncate() : null;
    if (v is String) {
      final parsed = num.tryParse(v.trim());
      if (parsed != null && parsed.isFinite) return parsed.truncate();
    }
    _note(field, 'entero', v);
    return null;
  }

  /// Sí/no. Acepta true/false, 1/0 y "true"/"false"/"1"/"0"/"si"/"no".
  bool? boolean(String field) {
    final v = _map[field];
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      switch (v.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'si':
        case 'sí':
        case 'yes':
          return true;
        case 'false':
        case '0':
        case 'no':
        case '':
          return false;
      }
    }
    _note(field, 'sí/no', v);
    return null;
  }

  /// Fecha. Acepta texto ISO, milisegundos desde 1970 (número o texto).
  DateTime? date(String field) {
    final v = _map[field];
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      final text = v.trim();
      if (text.isEmpty) return null;
      // Solo dígitos: segundos o milisegundos (como fecha ISO daría un año
      // disparatado).
      final millis = int.tryParse(text);
      if (millis != null) return _fromEpoch(millis);
      final parsed = DateTime.tryParse(text);
      if (parsed != null) return parsed;
    }
    if (v is num && v.isFinite) return _fromEpoch(v.truncate());
    _note(field, 'fecha', v);
    return null;
  }

  static DateTime? _fromEpoch(int value) {
    try {
      // Segundos o milisegundos.
      final ms = value.abs() < 100000000000 ? value * 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    } catch (_) {
      return null;
    }
  }

  /// Objeto anidado como mapa de texto → valor (`null` si no es un objeto).
  Map<String, dynamic>? object(String field) {
    final v = _map[field];
    if (v == null) return null;
    if (v is Map) {
      return {for (final e in v.entries) e.key.toString(): e.value};
    }
    _note(field, 'objeto', v);
    return null;
  }

  /// Lector de un objeto anidado (sus campos se anotan con el prefijo).
  TolerantJson child(String field) {
    final v = _map[field];
    final name = prefix.isEmpty ? field : '$prefix.$field';
    if (v == null) return TolerantJson(const <String, dynamic>{}, prefix: name);
    final reader = TolerantJson(v is Map ? v : const <String, dynamic>{},
        prefix: name);
    if (v is! Map) issues.add(JsonIssue(name, 'objeto', _typeOf(v)));
    return reader;
  }
}

/// El dato dentro de las envolturas `{success, data}` del servidor (a
/// veces viene envuelto dos veces). [looksLikeIt] dice si un mapa ya es el
/// dato buscado (p. ej. tiene `id`).
Object? unwrapData(Object? body, {bool Function(Map<dynamic, dynamic>)? looksLikeIt}) {
  var current = body;
  for (var depth = 0; depth < 4; depth++) {
    if (current is! Map) return current;
    if (looksLikeIt != null && looksLikeIt(current)) return current;
    if (!current.containsKey('data')) return current;
    current = current['data'];
  }
  return current;
}
