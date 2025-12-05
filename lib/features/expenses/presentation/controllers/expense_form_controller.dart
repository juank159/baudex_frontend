// lib/features/expenses/presentation/controllers/expense_form_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/usecases/create_expense_usecase.dart';
import '../../domain/usecases/update_expense_usecase.dart';
import '../../domain/usecases/get_expense_by_id_usecase.dart';
import '../../domain/usecases/get_expense_categories_usecase.dart';
import '../../domain/usecases/create_expense_category_usecase.dart';
import '../../domain/usecases/update_expense_category_usecase.dart';
import '../../domain/usecases/upload_attachments_usecase.dart';
import '../../domain/usecases/delete_attachment_usecase.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/services/file_service.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/utils/subscription_error_handler.dart';
import 'package:dartz/dartz.dart';

class ExpenseFormController extends GetxController {
  // Dependencies
  final CreateExpenseUseCase _createExpenseUseCase;
  final UpdateExpenseUseCase _updateExpenseUseCase;
  final GetExpenseByIdUseCase _getExpenseByIdUseCase;
  final GetExpenseCategoriesUseCase _getExpenseCategoriesUseCase;
  final CreateExpenseCategoryUseCase _createExpenseCategoryUseCase;
  final UpdateExpenseCategoryUseCase _updateExpenseCategoryUseCase;
  final UploadAttachmentsUseCase _uploadAttachmentsUseCase;
  final DeleteAttachmentUseCase _deleteAttachmentUseCase;
  final FileService _fileService;

  ExpenseFormController({
    required CreateExpenseUseCase createExpenseUseCase,
    required UpdateExpenseUseCase updateExpenseUseCase,
    required GetExpenseByIdUseCase getExpenseByIdUseCase,
    required GetExpenseCategoriesUseCase getExpenseCategoriesUseCase,
    required CreateExpenseCategoryUseCase createExpenseCategoryUseCase,
    required UpdateExpenseCategoryUseCase updateExpenseCategoryUseCase,
    required UploadAttachmentsUseCase uploadAttachmentsUseCase,
    required DeleteAttachmentUseCase deleteAttachmentUseCase,
    required FileService fileService,
  }) : _createExpenseUseCase = createExpenseUseCase,
       _updateExpenseUseCase = updateExpenseUseCase,
       _getExpenseByIdUseCase = getExpenseByIdUseCase,
       _getExpenseCategoriesUseCase = getExpenseCategoriesUseCase,
       _createExpenseCategoryUseCase = createExpenseCategoryUseCase,
       _updateExpenseCategoryUseCase = updateExpenseCategoryUseCase,
       _uploadAttachmentsUseCase = uploadAttachmentsUseCase,
       _deleteAttachmentUseCase = deleteAttachmentUseCase,
       _fileService = fileService;

  // Form
  final formKey = GlobalKey<FormState>();

  // Controllers
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  
  // Observables para campos de texto (para reactividad)
  final _description = ''.obs;
  final _amount = ''.obs;
  final vendorController = TextEditingController();
  final invoiceNumberController = TextEditingController();
  final referenceController = TextEditingController();
  final notesController = TextEditingController();
  final tagsController = TextEditingController();

  // Estado
  final _isLoading = false.obs;
  final _isSaving = false.obs;
  final _isLoadingCategories = false.obs;
  final _isUploadingAttachments = false.obs;
  final _uploadProgress = 0.0.obs;

  // Datos del formulario
  final selectedDate = Rxn<DateTime>();
  final selectedCategory = Rxn<ExpenseCategory>();
  final selectedType = Rxn<ExpenseType>();
  final selectedPaymentMethod = Rxn<PaymentMethod>();
  final attachments = <AttachmentFile>[].obs;
  final tags = <String>[].obs;

  // Categorías disponibles
  final categories = <ExpenseCategory>[].obs;

  // Datos para edición
  final _expenseId = Rxn<String>();
  final _originalExpense = Rxn<Expense>();

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;
  bool get isLoadingCategories => _isLoadingCategories.value;
  bool get isUploadingAttachments => _isUploadingAttachments.value;
  double get uploadProgress => _uploadProgress.value;
  bool get isEditMode => _expenseId.value != null;

  bool get canSave {
    return _description.value.trim().isNotEmpty &&
           _amount.value.trim().isNotEmpty &&
           selectedDate.value != null &&
           selectedCategory.value != null &&
           selectedType.value != null &&
           selectedPaymentMethod.value != null &&
           !_isSaving.value &&
           _isValidAmount(_amount.value) &&
           _isValidDescription(_description.value);
  }

  bool get hasUnsavedChanges {
    if (!isEditMode) {
      return _description.value.trim().isNotEmpty ||
             _amount.value.trim().isNotEmpty ||
             selectedDate.value != null ||
             selectedCategory.value != null ||
             selectedType.value != null ||
             selectedPaymentMethod.value != null ||
             vendorController.text.trim().isNotEmpty ||
             invoiceNumberController.text.trim().isNotEmpty ||
             referenceController.text.trim().isNotEmpty ||
             notesController.text.trim().isNotEmpty ||
             attachments.isNotEmpty ||
             tags.isNotEmpty;
    }

    final original = _originalExpense.value;
    if (original == null) return false;

    return _description.value.trim() != original.description ||
           (AppFormatters.parseNumber(_amount.value) ?? 0) != original.amount ||
           selectedDate.value != original.date ||
           selectedCategory.value?.id != original.categoryId ||
           selectedType.value != original.type ||
           selectedPaymentMethod.value != original.paymentMethod ||
           vendorController.text.trim() != (original.vendor ?? '') ||
           invoiceNumberController.text.trim() != (original.invoiceNumber ?? '') ||
           referenceController.text.trim() != (original.reference ?? '') ||
           notesController.text.trim() != (original.notes ?? '') ||
           !_listsEqual(attachments.map((a) => a.name).toList(), original.attachments ?? []) ||
           !_listsEqual(tags, original.tags ?? []);
  }

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
    
    // Verificar si es modo edición
    final expenseId = Get.parameters['id'];
    if (expenseId != null) {
      _expenseId.value = expenseId;
    }
  }

  @override
  void onReady() {
    super.onReady();
    _initializeData();
  }

  @override
  void onClose() {
    descriptionController.dispose();
    amountController.dispose();
    vendorController.dispose();
    invoiceNumberController.dispose();
    referenceController.dispose();
    notesController.dispose();
    tagsController.dispose();
    super.onClose();
  }

  // Inicialización
  Future<void> _initializeData() async {
    await loadCategories();
    
    if (isEditMode) {
      await _loadExpenseForEditing();
    } else {
      _setDefaultValues();
    }
  }

  void _setupListeners() {
    // Listener para actualizar tags
    tagsController.addListener(() {
      updateTags(tagsController.text);
    });
    
    // Listeners para campos requeridos - sincronizar con observables
    descriptionController.addListener(() {
      _description.value = descriptionController.text;
    });
    
    amountController.addListener(() {
      _amount.value = amountController.text;
    });
  }

  void _setDefaultValues() {
    selectedDate.value = DateTime.now();
    selectedType.value = ExpenseType.operating;
    selectedPaymentMethod.value = PaymentMethod.cash;
  }

  Future<void> _loadExpenseForEditing() async {
    if (_expenseId.value == null) return;

    _isLoading.value = true;

    try {
      final result = await _getExpenseByIdUseCase(
        GetExpenseByIdParams(id: _expenseId.value!),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar gasto', failure.message);
          Get.back();
        },
        (expense) {
          _originalExpense.value = expense;
          _populateFormWithExpense(expense);
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _populateFormWithExpense(Expense expense) {
    descriptionController.text = expense.description;
    amountController.text = AppFormatters.formatNumber(expense.amount);
    
    // Sincronizar observables
    _description.value = expense.description;
    _amount.value = AppFormatters.formatNumber(expense.amount);
    selectedDate.value = expense.date;
    selectedType.value = expense.type;
    selectedPaymentMethod.value = expense.paymentMethod;
    vendorController.text = expense.vendor ?? '';
    invoiceNumberController.text = expense.invoiceNumber ?? '';
    referenceController.text = expense.reference ?? '';
    notesController.text = expense.notes ?? '';
    
    // Buscar la categoría
    final category = categories.firstWhereOrNull(
      (cat) => cat.id == expense.categoryId,
    );
    selectedCategory.value = category;
    
    // Establecer adjuntos y etiquetas
    // Los adjuntos se cargarán como nombres de archivo por ahora
    // En una implementación completa, aquí se descargarían los archivos del servidor
    final attachmentNames = expense.attachments ?? [];
    attachments.clear();
    for (final name in attachmentNames) {
      // Crear objetos AttachmentFile placeholder para archivos existentes
      attachments.add(AttachmentFile(
        name: name,
        size: 0, // Tamaño desconocido para archivos existentes
        mimeType: 'application/octet-stream',
        path: '', // Sin path local para archivos del servidor
        isImage: name.toLowerCase().endsWith('.jpg') || 
                name.toLowerCase().endsWith('.jpeg') || 
                name.toLowerCase().endsWith('.png'),
      ));
    }
    
    tags.value = List<String>.from(expense.tags ?? []);
    tagsController.text = tags.join(', ');
  }

  // Cargar categorías
  Future<void> loadCategories({bool withStats = true}) async {
    _isLoadingCategories.value = true;

    try {
      final result = await _getExpenseCategoriesUseCase(
        GetExpenseCategoriesParams(
          limit: 100,
          withStats: withStats,
        ),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar categorías', failure.message);
          categories.clear();
        },
        (paginatedResult) {
          categories.value = paginatedResult.data;

          // Si no estamos en modo edición y no hay categoría seleccionada,
          // seleccionar la primera categoría automáticamente
          if (!isEditMode && selectedCategory.value == null && categories.isNotEmpty) {
            selectedCategory.value = categories.first;
          }
        },
      );
    } finally {
      _isLoadingCategories.value = false;
    }
  }

  // Guardar gasto como aprobado (comportamiento por defecto)
  Future<bool> saveExpense() async {
    return await _saveExpenseWithStatus(ExpenseStatus.approved);
  }

  // Guardar gasto como borrador
  Future<bool> saveExpenseAsDraft() async {
    return await _saveExpenseWithStatus(ExpenseStatus.draft);
  }

  // Método privado para guardar con status específico
  Future<bool> _saveExpenseWithStatus(ExpenseStatus status) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (!canSave) {
      _showError('Error', 'Complete todos los campos requeridos');
      return false;
    }

    _isSaving.value = true;

    try {
      if (isEditMode) {
        return await _updateExpense();
      } else {
        return await _createExpenseWithStatus(status);
      }
    } finally {
      _isSaving.value = false;
    }
  }

  Future<bool> _createExpenseWithStatus(ExpenseStatus status) async {
    try {
      // 1. Crear el gasto sin adjuntos primero
      final result = await _createExpenseUseCase(
        CreateExpenseParams(
          description: _description.value.trim(),
          amount: AppFormatters.parseNumber(_amount.value) ?? 0.0,
          date: selectedDate.value!,
          categoryId: selectedCategory.value!.id,
          type: selectedType.value!,
          paymentMethod: selectedPaymentMethod.value!,
          vendor: vendorController.text.trim().isEmpty
              ? null
              : vendorController.text.trim(),
          invoiceNumber: invoiceNumberController.text.trim().isEmpty
              ? null
              : invoiceNumberController.text.trim(),
          reference: referenceController.text.trim().isEmpty
              ? null
              : referenceController.text.trim(),
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          attachments: null, // No enviar adjuntos aquí
          tags: tags.isEmpty ? null : tags.toList(),
          status: status,
        ),
      );

      return await result.fold(
        (failure) {
          // 🔒 USAR HANDLER GLOBAL PARA ERRORES DE SUSCRIPCIÓN
          final handled = SubscriptionErrorHandler.handleFailure(
            failure,
            context: 'crear gasto',
          );

          if (!handled) {
            // Solo mostrar error genérico si no fue un error de suscripción
            _showError('Error al crear gasto', failure.message);
          }
          return false;
        },
        (expense) async {
          // 2. Si hay adjuntos con bytes (archivos nuevos), subirlos
          final filesToUpload = attachments.where((a) => a.bytes != null).toList();

          if (filesToUpload.isNotEmpty) {
            _isUploadingAttachments.value = true;
            _uploadProgress.value = 0.0;

            try {
              // Simular progreso (en una implementación real, esto vendría del dio)
              _uploadProgress.value = 0.3;

              final uploadResult = await _uploadAttachmentsUseCase(
                UploadAttachmentsParams(
                  expenseId: expense.id,
                  files: filesToUpload,
                ),
              );

              _uploadProgress.value = 1.0;

              uploadResult.fold(
                (uploadFailure) {
                  _showError(
                    'Advertencia',
                    'Gasto creado pero hubo un error al subir adjuntos: ${uploadFailure.message}',
                  );
                },
                (uploadedUrls) {
                  // Adjuntos subidos exitosamente
                },
              );
            } finally {
              _isUploadingAttachments.value = false;
              _uploadProgress.value = 0.0;
            }
          }

          final message = status == ExpenseStatus.draft
              ? 'Gasto guardado como borrador exitosamente'
              : 'Gasto creado y aprobado exitosamente';
          _showSuccess(message);
          return true;
        },
      );
    } catch (e) {
      _showError('Error inesperado', 'No se pudo crear el gasto');
      return false;
    }
  }

  Future<bool> _updateExpense() async {
    try {
      // 1. Actualizar el gasto sin tocar adjuntos
      final result = await _updateExpenseUseCase(
        UpdateExpenseParams(
          id: _expenseId.value!,
          description: _description.value.trim(),
          amount: AppFormatters.parseNumber(_amount.value) ?? 0.0,
          date: selectedDate.value!,
          categoryId: selectedCategory.value!.id,
          type: selectedType.value!,
          paymentMethod: selectedPaymentMethod.value!,
          vendor: vendorController.text.trim().isEmpty
              ? null
              : vendorController.text.trim(),
          invoiceNumber: invoiceNumberController.text.trim().isEmpty
              ? null
              : invoiceNumberController.text.trim(),
          reference: referenceController.text.trim().isEmpty
              ? null
              : referenceController.text.trim(),
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          attachments: null, // No tocar adjuntos aquí
          tags: tags.isEmpty ? null : tags.toList(),
        ),
      );

      return await result.fold(
        (failure) {
          // 🔒 USAR HANDLER GLOBAL PARA ERRORES DE SUSCRIPCIÓN
          final handled = SubscriptionErrorHandler.handleFailure(
            failure,
            context: 'editar gasto',
          );

          if (!handled) {
            // Solo mostrar error genérico si no fue un error de suscripción
            _showError('Error al actualizar gasto', failure.message);
          }
          return false;
        },
        (expense) async {
          // 2. Subir nuevos adjuntos si los hay
          final filesToUpload = attachments.where((a) => a.bytes != null).toList();

          if (filesToUpload.isNotEmpty) {
            _isUploadingAttachments.value = true;
            _uploadProgress.value = 0.0;

            try {
              // Simular progreso (en una implementación real, esto vendría del dio)
              _uploadProgress.value = 0.3;

              final uploadResult = await _uploadAttachmentsUseCase(
                UploadAttachmentsParams(
                  expenseId: _expenseId.value!,
                  files: filesToUpload,
                ),
              );

              _uploadProgress.value = 1.0;

              uploadResult.fold(
                (uploadFailure) {
                  _showError(
                    'Advertencia',
                    'Gasto actualizado pero hubo un error al subir adjuntos: ${uploadFailure.message}',
                  );
                },
                (uploadedUrls) {
                  // Adjuntos subidos exitosamente
                },
              );
            } finally {
              _isUploadingAttachments.value = false;
              _uploadProgress.value = 0.0;
            }
          }

          _showSuccess('Gasto actualizado exitosamente');
          return true;
        },
      );
    } catch (e) {
      _showError('Error inesperado', 'No se pudo actualizar el gasto');
      return false;
    }
  }

  // Gestión de adjuntos
  void addAttachment(AttachmentFile attachment) {
    // Verificar que no existe un archivo con el mismo nombre
    final existingIndex = attachments.indexWhere((a) => a.name == attachment.name);
    if (existingIndex >= 0) {
      attachments[existingIndex] = attachment;
    } else {
      attachments.add(attachment);
    }
  }

  Future<void> removeAttachment(AttachmentFile attachment) async {
    attachments.remove(attachment);

    // Si estamos en modo edición y el archivo no tiene bytes (es del servidor)
    if (isEditMode && attachment.bytes == null && _expenseId.value != null) {
      // Eliminar del servidor
      final deleteResult = await _deleteAttachmentUseCase(
        DeleteAttachmentParams(
          expenseId: _expenseId.value!,
          filename: attachment.name,
        ),
      );

      deleteResult.fold(
        (failure) {
          _showError('Error', 'No se pudo eliminar el adjunto del servidor: ${failure.message}');
          // Revertir la eliminación local
          attachments.add(attachment);
        },
        (_) {
          _showSuccess('Adjunto eliminado');
        },
      );
    } else {
      // Eliminar el archivo local si existe
      if (attachment.path.isNotEmpty) {
        _fileService.deleteAttachment(attachment.path).catchError((e) {
          // Error silencioso al eliminar archivo local
        });
      }
    }
  }

  Future<void> takePhoto() async {
    try {
      final file = await _fileService.pickImageFromCamera();
      if (file != null) {
        addAttachment(file);
        _showSuccess('Foto agregada: ${file.name}');
      }
    } catch (e) {
      _showError('Error', 'No se pudo tomar la foto: ${e.toString()}');
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final file = await _fileService.pickImageFromGallery();
      if (file != null) {
        addAttachment(file);
        _showSuccess('Imagen agregada: ${file.name}');
      }
    } catch (e) {
      _showError('Error', 'No se pudo seleccionar la imagen: ${e.toString()}');
    }
  }

  Future<void> pickFile() async {
    try {
      final file = await _fileService.pickFile();
      if (file != null) {
        addAttachment(file);
        _showSuccess('Archivo agregado: ${file.name}');
      }
    } catch (e) {
      _showError('Error', 'No se pudo seleccionar el archivo: ${e.toString()}');
    }
  }

  Future<void> pickMultipleFiles() async {
    try {
      final files = await _fileService.pickMultipleFiles(
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'jpg', 'jpeg', 'png'],
      );
      
      for (final file in files) {
        addAttachment(file);
      }
      
      if (files.isNotEmpty) {
        _showSuccess('${files.length} archivo(s) agregado(s)');
      }
    } catch (e) {
      _showError('Error', 'No se pudieron seleccionar los archivos: ${e.toString()}');
    }
  }

  // Gestión de etiquetas
  void updateTags(String tagsText) {
    final tagList = tagsText
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    
    tags.value = tagList;
  }

  // Crear categoría de gasto
  Future<Either<Failure, ExpenseCategory>> createExpenseCategory({
    required String name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
  }) async {
    try {
      final result = await _createExpenseCategoryUseCase(
        CreateExpenseCategoryParams(
          name: name,
          description: description,
          color: color,
          monthlyBudget: monthlyBudget,
          sortOrder: sortOrder,
        ),
      );

      return result.fold(
        (failure) => Left(failure),
        (category) {
          // Recargar las categorías para incluir la nueva
          loadCategories();
          return Right(category);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Error inesperado al crear categoría: $e'));
    }
  }

  Future<Either<Failure, ExpenseCategory>> updateExpenseCategory({
    required String categoryId,
    String? name,
    String? description,
    String? color,
    double? monthlyBudget,
    int? sortOrder,
    ExpenseCategoryStatus? status,
  }) async {
    try {
      final result = await _updateExpenseCategoryUseCase(
        UpdateExpenseCategoryParams(
          id: categoryId,
          name: name,
          description: description,
          color: color,
          monthlyBudget: monthlyBudget,
          sortOrder: sortOrder,
          status: status,
        ),
      );

      return result.fold(
        (failure) => Left(failure),
        (category) {
          // Recargar las categorías para mostrar los cambios
          loadCategories();
          return Right(category);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Error inesperado al actualizar categoría: $e'));
    }
  }

  // Métodos auxiliares de validación
  bool _isValidAmount(String amount) {
    if (amount.trim().isEmpty) return false;
    final numericValue = AppFormatters.parseNumber(amount);
    return numericValue != null && numericValue > 0 && numericValue <= 999999999;
  }

  bool _isValidDescription(String description) {
    final trimmed = description.trim();
    return trimmed.length >= 3 && trimmed.length <= 200;
  }

  bool _isValidVendor(String vendor) {
    final trimmed = vendor.trim();
    return trimmed.isEmpty || (trimmed.length >= 2 && trimmed.length <= 100);
  }

  bool _isValidInvoiceNumber(String invoiceNumber) {
    final trimmed = invoiceNumber.trim();
    return trimmed.isEmpty || (trimmed.length >= 3 && trimmed.length <= 50);
  }

  bool _isValidReference(String reference) {
    final trimmed = reference.trim();
    return trimmed.isEmpty || (trimmed.length >= 3 && trimmed.length <= 100);
  }

  bool _isValidNotes(String notes) {
    final trimmed = notes.trim();
    return trimmed.isEmpty || trimmed.length <= 500;
  }

  String? validateDescription(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return 'La descripción es requerida';
    }
    if (!_isValidDescription(value!)) {
      return 'La descripción debe tener entre 3 y 200 caracteres';
    }
    return null;
  }

  String? validateAmount(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return 'El monto es requerido';
    }
    
    final numericValue = AppFormatters.parseNumber(value!);
    if (numericValue == null) {
      return 'Ingrese un monto válido';
    }
    
    if (numericValue <= 0) {
      return 'El monto debe ser mayor a 0';
    }
    
    // Validar contra el presupuesto de la categoría si existe
    final category = selectedCategory.value;
    if (category != null && category.monthlyBudget > 0) {
      if (numericValue > category.monthlyBudget) {
        return 'El monto supera el presupuesto mensual de la categoría (${AppFormatters.formatCurrency(category.monthlyBudget)})';
      }
    }
    
    return null;
  }

  String? validateVendor(String? value) {
    if (!_isValidVendor(value ?? '')) {
      return 'El proveedor debe tener entre 2 y 100 caracteres';
    }
    return null;
  }

  String? validateInvoiceNumber(String? value) {
    if (!_isValidInvoiceNumber(value ?? '')) {
      return 'El número de factura debe tener entre 3 y 50 caracteres';
    }
    return null;
  }

  String? validateReference(String? value) {
    if (!_isValidReference(value ?? '')) {
      return 'La referencia debe tener entre 3 y 100 caracteres';
    }
    return null;
  }

  String? validateNotes(String? value) {
    if (!_isValidNotes(value ?? '')) {
      return 'Las notas no pueden exceder 500 caracteres';
    }
    return null;
  }

  String? validateDate() {
    if (selectedDate.value == null) {
      return 'Seleccione una fecha para el gasto';
    }
    
    final now = DateTime.now();
    final maxDate = DateTime(now.year, now.month, now.day + 1); // Permitir hasta mañana
    final minDate = DateTime(now.year - 2, now.month, now.day); // Máximo 2 años atrás
    
    if (selectedDate.value!.isAfter(maxDate)) {
      return 'La fecha no puede ser futura';
    }
    
    if (selectedDate.value!.isBefore(minDate)) {
      return 'La fecha no puede ser anterior a 2 años';
    }
    
    return null;
  }

  String? validateCategory() {
    if (selectedCategory.value == null) {
      return 'Seleccione una categoría';
    }
    return null;
  }

  String? validateType() {
    if (selectedType.value == null) {
      return 'Seleccione un tipo de gasto';
    }
    return null;
  }

  String? validatePaymentMethod() {
    if (selectedPaymentMethod.value == null) {
      return 'Seleccione un método de pago';
    }
    return null;
  }

  bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

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