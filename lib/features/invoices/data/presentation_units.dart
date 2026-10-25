// lib/features/invoices/data/presentation_units.dart
import 'package:isar/isar.dart';

import '../../products/data/models/isar/isar_product_presentation.dart';
import '../domain/entities/invoice_item.dart';

/// Unidades BASE que mueve una línea de venta: cantidad × factor de la
/// presentación vendida (1 caja x12 = 12 unidades). Es lo que el servidor
/// descuenta al vender y lo que se debe devolver al anular o con nota crédito.
///
/// Facturas guardadas en el equipo antes de que se conservara el factor no lo
/// traen: en ese caso se toma de la presentación del producto cuyo nombre es
/// la unidad de la línea (la app pone el nombre de la presentación como unidad).
class PresentationUnits {
  PresentationUnits._();

  static Future<double> factorFor(Isar isar, InvoiceItem item) async {
    final known = item.presentationFactor;
    if (known != null && known > 0) return known;
    final productId = item.productId;
    final unit = item.unit?.trim().toLowerCase();
    if (productId == null || productId.isEmpty || unit == null || unit.isEmpty) {
      return 1;
    }
    try {
      final presentations = await isar.isarProductPresentations
          .filter()
          .productIdEqualTo(productId)
          .findAll();
      for (final p in presentations) {
        if (p.name.trim().toLowerCase() == unit && p.factor > 0) return p.factor;
      }
    } catch (_) {}
    return 1;
  }

  /// Unidades base de [quantity] unidades de venta de [item].
  static Future<int> baseUnits(Isar isar, InvoiceItem item, double quantity) async {
    final factor = await factorFor(isar, item);
    return (quantity * factor).round();
  }
}
