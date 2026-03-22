// File: lib/features/invoices/presentation/controllers/thermal_printer_controller.dart
import 'package:image/image.dart' as img;

// lib/features/invoices/presentation/controllers/thermal_printer_controller.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/invoice.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/controllers/organization_controller.dart';
import '../../../settings/domain/entities/organization.dart';
import '../../../settings/domain/entities/printer_settings.dart' as settings;
import '../../../settings/data/models/isar/isar_organization.dart';

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

  // Cache de datos de organización para impresión rápida
  Organization? _cachedOrganization;

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
    _loadOrganizationData();
    _initializeSettingsController();
    _initializePrinter();
  }

  /// Carga datos de organización desde ISAR (rápido) o OrganizationController
  Future<void> _loadOrganizationData() async {
    try {
      // 1. Intentar desde OrganizationController (ya cargado)
      if (Get.isRegistered<OrganizationController>()) {
        final orgCtrl = Get.find<OrganizationController>();
        if (orgCtrl.currentOrganization != null) {
          _cachedOrganization = orgCtrl.currentOrganization;
          return;
        }
      }

      // 2. Fallback: leer directo de ISAR (instantáneo, sin red)
      final isar = IsarDatabase.instance.database;
      final isarOrg =
          await isar.isarOrganizations.filter().deletedAtIsNull().findFirst();
      if (isarOrg != null) {
        _cachedOrganization = isarOrg.toEntity();
      }
    } catch (e) {
      // Silencioso - usará fallbacks en los métodos de impresión
    }
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

    // También asegurar datos de organización
    if (_cachedOrganization == null) {
      await _loadOrganizationData();
    }

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

      _networkPrinters.clear();

      // Construir lista de IPs a escanear
      final ipsToScan = <String>{SATQ22UEConfig.defaultNetworkIP};

      // Intentar detectar subnet local y agregar IPs comunes
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
              // IPs comunes donde suelen estar las impresoras térmicas
              for (final lastOctet in [1, 100, 101, 150, 181, 200, 250]) {
                ipsToScan.add('$subnet.$lastOctet');
              }
            }
          }
        }
      } catch (e) {
        print('⚠️ No se pudo detectar subnet local: $e');
      }

      print('🔍 Escaneando ${ipsToScan.length} IPs...');

      // Escanear en paralelo con timeout corto
      final futures = ipsToScan.map((ip) async {
        try {
          final socket = await Socket.connect(
            ip,
            SATQ22UEConfig.defaultNetworkPort,
            timeout: const Duration(seconds: 2),
          );
          await socket.close();
          return ip;
        } catch (_) {
          return null;
        }
      });

      final results = await Future.wait(futures);
      final foundIps = results.whereType<String>().toList();

      for (final ip in foundIps) {
        _networkPrinters.add(NetworkPrinterInfo(
          name: ip == SATQ22UEConfig.defaultNetworkIP
              ? 'SAT Q22UE'
              : 'Impresora ($ip)',
          ip: ip,
          port: SATQ22UEConfig.defaultNetworkPort,
          isConnected: true,
        ));
        print('✅ Impresora encontrada en $ip');
      }

      if (_networkPrinters.isEmpty) {
        print('⚠️ No se encontraron impresoras en red');
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

      // Asegurar datos de organización cargados
      if (_cachedOrganization == null) await _loadOrganizationData();

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
        if (printerConfig.connectionType ==
            settings.PrinterConnectionType.usb) {
          print('🔌 Impresión USB configurada');
          success = await _printViaUSB(invoice);
        } else {
          print('🌐 Impresión por red configurada');
          success = await _printViaNetworkWithConfig(invoice, printerConfig);
        }
      } else {
        // Sin configuración de impresora
        print('❌ No hay impresora configurada');
        _lastError.value =
            'No hay impresora configurada. Ve a Configuración > Impresoras para agregar una.';
        success = false;
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

      final config = _currentPrinterConfig.value;
      final usbPath = config?.usbPath;
      if (usbPath == null || usbPath.isEmpty) {
        _lastError.value = 'No hay ruta USB configurada';
        return false;
      }

      // Generar bytes ESC/POS de la factura
      final bytes = await _generateInvoiceEscPosBytes(invoice);

      // Enviar bytes a la impresora USB según plataforma
      if (Platform.isWindows) {
        return await _printToUSBWindows(usbPath, bytes);
      } else if (Platform.isLinux) {
        return await _printToUSBLinux(usbPath, bytes);
      } else if (Platform.isMacOS) {
        return await _printToUSBMacOS(usbPath, bytes);
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

  /// Genera bytes de raster ESC/POS para una imagen (logo)
  List<int> _generateImageRasterBytes(img.Image image) {
    final int widthPx = image.width;
    final int heightPx = image.height;
    final int widthBytes = (widthPx + 7) ~/ 8;

    final List<int> rasterData = [];
    for (int y = 0; y < heightPx; y++) {
      for (int xByte = 0; xByte < widthBytes; xByte++) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          final int x = xByte * 8 + bit;
          if (x < widthPx) {
            final pixel = image.getPixel(x, y);
            final num maxVal = pixel.maxChannelValue;
            final double a = pixel.a / maxVal;
            if (a < 0.01) continue;
            final double r = (pixel.r / maxVal) * a + (1.0 - a);
            final double g = (pixel.g / maxVal) * a + (1.0 - a);
            final double b = (pixel.b / maxVal) * a + (1.0 - a);
            final double luminance = 0.299 * r + 0.587 * g + 0.114 * b;
            if (luminance < 0.5) {
              byte |= (0x80 >> bit);
            }
          }
        }
        rasterData.add(byte);
      }
    }

    final List<int> result = [];
    // Centrar imagen: ESC a 1
    result.addAll([0x1B, 0x61, 0x01]);
    // Comando GS v 0 (raster bit image)
    result.addAll([
      0x1D, 0x76, 0x30, 0x00,
      widthBytes & 0xFF, (widthBytes >> 8) & 0xFF,
      heightPx & 0xFF, (heightPx >> 8) & 0xFF,
    ]);
    result.addAll(rasterData);
    // Restaurar alineación izquierda: ESC a 0
    result.addAll([0x1B, 0x61, 0x00]);
    return result;
  }

  /// Genera bytes ESC/POS completos para una factura (usado para impresión USB)
  Future<Uint8List> _generateInvoiceEscPosBytes(Invoice invoice) async {
    final config = _currentPrinterConfig.value;
    final profile = await esc_pos.CapabilityProfile.load();

    esc_pos.PaperSize paperSize = esc_pos.PaperSize.mm80;
    if (config?.paperSize == settings.PaperSize.mm58) {
      paperSize = esc_pos.PaperSize.mm58;
    }

    final gen = esc_pos.Generator(paperSize, profile);
    List<int> bytes = [];

    // Inicialización
    bytes.addAll(SATQ22UEConfig.initializeCommands);

    // === HEADER CON LOGO ===
    final org = _cachedOrganization;
    final businessName = org?.businessName ?? 'Mi Negocio';

    // Intentar imprimir logo
    bool logoImpreso = false;
    try {
      final hasLogo = await _hasLogoAvailable();
      if (hasLogo) {
        final logo = await _loadLogoImage();
        if (logo != null) {
          bytes.addAll(_generateImageRasterBytes(logo));
          bytes.addAll(gen.feed(1));
          logoImpreso = true;
        }
      }
    } catch (e) {
      print('⚠️ Logo no disponible para USB: $e');
    }

    // Si no hay logo, imprimir nombre de empresa grande
    if (!logoImpreso) {
      bytes.addAll(gen.text(
        businessName,
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          bold: true,
          height: esc_pos.PosTextSize.size2,
          width: esc_pos.PosTextSize.size2,
        ),
      ));
    }

    if (org != null) {
      if (org.address.isNotEmpty) {
        bytes.addAll(gen.text(org.address,
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center)));
      }
      if (org.phone.isNotEmpty) {
        bytes.addAll(gen.text('Tel: ${org.phone}',
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center)));
      }
      if (org.taxId.isNotEmpty) {
        bytes.addAll(gen.text('NIT: ${org.taxId}',
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center)));
      }
      if (org.email.isNotEmpty) {
        bytes.addAll(gen.text(org.email,
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center)));
      }
    }
    bytes.addAll(gen.feed(1));

    // === INFO FACTURA ===
    bytes.addAll(gen.text(
      'FACTURA DE VENTA',
      styles: const esc_pos.PosStyles(
        align: esc_pos.PosAlign.center,
        bold: true,
      ),
    ));
    bytes.addAll(gen.feed(1));

    bytes.addAll(gen.row([
      esc_pos.PosColumn(text: 'No:', width: 4,
          styles: const esc_pos.PosStyles(bold: true)),
      esc_pos.PosColumn(text: invoice.number, width: 8,
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right)),
    ]));

    // Fecha de la factura (fecha de emisión, NO hora de impresión)
    final invoiceDate = invoice.date;
    final dateStr =
        '${invoiceDate.day.toString().padLeft(2, '0')}/${invoiceDate.month.toString().padLeft(2, '0')}/${invoiceDate.year} ${invoiceDate.hour.toString().padLeft(2, '0')}:${invoiceDate.minute.toString().padLeft(2, '0')}:${invoiceDate.second.toString().padLeft(2, '0')}';
    bytes.addAll(gen.row([
      esc_pos.PosColumn(text: 'Fecha:', width: 4,
          styles: const esc_pos.PosStyles(bold: true)),
      esc_pos.PosColumn(text: dateStr, width: 8,
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right)),
    ]));

    bytes.addAll(gen.row([
      esc_pos.PosColumn(text: 'Pago:', width: 4,
          styles: const esc_pos.PosStyles(bold: true)),
      esc_pos.PosColumn(text: invoice.paymentMethodDisplayName, width: 8,
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right)),
    ]));

    bytes.addAll(gen.hr());

    // === CLIENTE ===
    bytes.addAll(gen.text('CLIENTE:',
        styles: const esc_pos.PosStyles(bold: true)));
    bytes.addAll(gen.text(invoice.customerName));
    bytes.addAll(gen.hr());

    // === ITEMS ===
    bytes.addAll(gen.text(
      'ITEM      CANT.       V.UNIT                              TOTAL',
      styles: esc_pos.PosStyles(
        align: esc_pos.PosAlign.left,
        bold: true,
        fontType: esc_pos.PosFontType.fontB,
      ),
    ));
    bytes.addAll(gen.hr(ch: '-', linesAfter: 0));

    int itemNumber = 1;
    for (final item in invoice.items) {
      bytes.addAll(gen.text(
        '${itemNumber.toString().padLeft(2, '0')} - ${item.description.toUpperCase()}',
        styles: const esc_pos.PosStyles(bold: true, align: esc_pos.PosAlign.left),
      ));

      final quantity = item.quantity.toInt().toString();
      final total = item.quantity * item.unitPrice;

      bytes.addAll(gen.row([
        esc_pos.PosColumn(text: '', width: 2,
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center)),
        esc_pos.PosColumn(text: quantity, width: 2,
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left)),
        esc_pos.PosColumn(
            text: AppFormatters.formatCurrency(item.unitPrice), width: 4,
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left)),
        esc_pos.PosColumn(
            text: AppFormatters.formatCurrency(total), width: 4,
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right, bold: true)),
      ]));

      if (item.notes != null && item.notes!.isNotEmpty) {
        bytes.addAll(gen.text(item.notes!,
            styles: const esc_pos.PosStyles(
              fontType: esc_pos.PosFontType.fontB,
              align: esc_pos.PosAlign.left,
            )));
      } else if (item.description.toLowerCase().contains('impresora') ||
          item.description.toLowerCase().contains('equipo') ||
          item.description.toLowerCase().contains('dispositivo')) {
        bytes.addAll(gen.text('GARANTIA DE 3 MESES POR DEFECTOS DE FABRICA',
            styles: const esc_pos.PosStyles(
              fontType: esc_pos.PosFontType.fontB,
              align: esc_pos.PosAlign.left,
            )));
      }

      itemNumber++;
    }

    bytes.addAll(gen.hr(ch: '-', linesAfter: 0));
    bytes.addAll(gen.text('TOTAL ITEMS: ${invoice.items.length}',
        styles: const esc_pos.PosStyles(bold: true, align: esc_pos.PosAlign.left)));
    bytes.addAll(gen.feed(1));

    // === TOTALES ===
    if (invoice.discountAmount > 0) {
      bytes.addAll(gen.row([
        esc_pos.PosColumn(text: 'Descuento:', width: 8,
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left)),
        esc_pos.PosColumn(
            text: '-${AppFormatters.formatCurrency(invoice.discountAmount)}',
            width: 4,
            styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right, bold: true)),
      ]));
    }

    bytes.addAll(gen.hr(ch: '='));

    bytes.addAll(gen.row([
      esc_pos.PosColumn(text: 'TOTAL A PAGAR:', width: 5,
          styles: const esc_pos.PosStyles(
            align: esc_pos.PosAlign.left, bold: true,
            width: esc_pos.PosTextSize.size1, height: esc_pos.PosTextSize.size3,
          )),
      esc_pos.PosColumn(
          text: AppFormatters.formatCurrency(invoice.total), width: 7,
          styles: const esc_pos.PosStyles(
            align: esc_pos.PosAlign.right, bold: true,
            width: esc_pos.PosTextSize.size1, height: esc_pos.PosTextSize.size3,
          )),
    ]));

    bytes.addAll(gen.hr(ch: '='));

    // === PAGO EN EFECTIVO ===
    if (_hasCashPaymentDetails(invoice)) {
      final receivedAmount = _getReceivedAmount(invoice);
      final changeAmount = _getChangeAmount(invoice);

      if (receivedAmount > 0) {
        bytes.addAll(gen.text('DETALLE DE PAGO EN EFECTIVO',
            styles: const esc_pos.PosStyles(
              align: esc_pos.PosAlign.center, bold: true, underline: true,
            )));
        bytes.addAll(gen.feed(1));

        bytes.addAll(gen.row([
          esc_pos.PosColumn(text: 'Dinero Recibido:', width: 8,
              styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left, bold: true)),
          esc_pos.PosColumn(
              text: AppFormatters.formatCurrency(receivedAmount), width: 4,
              styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right, bold: true)),
        ]));

        if (changeAmount > 0) {
          bytes.addAll(gen.row([
            esc_pos.PosColumn(text: 'Cambio:', width: 8,
                styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left, bold: true)),
            esc_pos.PosColumn(
                text: AppFormatters.formatCurrency(changeAmount), width: 4,
                styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right, bold: true)),
          ]));
        } else if (changeAmount == 0) {
          bytes.addAll(gen.text('Pago exacto - Sin cambio',
              styles: const esc_pos.PosStyles(
                align: esc_pos.PosAlign.center,
                fontType: esc_pos.PosFontType.fontB,
              )));
        }
        bytes.addAll(gen.feed(1));
      }
    }

    // === FOOTER ===
    // Hora real de impresión (NO la fecha de la factura)
    final printTime = DateTime.now();
    final timeStr =
        '${printTime.day.toString().padLeft(2, '0')}/${printTime.month.toString().padLeft(2, '0')}/${printTime.year} ${printTime.hour.toString().padLeft(2, '0')}:${printTime.minute.toString().padLeft(2, '0')}:${printTime.second.toString().padLeft(2, '0')}';
    bytes.addAll(gen.text('Impreso: $timeStr',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          fontType: esc_pos.PosFontType.fontB,
        )));

    final footerMsg = org?.footerMessage ?? 'Gracias por su compra';
    bytes.addAll(gen.text(footerMsg,
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center, bold: true)));
    bytes.addAll(gen.feed(1));
    bytes.addAll(gen.text('Desarrollado, Impreso y Generado por Baudex',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          fontType: esc_pos.PosFontType.fontB,
        )));
    bytes.addAll(gen.text('Información: 3138448436',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          fontType: esc_pos.PosFontType.fontB,
        )));

    bytes.addAll(gen.feed(3));

    // Corte de papel si está habilitado
    if (config?.autoCut ?? true) {
      bytes.addAll(SATQ22UEConfig.cutCommands);
    }

    // Abrir caja registradora si está habilitado
    if (config?.cashDrawer ?? false) {
      bytes.addAll(SATQ22UEConfig.openDrawerCommands);
    }

    print('📝 Factura ESC/POS generada: ${bytes.length} bytes');
    return Uint8List.fromList(bytes);
  }

  // ==================== IMPRESIÓN USB PARA PÁGINAS DE PRUEBA ====================

  Future<Uint8List> _generateTestPageContentUSB(
    settings.PrinterSettings config,
  ) async {
    print(
      '📄 Generando contenido USB para página de prueba (formato ESC/POS)...',
    );

    try {
      final profile = await esc_pos.CapabilityProfile.load();

      esc_pos.PaperSize paperSize;
      if (config.paperSize == settings.PaperSize.mm58) {
        paperSize = esc_pos.PaperSize.mm58;
      } else {
        paperSize = esc_pos.PaperSize.mm80;
      }

      final generator = esc_pos.Generator(paperSize, profile);
      List<int> commands = [];

      // Inicialización
      commands.addAll(SATQ22UEConfig.initializeCommands);

      // Título — idéntico a la versión de red
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

      // Info de la impresora configurada — idéntico a la versión de red
      commands.addAll(
        generator.text(
          'Impresora: ${config.name}',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center, bold: true),
        ),
      );
      commands.addAll(
        generator.text(
          'Tipo: ${config.connectionType.name.toUpperCase()}',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      if (config.connectionType == settings.PrinterConnectionType.network) {
        commands.addAll(generator.text(
          'IP: ${config.ipAddress}',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ));
        commands.addAll(generator.text(
          'Puerto: ${config.port}',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ));
      } else {
        commands.addAll(generator.text(
          'USB: ${config.usbPath}',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ));
      }
      commands.addAll(
        generator.text(
          'Papel: ${config.paperSize == settings.PaperSize.mm58 ? "58mm" : "80mm"}',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(
        generator.text(
          'Auto-corte: ${config.autoCut ? "SÍ" : "NO"}',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(generator.feed(2));

      // Info del sistema
      commands.addAll(
        generator.text(
          'Sistema: Baudex Desktop',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(
        generator.text(
          'Fecha: ${DateTime.now().toString().split(' ')[0]}',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(
        generator.text(
          'Hora: ${DateTime.now().toString().split(' ')[1].split('.')[0]}',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(generator.feed(2));

      // Separador
      commands.addAll(
        generator.text(
          '================================',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(generator.feed(1));

      // Prueba de caracteres
      commands.addAll(
        generator.text(
          'Prueba de caracteres:',
          styles: const esc_pos.PosStyles(bold: true),
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
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
        ),
      );
      commands.addAll(
        generator.text(
          'Centro',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        ),
      );
      commands.addAll(
        generator.text(
          'Derecha',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.right),
        ),
      );
      commands.addAll(generator.feed(2));

      // Mensaje final
      commands.addAll(
        generator.text(
          'Configuración exitosa!',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center, bold: true),
        ),
      );
      commands.addAll(generator.feed(3));

      // Corte de papel
      if (config.autoCut) {
        commands.addAll(SATQ22UEConfig.cutCommands);
      }

      // Caja registradora
      if (config.cashDrawer) {
        commands.addAll(SATQ22UEConfig.openDrawerCommands);
      }

      final data = Uint8List.fromList(commands);
      print('✅ Contenido USB generado: ${data.length} bytes');
      return data;
    } catch (e) {
      print('❌ Error generando contenido USB: $e');
      return Uint8List.fromList(
        utf8.encode('Error generando contenido de prueba: $e'),
      );
    }
  }

  Future<bool> _printToUSBWindows(String usbPath, Uint8List data) async {
    try {
      print("🪟 Imprimiendo RAW a USB Windows: $usbPath");

      // Crear archivo temporal con los datos binarios RAW
      final tempFile =
          "${Directory.systemTemp.path}\\temp_print_${DateTime.now().millisecondsSinceEpoch}.bin";
      final file = File(tempFile);
      await file.writeAsBytes(data);
      print("📁 Archivo temporal creado: $tempFile (${data.length} bytes)");

      // Método 1: Enviar RAW vía PowerShell con .NET RawPrinterHelper
      // Esto envía bytes binarios directamente al spooler sin conversión de texto
      final psScript = '''
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class RawPrinterHelper {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public class DOCINFOA {
        [MarshalAs(UnmanagedType.LPStr)] public string pDocName;
        [MarshalAs(UnmanagedType.LPStr)] public string pOutputFile;
        [MarshalAs(UnmanagedType.LPStr)] public string pDataType;
    }
    [DllImport("winspool.Drv", EntryPoint = "OpenPrinterA", SetLastError = true, CharSet = CharSet.Ansi, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool OpenPrinter([MarshalAs(UnmanagedType.LPStr)] string szPrinter, out IntPtr hPrinter, IntPtr pd);
    [DllImport("winspool.Drv", EntryPoint = "ClosePrinter", SetLastError = true, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool ClosePrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint = "StartDocPrinterA", SetLastError = true, CharSet = CharSet.Ansi, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool StartDocPrinter(IntPtr hPrinter, Int32 level, [In, MarshalAs(UnmanagedType.LPStruct)] DOCINFOA di);
    [DllImport("winspool.Drv", EntryPoint = "EndDocPrinter", SetLastError = true, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool EndDocPrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint = "StartPagePrinter", SetLastError = true, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool StartPagePrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint = "EndPagePrinter", SetLastError = true, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool EndPagePrinter(IntPtr hPrinter);
    [DllImport("winspool.Drv", EntryPoint = "WritePrinter", SetLastError = true, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    public static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, Int32 dwCount, out Int32 dwWritten);

    public static bool SendBytesToPrinter(string szPrinterName, byte[] pBytes) {
        IntPtr hPrinter = new IntPtr(0);
        DOCINFOA di = new DOCINFOA();
        di.pDocName = "Baudex RAW Document";
        di.pDataType = "RAW";
        bool bSuccess = false;
        if (OpenPrinter(szPrinterName.Normalize(), out hPrinter, IntPtr.Zero)) {
            if (StartDocPrinter(hPrinter, 1, di)) {
                if (StartPagePrinter(hPrinter)) {
                    IntPtr pUnmanagedBytes = Marshal.AllocCoTaskMem(pBytes.Length);
                    Marshal.Copy(pBytes, 0, pUnmanagedBytes, pBytes.Length);
                    int dwWritten;
                    bSuccess = WritePrinter(hPrinter, pUnmanagedBytes, pBytes.Length, out dwWritten);
                    Marshal.FreeCoTaskMem(pUnmanagedBytes);
                    EndPagePrinter(hPrinter);
                }
                EndDocPrinter(hPrinter);
            }
            ClosePrinter(hPrinter);
        }
        return bSuccess;
    }
}
'@
\$bytes = [System.IO.File]::ReadAllBytes('$tempFile')
\$result = [RawPrinterHelper]::SendBytesToPrinter('$usbPath', \$bytes)
if (\$result) { Write-Output 'OK' } else { Write-Output 'FAILED'; exit 1 }
''';

      final psResult = await Process.run("powershell", [
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command",
        psScript,
      ]);

      print("🔍 Resultado RAW Print:");
      print("   - Código de salida: ${psResult.exitCode}");
      print("   - Salida: ${psResult.stdout.toString().trim()}");
      if (psResult.stderr.toString().trim().isNotEmpty) {
        print("   - Error: ${psResult.stderr}");
      }

      if (psResult.exitCode == 0 && psResult.stdout.toString().trim() == 'OK') {
        print("✅ Impresión RAW exitosa");
        await _cleanupTempFile(file);
        return true;
      }

      print("⚠️ RAW Print falló, intentando método copy /b...");

      // Método 2: Usar cmd copy /b con compartido de red local
      final copyResult = await Process.run("cmd", [
        "/c",
        "copy",
        "/b",
        tempFile,
        "\\\\localhost\\$usbPath",
      ]);

      if (copyResult.exitCode == 0) {
        print("✅ Impresión exitosa con copy /b UNC");
        await _cleanupTempFile(file);
        return true;
      } else {
        print("❌ Error con copy /b UNC: ${copyResult.stderr}");
      }

      // Método 3: Intentar con puerto USB directo
      // Obtener el puerto de la impresora via PowerShell
      final portResult = await Process.run("powershell", [
        "-NoProfile",
        "-Command",
        "(Get-Printer -Name '$usbPath' -ErrorAction SilentlyContinue).PortName",
      ]);

      if (portResult.exitCode == 0) {
        final portName = portResult.stdout.toString().trim();
        if (portName.isNotEmpty && portName.startsWith('USB')) {
          print("🔌 Puerto detectado: $portName");
          // Intentar escribir directamente al puerto
          final portCopy = await Process.run("cmd", [
            "/c",
            "copy",
            "/b",
            tempFile,
            "\\\\.\\$portName",
          ]);

          if (portCopy.exitCode == 0) {
            print("✅ Impresión exitosa directa a puerto $portName");
            await _cleanupTempFile(file);
            return true;
          }
        }
      }

      await _cleanupTempFile(file);
      print("❌ No se pudo enviar datos RAW a la impresora USB");
      _lastError.value = "No se pudo acceder a la impresora USB '$usbPath'";
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

  /// Cargar logo desde archivo local (guardado en configuración de organización)
  /// Usa dart:ui para decodificar cualquier formato (AVIF, HEIF, WebP, PNG, JPG, etc.)
  Future<img.Image?> _loadLogoImage() async {
    try {
      // Cache válido → retornar inmediatamente
      if (_cachedLogo != null && _logoLoadTime != null) {
        if (DateTime.now().difference(_logoLoadTime!) < _logoCacheExpiry) {
          return _cachedLogo;
        }
      }

      // 1. Buscar logo local guardado por el diálogo de organización
      final orgId = _cachedOrganization?.id;
      if (orgId == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final logoPath = '${dir.path}/org_logos/$orgId.png';
      final logoFile = File(logoPath);

      Uint8List? bytes;

      if (await logoFile.exists()) {
        print('🖼️ Logo encontrado en archivo local: $logoPath');
        bytes = await logoFile.readAsBytes();
      } else {
        // 2. Fallback: intentar descargar desde URL del servidor
        final logoUrl = _cachedOrganization?.logo;
        if (logoUrl == null || logoUrl.isEmpty) return null;

        String fullUrl = logoUrl;
        if (!logoUrl.startsWith('http')) return null;

        print('🌐 Descargando logo desde: $fullUrl');
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 5);
        final request = await client.getUrl(Uri.parse(fullUrl));
        final response = await request.close();
        if (response.statusCode != 200) return null;
        bytes = await consolidateHttpClientResponseBytes(response);
      }

      if (bytes == null || bytes.isEmpty) return null;

      // Paso 1: dart:ui decodifica CUALQUIER formato (AVIF, HEIF, WebP, PNG, JPG)
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      print(
        '🖼️ Logo decodificado: ${frameInfo.image.width}x${frameInfo.image.height}',
      );

      // Paso 2: Convertir a PNG bytes (formato universal, buffer mutable)
      final ByteData? pngData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frameInfo.image.dispose();

      if (pngData == null) {
        print('⚠️ No se pudo convertir logo a PNG');
        return null;
      }

      // Paso 3: Decodificar PNG con paquete image (crea buffer mutable)
      final originalImage = img.decodePng(pngData.buffer.asUint8List());
      if (originalImage == null) {
        print('⚠️ No se pudo decodificar PNG del logo');
        return null;
      }

      // Paso 4: Redimensionar
      final resized = img.copyResize(
        originalImage,
        width: 300,
        interpolation: img.Interpolation.linear,
      );

      print('🖼️ Logo listo para impresora: ${resized.width}x${resized.height}');

      _cachedLogo = resized;
      _logoLoadTime = DateTime.now();

      return resized;
    } catch (e) {
      print('⚠️ Logo no disponible: $e');
      return null;
    }
  }

  /// Verificar si hay logo disponible (archivo local o URL de organización)
  Future<bool> _hasLogoAvailable() async {
    // 1. Verificar archivo local
    final orgId = _cachedOrganization?.id;
    if (orgId != null) {
      final dir = await getApplicationDocumentsDirectory();
      final logoFile = File('${dir.path}/org_logos/$orgId.png');
      if (await logoFile.exists()) return true;
    }
    // 2. Verificar URL del servidor
    final logoUrl = _cachedOrganization?.logo;
    return logoUrl != null && logoUrl.isNotEmpty;
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
      final org = _cachedOrganization;
      final img.Image? logo = await _loadLogoImage();

      if (logo != null) {
        // Enviar imagen como raster ESC/POS manualmente
        // (evita bug de "fixed-length list" en esc_pos_utils_plus + image v4)
        _sendImageRaw(printer, logo);
        printer.feed(1);

        // Datos de la organización
        if (org != null) {
          if (org.address.isNotEmpty) {
            printer.text(
              org.address,
              styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
            );
          }
          if (org.phone.isNotEmpty) {
            printer.text(
              'Tel: ${org.phone}',
              styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
            );
          }
          if (org.taxId.isNotEmpty) {
            printer.text(
              'NIT: ${org.taxId}',
              styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
            );
          }
        }

        printer.feed(1);
      } else {
        await _printBusinessHeaderTextOnly(printer);
      }
    } catch (e) {
      print('❌ Error imprimiendo logo: $e');
      await _printBusinessHeaderTextOnly(printer);
    }
  }

  /// Enviar imagen directamente como raster (GS v 0) sin pasar por la librería
  void _sendImageRaw(NetworkPrinter printer, img.Image image) {
    printer.rawBytes(Uint8List.fromList(_generateImageRasterBytes(image)));
  }

  /// Header solo texto (fallback cuando no hay logo)
  Future<void> _printBusinessHeaderTextOnly(NetworkPrinter printer) async {
    final org = _cachedOrganization;
    final businessName = org?.businessName ?? 'Mi Negocio';

    printer.text(
      businessName,
      styles: const esc_pos.PosStyles(
        align: esc_pos.PosAlign.center,
        bold: true,
        height: esc_pos.PosTextSize.size2,
        width: esc_pos.PosTextSize.size2,
      ),
    );

    if (org != null) {
      if (org.address.isNotEmpty) {
        printer.text(
          org.address,
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        );
      }
      if (org.phone.isNotEmpty) {
        printer.text(
          'Tel: ${org.phone}',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        );
      }
      if (org.taxId.isNotEmpty) {
        printer.text(
          'NIT: ${org.taxId}',
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        );
      }
      if (org.email.isNotEmpty) {
        printer.text(
          org.email,
          styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.center),
        );
      }
    }

    printer.feed(1);
  }

  void setImageQuality({
    int maxWidth = 800,
    bool useMonochrome = true,
    int contrast = 250,
  }) {
    // Estas configuraciones se pueden usar en el procesamiento de imagen
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

      // Fecha de la factura (fecha de emisión, NO hora de impresión)
      final invoiceDate = invoice.date;
      final dateStr =
          '${invoiceDate.day.toString().padLeft(2, '0')}/${invoiceDate.month.toString().padLeft(2, '0')}/${invoiceDate.year} ${invoiceDate.hour.toString().padLeft(2, '0')}:${invoiceDate.minute.toString().padLeft(2, '0')}:${invoiceDate.second.toString().padLeft(2, '0')}';
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
      rethrow;
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

      printer.hr();
    } catch (e) {
      print('❌ Error imprimiendo info cliente: $e');
      rethrow;
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
      rethrow;
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
      rethrow;
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
      final org = _cachedOrganization;

      // Fecha y hora de impresión
      final now = DateTime.now();
      final timeStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      printer.text(
        'Impreso: $timeStr',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          fontType: esc_pos.PosFontType.fontB,
        ),
      );

      // Mensaje de agradecimiento (desde organización o default)
      final footerMsg = org?.footerMessage ?? 'Gracias por su compra';
      printer.text(
        footerMsg,
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          bold: true,
        ),
      );
      printer.feed(1);
      printer.text(
        'Desarrollado, Impreso y Generado por Baudex',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          fontType: esc_pos.PosFontType.fontB,
        ),
      );
      printer.text(
        'Información: 3138448436',
        styles: const esc_pos.PosStyles(
          align: esc_pos.PosAlign.center,
          fontType: esc_pos.PosFontType.fontB,
        ),
      );
    } catch (e) {
      print('❌ Error imprimiendo footer: $e');
      rethrow;
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

      // Asegurar datos de organización cargados
      if (_cachedOrganization == null) await _loadOrganizationData();

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
        'Fecha: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
        styles: const esc_pos.PosStyles(align: esc_pos.PosAlign.left),
      );

      printer.text(
        'Hora: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
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
