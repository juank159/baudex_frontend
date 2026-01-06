// test/integration/customers/customer_search_test.dart
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

  group('Customer Search Integration', () {
    test(
      'search by first name',
      () async {
        // Create test data
        await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
        );

        await repository.createCustomer(
          firstName: 'Jane',
          lastName: 'Smith',
          email: 'jane.smith@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
        );

        await repository.createCustomer(
          firstName: 'Johnny',
          lastName: 'Walker',
          email: 'johnny.walker@test.com',
          documentType: DocumentType.cc,
          documentNumber: '3333333333',
        );

        // Search for "John"
        final result = await repository.searchCustomers('John');

        result.fold(
          (failure) => fail('Search should succeed'),
          (customers) {
            expect(customers.length, 2);
            expect(customers.any((c) => c.firstName == 'John'), true);
            expect(customers.any((c) => c.firstName == 'Johnny'), true);
          },
        );
      },
    );

    test(
      'search by last name',
      () async {
        // Create test data
        await repository.createCustomer(
          firstName: 'John',
          lastName: 'Smith',
          email: 'john.smith@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
        );

        await repository.createCustomer(
          firstName: 'Jane',
          lastName: 'Smithson',
          email: 'jane.smithson@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
        );

        await repository.createCustomer(
          firstName: 'Bob',
          lastName: 'Johnson',
          email: 'bob.johnson@test.com',
          documentType: DocumentType.cc,
          documentNumber: '3333333333',
        );

        // Search for "Smith"
        final result = await repository.searchCustomers('Smith');

        result.fold(
          (failure) => fail('Search should succeed'),
          (customers) {
            expect(customers.length, 2);
            expect(customers.every((c) => c.lastName.contains('Smith')), true);
          },
        );
      },
    );

    test(
      'search by email',
      () async {
        // Create test data
        await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@company.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
        );

        await repository.createCustomer(
          firstName: 'Jane',
          lastName: 'Smith',
          email: 'jane@company.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
        );

        await repository.createCustomer(
          firstName: 'Bob',
          lastName: 'Johnson',
          email: 'bob@other.com',
          documentType: DocumentType.cc,
          documentNumber: '3333333333',
        );

        // Search for "company"
        final result = await repository.searchCustomers('company');

        result.fold(
          (failure) => fail('Search should succeed'),
          (customers) {
            expect(customers.length, 2);
            expect(customers.every((c) => c.email.contains('company')), true);
          },
        );
      },
    );

    test(
      'search by document number',
      () async {
        // Create test data
        await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );

        await repository.createCustomer(
          firstName: 'Jane',
          lastName: 'Smith',
          email: 'jane@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567891',
        );

        await repository.createCustomer(
          firstName: 'Bob',
          lastName: 'Johnson',
          email: 'bob@test.com',
          documentType: DocumentType.cc,
          documentNumber: '9876543210',
        );

        // Search for "123456789"
        final result = await repository.searchCustomers('123456789');

        result.fold(
          (failure) => fail('Search should succeed'),
          (customers) {
            expect(customers.length, 2);
            expect(
              customers.every((c) => c.documentNumber.startsWith('123456789')),
              true,
            );
          },
        );
      },
    );

    test(
      'search by company name',
      () async {
        // Create test data
        await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          companyName: 'Tech Solutions Inc',
          email: 'john@tech.com',
          documentType: DocumentType.nit,
          documentNumber: '900111111-1',
        );

        await repository.createCustomer(
          firstName: 'Jane',
          lastName: 'Smith',
          companyName: 'Tech Innovations LLC',
          email: 'jane@techinno.com',
          documentType: DocumentType.nit,
          documentNumber: '900222222-2',
        );

        await repository.createCustomer(
          firstName: 'Bob',
          lastName: 'Johnson',
          companyName: 'Food Services Corp',
          email: 'bob@food.com',
          documentType: DocumentType.nit,
          documentNumber: '900333333-3',
        );

        // Search for "Tech"
        final result = await repository.searchCustomers('Tech');

        result.fold(
          (failure) => fail('Search should succeed'),
          (customers) {
            expect(customers.length, 2);
            expect(
              customers.every((c) => c.companyName?.contains('Tech') ?? false),
              true,
            );
          },
        );
      },
    );

    test(
      'search is case insensitive',
      () async {
        // Create test data
        await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
        );

        // Search with different cases
        final lowerResult = await repository.searchCustomers('john');
        final upperResult = await repository.searchCustomers('JOHN');
        final mixedResult = await repository.searchCustomers('JoHn');

        lowerResult.fold(
          (failure) => fail('Lower case search should succeed'),
          (customers) => expect(customers.length, 1),
        );

        upperResult.fold(
          (failure) => fail('Upper case search should succeed'),
          (customers) => expect(customers.length, 1),
        );

        mixedResult.fold(
          (failure) => fail('Mixed case search should succeed'),
          (customers) => expect(customers.length, 1),
        );
      },
    );

    test(
      'search with limit',
      () async {
        // Create 15 customers with "Test" in name
        for (int i = 1; i <= 15; i++) {
          await repository.createCustomer(
            firstName: 'TestCustomer$i',
            lastName: 'User',
            email: 'test$i@test.com',
            documentType: DocumentType.cc,
            documentNumber: '${1000000000 + i}',
          );
        }

        // Search with limit 5
        final result = await repository.searchCustomers('TestCustomer', limit: 5);

        result.fold(
          (failure) => fail('Search should succeed'),
          (customers) => expect(customers.length, 5),
        );
      },
    );

    test(
      'search returns empty list when no matches',
      () async {
        // Create test data
        await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
        );

        // Search for non-existent term
        final result = await repository.searchCustomers('NonExistent');

        result.fold(
          (failure) => fail('Search should succeed'),
          (customers) => expect(customers.isEmpty, true),
        );
      },
    );

    test(
      'search excludes deleted customers',
      () async {
        // Create customers
        final createResult1 = await repository.createCustomer(
          firstName: 'Active',
          lastName: 'Customer',
          email: 'active@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
        );

        final createResult2 = await repository.createCustomer(
          firstName: 'Deleted',
          lastName: 'Customer',
          email: 'deleted@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
        );

        String? deletedId;
        createResult2.fold(
          (failure) => fail('Create should succeed'),
          (customer) => deletedId = customer.id,
        );

        // Delete one customer
        await repository.deleteCustomer(deletedId!);

        // Search should only return active customer
        final result = await repository.searchCustomers('Customer');

        result.fold(
          (failure) => fail('Search should succeed'),
          (customers) {
            expect(customers.length, 1);
            expect(customers[0].firstName, 'Active');
          },
        );
      },
    );

    test(
      'filter search results by status',
      () async {
        // Create active customers
        await repository.createCustomer(
          firstName: 'Active',
          lastName: 'TestUser1',
          email: 'active1@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
          status: CustomerStatus.active,
        );

        await repository.createCustomer(
          firstName: 'Active',
          lastName: 'TestUser2',
          email: 'active2@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
          status: CustomerStatus.active,
        );

        // Create inactive customer
        final createResult = await repository.createCustomer(
          firstName: 'Inactive',
          lastName: 'TestUser3',
          email: 'inactive@test.com',
          documentType: DocumentType.cc,
          documentNumber: '3333333333',
          status: CustomerStatus.active,
        );

        String? inactiveId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => inactiveId = customer.id,
        );

        // Make it inactive
        await repository.updateCustomerStatus(
          id: inactiveId!,
          status: CustomerStatus.inactive,
        );

        // Search with active filter
        final result = await repository.getCustomers(
          search: 'TestUser',
          status: CustomerStatus.active,
        );

        result.fold(
          (failure) => fail('Search should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
            expect(
              paginatedResult.data.every((c) => c.status == CustomerStatus.active),
              true,
            );
          },
        );
      },
    );

    test(
      'filter search results by city',
      () async {
        // Create customers in different cities
        await repository.createCustomer(
          firstName: 'Customer',
          lastName: 'One',
          email: 'customer1@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
          city: 'Bogota',
        );

        await repository.createCustomer(
          firstName: 'Customer',
          lastName: 'Two',
          email: 'customer2@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
          city: 'Bogota',
        );

        await repository.createCustomer(
          firstName: 'Customer',
          lastName: 'Three',
          email: 'customer3@test.com',
          documentType: DocumentType.cc,
          documentNumber: '3333333333',
          city: 'Medellin',
        );

        // Search with city filter
        final result = await repository.getCustomers(
          search: 'Customer',
          city: 'Bogota',
        );

        result.fold(
          (failure) => fail('Search should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
            expect(
              paginatedResult.data.every((c) => c.city == 'Bogota'),
              true,
            );
          },
        );
      },
    );

    test(
      'sort search results by name',
      () async {
        // Create customers in random order
        await repository.createCustomer(
          firstName: 'Charlie',
          lastName: 'Brown',
          email: 'charlie@test.com',
          documentType: DocumentType.cc,
          documentNumber: '3333333333',
        );

        await repository.createCustomer(
          firstName: 'Alice',
          lastName: 'Johnson',
          email: 'alice@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
        );

        await repository.createCustomer(
          firstName: 'Bob',
          lastName: 'Smith',
          email: 'bob@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
        );

        // Get with name sorting
        final ascResult = await repository.getCustomers(
          sortBy: 'name',
          sortOrder: 'asc',
        );

        ascResult.fold(
          (failure) => fail('Sort should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data[0].firstName, 'Alice');
            expect(paginatedResult.data[1].firstName, 'Bob');
            expect(paginatedResult.data[2].firstName, 'Charlie');
          },
        );

        // Get with name sorting descending
        final descResult = await repository.getCustomers(
          sortBy: 'name',
          sortOrder: 'desc',
        );

        descResult.fold(
          (failure) => fail('Sort should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data[0].firstName, 'Charlie');
            expect(paginatedResult.data[1].firstName, 'Bob');
            expect(paginatedResult.data[2].firstName, 'Alice');
          },
        );
      },
    );

    test(
      'combined search with multiple filters',
      () async {
        // Create diverse customer data
        await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
          city: 'Bogota',
          status: CustomerStatus.active,
        );

        await repository.createCustomer(
          firstName: 'Jane',
          lastName: 'Doe',
          email: 'jane@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
          city: 'Bogota',
          status: CustomerStatus.active,
        );

        await repository.createCustomer(
          firstName: 'Bob',
          lastName: 'Doe',
          email: 'bob@test.com',
          documentType: DocumentType.cc,
          documentNumber: '3333333333',
          city: 'Medellin',
          status: CustomerStatus.active,
        );

        final createResult = await repository.createCustomer(
          firstName: 'Alice',
          lastName: 'Doe',
          email: 'alice@test.com',
          documentType: DocumentType.cc,
          documentNumber: '4444444444',
          city: 'Bogota',
          status: CustomerStatus.active,
        );

        String? aliceId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => aliceId = customer.id,
        );

        // Make Alice inactive
        await repository.updateCustomerStatus(
          id: aliceId!,
          status: CustomerStatus.inactive,
        );

        // Search with multiple filters: "Doe", city=Bogota, status=active
        final result = await repository.getCustomers(
          search: 'Doe',
          city: 'Bogota',
          status: CustomerStatus.active,
        );

        result.fold(
          (failure) => fail('Search should succeed'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2); // John and Jane
            expect(
              paginatedResult.data.every((c) => c.lastName == 'Doe'),
              true,
            );
            expect(
              paginatedResult.data.every((c) => c.city == 'Bogota'),
              true,
            );
            expect(
              paginatedResult.data.every((c) => c.status == CustomerStatus.active),
              true,
            );
          },
        );
      },
    );
  });
}
