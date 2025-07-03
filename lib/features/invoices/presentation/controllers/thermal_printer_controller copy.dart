import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

// lib/features/invoices/presentation/controllers/thermal_printer_controller.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/invoice.dart';

// ==================== CONFIGURACIÓN ESPECÍFICA SAT Q22UE ====================

class SATQ22UEConfig {
  static const String defaultNetworkIP = '192.168.1.181';
  static const int defaultNetworkPort = 9100;
  static const PaperSize paperSize = PaperSize.mm80;

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
  final String ip;
  final int port;
  final bool isConnected;

  const NetworkPrinterInfo({
    required this.ip,
    required this.port,
    this.isConnected = false,
  });

  NetworkPrinterInfo copyWith({String? ip, int? port, bool? isConnected}) {
    return NetworkPrinterInfo(
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
  // ==================== OBSERVABLES ====================

  final _isConnected = false.obs;
  final _isPrinting = false.obs;
  final _lastError = Rxn<String>();
  final _printHistory = <PrintJob>[].obs;

  // Estado de red vs USB
  final _preferUSB = true.obs; // Desktop prefiere USB
  final _networkPrinters = <NetworkPrinterInfo>[].obs;

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

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    print('🖨️ ThermalPrinterController: Inicializando...');
    _initializePrinter();
  }

  @override
  void onClose() {
    print('🔚 ThermalPrinterController: Cerrando conexiones...');
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
    try {
      final profile = await CapabilityProfile.load();
      final printer = NetworkPrinter(SATQ22UEConfig.paperSize, profile);

      // Intentar conexión con timeout corto
      final result = await printer
          .connect(ip, port: port)
          .timeout(const Duration(seconds: 3));

      if (result == PosPrintResult.success) {
        printer.disconnect(); // Sin await - void return
        print('✅ Impresora encontrada en $ip:$port');
        return true;
      }

      printer.disconnect(); // Sin await - void return
      return false;
    } catch (e) {
      print('⚠️ No hay impresora en $ip:$port');
      return false;
    }
  }

  Future<void> refreshPrinters() async {
    print('🔄 Refrescando lista de impresoras...');
    await _discoverNetworkPrinters();
  }
  // ==================== IMPRESIÓN PRINCIPAL ====================

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
      print('   - Preferir USB: $_preferUSB');

      bool success = false;

      // Estrategia de impresión según plataforma
      if (!kIsWeb && !GetPlatform.isMobile && _preferUSB.value) {
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

      if (success) {
        _addToPrintHistory(invoice, true);
        _showSuccess('Factura impresa exitosamente');
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
      return false;
    } catch (e) {
      print('❌ Error en impresión USB: $e');
      _lastError.value = 'USB: $e';
      return false;
    }
  }

  Future<bool> _printUSBWindows(Invoice invoice) async {
    // TODO: Implementar usando comandos Windows o librerías específicas
    print('🪟 Impresión USB Windows no implementada aún');
    return false;
  }

  Future<bool> _printUSBLinux(Invoice invoice) async {
    // TODO: Implementar usando /dev/usb/lp* o cups
    print('🐧 Impresión USB Linux no implementada aún');
    return false;
  }

  Future<bool> _printUSBMacOS(Invoice invoice) async {
    // TODO: Implementar usando cups o librerías específicas
    print('🍎 Impresión USB macOS no implementada aún');
    return false;
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

  Future<bool> _sendToPrinter(
    NetworkPrinterInfo printerInfo,
    Invoice invoice,
  ) async {
    NetworkPrinter? printer;

    try {
      final profile = await CapabilityProfile.load();
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

      // Generar contenido de impresión
      await _generatePrintContent(printer, invoice);

      // Enviar comandos de corte
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.cutCommands));

      print('📄 Contenido enviado a impresora');
      return true;
    } catch (e) {
      print('❌ Error enviando a impresora: $e');
      _lastError.value = e.toString();
      return false;
    } finally {
      if (printer != null) {
        printer.disconnect(); // Sin await - void return
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
      // Inicializar impresora con comandos específicos SAT
      printer.rawBytes(Uint8List.fromList(SATQ22UEConfig.initializeCommands));

      // Header de empresa
      await _printBusinessHeader(printer);

      // Información de factura
      await _printInvoiceInfo(printer, invoice);

      // Información del cliente
      await _printCustomerInfo(printer, invoice);

      // Items
      await _printItems(printer, invoice);

      // Totales
      await _printTotals(printer, invoice);

      // Footer
      await _printFooter(printer, invoice);

      // Espaciado final
      printer.feed(3);
    } catch (e) {
      print('❌ Error generando contenido: $e');
      throw Exception('Error en generación de contenido: $e');
    }
  }

  Future<img.Image?> _loadLogoImage() async {
    try {
      print('🖼️ Cargando logo desde assets...');

      // Cargar imagen desde assets
      final ByteData data = await rootBundle.load(
        'assets/images/LOGO_GRANADA.png',
      );
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

      print(
        '✅ Logo procesado: ${processedImage.width}x${processedImage.height}',
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
    final img.Image contrastedImage = img.contrast(grayImage, contrast: 250);

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
      // Intentar imprimir logo
      final bool hasLogo = await _hasLogoAvailable();

      if (hasLogo) {
        print('🖼️ Imprimiendo header con logo...');
        await _printBusinessHeaderWithImage(printer);
      } else {
        print('📝 Imprimiendo header sin logo...');
        await _printBusinessHeaderTextOnly(printer);
      }
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
        printer.image(logo, align: PosAlign.center);
      }
    } catch (e) {
      print('❌ Error imprimiendo logo: $e');
      // Fallback a versión de texto
      await _printBusinessHeaderTextOnly(printer);
      return;
    }
  }

  /// Header solo texto (versión original como fallback)
  Future<void> _printBusinessHeaderTextOnly(NetworkPrinter printer) async {
    // Logo/Título centrado (versión original)
    printer.text(
      ' La Granada.',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    printer.text(
      'Ragonvalia, Norte de Santander',
      styles: const PosStyles(align: PosAlign.center),
    );

    printer.text(
      'Tel: +57 3167181910',
      styles: const PosStyles(align: PosAlign.center),
    );
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
    printer.text(
      'FACTURA DE VENTA',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );

    printer.feed(1);

    // Número de factura
    printer.row([
      PosColumn(text: 'No:', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(
        text: invoice.number,
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    // Fecha
    final now = DateTime.now();
    final dateStr =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    printer.row([
      PosColumn(text: 'Fecha:', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(
        text: dateStr,
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    // Método de pago
    printer.row([
      PosColumn(text: 'Pago:', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(
        text: invoice.paymentMethodDisplayName,
        width: 8,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    printer.hr();
  }

  Future<void> _printCustomerInfo(
    NetworkPrinter printer,
    Invoice invoice,
  ) async {
    printer.text('CLIENTE:', styles: const PosStyles(bold: true));

    printer.text(
      invoice.customerName,
      styles: const PosStyles(align: PosAlign.left),
    );

    if (invoice.customerEmail?.isNotEmpty == true) {
      printer.text(
        invoice.customerEmail!,
        styles: const PosStyles(align: PosAlign.left),
      );
    }

    printer.hr();
  }

  Future<void> _printItems(NetworkPrinter printer, Invoice invoice) async {
    // ✅ ENCABEZADO DE TABLA PROFESIONAL
    printer.text(
      'ITEM      CANT.       V.UNIT            IVA              TOTAL',
      styles: PosStyles(
        align: PosAlign.left, // Alineación centrada
        bold: true,
        fontType: PosFontType.fontB,
      ),
    );
    printer.hr(ch: '-', len: 40);

    // ✅ CONTADOR DE ITEMS
    int itemNumber = 1;

    for (final item in invoice.items) {
      // ✅ TÍTULO DEL PRODUCTO CON NÚMERO
      printer.text(
        '${itemNumber.toString().padLeft(2, '0')} - ${item.description.toUpperCase()}',
        styles: const PosStyles(bold: true, align: PosAlign.left),
      );

      // ✅ LÍNEA DE DETALLES - CORREGIDA PARA SUMAR 12
      final quantity = item.quantity.toInt().toString();
      final unitPrice = item.unitPrice.toStringAsFixed(0);
      final discount =
          item.discountAmount > 0
              ? item.discountAmount.toStringAsFixed(0)
              : (item.discountPercentage > 0
                  ? '${item.discountPercentage.toInt()}%'
                  : '0');
      final total = item.quantity * item.unitPrice;
      final itemTotal = total.toStringAsFixed(0);

      // ✅ FORMATEAR LÍNEA CON WIDTH CORRECTO (total = 12)
      printer.row([
        PosColumn(
          text: '',
          width: 2, // Cantidad
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: quantity,
          width: 2, // Unidad
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: '\$${format.format(item.unitPrice)}',
          width: 3, // ✅ CAMBIADO de 4 a 3
          styles: const PosStyles(align: PosAlign.left),
        ),
        // PosColumn(
        //   text: discount,
        //   width: 2, // Descuento
        //   styles: const PosStyles(align: PosAlign.center),
        // ),
        PosColumn(
          text: '19',
          width: 1, // IVA
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          //text: '\$${itemTotal}',
          text: '\$${itemTotal}',
          width: 4, // ✅ CAMBIADO de 4 a 3
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
      // TOTAL: 2+1+3+2+1+3 = 12 ✅

      // ✅ INFORMACIÓN ADICIONAL (garantía automática)
      if (item.notes != null && item.notes!.isNotEmpty) {
        printer.text(
          item.notes!,
          styles: const PosStyles(
            fontType: PosFontType.fontB,
            align: PosAlign.left,
          ),
        );
      } else {
        // Garantía por defecto para ciertos productos
        if (item.description.toLowerCase().contains('impresora') ||
            item.description.toLowerCase().contains('equipo') ||
            item.description.toLowerCase().contains('dispositivo')) {
          printer.text(
            'GARANTIA DE 3 MESES POR DEFECTOS DE FABRICA',
            styles: const PosStyles(
              fontType: PosFontType.fontB,
              align: PosAlign.left,
            ),
          );
        }
      }

      //printer.feed(1);
      itemNumber++;
    }

    // ✅ RESUMEN DE ITEMS
    printer.hr(ch: '-', len: 40);
    printer.text(
      'TOTAL ITEMS: ${invoice.items.length}',
      styles: const PosStyles(bold: true, align: PosAlign.left),
    );
    printer.feed(1);
  }

  // ✅ TAMBIÉN CORREGIR _printTotals PARA EVITAR ERRORES:

  Future<void> _printTotals(NetworkPrinter printer, Invoice invoice) async {
    // ✅ CÁLCULOS DETALLADOS
    final subtotalSinIva =
        invoice.subtotal / (1 + (invoice.taxPercentage / 100));
    final ivaCalculado = invoice.subtotal - subtotalSinIva;

    //   // ✅ TOTALES DETALLADOS - WIDTH CORREGIDO (total = 12)
    //   printer.row([
    //     PosColumn(
    //       text: 'Subtotal:',
    //       width: 8, // ✅ CORRECTO
    //       styles: const PosStyles(align: PosAlign.left, bold: true),
    //     ),
    //     PosColumn(
    //       text: '\$${subtotalSinIva.toStringAsFixed(1)}',
    //       width: 4, // ✅ CORRECTO (8+4=12)
    //       styles: const PosStyles(align: PosAlign.right),
    //     ),
    //   ]);

    //   printer.row([
    //     PosColumn(
    //       text: 'IVA:',
    //       width: 8,
    //       styles: const PosStyles(align: PosAlign.left, bold: true),
    //     ),
    //     PosColumn(
    //       text: '\$${ivaCalculado.toStringAsFixed(1)}',
    //       width: 4,
    //       styles: const PosStyles(align: PosAlign.right),
    //     ),
    //   ]);

    //   // ✅ TOTAL FINAL - WIDTH CORREGIDO
    printer.row([
      PosColumn(
        text: 'TOTAL A PAGAR:',
        width: 8,
        styles: const PosStyles(
          align: PosAlign.left,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
      PosColumn(
        text: ': \$${format.format(invoice.total)}',
        width: 4,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]);
    printer.feed(1);
  }

  Future<void> _printFooter(NetworkPrinter printer, Invoice invoice) async {
    // printer.feed(1);

    // // Información adicional si hay
    if (invoice.notes?.isNotEmpty == true) {
      //printer.text('NOTAS:', styles: const PosStyles(bold: true));
      printer.text(
        invoice.notes!,
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      printer.feed(1);
    }

    // Fecha y hora de impresión
    final now = DateTime.now();
    final timeStr =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    printer.text(
      'Impreso: $timeStr',
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    );
    // Mensaje de agradecimiento
    printer.text(
      '¡Gracias por su compra!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    printer.feed(1);
    printer.text(
      'Desarrollado, Impreso y Generado por Baudex',
      styles: const PosStyles(align: PosAlign.center),
    );
    printer.text(
      'Baudex es una marca registrada de Baudity',
      styles: const PosStyles(align: PosAlign.center),
    );
    printer.text(
      'Informacion: 3138888436',
      styles: const PosStyles(align: PosAlign.center),
    );
  }

  // ==================== GESTIÓN DE HISTORIAL ====================

  void _addToPrintHistory(Invoice invoice, bool success, [String? error]) {
    final job = PrintJob(
      invoiceNumber: invoice.number,
      timestamp: DateTime.now(),
      success: success,
      error: error,
      method: _preferUSB.value ? 'USB' : 'Red',
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

  // ==================== DEBUG ====================

  void debugPrintStatus() {
    print('🔍 === ESTADO IMPRESORA TÉRMICA ===');
    print('   - Conectado: $isConnected');
    print('   - Imprimiendo: $isPrinting');
    print('   - Preferir USB: $preferUSB');
    print('   - Impresoras red: ${networkPrinters.length}');
    print('   - Último error: $lastError');
    print('   - Historial: ${printHistory.length} trabajos');
  }
}
