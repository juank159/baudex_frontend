// lib/features/invoices/presentation/screens/invoice_print_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/invoice_print_controller.dart';
import '../controllers/invoice_detail_controller.dart';
import '../bindings/invoice_binding.dart';
import '../../domain/entities/invoice.dart';

class InvoicePrintScreen extends StatelessWidget {
  const InvoicePrintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Registrar controlador específico para impresión
    InvoiceBinding.registerDetailController();
    final detailController = Get.find<InvoiceDetailController>();

    // Crear controlador de impresión
    Get.put(InvoicePrintController(detailController));
    final printController = Get.find<InvoicePrintController>();

    return Scaffold(
      appBar: _buildAppBar(context, printController),
      body: GetBuilder<InvoicePrintController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const LoadingWidget(message: 'Preparando impresión...');
          }

          if (!controller.hasInvoice) {
            return _buildErrorState(context);
          }

          return ResponsiveLayout(
            mobile: _buildMobileLayout(context, controller),
            tablet: _buildTabletLayout(context, controller),
            desktop: _buildDesktopLayout(context, controller),
          );
        },
      ),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return AppBar(
      title: GetBuilder<InvoicePrintController>(
        builder:
            (controller) =>
                Text('Imprimir Factura ${controller.invoice?.number ?? ''}'),
      ),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Navega directamente al dashboard y elimina el historial
          Get.offAllNamed(AppRoutes.invoices);
        },
      ),
      actions: [
        // Vista previa
        IconButton(
          icon: const Icon(Icons.preview),
          onPressed: () => controller.showPreview(),
          tooltip: 'Vista Previa',
        ),

        // Configuración
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showPrintSettings(context, controller),
          tooltip: 'Configuración de Impresión',
        ),

        // Menú
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context, controller),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'save_pdf',
                  child: Row(
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text('Guardar como PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'email',
                  child: Row(
                    children: [
                      Icon(Icons.email),
                      SizedBox(width: 8),
                      Text('Enviar por Email'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Compartir'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildMobileLayout(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return Column(
      children: [
        // Selector de formato
        _buildFormatSelector(context, controller),

        // Vista previa
        Expanded(child: _buildPreview(context, controller)),

        // Acciones de impresión
        _buildPrintActions(context, controller),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return Row(
      children: [
        // Panel de configuración
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              _buildConfigurationPanel(context, controller),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPrintButtons(context, controller),
              ),
            ],
          ),
        ),

        // Vista previa
        Expanded(child: _buildPreview(context, controller)),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return Row(
      children: [
        // Panel de configuración izquierdo
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              _buildConfigurationPanel(context, controller),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPrintButtons(context, controller),
              ),
            ],
          ),
        ),

        // Vista previa principal
        Expanded(flex: 3, child: _buildPreview(context, controller)),

        // Panel de acciones derecho
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(children: [_buildActionPanel(context, controller)]),
        ),
      ],
    );
  }
  // ==================== COMPONENTS ====================

  Widget _buildFormatSelector(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: GetBuilder<InvoicePrintController>(
        builder:
            (controller) => Row(
              children: [
                Text(
                  'Formato:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children:
                        PrintFormat.values
                            .map(
                              (format) => ChoiceChip(
                                label: Text(format.displayName),
                                selected: controller.selectedFormat == format,
                                onSelected: (_) => controller.setFormat(format),
                                avatar: Icon(format.icon, size: 16),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildConfigurationPanel(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Configuración',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Formato de impresión
            _buildConfigSection(
              'Formato de Impresión',
              GetBuilder<InvoicePrintController>(
                builder:
                    (controller) => Column(
                      children:
                          PrintFormat.values
                              .map(
                                (format) => RadioListTile<PrintFormat>(
                                  title: Text(format.displayName),
                                  subtitle: Text(format.description),
                                  value: format,
                                  groupValue: controller.selectedFormat,
                                  onChanged: controller.setFormat,
                                  dense: true,
                                ),
                              )
                              .toList(),
                    ),
              ),
            ),

            // Configuración de impresora térmica
            GetBuilder<InvoicePrintController>(
              builder: (controller) {
                if (controller.selectedFormat == PrintFormat.thermal) {
                  return _buildConfigSection(
                    'Configuración Térmica',
                    Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Cortar papel'),
                          subtitle: const Text('Corte automático al final'),
                          value: controller.thermalSettings.autoCut,
                          onChanged:
                              (value) => controller.updateThermalSettings(
                                controller.thermalSettings.copyWith(
                                  autoCut: value,
                                ),
                              ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text('Código QR'),
                          subtitle: const Text('Incluir QR para consulta'),
                          value: controller.thermalSettings.includeQR,
                          onChanged:
                              (value) => controller.updateThermalSettings(
                                controller.thermalSettings.copyWith(
                                  includeQR: value,
                                ),
                              ),
                          dense: true,
                        ),
                        ListTile(
                          title: const Text('Copias'),
                          subtitle: Text(
                            '${controller.thermalSettings.copies} copia(s)',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed:
                                    controller.thermalSettings.copies > 1
                                        ? () =>
                                            controller.updateThermalSettings(
                                              controller.thermalSettings
                                                  .copyWith(
                                                    copies:
                                                        controller
                                                            .thermalSettings
                                                            .copies -
                                                        1,
                                                  ),
                                            )
                                        : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed:
                                    controller.thermalSettings.copies < 5
                                        ? () =>
                                            controller.updateThermalSettings(
                                              controller.thermalSettings
                                                  .copyWith(
                                                    copies:
                                                        controller
                                                            .thermalSettings
                                                            .copies +
                                                        1,
                                                  ),
                                            )
                                        : null,
                              ),
                            ],
                          ),
                          dense: true,
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Configuración de contenido
            _buildConfigSection(
              'Contenido',
              GetBuilder<InvoicePrintController>(
                builder:
                    (controller) => Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Logo de la empresa'),
                          value: controller.printSettings.includeLogo,
                          onChanged:
                              (value) => controller.updatePrintSettings(
                                controller.printSettings.copyWith(
                                  includeLogo: value,
                                ),
                              ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text('Términos y condiciones'),
                          value: controller.printSettings.includeTerms,
                          onChanged:
                              (value) => controller.updatePrintSettings(
                                controller.printSettings.copyWith(
                                  includeTerms: value,
                                ),
                              ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text('Notas adicionales'),
                          value: controller.printSettings.includeNotes,
                          onChanged:
                              (value) => controller.updatePrintSettings(
                                controller.printSettings.copyWith(
                                  includeNotes: value,
                                ),
                              ),
                          dense: true,
                        ),
                      ],
                    ),
              ),
            ),

            // Impresoras disponibles
            _buildConfigSection(
              'Impresoras',
              GetBuilder<InvoicePrintController>(
                builder:
                    (controller) => Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.print),
                          title: const Text('Impresora por defecto'),
                          subtitle: Text(
                            controller.selectedPrinter ?? 'No seleccionada',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => controller.selectPrinter(),
                          dense: true,
                        ),
                        ListTile(
                          leading: const Icon(Icons.refresh),
                          title: const Text('Buscar impresoras'),
                          onTap: () => controller.refreshPrinters(),
                          dense: true,
                        ),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        CustomCard(child: content),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPreview(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return GetBuilder<InvoicePrintController>(
      builder: (controller) {
        if (controller.selectedFormat == PrintFormat.thermal) {
          return _buildThermalPreview(context, controller);
        } else {
          return _buildPDFPreview(context, controller);
        }
      },
    );
  }

  Widget _buildThermalPreview(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: 320, // Simular ancho de 80mm
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildThermalContent(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildThermalContent(InvoicePrintController controller) {
    final invoice = controller.invoice!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo y header de empresa
        if (controller.printSettings.includeLogo) ...[
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business, size: 30),
          ),
          const SizedBox(height: 8),
        ],

        Text(
          'MI EMPRESA S.A.S.',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const Text('NIT: 900.123.456-7', style: TextStyle(fontSize: 12)),
        const Text('Ragonvalia, Colombia', style: TextStyle(fontSize: 12)),
        const Text('Tel: +57 300 123 4567', style: TextStyle(fontSize: 12)),

        const SizedBox(height: 16),
        const Divider(),

        // Información de la factura
        Text(
          'FACTURA DE VENTA',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('No:', style: TextStyle(fontSize: 12)),
            Text(invoice.number, style: const TextStyle(fontSize: 12)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Fecha:', style: TextStyle(fontSize: 12)),
            Text(
              '${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),

        const SizedBox(height: 12),
        const Divider(),

        // Cliente
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'CLIENTE:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            invoice.customerName,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        if (invoice.customerEmail?.isNotEmpty == true)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              invoice.customerEmail!,
              style: const TextStyle(fontSize: 10),
            ),
          ),

        const SizedBox(height: 12),
        const Divider(),

        // Items
        ...invoice.items.map((item) => _buildThermalItem(item)),

        const Divider(),

        // Totales
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal:', style: TextStyle(fontSize: 12)),
            Text(
              '\$${invoice.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),

        if (invoice.discountAmount > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Descuento:', style: TextStyle(fontSize: 12)),
              Text(
                '- \$${invoice.discountAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'IVA (${invoice.taxPercentage}%):',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '\$${invoice.taxAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),

        const Divider(),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              '\$${invoice.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Método de pago
        Text(
          'Método de pago: ${invoice.paymentMethodDisplayName}',
          style: const TextStyle(fontSize: 12),
        ),

        if (controller.thermalSettings.includeQR) ...[
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: const Center(
              child: Text('QR\nCODE', textAlign: TextAlign.center),
            ),
          ),
          const Text('Escanea para consultar', style: TextStyle(fontSize: 10)),
        ],

        if (controller.printSettings.includeTerms &&
            invoice.terms?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TÉRMINOS:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(invoice.terms!, style: const TextStyle(fontSize: 9)),
          ),
        ],

        const SizedBox(height: 16),
        const Text(
          'Gracias por su compra',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),

        if (controller.thermalSettings.autoCut) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.red),
          const Text(
            '✂️ CORTE AUTOMÁTICO',
            style: TextStyle(fontSize: 8, color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildThermalItem(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.description,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPDFPreview(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return FutureBuilder<pw.Document>(
      future: controller.generatePDF(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Generando vista previa...');
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('Error al generar vista previa: ${snapshot.error}'),
              ],
            ),
          );
        }

        return PdfPreview(
          build: (format) => snapshot.data!.save(),
          allowPrinting: true,
          allowSharing: true,
          canChangeOrientation: false,
          canDebug: false,
        );
      },
    );
  }

  Widget _buildPrintActions(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(child: _buildPrintButtons(context, controller)),
    );
  }

  // Widget _buildPrintButtons(
  //   BuildContext context,
  //   InvoicePrintController controller,
  // ) {
  //   return GetBuilder<InvoicePrintController>(
  //     builder:
  //         (controller) => Column(
  //           children: [
  //             // Botón principal de impresión
  //             CustomButton(
  //               text:
  //                   controller.isPrinting
  //                       ? 'Imprimiendo...'
  //                       : controller.selectedFormat == PrintFormat.thermal
  //                       ? 'Imprimir en Térmica'
  //                       : 'Imprimir',
  //               icon:
  //                   controller.selectedFormat == PrintFormat.thermal
  //                       ? Icons.receipt_long
  //                       : Icons.print,
  //               onPressed:
  //                   controller.isPrinting
  //                       ? null
  //                       : () => controller.printInvoice(),
  //               width: double.infinity,
  //               isLoading: controller.isPrinting,
  //             ),

  //             const SizedBox(height: 12),

  //             // Botones secundarios
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: CustomButton(
  //                     text: 'Vista Previa',
  //                     icon: Icons.preview,
  //                     type: ButtonType.outline,
  //                     onPressed: () => controller.showPreview(),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: CustomButton(
  //                     text: 'Guardar PDF',
  //                     icon: Icons.save,
  //                     type: ButtonType.outline,
  //                     onPressed: () => controller.savePDF(),
  //                   ),
  //                 ),
  //               ],
  //             ),

  //             if (controller.selectedFormat == PrintFormat.thermal &&
  //                 controller.thermalSettings.copies > 1) ...[
  //               const SizedBox(height: 8),
  //               Text(
  //                 'Se imprimirán ${controller.thermalSettings.copies} copias',
  //                 style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
  //               ),
  //             ],
  //           ],
  //         ),
  //   );
  // }

  Widget _buildPrintButtons(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return GetBuilder<InvoicePrintController>(
      builder:
          (controller) => Column(
            children: [
              // Botón principal de impresión
              CustomButton(
                text:
                    controller.isPrinting
                        ? 'Imprimiendo...'
                        : controller.selectedFormat == PrintFormat.thermal
                        ? 'Imprimir en Térmica'
                        : 'Imprimir',
                icon:
                    controller.selectedFormat == PrintFormat.thermal
                        ? Icons.receipt_long
                        : Icons.print,
                onPressed:
                    controller.isPrinting
                        ? null
                        : () => controller.printInvoice(), // ✅ CORREGIDO
                width: double.infinity,
                isLoading: controller.isPrinting,
              ),

              const SizedBox(height: 12),

              // Botones secundarios
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Vista Previa',
                      icon: Icons.preview,
                      type: ButtonType.outline,
                      onPressed: () => controller.showPreview(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Guardar PDF',
                      icon: Icons.save,
                      type: ButtonType.outline,
                      onPressed: () => controller.savePDF(),
                    ),
                  ),
                ],
              ),

              if (controller.selectedFormat == PrintFormat.thermal &&
                  controller.thermalSettings.copies > 1) ...[
                const SizedBox(height: 8),
                Text(
                  'Se imprimirán ${controller.thermalSettings.copies} copias',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
    );
  }

  // Widget _buildActionPanel(
  //   BuildContext context,
  //   InvoicePrintController controller,
  // ) {
  //   return Expanded(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
  //               const SizedBox(width: 8),
  //               Text(
  //                 'Acciones Rápidas',
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                   color: Theme.of(context).primaryColor,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 20),

  //           CustomButton(
  //             text: 'Imprimir Ahora',
  //             icon: Icons.print,
  //             onPressed: () => controller.printInvoice(),
  //             width: double.infinity,
  //           ),
  //           const SizedBox(height: 12),

  //           CustomButton(
  //             text: 'Enviar por Email',
  //             icon: Icons.email,
  //             type: ButtonType.outline,
  //             onPressed: () => controller.sendByEmail(),
  //             width: double.infinity,
  //           ),
  //           const SizedBox(height: 12),

  //           CustomButton(
  //             text: 'Compartir',
  //             icon: Icons.share,
  //             type: ButtonType.outline,
  //             onPressed: () => controller.share(),
  //             width: double.infinity,
  //           ),
  //           const SizedBox(height: 20),

  //           const Divider(),
  //           const SizedBox(height: 20),

  //           Text(
  //             'Historial de Impresión',
  //             style: TextStyle(
  //               fontWeight: FontWeight.bold,
  //               color: Colors.grey.shade800,
  //             ),
  //           ),
  //           const SizedBox(height: 12),

  //           GetBuilder<InvoicePrintController>(
  //             builder:
  //                 (controller) => Expanded(
  //                   child: ListView.builder(
  //                     itemCount: controller.printHistory.length,
  //                     itemBuilder: (context, index) {
  //                       final history = controller.printHistory[index];
  //                       return ListTile(
  //                         leading: Icon(
  //                           _getPrintTypeIcon(history.type),
  //                           color: Colors.grey.shade600,
  //                         ),
  //                         title: Text(
  //                           history.type,
  //                           style: const TextStyle(fontSize: 14),
  //                         ),
  //                         subtitle: Text(
  //                           _formatDateTime(history.timestamp),
  //                           style: const TextStyle(fontSize: 12),
  //                         ),
  //                         trailing:
  //                             history.success
  //                                 ? Icon(
  //                                   Icons.check_circle,
  //                                   color: Colors.green.shade600,
  //                                 )
  //                                 : Icon(
  //                                   Icons.error,
  //                                   color: Colors.red.shade600,
  //                                 ),
  //                         dense: true,
  //                       );
  //                     },
  //                   ),
  //                 ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildActionPanel(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            CustomButton(
              text: 'Imprimir Ahora',
              icon: Icons.print,
              onPressed: () => controller.printInvoice(), // ✅ CORREGIDO
              width: double.infinity,
            ),
            const SizedBox(height: 12),

            CustomButton(
              text: 'Enviar por Email',
              icon: Icons.email,
              type: ButtonType.outline,
              onPressed: () => controller.sendByEmail(),
              width: double.infinity,
            ),
            const SizedBox(height: 12),

            CustomButton(
              text: 'Compartir',
              icon: Icons.share,
              type: ButtonType.outline,
              onPressed: () => controller.share(),
              width: double.infinity,
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 20),

            Text(
              'Historial de Impresión',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),

            GetBuilder<InvoicePrintController>(
              builder:
                  (controller) => Expanded(
                    child: ListView.builder(
                      itemCount: controller.printHistory.length,
                      itemBuilder: (context, index) {
                        final history = controller.printHistory[index];
                        return ListTile(
                          leading: Icon(
                            _getPrintTypeIcon(history.type),
                            color: Colors.grey.shade600,
                          ),
                          title: Text(
                            history.type,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            _formatDateTime(history.timestamp),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing:
                              history.success
                                  ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade600,
                                  )
                                  : Icon(
                                    Icons.error,
                                    color: Colors.red.shade600,
                                  ),
                          dense: true,
                        );
                      },
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Error al cargar factura',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se pudo cargar la información de la factura',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          CustomButton(text: 'Volver', onPressed: () => Get.back()),
        ],
      ),
    );
  }

  // ==================== EVENT HANDLERS ====================

  void _handleMenuAction(
    String action,
    BuildContext context,
    InvoicePrintController controller,
  ) {
    switch (action) {
      case 'save_pdf':
        controller.savePDF();
        break;
      case 'email':
        controller.sendByEmail();
        break;
      case 'share':
        controller.share();
        break;
    }
  }

  // void _showPrintSettings(
  //   BuildContext context,
  //   InvoicePrintController controller,
  // ) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder:
  //         (context) => Container(
  //           height: MediaQuery.of(context).size.height * 0.8,
  //           decoration: const BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //           ),
  //           child: Column(
  //             children: [
  //               // Handle bar
  //               Container(
  //                 width: 40,
  //                 height: 4,
  //                 margin: const EdgeInsets.symmetric(vertical: 12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey.shade300,
  //                   borderRadius: BorderRadius.circular(2),
  //                 ),
  //               ),

  //               // Header
  //               Padding(
  //                 padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
  //                 child: Row(
  //                   children: [
  //                     Icon(
  //                       Icons.settings,
  //                       color: Theme.of(context).primaryColor,
  //                     ),
  //                     const SizedBox(width: 12),
  //                     Text(
  //                       'Configuración de Impresión',
  //                       style: TextStyle(
  //                         fontSize: 20,
  //                         fontWeight: FontWeight.bold,
  //                         color: Theme.of(context).primaryColor,
  //                       ),
  //                     ),
  //                     const Spacer(),
  //                     IconButton(
  //                       onPressed: () => Navigator.of(context).pop(),
  //                       icon: const Icon(Icons.close),
  //                     ),
  //                   ],
  //                 ),
  //               ),

  //               const Divider(height: 1),

  //               // Content
  //               Expanded(
  //                 child: SingleChildScrollView(
  //                   padding: const EdgeInsets.all(24),
  //                   child: GetBuilder<InvoicePrintController>(
  //                     builder:
  //                         (controller) => Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             // Formato de impresión
  //                             _buildSettingSection(
  //                               'Formato de Impresión',
  //                               Column(
  //                                 children:
  //                                     PrintFormat.values
  //                                         .map(
  //                                           (
  //                                             format,
  //                                           ) => RadioListTile<PrintFormat>(
  //                                             title: Text(format.displayName),
  //                                             subtitle: Text(
  //                                               format.description,
  //                                             ),
  //                                             value: format,
  //                                             groupValue:
  //                                                 controller.selectedFormat,
  //                                             onChanged: controller.setFormat,
  //                                             dense: true,
  //                                           ),
  //                                         )
  //                                         .toList(),
  //                               ),
  //                             ),

  //                             // Configuración térmica (solo si está seleccionada)
  //                             if (controller.selectedFormat ==
  //                                 PrintFormat.thermal) ...[
  //                               const SizedBox(height: 24),
  //                               _buildSettingSection(
  //                                 'Configuración Térmica',
  //                                 Column(
  //                                   children: [
  //                                     SwitchListTile(
  //                                       title: const Text(
  //                                         'Cortar papel automáticamente',
  //                                       ),
  //                                       subtitle: const Text(
  //                                         'Corte al final de la impresión',
  //                                       ),
  //                                       value:
  //                                           controller.thermalSettings.autoCut,
  //                                       onChanged:
  //                                           (value) => controller
  //                                               .updateThermalSettings(
  //                                                 controller.thermalSettings
  //                                                     .copyWith(autoCut: value),
  //                                               ),
  //                                       dense: true,
  //                                     ),
  //                                     SwitchListTile(
  //                                       title: const Text('Incluir código QR'),
  //                                       subtitle: const Text(
  //                                         'QR para consulta en línea',
  //                                       ),
  //                                       value:
  //                                           controller
  //                                               .thermalSettings
  //                                               .includeQR,
  //                                       onChanged:
  //                                           (value) => controller
  //                                               .updateThermalSettings(
  //                                                 controller.thermalSettings
  //                                                     .copyWith(
  //                                                       includeQR: value,
  //                                                     ),
  //                                               ),
  //                                       dense: true,
  //                                     ),
  //                                     SwitchListTile(
  //                                       title: const Text(
  //                                         'Abrir cajón de dinero',
  //                                       ),
  //                                       subtitle: const Text(
  //                                         'Si está conectado',
  //                                       ),
  //                                       value:
  //                                           controller
  //                                               .thermalSettings
  //                                               .openDrawer,
  //                                       onChanged:
  //                                           (value) => controller
  //                                               .updateThermalSettings(
  //                                                 controller.thermalSettings
  //                                                     .copyWith(
  //                                                       openDrawer: value,
  //                                                     ),
  //                                               ),
  //                                       dense: true,
  //                                     ),

  //                                     // Selector de copias
  //                                     ListTile(
  //                                       title: const Text('Número de copias'),
  //                                       subtitle: Text(
  //                                         '${controller.thermalSettings.copies} copia(s)',
  //                                       ),
  //                                       trailing: Row(
  //                                         mainAxisSize: MainAxisSize.min,
  //                                         children: [
  //                                           IconButton(
  //                                             icon: const Icon(
  //                                               Icons.remove_circle_outline,
  //                                             ),
  //                                             onPressed:
  //                                                 controller
  //                                                             .thermalSettings
  //                                                             .copies >
  //                                                         1
  //                                                     ? () => controller
  //                                                         .updateThermalSettings(
  //                                                           controller
  //                                                               .thermalSettings
  //                                                               .copyWith(
  //                                                                 copies:
  //                                                                     controller
  //                                                                         .thermalSettings
  //                                                                         .copies -
  //                                                                     1,
  //                                                               ),
  //                                                         )
  //                                                     : null,
  //                                           ),
  //                                           Container(
  //                                             width: 40,
  //                                             height: 40,
  //                                             decoration: BoxDecoration(
  //                                               border: Border.all(
  //                                                 color: Colors.grey.shade300,
  //                                               ),
  //                                               borderRadius:
  //                                                   BorderRadius.circular(8),
  //                                             ),
  //                                             child: Center(
  //                                               child: Text(
  //                                                 '${controller.thermalSettings.copies}',
  //                                                 style: const TextStyle(
  //                                                   fontWeight: FontWeight.bold,
  //                                                   fontSize: 16,
  //                                                 ),
  //                                               ),
  //                                             ),
  //                                           ),
  //                                           IconButton(
  //                                             icon: const Icon(
  //                                               Icons.add_circle_outline,
  //                                             ),
  //                                             onPressed:
  //                                                 controller
  //                                                             .thermalSettings
  //                                                             .copies <
  //                                                         10
  //                                                     ? () => controller
  //                                                         .updateThermalSettings(
  //                                                           controller
  //                                                               .thermalSettings
  //                                                               .copyWith(
  //                                                                 copies:
  //                                                                     controller
  //                                                                         .thermalSettings
  //                                                                         .copies +
  //                                                                     1,
  //                                                               ),
  //                                                         )
  //                                                     : null,
  //                                           ),
  //                                         ],
  //                                       ),
  //                                       dense: true,
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],

  //                             const SizedBox(height: 24),

  //                             // Configuración de contenido
  //                             _buildSettingSection(
  //                               'Contenido a Incluir',
  //                               Column(
  //                                 children: [
  //                                   SwitchListTile(
  //                                     title: const Text('Logo de la empresa'),
  //                                     subtitle: const Text(
  //                                       'Mostrar logo en el encabezado',
  //                                     ),
  //                                     value:
  //                                         controller.printSettings.includeLogo,
  //                                     onChanged:
  //                                         (value) =>
  //                                             controller.updatePrintSettings(
  //                                               controller.printSettings
  //                                                   .copyWith(
  //                                                     includeLogo: value,
  //                                                   ),
  //                                             ),
  //                                     dense: true,
  //                                   ),
  //                                   SwitchListTile(
  //                                     title: const Text(
  //                                       'Términos y condiciones',
  //                                     ),
  //                                     subtitle: const Text(
  //                                       'Incluir términos de la factura',
  //                                     ),
  //                                     value:
  //                                         controller.printSettings.includeTerms,
  //                                     onChanged:
  //                                         (value) =>
  //                                             controller.updatePrintSettings(
  //                                               controller.printSettings
  //                                                   .copyWith(
  //                                                     includeTerms: value,
  //                                                   ),
  //                                             ),
  //                                     dense: true,
  //                                   ),
  //                                   SwitchListTile(
  //                                     title: const Text('Notas adicionales'),
  //                                     subtitle: const Text(
  //                                       'Mostrar notas de la factura',
  //                                     ),
  //                                     value:
  //                                         controller.printSettings.includeNotes,
  //                                     onChanged:
  //                                         (value) =>
  //                                             controller.updatePrintSettings(
  //                                               controller.printSettings
  //                                                   .copyWith(
  //                                                     includeNotes: value,
  //                                                   ),
  //                                             ),
  //                                     dense: true,
  //                                   ),
  //                                   if (controller.selectedFormat !=
  //                                       PrintFormat.thermal)
  //                                     SwitchListTile(
  //                                       title: const Text('Código QR'),
  //                                       subtitle: const Text(
  //                                         'QR para consulta digital',
  //                                       ),
  //                                       value:
  //                                           controller.printSettings.includeQR,
  //                                       onChanged:
  //                                           (value) =>
  //                                               controller.updatePrintSettings(
  //                                                 controller.printSettings
  //                                                     .copyWith(
  //                                                       includeQR: value,
  //                                                     ),
  //                                               ),
  //                                       dense: true,
  //                                     ),
  //                                 ],
  //                               ),
  //                             ),

  //                             const SizedBox(height: 24),

  //                             // Configuración de impresora
  //                             _buildSettingSection(
  //                               'Impresora',
  //                               Column(
  //                                 children: [
  //                                   ListTile(
  //                                     leading: const Icon(Icons.print),
  //                                     title: const Text(
  //                                       'Impresora seleccionada',
  //                                     ),
  //                                     subtitle: Text(
  //                                       controller.selectedPrinter ??
  //                                           'Usar impresora por defecto',
  //                                     ),
  //                                     trailing: const Icon(
  //                                       Icons.arrow_forward_ios,
  //                                     ),
  //                                     onTap: () => controller.selectPrinter(),
  //                                     dense: true,
  //                                   ),
  //                                   ListTile(
  //                                     leading: const Icon(Icons.refresh),
  //                                     title: const Text('Buscar impresoras'),
  //                                     subtitle: Text(
  //                                       '${controller.availablePrinters.length} encontradas',
  //                                     ),
  //                                     trailing:
  //                                         controller.isLoading
  //                                             ? const SizedBox(
  //                                               width: 20,
  //                                               height: 20,
  //                                               child:
  //                                                   CircularProgressIndicator(
  //                                                     strokeWidth: 2,
  //                                                   ),
  //                                             )
  //                                             : const Icon(Icons.search),
  //                                     onTap:
  //                                         controller.isLoading
  //                                             ? null
  //                                             : () =>
  //                                                 controller.refreshPrinters(),
  //                                     dense: true,
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),

  //                             const SizedBox(height: 32),

  //                             // Botones de acción
  //                             Row(
  //                               children: [
  //                                 Expanded(
  //                                   child: CustomButton(
  //                                     text: 'Aplicar y Cerrar',
  //                                     icon: Icons.check,
  //                                     onPressed: () {
  //                                       Navigator.of(context).pop();
  //                                       Get.snackbar(
  //                                         'Éxito',
  //                                         'Configuración aplicada',
  //                                         snackPosition: SnackPosition.TOP,
  //                                         backgroundColor:
  //                                             Colors.green.shade100,
  //                                         colorText: Colors.green.shade800,
  //                                         icon: const Icon(
  //                                           Icons.check_circle,
  //                                           color: Colors.green,
  //                                         ),
  //                                         duration: const Duration(seconds: 2),
  //                                       );
  //                                     },
  //                                   ),
  //                                 ),
  //                                 const SizedBox(width: 16),
  //                                 Expanded(
  //                                   child: CustomButton(
  //                                     text: 'Imprimir Ahora',
  //                                     icon: Icons.print,
  //                                     type: ButtonType.outline,
  //                                     onPressed: () {
  //                                       Navigator.of(context).pop();
  //                                       controller.printInvoice();
  //                                     },
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ],
  //                         ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //   );
  // }

  void _showPrintSettings(
    BuildContext context,
    InvoicePrintController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Configuración de Impresión',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: GetBuilder<InvoicePrintController>(
                      builder:
                          (controller) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Formato de impresión
                              _buildSettingSection(
                                'Formato de Impresión',
                                Column(
                                  children:
                                      PrintFormat.values
                                          .map(
                                            (
                                              format,
                                            ) => RadioListTile<PrintFormat>(
                                              title: Text(format.displayName),
                                              subtitle: Text(
                                                format.description,
                                              ),
                                              value: format,
                                              groupValue:
                                                  controller.selectedFormat,
                                              onChanged: controller.setFormat,
                                              dense: true,
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),

                              // Configuración térmica (solo si está seleccionada)
                              if (controller.selectedFormat ==
                                  PrintFormat.thermal) ...[
                                const SizedBox(height: 24),
                                _buildSettingSection(
                                  'Configuración Térmica',
                                  Column(
                                    children: [
                                      SwitchListTile(
                                        title: const Text(
                                          'Cortar papel automáticamente',
                                        ),
                                        subtitle: const Text(
                                          'Corte al final de la impresión',
                                        ),
                                        value:
                                            controller.thermalSettings.autoCut,
                                        onChanged:
                                            (value) => controller
                                                .updateThermalSettings(
                                                  controller.thermalSettings
                                                      .copyWith(autoCut: value),
                                                ),
                                        dense: true,
                                      ),
                                      SwitchListTile(
                                        title: const Text('Incluir código QR'),
                                        subtitle: const Text(
                                          'QR para consulta en línea',
                                        ),
                                        value:
                                            controller
                                                .thermalSettings
                                                .includeQR,
                                        onChanged:
                                            (value) => controller
                                                .updateThermalSettings(
                                                  controller.thermalSettings
                                                      .copyWith(
                                                        includeQR: value,
                                                      ),
                                                ),
                                        dense: true,
                                      ),
                                      SwitchListTile(
                                        title: const Text(
                                          'Abrir cajón de dinero',
                                        ),
                                        subtitle: const Text(
                                          'Si está conectado',
                                        ),
                                        value:
                                            controller
                                                .thermalSettings
                                                .openDrawer,
                                        onChanged:
                                            (value) => controller
                                                .updateThermalSettings(
                                                  controller.thermalSettings
                                                      .copyWith(
                                                        openDrawer: value,
                                                      ),
                                                ),
                                        dense: true,
                                      ),

                                      // Selector de copias
                                      ListTile(
                                        title: const Text('Número de copias'),
                                        subtitle: Text(
                                          '${controller.thermalSettings.copies} copia(s)',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              onPressed:
                                                  controller
                                                              .thermalSettings
                                                              .copies >
                                                          1
                                                      ? () => controller
                                                          .updateThermalSettings(
                                                            controller
                                                                .thermalSettings
                                                                .copyWith(
                                                                  copies:
                                                                      controller
                                                                          .thermalSettings
                                                                          .copies -
                                                                      1,
                                                                ),
                                                          )
                                                      : null,
                                            ),
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${controller.thermalSettings.copies}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              onPressed:
                                                  controller
                                                              .thermalSettings
                                                              .copies <
                                                          10
                                                      ? () => controller
                                                          .updateThermalSettings(
                                                            controller
                                                                .thermalSettings
                                                                .copyWith(
                                                                  copies:
                                                                      controller
                                                                          .thermalSettings
                                                                          .copies +
                                                                      1,
                                                                ),
                                                          )
                                                      : null,
                                            ),
                                          ],
                                        ),
                                        dense: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Configuración de contenido
                              _buildSettingSection(
                                'Contenido a Incluir',
                                Column(
                                  children: [
                                    SwitchListTile(
                                      title: const Text('Logo de la empresa'),
                                      subtitle: const Text(
                                        'Mostrar logo en el encabezado',
                                      ),
                                      value:
                                          controller.printSettings.includeLogo,
                                      onChanged:
                                          (value) =>
                                              controller.updatePrintSettings(
                                                controller.printSettings
                                                    .copyWith(
                                                      includeLogo: value,
                                                    ),
                                              ),
                                      dense: true,
                                    ),
                                    SwitchListTile(
                                      title: const Text(
                                        'Términos y condiciones',
                                      ),
                                      subtitle: const Text(
                                        'Incluir términos de la factura',
                                      ),
                                      value:
                                          controller.printSettings.includeTerms,
                                      onChanged:
                                          (value) =>
                                              controller.updatePrintSettings(
                                                controller.printSettings
                                                    .copyWith(
                                                      includeTerms: value,
                                                    ),
                                              ),
                                      dense: true,
                                    ),
                                    SwitchListTile(
                                      title: const Text('Notas adicionales'),
                                      subtitle: const Text(
                                        'Mostrar notas de la factura',
                                      ),
                                      value:
                                          controller.printSettings.includeNotes,
                                      onChanged:
                                          (value) =>
                                              controller.updatePrintSettings(
                                                controller.printSettings
                                                    .copyWith(
                                                      includeNotes: value,
                                                    ),
                                              ),
                                      dense: true,
                                    ),
                                    if (controller.selectedFormat !=
                                        PrintFormat.thermal)
                                      SwitchListTile(
                                        title: const Text('Código QR'),
                                        subtitle: const Text(
                                          'QR para consulta digital',
                                        ),
                                        value:
                                            controller.printSettings.includeQR,
                                        onChanged:
                                            (value) =>
                                                controller.updatePrintSettings(
                                                  controller.printSettings
                                                      .copyWith(
                                                        includeQR: value,
                                                      ),
                                                ),
                                        dense: true,
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Configuración de impresora
                              _buildSettingSection(
                                'Impresora',
                                Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.print),
                                      title: const Text(
                                        'Impresora seleccionada',
                                      ),
                                      subtitle: Text(
                                        controller.selectedPrinter ??
                                            'Usar impresora por defecto',
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                      ),
                                      onTap: () => controller.selectPrinter(),
                                      dense: true,
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.refresh),
                                      title: const Text('Buscar impresoras'),
                                      subtitle: Text(
                                        '${controller.availablePrinters.length} encontradas',
                                      ),
                                      trailing:
                                          controller.isLoading
                                              ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                              : const Icon(Icons.search),
                                      onTap:
                                          controller.isLoading
                                              ? null
                                              : () =>
                                                  controller.refreshPrinters(),
                                      dense: true,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Botones de acción
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Aplicar y Cerrar',
                                      icon: Icons.check,
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Get.snackbar(
                                          'Éxito',
                                          'Configuración aplicada',
                                          snackPosition: SnackPosition.TOP,
                                          backgroundColor:
                                              Colors.green.shade100,
                                          colorText: Colors.green.shade800,
                                          icon: const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                          duration: const Duration(seconds: 2),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Imprimir Ahora',
                                      icon: Icons.print,
                                      type: ButtonType.outline,
                                      onPressed: () {
                                        // ✅ CORREGIDO
                                        Navigator.of(context).pop();
                                        controller.printInvoice();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSettingSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        CustomCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: content,
        ),
      ],
    );
  }

  // ==================== HELPER FUNCTIONS ====================

  /// Obtener icono según el tipo de impresión para el historial
  IconData _getPrintTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'impresión térmica':
      case 'impresión thermal':
        return Icons.receipt_long;
      case 'impresión a4':
      case 'impresión letter':
        return Icons.description;
      case 'vista previa':
        return Icons.preview;
      case 'guardar pdf':
        return Icons.save;
      case 'envío por email':
        return Icons.email;
      case 'compartir':
        return Icons.share;
      default:
        return Icons.print;
    }
  }

  /// Formatear fecha y hora para mostrar en el historial
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }
}
