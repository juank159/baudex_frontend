// lib/features/products/data/product_code_events.dart
import 'dart:async';

import '../../../app/data/local/enums/isar_enums.dart';
import 'models/isar/isar_product.dart';

/// Códigos de un producto que acaba de guardarse en el equipo.
class ProductCodeChange {
  final int localId;
  final String? sku;
  final String? barcode;

  /// Activo y no borrado (si no, sus códigos salen del índice).
  final bool active;

  const ProductCodeChange({
    required this.localId,
    this.sku,
    this.barcode,
    required this.active,
  });

  factory ProductCodeChange.of(IsarProduct p) => ProductCodeChange(
        localId: p.id,
        sku: p.sku,
        barcode: p.barcode,
        active: p.deletedAt == null && p.status == IsarProductStatus.active,
      );
}

/// Aviso inmediato (síncrono) de que se creó, editó o borró un producto en
/// el equipo, para que el índice de códigos cortos de la factura lo tenga
/// al instante. Lo que no pasa por aquí (p. ej. la descarga de la
/// sincronización) lo cubre el vigilante de la colección.
class ProductCodeEvents {
  ProductCodeEvents._();

  static final StreamController<ProductCodeChange> _controller =
      StreamController<ProductCodeChange>.broadcast(sync: true);

  static Stream<ProductCodeChange> get stream => _controller.stream;

  /// Llamar DESPUÉS de que la escritura terminó (el producto ya tiene id).
  static void notify(Iterable<IsarProduct> products) {
    for (final p in products) {
      if (p.id == 0 || p.id == -9223372036854775808) continue;
      _controller.add(ProductCodeChange.of(p));
    }
  }
}
