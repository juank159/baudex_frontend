// test/fixtures/customer_fixtures.dart
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';

/// Test fixtures for Customers module
class CustomerFixtures {
  // ============================================================================
  // ENTITY FIXTURES (Domain Layer)
  // ============================================================================

  /// Creates a single customer entity with default test data
  static Customer createCustomerEntity({
    String id = 'cust-001',
    String firstName = 'John',
    String lastName = 'Doe',
    String? companyName,
    String email = 'john.doe@example.com',
    String? phone = '+57 300 123 4567',
    String? mobile = '+57 300 123 4567',
    DocumentType documentType = DocumentType.cc,
    String documentNumber = '1234567890',
    String? address = '123 Main St',
    String? city = 'Bogota',
    String? state = 'Cundinamarca',
    String? zipCode = '110111',
    String? country = 'Colombia',
    CustomerStatus status = CustomerStatus.active,
    double creditLimit = 1000000.0,
    double currentBalance = 0.0,
    int paymentTerms = 30,
    double totalPurchases = 0.0,
    int totalOrders = 0,
  }) {
    return Customer(
      id: id,
      firstName: firstName,
      lastName: lastName,
      companyName: companyName,
      email: email,
      phone: phone,
      mobile: mobile,
      documentType: documentType,
      documentNumber: documentNumber,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      country: country,
      status: status,
      creditLimit: creditLimit,
      currentBalance: currentBalance,
      paymentTerms: paymentTerms,
      totalPurchases: totalPurchases,
      totalOrders: totalOrders,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates a list of customer entities
  static List<Customer> createCustomerEntityList(int count) {
    return List.generate(count, (index) {
      return createCustomerEntity(
        id: 'cust-${(index + 1).toString().padLeft(3, '0')}',
        firstName: 'Customer${index + 1}',
        lastName: 'Test',
        email: 'customer${index + 1}@example.com',
        documentNumber: '${1234567890 + index}',
        totalPurchases: index * 100000.0,
        totalOrders: index,
      );
    });
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES
  // ============================================================================

  /// Creates a corporate customer (with company name)
  static Customer createCorporateCustomer({
    String id = 'cust-corporate',
  }) {
    return createCustomerEntity(
      id: id,
      firstName: 'Juan',
      lastName: 'Perez',
      companyName: 'Tech Solutions S.A.S.',
      documentType: DocumentType.nit,
      documentNumber: '900123456-1',
      creditLimit: 5000000.0,
      paymentTerms: 60,
    );
  }

  /// Creates an individual customer (no company)
  static Customer createIndividualCustomer({
    String id = 'cust-individual',
  }) {
    return createCustomerEntity(
      id: id,
      firstName: 'Maria',
      lastName: 'Garcia',
      companyName: null,
      documentType: DocumentType.cc,
      documentNumber: '1234567890',
      creditLimit: 500000.0,
      paymentTerms: 30,
    );
  }

  /// Creates an inactive customer
  static Customer createInactiveCustomer({
    String id = 'cust-inactive',
  }) {
    return createCustomerEntity(
      id: id,
      firstName: 'Inactive',
      lastName: 'Customer',
      status: CustomerStatus.inactive,
    );
  }

  /// Creates a suspended customer
  static Customer createSuspendedCustomer({
    String id = 'cust-suspended',
  }) {
    return createCustomerEntity(
      id: id,
      firstName: 'Suspended',
      lastName: 'Customer',
      status: CustomerStatus.suspended,
      currentBalance: 1200000.0, // Over credit limit
      creditLimit: 1000000.0,
    );
  }

  /// Creates a customer with overdue balance
  static Customer createCustomerWithOverdueBalance({
    String id = 'cust-overdue',
    double overdueAmount = 500000.0,
  }) {
    return createCustomerEntity(
      id: id,
      firstName: 'Overdue',
      lastName: 'Customer',
      currentBalance: overdueAmount,
      creditLimit: 1000000.0,
      status: CustomerStatus.active,
    );
  }

  /// Creates a customer at credit limit
  static Customer createCustomerAtCreditLimit({
    String id = 'cust-at-limit',
  }) {
    return createCustomerEntity(
      id: id,
      firstName: 'AtLimit',
      lastName: 'Customer',
      currentBalance: 1000000.0,
      creditLimit: 1000000.0,
    );
  }

  /// Creates a customer over credit limit
  static Customer createCustomerOverCreditLimit({
    String id = 'cust-over-limit',
  }) {
    return createCustomerEntity(
      id: id,
      firstName: 'OverLimit',
      lastName: 'Customer',
      currentBalance: 1500000.0,
      creditLimit: 1000000.0,
    );
  }

  /// Creates a VIP customer (high credit limit, many orders)
  static Customer createVIPCustomer({
    String id = 'cust-vip',
  }) {
    return createCustomerEntity(
      id: id,
      firstName: 'VIP',
      lastName: 'Customer',
      companyName: 'VIP Corporation S.A.',
      creditLimit: 10000000.0,
      currentBalance: 2000000.0,
      totalPurchases: 50000000.0,
      totalOrders: 150,
      paymentTerms: 90,
    );
  }

  /// Creates a new customer (no purchase history)
  static Customer createNewCustomer({
    String id = 'cust-new',
  }) {
    return createCustomerEntity(
      id: id,
      firstName: 'New',
      lastName: 'Customer',
      totalPurchases: 0.0,
      totalOrders: 0,
    );
  }

  /// Creates a customer with recent activity
  static Customer createCustomerWithRecentActivity({
    String id = 'cust-recent',
  }) {
    return createCustomerEntity(
      id: id,
      firstName: 'Recent',
      lastName: 'Customer',
      totalPurchases: 5000000.0,
      totalOrders: 10,
    );
  }

  /// Creates a customer with different document type
  static Customer createCustomerWithPassport({
    String id = 'cust-passport',
  }) {
    return createCustomerEntity(
      id: id,
      firstName: 'Foreign',
      lastName: 'Customer',
      documentType: DocumentType.passport,
      documentNumber: 'AB123456',
      country: 'United States',
    );
  }

  // ============================================================================
  // BATCH CREATION HELPERS
  // ============================================================================

  /// Creates a mix of customers with different statuses
  static List<Customer> createMixedStatusCustomers() {
    return [
      createCustomerEntity(id: 'cust-001', status: CustomerStatus.active),
      createCustomerEntity(id: 'cust-002', status: CustomerStatus.active),
      createInactiveCustomer(id: 'cust-003'),
      createSuspendedCustomer(id: 'cust-004'),
    ];
  }

  /// Creates customers with varying balances
  static List<Customer> createCustomersWithVaryingBalances() {
    return [
      createCustomerEntity(
        id: 'cust-001',
        currentBalance: 0.0,
        creditLimit: 1000000.0,
      ),
      createCustomerEntity(
        id: 'cust-002',
        currentBalance: 500000.0,
        creditLimit: 1000000.0,
      ),
      createCustomerAtCreditLimit(id: 'cust-003'),
      createCustomerOverCreditLimit(id: 'cust-004'),
    ];
  }

  /// Creates customers by risk level
  static List<Customer> createCustomersByRiskLevel() {
    return [
      // Low risk
      createCustomerEntity(
        id: 'cust-low-risk',
        currentBalance: 100000.0,
        creditLimit: 1000000.0,
      ),
      // Medium risk
      createCustomerEntity(
        id: 'cust-medium-risk',
        currentBalance: 750000.0,
        creditLimit: 1000000.0,
      ),
      // High risk
      createCustomerEntity(
        id: 'cust-high-risk',
        currentBalance: 950000.0,
        creditLimit: 1000000.0,
      ),
    ];
  }
}
