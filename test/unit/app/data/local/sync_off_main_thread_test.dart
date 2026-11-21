import 'dart:convert';
import 'dart:isolate';

import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/app/data/local/sync_changes_client.dart';
import 'package:baudex_desktop/app/data/local/sync_refresh_policy.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter_test/flutter_test.dart';

/// La descarga lee el JSON y arma los registros locales en otro isolate
/// (antes congelaba la factura abierta hasta 1 s por página), y las
/// pantallas no se recargan con cada tanda de la descarga completa.
void main() {
  final now = DateTime.utc(2026, 11, 21, 12).toIso8601String();

  Map<String, dynamic> product(String id) => {
        'id': id,
        'name': 'Producto $id',
        'sku': 'SKU-$id',
        'barcode': '770$id',
        'type': 'product',
        'status': 'active',
        'stock': 12.0,
        'minStock': 1.0,
        'categoryId': 'cat-1',
        'createdById': 'user-1',
        'prices': [
          {
            'id': 'price-$id',
            'productId': id,
            'type': 'price1',
            'amount': 1500,
            'currency': 'COP',
            'status': 'active',
            'discountPercentage': 0,
            'minQuantity': 1,
            'createdAt': now,
            'updatedAt': now,
          }
        ],
        'createdAt': now,
        'updatedAt': now,
        'taxCategory': 'IVA',
        'taxRate': 19.0,
        'isTaxable': true,
      };

  Map<String, dynamic> invoice(String id) => {
        'id': id,
        'number': 'FV-$id',
        'date': now,
        'dueDate': now,
        'status': 'paid',
        'paymentMethod': 'cash',
        'subtotal': 3000,
        'taxPercentage': 0,
        'taxAmount': 0,
        'discountPercentage': 0,
        'discountAmount': 0,
        'total': 3000,
        'paidAmount': 3000,
        'balanceDue': 0,
        'customerId': 'cust-1',
        'createdById': 'user-1',
        'items': [
          {
            'id': 'item-$id',
            'description': 'Producto',
            'quantity': 2,
            'unitPrice': 1500,
            'discountPercentage': 0,
            'discountAmount': 0,
            'subtotal': 3000,
            'invoiceId': id,
            'productId': 'p1',
            'createdAt': now,
            'updatedAt': now,
          }
        ],
        'payments': [],
        'createdAt': now,
        'updatedAt': now,
      };

  String body(List<Map<String, dynamic>> items, {bool twice = false}) {
    final page = {
      'items': items,
      'stamps': [for (final _ in items) now],
      'deletedIds': ['gone-1'],
      'hasMore': true,
      'next': {'since': now, 'afterId': items.last['id']},
      'watermark': now,
    };
    final wrapped = {'success': true, 'data': page};
    return jsonEncode(twice ? {'success': true, 'data': wrapped} : wrapped);
  }

  group('página de /sync/changes leída en otro isolate', () {
    test('quita {success, data} aunque venga dos veces', () {
      final page = parseSyncChangesPage(
          body([product('p1')], twice: true), null);
      expect(page.items.single['id'], 'p1');
      expect(page.deletedIds, ['gone-1']);
      expect(page.hasMore, isTrue);
      expect(page.nextAfterId, 'p1');
      expect(page.rows, isNull);
    });

    test('productos: los registros llegan armados desde el otro isolate',
        () async {
      final text = body([product('p1'), product('p2')]);
      final page =
          await Isolate.run(() => parseSyncChangesPage(text, syncProductRows));
      expect(page.rows, hasLength(2));
      final rows = page.rows!.cast<IsarProduct>();
      expect(rows.map((r) => r.serverId), ['p1', 'p2']);
      expect(rows.first.barcode, '770p1');
      expect(rows.first.stock, 12.0);
    });

    test('facturas (con ítems): mismo registro que si se arma en la pantalla',
        () async {
      final text = body([invoice('i1')]);
      final page =
          await Isolate.run(() => parseSyncChangesPage(text, syncInvoiceRows));
      final fromIsolate = page.rows!.cast<IsarInvoice>().single;
      final here = syncInvoiceRows([invoice('i1')]).cast<IsarInvoice>().single;
      expect(fromIsolate.serverId, 'i1');
      expect(fromIsolate.number, here.number);
      expect(fromIsolate.total, here.total);
      expect(fromIsolate.itemsJson, here.itemsJson);
      expect(fromIsolate.itemsJson, contains('item-i1'));
    });
  });

  group('recargar pantallas tras un pull', () {
    bool decide({
      bool changes = true,
      Duration? since,
      bool pending = false,
      bool postponed = false,
    }) =>
        shouldRefreshScreensAfterPull(
          broughtChanges: changes,
          sinceLastRefresh: since,
          fullDownloadPending: pending,
          refreshPostponed: postponed,
        );

    test('descarga completa en curso: a lo sumo una recarga cada 30 s', () {
      expect(decide(pending: true, since: const Duration(seconds: 2)), isFalse);
      expect(decide(pending: true, since: const Duration(seconds: 29)), isFalse);
      expect(decide(pending: true, since: const Duration(seconds: 30)), isTrue);
      expect(decide(pending: true, since: null), isTrue);
      expect(decide(pending: true, changes: false, since: null), isFalse);
    });

    test('al terminar la descarga se recarga una vez aunque no haya cambios',
        () {
      expect(
          decide(
              changes: false,
              postponed: true,
              since: const Duration(seconds: 5)),
          isTrue);
    });

    test('sin descarga completa: igual que antes (cambios o cada 3 min)', () {
      expect(decide(since: const Duration(seconds: 5)), isTrue);
      expect(decide(changes: false, since: const Duration(minutes: 1)), isFalse);
      expect(decide(changes: false, since: const Duration(minutes: 3)), isTrue);
    });
  });
}
