class ApiErrorModel {
  final String message;
  final int? statusCode;
  final String? error;
  final List<String>? details;

  const ApiErrorModel({
    required this.message,
    this.statusCode,
    this.error,
    this.details,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(
      message: json['message'] as String? ?? 'Error desconocido',
      statusCode: json['statusCode'] as int?,
      error: json['error'] as String?,
      details:
          (json['details'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'error': error,
      'details': details,
    };
  }

  /// Obtener el mensaje de error principal
  String get primaryMessage {
    if (details != null && details!.isNotEmpty) {
      return details!.first;
    }
    return message;
  }

  /// Obtener todos los mensajes de error
  List<String> get allMessages {
    if (details != null && details!.isNotEmpty) {
      return details!;
    }
    return [message];
  }

  @override
  String toString() =>
      'ApiErrorModel(message: $message, statusCode: $statusCode)';
}
