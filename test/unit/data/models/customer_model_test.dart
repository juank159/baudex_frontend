// test/unit/data/models/customer_model_test.dart
import 'package:baudex_desktop/features/customers/data/models/customer_model.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/customer_fixtures.dart';

void main() {
  group('CustomerModel', () {
    final tCustomer = CustomerFixtures.createCustomerEntity();
    final tCustomerModel = CustomerModel.fromEntity(tCustomer);

    final tCustomerJson = {
      'id': tCustomer.id,
      'firstName': tCustomer.firstName,
      'lastName': tCustomer.lastName,
      'companyName': tCustomer.companyName,
      'email': tCustomer.email,
      'phone': tCustomer.phone,
      'mobile': tCustomer.mobile,
      'documentType': tCustomer.documentType.name,
      'documentNumber': tCustomer.documentNumber,
      'address': tCustomer.address,
      'city': tCustomer.city,
      'state': tCustomer.state,
      'zipCode': tCustomer.zipCode,
      'country': tCustomer.country,
      'status': tCustomer.status.name,
      'creditLimit': tCustomer.creditLimit,
      'currentBalance': tCustomer.currentBalance,
      'paymentTerms': tCustomer.paymentTerms,
      'birthDate': tCustomer.birthDate?.toIso8601String(),
      'notes': tCustomer.notes,
      'metadata': tCustomer.metadata,
      'lastPurchaseAt': tCustomer.lastPurchaseAt?.toIso8601String(),
      'totalPurchases': tCustomer.totalPurchases,
      'totalOrders': tCustomer.totalOrders,
      'createdAt': tCustomer.createdAt.toIso8601String(),
      'updatedAt': tCustomer.updatedAt.toIso8601String(),
      'deletedAt': tCustomer.deletedAt?.toIso8601String(),
    };

    group('fromJson', () {
      test('should return valid CustomerModel from JSON', () {
        // Act
        final result = CustomerModel.fromJson(tCustomerJson);

        // Assert
        expect(result, isA<CustomerModel>());
        expect(result.id, tCustomer.id);
        expect(result.firstName, tCustomer.firstName);
        expect(result.lastName, tCustomer.lastName);
        expect(result.email, tCustomer.email);
        expect(result.documentNumber, tCustomer.documentNumber);
      });

      test('should handle null optional fields', () {
        // Arrange
        final jsonWithNulls = {
          'id': 'cust-001',
          'firstName': 'John',
          'lastName': 'Doe',
          'companyName': null,
          'email': 'john@example.com',
          'phone': null,
          'mobile': null,
          'documentType': 'cc',
          'documentNumber': '1234567890',
          'address': null,
          'city': null,
          'state': null,
          'zipCode': null,
          'country': null,
          'status': 'active',
          'creditLimit': 1000000.0,
          'currentBalance': 0.0,
          'paymentTerms': 30,
          'birthDate': null,
          'notes': null,
          'metadata': null,
          'lastPurchaseAt': null,
          'totalPurchases': 0.0,
          'totalOrders': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'deletedAt': null,
        };

        // Act
        final result = CustomerModel.fromJson(jsonWithNulls);

        // Assert
        expect(result.companyName, isNull);
        expect(result.phone, isNull);
        expect(result.mobile, isNull);
        expect(result.address, isNull);
        expect(result.birthDate, isNull);
        expect(result.notes, isNull);
        expect(result.metadata, isNull);
        expect(result.lastPurchaseAt, isNull);
      });

      test('should parse creditLimit as double from int', () {
        // Arrange
        final jsonWithIntCredit = {
          ...tCustomerJson,
          'creditLimit': 1000000,
          'currentBalance': 500000,
          'totalPurchases': 2000000,
        };

        // Act
        final result = CustomerModel.fromJson(jsonWithIntCredit);

        // Assert
        expect(result.creditLimit, 1000000.0);
        expect(result.currentBalance, 500000.0);
        expect(result.totalPurchases, 2000000.0);
      });

      test('should parse financial amounts as double from string', () {
        // Arrange
        final jsonWithStringAmounts = {
          ...tCustomerJson,
          'creditLimit': '1000000.50',
          'currentBalance': '500000.25',
          'totalPurchases': '2000000.75',
        };

        // Act
        final result = CustomerModel.fromJson(jsonWithStringAmounts);

        // Assert
        expect(result.creditLimit, 1000000.50);
        expect(result.currentBalance, 500000.25);
        expect(result.totalPurchases, 2000000.75);
      });

      test('should parse all document types correctly', () {
        // Test CC
        final ccJson = {...tCustomerJson, 'documentType': 'cc'};
        final ccResult = CustomerModel.fromJson(ccJson);
        expect(ccResult.documentType, DocumentType.cc);

        // Test NIT
        final nitJson = {...tCustomerJson, 'documentType': 'nit'};
        final nitResult = CustomerModel.fromJson(nitJson);
        expect(nitResult.documentType, DocumentType.nit);

        // Test CE
        final ceJson = {...tCustomerJson, 'documentType': 'ce'};
        final ceResult = CustomerModel.fromJson(ceJson);
        expect(ceResult.documentType, DocumentType.ce);

        // Test Passport
        final passportJson = {...tCustomerJson, 'documentType': 'passport'};
        final passportResult = CustomerModel.fromJson(passportJson);
        expect(passportResult.documentType, DocumentType.passport);

        // Test Other
        final otherJson = {...tCustomerJson, 'documentType': 'other'};
        final otherResult = CustomerModel.fromJson(otherJson);
        expect(otherResult.documentType, DocumentType.other);
      });

      test('should parse all customer statuses correctly', () {
        // Test Active
        final activeJson = {...tCustomerJson, 'status': 'active'};
        final activeResult = CustomerModel.fromJson(activeJson);
        expect(activeResult.status, CustomerStatus.active);

        // Test Inactive
        final inactiveJson = {...tCustomerJson, 'status': 'inactive'};
        final inactiveResult = CustomerModel.fromJson(inactiveJson);
        expect(inactiveResult.status, CustomerStatus.inactive);

        // Test Suspended
        final suspendedJson = {...tCustomerJson, 'status': 'suspended'};
        final suspendedResult = CustomerModel.fromJson(suspendedJson);
        expect(suspendedResult.status, CustomerStatus.suspended);
      });

      test('should parse dates correctly', () {
        // Arrange
        final birthDate = DateTime(1990, 5, 15);
        final lastPurchaseAt = DateTime(2024, 1, 15);
        final jsonWithDates = {
          ...tCustomerJson,
          'birthDate': birthDate.toIso8601String(),
          'lastPurchaseAt': lastPurchaseAt.toIso8601String(),
        };

        // Act
        final result = CustomerModel.fromJson(jsonWithDates);

        // Assert
        expect(result.birthDate, isNotNull);
        expect(result.birthDate!.year, birthDate.year);
        expect(result.birthDate!.month, birthDate.month);
        expect(result.birthDate!.day, birthDate.day);
        expect(result.lastPurchaseAt, isNotNull);
      });

      test('should parse metadata as Map', () {
        // Arrange
        final jsonWithMetadata = {
          ...tCustomerJson,
          'metadata': {
            'preferredContact': 'email',
            'customerSince': '2020-01-01',
            'vipLevel': 'gold',
          },
        };

        // Act
        final result = CustomerModel.fromJson(jsonWithMetadata);

        // Assert
        expect(result.metadata, isNotNull);
        expect(result.metadata!['preferredContact'], 'email');
        expect(result.metadata!['vipLevel'], 'gold');
      });

      test('should handle uppercase document type strings', () {
        // Arrange
        final jsonWithUppercase = {
          ...tCustomerJson,
          'documentType': 'CC',
          'status': 'ACTIVE',
        };

        // Act
        final result = CustomerModel.fromJson(jsonWithUppercase);

        // Assert
        expect(result.documentType, DocumentType.cc);
        expect(result.status, CustomerStatus.active);
      });

      test('should handle invalid document type with default', () {
        // Arrange
        final jsonWithInvalid = {
          ...tCustomerJson,
          'documentType': 'invalid_type',
        };

        // Act
        final result = CustomerModel.fromJson(jsonWithInvalid);

        // Assert
        expect(result.documentType, DocumentType.cc); // Default
      });

      test('should handle invalid status with default', () {
        // Arrange
        final jsonWithInvalid = {
          ...tCustomerJson,
          'status': 'invalid_status',
        };

        // Act
        final result = CustomerModel.fromJson(jsonWithInvalid);

        // Assert
        expect(result.status, CustomerStatus.active); // Default
      });
    });

    group('toJson', () {
      test('should return valid JSON map', () {
        // Act
        final result = tCustomerModel.toJson();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], tCustomer.id);
        expect(result['firstName'], tCustomer.firstName);
        expect(result['lastName'], tCustomer.lastName);
        expect(result['email'], tCustomer.email);
      });

      test('should serialize dates as ISO 8601 strings', () {
        // Act
        final result = tCustomerModel.toJson();

        // Assert
        expect(result['createdAt'], isA<String>());
        expect(result['updatedAt'], isA<String>());
        expect(
          DateTime.parse(result['createdAt'] as String),
          isA<DateTime>(),
        );
      });

      test('should serialize enums as strings', () {
        // Act
        final result = tCustomerModel.toJson();

        // Assert
        expect(result['documentType'], tCustomer.documentType.name);
        expect(result['status'], tCustomer.status.name);
      });

      test('should serialize null fields as null', () {
        // Arrange
        final customerWithNulls = CustomerModel(
          id: 'cust-001',
          firstName: 'John',
          lastName: 'Doe',
          companyName: null,
          email: 'john@example.com',
          phone: null,
          mobile: null,
          documentType: DocumentType.cc,
          documentNumber: '1234567890',
          address: null,
          city: null,
          state: null,
          zipCode: null,
          country: null,
          status: CustomerStatus.active,
          creditLimit: 1000000.0,
          currentBalance: 0.0,
          paymentTerms: 30,
          birthDate: null,
          notes: null,
          metadata: null,
          lastPurchaseAt: null,
          totalPurchases: 0.0,
          totalOrders: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: null,
        );

        // Act
        final result = customerWithNulls.toJson();

        // Assert
        expect(result['companyName'], isNull);
        expect(result['phone'], isNull);
        expect(result['birthDate'], isNull);
        expect(result['notes'], isNull);
        expect(result['metadata'], isNull);
      });

      test('should serialize metadata correctly', () {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity();
        final model = CustomerModel.fromEntity(customer);

        // Act
        final result = model.toJson();

        // Assert
        if (customer.metadata != null) {
          expect(result['metadata'], isA<Map<String, dynamic>>());
        }
      });
    });

    group('toEntity', () {
      test('should convert to Customer entity', () {
        // Act
        final result = tCustomerModel.toEntity();

        // Assert
        expect(result, isA<Customer>());
        expect(result.id, tCustomerModel.id);
        expect(result.firstName, tCustomerModel.firstName);
        expect(result.lastName, tCustomerModel.lastName);
        expect(result.email, tCustomerModel.email);
      });

      test('should map document type correctly', () {
        // Arrange
        final passportCustomer = CustomerFixtures.createCustomerWithPassport();
        final model = CustomerModel.fromEntity(passportCustomer);

        // Act
        final result = model.toEntity();

        // Assert
        expect(result.documentType, DocumentType.passport);
      });

      test('should map status correctly', () {
        // Arrange
        final suspendedCustomer = CustomerFixtures.createSuspendedCustomer();
        final model = CustomerModel.fromEntity(suspendedCustomer);

        // Act
        final result = model.toEntity();

        // Assert
        expect(result.status, CustomerStatus.suspended);
      });

      test('should preserve all financial fields', () {
        // Arrange
        final vipCustomer = CustomerFixtures.createVIPCustomer();
        final model = CustomerModel.fromEntity(vipCustomer);

        // Act
        final result = model.toEntity();

        // Assert
        expect(result.creditLimit, vipCustomer.creditLimit);
        expect(result.currentBalance, vipCustomer.currentBalance);
        expect(result.paymentTerms, vipCustomer.paymentTerms);
        expect(result.totalPurchases, vipCustomer.totalPurchases);
        expect(result.totalOrders, vipCustomer.totalOrders);
      });
    });

    group('fromEntity', () {
      test('should create CustomerModel from Customer entity', () {
        // Arrange
        final customer = CustomerFixtures.createCustomerEntity();

        // Act
        final result = CustomerModel.fromEntity(customer);

        // Assert
        expect(result, isA<CustomerModel>());
        expect(result.id, customer.id);
        expect(result.firstName, customer.firstName);
        expect(result.lastName, customer.lastName);
        expect(result.email, customer.email);
      });

      test('should map DocumentType enum correctly', () {
        // Arrange
        final corporateCustomer = CustomerFixtures.createCorporateCustomer();

        // Act
        final result = CustomerModel.fromEntity(corporateCustomer);

        // Assert
        expect(result.documentType, DocumentType.nit);
      });

      test('should map CustomerStatus enum correctly', () {
        // Arrange
        final inactiveCustomer = CustomerFixtures.createInactiveCustomer();

        // Act
        final result = CustomerModel.fromEntity(inactiveCustomer);

        // Assert
        expect(result.status, CustomerStatus.inactive);
      });

      test('should handle corporate customer', () {
        // Arrange
        final corporateCustomer = CustomerFixtures.createCorporateCustomer();

        // Act
        final result = CustomerModel.fromEntity(corporateCustomer);

        // Assert
        expect(result.companyName, corporateCustomer.companyName);
        expect(result.documentType, DocumentType.nit);
      });

      test('should handle individual customer', () {
        // Arrange
        final individualCustomer = CustomerFixtures.createIndividualCustomer();

        // Act
        final result = CustomerModel.fromEntity(individualCustomer);

        // Assert
        expect(result.companyName, isNull);
        expect(result.documentType, DocumentType.cc);
      });
    });

    group('JSON roundtrip', () {
      test('should maintain data integrity through toJson -> fromJson', () {
        // Arrange
        final originalModel = tCustomerModel;

        // Act
        final json = originalModel.toJson();
        final reconstructedModel = CustomerModel.fromJson(json);

        // Assert
        expect(reconstructedModel.id, originalModel.id);
        expect(reconstructedModel.firstName, originalModel.firstName);
        expect(reconstructedModel.lastName, originalModel.lastName);
        expect(reconstructedModel.email, originalModel.email);
        expect(reconstructedModel.documentNumber, originalModel.documentNumber);
        expect(reconstructedModel.documentType, originalModel.documentType);
        expect(reconstructedModel.status, originalModel.status);
      });

      test('should maintain data integrity through toEntity -> fromEntity', () {
        // Arrange
        final originalEntity = tCustomer;

        // Act
        final model = CustomerModel.fromEntity(originalEntity);
        final reconstructedEntity = model.toEntity();

        // Assert
        expect(reconstructedEntity.id, originalEntity.id);
        expect(reconstructedEntity.firstName, originalEntity.firstName);
        expect(reconstructedEntity.lastName, originalEntity.lastName);
        expect(reconstructedEntity.email, originalEntity.email);
        expect(reconstructedEntity.documentType, originalEntity.documentType);
        expect(reconstructedEntity.status, originalEntity.status);
      });

      test('should handle corporate customer roundtrip', () {
        // Arrange
        final corporateCustomer = CustomerFixtures.createCorporateCustomer();

        // Act
        final model = CustomerModel.fromEntity(corporateCustomer);
        final json = model.toJson();
        final reconstructed = CustomerModel.fromJson(json);

        // Assert
        expect(reconstructed.companyName, corporateCustomer.companyName);
        expect(reconstructed.documentType, corporateCustomer.documentType);
      });

      test('should handle VIP customer roundtrip', () {
        // Arrange
        final vipCustomer = CustomerFixtures.createVIPCustomer();

        // Act
        final model = CustomerModel.fromEntity(vipCustomer);
        final json = model.toJson();
        final reconstructed = CustomerModel.fromJson(json);

        // Assert
        expect(reconstructed.creditLimit, vipCustomer.creditLimit);
        expect(reconstructed.totalPurchases, vipCustomer.totalPurchases);
        expect(reconstructed.totalOrders, vipCustomer.totalOrders);
      });
    });

    group('edge cases', () {
      test('should handle empty string values', () {
        // Arrange
        final jsonWithEmptyStrings = {
          ...tCustomerJson,
          'companyName': '',
          'phone': '',
          'notes': '',
        };

        // Act
        final result = CustomerModel.fromJson(jsonWithEmptyStrings);

        // Assert - Empty strings should be preserved, not converted to null
        expect(result.companyName, '');
        expect(result.phone, '');
        expect(result.notes, '');
      });

      test('should handle zero financial values', () {
        // Arrange
        final jsonWithZeros = {
          ...tCustomerJson,
          'creditLimit': 0.0,
          'currentBalance': 0.0,
          'totalPurchases': 0.0,
          'totalOrders': 0,
          'paymentTerms': 0,
        };

        // Act
        final result = CustomerModel.fromJson(jsonWithZeros);

        // Assert
        expect(result.creditLimit, 0.0);
        expect(result.currentBalance, 0.0);
        expect(result.totalPurchases, 0.0);
        expect(result.totalOrders, 0);
        expect(result.paymentTerms, 0);
      });

      test('should handle large financial values', () {
        // Arrange
        final jsonWithLargeValues = {
          ...tCustomerJson,
          'creditLimit': 99999999999.99,
          'currentBalance': 50000000000.50,
          'totalPurchases': 100000000000.00,
        };

        // Act
        final result = CustomerModel.fromJson(jsonWithLargeValues);

        // Assert
        expect(result.creditLimit, 99999999999.99);
        expect(result.currentBalance, 50000000000.50);
        expect(result.totalPurchases, 100000000000.00);
      });
    });
  });
}
