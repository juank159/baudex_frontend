// lib/features/auth/presentation/screens/login_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header_widget.dart';
import '../widgets/email_autocomplete_field.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

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
                GlassCard(
                  child: _buildLoginForm(context),
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
            child: _LeftBrandingPanel(),
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
                          title: 'Iniciar Sesión',
                          subtitle: 'Accede a tu cuenta',
                        ),
                        SizedBox(height: context.verticalSpacing * 2),
                        GlassCard(
                          child: _buildLoginForm(context),
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

  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: controller.loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmailAutocompleteField(
            controller: controller.loginEmailController,
            label: 'Correo Electrónico',
            hint: 'ejemplo@correo.com',
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
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
            ),
          ),
          SizedBox(height: context.verticalSpacing),
          Obx(
            () => ElegantButton(
              text: 'Iniciar Sesión',
              onPressed: controller.isLoginLoading ? null : controller.login,
              isLoading: controller.isLoginLoading,
              width: double.infinity,
              height: 50,
              icon: Icons.login,
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
                color: ElegantLightTheme.textSecondary,
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
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        if (context.isDesktop) ...[
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

// Panel izquierdo de branding con diseño elegante
class _LeftBrandingPanel extends StatefulWidget {
  @override
  State<_LeftBrandingPanel> createState() => _LeftBrandingPanelState();
}

class _LeftBrandingPanelState extends State<_LeftBrandingPanel>
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2563EB), // Blue 600
                    Color(0xFF1D4ED8), // Blue 700
                    Color(0xFF1E40AF), // Blue 800
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: _LoginPatternPainter(animation: _bgAnimation),
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
        // Contenido sobre el fondo
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo con glassmorfismo
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
                  'Baudex',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
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
                  'Gestiona tu negocio desde el escritorio',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Features list
                _buildFeatureItem(Icons.inventory_2_outlined, 'Inventario inteligente'),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.receipt_long_outlined, 'Facturación rápida'),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.analytics_outlined, 'Análisis en tiempo real'),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.cloud_sync_outlined, 'Sincronización offline'),
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

// Painter para patrón decorativo del panel izquierdo del login
class _LoginPatternPainter extends CustomPainter {
  final Animation<double> animation;

  _LoginPatternPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final time = animation.value * 2 * math.pi;

    final circles = [
      _CircleData(0.9, 0.1, 200, 0.06, 0),
      _CircleData(0.05, 0.85, 250, 0.05, math.pi / 3),
      _CircleData(0.75, 0.75, 160, 0.04, math.pi / 2),
      _CircleData(0.2, 0.2, 120, 0.05, math.pi),
      _CircleData(0.5, 0.5, 100, 0.03, math.pi * 1.5),
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
  bool shouldRepaint(covariant _LoginPatternPainter oldDelegate) => true;
}

class _CircleData {
  final double cx, cy, radius, opacity, phase;
  _CircleData(this.cx, this.cy, this.radius, this.opacity, this.phase);
}
