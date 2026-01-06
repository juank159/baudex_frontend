// test/fixtures/supplier_fixtures.dart
import 'package:baudex_desktop/features/suppliers/domain/entities/supplier.dart';

/// Test fixtures for Suppliers module
class SupplierFixtures {
  // ============================================================================
  // ENTITY FIXTURES (Domain Layer)
  // ============================================================================

  /// Creates a single supplier entity with default test data
  static Supplier createSupplierEntity({
    String id = 'supp-001',
    String name = 'Test Supplier',
    String? code = 'SUPP-001',
    DocumentType documentType = DocumentType.nit,
    String documentNumber = '900123456-1',
    String? contactPerson = 'John Supplier',
    String? email = 'supplier@example.com',
    String? phone = '+57 300 123 4567',
    String? mobile = '+57 300 123 4567',
    String? address = '456 Supplier St',
    String? city = 'Medellin',
    String? state = 'Antioquia',
    String? country = 'Colombia',
    String? postalCode = '050001',
    String? website = 'https://supplier.com',
    SupplierStatus status = SupplierStatus.active,
    String currency = 'COP',
    int paymentTermsDays = 30,
    double creditLimit = 5000000.0,
    double discountPercentage = 0.0,
    String organizationId = 'org-001',
  }) {
    return Supplier(
      id: id,
      name: name,
      code: code,
      documentType: documentType,
      documentNumber: documentNumber,
      contactPerson: contactPerson,
      email: email,
      phone: phone,
      mobile: mobile,
      address: address,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      website: website,
      status: status,
      currency: currency,
      paymentTermsDays: paymentTermsDays,
      creditLimit: creditLimit,
      discountPercentage: discountPercentage,
      organizationId: organizationId,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates a list of supplier entities
  static List<Supplier> createSupplierEntityList(int count) {
    return List.generate(count, (index) {
      return createSupplierEntity(
        id: 'supp-${(index + 1).toString().padLeft(3, '0')}',
        name: 'Supplier ${index + 1}',
        code: 'SUPP-${(index + 1).toString().padLeft(3, '0')}',
        documentNumber: '900${123456 + index}-1',
        email: 'supplier${index + 1}@example.com',
      );
    });
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES
  // ============================================================================

  /// Creates an inactive supplier
  static Supplier createInactiveSupplier({
    String id = 'supp-inactive',
  }) {
    return createSupplierEntity(
      id: id,
      name: 'Inactive Supplier',
      code: 'SUPP-INACTIVE',
      status: SupplierStatus.inactive,
    );
  }

  /// Creates a blocked supplier
  static Supplier createBlockedSupplier({
    String id = 'supp-blocked',
  }) {
    return createSupplierEntity(
      id: id,
      name: 'Blocked Supplier',
      code: 'SUPP-BLOCKED',
      status: SupplierStatus.blocked,
    );
  }

  /// Creates a supplier with discount
  static Supplier createSupplierWithDiscount({
    String id = 'supp-discount',
    double discountPercentage = 10.0,
  }) {
    return createSupplierEntity(
      id: id,
      name: 'Supplier with Discount',
      code: 'SUPP-DISCOUNT',
      discountPercentage: discountPercentage,
    );
  }

  /// Creates a supplier with extended payment terms
  static Supplier createSupplierWithExtendedTerms({
    String id = 'supp-extended',
    int paymentTermsDays = 90,
  }) {
    return createSupplierEntity(
      id: id,
      name: 'Supplier with Extended Terms',
      code: 'SUPP-EXTENDED',
      paymentTermsDays: paymentTermsDays,
    );
  }

  /// Creates a supplier with high credit limit
  static Supplier createSupplierWithHighCreditLimit({
    String id = 'supp-high-credit',
    double creditLimit = 50000000.0,
  }) {
    return createSupplierEntity(
      id: id,
      name: 'Supplier with High Credit Limit',
      code: 'SUPP-HIGH-CREDIT',
      creditLimit: creditLimit,
    );
  }

  /// Creates an international supplier (USD currency)
  static Supplier createInternationalSupplier({
    String id = 'supp-international',
  }) {
    return createSupplierEntity(
      id: id,
      name: 'International Supplier Inc.',
      code: 'SUPP-INTL',
      documentType: DocumentType.other,
      documentNumber: 'EIN-123456789',
      country: 'United States',
      city: 'Miami',
      state: 'Florida',
      currency: 'USD',
      website: 'https://international-supplier.com',
    );
  }

  /// Creates a supplier with minimal info
  static Supplier createMinimalSupplier({
    String id = 'supp-minimal',
  }) {
    return createSupplierEntity(
      id: id,
      name: 'Minimal Supplier',
      code: null,
      contactPerson: null,
      email: null,
      phone: null,
      mobile: null,
      address: null,
      city: null,
      state: null,
      postalCode: null,
      website: null,
    );
  }

  /// Creates a supplier with complete info
  static Supplier createCompleteSupplier({
    String id = 'supp-complete',
  }) {
    return createSupplierEntity(
      id: id,
      name: 'Complete Supplier S.A.S.',
      code: 'SUPP-COMPLETE',
      contactPerson: 'Maria Rodriguez',
      email: 'contact@completesupplier.com',
      phone: '+57 1 123 4567',
      mobile: '+57 300 123 4567',
      address: 'Calle 123 # 45-67',
      city: 'Bogota',
      state: 'Cundinamarca',
      country: 'Colombia',
      postalCode: '110111',
      website: 'https://completesupplier.com',
      status: SupplierStatus.active,
      currency: 'COP',
      paymentTermsDays: 45,
      creditLimit: 10000000.0,
      discountPercentage: 5.0,
    );
  }

  /// Creates a supplier without contact info
  static Supplier createSupplierWithoutContact({
    String id = 'supp-no-contact',
  }) {
    return createSupplierEntity(
      id: id,
      name: 'No Contact Supplier',
      code: 'SUPP-NO-CONTACT',
      contactPerson: null,
      email: null,
      phone: null,
      mobile: null,
    );
  }

  // ============================================================================
  // BATCH CREATION HELPERS
  // ============================================================================

  /// Creates a mix of suppliers with different statuses
  static List<Supplier> createMixedStatusSuppliers() {
    return [
      createSupplierEntity(id: 'supp-001', status: SupplierStatus.active),
      createSupplierEntity(id: 'supp-002', status: SupplierStatus.active),
      createInactiveSupplier(id: 'supp-003'),
      createBlockedSupplier(id: 'supp-004'),
    ];
  }

  /// Creates suppliers with different currencies
  static List<Supplier> createSuppliersWithDifferentCurrencies() {
    return [
      createSupplierEntity(
        id: 'supp-001',
        name: 'Local Supplier COP',
        currency: 'COP',
      ),
      createSupplierEntity(
        id: 'supp-002',
        name: 'US Supplier USD',
        currency: 'USD',
        country: 'United States',
      ),
      createSupplierEntity(
        id: 'supp-003',
        name: 'EU Supplier EUR',
        currency: 'EUR',
        country: 'Spain',
      ),
    ];
  }

  /// Creates suppliers with varying payment terms
  static List<Supplier> createSuppliersWithVaryingTerms() {
    return [
      createSupplierEntity(
        id: 'supp-001',
        name: 'Immediate Payment',
        paymentTermsDays: 0,
      ),
      createSupplierEntity(
        id: 'supp-002',
        name: '30 Days Payment',
        paymentTermsDays: 30,
      ),
      createSupplierEntity(
        id: 'supp-003',
        name: '60 Days Payment',
        paymentTermsDays: 60,
      ),
      createSupplierWithExtendedTerms(
        id: 'supp-004',
        paymentTermsDays: 90,
      ),
    ];
  }

  /// Creates suppliers with varying discount levels
  static List<Supplier> createSuppliersWithVaryingDiscounts() {
    return [
      createSupplierEntity(
        id: 'supp-001',
        name: 'No Discount',
        discountPercentage: 0.0,
      ),
      createSupplierEntity(
        id: 'supp-002',
        name: '5% Discount',
        discountPercentage: 5.0,
      ),
      createSupplierEntity(
        id: 'supp-003',
        name: '10% Discount',
        discountPercentage: 10.0,
      ),
      createSupplierEntity(
        id: 'supp-004',
        name: '15% Discount',
        discountPercentage: 15.0,
      ),
    ];
  }
}
