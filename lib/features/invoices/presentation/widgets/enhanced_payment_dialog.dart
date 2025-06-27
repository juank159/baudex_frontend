// // lib/features/invoices/presentation/widgets/enhanced_payment_dialog.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../../../app/core/utils/responsive.dart';
// import '../../domain/entities/invoice.dart';

// class EnhancedPaymentDialog extends StatefulWidget {
//   final double total;
//   final Function(
//     double receivedAmount,
//     double change,
//     PaymentMethod paymentMethod,
//   )
//   onPaymentConfirmed;
//   final VoidCallback onCancel;

//   const EnhancedPaymentDialog({
//     super.key,
//     required this.total,
//     required this.onPaymentConfirmed,
//     required this.onCancel,
//   });

//   @override
//   State<EnhancedPaymentDialog> createState() => _EnhancedPaymentDialogState();
// }

// class _EnhancedPaymentDialogState extends State<EnhancedPaymentDialog> {
//   final receivedController = TextEditingController();
//   PaymentMethod selectedPaymentMethod = PaymentMethod.cash;
//   double change = 0.0;
//   bool canProcess = false;

//   @override
//   void initState() {
//     super.initState();
//     // Para efectivo, inicializar con el total exacto
//     if (selectedPaymentMethod == PaymentMethod.cash) {
//       receivedController.text = widget.total.toStringAsFixed(0);
//       _calculateChange();
//     }
//   }

//   @override
//   void dispose() {
//     receivedController.dispose();
//     super.dispose();
//   }

//   void _calculateChange() {
//     final received = double.tryParse(receivedController.text) ?? 0.0;
//     setState(() {
//       change = received - widget.total;

//       // Para efectivo: debe haber recibido al menos el total
//       // Para otros métodos: el monto debe ser exacto al total
//       if (selectedPaymentMethod == PaymentMethod.cash) {
//         canProcess = received >= widget.total;
//       } else {
//         canProcess = received == widget.total;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ResponsiveLayout(
//       mobile: _buildMobileDialog(context),
//       tablet: _buildTabletDialog(context),
//       desktop: _buildDesktopDialog(context),
//     );
//   }

//   // ==================== MOBILE LAYOUT ====================
//   Widget _buildMobileDialog(BuildContext context) {
//     return Dialog.fullscreen(
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Procesar Pago'),
//           leading: IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: widget.onCancel,
//           ),
//           backgroundColor: Theme.of(context).primaryColor,
//           foregroundColor: Colors.white,
//           elevation: 0,
//         ),
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildTotalCard(context),
//                         const SizedBox(height: 24),
//                         _buildPaymentMethodSection(context, isMobile: true),
//                         const SizedBox(height: 24),
//                         if (selectedPaymentMethod == PaymentMethod.cash) ...[
//                           _buildCashPaymentSection(context, isMobile: true),
//                           const SizedBox(height: 24),
//                         ] else ...[
//                           _buildOtherPaymentSection(context),
//                           const SizedBox(height: 24),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ),
//                 _buildMobileActions(context),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ==================== TABLET LAYOUT ====================
//   Widget _buildTabletDialog(BuildContext context) {
//     return Dialog(
//       child: Container(
//         width: 500,
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.85,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildHeader(context),
//             Flexible(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildTotalCard(context),
//                     const SizedBox(height: 24),
//                     _buildPaymentMethodSection(context, isMobile: false),
//                     const SizedBox(height: 24),
//                     if (selectedPaymentMethod == PaymentMethod.cash) ...[
//                       _buildCashPaymentSection(context, isMobile: false),
//                     ] else ...[
//                       _buildOtherPaymentSection(context),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: _buildDesktopActions(context),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ==================== DESKTOP LAYOUT ====================
//   Widget _buildDesktopDialog(BuildContext context) {
//     return Dialog(
//       child: Container(
//         width: 550,
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.8,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildHeader(context),
//             Flexible(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(32),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildTotalCard(context),
//                     const SizedBox(height: 32),
//                     _buildPaymentMethodSection(context, isMobile: false),
//                     const SizedBox(height: 32),
//                     if (selectedPaymentMethod == PaymentMethod.cash) ...[
//                       _buildCashPaymentSection(context, isMobile: false),
//                     ] else ...[
//                       _buildOtherPaymentSection(context),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(32),
//               child: _buildDesktopActions(context),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ==================== SHARED COMPONENTS ====================

//   Widget _buildHeader(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Theme.of(context).primaryColor.withOpacity(0.1),
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(12),
//           topRight: Radius.circular(12),
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.payment, color: Theme.of(context).primaryColor, size: 28),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'Procesar Pago',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//           ),
//           IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.close)),
//         ],
//       ),
//     );
//   }

//   Widget _buildTotalCard(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Theme.of(context).primaryColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: Theme.of(context).primaryColor.withOpacity(0.3),
//         ),
//       ),
//       child: Column(
//         children: [
//           Text(
//             'Total a Pagar',
//             style: TextStyle(
//               fontSize: context.isMobile ? 16 : 18,
//               color: Theme.of(context).primaryColor,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             '\$${widget.total.toStringAsFixed(0)}',
//             style: TextStyle(
//               fontSize: context.isMobile ? 28 : 32,
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).primaryColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPaymentMethodSection(
//     BuildContext context, {
//     required bool isMobile,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Método de Pago',
//           style: TextStyle(
//             fontSize: isMobile ? 16 : 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 12),

//         if (isMobile)
//           _buildMobilePaymentMethods()
//         else
//           _buildDesktopPaymentMethods(),
//       ],
//     );
//   }

//   Widget _buildMobilePaymentMethods() {
//     return Column(
//       children:
//           PaymentMethod.values.map((method) {
//             final isSelected = selectedPaymentMethod == method;

//             return Container(
//               margin: const EdgeInsets.only(bottom: 8),
//               child: Material(
//                 borderRadius: BorderRadius.circular(8),
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(8),
//                   onTap: () => _selectPaymentMethod(method),
//                   child: Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       border: Border.all(
//                         color:
//                             isSelected
//                                 ? Theme.of(context).primaryColor
//                                 : Colors.grey.shade300,
//                         width: isSelected ? 2 : 1,
//                       ),
//                       borderRadius: BorderRadius.circular(8),
//                       color:
//                           isSelected
//                               ? Theme.of(context).primaryColor.withOpacity(0.1)
//                               : null,
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           _getPaymentMethodIcon(method),
//                           color:
//                               isSelected
//                                   ? Theme.of(context).primaryColor
//                                   : Colors.grey.shade600,
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             method.displayName,
//                             style: TextStyle(
//                               fontWeight:
//                                   isSelected
//                                       ? FontWeight.w600
//                                       : FontWeight.normal,
//                               color:
//                                   isSelected
//                                       ? Theme.of(context).primaryColor
//                                       : Colors.black,
//                             ),
//                           ),
//                         ),
//                         if (isSelected)
//                           Icon(
//                             Icons.check_circle,
//                             color: Theme.of(context).primaryColor,
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//     );
//   }

//   Widget _buildDesktopPaymentMethods() {
//     return Container(
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         children:
//             PaymentMethod.values.map((method) {
//               final isSelected = selectedPaymentMethod == method;
//               final isLast = method == PaymentMethod.values.last;

//               return Container(
//                 decoration: BoxDecoration(
//                   border:
//                       isLast
//                           ? null
//                           : Border(
//                             bottom: BorderSide(color: Colors.grey.shade200),
//                           ),
//                 ),
//                 child: RadioListTile<PaymentMethod>(
//                   value: method,
//                   groupValue: selectedPaymentMethod,
//                   onChanged: (value) => _selectPaymentMethod(value!),
//                   title: Row(
//                     children: [
//                       Icon(
//                         _getPaymentMethodIcon(method),
//                         color:
//                             isSelected
//                                 ? Theme.of(context).primaryColor
//                                 : Colors.grey.shade600,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         method.displayName,
//                         style: TextStyle(
//                           fontWeight:
//                               isSelected ? FontWeight.w600 : FontWeight.normal,
//                           color:
//                               isSelected
//                                   ? Theme.of(context).primaryColor
//                                   : Colors.black,
//                         ),
//                       ),
//                     ],
//                   ),
//                   activeColor: Theme.of(context).primaryColor,
//                 ),
//               );
//             }).toList(),
//       ),
//     );
//   }

//   Widget _buildCashPaymentSection(
//     BuildContext context, {
//     required bool isMobile,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Dinero Recibido',
//           style: TextStyle(
//             fontSize: isMobile ? 16 : 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 12),

//         TextField(
//           controller: receivedController,
//           keyboardType: const TextInputType.numberWithOptions(decimal: true),
//           inputFormatters: [
//             FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
//           ],
//           style: TextStyle(
//             fontSize: isMobile ? 16 : 18,
//             fontWeight: FontWeight.w600,
//           ),
//           decoration: InputDecoration(
//             prefixText: '\$ ',
//             prefixStyle: TextStyle(
//               fontSize: isMobile ? 16 : 18,
//               fontWeight: FontWeight.w600,
//             ),
//             border: const OutlineInputBorder(),
//             contentPadding: const EdgeInsets.all(16),
//             hintText: '0.00',
//           ),
//           onChanged: (value) => _calculateChange(),
//         ),
//         const SizedBox(height: 16),

//         // Cambio
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: change >= 0 ? Colors.green.shade200 : Colors.red.shade200,
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Cambio:',
//                 style: TextStyle(
//                   fontSize: isMobile ? 14 : 16,
//                   fontWeight: FontWeight.w600,
//                   color:
//                       change >= 0 ? Colors.green.shade800 : Colors.red.shade800,
//                 ),
//               ),
//               Text(
//                 '\$${change >= 0 ? change.toStringAsFixed(0) : '0'}',
//                 style: TextStyle(
//                   fontSize: isMobile ? 18 : 20,
//                   fontWeight: FontWeight.bold,
//                   color:
//                       change >= 0 ? Colors.green.shade800 : Colors.red.shade800,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildOtherPaymentSection(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.blue.shade200),
//       ),
//       child: Column(
//         children: [
//           Icon(Icons.info, color: Colors.blue.shade600),
//           const SizedBox(height: 8),
//           Text(
//             'Confirme que el pago ha sido procesado exitosamente',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: context.isMobile ? 14 : 16,
//               color: Colors.blue.shade800,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ==================== ACTIONS ====================

//   Widget _buildMobileActions(BuildContext context) {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           height: 48,
//           child: ElevatedButton(
//             onPressed: canProcess ? _confirmPayment : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//             ),
//             child: Text(
//               selectedPaymentMethod == PaymentMethod.cash
//                   ? 'Procesar Venta'
//                   : 'Confirmar Pago',
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           width: double.infinity,
//           height: 48,
//           child: OutlinedButton(
//             onPressed: widget.onCancel,
//             child: const Text('Cancelar'),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDesktopActions(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton(
//             onPressed: widget.onCancel,
//             style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
//             child: const Text('Cancelar'),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           flex: 2,
//           child: ElevatedButton(
//             onPressed: canProcess ? _confirmPayment : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.all(16),
//             ),
//             child: Text(
//               selectedPaymentMethod == PaymentMethod.cash
//                   ? 'Procesar Venta'
//                   : 'Confirmar Pago',
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ==================== HELPER METHODS ====================

//   void _selectPaymentMethod(PaymentMethod method) {
//     setState(() {
//       selectedPaymentMethod = method;

//       // Limpiar y reconfigurar según el método
//       if (selectedPaymentMethod == PaymentMethod.cash) {
//         receivedController.text = widget.total.toStringAsFixed(0);
//       } else {
//         receivedController.text = widget.total.toStringAsFixed(2);
//       }
//       _calculateChange();
//     });
//   }

//   void _confirmPayment() {
//     final received =
//         selectedPaymentMethod == PaymentMethod.cash
//             ? double.tryParse(receivedController.text) ?? 0.0
//             : widget.total;

//     widget.onPaymentConfirmed(
//       received,
//       change >= 0 ? change : 0.0,
//       selectedPaymentMethod,
//     );
//   }

//   IconData _getPaymentMethodIcon(PaymentMethod method) {
//     switch (method) {
//       case PaymentMethod.cash:
//         return Icons.attach_money;
//       case PaymentMethod.creditCard:
//         return Icons.credit_card;
//       case PaymentMethod.debitCard:
//         return Icons.payment;
//       case PaymentMethod.bankTransfer:
//         return Icons.account_balance;
//       case PaymentMethod.check:
//         return Icons.receipt_long;
//       case PaymentMethod.credit:
//         return Icons.schedule;
//       case PaymentMethod.other:
//         return Icons.more_horiz;
//       default:
//         return Icons.payment;
//     }
//   }
// }

// lib/features/invoices/presentation/widgets/enhanced_payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../domain/entities/invoice.dart';

class EnhancedPaymentDialog extends StatefulWidget {
  final double total;
  final Function(
    double receivedAmount,
    double change,
    PaymentMethod paymentMethod,
    InvoiceStatus status, // ✅ Agregar estado de factura
  )
  onPaymentConfirmed;
  final VoidCallback onCancel;

  const EnhancedPaymentDialog({
    super.key,
    required this.total,
    required this.onPaymentConfirmed,
    required this.onCancel,
  });

  @override
  State<EnhancedPaymentDialog> createState() => _EnhancedPaymentDialogState();
}

class _EnhancedPaymentDialogState extends State<EnhancedPaymentDialog> {
  final receivedController = TextEditingController();
  PaymentMethod selectedPaymentMethod = PaymentMethod.cash;
  double change = 0.0;
  bool canProcess = false;

  @override
  void initState() {
    super.initState();
    // Para efectivo, inicializar con el total exacto
    if (selectedPaymentMethod == PaymentMethod.cash) {
      receivedController.text = widget.total.toStringAsFixed(0);
      _calculateChange();
    }
  }

  @override
  void dispose() {
    receivedController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final received = double.tryParse(receivedController.text) ?? 0.0;
    setState(() {
      change = received - widget.total;

      // ✅ CORREGIDO - Para efectivo: debe ser igual o mayor al total
      if (selectedPaymentMethod == PaymentMethod.cash) {
        canProcess = received >= widget.total; // >= en lugar de >
      } else {
        // ✅ Para otros métodos: siempre puede procesar
        canProcess = true;
      }
    });
  }

  // ✅ DETERMINAR ESTADO DE FACTURA BASADO EN MÉTODO DE PAGO
  InvoiceStatus _getInvoiceStatus() {
    switch (selectedPaymentMethod) {
      case PaymentMethod.cash:
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
      case PaymentMethod.bankTransfer:
        return InvoiceStatus.paid; // Pagada inmediatamente
      case PaymentMethod.credit:
        return InvoiceStatus.pending; // Pendiente de pago
      case PaymentMethod.check:
      case PaymentMethod.other:
        return InvoiceStatus.pending; // Pendiente hasta confirmar
      default:
        return InvoiceStatus.draft; // Borrador por defecto
    }
  }

  // ✅ OBTENER COLOR SEGÚN ESTADO
  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.pending:
        return Colors.orange;
      case InvoiceStatus.draft:
        return Colors.blue;
      case InvoiceStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ✅ OBTENER DESCRIPCIÓN DEL ESTADO
  String _getStatusDescription(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return 'La factura quedará marcada como PAGADA';
      case InvoiceStatus.pending:
        return 'La factura quedará PENDIENTE de pago';
      case InvoiceStatus.draft:
        return 'La factura se guardará como BORRADOR';
      case InvoiceStatus.cancelled:
        return 'La factura será CANCELADA';
      default:
        return 'Estado desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileDialog(context),
      tablet: _buildTabletDialog(context),
      desktop: _buildDesktopDialog(context),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileDialog(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Procesar Pago'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel,
          ),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTotalCard(context),
                        const SizedBox(height: 24),
                        _buildPaymentMethodSection(context, isMobile: true),
                        const SizedBox(height: 24),
                        if (selectedPaymentMethod == PaymentMethod.cash) ...[
                          _buildCashPaymentSection(context, isMobile: true),
                          const SizedBox(height: 24),
                        ] else ...[
                          _buildOtherPaymentSection(context),
                          const SizedBox(height: 24),
                        ],
                        // ✅ MOSTRAR ESTADO DE FACTURA
                        _buildInvoiceStatusSection(context),
                      ],
                    ),
                  ),
                ),
                _buildMobileActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletDialog(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotalCard(context),
                    const SizedBox(height: 24),
                    _buildPaymentMethodSection(context, isMobile: false),
                    const SizedBox(height: 24),
                    if (selectedPaymentMethod == PaymentMethod.cash) ...[
                      _buildCashPaymentSection(context, isMobile: false),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildOtherPaymentSection(context),
                      const SizedBox(height: 24),
                    ],
                    // ✅ MOSTRAR ESTADO DE FACTURA
                    _buildInvoiceStatusSection(context),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildDesktopActions(context),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopDialog(BuildContext context) {
    return Dialog(
      child: Container(
        width: 550,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTotalCard(context),
                    const SizedBox(height: 32),
                    _buildPaymentMethodSection(context, isMobile: false),
                    const SizedBox(height: 32),
                    if (selectedPaymentMethod == PaymentMethod.cash) ...[
                      _buildCashPaymentSection(context, isMobile: false),
                      const SizedBox(height: 32),
                    ] else ...[
                      _buildOtherPaymentSection(context),
                      const SizedBox(height: 32),
                    ],
                    // ✅ MOSTRAR ESTADO DE FACTURA
                    _buildInvoiceStatusSection(context),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: _buildDesktopActions(context),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SHARED COMPONENTS ====================

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Procesar Pago',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Total a Pagar',
            style: TextStyle(
              fontSize: context.isMobile ? 16 : 18,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${widget.total.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: context.isMobile ? 28 : 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(
    BuildContext context, {
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de Pago',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),

        if (isMobile)
          _buildMobilePaymentMethods()
        else
          _buildDesktopPaymentMethods(),
      ],
    );
  }

  Widget _buildMobilePaymentMethods() {
    return Column(
      children:
          PaymentMethod.values.map((method) {
            final isSelected = selectedPaymentMethod == method;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _selectPaymentMethod(method),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getPaymentMethodIcon(method),
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            method.displayName,
                            style: TextStyle(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.black,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDesktopPaymentMethods() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children:
            PaymentMethod.values.map((method) {
              final isSelected = selectedPaymentMethod == method;
              final isLast = method == PaymentMethod.values.last;

              return Container(
                decoration: BoxDecoration(
                  border:
                      isLast
                          ? null
                          : Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                ),
                child: RadioListTile<PaymentMethod>(
                  value: method,
                  groupValue: selectedPaymentMethod,
                  onChanged: (value) => _selectPaymentMethod(value!),
                  title: Row(
                    children: [
                      Icon(
                        _getPaymentMethodIcon(method),
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        method.displayName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  activeColor: Theme.of(context).primaryColor,
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCashPaymentSection(
    BuildContext context, {
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dinero Recibido',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: receivedController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(16),
            hintText: '0.00',
          ),
          onChanged: (value) => _calculateChange(),
        ),
        const SizedBox(height: 16),

        // Cambio
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: change >= 0 ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: change >= 0 ? Colors.green.shade200 : Colors.red.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cambio:',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color:
                      change >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
              Text(
                '\$${change >= 0 ? change.toStringAsFixed(0) : '0'}',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color:
                      change >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),

        // ✅ MENSAJE DE AYUDA PARA EFECTIVO
        if (change < 0)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El monto recibido debe ser igual o mayor al total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOtherPaymentSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.info, color: Colors.blue.shade600),
          const SizedBox(height: 8),
          Text(
            selectedPaymentMethod == PaymentMethod.credit
                ? 'El pago se registrará como crédito y quedará pendiente'
                : 'Confirme que el pago ha sido procesado exitosamente',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.isMobile ? 14 : 16,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVA SECCIÓN - ESTADO DE FACTURA
  Widget _buildInvoiceStatusSection(BuildContext context) {
    final status = _getInvoiceStatus();
    final statusColor = _getStatusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getStatusIcon(status), color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Estado de Factura',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusDescription(status),
            style: TextStyle(fontSize: 12, color: statusColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  // ✅ ICONO SEGÚN ESTADO
  IconData _getStatusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.pending:
        return Icons.schedule;
      case InvoiceStatus.draft:
        return Icons.edit;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // ==================== ACTIONS ====================

  Widget _buildMobileActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: canProcess ? _confirmPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _getButtonText(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: widget.onCancel,
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: canProcess ? _confirmPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: Text(
              _getButtonText(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ TEXTO DINÁMICO DEL BOTÓN
  String _getButtonText() {
    switch (selectedPaymentMethod) {
      case PaymentMethod.cash:
        return 'Procesar Venta';
      case PaymentMethod.credit:
        return 'Generar Factura a Crédito';
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return 'Confirmar Pago con Tarjeta';
      case PaymentMethod.bankTransfer:
        return 'Confirmar Transferencia';
      case PaymentMethod.check:
        return 'Registrar Cheque';
      default:
        return 'Procesar Pago';
    }
  }

  // ==================== HELPER METHODS ====================

  void _selectPaymentMethod(PaymentMethod method) {
    setState(() {
      selectedPaymentMethod = method;

      // ✅ CONFIGURAR SEGÚN MÉTODO DE PAGO
      if (selectedPaymentMethod == PaymentMethod.cash) {
        // Para efectivo, inicializar con el total
        receivedController.text = widget.total.toStringAsFixed(0);
      } else {
        // Para otros métodos, usar el total exacto
        receivedController.text = widget.total.toStringAsFixed(2);
      }
      _calculateChange();
    });
  }

  void _confirmPayment() {
    final received =
        selectedPaymentMethod == PaymentMethod.cash
            ? double.tryParse(receivedController.text) ?? 0.0
            : widget.total;

    final invoiceStatus = _getInvoiceStatus();

    widget.onPaymentConfirmed(
      received,
      change >= 0 ? change : 0.0,
      selectedPaymentMethod,
      invoiceStatus, // ✅ Pasar el estado de la factura
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.attach_money;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.payment;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.check:
        return Icons.receipt_long;
      case PaymentMethod.credit:
        return Icons.schedule;
      case PaymentMethod.other:
        return Icons.more_horiz;
      default:
        return Icons.payment;
    }
  }
}
