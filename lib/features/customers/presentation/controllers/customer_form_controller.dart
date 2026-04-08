// lib/features/customers/presentation/controllers/customer_form_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/shared/widgets/safe_text_editing_controller.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import '../../domain/usecases/get_customer_by_id_usecase.dart';
import '../../../../app/shared/utils/subscription_error_handler.dart';
import '../../../../app/shared/services/subscription_validation_service.dart';
import 'customers_controller.dart';

class CustomerFormController extends GetxController {
  /// Deshabilitar logs de debug para producción
  static const bool _enableDebugLogs = false;

  void _log(String message) {
    if (_enableDebugLogs) {
      // ignore: avoid_print
      debugPrint('[CustomerForm] $message');
    }
  }

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
    _log('🎮 CustomerFormController: Instancia creada correctamente');
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

  // ==================== COLLAPSIBLE SECTIONS ====================
  // Variables para controlar secciones colapsables
  final showAdditionalInfo = false.obs;
  final showAdditionalContact = false.obs;
  final showConfiguration = false.obs;
  final showFinancial = false.obs;

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
    SyncService.notifyFormOpened();
    _log('🚀 CustomerFormController: Inicializando...');
    _log(
      '🔍 CustomerFormController: isEditMode = $isEditMode, customerId = "$customerId"',
    );

    _initializeForm();
  }

  @override
  void onClose() {
    SyncService.notifyFormClosed();
    _log('🔚 CustomerFormController: Liberando recursos...');

    try {
      _log('⏹️ Cancelando timer de validación de email...');
      _emailValidationTimer?.cancel();
      
      _log('⏹️ Cancelando timer de validación de documento...');
      _documentValidationTimer?.cancel();

      _log('🧹 Limpiando cache de validaciones...');
      // ✅ Limpiar cache de validaciones
      _lastValidatedEmail = null;
      _lastValidatedDocument = null;
      _lastValidatedDocumentType = null;

      _log('🎮 Llamando a _disposeControllers()...');
      _disposeControllers();
      
      _log('🔚 Llamando a super.onClose()...');
      super.onClose();
      
      _log('✅ CustomerFormController: Recursos liberados exitosamente');
    } catch (e) {
      _log('💥 CustomerFormController: Error durante onClose() - $e');
      _log('📍 Stack trace: ${StackTrace.current}');
      // Intentar llamar super.onClose() aunque haya errores
      try {
        super.onClose();
      } catch (superError) {
        _log('💥 Error adicional en super.onClose() - $superError');
      }
    }
  }

  // ==================== PRIVATE INITIALIZATION ====================

  void _initializeForm() {
    _log('⚙️ CustomerFormController: Configurando formulario...');

    _setDefaultValues();

    if (isEditMode) {
      _log(
        '📝 CustomerFormController: Modo edición detectado, cargando cliente...',
      );
      Future.microtask(() => loadCustomer(customerId));
    }

    _log('✅ CustomerFormController: Inicialización completada');
  }

  // Valor por defecto para límite de crédito (3,000,000)
  static const double defaultCreditLimit = 3000000;

  void _setDefaultValues() {
    // Usar formateo para valores numéricos
    creditLimitController.text = NumberInputFormatter.formatValueForDisplay(defaultCreditLimit, allowDecimals: false);
    paymentTermsController.text = '30';
    _selectedStatus.value = CustomerStatus.active;
    _selectedDocumentType.value = DocumentType.cc;

    _log('✅ CustomerFormController: Valores por defecto configurados');
  }

  /// Resetea el límite de crédito al valor por defecto (3,000,000)
  void resetCreditLimitToDefault() {
    creditLimitController.text = NumberInputFormatter.formatValueForDisplay(
      defaultCreditLimit,
      allowDecimals: false,
    );
  }

  /// Limpia todos los campos del formulario y resetea valores por defecto
  void clearAllFields() {
    firstNameController.clear();
    lastNameController.clear();
    companyNameController.clear();
    emailController.clear();
    phoneController.clear();
    mobileController.clear();
    documentNumberController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    zipCodeController.clear();
    notesController.clear();

    // Resetear valores por defecto
    _setDefaultValues();

    // Limpiar errores de validación
    _documentAvailable.value = true;
    _emailAvailable.value = true;
    _isValidatingDocument.value = false;
    _isValidatingEmail.value = false;

    update();
  }

  // ==================== PUBLIC METHODS ====================

  Future<void> loadCustomer(String customerId) async {
    _log(
      '📥 CustomerFormController: Iniciando carga de cliente para edición...',
    );
    _isLoadingCustomer.value = true;

    try {
      _log('📥 Cargando cliente: $customerId');

      final result = await _getCustomerByIdUseCase(
        GetCustomerByIdParams(id: customerId),
      );

      result.fold(
        (failure) {
          _log(
            '❌ CustomerFormController: Error al cargar cliente - ${failure.message}',
          );
          _showError('Error al cargar cliente', failure.message);
          Get.back();
        },
        (customer) {
          _log(
            '✅ CustomerFormController: Cliente cargado exitosamente - ${customer.displayName}',
          );
          _currentCustomer.value = customer;
          _populateForm(customer);
        },
      );
    } catch (e) {
      _log(
        '💥 CustomerFormController: Error inesperado al cargar cliente - $e',
      );
      _showError('Error inesperado', 'No se pudo cargar el cliente: $e');
      Get.back();
    } finally {
      _isLoadingCustomer.value = false;
      _log('🏁 CustomerFormController: Carga de cliente finalizada');
    }
  }

  Future<void> saveCustomer() async {
    _log('💾 CustomerFormController: Iniciando guardado de cliente...');

    // Cancelar timers pendientes para evitar conflictos
    _emailValidationTimer?.cancel();
    _documentValidationTimer?.cancel();

    // Mostrar estado de validación durante validaciones asíncronas
    _isSaving.value = true;

    if (!await _validateFormAsync()) {
      _log('❌ CustomerFormController: Validación de formulario falló');
      _isSaving.value = false; // Reset loading state on validation failure
      return;
    }

    try {
      if (isEditMode) {
        _log('🔄 CustomerFormController: Actualizando cliente existente...');
        await _updateCustomer();
      } else {
        _log('🆕 CustomerFormController: Creando nuevo cliente...');
        await _createCustomer();
      }
    } catch (e) {
      _log('💥 CustomerFormController: Error inesperado al guardar - $e');
      _showError('Error inesperado', 'No se pudo guardar el cliente: $e');
    } finally {
      _isSaving.value = false;
      _log('🏁 CustomerFormController: Guardado finalizado');
    }
  }

  Future<bool> _validateFormAsync() async {
    _log('🔍 Iniciando validación completa del formulario...');

    // 1. Validar campos manualmente sin depender del formKey
    final validationError = _validateFieldsManually();
    if (validationError != null) {
      _showError('Formulario inválido', validationError);
      return false;
    }

    // 3. Esperar a que terminen las validaciones en progreso (si las hay)
    if (_isValidatingEmail.value || _isValidatingDocument.value) {
      _log('⏳ Esperando validaciones en progreso...');

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

      _log('✅ Validaciones completadas, continuando...');
    }

    // 4. Forzar validación de email si es necesario
    final email = emailController.text.trim();
    if (email.isNotEmpty && GetUtils.isEmail(email)) {
      if (!_emailValidatedOnce.value ||
          (isEditMode && _currentCustomer.value?.email != email) ||
          !isEditMode) {
        _log('📧 Validando email antes de guardar...');
        await validateEmailAvailability();
      } else {
        _log('✅ Email ya validado, saltando validación');
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
        _log('📄 Validando documento antes de guardar...');
        await validateDocumentAvailability();
      } else {
        _log('✅ Documento ya validado, saltando validación');
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

    _log('✅ Validación completa exitosa');
    return true;
  }

  // ==================== FORM ACTIONS ====================

  Future<void> _createCustomer() async {
    // 🔒 VALIDACIÓN FRONTEND: Verificar suscripción ANTES de llamar al backend
    if (!await SubscriptionValidationService.canCreateCustomerAsync()) {
      _log('🚫 FRONTEND BLOCK: Suscripción expirada - BLOQUEANDO creación de cliente');
      return; // Bloquear operación
    }
    
    _log('✅ FRONTEND VALIDATION: Suscripción válida - CONTINUANDO con creación de cliente');
    _log('🆕 Creando nuevo cliente...');

    final result = await _createCustomerUseCase(
      CreateCustomerParams(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        companyName: _getOptionalText(companyNameController),
        email: emailController.text.trim(),
        phone: _normalizePhone(phoneController.text),
        mobile: _normalizePhone(mobileController.text),
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
        _log(
          '✅ CustomerFormController: Cliente creado exitosamente - ${customer.displayName}',
        );

        // Refrescar listado de clientes para que aparezca el nuevo
        _refreshCustomersList();

        // Navegar primero, luego snackbar (se muestra en el listado)
        Get.back(result: customer);
        _showSuccess('Cliente creado exitosamente');
      },
    );
  }

  Future<void> _updateCustomer() async {
    // 🔒 VALIDACIÓN FRONTEND: Verificar suscripción ANTES de llamar al backend
    if (!await SubscriptionValidationService.canUpdateCustomerAsync()) {
      _log('🚫 FRONTEND BLOCK: Suscripción expirada - BLOQUEANDO actualización de cliente');
      return; // Bloquear operación
    }
    
    _log('✅ FRONTEND VALIDATION: Suscripción válida - CONTINUANDO con actualización de cliente');
    _log('📝 Actualizando cliente...');

    final result = await _updateCustomerUseCase(
      UpdateCustomerParams(
        id: _currentCustomer.value!.id,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        companyName: _getOptionalText(companyNameController),
        email: emailController.text.trim(),
        phone: _normalizePhone(phoneController.text),
        mobile: _normalizePhone(mobileController.text),
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
        _log(
          '✅ CustomerFormController: Cliente actualizado exitosamente - ${customer.displayName}',
        );

        // Refrescar listado de clientes para que refleje los cambios
        _refreshCustomersList();

        // Navegar primero, luego snackbar (se muestra en el listado)
        Get.back(result: customer);
        _showSuccess('Cliente actualizado exitosamente');
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
      // Usar NumberInputFormatter para parsear valores con separadores de miles
      final parsed = NumberInputFormatter.getNumericValue(value);
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

  /// Valida un número de teléfono colombiano.
  /// Acepta: 3001234567, +573001234567, +57 300 123 4567
  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido';
    }
    return _validateColombianPhone(value);
  }

  /// Valida celular (opcional - solo valida formato si tiene contenido)
  String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Celular es opcional
    }
    return _validateColombianPhone(value);
  }

  /// Lógica compartida de validación de teléfono colombiano
  String? _validateColombianPhone(String value) {
    // Limpiar: quitar espacios, guiones, paréntesis, +
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Solo dígitos después de limpiar
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Solo puede contener números';
    }

    // Con código de país 57: debe tener 12 dígitos (57 + 10)
    if (cleaned.startsWith('57')) {
      if (cleaned.length != 12) {
        return 'Formato: 3XX XXX XXXX (10 dígitos)';
      }
      // Verificar que después de 57 inicie con 3 (móvil) o dígito fijo válido
      return null;
    }

    // Sin código de país: debe tener 10 dígitos
    if (cleaned.length < 10) {
      return 'Faltan dígitos (${cleaned.length}/10)';
    }
    if (cleaned.length > 10) {
      return 'Demasiados dígitos (${cleaned.length}/10)';
    }

    return null;
  }

  /// Retorna true si el teléfono actual es válido
  bool get isPhoneValid => validatePhone(phoneController.text) == null;

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
      _log('✅ [CACHE] Email ya validado previamente: $email');
      return;
    }

    _isValidatingEmail.value = true;
    _emailValidatedOnce.value = true;

    try {
      _log('🔍 [CONTROLLER] Validando disponibilidad de email: $email');

      final result = await _customerRepository.isEmailAvailable(
        email,
        excludeId: _currentCustomer.value?.id,
      );

      result.fold(
        (failure) {
          _log('⚠️ [CONTROLLER] Error al validar email: ${failure.message}');
          _emailAvailable.value = false;
          _showError(
            'Error de validación',
            'No se pudo verificar la disponibilidad del email',
          );
        },
        (available) {
          _log(
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
      _log('💥 [CONTROLLER] Error inesperado al validar email: $e');
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
      _log(
        '✅ [CACHE] Documento ya validado previamente: ${_selectedDocumentType.value}:$documentNumber',
      );
      return;
    }

    _isValidatingDocument.value = true;
    _documentValidatedOnce.value = true;

    try {
      _log(
        '🔍 [CONTROLLER] Validando disponibilidad de documento: ${_selectedDocumentType.value.name}:$documentNumber',
      );

      final result = await _customerRepository.isDocumentAvailable(
        _selectedDocumentType.value,
        documentNumber,
        excludeId: _currentCustomer.value?.id,
      );

      result.fold(
        (failure) {
          _log(
            '⚠️ [CONTROLLER] Error al validar documento: ${failure.message}',
          );
          _documentAvailable.value = false;
          _showError(
            'Error de validación',
            'No se pudo verificar la disponibilidad del documento',
          );
        },
        (available) {
          _log(
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
      _log('💥 [CONTROLLER] Error inesperado al validar documento: $e');
      _documentAvailable.value = false;
      _showError('Error de validación', 'Error al verificar documento: $e');
    } finally {
      _isValidatingDocument.value = false;
    }
  }

  // ==================== MANUAL VALIDATION ====================
  /// Retorna null si todos los campos son válidos, o un mensaje de error específico
  String? _validateFieldsManually() {
    _log('🔍 Validando campos manualmente...');

    // Validar nombre
    final firstNameError = validateFirstName(firstNameController.text);
    if (firstNameError != null) {
      _log('❌ Error en nombre: $firstNameError');
      return 'Nombre: $firstNameError';
    }

    // Validar apellido
    final lastNameError = validateLastName(lastNameController.text);
    if (lastNameError != null) {
      _log('❌ Error en apellido: $lastNameError');
      return 'Apellido: $lastNameError';
    }

    // Validar email
    final emailError = validateEmail(emailController.text);
    if (emailError != null) {
      _log('❌ Error en email: $emailError');
      return 'Email: $emailError';
    }

    // Validar documento
    final documentError = validateDocumentNumber(documentNumberController.text);
    if (documentError != null) {
      _log('❌ Error en documento: $documentError');
      return 'Documento: $documentError';
    }

    // Validar teléfono
    final phoneError = validatePhone(phoneController.text);
    if (phoneError != null) {
      _log('❌ Error en teléfono: $phoneError');
      return 'Teléfono: $phoneError';
    }

    // Validar celular (opcional pero si tiene contenido debe ser válido)
    final mobileError = validateMobile(mobileController.text);
    if (mobileError != null) {
      _log('❌ Error en celular: $mobileError');
      return 'Celular: $mobileError';
    }

    // Validar límite de crédito
    final creditLimitError = validateCreditLimit(creditLimitController.text);
    if (creditLimitError != null) {
      _log('❌ Error en límite de crédito: $creditLimitError');
      return 'Límite de crédito: $creditLimitError';
    }

    // Validar términos de pago
    final paymentTermsError = validatePaymentTerms(paymentTermsController.text);
    if (paymentTermsError != null) {
      _log('❌ Error en términos de pago: $paymentTermsError');
      return 'Términos de pago: $paymentTermsError';
    }

    _log('✅ Todos los campos son válidos');
    return null;
  }

  // ==================== HELPERS ====================
  String? _getOptionalText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  /// Normaliza un teléfono colombiano al formato +57XXXXXXXXXX
  String? _normalizePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;
    final cleaned = phone.trim().replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (cleaned.isEmpty) return null;
    if (cleaned.startsWith('57') && cleaned.length == 12) {
      return '+$cleaned';
    }
    if (cleaned.length == 10) {
      return '+57$cleaned';
    }
    return phone.trim(); // Devolver tal cual si no se puede normalizar
  }

  /// Refresca el listado de clientes en el CustomersController
  void _refreshCustomersList() {
    try {
      if (Get.isRegistered<CustomersController>()) {
        Get.find<CustomersController>().refreshCustomers();
      }
    } catch (_) {}
  }

  /// Parsea un string formateado (ej: "1.000.000") a double
  /// Usa NumberInputFormatter para manejar separadores de miles
  double? _parseDouble(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    // Usar NumberInputFormatter para manejar formatos con separadores de miles
    return NumberInputFormatter.getNumericValue(trimmed);
  }

  /// Parsea un string formateado (ej: "1.000") a int
  /// Usa NumberInputFormatter para manejar separadores de miles
  int? _parseInt(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    // Usar NumberInputFormatter para manejar formatos con separadores de miles
    final doubleValue = NumberInputFormatter.getNumericValue(trimmed);
    return doubleValue?.toInt();
  }

  void cancel() {
    Get.back();
  }

  void _populateForm(Customer customer) {
    _log(
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
    // Formatear valores numéricos para mostrar con separadores de miles
    creditLimitController.text = NumberInputFormatter.formatValueForDisplay(
      customer.creditLimit,
      allowDecimals: false,
    );
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

    _log('✅ CustomerFormController: Formulario poblado exitosamente');
  }

  void _disposeControllers() {
    _log('🧹 CustomerFormController: Iniciando limpieza de controladores...');
    
    try {
      _log('🧹 Disposing firstNameController...');
      firstNameController.dispose();
      
      _log('🧹 Disposing lastNameController...');
      lastNameController.dispose();
      
      _log('🧹 Disposing companyNameController...');
      companyNameController.dispose();
      
      _log('🧹 Disposing emailController...');
      emailController.dispose();
      
      _log('🧹 Disposing phoneController...');
      phoneController.dispose();
      
      _log('🧹 Disposing mobileController...');
      mobileController.dispose();
      
      _log('🧹 Disposing documentNumberController...');
      documentNumberController.dispose();
      
      _log('🧹 Disposing addressController...');
      addressController.dispose();
      
      _log('🧹 Disposing cityController...');
      cityController.dispose();
      
      _log('🧹 Disposing stateController...');
      stateController.dispose();
      
      _log('🧹 Disposing zipCodeController...');
      zipCodeController.dispose();
      
      _log('🧹 Disposing creditLimitController...');
      creditLimitController.dispose();
      
      _log('🧹 Disposing paymentTermsController...');
      paymentTermsController.dispose();
      
      _log('🧹 Disposing notesController...');
      notesController.dispose();
      
      _log('✅ CustomerFormController: Todos los controladores limpiados exitosamente');
    } catch (e) {
      _log('💥 CustomerFormController: Error al limpiar controladores - $e');
      _log('📍 Stack trace: ${StackTrace.current}');
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
