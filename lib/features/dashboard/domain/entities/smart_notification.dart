// lib/features/dashboard/domain/entities/smart_notification.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  // Críticas (Requieren atención inmediata)
  invoiceOverdue('invoice_overdue'),
  stockOut('stock_out'),
  paymentFailed('payment_failed'),
  securityBreach('security_breach'),
  systemError('system_error'),

  // Importantes (Requieren atención pronto)
  invoiceDueSoon('invoice_due_soon'),
  stockLow('stock_low'),
  largePaymentReceived('large_payment_received'),
  monthlyReportReady('monthly_report_ready'),
  customerCreditLimit('customer_credit_limit'),

  // Informativas
  paymentReceived('payment_received'),
  newCustomer('new_customer'),
  backupCompleted('backup_completed'),
  invoiceSent('invoice_sent'),
  productLowStockWarning('product_low_stock_warning'),

  // Promocionales/Marketing
  salesMilestone('sales_milestone'),
  newFeatureAvailable('new_feature_available'),
  performanceReport('performance_report');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.paymentReceived,
    );
  }
}

enum NotificationPriority {
  critical('critical'),
  high('high'),
  medium('medium'),
  low('low');

  const NotificationPriority(this.value);
  final String value;

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => NotificationPriority.medium,
    );
  }

  Color get color {
    switch (this) {
      case NotificationPriority.critical:
        return Colors.red.shade700;
      case NotificationPriority.high:
        return Colors.orange.shade600;
      case NotificationPriority.medium:
        return Colors.blue.shade600;
      case NotificationPriority.low:
        return Colors.grey.shade600;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case NotificationPriority.critical:
        return Colors.red.shade50;
      case NotificationPriority.high:
        return Colors.orange.shade50;
      case NotificationPriority.medium:
        return Colors.blue.shade50;
      case NotificationPriority.low:
        return Colors.grey.shade50;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationPriority.critical:
        return Icons.error;
      case NotificationPriority.high:
        return Icons.warning;
      case NotificationPriority.medium:
        return Icons.info;
      case NotificationPriority.low:
        return Icons.info_outline;
    }
  }

  String get label {
    switch (this) {
      case NotificationPriority.critical:
        return 'Crítica';
      case NotificationPriority.high:
        return 'Alta';
      case NotificationPriority.medium:
        return 'Media';
      case NotificationPriority.low:
        return 'Baja';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationPriority.critical:
        return 'crítica';
      case NotificationPriority.high:
        return 'alta';
      case NotificationPriority.medium:
        return 'media';
      case NotificationPriority.low:
        return 'baja';
    }
  }

  static const NotificationPriority normal = NotificationPriority.medium;
}

enum NotificationChannel {
  inApp('in_app'),
  email('email'),
  sms('sms'),
  push('push'),
  whatsapp('whatsapp');

  const NotificationChannel(this.value);
  final String value;

  static NotificationChannel fromString(String value) {
    return NotificationChannel.values.firstWhere(
      (channel) => channel.value == value,
      orElse: () => NotificationChannel.inApp,
    );
  }
}

enum NotificationStatus {
  pending('pending'),
  sent('sent'),
  delivered('delivered'),
  read('read'),
  archived('archived'),
  failed('failed');

  const NotificationStatus(this.value);
  final String value;

  static NotificationStatus fromString(String value) {
    return NotificationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => NotificationStatus.pending,
    );
  }

  bool get isRead => this == NotificationStatus.read || this == NotificationStatus.archived;
  bool get isUnread => this == NotificationStatus.pending || this == NotificationStatus.sent || this == NotificationStatus.delivered;
}

class SmartNotification extends Equatable {
  final String id;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationStatus status;
  final List<NotificationChannel> channels;
  final String title;
  final String message;
  final String? richContent;
  final String? entityId;
  final String? entityType;
  final String? actionUrl;
  final String? actionLabel;
  final Map<String, dynamic>? metadata;
  final String icon;
  final Color color;
  final DateTime? scheduledFor;
  final DateTime? expiresAt;
  final int retryCount;
  final int maxRetries;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? archivedAt;
  final bool isGrouped;
  final String? groupKey;
  final String userId;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SmartNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.status,
    required this.channels,
    required this.title,
    required this.message,
    this.richContent,
    this.entityId,
    this.entityType,
    this.actionUrl,
    this.actionLabel,
    this.metadata,
    required this.icon,
    required this.color,
    this.scheduledFor,
    this.expiresAt,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.archivedAt,
    this.isGrouped = false,
    this.groupKey,
    required this.userId,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        priority,
        status,
        channels,
        title,
        message,
        richContent,
        entityId,
        entityType,
        actionUrl,
        actionLabel,
        metadata,
        icon,
        color,
        scheduledFor,
        expiresAt,
        retryCount,
        maxRetries,
        sentAt,
        deliveredAt,
        readAt,
        archivedAt,
        isGrouped,
        groupKey,
        userId,
        organizationId,
        createdAt,
        updatedAt,
      ];

  // Helper methods
  bool get isRead => status.isRead;
  bool get isUnread => status.isUnread;
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get canRetry => retryCount < maxRetries;
  bool get hasAction => actionUrl != null && actionLabel != null;

  Color get priorityColor => priority.color;

  String get formattedTime => timeAgo;

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Ahora mismo';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}sem';
    }
  }

  IconData get iconData {
    switch (icon) {
      case 'schedule':
        return Icons.schedule;
      case 'report_problem':
        return Icons.report_problem;
      case 'warning':
        return Icons.warning;
      case 'payment':
        return Icons.payment;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'person_add':
        return Icons.person_add;
      case 'backup':
        return Icons.backup;
      case 'send':
        return Icons.send;
      case 'trending_up':
        return Icons.trending_up;
      case 'new_releases':
        return Icons.new_releases;
      case 'assessment':
        return Icons.assessment;
      case 'error':
        return Icons.error;
      case 'security':
        return Icons.security;
      default:
        return Icons.notifications;
    }
  }

  String get categoryLabel {
    switch (type) {
      case NotificationType.invoiceOverdue:
      case NotificationType.invoiceDueSoon:
      case NotificationType.invoiceSent:
        return 'Facturas';
      case NotificationType.stockOut:
      case NotificationType.stockLow:
      case NotificationType.productLowStockWarning:
        return 'Inventario';
      case NotificationType.paymentReceived:
      case NotificationType.largePaymentReceived:
      case NotificationType.paymentFailed:
        return 'Pagos';
      case NotificationType.newCustomer:
      case NotificationType.customerCreditLimit:
        return 'Clientes';
      case NotificationType.systemError:
      case NotificationType.securityBreach:
      case NotificationType.backupCompleted:
        return 'Sistema';
      case NotificationType.salesMilestone:
      case NotificationType.performanceReport:
      case NotificationType.monthlyReportReady:
        return 'Reportes';
      case NotificationType.newFeatureAvailable:
        return 'Novedades';
    }
  }

  // Factory constructor for creating from JSON
  factory SmartNotification.fromJson(Map<String, dynamic> json) {
    return SmartNotification(
      id: json['id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      priority: NotificationPriority.fromString(json['priority'] as String),
      status: NotificationStatus.fromString(json['status'] as String),
      channels: (json['channels'] as List<dynamic>?)
          ?.map((channel) => NotificationChannel.fromString(channel as String))
          .toList() ?? [NotificationChannel.inApp],
      title: json['title'] as String,
      message: json['message'] as String,
      richContent: json['richContent'] as String?,
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
      actionUrl: json['actionUrl'] as String?,
      actionLabel: json['actionLabel'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      icon: json['icon'] as String? ?? 'notifications',
      color: _parseColor(json['color']),
      scheduledFor: json['scheduledFor'] != null 
          ? DateTime.parse(json['scheduledFor'] as String)
          : null,
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      retryCount: json['retryCount'] as int? ?? 0,
      maxRetries: json['maxRetries'] as int? ?? 3,
      sentAt: json['sentAt'] != null 
          ? DateTime.parse(json['sentAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null 
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt'] as String)
          : null,
      archivedAt: json['archivedAt'] != null 
          ? DateTime.parse(json['archivedAt'] as String)
          : null,
      isGrouped: json['isGrouped'] as bool? ?? false,
      groupKey: json['groupKey'] as String?,
      userId: json['userId'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static Color _parseColor(dynamic colorValue) {
    try {
      if (colorValue == null) return Colors.blue;
      final colorString = colorValue.toString();
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
      }
      return Colors.blue;
    } catch (e) {
      return Colors.blue;
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'priority': priority.value,
      'status': status.value,
      'channels': channels.map((channel) => channel.value).toList(),
      'title': title,
      'message': message,
      'richContent': richContent,
      'entityId': entityId,
      'entityType': entityType,
      'actionUrl': actionUrl,
      'actionLabel': actionLabel,
      'metadata': metadata,
      'icon': icon,
      'color': '#${color.value.toRadixString(16).substring(2)}',
      'scheduledFor': scheduledFor?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'sentAt': sentAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
      'isGrouped': isGrouped,
      'groupKey': groupKey,
      'userId': userId,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  SmartNotification copyWith({
    String? id,
    NotificationType? type,
    NotificationPriority? priority,
    NotificationStatus? status,
    List<NotificationChannel>? channels,
    String? title,
    String? message,
    String? richContent,
    String? entityId,
    String? entityType,
    String? actionUrl,
    String? actionLabel,
    Map<String, dynamic>? metadata,
    String? icon,
    Color? color,
    DateTime? scheduledFor,
    DateTime? expiresAt,
    int? retryCount,
    int? maxRetries,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    DateTime? archivedAt,
    bool? isGrouped,
    String? groupKey,
    String? userId,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmartNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      channels: channels ?? this.channels,
      title: title ?? this.title,
      message: message ?? this.message,
      richContent: richContent ?? this.richContent,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      metadata: metadata ?? this.metadata,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      expiresAt: expiresAt ?? this.expiresAt,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      archivedAt: archivedAt ?? this.archivedAt,
      isGrouped: isGrouped ?? this.isGrouped,
      groupKey: groupKey ?? this.groupKey,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}