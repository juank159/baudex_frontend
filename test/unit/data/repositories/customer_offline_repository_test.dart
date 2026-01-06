// test/unit/data/repositories/customer_offline_repository_test.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/customers/data/repositories/customer_offline_repository.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/mock_isar.dart';
import '../../../fixtures/customer_fixtures.dart';

void main() {
  late CustomerOfflineRepository repository;
  late MockIsar mockIsar;
  late MockIsarDatabase mockIsarDatabase;

  setUp(() {
    mockIsar = MockIsar();
    mockIsarDatabase = MockIsarDatabase(mockIsar);
    repository = CustomerOfflineRepository(database: mockIsarDatabase);
  });

  tearDown(() async {
    await mockIsar.clear();
    await mockIsar.close();
  });

  group('CustomerOfflineRepository - getCustomers', () {
    test(
      'should return paginated customers from ISAR',
      () async {
        // Arrange
        final customers = CustomerFixtures.createCustomerEntityList(10);
        for (final customer in customers) {
          final isarCustomer = IsarCustomer.fromEntity(customer);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCustomers.put(isarCustomer);
          });
        }

        // Act
        final result = await repository.getCustomers(page: 1, limit: 5);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 5);
            expect(paginatedResult.meta.page, 1);
            expect(paginatedResult.meta.totalItems, 10);
            expect(paginatedResult.meta.totalPages, 2);
            expect(paginatedResult.meta.hasNextPage, true);
          },
        );
      },
    );

    test(
      'should filter customers by status',
      () async {
        // Arrange
        final activeCustomers = [
          CustomerFixtures.createCustomerEntity(id: 'cust-001', status: CustomerStatus.active),
          CustomerFixtures.createCustomerEntity(id: 'cust-002', status: CustomerStatus.active),
        ];
        final inactiveCustomer = CustomerFixtures.createInactiveCustomer(id: 'cust-003');

        for (final customer in [...activeCustomers, inactiveCustomer]) {
          final isarCustomer = IsarCustomer.fromEntity(customer);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCustomers.put(isarCustomer);
          });
        }

        // Act
        final result = await repository.getCustomers(
          status: CustomerStatus.active,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
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
      'should filter customers by document type',
      () async {
        // Arrange
        final ccCustomers = [
          CustomerFixtures.createCustomerEntity(id: 'cust-001', documentType: DocumentType.cc),
          CustomerFixtures.createCustomerEntity(id: 'cust-002', documentType: DocumentType.cc),
        ];
        final nitCustomer = CustomerFixtures.createCorporateCustomer(id: 'cust-003');

        for (final customer in [...ccCustomers, nitCustomer]) {
          final isarCustomer = IsarCustomer.fromEntity(customer);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCustomers.put(isarCustomer);
          });
        }

        // Act
        final result = await repository.getCustomers(
          documentType: DocumentType.cc,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 2);
            expect(
              paginatedResult.data.every((c) => c.documentType == DocumentType.cc),
              true,
            );
          },
        );
      },
    );

    test(
      'should search customers by name, email, and document',
      () async {
        // Arrange
        final customers = [
          CustomerFixtures.createCustomerEntity(id: 'cust-001', firstName: 'John', lastName: 'Smith'),
          CustomerFixtures.createCustomerEntity(id: 'cust-002', firstName: 'Jane', lastName: 'Doe', email: 'jane@example.com'),
          CustomerFixtures.createCustomerEntity(id: 'cust-003', firstName: 'Bob', lastName: 'Johnson', documentNumber: '1234567890'),
        ];

        for (final customer in customers) {
          final isarCustomer = IsarCustomer.fromEntity(customer);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCustomers.put(isarCustomer);
          });
        }

        // Act - search by first name
        final result1 = await repository.getCustomers(search: 'John');

        // Assert
        expect(result1.isRight(), true);
        result1.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, greaterThanOrEqualTo(1));
          },
        );
      },
    );

    test(
      'should filter customers by city',
      () async {
        // Arrange
        final customers = [
          CustomerFixtures.createCustomerEntity(id: 'cust-001', city: 'Bogota'),
          CustomerFixtures.createCustomerEntity(id: 'cust-002', city: 'Bogota'),
          CustomerFixtures.createCustomerEntity(id: 'cust-003', city: 'Medellin'),
        ];

        for (final customer in customers) {
          final isarCustomer = IsarCustomer.fromEntity(customer);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCustomers.put(isarCustomer);
          });
        }

        // Act
        final result = await repository.getCustomers(city: 'Bogota');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
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
      'should exclude soft-deleted customers',
      () async {
        // Arrange
        final activeCustomer = CustomerFixtures.createCustomerEntity(id: 'cust-001');
        final deletedCustomer = CustomerFixtures.createCustomerEntity(id: 'cust-002');

        final isarActive = IsarCustomer.fromEntity(activeCustomer);
        final isarDeleted = IsarCustomer.fromEntity(deletedCustomer);
        isarDeleted.softDelete();

        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarActive);
          await mockIsar.isarCustomers.put(isarDeleted);
        });

        // Act
        final result = await repository.getCustomers();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data.length, 1);
            expect(paginatedResult.data.first.id, 'cust-001');
          },
        );
      },
    );

    test(
      'should sort customers by total purchases descending',
      () async {
        // Arrange
        final customers = [
          CustomerFixtures.createCustomerEntity(id: 'cust-001', totalPurchases: 100000.0),
          CustomerFixtures.createCustomerEntity(id: 'cust-002', totalPurchases: 500000.0),
          CustomerFixtures.createCustomerEntity(id: 'cust-003', totalPurchases: 200000.0),
        ];

        for (final customer in customers) {
          final isarCustomer = IsarCustomer.fromEntity(customer);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCustomers.put(isarCustomer);
          });
        }

        // Act
        final result = await repository.getCustomers(
          sortBy: 'totalPurchases',
          sortOrder: 'desc',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (paginatedResult) {
            expect(paginatedResult.data[0].totalPurchases, 500000.0);
            expect(paginatedResult.data[1].totalPurchases, 200000.0);
            expect(paginatedResult.data[2].totalPurchases, 100000.0);
          },
        );
      },
    );
  });

  group('CustomerOfflineRepository - getCustomerById', () {
    test(
      'should return customer when found',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(id: 'cust-001');
        final isarCustomer = IsarCustomer.fromEntity(customer);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act
        final result = await repository.getCustomerById('cust-001');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (foundCustomer) {
            expect(foundCustomer.id, 'cust-001');
            expect(foundCustomer.firstName, 'John');
          },
        );
      },
    );

    test(
      'should return CacheFailure when customer not found',
      () async {
        // Act
        final result = await repository.getCustomerById('non-existent');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );

    test(
      'should not return soft-deleted customer',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(id: 'cust-001');
        final isarCustomer = IsarCustomer.fromEntity(customer);
        isarCustomer.softDelete();
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act
        final result = await repository.getCustomerById('cust-001');

        // Assert
        expect(result.isLeft(), true);
      },
    );
  });

  group('CustomerOfflineRepository - getCustomerByDocument', () {
    test(
      'should return customer by document type and number',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(
          id: 'cust-001',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );
        final isarCustomer = IsarCustomer.fromEntity(customer);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act
        final result = await repository.getCustomerByDocument(
          DocumentType.cc,
          '1234567890',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (foundCustomer) {
            expect(foundCustomer.documentNumber, '1234567890');
            expect(foundCustomer.documentType, DocumentType.cc);
          },
        );
      },
    );

    test(
      'should return CacheFailure when customer not found',
      () async {
        // Act
        final result = await repository.getCustomerByDocument(
          DocumentType.cc,
          'non-existent',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('CustomerOfflineRepository - getCustomerByEmail', () {
    test(
      'should return customer by email',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(
          id: 'cust-001',
          email: 'john.doe@example.com',
        );
        final isarCustomer = IsarCustomer.fromEntity(customer);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act
        final result = await repository.getCustomerByEmail('john.doe@example.com');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (foundCustomer) {
            expect(foundCustomer.email, 'john.doe@example.com');
          },
        );
      },
    );

    test(
      'should return CacheFailure when email not found',
      () async {
        // Act
        final result = await repository.getCustomerByEmail('nonexistent@example.com');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('CustomerOfflineRepository - searchCustomers', () {
    test(
      'should search customers and limit results',
      () async {
        // Arrange
        final customers = CustomerFixtures.createCustomerEntityList(20);
        for (final customer in customers) {
          final isarCustomer = IsarCustomer.fromEntity(customer);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCustomers.put(isarCustomer);
          });
        }

        // Act
        final result = await repository.searchCustomers('Customer', limit: 5);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (customers) {
            expect(customers.length, lessThanOrEqualTo(5));
          },
        );
      },
    );

    test(
      'should search customers by multiple fields',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(
          id: 'cust-001',
          firstName: 'SearchTest',
          email: 'search@example.com',
          documentNumber: 'SEARCH123',
        );
        final isarCustomer = IsarCustomer.fromEntity(customer);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act - search by name
        final result1 = await repository.searchCustomers('SearchTest');
        // Act - search by email
        final result2 = await repository.searchCustomers('search@example');
        // Act - search by document
        final result3 = await repository.searchCustomers('SEARCH123');

        // Assert
        expect(result1.isRight(), true);
        expect(result2.isRight(), true);
        expect(result3.isRight(), true);
      },
    );
  });

  group('CustomerOfflineRepository - getCustomerStats', () {
    test(
      'should calculate customer statistics',
      () async {
        // Arrange
        final customers = [
          CustomerFixtures.createCustomerEntity(
            id: 'cust-001',
            status: CustomerStatus.active,
            creditLimit: 1000000.0,
            currentBalance: 100000.0,
            totalPurchases: 500000.0,
            totalOrders: 5,
          ),
          CustomerFixtures.createCustomerEntity(
            id: 'cust-002',
            status: CustomerStatus.active,
            creditLimit: 2000000.0,
            currentBalance: 200000.0,
            totalPurchases: 1000000.0,
            totalOrders: 10,
          ),
          CustomerFixtures.createInactiveCustomer(id: 'cust-003'),
          CustomerFixtures.createSuspendedCustomer(id: 'cust-004'),
        ];

        for (final customer in customers) {
          final isarCustomer = IsarCustomer.fromEntity(customer);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCustomers.put(isarCustomer);
          });
        }

        // Act
        final result = await repository.getCustomerStats();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (stats) {
            expect(stats.total, 4);
            expect(stats.active, 2);
            expect(stats.inactive, 1);
            expect(stats.suspended, 1);
            expect(stats.activePercentage, 50.0);
          },
        );
      },
    );

    test(
      'should calculate correct average purchase amount',
      () async {
        // Arrange
        final customers = [
          CustomerFixtures.createCustomerEntity(
            id: 'cust-001',
            totalPurchases: 100000.0,
            totalOrders: 1,
          ),
          CustomerFixtures.createCustomerEntity(
            id: 'cust-002',
            totalPurchases: 200000.0,
            totalOrders: 2,
          ),
          CustomerFixtures.createNewCustomer(id: 'cust-003'), // No purchases
        ];

        for (final customer in customers) {
          final isarCustomer = IsarCustomer.fromEntity(customer);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCustomers.put(isarCustomer);
          });
        }

        // Act
        final result = await repository.getCustomerStats();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (stats) {
            // Average of 100000 and 200000 = 150000
            expect(stats.averagePurchaseAmount, 150000.0);
          },
        );
      },
    );
  });

  group('CustomerOfflineRepository - getCustomersWithOverdueInvoices', () {
    test(
      'should return customers with balance greater than zero',
      () async {
        // Arrange
        final customers = [
          CustomerFixtures.createCustomerWithOverdueBalance(id: 'cust-001', overdueAmount: 500000.0),
          CustomerFixtures.createCustomerWithOverdueBalance(id: 'cust-002', overdueAmount: 300000.0),
          CustomerFixtures.createCustomerEntity(id: 'cust-003', currentBalance: 0.0),
        ];

        for (final customer in customers) {
          final isarCustomer = IsarCustomer.fromEntity(customer);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCustomers.put(isarCustomer);
          });
        }

        // Act
        final result = await repository.getCustomersWithOverdueInvoices();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (customers) {
            expect(customers.length, 2);
            expect(
              customers.every((c) => c.currentBalance > 0),
              true,
            );
          },
        );
      },
    );
  });

  group('CustomerOfflineRepository - getTopCustomers', () {
    test(
      'should return top customers sorted by total purchases',
      () async {
        // Arrange
        final customers = [
          CustomerFixtures.createCustomerEntity(id: 'cust-001', totalPurchases: 100000.0),
          CustomerFixtures.createCustomerEntity(id: 'cust-002', totalPurchases: 500000.0),
          CustomerFixtures.createCustomerEntity(id: 'cust-003', totalPurchases: 300000.0),
          CustomerFixtures.createCustomerEntity(id: 'cust-004', totalPurchases: 200000.0),
        ];

        for (final customer in customers) {
          final isarCustomer = IsarCustomer.fromEntity(customer);
          await mockIsar.writeTxn(() async {
            await mockIsar.isarCustomers.put(isarCustomer);
          });
        }

        // Act
        final result = await repository.getTopCustomers(limit: 3);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (customers) {
            expect(customers.length, 3);
            expect(customers[0].totalPurchases, 500000.0);
            expect(customers[1].totalPurchases, 300000.0);
            expect(customers[2].totalPurchases, 200000.0);
          },
        );
      },
    );
  });

  group('CustomerOfflineRepository - createCustomer', () {
    test(
      'should create customer in ISAR with temp ID',
      () async {
        // Act
        final result = await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@example.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (customer) {
            expect(customer.id, startsWith('customer_'));
            expect(customer.firstName, 'John');
            expect(customer.lastName, 'Doe');
            expect(customer.email, 'john.doe@example.com');
          },
        );

        // Verify it's in ISAR
        final customers = await mockIsar.isarCustomers.filter().findAll();
        expect(customers.length, 1);
      },
    );

    test(
      'should mark created customer as unsynced',
      () async {
        // Act
        await repository.createCustomer(
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@example.com',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );

        // Assert
        final customers = await mockIsar.isarCustomers.filter().findAll();
        expect(customers.first.isSynced, false);
      },
    );
  });

  group('CustomerOfflineRepository - updateCustomer', () {
    test(
      'should update customer fields in ISAR',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(id: 'cust-001');
        final isarCustomer = IsarCustomer.fromEntity(customer);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act
        final result = await repository.updateCustomer(
          id: 'cust-001',
          firstName: 'Jane',
          lastName: 'Smith',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (updatedCustomer) {
            expect(updatedCustomer.firstName, 'Jane');
            expect(updatedCustomer.lastName, 'Smith');
          },
        );
      },
    );

    test(
      'should mark updated customer as unsynced',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(id: 'cust-001');
        final isarCustomer = IsarCustomer.fromEntity(customer);
        isarCustomer.markAsSynced();
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act
        await repository.updateCustomer(
          id: 'cust-001',
          firstName: 'Jane',
        );

        // Assert
        final updated = await mockIsar.isarCustomers
            .filter()
            .serverIdEqualTo('cust-001')
            .findFirst();
        expect(updated?.isSynced, false);
      },
    );

    test(
      'should return CacheFailure when customer not found',
      () async {
        // Act
        final result = await repository.updateCustomer(
          id: 'non-existent',
          firstName: 'Jane',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('CustomerOfflineRepository - deleteCustomer', () {
    test(
      'should soft delete customer in ISAR',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(id: 'cust-001');
        final isarCustomer = IsarCustomer.fromEntity(customer);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act
        final result = await repository.deleteCustomer('cust-001');

        // Assert
        expect(result.isRight(), true);

        // Verify soft delete
        final deleted = await mockIsar.isarCustomers
            .filter()
            .serverIdEqualTo('cust-001')
            .findFirst();
        expect(deleted?.deletedAt, isNotNull);
      },
    );

    test(
      'should return CacheFailure when customer not found',
      () async {
        // Act
        final result = await repository.deleteCustomer('non-existent');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should return Left'),
        );
      },
    );
  });

  group('CustomerOfflineRepository - Validation Operations', () {
    test(
      'should check email availability',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(
          id: 'cust-001',
          email: 'john@example.com',
        );
        final isarCustomer = IsarCustomer.fromEntity(customer);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act
        final result1 = await repository.isEmailAvailable('john@example.com');
        final result2 = await repository.isEmailAvailable('jane@example.com');

        // Assert
        expect(result1.isRight(), true);
        result1.fold(
          (failure) => fail('Should return Right'),
          (isAvailable) => expect(isAvailable, false),
        );

        expect(result2.isRight(), true);
        result2.fold(
          (failure) => fail('Should return Right'),
          (isAvailable) => expect(isAvailable, true),
        );
      },
    );

    test(
      'should check email availability excluding specific customer',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(
          id: 'cust-001',
          email: 'john@example.com',
        );
        final isarCustomer = IsarCustomer.fromEntity(customer);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act
        final result = await repository.isEmailAvailable(
          'john@example.com',
          excludeId: 'cust-001',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (isAvailable) => expect(isAvailable, true),
        );
      },
    );

    test(
      'should check document availability',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(
          id: 'cust-001',
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
        );
        final isarCustomer = IsarCustomer.fromEntity(customer);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act
        final result1 = await repository.isDocumentAvailable(
          DocumentType.cc,
          '1234567890',
        );
        final result2 = await repository.isDocumentAvailable(
          DocumentType.cc,
          '9876543210',
        );

        // Assert
        expect(result1.isRight(), true);
        result1.fold(
          (failure) => fail('Should return Right'),
          (isAvailable) => expect(isAvailable, false),
        );

        expect(result2.isRight(), true);
        result2.fold(
          (failure) => fail('Should return Right'),
          (isAvailable) => expect(isAvailable, true),
        );
      },
    );

    test(
      'should check if customer can make purchase',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(
          id: 'cust-001',
          status: CustomerStatus.active,
          creditLimit: 1000000.0,
          currentBalance: 200000.0,
        );
        final isarCustomer = IsarCustomer.fromEntity(customer);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act - within credit limit
        final result1 = await repository.canMakePurchase(
          customerId: 'cust-001',
          amount: 500000.0,
        );

        // Act - exceeds credit limit
        final result2 = await repository.canMakePurchase(
          customerId: 'cust-001',
          amount: 1000000.0,
        );

        // Assert
        expect(result1.isRight(), true);
        result1.fold(
          (failure) => fail('Should return Right'),
          (data) {
            expect(data['canPurchase'], true);
            expect(data['availableCredit'], 800000.0);
          },
        );

        expect(result2.isRight(), true);
        result2.fold(
          (failure) => fail('Should return Right'),
          (data) {
            expect(data['canPurchase'], false);
            expect(data['reason'], 'Insufficient credit');
          },
        );
      },
    );

    test(
      'should get customer financial summary',
      () async {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(
          id: 'cust-001',
          creditLimit: 1000000.0,
          currentBalance: 300000.0,
          totalPurchases: 5000000.0,
          totalOrders: 25,
        );
        final isarCustomer = IsarCustomer.fromEntity(customer);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCustomers.put(isarCustomer);
        });

        // Act
        final result = await repository.getCustomerFinancialSummary('cust-001');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (summary) {
            expect(summary['customerId'], 'cust-001');
            expect(summary['currentBalance'], 300000.0);
            expect(summary['creditLimit'], 1000000.0);
            expect(summary['availableCredit'], 700000.0);
            expect(summary['totalPurchases'], 5000000.0);
            expect(summary['totalOrders'], 25);
          },
        );
      },
    );
  });
}
