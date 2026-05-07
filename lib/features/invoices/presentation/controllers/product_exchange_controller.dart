// lib/features/invoices/presentation/controllers/product_exchange_controller.dart
//
// Controller de la pantalla "Cambio de producto". Orquesta:
//   - Carga la factura original (lista de items que se pueden devolver).
//   - Mantiene el estado de items devueltos + items nuevos a entregar.
//   - Calcula totales y la diferencia en tiempo real.
//   - Llama a ExchangeProductsUseCase para procesar el cambio.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../credit_notes/domain/entities/credit_note.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/product_exchange.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/usecases/exchange_products_usecase.dart';

class ProductExchangeController extends GetxController {
  final ExchangeProductsUseCase _exchangeUseCase;
  final InvoiceRepository _invoiceRepository;

  ProductExchangeController({
    required ExchangeProductsUseCase exchangeUseCase,
    required InvoiceRepository invoiceRepository,
  })  : _exchangeUseCase = exchangeUseCase,
        _invoiceRepository = invoiceRepository;

  // ==================== STATE ====================

  /// ID de la factura original recibido como argumento de ruta.
  late final String originalInvoiceId;

  /// Factura original cargada de ISAR (o servidor).
  final Rxn<Invoice> _originalInvoice = Rxn<Invoice>();
  Invoice? get originalInvoice => _originalInvoice.value;

  /// Items que se están devolviendo. La key es el invoiceItemId.
  final RxMap<String, ExchangeReturnedItem> _returnedItems =
      <String, ExchangeReturnedItem>{}.obs;
  Map<String, ExchangeReturnedItem> get returnedItems => _returnedItems;

  /// Items nuevos a entregar.
  final RxList<ExchangeNewItem> _newItems = <ExchangeNewItem>[].obs;
  List<ExchangeNewItem> get newItems => _newItems;

  /// Modo de conciliación elegido por el usuario.
  final Rx<ExchangeSettlementMode> _settlementMode =
      ExchangeSettlementMode.exact.obs;
  ExchangeSettlementMode get settlementMode => _settlementMode.value;
  set settlementMode(ExchangeSettlementMode m) => _settlementMode.value = m;

  /// Razón del cambio (default: other).
  final Rx<CreditNoteReason> _reason = CreditNoteReason.other.obs;
  CreditNoteReason get reason => _reason.value;
  set reason(CreditNoteReason r) => _reason.value = r;

  final RxString _reasonDescription = ''.obs;
  String get reasonDescription => _reasonDescription.value;
  set reasonDescription(String v) => _reasonDescription.value = v;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxBool _isProcessing = false.obs;
  bool get isProcessing => _isProcessing.value;

  final RxnString _error = RxnString();
  String? get error => _error.value;

  // ==================== COMPUTED ====================

  /// Total de lo que el cliente devuelve.
  double get totalReturned =>
      _returnedItems.values.fold(0.0, (sum, i) => sum + i.subtotal);

  /// Total de lo que se entrega.
  double get totalDelivered =>
      _newItems.fold(0.0, (sum, i) => sum + i.subtotal);

  /// Diferencia: positiva = cliente debe pagar, negativa = a su favor.
  double get difference => totalDelivered - totalReturned;

  /// Texto de ayuda según la diferencia.
  String get differenceLabel {
    final d = difference;
    if (d == 0) return 'Cambio neto';
    if (d > 0) return 'Cliente paga';
    return 'A favor del cliente';
  }

  /// Modos de conciliación válidos según la diferencia actual.
  List<ExchangeSettlementMode> get availableSettlementModes {
    final d = difference;
    if (d == 0) return [ExchangeSettlementMode.exact];
    if (d > 0) return [ExchangeSettlementMode.cashPayment];
    return [
      ExchangeSettlementMode.storeCredit,
      ExchangeSettlementMode.cashRefund,
    ];
  }

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    originalInvoiceId = (Get.arguments as Map?)?['invoiceId'] as String? ??
        Get.parameters['id'] ??
        '';
    if (originalInvoiceId.isEmpty) {
      _error.value = 'No se recibió ID de factura';
      return;
    }
    _loadOriginalInvoice();
  }

  Future<void> _loadOriginalInvoice() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final result = await _invoiceRepository.getInvoiceById(originalInvoiceId);
      result.fold(
        (failure) {
          _error.value = failure.message;
          AppLogger.e(
            'ProductExchange: error cargando factura original: ${failure.message}',
          );
        },
        (invoice) {
          _originalInvoice.value = invoice;
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // ==================== ACCIONES ====================

  /// Selecciona o actualiza un item devuelto. Si quantity == 0, lo quita.
  void setReturnedItem(InvoiceItem invoiceItem, double quantity) {
    if (quantity <= 0) {
      _returnedItems.remove(invoiceItem.id);
      _recalculateSettlementMode();
      return;
    }
    if (quantity > invoiceItem.quantity) {
      Get.snackbar(
        'Cantidad inválida',
        'No puede devolver más de lo facturado (${invoiceItem.quantity.toStringAsFixed(0)})',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    _returnedItems[invoiceItem.id] = ExchangeReturnedItem(
      invoiceItemId: invoiceItem.id,
      quantity: quantity,
      unitPrice: invoiceItem.unitPrice,
      description: invoiceItem.description,
      productId: invoiceItem.productId,
      unit: invoiceItem.unit,
    );
    _recalculateSettlementMode();
  }

  /// Agrega un item nuevo (a entregar al cliente).
  void addNewItem(ExchangeNewItem item) {
    _newItems.add(item);
    _recalculateSettlementMode();
  }

  /// Remueve un item nuevo por índice.
  void removeNewItem(int index) {
    if (index < 0 || index >= _newItems.length) return;
    _newItems.removeAt(index);
    _recalculateSettlementMode();
  }

  void _recalculateSettlementMode() {
    final available = availableSettlementModes;
    if (!available.contains(_settlementMode.value)) {
      // El modo actual ya no aplica → poner el primero disponible.
      _settlementMode.value = available.first;
    }
  }

  /// Procesa el cambio. Devuelve null si tuvo éxito (la pantalla cierra),
  /// o un mensaje de error.
  Future<ProductExchangeResult?> processExchange() async {
    if (_isProcessing.value) return null;
    if (_returnedItems.isEmpty) {
      Get.snackbar(
        'Sin items devueltos',
        'Debe seleccionar al menos un item para devolver',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    }

    _isProcessing.value = true;
    try {
      final invoice = _originalInvoice.value;
      if (invoice == null) {
        _error.value = 'Factura original no cargada';
        return null;
      }

      final request = ProductExchangeRequest(
        originalInvoiceId: originalInvoiceId,
        customerId: invoice.customerId,
        returnedItems: _returnedItems.values.toList(),
        newItems: _newItems.toList(),
        settlementMode: _settlementMode.value,
        reason: _reason.value,
        reasonDescription:
            _reasonDescription.value.isEmpty ? null : _reasonDescription.value,
        restoreInventory: true,
      );

      final result = await _exchangeUseCase(request);
      return result.fold(
        (failure) {
          _error.value = failure.message;
          if (failure is CompositeExchangeFailure) {
            Get.snackbar(
              'Cambio parcialmente completado',
              'Nota crédito creada (${failure.creditNote.number}) pero la '
                  'factura nueva falló. Puede reintentarla desde el detalle.',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 8),
              backgroundColor: Colors.orange.shade100,
              colorText: Colors.orange.shade900,
            );
          } else {
            Get.snackbar(
              'Error al procesar cambio',
              failure.message,
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red.shade100,
              colorText: Colors.red.shade900,
            );
          }
          return null;
        },
        (result) {
          Get.snackbar(
            'Cambio completado',
            _buildSuccessMessage(result),
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade900,
          );
          return result;
        },
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  String _buildSuccessMessage(ProductExchangeResult r) {
    final parts = <String>['NC ${r.creditNote.number} creada'];
    if (r.newInvoice != null) {
      parts.add('factura nueva ${r.newInvoice!.number} creada');
    }
    if (r.customerCredit != null) {
      parts.add('saldo a favor \$${r.settledAsCredit.toStringAsFixed(0)}');
    }
    if (r.settledInCash > 0) {
      parts.add('efectivo \$${r.settledInCash.toStringAsFixed(0)}');
    }
    return parts.join(' · ');
  }
}
