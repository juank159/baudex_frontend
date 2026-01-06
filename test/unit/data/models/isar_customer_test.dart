// test/unit/data/models/isar_customer_test.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/customer_fixtures.dart';

void main() {
  group('IsarCustomer', () {
    final tCustomer = CustomerFixtures.createCustomerEntity();

    group('fromEntity', () {
      test('should convert Customer entity to IsarCustomer', () {
        // Act
        final result = IsarCustomer.fromEntity(tCustomer);

        // Assert
        expect(result, isA<IsarCustomer>());
        expect(result.serverId, tCustomer.id);
        expect(result.firstName, tCustomer.firstName);
        expect(result.lastName, tCustomer.lastName);
        expect(result.email, tCustomer.email);
        expect(result.documentNumber, tCustomer.documentNumber);
      });

      test('should map DocumentType enum to IsarDocumentType', () {
        // Arrange
        final passportCustomer = CustomerFixtures.createCustomerWithPassport();

        // Act
        final result = IsarCustomer.fromEntity(passportCustomer);

        // Assert
        expect(result.documentType, IsarDocumentType.passport);
      });

      test('should map CustomerStatus enum to IsarCustomerStatus', () {
        // Arrange
        final inactiveCustomer = CustomerFixtures.createInactiveCustomer();

        // Act
        final result = IsarCustomer.fromEntity(inactiveCustomer);

        // Assert
        expect(result.status, IsarCustomerStatus.inactive);
      });

      test('should mark as synced by default', () {
        // Act
        final result = IsarCustomer.fromEntity(tCustomer);

        // Assert
        expect(result.isSynced, true);
        expect(result.lastSyncAt, isNotNull);
      });

      test('should handle null optional fields', () {
        // Arrange
        final customerWithNulls = CustomerFixtures.createCustomerEntity(
          companyName: null,
          phone: null,
          mobile: null,
          address: null,
          city: null,
          state: null,
          zipCode: null,
          country: null,
        );

        // Act
        final result = IsarCustomer.fromEntity(customerWithNulls);

        // Assert
        expect(result.companyName, isNull);
        expect(result.phone, isNull);
        expect(result.mobile, isNull);
        expect(result.address, isNull);
        expect(result.city, isNull);
        expect(result.state, isNull);
        expect(result.zipCode, isNull);
        expect(result.country, isNull);
      });

      test('should convert all document types correctly', () {
        // Test CC
        final ccCustomer = CustomerFixtures.createCustomerEntity(
          documentType: DocumentType.cc,
        );
        final ccResult = IsarCustomer.fromEntity(ccCustomer);
        expect(ccResult.documentType, IsarDocumentType.cc);

        // Test NIT
        final nitCustomer = CustomerFixtures.createCorporateCustomer();
        final nitResult = IsarCustomer.fromEntity(nitCustomer);
        expect(nitResult.documentType, IsarDocumentType.nit);

        // Test CE
        final ceCustomer = CustomerFixtures.createCustomerEntity(
          documentType: DocumentType.ce,
        );
        final ceResult = IsarCustomer.fromEntity(ceCustomer);
        expect(ceResult.documentType, IsarDocumentType.ce);

        // Test Passport
        final passportCustomer = CustomerFixtures.createCustomerWithPassport();
        final passportResult = IsarCustomer.fromEntity(passportCustomer);
        expect(passportResult.documentType, IsarDocumentType.passport);

        // Test Other
        final otherCustomer = CustomerFixtures.createCustomerEntity(
          documentType: DocumentType.other,
        );
        final otherResult = IsarCustomer.fromEntity(otherCustomer);
        expect(otherResult.documentType, IsarDocumentType.other);
      });

      test('should convert all customer statuses correctly', () {
        // Test Active
        final activeCustomer = CustomerFixtures.createCustomerEntity(
          status: CustomerStatus.active,
        );
        final activeResult = IsarCustomer.fromEntity(activeCustomer);
        expect(activeResult.status, IsarCustomerStatus.active);

        // Test Inactive
        final inactiveCustomer = CustomerFixtures.createInactiveCustomer();
        final inactiveResult = IsarCustomer.fromEntity(inactiveCustomer);
        expect(inactiveResult.status, IsarCustomerStatus.inactive);

        // Test Suspended
        final suspendedCustomer = CustomerFixtures.createSuspendedCustomer();
        final suspendedResult = IsarCustomer.fromEntity(suspendedCustomer);
        expect(suspendedResult.status, IsarCustomerStatus.suspended);
      });

      test('should handle financial data correctly', () {
        // Arrange
        final customerWithBalance = CustomerFixtures.createCustomerWithOverdueBalance(
          overdueAmount: 500000.0,
        );

        // Act
        final result = IsarCustomer.fromEntity(customerWithBalance);

        // Assert
        expect(result.creditLimit, customerWithBalance.creditLimit);
        expect(result.currentBalance, customerWithBalance.currentBalance);
        expect(result.paymentTerms, customerWithBalance.paymentTerms);
      });

      test('should handle purchase statistics correctly', () {
        // Arrange
        final vipCustomer = CustomerFixtures.createVIPCustomer();

        // Act
        final result = IsarCustomer.fromEntity(vipCustomer);

        // Assert
        expect(result.totalPurchases, vipCustomer.totalPurchases);
        expect(result.totalOrders, vipCustomer.totalOrders);
      });
    });

    group('toEntity', () {
      test('should convert IsarCustomer to Customer entity', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);

        // Act
        final result = isarCustomer.toEntity();

        // Assert
        expect(result, isA<Customer>());
        expect(result.id, isarCustomer.serverId);
        expect(result.firstName, isarCustomer.firstName);
        expect(result.lastName, isarCustomer.lastName);
        expect(result.email, isarCustomer.email);
      });

      test('should map IsarDocumentType to DocumentType enum', () {
        // Arrange
        final passportCustomer = CustomerFixtures.createCustomerWithPassport();
        final isarCustomer = IsarCustomer.fromEntity(passportCustomer);

        // Act
        final result = isarCustomer.toEntity();

        // Assert
        expect(result.documentType, DocumentType.passport);
      });

      test('should map IsarCustomerStatus to CustomerStatus enum', () {
        // Arrange
        final suspendedCustomer = CustomerFixtures.createSuspendedCustomer();
        final isarCustomer = IsarCustomer.fromEntity(suspendedCustomer);

        // Act
        final result = isarCustomer.toEntity();

        // Assert
        expect(result.status, CustomerStatus.suspended);
      });

      test('should preserve financial data', () {
        // Arrange
        final customerAtLimit = CustomerFixtures.createCustomerAtCreditLimit();
        final isarCustomer = IsarCustomer.fromEntity(customerAtLimit);

        // Act
        final result = isarCustomer.toEntity();

        // Assert
        expect(result.creditLimit, customerAtLimit.creditLimit);
        expect(result.currentBalance, customerAtLimit.currentBalance);
        expect(result.paymentTerms, customerAtLimit.paymentTerms);
      });
    });

    group('utility methods', () {
      test('isDeleted should return true when deletedAt is set', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        isarCustomer.deletedAt = DateTime.now();

        // Act & Assert
        expect(isarCustomer.isDeleted, true);
      });

      test('isDeleted should return false when deletedAt is null', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);

        // Act & Assert
        expect(isarCustomer.isDeleted, false);
      });

      test('isActive should return true when status is active and not deleted', () {
        // Arrange
        final activeCustomer = CustomerFixtures.createCustomerEntity(
          status: CustomerStatus.active,
        );
        final isarCustomer = IsarCustomer.fromEntity(activeCustomer);

        // Act & Assert
        expect(isarCustomer.isActive, true);
      });

      test('isActive should return false when deleted', () {
        // Arrange
        final activeCustomer = CustomerFixtures.createCustomerEntity(
          status: CustomerStatus.active,
        );
        final isarCustomer = IsarCustomer.fromEntity(activeCustomer);
        isarCustomer.deletedAt = DateTime.now();

        // Act & Assert
        expect(isarCustomer.isActive, false);
      });

      test('isActive should return false when status is inactive', () {
        // Arrange
        final inactiveCustomer = CustomerFixtures.createInactiveCustomer();
        final isarCustomer = IsarCustomer.fromEntity(inactiveCustomer);

        // Act & Assert
        expect(isarCustomer.isActive, false);
      });

      test('needsSync should return true when isSynced is false', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        isarCustomer.isSynced = false;

        // Act & Assert
        expect(isarCustomer.needsSync, true);
      });

      test('needsSync should return false when isSynced is true', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        isarCustomer.isSynced = true;

        // Act & Assert
        expect(isarCustomer.needsSync, false);
      });

      test('hasCredit should return true when creditLimit > 0', () {
        // Arrange
        final vipCustomer = CustomerFixtures.createVIPCustomer();
        final isarCustomer = IsarCustomer.fromEntity(vipCustomer);

        // Act & Assert
        expect(isarCustomer.hasCredit, true);
      });

      test('hasCredit should return false when creditLimit = 0', () {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(
          creditLimit: 0.0,
        );
        final isarCustomer = IsarCustomer.fromEntity(customer);

        // Act & Assert
        expect(isarCustomer.hasCredit, false);
      });

      test('isOverCreditLimit should return true when balance > limit', () {
        // Arrange
        final overLimitCustomer = CustomerFixtures.createCustomerOverCreditLimit();
        final isarCustomer = IsarCustomer.fromEntity(overLimitCustomer);

        // Act & Assert
        expect(isarCustomer.isOverCreditLimit, true);
      });

      test('isOverCreditLimit should return false when balance <= limit', () {
        // Arrange
        final normalCustomer = CustomerFixtures.createCustomerEntity();
        final isarCustomer = IsarCustomer.fromEntity(normalCustomer);

        // Act & Assert
        expect(isarCustomer.isOverCreditLimit, false);
      });

      test('fullName should return combined first and last name', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);

        // Act
        final result = isarCustomer.fullName;

        // Assert
        expect(result, '${tCustomer.firstName} ${tCustomer.lastName}');
      });

      test('displayName should return companyName when available', () {
        // Arrange
        final corporateCustomer = CustomerFixtures.createCorporateCustomer();
        final isarCustomer = IsarCustomer.fromEntity(corporateCustomer);

        // Act
        final result = isarCustomer.displayName;

        // Assert
        expect(result, corporateCustomer.companyName);
      });

      test('displayName should return fullName when no companyName', () {
        // Arrange
        final individualCustomer = CustomerFixtures.createIndividualCustomer();
        final isarCustomer = IsarCustomer.fromEntity(individualCustomer);

        // Act
        final result = isarCustomer.displayName;

        // Assert
        expect(result, isarCustomer.fullName);
      });
    });

    group('sync methods', () {
      test('markAsUnsynced should set isSynced to false', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        isarCustomer.isSynced = true;

        // Act
        isarCustomer.markAsUnsynced();

        // Assert
        expect(isarCustomer.isSynced, false);
      });

      test('markAsUnsynced should update updatedAt timestamp', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        final oldUpdatedAt = isarCustomer.updatedAt;

        // Wait a tiny bit to ensure timestamp difference
        Future.delayed(const Duration(milliseconds: 10));

        // Act
        isarCustomer.markAsUnsynced();

        // Assert
        expect(
          isarCustomer.updatedAt.isAfter(oldUpdatedAt) ||
              isarCustomer.updatedAt.isAtSameMomentAs(oldUpdatedAt),
          true,
        );
      });

      test('markAsSynced should set isSynced to true', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        isarCustomer.isSynced = false;

        // Act
        isarCustomer.markAsSynced();

        // Assert
        expect(isarCustomer.isSynced, true);
      });

      test('markAsSynced should update lastSyncAt timestamp', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        final oldLastSyncAt = isarCustomer.lastSyncAt;

        // Act
        isarCustomer.markAsSynced();

        // Assert
        expect(isarCustomer.lastSyncAt, isNotNull);
        if (oldLastSyncAt != null) {
          expect(
            isarCustomer.lastSyncAt!.isAfter(oldLastSyncAt) ||
                isarCustomer.lastSyncAt!.isAtSameMomentAs(oldLastSyncAt),
            true,
          );
        }
      });
    });

    group('soft delete', () {
      test('softDelete should set deletedAt timestamp', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);

        // Act
        isarCustomer.softDelete();

        // Assert
        expect(isarCustomer.deletedAt, isNotNull);
        expect(isarCustomer.isDeleted, true);
      });

      test('softDelete should mark as unsynced', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        isarCustomer.isSynced = true;

        // Act
        isarCustomer.softDelete();

        // Assert
        expect(isarCustomer.isSynced, false);
      });
    });

    group('financial operations', () {
      test('updateBalance should add positive amount', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        final initialBalance = isarCustomer.currentBalance;

        // Act
        isarCustomer.updateBalance(100000.0);

        // Assert
        expect(isarCustomer.currentBalance, initialBalance + 100000.0);
      });

      test('updateBalance should subtract negative amount', () {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity(
          currentBalance: 500000.0,
        );
        final isarCustomer = IsarCustomer.fromEntity(customer);
        final initialBalance = isarCustomer.currentBalance;

        // Act
        isarCustomer.updateBalance(-100000.0);

        // Assert
        expect(isarCustomer.currentBalance, initialBalance - 100000.0);
      });

      test('updateBalance should mark as unsynced', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        isarCustomer.isSynced = true;

        // Act
        isarCustomer.updateBalance(50000.0);

        // Assert
        expect(isarCustomer.isSynced, false);
      });

      test('recordPurchase should update totalPurchases', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        final initialPurchases = isarCustomer.totalPurchases;

        // Act
        isarCustomer.recordPurchase(250000.0);

        // Assert
        expect(isarCustomer.totalPurchases, initialPurchases + 250000.0);
      });

      test('recordPurchase should increment totalOrders', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        final initialOrders = isarCustomer.totalOrders;

        // Act
        isarCustomer.recordPurchase(250000.0);

        // Assert
        expect(isarCustomer.totalOrders, initialOrders + 1);
      });

      test('recordPurchase should update lastPurchaseAt', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);

        // Act
        isarCustomer.recordPurchase(250000.0);

        // Assert
        expect(isarCustomer.lastPurchaseAt, isNotNull);
      });

      test('recordPurchase should mark as unsynced', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);
        isarCustomer.isSynced = true;

        // Act
        isarCustomer.recordPurchase(250000.0);

        // Assert
        expect(isarCustomer.isSynced, false);
      });
    });

    group('entity roundtrip', () {
      test('should maintain data integrity through fromEntity -> toEntity', () {
        // Arrange
        final originalCustomer = tCustomer;

        // Act
        final isarCustomer = IsarCustomer.fromEntity(originalCustomer);
        final reconstructedCustomer = isarCustomer.toEntity();

        // Assert
        expect(reconstructedCustomer.id, originalCustomer.id);
        expect(reconstructedCustomer.firstName, originalCustomer.firstName);
        expect(reconstructedCustomer.lastName, originalCustomer.lastName);
        expect(reconstructedCustomer.email, originalCustomer.email);
        expect(reconstructedCustomer.documentNumber, originalCustomer.documentNumber);
        expect(reconstructedCustomer.documentType, originalCustomer.documentType);
        expect(reconstructedCustomer.status, originalCustomer.status);
        expect(reconstructedCustomer.creditLimit, originalCustomer.creditLimit);
        expect(reconstructedCustomer.currentBalance, originalCustomer.currentBalance);
      });

      test('should handle corporate customer roundtrip', () {
        // Arrange
        final corporateCustomer = CustomerFixtures.createCorporateCustomer();

        // Act
        final isarCustomer = IsarCustomer.fromEntity(corporateCustomer);
        final reconstructedCustomer = isarCustomer.toEntity();

        // Assert
        expect(reconstructedCustomer.companyName, corporateCustomer.companyName);
        expect(reconstructedCustomer.documentType, DocumentType.nit);
      });

      test('should handle VIP customer roundtrip', () {
        // Arrange
        final vipCustomer = CustomerFixtures.createVIPCustomer();

        // Act
        final isarCustomer = IsarCustomer.fromEntity(vipCustomer);
        final reconstructedCustomer = isarCustomer.toEntity();

        // Assert
        expect(reconstructedCustomer.totalPurchases, vipCustomer.totalPurchases);
        expect(reconstructedCustomer.totalOrders, vipCustomer.totalOrders);
        expect(reconstructedCustomer.creditLimit, vipCustomer.creditLimit);
      });

      test('should handle customer with overdue balance roundtrip', () {
        // Arrange
        final overdueCustomer = CustomerFixtures.createCustomerWithOverdueBalance();

        // Act
        final isarCustomer = IsarCustomer.fromEntity(overdueCustomer);
        final reconstructedCustomer = isarCustomer.toEntity();

        // Assert
        expect(reconstructedCustomer.currentBalance, overdueCustomer.currentBalance);
        expect(reconstructedCustomer.currentBalance > 0, true);
      });
    });

    group('toString', () {
      test('should return formatted string representation', () {
        // Arrange
        final isarCustomer = IsarCustomer.fromEntity(tCustomer);

        // Act
        final result = isarCustomer.toString();

        // Assert
        expect(result, contains('IsarCustomer'));
        expect(result, contains(tCustomer.id));
        expect(result, contains(isarCustomer.fullName));
        expect(result, contains(tCustomer.email));
      });
    });
  });
}
