// lib/features/customers/presentation/controllers/customer_form_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/safe_text_editing_controller.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import '../../domain/usecases/get_customer_by_id_usecase.dart';
import '../../../../app/shared/utils/subscription_error_handler.dart';
import '../../../../app/shared/services/subscription_validation_service.dart';

class CustomerFormController extends GetxController {
  Timer? _emailValidationTimer;
  Timer? _documentValidationTimer;

  // Dependencies
  final CreateCustomerUseCase _createCustomerUseCase;
  final UpdateCustomerUseCase _updateCustomerUseCase;
  final GetCustomerByIdUseCase _getCustomerByIdUseCase;
  final CustomerRepository _customerRepository;

  CustomerFormController({
    required CreateCustomerUseCase createCustomerUseCase,
    required UpdateCustomerUseCase updateCustomerUseCase,
    required GetCustomerByIdUseCase getCustomerByIdUseCase,
    required CustomerRepository customerRepository,
  }) : _createCustomerUseCase = createCustomerUseCase,
       _updateCustomerUseCase = updateCustomerUseCase,
       _getCustomerByIdUseCase = getCustomerByIdUseCase,
       _customerRepository = customerRepository {
    print('🎮 CustomerFormController: Instancia creada correctamente');
  }

  // ==================== FORM KEY ====================
  final formKey = GlobalKey<FormState>();

  // ==================== TEXT CONTROLLERS ====================
  // Using SafeTextEditingController to prevent disposal errors
  final firstNameController = SafeTextEditingController(debugLabel: 'CustomerFormFirstName');
  final lastNameController = SafeTextEditingController(debugLabel: 'CustomerFormLastName');
  final companyNameController = SafeTextEditingController(debugLabel: 'CustomerFormCompanyName');
  final emailController = SafeTextEditingController(debugLabel: 'CustomerFormEmail');
  final phoneController = SafeTextEditingController(debugLabel: 'CustomerFormPhone');
  final mobileController = SafeTextEditingController(debugLabel: 'CustomerFormMobile');
  final documentNumberController = SafeTextEditingController(debugLabel: 'CustomerFormDocumentNumber');
  final addressController = SafeTextEditingController(debugLabel: 'CustomerFormAddress');
  final cityController = SafeTextEditingController(debugLabel: 'CustomerFormCity');
  final stateController = SafeTextEditingController(debugLabel: 'CustomerFormState');
  final zipCodeController = SafeTextEditingController(debugLabel: 'CustomerFormZipCode');
  final creditLimitController = SafeTextEditingController(debugLabel: 'CustomerFormCreditLimit');
  final paymentTermsController = SafeTextEditingController(debugLabel: 'CustomerFormPaymentTerms');
  final notesController = SafeTextEditingController(debugLabel: 'CustomerFormNotes');

  // ==================== OBSERVABLES ====================
  final _isLoading = false.obs;
  final _isLoadingCustomer = false.obs;
  final _isSaving = false.obs;
  final _selectedStatus = CustomerStatus.active.obs;
  final _selectedDocumentType = DocumentType.cc.obs;
  final _birthDate = Rxn<DateTime>();
  final _currentCustomer = Rxn<Customer>();

  // Validation states - ✅ INICIALIZAR COMO TRUE
  final _emailAvailable = true.obs;
  final _documentAvailable = true.obs;
  final _isValidatingEmail = false.obs;
  final _isValidatingDocument = false.obs;

  // ✅ NUEVO: Control de cuándo se ha validado por primera vez
  final _emailValidatedOnce = false.obs;
  final _documentValidatedOnce = false.obs;

  // ✅ Cache para evitar validaciones redundantes
  String? _lastValidatedEmail;
  String? _lastValidatedDocument;
  DocumentType? _lastValidatedDocumentType;

  // ==================== GETTERS ====================
  bool get isLoading => _isLoading.value;
  bool get isLoadingCustomer => _isLoadingCustomer.value;
  bool get isSaving => _isSaving.value;
  CustomerStatus get selectedStatus => _selectedStatus.value;
  DocumentType get selectedDocumentType => _selectedDocumentType.value;
  DateTime? get birthDate => _birthDate.value;
  Customer? get currentCustomer => _currentCustomer.value;
  bool get emailAvailable => _emailAvailable.value;
  bool get documentAvailable => _documentAvailable.value;
  bool get isValidatingEmail => _isValidatingEmail.value;
  bool get isValidatingDocument => _isValidatingDocument.value;

  String get customerId => Get.parameters['id'] ?? '';
  bool get isEditMode => customerId.isNotEmpty;
  bool get hasCustomer => _currentCustomer.value != null;
  String get formTitle => isEditMode ? 'Editar Cliente' : 'Nuevo Cliente';
  String get submitButtonText {
    if (_isSaving.value) {
      if (_isValidatingEmail.value || _isValidatingDocument.value) {
        return 'Validando...';
      }
      return isEditMode ? 'Actualizando...' : 'Creando...';
    }
    return isEditMode ? 'Actualizar' : 'Crear Cliente';
  }

  // ==================== LIFECYCLE ====================
  @override
  void onInit() {
    super.onInit();
    print('🚀 CustomerFormController: Inicializando...');
    print(
      '🔍 CustomerFormController: isEditMode = $isEditMode, customerId = "$customerId"',
    );

    _initializeForm();
  }

  @override
  void onClose() {
    print('🔚 CustomerFormController: Liberando recursos...');
    
    try {
      print('⏹️ Cancelando timer de validación de email...');
      _emailValidationTimer?.cancel();
      
      print('⏹️ Cancelando timer de validación de documento...');
      _documentValidationTimer?.cancel();

      print('🧹 Limpiando cache de validaciones...');
      // ✅ Limpiar cache de validaciones
      _lastValidatedEmail = null;
      _lastValidatedDocument = null;
      _lastValidatedDocumentType = null;

      print('🎮 Llamando a _disposeControllers()...');
      _disposeControllers();
      
      print('🔚 Llamando a super.onClose()...');
      super.onClose();
      
      print('✅ CustomerFormController: Recursos liberados exitosamente');
    } catch (e) {
      print('💥 CustomerFormController: Error durante onClose() - $e');
      print('📍 Stack trace: ${StackTrace.current}');
      // Intentar llamar super.onClose() aunque haya errores
      try {
        super.onClose();
      } catch (superError) {
        print('💥 Error adicional en super.onClose() - $superError');
      }
    }
  }

  // ==================== PRIVATE INITIALIZATION ====================

  void _initializeForm() {
    print('⚙️ CustomerFormController: Configurando formulario...');

    _setDefaultValues();

    if (isEditMode) {
      print(
        '📝 CustomerFormController: Modo edición detectado, cargando cliente...',
      );
      Future.microtask(() => loadCustomer(customerId));
    }

    print('✅ CustomerFormController: Inicialización completada');
  }

  void _setDefaultValues() {
    creditLimitController.text = '0';
    paymentTermsController.text = '30';
    _selectedStatus.value = CustomerStatus.active;
    _selectedDocumentType.value = DocumentType.cc;

    print('✅ CustomerFormController: Valores por defecto configurados');
  }

  // ==================== PUBLIC METHODS ====================

  Future<void> loadCustomer(String customerId) async {
    print(
      '📥 CustomerFormController: Iniciando carga de cliente para edición...',
    );
    _isLoadingCustomer.value = true;

    try {
      print('📥 Cargando cliente: $customerId');

      final result = await _getCustomerByIdUseCase(
        GetCustomerByIdParams(id: customerId),
      );

      result.fold(
        (failure) {
          print(
            '❌ CustomerFormController: Error al cargar cliente - ${failure.message}',
          );
          _showError('Error al cargar cliente', failure.message);
          Get.back();
        },
        (customer) {
          print(
            '✅ CustomerFormController: Cliente cargado exitosamente - ${customer.displayName}',
          );
          _currentCustomer.value = customer;
          _populateForm(customer);
        },
      );
    } catch (e) {
      print(
        '💥 CustomerFormController: Error inesperado al cargar cliente - $e',
      );
      _showError('Error inesperado', 'No se pudo cargar el cliente: $e');
      Get.back();
    } finally {
      _isLoadingCustomer.value = false;
      print('🏁 CustomerFormController: Carga de cliente finalizada');
    }
  }

  Future<void> saveCustomer() async {
    print('💾 CustomerFormController: Iniciando guardado de cliente...');

    // Cancelar timers pendientes para evitar conflictos
    _emailValidationTimer?.cancel();
    _documentValidationTimer?.cancel();

    // Mostrar estado de validación durante validaciones asíncronas
    _isSaving.value = true;

    if (!await _validateFormAsync()) {
      print('❌ CustomerFormController: Validación de formulario falló');
      _isSaving.value = false; // Reset loading state on validation failure
      return;
    }

    try {
      if (isEditMode) {
        print('🔄 CustomerFormController: Actualizando cliente existente...');
        await _updateCustomer();
      } else {
        print('🆕 CustomerFormController: Creando nuevo cliente...');
        await _createCustomer();
      }
    } catch (e) {
      print('💥 CustomerFormController: Error inesperado al guardar - $e');
      _showError('Error inesperado', 'No se pudo guardar el cliente: $e');
    } finally {
      _isSaving.value = false;
      print('🏁 CustomerFormController: Guardado finalizado');
    }
  }

  Future<bool> _validateFormAsync() async {
    print('🔍 Iniciando validación completa del formulario...');

    // 1. Validar campos manualmente sin depender del formKey
    if (!_validateFieldsManually()) {
      _showError(
        'Formulario inválido',
        'Por favor corrige los errores en los campos',
      );
      return false;
    }

    // 3. Esperar a que terminen las validaciones en progreso (si las hay)
    if (_isValidatingEmail.value || _isValidatingDocument.value) {
      print('⏳ Esperando validaciones en progreso...');

      // Esperar hasta que las validaciones terminen (máximo 10 segundos)
      int attempts = 0;
      const maxAttempts = 50; // 50 * 200ms = 10 segundos máximo

      while ((_isValidatingEmail.value || _isValidatingDocument.value) &&
          attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }

      // Si después de esperar aún hay validaciones en progreso, fallar
      if (_isValidatingEmail.value || _isValidatingDocument.value) {
        _showError(
          'Validación timeout',
          'Las validaciones tardaron demasiado. Intenta de nuevo.',
        );
        return false;
      }

      print('✅ Validaciones completadas, continuando...');
    }

    // 4. Forzar validación de email si es necesario
    final email = emailController.text.trim();
    if (email.isNotEmpty && GetUtils.isEmail(email)) {
      if (!_emailValidatedOnce.value ||
          (isEditMode && _currentCustomer.value?.email != email) ||
          !isEditMode) {
        print('📧 Validando email antes de guardar...');
        await validateEmailAvailability();
      } else {
        print('✅ Email ya validado, saltando validación');
      }
    }

    // 5. Forzar validación de documento si es necesario
    final documentNumber = documentNumberController.text.trim();
    if (documentNumber.isNotEmpty) {
      if (!_documentValidatedOnce.value ||
          (isEditMode &&
              (_currentCustomer.value?.documentNumber != documentNumber ||
                  _currentCustomer.value?.documentType !=
                      _selectedDocumentType.value)) ||
          !isEditMode) {
        print('📄 Validando documento antes de guardar...');
        await validateDocumentAvailability();
      } else {
        print('✅ Documento ya validado, saltando validación');
      }
    }

    // 6. Verificar resultados de validaciones asíncronas
    if (!_emailAvailable.value) {
      _showError('Email no disponible', 'El email ya está registrado');
      return false;
    }

    if (!_documentAvailable.value) {
      _showError('Documento no disponible', 'El documento ya está registrado');
      return false;
    }

    print('✅ Validación completa exitosa');
    return true;
  }

  // ==================== FORM ACTIONS ====================

  Future<void> _createCustomer() async {
    // 🔒 VALIDACIÓN FRONTEND: Verificar suscripción ANTES de llamar al backend
    if (!SubscriptionValidationService.canCreateCustomer()) {
      print('🚫 FRONTEND BLOCK: Suscripción expirada - BLOQUEANDO creación de cliente');
      return; // Bloquear operación
    }
    
    print('✅ FRONTEND VALIDATION: Suscripción válida - CONTINUANDO con creación de cliente');
    print('🆕 Creando nuevo cliente...');

    final result = await _createCustomerUseCase(
      CreateCustomerParams(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        companyName: _getOptionalText(companyNameController),
        email: emailController.text.trim(),
        phone: _getOptionalText(phoneController),
        mobile: _getOptionalText(mobileController),
        documentType: _selectedDocumentType.value,
        documentNumber: documentNumberController.text.trim(),
        address: _getOptionalText(addressController),
        city: _getOptionalText(cityController),
        state: _getOptionalText(stateController),
        zipCode: _getOptionalText(zipCodeController),
        country: 'Colombia',
        status: _selectedStatus.value,
        creditLimit: _parseDouble(creditLimitController.text),
        paymentTerms: _parseInt(paymentTermsController.text),
        birthDate: _birthDate.value,
        notes: _getOptionalText(notesController),
      ),
    );

    result.fold(
      (failure) {
        // 🔒 USAR HANDLER GLOBAL PARA ERRORES DE SUSCRIPCIÓN
        final handled = SubscriptionErrorHandler.handleFailure(
          failure,
          context: 'crear cliente',
        );
        
        if (!handled) {
          // Solo mostrar error genérico si no fue un error de suscripción
          _showError('Error al crear cliente', failure.message);
        }
      },
      (customer) {
        print(
          '✅ CustomerFormController: Cliente creado exitosamente - ${customer.displayName}',
        );
        _showSuccess('Cliente creado exitosamente');

        if (Get.currentRoute.contains('/customers/create')) {
          Get.offAllNamed('/customers');
        } else {
          Get.back(result: customer);
        }
      },
    );
  }

  Future<void> _updateCustomer() async {
    // 🔒 VALIDACIÓN FRONTEND: Verificar suscripción ANTES de llamar al backend
    if (!SubscriptionValidationService.canUpdateCustomer()) {
      print('🚫 FRONTEND BLOCK: Suscripción expirada - BLOQUEANDO actualización de cliente');
      return; // Bloquear operación
    }
    
    print('✅ FRONTEND VALIDATION: Suscripción válida - CONTINUANDO con actualización de cliente');
    print('📝 Actualizando cliente...');

    final result = await _updateCustomerUseCase(
      UpdateCustomerParams(
        id: _currentCustomer.value!.id,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        companyName: _getOptionalText(companyNameController),
        email: emailController.text.trim(),
        phone: _getOptionalText(phoneController),
        mobile: _getOptionalText(mobileController),
        documentType: _selectedDocumentType.value,
        documentNumber: documentNumberController.text.trim(),
        address: _getOptionalText(addressController),
        city: _getOptionalText(cityController),
        state: _getOptionalText(stateController),
        zipCode: _getOptionalText(zipCodeController),
        country: 'Colombia',
        status: _selectedStatus.value,
        creditLimit: _parseDouble(creditLimitController.text),
        paymentTerms: _parseInt(paymentTermsController.text),
        birthDate: _birthDate.value,
        notes: _getOptionalText(notesController),
      ),
    );

    result.fold(
      (failure) {
        // 🔒 USAR HANDLER GLOBAL PARA ERRORES DE SUSCRIPCIÓN
        final handled = SubscriptionErrorHandler.handleFailure(
          failure,
          context: 'editar cliente',
        );
        
        if (!handled) {
          // Solo mostrar error genérico si no fue un error de suscripción
          _showError('Error al actualizar cliente', failure.message);
        }
      },
      (customer) {
        print(
          '✅ CustomerFormController: Cliente actualizado exitosamente - ${customer.displayName}',
        );
        _showSuccess('Cliente actualizado exitosamente');
        Get.offAllNamed('/customers/detail/${customer.id}');
      },
    );
  }

  // ==================== FORM FIELD CHANGES ====================
  void changeStatus(CustomerStatus status) {
    _selectedStatus.value = status;
  }

  void changeDocumentType(DocumentType documentType) {
    _selectedDocumentType.value = documentType;
    _lastValidatedDocument =
        null; // ✅ Limpiar cache al cambiar tipo de documento
    _lastValidatedDocumentType = null;

    // ✅ SOLO revalidar si ya se había validado antes Y hay contenido
    if (_documentValidatedOnce.value &&
        documentNumberController.text.trim().isNotEmpty) {
      _documentAvailable.value = true; // Resetear estado
      Future.delayed(const Duration(milliseconds: 500), () {
        validateDocumentAvailability();
      });
    } else {
      _documentAvailable.value = true;
    }
  }

  void onEmailChanged(String value) {
    _emailValidationTimer?.cancel();
    _lastValidatedEmail = null; // ✅ Limpiar cache al cambiar email

    // Si está vacío, resetear estado
    if (value.trim().isEmpty) {
      _emailAvailable.value = true;
      _emailValidatedOnce.value = false;
      return;
    }

    // Solo validar si es un email válido y después de un delay de 1 segundo
    if (GetUtils.isEmail(value.trim())) {
      _emailValidationTimer = Timer(const Duration(milliseconds: 1000), () {
        validateEmailAvailability();
      });
    }
  }

  void onDocumentNumberChanged(String value) {
    _documentValidationTimer?.cancel();
    _lastValidatedDocument = null; // ✅ Limpiar cache al cambiar documento
    _lastValidatedDocumentType = null;

    // Si está vacío, resetear estado
    if (value.trim().isEmpty) {
      _documentAvailable.value = true;
      _documentValidatedOnce.value = false;
      return;
    }

    // Solo validar si tiene suficiente longitud y después de un delay de 1 segundo
    if (value.trim().length >= 3) {
      _documentValidationTimer = Timer(const Duration(milliseconds: 1000), () {
        validateDocumentAvailability();
      });
    }
  }

  void changeBirthDate(DateTime? date) {
    _birthDate.value = date;
  }

  // ==================== VALIDATION ====================
  String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El apellido es requerido';
    }
    if (value.trim().length < 2) {
      return 'El apellido debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Ingresa un email válido';
    }
    // NO mostrar error de disponibilidad aquí - solo en el indicador visual
    return null;
  }

  String? validateDocumentNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de documento es requerido';
    }
    if (value.trim().length < 3) {
      return 'El documento debe tener al menos 3 caracteres';
    }
    // NO mostrar error de disponibilidad aquí - solo en el indicador visual
    return null;
  }

  String? validateCreditLimit(String? value) {
    if (value != null && value.isNotEmpty) {
      final parsed = double.tryParse(value);
      if (parsed == null || parsed < 0) {
        return 'Ingresa un límite de crédito válido';
      }
    }
    return null;
  }

  String? validatePaymentTerms(String? value) {
    if (value != null && value.isNotEmpty) {
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 1) {
        return 'Los términos de pago deben ser al menos 1 día';
      }
    }
    return null;
  }

  // ==================== ASYNC VALIDATION ====================
  Future<void> validateEmailAvailability() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      _emailAvailable.value = true;
      _emailValidatedOnce.value = false;
      return;
    }

    // Si estamos editando y el email no cambió, marcarlo como disponible
    if (isEditMode && _currentCustomer.value?.email == email) {
      _emailAvailable.value = true;
      _emailValidatedOnce.value = true;
      return;
    }

    // ✅ Cache: Si ya validamos este email, reutilizar resultado
    if (_lastValidatedEmail == email && _emailValidatedOnce.value) {
      print('✅ [CACHE] Email ya validado previamente: $email');
      return;
    }

    _isValidatingEmail.value = true;
    _emailValidatedOnce.value = true;

    try {
      print('🔍 [CONTROLLER] Validando disponibilidad de email: $email');

      final result = await _customerRepository.isEmailAvailable(
        email,
        excludeId: _currentCustomer.value?.id,
      );

      result.fold(
        (failure) {
          print('⚠️ [CONTROLLER] Error al validar email: ${failure.message}');
          _emailAvailable.value = false;
          _showError(
            'Error de validación',
            'No se pudo verificar la disponibilidad del email',
          );
        },
        (available) {
          print(
            '📧 [CONTROLLER] Email $email: ${available ? "DISPONIBLE" : "YA EXISTE"}',
          );
          _emailAvailable.value = available;

          // ✅ Actualizar cache solo si la validación fue exitosa
          if (available) {
            _lastValidatedEmail = email;
          }

          // Solo mostrar error si no está disponible en modo creación
          if (!available && !isEditMode) {
            _showError('Email no disponible', 'Este email ya está registrado');
          }
        },
      );
    } catch (e) {
      print('💥 [CONTROLLER] Error inesperado al validar email: $e');
      _emailAvailable.value = false;
      _showError('Error de validación', 'Error al verificar email: $e');
    } finally {
      _isValidatingEmail.value = false;
    }
  }

  Future<void> validateDocumentAvailability() async {
    final documentNumber = documentNumberController.text.trim();

    if (documentNumber.isEmpty || documentNumber.length < 3) {
      _documentAvailable.value = true;
      _documentValidatedOnce.value = false;
      return;
    }

    // Si estamos editando y el documento no cambió, marcarlo como disponible
    if (isEditMode &&
        _currentCustomer.value?.documentNumber == documentNumber &&
        _currentCustomer.value?.documentType == _selectedDocumentType.value) {
      _documentAvailable.value = true;
      _documentValidatedOnce.value = true;
      return;
    }

    // ✅ Cache: Si ya validamos este documento con este tipo, reutilizar resultado
    if (_lastValidatedDocument == documentNumber &&
        _lastValidatedDocumentType == _selectedDocumentType.value &&
        _documentValidatedOnce.value) {
      print(
        '✅ [CACHE] Documento ya validado previamente: ${_selectedDocumentType.value}:$documentNumber',
      );
      return;
    }

    _isValidatingDocument.value = true;
    _documentValidatedOnce.value = true;

    try {
      print(
        '🔍 [CONTROLLER] Validando disponibilidad de documento: ${_selectedDocumentType.value.name}:$documentNumber',
      );

      final result = await _customerRepository.isDocumentAvailable(
        _selectedDocumentType.value,
        documentNumber,
        excludeId: _currentCustomer.value?.id,
      );

      result.fold(
        (failure) {
          print(
            '⚠️ [CONTROLLER] Error al validar documento: ${failure.message}',
          );
          _documentAvailable.value = false;
          _showError(
            'Error de validación',
            'No se pudo verificar la disponibilidad del documento',
          );
        },
        (available) {
          print(
            '📄 [CONTROLLER] Documento ${_selectedDocumentType.value.name}:$documentNumber: ${available ? "DISPONIBLE" : "YA EXISTE"}',
          );
          _documentAvailable.value = available;

          // ✅ Actualizar cache solo si la validación fue exitosa
          if (available) {
            _lastValidatedDocument = documentNumber;
            _lastValidatedDocumentType = _selectedDocumentType.value;
          }

          // Solo mostrar error si no está disponible en modo creación
          if (!available && !isEditMode) {
            _showError(
              'Documento no disponible',
              'Este documento ya está registrado',
            );
          }
        },
      );
    } catch (e) {
      print('💥 [CONTROLLER] Error inesperado al validar documento: $e');
      _documentAvailable.value = false;
      _showError('Error de validación', 'Error al verificar documento: $e');
    } finally {
      _isValidatingDocument.value = false;
    }
  }

  // ==================== MANUAL VALIDATION ====================
  bool _validateFieldsManually() {
    print('🔍 Validando campos manualmente...');
    
    // Validar nombre
    final firstNameError = validateFirstName(firstNameController.text);
    if (firstNameError != null) {
      print('❌ Error en nombre: $firstNameError');
      return false;
    }
    
    // Validar apellido
    final lastNameError = validateLastName(lastNameController.text);
    if (lastNameError != null) {
      print('❌ Error en apellido: $lastNameError');
      return false;
    }
    
    // Validar email
    final emailError = validateEmail(emailController.text);
    if (emailError != null) {
      print('❌ Error en email: $emailError');
      return false;
    }
    
    // Validar documento
    final documentError = validateDocumentNumber(documentNumberController.text);
    if (documentError != null) {
      print('❌ Error en documento: $documentError');
      return false;
    }
    
    // Validar límite de crédito
    final creditLimitError = validateCreditLimit(creditLimitController.text);
    if (creditLimitError != null) {
      print('❌ Error en límite de crédito: $creditLimitError');
      return false;
    }
    
    // Validar términos de pago
    final paymentTermsError = validatePaymentTerms(paymentTermsController.text);
    if (paymentTermsError != null) {
      print('❌ Error en términos de pago: $paymentTermsError');
      return false;
    }
    
    print('✅ Todos los campos son válidos');
    return true;
  }

  // ==================== HELPERS ====================
  String? _getOptionalText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  double? _parseDouble(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  int? _parseInt(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  void cancel() {
    Get.back();
  }

  void _populateForm(Customer customer) {
    print(
      '📝 CustomerFormController: Poblando formulario con datos del cliente...',
    );

    firstNameController.text = customer.firstName;
    lastNameController.text = customer.lastName;
    companyNameController.text = customer.companyName ?? '';
    emailController.text = customer.email;
    phoneController.text = customer.phone ?? '';
    mobileController.text = customer.mobile ?? '';
    documentNumberController.text = customer.documentNumber;
    addressController.text = customer.address ?? '';
    cityController.text = customer.city ?? '';
    stateController.text = customer.state ?? '';
    zipCodeController.text = customer.zipCode ?? '';
    creditLimitController.text = customer.creditLimit.toString();
    paymentTermsController.text = customer.paymentTerms.toString();
    notesController.text = customer.notes ?? '';

    _selectedStatus.value = customer.status;
    _selectedDocumentType.value = customer.documentType;
    _birthDate.value = customer.birthDate;

    // ✅ IMPORTANTE: Marcar como validados ya que son datos existentes
    _emailAvailable.value = true;
    _documentAvailable.value = true;
    _emailValidatedOnce.value = true;
    _documentValidatedOnce.value = true;

    print('✅ CustomerFormController: Formulario poblado exitosamente');
  }

  void _disposeControllers() {
    print('🧹 CustomerFormController: Iniciando limpieza de controladores...');
    
    try {
      print('🧹 Disposing firstNameController...');
      firstNameController.dispose();
      
      print('🧹 Disposing lastNameController...');
      lastNameController.dispose();
      
      print('🧹 Disposing companyNameController...');
      companyNameController.dispose();
      
      print('🧹 Disposing emailController...');
      emailController.dispose();
      
      print('🧹 Disposing phoneController...');
      phoneController.dispose();
      
      print('🧹 Disposing mobileController...');
      mobileController.dispose();
      
      print('🧹 Disposing documentNumberController...');
      documentNumberController.dispose();
      
      print('🧹 Disposing addressController...');
      addressController.dispose();
      
      print('🧹 Disposing cityController...');
      cityController.dispose();
      
      print('🧹 Disposing stateController...');
      stateController.dispose();
      
      print('🧹 Disposing zipCodeController...');
      zipCodeController.dispose();
      
      print('🧹 Disposing creditLimitController...');
      creditLimitController.dispose();
      
      print('🧹 Disposing paymentTermsController...');
      paymentTermsController.dispose();
      
      print('🧹 Disposing notesController...');
      notesController.dispose();
      
      print('✅ CustomerFormController: Todos los controladores limpiados exitosamente');
    } catch (e) {
      print('💥 CustomerFormController: Error al limpiar controladores - $e');
      print('📍 Stack trace: ${StackTrace.current}');
    }
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
