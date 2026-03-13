import 'dart:ui';

import 'package:baudex_desktop/app/app_binding.dart';
import 'package:baudex_desktop/app/config/env/env_config.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app/config/routes/app_pages.dart';
import 'app/config/routes/app_routes.dart';
import 'app/config/themes/app_theme.dart';
import 'app/config/constants/api_constants.dart';
import 'app/core/navigation/app_route_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // === HANDLER 1: Errores del framework Flutter (build, layout, paint) ===
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final message = details.exception.toString();
    if (message.contains('FocusScopeNode') && message.contains('disposed')) {
      return;
    }
    if (message.contains('Invalid state transition') &&
        message.contains('AppLifecycleState')) {
      return;
    }
    originalOnError?.call(details);
  };

  // === HANDLER 2: Errores asíncronos no manejados (microtasks, futures) ===
  PlatformDispatcher.instance.onError = (error, stack) {
    final message = error.toString();
    if (message.contains('FocusScopeNode') && message.contains('disposed')) {
      return true;
    }
    if (message.contains('Invalid state transition') &&
        message.contains('AppLifecycleState')) {
      return true;
    }
    if (message.contains('disposed') || message.contains('unmounted')) {
      return true;
    }
    return false;
  };

  print('Iniciando Baudex Desktop con arquitectura offline-first...');

  try {
    // PASO 1: Inicializar datos de localización y timezone
    await initializeDateFormatting('es_CO', null);
    tz.initializeTimeZones();
    
    // PASO 2: Inicializar configuración de entorno
    await EnvConfig.initialize();

    // PASO 3: Inicializar base de datos ISAR
    print('💾 Inicializando base de datos ISAR...');
    await IsarDatabase.instance.initialize();

    // PASO 4: Mostrar configuración
    ApiConstants.printCurrentConfig();

    // PASO 5: Inicializar dependencias offline-first
    InitialBinding().dependencies();

    print('✅ Inicialización offline-first completada');
  } catch (e, stackTrace) {
    print('❌ Error durante inicialización: $e');
    print('📍 Stack trace: $stackTrace');
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('en', 'US'),
      ],
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),

      // RouteObserver deshabilitado: causa crash nativo de FocusScopeNode en macOS desktop
      // El auto-refresh se maneja via cache del controller (checkAndRefreshIfNeeded)
      // navigatorObservers: [appRouteObserver],

      initialBinding: InitialBinding(),
    );
  }
}
