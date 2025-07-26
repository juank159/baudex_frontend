// lib/features/dashboard/domain/entities/recent_activity_advanced.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ActivityType {
  // Ventas y Facturación
  invoiceCreated('invoice_created'),
  invoiceUpdated('invoice_updated'),
  invoicePaid('invoice_paid'),
  invoicePartiallyPaid('invoice_partially_paid'),
  invoiceCancelled('invoice_cancelled'),
  invoiceOverdue('invoice_overdue'),
  paymentReceived('payment_received'),
  paymentFailed('payment_failed'),

  // Productos e Inventario
  productCreated('product_created'),
  productUpdated('product_updated'),
  productDeleted('product_deleted'),
  stockLow('stock_low'),
  stockOut('stock_out'),
  stockReplenished('stock_replenished'),

  // Clientes
  customerCreated('customer_created'),
  customerUpdated('customer_updated'),
  customerDeleted('customer_deleted'),

  // Gastos
  expenseCreated('expense_created'),
  expenseUpdated('expense_updated'),
  expenseApproved('expense_approved'),
  expenseRejected('expense_rejected'),
  expensePaid('expense_paid'),

  // Sistema y Seguridad
  userLogin('user_login'),
  userLogout('user_logout'),
  userFailedLogin('user_failed_login'),
  settingsUpdated('settings_updated'),
  backupCreated('backup_created'),
  dataExported('data_exported'),
  dataImported('data_imported'),

  // Analytics y Reportes
  reportGenerated('report_generated'),
  dashboardViewed('dashboard_viewed'),
  bulkActionPerformed('bulk_action_performed');

  const ActivityType(this.value);
  final String value;

  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ActivityType.dashboardViewed,
    );
  }
}

enum ActivityCategory {
  financial('financial'),
  inventory('inventory'),
  customer('customer'),
  system('system'),
  security('security'),
  analytics('analytics');

  const ActivityCategory(this.value);
  final String value;

  static ActivityCategory fromString(String value) {
    return ActivityCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => ActivityCategory.system,
    );
  }
}

enum ActivityPriority {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const ActivityPriority(this.value);
  final String value;

  static ActivityPriority fromString(String value) {
    return ActivityPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => ActivityPriority.medium,
    );
  }

  Color get color {
    switch (this) {
      case ActivityPriority.low:
        return Colors.grey;
      case ActivityPriority.medium:
        return Colors.blue;
      case ActivityPriority.high:
        return Colors.orange;
      case ActivityPriority.critical:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityPriority.low:
        return Icons.info_outline;
      case ActivityPriority.medium:
        return Icons.info;
      case ActivityPriority.high:
        return Icons.warning;
      case ActivityPriority.critical:
        return Icons.error;
    }
  }

  String get displayName {
    switch (this) {
      case ActivityPriority.low:
        return 'baja';
      case ActivityPriority.medium:
        return 'media';
      case ActivityPriority.high:
        return 'alta';
      case ActivityPriority.critical:
        return 'crítica';
    }
  }

  static const ActivityPriority normal = ActivityPriority.medium;
}

class RecentActivityAdvanced extends Equatable {
  final String id;
  final ActivityType type;
  final ActivityCategory category;
  final ActivityPriority priority;
  final String title;
  final String description;
  final String? entityId;
  final String? entityType;
  final Map<String, dynamic>? metadata;
  final String icon;
  final Color color;
  final bool isSystemGenerated;
  final String? ipAddress;
  final String? userAgent;
  final String userId;
  final String userName;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecentActivityAdvanced({
    required this.id,
    required this.type,
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    this.entityId,
    this.entityType,
    this.metadata,
    required this.icon,
    required this.color,
    this.isSystemGenerated = false,
    this.ipAddress,
    this.userAgent,
    required this.userId,
    required this.userName,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        category,
        priority,
        title,
        description,
        entityId,
        entityType,
        metadata,
        icon,
        color,
        isSystemGenerated,
        ipAddress,
        userAgent,
        userId,
        userName,
        organizationId,
        createdAt,
        updatedAt,
      ];

  // Helper methods
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

  String get formattedTime => timeAgo;

  IconData get iconData {
    switch (icon) {
      case 'receipt_long':
        return Icons.receipt_long;
      case 'payment':
        return Icons.payment;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'schedule':
        return Icons.schedule;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'warning':
        return Icons.warning;
      case 'report_problem':
        return Icons.report_problem;
      case 'person_add':
        return Icons.person_add;
      case 'money_off':
        return Icons.money_off;
      case 'check_circle':
        return Icons.check_circle;
      case 'login':
        return Icons.login;
      case 'backup':
        return Icons.backup;
      default:
        return Icons.info;
    }
  }

  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 1;
  }

  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  String get formattedAmount {
    if (metadata?['amount'] != null) {
      final amount = (metadata!['amount'] as num).toDouble();
      return '\$${amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    }
    return '';
  }

  // Factory constructor for creating from JSON
  factory RecentActivityAdvanced.fromJson(Map<String, dynamic> json) {
    return RecentActivityAdvanced(
      id: json['id'] as String,
      type: ActivityType.fromString(json['type'] as String),
      category: ActivityCategory.fromString(json['category'] as String),
      priority: ActivityPriority.fromString(json['priority'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      icon: json['icon'] as String? ?? 'circle',
      color: _parseColor(json['color']),
      isSystemGenerated: json['isSystemGenerated'] as bool? ?? false,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      userId: json['userId'] as String? ?? '',
      userName: json['user']?['firstName'] != null 
          ? '${json['user']['firstName']} ${json['user']['lastName'] ?? ''}'.trim()
          : json['userName'] as String? ?? 'Usuario',
      organizationId: json['organizationId'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static Color _parseColor(dynamic colorValue) {
    try {
      if (colorValue == null) return Colors.grey;
      final colorString = colorValue.toString();
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
      }
      return Colors.grey;
    } catch (e) {
      return Colors.grey;
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'category': category.value,
      'priority': priority.value,
      'title': title,
      'description': description,
      'entityId': entityId,
      'entityType': entityType,
      'metadata': metadata,
      'icon': icon,
      'color': '#${color.value.toRadixString(16).substring(2)}',
      'isSystemGenerated': isSystemGenerated,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'userId': userId,
      'userName': userName,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  RecentActivityAdvanced copyWith({
    String? id,
    ActivityType? type,
    ActivityCategory? category,
    ActivityPriority? priority,
    String? title,
    String? description,
    String? entityId,
    String? entityType,
    Map<String, dynamic>? metadata,
    String? icon,
    Color? color,
    bool? isSystemGenerated,
    String? ipAddress,
    String? userAgent,
    String? userId,
    String? userName,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecentActivityAdvanced(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      metadata: metadata ?? this.metadata,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}