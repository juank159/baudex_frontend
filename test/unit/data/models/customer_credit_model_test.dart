// test/unit/data/models/customer_credit_model_test.dart
import 'package:baudex_desktop/features/customer_credits/data/models/customer_credit_model.dart';
import 'package:baudex_desktop/features/customer_credits/domain/entities/customer_credit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/customer_credit_fixtures.dart';

void main() {
  group('CustomerCreditModel', () {
    final tCredit = CustomerCreditFixtures.createCustomerCreditEntity();
    final tCreditModel = CustomerCreditModel(
      id: tCredit.id,
      originalAmount: tCredit.originalAmount,
      paidAmount: tCredit.paidAmount,
      balanceDue: tCredit.balanceDue,
      status: tCredit.status,
      dueDate: tCredit.dueDate,
      description: tCredit.description,
      notes: tCredit.notes,
      customerId: tCredit.customerId,
      customerName: tCredit.customerName,
      invoiceId: tCredit.invoiceId,
      invoiceNumber: tCredit.invoiceNumber,
      organizationId: tCredit.organizationId,
      createdById: tCredit.createdById,
      createdByName: tCredit.createdByName,
      payments: tCredit.payments,
      createdAt: tCredit.createdAt,
      updatedAt: tCredit.updatedAt,
      deletedAt: tCredit.deletedAt,
    );

    final tCreditJson = {
      'id': tCredit.id,
      'originalAmount': tCredit.originalAmount,
      'paidAmount': tCredit.paidAmount,
      'balanceDue': tCredit.balanceDue,
      'status': tCredit.status.value,
      'dueDate': tCredit.dueDate?.toIso8601String(),
      'description': tCredit.description,
      'notes': tCredit.notes,
      'customerId': tCredit.customerId,
      'invoiceId': tCredit.invoiceId,
      'organizationId': tCredit.organizationId,
      'createdById': tCredit.createdById,
      'createdAt': tCredit.createdAt.toIso8601String(),
      'updatedAt': tCredit.updatedAt.toIso8601String(),
      'deletedAt': tCredit.deletedAt?.toIso8601String(),
    };

    group('fromJson', () {
      test('should return valid CustomerCreditModel from JSON', () {
        // Act
        final result = CustomerCreditModel.fromJson(tCreditJson);

        // Assert
        expect(result, isA<CustomerCreditModel>());
        expect(result.id, tCredit.id);
        expect(result.originalAmount, tCredit.originalAmount);
        expect(result.paidAmount, tCredit.paidAmount);
        expect(result.balanceDue, tCredit.balanceDue);
        expect(result.status, tCredit.status);
        expect(result.customerId, tCredit.customerId);
      });

      test('should handle null optional fields', () {
        // Arrange
        final jsonWithNulls = {
          'id': 'credit-001',
          'originalAmount': 500000.0,
          'paidAmount': 0.0,
          'balanceDue': 500000.0,
          'status': 'pending',
          'dueDate': null,
          'description': null,
          'notes': null,
          'customerId': 'cust-001',
          'customerName': null,
          'invoiceId': null,
          'invoiceNumber': null,
          'organizationId': 'org-001',
          'createdById': 'user-001',
          'createdByName': null,
          'payments': null,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'deletedAt': null,
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithNulls);

        // Assert
        expect(result.dueDate, isNull);
        expect(result.description, isNull);
        expect(result.notes, isNull);
        expect(result.customerName, isNull);
        expect(result.invoiceId, isNull);
        expect(result.payments, isNull);
      });

      test('should parse amounts as double from int', () {
        // Arrange
        final jsonWithIntAmounts = {
          ...tCreditJson,
          'originalAmount': 500000,
          'paidAmount': 200000,
          'balanceDue': 300000,
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithIntAmounts);

        // Assert
        expect(result.originalAmount, 500000.0);
        expect(result.paidAmount, 200000.0);
        expect(result.balanceDue, 300000.0);
      });

      test('should parse amounts as double from string', () {
        // Arrange
        final jsonWithStringAmounts = {
          ...tCreditJson,
          'originalAmount': '500000.50',
          'paidAmount': '200000.25',
          'balanceDue': '300000.25',
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithStringAmounts);

        // Assert
        expect(result.originalAmount, 500000.50);
        expect(result.paidAmount, 200000.25);
        expect(result.balanceDue, 300000.25);
      });

      test('should parse all credit statuses correctly', () {
        // Test pending
        final pendingJson = {...tCreditJson, 'status': 'pending'};
        final pendingResult = CustomerCreditModel.fromJson(pendingJson);
        expect(pendingResult.status, CreditStatus.pending);

        // Test partially_paid
        final partialJson = {...tCreditJson, 'status': 'partially_paid'};
        final partialResult = CustomerCreditModel.fromJson(partialJson);
        expect(partialResult.status, CreditStatus.partiallyPaid);

        // Test paid
        final paidJson = {...tCreditJson, 'status': 'paid'};
        final paidResult = CustomerCreditModel.fromJson(paidJson);
        expect(paidResult.status, CreditStatus.paid);

        // Test cancelled
        final cancelledJson = {...tCreditJson, 'status': 'cancelled'};
        final cancelledResult = CustomerCreditModel.fromJson(cancelledJson);
        expect(cancelledResult.status, CreditStatus.cancelled);

        // Test overdue
        final overdueJson = {...tCreditJson, 'status': 'overdue'};
        final overdueResult = CustomerCreditModel.fromJson(overdueJson);
        expect(overdueResult.status, CreditStatus.overdue);
      });

      test('should parse dueDate correctly', () {
        // Arrange
        final dueDate = DateTime(2024, 12, 31);
        final jsonWithDate = {
          ...tCreditJson,
          'dueDate': dueDate.toIso8601String(),
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithDate);

        // Assert
        expect(result.dueDate, isNotNull);
        expect(result.dueDate!.year, dueDate.year);
        expect(result.dueDate!.month, dueDate.month);
        expect(result.dueDate!.day, dueDate.day);
      });

      test('should parse customer name from customer object', () {
        // Arrange
        final jsonWithCustomer = {
          ...tCreditJson,
          'customer': {
            'firstName': 'John',
            'lastName': 'Doe',
          },
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithCustomer);

        // Assert
        expect(result.customerName, 'John Doe');
      });

      test('should parse invoice number from invoice object', () {
        // Arrange
        final jsonWithInvoice = {
          ...tCreditJson,
          'invoice': {
            'number': 'INV-12345',
          },
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithInvoice);

        // Assert
        expect(result.invoiceNumber, 'INV-12345');
      });

      test('should parse created by name from createdBy object', () {
        // Arrange
        final jsonWithCreatedBy = {
          ...tCreditJson,
          'createdBy': {
            'firstName': 'Admin',
            'lastName': 'User',
          },
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithCreatedBy);

        // Assert
        expect(result.createdByName, 'Admin User');
      });

      test('should parse payments array', () {
        // Arrange
        final jsonWithPayments = {
          ...tCreditJson,
          'payments': [
            {
              'id': 'pay-001',
              'amount': 100000.0,
              'paymentMethod': 'cash',
              'paymentDate': DateTime(2024, 1, 5).toIso8601String(),
              'creditId': 'credit-001',
              'organizationId': 'org-001',
              'createdById': 'user-001',
              'createdAt': DateTime(2024, 1, 5).toIso8601String(),
              'updatedAt': DateTime(2024, 1, 5).toIso8601String(),
            },
          ],
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithPayments);

        // Assert
        expect(result.payments, isNotNull);
        expect(result.payments!.length, 1);
        expect(result.payments!.first.amount, 100000.0);
        expect(result.payments!.first.paymentMethod, 'cash');
      });

      test('should handle snake_case field names', () {
        // Arrange
        final jsonSnakeCase = {
          'id': 'credit-001',
          'originalAmount': 500000.0,
          'paidAmount': 0.0,
          'balanceDue': 500000.0,
          'status': 'pending',
          'customer_id': 'cust-001',
          'invoice_id': 'inv-001',
          'organization_id': 'org-001',
          'created_by_id': 'user-001',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonSnakeCase);

        // Assert
        expect(result.customerId, 'cust-001');
        expect(result.invoiceId, 'inv-001');
        expect(result.organizationId, 'org-001');
        expect(result.createdById, 'user-001');
      });
    });

    group('toJson', () {
      test('should return valid JSON map', () {
        // Act
        final result = tCreditModel.toJson();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], tCredit.id);
        expect(result['originalAmount'], tCredit.originalAmount);
        expect(result['paidAmount'], tCredit.paidAmount);
        expect(result['balanceDue'], tCredit.balanceDue);
        expect(result['status'], tCredit.status.value);
      });

      test('should serialize dates as ISO 8601 strings', () {
        // Act
        final result = tCreditModel.toJson();

        // Assert
        expect(result['createdAt'], isA<String>());
        expect(result['updatedAt'], isA<String>());
        expect(
          DateTime.parse(result['createdAt'] as String),
          isA<DateTime>(),
        );
      });

      test('should serialize status as string', () {
        // Act
        final result = tCreditModel.toJson();

        // Assert
        expect(result['status'], tCredit.status.value);
        expect(result['status'], isA<String>());
      });

      test('should serialize null fields as null', () {
        // Arrange
        final creditWithNulls = CustomerCreditModel(
          id: 'credit-001',
          originalAmount: 500000.0,
          paidAmount: 0.0,
          balanceDue: 500000.0,
          status: CreditStatus.pending,
          dueDate: null,
          description: null,
          notes: null,
          customerId: 'cust-001',
          customerName: null,
          invoiceId: null,
          invoiceNumber: null,
          organizationId: 'org-001',
          createdById: 'user-001',
          createdByName: null,
          payments: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: null,
        );

        // Act
        final result = creditWithNulls.toJson();

        // Assert
        expect(result['dueDate'], isNull);
        expect(result['description'], isNull);
        expect(result['notes'], isNull);
        expect(result['deletedAt'], isNull);
      });
    });

    group('JSON roundtrip', () {
      test('should maintain data integrity through toJson -> fromJson', () {
        // Arrange
        final originalModel = tCreditModel;

        // Act
        final json = originalModel.toJson();
        final reconstructedModel = CustomerCreditModel.fromJson(json);

        // Assert
        expect(reconstructedModel.id, originalModel.id);
        expect(reconstructedModel.originalAmount, originalModel.originalAmount);
        expect(reconstructedModel.paidAmount, originalModel.paidAmount);
        expect(reconstructedModel.balanceDue, originalModel.balanceDue);
        expect(reconstructedModel.status, originalModel.status);
        expect(reconstructedModel.customerId, originalModel.customerId);
        expect(reconstructedModel.organizationId, originalModel.organizationId);
      });

      test('should handle partially paid credit roundtrip', () {
        // Arrange
        final partialCredit = CustomerCreditFixtures.createPartiallyPaidCredit();
        final model = CustomerCreditModel(
          id: partialCredit.id,
          originalAmount: partialCredit.originalAmount,
          paidAmount: partialCredit.paidAmount,
          balanceDue: partialCredit.balanceDue,
          status: partialCredit.status,
          dueDate: partialCredit.dueDate,
          description: partialCredit.description,
          notes: partialCredit.notes,
          customerId: partialCredit.customerId,
          customerName: partialCredit.customerName,
          invoiceId: partialCredit.invoiceId,
          invoiceNumber: partialCredit.invoiceNumber,
          organizationId: partialCredit.organizationId,
          createdById: partialCredit.createdById,
          createdByName: partialCredit.createdByName,
          payments: partialCredit.payments,
          createdAt: partialCredit.createdAt,
          updatedAt: partialCredit.updatedAt,
          deletedAt: partialCredit.deletedAt,
        );

        // Act
        final json = model.toJson();
        final reconstructed = CustomerCreditModel.fromJson(json);

        // Assert
        expect(reconstructed.status, CreditStatus.partiallyPaid);
        expect(reconstructed.paidAmount, partialCredit.paidAmount);
        expect(reconstructed.balanceDue, partialCredit.balanceDue);
      });
    });

    group('edge cases', () {
      test('should handle zero amounts', () {
        // Arrange
        final jsonWithZeros = {
          ...tCreditJson,
          'originalAmount': 0.0,
          'paidAmount': 0.0,
          'balanceDue': 0.0,
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithZeros);

        // Assert
        expect(result.originalAmount, 0.0);
        expect(result.paidAmount, 0.0);
        expect(result.balanceDue, 0.0);
      });

      test('should handle large amounts', () {
        // Arrange
        final jsonWithLargeAmounts = {
          ...tCreditJson,
          'originalAmount': 999999999.99,
          'paidAmount': 500000000.50,
          'balanceDue': 499999999.49,
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithLargeAmounts);

        // Assert
        expect(result.originalAmount, 999999999.99);
        expect(result.paidAmount, 500000000.50);
        expect(result.balanceDue, 499999999.49);
      });

      test('should handle empty string values', () {
        // Arrange
        final jsonWithEmptyStrings = {
          ...tCreditJson,
          'description': '',
          'notes': '',
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithEmptyStrings);

        // Assert
        expect(result.description, '');
        expect(result.notes, '');
      });

      test('should default to pending status on invalid status', () {
        // Arrange
        final jsonWithInvalidStatus = {
          ...tCreditJson,
          'status': 'invalid_status',
        };

        // Act
        final result = CustomerCreditModel.fromJson(jsonWithInvalidStatus);

        // Assert
        expect(result.status, CreditStatus.pending);
      });
    });
  });

  group('CreditPaymentModel', () {
    final tPayment = CustomerCreditFixtures.createCreditPaymentEntity();
    final tPaymentJson = {
      'id': tPayment.id,
      'amount': tPayment.amount,
      'paymentMethod': tPayment.paymentMethod,
      'paymentDate': tPayment.paymentDate.toIso8601String(),
      'reference': tPayment.reference,
      'notes': tPayment.notes,
      'creditId': tPayment.creditId,
      'bankAccountId': tPayment.bankAccountId,
      'organizationId': tPayment.organizationId,
      'createdById': tPayment.createdById,
      'createdAt': tPayment.createdAt.toIso8601String(),
      'updatedAt': tPayment.updatedAt.toIso8601String(),
    };

    group('fromJson', () {
      test('should return valid CreditPaymentModel from JSON', () {
        // Act
        final result = CreditPaymentModel.fromJson(tPaymentJson);

        // Assert
        expect(result, isA<CreditPaymentModel>());
        expect(result.id, tPayment.id);
        expect(result.amount, tPayment.amount);
        expect(result.paymentMethod, tPayment.paymentMethod);
        expect(result.creditId, tPayment.creditId);
      });

      test('should handle snake_case field names', () {
        // Arrange
        final jsonSnakeCase = {
          'id': 'pay-001',
          'amount': 100000.0,
          'payment_method': 'cash',
          'payment_date': DateTime(2024, 1, 5).toIso8601String(),
          'credit_id': 'credit-001',
          'bank_account_id': 'bank-001',
          'organization_id': 'org-001',
          'created_by_id': 'user-001',
          'created_at': DateTime(2024, 1, 5).toIso8601String(),
          'updated_at': DateTime(2024, 1, 5).toIso8601String(),
        };

        // Act
        final result = CreditPaymentModel.fromJson(jsonSnakeCase);

        // Assert
        expect(result.paymentMethod, 'cash');
        expect(result.creditId, 'credit-001');
        expect(result.bankAccountId, 'bank-001');
        expect(result.organizationId, 'org-001');
        expect(result.createdById, 'user-001');
      });
    });

    group('toJson', () {
      test('should return valid JSON map', () {
        // Arrange
        final model = CreditPaymentModel.fromJson(tPaymentJson);

        // Act
        final result = model.toJson();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], tPayment.id);
        expect(result['amount'], tPayment.amount);
        expect(result['paymentMethod'], tPayment.paymentMethod);
      });
    });
  });

  group('CreditStatsModel', () {
    final tStatsJson = {
      'totalPending': 1500000.0,
      'totalOverdue': 500000.0,
      'countPending': 10,
      'countOverdue': 3,
      'totalPaid': 5000000.0,
    };

    test('should parse from JSON correctly', () {
      // Act
      final result = CreditStatsModel.fromJson(tStatsJson);

      // Assert
      expect(result, isA<CreditStatsModel>());
      expect(result.totalPending, 1500000.0);
      expect(result.totalOverdue, 500000.0);
      expect(result.countPending, 10);
      expect(result.countOverdue, 3);
      expect(result.totalPaid, 5000000.0);
    });

    test('should handle snake_case field names', () {
      // Arrange
      final jsonSnakeCase = {
        'total_pending': 1500000.0,
        'total_overdue': 500000.0,
        'count_pending': 10,
        'count_overdue': 3,
        'total_paid': 5000000.0,
      };

      // Act
      final result = CreditStatsModel.fromJson(jsonSnakeCase);

      // Assert
      expect(result.totalPending, 1500000.0);
      expect(result.countPending, 10);
    });
  });
}
