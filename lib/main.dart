import 'package:flutter/scheduler.dart';
import 'app/core/theme/performance_mode.dart';
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
import 'app/shared/utils/global_shortcuts.dart';
import 'app/config/constants/api_constants.dart';
import 'app/core/navigation/app_route_observer.dart';
import 'app/core/navigation/route_stack_observer.dart';
import 'app/core/network/bundled_roots.dart';
import 'app/core/diagnostics/startup_trace.dart';
import 'app/core/diagnostics/startup_trace_binding.dart';
import 'app/core/ops/ops_reporter.dart';
import 'app/core/storage/durable_prefs_store.dart';
import 'app/core/storage/prefs_startup_report.dart';
import 'app/core/storage/session_startup_trace.dart';
import 'app/core/ops/ops_health_watcher.dart';
import 'app/core/navigation/getx_route_janitor.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Línea de tiempo del arranque (sale en Diagnóstico → Exportar reporte).
  final trace = StartupTrace.instance;
  startStartupPhase('al abrir');

  // Antes de cualquier conexión: en un Windows recién instalado falta la raíz
  // de Let's Encrypt y, sin esto, la app no logra hablar con el servidor.
  BundledRoots.ensureTrusted();

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
    // Ops API: reporta el error real (el ruido ya se filtró arriba)
    OpsReporter.capture(details.exception, details.stack,
        context: {'library': details.library});
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
    // Suprimir error de GetX Obx dispose en navegación desktop (removeSubscription null check)
    if (message.contains('Null check') &&
        stackStr.contains('removeSubscription')) {
      return true;
    }
    // Ops API: error asíncrono no manejado que no es ruido conocido
    OpsReporter.capture(error, stack);
    return false;
  };

  try {
    // PASO 1: Inicializar datos de localización y timezone
    await trace.task('idioma y zonas horarias', () async {
      await initializeDateFormatting('es_CO', null);
      tz.initializeTimeZones();
    });
    
    // PASO 1.5: Preferencias del equipo a prueba de apagones (Windows y
    // Linux). Va ANTES de cualquier uso de preferencias: el almacén de
    // sesión y la sincronización deciden su modo con lo que lean de ahí.
    await trace.task('preferencias del equipo', () => installDurablePrefs(
      onProblem: (e, st) => OpsReporter.capture(
        e,
        st,
        errorType: 'DevicePreferences',
        fingerprint: 'device_prefs|write',
      ),
    ));

    // PASO 2: Inicializar configuración de entorno
    await trace.task('configuración (.env)', EnvConfig.initialize);

    // Tema completo o liviano, según lo guardado en este equipo.
    await trace.task('modo rendimiento', PerformanceMode.load);

    // PASO 2.1: Central de errores (Ops API → Telegram). Sin OPS_URL queda apagado.
    await trace.task('central de errores', _initOpsReporter);

    // PASO 3: Inicializar base de datos ISAR
    await trace.task('abrir la base local', IsarDatabase.instance.initialize);

    // PASO 3.1: Si las preferencias estaban dañadas y hubo que recuperarlas,
    // dejarlo en Diagnóstico y en la central de errores.
    reportDurablePrefsStartup();
    // Los renglones "sesión: …" y "preferencias: …" de este arranque se
    // escriben en Diagnóstico cuando ya se sabe de qué negocio es el equipo.
    SessionStartupTrace.organizationKnown = () {
      try {
        if (!Get.isRegistered<AuthController>()) return false;
        final org = Get.find<AuthController>().currentUser?.organizationId;
        return org != null && org.isNotEmpty;
      } catch (_) {
        return false;
      }
    };

    // PASO 4: Mostrar configuración
    ApiConstants.printCurrentConfig();

    // PASO 5: Inicializar dependencias offline-first
    trace.taskSync('registrar servicios', () => InitialBinding().dependencies());

    // PASO 6: Vigilante automático de salud (reporta problemas a la Ops API)
    OpsHealthWatcher.start();

  } catch (e, stackTrace) {
  }

  trace.mark('app montada');
  runApp(const MyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) => trace.mark('primer cuadro'));

  // En "Automático": si este equipo tarda en pintar, la app pasa sola al
  // tema liviano. El motor entrega los tiempos en tandas, una vez por
  // segundo: no cuesta nada medible.
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      PerformanceMode.recordRaster(t.rasterDuration.inMicroseconds / 1000);
    }
  });
  PerformanceMode.light.addListener(() {
    trace.mark(PerformanceMode.isLight ? 'tema LIVIANO activado' : 'tema completo activado');
    // Las sombras y desenfoques se deciden al construir: se redibuja todo.
    Get.forceAppUpdate();
  });
}

/// Configura el envío de errores a la Ops API con el cliente (organización)
/// y usuario actuales, para saber a quién afecta cada error.
Future<void> _initOpsReporter() async {
  String? release;
  try {
    final info = await PackageInfo.fromPlatform();
    release = '${info.version}+${info.buildNumber}';
  } catch (_) {
    // Sin versión: el reporte sale igual
  }
  AuthController? auth() =>
      Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
  // La llave va por --dart-define-from-file=ops.json (archivo privado que git
  // ignora); el .env solo sirve de respaldo porque los .env sí se suben a git.
  const definedUrl = String.fromEnvironment('OPS_URL');
  const definedKey = String.fromEnvironment('OPS_KEY');
  OpsReporter.init(
    url: definedUrl.isNotEmpty ? definedUrl : (dotenv.env['OPS_URL'] ?? ''),
    key: definedKey.isNotEmpty ? definedKey : (dotenv.env['OPS_KEY'] ?? ''),
    // En debug nunca avisamos a Telegram aunque el .env apunte a producción
    environment: kDebugMode ? 'development' : (dotenv.env['APP_ENV'] ?? 'production'),
    release: release,
    tenantId: () => auth()?.currentUser?.organizationId,
    userId: () => auth()?.currentUser?.id,
    currentRoute: () => Get.currentRoute,
  );
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
        // Lo último que se guardó en preferencias, a disco.
        installedDurablePrefs?.flush();
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
    // Lo último guardado en preferencias (sesión, marcas) queda en disco
    // antes de salir; con tope para no frenar el cierre.
    try {
      await installedDurablePrefs?.flush().timeout(const Duration(seconds: 3));
    } catch (_) {}
    return AppExitResponse.exit;
  }

  /// Cierra ISAR forzando flush de cualquier transacción pendiente.
  /// Idempotente: seguro de llamar varias veces.
  Future<void> _flushAndCloseIsar() async {
    try {
      final db = IsarDatabase.instance;
      if (db.isInitialized) {
        await db.close();
      }
    } catch (e) {
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
      // En tema liviano las pantallas cambian al instante.
      defaultTransition: PerformanceMode.isLight ? Transition.noTransition : Transition.fade,
      transitionDuration: PerformanceMode.isLight
          ? Duration.zero
          : const Duration(milliseconds: 300),

      // RouteObserver deshabilitado: causa crash nativo de FocusScopeNode en macOS desktop
      // El auto-refresh se maneja via cache del controller (checkAndRefreshIfNeeded)
      // navigatorObservers: [appRouteObserver],
      // Solo anota qué pantallas están abiertas (no avisa a ninguna): la
      // navegación lo usa para volver a una pantalla abierta en vez de
      // crear una segunda copia.
      // GetxRouteJanitor: libera las pantallas cerradas que GetX retiene.
      navigatorObservers: [
        RouteStackObserver.instance,
        GetxRouteJanitor.instance,
      ],

      initialBinding: InitialBinding(),

      // Capa de atajos globales (Ctrl+K, Ctrl+B, Ctrl+/, Alt+1..9).
      // Montada UNA sola vez encima del Navigator. Respeta el árbol de
      // focus de Flutter: si una pantalla interna declara su propio
      // `Shortcuts` (como el form de factura con Ctrl+1..9), el inner
      // gana — estos atajos globales NO interceptan.
      builder: GlobalShortcuts.builder,
    );
  }
}
