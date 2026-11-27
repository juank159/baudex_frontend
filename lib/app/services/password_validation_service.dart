// lib/app/services/password_validation_service.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../core/errors/exceptions.dart';
import '../core/network/api_interceptor.dart';
import '../core/network/dio_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../shared/widgets/password_validation_dialog.dart';

/// Lo que ve el usuario cuando la contraseña no coincide.
const String wrongPasswordMessage =
    'Contraseña incorrecta. Verifique e intente de nuevo.';

const String _offlineMessage =
    'No se pudo validar la contraseña: sin conexión con el servidor';

/// Error al validar con un mensaje listo para mostrar.
class PasswordValidationException implements Exception {
  final String message;
  const PasswordValidationException(this.message);

  @override
  String toString() => message;
}

/// Mensaje para el diálogo a partir de cualquier error de la validación.
/// Nunca devuelve "Exception: ..." ni el prefijo "Solicitud incorrecta: ".
String passwordValidationErrorMessage(Object error) {
  if (error is PasswordValidationException) return error.message;
  if (error is ConnectionException) return _offlineMessage;
  if (error is AppException) {
    return 'No se pudo validar la contraseña: ${_clean(error.message)}';
  }
  return 'No se pudo validar la contraseña. Intente de nuevo.';
}

String _clean(String message) {
  var m = message.trim();
  for (final p in const ['Exception: ', 'Solicitud incorrecta: ', 'Error: ']) {
    if (m.startsWith(p)) m = m.substring(p.length).trim();
  }
  return m.isEmpty ? 'error del servidor' : m;
}

class PasswordValidationService {
  final DioClient _dioClient;
  final SecureStorageService? _storage;

  PasswordValidationService(this._dioClient, {SecureStorageService? storage})
      : _storage = storage;

  SecureStorageService? get _storageOrNull {
    if (_storage != null) return _storage;
    try {
      return Get.find<SecureStorageService>();
    } catch (_) {
      return null;
    }
  }

  /// Valida la contraseña del usuario que tiene la sesión abierta.
  ///
  /// - true: el servidor (o, sin conexión, la huella guardada en el equipo)
  ///   confirma la contraseña.
  /// - false: contraseña incorrecta (401 del servidor).
  /// - [PasswordValidationException]: no se pudo saber (sin conexión y sin
  ///   huella, error del servidor); su mensaje se puede mostrar tal cual.
  ///
  /// La contraseña se manda tal cual la escribió (sin quitarle espacios).
  Future<bool> validatePassword(String password) async {
    try {
      final response = await _dioClient.post(
        '/auth/validate-password',
        data: {'password': password},
        options: Options(
          // Lleva token y negocio (el servidor exige sesión), pero el 401
          // de "contraseña incorrecta" no debe cerrar la sesión.
          // NO usar `skip_auth_interceptor`: esa marca es para peticiones
          // públicas y quita el token y el negocio.
          extra: {ApiInterceptor.keepSessionOn401: true},
        ),
      );
      return _isValid(response.data);
    } on DioException catch (e) {
      return _onError(_fromDio(e), password);
    } on AppException catch (e) {
      return _onError(e, password);
    } on PasswordValidationException {
      rethrow;
    } catch (_) {
      throw const PasswordValidationException(
          'No se pudo validar la contraseña. Intente de nuevo.');
    }
  }

  /// Respuesta `{success, data: {valid}}`, a veces envuelta dos veces.
  static bool _isValid(dynamic body) {
    var data = body;
    for (var i = 0; i < 3 && data is Map; i++) {
      if (data['valid'] is bool) return data['valid'] as bool;
      data = data['data'];
    }
    return false;
  }

  static AppException _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ConnectionException();
      default:
        final data = e.response?.data;
        final msg = data is Map ? '${data['message'] ?? ''}' : '';
        return ServerException(msg, statusCode: e.response?.statusCode);
    }
  }

  Future<bool> _onError(AppException e, String password) async {
    if (e is ConnectionException) return _validateOffline(password);
    if (e.statusCode == 401) return false;
    if (e.statusCode == 400) {
      throw const PasswordValidationException('Ingrese su contraseña');
    }
    throw PasswordValidationException(passwordValidationErrorMessage(e));
  }

  /// Sin conexión: compara con la huella que guardó el último inicio de
  /// sesión en este equipo (la misma del ingreso sin internet). Si no hay
  /// huella del usuario actual, no se puede confirmar.
  Future<bool> _validateOffline(String password) async {
    final storage = _storageOrNull;
    if (storage == null) {
      throw const PasswordValidationException(_offlineMessage);
    }
    String? email;
    try {
      final user = await storage.getUserData();
      email = user?['email'] as String?;
    } catch (_) {}
    if (email == null || email.trim().isEmpty) {
      throw const PasswordValidationException(_offlineMessage);
    }
    final saved = await storage.getOfflineCredentials();
    final savedEmail = saved?['email'] as String?;
    if (savedEmail != email.toLowerCase().trim() ||
        !await storage.hasOfflineCredentials()) {
      throw const PasswordValidationException(_offlineMessage);
    }
    return storage.verifyOfflineCredentials(email: email, password: password);
  }

  /// Mostrar diálogo de validación de contraseña
  static Future<bool> showPasswordValidationDialog({
    required String title,
    required String message,
  }) async {
    final service = Get.find<PasswordValidationService>();

    final result = await Get.dialog<bool>(
      barrierDismissible: false,
      _PasswordValidationDialog(
        title: title,
        message: message,
        onValidate: service.validatePassword,
      ),
    );

    return result ?? false;
  }
}

// Wrapper del diálogo para usar en el servicio
class _PasswordValidationDialog extends StatelessWidget {
  final String title;
  final String message;
  final Future<bool> Function(String) onValidate;

  const _PasswordValidationDialog({
    required this.title,
    required this.message,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return PasswordValidationDialog(
      title: title,
      message: message,
      onValidate: onValidate,
    );
  }
}
