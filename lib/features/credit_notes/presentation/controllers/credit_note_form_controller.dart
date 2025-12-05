// lib/features/credit_notes/presentation/controllers/credit_note_form_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/credit_note.dart';
import '../../domain/entities/credit_note_item.dart';
import '../../domain/repositories/credit_note_repository.dart';
import '../../domain/usecases/create_credit_note.dart';
import '../../domain/usecases/update_credit_note.dart';
import '../../domain/usecases/get_credit_note_by_id.dart';
import '../../domain/usecases/get_remaining_creditable_amount.dart';
import '../../domain/usecases/get_available_quantities_for_credit_note.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/domain/usecases/get_invoice_by_id_usecase.dart';

class CreditNoteFormController extends GetxController {
  // Dependencies
  final CreateCreditNote _createCreditNoteUseCase;
  final UpdateCreditNote _updateCreditNoteUseCase;
  final GetCreditNoteById _getCreditNoteByIdUseCase;
  final GetRemainingCreditableAmount _getRemainingCreditableAmountUseCase;
  final GetAvailableQuantitiesForCreditNote _getAvailableQuantitiesUseCase;
  final GetInvoiceByIdUseCase _getInvoiceByIdUseCase;

  CreditNoteFormController({
    required CreateCreditNote createCreditNoteUseCase,
    required UpdateCreditNote updateCreditNoteUseCase,
    required GetCreditNoteById getCreditNoteByIdUseCase,
    required GetRemainingCreditableAmount getRemainingCreditableAmountUseCase,
    required GetAvailableQuantitiesForCreditNote getAvailableQuantitiesUseCase,
    required GetInvoiceByIdUseCase getInvoiceByIdUseCase,
  })  : _createCreditNoteUseCase = createCreditNoteUseCase,
        _updateCreditNoteUseCase = updateCreditNoteUseCase,
        _getCreditNoteByIdUseCase = getCreditNoteByIdUseCase,
        _getRemainingCreditableAmountUseCase = getRemainingCreditableAmountUseCase,
        _getAvailableQuantitiesUseCase = getAvailableQuantitiesUseCase,
        _getInvoiceByIdUseCase = getInvoiceByIdUseCase;

  // ==================== OBSERVABLES ====================

  final _isLoading = false.obs;
  final _isSaving = false.obs;
  final _isEditMode = false.obs;

  // Datos
  final _creditNote = Rxn<CreditNote>();
  final _invoice = Rxn<Invoice>();
  final _remainingCreditableAmount = 0.0.obs;

  // Cantidades disponibles para nota de crédito
  final _availableQuantities = Rxn<AvailableQuantitiesResponse>();
  final _isLoadingAvailableQuantities = false.obs;

  // Formulario
  final _selectedType = CreditNoteType.partial.obs;
  final _selectedReason = CreditNoteReason.returnedGoods.obs;
  final _date = DateTime.now().obs;
  final _items = <CreditNoteItem>[].obs;
  final _taxPercentage = 19.0.obs;
  final _notes = ''.obs;
  final _terms = ''.obs;
  final _restoreInventory = true.obs;

  // Form key y controllers
  final formKey = GlobalKey<FormState>();
  final numberController = TextEditingController();
  final notesController = TextEditingController();
  final termsController = TextEditingController();
  final reasonDescriptionController = TextEditingController();

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;
  bool get isEditMode => _isEditMode.value;
  bool get canSave => _items.isNotEmpty && (_invoice.value != null || isEditMode);

  CreditNote? get creditNote => _creditNote.value;
  Invoice? get invoice => _invoice.value;
  double get remainingCreditableAmount => _remainingCreditableAmount.value;

  // Cantidades disponibles
  AvailableQuantitiesResponse? get availableQuantities => _availableQuantities.value;
  bool get isLoadingAvailableQuantities => _isLoadingAvailableQuantities.value;
  bool get hasAvailableQuantities => _availableQuantities.value != null;
  bool get canCreateFullCreditNote => _availableQuantities.value?.canCreateFullCreditNote ?? false;
  bool get canCreatePartialCreditNote => _availableQuantities.value?.canCreatePartialCreditNote ?? true;
  List<AvailableQuantityItem> get availableItems => _availableQuantities.value?.availableItems ?? [];
  List<DraftCreditNoteSummary> get draftCreditNotes => _availableQuantities.value?.draftCreditNotes ?? [];
  bool get hasDraftCreditNotes => _availableQuantities.value?.hasDraftCreditNotes ?? false;

  CreditNoteType get selectedType => _selectedType.value;
  CreditNoteReason get selectedReason => _selectedReason.value;
  DateTime get date => _date.value;
  List<CreditNoteItem> get items => _items;
  double get taxPercentage => _taxPercentage.value;
  String get notes => _notes.value;
  String get terms => _terms.value;
  bool get restoreInventory => _restoreInventory.value;

  // Cálculos
  // IMPORTANTE: item.subtotal contiene el precio CON IVA incluido (quantity * unitPrice - descuento)
  // Este es el TOTAL de la nota de crédito
  // El subtotal (sin IVA) se calcula extrayendo el IVA del total
  double get total => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get subtotal => total / (1 + taxPercentage / 100);
  double get taxAmount => total - subtotal;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    _initializeForm();
  }

  @override
  void onClose() {
    numberController.dispose();
    notesController.dispose();
    termsController.dispose();
    reasonDescriptionController.dispose();
    super.onClose();
  }

  Future<void> _initializeForm() async {
    print('🔧 CreditNoteFormController._initializeForm: Iniciando...');
    print('🔧 Get.parameters: ${Get.parameters}');
    print('🔧 Get.arguments: ${Get.arguments}');
    print('🔧 Get.arguments type: ${Get.arguments?.runtimeType}');

    String? id;
    String? invoiceId;

    // Primero intentar obtener de arguments (navegación con Get.to)
    // porque es la forma más común de pasar datos en esta app
    if (Get.arguments != null) {
      final args = Get.arguments;
      if (args is Map<String, dynamic>) {
        id = args['id']?.toString();
        invoiceId = args['invoiceId']?.toString();
        print('📋 CreditNoteFormController: Args como Map - id: $id, invoiceId: $invoiceId');
      } else if (args is Map) {
        id = args['id']?.toString();
        invoiceId = args['invoiceId']?.toString();
        print('📋 CreditNoteFormController: Args como Map genérico - id: $id, invoiceId: $invoiceId');
      }
    }

    // Si no hay en arguments, intentar parameters (rutas con parámetros en URL)
    if (id == null && invoiceId == null) {
      id = Get.parameters['id'];
      invoiceId = Get.parameters['invoiceId'];
      print('📋 CreditNoteFormController: Usando parameters - id: $id, invoiceId: $invoiceId');
    }

    print('🔧 CreditNoteFormController: Valores finales - id: $id, invoiceId: $invoiceId');

    if (id != null && id.isNotEmpty) {
      // Modo edición
      print('📝 CreditNoteFormController: Modo EDICIÓN - cargando nota de crédito $id');
      _isEditMode.value = true;
      await _loadCreditNote(id);
    } else if (invoiceId != null && invoiceId.isNotEmpty) {
      // Modo creación con factura preseleccionada
      print('📝 CreditNoteFormController: Modo CREACIÓN - cargando factura $invoiceId');
      await _loadInvoice(invoiceId);
      // Cargar cantidades disponibles (incluye el monto acreditable)
      await loadAvailableQuantities(invoiceId);
    } else {
      print('⚠️ CreditNoteFormController: No se recibió id ni invoiceId válidos');
    }
  }

  // ==================== DATA LOADING ====================

  Future<void> _loadCreditNote(String id) async {
    _isLoading.value = true;

    try {
      final result = await _getCreditNoteByIdUseCase(id);

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          Get.back();
        },
        (creditNote) {
          _creditNote.value = creditNote;
          _populateFormFromCreditNote(creditNote);
          if (creditNote.invoice != null) {
            _invoice.value = creditNote.invoice;
          }
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadInvoice(String invoiceId) async {
    _isLoading.value = true;

    try {
      final result = await _getInvoiceByIdUseCase(GetInvoiceByIdParams(id: invoiceId));

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        (invoice) {
          _invoice.value = invoice;
          _taxPercentage.value = invoice.taxPercentage;
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Carga las cantidades disponibles para crear notas de crédito
  Future<void> loadAvailableQuantities(String invoiceId) async {
    _isLoadingAvailableQuantities.value = true;

    try {
      print('📊 CreditNoteFormController: Cargando cantidades disponibles para factura $invoiceId');
      final result = await _getAvailableQuantitiesUseCase(invoiceId);

      result.fold(
        (failure) {
          print('❌ Error al obtener cantidades disponibles: ${failure.message}');
          Get.snackbar(
            'Error',
            'No se pudieron cargar las cantidades disponibles: ${failure.message}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        },
        (response) {
          _availableQuantities.value = response;
          _remainingCreditableAmount.value = response.remainingCreditableAmount;

          print('✅ Cantidades disponibles cargadas:');
          print('   - Items disponibles: ${response.availableItems.length}');
          print('   - Monto acreditable: ${response.remainingCreditableAmount}');
          print('   - Puede crear completa: ${response.canCreateFullCreditNote}');
          print('   - Puede crear parcial: ${response.canCreatePartialCreditNote}');

          // Mostrar mensaje informativo si hay notas en borrador
          if (response.hasDraftCreditNotes) {
            final draftNumbers = response.draftCreditNotes.map((d) => d.number).join(', ');
            Get.snackbar(
              'Notas de Crédito en Borrador',
              'Existen notas de crédito en borrador ($draftNumbers) que afectan las cantidades disponibles.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.blue,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          }

          // Mostrar mensaje si no se puede crear nota de crédito
          if (!response.canCreatePartialCreditNote) {
            Get.snackbar(
              'No Disponible',
              response.message ?? 'No hay cantidades disponibles para crear notas de crédito.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        },
      );
    } catch (e) {
      print('❌ Error inesperado al obtener cantidades disponibles: $e');
    } finally {
      _isLoadingAvailableQuantities.value = false;
    }
  }

  /// Obtiene la cantidad disponible para un item de factura específico
  AvailableQuantityItem? getAvailableQuantityForItem(String invoiceItemId) {
    return _availableQuantities.value?.items.firstWhereOrNull(
      (item) => item.invoiceItemId == invoiceItemId,
    );
  }

  /// Verifica si un item de factura tiene cantidad disponible para acreditar
  bool hasAvailableQuantityForItem(String invoiceItemId) {
    final item = getAvailableQuantityForItem(invoiceItemId);
    return item != null && item.availableQuantity > 0;
  }

  /// Obtiene la cantidad máxima que se puede acreditar para un item
  double getMaxCreditableQuantity(String invoiceItemId) {
    final item = getAvailableQuantityForItem(invoiceItemId);
    return item?.availableQuantity ?? 0;
  }

  void _populateFormFromCreditNote(CreditNote creditNote) {
    numberController.text = creditNote.number;
    _selectedType.value = creditNote.type;
    _selectedReason.value = creditNote.reason;
    reasonDescriptionController.text = creditNote.reasonDescription ?? '';
    _date.value = creditNote.date;
    _items.value = List.from(creditNote.items);
    _taxPercentage.value = creditNote.taxPercentage;
    _restoreInventory.value = creditNote.restoreInventory;
    notesController.text = creditNote.notes ?? '';
    termsController.text = creditNote.terms ?? '';
  }

  // ==================== FORM ACTIONS ====================

  void setType(CreditNoteType type) {
    // Verificar si se puede crear nota de crédito completa
    if (type == CreditNoteType.full && !canCreateFullCreditNote) {
      Get.snackbar(
        'No Disponible',
        'No se puede crear una nota de crédito completa porque ya existen notas de crédito aplicadas o en borrador para esta factura.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    _selectedType.value = type;

    // Si es crédito completo, agregar todos los items con cantidades disponibles
    if (type == CreditNoteType.full && invoice != null) {
      _items.clear();

      // Usar cantidades disponibles si están cargadas
      if (hasAvailableQuantities) {
        for (var availableItem in availableItems) {
          if (availableItem.availableQuantity <= 0) continue;

          // IMPORTANTE: El subtotal debe ser el precio CON IVA (quantity * unitPrice)
          final double itemTotal = availableItem.availableQuantity * availableItem.unitPrice;

          _items.add(CreditNoteItem(
            id: '',
            description: availableItem.description,
            quantity: availableItem.availableQuantity,
            unitPrice: availableItem.unitPrice,
            discountPercentage: 0,
            discountAmount: 0,
            subtotal: itemTotal,
            unit: availableItem.unit,
            creditNoteId: '',
            productId: availableItem.productId,
            invoiceItemId: availableItem.invoiceItemId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      } else {
        // Fallback: usar items de factura originales
        for (var invoiceItem in invoice!.items) {
          final double itemTotal = invoiceItem.quantity * invoiceItem.unitPrice;
          // Calcular descuento: usar porcentaje si es mayor a 0, sino usar monto fijo
          final double discountAmount = invoiceItem.discountPercentage > 0
              ? itemTotal * (invoiceItem.discountPercentage / 100)
              : invoiceItem.discountAmount;
          final double subtotalWithTax = itemTotal - discountAmount;

          _items.add(CreditNoteItem(
            id: '',
            description: invoiceItem.description,
            quantity: invoiceItem.quantity,
            unitPrice: invoiceItem.unitPrice,
            discountPercentage: invoiceItem.discountPercentage,
            discountAmount: discountAmount,
            subtotal: subtotalWithTax,
            unit: invoiceItem.unit,
            creditNoteId: '',
            productId: invoiceItem.productId,
            invoiceItemId: invoiceItem.id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }
    }
  }

  void setRestoreInventory(bool value) {
    _restoreInventory.value = value;
  }

  void setReason(CreditNoteReason reason) {
    _selectedReason.value = reason;
  }

  void setDate(DateTime newDate) {
    _date.value = newDate;
  }

  void setTaxPercentage(double percentage) {
    _taxPercentage.value = percentage;
  }

  // ==================== ITEMS MANAGEMENT ====================

  void addItem(CreditNoteItem item) {
    _items.add(item);
  }

  void updateItem(int index, CreditNoteItem item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      _items.refresh();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
    }
  }

  void clearItems() {
    _items.clear();
  }

  // ==================== SAVE ====================

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar(
        'Formulario Incompleto',
        'Por favor complete todos los campos requeridos',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (_items.isEmpty) {
      Get.snackbar(
        'Items Requeridos',
        'Debe agregar al menos un item a la nota de crédito',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (!isEditMode && invoice == null) {
      Get.snackbar(
        'Factura Requerida',
        'Debe seleccionar una factura',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Validar que el total no exceda el monto acreditable restante
    if (!isEditMode && hasAvailableQuantities) {
      if (total > remainingCreditableAmount) {
        Get.snackbar(
          'Monto Excedido',
          'El total de la nota de crédito (\$${total.toStringAsFixed(0)}) excede el monto acreditable restante (\$${remainingCreditableAmount.toStringAsFixed(0)})',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // Validar que cada item no exceda la cantidad disponible
      for (var item in _items) {
        if (item.invoiceItemId != null) {
          final availableItem = getAvailableQuantityForItem(item.invoiceItemId!);
          if (availableItem != null && item.quantity > availableItem.availableQuantity) {
            Get.snackbar(
              'Cantidad Excedida',
              'El item "${item.description}" tiene cantidad ${item.quantity} pero solo hay ${availableItem.availableQuantity} disponible',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            return;
          }
        }
      }
    }

    _isSaving.value = true;

    try {
      if (isEditMode) {
        await _updateExistingCreditNote();
      } else {
        await _createNewCreditNote();
      }
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> _createNewCreditNote() async {
    final params = CreateCreditNoteParams(
      invoiceId: invoice!.id,
      number: numberController.text.isNotEmpty ? numberController.text : null,
      date: date,
      type: selectedType,
      reason: selectedReason,
      reasonDescription: reasonDescriptionController.text.isNotEmpty
          ? reasonDescriptionController.text
          : null,
      items: _items
          .map((item) => CreateCreditNoteItemParams(
                productId: item.productId,
                invoiceItemId: item.invoiceItemId,
                description: item.description,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                discountPercentage: item.discountPercentage,
                discountAmount: item.discountAmount,
                unit: item.unit,
                notes: item.notes,
              ))
          .toList(),
      taxPercentage: taxPercentage,
      restoreInventory: restoreInventory,
      notes: notesController.text.isNotEmpty ? notesController.text : null,
      terms: termsController.text.isNotEmpty ? termsController.text : null,
    );

    final result = await _createCreditNoteUseCase(params);

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
      (creditNote) {
        Get.back(result: creditNote);
        Get.snackbar(
          'Creada',
          'Nota de crédito creada exitosamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }

  Future<void> _updateExistingCreditNote() async {
    if (creditNote == null) return;

    // NOTA: El backend solo permite actualizar reason, reasonDescription, restoreInventory, notes, terms
    // Solo se pueden actualizar notas de crédito en estado DRAFT
    final params = UpdateCreditNoteParams(
      id: creditNote!.id,
      reason: selectedReason,
      reasonDescription: reasonDescriptionController.text.isNotEmpty
          ? reasonDescriptionController.text
          : null,
      restoreInventory: restoreInventory,
      notes: notesController.text.isNotEmpty ? notesController.text : null,
      terms: termsController.text.isNotEmpty ? termsController.text : null,
    );

    final result = await _updateCreditNoteUseCase(params);

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
      (updatedCreditNote) {
        Get.back(result: updatedCreditNote);
        Get.snackbar(
          'Actualizada',
          'Nota de crédito actualizada exitosamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }
}
