// lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header_widget.dart';

class RegisterScreen extends GetView<AuthController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          children: [
            SizedBox(height: context.verticalSpacing),
            const AuthHeaderWidget(
              title: 'Crear Cuenta',
              subtitle: 'Únete a nosotros',
            ),
            SizedBox(height: context.verticalSpacing * 2),
            _buildRegisterForm(context),
            SizedBox(height: context.verticalSpacing),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: AdaptiveContainer(
            maxWidth: 500,
            child: Column(
              children: [
                SizedBox(height: context.verticalSpacing),
                const AuthHeaderWidget(
                  title: 'Crear Cuenta',
                  subtitle: 'Únete a nosotros',
                ),
                SizedBox(height: context.verticalSpacing * 2),
                CustomCard(child: _buildRegisterForm(context)),
                SizedBox(height: context.verticalSpacing),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          // Panel izquierdo con imagen/branding
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.8),
                    Theme.of(context).primaryColor,
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_add, size: 120, color: Colors.white),
                    SizedBox(height: 32),
                    Text(
                      'Únete a Nosotros',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Crea tu cuenta y comienza a gestionar\ntu negocio de manera eficiente',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Panel derecho con formulario
          Expanded(
            flex: 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      const AuthHeaderWidget(
                        title: 'Crear Cuenta',
                        subtitle: 'Completa tus datos',
                      ),
                      SizedBox(height: context.verticalSpacing * 2),
                      CustomCard(child: _buildRegisterForm(context)),
                      SizedBox(height: context.verticalSpacing),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
          // Nombres en fila en tablet/desktop
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
            // Nombres separados en móvil
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
              validator: _validatePassword,
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

          SizedBox(height: context.verticalSpacing / 2),

          _buildPasswordRequirements(context),

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
        ],
      ),
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
          Text(
            'La contraseña debe contener:',
            style: TextStyle(
              fontSize: Responsive.getFontSize(
                context,
                mobile: 12,
                tablet: 13,
                desktop: 14,
              ),
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 6),
          _buildRequirement('Al menos 6 caracteres'),
          _buildRequirement('Una letra minúscula'),
          _buildRequirement('Una letra mayúscula'),
          _buildRequirement('Un número'),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿Ya tienes cuenta? ',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                color: Colors.grey.shade600,
              ),
            ),
            TextButton(
              onPressed: controller.goToLogin,
              child: Text(
                'Inicia Sesión',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (Responsive.isDesktop(context)) ...[
          SizedBox(height: context.verticalSpacing),
          Text(
            '© 2024 Baudex. Todos los derechos reservados.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ==================== VALIDACIONES ====================

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }

    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    if (value.trim().length > 100) {
      return 'El nombre no puede exceder 100 caracteres';
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

    if (value.trim().length > 100) {
      return 'El apellido no puede exceder 100 caracteres';
    }

    return null;
  }

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

    if (value.length > 50) {
      return 'La contraseña no puede exceder 50 caracteres';
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
