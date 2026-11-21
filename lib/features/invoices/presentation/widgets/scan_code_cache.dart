// lib/features/invoices/presentation/widgets/scan_code_cache.dart
import '../../../products/domain/entities/product.dart';

/// Recuerda qué producto corresponde a cada código escaneado en la factura.
///
/// Solo responde si ese producto TODAVÍA está en la factura: así un
/// re-escaneo (sumar uno más) no espera a la base local, y un producto que
/// se quitó vuelve a buscarse con su precio y existencia actuales.
class ScanCodeCache {
  ScanCodeCache({this.maxEntries = 500});

  final int maxEntries;
  final Map<String, Product> _byCode = {};

  int get length => _byCode.length;

  Product? lookup(String code, {required bool Function(String productId) isInInvoice}) {
    final product = _byCode[code];
    if (product == null) return null;
    if (!isInInvoice(product.id)) {
      _byCode.remove(code);
      return null;
    }
    return product;
  }

  void remember(String code, Product product) {
    _byCode.remove(code);
    _byCode[code] = product;
    while (_byCode.length > maxEntries) {
      _byCode.remove(_byCode.keys.first);
    }
  }

  void clear() => _byCode.clear();
}
