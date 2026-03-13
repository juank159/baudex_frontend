// lib/features/auth/presentation/screens/register_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header_widget.dart';

class RegisterScreen extends GetView<AuthController> {
  const RegisterScreen({super.key});

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
                GlassCard(
                  child: _buildRegisterForm(context),
                ),
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
          // Panel izquierdo con branding elegante
          Expanded(
            flex: 3,
            child: _RegisterBrandingPanel(),
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
                    child: Column(
                      children: [
                        const AuthHeaderWidget(
                          title: 'Crear Cuenta',
                          subtitle: 'Completa tus datos',
                        ),
                        SizedBox(height: context.verticalSpacing * 2),
                        GlassCard(
                          child: _buildRegisterForm(context),
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

          _PasswordRequirementsWidget(
            passwordController: controller.registerPasswordController,
            confirmController: controller.registerConfirmPasswordController,
          ),

          SizedBox(height: context.verticalSpacing),

          Obx(
            () => ElegantButton(
              text: 'Crear Cuenta',
              onPressed:
                  controller.isRegisterLoading ? null : controller.register,
              isLoading: controller.isRegisterLoading,
              width: double.infinity,
              height: 50,
              icon: Icons.person_add_outlined,
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
              '¿Ya tienes cuenta? ',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                color: ElegantLightTheme.textSecondary,
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
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
            ),
          ],
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
        final passwordsMatch = password.isNotEmpty &&
            confirm.isNotEmpty &&
            password == confirm;

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
      // Sin input: estado neutral
      icon = Icons.radio_button_unchecked;
      iconColor = ElegantLightTheme.textTertiary;
      textColor = ElegantLightTheme.textTertiary;
    } else if (isMet) {
      // Cumplido: verde
      icon = Icons.check_circle;
      iconColor = Colors.green.shade500;
      textColor = ElegantLightTheme.textPrimary;
    } else {
      // No cumplido: rojo
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
              key: ValueKey('${text}_$isMet\_$hasInput'),
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

// Panel izquierdo de branding para registro
class _RegisterBrandingPanel extends StatefulWidget {
  @override
  State<_RegisterBrandingPanel> createState() => _RegisterBrandingPanelState();
}

class _RegisterBrandingPanelState extends State<_RegisterBrandingPanel>
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
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFF1D4ED8), // Blue 700
                    Color(0xFF2563EB), // Blue 600
                    Color(0xFF1E40AF), // Blue 800
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: _RegisterPatternPainter(animation: _bgAnimation),
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
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
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
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/baudex_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Únete a Baudex',
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
                  'Crea tu cuenta y comienza a gestionar\ntu negocio de manera eficiente',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildStepItem('1', 'Crea tu cuenta gratis'),
                const SizedBox(height: 16),
                _buildStepItem('2', 'Configura tu negocio'),
                const SizedBox(height: 16),
                _buildStepItem('3', 'Empieza a vender'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
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

// Painter para patrón decorativo del panel de registro
class _RegisterPatternPainter extends CustomPainter {
  final Animation<double> animation;

  _RegisterPatternPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final time = animation.value * 2 * math.pi;

    final circles = [
      _CircleData(0.1, 0.15, 190, 0.06, math.pi / 4),
      _CircleData(0.85, 0.8, 230, 0.05, math.pi / 2),
      _CircleData(0.7, 0.2, 150, 0.04, math.pi),
      _CircleData(0.25, 0.75, 130, 0.05, math.pi * 1.3),
      _CircleData(0.5, 0.45, 110, 0.03, math.pi * 1.7),
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
  bool shouldRepaint(covariant _RegisterPatternPainter oldDelegate) => true;
}

class _CircleData {
  final double cx, cy, radius, opacity, phase;
  _CircleData(this.cx, this.cy, this.radius, this.opacity, this.phase);
}
