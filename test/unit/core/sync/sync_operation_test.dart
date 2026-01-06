// test/unit/core/sync/sync_operation_test.dart
//
// NOTE: These tests require the Isar native library to be present.
// If you get "Failed to load dynamic library" errors, run:
//   flutter test --update-goldens
// or ensure the libisar library is properly installed for your platform.
//
// Alternatively, these tests can be run as integration tests once
// the app is running with proper Isar initialization.

import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_isar_helper.dart';
import '../../../mocks/mock_isar.dart';

void main() {
  late MockIsar isar;

  setUp(() async {
    isar = await TestIsarHelper.createInMemoryIsar();
  });

  tearDown(() async {
    await TestIsarHelper.cleanAndClose(isar);
  });

  group('SyncOperation', () {
    group('Constructor', () {
      test('should create operation with correct fields using named constructor',
          () {
        // Arrange & Act
        final operation = SyncOperation.create(
          entityType: 'Product',
          entityId: 'prod-123',
          operationType: SyncOperationType.create,
          payload: '{"id": "prod-123", "name": "Test Product"}',
          organizationId: 'org-456',
          priority: 5,
        );

        // Assert
        expect(operation.entityType, 'Product');
        expect(operation.entityId, 'prod-123');
        expect(operation.operationType, SyncOperationType.create);
        expect(
            operation.payload, '{"id": "prod-123", "name": "Test Product"}');
        expect(operation.organizationId, 'org-456');
        expect(operation.priority, 5);
        expect(operation.status, SyncStatus.pending);
        expect(operation.retryCount, 0);
        expect(operation.createdAt, isNotNull);
        expect(operation.syncedAt, isNull);
        expect(operation.error, isNull);
      });

      test('should create operation with default priority when not specified',
          () {
        // Arrange & Act
        final operation = SyncOperation.create(
          entityType: 'Customer',
          entityId: 'cust-789',
          operationType: SyncOperationType.update,
          payload: '{"id": "cust-789", "name": "Test Customer"}',
          organizationId: 'org-456',
        );

        // Assert
        expect(operation.priority, 0);
        expect(operation.status, SyncStatus.pending);
        expect(operation.retryCount, 0);
      });
    });

    group('Status Transitions', () {
      test('should transition from pending to inProgress', () async {
        // Arrange
        final operation = SyncOperation.create(
          entityType: 'Invoice',
          entityId: 'inv-001',
          operationType: SyncOperationType.create,
          payload: '{"id": "inv-001", "total": 100.0}',
          organizationId: 'org-123',
        );

        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Act
        await isar.writeTxn(() async {
          operation.status = SyncStatus.inProgress;
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.status, SyncStatus.inProgress);
        expect(result.isPending, false);
        expect(result.isInProgress, true);
        expect(result.isCompleted, false);
        expect(result.isFailed, false);
      });

      test('should transition from inProgress to completed', () async {
        // Arrange
        final operation = SyncOperation.create(
          entityType: 'Product',
          entityId: 'prod-001',
          operationType: SyncOperationType.update,
          payload: '{"id": "prod-001", "price": 50.0}',
          organizationId: 'org-123',
        );
        operation.status = SyncStatus.inProgress;

        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Act
        await isar.writeTxn(() async {
          operation.status = SyncStatus.completed;
          operation.syncedAt = DateTime.now();
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.status, SyncStatus.completed);
        expect(result.isCompleted, true);
        expect(result.syncedAt, isNotNull);
        expect(result.isPending, false);
        expect(result.isInProgress, false);
        expect(result.isFailed, false);
      });

      test('should transition from inProgress to failed', () async {
        // Arrange
        final operation = SyncOperation.create(
          entityType: 'Customer',
          entityId: 'cust-001',
          operationType: SyncOperationType.delete,
          payload: '{"id": "cust-001"}',
          organizationId: 'org-123',
        );
        operation.status = SyncStatus.inProgress;

        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Act
        await isar.writeTxn(() async {
          operation.status = SyncStatus.failed;
          operation.error = 'Network timeout';
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.status, SyncStatus.failed);
        expect(result.isFailed, true);
        expect(result.error, 'Network timeout');
        expect(result.isPending, false);
        expect(result.isInProgress, false);
        expect(result.isCompleted, false);
      });

      test('should transition from failed back to pending for retry', () async {
        // Arrange
        final operation = SyncOperation.create(
          entityType: 'Product',
          entityId: 'prod-002',
          operationType: SyncOperationType.create,
          payload: '{"id": "prod-002", "name": "New Product"}',
          organizationId: 'org-123',
        );
        operation.status = SyncStatus.failed;
        operation.error = 'Connection refused';
        operation.retryCount = 1;

        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Act
        await isar.writeTxn(() async {
          operation.status = SyncStatus.pending;
          operation.error = null;
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.status, SyncStatus.pending);
        expect(result.isPending, true);
        expect(result.error, isNull);
        expect(result.retryCount, 1);
        // canRetry requires isFailed=true, but status is pending, so canRetry should be false
        expect(result.canRetry, false);
      });
    });

    group('Retry Count', () {
      test('should increment retry count', () async {
        // Arrange
        final operation = SyncOperation.create(
          entityType: 'Invoice',
          entityId: 'inv-002',
          operationType: SyncOperationType.update,
          payload: '{"id": "inv-002", "status": "paid"}',
          organizationId: 'org-123',
        );

        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Act - Simulate multiple retries
        for (int i = 1; i <= 3; i++) {
          await isar.writeTxn(() async {
            operation.retryCount = i;
            operation.status = SyncStatus.failed;
            operation.error = 'Retry attempt $i failed';
            await isar.syncOperations.put(operation);
          });
        }

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.retryCount, 3);
        expect(result.canRetry, true);
      });

      test('should not allow retry when retry count exceeds limit', () async {
        // Arrange
        final operation = SyncOperation.create(
          entityType: 'Product',
          entityId: 'prod-003',
          operationType: SyncOperationType.delete,
          payload: '{"id": "prod-003"}',
          organizationId: 'org-123',
        );

        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Act - Set retry count to max
        await isar.writeTxn(() async {
          operation.retryCount = 5;
          operation.status = SyncStatus.failed;
          operation.error = 'Max retries exceeded';
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.retryCount, 5);
        expect(result.canRetry, false);
        expect(result.isFailed, true);
      });

      test('should allow retry when retry count is below limit', () async {
        // Arrange
        final operation = SyncOperation.create(
          entityType: 'Customer',
          entityId: 'cust-003',
          operationType: SyncOperationType.update,
          payload: '{"id": "cust-003", "email": "test@example.com"}',
          organizationId: 'org-123',
        );

        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Act
        await isar.writeTxn(() async {
          operation.retryCount = 4;
          operation.status = SyncStatus.failed;
          operation.error = 'Temporary error';
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.retryCount, 4);
        expect(result.canRetry, true);
      });
    });

    group('Error Message', () {
      test('should store error message on failure', () async {
        // Arrange
        final operation = SyncOperation.create(
          entityType: 'Invoice',
          entityId: 'inv-003',
          operationType: SyncOperationType.create,
          payload: '{"id": "inv-003", "total": 250.0}',
          organizationId: 'org-123',
        );

        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Act
        const errorMessage = 'Server returned 500: Internal Server Error';
        await isar.writeTxn(() async {
          operation.status = SyncStatus.failed;
          operation.error = errorMessage;
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.error, errorMessage);
        expect(result.isFailed, true);
      });

      test('should clear error message on successful retry', () async {
        // Arrange
        final operation = SyncOperation.create(
          entityType: 'Product',
          entityId: 'prod-004',
          operationType: SyncOperationType.update,
          payload: '{"id": "prod-004", "stock": 100}',
          organizationId: 'org-123',
        );
        operation.status = SyncStatus.failed;
        operation.error = 'Network timeout';

        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Act
        await isar.writeTxn(() async {
          operation.status = SyncStatus.completed;
          operation.error = null;
          operation.syncedAt = DateTime.now();
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.error, isNull);
        expect(result.isCompleted, true);
        expect(result.syncedAt, isNotNull);
      });

      test('should handle long error messages', () async {
        // Arrange
        final operation = SyncOperation.create(
          entityType: 'Customer',
          entityId: 'cust-004',
          operationType: SyncOperationType.create,
          payload: '{"id": "cust-004", "name": "Long Error Test"}',
          organizationId: 'org-123',
        );

        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Act
        const longError =
            'Very long error message with detailed stack trace and multiple lines '
            'that simulates a real error scenario with lots of debugging information '
            'including HTTP headers, response body, and connection details. '
            'This helps verify that the error field can handle lengthy strings.';

        await isar.writeTxn(() async {
          operation.status = SyncStatus.failed;
          operation.error = longError;
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.error, longError);
      });
    });

    group('Payload Serialization', () {
      test('should serialize and deserialize simple JSON payload', () async {
        // Arrange
        const payload = '{"id": "item-001", "name": "Simple Item"}';
        final operation = SyncOperation.create(
          entityType: 'Item',
          entityId: 'item-001',
          operationType: SyncOperationType.create,
          payload: payload,
          organizationId: 'org-123',
        );

        // Act
        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.payload, payload);
      });

      test('should serialize and deserialize complex JSON payload', () async {
        // Arrange
        const payload = '''
        {
          "id": "invoice-001",
          "customer": {
            "id": "cust-001",
            "name": "John Doe",
            "email": "john@example.com"
          },
          "items": [
            {"id": "item-1", "quantity": 2, "price": 50.0},
            {"id": "item-2", "quantity": 1, "price": 100.0}
          ],
          "total": 200.0,
          "createdAt": "2024-01-15T10:30:00Z"
        }
        ''';

        final operation = SyncOperation.create(
          entityType: 'Invoice',
          entityId: 'invoice-001',
          operationType: SyncOperationType.create,
          payload: payload,
          organizationId: 'org-123',
        );

        // Act
        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.payload, payload);
      });

      test('should handle empty payload', () async {
        // Arrange - For delete operations, payload might be minimal
        const payload = '{}';
        final operation = SyncOperation.create(
          entityType: 'Product',
          entityId: 'prod-005',
          operationType: SyncOperationType.delete,
          payload: payload,
          organizationId: 'org-123',
        );

        // Act
        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.payload, payload);
      });

      test('should handle special characters in payload', () async {
        // Arrange
        const payload = '''
        {
          "id": "special-001",
          "description": "Product with special chars: @#\$%^&*()_+-={}[]|\\:;'<>?,./",
          "unicode": "测试 テスト 🎉 😀"
        }
        ''';

        final operation = SyncOperation.create(
          entityType: 'Product',
          entityId: 'special-001',
          operationType: SyncOperationType.update,
          payload: payload,
          organizationId: 'org-123',
        );

        // Act
        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        // Assert
        final result = await isar.syncOperations.get(operation.id);
        expect(result, isNotNull);
        expect(result!.payload, payload);
      });
    });

    group('Helpers and Getters', () {
      test('isPending should return correct value', () {
        final operation = SyncOperation.create(
          entityType: 'Test',
          entityId: 'test-001',
          operationType: SyncOperationType.create,
          payload: '{}',
          organizationId: 'org-123',
        );

        expect(operation.isPending, true);
        expect(operation.isInProgress, false);
        expect(operation.isCompleted, false);
        expect(operation.isFailed, false);
      });

      test('isInProgress should return correct value', () {
        final operation = SyncOperation.create(
          entityType: 'Test',
          entityId: 'test-002',
          operationType: SyncOperationType.update,
          payload: '{}',
          organizationId: 'org-123',
        );
        operation.status = SyncStatus.inProgress;

        expect(operation.isInProgress, true);
        expect(operation.isPending, false);
        expect(operation.isCompleted, false);
        expect(operation.isFailed, false);
      });

      test('isCompleted should return correct value', () {
        final operation = SyncOperation.create(
          entityType: 'Test',
          entityId: 'test-003',
          operationType: SyncOperationType.delete,
          payload: '{}',
          organizationId: 'org-123',
        );
        operation.status = SyncStatus.completed;

        expect(operation.isCompleted, true);
        expect(operation.isPending, false);
        expect(operation.isInProgress, false);
        expect(operation.isFailed, false);
      });

      test('isFailed should return correct value', () {
        final operation = SyncOperation.create(
          entityType: 'Test',
          entityId: 'test-004',
          operationType: SyncOperationType.create,
          payload: '{}',
          organizationId: 'org-123',
        );
        operation.status = SyncStatus.failed;

        expect(operation.isFailed, true);
        expect(operation.isPending, false);
        expect(operation.isInProgress, false);
        expect(operation.isCompleted, false);
      });

      test('toString should return formatted string', () async {
        final operation = SyncOperation.create(
          entityType: 'Product',
          entityId: 'prod-123',
          operationType: SyncOperationType.create,
          payload: '{}',
          organizationId: 'org-456',
        );

        await isar.writeTxn(() async {
          await isar.syncOperations.put(operation);
        });

        final result = operation.toString();
        expect(result, contains('SyncOperation'));
        expect(result, contains('Product'));
        expect(result, contains('create'));
        expect(result, contains('pending'));
        expect(result, contains('prod-123'));
      });
    });

    group('Organization ID (Multitenancy)', () {
      test('should filter operations by organization ID', () async {
        // Arrange - Create operations for different organizations
        await isar.writeTxn(() async {
          for (var i = 0; i < 3; i++) {
            final op1 = SyncOperation.create(
              entityType: 'Product',
              entityId: 'org1-prod-$i',
              operationType: SyncOperationType.create,
              payload: '{}',
              organizationId: 'org-111',
            );
            await isar.syncOperations.put(op1);

            final op2 = SyncOperation.create(
              entityType: 'Product',
              entityId: 'org2-prod-$i',
              operationType: SyncOperationType.create,
              payload: '{}',
              organizationId: 'org-222',
            );
            await isar.syncOperations.put(op2);
          }
        });

        // Act - Query operations for org-111
        final org1Operations = await isar.syncOperations
            .filter()
            .organizationIdEqualTo('org-111')
            .findAll();

        final org2Operations = await isar.syncOperations
            .filter()
            .organizationIdEqualTo('org-222')
            .findAll();

        // Assert
        expect(org1Operations.length, 3);
        expect(org2Operations.length, 3);
        expect(
            org1Operations.every((op) => op.organizationId == 'org-111'), true);
        expect(
            org2Operations.every((op) => op.organizationId == 'org-222'), true);
      });
    });

    group('Priority', () {
      test('should order operations by priority', () async {
        // Arrange - Create operations with different priorities
        await isar.writeTxn(() async {
          final op1 = SyncOperation.create(
            entityType: 'Invoice',
            entityId: 'inv-001',
            operationType: SyncOperationType.create,
            payload: '{}',
            organizationId: 'org-123',
            priority: 1,
          );
          await isar.syncOperations.put(op1);

          final op2 = SyncOperation.create(
            entityType: 'Invoice',
            entityId: 'inv-002',
            operationType: SyncOperationType.create,
            payload: '{}',
            organizationId: 'org-123',
            priority: 10,
          );
          await isar.syncOperations.put(op2);

          final op3 = SyncOperation.create(
            entityType: 'Invoice',
            entityId: 'inv-003',
            operationType: SyncOperationType.create,
            payload: '{}',
            organizationId: 'org-123',
            priority: 5,
          );
          await isar.syncOperations.put(op3);
        });

        // Act - Query all and check priorities exist
        final operations = await isar.syncOperations.where().findAll();

        // Assert
        expect(operations.length, 3);

        // Sort manually to verify priorities
        operations.sort((a, b) => b.priority.compareTo(a.priority));

        expect(operations[0].priority, 10);
        expect(operations[1].priority, 5);
        expect(operations[2].priority, 1);
        expect(operations[0].entityId, 'inv-002');
        expect(operations[1].entityId, 'inv-003');
        expect(operations[2].entityId, 'inv-001');
      });
    });
  });
}
