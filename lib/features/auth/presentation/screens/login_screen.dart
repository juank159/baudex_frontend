// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header_widget.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

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
              title: 'Iniciar Sesión',
              subtitle: 'Bienvenido de vuelta',
            ),
            SizedBox(height: context.verticalSpacing * 2),
            _buildLoginForm(context),
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
                  title: 'Iniciar Sesión',
                  subtitle: 'Bienvenido de vuelta',
                ),
                SizedBox(height: context.verticalSpacing * 2),
                CustomCard(child: _buildLoginForm(context)),
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
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.desktop_windows, size: 120, color: Colors.white),
                    SizedBox(height: 32),
                    Text(
                      'Baudex',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Gestiona tu negocio desde el escritorio',
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
                        title: 'Iniciar Sesión',
                        subtitle: 'Accede a tu cuenta',
                      ),
                      SizedBox(height: context.verticalSpacing * 2),
                      CustomCard(child: _buildLoginForm(context)),
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _onForgotPassword,
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
          ),
          SizedBox(height: context.verticalSpacing),
          Obx(
            () => CustomButton(
              text: 'Iniciar Sesión',
              onPressed: controller.isLoginLoading ? null : controller.login,
              isLoading: controller.isLoginLoading,
              width: double.infinity,
            ),
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
              '¿No tienes cuenta? ',
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
              onPressed: controller.goToRegister,
              child: Text(
                'Regístrate',
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
        if (context.isDesktop) ...[
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

  // ==================== ACCIONES ====================

  void _onForgotPassword() {
    Get.snackbar(
      'Funcionalidad no implementada',
      'La recuperación de contraseña estará disponible pronto',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade800,
      icon: const Icon(Icons.info, color: Colors.orange),
    );
  }
}
