// test/integration/customers/customer_offline_flow_test.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/customers/data/repositories/customer_offline_repository.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_isar.dart';
import '../../fixtures/customer_fixtures.dart';

void main() {
  late CustomerOfflineRepository repository;
  late MockIsar mockIsar;
  late MockIsarDatabase mockIsarDatabase;

  setUp(() {
    mockIsar = MockIsar();
    mockIsarDatabase = MockIsarDatabase(mockIsar);
    final dynamic db = mockIsarDatabase;
    repository = CustomerOfflineRepository(database: db);
  });

  tearDown(() async {
    await mockIsar.clear();
    await mockIsar.close();
  });

  group('Customer Offline Flow Integration', () {
    test(
      'create multiple customers offline',
      () async {
        // Create 10 customers offline
        final customerIds = <String>[];

        for (int i = 1; i <= 10; i++) {
          final result = await repository.createCustomer(
            firstName: 'Customer$i',
            lastName: 'Test',
            email: 'customer$i@test.com',
            documentType: DocumentType.cc,
            documentNumber: '${1234567890 + i}',
            creditLimit: 1000000.0,
            paymentTerms: 30,
          );

          result.fold(
            (failure) => fail('Create should succeed'),
            (customer) => customerIds.add(customer.id),
          );
        }

        // Verify all created with offline IDs
        expect(customerIds.length, 10);
        expect(customerIds.every((id) => id.startsWith('customer_')), true);

        // Verify in ISAR
        final isarCustomers = await mockIsar.isarCustomers.where().findAll();
        expect(isarCustomers.length, 10);
        expect(isarCustomers.every((c) => !c.isSynced), true);
      },
    );

    test(
      'search customers offline',
      () async {
        // Create customers with different names
        await repository.createCustomer(
          firstName: 'John',
          lastName: 'Smith',
          email: 'john.smith@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );

        await repository.createCustomer(
          firstName: 'Johnny',
          lastName: 'Doe',
          email: 'johnny.doe@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567891',
        );

        await repository.createCustomer(
          firstName: 'Maria',
          lastName: 'Garcia',
          email: 'maria.garcia@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567892',
        );

        // Search for "John"
        final searchResult = await repository.searchCustomers('John');

        searchResult.fold(
          (failure) => fail('Search should succeed'),
          (customers) {
            expect(customers.length, 2);
            expect(
              customers.every((c) => c.firstName.contains('John')),
              true,
            );
          },
        );
      },
    );

    test(
      'filter customers by status offline',
      () async {
        // Create active customers
        await repository.createCustomer(
          firstName: 'Active',
          lastName: 'Customer1',
          email: 'active1@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
          status: CustomerStatus.active,
        );

        await repository.createCustomer(
          firstName: 'Active',
          lastName: 'Customer2',
          email: 'active2@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
          status: CustomerStatus.active,
        );

        // Create inactive customer manually in ISAR
        final inactiveCustomer = IsarCustomer()
          ..serverId = 'customer_offline_inactive'
          ..firstName = 'Inactive'
          ..lastName = 'Customer'
          ..email = 'inactive@test.com'
          ..documentType = IsarDocumentType.cc
          ..documentNumber = '3333333333'
          ..status = IsarCustomerStatus.inactive
          ..creditLimit = 0.0
          ..currentBalance = 0.0
          ..paymentTerms = 0
          ..totalPurchases = 0.0
          ..totalOrders = 0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..isSynced = false;

        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(inactiveCustomer);
        });

        // Filter by active status
        final result = await repository.getCustomers(
          status: CustomerStatus.active,
        );

        result.fold(
          (failure) => fail('Filter should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
            expect(
              paginatedResult.data
                  .every((c) => c.status == CustomerStatus.active),
              true,
            );
          },
        );
      },
    );

    test(
      'filter customers by document type offline',
      () async {
        // Create customers with different document types
        await repository.createCustomer(
          firstName: 'Individual',
          lastName: 'One',
          email: 'individual1@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
        );

        await repository.createCustomer(
          firstName: 'Individual',
          lastName: 'Two',
          email: 'individual2@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
        );

        await repository.createCustomer(
          firstName: 'Company',
          lastName: 'One',
          email: 'company@test.com',
          documentType: DocumentType.nit,
          documentNumber: '900123456-1',
        );

        // Filter by CC (individual)
        final result = await repository.getCustomers(
          documentType: DocumentType.cc,
        );

        result.fold(
          (failure) => fail('Filter should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
            expect(
              paginatedResult.data
                  .every((c) => c.documentType == DocumentType.cc),
              true,
            );
          },
        );
      },
    );

    test(
      'paginate customers offline',
      () async {
        // Create 25 customers
        for (int i = 1; i <= 25; i++) {
          await repository.createCustomer(
            firstName: 'Customer$i',
            lastName: 'Test',
            email: 'customer$i@test.com',
            documentType: DocumentType.cc,
            documentNumber: '${1000000000 + i}',
          );
        }

        // Get page 1 (limit 10)
        final page1Result = await repository.getCustomers(
          page: 1,
          limit: 10,
        );

        page1Result.fold(
          (failure) => fail('Page 1 should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 10);
            expect(paginatedResult.meta.page, 1);
            expect(paginatedResult.meta.totalItems, 25);
            expect(paginatedResult.meta.totalPages, 3);
            expect(paginatedResult.meta.hasNextPage, true);
            expect(paginatedResult.meta.hasPreviousPage, false);
          },
        );

        // Get page 2
        final page2Result = await repository.getCustomers(
          page: 2,
          limit: 10,
        );

        page2Result.fold(
          (failure) => fail('Page 2 should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 10);
            expect(paginatedResult.meta.page, 2);
            expect(paginatedResult.meta.hasNextPage, true);
            expect(paginatedResult.meta.hasPreviousPage, true);
          },
        );

        // Get page 3
        final page3Result = await repository.getCustomers(
          page: 3,
          limit: 10,
        );

        page3Result.fold(
          (failure) => fail('Page 3 should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 5);
            expect(paginatedResult.meta.page, 3);
            expect(paginatedResult.meta.hasNextPage, false);
            expect(paginatedResult.meta.hasPreviousPage, true);
          },
        );
      },
    );

    test(
      'update customer balance offline',
      () async {
        // Create customer
        final createResult = await repository.createCustomer(
          firstName: 'Balance',
          lastName: 'Customer',
          email: 'balance@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          creditLimit: 1000000.0,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Add to balance multiple times
        await repository.updateCustomerBalance(
          id: customerId!,
          amount: 100000.0,
          operation: 'add',
        );

        await repository.updateCustomerBalance(
          id: customerId!,
          amount: 150000.0,
          operation: 'add',
        );

        // Subtract from balance
        await repository.updateCustomerBalance(
          id: customerId!,
          amount: 50000.0,
          operation: 'subtract',
        );

        // Verify final balance: 0 + 100000 + 150000 - 50000 = 200000
        final result = await repository.getCustomerById(customerId!);

        result.fold(
          (failure) => fail('Get customer should succeed'),
          (customer) => expect(customer.currentBalance, 200000.0),
        );
      },
    );

    test(
      'get customers with overdue invoices offline',
      () async {
        // Create customers with varying balances
        final createResult1 = await repository.createCustomer(
          firstName: 'No',
          lastName: 'Balance',
          email: 'nobalance@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
        );

        final createResult2 = await repository.createCustomer(
          firstName: 'Has',
          lastName: 'Balance1',
          email: 'hasbalance1@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
        );

        final createResult3 = await repository.createCustomer(
          firstName: 'Has',
          lastName: 'Balance2',
          email: 'hasbalance2@test.com',
          documentType: DocumentType.cc,
          documentNumber: '3333333333',
        );

        // Update balances after creation
        String? customerId2;
        String? customerId3;
        createResult2.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId2 = customer.id,
        );
        createResult3.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId3 = customer.id,
        );

        await repository.updateCustomerBalance(
          id: customerId2!,
          amount: 100000.0,
          operation: 'add',
        );

        await repository.updateCustomerBalance(
          id: customerId3!,
          amount: 200000.0,
          operation: 'add',
        );

        // Get customers with overdue
        final result = await repository.getCustomersWithOverdueInvoices();

        result.fold(
          (failure) => fail('Get overdue should succeed'),
          (customers) {
            expect(customers.length, 2);
            expect(customers.every((c) => c.currentBalance > 0), true);
          },
        );
      },
    );

    test(
      'delete customer offline',
      () async {
        // Create customer
        final createResult = await repository.createCustomer(
          firstName: 'Delete',
          lastName: 'Customer',
          email: 'delete@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Delete
        final deleteResult = await repository.deleteCustomer(customerId!);

        expect(deleteResult.isRight(), true);

        // Verify soft deleted in ISAR
        final deletedCustomer = await mockIsar.isarCustomers
            .filter()
            .serverIdEqualTo(customerId!)
            .findFirst();

        expect(deletedCustomer!.deletedAt, isNotNull);

        // Should not appear in normal queries
        final getResult = await repository.getCustomerById(customerId!);
        expect(getResult.isLeft(), true);
      },
    );

    test(
      'get customer stats offline',
      () async {
        // Create customers with different statuses
        final createResult1 = await repository.createCustomer(
          firstName: 'Active',
          lastName: 'Customer1',
          email: 'active1@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
          status: CustomerStatus.active,
          creditLimit: 1000000.0,
        );

        final createResult2 = await repository.createCustomer(
          firstName: 'Active',
          lastName: 'Customer2',
          email: 'active2@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
          status: CustomerStatus.active,
          creditLimit: 2000000.0,
        );

        // Update balances after creation
        String? customerId1;
        String? customerId2;
        createResult1.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId1 = customer.id,
        );
        createResult2.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId2 = customer.id,
        );

        await repository.updateCustomerBalance(
          id: customerId1!,
          amount: 100000.0,
          operation: 'add',
        );

        await repository.updateCustomerBalance(
          id: customerId2!,
          amount: 200000.0,
          operation: 'add',
        );

        final inactiveCustomer = IsarCustomer()
          ..serverId = 'customer_inactive'
          ..firstName = 'Inactive'
          ..lastName = 'Customer'
          ..email = 'inactive@test.com'
          ..documentType = IsarDocumentType.cc
          ..documentNumber = '3333333333'
          ..status = IsarCustomerStatus.inactive
          ..creditLimit = 500000.0
          ..currentBalance = 0.0
          ..paymentTerms = 0
          ..totalPurchases = 0.0
          ..totalOrders = 0
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..isSynced = false;

        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(inactiveCustomer);
        });

        // Get stats
        final statsResult = await repository.getCustomerStats();

        statsResult.fold(
          (failure) => fail('Get stats should succeed'),
          (stats) {
            expect(stats.total, 3);
            expect(stats.active, 2);
            expect(stats.inactive, 1);
            expect(stats.totalCreditLimit, 3500000.0);
            expect(stats.totalBalance, 300000.0);
            expect(stats.customersWithOverdue, 2);
          },
        );
      },
    );

    test(
      'get top customers offline',
      () async {
        // Create customers with varying purchase amounts
        await repository.createCustomer(
          firstName: 'Low',
          lastName: 'Purchaser',
          email: 'low@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
        );

        // Record purchases manually
        final customer1Id = (await repository.getCustomerByEmail('low@test.com'))
            .getOrElse(() => throw Exception());

        await repository.recordPurchase(
          customerId: customer1Id.id,
          amount: 100000.0,
        );

        await repository.createCustomer(
          firstName: 'High',
          lastName: 'Purchaser',
          email: 'high@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
        );

        final customer2Id = (await repository.getCustomerByEmail('high@test.com'))
            .getOrElse(() => throw Exception());

        await repository.recordPurchase(
          customerId: customer2Id.id,
          amount: 1000000.0,
        );

        // Get top customers
        final result = await repository.getTopCustomers(limit: 2);

        result.fold(
          (failure) => fail('Get top customers should succeed'),
          (customers) {
            expect(customers.length, 2);
            // Should be sorted by total purchases descending
            expect(customers[0].totalPurchases, greaterThan(customers[1].totalPurchases));
          },
        );
      },
    );

    test(
      'validate email availability offline',
      () async {
        // Create customer
        await repository.createCustomer(
          firstName: 'Existing',
          lastName: 'Customer',
          email: 'existing@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );

        // Check existing email
        final existingResult = await repository.isEmailAvailable('existing@test.com');

        existingResult.fold(
          (failure) => fail('Check should succeed'),
          (isAvailable) => expect(isAvailable, false),
        );

        // Check new email
        final newResult = await repository.isEmailAvailable('new@test.com');

        newResult.fold(
          (failure) => fail('Check should succeed'),
          (isAvailable) => expect(isAvailable, true),
        );
      },
    );

    test(
      'validate document availability offline',
      () async {
        // Create customer
        await repository.createCustomer(
          firstName: 'Existing',
          lastName: 'Customer',
          email: 'existing@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );

        // Check existing document
        final existingResult = await repository.isDocumentAvailable(
          DocumentType.cc,
          '1234567890',
        );

        existingResult.fold(
          (failure) => fail('Check should succeed'),
          (isAvailable) => expect(isAvailable, false),
        );

        // Check new document
        final newResult = await repository.isDocumentAvailable(
          DocumentType.cc,
          '9876543210',
        );

        newResult.fold(
          (failure) => fail('Check should succeed'),
          (isAvailable) => expect(isAvailable, true),
        );
      },
    );

    test(
      'complete offline workflow with all operations',
      () async {
        // Simulate complete offline session

        // 1. Create customers
        final customerIds = <String>[];
        for (int i = 1; i <= 5; i++) {
          final result = await repository.createCustomer(
            firstName: 'Workflow',
            lastName: 'Customer$i',
            email: 'workflow$i@test.com',
            documentType: DocumentType.cc,
            documentNumber: '${1000000000 + i}',
            creditLimit: 1000000.0,
          );

          result.fold(
            (failure) => fail('Create should succeed'),
            (customer) => customerIds.add(customer.id),
          );
        }

        // 2. Search
        final searchResult = await repository.searchCustomers('Workflow');
        searchResult.fold(
          (failure) => fail('Search should succeed'),
          (customers) => expect(customers.length, 5),
        );

        // 3. Update some customers
        await repository.updateCustomer(
          id: customerIds[0],
          firstName: 'Updated',
        );

        await repository.updateCustomerStatus(
          id: customerIds[1],
          status: CustomerStatus.inactive,
        );

        // 4. Update balances
        await repository.updateCustomerBalance(
          id: customerIds[2],
          amount: 500000.0,
          operation: 'add',
        );

        // 5. Filter by status
        final activeResult = await repository.getCustomers(
          status: CustomerStatus.active,
        );

        activeResult.fold(
          (failure) => fail('Filter should succeed'),
          (paginatedResult) => expect(paginatedResult.data.length, 4),
        );

        // 6. Paginate
        final paginatedResult = await repository.getCustomers(
          page: 1,
          limit: 3,
        );

        paginatedResult.fold(
          (failure) => fail('Pagination should succeed'),
          (result) {
            expect(result.data.length, 3);
            expect(result.meta.hasNextPage, true);
          },
        );

        // 7. Delete a customer
        await repository.deleteCustomer(customerIds[4]);

        // Verify final state
        final finalCustomers = await mockIsar.isarCustomers
            .filter()
            .deletedAtIsNull()
            .findAll();

        expect(finalCustomers.length, 4); // 5 created - 1 deleted

        // All should be unsynced
        expect(finalCustomers.every((c) => !c.isSynced), true);
      },
    );
  });
}
