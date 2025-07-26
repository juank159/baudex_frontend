// lib/features/invoices/presentation/controllers/invoice_print_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../domain/entities/invoice.dart';
import 'invoice_detail_controller.dart';

// ==================== ENUMS Y CLASES ====================

enum PrintFormat {
  thermal(
    'thermal',
    'Térmica 80mm',
    'Impresión en rollo térmico de 80mm',
    Icons.receipt_long,
  ),
  a4('a4', 'A4', 'Formato A4 estándar', Icons.description),
  letter('letter', 'Carta', 'Formato carta US', Icons.article),
  receipt('receipt', 'Recibo', 'Formato de recibo compacto', Icons.receipt);

  const PrintFormat(this.value, this.displayName, this.description, this.icon);
  final String value;
  final String displayName;
  final String description;
  final IconData icon;
}

class ThermalSettings {
  final bool autoCut;
  final bool includeQR;
  final int copies;
  final double paperWidth; // en mm
  final bool openDrawer;

  const ThermalSettings({
    this.autoCut = true,
    this.includeQR = false,
    this.copies = 1,
    this.paperWidth = 80.0,
    this.openDrawer = false,
  });

  ThermalSettings copyWith({
    bool? autoCut,
    bool? includeQR,
    int? copies,
    double? paperWidth,
    bool? openDrawer,
  }) {
    return ThermalSettings(
      autoCut: autoCut ?? this.autoCut,
      includeQR: includeQR ?? this.includeQR,
      copies: copies ?? this.copies,
      paperWidth: paperWidth ?? this.paperWidth,
      openDrawer: openDrawer ?? this.openDrawer,
    );
  }
}

class PrintSettings {
  final bool includeLogo;
  final bool includeTerms;
  final bool includeNotes;
  final bool includeQR;
  final String? customHeader;
  final String? customFooter;

  const PrintSettings({
    this.includeLogo = true,
    this.includeTerms = true,
    this.includeNotes = true,
    this.includeQR = false,
    this.customHeader,
    this.customFooter,
  });

  PrintSettings copyWith({
    bool? includeLogo,
    bool? includeTerms,
    bool? includeNotes,
    bool? includeQR,
    String? customHeader,
    String? customFooter,
  }) {
    return PrintSettings(
      includeLogo: includeLogo ?? this.includeLogo,
      includeTerms: includeTerms ?? this.includeTerms,
      includeNotes: includeNotes ?? this.includeNotes,
      includeQR: includeQR ?? this.includeQR,
      customHeader: customHeader ?? this.customHeader,
      customFooter: customFooter ?? this.customFooter,
    );
  }
}

class PrintHistory {
  final String type;
  final DateTime timestamp;
  final bool success;
  final String? error;

  const PrintHistory({
    required this.type,
    required this.timestamp,
    required this.success,
    this.error,
  });
}

// ==================== CONTROLADOR PRINCIPAL ====================

class InvoicePrintController extends GetxController {
  // Dependencies
  final InvoiceDetailController _detailController;

  InvoicePrintController(this._detailController) {
    debugPrint('🖨️ InvoicePrintController: Instancia creada');
  }

  // ==================== OBSERVABLES ====================

  // Estados
  final _isLoading = false.obs;
  final _isPrinting = false.obs;
  final _isGeneratingPDF = false.obs;

  // Configuración
  final _selectedFormat = PrintFormat.a4.obs;
  final Rx<ThermalSettings> _thermalSettings = const ThermalSettings().obs;
  final Rx<PrintSettings> _printSettings = const PrintSettings().obs;

  // Impresoras
  final _availablePrinters = <Printer>[].obs;
  final Rxn<String> _selectedPrinter = Rxn<String>();

  // Historial
  final _printHistory = <PrintHistory>[].obs;

  // PDF generado
  final Rxn<pw.Document> _generatedPDF = Rxn<pw.Document>();

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isPrinting => _isPrinting.value;
  bool get isGeneratingPDF => _isGeneratingPDF.value;

  PrintFormat get selectedFormat => _selectedFormat.value;
  ThermalSettings get thermalSettings => _thermalSettings.value;
  PrintSettings get printSettings => _printSettings.value;

  List<Printer> get availablePrinters => _availablePrinters;
  String? get selectedPrinter => _selectedPrinter.value;

  List<PrintHistory> get printHistory => _printHistory;

  Invoice? get invoice => _detailController.invoice;
  bool get hasInvoice => _detailController.hasInvoice;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    debugPrint('🚀 InvoicePrintController: Inicializando...');
    _initializePrintController();
  }

  @override
  void onClose() {
    debugPrint('🔚 InvoicePrintController: Liberando recursos...');
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  Future<void> _initializePrintController() async {
    try {
      _isLoading.value = true;

      // Buscar impresoras disponibles
      await refreshPrinters();

      // Cargar configuración guardada
      await _loadSettings();

      debugPrint('✅ InvoicePrintController inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando InvoicePrintController: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadSettings() async {
    // TODO: Implementar carga de configuración desde storage
    debugPrint('📄 Cargando configuración de impresión...');
  }

  // ==================== FORMAT SETTINGS ====================

  void setFormat(PrintFormat? format) {
    if (format != null) {
      _selectedFormat.value = format;
      debugPrint('📋 Formato seleccionado: ${format.displayName}');
      update();
    }
  }

  void updateThermalSettings(ThermalSettings settings) {
    _thermalSettings.value = settings;
    debugPrint('🔧 Configuración térmica actualizada');
    update();
  }

  void updatePrintSettings(PrintSettings settings) {
    _printSettings.value = settings;
    debugPrint('⚙️ Configuración de impresión actualizada');
    update();
  }

  // ==================== PRINTER MANAGEMENT ====================

  Future<void> refreshPrinters() async {
    try {
      debugPrint('🔍 Buscando impresoras disponibles...');
      final printers = await Printing.listPrinters();
      _availablePrinters.value = printers;

      // Seleccionar impresora por defecto si no hay una seleccionada
      if (_selectedPrinter.value == null && printers.isNotEmpty) {
        _selectedPrinter.value = printers.first.name;
      }

      debugPrint('✅ ${printers.length} impresoras encontradas');
    } catch (e) {
      debugPrint('❌ Error buscando impresoras: $e');
      _showError('Error', 'No se pudieron buscar las impresoras disponibles');
    }
  }

  Future<void> selectPrinter() async {
    try {
      final printer = await Get.dialog<Printer>(
        AlertDialog(
          title: const Text('Seleccionar Impresora'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_availablePrinters.isEmpty) ...[
                  const Text('No se encontraron impresoras disponibles'),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      await refreshPrinters();
                      Get.back();
                    },
                    child: const Text('Buscar Impresoras'),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availablePrinters.length,
                    itemBuilder: (context, index) {
                      final printer = _availablePrinters[index];
                      return ListTile(
                        leading: const Icon(Icons.print),
                        title: Text(printer.name),
                        subtitle: Text(printer.url),
                        selected: _selectedPrinter.value == printer.name,
                        onTap: () => Get.back(result: printer),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );

      if (printer != null) {
        _selectedPrinter.value = printer.name;
        _showSuccess('Impresora seleccionada: ${printer.name}');
      }
    } catch (e) {
      debugPrint('❌ Error seleccionando impresora: $e');
      _showError('Error', 'No se pudo seleccionar la impresora');
    }
  }
  // ==================== PDF GENERATION ====================

  Future<pw.Document> generatePDF() async {
    if (_generatedPDF.value != null) {
      return _generatedPDF.value!;
    }

    try {
      _isGeneratingPDF.value = true;
      debugPrint('📄 Generando PDF...');

      final pdf = pw.Document();

      switch (_selectedFormat.value) {
        case PrintFormat.thermal:
          await _generateThermalPDF(pdf);
          break;
        case PrintFormat.a4:
        case PrintFormat.letter:
        case PrintFormat.receipt:
          await _generateStandardPDF(pdf);
          break;
      }

      _generatedPDF.value = pdf;
      debugPrint('✅ PDF generado exitosamente');
      return pdf;
    } catch (e) {
      debugPrint('❌ Error generando PDF: $e');
      throw Exception('Error al generar PDF: $e');
    } finally {
      _isGeneratingPDF.value = false;
    }
  }

  Future<void> _generateStandardPDF(pw.Document pdf) async {
    final invoice = this.invoice!;

    // Usar fuentes básicas para evitar problemas
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.Page(
        pageFormat:
            _selectedFormat.value == PrintFormat.a4
                ? PdfPageFormat.a4
                : PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildPDFHeader(invoice, font, fontBold),
              pw.SizedBox(height: 20),

              // Invoice Info
              _buildPDFInvoiceInfo(invoice, font, fontBold),
              pw.SizedBox(height: 20),

              // Customer Info
              _buildPDFCustomerInfo(invoice, font, fontBold),
              pw.SizedBox(height: 20),

              // Items Table
              _buildPDFItemsTable(invoice, font, fontBold),
              pw.SizedBox(height: 20),

              // Totals
              _buildPDFTotals(invoice, font, fontBold),

              // Footer
              if (_printSettings.value.includeTerms ||
                  _printSettings.value.includeNotes)
                pw.Expanded(child: pw.Container()),
              _buildPDFFooter(invoice, font, fontBold),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generateThermalPDF(pw.Document pdf) async {
    final invoice = this.invoice!;
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          _thermalSettings.value.paperWidth * PdfPageFormat.mm,
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo y empresa
              if (_printSettings.value.includeLogo)
                pw.Container(
                  width: 60,
                  height: 60,
                  color: PdfColors.grey300,
                  child: pw.Center(
                    child: pw.Text('LOGO', style: pw.TextStyle(font: fontBold)),
                  ),
                ),

              pw.SizedBox(height: 10),

              // Información de empresa
              pw.Text(
                'la Granada',
                style: pw.TextStyle(font: fontBold, fontSize: 14),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'NIT: 900.123.456-7',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                'Ragonvalia, Colombia',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                'Tel: +57 3167181910',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),

              pw.SizedBox(height: 15),
              pw.Divider(),

              // Información de factura
              pw.Text(
                'FACTURA DE VENTA',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No:', style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text(
                    invoice.number,
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Fecha:',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.Text(
                    '${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(),

              // Cliente
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'CLIENTE:',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  invoice.customerName,
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ),

              pw.SizedBox(height: 10),
              pw.Divider(),

              // Items
              ...invoice.items.map(
                (item) => _buildThermalPDFItem(item, font, fontBold),
              ),

              pw.Divider(),

              // Totales
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Subtotal:',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.Text(
                    '\$${invoice.subtotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),

              if (invoice.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Descuento:',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                    pw.Text(
                      '- \$${invoice.discountAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'IVA (${invoice.taxPercentage}%):',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.Text(
                    '\$${invoice.taxAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),

              pw.Divider(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                  pw.Text(
                    '\$${invoice.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                ],
              ),

              pw.SizedBox(height: 15),

              // Método de pago
              pw.Text(
                'Método de pago: ${invoice.paymentMethodDisplayName}',
                style: pw.TextStyle(font: font, fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),

              // QR Code si está habilitado
              if (_thermalSettings.value.includeQR) ...[
                pw.SizedBox(height: 15),
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'QR\nCODE',
                      style: pw.TextStyle(font: font, fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
                pw.Text(
                  'Escanea para consultar',
                  style: pw.TextStyle(font: font, fontSize: 8),
                ),
              ],

              // Términos y condiciones
              if (_printSettings.value.includeTerms &&
                  invoice.terms?.isNotEmpty == true) ...[
                pw.SizedBox(height: 15),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'TÉRMINOS:',
                    style: pw.TextStyle(font: fontBold, fontSize: 8),
                  ),
                ),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    invoice.terms!,
                    style: pw.TextStyle(font: font, fontSize: 7),
                  ),
                ),
              ],

              pw.SizedBox(height: 15),
              pw.Text(
                'Gracias por su compra',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),

              if (_thermalSettings.value.autoCut) ...[
                pw.SizedBox(height: 15),
                pw.Divider(color: PdfColors.red),
                pw.Text(
                  '✂️ CORTE AUTOMÁTICO',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 6,
                    color: PdfColors.red,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  pw.Widget _buildPDFHeader(Invoice invoice, pw.Font font, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (_printSettings.value.includeLogo)
              pw.Container(
                width: 80,
                height: 80,
                color: PdfColors.grey300,
                child: pw.Center(
                  child: pw.Text('LOGO', style: pw.TextStyle(font: fontBold)),
                ),
              ),
            pw.SizedBox(height: 10),
            pw.Text(
              'MI EMPRESA S.A.S.',
              style: pw.TextStyle(font: fontBold, fontSize: 18),
            ),
            pw.Text('NIT: 900.123.456-7', style: pw.TextStyle(font: font)),
            pw.Text('Ragonvalia, Colombia', style: pw.TextStyle(font: font)),
            pw.Text('Tel: +57 300 123 4567', style: pw.TextStyle(font: font)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'FACTURA',
              style: pw.TextStyle(font: fontBold, fontSize: 24),
            ),
            pw.Text(
              'No. ${invoice.number}',
              style: pw.TextStyle(font: fontBold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFInvoiceInfo(
    Invoice invoice,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Fecha: ${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
                style: pw.TextStyle(font: font),
              ),
              pw.Text(
                'Vencimiento: ${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
                style: pw.TextStyle(font: font),
              ),
              pw.Text(
                'Estado: ${invoice.statusDisplayName}',
                style: pw.TextStyle(font: font),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFCustomerInfo(
    Invoice invoice,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('FACTURAR A:', style: pw.TextStyle(font: fontBold)),
        pw.SizedBox(height: 5),
        pw.Text(invoice.customerName, style: pw.TextStyle(font: font)),
        if (invoice.customerEmail?.isNotEmpty == true)
          pw.Text(invoice.customerEmail!, style: pw.TextStyle(font: font)),
      ],
    );
  }

  pw.Widget _buildPDFItemsTable(
    Invoice invoice,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Descripción',
                style: pw.TextStyle(font: fontBold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Cant.', style: pw.TextStyle(font: fontBold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Precio Unit.',
                style: pw.TextStyle(font: fontBold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Total', style: pw.TextStyle(font: fontBold)),
            ),
          ],
        ),
        // Items
        ...invoice.items.map(
          (item) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  item.description,
                  style: pw.TextStyle(font: font),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  item.quantity.toString(),
                  style: pw.TextStyle(font: font),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '\${item.unitPrice.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: font),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '\${item.subtotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: font),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFTotals(Invoice invoice, pw.Font font, pw.Font fontBold) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal:', style: pw.TextStyle(font: font)),
                pw.Text(
                  '\${invoice.subtotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: font),
                ),
              ],
            ),
            if (invoice.discountAmount > 0) ...[
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Descuento:', style: pw.TextStyle(font: font)),
                  pw.Text(
                    '- \${invoice.discountAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(font: font),
                  ),
                ],
              ),
            ],
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'IVA (${invoice.taxPercentage}%):',
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  '\${invoice.taxAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: font),
                ),
              ],
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL:',
                  style: pw.TextStyle(font: fontBold, fontSize: 16),
                ),
                pw.Text(
                  '\${invoice.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: fontBold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPDFFooter(Invoice invoice, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (_printSettings.value.includeTerms &&
            invoice.terms?.isNotEmpty == true) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            'TÉRMINOS Y CONDICIONES:',
            style: pw.TextStyle(font: fontBold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            invoice.terms!,
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ],
        if (_printSettings.value.includeNotes &&
            invoice.notes?.isNotEmpty == true) ...[
          pw.SizedBox(height: 20),
          pw.Text('NOTAS:', style: pw.TextStyle(font: fontBold)),
          pw.SizedBox(height: 5),
          pw.Text(
            invoice.notes!,
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ],
        pw.SizedBox(height: 20),
        pw.Text(
          'Método de pago: ${invoice.paymentMethodDisplayName}',
          style: pw.TextStyle(font: font),
        ),
      ],
    );
  }

  pw.Widget _buildThermalPDFItem(dynamic item, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.description,
            style: pw.TextStyle(font: fontBold, fontSize: 10),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${item.quantity} x \${item.unitPrice.toStringAsFixed(2)}',
                style: pw.TextStyle(font: font, fontSize: 8),
              ),
              pw.Text(
                '\${item.subtotal.toStringAsFixed(2)}',
                style: pw.TextStyle(font: fontBold, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // ==================== PRINTING ACTIONS ====================

  /// Imprimir factura
  Future<void> printInvoice() async {
    if (!hasInvoice) {
      _showError('Error', 'No hay factura para imprimir');
      return;
    }

    try {
      _isPrinting.value = true;
      debugPrint('🖨️ Iniciando impresión...');

      switch (_selectedFormat.value) {
        case PrintFormat.thermal:
          await _printThermal();
          break;
        case PrintFormat.a4:
        case PrintFormat.letter:
        case PrintFormat.receipt:
          await _printStandard();
          break;
      }

      _addToHistory('Impresión ${_selectedFormat.value.displayName}', true);
      //_showSuccess('Factura impresa exitosamente');
    } catch (e) {
      debugPrint('❌ Error imprimiendo: $e');
      _addToHistory(
        'Impresión ${_selectedFormat.value.displayName}',
        false,
        e.toString(),
      );
      _showError('Error de impresión', 'No se pudo imprimir la factura: $e');
    } finally {
      _isPrinting.value = false;
    }
  }

  Future<void> _printStandard() async {
    final pdf = await generatePDF();
    final bytes = await pdf.save();

    if (_selectedPrinter.value != null) {
      // Imprimir en impresora específica
      await Printing.directPrintPdf(
        printer: Printer(url: _selectedPrinter.value!),
        onLayout: (format) => bytes,
      );
    } else {
      // Mostrar diálogo de impresión del sistema
      await Printing.layoutPdf(
        onLayout: (format) => bytes,
        name: 'Factura_${invoice!.number}',
      );
    }
  }

  Future<void> _printThermal() async {
    final pdf = await generatePDF();
    final bytes = await pdf.save();

    // Imprimir múltiples copias si está configurado
    for (int i = 0; i < _thermalSettings.value.copies; i++) {
      if (_selectedPrinter.value != null) {
        await Printing.directPrintPdf(
          printer: Printer(url: _selectedPrinter.value!),
          onLayout: (format) => bytes,
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (format) => bytes,
          name: 'Factura_Termica_${invoice!.number}_${i + 1}',
        );
      }

      // Pequeña pausa entre copias
      if (i < _thermalSettings.value.copies - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  // ==================== PREVIEW ACTIONS ====================

  /// Mostrar vista previa
  Future<void> showPreview() async {
    if (!hasInvoice) {
      _showError('Error', 'No hay factura para previsualizar');
      return;
    }

    try {
      debugPrint('👁️ Mostrando vista previa...');
      final pdf = await generatePDF();
      final bytes = await pdf.save();

      await Printing.layoutPdf(
        onLayout: (format) => bytes,
        name: 'Vista_Previa_${invoice!.number}',
      );

      _addToHistory('Vista Previa', true);
    } catch (e) {
      debugPrint('❌ Error en vista previa: $e');
      _addToHistory('Vista Previa', false, e.toString());
      _showError('Error', 'No se pudo mostrar la vista previa: $e');
    }
  }

  // ==================== SAVE ACTIONS ====================

  /// Guardar como PDF
  Future<void> savePDF() async {
    if (!hasInvoice) {
      _showError('Error', 'No hay factura para guardar');
      return;
    }

    try {
      debugPrint('💾 Guardando PDF...');
      final pdf = await generatePDF();
      final bytes = await pdf.save();

      // En móvil/tablet, usar share
      if (GetPlatform.isMobile || GetPlatform.isWeb) {
        await _sharePDF(bytes);
      } else {
        // En desktop, guardar archivo
        await _savePDFToFile(bytes);
      }

      _addToHistory('Guardar PDF', true);
      _showSuccess('PDF guardado exitosamente');
    } catch (e) {
      debugPrint('❌ Error guardando PDF: $e');
      _addToHistory('Guardar PDF', false, e.toString());
      _showError('Error', 'No se pudo guardar el PDF: $e');
    }
  }

  Future<void> _sharePDF(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Factura_${invoice!.number}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Factura ${invoice!.number}');
  }

  Future<void> _savePDFToFile(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Factura_${invoice!.number}.pdf');
    await file.writeAsBytes(bytes);

    _showSuccess('PDF guardado en: ${file.path}');
  }

  // ==================== EMAIL ACTIONS ====================

  /// Enviar por email
  Future<void> sendByEmail() async {
    if (!hasInvoice) {
      _showError('Error', 'No hay factura para enviar');
      return;
    }

    try {
      debugPrint('📧 Preparando email...');
      final pdf = await generatePDF();
      final bytes = await pdf.save();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Factura_${invoice!.number}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Adjunto encontrarás la factura ${invoice!.number}',
        subject: 'Factura ${invoice!.number} - MI EMPRESA S.A.S.',
      );

      _addToHistory('Envío por Email', true);
      _showSuccess('Email preparado exitosamente');
    } catch (e) {
      debugPrint('❌ Error enviando email: $e');
      _addToHistory('Envío por Email', false, e.toString());
      _showError('Error', 'No se pudo preparar el email: $e');
    }
  }

  // ==================== SHARE ACTIONS ====================

  /// Compartir factura
  Future<void> share() async {
    if (!hasInvoice) {
      _showError('Error', 'No hay factura para compartir');
      return;
    }

    try {
      debugPrint('📤 Compartiendo factura...');
      final pdf = await generatePDF();
      final bytes = await pdf.save();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Factura_${invoice!.number}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Factura ${invoice!.number}');

      _addToHistory('Compartir', true);
    } catch (e) {
      debugPrint('❌ Error compartiendo: $e');
      _addToHistory('Compartir', false, e.toString());
      _showError('Error', 'No se pudo compartir la factura: $e');
    }
  }

  // ==================== HISTORY MANAGEMENT ====================

  void _addToHistory(String type, bool success, [String? error]) {
    final history = PrintHistory(
      type: type,
      timestamp: DateTime.now(),
      success: success,
      error: error,
    );

    _printHistory.insert(0, history);

    // Mantener solo los últimos 20 registros
    if (_printHistory.length > 20) {
      _printHistory.removeRange(20, _printHistory.length);
    }

    update();
  }

  void clearHistory() {
    _printHistory.clear();
    update();
    _showSuccess('Historial limpiado');
  }

  // ==================== UTILITY METHODS ====================

  /// Resetear PDF generado para forzar regeneración
  void resetGeneratedPDF() {
    _generatedPDF.value = null;
    debugPrint('🔄 PDF reset - se regenerará en la próxima solicitud');
  }

  /// Validar si se puede imprimir
  bool canPrint() {
    return hasInvoice && !isPrinting;
  }

  /// Obtener configuración como mapa para persistencia
  Map<String, dynamic> getSettingsAsMap() {
    return {
      'selectedFormat': _selectedFormat.value.value,
      'thermalSettings': {
        'autoCut': _thermalSettings.value.autoCut,
        'includeQR': _thermalSettings.value.includeQR,
        'copies': _thermalSettings.value.copies,
        'paperWidth': _thermalSettings.value.paperWidth,
        'openDrawer': _thermalSettings.value.openDrawer,
      },
      'printSettings': {
        'includeLogo': _printSettings.value.includeLogo,
        'includeTerms': _printSettings.value.includeTerms,
        'includeNotes': _printSettings.value.includeNotes,
        'includeQR': _printSettings.value.includeQR,
        'customHeader': _printSettings.value.customHeader,
        'customFooter': _printSettings.value.customFooter,
      },
      'selectedPrinter': _selectedPrinter.value,
    };
  }

  /// Cargar configuración desde mapa
  void loadSettingsFromMap(Map<String, dynamic> settings) {
    try {
      if (settings['selectedFormat'] != null) {
        _selectedFormat.value = PrintFormat.values.firstWhere(
          (format) => format.value == settings['selectedFormat'],
          orElse: () => PrintFormat.a4,
        );
      }

      if (settings['thermalSettings'] != null) {
        final thermal = settings['thermalSettings'];
        _thermalSettings.value = ThermalSettings(
          autoCut: thermal['autoCut'] ?? true,
          includeQR: thermal['includeQR'] ?? false,
          copies: thermal['copies'] ?? 1,
          paperWidth: thermal['paperWidth'] ?? 80.0,
          openDrawer: thermal['openDrawer'] ?? false,
        );
      }

      if (settings['printSettings'] != null) {
        final printSettings = settings['printSettings'];
        _printSettings.value = PrintSettings(
          includeLogo: printSettings['includeLogo'] ?? true,
          includeTerms: printSettings['includeTerms'] ?? true,
          includeNotes: printSettings['includeNotes'] ?? true,
          includeQR: printSettings['includeQR'] ?? false,
          customHeader: printSettings['customHeader'],
          customFooter: printSettings['customFooter'],
        );
      }

      if (settings['selectedPrinter'] != null) {
        _selectedPrinter.value = settings['selectedPrinter'];
      }

      update();
      debugPrint('✅ Configuración cargada desde mapa');
    } catch (e) {
      debugPrint('❌ Error cargando configuración: $e');
    }
  }

  // ==================== MESSAGE HELPERS ====================

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
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
  }
}
