import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/credit_notes/data/models/isar/isar_credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/data/repositories/credit_note_offline_repository.dart';
import 'package:baudex_desktop/features/credit_notes/domain/entities/credit_note.dart';
import 'package:baudex_desktop/features/credit_notes/domain/repositories/credit_note_repository.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product_presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

/// Notas crédito (devoluciones) SIN internet: mismo resultado que el
/// servidor — inventario en unidades base (cantidad × presentación), factura
/// acreditada — y siempre encoladas para subir.
class _FakeSync extends SyncService {
  _FakeSync() : super(null);
  final ops = <Map<String, dynamic>>[];
  bool fail = false;

  @override
  Future<void> onInit() async {}

  @override
  Future<void> addOperationForCurrentUser({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    if (fail) throw Exception('cola no disponible');
    ops.add({'entityType': entityType, 'entityId': entityId, 'op': operationType.name, ...data});
  }
}

void main() {
  late Isar isar;
  late CreditNoteOfflineRepository repo;
  late _FakeSync sync;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_cn_offline');
    isar = await Isar.open([
      IsarCreditNoteSchema,
      IsarInvoiceSchema,
      IsarProductSchema,
      IsarProductPresentationSchema,
      IsarInventoryBatchSchema,
    ], directory: dir.path);
    IsarDatabase.debugSetDatabase(isar);
    Get.testMode = true;
    sync = _FakeSync();
    Get.put<SyncService>(sync);
    repo = CreditNoteOfflineRepository();

    await isar.writeTxn(() async {
      // Venta: 2 cajas x12 de huevo (sin factor guardado: factura bajada
      // antes del arreglo) + 1 unidad de sal. Total 13.000, pagada.
      await isar.isarInvoices.put(IsarInvoice.create(
        serverId: 'f1',
        number: 'INV-1',
        date: DateTime(2026, 10, 25),
        dueDate: DateTime(2026, 10, 25),
        status: IsarInvoiceStatus.paid,
        paymentMethod: IsarPaymentMethod.cash,
        subtotal: 13000,
        taxPercentage: 0,
        taxAmount: 0,
        discountPercentage: 0,
        discountAmount: 0,
        total: 13000,
        paidAmount: 13000,
        balanceDue: 0,
        customerId: 'c',
        createdAt: DateTime(2026, 10, 25),
        updatedAt: DateTime(2026, 10, 25),
        isSynced: true,
      )..itemsJson = jsonEncode([
          {'id': 'it-huevo', 'description': 'Huevo', 'quantity': 2, 'unitPrice': 6000,
           'subtotal': 12000, 'unit': 'Caja x12', 'invoiceId': 'f1', 'productId': 'huevo'},
          {'id': 'it-sal', 'description': 'Sal', 'quantity': 1, 'unitPrice': 1000,
           'subtotal': 1000, 'unit': 'und', 'invoiceId': 'f1', 'productId': 'sal'},
        ]));
      await isar.isarProductPresentations.put(IsarProductPresentation.create(
        serverId: 'pres-caja',
        productId: 'huevo',
        name: 'Caja x12',
        factor: 12,
        price: 6000,
        currency: 'COP',
        isDefault: false,
        isActive: true,
        sortOrder: 0,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        isSynced: true,
      ));
      for (final id in ['huevo', 'sal']) {
        await isar.isarProducts.put(IsarProduct.create(
          serverId: id, name: id, sku: 'SKU-$id', type: IsarProductType.product,
          status: IsarProductStatus.active, stock: 10, minStock: 0, categoryId: 'c',
          createdAt: DateTime(2026), updatedAt: DateTime(2026), isSynced: true,
          taxCategory: IsarTaxCategory.noGravado, taxRate: 0, isTaxable: false,
          hasRetention: false));
      }
    });
  });

  tearDown(() async {
    Get.reset();
    await isar.close(deleteFromDisk: true);
    IsarDatabase.debugSetDatabase(null);
  });

  Future<double> stock(String id) async =>
      (await isar.isarProducts.filter().serverIdEqualTo(id).findFirst())!.stock;
  Future<IsarInvoice> invoice() async =>
      (await isar.isarInvoices.filter().serverIdEqualTo('f1').findFirst())!;

  CreateCreditNoteParams params({bool restore = true, bool onlyEggs = true}) =>
      CreateCreditNoteParams(
        invoiceId: 'f1',
        type: onlyEggs ? CreditNoteType.partial : CreditNoteType.full,
        reason: CreditNoteReason.returnedGoods,
        restoreInventory: restore,
        items: [
          const CreateCreditNoteItemParams(
            productId: 'huevo', invoiceItemId: 'it-huevo', description: 'Huevo',
            quantity: 2, unitPrice: 6000),
          if (!onlyEggs)
            const CreateCreditNoteItemParams(
              productId: 'sal', invoiceItemId: 'it-sal', description: 'Sal',
              quantity: 1, unitPrice: 1000),
        ],
      );

  test('devolución con presentación: 2 cajas x12 suman 24 unidades y la factura queda acreditada', () async {
    final result = await repo.createCreditNote(params());

    expect(result.isRight(), isTrue);
    expect(await stock('huevo'), 34); // 10 + 2 × 12
    final note = result.getOrElse(() => throw 'sin nota');
    expect(note.status, CreditNoteStatus.confirmed);
    expect(note.total, 12000);
    expect((await invoice()).status, IsarInvoiceStatus.partiallyCredited);
    expect(sync.ops.single['op'], 'create');
    expect(sync.ops.single['restoreInventory'], isTrue);
  });

  test('devolución completa deja la factura acreditada', () async {
    await repo.createCreditNote(params(onlyEggs: false));
    expect((await invoice()).status, IsarInvoiceStatus.credited);
    expect(await stock('sal'), 11);
  });

  test('si no se puede encolar no queda nota ni inventario devuelto', () async {
    sync.fail = true;
    final result = await repo.createCreditNote(params());

    expect(result.isLeft(), isTrue);
    expect(await isar.isarCreditNotes.count(), 0);
    expect(await stock('huevo'), 10);
  });

  test('borrador sin devolución: confirmar encola y aplica; anular otro encola', () async {
    final draft = (await repo.createCreditNote(params(restore: false)))
        .getOrElse(() => throw 'sin nota');
    expect(draft.status, CreditNoteStatus.draft);
    expect(await stock('huevo'), 10);

    final confirmed = await repo.confirmCreditNote(draft.id);
    expect(confirmed.isRight(), isTrue);
    expect(sync.ops.last['action'], 'confirm');
    expect((await invoice()).status, IsarInvoiceStatus.partiallyCredited);
    expect(await stock('huevo'), 10); // la nota no devuelve inventario

    final again = await repo.confirmCreditNote(draft.id);
    expect(again.isLeft(), isTrue); // ya no está en borrador

    final other = (await repo.createCreditNote(params(restore: false)))
        .getOrElse(() => throw 'sin nota');
    final cancelled = await repo.cancelCreditNote(other.id);
    expect(cancelled.isRight(), isTrue);
    expect(sync.ops.last['action'], 'cancel');
  });

  test('borrador con devolución pendiente: confirmar devuelve el inventario', () async {
    // Nota del servidor en borrador (p. ej. creada con internet sin confirmar).
    await isar.writeTxn(() => isar.isarCreditNotes.put(IsarCreditNote.create(
          serverId: 'nc-uuid',
          number: 'NC-1',
          date: DateTime(2026, 10, 25),
          type: IsarCreditNoteType.partial,
          reason: IsarCreditNoteReason.returnedGoods,
          status: IsarCreditNoteStatus.draft,
          subtotal: 6000,
          taxPercentage: 0,
          taxAmount: 0,
          total: 6000,
          restoreInventory: true,
          inventoryRestored: false,
          invoiceId: 'f1',
          customerId: 'c',
          createdById: 'u',
          itemsJson: jsonEncode([
            {'id': 'x', 'description': 'Huevo', 'quantity': 1, 'unitPrice': 6000,
             'subtotal': 6000, 'creditNoteId': 'nc-uuid', 'productId': 'huevo',
             'invoiceItemId': 'it-huevo', 'createdAt': '2026-10-25T00:00:00.000',
             'updatedAt': '2026-10-25T00:00:00.000'},
          ]),
          createdAt: DateTime(2026, 10, 25),
          updatedAt: DateTime(2026, 10, 25),
          isSynced: true,
        )));

    final result = await repo.confirmCreditNote('nc-uuid');

    expect(result.isRight(), isTrue);
    expect(await stock('huevo'), 22); // 10 + 1 × 12
    expect(sync.ops.single['action'], 'confirm');
    expect(sync.ops.single['entityId'], 'nc-uuid');
  });
}
