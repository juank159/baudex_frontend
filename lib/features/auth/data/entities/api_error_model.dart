// lib/features/auth/data/entities/api_error_model.dart
class ApiErrorModel {
  final String message;
  final String? code;
  final int? statusCode;
  final List<String>? details;
  final DateTime timestamp;

  const ApiErrorModel({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
    required this.timestamp,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(
      message: json['message'] as String? ?? 'Error desconocido',
      code: json['code'] as String?,
      statusCode: json['statusCode'] as int?,
      details:
          (json['details'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'statusCode': statusCode,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Mensaje principal para mostrar al usuario
  String get primaryMessage {
    if (details != null && details!.isNotEmpty) {
      return details!.first;
    }
    return message;
  }

  /// Mensaje completo con detalles
  String get fullMessage {
    final buffer = StringBuffer(message);
    if (details != null && details!.isNotEmpty) {
      buffer.write('\nDetalles: ${details!.join(', ')}');
    }
    return buffer.toString();
  }

  /// Verificar si es un error de validación
  bool get isValidationError => statusCode == 400;

  /// Verificar si es un error de autenticación
  bool get isAuthError => statusCode == 401;

  /// Verificar si es un error de permisos
  bool get isPermissionError => statusCode == 403;

  /// Verificar si es un error de recurso no encontrado
  bool get isNotFoundError => statusCode == 404;

  /// Verificar si es un error del servidor
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() =>
      'ApiErrorModel(message: $message, statusCode: $statusCode)';
}
