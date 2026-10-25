import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/full_sync_service.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../../../helpers/test_isar.dart';

/// Limpieza al final de una descarga completa: solo se quitan copias que no
/// llegaron Y que no cambiaron desde que empezó la descarga. Un cliente
/// creado mientras se descargaba no debe desaparecer.
void main() {
  late Isar isar;

  setUp(() async => isar = await openTestIsar());
  tearDown(() => closeTestIsar(isar));

  IsarCustomer customer(String id, DateTime updated) => IsarCustomer.create(
        serverId: id,
        firstName: id,
        lastName: 'x',
        email: '$id@x.com',
        documentType: IsarDocumentType.cc,
        documentNumber: id,
        status: IsarCustomerStatus.active,
        creditLimit: 0,
        currentBalance: 0,
        paymentTerms: 30,
        totalPurchases: 0,
        totalOrders: 0,
        createdAt: updated,
        updatedAt: updated,
        isSynced: true,
      );

  test('conserva lo creado durante la descarga; quita lo viejo que ya no existe', () async {
    final cutoff = DateTime.utc(2026, 10, 25, 12);
    const viejo = '11111111-1111-1111-1111-111111111111';
    const nuevo = '22222222-2222-2222-2222-222222222222';
    await isar.writeTxn(() => isar.isarCustomers.putAll([
          customer(viejo, DateTime.utc(2026, 10, 1)),
          customer(nuevo, DateTime.utc(2026, 10, 25, 12, 0, 30)),
        ]));

    final stale = await FullSyncService.debugUnchangedSince(
      isar.isarCustomers,
      [viejo, nuevo],
      cutoff,
    );

    expect(stale, [viejo]);
  });

  test('ante un id que no está en el equipo no falla ni devuelve nada', () async {
    final stale = await FullSyncService.debugUnchangedSince(
      isar.isarCustomers,
      ['33333333-3333-3333-3333-333333333333'],
      DateTime.utc(2026),
    );
    expect(stale, isEmpty);
  });
}
