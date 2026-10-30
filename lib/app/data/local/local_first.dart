import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../core/errors/failures.dart';
import 'full_sync_service.dart';

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

/// Colección local → módulo de la descarga incremental. Estos módulos se
/// descargan por partes (primero lo reciente, luego el histórico), así que
/// "tener datos" no basta: hay que esperar a que la descarga termine.
const Map<String, String> _incrementalEntityByCollection = {
  'IsarProduct': 'products',
  'IsarProductPresentation': 'product_presentations',
  'IsarCustomer': 'customers',
  'IsarSupplier': 'suppliers',
  'IsarInvoice': 'invoices',
  'IsarExpense': 'expenses',
  'IsarPurchaseOrder': 'purchase_orders',
  'IsarCreditNote': 'credit_notes',
  'IsarCustomerCredit': 'customer_credits',
  'IsarInventoryBatch': 'inventory_batches',
  'IsarInventoryMovement': 'inventory_movements',
  'IsarNotification': 'notifications',
};

/// ¿El equipo ya tiene el módulo COMPLETO? Para los módulos incrementales,
/// su descarga completa debe haber terminado (antes bastaba con tener algún
/// registro, y tras una reinstalación las pantallas mostraban solo lo de los
/// últimos días, p. ej. "6 productos"). Una vez listo, se recuerda.
final Set<String> _readyCollections = {};

Future<bool> localCollectionReady(IsarCollection<dynamic> collection) async {
  final key = collection.name;
  if (_readyCollections.contains(key)) return true;
  final entity = _incrementalEntityByCollection[key];
  if (entity != null) {
    if (!Get.isRegistered<FullSyncService>()) return false;
    if (!await Get.find<FullSyncService>().isModuleDownloaded(entity)) {
      return false;
    }
    // Descarga completa terminada: lo del equipo es TODO lo que hay, aunque
    // esté vacío (p. ej. un negocio sin presentaciones). Antes "vacío" era
    // "no listo" y cada producto agregado a la factura esperaba al servidor.
    _readyCollections.add(key);
    return true;
  }
  final ready = await collection.count() > 0;
  if (ready) _readyCollections.add(key);
  return ready;
}

/// Al cambiar de negocio o cerrar sesión la base local se vacía: olvidar.
void resetLocalCollectionsReady() => _readyCollections.clear();
