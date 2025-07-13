// lib/features/invoices/presentation/screens/invoice_detail_screen.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../../app/core/utils/responsive.dart';
// import '../../../../app/shared/widgets/custom_button.dart';
// import '../../../../app/shared/widgets/custom_card.dart';
// import '../../../../app/shared/widgets/custom_text_field.dart';
// import '../../../../app/shared/widgets/loading_widget.dart';
// import '../controllers/invoice_detail_controller.dart';
// import '../bindings/invoice_binding.dart';
// import '../widgets/invoice_status_widget.dart';
// import '../widgets/invoice_payment_form_widget.dart';
// import '../widgets/invoice_items_list_widget.dart';
// import '../../domain/entities/invoice.dart';

// class InvoiceDetailScreen extends StatelessWidget {
//   const InvoiceDetailScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Registrar controlador específico para esta pantalla
//     InvoiceBinding.registerDetailController();
//     final controller = Get.find<InvoiceDetailController>();

//     return Scaffold(
//       appBar: _buildAppBar(context, controller),
//       body: GetBuilder<InvoiceDetailController>(
//         builder: (controller) {
//           if (controller.isLoading) {
//             return const LoadingWidget(message: 'Cargando factura...');
//           }

//           if (!controller.hasInvoice) {
//             return _buildErrorState(context);
//           }

//           return ResponsiveLayout(
//             mobile: _buildMobileLayout(context, controller),
//             tablet: _buildTabletLayout(context, controller),
//             desktop: _buildDesktopLayout(context, controller),
//           );
//         },
//       ),
//       floatingActionButton: _buildFloatingActionButton(context, controller),
//       bottomNavigationBar: _buildBottomActions(context, controller),
//     );
//   }

//   // ==================== APP BAR ====================

//   PreferredSizeWidget _buildAppBar(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     return AppBar(
//       title: GetBuilder<InvoiceDetailController>(
//         builder:
//             (controller) => Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   controller.invoice?.number ?? 'Factura',
//                   style: const TextStyle(fontSize: 18),
//                 ),
//                 if (controller.hasInvoice)
//                   Text(
//                     controller.invoice!.customerName,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.normal,
//                     ),
//                   ),
//               ],
//             ),
//       ),
//       elevation: 0,
//       actions: [
//         // Refrescar
//         IconButton(
//           icon: const Icon(Icons.refresh),
//           onPressed: () => controller.refreshInvoice(),
//           tooltip: 'Refrescar',
//         ),

//         // Editar
//         GetBuilder<InvoiceDetailController>(
//           builder:
//               (controller) => IconButton(
//                 icon: const Icon(Icons.edit),
//                 onPressed:
//                     controller.canEdit ? controller.goToEditInvoice : null,
//                 tooltip: 'Editar',
//               ),
//         ),

//         // Imprimir
//         GetBuilder<InvoiceDetailController>(
//           builder:
//               (controller) => IconButton(
//                 icon: const Icon(Icons.print),
//                 onPressed:
//                     controller.canPrint ? controller.goToPrintInvoice : null,
//                 tooltip: 'Imprimir',
//               ),
//         ),

//         // Menú de opciones
//         GetBuilder<InvoiceDetailController>(
//           builder:
//               (controller) => PopupMenuButton<String>(
//                 onSelected:
//                     (value) => _handleMenuAction(value, context, controller),
//                 itemBuilder:
//                     (context) => [
//                       PopupMenuItem(
//                         value: 'print',
//                         enabled: controller.canPrint,
//                         child: const Row(
//                           children: [
//                             Icon(Icons.print),
//                             SizedBox(width: 8),
//                             Text('Imprimir'),
//                           ],
//                         ),
//                       ),
//                       PopupMenuItem(
//                         value: 'share',
//                         enabled: controller.hasInvoice,
//                         child: const Row(
//                           children: [
//                             Icon(Icons.share),
//                             SizedBox(width: 8),
//                             Text('Compartir'),
//                           ],
//                         ),
//                       ),
//                       PopupMenuItem(
//                         value: 'duplicate',
//                         enabled: controller.hasInvoice,
//                         child: const Row(
//                           children: [
//                             Icon(Icons.copy),
//                             SizedBox(width: 8),
//                             Text('Duplicar'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuDivider(),
//                       PopupMenuItem(
//                         value: 'confirm',
//                         enabled: controller.canConfirm,
//                         child: const Row(
//                           children: [
//                             Icon(Icons.check_circle, color: Colors.green),
//                             SizedBox(width: 8),
//                             Text('Confirmar'),
//                           ],
//                         ),
//                       ),
//                       PopupMenuItem(
//                         value: 'cancel',
//                         enabled: controller.canCancel,
//                         child: const Row(
//                           children: [
//                             Icon(Icons.cancel, color: Colors.orange),
//                             SizedBox(width: 8),
//                             Text('Cancelar'),
//                           ],
//                         ),
//                       ),
//                       PopupMenuItem(
//                         value: 'delete',
//                         enabled: controller.canDelete,
//                         child: const Row(
//                           children: [
//                             Icon(Icons.delete, color: Colors.red),
//                             SizedBox(width: 8),
//                             Text('Eliminar'),
//                           ],
//                         ),
//                       ),
//                     ],
//               ),
//         ),
//       ],
//     );
//   }

//   // ==================== LAYOUTS ====================

//   Widget _buildMobileLayout(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     final invoice = controller.invoice!;

//     return SingleChildScrollView(
//       padding: context.responsivePadding,
//       child: Column(
//         children: [
//           // Estado y resumen
//           _buildStatusCard(context, controller),
//           SizedBox(height: context.verticalSpacing),

//           // Información del cliente
//           _buildCustomerCard(context, controller),
//           SizedBox(height: context.verticalSpacing),

//           // Items
//           _buildItemsCard(context, controller),
//           SizedBox(height: context.verticalSpacing),

//           // Totales
//           _buildTotalsCard(context, controller),
//           SizedBox(height: context.verticalSpacing),

//           // Información adicional
//           if (invoice.notes?.isNotEmpty == true ||
//               invoice.terms?.isNotEmpty == true)
//             _buildAdditionalInfoCard(context, controller),

//           // Formulario de pago (si está visible)
//           GetBuilder<InvoiceDetailController>(
//             builder: (controller) {
//               if (controller.showPaymentForm) {
//                 return Column(
//                   children: [
//                     SizedBox(height: context.verticalSpacing),
//                     _buildPaymentForm(context, controller),
//                   ],
//                 );
//               }
//               return const SizedBox.shrink();
//             },
//           ),

//           // Espacio para el bottom bar
//           SizedBox(height: context.verticalSpacing * 4),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabletLayout(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     return SingleChildScrollView(
//       child: AdaptiveContainer(
//         maxWidth: 1000,
//         child: Column(
//           children: [
//             SizedBox(height: context.verticalSpacing),

//             // Estado y resumen
//             CustomCard(child: _buildStatusContent(context, controller)),
//             SizedBox(height: context.verticalSpacing),

//             // Cliente e información en fila
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: CustomCard(
//                     child: _buildCustomerContent(context, controller),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: CustomCard(
//                     child: _buildInvoiceInfoContent(context, controller),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: context.verticalSpacing),

//             // Items
//             CustomCard(child: _buildItemsContent(context, controller)),
//             SizedBox(height: context.verticalSpacing),

//             // Totales y formulario de pago en fila
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: CustomCard(
//                     child: _buildTotalsContent(context, controller),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: GetBuilder<InvoiceDetailController>(
//                     builder: (controller) {
//                       if (controller.showPaymentForm) {
//                         return CustomCard(
//                           child: _buildPaymentFormContent(context, controller),
//                         );
//                       }
//                       return CustomCard(
//                         child: _buildActionsContent(context, controller),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: context.verticalSpacing),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDesktopLayout(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     return Row(
//       children: [
//         // Contenido principal
//         Expanded(
//           flex: 3,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(32.0),
//             child: Column(
//               children: [
//                 // Estado
//                 CustomCard(child: _buildStatusContent(context, controller)),
//                 const SizedBox(height: 24),

//                 // Cliente e información
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: CustomCard(
//                         child: _buildCustomerContent(context, controller),
//                       ),
//                     ),
//                     const SizedBox(width: 24),
//                     Expanded(
//                       child: CustomCard(
//                         child: _buildInvoiceInfoContent(context, controller),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

//                 // Items
//                 CustomCard(child: _buildItemsContent(context, controller)),
//                 const SizedBox(height: 24),

//                 // Información adicional
//                 CustomCard(
//                   child: _buildAdditionalInfoContent(context, controller),
//                 ),
//               ],
//             ),
//           ),
//         ),

//         // Panel lateral
//         Container(
//           width: 400,
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             border: Border(left: BorderSide(color: Colors.grey.shade300)),
//           ),
//           child: Column(
//             children: [
//               // Header del panel
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).primaryColor.withOpacity(0.1),
//                   border: Border(
//                     bottom: BorderSide(color: Colors.grey.shade300),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(Icons.receipt, color: Theme.of(context).primaryColor),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Resumen de Factura',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Totales
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: _buildTotalsContent(context, controller),
//               ),

//               // Formulario de pago o acciones
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: GetBuilder<InvoiceDetailController>(
//                     builder: (controller) {
//                       if (controller.showPaymentForm) {
//                         return _buildPaymentFormContent(context, controller);
//                       }
//                       return _buildActionsContent(context, controller);
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // ==================== CONTENT SECTIONS ====================

//   Widget _buildStatusCard(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     return CustomCard(child: _buildStatusContent(context, controller));
//   }

//   Widget _buildStatusContent(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     final invoice = controller.invoice!;

//     return Column(
//       children: [
//         InvoiceStatusWidget(invoice: invoice, showDescription: true),

//         if (controller.isOverdue) ...[
//           const SizedBox(height: 16),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.red.shade50,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.red.shade200),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.warning, color: Colors.red.shade600),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Factura vencida hace ${controller.daysOverdue} días',
//                     style: TextStyle(
//                       color: Colors.red.shade800,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _buildCustomerCard(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     return CustomCard(child: _buildCustomerContent(context, controller));
//   }

//   Widget _buildCustomerContent(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     final invoice = controller.invoice!;
//     final customer = invoice.customer;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               'Cliente',
//               style: TextStyle(
//                 fontSize: Responsive.getFontSize(
//                   context,
//                   mobile: 18,
//                   tablet: 20,
//                 ),
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const Spacer(),
//             if (customer != null)
//               CustomButton(
//                 text: 'Ver Cliente',
//                 icon: Icons.person,
//                 type: ButtonType.outline,
//                 onPressed: controller.goToCustomerDetail,
//               ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         if (customer != null) ...[
//           _buildInfoRow('Nombre', invoice.customerName),
//           if (customer.email?.isNotEmpty == true)
//             _buildInfoRow('Email', customer.email!),
//           if (customer.phone?.isNotEmpty == true)
//             _buildInfoRow('Teléfono', customer.phone!),
//           if (customer.address?.isNotEmpty == true)
//             _buildInfoRow('Dirección', customer.address!),
//         ] else
//           Text(
//             'Información del cliente no disponible',
//             style: TextStyle(color: Colors.grey.shade600),
//           ),
//       ],
//     );
//   }

//   Widget _buildInvoiceInfoContent(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     final invoice = controller.invoice!;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Información de la Factura',
//           style: TextStyle(
//             fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),

//         _buildInfoRow('Número', invoice.number),
//         _buildInfoRow(
//           'Fecha',
//           '${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
//         ),
//         _buildInfoRow(
//           'Vencimiento',
//           '${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
//         ),
//         _buildInfoRow('Método de Pago', invoice.paymentMethodDisplayName),
//         _buildInfoRow('Creada por', invoice.createdBy?.firstName ?? 'N/A'),
//       ],
//     );
//   }

//   Widget _buildItemsCard(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     return CustomCard(child: _buildItemsContent(context, controller));
//   }

//   Widget _buildItemsContent(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     final invoice = controller.invoice!;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Items de la Factura',
//           style: TextStyle(
//             fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
//             fontWeight: FontWeight.bold,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 16),

//         InvoiceItemsListWidget(
//           items: invoice.items,
//           onItemTap: (item) {
//             if (item.productId != null) {
//               controller.goToProductDetail(item.productId);
//             }
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildTotalsCard(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     return CustomCard(child: _buildTotalsContent(context, controller));
//   }

//   Widget _buildTotalsContent(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     final invoice = controller.invoice!;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Totales',
//           style: TextStyle(
//             fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),

//         _buildTotalRow('Subtotal', invoice.subtotal),

//         if (invoice.discountAmount > 0 || invoice.discountPercentage > 0) ...[
//           if (invoice.discountPercentage > 0)
//             _buildTotalRow(
//               'Descuento (${invoice.discountPercentage}%)',
//               -invoice.discountAmount,
//             ),
//           if (invoice.discountAmount > 0 && invoice.discountPercentage == 0)
//             _buildTotalRow('Descuento', -invoice.discountAmount),
//         ],

//         _buildTotalRow(
//           'Impuestos (${invoice.taxPercentage}%)',
//           invoice.taxAmount,
//         ),

//         const Divider(),
//         _buildTotalRow('Total', invoice.total, isTotal: true),

//         if (invoice.paidAmount > 0) ...[
//           const SizedBox(height: 8),
//           _buildTotalRow('Pagado', invoice.paidAmount, color: Colors.green),
//           _buildTotalRow(
//             'Saldo Pendiente',
//             invoice.balanceDue,
//             color: invoice.balanceDue > 0 ? Colors.red : Colors.green,
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _buildAdditionalInfoCard(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     return CustomCard(child: _buildAdditionalInfoContent(context, controller));
//   }

//   Widget _buildAdditionalInfoContent(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     final invoice = controller.invoice!;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Información Adicional',
//           style: TextStyle(
//             fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),

//         if (invoice.notes?.isNotEmpty == true) ...[
//           Text('Notas:', style: const TextStyle(fontWeight: FontWeight.w500)),
//           const SizedBox(height: 4),
//           Text(invoice.notes!),
//           const SizedBox(height: 16),
//         ],

//         if (invoice.terms?.isNotEmpty == true) ...[
//           Text(
//             'Términos y Condiciones:',
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//           const SizedBox(height: 4),
//           Text(invoice.terms!),
//         ],
//       ],
//     );
//   }

//   Widget _buildPaymentForm(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     return CustomCard(child: _buildPaymentFormContent(context, controller));
//   }

//   Widget _buildPaymentFormContent(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     return InvoicePaymentFormWidget(
//       controller: controller,
//       onCancel: controller.hidePaymentForm,
//       onSubmit: controller.addPayment,
//     );
//   }

//   Widget _buildActionsContent(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Acciones',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 16),

//         // Agregar pago
//         if (controller.canAddPayment) ...[
//           CustomButton(
//             text: 'Agregar Pago',
//             icon: Icons.payment,
//             onPressed: controller.togglePaymentForm, // ✅ Corregido
//             width: double.infinity,
//           ),
//           const SizedBox(height: 12),
//         ],

//         // Confirmar
//         if (controller.canConfirm) ...[
//           CustomButton(
//             text: 'Confirmar Factura',
//             icon: Icons.check_circle,
//             onPressed: controller.confirmInvoice,
//             width: double.infinity,
//           ),
//           const SizedBox(height: 12),
//         ],

//         // Editar
//         if (controller.canEdit) ...[
//           CustomButton(
//             text: 'Editar',
//             icon: Icons.edit,
//             type: ButtonType.outline,
//             onPressed: controller.goToEditInvoice,
//             width: double.infinity,
//           ),
//           const SizedBox(height: 12),
//         ],

//         // Imprimir
//         if (controller.canPrint) ...[
//           CustomButton(
//             text: 'Imprimir',
//             icon: Icons.print,
//             type: ButtonType.outline,
//             onPressed: controller.goToPrintInvoice,
//             width: double.infinity,
//           ),
//           const SizedBox(height: 12),
//         ],

//         // Compartir
//         CustomButton(
//           text: 'Compartir',
//           icon: Icons.share,
//           type: ButtonType.outline,
//           onPressed: controller.shareInvoice,
//           width: double.infinity,
//         ),
//         const SizedBox(height: 12),

//         // Duplicar
//         CustomButton(
//           text: 'Duplicar',
//           icon: Icons.copy,
//           type: ButtonType.outline,
//           onPressed: controller.duplicateInvoice,
//           width: double.infinity,
//         ),

//         if (controller.canCancel || controller.canDelete) ...[
//           const SizedBox(height: 16),
//           const Divider(),
//           const SizedBox(height: 16),

//           // Cancelar
//           if (controller.canCancel) ...[
//             CustomButton(
//               text: 'Cancelar Factura',
//               icon: Icons.cancel,
//               type: ButtonType.outline,
//               onPressed: controller.cancelInvoice,
//               width: double.infinity,
//               textColor: Colors.orange,
//             ),
//             const SizedBox(height: 12),
//           ],

//           // Eliminar
//           if (controller.canDelete) ...[
//             CustomButton(
//               text: 'Eliminar',
//               icon: Icons.delete,
//               type: ButtonType.outline,
//               onPressed: controller.deleteInvoice,
//               width: double.infinity,
//               textColor: Colors.red,
//             ),
//           ],
//         ],
//       ],
//     );
//   }

//   // ==================== UTILITY WIDGETS ====================

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               '$label:',
//               style: TextStyle(
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey.shade700,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w400,
//                 color: Colors.black54,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTotalRow(
//     String label,
//     double amount, {
//     bool isTotal = false,
//     Color? color,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
//               fontSize: isTotal ? 16 : 14,
//               color: color,
//             ),
//           ),
//           Text(
//             AppFormatters.formatCurrency(amount),
//             style: TextStyle(
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
//               fontSize: isTotal ? 16 : 14,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorState(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
//           const SizedBox(height: 16),
//           Text(
//             'Factura no encontrada',
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey.shade600,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'La factura que buscas no existe o fue eliminada',
//             style: TextStyle(color: Colors.grey.shade500),
//           ),
//           const SizedBox(height: 24),
//           CustomButton(
//             text: 'Volver a Facturas',
//             onPressed: () => Get.offAllNamed('/invoices'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ==================== ACTION BUTTONS ====================

//   Widget? _buildFloatingActionButton(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     if (!context.isMobile) return null;

//     return GetBuilder<InvoiceDetailController>(
//       builder: (controller) {
//         if (controller.showPaymentForm) {
//           return FloatingActionButton(
//             onPressed: controller.hidePaymentForm, // ✅ Corregido
//             backgroundColor: Colors.grey,
//             child: const Icon(Icons.close),
//           );
//         }

//         if (controller.canAddPayment) {
//           return FloatingActionButton.extended(
//             onPressed: controller.togglePaymentForm, // ✅ Corregido
//             icon: const Icon(Icons.payment),
//             label: const Text('Agregar Pago'),
//           );
//         }

//         if (controller.canPrint) {
//           return FloatingActionButton(
//             onPressed: controller.goToPrintInvoice,
//             child: const Icon(Icons.print),
//           );
//         }

//         return const SizedBox.shrink(); // ✅ Corregido
//       },
//     );
//   }

//   Widget? _buildBottomActions(
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     if (!context.isMobile) return null;

//     return GetBuilder<InvoiceDetailController>(
//       builder: (controller) {
//         if (controller.showPaymentForm)
//           return const SizedBox.shrink(); // ✅ Corregido

//         return Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             border: Border(top: BorderSide(color: Colors.grey.shade300)),
//           ),
//           child: SafeArea(
//             child: Row(
//               children: [
//                 if (controller.canEdit) ...[
//                   Expanded(
//                     child: CustomButton(
//                       text: 'Editar',
//                       icon: Icons.edit,
//                       type: ButtonType.outline,
//                       onPressed: controller.goToEditInvoice,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                 ],

//                 if (controller.canConfirm) ...[
//                   Expanded(
//                     flex: 2,
//                     child: CustomButton(
//                       text: 'Confirmar',
//                       icon: Icons.check_circle,
//                       onPressed: controller.confirmInvoice,
//                     ),
//                   ),
//                 ] else if (controller.canPrint) ...[
//                   Expanded(
//                     flex: 2,
//                     child: CustomButton(
//                       text: 'Imprimir',
//                       icon: Icons.print,
//                       onPressed: controller.goToPrintInvoice,
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ==================== EVENT HANDLERS ====================

//   void _handleMenuAction(
//     String action,
//     BuildContext context,
//     InvoiceDetailController controller,
//   ) {
//     switch (action) {
//       case 'print':
//         controller.goToPrintInvoice();
//         break;
//       case 'share':
//         controller.shareInvoice();
//         break;
//       case 'duplicate':
//         controller.duplicateInvoice();
//         break;
//       case 'confirm':
//         controller.confirmInvoice();
//         break;
//       case 'cancel':
//         controller.cancelInvoice();
//         break;
//       case 'delete':
//         controller.deleteInvoice();
//         break;
//     }
//   }
// }

// =========== Invoice Detail Screen ============

// =========== Invoice Detail Screen ============

//lib/features/invoices/presentation/screens/invoice_detail_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/invoice_detail_controller.dart';
import '../bindings/invoice_binding.dart';
import '../widgets/invoice_status_widget.dart';
import '../widgets/invoice_payment_form_widget.dart';
import '../widgets/invoice_items_list_widget.dart';
import '../../domain/entities/invoice.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Registrar controlador específico para esta pantalla
    InvoiceBinding.registerDetailController();
    final controller = Get.find<InvoiceDetailController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildModernAppBar(context, controller),
      body: GetBuilder<InvoiceDetailController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const LoadingWidget(message: 'Cargando factura...');
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
      floatingActionButton: _buildFloatingActionButton(context, controller),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return AppBar(
      title: GetBuilder<InvoiceDetailController>(
        builder:
            (controller) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.invoice?.number ?? 'Factura',
                  style: const TextStyle(fontSize: 18),
                ),
                if (controller.hasInvoice)
                  Text(
                    controller.invoice!.customerName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
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
        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => controller.refreshInvoice(),
          tooltip: 'Refrescar',
        ),

        // Editar
        GetBuilder<InvoiceDetailController>(
          builder:
              (controller) => IconButton(
                icon: const Icon(Icons.edit),
                onPressed:
                    controller.canEdit ? controller.goToEditInvoice : null,
                tooltip: 'Editar',
              ),
        ),

        // Imprimir
        GetBuilder<InvoiceDetailController>(
          builder:
              (controller) => IconButton(
                icon: const Icon(Icons.print),
                onPressed:
                    controller.canPrint ? controller.goToPrintInvoice : null,
                tooltip: 'Imprimir',
              ),
        ),

        // Menú de opciones
        GetBuilder<InvoiceDetailController>(
          builder:
              (controller) => PopupMenuButton<String>(
                onSelected:
                    (value) => _handleMenuAction(value, context, controller),
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'print',
                        enabled: controller.canPrint,
                        child: const Row(
                          children: [
                            Icon(Icons.print),
                            SizedBox(width: 8),
                            Text('Imprimir'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        enabled: controller.hasInvoice,
                        child: const Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('Compartir'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        enabled: controller.hasInvoice,
                        child: const Row(
                          children: [
                            Icon(Icons.copy),
                            SizedBox(width: 8),
                            Text('Duplicar'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'confirm',
                        enabled: controller.canConfirm,
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Confirmar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'cancel',
                        enabled: controller.canCancel,
                        child: const Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Cancelar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        enabled: controller.canDelete,
                        child: const Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
              ),
        ),
      ],
    );
  }

  // ==================== LAYOUTS ====================

  Widget _buildMobileLayout(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;

    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        children: [
          // Estado y resumen
          _buildStatusCard(context, controller),
          SizedBox(height: context.verticalSpacing),

          // Información del cliente
          _buildCustomerCard(context, controller),
          SizedBox(height: context.verticalSpacing),

          // Items
          _buildItemsCard(context, controller),
          SizedBox(height: context.verticalSpacing),

          // Totales
          _buildTotalsCard(context, controller),
          SizedBox(height: context.verticalSpacing),

          // Información adicional
          if (invoice.notes?.isNotEmpty == true ||
              invoice.terms?.isNotEmpty == true)
            _buildAdditionalInfoCard(context, controller),

          // Formulario de pago (si está visible)
          GetBuilder<InvoiceDetailController>(
            builder: (controller) {
              if (controller.showPaymentForm) {
                return Column(
                  children: [
                    SizedBox(height: context.verticalSpacing),
                    _buildPaymentForm(context, controller),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Espacio para el bottom bar
          SizedBox(height: context.verticalSpacing * 4),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return SingleChildScrollView(
      child: AdaptiveContainer(
        maxWidth: 1000,
        child: Column(
          children: [
            SizedBox(height: context.verticalSpacing),

            // Estado y resumen
            CustomCard(child: _buildStatusContent(context, controller)),
            SizedBox(height: context.verticalSpacing),

            // Cliente e información en fila
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomCard(
                    child: _buildCustomerContent(context, controller),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomCard(
                    child: _buildInvoiceInfoContent(context, controller),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),

            // Items
            CustomCard(child: _buildItemsContent(context, controller)),
            SizedBox(height: context.verticalSpacing),

            // Totales y formulario de pago en fila
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomCard(
                    child: _buildTotalsContent(context, controller),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GetBuilder<InvoiceDetailController>(
                    builder: (controller) {
                      if (controller.showPaymentForm) {
                        return CustomCard(
                          child: _buildPaymentFormContent(context, controller),
                        );
                      }
                      return CustomCard(
                        child: _buildActionsContent(context, controller),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                // Estado
                CustomCard(child: _buildStatusContent(context, controller)),
                const SizedBox(height: 24),

                // Cliente e información
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomCard(
                        child: _buildCustomerContent(context, controller),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: CustomCard(
                        child: _buildInvoiceInfoContent(context, controller),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Items
                CustomCard(child: _buildItemsContent(context, controller)),
                const SizedBox(height: 24),

                // Información adicional
                CustomCard(
                  child: _buildAdditionalInfoContent(context, controller),
                ),
              ],
            ),
          ),
        ),

        // Panel lateral
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              // Header del panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Resumen de Factura',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Totales
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildTotalsContent(context, controller),
              ),

              // Formulario de pago o acciones
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GetBuilder<InvoiceDetailController>(
                    builder: (controller) {
                      if (controller.showPaymentForm) {
                        return _buildPaymentFormContent(context, controller);
                      }
                      return _buildActionsContent(context, controller);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== CONTENT SECTIONS ====================

  Widget _buildStatusCard(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildStatusContent(context, controller));
  }

  Widget _buildStatusContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;

    return Column(
      children: [
        InvoiceStatusWidget(invoice: invoice, showDescription: true),

        if (controller.isOverdue) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Factura vencida hace ${controller.daysOverdue} días',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildCustomerContent(context, controller));
  }

  Widget _buildCustomerContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;
    final customer = invoice.customer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Cliente',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            if (customer != null)
              CustomButton(
                text: 'Ver Cliente',
                icon: Icons.person,
                type: ButtonType.outline,
                onPressed: controller.goToCustomerDetail,
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (customer != null) ...[
          _buildInfoRow('Nombre', invoice.customerName),
          if (customer.email?.isNotEmpty == true)
            _buildInfoRow('Email', customer.email!),
          if (customer.phone?.isNotEmpty == true)
            _buildInfoRow('Teléfono', customer.phone!),
          if (customer.address?.isNotEmpty == true)
            _buildInfoRow('Dirección', customer.address!),
        ] else
          Text(
            'Información del cliente no disponible',
            style: TextStyle(color: Colors.grey.shade600),
          ),
      ],
    );
  }

  Widget _buildInvoiceInfoContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de la Factura',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        _buildInfoRow('Número', invoice.number),
        _buildInfoRow(
          'Fecha',
          '${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
        ),
        _buildInfoRow(
          'Vencimiento',
          '${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
        ),
        _buildInfoRow('Método de Pago', invoice.paymentMethodDisplayName),
        _buildInfoRow('Creada por', invoice.createdBy?.firstName ?? 'N/A'),
      ],
    );
  }

  Widget _buildItemsCard(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildItemsContent(context, controller));
  }

  Widget _buildItemsContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items de la Factura',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // ✅ MEJORA: Mostrar items con descripción visible o mensaje si está vacío
        if (invoice.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 48,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 12),
                Text(
                  'No hay items en esta factura',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          InvoiceItemsListWidget(
            items: invoice.items,
            onItemTap: (item) {
              if (item.productId != null) {
                controller.goToProductDetail(item.productId);
              }
            },
          ),
      ],
    );
  }

  Widget _buildTotalsCard(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildTotalsContent(context, controller));
  }

  Widget _buildTotalsContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Totales',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        _buildTotalRow('Subtotal', invoice.subtotal),

        if (invoice.discountAmount > 0 || invoice.discountPercentage > 0) ...[
          if (invoice.discountPercentage > 0)
            _buildTotalRow(
              'Descuento (${invoice.discountPercentage}%)',
              -invoice.discountAmount,
            ),
          if (invoice.discountAmount > 0 && invoice.discountPercentage == 0)
            _buildTotalRow('Descuento', -invoice.discountAmount),
        ],

        _buildTotalRow(
          'Impuestos (${invoice.taxPercentage}%)',
          invoice.taxAmount,
        ),

        const Divider(),
        _buildTotalRow('Total', invoice.total, isTotal: true),

        if (invoice.paidAmount > 0) ...[
          const SizedBox(height: 8),
          _buildTotalRow('Pagado', invoice.paidAmount, color: Colors.green),
          _buildTotalRow(
            'Saldo Pendiente',
            invoice.balanceDue,
            color: invoice.balanceDue > 0 ? Colors.red : Colors.green,
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfoCard(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildAdditionalInfoContent(context, controller));
  }

  Widget _buildAdditionalInfoContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Adicional',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        if (invoice.notes?.isNotEmpty == true) ...[
          Text(
            'Notas:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(invoice.notes!, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 16),
        ],

        if (invoice.terms?.isNotEmpty == true) ...[
          Text(
            'Términos y Condiciones:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(invoice.terms!, style: const TextStyle(color: Colors.black87)),
        ],
      ],
    );
  }

  Widget _buildPaymentForm(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildPaymentFormContent(context, controller));
  }

  Widget _buildPaymentFormContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return InvoicePaymentFormWidget(
      controller: controller,
      onCancel: controller.hidePaymentForm,
      onSubmit: controller.addPayment,
    );
  }

  // Widget _buildActionsContent(
  //   BuildContext context,
  //   InvoiceDetailController controller,
  // ) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Acciones',
  //         style: TextStyle(
  //           fontWeight: FontWeight.bold,
  //           color: Colors.grey.shade800,
  //         ),
  //       ),
  //       const SizedBox(height: 16),

  //       // Agregar pago
  //       if (controller.canAddPayment) ...[
  //         CustomButton(
  //           text: 'Agregar Pago',
  //           icon: Icons.payment,
  //           onPressed: controller.togglePaymentForm,
  //           width: double.infinity,
  //         ),
  //         const SizedBox(height: 12),
  //       ],

  //       // Confirmar
  //       if (controller.canConfirm) ...[
  //         CustomButton(
  //           text: 'Confirmar Factura',
  //           icon: Icons.check_circle,
  //           onPressed: controller.confirmInvoice,
  //           width: double.infinity,
  //         ),
  //         const SizedBox(height: 12),
  //       ],

  //       // Editar
  //       if (controller.canEdit) ...[
  //         CustomButton(
  //           text: 'Editar',
  //           icon: Icons.edit,
  //           type: ButtonType.outline,
  //           onPressed: controller.goToEditInvoice,
  //           width: double.infinity,
  //         ),
  //         const SizedBox(height: 12),
  //       ],

  //       // Imprimir
  //       if (controller.canPrint) ...[
  //         CustomButton(
  //           text: 'Imprimir',
  //           icon: Icons.print,
  //           type: ButtonType.outline,
  //           onPressed: controller.goToPrintInvoice,
  //           width: double.infinity,
  //         ),
  //         const SizedBox(height: 12),
  //       ],

  //       // Compartir
  //       CustomButton(
  //         text: 'Compartir',
  //         icon: Icons.share,
  //         type: ButtonType.outline,
  //         onPressed: controller.shareInvoice,
  //         width: double.infinity,
  //       ),
  //       const SizedBox(height: 12),

  //       // Duplicar
  //       CustomButton(
  //         text: 'Duplicar',
  //         icon: Icons.copy,
  //         type: ButtonType.outline,
  //         onPressed: controller.duplicateInvoice,
  //         width: double.infinity,
  //       ),

  //       if (controller.canCancel || controller.canDelete) ...[
  //         const SizedBox(height: 16),
  //         const Divider(),
  //         const SizedBox(height: 16),

  //         // Cancelar
  //         if (controller.canCancel) ...[
  //           CustomButton(
  //             text: 'Cancelar Factura',
  //             icon: Icons.cancel,
  //             type: ButtonType.outline,
  //             onPressed: controller.cancelInvoice,
  //             width: double.infinity,
  //             textColor: Colors.orange,
  //           ),
  //           const SizedBox(height: 12),
  //         ],

  //         // Eliminar
  //         if (controller.canDelete) ...[
  //           CustomButton(
  //             text: 'Eliminar',
  //             icon: Icons.delete,
  //             type: ButtonType.outline,
  //             onPressed: controller.deleteInvoice,
  //             width: double.infinity,
  //             textColor: Colors.red,
  //           ),
  //         ],
  //       ],
  //     ],
  //   );
  // }

  // ==================== PANEL DE ACCIONES MEJORADO ====================
  // Reemplazar el método _buildActionsContent en invoice_detail_screen.dart

  Widget _buildActionsContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // ✅ ACCIONES PARA FACTURAS CON PAGOS PENDIENTES (PENDING O PARTIALLY_PAID)
        if (controller.canAddPayment) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.invoice?.status ==
                                InvoiceStatus.partiallyPaid
                            ? 'Continuar Pago'
                            : 'Procesar Pago',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Saldo pendiente: ${AppFormatters.formatCurrency(controller.remainingBalance)}',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Botones específicos según método de pago
          if (controller.invoice!.paymentMethod == PaymentMethod.credit) ...[
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text:
                    controller.invoice?.status == InvoiceStatus.partiallyPaid
                        ? 'Continuar Pago a Crédito'
                        : 'Agregar Pago a Crédito',
                icon: Icons.account_balance_wallet,
                onPressed: controller.showCreditPaymentDialog,
                backgroundColor: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Permite pagos parciales o totales',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else if (controller.invoice!.paymentMethod == PaymentMethod.check &&
              controller.invoice?.status == InvoiceStatus.pending) ...[
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Confirmar Cheque',
                icon: Icons.receipt,
                onPressed: controller.confirmCheckPayment,
                backgroundColor: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Marca la factura como pagada',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else if (controller.invoice?.status == InvoiceStatus.pending) ...[
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Confirmar Pago Completo',
                icon: Icons.check_circle,
                onPressed: controller.confirmFullPayment,
                backgroundColor: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confirma el pago y marca como pagada',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Agregar Pago',
                icon: Icons.payment,
                onPressed: controller.togglePaymentForm,
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],

        // Confirmar
        if (controller.canConfirm) ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Confirmar Factura',
              icon: Icons.check_circle,
              onPressed: controller.confirmInvoice,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Editar
        if (controller.canEdit) ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Editar',
              icon: Icons.edit,
              type: ButtonType.outline,
              onPressed: controller.goToEditInvoice,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Imprimir
        if (controller.canPrint) ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Imprimir',
              icon: Icons.print,
              type: ButtonType.outline,
              onPressed: controller.goToPrintInvoice,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Compartir
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Compartir',
            icon: Icons.share,
            type: ButtonType.outline,
            onPressed: controller.shareInvoice,
          ),
        ),
        const SizedBox(height: 12),

        // Duplicar
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Duplicar',
            icon: Icons.copy,
            type: ButtonType.outline,
            onPressed: controller.duplicateInvoice,
          ),
        ),

        if (controller.canCancel || controller.canDelete) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Cancelar
          if (controller.canCancel) ...[
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Cancelar Factura',
                icon: Icons.cancel,
                type: ButtonType.outline,
                onPressed: controller.cancelInvoice,
                textColor: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Eliminar
          if (controller.canDelete) ...[
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Eliminar',
                icon: Icons.delete,
                type: ButtonType.outline,
                onPressed: controller.deleteInvoice,
                textColor: Colors.red,
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ==================== UTILITY WIDGETS ====================

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color:
                    Colors
                        .black87, // ✅ Cambiado de Colors.black54 a Colors.black87
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: color ?? Colors.grey.shade800,
            ),
          ),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: color ?? Colors.black87,
            ),
          ),
        ],
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
            'Factura no encontrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La factura que buscas no existe o fue eliminada',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Volver a Facturas',
            onPressed: () => Get.offAllNamed('/invoices'),
          ),
        ],
      ),
    );
  }

  // ==================== ACTION BUTTONS ====================

  // Widget? _buildFloatingActionButton(
  //   BuildContext context,
  //   InvoiceDetailController controller,
  // ) {
  //   if (!context.isMobile) return null;

  //   return GetBuilder<InvoiceDetailController>(
  //     builder: (controller) {
  //       if (controller.showPaymentForm) {
  //         return FloatingActionButton(
  //           onPressed: controller.hidePaymentForm,
  //           backgroundColor: Colors.grey,
  //           child: const Icon(Icons.close),
  //         );
  //       }

  //       if (controller.canAddPayment) {
  //         return FloatingActionButton.extended(
  //           onPressed: controller.togglePaymentForm,
  //           icon: const Icon(Icons.payment),
  //           label: const Text('Agregar Pago'),
  //         );
  //       }

  //       if (controller.canPrint) {
  //         return FloatingActionButton(
  //           onPressed: controller.goToPrintInvoice,
  //           child: const Icon(Icons.print),
  //         );
  //       }

  //       return const SizedBox.shrink();
  //     },
  //   );
  // }

  // ==================== FLOATING ACTION BUTTON MEJORADO ====================
  // Reemplazar el método _buildFloatingActionButton en invoice_detail_screen.dart

  // Widget? _buildFloatingActionButton(
  //   BuildContext context,
  //   InvoiceDetailController controller,
  // ) {
  //   if (!context.isMobile) return null;

  //   return GetBuilder<InvoiceDetailController>(
  //     builder: (controller) {
  //       if (controller.showPaymentForm) {
  //         return FloatingActionButton(
  //           onPressed: controller.hidePaymentForm,
  //           backgroundColor: Colors.grey,
  //           child: const Icon(Icons.close),
  //         );
  //       }

  //       // ✅ LÓGICA ESPECÍFICA PARA FACTURAS PENDIENTES
  //       if (controller.invoice?.status == InvoiceStatus.pending &&
  //           controller.canAddPayment) {
  //         switch (controller.invoice!.paymentMethod) {
  //           case PaymentMethod.credit:
  //             // Para crédito: permitir pagos parciales y totales
  //             return FloatingActionButton.extended(
  //               onPressed: controller.showCreditPaymentDialog,
  //               icon: const Icon(Icons.account_balance_wallet),
  //               label: const Text('Agregar Pago'),
  //               backgroundColor: Colors.blue.shade600,
  //             );

  //           case PaymentMethod.check:
  //             // Para cheque: confirmar directamente
  //             return FloatingActionButton.extended(
  //               onPressed: controller.confirmCheckPayment,
  //               icon: const Icon(Icons.receipt),
  //               label: const Text('Confirmar Cheque'),
  //               backgroundColor: Colors.orange.shade600,
  //             );

  //           case PaymentMethod.cash:
  //           case PaymentMethod.creditCard:
  //           case PaymentMethod.debitCard:
  //           case PaymentMethod.bankTransfer:
  //           default:
  //             // Para otros métodos: confirmar pago completo
  //             return FloatingActionButton.extended(
  //               onPressed: controller.confirmFullPayment,
  //               icon: const Icon(Icons.check_circle),
  //               label: const Text('Confirmar Pago'),
  //               backgroundColor: Colors.green.shade600,
  //             );
  //         }
  //       }

  //       // ✅ LÓGICA PARA OTROS ESTADOS
  //       if (controller.canAddPayment) {
  //         return FloatingActionButton.extended(
  //           onPressed: controller.togglePaymentForm,
  //           icon: const Icon(Icons.payment),
  //           label: const Text('Agregar Pago'),
  //         );
  //       }

  //       if (controller.canPrint) {
  //         return FloatingActionButton(
  //           onPressed: controller.goToPrintInvoice,
  //           child: const Icon(Icons.print),
  //         );
  //       }

  //       return const SizedBox.shrink();
  //     },
  //   );
  // }

  Widget? _buildFloatingActionButton(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    if (!context.isMobile) return null;

    return GetBuilder<InvoiceDetailController>(
      builder: (controller) {
        if (controller.showPaymentForm) {
          return FloatingActionButton(
            onPressed: controller.hidePaymentForm,
            backgroundColor: Colors.grey,
            child: const Icon(Icons.close),
          );
        }

        // ✅ LÓGICA CORREGIDA - INCLUIR PARTIALLY_PAID
        if (controller.canAddPayment) {
          // Para facturas PENDING o PARTIALLY_PAID con método CREDIT
          if ((controller.invoice?.status == InvoiceStatus.pending ||
                  controller.invoice?.status == InvoiceStatus.partiallyPaid) &&
              controller.invoice?.paymentMethod == PaymentMethod.credit) {
            return FloatingActionButton.extended(
              onPressed: controller.showCreditPaymentDialog,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Agregar Pago'),
              backgroundColor: Colors.blue.shade600,
            );
          }

          // Para facturas PENDING con método CHECK
          if (controller.invoice?.status == InvoiceStatus.pending &&
              controller.invoice?.paymentMethod == PaymentMethod.check) {
            return FloatingActionButton.extended(
              onPressed: controller.confirmCheckPayment,
              icon: const Icon(Icons.receipt),
              label: const Text('Confirmar Cheque'),
              backgroundColor: Colors.orange.shade600,
            );
          }

          // Para facturas PENDING con otros métodos
          if (controller.invoice?.status == InvoiceStatus.pending &&
              (controller.invoice?.paymentMethod == PaymentMethod.cash ||
                  controller.invoice?.paymentMethod ==
                      PaymentMethod.creditCard ||
                  controller.invoice?.paymentMethod ==
                      PaymentMethod.debitCard ||
                  controller.invoice?.paymentMethod ==
                      PaymentMethod.bankTransfer)) {
            return FloatingActionButton.extended(
              onPressed: controller.confirmFullPayment,
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirmar Pago'),
              backgroundColor: Colors.green.shade600,
            );
          }

          // Para cualquier otra factura que puede recibir pagos
          return FloatingActionButton.extended(
            onPressed: controller.togglePaymentForm,
            icon: const Icon(Icons.payment),
            label: const Text('Agregar Pago'),
          );
        }

        if (controller.canPrint) {
          return FloatingActionButton(
            onPressed: controller.goToPrintInvoice,
            child: const Icon(Icons.print),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget? _buildBottomActions(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    if (!context.isMobile) return null;

    return GetBuilder<InvoiceDetailController>(
      builder: (controller) {
        if (controller.showPaymentForm) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (controller.canEdit) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Editar',
                      icon: Icons.edit,
                      type: ButtonType.outline,
                      onPressed: controller.goToEditInvoice,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                if (controller.canConfirm) ...[
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Confirmar',
                      icon: Icons.check_circle,
                      onPressed: controller.confirmInvoice,
                    ),
                  ),
                ] else if (controller.canPrint) ...[
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Imprimir',
                      icon: Icons.print,
                      onPressed: controller.goToPrintInvoice,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== EVENT HANDLERS ====================

  void _handleMenuAction(
    String action,
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    switch (action) {
      case 'print':
        controller.goToPrintInvoice();
        break;
      case 'share':
        controller.shareInvoice();
        break;
      case 'duplicate':
        controller.duplicateInvoice();
        break;
      case 'confirm':
        controller.confirmInvoice();
        break;
      case 'cancel':
        controller.cancelInvoice();
        break;
      case 'delete':
        controller.deleteInvoice();
        break;
    }
  }

  // ==================== CLEAN APP BAR ====================

  PreferredSizeWidget _buildModernAppBar(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.offAllNamed(AppRoutes.invoices),
        tooltip: 'Volver a facturas',
      ),
      title: GetBuilder<InvoiceDetailController>(
        builder: (controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.invoice?.number ?? 'Factura',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (controller.hasInvoice)
              Text(
                controller.invoice!.customerName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
      actions: [
        // Solo mostrar editar si está en borrador
        GetBuilder<InvoiceDetailController>(
          builder: (controller) => controller.canEdit
              ? IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: controller.goToEditInvoice,
                  tooltip: 'Editar factura',
                )
              : const SizedBox.shrink(),
        ),

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => controller.refreshInvoice(),
          tooltip: 'Refrescar',
        ),

        // Menú de opciones
        GetBuilder<InvoiceDetailController>(
          builder: (controller) => PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => _handleMenuAction(value, context, controller),
            itemBuilder: (context) => [
              if (controller.canPrint)
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print, color: Colors.green),
                      SizedBox(width: 12),
                      Text('Imprimir'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Compartir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Duplicar'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              if (controller.canConfirm)
                const PopupMenuItem(
                  value: 'confirm',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Text('Confirmar'),
                    ],
                  ),
                ),
              if (controller.canCancel)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.orange),
                      SizedBox(width: 12),
                      Text('Cancelar'),
                    ],
                  ),
                ),
              if (controller.canDelete) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
