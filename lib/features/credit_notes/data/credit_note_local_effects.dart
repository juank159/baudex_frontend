// lib/features/credit_notes/data/credit_note_local_effects.dart
import 'package:isar/isar.dart';

import '../../../app/data/local/enums/isar_enums.dart';
import '../../inventory/data/models/isar/isar_inventory_batch.dart';
import '../../invoices/data/models/isar/isar_invoice.dart';
import '../../invoices/data/presentation_units.dart';
import '../../products/data/models/isar/isar_product.dart';
import 'models/isar/isar_credit_note.dart';

/// Línea de una nota crédito, lo mínimo para mover inventario.
class CreditNoteLine {
  final String? productId;
  final String? invoiceItemId;
  final double quantity;

  const CreditNoteLine({
    required this.productId,
    required this.invoiceItemId,
    required this.quantity,
  });
}

/// Efectos de CONFIRMAR una nota crédito en la base del equipo, iguales a los
/// del servidor (`CreditNotesService.confirm`):
/// - devuelve al inventario las unidades BASE (cantidad × presentación),
///   al lote más reciente primero;
/// - la factura queda acreditada total o parcialmente y baja su saldo.
class CreditNoteLocalEffects {
  CreditNoteLocalEffects._();

  /// Unidades base a devolver por producto.
  static Future<Map<String, int>> baseUnitsByProduct(
    Isar isar,
    String invoiceId,
    List<CreditNoteLine> lines,
  ) async {
    final invoice =
        await isar.isarInvoices.filter().serverIdEqualTo(invoiceId).findFirst();
    final invoiceItems = invoice?.toEntity().items ?? const [];
    final units = <String, int>{};
    for (final line in lines) {
      final productId = line.productId;
      if (productId == null || productId.isEmpty || line.quantity <= 0) continue;
      final invoiceItem = invoiceItems
          .where((i) => i.id == line.invoiceItemId)
          .firstOrNull;
      final qty = invoiceItem != null
          ? await PresentationUnits.baseUnits(isar, invoiceItem, line.quantity)
          : line.quantity.round();
      if (qty > 0) units[productId] = (units[productId] ?? 0) + qty;
    }
    return units;
  }

  /// Suma [units] al inventario del equipo. Con [markUnsynced] los productos
  /// quedan protegidos de la descarga hasta que el servidor confirme la nota.
  static Future<void> restoreInventory(
    Isar isar,
    Map<String, int> units, {
    required bool markUnsynced,
    required String modifiedBy,
  }) async {
    if (units.isEmpty) return;
    await isar.writeTxn(() async {
      for (final entry in units.entries) {
        final batches = await isar.isarInventoryBatchs
            .filter()
            .deletedAtIsNull()
            .and()
            .productIdEqualTo(entry.key)
            .findAll();
        batches.sort((a, b) => b.entryDate.compareTo(a.entryDate));
        var remaining = entry.value;
        for (final batch in batches) {
          if (remaining <= 0) break;
          final headroom = batch.originalQuantity - batch.currentQuantity;
          if (headroom <= 0) continue;
          final toRestore = remaining > headroom ? headroom : remaining;
          batch.addQuantity(toRestore, modifiedBy: modifiedBy);
          await isar.isarInventoryBatchs.put(batch);
          remaining -= toRestore;
        }

        final product = await isar.isarProducts
            .filter()
            .serverIdEqualTo(entry.key)
            .findFirst();
        if (product != null) {
          product.stock = product.stock + entry.value;
          if (markUnsynced) product.markAsUnsynced();
          await isar.isarProducts.put(product);
        }
      }
    });
  }

  /// Estado de la factura según sus notas crédito CONFIRMADAS en el equipo.
  static Future<void> applyInvoiceStatus(Isar isar, String invoiceId) async {
    final invoice =
        await isar.isarInvoices.filter().serverIdEqualTo(invoiceId).findFirst();
    if (invoice == null) return;
    final notes = await isar.isarCreditNotes
        .filter()
        .invoiceIdEqualTo(invoiceId)
        .and()
        .deletedAtIsNull()
        .and()
        .statusEqualTo(IsarCreditNoteStatus.confirmed)
        .findAll();
    final credited = notes.fold<double>(0, (sum, n) => sum + n.total);
    if (credited <= 0) return;
    if (credited >= invoice.total - 0.01) {
      invoice.status = IsarInvoiceStatus.credited;
      invoice.balanceDue = 0;
    } else {
      invoice.status = IsarInvoiceStatus.partiallyCredited;
      final balance = invoice.total - invoice.paidAmount - credited;
      invoice.balanceDue = balance > 0 ? balance : 0;
    }
    invoice.updatedAt = DateTime.now();
    await isar.writeTxn(() => isar.isarInvoices.put(invoice));
  }
}
