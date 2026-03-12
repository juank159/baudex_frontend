// lib/features/notifications/data/models/create_notification_request_model.dart
import '../../../dashboard/domain/entities/notification.dart';

class CreateNotificationRequestModel {
  final String type;
  final String title;
  final String message;
  final String priority;
  final String? relatedId;
  final Map<String, dynamic>? actionData;

  const CreateNotificationRequestModel({
    required this.type,
    required this.title,
    required this.message,
    this.priority = 'medium',
    this.relatedId,
    this.actionData,
  });

  /// Crear desde parámetros tipados
  factory CreateNotificationRequestModel.fromParams({
    required NotificationType type,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.medium,
    String? relatedId,
    Map<String, dynamic>? actionData,
  }) {
    return CreateNotificationRequestModel(
      type: type.name,
      title: title,
      message: message,
      priority: priority.name,
      relatedId: relatedId,
      actionData: actionData,
    );
  }

  /// Convertir a JSON (API request)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'type': type,
      'title': title,
      'message': message,
      'priority': priority,
    };

    if (relatedId != null && relatedId!.isNotEmpty) {
      json['relatedId'] = relatedId;
    }

    if (actionData != null && actionData!.isNotEmpty) {
      json['actionData'] = actionData;
    }

    return json;
  }

  /// Validar que los datos sean correctos
  bool isValid() {
    if (title.trim().isEmpty) return false;
    if (message.trim().isEmpty) return false;
    if (!_isValidType(type)) return false;
    if (!_isValidPriority(priority)) return false;
    return true;
  }

  /// Obtener lista de errores de validación
  List<String> getValidationErrors() {
    final List<String> errors = [];

    if (title.trim().isEmpty) {
      errors.add('El título es requerido');
    }

    if (message.trim().isEmpty) {
      errors.add('El mensaje es requerido');
    }

    if (!_isValidType(type)) {
      errors.add('Tipo de notificación inválido: $type');
    }

    if (!_isValidPriority(priority)) {
      errors.add('Prioridad inválida: $priority');
    }

    return errors;
  }

  /// Validar tipo de notificación
  static bool _isValidType(String type) {
    const validTypes = [
      'system',
      'payment',
      'invoice',
      'lowStock',
      'expense',
      'sale',
      'user',
      'reminder',
    ];
    return validTypes.contains(type);
  }

  /// Validar prioridad
  static bool _isValidPriority(String priority) {
    const validPriorities = ['low', 'medium', 'high', 'urgent'];
    return validPriorities.contains(priority);
  }

  @override
  String toString() {
    return 'CreateNotificationRequestModel(type: $type, title: $title, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CreateNotificationRequestModel &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.priority == priority &&
        other.relatedId == relatedId;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        title.hashCode ^
        message.hashCode ^
        priority.hashCode ^
        relatedId.hashCode;
  }
}
