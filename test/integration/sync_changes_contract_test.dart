// Verifica contra un backend real que lo que entrega GET /sync/changes se
// interpreta con los mismos modelos de la app. Se salta si no hay backend:
//   SYNC_TEST_URL=http://127.0.0.1:3997/api SYNC_TEST_TOKEN=... flutter test test/integration/sync_changes_contract_test.dart
import 'dart:io';

import 'package:baudex_desktop/app/data/local/sync_changes_client.dart';
import 'package:baudex_desktop/features/credit_notes/data/models/credit_note_model.dart';
import 'package:baudex_desktop/features/customer_credits/data/models/customer_credit_model.dart';
import 'package:baudex_desktop/features/customers/data/models/customer_model.dart';
import 'package:baudex_desktop/features/expenses/data/models/expense_model.dart';
import 'package:baudex_desktop/features/inventory/data/models/inventory_batch_model.dart';
import 'package:baudex_desktop/features/inventory/data/models/inventory_movement_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_model.dart';
import 'package:baudex_desktop/features/notifications/data/models/notification_model.dart';
import 'package:baudex_desktop/features/products/data/models/product_model.dart';
import 'package:baudex_desktop/features/products/data/models/product_presentation_model.dart';
import 'package:baudex_desktop/features/purchase_orders/data/models/purchase_order_model.dart';
import 'package:baudex_desktop/features/suppliers/data/models/supplier_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final url = Platform.environment['SYNC_TEST_URL'];
  final token = Platform.environment['SYNC_TEST_TOKEN'];
  final skip = url == null || token == null ? 'sin backend de prueba' : null;

  final parsers = <String, void Function(Map<String, dynamic>)>{
    'invoices': (j) => InvoiceModel.fromJson(j),
    'products': (j) => ProductModel.fromJson(j),
    'product_presentations': (j) => ProductPresentationModel.fromJson(j),
    'customers': (j) => CustomerModel.fromJson(j),
    'suppliers': (j) => SupplierModel.fromJson(j),
    'expenses': (j) => ExpenseModel.fromJson(j).toEntity(),
    'purchase_orders': (j) => PurchaseOrderModel.fromJson(j),
    'credit_notes': (j) => CreditNoteModel.fromJson(j),
    'customer_credits': (j) => CustomerCreditModel.fromJson(j),
    'inventory_batches': (j) => InventoryBatchModel.fromJson(j).toEntity(),
    'inventory_movements': (j) => InventoryMovementModel.fromJson(j),
    'notifications': (j) => NotificationModel.fromJson(j),
  };

  for (final entry in parsers.entries) {
    test('${entry.key}: la app interpreta cada registro', () async {
      final dio = Dio(BaseOptions(baseUrl: url!, headers: {
        'Authorization': 'Bearer $token',
        'X-Device-Id': 'test-device-1',
      }));
      final response = await dio.get('/sync/changes/${entry.key}',
          queryParameters: {'since': SyncChangesClient.epoch});
      final page = SyncChangesPage.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map));
      expect(page.items, isNotEmpty, reason: 'el backend de prueba debe tener datos');
      expect(page.stamps.length, page.items.length);
      for (final item in page.items) {
        entry.value(item);
      }
      // La marca que guarda la app la acepta el servidor tal cual.
      final next = await dio.get('/sync/changes/${entry.key}', queryParameters: {
        'since': SyncWatermarkStore.safeWatermark(page.watermark!, page.stamps.first),
      });
      expect(next.statusCode, 200);
    }, skip: skip);
  }
}
