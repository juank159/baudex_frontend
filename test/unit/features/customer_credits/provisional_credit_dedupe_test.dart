import 'package:baudex_desktop/features/customer_credits/data/models/customer_credit_model.dart';
import 'package:baudex_desktop/features/customer_credits/data/repositories/customer_credit_repository_impl.dart';
import 'package:baudex_desktop/features/customer_credits/domain/entities/customer_credit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Una venta a crédito sin conexión crea un crédito provisional en el equipo.
/// Cuando la factura sube, el servidor crea el real. La lista (que ahora se
/// lee de la base local) nunca debe mostrar la deuda dos veces, ni esconder
/// el provisional mientras el real no ha llegado.
void main() {
  CustomerCreditModel credit(
    String id, {
    String customerId = 'cli-1',
    String? invoiceId,
    String? invoiceNumber,
    double amount = 5000,
  }) =>
      CustomerCreditModel(
        id: id,
        originalAmount: amount,
        paidAmount: 0,
        balanceDue: amount,
        status: CreditStatus.pending,
        customerId: customerId,
        invoiceId: invoiceId,
        invoiceNumber: invoiceNumber,
        organizationId: 'org',
        createdById: 'u',
        createdAt: DateTime(2026, 10, 10, 20),
        updatedAt: DateTime(2026, 10, 10, 20),
      );

  final dedupe = CustomerCreditRepositoryImpl.withoutReplacedProvisionalCredits;

  test('sin el crédito real, el provisional se muestra', () {
    final list = dedupe([
      credit('credit_offline_1', invoiceId: 'inv_temp_1', invoiceNumber: 'INV-2026-943655'),
    ]);
    expect(list.map((c) => c.id), ['credit_offline_1']);
  });

  test('llegó el real de la misma factura: solo se muestra el real', () {
    final list = dedupe([
      credit('credit_offline_1', invoiceId: 'f3c1a2b4-0000-4000-8000-000000000001'),
      credit('9a1b2c3d-0000-4000-8000-000000000002',
          invoiceId: 'f3c1a2b4-0000-4000-8000-000000000001'),
    ]);
    expect(list.map((c) => c.id), ['9a1b2c3d-0000-4000-8000-000000000002']);
  });

  test('provisional viejo con id de factura temporal: se reconoce por número y cliente', () {
    final list = dedupe([
      credit('credit_offline_1', invoiceId: 'inv_temp_1', invoiceNumber: 'INV-2026-943655'),
      credit('9a1b2c3d-0000-4000-8000-000000000002',
          invoiceId: 'f3c1a2b4-0000-4000-8000-000000000001',
          invoiceNumber: 'INV-2026-943655'),
    ]);
    expect(list.map((c) => c.id), ['9a1b2c3d-0000-4000-8000-000000000002']);
  });

  test('mismo número de factura pero de OTRO cliente no se oculta', () {
    final list = dedupe([
      credit('credit_offline_1', customerId: 'cli-1', invoiceNumber: 'INV-1'),
      credit('9a1b2c3d-0000-4000-8000-000000000002', customerId: 'cli-2', invoiceNumber: 'INV-1'),
    ]);
    expect(list.length, 2);
  });

  test('los créditos reales nunca se ocultan', () {
    final list = dedupe([
      credit('9a1b2c3d-0000-4000-8000-000000000002', invoiceId: 'f1'),
      credit('8b2c3d4e-0000-4000-8000-000000000003', invoiceId: 'f1'),
    ]);
    expect(list.length, 2);
  });
}
