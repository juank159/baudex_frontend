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

  // Suprimir error conocido de Flutter desktop: FocusScopeNode disposed
  // durante transiciones de ruta cuando macOS envía lifecycle events.
  // Bug de Flutter framework, no de la app. No afecta funcionalidad.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final message = details.exception.toString();
    if (message.contains('FocusScopeNode') && message.contains('disposed')) {
      return; // Ignorar este error conocido de desktop
    }
    if (message.contains('Invalid state transition') &&
        message.contains('AppLifecycleState')) {
      return; // Ignorar transiciones de lifecycle inválidas en macOS
    }
    originalOnError?.call(details);
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

      // ✅ RouteObserver para auto-refresh al regresar a pantallas
      navigatorObservers: [appRouteObserver],

      initialBinding: InitialBinding(),
    );
  }
}
