// lib/features/auth/presentation/screens/verify_email_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/auth_controller.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final RxBool _isLoading = false.obs;
  final RxBool _canResend = true.obs;
  final RxInt _countdown = 60.obs;
  Timer? _countdownTimer;

  late String _email;

  @override
  void initState() {
    super.initState();
    _email = Get.arguments?['email'] ?? '';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
      final authController = Get.find<AuthController>();
      await authController.verifyEmail(_email, code);

      // Navegar primero, luego snackbar
      Get.offAllNamed('/login');
      Get.snackbar(
        'Verificación exitosa',
        'Tu correo ha sido verificado correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
      );
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Error de verificación',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
      _clearCode();
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend.value) return;

    try {
      final authController = Get.find<AuthController>();
      await authController.resendVerificationCode(_email);

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
            _buildHeader(context),
            SizedBox(height: context.verticalSpacing * 2),
            _buildVerificationForm(context),
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
                _buildHeader(context),
                SizedBox(height: context.verticalSpacing * 2),
                GlassCard(
                  child: _buildVerificationForm(context),
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
          // Panel izquierdo con branding
          Expanded(
            flex: 3,
            child: _VerifyEmailBrandingPanel(),
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
                        _buildHeader(context),
                        SizedBox(height: context.verticalSpacing * 2),
                        GlassCard(
                          child: _buildVerificationForm(context),
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

  Widget _buildHeader(BuildContext context) {
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
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: Colors.white,
          ),
        ),
        SizedBox(height: context.verticalSpacing),
        Text(
          'Verifica tu correo electrónico',
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
          'Hemos enviado un código de 6 dígitos a',
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
        const SizedBox(height: 4),
        Text(
          _email,
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 14,
              tablet: 16,
              desktop: 18,
            ),
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.primaryBlue,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerificationForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ingresa el código',
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
            text: 'Verificar',
            onPressed: _isLoading.value ? null : _verifyCode,
            isLoading: _isLoading.value,
            width: double.infinity,
            height: 50,
            icon: Icons.check_circle_outline,
          ),
        ),
        SizedBox(height: context.verticalSpacing),
        // Resend code section
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿No recibiste el código? ',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            Obx(
              () => _canResend.value
                  ? TextButton(
                      onPressed: _resendCode,
                      child: Text(
                        'Reenviar',
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
      ],
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
              // Auto-submit on last digit
              _verifyCode();
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

// Panel izquierdo de branding para verificación de email
class _VerifyEmailBrandingPanel extends StatefulWidget {
  @override
  State<_VerifyEmailBrandingPanel> createState() =>
      _VerifyEmailBrandingPanelState();
}

class _VerifyEmailBrandingPanelState extends State<_VerifyEmailBrandingPanel>
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
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2563EB), // Blue 600
                    Color(0xFF1D4ED8), // Blue 700
                    Color(0xFF1E40AF), // Blue 800
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: _VerifyPatternPainter(animation: _bgAnimation),
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
                        Icons.email_outlined,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Verifica tu cuenta',
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
                  'Estás a un paso de completar tu registro',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildFeatureItem(Icons.shield_outlined, 'Cuenta segura'),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.verified_user_outlined, 'Verificación rápida'),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.lock_outline, 'Protección de datos'),
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

// Painter para patrón decorativo del panel de verificación
class _VerifyPatternPainter extends CustomPainter {
  final Animation<double> animation;

  _VerifyPatternPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final time = animation.value * 2 * math.pi;

    final circles = [
      _CircleData(0.15, 0.2, 180, 0.06, 0),
      _CircleData(0.8, 0.15, 220, 0.05, math.pi / 3),
      _CircleData(0.25, 0.7, 160, 0.04, math.pi / 2),
      _CircleData(0.7, 0.65, 140, 0.05, math.pi),
      _CircleData(0.5, 0.4, 120, 0.03, math.pi * 1.5),
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
  bool shouldRepaint(covariant _VerifyPatternPainter oldDelegate) => true;
}

class _CircleData {
  final double cx, cy, radius, opacity, phase;
  _CircleData(this.cx, this.cy, this.radius, this.opacity, this.phase);
}
