import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/bank_accounts/data/models/isar/isar_bank_account.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/invoices/data/invoice_list_query_plan.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

/// La lista de facturas se lee por páginas usando índices de la base. Estas
/// pruebas comparan cada página contra la respuesta "a mano" (todas las
/// facturas filtradas y ordenadas en memoria): mismo orden, sin huecos ni
/// repetidas, mismo total.
void main() {
  group('regla: qué índice usa la lista', () {
    test('por defecto (createdAt o desconocido) recorre el índice de creación', () {
      expect(pickInvoiceListIndex(sortBy: 'createdAt'), InvoiceListIndex.createdAt);
      expect(pickInvoiceListIndex(sortBy: 'loquesea'), InvoiceListIndex.createdAt);
      expect(invoiceIndexGivesOrder(InvoiceListIndex.createdAt), isTrue);
    });
    test('fecha y vencimiento usan su propio índice ya ordenado', () {
      expect(pickInvoiceListIndex(sortBy: 'date'), InvoiceListIndex.date);
      expect(pickInvoiceListIndex(sortBy: 'dueDate'), InvoiceListIndex.dueDate);
    });
    test('número y total no tienen índice ordenable: se ordena todo', () {
      expect(pickInvoiceListIndex(sortBy: 'number'), InvoiceListIndex.fullScan);
      expect(pickInvoiceListIndex(sortBy: 'total'), InvoiceListIndex.fullScan);
      expect(invoiceIndexGivesOrder(InvoiceListIndex.fullScan), isFalse);
    });
    test('un rango de fechas o un cliente acotan primero y luego se ordena', () {
      expect(pickInvoiceListIndex(sortBy: 'createdAt', hasDateRange: true),
          InvoiceListIndex.dateRange);
      expect(pickInvoiceListIndex(sortBy: 'date', hasCustomer: true),
          InvoiceListIndex.customer);
      expect(invoiceIndexGivesOrder(InvoiceListIndex.dateRange), isFalse);
      expect(invoiceIndexGivesOrder(InvoiceListIndex.customer), isFalse);
    });
    test('un estado con el orden por defecto: su índice ya viene en orden', () {
      expect(pickInvoiceListIndex(sortBy: 'createdAt', hasStatus: true),
          InvoiceListIndex.status);
      expect(invoiceIndexGivesOrder(InvoiceListIndex.status), isTrue);
      // Varios estados ("Pendientes" = pendientes + abonadas): se juntan y
      // se ordenan (son pocas).
      expect(invoiceIndexGivesOrder(InvoiceListIndex.status, statusCount: 2),
          isFalse);
      // Con otro orden, el índice de estado no ayuda al orden.
      expect(pickInvoiceListIndex(sortBy: 'total', hasStatus: true),
          InvoiceListIndex.fullScan);
      expect(pickInvoiceListIndex(sortBy: 'date', hasStatus: true),
          InvoiceListIndex.date);
      // Fechas o cliente acotan primero.
      expect(
          pickInvoiceListIndex(
              sortBy: 'createdAt', hasStatus: true, hasDateRange: true),
          InvoiceListIndex.dateRange);
    });
    test('cliente con el orden por defecto: su índice ya viene en orden', () {
      expect(
          invoiceIndexGivesOrder(InvoiceListIndex.customer,
              createdAtSort: true),
          isTrue);
      expect(isCreatedAtSort('createdAt'), isTrue);
      expect(isCreatedAtSort('loquesea'), isTrue);
      expect(isCreatedAtSort('total'), isFalse);
    });
    test('datos de paginación', () {
      final a = invoicePageInfo(totalItems: 61, page: 1, limit: 30);
      expect(a.totalPages, 3);
      expect(a.hasNextPage, isTrue);
      expect(a.hasPreviousPage, isFalse);
      final b = invoicePageInfo(totalItems: 60, page: 2, limit: 30);
      expect(b.totalPages, 2);
      expect(b.hasNextPage, isFalse);
      expect(b.hasPreviousPage, isTrue);
      expect(invoicePageInfo(totalItems: 0, page: 1, limit: 30).totalPages, 0);
    });
  });

  group('consulta paginada en la base local', () {
    late Isar isar;
    late InvoiceOfflineRepositorySimple repo;
    late List<IsarInvoice> all;
    const customers = 80; // más de 50: la búsqueda amplia usa su camino aparte

    setUpAll(() async {
      final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
          'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
      await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
      final dir = await Directory.systemTemp.createTemp('isar_invoice_paged');
      isar = await Isar.open(
        [IsarInvoiceSchema, IsarCustomerSchema, IsarBankAccountSchema],
        directory: dir.path,
      );
      IsarDatabase.debugSetDatabase(isar);
      repo = InvoiceOfflineRepositorySimple();

      final base = DateTime(2026, 1, 1, 8);
      const statuses = [
        IsarInvoiceStatus.paid,
        IsarInvoiceStatus.pending,
        IsarInvoiceStatus.partiallyPaid,
        IsarInvoiceStatus.cancelled,
        IsarInvoiceStatus.draft,
      ];
      final invoices = <IsarInvoice>[
        for (var i = 0; i < 250; i++)
          IsarInvoice.create(
            serverId: 'i$i',
            number: 'FV-${i.toString().padLeft(4, '0')}',
            // Creación y fecha de factura en órdenes distintos (la fecha
            // va al revés cada 7) para que el orden por cada una se note.
            date: base.add(Duration(hours: (i * 7) % 250)),
            dueDate: base.add(Duration(hours: (i * 13) % 250 + 500)),
            status: statuses[i % statuses.length],
            paymentMethod:
                i % 4 == 0 ? IsarPaymentMethod.credit : IsarPaymentMethod.cash,
            subtotal: 1000.0 + (i * 37) % 250,
            taxPercentage: 0,
            taxAmount: 0,
            discountPercentage: 0,
            discountAmount: 0,
            total: 1000.0 + (i * 37) % 250,
            paidAmount: 0,
            balanceDue: 0,
            customerId: 'c${i % customers}',
            createdAt: base.add(Duration(minutes: i)),
            updatedAt: base.add(Duration(minutes: i)),
            // Algunas borradas: nunca aparecen ni cuentan.
            deletedAt: i % 23 == 0 ? base : null,
            isSynced: true,
          ),
      ];
      // Un cliente cuyo nombre empieza igual que un número de factura: su
      // factura FV-9001 coincide por número Y por cliente (no debe salir
      // repetida); la ZZ-1 solo por cliente. Las más viejas de todas.
      for (final (n, number) in [(0, 'FV-9001'), (1, 'ZZ-1')]) {
        invoices.add(IsarInvoice.create(
          serverId: 'x$n',
          number: number,
          date: base.subtract(Duration(days: 2, minutes: n)),
          dueDate: base.add(const Duration(days: 30)),
          status: IsarInvoiceStatus.paid,
          paymentMethod: IsarPaymentMethod.cash,
          subtotal: 5000,
          taxPercentage: 0,
          taxAmount: 0,
          discountPercentage: 0,
          discountAmount: 0,
          total: 5000,
          paidAmount: 5000,
          balanceDue: 0,
          customerId: 'cx',
          createdAt: base.subtract(Duration(days: 2, minutes: n)),
          updatedAt: base,
          isSynced: true,
        ));
      }
      await isar.writeTxn(() async {
        await isar.isarInvoices.putAll(invoices);
        await isar.isarCustomers.put(IsarCustomer.create(
          serverId: 'cx',
          firstName: 'FV-9 Tienda',
          lastName: 'Gomez',
          email: 'cx@x.com',
          documentType: IsarDocumentType.cc,
          documentNumber: '999',
          status: IsarCustomerStatus.active,
          creditLimit: 0,
          currentBalance: 0,
          paymentTerms: 30,
          totalPurchases: 0,
          totalOrders: 0,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          isSynced: true,
        ));
        await isar.isarCustomers.putAll([
          for (var c = 0; c < customers; c++)
            IsarCustomer.create(
              serverId: 'c$c',
              firstName: c.isEven ? 'Ana$c' : 'Luis$c',
              lastName: 'Perez',
              email: 'c$c@x.com',
              documentType: IsarDocumentType.cc,
              documentNumber: '$c',
              status: IsarCustomerStatus.active,
              creditLimit: 0,
              currentBalance: 0,
              paymentTerms: 30,
              totalPurchases: 0,
              totalOrders: 0,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              isSynced: true,
            ),
        ]);
      });
      all = await isar.isarInvoices.where().findAll();
    });

    tearDownAll(() async {
      IsarDatabase.debugSetDatabase(null);
      await isar.close(deleteFromDisk: true);
    });

    /// Lee TODAS las páginas y devuelve los ids en orden + el total.
    Future<(List<String>, int)> readAllPages({
      int limit = 30,
      String sortBy = 'createdAt',
      String sortOrder = 'DESC',
      InvoiceStatus? status,
      List<InvoiceStatus>? statuses,
      String? customerId,
      String? search,
      DateTime? start,
      DateTime? end,
    }) async {
      final ids = <String>[];
      var page = 1;
      var total = -1;
      while (true) {
        final r = (await repo.getInvoices(
          page: page,
          limit: limit,
          sortBy: sortBy,
          sortOrder: sortOrder,
          status: status,
          statuses: statuses,
          customerId: customerId,
          search: search,
          startDate: start,
          endDate: end,
        ))
            .getOrElse(() => throw 'falló');
        if (total == -1) total = r.meta.totalItems;
        expect(r.meta.totalItems, total, reason: 'el total no cambia entre páginas');
        expect(r.data.length, lessThanOrEqualTo(limit));
        ids.addAll(r.data.map((i) => i.id));
        if (!r.meta.hasNextPage) break;
        page++;
        expect(page, lessThan(100));
      }
      return (ids, total);
    }

    /// Respuesta esperada calculada en memoria.
    List<String> expected({
      String sortBy = 'createdAt',
      bool desc = true,
      bool Function(IsarInvoice)? where,
    }) {
      final list = all
          .where((i) => i.deletedAt == null && (where?.call(i) ?? true))
          .toList();
      Comparable key(IsarInvoice i) => switch (sortBy) {
            'date' => i.date,
            'dueDate' => i.dueDate,
            'number' => i.number,
            'total' => i.total,
            _ => i.createdAt,
          };
      list.sort((a, b) {
        final c = key(a).compareTo(key(b));
        // Desempate estable por id interno, como la base.
        return c != 0 ? c : a.id.compareTo(b.id);
      });
      final ids = list.map((i) => i.serverId).toList();
      return desc ? ids.reversed.toList() : ids;
    }

    test('por defecto: más nuevas primero, páginas sin huecos ni repetidas', () async {
      final (ids, total) = await readAllPages();
      final exp = expected();
      expect(ids, exp);
      expect(total, exp.length);
      expect(ids.toSet().length, ids.length);
      expect(ids, isNot(contains('i0')), reason: 'i0 está borrada');
    });

    test('la primera página son las 30 más recientes', () async {
      final r = (await repo.getInvoices(page: 1, limit: 30, sortOrder: 'DESC'))
          .getOrElse(() => throw 'falló');
      expect(r.data.map((i) => i.id), expected().take(30));
      expect(r.meta.hasNextPage, isTrue);
      expect(r.meta.totalPages, (expected().length / 30).ceil());
      // El cliente llega resuelto (nombre en la fila).
      expect(r.data.first.customer, isNotNull);
    });

    test('ascendente y por fecha de factura / vencimiento (índices)', () async {
      expect((await readAllPages(sortOrder: 'ASC')).$1, expected(desc: false));
      expect((await readAllPages(sortBy: 'date')).$1, expected(sortBy: 'date'));
      expect((await readAllPages(sortBy: 'dueDate', sortOrder: 'ASC')).$1,
          expected(sortBy: 'dueDate', desc: false));
    });

    test('por número y por total (sin índice ordenable)', () async {
      expect((await readAllPages(sortBy: 'number')).$1, expected(sortBy: 'number'));
      final byTotal = (await readAllPages(sortBy: 'total', sortOrder: 'ASC')).$1;
      final exp = expected(sortBy: 'total', desc: false);
      // Totales repetidos: se compara el orden de los montos, no el desempate.
      double totalOf(String id) => all.firstWhere((i) => i.serverId == id).total;
      expect(byTotal.map(totalOf), exp.map(totalOf));
      expect(byTotal.toSet(), exp.toSet());
    });

    test('filtro de estado paginado', () async {
      final (ids, total) = await readAllPages(status: InvoiceStatus.pending);
      final exp = expected(where: (i) => i.status == IsarInvoiceStatus.pending);
      expect(ids, exp);
      expect(total, exp.length);
    });

    test('rango de fechas inclusivo, ordenado por creación', () async {
      final start = DateTime(2026, 1, 3, 8);
      final end = DateTime(2026, 1, 6, 8);
      final (ids, total) = await readAllPages(start: start, end: end, limit: 7);
      final exp = expected(
          where: (i) => !i.date.isBefore(start) && !i.date.isAfter(end));
      expect(ids, exp);
      expect(total, exp.length);
      // Solo inicio.
      expect((await readAllPages(start: start)).$1,
          expected(where: (i) => !i.date.isBefore(start)));
    });

    test('por cliente, ordenado por fecha de factura', () async {
      final (ids, _) = await readAllPages(customerId: 'c3', sortBy: 'date', limit: 2);
      expect(ids, expected(sortBy: 'date', where: (i) => i.customerId == 'c3'));
    });

    test('búsqueda por número', () async {
      final (ids, total) = await readAllPages(search: 'fv-01');
      expect(ids, expected(where: (i) => i.number.startsWith('FV-01')));
      expect(total, ids.length);
    });

    test('búsqueda que coincide con pocos clientes', () async {
      final (ids, _) = await readAllPages(search: 'Ana12');
      expect(ids, expected(where: (i) => i.customerId == 'c12'));
    });

    test('búsqueda amplia (más de 50 clientes): mismo resultado, paginado', () async {
      // "Perez" coincide con los 80 clientes: todas las no borradas.
      // (El cliente "cx" es Gomez: sus facturas no entran.)
      bool perez(IsarInvoice i) => i.customerId != 'cx';
      final (ids, total) = await readAllPages(search: 'perez', limit: 17);
      expect(ids, expected(where: perez));
      expect(total, expected(where: perez).length);
      // "Ana" coincide con 40 clientes (camino normal) y "e" con todos
      // (camino amplio, por "Perez"). Combinado con estado.
      final (withStatus, _) =
          await readAllPages(search: 'e', status: InvoiceStatus.paid);
      expect(withStatus,
          expected(where: (i) => i.status == IsarInvoiceStatus.paid));
      final (ana, _) = await readAllPages(search: 'Ana');
      expect(
          ana,
          expected(where: (i) {
            final c = int.tryParse(i.customerId.substring(1));
            return c != null && c.isEven;
          }));
    });

    test('"Pendientes" = pendientes + abonadas: TODAS, por índice de estado',
        () async {
      bool open(IsarInvoice i) =>
          i.status == IsarInvoiceStatus.pending ||
          i.status == IsarInvoiceStatus.partiallyPaid;
      final (ids, total) = await readAllPages(
        statuses: const [InvoiceStatus.pending, InvoiceStatus.partiallyPaid],
        limit: 7,
      );
      expect(ids, expected(where: open));
      expect(total, all.where((i) => i.deletedAt == null && open(i)).length);
      // Ascendente y con otro orden: mismo conjunto.
      final (asc, _) = await readAllPages(
        statuses: const [InvoiceStatus.pending, InvoiceStatus.partiallyPaid],
        sortOrder: 'ASC',
      );
      expect(asc, expected(where: open, desc: false));
      final (byTotal, _) = await readAllPages(
        statuses: const [InvoiceStatus.pending, InvoiceStatus.partiallyPaid],
        sortBy: 'total',
      );
      expect(byTotal.toSet(), expected(where: open).toSet());
    });

    test('un estado, ascendente y descendente, por su índice', () async {
      for (final desc in [true, false]) {
        final (ids, total) = await readAllPages(
          status: InvoiceStatus.cancelled,
          sortOrder: desc ? 'DESC' : 'ASC',
          limit: 9,
        );
        expect(
            ids,
            expected(
                desc: desc,
                where: (i) => i.status == IsarInvoiceStatus.cancelled));
        expect(total, ids.length);
      }
    });

    test('por cliente con el orden por defecto (índice cliente + creación)',
        () async {
      for (final desc in [true, false]) {
        final (ids, total) = await readAllPages(
            customerId: 'c3', limit: 2, sortOrder: desc ? 'DESC' : 'ASC');
        expect(ids,
            expected(desc: desc, where: (i) => i.customerId == 'c3'));
        expect(total, ids.length);
      }
    });

    test('búsqueda por comienzo del número: sin importar mayúsculas', () async {
      final (lower, _) = await readAllPages(search: 'fv-002');
      final (upper, _) = await readAllPages(search: 'FV-002', limit: 3);
      final want = expected(where: (i) => i.number.startsWith('FV-002'));
      expect(lower, want);
      expect(upper, want);
      expect(want, hasLength(greaterThan(5)));
    });

    test('búsqueda por una parte del número que no es el comienzo', () async {
      final (ids, _) = await readAllPages(search: '-012');
      expect(ids, expected(where: (i) => i.number.contains('-012')));
      expect(ids, isNotEmpty);
    });

    test('coincide por número y por cliente a la vez: no sale repetida',
        () async {
      final (ids, total) = await readAllPages(search: 'fv-9');
      expect(ids, ['x0', 'x1']);
      expect(total, 2);
      // Con filtro de estado encima.
      final (paid, _) =
          await readAllPages(search: 'FV-9', status: InvoiceStatus.paid);
      expect(paid, ['x0', 'x1']);
      final (none, _) =
          await readAllPages(search: 'FV-9', status: InvoiceStatus.draft);
      expect(none, isEmpty);
    });

    test('vencidas: pendientes con vencimiento pasado, por índice de estado',
        () async {
      final overdue = (await repo.getOverdueInvoices())
          .getOrElse(() => throw 'falló')
          .map((i) => i.id)
          .toSet();
      final now = DateTime.now();
      final want = all
          .where((i) =>
              i.deletedAt == null &&
              i.status == IsarInvoiceStatus.pending &&
              i.dueDate.isBefore(now))
          .map((i) => i.serverId)
          .toSet();
      expect(overdue.length, want.length > 50 ? 50 : want.length);
      expect(want.containsAll(overdue), isTrue);
    });

    test('página más allá del final: vacía, sin errores', () async {
      final r = (await repo.getInvoices(page: 99, limit: 30))
          .getOrElse(() => throw 'falló');
      expect(r.data, isEmpty);
      expect(r.meta.hasNextPage, isFalse);
    });

    test('estadísticas con índices: mismos conteos que en memoria', () async {
      final s = (await repo.getInvoiceStats()).getOrElse(() => throw 'falló');
      final live = all.where((i) => i.deletedAt == null).toList();
      int n(IsarInvoiceStatus st) => live.where((i) => i.status == st).length;
      expect(s.total, live.length);
      expect(s.paid, n(IsarInvoiceStatus.paid));
      expect(s.pending, n(IsarInvoiceStatus.pending));
      expect(s.cancelled, n(IsarInvoiceStatus.cancelled));
      expect(s.draft, n(IsarInvoiceStatus.draft));
      expect(s.partiallyPaid, n(IsarInvoiceStatus.partiallyPaid));
    });
  });
}
