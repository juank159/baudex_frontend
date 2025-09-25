// lib/features/notifications/data/models/isar/isar_notification.dart
import 'dart:convert';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/dashboard/domain/entities/notification.dart';
import 'package:isar/isar.dart';

part 'isar_notification.g.dart';

@collection
class IsarNotification {
  Id id = Isar.autoIncrement; // Auto-increment ID para ISAR

  @Index(unique: true)
  late String serverId; // ID del servidor (UUID)

  @Enumerated(EnumType.name)
  late IsarNotificationType type;

  @Index()
  late String title;

  late String message;

  @Index()
  late DateTime timestamp;

  @Index()
  late bool isRead;

  @Enumerated(EnumType.name)
  late IsarNotificationPriority priority;

  @Index()
  String? relatedId;

  // Action data como JSON string
  String? actionDataJson;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Constructores
  IsarNotification();

  IsarNotification.create({
    required this.serverId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.priority,
    this.relatedId,
    this.actionDataJson,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
  });

  // Mappers
  static IsarNotification fromEntity(Notification entity) {
    return IsarNotification.create(
      serverId: entity.id,
      type: _mapNotificationType(entity.type),
      title: entity.title,
      message: entity.message,
      timestamp: entity.timestamp,
      isRead: entity.isRead,
      priority: _mapNotificationPriority(entity.priority),
      relatedId: entity.relatedId,
      actionDataJson:
          entity.actionData != null
              ? _encodeActionData(entity.actionData!)
              : null,
      createdAt: entity.timestamp,
      updatedAt: entity.timestamp,
      isSynced: true, // Asumimos que viene del servidor sincronizado
      lastSyncAt: DateTime.now(),
    );
  }

  Notification toEntity() {
    return Notification(
      id: serverId,
      type: _mapIsarNotificationType(type),
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead,
      priority: _mapIsarNotificationPriority(priority),
      relatedId: relatedId,
      actionData:
          actionDataJson != null ? _decodeActionData(actionDataJson!) : null,
    );
  }

  // Helpers para mapeo de enums
  static IsarNotificationType _mapNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return IsarNotificationType.system;
      case NotificationType.payment:
        return IsarNotificationType.payment;
      case NotificationType.invoice:
        return IsarNotificationType.invoice;
      case NotificationType.lowStock:
        return IsarNotificationType.lowStock;
      case NotificationType.expense:
        return IsarNotificationType.expense;
      case NotificationType.sale:
        return IsarNotificationType.sale;
      case NotificationType.user:
        return IsarNotificationType.user;
      case NotificationType.reminder:
        return IsarNotificationType.reminder;
    }
  }

  static NotificationType _mapIsarNotificationType(IsarNotificationType type) {
    switch (type) {
      case IsarNotificationType.system:
        return NotificationType.system;
      case IsarNotificationType.payment:
        return NotificationType.payment;
      case IsarNotificationType.invoice:
        return NotificationType.invoice;
      case IsarNotificationType.lowStock:
        return NotificationType.lowStock;
      case IsarNotificationType.expense:
        return NotificationType.expense;
      case IsarNotificationType.sale:
        return NotificationType.sale;
      case IsarNotificationType.user:
        return NotificationType.user;
      case IsarNotificationType.reminder:
        return NotificationType.reminder;
    }
  }

  static IsarNotificationPriority _mapNotificationPriority(
    NotificationPriority priority,
  ) {
    switch (priority) {
      case NotificationPriority.low:
        return IsarNotificationPriority.low;
      case NotificationPriority.medium:
        return IsarNotificationPriority.medium;
      case NotificationPriority.high:
        return IsarNotificationPriority.high;
      case NotificationPriority.urgent:
        return IsarNotificationPriority.urgent;
    }
  }

  static NotificationPriority _mapIsarNotificationPriority(
    IsarNotificationPriority priority,
  ) {
    switch (priority) {
      case IsarNotificationPriority.low:
        return NotificationPriority.low;
      case IsarNotificationPriority.medium:
        return NotificationPriority.medium;
      case IsarNotificationPriority.high:
        return NotificationPriority.high;
      case IsarNotificationPriority.urgent:
        return NotificationPriority.urgent;
    }
  }

  // Helpers para action data
  static String _encodeActionData(Map<String, dynamic> actionData) {
    return json.encode(actionData);
  }

  static Map<String, dynamic> _decodeActionData(String actionDataJson) {
    try {
      return json.decode(actionDataJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Métodos de utilidad para offline operations
  bool get isDeleted => deletedAt != null;
  bool get isUnread => !isRead;
  bool get isHighPriority =>
      priority == IsarNotificationPriority.high ||
      priority == IsarNotificationPriority.urgent;
  bool get isUrgent => priority == IsarNotificationPriority.urgent;
  bool get needsSync => !isSynced;
  bool get hasActionData =>
      actionDataJson != null && actionDataJson!.isNotEmpty;
  bool get hasRelatedEntity => relatedId != null && relatedId!.isNotEmpty;

  // Métodos para gestión de tiempo
  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return timestamp.isAfter(weekStart);
  }

  bool get isRecent => DateTime.now().difference(timestamp).inHours < 24;

  // Utility methods para operaciones offline
  void markAsRead() {
    if (!isRead) {
      isRead = true;
      updatedAt = DateTime.now();
      markAsUnsynced();
    }
  }

  void markAsUnread() {
    if (isRead) {
      isRead = false;
      updatedAt = DateTime.now();
      markAsUnsynced();
    }
  }

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void softDelete() {
    deletedAt = DateTime.now();
    markAsUnsynced();
  }

  void restore() {
    deletedAt = null;
    updatedAt = DateTime.now();
    markAsUnsynced();
  }

  // Métodos para búsqueda y filtrado
  bool matchesQuery(String query) {
    final searchTerm = query.toLowerCase();
    return title.toLowerCase().contains(searchTerm) ||
        message.toLowerCase().contains(searchTerm) ||
        type.name.toLowerCase().contains(searchTerm);
  }

  bool matchesType(NotificationType searchType) {
    return _mapIsarNotificationType(type) == searchType;
  }

  bool matchesPriority(NotificationPriority searchPriority) {
    return _mapIsarNotificationPriority(priority) == searchPriority;
  }

  bool isInDateRange(DateTime startDate, DateTime endDate) {
    return timestamp.isAfter(startDate) && timestamp.isBefore(endDate);
  }

  // Método para crear notificación local (no sincronizada)
  static IsarNotification createLocal({
    required String serverId,
    required IsarNotificationType type,
    required String title,
    required String message,
    IsarNotificationPriority priority = IsarNotificationPriority.medium,
    String? relatedId,
    Map<String, dynamic>? actionData,
  }) {
    final now = DateTime.now();
    return IsarNotification.create(
      serverId: serverId,
      type: type,
      title: title,
      message: message,
      timestamp: now,
      isRead: false,
      priority: priority,
      relatedId: relatedId,
      actionDataJson: actionData != null ? _encodeActionData(actionData) : null,
      createdAt: now,
      updatedAt: now,
      isSynced: false, // Creada localmente, necesita sincronización
    );
  }

  // Método para obtener la representación de tiempo formateada
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

  // Método para obtener el nombre de display del tipo
  String get typeDisplayName {
    return _mapIsarNotificationType(type).displayName;
  }

  // Método para obtener el nombre del icono
  String get typeIconName {
    return _mapIsarNotificationType(type).iconName;
  }

  // Método para obtener el nombre de display de la prioridad
  String get priorityDisplayName {
    return _mapIsarNotificationPriority(priority).displayName;
  }

  @override
  String toString() {
    return 'IsarNotification{serverId: $serverId, title: $title, type: $type, isRead: $isRead, isSynced: $isSynced}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IsarNotification && other.serverId == serverId;
  }

  @override
  int get hashCode => serverId.hashCode;
}
