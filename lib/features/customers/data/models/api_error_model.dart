// lib/features/customers/data/models/api_error_model.dart
class ApiErrorModel {
  final bool success;
  final String message;
  final String? error;
  final List<String>? errors;
  final String? statusCode;
  final String? timestamp;
  final String? path;

  const ApiErrorModel({
    required this.success,
    required this.message,
    this.error,
    this.errors,
    this.statusCode,
    this.timestamp,
    this.path,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Error desconocido',
      error: json['error'] as String?,
      errors:
          json['errors'] != null
              ? List<String>.from(json['errors'] as List)
              : null,
      statusCode: json['statusCode']?.toString(),
      timestamp: json['timestamp'] as String?,
      path: json['path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'error': error,
      'errors': errors,
      'statusCode': statusCode,
      'timestamp': timestamp,
      'path': path,
    };
  }

  /// Obtener el mensaje principal del error
  String get primaryMessage {
    if (errors != null && errors!.isNotEmpty) {
      return errors!.first;
    }
    return error ?? message;
  }

  /// Obtener todos los mensajes de error
  List<String> get allMessages {
    final messages = <String>[];

    if (message.isNotEmpty) {
      messages.add(message);
    }

    if (error != null && error!.isNotEmpty) {
      messages.add(error!);
    }

    if (errors != null) {
      messages.addAll(errors!);
    }

    // Remover duplicados
    return messages.toSet().toList();
  }

  @override
  String toString() => 'ApiErrorModel(success: $success, message: $message)';
}
