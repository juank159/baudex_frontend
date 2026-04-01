// lib/features/auth/presentation/screens/forgot_password_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final RxInt _currentStep = 0.obs;
  final RxBool _isLoading = false.obs;

  // Step 0: Enter email
  final _emailController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();

  // Step 1: Enter code
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final RxBool _canResend = true.obs;
  final RxInt _countdown = 60.obs;
  Timer? _countdownTimer;

  // Step 2: New password
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  final RxBool _isPasswordVisible = false.obs;
  final RxBool _isConfirmPasswordVisible = false.obs;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _canResend.value = false;
    _countdown.value = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown.value > 0) {
        _countdown.value--;
      } else {
        _canResend.value = true;
        timer.cancel();
      }
    });
  }

  String _getCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  void _clearCode() {
    for (var controller in _codeControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    _isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      await authController.forgotPassword(_emailController.text.trim());

      _currentStep.value = 1;
      _startCountdown();

      Get.snackbar(
        'Código enviado',
        'Hemos enviado un código de verificación a tu correo',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        icon: const Icon(Icons.email, color: Colors.blue),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _verifyCode() async {
    final code = _getCode();
    if (code.length != 6) {
      Get.snackbar(
        'Código incompleto',
        'Por favor ingresa el código de 6 dígitos',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    _isLoading.value = true;
    try {
      // Code verification is implicit in the next step
      // For now, just move to the next step
      _currentStep.value = 2;
      _isLoading.value = false;
    } catch (e) {
      Get.snackbar(
        'Error de verificación',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
      _clearCode();
      _isLoading.value = false;
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend.value) return;

    try {
      final authController = Get.find<AuthController>();
      await authController.resendForgotPasswordCode(_emailController.text.trim());

      _startCountdown();

      Get.snackbar(
        'Código reenviado',
        'Se ha enviado un nuevo código a tu correo',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        icon: const Icon(Icons.email, color: Colors.blue),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final code = _getCode();
    if (code.length != 6) {
      Get.snackbar(
        'Error',
        'Código de verificación inválido',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
      return;
    }

    _isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      await authController.resetPassword(
        _emailController.text.trim(),
        code,
        _passwordController.text,
      );

      // Navegar primero, luego snackbar (Get.back antes de snackbar
      // para evitar que el snackbar interfiera con la navegación)
      Get.back();
      Get.snackbar(
        'Contraseña actualizada',
        'Tu contraseña ha sido cambiada exitosamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
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
        child: Obx(
          () => Column(
            children: [
              SizedBox(height: context.verticalSpacing),
              _buildHeader(context),
              SizedBox(height: context.verticalSpacing * 2),
              _buildStepContent(context),
              SizedBox(height: context.verticalSpacing),
              _buildFooter(context),
            ],
          ),
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
            child: Obx(
              () => Column(
                children: [
                  SizedBox(height: context.verticalSpacing),
                  _buildHeader(context),
                  SizedBox(height: context.verticalSpacing * 2),
                  GlassCard(
                    child: _buildStepContent(context),
                  ),
                  SizedBox(height: context.verticalSpacing),
                  _buildFooter(context),
                ],
              ),
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
          // Panel izquierdo con branding
          Expanded(
            flex: 3,
            child: _ForgotPasswordBrandingPanel(),
          ),
          // Panel derecho con formulario
          Expanded(
            flex: 2,
            child: Container(
              color: ElegantLightTheme.backgroundColor,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Obx(
                      () => Column(
                        children: [
                          _buildHeader(context),
                          SizedBox(height: context.verticalSpacing * 2),
                          GlassCard(
                            child: _buildStepContent(context),
                          ),
                          SizedBox(height: context.verticalSpacing),
                          _buildFooter(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    IconData icon;
    String title;
    String subtitle;

    switch (_currentStep.value) {
      case 0:
        icon = Icons.lock_reset_outlined;
        title = 'Recuperar Contraseña';
        subtitle = 'Ingresa tu correo electrónico';
        break;
      case 1:
        icon = Icons.pin_outlined;
        title = 'Ingresa el Código';
        subtitle = 'Enviamos un código de 6 dígitos a ${_emailController.text}\nEl código es válido por 10 minutos';
        break;
      case 2:
        icon = Icons.lock_outline;
        title = 'Nueva Contraseña';
        subtitle = 'Crea una contraseña segura';
        break;
      default:
        icon = Icons.lock_reset_outlined;
        title = 'Recuperar Contraseña';
        subtitle = '';
    }

    return Column(
      children: [
        // Icon with gradient
        Container(
          width: context.isMobile ? 80 : 100,
          height: context.isMobile ? 80 : 100,
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: ElegantLightTheme.glowShadow,
          ),
          child: Icon(
            icon,
            size: 48,
            color: Colors.white,
          ),
        ),
        SizedBox(height: context.verticalSpacing),
        Text(
          title,
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 24,
              tablet: 28,
              desktop: 32,
            ),
            fontWeight: FontWeight.bold,
            color: ElegantLightTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.verticalSpacing / 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
            color: ElegantLightTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep.value) {
      case 0:
        return _buildEmailStep(context);
      case 1:
        return _buildCodeStep(context);
      case 2:
        return _buildPasswordStep(context);
      default:
        return _buildEmailStep(context);
    }
  }

  Widget _buildEmailStep(BuildContext context) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context),
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: 'Correo Electrónico',
              hintText: 'ejemplo@correo.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(
                  color: ElegantLightTheme.primaryBlue,
                  width: 2.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.red, width: 2.0),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.isMobile ? 16.0 : 20.0,
                vertical: context.isMobile ? 16.0 : 18.0,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El correo electrónico es requerido';
              }
              const emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
              if (!RegExp(emailRegex).hasMatch(value)) {
                return 'Ingresa un correo electrónico válido';
              }
              return null;
            },
          ),
          SizedBox(height: context.verticalSpacing * 1.5),
          Obx(
            () => ElegantButton(
              text: 'Enviar Código',
              onPressed: _isLoading.value ? null : _sendCode,
              isLoading: _isLoading.value,
              width: double.infinity,
              height: 50,
              icon: Icons.send,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Código de verificación',
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 14,
              tablet: 15,
              desktop: 16,
            ),
            fontWeight: FontWeight.w500,
            color: ElegantLightTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.verticalSpacing),
        // OTP Input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) => _buildOTPField(context, index)),
        ),
        SizedBox(height: context.verticalSpacing * 1.5),
        // Verify Button
        Obx(
          () => ElegantButton(
            text: 'Verificar Código',
            onPressed: _isLoading.value ? null : _verifyCode,
            isLoading: _isLoading.value,
            width: double.infinity,
            height: 50,
            icon: Icons.check_circle_outline,
          ),
        ),
        SizedBox(height: context.verticalSpacing),
        // Resend code
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(
              () => _canResend.value
                  ? TextButton(
                      onPressed: _resendCode,
                      child: Text(
                        'Reenviar código',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 15,
                          ),
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    )
                  : Text(
                      'Reenviar en ${_countdown.value}s',
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                        fontWeight: FontWeight.w500,
                        color: ElegantLightTheme.textTertiary,
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Change email
        TextButton(
          onPressed: () {
            _currentStep.value = 0;
            _clearCode();
            _countdownTimer?.cancel();
            _canResend.value = true;
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 16,
                color: ElegantLightTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Cambiar correo',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 13,
                    tablet: 14,
                    desktop: 15,
                  ),
                  fontWeight: FontWeight.w500,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(BuildContext context) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible.value,
              style: TextStyle(
                fontSize: Responsive.getFontSize(context),
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña',
                hintText: 'Crea una contraseña segura',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: ElegantLightTheme.primaryBlue,
                  ),
                  onPressed: () =>
                      _isPasswordVisible.value = !_isPasswordVisible.value,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    color: ElegantLightTheme.primaryBlue,
                    width: 2.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.red, width: 2.0),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.isMobile ? 16.0 : 20.0,
                  vertical: context.isMobile ? 16.0 : 18.0,
                ),
              ),
              validator: (value) {
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
              },
            ),
          ),
          SizedBox(height: context.verticalSpacing),
          Obx(
            () => TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible.value,
              style: TextStyle(
                fontSize: Responsive.getFontSize(context),
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Confirmar Contraseña',
                hintText: 'Confirma tu contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: ElegantLightTheme.primaryBlue,
                  ),
                  onPressed: () => _isConfirmPasswordVisible.value =
                      !_isConfirmPasswordVisible.value,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    color: ElegantLightTheme.primaryBlue,
                    width: 2.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.red, width: 2.0),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.isMobile ? 16.0 : 20.0,
                  vertical: context.isMobile ? 16.0 : 18.0,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La confirmación de contraseña es requerida';
                }
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
          ),
          SizedBox(height: context.verticalSpacing / 2),
          _PasswordRequirementsWidget(
            passwordController: _passwordController,
            confirmController: _confirmPasswordController,
          ),
          SizedBox(height: context.verticalSpacing),
          Obx(
            () => ElegantButton(
              text: 'Cambiar Contraseña',
              onPressed: _isLoading.value ? null : _resetPassword,
              isLoading: _isLoading.value,
              width: double.infinity,
              height: 50,
              icon: Icons.lock_reset,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPField(BuildContext context, int index) {
    return Container(
      width: context.isMobile ? 42 : 48,
      height: context.isMobile ? 50 : 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        controller: _codeControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: context.isMobile ? 20 : 24,
          fontWeight: FontWeight.bold,
          color: ElegantLightTheme.textPrimary,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => Get.offAllNamed('/login'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back,
                size: 16,
                color: ElegantLightTheme.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'Volver al inicio de sesión',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        if (Responsive.isDesktop(context)) ...[
          SizedBox(height: context.verticalSpacing),
          const Text(
            '© 2026 Baudex. Todos los derechos reservados.',
            style: TextStyle(
              fontSize: 12,
              color: ElegantLightTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// Widget de requisitos de contraseña con validación en tiempo real
class _PasswordRequirementsWidget extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;

  const _PasswordRequirementsWidget({
    required this.passwordController,
    required this.confirmController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([passwordController, confirmController]),
      builder: (context, child) {
        final password = passwordController.text;
        final confirm = confirmController.text;
        final hasInput = password.isNotEmpty;

        final hasMinLength = password.length >= 6;
        final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
        final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
        final hasNumber = RegExp(r'\d').hasMatch(password);
        final passwordsMatch =
            password.isNotEmpty && confirm.isNotEmpty && password == confirm;

        final totalMet = [
          hasMinLength,
          hasLowercase,
          hasUppercase,
          hasNumber,
          passwordsMatch,
        ].where((v) => v).length;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ElegantLightTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: !hasInput
                  ? ElegantLightTheme.textTertiary.withOpacity(0.3)
                  : totalMet == 5
                      ? Colors.green.shade300
                      : ElegantLightTheme.primaryBlue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: !hasInput
                        ? ElegantLightTheme.textTertiary
                        : totalMet == 5
                            ? Colors.green.shade600
                            : ElegantLightTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Requisitos de contraseña',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: !hasInput
                          ? ElegantLightTheme.textSecondary
                          : totalMet == 5
                              ? Colors.green.shade700
                              : ElegantLightTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (hasInput)
                    Text(
                      '$totalMet/5',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: totalMet == 5
                            ? Colors.green.shade600
                            : ElegantLightTheme.primaryBlue,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _buildRequirementRow(
                'Al menos 6 caracteres',
                hasMinLength,
                hasInput,
              ),
              _buildRequirementRow(
                'Una letra minúscula (a-z)',
                hasLowercase,
                hasInput,
              ),
              _buildRequirementRow(
                'Una letra mayúscula (A-Z)',
                hasUppercase,
                hasInput,
              ),
              _buildRequirementRow(
                'Un número (0-9)',
                hasNumber,
                hasInput,
              ),
              _buildRequirementRow(
                'Las contraseñas coinciden',
                passwordsMatch,
                confirm.isNotEmpty,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequirementRow(String text, bool isMet, bool hasInput) {
    final Color iconColor;
    final IconData icon;
    final Color textColor;

    if (!hasInput) {
      icon = Icons.radio_button_unchecked;
      iconColor = ElegantLightTheme.textTertiary;
      textColor = ElegantLightTheme.textTertiary;
    } else if (isMet) {
      icon = Icons.check_circle;
      iconColor = Colors.green.shade500;
      textColor = ElegantLightTheme.textPrimary;
    } else {
      icon = Icons.cancel;
      iconColor = Colors.red.shade400;
      textColor = Colors.red.shade600;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              key: ValueKey('${text}_${isMet}_$hasInput'),
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: isMet && hasInput ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Panel izquierdo de branding para recuperación de contraseña
class _ForgotPasswordBrandingPanel extends StatefulWidget {
  @override
  State<_ForgotPasswordBrandingPanel> createState() =>
      _ForgotPasswordBrandingPanelState();
}

class _ForgotPasswordBrandingPanelState
    extends State<_ForgotPasswordBrandingPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _bgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.linear),
    );
    _bgController.repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo con gradiente
        AnimatedBuilder(
          animation: _bgAnimation,
          builder: (context, child) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color(0xFF1E40AF), // Blue 800
                    Color(0xFF2563EB), // Blue 600
                    Color(0xFF1D4ED8), // Blue 700
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: _ForgotPasswordPatternPainter(animation: _bgAnimation),
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
        // Contenido
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: const Icon(
                        Icons.lock_reset_outlined,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Recupera tu cuenta',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  width: 50,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Restablece tu contraseña de manera segura',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildFeatureItem(Icons.security_outlined, 'Proceso seguro'),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.speed_outlined, 'Recuperación rápida'),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.verified_outlined, 'Verificación por email'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// Painter para patrón decorativo del panel de recuperación
class _ForgotPasswordPatternPainter extends CustomPainter {
  final Animation<double> animation;

  _ForgotPasswordPatternPainter({required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final time = animation.value * 2 * math.pi;

    final circles = [
      _CircleData(0.2, 0.3, 170, 0.06, math.pi / 6),
      _CircleData(0.75, 0.2, 200, 0.05, math.pi / 4),
      _CircleData(0.3, 0.65, 155, 0.04, math.pi / 3),
      _CircleData(0.8, 0.7, 135, 0.05, math.pi * 1.2),
      _CircleData(0.45, 0.45, 115, 0.03, math.pi * 1.6),
    ];

    for (final c in circles) {
      final ox = math.sin(time + c.phase) * 12;
      final oy = math.cos(time + c.phase) * 8;
      paint.color = Colors.white.withOpacity(c.opacity);
      canvas.drawCircle(
        Offset(size.width * c.cx + ox, size.height * c.cy + oy),
        c.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ForgotPasswordPatternPainter oldDelegate) =>
      true;
}

class _CircleData {
  final double cx, cy, radius, opacity, phase;
  _CircleData(this.cx, this.cy, this.radius, this.opacity, this.phase);
}
