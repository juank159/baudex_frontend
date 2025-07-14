// // lib/main.dart
// import 'package:baudex_desktop/features/auth/domain/repositories/auth_repository.dart';
// import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'app/config/routes/app_pages.dart';
// import 'app/config/routes/app_routes.dart';
// import 'app/config/themes/app_theme.dart';
// import 'features/auth/presentation/bindings/auth_binding.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Inicializar servicios core
//   await _initializeServices();

//   runApp(MyApp());
// }

// /// Inicializar servicios esenciales
// Future<void> _initializeServices() async {
//   // Registrar servicios core que necesitan estar disponibles globalmente
//   InitialBinding().dependencies();
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Tu Aplicación',
//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: ThemeMode.system,

//       // Configuración de rutas
//       initialRoute: AppRoutes.initial,
//       getPages: AppPages.pages,

//       // Configuración de debug
//       debugShowCheckedModeBanner: false,

//       // Configuración de localización
//       locale: const Locale('es', 'CO'),
//       fallbackLocale: const Locale('en', 'US'),

//       // Configuración de transiciones
//       defaultTransition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),

//       // Configuración de GetX
//       enableLog: true,
//       logWriterCallback: (text, {bool? isError}) {
//         if (isError == true) {
//           print('🔴 GetX Error: $text');
//         } else {
//           print('🔵 GetX: $text');
//         }
//       },

//       // Builder para configuraciones globales
//       builder: (context, child) {
//         return MediaQuery(
//           // Configurar textScaleFactor para desktop
//           data: MediaQuery.of(context).copyWith(
//             textScaleFactor:
//                 MediaQuery.of(context).size.width > 1200 ? 1.0 : 1.0,
//           ),
//           child: child!,
//         );
//       },

//       // Configuración de home
//       home: const SplashScreen(),
//     );
//   }
// }

// // Pantalla de splash temporal
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _checkInitialRoute();
//   }

//   Future<void> _checkInitialRoute() async {
//     // Esperar un momento para mostrar splash
//     await Future.delayed(const Duration(milliseconds: 1500));

//     // Verificar si el usuario está autenticado
//     try {
//       // Inicializar binding de auth para verificación
//       AuthCheckBinding().dependencies();

//       final authRepo = Get.find<AuthRepository>();
//       final isAuthenticated = await authRepo.isAuthenticated();

//       if (isAuthenticated) {
//         // Usuario autenticado, ir al dashboard
//         Get.offAllNamed(AppRoutes.dashboard);
//       } else {
//         // Usuario no autenticado, ir al login
//         Get.offAllNamed(AppRoutes.login);
//       }
//     } catch (e) {
//       // En caso de error, ir al login
//       Get.offAllNamed(AppRoutes.login);
//     }
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
//         child: const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.desktop_windows, size: 100, color: Colors.white),
//               SizedBox(height: 24),
//               Text(
//                 'Tu Aplicación',
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

// // Dashboard temporal
// class DashboardScreen extends StatelessWidget {
//   const DashboardScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dashboard'),
//         actions: [
//           IconButton(
//             onPressed: () {
//               final authController = Get.find<AuthController>();
//               authController.logout();
//             },
//             icon: const Icon(Icons.logout),
//           ),
//         ],
//       ),
//       body: const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.dashboard, size: 100, color: Colors.grey),
//             SizedBox(height: 24),
//             Text(
//               'Dashboard',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Bienvenido a tu aplicación',
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

import 'package:baudex_desktop/app/app_binding.dart';
import 'package:baudex_desktop/app/config/env/env_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/config/routes/app_pages.dart';
import 'app/config/routes/app_routes.dart';
import 'app/config/themes/app_theme.dart';
import 'app/config/constants/api_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Iniciando Baudex Desktop...');

  try {
    // PASO 1: Inicializar configuración de entorno
    await EnvConfig.initialize();

    // PASO 2: Mostrar configuración
    ApiConstants.printCurrentConfig();

    // PASO 3: Inicializar dependencias
    InitialBinding().dependencies();

    print('✅ Inicialización completada');
  } catch (e) {
    print('❌ Error durante inicialización: $e');
    print('⚠️ Continuando con configuración por defecto...');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: EnvConfig.isInitialized ? EnvConfig.appName : 'Baudex Desktop',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      initialRoute: AppRoutes.splash,

      getPages: AppPages.pages,

      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'CO'),
      fallbackLocale: const Locale('en', 'US'),
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),

      initialBinding: BindingsBuilder(() {
        print('🚀 App inicializada con dependencias cargadas');
        print('📍 Ruta inicial: ${AppRoutes.splash}');
      }),
    );
  }
}
