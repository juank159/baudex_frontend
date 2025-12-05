// lib/features/auth/presentation/widgets/change_password_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../controllers/auth_controller.dart';

class ChangePasswordDialog extends GetView<AuthController> {
  const ChangePasswordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('Cambiar Contraseña'),
        ],
      ),
      content: SizedBox(
        width: context.isMobile ? double.maxFinite : 400,
        child: SingleChildScrollView(
          child: Form(
            key: controller.changePasswordFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Contraseña actual
                Obx(
                  () => CustomTextField(
                    controller: controller.currentPasswordController,
                    label: 'Contraseña Actual',
                    hint: 'Ingresa tu contraseña actual',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon:
                        controller.isCurrentPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                    onSuffixIconPressed:
                        controller.toggleCurrentPasswordVisibility,
                    obscureText: !controller.isCurrentPasswordVisible,
                    validator: _validateCurrentPassword,
                  ),
                ),

                SizedBox(height: context.verticalSpacing),

                // Nueva contraseña
                Obx(
                  () => CustomTextField(
                    controller: controller.newPasswordController,
                    label: 'Nueva Contraseña',
                    hint: 'Ingresa tu nueva contraseña',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon:
                        controller.isNewPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                    onSuffixIconPressed: controller.toggleNewPasswordVisibility,
                    obscureText: !controller.isNewPasswordVisible,
                    validator: _validateNewPassword,
                  ),
                ),

                SizedBox(height: context.verticalSpacing),

                // Confirmar nueva contraseña
                CustomTextField(
                  controller: controller.confirmPasswordController,
                  label: 'Confirmar Nueva Contraseña',
                  hint: 'Confirma tu nueva contraseña',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: _validateConfirmPassword,
                ),

                SizedBox(height: context.verticalSpacing / 2),

                // Requisitos de contraseña
                _buildPasswordRequirements(context),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Limpiar formulario y cerrar
            controller.currentPasswordController.clear();
            controller.newPasswordController.clear();
            controller.confirmPasswordController.clear();
            Get.back();
          },
          child: const Text('Cancelar'),
        ),
        Obx(
          () => CustomButton(
            text: 'Cambiar',
            onPressed:
                controller.isLoading
                    ? null
                    : () {
                      if (controller.changePasswordFormKey.currentState!
                          .validate()) {
                        controller.changePassword();
                      }
                    },
            isLoading: controller.isLoading,
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildPasswordRequirements(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text(
                'La nueva contraseña debe contener:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRequirement('Al menos 6 caracteres'),
          _buildRequirement('Una letra minúscula (a-z)'),
          _buildRequirement('Una letra mayúscula (A-Z)'),
          _buildRequirement('Un número (0-9)'),
          _buildRequirement('Diferente a la contraseña actual'),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== VALIDACIONES ====================

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña actual es requerida';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La nueva contraseña es requerida';
    }

    if (value.length < 6) {
      return 'Debe tener al menos 6 caracteres';
    }

    if (value.length > 50) {
      return 'No puede exceder 50 caracteres';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe contener al menos una minúscula';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener al menos una mayúscula';
    }

    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }

    // Validar que sea diferente a la actual
    final currentPassword = controller.currentPasswordController.text;
    if (currentPassword.isNotEmpty && value == currentPassword) {
      return 'Debe ser diferente a la actual';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La confirmación es requerida';
    }

    if (value != controller.newPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }
}
