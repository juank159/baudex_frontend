import 'package:flutter_test/flutter_test.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/notifications/data/models/isar/isar_notification.dart';
import 'package:baudex_desktop/features/dashboard/domain/entities/notification.dart';

void main() {
  group('IsarNotification', () {
    final tDateTime = DateTime(2024, 1, 1, 12, 0);

    final tIsarNotification = IsarNotification.create(
      serverId: 'notif-001',
      type: IsarNotificationType.invoice,
      title: 'Test Notification',
      message: 'This is a test message',
      timestamp: tDateTime,
      isRead: false,
      priority: IsarNotificationPriority.high,
      relatedId: 'inv-001',
      actionDataJson: '{"action":"view","id":"inv-001"}',
      createdAt: tDateTime,
      updatedAt: tDateTime,
      isSynced: true,
      lastSyncAt: tDateTime,
    );

    group('fromEntity', () {
      test('should create IsarNotification from Notification entity', () {
        final entity = Notification(
          id: 'notif-002',
          type: NotificationType.payment,
          title: 'Payment Received',
          message: 'Payment of \$100 received',
          timestamp: tDateTime,
          isRead: false,
          priority: NotificationPriority.medium,
          relatedId: 'pay-001',
          actionData: {'amount': 100},
        );

        final result = IsarNotification.fromEntity(entity);

        expect(result.serverId, equals('notif-002'));
        expect(result.type, equals(IsarNotificationType.payment));
        expect(result.title, equals('Payment Received'));
        expect(result.message, equals('Payment of \$100 received'));
        expect(result.isRead, equals(false));
        expect(result.priority, equals(IsarNotificationPriority.medium));
        expect(result.isSynced, equals(true));
      });
    });

    group('toEntity', () {
      test('should convert IsarNotification to Notification entity', () {
        final entity = tIsarNotification.toEntity();

        expect(entity, isA<Notification>());
        expect(entity.id, equals('notif-001'));
        expect(entity.type, equals(NotificationType.invoice));
        expect(entity.title, equals('Test Notification'));
        expect(entity.message, equals('This is a test message'));
        expect(entity.isRead, equals(false));
        expect(entity.priority, equals(NotificationPriority.high));
      });
    });

    group('utility methods', () {
      test('markAsRead should update isRead and isSynced', () {
        final notification = IsarNotification.create(
          serverId: 'test',
          type: IsarNotificationType.system,
          title: 'Test',
          message: 'Test',
          timestamp: tDateTime,
          isRead: false,
          priority: IsarNotificationPriority.low,
          createdAt: tDateTime,
          updatedAt: tDateTime,
          isSynced: true,
        );

        notification.markAsRead();

        expect(notification.isRead, equals(true));
        expect(notification.isSynced, equals(false));
      });

      test('markAsUnread should update isRead and isSynced', () {
        final notification = IsarNotification.create(
          serverId: 'test',
          type: IsarNotificationType.system,
          title: 'Test',
          message: 'Test',
          timestamp: tDateTime,
          isRead: true,
          priority: IsarNotificationPriority.low,
          createdAt: tDateTime,
          updatedAt: tDateTime,
          isSynced: true,
        );

        notification.markAsUnread();

        expect(notification.isRead, equals(false));
        expect(notification.isSynced, equals(false));
      });

      test('softDelete should set deletedAt and markAsUnsynced', () {
        final notification = IsarNotification.create(
          serverId: 'test',
          type: IsarNotificationType.system,
          title: 'Test',
          message: 'Test',
          timestamp: tDateTime,
          isRead: false,
          priority: IsarNotificationPriority.low,
          createdAt: tDateTime,
          updatedAt: tDateTime,
          isSynced: true,
        );

        notification.softDelete();

        expect(notification.deletedAt, isNotNull);
        expect(notification.isSynced, equals(false));
        expect(notification.isDeleted, equals(true));
      });
    });

    group('createLocal', () {
      test('should create local notification with default values', () {
        final notification = IsarNotification.createLocal(
          serverId: 'local-001',
          type: IsarNotificationType.lowStock,
          title: 'Low Stock',
          message: 'Product X is low on stock',
        );

        expect(notification.serverId, equals('local-001'));
        expect(notification.isRead, equals(false));
        expect(notification.isSynced, equals(false));
        expect(notification.priority, equals(IsarNotificationPriority.medium));
      });
    });

    group('equality', () {
      test('should be equal for same serverId', () {
        final notif1 = IsarNotification.create(
          serverId: 'same-id',
          type: IsarNotificationType.system,
          title: 'Test',
          message: 'Test',
          timestamp: tDateTime,
          isRead: false,
          priority: IsarNotificationPriority.low,
          createdAt: tDateTime,
          updatedAt: tDateTime,
          isSynced: true,
        );

        final notif2 = IsarNotification.create(
          serverId: 'same-id',
          type: IsarNotificationType.payment,
          title: 'Different',
          message: 'Different',
          timestamp: tDateTime,
          isRead: true,
          priority: IsarNotificationPriority.high,
          createdAt: tDateTime,
          updatedAt: tDateTime,
          isSynced: false,
        );

        expect(notif1, equals(notif2));
      });

      test('should not be equal for different serverId', () {
        final notif1 = IsarNotification.create(
          serverId: 'id-1',
          type: IsarNotificationType.system,
          title: 'Test',
          message: 'Test',
          timestamp: tDateTime,
          isRead: false,
          priority: IsarNotificationPriority.low,
          createdAt: tDateTime,
          updatedAt: tDateTime,
          isSynced: true,
        );

        final notif2 = IsarNotification.create(
          serverId: 'id-2',
          type: IsarNotificationType.system,
          title: 'Test',
          message: 'Test',
          timestamp: tDateTime,
          isRead: false,
          priority: IsarNotificationPriority.low,
          createdAt: tDateTime,
          updatedAt: tDateTime,
          isSynced: true,
        );

        expect(notif1, isNot(equals(notif2)));
      });
    });
  });
}
