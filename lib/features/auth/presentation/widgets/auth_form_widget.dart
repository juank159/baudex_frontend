import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../controllers/auth_controller.dart';

enum AuthFormType { login, register }

class AuthFormWidget extends GetView<AuthController> {
  final AuthFormType formType;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;

  const AuthFormWidget({
    super.key,
    required this.formType,
    this.onSecondaryAction,
    this.secondaryActionText,
  });

  @override
  Widget build(BuildContext context) {
    return formType == AuthFormType.login
        ? _buildLoginForm(context)
        : _buildRegisterForm(context);
  }

  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: controller.loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: controller.loginEmailController,
            label: 'Correo Electrónico',
            hint: 'ejemplo@correo.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          SizedBox(height: context.verticalSpacing),
          Obx(
            () => CustomTextField(
              controller: controller.loginPasswordController,
              label: 'Contraseña',
              hint: 'Ingresa tu contraseña',
              prefixIcon: Icons.lock_outline,
              suffixIcon:
                  controller.isLoginPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
              onSuffixIconPressed: controller.toggleLoginPasswordVisibility,
              obscureText: !controller.isLoginPasswordVisible,
              validator: _validatePassword,
            ),
          ),
          SizedBox(height: context.verticalSpacing / 2),
          _buildForgotPasswordButton(context),
          SizedBox(height: context.verticalSpacing),
          Obx(
            () => CustomButton(
              text: 'Iniciar Sesión',
              onPressed: controller.isLoginLoading ? null : controller.login,
              isLoading: controller.isLoginLoading,
              width: double.infinity,
            ),
          ),
          if (onSecondaryAction != null) ...[
            SizedBox(height: context.verticalSpacing),
            _buildSecondaryAction(context),
          ],
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    return Form(
      key: controller.registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (Responsive.isDesktop(context) || Responsive.isTablet(context))
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: controller.registerFirstNameController,
                    label: 'Nombre',
                    hint: 'Tu nombre',
                    prefixIcon: Icons.person_outline,
                    validator: _validateFirstName,
                  ),
                ),
                SizedBox(width: context.horizontalSpacing),
                Expanded(
                  child: CustomTextField(
                    controller: controller.registerLastNameController,
                    label: 'Apellido',
                    hint: 'Tu apellido',
                    prefixIcon: Icons.person_outline,
                    validator: _validateLastName,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                CustomTextField(
                  controller: controller.registerFirstNameController,
                  label: 'Nombre',
                  hint: 'Tu nombre',
                  prefixIcon: Icons.person_outline,
                  validator: _validateFirstName,
                ),
                SizedBox(height: context.verticalSpacing),
                CustomTextField(
                  controller: controller.registerLastNameController,
                  label: 'Apellido',
                  hint: 'Tu apellido',
                  prefixIcon: Icons.person_outline,
                  validator: _validateLastName,
                ),
              ],
            ),
          SizedBox(height: context.verticalSpacing),
          CustomTextField(
            controller: controller.registerEmailController,
            label: 'Correo Electrónico',
            hint: 'ejemplo@correo.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          SizedBox(height: context.verticalSpacing),
          Obx(
            () => CustomTextField(
              controller: controller.registerPasswordController,
              label: 'Contraseña',
              hint: 'Crea una contraseña segura',
              prefixIcon: Icons.lock_outline,
              suffixIcon:
                  controller.isRegisterPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
              onSuffixIconPressed: controller.toggleRegisterPasswordVisibility,
              obscureText: !controller.isRegisterPasswordVisible,
              validator: _validatePasswordRegister,
            ),
          ),
          SizedBox(height: context.verticalSpacing),
          Obx(
            () => CustomTextField(
              controller: controller.registerConfirmPasswordController,
              label: 'Confirmar Contraseña',
              hint: 'Confirma tu contraseña',
              prefixIcon: Icons.lock_outline,
              suffixIcon:
                  controller.isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
              onSuffixIconPressed: controller.toggleConfirmPasswordVisibility,
              obscureText: !controller.isConfirmPasswordVisible,
              validator: _validateConfirmPassword,
            ),
          ),
          SizedBox(height: context.verticalSpacing),
          Obx(
            () => CustomButton(
              text: 'Crear Cuenta',
              onPressed:
                  controller.isRegisterLoading ? null : controller.register,
              isLoading: controller.isRegisterLoading,
              width: double.infinity,
            ),
          ),
          if (onSecondaryAction != null) ...[
            SizedBox(height: context.verticalSpacing),
            _buildSecondaryAction(context),
          ],
        ],
      ),
    );
  }

  Widget _buildForgotPasswordButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Get.snackbar(
            'Funcionalidad no implementada',
            'La recuperación de contraseña estará disponible pronto',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
            icon: const Icon(Icons.info, color: Colors.orange),
          );
        },
        child: Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 14,
              tablet: 15,
              desktop: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onSecondaryAction,
        child: Text(
          secondaryActionText ?? '',
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 16,
              tablet: 17,
              desktop: 18,
            ),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==================== VALIDACIONES ====================

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    const emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    if (!RegExp(emailRegex).hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validatePasswordRegister(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe contener al menos una letra minúscula';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener al menos una letra mayúscula';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }
    return null;
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El apellido es requerido';
    }
    if (value.trim().length < 2) {
      return 'El apellido debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La confirmación de contraseña es requerida';
    }
    if (value != controller.registerPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}
