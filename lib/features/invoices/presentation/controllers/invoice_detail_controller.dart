// lib/features/invoices/presentation/controllers/invoice_detail_controller.dart
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

    if (invoiceId.isNotEmpty) {
      loadInvoice();
    } else {
      _showError('Error', 'ID de factura no válido');
      Get.back();
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
          Get.back();
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
          hidePaymentForm();
          _showSuccess('Pago agregado exitosamente');
        },
      );
    } catch (e) {
      print('💥 Error al agregar pago: $e');
      _showError('Error inesperado', 'No se pudo agregar el pago');
    } finally {
      _isProcessing.value = false;
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

    Get.toNamed('/invoices/create', parameters: {'duplicate_from': invoiceId});
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
