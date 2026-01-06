// test/integration/customers/customer_credit_management_test.dart
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

  group('Customer Credit Management Integration', () {
    test(
      'check if customer can make purchase within credit limit',
      () async {
        // Create customer with credit limit
        final createResult = await repository.createCustomer(
          firstName: 'Credit',
          lastName: 'Customer',
          email: 'credit@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          creditLimit: 1000000.0,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Check if can purchase 500,000 (should succeed)
        final canPurchaseResult = await repository.canMakePurchase(
          customerId: customerId!,
          amount: 500000.0,
        );

        canPurchaseResult.fold(
          (failure) => fail('Check should succeed'),
          (result) {
            expect(result['canPurchase'], true);
            expect(result['availableCredit'], 1000000.0);
            expect(result['requiredAmount'], 500000.0);
          },
        );
      },
    );

    test(
      'check if customer cannot make purchase exceeding credit limit',
      () async {
        // Create customer with credit limit
        final createResult = await repository.createCustomer(
          firstName: 'Credit',
          lastName: 'Customer',
          email: 'credit@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          creditLimit: 1000000.0,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Check if can purchase 1,500,000 (should fail)
        final canPurchaseResult = await repository.canMakePurchase(
          customerId: customerId!,
          amount: 1500000.0,
        );

        canPurchaseResult.fold(
          (failure) => fail('Check should succeed'),
          (result) {
            expect(result['canPurchase'], false);
            expect(result['reason'], 'Insufficient credit');
            expect(result['deficit'], 500000.0);
          },
        );
      },
    );

    test(
      'check purchase with existing balance',
      () async {
        // Create customer with existing balance
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

        // Add existing balance
        await repository.updateCustomerBalance(
          id: customerId!,
          amount: 600000.0,
          operation: 'add',
        );

        // Available credit = 1,000,000 - 600,000 = 400,000
        // Check if can purchase 300,000 (should succeed)
        final successResult = await repository.canMakePurchase(
          customerId: customerId!,
          amount: 300000.0,
        );

        successResult.fold(
          (failure) => fail('Check should succeed'),
          (result) {
            expect(result['canPurchase'], true);
            expect(result['availableCredit'], 400000.0);
          },
        );

        // Check if can purchase 500,000 (should fail)
        final failResult = await repository.canMakePurchase(
          customerId: customerId!,
          amount: 500000.0,
        );

        failResult.fold(
          (failure) => fail('Check should succeed'),
          (result) {
            expect(result['canPurchase'], false);
            expect(result['deficit'], 100000.0);
          },
        );
      },
    );

    test(
      'inactive customer cannot make purchase',
      () async {
        // Create inactive customer
        final createResult = await repository.createCustomer(
          firstName: 'Inactive',
          lastName: 'Customer',
          email: 'inactive@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          creditLimit: 1000000.0,
          status: CustomerStatus.inactive,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Check if can purchase (should fail due to status)
        final canPurchaseResult = await repository.canMakePurchase(
          customerId: customerId!,
          amount: 100000.0,
        );

        canPurchaseResult.fold(
          (failure) => fail('Check should succeed'),
          (result) {
            expect(result['canPurchase'], false);
            expect(result['reason'], 'Customer is not active');
          },
        );
      },
    );

    test(
      'update credit limit',
      () async {
        // Create customer
        final createResult = await repository.createCustomer(
          firstName: 'Credit',
          lastName: 'Customer',
          email: 'credit@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          creditLimit: 1000000.0,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Increase credit limit
        await repository.updateCustomer(
          id: customerId!,
          creditLimit: 2000000.0,
        );

        // Verify new limit
        final result = await repository.getCustomerById(customerId!);

        result.fold(
          (failure) => fail('Get should succeed'),
          (customer) => expect(customer.creditLimit, 2000000.0),
        );
      },
    );

    test(
      'get financial summary',
      () async {
        // Create customer
        final createResult = await repository.createCustomer(
          firstName: 'Financial',
          lastName: 'Customer',
          email: 'financial@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          creditLimit: 1000000.0,
          paymentTerms: 30,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Add balance
        await repository.updateCustomerBalance(
          id: customerId!,
          amount: 300000.0,
          operation: 'add',
        );

        // Get financial summary
        final summaryResult = await repository.getCustomerFinancialSummary(
          customerId!,
        );

        summaryResult.fold(
          (failure) => fail('Get summary should succeed'),
          (summary) {
            expect(summary['customerId'], customerId);
            expect(summary['creditLimit'], 1000000.0);
            expect(summary['currentBalance'], 300000.0);
            expect(summary['availableCredit'], 700000.0);
            expect(summary['paymentTerms'], 30);
            expect(summary['riskLevel'], 'low'); // 30% utilization
          },
        );
      },
    );

    test(
      'risk level calculation - low risk',
      () async {
        // Create customer with 50% credit utilization
        final createResult = await repository.createCustomer(
          firstName: 'Low',
          lastName: 'Risk',
          email: 'lowrisk@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          creditLimit: 1000000.0,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Add balance for 50% utilization
        await repository.updateCustomerBalance(
          id: customerId!,
          amount: 500000.0,
          operation: 'add',
        );

        final summaryResult = await repository.getCustomerFinancialSummary(
          customerId!,
        );

        summaryResult.fold(
          (failure) => fail('Get summary should succeed'),
          (summary) => expect(summary['riskLevel'], 'low'),
        );
      },
    );

    test(
      'risk level calculation - medium risk',
      () async {
        // Create customer with 75% credit utilization
        final createResult = await repository.createCustomer(
          firstName: 'Medium',
          lastName: 'Risk',
          email: 'mediumrisk@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          creditLimit: 1000000.0,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Add balance for 75% utilization
        await repository.updateCustomerBalance(
          id: customerId!,
          amount: 750000.0,
          operation: 'add',
        );

        final summaryResult = await repository.getCustomerFinancialSummary(
          customerId!,
        );

        summaryResult.fold(
          (failure) => fail('Get summary should succeed'),
          (summary) => expect(summary['riskLevel'], 'medium'),
        );
      },
    );

    test(
      'risk level calculation - high risk',
      () async {
        // Create customer with 95% credit utilization
        final createResult = await repository.createCustomer(
          firstName: 'High',
          lastName: 'Risk',
          email: 'highrisk@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          creditLimit: 1000000.0,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Add balance for 95% utilization
        await repository.updateCustomerBalance(
          id: customerId!,
          amount: 950000.0,
          operation: 'add',
        );

        final summaryResult = await repository.getCustomerFinancialSummary(
          customerId!,
        );

        summaryResult.fold(
          (failure) => fail('Get summary should succeed'),
          (summary) => expect(summary['riskLevel'], 'high'),
        );
      },
    );

    test(
      'record purchase updates balance and statistics',
      () async {
        // Create customer
        final createResult = await repository.createCustomer(
          firstName: 'Purchase',
          lastName: 'Customer',
          email: 'purchase@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          creditLimit: 1000000.0,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Record first purchase
        await repository.recordPurchase(
          customerId: customerId!,
          amount: 100000.0,
        );

        // Verify updates
        final result1 = await repository.getCustomerById(customerId!);
        result1.fold(
          (failure) => fail('Get should succeed'),
          (customer) {
            expect(customer.totalPurchases, 100000.0);
            expect(customer.totalOrders, 1);
            expect(customer.lastPurchaseAt, isNotNull);
          },
        );

        // Record second purchase
        await repository.recordPurchase(
          customerId: customerId!,
          amount: 150000.0,
        );

        // Verify cumulative updates
        final result2 = await repository.getCustomerById(customerId!);
        result2.fold(
          (failure) => fail('Get should succeed'),
          (customer) {
            expect(customer.totalPurchases, 250000.0);
            expect(customer.totalOrders, 2);
          },
        );
      },
    );

    test(
      'get customers at credit limit',
      () async {
        // Create customer at credit limit
        final createResult1 = await repository.createCustomer(
          firstName: 'AtLimit',
          lastName: 'Customer',
          email: 'atlimit@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
          creditLimit: 1000000.0,
        );

        String? customerId1;
        createResult1.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId1 = customer.id,
        );

        // Set balance at limit
        await repository.updateCustomerBalance(
          id: customerId1!,
          amount: 1000000.0,
          operation: 'add',
        );

        // Create customer under limit
        final createResult2 = await repository.createCustomer(
          firstName: 'UnderLimit',
          lastName: 'Customer',
          email: 'under@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
          creditLimit: 1000000.0,
        );

        String? customerId2;
        createResult2.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId2 = customer.id,
        );

        // Set balance under limit
        await repository.updateCustomerBalance(
          id: customerId2!,
          amount: 500000.0,
          operation: 'add',
        );

        // Get customers with overdue (balance > 0)
        final result = await repository.getCustomersWithOverdueInvoices();

        result.fold(
          (failure) => fail('Get should succeed'),
          (customers) {
            expect(customers.length, 2);
            // At limit customer should be first (higher balance)
            expect(customers.any((c) => c.currentBalance >= 1000000.0), true);
          },
        );
      },
    );

    test(
      'get customers over credit limit',
      () async {
        // Create customer over credit limit
        final createResult1 = await repository.createCustomer(
          firstName: 'OverLimit',
          lastName: 'Customer',
          email: 'overlimit@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
          creditLimit: 1000000.0,
        );

        String? customerId1;
        createResult1.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId1 = customer.id,
        );

        // Set balance over limit
        await repository.updateCustomerBalance(
          id: customerId1!,
          amount: 1200000.0,
          operation: 'add',
        );

        // Create customer within limit
        final createResult2 = await repository.createCustomer(
          firstName: 'WithinLimit',
          lastName: 'Customer',
          email: 'within@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
          creditLimit: 1000000.0,
        );

        String? customerId2;
        createResult2.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId2 = customer.id,
        );

        // Set balance within limit
        await repository.updateCustomerBalance(
          id: customerId2!,
          amount: 800000.0,
          operation: 'add',
        );

        // Get all customers and check
        final result = await repository.getCustomers();

        result.fold(
          (failure) => fail('Get should succeed'),
          (paginatedResult) {
            final overLimitCustomers = paginatedResult.data
                .where((c) => c.currentBalance > c.creditLimit)
                .toList();
            expect(overLimitCustomers.length, 1);
            expect(overLimitCustomers[0].firstName, 'OverLimit');
          },
        );
      },
    );

    test(
      'customer stats include credit information',
      () async {
        // Create diverse customers
        final createResult1 = await repository.createCustomer(
          firstName: 'Customer1',
          lastName: 'Test',
          email: 'customer1@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1111111111',
          creditLimit: 1000000.0,
        );

        final createResult2 = await repository.createCustomer(
          firstName: 'Customer2',
          lastName: 'Test',
          email: 'customer2@test.com',
          documentType: DocumentType.cc,
          documentNumber: '2222222222',
          creditLimit: 2000000.0,
        );

        final createResult3 = await repository.createCustomer(
          firstName: 'Customer3',
          lastName: 'Test',
          email: 'customer3@test.com',
          documentType: DocumentType.cc,
          documentNumber: '3333333333',
          creditLimit: 500000.0,
        );

        // Get IDs and update balances
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
          amount: 500000.0,
          operation: 'add',
        );

        await repository.updateCustomerBalance(
          id: customerId2!,
          amount: 1000000.0,
          operation: 'add',
        );

        // Get stats
        final statsResult = await repository.getCustomerStats();

        statsResult.fold(
          (failure) => fail('Get stats should succeed'),
          (stats) {
            expect(stats.total, 3);
            expect(stats.totalCreditLimit, 3500000.0);
            expect(stats.totalBalance, 1500000.0);
            expect(stats.customersWithOverdue, 2);
          },
        );
      },
    );

    test(
      'update payment terms',
      () async {
        // Create customer with default payment terms
        final createResult = await repository.createCustomer(
          firstName: 'Payment',
          lastName: 'Customer',
          email: 'payment@test.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          paymentTerms: 30,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // Update to 60 days
        await repository.updateCustomer(
          id: customerId!,
          paymentTerms: 60,
        );

        // Verify
        final result = await repository.getCustomerById(customerId!);

        result.fold(
          (failure) => fail('Get should succeed'),
          (customer) => expect(customer.paymentTerms, 60),
        );
      },
    );

    test(
      'complex credit scenario - multiple operations',
      () async {
        // Create VIP customer
        final createResult = await repository.createCustomer(
          firstName: 'VIP',
          lastName: 'Customer',
          email: 'vip@test.com',
          documentType: DocumentType.nit,
          documentNumber: '900123456-1',
          creditLimit: 5000000.0,
          paymentTerms: 60,
        );

        String? customerId;
        createResult.fold(
          (failure) => fail('Create should succeed'),
          (customer) => customerId = customer.id,
        );

        // 1. Make first purchase
        await repository.recordPurchase(
          customerId: customerId!,
          amount: 1000000.0,
        );

        await repository.updateCustomerBalance(
          id: customerId!,
          amount: 1000000.0,
          operation: 'add',
        );

        // 2. Check can make another purchase
        final canPurchase1 = await repository.canMakePurchase(
          customerId: customerId!,
          amount: 2000000.0,
        );

        canPurchase1.fold(
          (failure) => fail('Check should succeed'),
          (result) {
            expect(result['canPurchase'], true);
            expect(result['availableCredit'], 4000000.0);
          },
        );

        // 3. Make second purchase
        await repository.recordPurchase(
          customerId: customerId!,
          amount: 2000000.0,
        );

        await repository.updateCustomerBalance(
          id: customerId!,
          amount: 2000000.0,
          operation: 'add',
        );

        // 4. Customer pays 500,000
        await repository.updateCustomerBalance(
          id: customerId!,
          amount: 500000.0,
          operation: 'subtract',
        );

        // 5. Get financial summary
        final summary = await repository.getCustomerFinancialSummary(
          customerId!,
        );

        summary.fold(
          (failure) => fail('Get summary should succeed'),
          (result) {
            expect(result['currentBalance'], 2500000.0); // 3M - 500K
            expect(result['availableCredit'], 2500000.0); // 5M - 2.5M
            expect(result['totalPurchases'], 3000000.0);
            expect(result['totalOrders'], 2);
            expect(result['riskLevel'], 'low'); // 50% utilization
          },
        );
      },
    );
  });
}
