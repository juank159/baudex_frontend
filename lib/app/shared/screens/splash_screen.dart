// // lib/app/shared/screens/splash_screen.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../config/routes/app_routes.dart';
// import '../../core/utils/responsive.dart';
// import '../../../features/auth/presentation/bindings/auth_binding.dart';
// import '../../../features/auth/domain/repositories/auth_repository.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _logoController;
//   late AnimationController _progressController;
//   late Animation<double> _logoAnimation;
//   late Animation<double> _progressAnimation;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _checkInitialRoute();
//   }

//   void _initializeAnimations() {
//     // Controlador para el logo
//     _logoController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );

//     // Controlador para el progreso
//     _progressController = AnimationController(
//       duration: const Duration(milliseconds: 2000),
//       vsync: this,
//     );

//     // Animación del logo (escala)
//     _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
//     );

//     // Animación del progreso
//     _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
//     );

//     // Animación de fade para el texto
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _logoController,
//         curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
//       ),
//     );

//     // Iniciar animaciones
//     _logoController.forward();

//     // Iniciar progreso después de un delay
//     Future.delayed(const Duration(milliseconds: 500), () {
//       if (mounted) {
//         _progressController.forward();
//       }
//     });
//   }

//   Future<void> _checkInitialRoute() async {
//     try {
//       // Esperar que las animaciones se completen
//       await Future.delayed(const Duration(milliseconds: 2500));

//       if (!mounted) return;

//       // Inicializar binding de auth para verificación
//       AuthCheckBinding().dependencies();

//       // Verificar si el usuario está autenticado
//       final authRepo = Get.find<AuthRepository>();
//       final isAuthenticated = await authRepo.isAuthenticated();

//       if (!mounted) return;

//       if (isAuthenticated) {
//         // Usuario autenticado, ir al dashboard
//         Get.offAllNamed(AppRoutes.dashboard);
//       } else {
//         // Usuario no autenticado, ir al login
//         Get.offAllNamed(AppRoutes.login);
//       }
//     } catch (e) {
//       // En caso de error, ir al login
//       if (mounted) {
//         Get.offAllNamed(AppRoutes.login);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _logoController.dispose();
//     _progressController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Theme.of(context).primaryColor,
//               Theme.of(context).primaryColor.withOpacity(0.8),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: ResponsiveLayout(
//             mobile: _buildMobileLayout(context),
//             tablet: _buildTabletLayout(context),
//             desktop: _buildDesktopLayout(context),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMobileLayout(BuildContext context) {
//     return _buildSplashContent(context, isMobile: true);
//   }

//   Widget _buildTabletLayout(BuildContext context) {
//     return _buildSplashContent(context, isMobile: false);
//   }

//   Widget _buildDesktopLayout(BuildContext context) {
//     return Row(
//       children: [
//         // Panel izquierdo con branding adicional
//         Expanded(
//           flex: 1,
//           child: Container(
//             padding: const EdgeInsets.all(48),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: Column(
//                     children: [
//                       Text(
//                         'Bienvenido a',
//                         style: TextStyle(
//                           fontSize: 24,
//                           color: Colors.white.withOpacity(0.9),
//                           fontWeight: FontWeight.w300,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       const Text(
//                         'Baudex',
//                         style: TextStyle(
//                           fontSize: 28,
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'Gestiona tu negocio desde el escritorio con todas las herramientas que necesitas.',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.white.withOpacity(0.8),
//                           height: 1.5,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         // Panel derecho con splash principal
//         Expanded(flex: 1, child: _buildSplashContent(context, isMobile: false)),
//       ],
//     );
//   }

//   Widget _buildSplashContent(BuildContext context, {required bool isMobile}) {
//     final logoSize = isMobile ? 100.0 : 120.0;
//     final titleSize = isMobile ? 32.0 : 40.0;
//     final subtitleSize = isMobile ? 16.0 : 18.0;

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Logo animado
//           AnimatedBuilder(
//             animation: _logoAnimation,
//             builder: (context, child) {
//               return Transform.scale(
//                 scale: _logoAnimation.value,
//                 child: Container(
//                   width: logoSize,
//                   height: logoSize,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.3),
//                       width: 2,
//                     ),
//                   ),
//                   child: Icon(
//                     Icons.desktop_windows,
//                     size: logoSize * 0.6,
//                     color: Colors.white,
//                   ),
//                 ),
//               );
//             },
//           ),

//           SizedBox(height: context.verticalSpacing * 1.5),

//           // Título animado
//           FadeTransition(
//             opacity: _fadeAnimation,
//             child: Text(
//               'Baudex',
//               style: TextStyle(
//                 fontSize: titleSize,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),

//           SizedBox(height: context.verticalSpacing / 2),

//           // Subtítulo animado
//           FadeTransition(
//             opacity: _fadeAnimation,
//             child: Text(
//               'Inicializando...',
//               style: TextStyle(
//                 fontSize: subtitleSize,
//                 color: Colors.white.withOpacity(0.8),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),

//           SizedBox(height: context.verticalSpacing * 2),

//           // Indicador de progreso
//           AnimatedBuilder(
//             animation: _progressAnimation,
//             builder: (context, child) {
//               return Column(
//                 children: [
//                   // Barra de progreso personalizada
//                   Container(
//                     width: isMobile ? 200 : 250,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.3),
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                     child: FractionallySizedBox(
//                       alignment: Alignment.centerLeft,
//                       widthFactor: _progressAnimation.value,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   // Porcentaje
//                   Text(
//                     '${(_progressAnimation.value * 100).toInt()}%',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.white.withOpacity(0.8),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),

//           SizedBox(height: context.verticalSpacing * 2),

//           // Versión de la app
//           FadeTransition(
//             opacity: _fadeAnimation,
//             child: Text(
//               'Versión 1.0.0',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.white.withOpacity(0.6),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Extensión para crear un splash screen más simple si lo necesitas
// class SimpleSplashScreen extends StatelessWidget {
//   const SimpleSplashScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Navegación automática después de 2 segundos
//     Future.delayed(const Duration(seconds: 2), () {
//       if (context.mounted) {
//         Get.offAllNamed(AppRoutes.login);
//       }
//     });

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Theme.of(context).primaryColor,
//               Theme.of(context).primaryColor.withOpacity(0.8),
//             ],
//           ),
//         ),
//         child: const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.desktop_windows, size: 100, color: Colors.white),
//               SizedBox(height: 24),
//               Text(
//                 'Baudex',
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               SizedBox(height: 16),
//               Text(
//                 'Cargando...',
//                 style: TextStyle(fontSize: 16, color: Colors.white70),
//               ),
//               SizedBox(height: 32),
//               SizedBox(
//                 width: 40,
//                 height: 40,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 3,
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// lib/app/shared/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkInitialRoute();
  }

  void _initializeAnimations() {
    // Controlador para el logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Controlador para el progreso
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animación del logo (escala)
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Animación del progreso
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Animación de fade para el texto
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Iniciar animaciones
    _logoController.forward();

    // Iniciar progreso después de un delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  Future<void> _checkInitialRoute() async {
    try {
      // Esperar que las animaciones se completen
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;

      // ✅ Ya no necesitamos AuthCheckBinding porque AuthController está disponible globalmente
      // desde InitialBinding

      // Verificar si el usuario está autenticado usando AuthController
      final authController = Get.find<AuthController>();

      // ✅ Usar directamente el getter isAuthenticated que ya es bool
      final isAuthenticated = authController.isAuthenticated;

      if (!mounted) return;

      if (isAuthenticated) {
        print('🟢 SplashScreen: Usuario autenticado, navegando a dashboard');
        // Usuario autenticado, ir al dashboard
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        print('🔴 SplashScreen: Usuario no autenticado, navegando a login');
        // Usuario no autenticado, ir al login
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (e) {
      print('❌ SplashScreen: Error al verificar autenticación - $e');
      // En caso de error, ir al login
      if (mounted) {
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: ResponsiveLayout(
            mobile: _buildMobileLayout(context),
            tablet: _buildTabletLayout(context),
            desktop: _buildDesktopLayout(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return _buildSplashContent(context, isMobile: true);
  }

  Widget _buildTabletLayout(BuildContext context) {
    return _buildSplashContent(context, isMobile: false);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Panel izquierdo con branding adicional
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Bienvenido a',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Baudex',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Gestiona tu negocio desde el escritorio con todas las herramientas que necesitas.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Panel derecho con splash principal
        Expanded(flex: 1, child: _buildSplashContent(context, isMobile: false)),
      ],
    );
  }

  Widget _buildSplashContent(BuildContext context, {required bool isMobile}) {
    final logoSize = isMobile ? 100.0 : 120.0;
    final titleSize = isMobile ? 32.0 : 40.0;
    final subtitleSize = isMobile ? 16.0 : 18.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animado
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _logoAnimation.value,
                child: Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.desktop_windows,
                    size: logoSize * 0.6,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          SizedBox(height: context.verticalSpacing * 1.5),

          // Título animado
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Baudex',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.verticalSpacing / 2),

          // Subtítulo animado
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Inicializando...',
              style: TextStyle(
                fontSize: subtitleSize,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: context.verticalSpacing * 2),

          // Indicador de progreso
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  // Barra de progreso personalizada
                  Container(
                    width: isMobile ? 200 : 250,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Porcentaje
                  Text(
                    '${(_progressAnimation.value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: context.verticalSpacing * 2),

          // Versión de la app
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Versión 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extensión para crear un splash screen más simple si lo necesitas
class SimpleSplashScreen extends StatelessWidget {
  const SimpleSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Navegación automática usando AuthController
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        try {
          final authController = Get.find<AuthController>();
          if (authController.isAuthenticated) {
            Get.offAllNamed(AppRoutes.dashboard);
          } else {
            Get.offAllNamed(AppRoutes.login);
          }
        } catch (e) {
          Get.offAllNamed(AppRoutes.login);
        }
      }
    });

    return Scaffold(
      body: Container(
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
              Icon(Icons.desktop_windows, size: 100, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'Baudex',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando...',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
