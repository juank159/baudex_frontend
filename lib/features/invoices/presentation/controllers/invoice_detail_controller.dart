// lib/features/invoices/presentation/controllers/invoice_detail_controller.dart
import 'package:baudex_desktop/app/core/utils/responsive.dart';
import 'package:baudex_desktop/app/shared/widgets/custom_button.dart';
import 'package:baudex_desktop/app/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/get_invoice_by_id_usecase.dart';
import '../../domain/usecases/add_payment_usecase.dart';
import '../../domain/usecases/confirm_invoice_usecase.dart';
import '../../domain/usecases/cancel_invoice_usecase.dart';
import '../../domain/usecases/delete_invoice_usecase.dart';

class InvoiceDetailController extends GetxController {
  // Dependencies
  final GetInvoiceByIdUseCase _getInvoiceByIdUseCase;
  final AddPaymentUseCase _addPaymentUseCase;
  final ConfirmInvoiceUseCase _confirmInvoiceUseCase;
  final CancelInvoiceUseCase _cancelInvoiceUseCase;
  final DeleteInvoiceUseCase _deleteInvoiceUseCase;

  InvoiceDetailController({
    required GetInvoiceByIdUseCase getInvoiceByIdUseCase,
    required AddPaymentUseCase addPaymentUseCase,
    required ConfirmInvoiceUseCase confirmInvoiceUseCase,
    required CancelInvoiceUseCase cancelInvoiceUseCase,
    required DeleteInvoiceUseCase deleteInvoiceUseCase,
  }) : _getInvoiceByIdUseCase = getInvoiceByIdUseCase,
       _addPaymentUseCase = addPaymentUseCase,
       _confirmInvoiceUseCase = confirmInvoiceUseCase,
       _cancelInvoiceUseCase = cancelInvoiceUseCase,
       _deleteInvoiceUseCase = deleteInvoiceUseCase {
    print('🎮 InvoiceDetailController: Instancia creada correctamente');
  }

  // ==================== OBSERVABLES ====================

  // Estados
  final _isLoading = false.obs;
  final _isProcessing = false.obs;

  // Datos
  final Rxn<Invoice> _invoice = Rxn<Invoice>();

  // UI States
  final _showPaymentForm = false.obs;
  final _selectedPaymentMethod = PaymentMethod.cash.obs;

  // Controllers para agregar pago
  final paymentAmountController = TextEditingController();
  final paymentReferenceController = TextEditingController();
  final paymentNotesController = TextEditingController();
  final paymentFormKey = GlobalKey<FormState>();

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isProcessing => _isProcessing.value;
  Invoice? get invoice => _invoice.value;
  bool get showPaymentForm => _showPaymentForm.value;
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod.value;

  String get invoiceId => Get.parameters['id'] ?? '';
  bool get hasInvoice => _invoice.value != null;

  // Invoice status helpers
  bool get canEdit => invoice?.canBeEdited ?? false;
  bool get canConfirm => invoice?.status == InvoiceStatus.draft;
  bool get canCancel => invoice?.canBeCancelled ?? false;
  bool get canAddPayment => invoice?.canAddPayment ?? false;
  bool get canDelete =>
      invoice?.status == InvoiceStatus.draft ||
      invoice?.status == InvoiceStatus.cancelled;
  bool get canPrint => invoice != null;

  // Payment helpers
  double get remainingBalance => invoice?.balanceDue ?? 0;
  bool get isFullyPaid => invoice?.isPaid ?? false;
  bool get isPartiallyPaid => invoice?.isPartiallyPaid ?? false;
  bool get isOverdue => invoice?.isOverdue ?? false;
  int get daysOverdue => invoice?.daysOverdue ?? 0;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    print('🚀 InvoiceDetailController: Inicializando...');
    print('🔍 ID de factura recibido: $invoiceId');
    print('🔍 Ruta actual en onInit: ${Get.currentRoute}');

    if (invoiceId.isNotEmpty) {
      loadInvoice();
    } else {
      _showError('Error', 'ID de factura no válido');
      print('❌ ID de factura no válido, EVITANDO Get.back() automático');
      // ✅ SOLUCIÓN: No hacer Get.back() automático para evitar [GETX] Redirect to null
      // Get.back();
    }
  }

  @override
  void onClose() {
    print('🔚 InvoiceDetailController: Liberando recursos...');
    _disposeControllers();
    super.onClose();
  }

  // ==================== CORE METHODS ====================

  /// Cargar factura
  Future<void> loadInvoice() async {
    try {
      _isLoading.value = true;
      print('📋 Cargando factura: $invoiceId');

      final result = await _getInvoiceByIdUseCase(
        GetInvoiceByIdParams(id: invoiceId),
      );

      //   result.fold(
      //     (failure) {
      //       print('❌ Error al cargar factura: ${failure.message}');
      //       _showError('Error al cargar factura', failure.message);
      //       Get.back();
      //     },
      //     (loadedInvoice) {
      //       _invoice.value = loadedInvoice;
      //       print('✅ Factura cargada: ${loadedInvoice.number}');
      //     },
      //   );
      // } catch (e) {
      //   print('💥 Error inesperado al cargar factura: $e');
      //   _showError('Error inesperado', 'No se pudo cargar la factura');
      //   Get.back();

      result.fold(
        (failure) {
          print('❌ Error al cargar factura: ${failure.message}');
          _showError('Error al cargar factura', failure.message);
          // ✅ SOLUCIÓN TEMPORAL: Comentar Get.back() para investigar redirect
          // Get.back();
          print('⚠️ Get.back() comentado temporalmente para debug');
        },
        (loadedInvoice) {
          print('🔍 DEBUG DETALLE: === FACTURA CARGADA ===');
          print('🔍 DEBUG DETALLE: ID: ${loadedInvoice.id}');
          print('🔍 DEBUG DETALLE: Número: ${loadedInvoice.number}');
          print('🔍 DEBUG DETALLE: Cliente: ${loadedInvoice.customerName}');
          print('🔍 DEBUG DETALLE: Items: ${loadedInvoice.items.length}');
          print('🔍 DEBUG DETALLE: Total: ${loadedInvoice.total}');
          print('🔍 DEBUG DETALLE: === FIN DEBUG ===');

          _invoice.value = loadedInvoice;
          update(); // ✅ AGREGAR ESTA LÍNEA PARA FORZAR ACTUALIZACIÓN DE UI
          print('✅ Factura cargada: ${loadedInvoice.number}');
          print('🔍 RUTA ACTUAL AL FINALIZAR CARGA: ${Get.currentRoute}');

          // ✅ VERIFICACIÓN: Agregar delay para detectar redirects inesperados
          Future.delayed(const Duration(milliseconds: 500), () {
            print('🔍 RUTA DESPUÉS DE 500ms: ${Get.currentRoute}');
          });

          Future.delayed(const Duration(milliseconds: 1000), () {
            print('🔍 RUTA DESPUÉS DE 1000ms: ${Get.currentRoute}');
          });
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refrescar factura
  Future<void> refreshInvoice() async {
    print('🔄 Refrescando factura...');
    await loadInvoice();
  }

  // ==================== INVOICE ACTIONS ====================

  /// Confirmar factura
  Future<void> confirmInvoice() async {
    if (!canConfirm) {
      _showError(
        'Acción no disponible',
        'Esta factura no puede ser confirmada',
      );
      return;
    }

    try {
      _isProcessing.value = true;
      print('✅ Confirmando factura: $invoiceId');

      final result = await _confirmInvoiceUseCase(
        ConfirmInvoiceParams(id: invoiceId),
      );

      result.fold(
        (failure) {
          _showError('Error al confirmar factura', failure.message);
        },
        (updatedInvoice) {
          _invoice.value = updatedInvoice;
          _showSuccess('Factura confirmada exitosamente');
        },
      );
    } catch (e) {
      print('💥 Error al confirmar factura: $e');
      _showError('Error inesperado', 'No se pudo confirmar la factura');
    } finally {
      _isProcessing.value = false;
    }
  }

  // Future<void> confirmFullPayment() async {
  //   if (!canAddPayment) {
  //     _showError(
  //       'Acción no disponible',
  //       'No se pueden procesar pagos para esta factura',
  //     );
  //     return;
  //   }

  //   final confirmed = await _showConfirmationDialog(
  //     'Confirmar Pago Completo',
  //     '¿Confirmas que se ha recibido el pago completo de esta factura?\n\n'
  //         'Total: \$${invoice!.total.toStringAsFixed(2)}\n'
  //         'Método: ${invoice!.paymentMethodDisplayName}',
  //     confirmText: 'Confirmar Pago',
  //     confirmColor: Colors.green,
  //   );

  //   if (!confirmed) return;

  //   try {
  //     _isProcessing.value = true;
  //     print('💰 Confirmando pago completo para: ${invoiceId}');

  //     final result = await _addPaymentUseCase(
  //       AddPaymentParams(
  //         invoiceId: invoiceId,
  //         amount: remainingBalance, // Pago completo
  //         paymentMethod: invoice!.paymentMethod,
  //         paymentDate: DateTime.now(),
  //         reference: 'Pago confirmado - ${invoice!.paymentMethodDisplayName}',
  //         notes:
  //             'Pago completo confirmado el ${DateTime.now().toString().split(' ')[0]}',
  //       ),
  //     );

  //     result.fold(
  //       (failure) {
  //         _showError('Error al confirmar pago', failure.message);
  //       },
  //       (updatedInvoice) {
  //         _invoice.value = updatedInvoice;
  //         _showSuccess('Pago confirmado exitosamente');
  //       },
  //     );
  //   } catch (e) {
  //     print('💥 Error al confirmar pago completo: $e');
  //     _showError('Error inesperado', 'No se pudo confirmar el pago');
  //   } finally {
  //     _isProcessing.value = false;
  //   }
  // }

  Future<void> confirmFullPayment() async {
    if (!canAddPayment) {
      _showError(
        'Acción no disponible',
        'No se pueden procesar pagos para esta factura',
      );
      return;
    }

    final confirmed = await _showConfirmationDialog(
      'Confirmar Pago Completo',
      '¿Confirmas que se ha recibido el pago completo de esta factura?\n\n'
          'Total: \$${invoice!.total.toStringAsFixed(2)}\n'
          'Método: ${invoice!.paymentMethodDisplayName}',
      confirmText: 'Confirmar Pago',
      confirmColor: Colors.green,
    );

    if (!confirmed) return;

    try {
      _isProcessing.value = true;
      update();

      print('💰 Confirmando pago completo para: $invoiceId');

      final result = await _addPaymentUseCase(
        AddPaymentParams(
          invoiceId: invoiceId,
          amount: remainingBalance,
          paymentMethod: invoice!.paymentMethod,
          paymentDate: DateTime.now(),
          reference: 'Pago confirmado - ${invoice!.paymentMethodDisplayName}',
          notes:
              'Pago completo confirmado el ${DateTime.now().toString().split(' ')[0]}',
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al confirmar pago', failure.message);
        },
        (updatedInvoice) {
          _invoice.value = updatedInvoice;
          print(
            '✅ Factura actualizada - Nuevo status: ${updatedInvoice.status}',
          );

          update();
          _invoice.refresh();

          _showSuccess('Pago confirmado exitosamente');
        },
      );
    } catch (e) {
      print('💥 Error al confirmar pago completo: $e');
      _showError('Error inesperado', 'No se pudo confirmar el pago');
    } finally {
      _isProcessing.value = false;
      update();
    }
  }

  // Future<void> confirmCheckPayment() async {
  //   if (!canAddPayment) {
  //     _showError(
  //       'Acción no disponible',
  //       'No se pueden procesar pagos para esta factura',
  //     );
  //     return;
  //   }

  //   // Mostrar diálogo para confirmar cheque
  //   final result = await Get.dialog<Map<String, dynamic>>(
  //     AlertDialog(
  //       title: const Text('Confirmar Cheque'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Total a pagar: \$${remainingBalance.toStringAsFixed(2)}',
  //             style: const TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 16),
  //           CustomTextField(
  //             controller: paymentReferenceController,
  //             label: 'Número de Cheque',
  //             hint: 'Ej: 001234',
  //             prefixIcon: Icons.receipt,
  //           ),
  //           const SizedBox(height: 12),
  //           CustomTextField(
  //             controller: paymentNotesController,
  //             label: 'Banco Emisor (Opcional)',
  //             hint: 'Ej: Banco de Bogotá',
  //             prefixIcon: Icons.account_balance,
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(),
  //           child: const Text('Cancelar'),
  //         ),
  //         ElevatedButton(
  //           onPressed:
  //               () => Get.back(
  //                 result: {
  //                   'reference': paymentReferenceController.text,
  //                   'notes': paymentNotesController.text,
  //                 },
  //               ),
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
  //           child: const Text('Confirmar Cheque'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (result == null) return;

  //   try {
  //     _isProcessing.value = true;
  //     print('📄 Confirmando pago con cheque para: ${invoiceId}');

  //     final checkReference = result['reference'] ?? '';
  //     final bankNotes = result['notes'] ?? '';

  //     final paymentResult = await _addPaymentUseCase(
  //       AddPaymentParams(
  //         invoiceId: invoiceId,
  //         amount: remainingBalance,
  //         paymentMethod: PaymentMethod.check,
  //         paymentDate: DateTime.now(),
  //         reference:
  //             checkReference.isNotEmpty
  //                 ? 'Cheque #$checkReference'
  //                 : 'Cheque confirmado',
  //         notes:
  //             bankNotes.isNotEmpty
  //                 ? 'Cheque confirmado - Banco: $bankNotes'
  //                 : 'Cheque confirmado el ${DateTime.now().toString().split(' ')[0]}',
  //       ),
  //     );

  //     paymentResult.fold(
  //       (failure) {
  //         _showError('Error al confirmar cheque', failure.message);
  //       },
  //       (updatedInvoice) {
  //         _invoice.value = updatedInvoice;
  //         _showSuccess('Cheque confirmado exitosamente');
  //         // Limpiar campos
  //         paymentReferenceController.clear();
  //         paymentNotesController.clear();
  //       },
  //     );
  //   } catch (e) {
  //     print('💥 Error al confirmar cheque: $e');
  //     _showError('Error inesperado', 'No se pudo confirmar el cheque');
  //   } finally {
  //     _isProcessing.value = false;
  //   }
  // }

  Future<void> confirmCheckPayment() async {
    if (!canAddPayment) {
      _showError(
        'Acción no disponible',
        'No se pueden procesar pagos para esta factura',
      );
      return;
    }

    final tempReferenceController = TextEditingController();
    final tempNotesController = TextEditingController();

    final result = await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        title: const Text('Confirmar Cheque'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total a pagar: \$${remainingBalance.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: tempReferenceController,
              label: 'Número de Cheque',
              hint: 'Ej: 001234',
              prefixIcon: Icons.receipt,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: tempNotesController,
              label: 'Banco Emisor (Opcional)',
              hint: 'Ej: Banco de Bogotá',
              prefixIcon: Icons.account_balance,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              tempReferenceController.dispose();
              tempNotesController.dispose();
              Get.back();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final data = {
                'reference': tempReferenceController.text,
                'notes': tempNotesController.text,
              };
              tempReferenceController.dispose();
              tempNotesController.dispose();
              Get.back(result: data);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar Cheque'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      _isProcessing.value = true;
      update();

      print('📄 Confirmando pago con cheque para: $invoiceId');

      final checkReference = result['reference'] ?? '';
      final bankNotes = result['notes'] ?? '';

      final paymentResult = await _addPaymentUseCase(
        AddPaymentParams(
          invoiceId: invoiceId,
          amount: remainingBalance,
          paymentMethod: PaymentMethod.check,
          paymentDate: DateTime.now(),
          reference:
              checkReference.isNotEmpty
                  ? 'Cheque #$checkReference'
                  : 'Cheque confirmado',
          notes:
              bankNotes.isNotEmpty
                  ? 'Cheque confirmado - Banco: $bankNotes'
                  : 'Cheque confirmado el ${DateTime.now().toString().split(' ')[0]}',
        ),
      );

      paymentResult.fold(
        (failure) {
          _showError('Error al confirmar cheque', failure.message);
        },
        (updatedInvoice) {
          _invoice.value = updatedInvoice;
          print(
            '✅ Factura actualizada - Nuevo status: ${updatedInvoice.status}',
          );

          update();
          _invoice.refresh();

          _showSuccess('Cheque confirmado exitosamente');
        },
      );
    } catch (e) {
      print('💥 Error al confirmar cheque: $e');
      _showError('Error inesperado', 'No se pudo confirmar el cheque');
    } finally {
      _isProcessing.value = false;
      update();
    }
  }

  // Future<void> showCreditPaymentDialog() async {
  //   if (!canAddPayment) {
  //     _showError(
  //       'Acción no disponible',
  //       'No se pueden agregar pagos a esta factura',
  //     );
  //     return;
  //   }

  //   final tempAmountController = TextEditingController();
  //   final tempReferenceController = TextEditingController();
  //   final tempNotesController = TextEditingController();
  //   final tempFormKey = GlobalKey<FormState>();

  //   await Get.dialog(
  //     Dialog(
  //       child: Container(
  //         width: 500,
  //         padding: const EdgeInsets.all(24),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Row(
  //               children: [
  //                 Icon(
  //                   Icons.account_balance_wallet,
  //                   color: Colors.blue.shade600,
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Text(
  //                   'Pago a Crédito',
  //                   style: TextStyle(
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.blue.shade800,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 16),

  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.blue.shade50,
  //                 borderRadius: BorderRadius.circular(8),
  //                 border: Border.all(color: Colors.blue.shade200),
  //               ),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     'Saldo Pendiente: \$${remainingBalance.toStringAsFixed(2)}',
  //                     style: TextStyle(
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.blue.shade800,
  //                       fontSize: 16,
  //                     ),
  //                   ),
  //                   Text(
  //                     'Puedes realizar un pago parcial o total',
  //                     style: TextStyle(
  //                       color: Colors.blue.shade600,
  //                       fontSize: 12,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 16),

  //             Form(
  //               key: tempFormKey,
  //               child: Column(
  //                 children: [
  //                   CustomTextField(
  //                     controller: tempAmountController,
  //                     label: 'Monto del Pago',
  //                     hint: 'Ingresa el monto a abonar',
  //                     prefixIcon: Icons.attach_money,
  //                     keyboardType: const TextInputType.numberWithOptions(
  //                       decimal: true,
  //                     ),
  //                     validator: (value) {
  //                       if (value == null || value.isEmpty) {
  //                         return 'El monto es requerido';
  //                       }
  //                       final amount = double.tryParse(value);
  //                       if (amount == null || amount <= 0) {
  //                         return 'Ingresa un monto válido';
  //                       }
  //                       if (amount > remainingBalance) {
  //                         return 'El monto excede el saldo pendiente (\$${remainingBalance.toStringAsFixed(2)})';
  //                       }
  //                       return null;
  //                     },
  //                     suffixIcon: Icons.calculate,
  //                     onSuffixIconPressed:
  //                         () =>
  //                             _showQuickAmountsForCredit(tempAmountController),
  //                   ),
  //                   const SizedBox(height: 16),

  //                   CustomTextField(
  //                     controller: tempReferenceController,
  //                     label: 'Referencia (Opcional)',
  //                     hint: 'Número de transferencia, etc.',
  //                     prefixIcon: Icons.receipt_long,
  //                   ),
  //                   const SizedBox(height: 16),

  //                   CustomTextField(
  //                     controller: tempNotesController,
  //                     label: 'Notas (Opcional)',
  //                     hint: 'Notas sobre el pago...',
  //                     prefixIcon: Icons.note,
  //                     maxLines: 2,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 24),

  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: CustomButton(
  //                     text: 'Cancelar',
  //                     type: ButtonType.outline,
  //                     onPressed: () {
  //                       tempAmountController.dispose();
  //                       tempReferenceController.dispose();
  //                       tempNotesController.dispose();
  //                       Get.back();
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(width: 16),
  //                 Expanded(
  //                   flex: 2,
  //                   child: GetBuilder<InvoiceDetailController>(
  //                     builder:
  //                         (controller) => CustomButton(
  //                           text:
  //                               controller.isProcessing
  //                                   ? 'Procesando...'
  //                                   : 'Agregar Pago',
  //                           icon: Icons.add_card,
  //                           onPressed:
  //                               controller.isProcessing
  //                                   ? null
  //                                   : () async {
  //                                     if (tempFormKey.currentState!
  //                                         .validate()) {
  //                                       final success =
  //                                           await _processCreditPayment(
  //                                             tempAmountController,
  //                                             tempReferenceController,
  //                                             tempNotesController,
  //                                           );
  //                                       if (success) {
  //                                         tempAmountController.dispose();
  //                                         tempReferenceController.dispose();
  //                                         tempNotesController.dispose();
  //                                         Get.back();
  //                                       }
  //                                     }
  //                                   },
  //                           isLoading: controller.isProcessing,
  //                         ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Future<void> showCreditPaymentDialog() async {
    if (!canAddPayment) {
      _showError(
        'Acción no disponible',
        'No se pueden agregar pagos a esta factura',
      );
      return;
    }

    print('🔷 Mostrando diálogo de pago a crédito');

    await Get.dialog(
      WillPopScope(
        onWillPop: () async => true,
        child: Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxWidth:
                  Responsive.isMobile(Get.context!) ? Get.width * 0.9 : 500,
            ),
            padding: const EdgeInsets.all(24),
            child: _CreditPaymentDialogContent(
              controller: this,
              remainingBalance: remainingBalance,
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<bool> _processCreditPayment(
    TextEditingController amountController,
    TextEditingController referenceController,
    TextEditingController notesController,
  ) async {
    try {
      _isProcessing.value = true;
      update();

      final amount = double.tryParse(amountController.text) ?? 0;
      print('💰 Procesando pago a crédito: $amount');

      final result = await _addPaymentUseCase(
        AddPaymentParams(
          invoiceId: invoiceId,
          amount: amount,
          paymentMethod: PaymentMethod.credit,
          paymentDate: DateTime.now(),
          reference:
              referenceController.text.isNotEmpty
                  ? referenceController.text
                  : null,
          notes: notesController.text.isNotEmpty ? notesController.text : null,
        ),
      );

      return result.fold(
        (failure) {
          _showError('Error al agregar pago', failure.message);
          return false;
        },
        (updatedInvoice) {
          _invoice.value = updatedInvoice;
          print(
            '✅ Factura actualizada - Nuevo saldo: ${updatedInvoice.balanceDue}',
          );

          update();
          _invoice.refresh();

          _showSuccess('Pago agregado exitosamente');
          return true;
        },
      );
    } catch (e) {
      print('💥 Error al procesar pago a crédito: $e');
      _showError('Error inesperado', 'No se pudo procesar el pago');
      return false;
    } finally {
      _isProcessing.value = false;
      update();
    }
  }

  /// ✅ MÉTODO HELPER - Mostrar montos rápidos para crédito
  void _showQuickAmountsForCredit(TextEditingController amountController) {
    final balance = remainingBalance;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montos Rápidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: [
                _buildQuickAmountButton(
                  'Saldo Completo',
                  balance,
                  amountController,
                ),
                _buildQuickAmountButton('50%', balance * 0.5, amountController),
                _buildQuickAmountButton(
                  '25%',
                  balance * 0.25,
                  amountController,
                ),
                _buildQuickAmountButton('10%', balance * 0.1, amountController),
                if (balance >= 100)
                  _buildQuickAmountButton('\$100', 100, amountController),
                if (balance >= 500)
                  _buildQuickAmountButton('\$500', 500, amountController),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Widget _buildCreditQuickAmountButton(
  //   String label,
  //   double amount,
  //   TextEditingController controller,
  // ) {
  //   final isValid = amount > 0 && amount <= remainingBalance;

  //   return CustomButton(
  //     text: label,
  //     type: ButtonType.outline,
  //     onPressed:
  //         isValid
  //             ? () {
  //               controller.text = amount.toStringAsFixed(2);
  //               Get.back();
  //             }
  //             : null,
  //     backgroundColor: isValid ? null : Colors.grey.shade200,
  //     textColor: isValid ? null : Colors.grey.shade500,
  //   );
  // }

  Widget _buildQuickAmountButton(
    String label,
    double amount,
    TextEditingController controller,
  ) {
    final isValid = amount > 0 && amount <= remainingBalance;

    return CustomButton(
      text: label,
      type: ButtonType.outline,
      onPressed:
          isValid
              ? () {
                controller.text = amount.toStringAsFixed(2);
                Get.back();
              }
              : null,
      backgroundColor: isValid ? null : Colors.grey.shade200,
      textColor: isValid ? null : Colors.grey.shade500,
    );
  }

  /// Cancelar factura
  Future<void> cancelInvoice() async {
    if (!canCancel) {
      _showError('Acción no disponible', 'Esta factura no puede ser cancelada');
      return;
    }

    final confirmed = await _showConfirmationDialog(
      'Cancelar Factura',
      '¿Estás seguro que deseas cancelar esta factura?\n\nEsta acción no se puede deshacer.',
      confirmText: 'Cancelar Factura',
      confirmColor: Colors.orange,
    );

    if (!confirmed) return;

    try {
      _isProcessing.value = true;
      print('❌ Cancelando factura: $invoiceId');

      final result = await _cancelInvoiceUseCase(
        CancelInvoiceParams(id: invoiceId),
      );

      result.fold(
        (failure) {
          _showError('Error al cancelar factura', failure.message);
        },
        (updatedInvoice) {
          _invoice.value = updatedInvoice;
          _showSuccess('Factura cancelada exitosamente');
        },
      );
    } catch (e) {
      print('💥 Error al cancelar factura: $e');
      _showError('Error inesperado', 'No se pudo cancelar la factura');
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Eliminar factura
  Future<void> deleteInvoice() async {
    if (!canDelete) {
      _showError('Acción no disponible', 'Esta factura no puede ser eliminada');
      return;
    }

    final confirmed = await _showConfirmationDialog(
      'Eliminar Factura',
      '¿Estás seguro que deseas eliminar esta factura?\n\nEsta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      confirmColor: Colors.red,
    );

    if (!confirmed) return;

    try {
      _isProcessing.value = true;
      print('🗑️ Eliminando factura: $invoiceId');

      final result = await _deleteInvoiceUseCase(
        DeleteInvoiceParams(id: invoiceId),
      );

      result.fold(
        (failure) {
          _showError('Error al eliminar factura', failure.message);
        },
        (_) {
          _showSuccess('Factura eliminada exitosamente');
          Get.back(); // Volver a la lista
        },
      );
    } catch (e) {
      print('💥 Error al eliminar factura: $e');
      _showError('Error inesperado', 'No se pudo eliminar la factura');
    } finally {
      _isProcessing.value = false;
    }
  }

  // ==================== PAYMENT METHODS ====================

  /// Mostrar formulario de pago
  void togglePaymentForm() {
    if (!canAddPayment) {
      _showError(
        'Acción no disponible',
        'No se pueden agregar pagos a esta factura',
      );
      return;
    }

    _showPaymentForm.value = true;
    _clearPaymentForm();
    print('📝 Mostrando formulario de pago');
  }

  /// Ocultar formulario de pago
  void hidePaymentForm() {
    _showPaymentForm.value = false;
    _clearPaymentForm();
    print('❌ Ocultando formulario de pago');
  }

  /// Cambiar método de pago
  void setPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod.value = method;
    print('💳 Método de pago seleccionado: ${method.displayName}');
  }

  /// Agregar pago
  // Future<void> addPayment() async {
  //   if (!paymentFormKey.currentState!.validate()) {
  //     return;
  //   }

  //   if (!canAddPayment) {
  //     _showError(
  //       'Acción no disponible',
  //       'No se pueden agregar pagos a esta factura',
  //     );
  //     return;
  //   }

  //   try {
  //     _isProcessing.value = true;
  //     print('💰 Agregando pago a factura: $invoiceId');

  //     final amount = double.tryParse(paymentAmountController.text) ?? 0;

  //     if (amount <= 0) {
  //       _showError('Error de validación', 'El monto debe ser mayor a cero');
  //       return;
  //     }

  //     if (amount > remainingBalance) {
  //       _showError('Error de validación', 'El monto excede el saldo pendiente');
  //       return;
  //     }

  //     final result = await _addPaymentUseCase(
  //       AddPaymentParams(
  //         invoiceId: invoiceId,
  //         amount: amount,
  //         paymentMethod: _selectedPaymentMethod.value,
  //         paymentDate: DateTime.now(),
  //         reference:
  //             paymentReferenceController.text.isNotEmpty
  //                 ? paymentReferenceController.text
  //                 : null,
  //         notes:
  //             paymentNotesController.text.isNotEmpty
  //                 ? paymentNotesController.text
  //                 : null,
  //       ),
  //     );

  //     result.fold(
  //       (failure) {
  //         _showError('Error al agregar pago', failure.message);
  //       },
  //       (updatedInvoice) {
  //         _invoice.value = updatedInvoice;
  //         hidePaymentForm();
  //         _showSuccess('Pago agregado exitosamente');
  //       },
  //     );
  //   } catch (e) {
  //     print('💥 Error al agregar pago: $e');
  //     _showError('Error inesperado', 'No se pudo agregar el pago');
  //   } finally {
  //     _isProcessing.value = false;
  //   }
  // }

  Future<void> addPayment() async {
    if (!paymentFormKey.currentState!.validate()) {
      return;
    }

    if (!canAddPayment) {
      _showError(
        'Acción no disponible',
        'No se pueden agregar pagos a esta factura',
      );
      return;
    }

    try {
      _isProcessing.value = true;
      update();

      print('💰 Agregando pago a factura: $invoiceId');

      final amount = double.tryParse(paymentAmountController.text) ?? 0;

      if (amount <= 0) {
        _showError('Error de validación', 'El monto debe ser mayor a cero');
        return;
      }

      if (amount > remainingBalance) {
        _showError('Error de validación', 'El monto excede el saldo pendiente');
        return;
      }

      final result = await _addPaymentUseCase(
        AddPaymentParams(
          invoiceId: invoiceId,
          amount: amount,
          paymentMethod: _selectedPaymentMethod.value,
          paymentDate: DateTime.now(),
          reference:
              paymentReferenceController.text.isNotEmpty
                  ? paymentReferenceController.text
                  : null,
          notes:
              paymentNotesController.text.isNotEmpty
                  ? paymentNotesController.text
                  : null,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al agregar pago', failure.message);
        },
        (updatedInvoice) {
          _invoice.value = updatedInvoice;
          print(
            '✅ Factura actualizada - Nuevo saldo: ${updatedInvoice.balanceDue}',
          );

          update();
          _invoice.refresh();

          hidePaymentForm();
          _showSuccess('Pago agregado exitosamente');
        },
      );
    } catch (e) {
      print('💥 Error al agregar pago: $e');
      _showError('Error inesperado', 'No se pudo agregar el pago');
    } finally {
      _isProcessing.value = false;
      update();
    }
  }

  // ==================== NAVIGATION METHODS ====================

  /// Navegar a editar factura
  void goToEditInvoice() {
    if (!canEdit) {
      _showError('Acción no disponible', 'Esta factura no puede ser editada');
      return;
    }
    Get.toNamed('/invoices/edit/$invoiceId');
  }

  /// Navegar a imprimir factura
  void goToPrintInvoice() {
    if (!canPrint) {
      _showError('Acción no disponible', 'Esta factura no puede ser impresa');
      return;
    }
    Get.toNamed('/invoices/print/$invoiceId');
  }

  /// Navegar a cliente
  void goToCustomerDetail() {
    if (invoice?.customerId != null) {
      Get.toNamed('/customers/detail/${invoice!.customerId}');
    }
  }

  /// Navegar a producto desde item
  void goToProductDetail(String? productId) {
    if (productId != null) {
      Get.toNamed('/products/detail/$productId');
    }
  }

  /// Compartir factura
  void shareInvoice() {
    // TODO: Implementar compartir factura
    _showInfo('Próximamente', 'Función de compartir en desarrollo');
  }

  /// Duplicar factura
  void duplicateInvoice() {
    if (invoice == null) return;

    Get.toNamed('/invoices/tabs', parameters: {'duplicate_from': invoiceId});
  }

  // ==================== VALIDATION METHODS ====================

  String? validatePaymentAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'El monto es requerido';
    }

    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Ingresa un monto válido';
    }

    if (amount > remainingBalance) {
      return 'El monto excede el saldo pendiente (\$${remainingBalance.toStringAsFixed(2)})';
    }

    return null;
  }

  // ==================== UTILITY METHODS ====================

  /// Obtener color del estado
  Color getStatusColor() {
    if (invoice == null) return Colors.grey;

    switch (invoice!.status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.pending:
        return isOverdue ? Colors.red : Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.grey;
      case InvoiceStatus.partiallyPaid:
        return isOverdue ? Colors.red : Colors.blue;
    }
  }

  /// Obtener icono del estado
  IconData getStatusIcon() {
    if (invoice == null) return Icons.help;

    switch (invoice!.status) {
      case InvoiceStatus.draft:
        return Icons.edit;
      case InvoiceStatus.pending:
        return isOverdue ? Icons.warning : Icons.schedule;
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.overdue:
        return Icons.error;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
      case InvoiceStatus.partiallyPaid:
        return Icons.pie_chart;
    }
  }

  /// Obtener texto descriptivo del estado
  String getStatusDescription() {
    if (invoice == null) return '';

    switch (invoice!.status) {
      case InvoiceStatus.draft:
        return 'Factura en borrador, lista para confirmar';
      case InvoiceStatus.pending:
        if (isOverdue) {
          return 'Factura vencida hace $daysOverdue días';
        }
        return 'Factura pendiente de pago';
      case InvoiceStatus.paid:
        return 'Factura pagada completamente';
      case InvoiceStatus.overdue:
        return 'Factura vencida hace $daysOverdue días';
      case InvoiceStatus.cancelled:
        return 'Factura cancelada';
      case InvoiceStatus.partiallyPaid:
        if (isOverdue) {
          return 'Pago parcial, vencida hace $daysOverdue días';
        }
        return 'Pago parcial recibido';
    }
  }

  /// Limpiar formulario de pago
  void _clearPaymentForm() {
    paymentAmountController.clear();
    paymentReferenceController.clear();
    paymentNotesController.clear();
    _selectedPaymentMethod.value = PaymentMethod.cash;
    paymentFormKey.currentState?.reset();
  }

  /// Liberar controladores
  void _disposeControllers() {
    paymentAmountController.dispose();
    paymentReferenceController.dispose();
    paymentNotesController.dispose();
  }

  // ==================== DIALOG HELPERS ====================

  /// Mostrar diálogo de confirmación
  Future<bool> _showConfirmationDialog(
    String title,
    String content, {
    String confirmText = 'Confirmar',
    Color? confirmColor,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? Get.theme.primaryColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
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

  void _showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.info, color: Colors.blue),
      duration: const Duration(seconds: 3),
    );
  }
}

// class _CreditPaymentDialogContent extends StatefulWidget {
//   final InvoiceDetailController controller;
//   final double remainingBalance;

//   const _CreditPaymentDialogContent({
//     required this.controller,
//     required this.remainingBalance,
//   });

//   @override
//   State<_CreditPaymentDialogContent> createState() =>
//       _CreditPaymentDialogContentState();
// }

// class _CreditPaymentDialogContentState
//     extends State<_CreditPaymentDialogContent> {
//   late TextEditingController amountController;
//   late TextEditingController referenceController;
//   late TextEditingController notesController;
//   late GlobalKey<FormState> formKey;
//   bool isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     amountController = TextEditingController();
//     referenceController = TextEditingController();
//     notesController = TextEditingController();
//     formKey = GlobalKey<FormState>();
//   }

//   @override
//   void dispose() {
//     amountController.dispose();
//     referenceController.dispose();
//     notesController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header responsivo
//         Row(
//           children: [
//             Icon(
//               Icons.account_balance_wallet,
//               color: Colors.blue.shade600,
//               size: context.isMobile ? 20 : 24,
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'Pago a Crédito',
//                 style: TextStyle(
//                   fontSize: context.isMobile ? 18 : 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue.shade800,
//                 ),
//               ),
//             ),
//             IconButton(
//               onPressed: () => Navigator.of(context).pop(),
//               icon: const Icon(Icons.close),
//               iconSize: context.isMobile ? 18 : 20,
//               tooltip: 'Cerrar',
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         // Info del saldo
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.blue.shade50,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.blue.shade200),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Saldo Pendiente: \$${widget.remainingBalance.toStringAsFixed(2)}',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue.shade800,
//                   fontSize: context.isMobile ? 14 : 16,
//                 ),
//               ),
//               Text(
//                 'Puedes realizar un pago parcial o total',
//                 style: TextStyle(
//                   color: Colors.blue.shade600,
//                   fontSize: context.isMobile ? 10 : 12,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),

//         // Formulario
//         Form(
//           key: formKey,
//           child: Column(
//             children: [
//               CustomTextField(
//                 controller: amountController,
//                 label: 'Monto del Pago',
//                 hint: 'Ingresa el monto a abonar',
//                 prefixIcon: Icons.attach_money,
//                 keyboardType: const TextInputType.numberWithOptions(
//                   decimal: true,
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'El monto es requerido';
//                   }
//                   final amount = double.tryParse(value);
//                   if (amount == null || amount <= 0) {
//                     return 'Ingresa un monto válido';
//                   }
//                   if (amount > widget.remainingBalance) {
//                     return 'El monto excede el saldo pendiente';
//                   }
//                   return null;
//                 },
//                 suffixIcon: Icons.calculate,
//                 onSuffixIconPressed: () => _showQuickAmounts(),
//               ),
//               const SizedBox(height: 16),

//               CustomTextField(
//                 controller: referenceController,
//                 label: 'Referencia (Opcional)',
//                 hint: 'Número de transferencia, etc.',
//                 prefixIcon: Icons.receipt_long,
//               ),
//               const SizedBox(height: 16),

//               CustomTextField(
//                 controller: notesController,
//                 label: 'Notas (Opcional)',
//                 hint: 'Notas sobre el pago...',
//                 prefixIcon: Icons.note,
//                 maxLines: 2,
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 24),

//         // ✅ BOTONES CORREGIDOS - RESPONSIVOS
//         _buildActionButtons(context),
//       ],
//     );
//   }

//   // ✅ MÉTODO SEPARADO PARA BOTONES RESPONSIVOS
//   Widget _buildActionButtons(BuildContext context) {
//     if (context.isMobile) {
//       // Móvil: Botones apilados verticalmente
//       return Column(
//         children: [
//           SizedBox(
//             width: double.infinity,
//             child: CustomButton(
//               text: isProcessing ? 'Procesando...' : 'Agregar Pago',
//               icon: isProcessing ? null : Icons.add_card,
//               onPressed: isProcessing ? null : _processPayment,
//               isLoading: isProcessing,
//             ),
//           ),
//           const SizedBox(height: 12),
//           SizedBox(
//             width: double.infinity,
//             child: CustomButton(
//               text: 'Cancelar',
//               type: ButtonType.outline,
//               onPressed:
//                   isProcessing ? null : () => Navigator.of(context).pop(),
//             ),
//           ),
//         ],
//       );
//     } else {
//       // Tablet/Desktop: Botones en fila
//       return Row(
//         children: [
//           Expanded(
//             child: CustomButton(
//               text: 'Cancelar',
//               type: ButtonType.outline,
//               onPressed:
//                   isProcessing ? null : () => Navigator.of(context).pop(),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             flex: 2,
//             child: CustomButton(
//               text: isProcessing ? 'Procesando...' : 'Agregar Pago',
//               icon: isProcessing ? null : Icons.add_card,
//               onPressed: isProcessing ? null : _processPayment,
//               isLoading: isProcessing,
//             ),
//           ),
//         ],
//       );
//     }
//   }

//   // ✅ MÉTODO CORREGIDO - CIERRE AUTOMÁTICO GARANTIZADO
//   Future<void> _processPayment() async {
//     if (!formKey.currentState!.validate()) return;

//     setState(() => isProcessing = true);

//     try {
//       final amount = double.parse(amountController.text);
//       print('💰 Procesando pago a crédito: $amount');

//       final result = await widget.controller._addPaymentUseCase(
//         AddPaymentParams(
//           invoiceId: widget.controller.invoiceId,
//           amount: amount,
//           paymentMethod: PaymentMethod.credit,
//           paymentDate: DateTime.now(),
//           reference:
//               referenceController.text.isNotEmpty
//                   ? referenceController.text
//                   : null,
//           notes: notesController.text.isNotEmpty ? notesController.text : null,
//         ),
//       );

//       result.fold(
//         (failure) {
//           widget.controller._showError(
//             'Error al agregar pago',
//             failure.message,
//           );
//           setState(() => isProcessing = false);
//         },
//         (updatedInvoice) {
//           print(
//             '✅ Pago agregado exitosamente - Nuevo saldo: ${updatedInvoice.balanceDue}',
//           );

//           // ✅ ACTUALIZAR CONTROLLER
//           widget.controller._invoice.value = updatedInvoice;
//           widget.controller.update();
//           widget.controller._invoice.refresh();

//           // ✅ MOSTRAR MENSAJE DE ÉXITO
//           widget.controller._showSuccess('Pago agregado exitosamente');

//           // ✅ CERRAR DIÁLOGO - MÚLTIPLES MÉTODOS PARA GARANTIZAR CIERRE
//           if (mounted) {
//             setState(() => isProcessing = false);

//             // Método 1: Navigator directo
//             Navigator.of(context).pop();

//             // Método 2: Get.back como fallback (después de un delay mínimo)
//             Future.delayed(const Duration(milliseconds: 100), () {
//               if (Get.isDialogOpen == true) {
//                 Get.back();
//               }
//             });
//           }
//         },
//       );
//     } catch (e) {
//       print('💥 Error al procesar pago: $e');
//       widget.controller._showError(
//         'Error inesperado',
//         'No se pudo procesar el pago',
//       );
//       setState(() => isProcessing = false);
//     }
//   }

//   void _showQuickAmounts() {
//     final balance = widget.remainingBalance;

//     Get.bottomSheet(
//       Container(
//         padding: EdgeInsets.all(context.isMobile ? 16 : 20),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Montos Rápidos',
//               style: TextStyle(
//                 fontSize: context.isMobile ? 16 : 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),

//             // ✅ GRID RESPONSIVO USANDO TU SISTEMA
//             GridView.count(
//               crossAxisCount: context.isMobile ? 2 : 3,
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//               childAspectRatio: context.isMobile ? 2.5 : 3,
//               children: [
//                 _quickAmountButton('Completo', balance),
//                 _quickAmountButton('50%', balance * 0.5),
//                 _quickAmountButton('25%', balance * 0.25),
//                 _quickAmountButton('10%', balance * 0.1),
//                 if (balance >= 100) _quickAmountButton('\$100', 100),
//                 if (balance >= 500) _quickAmountButton('\$500', 500),
//               ],
//             ),
//             const SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _quickAmountButton(String label, double amount) {
//     final isValid = amount > 0 && amount <= widget.remainingBalance;

//     return CustomButton(
//       text: label,
//       type: ButtonType.outline,
//       onPressed:
//           isValid
//               ? () {
//                 amountController.text = amount.toStringAsFixed(2);
//                 Get.back(); // Cerrar bottom sheet
//               }
//               : null,
//       backgroundColor: isValid ? null : Colors.grey.shade200,
//       textColor: isValid ? null : Colors.grey.shade500,
//     );
//   }
// }

class _CreditPaymentDialogContent extends StatefulWidget {
  final InvoiceDetailController controller;
  final double remainingBalance;

  const _CreditPaymentDialogContent({
    required this.controller,
    required this.remainingBalance,
  });

  @override
  State<_CreditPaymentDialogContent> createState() =>
      _CreditPaymentDialogContentState();
}

class _CreditPaymentDialogContentState
    extends State<_CreditPaymentDialogContent> {
  late TextEditingController amountController;
  late TextEditingController referenceController;
  late TextEditingController notesController;
  late GlobalKey<FormState> formKey;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    referenceController = TextEditingController();
    notesController = TextEditingController();
    formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    amountController.dispose();
    referenceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header responsivo
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: Colors.blue.shade600,
              size: context.isMobile ? 20 : 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pago a Crédito',
                style: TextStyle(
                  fontSize: context.isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              iconSize: context.isMobile ? 18 : 20,
              tooltip: 'Cerrar',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Info del saldo
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
              Text(
                'Saldo Pendiente: \$${widget.remainingBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  fontSize: context.isMobile ? 14 : 16,
                ),
              ),
              Text(
                'Puedes realizar un pago parcial o total',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: context.isMobile ? 10 : 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Formulario
        Form(
          key: formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: amountController,
                label: 'Monto del Pago',
                hint: 'Ingresa el monto a abonar',
                prefixIcon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El monto es requerido';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  if (amount > widget.remainingBalance) {
                    return 'El monto excede el saldo pendiente';
                  }
                  return null;
                },
                suffixIcon: Icons.calculate,
                onSuffixIconPressed: () => _showQuickAmounts(),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: referenceController,
                label: 'Referencia (Opcional)',
                hint: 'Número de transferencia, etc.',
                prefixIcon: Icons.receipt_long,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: notesController,
                label: 'Notas (Opcional)',
                hint: 'Notas sobre el pago...',
                prefixIcon: Icons.note,
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ✅ BOTONES CORREGIDOS - RESPONSIVOS
        _buildActionButtons(context),
      ],
    );
  }

  // ✅ MÉTODO SEPARADO PARA BOTONES RESPONSIVOS
  Widget _buildActionButtons(BuildContext context) {
    if (context.isMobile) {
      // Móvil: Botones apilados verticalmente
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: isProcessing ? 'Procesando...' : 'Agregar Pago',
              icon: isProcessing ? null : Icons.add_card,
              onPressed: isProcessing ? null : _processPayment,
              isLoading: isProcessing,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Cancelar',
              type: ButtonType.outline,
              onPressed:
                  isProcessing ? null : () => Navigator.of(context).pop(),
            ),
          ),
        ],
      );
    } else {
      // Tablet/Desktop: Botones en fila
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              type: ButtonType.outline,
              onPressed:
                  isProcessing ? null : () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: isProcessing ? 'Procesando...' : 'Agregar Pago',
              icon: isProcessing ? null : Icons.add_card,
              onPressed: isProcessing ? null : _processPayment,
              isLoading: isProcessing,
            ),
          ),
        ],
      );
    }
  }

  // ✅ MÉTODO CORREGIDO - CIERRE AUTOMÁTICO GARANTIZADO
  Future<void> _processPayment() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isProcessing = true);

    try {
      final amount = double.parse(amountController.text);
      print('💰 Procesando pago a crédito: $amount');

      final result = await widget.controller._addPaymentUseCase(
        AddPaymentParams(
          invoiceId: widget.controller.invoiceId,
          amount: amount,
          paymentMethod: PaymentMethod.credit,
          paymentDate: DateTime.now(),
          reference:
              referenceController.text.isNotEmpty
                  ? referenceController.text
                  : null,
          notes: notesController.text.isNotEmpty ? notesController.text : null,
        ),
      );

      result.fold(
        (failure) {
          widget.controller._showError(
            'Error al agregar pago',
            failure.message,
          );
          setState(() => isProcessing = false);
        },
        (updatedInvoice) {
          print(
            '✅ Pago agregado exitosamente - Nuevo saldo: ${updatedInvoice.balanceDue}',
          );

          // ✅ ACTUALIZAR CONTROLLER
          widget.controller._invoice.value = updatedInvoice;
          widget.controller.update();
          widget.controller._invoice.refresh();

          // ✅ MOSTRAR MENSAJE DE ÉXITO
          widget.controller._showSuccess('Pago agregado exitosamente');

          // ✅ CERRAR DIÁLOGO - MÚLTIPLES MÉTODOS PARA GARANTIZAR CIERRE
          if (mounted) {
            setState(() => isProcessing = false);

            // Método 1: Navigator directo
            Navigator.of(context).pop();

            // Método 2: Get.back como fallback (después de un delay mínimo)
            Future.delayed(const Duration(milliseconds: 100), () {
              if (Get.isDialogOpen == true) {
                Get.back();
              }
            });
          }
        },
      );
    } catch (e) {
      print('💥 Error al procesar pago: $e');
      widget.controller._showError(
        'Error inesperado',
        'No se pudo procesar el pago',
      );
      setState(() => isProcessing = false);
    }
  }

  void _showQuickAmounts() {
    final balance = widget.remainingBalance;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Montos Rápidos',
              style: TextStyle(
                fontSize: context.isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // ✅ GRID RESPONSIVO USANDO TU SISTEMA
            GridView.count(
              crossAxisCount: context.isMobile ? 2 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: context.isMobile ? 2.5 : 3,
              children: [
                _quickAmountButton('Completo', balance),
                _quickAmountButton('50%', balance * 0.5),
                _quickAmountButton('25%', balance * 0.25),
                _quickAmountButton('10%', balance * 0.1),
                if (balance >= 100) _quickAmountButton('\$100', 100),
                if (balance >= 500) _quickAmountButton('\$500', 500),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _quickAmountButton(String label, double amount) {
    final isValid = amount > 0 && amount <= widget.remainingBalance;

    return CustomButton(
      text: label,
      type: ButtonType.outline,
      onPressed:
          isValid
              ? () {
                amountController.text = amount.toStringAsFixed(2);
                Get.back(); // Cerrar bottom sheet
              }
              : null,
      backgroundColor: isValid ? null : Colors.grey.shade200,
      textColor: isValid ? null : Colors.grey.shade500,
    );
  }
}
