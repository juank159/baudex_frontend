// test/unit/features/invoices/invoice_detail_offline_sources_test.dart
//
// QA 1.0.24 (cambio C2): la venta ya no escribe `invoice_detail_<id>` en el
// almacén de sesión. El detalle sin internet (reimprimir, nota crédito,
// compartir) debe seguir encontrando:
//  - la factura NUEVA, que solo queda en la base del equipo (Isar);
//  - la factura VIEJA que solo existe en la copia antigua del almacén;
//  - y conservar pagos en otra moneda (moneda, monto, tasa) y a crédito.
import 'dart:convert';

import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_local_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_remote_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_repository_impl.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_isar.dart';

class _MemStorage implements SecureStorageService {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Remote extends Mock implements InvoiceRemoteDataSource {}

class _Offline implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;
  @override
  bool get isServerReachable => false;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Map<String, dynamic> _serverInvoice(String id, String number) => {
      'id': id,
      'number': number,
      'date': '2026-11-20T10:00:00.000-05:00',
      'dueDate': '2026-12-20T10:00:00.000-05:00',
      'status': 'partially_paid',
      'paymentMethod': 'credit',
      'subtotal': 100000,
      'taxPercentage': 0,
      'taxAmount': 0,
      'discountPercentage': 0,
      'discountAmount': 0,
      'total': 100000,
      'paidAmount': 40000,
      'balanceDue': 60000,
      'customerId': 'cust-1',
      'createdById': 'user-1',
      'items': [
        {
          'id': 'it-1',
          'description': 'Arroz',
          'quantity': 2,
          'unitPrice': 50000,
          'discountPercentage': 0,
          'discountAmount': 0,
          'subtotal': 100000,
          'unit': 'pcs',
          'invoiceId': id,
          'productId': 'prod-1',
          'createdAt': '2026-11-20T10:00:00.000-05:00',
          'updatedAt': '2026-11-20T10:00:00.000-05:00',
        }
      ],
      'payments': [
        {
          'id': 'pay-1',
          'amount': 40000,
          'paymentMethod': 'cash',
          'paymentDate': '2026-11-20T10:00:00.000-05:00',
          'invoiceId': id,
          'createdById': 'user-1',
          'organizationId': 'org-1',
          'paymentCurrency': 'USD',
          'paymentCurrencyAmount': 10,
          'exchangeRate': 4000,
          'createdAt': '2026-11-20T10:00:00.000-05:00',
          'updatedAt': '2026-11-20T10:00:00.000-05:00',
        }
      ],
      'createdAt': '2026-11-20T10:00:00.000-05:00',
      'updatedAt': '2026-11-20T10:00:00.000-05:00',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;
  late _MemStorage storage;
  late InvoiceRepositoryImpl repo;
  late InvoiceLocalDataSourceImpl local;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    isar = await openTestIsar();
  });

  tearDownAll(() async => closeTestIsar(isar));

  setUp(() async {
    await isar.writeTxn(() => isar.isarInvoices.clear());
    storage = _MemStorage();
    local = InvoiceLocalDataSourceImpl(storageService: storage);
    repo = InvoiceRepositoryImpl(
      remoteDataSource: _Remote(),
      localDataSource: local,
      networkInfo: _Offline(),
      offlineRepository: InvoiceOfflineRepositorySimple(),
    );
  });

  void expectSameSale(Invoice inv, String number) {
    expect(inv.number, number);
    expect(inv.total, 100000);
    expect(inv.paidAmount, 40000);
    expect(inv.balanceDue, 60000);
    expect(inv.items, hasLength(1));
    expect(inv.payments, hasLength(1));
    final p = inv.payments.single;
    expect(p.paymentCurrency, 'USD', reason: 'se perdió la moneda del pago');
    expect(p.paymentCurrencyAmount, 10);
    expect(p.exchangeRate, 4000);
  }

  test('factura NUEVA: no deja copia en el almacén y sin internet se lee de la base del equipo',
      () async {
    final model = InvoiceModel.fromJson(_serverInvoice('inv-new', 'F-100'));
    await local.cacheInvoice(model);

    expect(storage.data.keys.where((k) => k.startsWith('invoice_detail_')), isEmpty,
        reason: 'la venta volvió a escribir la copia por factura');
    final result = await repo.getInvoiceById('inv-new');
    final inv = result.fold((f) => fail('no se encontró sin internet: ${f.message}'), (i) => i);
    expectSameSale(inv, 'F-100');
  });

  test('factura VIEJA que solo existe en la copia antigua del almacén: sigue apareciendo sin internet',
      () async {
    // Base del equipo con otra factura (no vacía) y la vieja solo en el almacén.
    await local.cacheInvoice(InvoiceModel.fromJson(_serverInvoice('inv-other', 'F-1')));
    storage.data['invoice_detail_inv-old'] = jsonEncode({
      'invoice': _serverInvoice('inv-old', 'F-050'),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'version': '1.0',
    });

    final result = await repo.getInvoiceById('inv-old');
    final inv = result.fold((f) => fail('la factura vieja ya no aparece: ${f.message}'), (i) => i);
    expectSameSale(inv, 'F-050');
  });

  test('factura que no está en ninguna parte: error de conexión, como antes', () async {
    final result = await repo.getInvoiceById('no-existe');
    expect(result.isLeft(), isTrue);
  });
}
