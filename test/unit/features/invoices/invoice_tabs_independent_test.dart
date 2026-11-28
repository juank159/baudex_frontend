import 'dart:async';

import 'package:baudex_desktop/app/core/errors/automatic_work.dart';
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/services/tenant_datetime_service.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_form_models.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/create_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/update_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_tabs_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../../helpers/test_isar.dart';

/// Reporte de una clienta: con varias pestañas de factura, la segunda decía
/// "Editar Factura" + "BORRADOR" y al facturar salía
/// "Error al actualizar factura — Factura no encontrada en ISAR: (un UUID)".
///
/// Causa: cada pestaña leía la factura a editar de `Get.parameters['id']`,
/// que es global y guarda el `id` de la última pantalla de detalle visitada
/// (producto, cliente, otra factura). Facturación queda viva debajo al ir a
/// otro módulo, así que al volver y abrir una pestaña nueva, esa pestaña
/// "editaba" una factura con el id de otra cosa.
class _FakeSync extends SyncService {
  _FakeSync() : super(null);

  @override
  // ignore: must_call_super
  Future<void> onInit() async {}

  @override
  Future<void> addOperation({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    required String organizationId,
    int priority = 0,
  }) async {}
}

/// Crear: solo se anota que se pidió (la venta en sí tiene sus pruebas).
class _RecordingCreate implements CreateInvoiceUseCase {
  final calls = <CreateInvoiceParams>[];

  @override
  Future<Either<Failure, Invoice>> call(CreateInvoiceParams params) async {
    calls.add(params);
    return const Left(CacheFailure('prueba: crear no se ejecuta'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Actualizar: pasa por el repositorio real sin internet (o por una respuesta
/// fija, para simular el servidor) y anota lo que respondió.
class _RecordingUpdate implements UpdateInvoiceUseCase {
  _RecordingUpdate(this._real);

  final UpdateInvoiceUseCase _real;
  final ids = <String>[];
  final errors = <String>[];
  Failure? serverAnswer;

  @override
  Future<Either<Failure, Invoice>> call(UpdateInvoiceParams params) async {
    ids.add(params.id);
    final result =
        serverAnswer != null ? Left<Failure, Invoice>(serverAnswer!) : await _real(params);
    result.fold((f) => errors.add(f.message), (_) {});
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _detailId = '0b6f6a52-2f1c-4c53-9a55-0d0c6f6a1b11'; // id de un producto visto
const _draftId = '7c1d2e3f-4a5b-4c6d-8e9f-0a1b2c3d4e5f'; // borrador real
const _customerId = '11111111-2222-4333-8444-555555555555';

void main() {
  late Isar isar;
  late InvoiceTabsController tabs;
  late _RecordingCreate create;
  late _RecordingUpdate update;

  setUpAll(tzdata.initializeTimeZones);

  final customer = Customer(
    id: _customerId,
    firstName: 'Ana',
    lastName: 'Ruiz',
    email: 'ana@x.com',
    documentType: DocumentType.cc,
    documentNumber: '123',
    status: CustomerStatus.active,
    creditLimit: 0,
    currentBalance: 0,
    paymentTerms: 0,
    totalPurchases: 0,
    totalOrders: 0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      tester.binding.scheduleFrame();
      await tester.pump(const Duration(seconds: 3));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
  }

  /// Abre la app como la usa la cajera: Facturación con una pestaña.
  Future<void> openInvoicing(WidgetTester tester) async {
    await tester.runAsync(() async {
      isar = await openTestIsar();
      await isar.writeTxn(() async {
        await isar.isarCustomers.put(IsarCustomer.create(
          serverId: _customerId,
          firstName: 'Ana',
          lastName: 'Ruiz',
          email: 'ana@x.com',
          documentType: IsarDocumentType.cc,
          documentNumber: '123',
          status: IsarCustomerStatus.active,
          creditLimit: 0,
          currentBalance: 0,
          paymentTerms: 0,
          totalPurchases: 0,
          totalOrders: 0,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          isSynced: true,
        ));
      });
    });
    addTearDown(() async {
      Get.reset();
      await tester.runAsync(() => closeTestIsar(isar));
    });

    Get.put<SyncService>(_FakeSync());
    final repo = InvoiceOfflineRepositorySimple();
    create = _RecordingCreate();
    update = _RecordingUpdate(UpdateInvoiceUseCase(repo));
    Get.put<TenantDateTimeService>(TenantDateTimeService());
    Get.put<CreateInvoiceUseCase>(create);
    Get.put<UpdateInvoiceUseCase>(update);
    Get.put<GetInvoiceByIdUseCase>(GetInvoiceByIdUseCase(repo));

    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SizedBox()),
        GetPage(name: '/invoices/tabs', page: () => const SizedBox()),
        GetPage(name: '/products/detail/:id', page: () => const SizedBox()),
      ],
    ));
    Get.toNamed('/invoices/tabs');
    await tester.pump(const Duration(seconds: 1));
    tabs = Get.put(InvoiceTabsController());
    await settle(tester);
  }

  /// La cajera mira el detalle de un producto (o cliente, o factura) y vuelve.
  Future<void> visitDetailAndReturn(WidgetTester tester) async {
    Get.toNamed('/products/detail/$_detailId');
    await tester.pump(const Duration(seconds: 1));
    expect(Get.parameters['id'], _detailId);
    Get.back();
    await tester.pump(const Duration(seconds: 1));
    expect(Get.currentRoute, '/invoices/tabs');
    expect(Get.parameters['id'], _detailId,
        reason: 'GetX no limpia el id al volver: por eso no se puede leer ahí');
  }

  void fill(InvoiceFormController c, String name) {
    c.selectCustomer(customer);
    c.addItem(InvoiceItemFormData(
      id: 'item-$name',
      description: name,
      quantity: 1,
      unitPrice: 5000,
    ));
  }

  /// Guarda como lo hace el botón. Los avisos de error se anotan en vez de
  /// dibujarse, para poder leerlos.
  Future<List<String>> save(WidgetTester tester, InvoiceFormController c) async {
    final log = BackgroundFailureLog.instance;
    final before = log.entries.length;
    var done = false;
    unawaited(
      AutomaticWork.run('prueba', c.saveInvoice).whenComplete(() => done = true),
    );
    // La base responde en tiempo real y la app sigue en el reloj de prueba.
    for (var i = 0; i < 200 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(done, isTrue, reason: 'el guardado no terminó');
    // Avisos de éxito (esos sí se dibujan): que salgan y venzan.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 3));
    }
    return log.entries.skip(before).map((e) => e.message).toList();
  }

  /// Abre el borrador real en una pestaña y espera a que cargue de la base
  /// (se sabe que cargó cuando aparece su cliente).
  Future<InvoiceFormController> openDraftTab(WidgetTester tester) async {
    final id = tabs.addNewTab(invoiceId: _draftId);
    final c = tabs.tabs.firstWhere((t) => t.id == id).controller;
    for (var i = 0; i < 10 && c.selectedCustomer?.id != _customerId; i++) {
      await settle(tester);
    }
    return c;
  }

  /// Borrador recién abierto, todavía sin productos. (Un borrador CON
  /// productos hoy no carga en el formulario: ver el informe del arreglo.)
  Future<void> putDraft(WidgetTester tester) => tester.runAsync(() async {
        await isar.writeTxn(() async {
          await isar.isarInvoices.put(IsarInvoice.create(
            serverId: _draftId,
            number: 'BORR-1',
            date: DateTime(2026, 11, 20),
            dueDate: DateTime(2026, 11, 20),
            status: IsarInvoiceStatus.draft,
            paymentMethod: IsarPaymentMethod.cash,
            subtotal: 0,
            taxPercentage: 0,
            taxAmount: 0,
            discountPercentage: 0,
            discountAmount: 0,
            total: 0,
            paidAmount: 0,
            balanceDue: 0,
            customerId: _customerId,
            createdAt: DateTime(2026, 11, 20),
            updatedAt: DateTime(2026, 11, 20),
            isSynced: true,
          ));
        });
      });

  group('reglas', () {
    test('una pestaña no toma la factura a editar de la ruta', () {
      expect(
        resolveInvoiceIdToEdit(readFromRoute: false, routeId: _detailId),
        isNull,
      );
      expect(
        resolveInvoiceIdToEdit(
            readFromRoute: false, explicitId: _draftId, routeId: _detailId),
        _draftId,
      );
      expect(resolveInvoiceIdToEdit(readFromRoute: false, explicitId: ''), isNull);
    });

    test('la pantalla de una sola factura sigue leyendo la ruta', () {
      expect(
        resolveInvoiceIdToEdit(readFromRoute: true, routeId: _draftId),
        _draftId,
      );
      expect(resolveInvoiceIdToEdit(readFromRoute: true), isNull);
      expect(resolveInvoiceIdToEdit(readFromRoute: true, routeId: ''), isNull);
    });

    test('solo "no está en este equipo" convierte la edición en factura nueva', () {
      expect(isInvoiceMissingFailure('Factura no encontrada en ISAR: $_draftId'), isTrue);
      expect(isInvoiceMissingFailure('Factura no encontrada en el equipo: x'), isTrue);
      // El servidor dijo que no: la factura puede seguir viva en el equipo.
      expect(isInvoiceMissingFailure('Factura no encontrada'), isFalse);
      expect(isInvoiceMissingFailure('Solicitud incorrecta: cliente inválido'), isFalse);
      expect(isInvoiceMissingFailure('Sin conexión'), isFalse);
    });
  });

  for (final count in [2, 3, 5]) {
    testWidgets(
        '$count pestañas tras ver un detalle: todas son factura nueva e independientes',
        (tester) async {
      await openInvoicing(tester);
      fill(tabs.tabs[0].controller, 'venta-1');
      await visitDetailAndReturn(tester);

      for (var i = 1; i < count; i++) {
        expect(tabs.addNewTab(), isNotEmpty);
      }
      await settle(tester);

      expect(tabs.tabs.length, count);
      for (final tab in tabs.tabs) {
        expect(tab.isNewInvoice, isTrue);
        expect(tab.controller.isEditMode, isFalse, reason: tab.title);
        expect(tab.controller.editingInvoiceId, isNull, reason: tab.title);
        expect(tab.controller.pageTitle, 'Punto de Venta');
        expect(tab.controller.saveButtonText, 'Procesar Venta');
      }
      // Lo digitado en la 1 sigue solo en la 1.
      expect(tabs.tabs[0].controller.invoiceItems.single.description, 'venta-1');
      for (final tab in tabs.tabs.skip(1)) {
        expect(tab.controller.invoiceItems, isEmpty);
      }
    });
  }

  testWidgets(
      'sin internet: procesar la pestaña 1 y luego la 2 crea dos facturas, nunca "actualiza"',
      (tester) async {
    await openInvoicing(tester);
    await visitDetailAndReturn(tester);
    tabs.addNewTab();
    await settle(tester);

    final first = tabs.tabs[0].controller;
    final second = tabs.tabs[1].controller;
    fill(first, 'venta-1');
    fill(second, 'venta-2');

    await save(tester, first);
    await save(tester, second);

    expect(update.ids, isEmpty,
        reason: 'antes: la pestaña 2 actualizaba $_detailId → ${update.errors}');
    expect(update.errors, isEmpty);
    expect(create.calls.length, 2);
    expect(create.calls[0].items.single.description, 'venta-1');
    expect(create.calls[1].items.single.description, 'venta-2');
  });

  testWidgets('la pestaña que ya vendió y se cierra no afecta a las demás',
      (tester) async {
    await openInvoicing(tester);
    await visitDetailAndReturn(tester);
    tabs.addNewTab();
    tabs.addNewTab();
    await settle(tester);
    fill(tabs.tabs[1].controller, 'venta-2');
    fill(tabs.tabs[2].controller, 'venta-3');

    tabs.closeTab(tabs.tabs[0].id, forceClose: true);
    await settle(tester);
    tabs.addNewTab();
    await settle(tester);

    expect(tabs.tabs.length, 3);
    expect(tabs.tabs[0].controller.invoiceItems.single.description, 'venta-2');
    expect(tabs.tabs[1].controller.invoiceItems.single.description, 'venta-3');
    expect(tabs.tabs.every((t) => !t.controller.isEditMode), isTrue);
  });

  testWidgets('un borrador real abierto en una pestaña se edita y se actualiza',
      (tester) async {
    await openInvoicing(tester);
    await putDraft(tester);
    await visitDetailAndReturn(tester);

    final draftTab = await openDraftTab(tester);
    tabs.addNewTab();
    await settle(tester);

    expect(draftTab.isEditMode, isTrue);
    expect(draftTab.editingInvoiceId, _draftId);
    expect(draftTab.pageTitle, 'Editar Factura');
    expect(draftTab.selectedCustomer?.id, _customerId);
    draftTab.addItem(const InvoiceItemFormData(
      id: 'nuevo',
      description: 'Arroz',
      quantity: 2,
      unitPrice: 4000,
    ));
    // Las otras dos siguen siendo facturas nuevas.
    expect(tabs.tabs[0].controller.isEditMode, isFalse);
    expect(tabs.tabs[2].controller.isEditMode, isFalse);

    await save(tester, draftTab);

    expect(update.ids, [_draftId]);
    expect(update.errors, isEmpty);
    expect(create.calls, isEmpty);
  });

  testWidgets(
      'el borrador que se editaba ya no está en el equipo: aviso claro y lo digitado se conserva',
      (tester) async {
    await openInvoicing(tester);
    await putDraft(tester);
    final draftTab = await openDraftTab(tester);
    expect(draftTab.isEditMode, isTrue);
    draftTab.addItem(const InvoiceItemFormData(
      id: 'nuevo',
      description: 'Lo que digitó la cajera',
      quantity: 3,
      unitPrice: 1000,
    ));

    // Se procesó o eliminó desde otra pestaña / otro equipo.
    await tester.runAsync(() => isar.writeTxn(
        () => isar.isarInvoices.filter().serverIdEqualTo(_draftId).deleteAll()));

    final notices = await save(tester, draftTab);

    expect(update.errors.single, 'Factura no encontrada en ISAR: $_draftId');
    expect(notices.single, contains('Este borrador ya no existe'));
    expect(notices.single, contains('Lo que digitó sigue en pantalla'));
    expect(notices.single, isNot(contains('ISAR')));
    expect(draftTab.invoiceItems.single.description, 'Lo que digitó la cajera');
    expect(draftTab.selectedCustomer?.id, _customerId);
    expect(draftTab.isEditMode, isFalse);
    expect(draftTab.pageTitle, 'Punto de Venta');

    // Volver a procesar la guarda como factura nueva, con todo lo digitado.
    await save(tester, draftTab);
    expect(update.ids.length, 1);
    expect(create.calls.single.items.single.description, 'Lo que digitó la cajera');
    expect(create.calls.single.customerId, _customerId);
  });

  testWidgets(
      'con internet: si el servidor rechaza la edición, se sigue editando la misma factura',
      (tester) async {
    await openInvoicing(tester);
    await putDraft(tester);
    final draftTab = await openDraftTab(tester);
    draftTab.addItem(const InvoiceItemFormData(
      id: 'nuevo',
      description: 'Arroz',
      quantity: 1,
      unitPrice: 4000,
    ));
    update.serverAnswer = const ServerFailure('Factura no encontrada');

    final notices = await save(tester, draftTab);

    expect(notices.single, contains('Error al actualizar factura'));
    expect(draftTab.isEditMode, isTrue);
    expect(draftTab.editingInvoiceId, _draftId);
    expect(draftTab.invoiceItems.single.description, 'Arroz');
    expect(create.calls, isEmpty);
  });
}
