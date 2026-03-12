// lib/features/notifications/data/models/notification_query_model.dart
import '../../../dashboard/domain/entities/notification.dart';

class NotificationQueryModel {
  final int page;
  final int limit;
  final bool? unreadOnly;
  final NotificationType? type;
  final NotificationPriority? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? sortBy;
  final String? sortOrder;

  const NotificationQueryModel({
    this.page = 1,
    this.limit = 20,
    this.unreadOnly,
    this.type,
    this.priority,
    this.startDate,
    this.endDate,
    this.sortBy = 'timestamp',
    this.sortOrder = 'DESC',
  });

  /// Convertir a query parameters para la API
  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {
      'page': page,
      'limit': limit,
    };

    if (unreadOnly != null) {
      params['unreadOnly'] = unreadOnly;
    }

    if (type != null) {
      params['type'] = type!.name;
    }

    if (priority != null) {
      params['priority'] = priority!.name;
    }

    if (startDate != null) {
      params['startDate'] = startDate!.toIso8601String();
    }

    if (endDate != null) {
      params['endDate'] = endDate!.toIso8601String();
    }

    if (sortBy != null && sortBy!.isNotEmpty) {
      params['sortBy'] = sortBy;
    }

    if (sortOrder != null && sortOrder!.isNotEmpty) {
      params['sortOrder'] = sortOrder;
    }

    return params;
  }

  /// Copiar con nuevos valores
  NotificationQueryModel copyWith({
    int? page,
    int? limit,
    bool? unreadOnly,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
  }) {
    return NotificationQueryModel(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'NotificationQueryModel(page: $page, limit: $limit, unreadOnly: $unreadOnly, type: $type, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationQueryModel &&
        other.page == page &&
        other.limit == limit &&
        other.unreadOnly == unreadOnly &&
        other.type == type &&
        other.priority == priority &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.sortBy == sortBy &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode {
    return page.hashCode ^
        limit.hashCode ^
        unreadOnly.hashCode ^
        type.hashCode ^
        priority.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        sortBy.hashCode ^
        sortOrder.hashCode;
  }
}
