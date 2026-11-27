// lib/features/products/domain/services/product_code_rules.dart
//
// Cómo leer lo que el cajero escribe o escanea en un buscador de productos.
// Sin Flutter ni GetX: se prueba sola.

/// Qué escribió el cajero.
enum SearchEntryKind {
  /// Texto (nombre, SKU con letras…): búsqueda normal.
  text,

  /// Número de 1 a 7 dígitos: un valor ("500", "20000") para un producto
  /// sin registrar, salvo que exista un producto con ese SKU o código de
  /// barras exacto.
  price,

  /// Número de 8 dígitos o más: código de barras (lector).
  barcode,
}

/// Regla de siempre de la app: solo números (se ignoran `.` y `,`); hasta 7
/// dígitos es un valor, 8 o más es un código de barras. Un EAN-8/EAN-13/
/// UPC-A tiene 8, 12 o 13 dígitos, y un valor de 7 dígitos ya es 9.999.999.
SearchEntryKind classifySearchEntry(String raw) {
  final value = raw.trim();
  if (value.isEmpty || double.tryParse(value) == null) {
    return SearchEntryKind.text;
  }
  final digits = value.replaceAll('.', '').replaceAll(',', '');
  if (RegExp(r'^\d{8,}$').hasMatch(digits)) return SearchEntryKind.barcode;
  if (RegExp(r'^\d{1,7}$').hasMatch(digits)) return SearchEntryKind.price;
  return SearchEntryKind.text;
}

/// Variantes de un código de barras para la búsqueda exacta: tal cual, sin
/// ceros adelante y con un cero adelante (códigos guardados con o sin el 0
/// de un EAN-13 / UPC-A).
List<String> barcodeVariants(String raw) {
  final code = raw.trim();
  if (code.isEmpty) return const [];
  final out = <String>[code];
  final stripped = code.replaceFirst(RegExp(r'^0+'), '');
  if (stripped.isNotEmpty && stripped != code) out.add(stripped);
  if (RegExp(r'^\d+$').hasMatch(code)) out.add('0$code');
  return out;
}

/// Largo máximo del código de barras de un producto (el servidor acepta
/// hasta 20 caracteres, sin mínimo).
const int maxProductBarcodeLength = 20;

/// Regla del código de barras al guardar un producto. Devuelve `null` si
/// sirve, o el mensaje para el usuario si no.
///
/// Vacío sirve (es opcional). Si tiene algo: sin espacios a los lados, de 1 a
/// [maxLength] caracteres y sin espacios por dentro. No se exige un largo
/// mínimo ni que sea un EAN: muchos negocios usan códigos propios cortos
/// ("0013390", "57") y los ceros adelante se guardan tal cual.
String? productBarcodeError(
  String? raw, {
  int maxLength = maxProductBarcodeLength,
}) {
  final code = raw?.trim() ?? '';
  if (code.isEmpty) return null;
  if (RegExp(r'\s').hasMatch(code)) {
    return 'El código de barras no puede tener espacios';
  }
  if (code.length > maxLength) {
    return 'El código de barras no puede tener más de $maxLength caracteres';
  }
  return null;
}
