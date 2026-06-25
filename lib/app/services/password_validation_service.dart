// lib/app/services/password_validation_service.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../core/network/dio_client.dart';
import '../shared/widgets/password_validation_dialog.dart';

class PasswordValidationService {
  final DioClient _dioClient;

  PasswordValidationService(this._dioClient);

  /// Validar contraseña del usuario actual
  Future<bool> validatePassword(String password) async {
    try {

      final response = await _dioClient.post(
        '/auth/validate-password',
        data: {'password': password},
        options: Options(
          // IMPORTANTE: Evitar que los interceptores 401 causen logout
          extra: {'skip_auth_interceptor': true},
        ),
      );

      // La respuesta del backend viene como: {"success":true,"data":{"valid":true,"message":"..."}}
      final responseData = response.data['data'] as Map<String, dynamic>? ?? {};
      final success = responseData['valid'] as bool? ?? false;
      final message = responseData['message'] as String? ?? '';

      return success;
    } on DioException catch (e) {

      // Para error 401 (contraseña incorrecta), retornar false en lugar de excepción
      if (e.response?.statusCode == 401) {
        return false; // Contraseña incorrecta, no es una excepción crítica
      } else if (e.response?.statusCode == 400) {
        throw Exception('Contraseña requerida');
      } else {
        throw Exception('Error al validar contraseña');
      }
    } catch (e) {
      throw Exception('Error inesperado al validar contraseña');
    }
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
