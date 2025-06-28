// // lib/features/invoices/presentation/screens/invoice_form_screen.dart
// import 'package:baudex_desktop/features/invoices/presentation/widgets/enhanced_invoice_item_widget.dart';
// import 'package:baudex_desktop/features/invoices/presentation/widgets/enhanced_payment_dialog.dart';
// import 'package:baudex_desktop/features/products/domain/entities/product.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/invoice_form_controller.dart';
// import '../widgets/product_search_widget.dart';
// import '../widgets/customer_selector_widget.dart';

// class InvoiceFormScreen extends StatelessWidget {
//   const InvoiceFormScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<InvoiceFormController>(
//       builder: (controller) {
//         return Scaffold(
//           appBar: _buildAppBar(context, controller),
//           body:
//               controller.isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // ✅ SELECTOR DE CLIENTE
//                         CustomerSelectorWidget(
//                           selectedCustomer: controller.selectedCustomer,
//                           onCustomerSelected: controller.selectCustomer,
//                           onClearCustomer: controller.clearCustomer,
//                         ),

//                         const SizedBox(height: 20),

//                         //✅ BUSCADOR DE PRODUCTOS
//                         ProductSearchWidget(
//                           autoFocus: true,
//                           onProductSelected: (product, quantity) {
//                             controller.addOrUpdateProductToInvoice(
//                               product,
//                               quantity: quantity,
//                             );
//                           },
//                         ),
//                         const SizedBox(height: 20),

//                         // LISTA DE PRODUCTOS EN LA FACTURA
//                         _buildInvoiceItems(context, controller),

//                         const SizedBox(height: 20),

//                         // TOTALES
//                         _buildTotalsSection(context, controller),
//                       ],
//                     ),
//                   ),
//         );
//       },
//     );
//   }

//   AppBar _buildAppBar(BuildContext context, InvoiceFormController controller) {
//     return AppBar(
//       title: Row(
//         children: [
//           Text(controller.pageTitle),
//           // ✅ Mostrar indicador si es un borrador siendo editado
//           if (controller.isEditMode)
//             Container(
//               margin: const EdgeInsets.only(left: 8),
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade100,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 'BORRADOR',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.blue.shade800,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//         ],
//       ),
//       backgroundColor: Theme.of(context).primaryColor,
//       foregroundColor: Colors.white,
//       actions: [
//         // Botón de nueva venta
//         if (!controller.isEditMode)
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: controller.clearFormForNewSale,
//             tooltip: 'Nueva Venta',
//           ),

//         // ✅ Botón adicional para borradores
//         if (controller.isEditMode)
//           IconButton(
//             icon: const Icon(Icons.check_circle),
//             onPressed: () => _showConfirmDraftDialog(context, controller),
//             tooltip: 'Confirmar Borrador',
//           ),

//         // Botón de guardar/procesar
//         Container(
//           margin: const EdgeInsets.only(right: 8),
//           child: ElevatedButton.icon(
//             onPressed:
//                 controller.canSave && !controller.isSaving
//                     ? () => _showPaymentDialog(context, controller)
//                     : null,
//             icon:
//                 controller.isSaving
//                     ? const SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     )
//                     : const Icon(Icons.point_of_sale),
//             label: Text(controller.saveButtonText),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInvoiceItems(
//     BuildContext context,
//     InvoiceFormController controller,
//   ) {
//     return Obx(() {
//       if (controller.invoiceItems.isEmpty) {
//         return Container(
//           padding: const EdgeInsets.all(32),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade50,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade300),
//           ),
//           child: Column(
//             children: [
//               Icon(
//                 Icons.shopping_cart_outlined,
//                 size: 48,
//                 color: Colors.grey.shade400,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'No hay productos agregados',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey.shade600,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Busca y agrega productos para comenzar la venta',
//                 style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         );
//       }

//       return Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade300),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).primaryColor.withOpacity(0.1),
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(12),
//                   topRight: Radius.circular(12),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.shopping_cart,
//                     color: Theme.of(context).primaryColor,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Productos (${controller.invoiceItems.length})',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).primaryColor,
//                     ),
//                   ),
//                   const Spacer(),
//                   if (controller.invoiceItems.isNotEmpty)
//                     TextButton.icon(
//                       onPressed: controller.clearItems,
//                       icon: const Icon(Icons.clear_all, size: 16),
//                       label: const Text('Limpiar'),
//                       style: TextButton.styleFrom(foregroundColor: Colors.red),
//                     ),
//                 ],
//               ),
//             ),

//             // Lista de items
//             ListView.separated(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: controller.invoiceItems.length,
//               separatorBuilder:
//                   (context, index) =>
//                       Divider(height: 1, color: Colors.grey.shade200),
//               itemBuilder: (context, index) {
//                 final item = controller.invoiceItems[index];

//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 8),
//                   child: _buildInvoiceItemTile(
//                     context,
//                     controller,
//                     item,
//                     index,
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildInvoiceItemTile(
//     BuildContext context,
//     InvoiceFormController controller,
//     item,
//     int index,
//   ) {
//     // ✅ Buscar el producto correspondiente para mostrar precios
//     Product? product;
//     if (item.productId != null) {
//       product = controller.availableProducts.firstWhereOrNull(
//         (p) => p.id == item.productId,
//       );
//     }

//     return EnhancedInvoiceItemWidget(
//       item: item,
//       index: index,
//       product: product,
//       onUpdate: (updatedItem) => controller.updateItem(index, updatedItem),
//       onRemove: () => controller.removeItem(index),
//       showPriceSelector: true, // ✅ Habilitar selector de precios
//     );
//   }

//   Widget _buildTotalsSection(
//     BuildContext context,
//     InvoiceFormController controller,
//   ) {
//     return Obx(() {
//       return Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade300),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Resumen de Venta',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Theme.of(context).primaryColor,
//                   ),
//                 ),
//                 // ✅ Mostrar ayuda para borradores
//                 if (controller.invoiceItems.isNotEmpty)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.blue.shade200),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.info, size: 16, color: Colors.blue.shade600),
//                         const SizedBox(width: 4),
//                         Text(
//                           'Puede guardar como borrador',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.blue.shade800,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // Subtotal
//             _buildTotalRow('Subtotal', controller.subtotalWithoutTax),

//             // Descuentos (si hay)
//             if (controller.totalDiscountAmount > 0)
//               _buildTotalRow(
//                 'Descuentos',
//                 -controller.totalDiscountAmount,
//                 isDiscount: true,
//               ),

//             // Impuestos
//             if (controller.taxAmount > 0)
//               _buildTotalRow(
//                 'IVA (${controller.taxPercentage}%)',
//                 controller.taxAmount,
//               ),

//             const Divider(height: 20),

//             // Total
//             _buildTotalRow('TOTAL', controller.total, isTotal: true),
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildTotalRow(
//     String label,
//     double amount, {
//     bool isTotal = false,
//     bool isDiscount = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: isTotal ? 18 : 14,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
//               color: isTotal ? Colors.black : Colors.grey.shade700,
//             ),
//           ),
//           Text(
//             '${isDiscount ? '-' : ''}\$${amount.abs().toStringAsFixed(0)}',
//             style: TextStyle(
//               fontSize: isTotal ? 20 : 16,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
//               color:
//                   isTotal
//                       ? Colors.green.shade600
//                       : isDiscount
//                       ? Colors.red.shade600
//                       : Colors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showPaymentDialog(
//     BuildContext context,
//     InvoiceFormController controller,
//   ) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder:
//           (context) => EnhancedPaymentDialog(
//             total: controller.total,
//             onPaymentConfirmed: (
//               receivedAmount,
//               change,
//               paymentMethod,
//               status,
//             ) async {
//               Navigator.of(context).pop();

//               // ✅ Establecer el método de pago seleccionado
//               controller.setPaymentMethod(paymentMethod);

//               // ✅ Procesar la venta con la información de pago Y estado
//               await controller.saveInvoiceWithPayment(
//                 receivedAmount,
//                 change,
//                 paymentMethod,
//                 status, // ✅ NUEVO PARÁMETRO
//               );
//             },
//             onCancel: () => Navigator.of(context).pop(),
//           ),
//     );
//   }

//   void _showConfirmDraftDialog(
//     BuildContext context,
//     InvoiceFormController controller,
//   ) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('Confirmar Borrador'),
//             content: const Text(
//               '¿Estás seguro de que quieres confirmar este borrador?\n\n'
//               'La factura cambiará a estado pendiente y podrá ser procesada.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Cancelar'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   controller.confirmDraftInvoice(controller.editingInvoiceId!);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Confirmar'),
//               ),
//             ],
//           ),
//     );
//   }
// }

// lib/features/invoices/presentation/screens/invoice_form_screen.dart
import 'package:baudex_desktop/features/invoices/presentation/widgets/enhanced_invoice_item_widget.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/enhanced_payment_dialog.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/app/core/utils/responsive.dart'; // ✅ IMPORTAR RESPONSIVE
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/invoice_form_controller.dart';
import '../widgets/product_search_widget.dart';
import '../widgets/customer_selector_widget.dart';

class InvoiceFormScreen extends StatelessWidget {
  const InvoiceFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InvoiceFormController>(
      builder: (controller) {
        return Scaffold(
          appBar: _buildAppBar(context, controller),
          body:
              controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    padding: context.responsivePadding, // ✅ PADDING RESPONSIVO
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ SELECTOR DE CLIENTE
                        CustomerSelectorWidget(
                          selectedCustomer: controller.selectedCustomer,
                          onCustomerSelected: controller.selectCustomer,
                          onClearCustomer: controller.clearCustomer,
                        ),

                        SizedBox(height: context.verticalSpacing),

                        //✅ BUSCADOR DE PRODUCTOS
                        ProductSearchWidget(
                          autoFocus: true,
                          onProductSelected: (product, quantity) {
                            controller.addOrUpdateProductToInvoice(
                              product,
                              quantity: quantity,
                            );
                          },
                        ),
                        SizedBox(height: context.verticalSpacing),

                        // LISTA DE PRODUCTOS EN LA FACTURA
                        _buildInvoiceItems(context, controller),

                        SizedBox(height: context.verticalSpacing),

                        // TOTALES
                        _buildTotalsSection(context, controller),
                      ],
                    ),
                  ),
        );
      },
    );
  }

  // ✅ APPBAR CORREGIDO - SIN OVERFLOW
  AppBar _buildAppBar(BuildContext context, InvoiceFormController controller) {
    return AppBar(
      title:
          context.isMobile
              ? _buildMobileTitle(context, controller)
              : _buildDesktopTitle(context, controller),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      actions: _buildAppBarActions(context, controller),
    );
  }

  // ✅ TÍTULO PARA MÓVIL - MÁS COMPACTO
  Widget _buildMobileTitle(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          controller.isEditMode ? 'Editar' : 'POS',
          style: const TextStyle(fontSize: 16),
        ),
        if (controller.isEditMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'BORRADOR',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ✅ TÍTULO PARA DESKTOP - COMPLETO
  Widget _buildDesktopTitle(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(controller.pageTitle),
        if (controller.isEditMode) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'BORRADOR',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ✅ ACCIONES DEL APPBAR - RESPONSIVAS
  List<Widget> _buildAppBarActions(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    final actions = <Widget>[];

    // Botón de nueva venta (solo en desktop/tablet)
    if (!controller.isEditMode && !context.isMobile) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.clearFormForNewSale,
          tooltip: 'Nueva Venta',
        ),
      );
    }

    // Botón para confirmar borrador
    if (controller.isEditMode) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.check_circle),
          onPressed: () => _showConfirmDraftDialog(context, controller),
          tooltip: 'Confirmar Borrador',
        ),
      );
    }

    // Botón principal
    actions.add(
      Container(
        margin: EdgeInsets.only(right: context.isMobile ? 4 : 8),
        child:
            context.isMobile
                ? _buildMobileSaveButton(context, controller)
                : _buildDesktopSaveButton(context, controller),
      ),
    );

    return actions;
  }

  // ✅ BOTÓN DE GUARDAR PARA MÓVIL - COMPACTO
  Widget _buildMobileSaveButton(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return ElevatedButton(
      onPressed:
          controller.canSave && !controller.isSaving
              ? () => _showPaymentDialog(context, controller)
              : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child:
          controller.isSaving
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Icon(Icons.point_of_sale, size: 20),
    );
  }

  // ✅ BOTÓN DE GUARDAR PARA DESKTOP - COMPLETO
  Widget _buildDesktopSaveButton(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return ElevatedButton.icon(
      onPressed:
          controller.canSave && !controller.isSaving
              ? () => _showPaymentDialog(context, controller)
              : null,
      icon:
          controller.isSaving
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Icon(Icons.point_of_sale),
      label: Text(controller.saveButtonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildInvoiceItems(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Obx(() {
      if (controller.invoiceItems.isEmpty) {
        return Container(
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: context.isMobile ? 40 : 48,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: context.isMobile ? 12 : 16),
              Text(
                'No hay productos agregados',
                style: TextStyle(
                  fontSize: context.isMobile ? 14 : 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: context.isMobile ? 6 : 8),
              Text(
                'Busca y agrega productos para comenzar la venta',
                style: TextStyle(
                  fontSize: context.isMobile ? 12 : 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: context.responsivePadding,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    color: Theme.of(context).primaryColor,
                    size: context.isMobile ? 20 : 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Productos (${controller.invoiceItems.length})',
                      style: TextStyle(
                        fontSize: context.isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  if (controller.invoiceItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: controller.clearItems,
                      icon: Icon(
                        Icons.clear_all,
                        size: context.isMobile ? 14 : 16,
                      ),
                      label: Text(
                        context.isMobile ? 'Limpiar' : 'Limpiar',
                        style: TextStyle(fontSize: context.isMobile ? 12 : 14),
                      ),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                ],
              ),
            ),

            // Lista de items
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.invoiceItems.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final item = controller.invoiceItems[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: _buildInvoiceItemTile(
                    context,
                    controller,
                    item,
                    index,
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInvoiceItemTile(
    BuildContext context,
    InvoiceFormController controller,
    item,
    int index,
  ) {
    // ✅ Buscar el producto correspondiente para mostrar precios
    Product? product;
    if (item.productId != null) {
      product = controller.availableProducts.firstWhereOrNull(
        (p) => p.id == item.productId,
      );
    }

    return EnhancedInvoiceItemWidget(
      item: item,
      index: index,
      product: product,
      onUpdate: (updatedItem) => controller.updateItem(index, updatedItem),
      onRemove: () => controller.removeItem(index),
      showPriceSelector: true, // ✅ Habilitar selector de precios
    );
  }

  // ✅ SECCIÓN DE TOTALES CORREGIDA - SIN OVERFLOW
  Widget _buildTotalsSection(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Obx(() {
      return Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ HEADER RESPONSIVO
            context.isMobile
                ? _buildMobileTotalsHeader(context, controller)
                : _buildDesktopTotalsHeader(context, controller),

            SizedBox(height: context.isMobile ? 12 : 16),

            // Subtotal
            _buildTotalRow(context, 'Subtotal', controller.subtotalWithoutTax),

            // Descuentos (si hay)
            if (controller.totalDiscountAmount > 0)
              _buildTotalRow(
                context,
                'Descuentos',
                -controller.totalDiscountAmount,
                isDiscount: true,
              ),

            // Impuestos
            if (controller.taxAmount > 0)
              _buildTotalRow(
                context,
                'IVA (${controller.taxPercentage}%)',
                controller.taxAmount,
              ),

            const Divider(height: 20),

            // Total
            _buildTotalRow(context, 'TOTAL', controller.total, isTotal: true),
          ],
        ),
      );
    });
  }

  // ✅ HEADER MÓVIL - INFORMACIÓN EN COLUMNA
  Widget _buildMobileTotalsHeader(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de Venta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        if (controller.invoiceItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info, size: 14, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Puede guardar como borrador',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ✅ HEADER DESKTOP - INFORMACIÓN EN FILA
  Widget _buildDesktopTotalsHeader(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Resumen de Venta',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        // ✅ Mostrar ayuda para borradores
        if (controller.invoiceItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Text(
                  'Puede guardar como borrador',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ✅ FILA DE TOTAL RESPONSIVA
  Widget _buildTotalRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize:
                    isTotal
                        ? (context.isMobile ? 16 : 18)
                        : (context.isMobile ? 12 : 14),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.black : Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${isDiscount ? '-' : ''}\$${amount.abs().toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize:
                    isTotal
                        ? (context.isMobile ? 18 : 20)
                        : (context.isMobile ? 14 : 16),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color:
                    isTotal
                        ? Colors.green.shade600
                        : isDiscount
                        ? Colors.red.shade600
                        : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => EnhancedPaymentDialog(
            total: controller.total,
            onPaymentConfirmed: (
              receivedAmount,
              change,
              paymentMethod,
              status,
            ) async {
              Navigator.of(context).pop();

              // ✅ Establecer el método de pago seleccionado
              controller.setPaymentMethod(paymentMethod);

              // ✅ Procesar la venta con la información de pago Y estado
              await controller.saveInvoiceWithPayment(
                receivedAmount,
                change,
                paymentMethod,
                status, // ✅ NUEVO PARÁMETRO
              );
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
    );
  }

  void _showConfirmDraftDialog(
    BuildContext context,
    InvoiceFormController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Borrador'),
            content: const Text(
              '¿Estás seguro de que quieres confirmar este borrador?\n\n'
              'La factura cambiará a estado pendiente y podrá ser procesada.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  controller.confirmDraftInvoice(controller.editingInvoiceId!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
  }
}
