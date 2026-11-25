import 'dart:async';

import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:baudex_desktop/features/invoices/domain/services/invoice_history_lookup.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/cancel_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/confirm_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/delete_invoice_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoice_by_id_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/get_invoices_usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/usecases/search_invoices_usecase.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_list_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

typedef _Page = Either<Failure, PaginatedResult<Invoice>>;

class _Repo extends Mock implements InvoiceRepository {}

/// Caso de uso de mentiras: cada prueba decide qué responde y cuándo.
class _FakeGetInvoices implements GetInvoicesUseCase {
  Future<_Page> Function(GetInvoicesParams) handler = (_) async => page([]);
  final calls = <GetInvoicesParams>[];

  @override
  InvoiceRepository get repository => throw UnimplementedError();

  @override
  Future<_Page> call(GetInvoicesParams params) {
    calls.add(params);
    return handler(params);
  }
}

class _FakeHistory implements InvoiceHistoryLookup {
  bool downloading = true;
  final serverCalls = <GetInvoicesParams>[];
  Future<_Page> Function(GetInvoicesParams) server = (_) async => page([]);

  @override
  Future<bool> isHistoryDownloading() async => downloading;

  @override
  Future<_Page> getInvoicesFromServer(GetInvoicesParams params) {
    serverCalls.add(params);
    return server(params);
  }
}

Invoice invoice(String id, IsarInvoiceStatus status) => IsarInvoice.create(
      serverId: id,
      number: 'FV-$id',
      date: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 2, 1),
      status: status,
      paymentMethod: IsarPaymentMethod.cash,
      subtotal: 1000,
      taxPercentage: 0,
      taxAmount: 0,
      discountPercentage: 0,
      discountAmount: 0,
      total: 1000,
      paidAmount: 0,
      balanceDue: 1000,
      customerId: 'c1',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      isSynced: true,
    ).toEntity();

_Page page(List<Invoice> data, {bool hasNext = false}) => Right(PaginatedResult(
      data: data,
      meta: PaginationMeta(
        page: 1,
        limit: 30,
        totalItems: data.length,
        totalPages: hasNext ? 2 : 1,
        hasNextPage: hasNext,
        hasPreviousPage: false,
      ),
    ));

/// La lista de facturas atiende SIEMPRE la última búsqueda o filtro pedido.
/// Antes, lo que llegaba mientras otra carga esperaba se descartaba: la
/// pantalla quedaba con "Anuladas" marcado, 0 filas y el total de "Pagadas".
void main() {
  late _FakeGetInvoices getInvoices;
  late _FakeHistory history;

  InvoiceListController open({bool withHistory = true}) {
    final repo = _Repo();
    return Get.put(InvoiceListController(
      getInvoicesUseCase: getInvoices,
      searchInvoicesUseCase: SearchInvoicesUseCase(repo),
      deleteInvoiceUseCase: DeleteInvoiceUseCase(repo),
      confirmInvoiceUseCase: ConfirmInvoiceUseCase(repo),
      cancelInvoiceUseCase: CancelInvoiceUseCase(repo),
      getInvoiceByIdUseCase: GetInvoiceByIdUseCase(repo),
      historyLookup: withHistory ? history : null,
    ));
  }

  Future<void> settle([int ms = 20]) =>
      Future.delayed(Duration(milliseconds: ms));

  setUp(() {
    Get.testMode = true;
    InvoiceListController.invalidateCache();
    getInvoices = _FakeGetInvoices();
    history = _FakeHistory();
  });
  tearDown(Get.reset);

  final paid = [invoice('p1', IsarInvoiceStatus.paid), invoice('p2', IsarInvoiceStatus.paid)];
  final cancelled = [invoice('a1', IsarInvoiceStatus.cancelled)];

  test('dos filtros seguidos: queda el último, aunque el primero llegue después',
      () async {
    final slowPaid = Completer<_Page>();
    getInvoices.handler = (p) {
      if (p.status == InvoiceStatus.paid) return slowPaid.future;
      if (p.status == InvoiceStatus.cancelled) return Future.value(page(cancelled));
      return Future.value(page([...paid, ...cancelled]));
    };
    final c = open();
    await settle();

    c.filterByStatus(InvoiceStatus.paid);
    await settle(1);
    expect(c.isLoading, isTrue);
    c.filterByStatus(InvoiceStatus.cancelled);
    await settle();

    expect(c.filteredInvoices.map((i) => i.id), ['a1']);
    expect(c.totalItems, 1);
    expect(c.isLoading, isFalse, reason: 'la última ya respondió');

    // La respuesta vieja llega tarde: no pisa la lista ni el total.
    slowPaid.complete(page(paid));
    await settle();
    expect(c.filteredInvoices.map((i) => i.id), ['a1']);
    expect(c.totalItems, 1);
    expect(c.isLoading, isFalse);
  });

  test('la respuesta vieja no apaga el "cargando" de la nueva', () async {
    final first = Completer<_Page>();
    final second = Completer<_Page>();
    getInvoices.handler = (p) {
      if (p.status == InvoiceStatus.paid) return first.future;
      if (p.status == InvoiceStatus.cancelled) return second.future;
      return Future.value(page([]));
    };
    final c = open();
    await settle();
    c.filterByStatus(InvoiceStatus.paid);
    c.filterByStatus(InvoiceStatus.cancelled);
    first.complete(page(paid));
    await settle();
    expect(c.isLoading, isTrue, reason: 'la de "Anuladas" sigue en camino');
    expect(c.filteredInvoices, isEmpty);
    second.complete(page(cancelled));
    await settle();
    expect(c.isLoading, isFalse);
    expect(c.filteredInvoices.map((i) => i.id), ['a1']);
  });

  test('buscar mientras la pantalla todavía abre: la búsqueda se atiende',
      () async {
    final slowOpen = Completer<_Page>();
    getInvoices.handler = (p) => p.search == null
        ? slowOpen.future
        : Future.value(page([invoice('b1', IsarInvoiceStatus.paid)]));
    final c = open();
    await settle(1);
    c.searchController.text = 'FV-b1';
    await settle(600); // pausa de teclado de 500 ms
    expect(getInvoices.calls.last.search, 'FV-b1');
    expect(c.filteredInvoices.map((i) => i.id), ['b1']);
    slowOpen.complete(page(paid));
    await settle();
    expect(c.filteredInvoices.map((i) => i.id), ['b1']);
    expect(c.isLoading, isFalse);
  });

  test('"Pendientes" pide pendientes y abonadas a la base, en una sola consulta',
      () async {
    final open_ = [
      invoice('n1', IsarInvoiceStatus.pending),
      invoice('n2', IsarInvoiceStatus.partiallyPaid),
    ];
    getInvoices.handler = (p) async => page(
        p.statuses == null ? [...paid, ...open_] : open_,
        hasNext: p.statuses == null);
    final c = open();
    await settle();
    final before = getInvoices.calls.length;
    c.filterByStatus(InvoiceStatus.pending);
    await settle();
    final asked = getInvoices.calls.sublist(before);
    expect(asked, hasLength(1), reason: 'sin traer páginas de más');
    expect(asked.single.status, isNull);
    expect(asked.single.statuses,
        [InvoiceStatus.pending, InvoiceStatus.partiallyPaid]);
    expect(c.filteredInvoices.map((i) => i.id), ['n1', 'n2']);
    // Otro estado va como siempre: uno solo.
    c.filterByStatus(InvoiceStatus.cancelled);
    await settle();
    expect(getInvoices.calls.last.status, InvoiceStatus.cancelled);
    expect(getInvoices.calls.last.statuses, isNull);
  });

  group('historial todavía bajando', () {
    test('la pantalla lo sabe (aviso) y deja de avisar al terminar', () async {
      final c = open();
      await settle();
      expect(c.isHistoryDownloading, isTrue);
      history.downloading = false;
      await c.loadInvoices(forceRefresh: true);
      await settle();
      expect(c.isHistoryDownloading, isFalse);
    });

    test('búsqueda sin resultados: no bloquea, pregunta al servidor por detrás y agrega lo que llega',
        () async {
      final server = Completer<_Page>();
      history.server = (_) => server.future;
      getInvoices.handler =
          (p) async => page(p.search == null ? paid : const []);
      final c = open();
      await settle();
      c.searchController.text = 'FV-VIEJA';
      await settle(600);

      // Ya respondió con lo del equipo: nada, y sin "cargando".
      expect(c.isLoading, isFalse);
      expect(c.filteredInvoices, isEmpty);
      expect(c.isSearchingServer, isTrue);
      expect(history.serverCalls.single.search, 'FV-VIEJA');

      server.complete(page([invoice('v1', IsarInvoiceStatus.paid)]));
      await settle();
      expect(c.filteredInvoices.map((i) => i.id), ['v1']);
      expect(c.isSearchingServer, isFalse);
    });

    test('si mientras tanto se busca otra cosa, lo del servidor no se mezcla',
        () async {
      final server = Completer<_Page>();
      history.server = (p) =>
          p.search == 'FV-VIEJA' ? server.future : Future.value(page([]));
      getInvoices.handler = (p) async => page(p.search == 'FV-p1'
          ? [paid.first]
          : (p.search == null ? paid : const []));
      final c = open();
      await settle();
      c.searchController.text = 'FV-VIEJA';
      await settle(600);
      c.searchController.text = 'FV-p1';
      await settle(600);
      expect(c.filteredInvoices.map((i) => i.id), ['p1']);
      server.complete(page([invoice('v1', IsarInvoiceStatus.paid)]));
      await settle();
      expect(c.filteredInvoices.map((i) => i.id), ['p1']);
      expect(c.isSearchingServer, isFalse);
    });

    test('con resultados en el equipo, o sin búsqueda, no se llama al servidor',
        () async {
      getInvoices.handler = (p) async =>
          page(p.status == InvoiceStatus.cancelled ? cancelled : paid);
      final c = open();
      await settle();
      c.searchController.text = 'FV-p';
      await settle(600);
      c.filterByStatus(InvoiceStatus.cancelled);
      await settle();
      expect(history.serverCalls, isEmpty);
    });

    test('servidor caído o sin internet: queda "sin resultados", sin error',
        () async {
      history.server =
          (_) async => const Left(ConnectionFailure('Sin conexión a internet'));
      getInvoices.handler =
          (p) async => page(p.search == null ? paid : const []);
      final c = open();
      await settle();
      c.searchController.text = 'FV-NO';
      await settle(600);
      expect(c.filteredInvoices, isEmpty);
      expect(c.isSearchingServer, isFalse);
      expect(c.isLoading, isFalse);
    });
  });

  test('historial completo: búsqueda sin resultados no va al servidor', () async {
    history.downloading = false;
    getInvoices.handler = (p) async => page(p.search == null ? paid : const []);
    final c = open();
    await settle();
    c.searchController.text = 'FV-NO';
    await settle(600);
    expect(c.filteredInvoices, isEmpty);
    expect(history.serverCalls, isEmpty);
    expect(c.isHistoryDownloading, isFalse);
  });
}
