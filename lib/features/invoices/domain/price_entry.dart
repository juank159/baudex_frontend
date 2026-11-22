// lib/features/invoices/domain/price_entry.dart
//
// Qué hacer cuando el cajero escribe algo en el buscador de la factura y
// presiona Enter. Sin Flutter ni GetX: se prueba sola.

import '../../products/domain/services/product_code_rules.dart';

export '../../products/domain/services/product_code_rules.dart';

/// Valor del producto sin registrar (misma lectura que antes).
double priceFromEntry(String raw) => double.tryParse(raw.trim()) ?? 0.0;

/// Códigos cortos (SKU o código de barras de 1 a 7 dígitos, lo que se
/// confunde con un valor) de los productos activos del equipo, en memoria:
/// código → id local del producto. Con esto el cajero ve "sin registrar"
/// sin esperar a la base, y un producto registrado con código corto gana.
class ShortCodeIndex {
  ShortCodeIndex._(this._byCode, this.complete, this.builtAt);

  /// [entries]: (código, id local) de SKU y códigos de barras.
  /// [complete]: el catálogo entero ya está en el equipo; si no, un código
  /// que no está aquí todavía puede existir (descarga en curso).
  factory ShortCodeIndex.build(
    Iterable<(String?, int)> entries, {
    required bool complete,
    DateTime? builtAt,
  }) {
    final map = <String, int>{};
    for (final (raw, id) in entries) {
      final code = normalizeShortCode(raw);
      if (code == null) continue;
      map.putIfAbsent(code, () => id);
    }
    return ShortCodeIndex._(map, complete, builtAt ?? DateTime.now());
  }

  final Map<String, int> _byCode;
  final bool complete;
  final DateTime builtAt;

  int get length => _byCode.length;

  int? lookup(String code) {
    final key = normalizeShortCode(code);
    return key == null ? null : _byCode[key];
  }

  bool isOlderThan(Duration age, DateTime now) =>
      now.difference(builtAt) > age;
}

/// Código corto en la forma en que se compara (`null` si no es corto).
String? normalizeShortCode(String? raw) {
  final code = raw?.trim().toLowerCase() ?? '';
  if (code.isEmpty) return null;
  return classifySearchEntry(code) == SearchEntryKind.price ? code : null;
}

/// Lo que decide el Enter (o la pausa) con un valor.
sealed class PriceEntryDecision {
  const PriceEntryDecision();
}

/// Existe un producto con ese código: se agrega ese (id local).
class AddExistingProduct extends PriceEntryDecision {
  final int localId;
  const AddExistingProduct(this.localId);
}

/// No existe: producto sin registrar por ese valor.
class AddUnregisteredProduct extends PriceEntryDecision {
  final double price;
  const AddUnregisteredProduct(this.price);
}

/// No se puede decidir en memoria (catálogo aún bajando o índice sin
/// cargar): se consulta la base como antes.
class PriceEntryNeedsLookup extends PriceEntryDecision {
  const PriceEntryNeedsLookup();
}

/// Decide al instante qué hacer con un valor escrito por el cajero.
PriceEntryDecision decidePriceEntry(String raw, ShortCodeIndex? index) {
  if (classifySearchEntry(raw) != SearchEntryKind.price) {
    return const PriceEntryNeedsLookup();
  }
  if (index == null) return const PriceEntryNeedsLookup();
  final hit = index.lookup(raw);
  if (hit != null) return AddExistingProduct(hit);
  if (!index.complete) return const PriceEntryNeedsLookup();
  return AddUnregisteredProduct(priceFromEntry(raw));
}

/// Nombre de la línea cuando el cajero no le pone otro.
const String unregisteredProductName = 'Producto sin registrar';
