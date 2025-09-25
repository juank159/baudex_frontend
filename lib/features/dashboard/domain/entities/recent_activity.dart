// lib/features/dashboard/domain/entities/recent_activity.dart
import 'package:equatable/equatable.dart';

class RecentActivity extends Equatable {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? relatedId;
  final Map<String, dynamic>? metadata;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.relatedId,
    this.metadata,
  });

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

  String get formattedTime => timeAgo;

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    description,
    timestamp,
    relatedId,
    metadata,
  ];
}

enum ActivityType {
  invoice,
  payment,
  product,
  customer,
  expense,
  sale,
  order,
  user,
  system,
}

extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.invoice:
        return 'Factura';
      case ActivityType.payment:
        return 'Pago';
      case ActivityType.product:
        return 'Producto';
      case ActivityType.customer:
        return 'Cliente';
      case ActivityType.expense:
        return 'Gasto';
      case ActivityType.sale:
        return 'Venta';
      case ActivityType.order:
        return 'Pedido';
      case ActivityType.user:
        return 'Usuario';
      case ActivityType.system:
        return 'Sistema';
    }
  }

  String get iconName {
    switch (this) {
      case ActivityType.invoice:
        return 'receipt_long';
      case ActivityType.payment:
        return 'payment';
      case ActivityType.product:
        return 'inventory_2';
      case ActivityType.customer:
        return 'person_add';
      case ActivityType.expense:
        return 'trending_down';
      case ActivityType.sale:
        return 'trending_up';
      case ActivityType.order:
        return 'shopping_cart';
      case ActivityType.user:
        return 'person';
      case ActivityType.system:
        return 'settings';
    }
  }
}