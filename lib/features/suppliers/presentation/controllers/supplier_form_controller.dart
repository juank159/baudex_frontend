// lib/features/suppliers/presentation/controllers/supplier_form_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/create_supplier_usecase.dart';
import '../../domain/usecases/update_supplier_usecase.dart';
import '../../domain/usecases/get_supplier_by_id_usecase.dart';
import '../../domain/usecases/check_document_uniqueness_usecase.dart';

class SupplierFormController extends GetxController {
  final CreateSupplierUseCase createSupplierUseCase;
  final UpdateSupplierUseCase updateSupplierUseCase;
  final GetSupplierByIdUseCase getSupplierByIdUseCase;
  final CheckDocumentUniquenessUseCase checkDocumentUniquenessUseCase;

  SupplierFormController({
    required this.createSupplierUseCase,
    required this.updateSupplierUseCase,
    required this.getSupplierByIdUseCase,
    required this.checkDocumentUniquenessUseCase,
  });

  // ==================== REACTIVE VARIABLES ====================

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString error = ''.obs;
  final Rx<Supplier?> supplier = Rx<Supplier?>(null);
  final RxBool isEditMode = false.obs;

  // Form validation
  late final GlobalKey<FormState> formKey;
  final RxBool isFormValid = false.obs;

  // Form Controllers
  final nameController = TextEditingController();
  final codeController = TextEditingController();
  final documentNumberController = TextEditingController();
  final contactPersonController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  final postalCodeController = TextEditingController();
  final websiteController = TextEditingController();
  final currencyController = TextEditingController();
  final paymentTermsController = TextEditingController();
  final creditLimitController = TextEditingController();
  final discountPercentageController = TextEditingController();
  final notesController = TextEditingController();

  // Dropdowns
  final Rx<DocumentType?> documentType = Rx<DocumentType?>(null);
  final Rx<SupplierStatus> status = SupplierStatus.active.obs;

  // Validation flags
  final RxBool nameError = false.obs;
  final RxBool emailError = false.obs;
  final RxBool documentError = false.obs;
  final RxBool codeError = false.obs;
  final RxBool documentTypeError = false.obs;
  final RxBool documentNumberError = false.obs;

  // Document validation reactive variables
  final RxString documentNumber = ''.obs;

  // UI State
  final RxBool showAdvancedFields = false.obs;
  final RxInt currentStep = 0.obs;
  final RxBool isStepValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize unique FormKey
    formKey = GlobalKey<FormState>();
    _initializeForm();
    _setupFormValidation();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _disposeControllers();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeForm() {
    // Valores por defecto
    currencyController.text = 'COP';
    paymentTermsController.text = '30';
    creditLimitController.text = '0';
    discountPercentageController.text = '0';
    countryController.text = 'Colombia';

    // Si hay un ID en los argumentos, cargar el proveedor
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('supplierId')) {
      final supplierId = args['supplierId'] as String;
      loadSupplier(supplierId);
    } else {
      // Para nuevos proveedores, establecer valores por defecto para documento
      documentType.value = DocumentType.nit; // Valor por defecto
      documentNumber.value = '';
    }
  }

  void _setupFormValidation() {
    // Escuchar cambios en los campos principales
    nameController.addListener(_validateForm);
    emailController.addListener(_validateForm);
    
    // Document number controller con debounce para validación de unicidad
    documentNumberController.addListener((){
      documentNumber.value = documentNumberController.text.trim();
      // Solo revalidar campos requeridos inmediatamente, no unicidad
      _validateForm();
    });
    
    codeController.addListener(_validateForm);
    paymentTermsController.addListener(_validateForm);
    currencyController.addListener(_validateForm);
    creditLimitController.addListener(_validateForm);
    discountPercentageController.addListener(_validateForm);
    
    // Listen to document changes with debounce for uniqueness validation
    documentType.listen((_) => _debounceDocumentValidation());
    documentNumber.listen((_) => _debounceDocumentValidation());
  }

  void _disposeControllers() {
    nameController.dispose();
    codeController.dispose();
    documentNumberController.dispose();
    contactPersonController.dispose();
    emailController.dispose();
    phoneController.dispose();
    mobileController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    postalCodeController.dispose();
    websiteController.dispose();
    currencyController.dispose();
    paymentTermsController.dispose();
    creditLimitController.dispose();
    discountPercentageController.dispose();
    notesController.dispose();
  }

  // ==================== DATA LOADING ====================

  Future<void> loadSupplier(String supplierId) async {
    try {
      isLoading.value = true;
      isEditMode.value = true;
      error.value = '';

      final result = await getSupplierByIdUseCase(supplierId);

      result.fold(
        (failure) {
          error.value = failure.message;
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
        },
        (loadedSupplier) {
          supplier.value = loadedSupplier;
          _populateForm(loadedSupplier);
        },
      );
    } catch (e) {
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _populateForm(Supplier supplier) {
    nameController.text = supplier.name;
    codeController.text = supplier.code ?? '';
    documentNumberController.text = supplier.documentNumber;
    contactPersonController.text = supplier.contactPerson ?? '';
    emailController.text = supplier.email ?? '';
    phoneController.text = supplier.phone ?? '';
    mobileController.text = supplier.mobile ?? '';
    addressController.text = supplier.address ?? '';
    cityController.text = supplier.city ?? '';
    stateController.text = supplier.state ?? '';
    countryController.text = supplier.country ?? '';
    postalCodeController.text = supplier.postalCode ?? '';
    websiteController.text = supplier.website ?? '';
    currencyController.text = supplier.currency;
    paymentTermsController.text = supplier.paymentTermsDays.toString();
    creditLimitController.text = supplier.creditLimit.toString();
    discountPercentageController.text = supplier.discountPercentage.toString();
    notesController.text = supplier.notes ?? '';

    documentType.value = supplier.documentType;
    status.value = supplier.status;
    
    // Initialize reactive document number
    documentNumber.value = supplier.documentNumber;
  }

  // ==================== FORM VALIDATION ====================

  void _validateForm() {
    // Validación básica
    final hasName = nameController.text.trim().isNotEmpty;
    final hasValidPaymentTerms = paymentTermsController.text.isNotEmpty && 
        (int.tryParse(paymentTermsController.text) ?? 0) > 0;
    final hasValidCurrency = currencyController.text.isNotEmpty;
    
    // Validaciones adicionales
    final isEmailValid = emailController.text.isEmpty || GetUtils.isEmail(emailController.text);
    final isCreditLimitValid = creditLimitController.text.isEmpty || 
        (double.tryParse(creditLimitController.text) ?? -1) >= 0;
    final isDiscountValid = discountPercentageController.text.isEmpty || 
        ((double.tryParse(discountPercentageController.text) ?? -1) >= 0 && 
         (double.tryParse(discountPercentageController.text) ?? 101) <= 100);
    
    // Document validation: both type and number are ALWAYS required
    final hasDocumentType = documentType.value != null;
    final hasDocumentNumber = documentNumber.value.isNotEmpty;
    final isDocumentValid = hasDocumentType && hasDocumentNumber;
    
    isFormValid.value = hasName && hasValidPaymentTerms && hasValidCurrency && 
        isEmailValid && isCreditLimitValid && isDiscountValid && isDocumentValid;
    
    // Actualizar errores individuales
    nameError.value = !hasName;
    emailError.value = !isEmailValid;
    
    // Validar step actual (si se mantiene el step system)
    isStepValid.value = isFormValid.value;
  }

  bool validateCurrentStep() {
    switch (currentStep.value) {
      case 0:
        return _validateBasicInfo();
      case 1:
        return _validateContactInfo();
      case 2:
        return _validateCommercialInfo();
      default:
        return true;
    }
  }

  bool _validateBasicInfo() {
    bool isValid = true;

    // Validar nombre
    if (nameController.text.trim().isEmpty) {
      nameError.value = true;
      isValid = false;
    } else {
      nameError.value = false;
    }

    // Validar documento - AMBOS campos son obligatorios
    final hasDocumentType = documentType.value != null;
    final hasDocumentNumber = documentNumber.value.isNotEmpty;
    
    // Don't reset document errors here as they may be set by async uniqueness validation
    // Only set errors for required fields, don't clear existing errors
    
    // Both fields are required
    if (!hasDocumentType) {
      documentTypeError.value = true;
      documentError.value = true;
      isValid = false;
    }
    
    if (!hasDocumentNumber) {
      documentNumberError.value = true;
      documentError.value = true;
      isValid = false;
    }
    
    // If both fields are present but there are still errors, form is not valid
    if (hasDocumentType && hasDocumentNumber && 
        (documentTypeError.value || documentNumberError.value)) {
      documentError.value = true;
      isValid = false;
    }
    
    // Clear documentError if both fields are valid
    if (hasDocumentType && hasDocumentNumber && 
        !documentTypeError.value && !documentNumberError.value) {
      documentError.value = false;
    }

    return isValid;
  }

  bool _validateContactInfo() {
    bool isValid = true;

    // Validar email si está presente
    if (emailController.text.isNotEmpty && !GetUtils.isEmail(emailController.text)) {
      emailError.value = true;
      isValid = false;
    } else {
      emailError.value = false;
    }

    return isValid;
  }

  bool _validateCommercialInfo() {
    // Validar que los números sean válidos
    try {
      if (paymentTermsController.text.isNotEmpty) {
        int.parse(paymentTermsController.text);
      }
      if (creditLimitController.text.isNotEmpty) {
        double.parse(creditLimitController.text);
      }
      if (discountPercentageController.text.isNotEmpty) {
        final discount = double.parse(discountPercentageController.text);
        if (discount < 0 || discount > 100) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== FORM SUBMISSION ====================

  Future<void> saveSupplier() async {
    if (!isFormValid.value || !formKey.currentState!.validate()) {
      Get.snackbar(
        'Error',
        'Por favor complete los campos requeridos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    try {
      isSaving.value = true;
      error.value = '';

      if (isEditMode.value) {
        await _updateSupplier();
      } else {
        await _createSupplier();
      }
    } catch (e) {
      error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _createSupplier() async {
    final params = CreateSupplierParams(
      name: nameController.text.trim(),
      code: codeController.text.trim().isNotEmpty ? codeController.text.trim() : null,
      documentType: documentType.value!,
      documentNumber: documentNumberController.text.trim(),
      contactPerson: contactPersonController.text.trim().isNotEmpty 
          ? contactPersonController.text.trim() 
          : null,
      email: emailController.text.trim().isNotEmpty 
          ? emailController.text.trim() 
          : null,
      phone: phoneController.text.trim().isNotEmpty 
          ? phoneController.text.trim() 
          : null,
      mobile: mobileController.text.trim().isNotEmpty 
          ? mobileController.text.trim() 
          : null,
      address: addressController.text.trim().isNotEmpty 
          ? addressController.text.trim() 
          : null,
      city: cityController.text.trim().isNotEmpty 
          ? cityController.text.trim() 
          : null,
      state: stateController.text.trim().isNotEmpty 
          ? stateController.text.trim() 
          : null,
      country: countryController.text.trim().isNotEmpty 
          ? countryController.text.trim() 
          : null,
      postalCode: postalCodeController.text.trim().isNotEmpty 
          ? postalCodeController.text.trim() 
          : null,
      website: websiteController.text.trim().isNotEmpty 
          ? websiteController.text.trim() 
          : null,
      status: status.value,
      currency: currencyController.text.trim().isNotEmpty 
          ? currencyController.text.trim() 
          : 'COP',
      paymentTermsDays: int.tryParse(paymentTermsController.text) ?? 30,
      creditLimit: double.tryParse(creditLimitController.text) ?? 0.0,
      discountPercentage: double.tryParse(discountPercentageController.text) ?? 0.0,
      notes: notesController.text.trim().isNotEmpty 
          ? notesController.text.trim() 
          : null,
    );

    final result = await createSupplierUseCase(params);

    result.fold(
      (failure) {
        error.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      },
      (createdSupplier) {
        Get.snackbar(
          'Éxito',
          'Proveedor creado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        
        // Volver a la lista y forzar refresco
        Get.offAllNamed('/suppliers');
      },
    );
  }

  Future<void> _updateSupplier() async {
    if (supplier.value == null) return;

    final params = UpdateSupplierParams(
      id: supplier.value!.id,
      name: nameController.text.trim(),
      code: codeController.text.trim().isNotEmpty ? codeController.text.trim() : null,
      documentType: documentType.value!,
      documentNumber: documentNumberController.text.trim(),
      contactPerson: contactPersonController.text.trim().isNotEmpty 
          ? contactPersonController.text.trim() 
          : null,
      email: emailController.text.trim().isNotEmpty 
          ? emailController.text.trim() 
          : null,
      phone: phoneController.text.trim().isNotEmpty 
          ? phoneController.text.trim() 
          : null,
      mobile: mobileController.text.trim().isNotEmpty 
          ? mobileController.text.trim() 
          : null,
      address: addressController.text.trim().isNotEmpty 
          ? addressController.text.trim() 
          : null,
      city: cityController.text.trim().isNotEmpty 
          ? cityController.text.trim() 
          : null,
      state: stateController.text.trim().isNotEmpty 
          ? stateController.text.trim() 
          : null,
      country: countryController.text.trim().isNotEmpty 
          ? countryController.text.trim() 
          : null,
      postalCode: postalCodeController.text.trim().isNotEmpty 
          ? postalCodeController.text.trim() 
          : null,
      website: websiteController.text.trim().isNotEmpty 
          ? websiteController.text.trim() 
          : null,
      status: status.value,
      currency: currencyController.text.trim().isNotEmpty 
          ? currencyController.text.trim() 
          : 'COP',
      paymentTermsDays: int.tryParse(paymentTermsController.text) ?? 30,
      creditLimit: double.tryParse(creditLimitController.text) ?? 0.0,
      discountPercentage: double.tryParse(discountPercentageController.text) ?? 0.0,
      notes: notesController.text.trim().isNotEmpty 
          ? notesController.text.trim() 
          : null,
    );

    final result = await updateSupplierUseCase(params);

    result.fold(
      (failure) {
        error.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      },
      (updatedSupplier) {
        Get.snackbar(
          'Éxito',
          'Proveedor actualizado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
        
        // Volver a la lista y forzar refresco
        Get.offAllNamed('/suppliers');
      },
    );
  }

  // ==================== STEPPER NAVIGATION ====================

  void nextStep() {
    if (validateCurrentStep() && currentStep.value < 2) {
      currentStep.value++;
      _validateForm();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      _validateForm();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      currentStep.value = step;
      _validateForm();
    }
  }

  // ==================== UI HELPERS ====================

  void toggleAdvancedFields() {
    showAdvancedFields.value = !showAdvancedFields.value;
  }

  void clearForm() {
    formKey.currentState?.reset();
    
    nameController.clear();
    codeController.clear();
    documentNumberController.clear();
    contactPersonController.clear();
    emailController.clear();
    phoneController.clear();
    mobileController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    countryController.clear();
    postalCodeController.clear();
    websiteController.clear();
    currencyController.text = 'COP';
    paymentTermsController.text = '30';
    creditLimitController.text = '0';
    discountPercentageController.text = '0';
    notesController.clear();

    documentType.value = null;
    status.value = SupplierStatus.active;
    
    // Clear reactive variables
    documentNumber.value = '';

    nameError.value = false;
    emailError.value = false;
    documentError.value = false;
    codeError.value = false;
    documentTypeError.value = false;
    documentNumberError.value = false;

    currentStep.value = 0;
    showAdvancedFields.value = false;
  }

  String getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Información Básica';
      case 1:
        return 'Información de Contacto';
      case 2:
        return 'Información Comercial';
      default:
        return 'Paso ${step + 1}';
    }
  }

  // ==================== COMPUTED PROPERTIES ====================

  bool get canProceed => isStepValid.value;
  
  bool get isLastStep => currentStep.value == 2;
  
  bool get isFirstStep => currentStep.value == 0;
  
  String get saveButtonText => isEditMode.value ? 'Actualizar' : 'Crear';
  
  String get titleText => isEditMode.value ? 'Editar Proveedor' : 'Nuevo Proveedor';

  // ==================== DOCUMENT VALIDATION ====================

  // Real-time document uniqueness validation
  Future<bool> validateDocumentUniqueness() async {
    if (documentType.value == null || documentNumber.value.isEmpty) {
      print('🚫 Validation skipped - campos vacíos');
      return true; // No validation needed if fields are empty
    }
    
    try {
      final params = CheckDocumentUniquenessParams(
        documentType: documentType.value!,
        documentNumber: documentNumber.value,
        excludeId: isEditMode.value ? supplier.value?.id : null,
      );
      
      print('📋 Validando con params: ${documentType.value?.name} - ${documentNumber.value} - excludeId: ${params.excludeId}');
      
      final result = await checkDocumentUniquenessUseCase(params);
      
      return result.fold(
        (failure) {
          // If there's an error, return true to avoid false positives
          print('❌ Error en validación: $failure');
          return true; // Changed: assume unique if there's an error
        },
        (isUnique) {
          print('✅ Respuesta de API: isUnique = $isUnique');
          return isUnique;
        },
      );
    } catch (e) {
      // If there's an exception, return true to avoid false positives
      print('💥 Excepción en validación: $e');
      return true; // Changed: assume unique if there's an exception
    }
  }

  // Debounced validation to avoid too many API calls
  Timer? _debounceTimer;
  
  void _debounceDocumentValidation() {
    _debounceTimer?.cancel();
    
    // Solo validar unicidad si ambos campos están completos
    if (documentType.value == null || documentNumber.value.isEmpty) {
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      // Verificar nuevamente que los campos sigan completos después del debounce
      if (documentType.value != null && documentNumber.value.isNotEmpty) {
        print('🔍 Iniciando validación de unicidad para: ${documentType.value?.name} - ${documentNumber.value}');
        
        final isUnique = await validateDocumentUniqueness();
        
        print('📋 Resultado validación: isUnique = $isUnique');
        
        if (!isUnique) {
          // Documento duplicado - mostrar error
          documentNumberError.value = true;
          documentTypeError.value = true;
          Get.snackbar(
            'Documento duplicado',
            'Ya existe un proveedor con este tipo y número de documento',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
            duration: const Duration(seconds: 3),
          );
        } else {
          // Documento único - limpiar errores de unicidad solo si ambos campos están presentes
          print('✅ Documento único - limpiando errores');
          documentNumberError.value = false;
          documentTypeError.value = false;
        }
        
        // Revalidar el formulario completo
        _validateForm();
      }
    });
  }
}