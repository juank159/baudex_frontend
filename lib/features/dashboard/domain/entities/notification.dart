// lib/features/dashboard/domain/entities/notification.dart
import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationPriority priority;
  final String? relatedId;
  final Map<String, dynamic>? actionData;

  const Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.priority,
    this.relatedId,
    this.actionData,
  });

  Notification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationPriority? priority,
    String? relatedId,
    Map<String, dynamic>? actionData,
  }) {
    return Notification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      relatedId: relatedId ?? this.relatedId,
      actionData: actionData ?? this.actionData,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return 'Hace ${(difference.inDays / 7).floor()}sem';
    }
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return 'Hace ${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    message,
    timestamp,
    isRead,
    priority,
    relatedId,
    actionData,
  ];
}

enum NotificationType {
  system,
  payment,
  invoice,
  lowStock,
  expense,
  sale,
  user,
  reminder,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.system:
        return 'Sistema';
      case NotificationType.payment:
        return 'Pago';
      case NotificationType.invoice:
        return 'Factura';
      case NotificationType.lowStock:
        return 'Stock Bajo';
      case NotificationType.expense:
        return 'Gasto';
      case NotificationType.sale:
        return 'Venta';
      case NotificationType.user:
        return 'Usuario';
      case NotificationType.reminder:
        return 'Recordatorio';
    }
  }

  String get iconName {
    switch (this) {
      case NotificationType.system:
        return 'settings';
      case NotificationType.payment:
        return 'payment';
      case NotificationType.invoice:
        return 'receipt_long';
      case NotificationType.lowStock:
        return 'warning';
      case NotificationType.expense:
        return 'trending_down';
      case NotificationType.sale:
        return 'trending_up';
      case NotificationType.user:
        return 'person';
      case NotificationType.reminder:
        return 'schedule';
    }
  }
}

extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Baja';
      case NotificationPriority.medium:
        return 'Media';
      case NotificationPriority.high:
        return 'Alta';
      case NotificationPriority.urgent:
        return 'Urgente';
    }
  }
}