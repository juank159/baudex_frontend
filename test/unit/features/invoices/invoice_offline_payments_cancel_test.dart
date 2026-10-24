import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/bank_accounts/data/models/isar/isar_bank_account.dart';
import 'package:baudex_desktop/features/customer_credits/data/models/isar/isar_customer_credit.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_item_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

/// Pagos con varios métodos y anulación de facturas SIN internet: deben
/// dejar el equipo igual que lo dejaría el servidor y encolar una operación
/// que el servidor aplique sin duplicar nada.
class _FakeSync extends SyncService {
  _FakeSync() : super(null);

  final ops = <Map<String, dynamic>>[];
  bool fail = false;

  @override
  Future<void> onInit() async {}

  @override
  Future<void> addOperation({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    required String organizationId,
    int priority = 0,
  }) async {
    if (fail) throw Exception('cola no disponible');
    ops.add({'entityType': entityType, 'entityId': entityId, ...data});
  }
}

void main() {
  late Isar isar;
  late InvoiceOfflineRepositorySimple repo;
  late _FakeSync sync;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  IsarCustomer customer(String id, String first, String last,
          {double creditLimit = 0, String? document}) =>
      IsarCustomer.create(
        serverId: id,
        firstName: first,
        lastName: last,
        email: '$id@x.com',
        documentType: IsarDocumentType.cc,
        documentNumber: document ?? id,
        status: IsarCustomerStatus.active,
        creditLimit: creditLimit,
        currentBalance: 0,
        paymentTerms: 30,
        totalPurchases: 0,
        totalOrders: 0,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isSynced: true,
      );

  IsarInvoice invoice(
    String id, {
    required String customerId,
    double total = 10000,
    double paid = 0,
    IsarInvoiceStatus status = IsarInvoiceStatus.pending,
    List<Map<String, dynamic>> items = const [],
  }) =>
      IsarInvoice.create(
        serverId: id,
        number: 'INV-$id',
        date: DateTime(2026, 10, 24),
        dueDate: DateTime(2026, 11, 24),
        status: status,
        paymentMethod: IsarPaymentMethod.cash,
        subtotal: total,
        taxPercentage: 0,
        taxAmount: 0,
        discountPercentage: 0,
        discountAmount: 0,
        total: total,
        paidAmount: paid,
        balanceDue: total - paid,
        customerId: customerId,
        createdAt: DateTime(2026, 10, 24),
        updatedAt: DateTime(2026, 10, 24),
        isSynced: true,
      )..itemsJson = jsonEncode(items);

  IsarProduct product(String id, double stock) => IsarProduct.create(
        serverId: id,
        name: id,
        sku: 'SKU-$id',
        type: IsarProductType.product,
        status: IsarProductStatus.active,
        stock: stock,
        minStock: 0,
        categoryId: 'cat',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isSynced: true,
        taxCategory: IsarTaxCategory.noGravado,
        taxRate: 0,
        isTaxable: false,
        hasRetention: false,
      );

  IsarInventoryBatch batch(String id, String productId,
          {required int original, required int current}) =>
      IsarInventoryBatch.create(
        serverId: id,
        productId: productId,
        productName: productId,
        productSku: productId,
        batchNumber: id,
        originalQuantity: original,
        currentQuantity: current,
        consumedQuantity: original - current,
        unitCost: 100,
        totalCost: original * 100,
        entryDate: DateTime(2026, 1, 1),
        status: IsarInventoryBatchStatus.active,
        warehouseId: 'w1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        isSynced: true,
      );

  IsarCustomerCredit credit(String id, String invoiceId, String customerId,
          double amount) =>
      IsarCustomerCredit(
        serverId: id,
        originalAmount: amount,
        paidAmount: 0,
        balanceDue: amount,
        status: IsarCreditStatus.pending,
        customerId: customerId,
        invoiceId: invoiceId,
        organizationId: 'org',
        createdById: 'u',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isSynced: true,
      );

  Future<IsarInvoice> reload(String id) async =>
      (await isar.isarInvoices.filter().serverIdEqualTo(id).findFirst())!;

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_inv_offline');
    isar = await Isar.open(
      [
        IsarInvoiceSchema,
        IsarCustomerSchema,
        IsarBankAccountSchema,
        IsarCustomerCreditSchema,
        IsarProductSchema,
        IsarInventoryBatchSchema,
      ],
      directory: dir.path,
    );
    IsarDatabase.debugSetDatabase(isar);
    Get.testMode = true;
    sync = _FakeSync();
    Get.put<SyncService>(sync);
    repo = InvoiceOfflineRepositorySimple();

    await isar.writeTxn(() async {
      await isar.isarCustomers.putAll([
        customer('juan', 'Juan', 'Perez', creditLimit: 50000),
        customer('cf', 'Consumidor', 'Final', document: '222222222222'),
      ]);
    });
  });

  tearDown(() async {
    Get.reset();
    await isar.close(deleteFromDisk: true);
    IsarDatabase.debugSetDatabase(null);
  });

  group('Anular sin internet', () {
    test('devuelve al inventario cantidad × presentación y anula el crédito', () async {
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice('f1', customerId: 'juan', items: [
          {
            'id': 'i1',
            'description': 'Huevos caja x12',
            'quantity': 2,
            'unitPrice': 5000,
            'subtotal': 10000,
            'invoiceId': 'f1',
            'productId': 'huevo',
            'presentationId': 'caja12',
            'presentationFactor': 12,
          },
        ]));
        await isar.isarProducts.put(product('huevo', 6));
        await isar.isarInventoryBatchs
            .put(batch('lote1', 'huevo', original: 30, current: 6));
        await isar.isarCustomerCredits.put(credit('c1', 'f1', 'juan', 10000));
      });

      final result = await repo.cancelInvoice('f1');

      expect(result.isRight(), isTrue);
      expect((await reload('f1')).status, IsarInvoiceStatus.cancelled);
      final p = await isar.isarProducts.filter().serverIdEqualTo('huevo').findFirst();
      expect(p!.stock, 30); // 6 + 2 cajas × 12
      expect(p.isSynced, isFalse); // protegido hasta que suba la anulación
      final b = await isar.isarInventoryBatchs.filter().serverIdEqualTo('lote1').findFirst();
      expect(b!.currentQuantity, 30);
      final c = await isar.isarCustomerCredits.filter().serverIdEqualTo('c1').findFirst();
      expect(c!.status, IsarCreditStatus.cancelled);

      expect(sync.ops, hasLength(1));
      expect(sync.ops.single['action'], 'cancel');
      expect(sync.ops.single['entityId'], 'f1');
      expect((sync.ops.single['items'] as List).single['productId'], 'huevo');
    });

    test('una factura pagada no se anula (igual que el servidor)', () async {
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice('f2',
            customerId: 'juan', paid: 10000, status: IsarInvoiceStatus.paid));
      });

      final result = await repo.cancelInvoice('f2');

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f.message, contains('pagada')), (_) {});
      expect((await reload('f2')).status, IsarInvoiceStatus.paid);
      expect(sync.ops, isEmpty);
    });

    test('un borrador se anula sin tocar inventario', () async {
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice('f3',
            customerId: 'juan',
            status: IsarInvoiceStatus.draft,
            items: [
              {
                'id': 'i1',
                'description': 'Huevo',
                'quantity': 3,
                'unitPrice': 500,
                'subtotal': 1500,
                'invoiceId': 'f3',
                'productId': 'huevo',
              },
            ]));
        await isar.isarProducts.put(product('huevo', 6));
      });

      await repo.cancelInvoice('f3');

      final p = await isar.isarProducts.filter().serverIdEqualTo('huevo').findFirst();
      expect(p!.stock, 6);
    });

    test('si no se puede encolar, no queda anulada en el equipo', () async {
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice('f4', customerId: 'juan'));
      });
      sync.fail = true;

      final result = await repo.cancelInvoice('f4');

      expect(result.isLeft(), isTrue);
      expect((await reload('f4')).status, IsarInvoiceStatus.pending);
    });
  });

  group('Pagos con varios métodos sin internet', () {
    test('registra cada pago con su clave y una sola operación en cola', () async {
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice('f5', customerId: 'juan'));
      });

      final result = await repo.addMultiplePayments(
        invoiceId: 'f5',
        payments: [
          PaymentItemData(amount: 3000, paymentMethod: PaymentMethod.cash),
          PaymentItemData(amount: 2000, paymentMethod: PaymentMethod.bankTransfer),
        ],
        idempotencyKeys: ['k1', 'k2'],
      );

      expect(result.isRight(), isTrue);
      final inv = await reload('f5');
      expect(inv.paidAmount, 5000);
      expect(inv.balanceDue, 5000);
      expect(inv.status, IsarInvoiceStatus.partiallyPaid);
      final payments = IsarInvoice.decodePayments(inv.paymentsJson);
      expect(payments.map((p) => p.id), ['k1', 'k2']);

      expect(sync.ops, hasLength(1));
      final op = sync.ops.single;
      expect(op['action'], 'addMultiplePayments');
      final sent = (op['payments'] as List).cast<Map>();
      expect(sent.map((p) => p['idempotencyKey']), ['k1', 'k2']);
      expect(sent.map((p) => p['paymentMethod']), ['cash', 'bank_transfer']);
    });

    test('pagar el saldo completo deja la factura pagada y baja su crédito', () async {
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice('f6', customerId: 'juan'));
        await isar.isarCustomerCredits.put(credit('c6', 'f6', 'juan', 10000));
      });

      await repo.addMultiplePayments(
        invoiceId: 'f6',
        payments: [
          PaymentItemData(amount: 6000, paymentMethod: PaymentMethod.cash),
          PaymentItemData(amount: 4000, paymentMethod: PaymentMethod.cash),
        ],
      );

      expect((await reload('f6')).status, IsarInvoiceStatus.paid);
      final c = await isar.isarCustomerCredits.filter().serverIdEqualTo('c6').findFirst();
      expect(c!.balanceDue, 0);
      expect(c.status, IsarCreditStatus.paid);
    });

    test('más del saldo sin crédito se rechaza', () async {
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice('f7', customerId: 'juan'));
      });

      final result = await repo.addMultiplePayments(
        invoiceId: 'f7',
        payments: [PaymentItemData(amount: 12000, paymentMethod: PaymentMethod.cash)],
      );

      expect(result.isLeft(), isTrue);
      expect(sync.ops, isEmpty);
    });

    test('el Consumidor Final no puede dejar saldo a crédito', () async {
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice('f8', customerId: 'cf'));
      });

      final result = await repo.addMultiplePayments(
        invoiceId: 'f8',
        payments: [PaymentItemData(amount: 4000, paymentMethod: PaymentMethod.cash)],
        createCreditForRemaining: true,
      );

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f.message, contains('Consumidor Final')), (_) {});
      expect((await reload('f8')).paidAmount, 0);
      expect(sync.ops, isEmpty);
    });

    test('saldo a crédito dentro del cupo crea el crédito provisional', () async {
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice('f9', customerId: 'juan'));
      });

      final result = await repo.addMultiplePayments(
        invoiceId: 'f9',
        payments: [PaymentItemData(amount: 4000, paymentMethod: PaymentMethod.cash)],
        createCreditForRemaining: true,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (r) => expect(r.creditCreated, isTrue));
      final credits = await isar.isarCustomerCredits
          .filter()
          .invoiceIdEqualTo('f9')
          .findAll();
      expect(credits, hasLength(1));
      expect(credits.single.serverId, startsWith('credit_offline_'));
      expect(credits.single.balanceDue, 6000);
    });

    test('saldo a crédito que supera el cupo se rechaza', () async {
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice('f10', customerId: 'juan', total: 100000));
      });

      final result = await repo.addMultiplePayments(
        invoiceId: 'f10',
        payments: [PaymentItemData(amount: 10000, paymentMethod: PaymentMethod.cash)],
        createCreditForRemaining: true,
      );

      expect(result.isLeft(), isTrue); // 90.000 > cupo de 50.000
      expect(sync.ops, isEmpty);
    });

    test('si no se puede encolar, los pagos se deshacen', () async {
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice('f11', customerId: 'juan'));
      });
      sync.fail = true;

      final result = await repo.addMultiplePayments(
        invoiceId: 'f11',
        payments: [PaymentItemData(amount: 3000, paymentMethod: PaymentMethod.cash)],
      );

      expect(result.isLeft(), isTrue);
      final inv = await reload('f11');
      expect(inv.paidAmount, 0);
      expect(IsarInvoice.decodePayments(inv.paymentsJson), isEmpty);
    });
  });

  test('la presentación vendida se conserva al guardar la factura en el equipo', () {
    final item = InvoiceItemModel.fromJson({
      'id': 'i1',
      'description': 'Huevos caja x12',
      'quantity': 1,
      'unitPrice': '5000.00',
      'subtotal': '5000.00',
      'invoiceId': 'f',
      'productId': 'huevo',
      'presentationId': 'caja12',
      'presentationFactor': '12.0000',
    });
    expect(item.presentationId, 'caja12');
    expect(item.presentationFactor, 12);

    final stored = IsarInvoice.decodeItemsPublic(jsonEncode([item.toJson()]));
    expect(stored.single.presentationId, 'caja12');
    expect(stored.single.presentationFactor, 12);
  });
}
