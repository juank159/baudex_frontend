// lib/features/notifications/data/models/notification_model.dart
import '../../../dashboard/domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.message,
    required super.timestamp,
    required super.isRead,
    required super.priority,
    super.relatedId,
    super.actionData,
  });

  /// Crear desde JSON (API response)
  /// Soporta tanto el formato simple como el formato SmartNotification del dashboard
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Determinar timestamp - soporta múltiples formatos
    DateTime timestamp;
    if (json['timestamp'] != null) {
      timestamp = DateTime.parse(json['timestamp'] as String);
    } else if (json['createdAt'] != null) {
      timestamp = DateTime.parse(json['createdAt'] as String);
    } else if (json['created_at'] != null) {
      timestamp = DateTime.parse(json['created_at'] as String);
    } else {
      timestamp = DateTime.now();
    }

    // Determinar isRead - soporta formato SmartNotification con status
    bool isRead = json['isRead'] as bool? ?? false;
    if (json['status'] != null) {
      final status = json['status'] as String;
      isRead = status == 'read' || status == 'archived';
    }

    // Determinar relatedId - soporta entityId del SmartNotification
    String? relatedId = json['relatedId'] as String?;
    relatedId ??= json['entityId'] as String?;

    // Construir actionData con metadata adicional del SmartNotification
    Map<String, dynamic>? actionData = json['actionData'] as Map<String, dynamic>?;
    if (actionData == null && json['metadata'] != null) {
      actionData = json['metadata'] as Map<String, dynamic>?;
    }
    // Agregar actionUrl y entityType si existen
    if (json['actionUrl'] != null || json['entityType'] != null) {
      actionData ??= {};
      if (json['actionUrl'] != null) {
        actionData['actionUrl'] = json['actionUrl'];
      }
      if (json['entityType'] != null) {
        actionData['entityType'] = json['entityType'];
      }
      if (json['icon'] != null) {
        actionData['icon'] = json['icon'];
      }
      if (json['color'] != null) {
        actionData['color'] = json['color'];
      }
    }

    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: _mapStringToNotificationType(json['type'] as String?),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      timestamp: timestamp,
      isRead: isRead,
      priority: _mapStringToNotificationPriority(json['priority'] as String?),
      relatedId: relatedId,
      actionData: actionData,
    );
  }

  /// Convertir a JSON (API request)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'priority': priority.name,
    };

    if (relatedId != null) {
      json['relatedId'] = relatedId;
    }

    if (actionData != null) {
      json['actionData'] = actionData;
    }

    return json;
  }

  /// Crear desde entidad del dominio
  factory NotificationModel.fromEntity(Notification entity) {
    return NotificationModel(
      id: entity.id,
      type: entity.type,
      title: entity.title,
      message: entity.message,
      timestamp: entity.timestamp,
      isRead: entity.isRead,
      priority: entity.priority,
      relatedId: entity.relatedId,
      actionData: entity.actionData,
    );
  }

  /// Convertir a entidad del dominio
  Notification toEntity() {
    return Notification(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead,
      priority: priority,
      relatedId: relatedId,
      actionData: actionData,
    );
  }

  /// Copiar con nuevos valores
  @override
  NotificationModel copyWith({
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
    return NotificationModel(
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

  // ==================== MAPPERS DE ENUMS ====================

  /// Mapear string a NotificationType
  /// Soporta tanto tipos simples como tipos SmartNotification del dashboard
  static NotificationType _mapStringToNotificationType(String? type) {
    if (type == null) return NotificationType.system;

    switch (type.toLowerCase()) {
      // Tipos simples
      case 'system':
        return NotificationType.system;
      case 'payment':
        return NotificationType.payment;
      case 'invoice':
        return NotificationType.invoice;
      case 'lowstock':
      case 'low_stock':
        return NotificationType.lowStock;
      case 'expense':
        return NotificationType.expense;
      case 'sale':
        return NotificationType.sale;
      case 'user':
        return NotificationType.user;
      case 'reminder':
        return NotificationType.reminder;

      // Tipos SmartNotification - Stock
      case 'stock_low':
      case 'stock_out':
      case 'product_low_stock_warning':
        return NotificationType.lowStock;

      // Tipos SmartNotification - Facturas
      case 'invoice_overdue':
      case 'invoice_due_soon':
      case 'invoice_sent':
        return NotificationType.invoice;

      // Tipos SmartNotification - Pagos
      case 'payment_received':
      case 'payment_failed':
      case 'large_payment_received':
        return NotificationType.payment;

      // Tipos SmartNotification - Sistema
      case 'system_error':
      case 'security_breach':
      case 'backup_completed':
        return NotificationType.system;

      // Tipos SmartNotification - Ventas/Reportes
      case 'sales_milestone':
      case 'monthly_report_ready':
      case 'performance_report':
        return NotificationType.sale;

      // Tipos SmartNotification - Clientes
      case 'new_customer':
      case 'customer_credit_limit':
        return NotificationType.user;

      // Tipos SmartNotification - Otros
      case 'new_feature_available':
        return NotificationType.system;

      default:
        return NotificationType.system;
    }
  }

  /// Mapear string a NotificationPriority
  /// Soporta tanto prioridades simples como SmartNotification (critical = urgent)
  static NotificationPriority _mapStringToNotificationPriority(
    String? priority,
  ) {
    if (priority == null) return NotificationPriority.medium;

    switch (priority.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'medium':
      case 'normal':
        return NotificationPriority.medium;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
      case 'critical': // SmartNotification usa 'critical' para urgente
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.medium;
    }
  }

  /// Convertir a SmartNotification (para uso compartido con Dashboard)
  /// Esto permite usar el mismo modelo de datos en ambas vistas
  Map<String, dynamic> toSmartNotificationJson() {
    return {
      'id': id,
      'type': _mapTypeToSmartType(type),
      'priority': priority.name,
      'status': isRead ? 'read' : 'pending',
      'channels': ['in_app'],
      'title': title,
      'message': message,
      'entityId': relatedId,
      'entityType': actionData?['entityType'] ?? 'unknown',
      'icon': actionData?['icon'] ?? 'notifications',
      'color': actionData?['color'] ?? '#2196F3',
      'createdAt': timestamp.toIso8601String(),
      'updatedAt': timestamp.toIso8601String(),
      'userId': '',
      'organizationId': '',
    };
  }

  /// Mapear NotificationType a string de SmartNotification
  static String _mapTypeToSmartType(NotificationType type) {
    switch (type) {
      case NotificationType.lowStock:
        return 'stock_low';
      case NotificationType.invoice:
        return 'invoice_due_soon';
      case NotificationType.payment:
        return 'payment_received';
      case NotificationType.system:
        return 'system_error';
      case NotificationType.sale:
        return 'sales_milestone';
      case NotificationType.user:
        return 'new_customer';
      case NotificationType.expense:
        return 'payment_failed';
      case NotificationType.reminder:
        return 'invoice_due_soon';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: ${type.name}, title: $title, isRead: $isRead, priority: ${priority.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationModel &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.timestamp == timestamp &&
        other.isRead == isRead &&
        other.priority == priority &&
        other.relatedId == relatedId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        title.hashCode ^
        message.hashCode ^
        timestamp.hashCode ^
        isRead.hashCode ^
        priority.hashCode ^
        relatedId.hashCode;
  }
}
