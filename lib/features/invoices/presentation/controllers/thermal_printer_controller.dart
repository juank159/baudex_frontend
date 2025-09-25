// File: lib/features/invoices/presentation/controllers/thermal_printer_controller.dart
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

// lib/features/invoices/presentation/controllers/thermal_printer_controller.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/invoice.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/domain/entities/printer_settings.dart' as settings;

// ==================== CONFIGURACIÓN ESPECÍFICA SAT Q22UE ====================

class SATQ22UEConfig {
  static const String defaultNetworkIP = '192.168.100.181';
  static const int defaultNetworkPort = 9100;
  static const esc_pos.PaperSize paperSize = esc_pos.PaperSize.mm80;

  // Comandos específicos para SAT Q22UE
  static const List<int> initializeCommands = [
    0x1B, 0x40, // ESC @ (Inicializar impresora)
    0x1B, 0x74, 0x06, // ESC t (Seleccionar juego de caracteres)
  ];

  static const List<int> cutCommands = [
    0x1D, 0x56, 0x41, 0x03, // Corte parcial
  ];

  static const List<int> openDrawerCommands = [
    0x1B, 0x70, 0x00, 0x19, 0xFF, // Abrir cajón
  ];
}

// ==================== MODELOS DE DATOS ====================

class NetworkPrinterInfo {
  final String name;
  final String ip;
  final int port;
  final bool isConnected;

  const NetworkPrinterInfo({
    required this.name,
    required this.ip,
    required this.port,
    this.isConnected = false,
  });

  NetworkPrinterInfo copyWith({
    String? name,
    String? ip,
    int? port,
    bool? isConnected,
  }) {
    return NetworkPrinterInfo(
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class PrintJob {
  final String invoiceNumber;
  final DateTime timestamp;
  final bool success;
  final String? error;
  final String method;

  const PrintJob({
    required this.invoiceNumber,
    required this.timestamp,
    required this.success,
    this.error,
    required this.method,
  });
}

// ==================== CONTROLADOR PRINCIPAL ====================

class ThermalPrinterController extends GetxController {
  // ==================== DEPENDENCIAS ====================

  SettingsController? _settingsController;

  // ==================== ESTADO DEL CONTROLADOR ====================

  bool _isControllerActive =
      true; // ✅ NUEVO: Rastrear si el controlador está activo

  // ==================== OBSERVABLES ====================

  final _isConnected = false.obs;
  final _isPrinting = false.obs;
  final _lastError = Rxn<String>();
  final _printHistory = <PrintJob>[].obs;

  // Estado de red vs USB
  final _preferUSB = true.obs; // Desktop prefiere USB
  final _networkPrinters = <NetworkPrinterInfo>[].obs;
  final _selectedPrinter = Rxn<NetworkPrinterInfo>();

  // Configuraciones de impresión
  final _paperWidth = 80.obs; // 58mm o 80mm
  final _autoCut = true.obs;
  final _openCashDrawer = false.obs;

  // Configuración de impresora actual
  final _currentPrinterConfig = Rxn<settings.PrinterSettings>();

  // ==================== CACHE DE OPTIMIZACIÓN ====================

  // Cache del logo procesado para evitar cargarlo cada vez
  img.Image? _cachedLogo;
  DateTime? _logoLoadTime;
  static const Duration _logoCacheExpiry = Duration(hours: 1);

  final format = NumberFormat(
    '#,###',
    'es_CO',
  ); // es_CO usa puntos como separador

  // ==================== GETTERS ====================

  bool get isConnected => _isConnected.value;
  bool get isPrinting => _isPrinting.value;
  String? get lastError => _lastError.value;
  List<PrintJob> get printHistory => _printHistory;
  bool get preferUSB => _preferUSB.value;
  List<NetworkPrinterInfo> get networkPrinters => _networkPrinters;
  List<NetworkPrinterInfo> get discoveredPrinters => _networkPrinters;
  NetworkPrinterInfo? get selectedPrinter => _selectedPrinter.value;

  // Configuraciones de impresión
  int get paperWidth => _paperWidth.value;
  bool get autoCut => _autoCut.value;
  bool get openCashDrawer => _openCashDrawer.value;
  settings.PrinterSettings? get currentPrinterConfig =>
      _currentPrinterConfig.value;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    print('🖨️ ThermalPrinterController: Inicializando...');
    _initializeSettingsController();
    _initializePrinter();
  }

  // ✅ NUEVA FUNCIÓN: Configurar impresora temporal para pruebas
  Future<void> setTempPrinterConfig(settings.PrinterSettings config) async {
    print('🔧 Configurando impresora temporal para pruebas: ${config.name}');
    _currentPrinterConfig.value = config;
  }

  Future<void> _initializeSettingsController() async {
    try {
      // Intentar obtener SettingsController existente
      _settingsController = Get.find<SettingsController>();
      print('✅ SettingsController encontrado');

      // Cargar configuración de impresora por defecto
      await _loadDefaultPrinterConfig();
    } catch (e) {
      print('⚠️ SettingsController no encontrado inicialmente: $e');
      print(
        '🔄 Configurando reintento para cargar configuración de impresora...',
      );
      _settingsController = null;

      // ✅ NUEVO: Programa reintento para cargar configuración después
      _scheduleSettingsRetry();
    }
  }

  /// ✅ NUEVO: Programa reintentos para cargar la configuración de impresora
  void _scheduleSettingsRetry() {
    // Programar reintentos con delays incrementales
    final retryDelays = [1, 3, 5, 10]; // segundos

    for (int i = 0; i < retryDelays.length; i++) {
      Future.delayed(Duration(seconds: retryDelays[i]), () async {
        if (_settingsController == null && _isControllerActive) {
          await _retryLoadingSettings(i + 1, retryDelays.length);
        }
      });
    }
  }

  /// ✅ NUEVO: Reintenta cargar configuración de impresora
  Future<void> _retryLoadingSettings(int attempt, int maxAttempts) async {
    try {
      print('🔄 Intento $attempt/$maxAttempts: Buscando SettingsController...');
      _settingsController = Get.find<SettingsController>();
      print('✅ SettingsController encontrado en intento $attempt');

      // Cargar configuración de impresora
      await _loadDefaultPrinterConfig();
    } catch (e) {
      print(
        '⚠️ Intento $attempt fallido: SettingsController aún no disponible',
      );

      if (attempt == maxAttempts) {
        print(
          '❌ Todos los reintentos agotados. Impresora usará configuración por defecto.',
        );
      }
    }
  }

  Future<void> _loadDefaultPrinterConfig() async {
    if (_settingsController == null) return;

    try {
      print('🔍 Cargando configuración de impresora por defecto...');
      await _settingsController!.loadPrinterSettings();

      final defaultPrinter = _settingsController!.defaultPrinter;
      if (defaultPrinter != null) {
        _currentPrinterConfig.value = defaultPrinter;
        print('📄 Impresora por defecto cargada: ${defaultPrinter.name}');
        print('   - Tipo: ${defaultPrinter.connectionType}');
        print('   - IP: ${defaultPrinter.ipAddress}');
        print('   - Puerto: ${defaultPrinter.port}');
        print('   - Papel: ${defaultPrinter.paperSize}mm');
      } else {
        print('⚠️ No hay impresora por defecto configurada');
      }
    } catch (e) {
      print('❌ Error cargando configuración de impresora: $e');
    }
  }

  /// ✅ NUEVO: Método público para forzar recarga de configuración de impresora
  /// Este método puede ser llamado desde enhanced_payment_dialog.dart antes de imprimir
  Future<bool> ensurePrinterConfigLoaded() async {
    print('🔄 === ASEGURANDO CONFIGURACIÓN DE IMPRESORA ===');

    // Si ya tenemos configuración, verificar que sigue siendo válida
    if (_currentPrinterConfig.value != null) {
      print(
        '✅ Configuración de impresora ya disponible: ${_currentPrinterConfig.value!.name}',
      );
      return true;
    }

    // Intentar cargar SettingsController si no está disponible
    if (_settingsController == null) {
      try {
        print('🔍 Intentando obtener SettingsController...');
        _settingsController = Get.find<SettingsController>();
        print('✅ SettingsController obtenido exitosamente');
      } catch (e) {
        print('❌ SettingsController no disponible: $e');
        return false;
      }
    }

    // Cargar configuración de impresora
    await _loadDefaultPrinterConfig();

    final hasConfig = _currentPrinterConfig.value != null;
    if (hasConfig) {
      print('✅ Configuración de impresora cargada exitosamente');
    } else {
      print('⚠️ No se pudo cargar configuración de impresora');
    }

    return hasConfig;
  }

  @override
  void onClose() {
    print('🔚 ThermalPrinterController: Cerrando conexiones...');
    _isControllerActive = false; // ✅ NUEVO: Marcar controlador como inactivo
    _closeAllConnections();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  Future<void> _initializePrinter() async {
    try {
      // Determinar estrategia según plataforma
      if (kIsWeb || GetPlatform.isMobile) {
        _preferUSB.value = false; // Móvil/Web solo red
        print('📱 Plataforma móvil/web detectada - Solo impresión por red');
      } else {
        _preferUSB.value = true; // Desktop prefiere USB
        print('💻 Plataforma desktop detectada - Preferencia USB');
      }

      await _discoverNetworkPrinters();

      print('✅ ThermalPrinterController inicializado');
    } catch (e) {
      print('❌ Error inicializando impresora térmica: $e');
      _lastError.value = e.toString();
    }
  }

  // ==================== UTILIDADES HELPER ====================

  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (GetPlatform.isMobile) return 'Mobile';
    if (GetPlatform.isDesktop) return 'Desktop';
    return 'Unknown';
  }
  // ==================== DISCOVERY ====================

  Future<void> _discoverNetworkPrinters() async {
    try {
      print('🔍 Buscando impresoras en red...');

      // Limpiar lista anterior
      _networkPrinters.clear();

      // Probar IP conocida primero
      final isAvailable = await _testNetworkPrinter(
        SATQ22UEConfig.defaultNetworkIP,
        SATQ22UEConfig.defaultNetworkPort,
      );

      if (isAvailable) {
        _networkPrinters.add(
          const NetworkPrinterInfo(
            name: 'SAT Q22UE',
            ip: SATQ22UEConfig.defaultNetworkIP,
            port: SATQ22UEConfig.defaultNetworkPort,
            isConnected: false,
          ),
        );
        print('✅ Impresora SAT encontrada en IP conocida');
      }
    } catch (e) {
      print('❌ Error en descubrimiento de red: $e');
      _lastError.value = 'Error buscando impresoras: $e';
    }
  }

  Future<bool> _testNetworkPrinter(String ip, int port) async {
    NetworkPrinter? printer;
    try {
      final profile = await esc_pos.CapabilityProfile.load();
      printer = NetworkPrinter(SATQ22UEConfig.paperSize, profile);

      // Intentar conexión con timeout más corto para evitar bloqueos
      final result = await printer
          .connect(ip, port: port)
          .timeout(const Duration(seconds: 2));

      if (result == PosPrintResult.success) {
        try {
          printer.disconnect(); // Sin await - void return
        } catch (disconnectError) {
          // Ignorar error de desconexión
        }
        print('✅ Impresora encontrada en $ip:$port');
        return true;
      }

      // No intentar desconectar si la conexión falló
      return false;
    } catch (e) {
      print('⚠️ No hay impresora en $ip:$port - $e');
      // No intentar desconectar si hubo una excepción durante la conexión
      return false;
    }
  }

  Future<void> refreshPrinters() async {
    print('🔄 Refrescando lista de impresoras...');
    await _discoverNetworkPrinters();
  }
  // ==================== IMPRESIÓN PRINCIPAL ====================

  // ✅ NUEVA FUNCIÓN: Imprimir página de prueba
  Future<bool> printTestPage() async {
    if (_isPrinting.value) {
      _showError(
        'Impresión en curso',
        'Ya hay una impresión en curso, espere a que termine',
      );
      return false;
    }

    try {
      _isPrinting.value = true;
      _lastError.value = null;

      print('🖨️ === IMPRIMIENDO PÁGINA DE PRUEBA ===');

      final printerConfig = _currentPrinterConfig.value;
      if (printerConfig != null) {
        print('📄 Usando impresora configurada: ${printerConfig.name}');
        print('   - Tipo: ${printerConfig.connectionType}');
        print('   - IP: ${printerConfig.ipAddress}');
        print('   - Puerto: ${printerConfig.port}');
        print('   - USB: ${printerConfig.usbPath}');
        print('   - Papel: ${printerConfig.paperSize}mm');
      } else {
        print('⚠️ No hay impresora configurada, usando valores por defecto');
      }

      bool success = false;

      // Usar configuración de impresora si está disponible
      if (printerConfig != null) {
        if (printerConfig.connectionType ==
            settings.PrinterConnectionType.usb) {
          print('🔌 Página de prueba USB configurada');
          success = await _printTestPageUSB(printerConfig);
        } else {
          print('🌐 Página de prueba por red configurada');
          success = await _printTestPageNetworkWithConfig(printerConfig);
        }
      } else {
        // Fallback a la lógica por defecto
        print('📱 Imprimiendo página de prueba por red...');
        success = await _printTestPageNetwork();
      }

      if (success) {
        _addToPrintHistory(null, true, null, 'Test Page');
        print('✅ Página de prueba impresa exitosamente');
      } else {
        _addToPrintHistory(null, false, _lastError.value, 'Test Page');
        print('❌ Error al imprimir página de prueba');
      }

      return success;
    } catch (e) {
      print('💥 Error inesperado en impresión de página de prueba: $e');
      _lastError.value = e.toString();
      _addToPrintHistory(null, false, e.toString(), 'Test Page');
      return false;
    } finally {
      _isPrinting.value = false;
    }
  }

  Future<bool> printInvoice(Invoice invoice) async {
    if (_isPrinting.value) {
      _showError(
        'Impresión en curso',
        'Ya hay una impresión en curso, espere a que termine',
      );
      return false;
    }

    try {
      _isPrinting.value = true;
      _lastError.value = null;

      print('🖨️ === INICIANDO IMPRESIÓN TÉRMICA ===');
      print('   - Factura: ${invoice.number}');
      print('   - Plataforma: ${_getPlatformName()}');

      // ✅ NUEVA LÓGICA: Usar configuración de impresora por defecto
      final printerConfig = _currentPrinterConfig.value;
      if (printerConfig != null) {
        print('📄 Usando impresora configurada: ${printerConfig.name}');
        print('   - Tipo: ${printerConfig.connectionType}');
        print('   - IP: ${printerConfig.ipAddress}');
        print('   - Puerto: ${printerConfig.port}');
        print('   - Papel: ${printerConfig.paperSize}mm');
      } else {
        print('⚠️ No hay impresora configurada, usando valores por defecto');
      }

      bool success = false;

      // ✅ NUEVA LÓGICA: Usar configuración de impresora
      if (printerConfig != null) {
        if (printerConfig.connectionType == 'usb') {
          print('🔌 Impresión USB configurada');
          success = await _printViaUSB(invoice);
        } else {
          print('🌐 Impresión por red configurada');
          success = await _printViaNetworkWithConfig(invoice, printerConfig);
        }
      } else {
        // Fallback a la lógica anterior
        if (Platform.isWindows) {
          print('🪟 Windows detectado - Forzando impresión por red');
          success = await _printViaNetwork(invoice);
        } else if (!kIsWeb && !GetPlatform.isMobile && _preferUSB.value) {
          print('💻 Intentando impresión USB primero...');
          success = await _printViaUSB(invoice);

          if (!success) {
            print('🔄 USB falló, intentando red...');
            success = await _printViaNetwork(invoice);
          }
        } else {
          print('📱 Imprimiendo solo por red...');
          success = await _printViaNetwork(invoice);
        }
      }

      if (success) {
        _addToPrintHistory(invoice, true);
        //_showSuccess('Factura impresa exitosamente');
        print('✅ Impresión completada exitosamente');
      } else {
        _addToPrintHistory(invoice, false, _lastError.value);
        _showError(
          'Error al imprimir',
          _lastError.value ?? "Error desconocido",
        );
        print('❌ Impresión falló');
      }

      return success;
    } catch (e) {
      print('💥 Error inesperado en impresión: $e');
      _lastError.value = e.toString();
      _addToPrintHistory(invoice, false, e.toString());
      _showError('Error inesperado', e.toString());
      return false;
    } finally {
      _isPrinting.value = false;
    }
  }

  // ==================== IMPRESIÓN USB ====================

  Future<bool> _printViaUSB(Invoice invoice) async {
    try {
      print('🔌 Intentando impresión USB...');

      // TODO: Implementar impresión USB directa
      // Esto requiere librerías específicas del SO o comandos del sistema

      if (Platform.isWindows) {
        return await _printUSBWindows(invoice);
      } else if (Platform.isLinux) {
        return await _printUSBLinux(invoice);
      } else if (Platform.isMacOS) {
        return await _printUSBMacOS(invoice);
      }

      print('⚠️ Impresión USB no soportada en esta plataforma');
      _lastError.value = 'Impresión USB no soportada en esta plataforma';
      return false;
    } catch (e) {
      print('❌ Error en impresión USB: $e');
      _lastError.value = 'USB: $e';
      return false;
    }
  }

  Future<bool> _printUSBWindows(Invoice invoice) async {
    print('🪟 Impresión USB Windows no implementada aún');
    _lastError.value = 'Impresión USB Windows no implementada';
    return false;
  }

  Future<bool> _printUSBLinux(Invoice invoice) async {
    print('🐧 Impresión USB Linux no implementada aún');
    _lastError.value = 'Impresión USB Linux no implementada';
    return false;
  }

  Future<bool> _printUSBMacOS(Invoice invoice) async {
    print('🍎 Impresión USB macOS no implementada aún');
    _lastError.value = 'Impresión USB macOS no implementada';
    return false;
  }

  // ==================== IMPRESIÓN USB PARA PÁGINAS DE PRUEBA ====================

  Future<Uint8List> _generateTestPageContentUSB(
    settings.PrinterSettings config,
  ) async {
    print(
      '📄 Generando contenido USB para página de prueba (formato ESC/POS)...',
    );

    try {
      // Usar el generador de comandos ESC/POS directamente
      final profile = await esc_pos.CapabilityProfile.load();

      // Crear el tamaño de papel correcto
      esc_pos.PaperSize paperSize;
      if (config.paperSize == settings.PaperSize.mm58) {
        paperSize = esc_pos.PaperSize.mm58;
      } else {
        paperSize = esc_pos.PaperSize.mm80;
      }

      // Crear generador de comandos ESC/POS
      final generator = esc_pos.Generator(paperSize, profile);
      List<int> commands = [];

      // Comandos de inicialización
      commands.addAll(SATQ22UEConfig.initializeCommands);

      // Título centrado y grande
      commands.addAll(
        generator.text(
          'PÁGINA DE PRUEBA',
          styles: esc_pos.PosStyles(
            align: esc_pos.PosAlign.center,
            bold: true,
            height: esc_pos.PosTextSize.size2,
            width: esc_pos.PosTextSize.size2,
          ),
        ),
      );
      commands.addAll(generator.feed(2));

      // Información del sistema
      commands.addAll(
        generator.text(
          'Sistema: Baudex Desktop',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(
        generator.text(
          'Impresora: ${config.name}',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(
        generator.text(
          'Conexión: USB',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(
        generator.text(
          'Ruta: ${config.usbPath}',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(
        generator.text(
          'Papel: ${config.paperSize == settings.PaperSize.mm58 ? "58mm" : "80mm"}',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(
        generator.text(
          'Fecha: ${DateTime.now().toString().split(' ')[0]}',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(
        generator.text(
          'Hora: ${DateTime.now().toString().split(' ')[1].split('.')[0]}',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(generator.feed(2));

      // Línea separadora
      commands.addAll(
        generator.text(
          '================================',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(generator.feed(1));

      // Prueba de caracteres
      commands.addAll(
        generator.text(
          'Prueba de caracteres:',
          styles: esc_pos.PosStyles(bold: true),
        ),
      );
      commands.addAll(generator.text('ABCDEFGHIJKLMNOPQRSTUVWXYZ'));
      commands.addAll(generator.text('abcdefghijklmnopqrstuvwxyz'));
      commands.addAll(generator.text('0123456789'));
      commands.addAll(generator.text('ñáéíóúü ¡!¿?'));
      commands.addAll(generator.feed(2));

      // Prueba de alineación
      commands.addAll(
        generator.text(
          'Izquierda',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.left),
        ),
      );
      commands.addAll(
        generator.text(
          'Centro',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(
        generator.text(
          'Derecha',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.right),
        ),
      );
      commands.addAll(generator.feed(2));

      // Mensaje final
      commands.addAll(
        generator.text(
          'Impresión exitosa!',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center, bold: true),
        ),
      );
      commands.addAll(generator.feed(2));

      // Línea separadora final
      commands.addAll(
        generator.text(
          '================================',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(generator.feed(1));

      // Corte de papel si está habilitado
      if (config.autoCut) {
        commands.addAll(SATQ22UEConfig.cutCommands);
      }

      // Abrir caja registradora si está habilitado
      if (config.cashDrawer) {
        commands.addAll(SATQ22UEConfig.openDrawerCommands);
      }

      final data = Uint8List.fromList(commands);

      print(
        '📝 Contenido generado con Generator ESC/POS: ${data.length} bytes',
      );
      print('✅ Contenido USB generado: ${data.length} bytes');
      return data;
    } catch (e) {
      print('❌ Error generando contenido USB: $e');
      // Fallback a formato simple si hay error
      return Uint8List.fromList(
        utf8.encode('Error generando contenido de prueba: $e'),
      );
    }
  }

  Future<bool> _printToUSBWindows(String usbPath, Uint8List data) async {
    try {
      print("🪟 Imprimiendo a USB Windows: $usbPath");

      // Crear archivo temporal con los datos
      final tempFile =
          "${Directory.systemTemp.path}\\temp_print_${DateTime.now().millisecondsSinceEpoch}.tmp";
      final file = File(tempFile);
      await file.writeAsBytes(data);

      print("📁 Archivo temporal creado: $tempFile");

      // Método 1: Usar PowerShell Out-Printer que es más confiable
      final psResult = await Process.run("powershell", [
        "-Command",
        "Get-Content '$tempFile' -Raw | Out-Printer -Name '$usbPath'",
      ]);

      print("🔍 Resultado PowerShell Out-Printer:");
      print("   - Código de salida: ${psResult.exitCode}");
      print("   - Salida estándar: ${psResult.stdout}");
      print("   - Salida de error: ${psResult.stderr}");

      if (psResult.exitCode == 0) {
        print("✅ Impresión exitosa con PowerShell Out-Printer");
        await _cleanupTempFile(file);
        return true;
      } else {
        print("❌ Error con PowerShell Out-Printer: ${psResult.stderr}");
      }

      // Método 2: Usar copy con UNC path
      final copyResult = await Process.run("copy", [
        "/b",
        tempFile,
        "\\\\localhost\\$usbPath",
      ]);

      if (copyResult.exitCode == 0) {
        print("✅ Impresión exitosa con copy UNC");
        await _cleanupTempFile(file);
        return true;
      } else {
        print("❌ Error con copy UNC: ${copyResult.stderr}");
      }

      // Método 3: Buscar impresoras USB con WMI
      final wmiResult = await Process.run("wmic", [
        "printer",
        "get",
        "name,portname",
        "/format:csv",
      ]);

      if (wmiResult.exitCode == 0) {
        final lines = wmiResult.stdout.toString().split("\n");

        for (String line in lines) {
          if (line.contains("USB") ||
              line.contains("POS") ||
              line.contains("Thermal")) {
            final parts = line.split(",");
            if (parts.length >= 3) {
              final printerName = parts[2].trim();
              if (printerName.isNotEmpty && printerName != "Name") {
                print("🖨️ Intentando con impresora encontrada: $printerName");

                final testPrintResult = await Process.run("print", [
                  "/D:$printerName",
                  tempFile,
                ]);

                if (testPrintResult.exitCode == 0) {
                  print("✅ Impresión exitosa con WMI: $printerName");
                  await _cleanupTempFile(file);
                  return true;
                }
              }
            }
          }
        }
      }

      // Método 4: Intentar con variaciones del nombre
      final variations = [
        "USB$usbPath",
        "USB00$usbPath",
        "USB${usbPath.replaceAll("USB", "").replaceAll("00", "")}",
        "POS-80",
        "POS-58",
        "Thermal Printer",
      ];

      for (String variation in variations) {
        print("🔄 Probando con variación: $variation");
        final varResult = await Process.run("print", [
          "/D:$variation",
          tempFile,
        ]);

        if (varResult.exitCode == 0) {
          print("✅ Impresión exitosa con variación: $variation");
          await _cleanupTempFile(file);
          return true;
        }
      }

      await _cleanupTempFile(file);
      print("❌ No se pudo enviar a ninguna impresora USB");
      _lastError.value = "No se pudo encontrar o acceder a la impresora USB";
      return false;
    } catch (e) {
      print("❌ Error en impresión USB Windows: $e");
      _lastError.value = "Error USB Windows: $e";
      return false;
    }
  }

  Future<void> _cleanupTempFile(File file) async {
    try {
      await file.delete();
      print('🧹 Archivo temporal eliminado');
    } catch (e) {
      print('⚠️ No se pudo eliminar archivo temporal: $e');
    }
  }

  Future<bool> _printToUSBLinux(String usbPath, Uint8List data) async {
    try {
      print('🐧 Imprimiendo a USB Linux: $usbPath');

      // En Linux, las impresoras USB suelen estar en /dev/usb/lp0, /dev/usb/lp1, etc.
      String devicePath = usbPath;

      // Si no es una ruta absoluta, asumir que es un dispositivo en /dev/usb/
      if (!usbPath.startsWith('/')) {
        devicePath = '/dev/usb/$usbPath';
      }

      print('📂 Ruta del dispositivo: $devicePath');

      // Verificar que el dispositivo existe
      final deviceFile = File(devicePath);
      if (!await deviceFile.exists()) {
        print('❌ El dispositivo $devicePath no existe');
        _lastError.value = 'El dispositivo $devicePath no existe';
        return false;
      }

      // Escribir datos directamente al dispositivo
      try {
        await deviceFile.writeAsBytes(data, mode: FileMode.write);
        print('✅ Datos enviados exitosamente a USB Linux');
        return true;
      } catch (e) {
        print('❌ Error escribiendo al dispositivo: $e');
        _lastError.value = 'Error escribiendo al dispositivo: $e';
        return false;
      }
    } catch (e) {
      print('❌ Error en impresión USB Linux: $e');
      _lastError.value = 'Error USB Linux: $e';
      return false;
    }
  }

  Future<bool> _printToUSBMacOS(String usbPath, Uint8List data) async {
    try {
      print('🍎 Imprimiendo a USB macOS: $usbPath');

      // En macOS, podemos usar el sistema de impresión CUPS
      // Primero intentar con lpr
      final tempFile =
          '${Directory.systemTemp.path}/temp_print_${DateTime.now().millisecondsSinceEpoch}.tmp';
      final file = File(tempFile);
      await file.writeAsBytes(data);

      // Intentar imprimir con lpr
      final result = await Process.run('lpr', [
        '-P',
        usbPath,
        '-o',
        'raw',
        tempFile,
      ]);

      // Limpiar archivo temporal
      try {
        await file.delete();
      } catch (e) {
        print('⚠️ No se pudo eliminar archivo temporal: $e');
      }

      if (result.exitCode == 0) {
        print('✅ Datos enviados exitosamente a USB macOS');
        return true;
      } else {
        print('❌ Error en lpr: ${result.stderr}');
        _lastError.value = 'Error en lpr: ${result.stderr}';
        return false;
      }
    } catch (e) {
      print('❌ Error en impresión USB macOS: $e');
      _lastError.value = 'Error USB macOS: $e';
      return false;
    }
  }

  // ==================== IMPRESIÓN RED ====================

  Future<bool> _printViaNetwork(Invoice invoice) async {
    try {
      print('🌐 Intentando impresión por red...');

      if (_networkPrinters.isEmpty) {
        await _discoverNetworkPrinters();
      }

      if (_networkPrinters.isEmpty) {
        _lastError.value = 'No se encontraron impresoras en red';
        return false;
      }

      // Usar la primera impresora disponible
      final printerInfo = _networkPrinters.first;
      return await _sendToPrinter(printerInfo, invoice);
    } catch (e) {
      print('❌ Error en impresión por red: $e');
      _lastError.value = 'Red: $e';
      return false;
    }
  }

  // ✅ NUEVA FUNCIÓN: Impresión por red con configuración específica
  Future<bool> _printViaNetworkWithConfig(
    Invoice invoice,
    settings.PrinterSettings config,
  ) async {
    try {
      print('🌐 Impresión por red con configuración específica...');
      print('   - IP: ${config.ipAddress}');
      print('   - Puerto: ${config.port}');
      print('   - Papel: ${config.paperSize}mm');

      final printerInfo = NetworkPrinterInfo(
        name: config.name,
        ip: config.ipAddress ?? '',
        port: config.port ?? 9100,
        isConnected: false,
      );

      return await _sendToPrinterWithConfig(printerInfo, invoice, config);
    } catch (e) {
      print('❌ Error en impresión por red con configuración: $e');
      _lastError.value = 'Red (configurada): $e';
      return false;
    }
  }

  Future<bool> _sendToPrinter(
    NetworkPrinterInfo printerInfo,
    Invoice invoice,
  ) async {
    NetworkPrinter? printer;

    try {
      final profile = await esc_pos.CapabilityProfile.load();
      printer = NetworkPrinter(SATQ22UEConfig.paperSize, profile);

      print('🔗 Conectando a ${printerInfo.ip}:${printerInfo.port}...');

      final result = await printer.connect(
        printerInfo.ip,
        port: printerInfo.port,
      );

      if (result != PosPrintResult.success) {
        _lastError.value = 'Error de conexión: ${result.msg}';
        return false;
      }

      _isConnected.value = true;
      print('✅ Conectado a impresora SAT');

      // ⚡ GENERACIÓN Y ENVÍO CONTINUO
      try {
        // Generar contenido de impresión
        await _generatePrintContent(printer, invoice);

        // ⚡ SOLO UN DELAY FINAL MÍNIMO ANTES DEL CORTE
        await Future.delayed(const Duration(milliseconds: 100));

        // Enviar comandos de corte
        printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.cutCommands));

        print('📄 Contenido enviado a impresora exitosamente');
        return true;
      } catch (contentError) {
        print('❌ Error generando contenido: $contentError');
        _lastError.value = 'Error en contenido: $contentError';
        return false;
      }
    } catch (e) {
      print('❌ Error enviando a impresora: $e');
      _lastError.value = e.toString();
      return false;
    } finally {
      if (printer != null) {
        // ⚡ DELAY MÍNIMO ANTES DE DESCONECTAR
        await Future.delayed(const Duration(milliseconds: 200));
        printer.disconnect();
        _isConnected.value = false;
        print('🔌 Desconectado de impresora');
      }
    }
  }

  // ✅ NUEVA FUNCIÓN: Envío con configuración específica
  Future<bool> _sendToPrinterWithConfig(
    NetworkPrinterInfo printerInfo,
    Invoice invoice,
    settings.PrinterSettings config,
  ) async {
    NetworkPrinter? printer;

    try {
      final profile = await esc_pos.CapabilityProfile.load();

      // Usar el tamaño de papel configurado
      esc_pos.PaperSize paperSize = esc_pos.PaperSize.mm80;
      if (config.paperSize == settings.PaperSize.mm58) {
        paperSize = esc_pos.PaperSize.mm58;
      }

      printer = NetworkPrinter(paperSize, profile);

      print('🔗 Conectando a ${printerInfo.ip}:${printerInfo.port}...');

      final result = await printer.connect(
        printerInfo.ip,
        port: printerInfo.port,
      );

      if (result != PosPrintResult.success) {
        _lastError.value = 'Error de conexión: ${result.msg}';
        return false;
      }

      _isConnected.value = true;
      print('✅ Conectado a impresora ${config.name}');

      // ⚡ GENERACIÓN Y ENVÍO CONTINUO
      try {
        // Generar contenido de impresión con configuración
        await _generatePrintContentWithConfig(printer, invoice, config);

        // ⚡ SOLO UN DELAY FINAL MÍNIMO ANTES DEL CORTE
        await Future.delayed(const Duration(milliseconds: 100));

        // Enviar comandos de corte si está habilitado
        if (config.autoCut) {
          printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.cutCommands));
        }

        print('📄 Contenido enviado a impresora exitosamente');
        return true;
      } catch (contentError) {
        print('❌ Error generando contenido: $contentError');
        _lastError.value = 'Error en contenido: $contentError';
        return false;
      }
    } catch (e) {
      print('❌ Error enviando a impresora: $e');
      _lastError.value = e.toString();
      return false;
    } finally {
      if (printer != null) {
        // ⚡ DELAY MÍNIMO ANTES DE DESCONECTAR
        await Future.delayed(const Duration(milliseconds: 200));
        printer.disconnect();
        _isConnected.value = false;
        print('🔌 Desconectado de impresora');
      }
    }
  }

  // ==================== GENERACIÓN DE CONTENIDO ====================

  Future<void> _generatePrintContent(
    NetworkPrinter printer,
    Invoice invoice,
  ) async {
    try {
      print('📝 === GENERANDO CONTENIDO DE IMPRESIÓN ===');

      // Inicializar impresora con comandos específicos SAT
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.initializeCommands));

      // ⚡ SOLO UN DELAY INICIAL MÍNIMO PARA INICIALIZACIÓN
      await Future.delayed(const Duration(milliseconds: 50));

      // Header de empresa
      print('📝 Imprimiendo header...');
      await _printBusinessHeader(printer);

      // Información de factura
      print('📝 Imprimiendo info factura...');
      await _printInvoiceInfo(printer, invoice);

      // Información del cliente
      print('📝 Imprimiendo info cliente...');
      await _printCustomerInfo(printer, invoice);

      // Items
      print('📝 Imprimiendo items...');
      await _printItems(printer, invoice);

      // Totales
      print('📝 Imprimiendo totales...');
      await _printTotals(printer, invoice);

      // Footer
      print('📝 Imprimiendo footer...');
      await _printFooter(printer, invoice);

      // Espaciado final
      printer.feed(3);

      print('✅ Contenido de impresión generado completamente');
    } catch (e) {
      print('❌ Error generando contenido: $e');
      throw Exception('Error en generación de contenido: $e');
    }
  }

  // ✅ NUEVA FUNCIÓN: Generar contenido con configuración específica
  Future<void> _generatePrintContentWithConfig(
    NetworkPrinter printer,
    Invoice invoice,
    settings.PrinterSettings config,
  ) async {
    try {
      print('📝 === GENERANDO CONTENIDO CON CONFIGURACIÓN ===');
      print('   - Impresora: ${config.name}');
      print('   - Papel: ${config.paperSize}mm');
      print('   - Auto corte: ${config.autoCut}');

      // Inicializar impresora con comandos específicos SAT
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.initializeCommands));

      // ⚡ SOLO UN DELAY INICIAL MÍNIMO PARA INICIALIZACIÓN
      await Future.delayed(const Duration(milliseconds: 50));

      // Header de empresa
      print('📝 Imprimiendo header...');
      await _printBusinessHeader(printer);

      // Información de factura
      print('📝 Imprimiendo info factura...');
      await _printInvoiceInfo(printer, invoice);

      // Información del cliente
      print('📝 Imprimiendo info cliente...');
      await _printCustomerInfo(printer, invoice);

      // Items
      print('📝 Imprimiendo items...');
      await _printItems(printer, invoice);

      // Totales
      print('📝 Imprimiendo totales...');
      await _printTotals(printer, invoice);

      // Footer
      print('📝 Imprimiendo footer...');
      await _printFooter(printer, invoice);

      // Espaciado final
      printer.feed(3);

      print(
        '✅ Contenido de impresión con configuración generado completamente',
      );
    } catch (e) {
      print('❌ Error generando contenido con configuración: $e');
      throw Exception('Error en generación de contenido: $e');
    }
  }

  /// ⚡ OPTIMIZADO: Cargar logo con cache para impresión rápida
  Future<img.Image?> _loadLogoImage() async {
    try {
      // Verificar si tenemos logo en cache y no ha expirado
      if (_cachedLogo != null && _logoLoadTime != null) {
        final timeSinceLoad = DateTime.now().difference(_logoLoadTime!);
        if (timeSinceLoad < _logoCacheExpiry) {
          print(
            '⚡ Usando logo desde CACHE (${timeSinceLoad.inSeconds}s antiguo)',
          );
          return _cachedLogo;
        } else {
          print('🔄 Cache del logo expirado, recargando...');
        }
      }

      print('🖼️ Cargando logo desde assets (primera vez o cache expirado)...');

      // Cargar imagen desde assets
      final ByteData data = await rootBundle.load(
        'assets/images/LOGO_FORTALEZA.png',
      );
      // final ByteData data = await rootBundle.load(
      //   'assets/images/LOGO_GRANADA.png',
      // );
      final Uint8List bytes = data.buffer.asUint8List();

      // Decodificar imagen
      final img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        print('❌ No se pudo decodificar la imagen');
        return null;
      }

      // Redimensionar para impresora térmica (máximo 384 píxeles de ancho para 80mm)
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: 480, // Ancho máximo recomendado
        height: -1, // Altura proporcional
        interpolation:
            img.Interpolation.nearest, // Mejor para impresoras térmicas
      );

      // Convertir a escala de grises y aumentar contraste
      final img.Image processedImage = _processImageForThermal(resizedImage);

      // ⚡ GUARDAR EN CACHE
      _cachedLogo = processedImage;
      _logoLoadTime = DateTime.now();

      print(
        '✅ Logo procesado y cacheado: ${processedImage.width}x${processedImage.height}',
      );
      return processedImage;
    } catch (e) {
      print('❌ Error cargando logo: $e');
      return null;
    }
  }

  /// Procesar imagen para impresión térmica óptima
  img.Image _processImageForThermal(img.Image image) {
    // Convertir a escala de grises
    final img.Image grayImage = img.grayscale(image);

    // Aumentar contraste para mejor definición en impresora térmica
    final img.Image contrastedImage = img.contrast(grayImage, contrast: 150);

    // Aplicar dithering para mejor calidad en blanco y negro
    final img.Image ditheredImage = img.monochrome(contrastedImage);

    return ditheredImage;
  }

  /// Verificar si hay logo disponible
  Future<bool> _hasLogoAvailable() async {
    try {
      await rootBundle.load('assets/images/LOGO_GRANADA.png');
      return true;
    } catch (e) {
      print('⚠️ Logo no disponible: $e');
      return false;
    }
  }

  Future<void> _printBusinessHeader(NetworkPrinter printer) async {
    try {
      print('🏢 Imprimiendo header de empresa...');

      // ⚠️ CAMBIO: Intentar logo pero con mejor manejo de errores
      final bool hasLogo = await _hasLogoAvailable();

      if (hasLogo) {
        print('🖼️ Imprimiendo header con logo...');
        try {
          await _printBusinessHeaderWithImage(printer);
          print('✅ Logo impreso exitosamente');
        } catch (logoError) {
          print('❌ Error con logo, usando texto: $logoError');
          await _printBusinessHeaderTextOnly(printer);
        }
      } else {
        print('📝 Imprimiendo header sin logo...');
        await _printBusinessHeaderTextOnly(printer);
      }

      print('✅ Header de empresa completado');
    } catch (e) {
      print('❌ Error en header, usando versión de texto: $e');
      await _printBusinessHeaderTextOnly(printer);
    }
  }

  /// Header con imagen
  Future<void> _printBusinessHeaderWithImage(NetworkPrinter printer) async {
    try {
      // Cargar y procesar logo
      final img.Image? logo = await _loadLogoImage();

      if (logo != null) {
        // Imprimir logo centrado
        printer.image(logo, align: esc_pos.PosAlign.center);

        // ⚠️ ASEGURAR QUE DESPUÉS DEL LOGO CONTINÚE EL TEXTO
        printer.feed(1);

        // Información de la empresa después del logo
        printer.text(
          'Ragonvalia, Norte de Santander',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        );

        printer.text(
          'Calle 8  # 3-05 B. Centenario',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        );

        // printer.text(
        //   'Av 3  # 2-58 B. Humildad',
        //   styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        // );

        printer.feed(1);
      } else {
        // Si falla la carga del logo, usar texto
        await _printBusinessHeaderTextOnly(printer);
      }
    } catch (e) {
      print('❌ Error imprimiendo logo: $e');
      // Fallback a versión de texto
      await _printBusinessHeaderTextOnly(printer);
    }
  }

  /// Header solo texto (versión original como fallback)
  Future<void> _printBusinessHeaderTextOnly(NetworkPrinter printer) async {
    // Logo/Título centrado (versión original)
    printer.text(
      ' La Granada.',
      styles: const esc_pos.PosStyles(
        align: esc_pos.PosAlign.center,
        bold: true,
        height: esc_pos.PosTextSize.size2,
        width: esc_pos.PosTextSize.size2,
      ),
    );

    printer.text(
      'Ragonvalia, Norte de Santander',
      styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
    );

    printer.text(
      'Tel: +57 3167181910',
      styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
    );

    printer.feed(1);
  }

  void setImageQuality({
    int maxWidth = 800,
    bool useMonochrome = true,
    int contrast = 250,
  }) {
    // Estas configuraciones se pueden usar en _processImageForThermal
    print('⚙️ Configuración de imagen actualizada');
    print('   - Ancho máximo: ${maxWidth}px');
    print('   - Monocromo: $useMonochrome');
    print('   - Contraste: $contrast');
  }

  /// Debug de imagen
  Future<void> debugImageInfo() async {
    try {
      final hasLogo = await _hasLogoAvailable();
      print('🔍 === INFO DE IMAGEN ===');
      print('   - Logo disponible: $hasLogo');

      if (hasLogo) {
        final logo = await _loadLogoImage();
        if (logo != null) {
          print('   - Dimensiones: ${logo.width}x${logo.height}');
          print('   - Canales: ${logo.numChannels}');
        }
      }
    } catch (e) {
      print('❌ Error en debug de imagen: $e');
    }
  }

  Future<void> _printInvoiceInfo(
    NetworkPrinter printer,
    Invoice invoice,
  ) async {
    try {
      printer.text(
        'FACTURA DE VENTA',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          bold: true,
          height: esc_pos.PosTextSize.size1,
          width: esc_pos.PosTextSize.size1,
        ),
      );

      printer.feed(1);

      // Número de factura
      printer.row([
        esc_pos.PosColumn(
          text: 'No:',
          width: 4,
          styles: const esc_pos.PosStyles(bold: true),
        ),
        esc_pos.PosColumn(
          text: invoice.number,
          width: 8,
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right),
        ),
      ]);

      // Fecha
      final now = DateTime.now();
      final dateStr =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      printer.row([
        esc_pos.PosColumn(
          text: 'Fecha:',
          width: 4,
          styles: const esc_pos.PosStyles(bold: true),
        ),
        esc_pos.PosColumn(
          text: dateStr,
          width: 8,
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right),
        ),
      ]);

      // Método de pago
      printer.row([
        esc_pos.PosColumn(
          text: 'Pago:',
          width: 4,
          styles: const esc_pos.PosStyles(bold: true),
        ),
        esc_pos.PosColumn(
          text: invoice.paymentMethodDisplayName,
          width: 8,
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right),
        ),
      ]);

      printer.hr();
    } catch (e) {
      print('❌ Error imprimiendo info factura: $e');
      throw e;
    }
  }

  Future<void> _printCustomerInfo(
    NetworkPrinter printer,
    Invoice invoice,
  ) async {
    try {
      printer.text('CLIENTE:', styles: const esc_pos.PosStyles(bold: true));

      printer.text(
        invoice.customerName,
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      );

      if (invoice.customerEmail?.isNotEmpty == true) {
        printer.text(
          invoice.customerEmail!,
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
        );
      }

      printer.hr();
    } catch (e) {
      print('❌ Error imprimiendo info cliente: $e');
      throw e;
    }
  }

  Future<void> _printItems(NetworkPrinter printer, Invoice invoice) async {
    try {
      // ✅ ENCABEZADO DE TABLA PROFESIONAL
      printer.text(
        'ITEM      CANT.       V.UNIT                              TOTAL',
        styles: esc_pos.PosStyles(
          align: esc_pos.PosAlign.left, // Alineación centrada
          bold: true,
          fontType: esc_pos.PosFontType.fontB,
        ),
      );
      printer.hr(ch: '-', len: 40);

      // ✅ CONTADOR DE ITEMS
      int itemNumber = 1;

      for (final item in invoice.items) {
        // ✅ TÍTULO DEL PRODUCTO CON NÚMERO
        printer.text(
          '${itemNumber.toString().padLeft(2, '0')} - ${item.description.toUpperCase()}',
          styles: const esc_pos.PosStyles(
            bold: true,
            align: esc_pos.PosAlign.left,
          ),
        );

        // ✅ LÍNEA DE DETALLES CON FORMATEO PROFESIONAL
        final quantity = item.quantity.toInt().toString();
        final total = item.quantity * item.unitPrice;

        // ✅ FORMATEAR LÍNEA CON WIDTH CORRECTO (total = 12)
        printer.row([
          esc_pos.PosColumn(
            text: '',
            width: 2, // Cantidad
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
          ),
          esc_pos.PosColumn(
            text: quantity,
            width: 2, // Unidad
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
          ),
          esc_pos.PosColumn(
            text: AppFormatters.formatCurrency(item.unitPrice),
            width: 4, // Precio unitario con formato profesional
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
          ),
          esc_pos.PosColumn(
            text: AppFormatters.formatCurrency(total),
            width: 4, // Total del item con formato profesional
            styles: const esc_pos.PosStyles(
              align: esc_pos.PosAlign.right,
              bold: true,
            ),
          ),
        ]);

        // ✅ INFORMACIÓN ADICIONAL (garantía automática)
        if (item.notes != null && item.notes!.isNotEmpty) {
          printer.text(
            item.notes!,
            styles: const esc_pos.PosStyles(
              fontType: esc_pos.PosFontType.fontB,
              align: esc_pos.PosAlign.left,
            ),
          );
        } else {
          // Garantía por defecto para ciertos productos
          if (item.description.toLowerCase().contains('impresora') ||
              item.description.toLowerCase().contains('equipo') ||
              item.description.toLowerCase().contains('dispositivo')) {
            printer.text(
              'GARANTIA DE 3 MESES POR DEFECTOS DE FABRICA',
              styles: const esc_pos.PosStyles(
                fontType: esc_pos.PosFontType.fontB,
                align: esc_pos.PosAlign.left,
              ),
            );
          }
        }

        itemNumber++;
      }

      // ✅ RESUMEN DE ITEMS
      printer.hr(ch: '-', len: 40);
      printer.text(
        'TOTAL ITEMS: ${invoice.items.length}',
        styles: const esc_pos.PosStyles(
          bold: true,
          align: esc_pos.PosAlign.left,
        ),
      );
      printer.feed(1);
    } catch (e) {
      print('❌ Error imprimiendo items: $e');
      throw e;
    }
  }

  Future<void> _printTotals(NetworkPrinter printer, Invoice invoice) async {
    try {
      // ✅ SUBTOTAL CON FORMATO PROFESIONAL
      // if (invoice.subtotal != invoice.total) {
      //   printer.row([
      //     esc_pos.PosColumn(
      //       text: 'Subtotal:',
      //       width: 8,
      //       styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      //     ),
      //     esc_pos.PosColumn(
      //       text: AppFormatters.formatCurrency(invoice.subtotal),
      //       width: 4,
      //       styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right),
      //     ),
      //   ]);
      // }

      // // ✅ IVA SI APLICA
      // if (invoice.taxAmount > 0) {
      //   printer.row([
      //     esc_pos.PosColumn(
      //       text: 'IVA (${invoice.taxPercentage.toInt()}%):',
      //       width: 8,
      //       styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      //     ),
      //     esc_pos.PosColumn(
      //       text: AppFormatters.formatCurrency(invoice.taxAmount),
      //       width: 4,
      //       styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right),
      //     ),
      //   ]);
      // }

      // ✅ DESCUENTOS SI APLICAN
      if (invoice.discountAmount > 0) {
        printer.row([
          esc_pos.PosColumn(
            text: 'Descuento:',
            width: 8,
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
          ),
          esc_pos.PosColumn(
            text: '-${AppFormatters.formatCurrency(invoice.discountAmount)}',
            width: 4,
            styles: const esc_pos.PosStyles(
              align: esc_pos.PosAlign.right,
              bold: true,
            ),
          ),
        ]);
      }

      printer.hr(ch: '=', len: 32);

      // ✅ TOTAL FINAL CON FORMATO PROFESIONAL
      printer.row([
        esc_pos.PosColumn(
          text: 'TOTAL A PAGAR:',
          width: 5,
          styles: const esc_pos.PosStyles(
            align: esc_pos.PosAlign.left,
            bold: true,
            width: esc_pos.PosTextSize.size1,
            height: esc_pos.PosTextSize.size3,
          ),
        ),
        esc_pos.PosColumn(
          text: AppFormatters.formatCurrency(invoice.total),
          width: 7,
          styles: const esc_pos.PosStyles(
            align: esc_pos.PosAlign.right,
            bold: true,
            width: esc_pos.PosTextSize.size1,
            height: esc_pos.PosTextSize.size3,
          ),
        ),
      ]);

      printer.hr(ch: '=', len: 32);

      // ✅ INFORMACIÓN DE PAGO EN EFECTIVO
      await _printCashPaymentDetails(printer, invoice);

      printer.feed(1);
    } catch (e) {
      print('❌ Error imprimiendo totales: $e');
      throw e;
    }
  }

  // ==================== INFORMACIÓN DE PAGO EN EFECTIVO ====================

  /// Verifica si la factura tiene información de pago en efectivo
  bool _hasCashPaymentDetails(Invoice invoice) {
    if (invoice.paymentMethod != PaymentMethod.cash) return false;
    if (invoice.notes == null || invoice.notes!.isEmpty) return false;

    return invoice.notes!.contains('Recibido:') &&
        invoice.notes!.contains('Cambio:');
  }

  /// Extrae el monto recibido de las notas de la factura
  double _getReceivedAmount(Invoice invoice) {
    if (!_hasCashPaymentDetails(invoice)) return 0.0;

    try {
      final notes = invoice.notes!;
      final recibidoMatch = RegExp(
        r'Recibido:\s*\$?\s*([\d.,]+)',
      ).firstMatch(notes);

      if (recibidoMatch != null) {
        String amountStr = recibidoMatch.group(1)!;
        // Limpiar formato de miles colombiano (puntos) pero preservar decimales (comas)
        amountStr = amountStr.replaceAll(
          RegExp(r'\.(?=\d{3})'),
          '',
        ); // Remover puntos de miles
        amountStr = amountStr.replaceAll(
          ',',
          '.',
        ); // Convertir comas decimales a puntos
        return double.tryParse(amountStr) ?? 0.0;
      }
    } catch (e) {
      // Silencioso en producción
    }

    return 0.0;
  }

  /// Extrae el monto del cambio de las notas de la factura
  double _getChangeAmount(Invoice invoice) {
    if (!_hasCashPaymentDetails(invoice)) return 0.0;

    try {
      final notes = invoice.notes!;
      final cambioMatch = RegExp(
        r'Cambio:\s*\$?\s*([\d.,]+)',
      ).firstMatch(notes);

      if (cambioMatch != null) {
        String amountStr = cambioMatch.group(1)!;
        // Limpiar formato de miles colombiano (puntos) pero preservar decimales (comas)
        amountStr = amountStr.replaceAll(
          RegExp(r'\.(?=\d{3})'),
          '',
        ); // Remover puntos de miles
        amountStr = amountStr.replaceAll(
          ',',
          '.',
        ); // Convertir comas decimales a puntos
        return double.tryParse(amountStr) ?? 0.0;
      }
    } catch (e) {
      // Silencioso en producción
    }

    return 0.0;
  }

  /// Imprime información de pago en efectivo con formato profesional
  Future<void> _printCashPaymentDetails(
    NetworkPrinter printer,
    Invoice invoice,
  ) async {
    if (!_hasCashPaymentDetails(invoice)) return;

    try {
      final receivedAmount = _getReceivedAmount(invoice);
      final changeAmount = _getChangeAmount(invoice);

      // Solo imprimir si tenemos información válida
      if (receivedAmount > 0) {
        printer.text(
          'DETALLE DE PAGO EN EFECTIVO',
          styles: const esc_pos.PosStyles(
            align: esc_pos.PosAlign.center,
            bold: true,
            underline: true,
          ),
        );
        printer.feed(1);

        // Dinero recibido
        printer.row([
          esc_pos.PosColumn(
            text: 'Dinero Recibido:',
            width: 8,
            styles: const esc_pos.PosStyles(
              align: esc_pos.PosAlign.left,
              bold: true,
            ),
          ),
          esc_pos.PosColumn(
            text: AppFormatters.formatCurrency(receivedAmount),
            width: 4,
            styles: const esc_pos.PosStyles(
              align: esc_pos.PosAlign.right,
              bold: true,
            ),
          ),
        ]);

        // Cambio (solo si es mayor a 0)
        if (changeAmount > 0) {
          printer.row([
            esc_pos.PosColumn(
              text: 'Cambio:',
              width: 8,
              styles: const esc_pos.PosStyles(
                align: esc_pos.PosAlign.left,
                bold: true,
              ),
            ),
            esc_pos.PosColumn(
              text: AppFormatters.formatCurrency(changeAmount),
              width: 4,
              styles: const esc_pos.PosStyles(
                align: esc_pos.PosAlign.right,
                bold: true,
              ),
            ),
          ]);
        } else if (changeAmount == 0) {
          printer.text(
            'Pago exacto - Sin cambio',
            styles: const esc_pos.PosStyles(
              align: esc_pos.PosAlign.center,
              fontType: esc_pos.PosFontType.fontB,
            ),
          );
        }

        printer.feed(1);
      }
    } catch (e) {
      print('❌ Error imprimiendo información de pago en efectivo: $e');
    }
  }

  Future<void> _printFooter(NetworkPrinter printer, Invoice invoice) async {
    try {
      // Información adicional si hay
      // if (invoice.notes?.isNotEmpty == true) {
      //   printer.text(
      //     invoice.notes!,
      //     styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left, bold: true),
      //   );
      //   printer.feed(1);
      // }

      // Fecha y hora de impresión
      final now = DateTime.now();
      final timeStr =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      printer.text(
        'Impreso: $timeStr',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          fontType: esc_pos.PosFontType.fontB,
        ),
      );
      // Mensaje de agradecimiento
      printer.text(
        '¡Gracias por su compra!',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          bold: true,
        ),
      );
      printer.feed(1);
      printer.text(
        'Desarrollado, Impreso y Generado por Baudex',
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.text(
        'Baudex es una marca registrada de Baudity',
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.text(
        'Informacion: 3138448436',
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
    } catch (e) {
      print('❌ Error imprimiendo footer: $e');
      throw e;
    }
  }

  // ⚡ NUEVO: Versión para impresión fluida sin delays
  Future<bool> printInvoiceFast(Invoice invoice) async {
    if (_isPrinting.value) {
      _showError(
        'Impresión en curso',
        'Ya hay una impresión en curso, espere a que termine',
      );
      return false;
    }

    try {
      _isPrinting.value = true;
      _lastError.value = null;

      print('⚡ === IMPRESIÓN RÁPIDA INICIADA ===');
      print('   - Factura: ${invoice.number}');
      print('   - Plataforma: ${_getPlatformName()}');

      bool success = false;

      // Forzar impresión por red para fluidez
      success = await _printViaNetworkFast(invoice);

      if (success) {
        _addToPrintHistory(invoice, true);
        //_showSuccess('Factura impresa exitosamente');
        print('✅ Impresión rápida completada');
      } else {
        _addToPrintHistory(invoice, false, _lastError.value);
        _showError(
          'Error al imprimir',
          _lastError.value ?? "Error desconocido",
        );
        print('❌ Impresión rápida falló');
      }

      return success;
    } catch (e) {
      print('💥 Error en impresión rápida: $e');
      _lastError.value = e.toString();
      _addToPrintHistory(invoice, false, e.toString());
      _showError('Error inesperado', e.toString());
      return false;
    } finally {
      _isPrinting.value = false;
    }
  }

  // ⚡ Versión optimizada sin delays
  Future<bool> _printViaNetworkFast(Invoice invoice) async {
    try {
      print('⚡ Impresión rápida por red...');

      if (_networkPrinters.isEmpty) {
        await _discoverNetworkPrinters();
      }

      if (_networkPrinters.isEmpty) {
        _lastError.value = 'No se encontraron impresoras en red';
        return false;
      }

      final printerInfo = _networkPrinters.first;
      return await _sendToPrinterFast(printerInfo, invoice);
    } catch (e) {
      print('❌ Error en impresión rápida: $e');
      _lastError.value = 'Red: $e';
      return false;
    }
  }

  // ⚡ Envío optimizado sin delays
  Future<bool> _sendToPrinterFast(
    NetworkPrinterInfo printerInfo,
    Invoice invoice,
  ) async {
    NetworkPrinter? printer;

    try {
      final profile = await esc_pos.CapabilityProfile.load();
      printer = NetworkPrinter(SATQ22UEConfig.paperSize, profile);

      print('⚡ Conectando rápido a ${printerInfo.ip}:${printerInfo.port}...');

      final result = await printer.connect(
        printerInfo.ip,
        port: printerInfo.port,
      );

      if (result != PosPrintResult.success) {
        _lastError.value = 'Error de conexión: ${result.msg}';
        return false;
      }

      _isConnected.value = true;
      print('✅ Conectado para impresión rápida');

      // ⚡ GENERACIÓN CONTINUA SIN PAUSA
      try {
        await _generatePrintContentFast(printer, invoice);

        // Solo cortar al final
        printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.cutCommands));

        print('⚡ Contenido enviado de forma continua');
        return true;
      } catch (contentError) {
        print('❌ Error en contenido rápido: $contentError');
        _lastError.value = 'Error en contenido: $contentError';
        return false;
      }
    } catch (e) {
      print('❌ Error en envío rápido: $e');
      _lastError.value = e.toString();
      return false;
    } finally {
      if (printer != null) {
        printer.disconnect();
        _isConnected.value = false;
        print('⚡ Desconectado rápido');
      }
    }
  }

  // ⚡ Generación continua sin delays
  Future<void> _generatePrintContentFast(
    NetworkPrinter printer,
    Invoice invoice,
  ) async {
    try {
      print('⚡ === GENERACIÓN CONTINUA ===');

      // Inicializar
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.initializeCommands));

      // Todo de una vez, sin pausa
      await _printBusinessHeaderTextOnly(printer); // Sin logo para velocidad
      await _printInvoiceInfo(printer, invoice);
      await _printCustomerInfo(printer, invoice);
      await _printItems(printer, invoice);
      await _printTotals(printer, invoice);
      await _printFooter(printer, invoice);

      printer.feed(3);

      print('⚡ Generación continua completada');
    } catch (e) {
      print('❌ Error en generación continua: $e');
      throw Exception('Error en generación continua: $e');
    }
  }

  void _addToPrintHistory(
    Invoice? invoice,
    bool success, [
    String? error,
    String? method,
  ]) {
    final job = PrintJob(
      invoiceNumber: invoice?.number ?? 'TEST-PAGE',
      timestamp: DateTime.now(),
      success: success,
      error: error,
      method: method ?? (_preferUSB.value ? 'USB' : 'Red'),
    );

    _printHistory.insert(0, job);

    // Mantener solo los últimos 50 trabajos
    if (_printHistory.length > 50) {
      _printHistory.removeRange(50, _printHistory.length);
    }

    update();
  }

  void clearPrintHistory() {
    _printHistory.clear();
    update();
  }

  // ==================== FUNCIONES DE PÁGINA DE PRUEBA ====================

  Future<bool> _printTestPageNetwork() async {
    try {
      print('🌐 Imprimiendo página de prueba por red...');

      if (_networkPrinters.isEmpty) {
        await _discoverNetworkPrinters();
      }

      if (_networkPrinters.isEmpty) {
        _lastError.value = 'No se encontraron impresoras en red';
        return false;
      }

      final printerInfo = _networkPrinters.first;
      return await _sendTestPageToPrinter(printerInfo);
    } catch (e) {
      print('❌ Error en impresión de página de prueba por red: $e');
      _lastError.value = 'Red: $e';
      return false;
    }
  }

  Future<bool> _printTestPageNetworkWithConfig(
    settings.PrinterSettings config,
  ) async {
    try {
      print('🌐 Imprimiendo página de prueba por red con configuración...');

      // Validar configuración
      if (config.ipAddress == null || config.ipAddress!.isEmpty) {
        _lastError.value = 'IP no configurada';
        print('❌ IP no configurada');
        return false;
      }

      if (config.port == null || config.port! <= 0) {
        _lastError.value = 'Puerto no configurado';
        print('❌ Puerto no configurado');
        return false;
      }

      final printerInfo = NetworkPrinterInfo(
        name: config.name,
        ip: config.ipAddress!,
        port: config.port!,
        isConnected: false,
      );

      return await _sendTestPageToPrinterWithConfig(printerInfo, config);
    } catch (e) {
      print(
        '❌ Error en impresión de página de prueba por red con configuración: $e',
      );
      _lastError.value = 'Red (configurada): $e';
      return false;
    }
  }

  Future<bool> _printTestPageUSB(settings.PrinterSettings config) async {
    try {
      print('🔌 Imprimiendo página de prueba USB...');
      print('   - Ruta USB: ${config.usbPath}');

      // Generar contenido de página de prueba
      final testPageContent = await _generateTestPageContentUSB(config);

      // Enviar a impresora USB según el sistema operativo
      bool success = false;

      if (Platform.isWindows) {
        success = await _printToUSBWindows(config.usbPath!, testPageContent);
      } else if (Platform.isLinux) {
        success = await _printToUSBLinux(config.usbPath!, testPageContent);
      } else if (Platform.isMacOS) {
        success = await _printToUSBMacOS(config.usbPath!, testPageContent);
      } else {
        print('⚠️ Sistema operativo no soportado para impresión USB');
        _lastError.value = 'Sistema operativo no soportado para impresión USB';
        return false;
      }

      if (success) {
        print('✅ Página de prueba USB enviada exitosamente');
      } else {
        print('❌ Error al enviar página de prueba USB');
      }

      return success;
    } catch (e) {
      print('❌ Error en impresión de página de prueba USB: $e');
      _lastError.value = 'USB: $e';
      return false;
    }
  }

  Future<bool> _sendTestPageToPrinter(NetworkPrinterInfo printerInfo) async {
    NetworkPrinter? printer;
    bool connectionEstablished = false;

    try {
      final profile = await esc_pos.CapabilityProfile.load();
      printer = NetworkPrinter(SATQ22UEConfig.paperSize, profile);

      print(
        '🔗 Conectando a ${printerInfo.ip}:${printerInfo.port} para página de prueba...',
      );
      print('📊 Detalles de conexión:');
      print('   - IP: ${printerInfo.ip}');
      print('   - Puerto: ${printerInfo.port}');
      print('   - Nombre: ${printerInfo.name}');
      print('   - Papel: ${SATQ22UEConfig.paperSize.toString()}');

      final result = await printer
          .connect(printerInfo.ip, port: printerInfo.port)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ Timeout en conexión a impresora (15 segundos)');
              return PosPrintResult.timeout;
            },
          );

      print('📡 Resultado de conexión: ${result.msg}');

      if (result != PosPrintResult.success) {
        String errorMsg = 'Error de conexión: ${result.msg}';

        // Mensajes de error más descriptivos
        if (result == PosPrintResult.timeout) {
          errorMsg =
              'Timeout de conexión: La impresora no responde en ${printerInfo.ip}:${printerInfo.port}';
        } else {
          errorMsg =
              'Error de conexión: No se puede alcanzar la impresora en ${printerInfo.ip}:${printerInfo.port} - ${result.msg}';
        }

        _lastError.value = errorMsg;
        print('❌ Falló la conexión: $errorMsg');
        return false;
      }

      connectionEstablished = true;
      print('✅ Conectado a impresora para página de prueba');

      // Generar página de prueba
      await _generateTestPageContent(printer);

      // Delay mínimo antes del corte
      await Future.delayed(const Duration(milliseconds: 100));

      // Enviar comandos de corte
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.cutCommands));

      print('📄 Página de prueba enviada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error enviando página de prueba: $e');
      _lastError.value = e.toString();
      return false;
    } finally {
      // Solo desconectar si la conexión se estableció exitosamente
      if (printer != null && connectionEstablished) {
        try {
          await Future.delayed(const Duration(milliseconds: 200));
          printer.disconnect();
          print('🔌 Desconectado de impresora');
        } catch (disconnectError) {
          print('⚠️ Error al desconectar impresora: $disconnectError');
        }
      }
    }
  }

  Future<bool> _sendTestPageToPrinterWithConfig(
    NetworkPrinterInfo printerInfo,
    settings.PrinterSettings config,
  ) async {
    NetworkPrinter? printer;
    bool connectionEstablished = false;

    try {
      final profile = await esc_pos.CapabilityProfile.load();

      // Usar el tamaño de papel configurado
      esc_pos.PaperSize paperSize = esc_pos.PaperSize.mm80;
      if (config.paperSize == settings.PaperSize.mm58) {
        paperSize = esc_pos.PaperSize.mm58;
      }

      printer = NetworkPrinter(paperSize, profile);

      print(
        '🔗 Conectando a ${printerInfo.ip}:${printerInfo.port} para página de prueba...',
      );
      print('📊 Detalles de conexión:');
      print('   - IP: ${printerInfo.ip}');
      print('   - Puerto: ${printerInfo.port}');
      print('   - Nombre: ${printerInfo.name}');
      print('   - Papel: ${paperSize.toString()}');

      final result = await printer
          .connect(printerInfo.ip, port: printerInfo.port)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⏰ Timeout en conexión a impresora (15 segundos)');
              return PosPrintResult.timeout;
            },
          );

      print('📡 Resultado de conexión: ${result.msg}');

      if (result != PosPrintResult.success) {
        String errorMsg = 'Error de conexión: ${result.msg}';

        // Mensajes de error más descriptivos
        if (result == PosPrintResult.timeout) {
          errorMsg =
              'Timeout de conexión: La impresora no responde en ${printerInfo.ip}:${printerInfo.port}';
        } else {
          errorMsg =
              'Error de conexión: No se puede alcanzar la impresora en ${printerInfo.ip}:${printerInfo.port} - ${result.msg}';
        }

        _lastError.value = errorMsg;
        print('❌ Falló la conexión: $errorMsg');
        return false;
      }

      connectionEstablished = true;
      print('✅ Conectado a impresora ${config.name} para página de prueba');

      // Generar página de prueba con configuración
      await _generateTestPageContentWithConfig(printer, config);

      // Delay mínimo antes del corte
      await Future.delayed(const Duration(milliseconds: 100));

      // Enviar comandos de corte si está habilitado
      if (config.autoCut) {
        printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.cutCommands));
      }

      print('📄 Página de prueba con configuración enviada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error enviando página de prueba con configuración: $e');
      _lastError.value = e.toString();
      return false;
    } finally {
      // Solo desconectar si la conexión se estableció exitosamente
      if (printer != null && connectionEstablished) {
        try {
          await Future.delayed(const Duration(milliseconds: 200));
          printer.disconnect();
          print('🔌 Desconectado de impresora');
        } catch (disconnectError) {
          print('⚠️ Error al desconectar impresora: $disconnectError');
        }
      }
    }
  }

  Future<void> _generateTestPageContent(NetworkPrinter printer) async {
    try {
      print('📝 Generando contenido de página de prueba...');

      // Inicializar impresora
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.initializeCommands));
      await Future.delayed(const Duration(milliseconds: 50));

      // Título centrado
      printer.text(
        'PÁGINA DE PRUEBA',
        styles: esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          bold: true,
          height: esc_pos.PosTextSize.size2,
          width: esc_pos.PosTextSize.size2,
        ),
      );
      printer.feed(2);

      // Información del sistema
      printer.text(
        'Sistema: Baudex Desktop',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.text(
        'Fecha: ${DateTime.now().toString().split(' ')[0]}',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.text(
        'Hora: ${DateTime.now().toString().split(' ')[1].split('.')[0]}',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.feed(2);

      // Línea separadora
      printer.text(
        '================================',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.feed(1);

      // Prueba de caracteres
      printer.text(
        'Prueba de caracteres:',
        styles: esc_pos.PosStyles(bold: true),
      );
      printer.text('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
      printer.text('abcdefghijklmnopqrstuvwxyz');
      printer.text('0123456789');
      printer.text('ñáéíóúü ¡!¿?');
      printer.feed(2);

      // Prueba de alineación
      printer.text(
        'Izquierda',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      );
      printer.text(
        'Centro',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.text(
        'Derecha',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.right),
      );
      printer.feed(2);

      // Mensaje final
      printer.text(
        'Impresión exitosa!',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center, bold: true),
      );
      printer.feed(3);

      print('✅ Contenido de página de prueba generado');
    } catch (e) {
      print('❌ Error generando contenido de página de prueba: $e');
      throw Exception('Error en generación de página de prueba: $e');
    }
  }

  Future<void> _generateTestPageContentWithConfig(
    NetworkPrinter printer,
    settings.PrinterSettings config,
  ) async {
    try {
      print('📝 Generando contenido de página de prueba con configuración...');

      // Inicializar impresora
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.initializeCommands));
      await Future.delayed(const Duration(milliseconds: 50));

      // Título centrado
      printer.text(
        'PÁGINA DE PRUEBA',
        styles: esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          bold: true,
          height: esc_pos.PosTextSize.size2,
          width: esc_pos.PosTextSize.size2,
        ),
      );
      printer.feed(2);

      // Información de la impresora
      printer.text(
        'Impresora: ${config.name}',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center, bold: true),
      );
      printer.text(
        'Tipo: ${config.connectionType.name.toUpperCase()}',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      if (config.connectionType == settings.PrinterConnectionType.network) {
        printer.text(
          'IP: ${config.ipAddress}',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        );
        printer.text(
          'Puerto: ${config.port}',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        );
      } else {
        printer.text(
          'USB: ${config.usbPath}',
          styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        );
      }
      printer.text(
        'Papel: ${config.paperSize}mm',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.text(
        'Auto-corte: ${config.autoCut ? "SÍ" : "NO"}',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.feed(2);

      // Información del sistema
      printer.text(
        'Sistema: Baudex Desktop',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.text(
        'Fecha: ${DateTime.now().toString().split(' ')[0]}',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.text(
        'Hora: ${DateTime.now().toString().split(' ')[1].split('.')[0]}',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.feed(2);

      // Línea separadora
      printer.text(
        '================================',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.feed(1);

      // Prueba de caracteres
      printer.text(
        'Prueba de caracteres:',
        styles: esc_pos.PosStyles(bold: true),
      );
      printer.text('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
      printer.text('abcdefghijklmnopqrstuvwxyz');
      printer.text('0123456789');
      printer.text('ñáéíóúü ¡!¿?');
      printer.feed(2);

      // Prueba de alineación
      printer.text(
        'Izquierda',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      );
      printer.text(
        'Centro',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center),
      );
      printer.text(
        'Derecha',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.right),
      );
      printer.feed(2);

      // Mensaje final
      printer.text(
        'Configuración exitosa!',
        styles: esc_pos.PosStyles(align: esc_pos.PosAlign.center, bold: true),
      );
      printer.feed(3);

      print('✅ Contenido de página de prueba con configuración generado');
    } catch (e) {
      print(
        '❌ Error generando contenido de página de prueba con configuración: $e',
      );
      throw Exception('Error en generación de página de prueba: $e');
    }
  }

  // ==================== UTILIDADES ====================

  Future<void> _closeAllConnections() async {
    try {
      _isConnected.value = false;
      _networkPrinters.clear();
      print('🔌 Todas las conexiones cerradas');
    } catch (e) {
      print('❌ Error cerrando conexiones: $e');
    }
  }

  void setPreferUSB(bool prefer) {
    _preferUSB.value = prefer;
    print('⚙️ Preferencia USB cambiada a: $prefer');
  }

  // ==================== MENSAJES ====================

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Impresión Exitosa',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
  }

  // ==================== DEBUG Y PRUEBAS ====================

  void debugPrintStatus() {
    print('🔍 === ESTADO IMPRESORA TÉRMICA ===');
    print('   - Conectado: $isConnected');
    print('   - Imprimiendo: $isPrinting');
    print('   - Preferir USB: $preferUSB');
    print('   - Impresoras red: ${networkPrinters.length}');
    print('   - Último error: $lastError');
    print('   - Historial: ${printHistory.length} trabajos');
  }

  // ⚠️ NUEVO: Método para probar impresión paso a paso
  Future<void> testPrintSteps(Invoice invoice) async {
    print('🧪 === PRUEBA PASO A PASO ===');

    try {
      // Paso 1: Verificar conexión
      print('🔍 Paso 1: Verificando impresoras...');
      await _discoverNetworkPrinters();

      if (_networkPrinters.isEmpty) {
        print('❌ No hay impresoras disponibles');
        return;
      }

      // Paso 2: Conectar
      print('🔗 Paso 2: Conectando...');
      final profile = await esc_pos.CapabilityProfile.load();
      final printer = NetworkPrinter(SATQ22UEConfig.paperSize, profile);
      final printerInfo = _networkPrinters.first;

      final result = await printer.connect(
        printerInfo.ip,
        port: printerInfo.port,
      );

      if (result != PosPrintResult.success) {
        print('❌ Error de conexión: ${result.msg}');
        return;
      }

      print('✅ Conectado exitosamente');

      // Paso 3: Probar cada sección individualmente
      print('🧪 Paso 3: Probando header...');
      await _printBusinessHeaderTextOnly(printer);
      await Future.delayed(const Duration(seconds: 2));

      print('🧪 Paso 4: Probando info factura...');
      await _printInvoiceInfo(printer, invoice);
      await Future.delayed(const Duration(seconds: 2));

      print('🧪 Paso 5: Probando info cliente...');
      await _printCustomerInfo(printer, invoice);
      await Future.delayed(const Duration(seconds: 2));

      print('🧪 Paso 6: Probando items...');
      await _printItems(printer, invoice);
      await Future.delayed(const Duration(seconds: 2));

      print('🧪 Paso 7: Probando totales...');
      await _printTotals(printer, invoice);
      await Future.delayed(const Duration(seconds: 2));

      print('🧪 Paso 8: Probando footer...');
      await _printFooter(printer, invoice);

      // Paso 4: Cortar y desconectar
      printer.feed(3);
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.cutCommands));

      await Future.delayed(const Duration(milliseconds: 500));
      printer.disconnect();

      print('✅ Prueba completada exitosamente');
    } catch (e) {
      print('❌ Error en prueba: $e');
    }
  }

  // ⚠️ NUEVO: Método simple para debug sin logo
  Future<bool> printInvoiceDebug(Invoice invoice) async {
    if (_isPrinting.value) {
      print('⚠️ Ya hay una impresión en curso');
      return false;
    }

    try {
      _isPrinting.value = true;
      _lastError.value = null;

      print('🐛 === MODO DEBUG SIN LOGO ===');

      // Solo impresión por red
      if (_networkPrinters.isEmpty) {
        await _discoverNetworkPrinters();
      }

      if (_networkPrinters.isEmpty) {
        _lastError.value = 'No se encontraron impresoras en red';
        return false;
      }

      final printerInfo = _networkPrinters.first;
      final profile = await esc_pos.CapabilityProfile.load();
      final printer = NetworkPrinter(SATQ22UEConfig.paperSize, profile);

      print('🔗 Conectando en modo debug...');
      final result = await printer.connect(
        printerInfo.ip,
        port: printerInfo.port,
      );

      if (result != PosPrintResult.success) {
        _lastError.value = 'Error de conexión: ${result.msg}';
        return false;
      }

      // Inicializar
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.initializeCommands));

      // Solo texto, sin logo
      await _printBusinessHeaderTextOnly(printer);
      await _printInvoiceInfo(printer, invoice);
      await _printCustomerInfo(printer, invoice);
      await _printItems(printer, invoice);
      await _printTotals(printer, invoice);
      await _printFooter(printer, invoice);

      printer.feed(3);
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.cutCommands));

      await Future.delayed(const Duration(milliseconds: 500));
      printer.disconnect();

      print('✅ Impresión debug completada');
      return true;
    } catch (e) {
      print('❌ Error en impresión debug: $e');
      _lastError.value = e.toString();
      return false;
    } finally {
      _isPrinting.value = false;
    }
  }

  // ==================== MÉTODOS PARA SETTINGS SCREEN ====================

  void setPaperWidth(int width) {
    if (width == 58 || width == 80) {
      _paperWidth.value = width;
      print('📏 Ancho de papel configurado a: ${width}mm');
      update(); // Notificar cambios a GetBuilder
    }
  }

  void setAutoCut(bool enabled) {
    _autoCut.value = enabled;
    print('✂️ Corte automático: ${enabled ? 'activado' : 'desactivado'}');
    update();
  }

  void setOpenCashDrawer(bool enabled) {
    _openCashDrawer.value = enabled;
    print(
      '💰 Abrir caja registradora: ${enabled ? 'activado' : 'desactivado'}',
    );
    update();
  }

  void addManualPrinter(String name, String ip, int port) {
    try {
      final newPrinter = NetworkPrinterInfo(
        name: name,
        ip: ip,
        port: port,
        isConnected: false,
      );

      // Verificar si ya existe esta IP
      final existingIndex = _networkPrinters.indexWhere(
        (p) => p.ip == ip && p.port == port,
      );

      if (existingIndex != -1) {
        // Actualizar impresora existente
        _networkPrinters[existingIndex] = newPrinter;
        print('🔄 Impresora actualizada: $name ($ip:$port)');
      } else {
        // Agregar nueva impresora
        _networkPrinters.add(newPrinter);
        print('➕ Impresora agregada manualmente: $name ($ip:$port)');
      }

      update();

      // Probar conexión automáticamente
      _testAndUpdatePrinterStatus(newPrinter);
    } catch (e) {
      print('❌ Error agregando impresora manual: $e');
      _showError('Error', 'No se pudo agregar la impresora: $e');
    }
  }

  void selectPrinter(NetworkPrinterInfo printer) {
    _selectedPrinter.value = printer;
    print(
      '🖨️ Impresora seleccionada: ${printer.name} (${printer.ip}:${printer.port})',
    );
    update();

    // Intentar conectar automáticamente
    connectToPrinter(printer);
  }

  Future<void> connectToPrinter(NetworkPrinterInfo printerInfo) async {
    try {
      print('🔗 Intentando conectar a ${printerInfo.name}...');

      final profile = await esc_pos.CapabilityProfile.load();
      final printer = NetworkPrinter(SATQ22UEConfig.paperSize, profile);

      final result = await printer
          .connect(printerInfo.ip, port: printerInfo.port)
          .timeout(const Duration(seconds: 5));

      if (result == PosPrintResult.success) {
        _isConnected.value = true;

        // Actualizar estado de la impresora
        final updatedPrinter = printerInfo.copyWith(isConnected: true);
        final index = _networkPrinters.indexWhere(
          (p) => p.ip == printerInfo.ip && p.port == printerInfo.port,
        );
        if (index != -1) {
          _networkPrinters[index] = updatedPrinter;
        }

        _selectedPrinter.value = updatedPrinter;

        print('✅ Conectado exitosamente a ${printerInfo.name}');
        _showSuccess('Conectado a ${printerInfo.name}');

        // Desconectar inmediatamente (solo para prueba)
        try {
          printer.disconnect();
        } catch (e) {
          print('⚠️ Error al desconectar después de prueba: $e');
        }
      } else {
        _isConnected.value = false;
        print('❌ Error conectando: ${result.msg}');
        _showError('Error de conexión', result.msg);
      }
    } catch (e) {
      _isConnected.value = false;
      print('❌ Error en conexión: $e');
      _showError('Error', 'No se pudo conectar: $e');
    }

    update();
  }

  Future<void> printTestReceipt() async {
    if (_selectedPrinter.value == null) {
      _showError('Error', 'Selecciona una impresora primero');
      return;
    }

    if (_isPrinting.value) {
      _showError('Impresión en curso', 'Ya hay una impresión en curso');
      return;
    }

    try {
      _isPrinting.value = true;
      print('🧪 Imprimiendo recibo de prueba...');

      final profile = await esc_pos.CapabilityProfile.load();
      final printer = NetworkPrinter(SATQ22UEConfig.paperSize, profile);

      final result = await printer.connect(
        _selectedPrinter.value!.ip,
        port: _selectedPrinter.value!.port,
      );

      if (result != PosPrintResult.success) {
        throw Exception('Error de conexión: ${result.msg}');
      }

      // Inicializar
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.initializeCommands));

      // Imprimir recibo de prueba
      printer.text(
        'RECIBO DE PRUEBA',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          bold: true,
          height: esc_pos.PosTextSize.size2,
        ),
      );

      printer.hr();

      printer.text(
        'Impresora: ${_selectedPrinter.value!.name}',
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      );

      printer.text(
        'IP: ${_selectedPrinter.value!.ip}:${_selectedPrinter.value!.port}',
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      );

      printer.text(
        'Papel: ${_paperWidth.value}mm',
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      );

      printer.text(
        'Corte automático: ${_autoCut.value ? "SÍ" : "NO"}',
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      );

      printer.text(
        'Caja registradora: ${_openCashDrawer.value ? "SÍ" : "NO"}',
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      );

      printer.hr();

      final now = DateTime.now();
      printer.text(
        'Fecha: ${now.day}/${now.month}/${now.year}',
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      );

      printer.text(
        'Hora: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      );

      printer.feed(2);

      printer.text(
        '*** PRUEBA EXITOSA ***',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          bold: true,
        ),
      );

      printer.feed(3);

      // Cortar papel si está habilitado
      if (_autoCut.value) {
        printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.cutCommands));
      }

      // Abrir caja registradora si está habilitado
      if (_openCashDrawer.value) {
        printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.openDrawerCommands));
      }

      await Future.delayed(const Duration(milliseconds: 500));

      try {
        printer.disconnect();
      } catch (e) {
        print('⚠️ Error al desconectar después de prueba: $e');
      }

      _showSuccess('Recibo de prueba impreso exitosamente');
      print('✅ Recibo de prueba completado');
    } catch (e) {
      print('❌ Error imprimiendo recibo de prueba: $e');
      _showError('Error', 'No se pudo imprimir el recibo de prueba: $e');
    } finally {
      _isPrinting.value = false;
      update();
    }
  }

  // ==================== MÉTODOS HELPER PRIVADOS ====================

  Future<void> _testAndUpdatePrinterStatus(
    NetworkPrinterInfo printerInfo,
  ) async {
    try {
      final isAvailable = await _testNetworkPrinter(
        printerInfo.ip,
        printerInfo.port,
      );

      final index = _networkPrinters.indexWhere(
        (p) => p.ip == printerInfo.ip && p.port == printerInfo.port,
      );

      if (index != -1) {
        _networkPrinters[index] = printerInfo.copyWith(
          isConnected: isAvailable,
        );
        update();
      }
    } catch (e) {
      print('⚠️ Error probando estado de impresora: $e');
    }
  }
}

// ==================== CIERRE DE CLASE ====================
