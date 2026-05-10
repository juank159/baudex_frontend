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
    final stackStr = stack.toString();
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
    // Suprimir error de GetX Obx dispose en navegación desktop (removeSubscription null check)
    if (message.contains('Null check') &&
        stackStr.contains('removeSubscription')) {
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // Registramos un listener del ciclo de vida para garantizar que ISAR
    // se cierre limpiamente cuando el usuario hace cmd+Q, apaga la Mac
    // o cierra la ventana. Sin esto, una transacción ISAR en vuelo podría
    // dejar la BD corrupta al reabrir la app.
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: _onExitRequested,
      // onDetach es VoidCallback (no espera futures). Disparamos el cierre
      // como best-effort fire-and-forget. La ruta principal de cierre limpio
      // es onExitRequested, que SÍ es awaitable.
      onDetach: () {
        _flushAndCloseIsar();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  /// Antes de que el SO termine la app: confirmamos el exit pero NO
  /// cerramos ISAR aquí. Razón: este callback se dispara también en
  /// escenarios donde la app PUEDE NO cerrarse (cmd+W, focus loss en
  /// macOS, exit cancelado por el SO). Si cerramos ISAR ahora y la app
  /// sigue viva, todo lo que toque la BD explota con
  /// "ISAR database not initialized".
  ///
  /// El cierre real de ISAR se hace en `onDetach` (cuando el engine se
  /// despega), y sus transacciones son ACID + auto-flush, así que no
  /// perdemos datos aunque el SO mate el proceso de golpe.
  Future<AppExitResponse> _onExitRequested() async {
    return AppExitResponse.exit;
  }

  /// Cierra ISAR forzando flush de cualquier transacción pendiente.
  /// Idempotente: seguro de llamar varias veces.
  Future<void> _flushAndCloseIsar() async {
    try {
      final db = IsarDatabase.instance;
      if (db.isInitialized) {
        await db.close();
        print('💾 ISAR cerrado limpiamente al salir');
      }
    } catch (e) {
      print('⚠️ Error cerrando ISAR al salir: $e');
    }
  }

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
