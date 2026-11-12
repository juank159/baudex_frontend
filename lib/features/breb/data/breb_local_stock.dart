// lib/features/breb/data/breb_local_stock.dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../app/data/local/isar_database.dart';
import '../../products/data/datasources/product_remote_datasource.dart';
import '../../products/data/models/isar/isar_product.dart';

/// Una venta por Bre-B la crea el servidor (cuando llega el aviso del banco),
/// no este equipo: el inventario baja allá. Para que el cajero vea el stock
/// correcto de inmediato, sin esperar la siguiente sincronización, se trae del
/// servidor el stock de los productos vendidos y se guarda en el equipo.
///
/// Se COPIA el stock del servidor (no se resta aquí): así da igual si una
/// sincronización ya lo había actualizado, nunca se descuenta dos veces.
Future<int> refreshLocalStock({
  required Iterable<String> productIds,
  required Future<double?> Function(String productId) serverStockOf,
  required Isar isar,
}) async {
  var updated = 0;
  for (final id in productIds.toSet()) {
    try {
      final stock = await serverStockOf(id);
      if (stock == null) continue;
      final local = await isar.isarProducts.filter().serverIdEqualTo(id).findFirst();
      if (local == null || local.stock == stock) continue;
      local.stock = stock;
      await isar.writeTxn(() => isar.isarProducts.put(local));
      updated++;
    } catch (_) {
      // Sin conexión o producto no encontrado: lo corrige la sincronización.
    }
  }
  return updated;
}

/// Igual que [refreshLocalStock], con el servidor y la base local de la app.
Future<void> refreshLocalStockFromServer(Iterable<String> productIds) async {
  try {
    if (!Get.isRegistered<ProductRemoteDataSource>()) return;
    final remote = Get.find<ProductRemoteDataSource>();
    await refreshLocalStock(
      productIds: productIds,
      serverStockOf: (id) async => (await remote.getProductById(id)).stock,
      isar: IsarDatabase.instance.database as Isar,
    );
  } catch (_) {
    // Nunca debe interrumpir el cierre de la venta.
  }
}
