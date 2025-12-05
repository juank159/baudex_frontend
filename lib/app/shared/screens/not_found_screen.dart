// lib/app/shared/screens/not_found_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/custom_button.dart';

class NotFoundScreen extends StatefulWidget {
  const NotFoundScreen({super.key});

  @override
  State<NotFoundScreen> createState() => _NotFoundScreenState();
}

class _NotFoundScreenState extends State<NotFoundScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Controlador para el rebote del ícono
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controlador para el fade del contenido
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animación de rebote
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Animación de fade
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Animación de deslizamiento
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    // Iniciar animaciones
    _bounceController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });

    // Repetir animación de rebote cada 3 segundos
    _bounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _bounceController.reset();
            _bounceController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Página No Encontrada'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return _buildContent(context, isMobile: true);
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: _buildContent(context, isMobile: false),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Panel izquierdo con ilustración
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
            ),
            child: Center(child: _buildIllustration(context, size: 300)),
          ),
        ),
        // Panel derecho con contenido
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: _buildTextContent(context, isMobile: false),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, {required bool isMobile}) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isMobile) ...[
              SizedBox(height: context.verticalSpacing * 2),
              _buildIllustration(context, size: isMobile ? 200 : 250),
              SizedBox(height: context.verticalSpacing * 2),
            ],
            _buildTextContent(context, isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(BuildContext context, {required double size}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Número 404 animado
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (_bounceAnimation.value * 0.2),
              child: Container(
                width: size,
                height: size * 0.6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Fondo con gradiente
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context).primaryColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    // Texto 404
                    Center(
                      child: Text(
                        '404',
                        style: TextStyle(
                          fontSize: size * 0.3,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    // Ícono decorativo
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Icon(
                        Icons.search_off,
                        size: size * 0.15,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // Iconos flotantes decorativos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFloatingIcon(Icons.error_outline, 0),
            _buildFloatingIcon(Icons.help_outline, 500),
            _buildFloatingIcon(Icons.warning_amber_outlined, 1000),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingIcon(IconData icon, int delay) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 2000 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -10 * (0.5 - (value - 0.5).abs()) * 4),
          child: Opacity(
            opacity: 0.5 + (value * 0.3),
            child: Icon(icon, size: 24, color: Theme.of(context).primaryColor),
          ),
        );
      },
    );
  }

  Widget _buildTextContent(BuildContext context, {required bool isMobile}) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment:
              isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            // Título principal
            Text(
              '¡Ups! Página no encontrada',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 24,
                  tablet: 28,
                  desktop: 32,
                ),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineLarge?.color,
              ),
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
            ),

            SizedBox(height: context.verticalSpacing),

            // Descripción
            Text(
              'Lo sentimos, pero la página que estás buscando no existe o ha sido movida.',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
            ),

            SizedBox(height: context.verticalSpacing / 2),

            // Sugerencias
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puedes intentar:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSuggestion(
                    'Verificar la URL en la barra de direcciones',
                  ),
                  _buildSuggestion('Regresar a la página anterior'),
                  _buildSuggestion('Ir a la página principal'),
                  _buildSuggestion('Contactar soporte si el problema persiste'),
                ],
              ),
            ),

            SizedBox(height: context.verticalSpacing * 1.5),

            // Botones de acción
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildActionButtons(context),
              )
            else
              Row(children: _buildActionButtons(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final buttons = [
      CustomButton(
        text: 'Ir al Inicio',
        icon: Icons.home,
        onPressed: () => Get.offAllNamed(AppRoutes.login),
        width: context.isMobile ? double.infinity : null,
      ),
      if (!context.isMobile) const SizedBox(width: 16),
      if (context.isMobile) SizedBox(height: context.verticalSpacing / 2),
      CustomButton(
        text: 'Volver',
        icon: Icons.arrow_back,
        type: ButtonType.outline,
        onPressed: () {
          if (Get.routing.previous.isNotEmpty) {
            Get.back();
          } else {
            Get.offAllNamed(AppRoutes.login);
          }
        },
        width: context.isMobile ? double.infinity : null,
      ),
    ];

    return buttons;
  }
}

// Extensión para crear una página 404 más simple
class Simple404Screen extends StatelessWidget {
  const Simple404Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error 404'), elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              'Página no encontrada',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'La página que buscas no existe',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Ir al inicio',
              onPressed: () => Get.offAllNamed(AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}
