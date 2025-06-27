// // lib/features/customers/presentation/controllers/customer_form_controller.dart
// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../domain/entities/customer.dart';
// import '../../domain/repositories/customer_repository.dart';
// import '../../domain/usecases/create_customer_usecase.dart';
// import '../../domain/usecases/update_customer_usecase.dart';
// import '../../domain/usecases/get_customer_by_id_usecase.dart';

// class CustomerFormController extends GetxController {
//   Timer? _emailValidationTimer;
//   Timer? _documentValidationTimer;
//   // Dependencies
//   final CreateCustomerUseCase _createCustomerUseCase;
//   final UpdateCustomerUseCase _updateCustomerUseCase;
//   final GetCustomerByIdUseCase _getCustomerByIdUseCase;
//   final CustomerRepository _customerRepository;

//   CustomerFormController({
//     required CreateCustomerUseCase createCustomerUseCase,
//     required UpdateCustomerUseCase updateCustomerUseCase,
//     required GetCustomerByIdUseCase getCustomerByIdUseCase,
//     required CustomerRepository customerRepository,
//   }) : _createCustomerUseCase = createCustomerUseCase,
//        _updateCustomerUseCase = updateCustomerUseCase,
//        _getCustomerByIdUseCase = getCustomerByIdUseCase,
//        _customerRepository = customerRepository {
//     print('🎮 CustomerFormController: Instancia creada correctamente');
//   }

//   // ==================== FORM KEY ====================
//   final formKey = GlobalKey<FormState>();

//   // ==================== TEXT CONTROLLERS ====================
//   final firstNameController = TextEditingController();
//   final lastNameController = TextEditingController();
//   final companyNameController = TextEditingController();
//   final emailController = TextEditingController();
//   final phoneController = TextEditingController();
//   final mobileController = TextEditingController();
//   final documentNumberController = TextEditingController();
//   final addressController = TextEditingController();
//   final cityController = TextEditingController();
//   final stateController = TextEditingController();
//   final zipCodeController = TextEditingController();
//   final creditLimitController = TextEditingController();
//   final paymentTermsController = TextEditingController();
//   final notesController = TextEditingController();

//   // ==================== OBSERVABLES ====================
//   final _isLoading = false.obs;
//   final _isLoadingCustomer = false.obs;
//   final _isSaving = false.obs; // ✅ NUEVO - Separar loading de guardado
//   final _selectedStatus = CustomerStatus.active.obs;
//   final _selectedDocumentType = DocumentType.cc.obs;
//   final _birthDate = Rxn<DateTime>();
//   final _currentCustomer = Rxn<Customer>();

//   // Validation states
//   final _emailAvailable = true.obs;
//   final _documentAvailable = true.obs;
//   final _isValidatingEmail = false.obs;
//   final _isValidatingDocument = false.obs;

//   // ==================== GETTERS ====================
//   bool get isLoading => _isLoading.value;
//   bool get isLoadingCustomer => _isLoadingCustomer.value;
//   bool get isSaving => _isSaving.value; // ✅ NUEVO
//   CustomerStatus get selectedStatus => _selectedStatus.value;
//   DocumentType get selectedDocumentType => _selectedDocumentType.value;
//   DateTime? get birthDate => _birthDate.value;
//   Customer? get currentCustomer => _currentCustomer.value;
//   bool get emailAvailable => _emailAvailable.value;
//   bool get documentAvailable => _documentAvailable.value;
//   bool get isValidatingEmail => _isValidatingEmail.value;
//   bool get isValidatingDocument => _isValidatingDocument.value;

//   String get customerId => Get.parameters['id'] ?? '';
//   bool get isEditMode => customerId.isNotEmpty;
//   bool get hasCustomer => _currentCustomer.value != null;
//   String get formTitle => isEditMode ? 'Editar Cliente' : 'Nuevo Cliente';
//   String get submitButtonText => isEditMode ? 'Actualizar' : 'Crear Cliente';

//   // ==================== LIFECYCLE ====================
//   @override
//   void onInit() {
//     super.onInit();
//     print('🚀 CustomerFormController: Inicializando...');
//     print(
//       '🔍 CustomerFormController: isEditMode = $isEditMode, customerId = "$customerId"',
//     );

//     // ✅ SOLUCIÓN: Mover la carga asíncrona fuera de onInit
//     _initializeForm();
//   }

//   @override
//   void onClose() {
//     print('🔚 CustomerFormController: Liberando recursos...');
//     _disposeControllers();
//     super.onClose();
//   }

//   // ==================== PRIVATE INITIALIZATION ====================

//   /// ✅ Inicialización sin bloqueos
//   void _initializeForm() {
//     print('⚙️ CustomerFormController: Configurando formulario...');

//     // Configurar valores por defecto inmediatamente (síncronos)
//     _setDefaultValues();

//     // Si es modo edición, cargar datos de forma asíncrona SIN AWAIT
//     if (isEditMode) {
//       print(
//         '📝 CustomerFormController: Modo edición detectado, cargando cliente...',
//       );

//       // ✅ CLAVE: Usar Future.microtask para no bloquear onInit
//       Future.microtask(() => loadCustomer(customerId));
//     }

//     print('✅ CustomerFormController: Inicialización completada');
//   }

//   /// Configurar valores por defecto (operaciones síncronas únicamente)
//   void _setDefaultValues() {
//     creditLimitController.text = '0';
//     paymentTermsController.text = '30';
//     _selectedStatus.value = CustomerStatus.active;
//     _selectedDocumentType.value = DocumentType.cc;

//     print('✅ CustomerFormController: Valores por defecto configurados');
//   }

//   // ==================== PUBLIC METHODS ====================

//   /// Cargar cliente para edición (ahora completamente asíncrono)
//   Future<void> loadCustomer(String customerId) async {
//     print(
//       '📥 CustomerFormController: Iniciando carga de cliente para edición...',
//     );
//     _isLoadingCustomer.value = true;

//     try {
//       print('📥 Cargando cliente: $customerId');

//       final result = await _getCustomerByIdUseCase(
//         GetCustomerByIdParams(id: customerId),
//       );

//       result.fold(
//         (failure) {
//           print(
//             '❌ CustomerFormController: Error al cargar cliente - ${failure.message}',
//           );
//           _showError('Error al cargar cliente', failure.message);
//           Get.back();
//         },
//         (customer) {
//           print(
//             '✅ CustomerFormController: Cliente cargado exitosamente - ${customer.displayName}',
//           );
//           _currentCustomer.value = customer;
//           _populateForm(customer);
//         },
//       );
//     } catch (e) {
//       print(
//         '💥 CustomerFormController: Error inesperado al cargar cliente - $e',
//       );
//       _showError('Error inesperado', 'No se pudo cargar el cliente: $e');
//       Get.back();
//     } finally {
//       _isLoadingCustomer.value = false;
//       print('🏁 CustomerFormController: Carga de cliente finalizada');
//     }
//   }

//   /// Guardar cliente (crear o actualizar)
//   // Future<void> saveCustomer() async {
//   //   print('💾 CustomerFormController: Iniciando guardado de cliente...');

//   //   if (!_validateForm()) {
//   //     print('❌ CustomerFormController: Validación de formulario falló');
//   //     return;
//   //   }

//   //   _isSaving.value = true; // ✅ USAR isSaving en lugar de isLoading

//   //   try {
//   //     if (isEditMode) {
//   //       print('🔄 CustomerFormController: Actualizando cliente existente...');
//   //       await _updateCustomer();
//   //     } else {
//   //       print('🆕 CustomerFormController: Creando nuevo cliente...');
//   //       await _createCustomer();
//   //     }
//   //   } catch (e) {
//   //     print('💥 CustomerFormController: Error inesperado al guardar - $e');
//   //     _showError('Error inesperado', 'No se pudo guardar el cliente: $e');
//   //   } finally {
//   //     _isSaving.value = false;
//   //     print('🏁 CustomerFormController: Guardado finalizado');
//   //   }
//   // }

//   Future<void> saveCustomer() async {
//     print('💾 CustomerFormController: Iniciando guardado de cliente...');

//     // ✅ NUEVO: Validar formulario con validaciones asíncronas
//     if (!await _validateFormAsync()) {
//       print('❌ CustomerFormController: Validación de formulario falló');
//       return;
//     }

//     _isSaving.value = true;

//     try {
//       if (isEditMode) {
//         print('🔄 CustomerFormController: Actualizando cliente existente...');
//         await _updateCustomer();
//       } else {
//         print('🆕 CustomerFormController: Creando nuevo cliente...');
//         await _createCustomer();
//       }
//     } catch (e) {
//       print('💥 CustomerFormController: Error inesperado al guardar - $e');
//       _showError('Error inesperado', 'No se pudo guardar el cliente: $e');
//     } finally {
//       _isSaving.value = false;
//       print('🏁 CustomerFormController: Guardado finalizado');
//     }
//   }

//   Future<bool> _validateFormAsync() async {
//     print('🔍 Iniciando validación completa del formulario...');

//     // 1. Validar campos básicos del formulario
//     if (!formKey.currentState!.validate()) {
//       _showError(
//         'Formulario inválido',
//         'Por favor corrige los errores en los campos',
//       );
//       return false;
//     }

//     // 2. Verificar que no haya validaciones en progreso
//     if (_isValidatingEmail.value || _isValidatingDocument.value) {
//       _showError(
//         'Validación en progreso',
//         'Espera a que terminen las validaciones',
//       );
//       return false;
//     }

//     // 3. Forzar validación de email si es necesario
//     final email = emailController.text.trim();
//     if (email.isNotEmpty && GetUtils.isEmail(email)) {
//       if (isEditMode && _currentCustomer.value?.email != email) {
//         // Email cambió en modo edición, revalidar
//         print('📧 Email cambió, revalidando...');
//         await validateEmailAvailability();
//       } else if (!isEditMode) {
//         // Modo creación, siempre validar
//         print('📧 Modo creación, validando email...');
//         await validateEmailAvailability();
//       }
//     }

//     // 4. Forzar validación de documento si es necesario
//     final documentNumber = documentNumberController.text.trim();
//     if (documentNumber.isNotEmpty) {
//       if (isEditMode &&
//           (_currentCustomer.value?.documentNumber != documentNumber ||
//               _currentCustomer.value?.documentType !=
//                   _selectedDocumentType.value)) {
//         // Documento cambió en modo edición, revalidar
//         print('📄 Documento cambió, revalidando...');
//         await validateDocumentAvailability();
//       } else if (!isEditMode) {
//         // Modo creación, siempre validar
//         print('📄 Modo creación, validando documento...');
//         await validateDocumentAvailability();
//       }
//     }

//     // 5. Verificar resultados de validaciones asíncronas
//     if (!_emailAvailable.value) {
//       _showError('Email no disponible', 'El email ya está registrado');
//       return false;
//     }

//     if (!_documentAvailable.value) {
//       _showError('Documento no disponible', 'El documento ya está registrado');
//       return false;
//     }

//     print('✅ Validación completa exitosa');
//     return true;
//   }

//   // ==================== FORM ACTIONS ====================

//   Future<void> _createCustomer() async {
//     print('🆕 Creando nuevo cliente...');

//     final result = await _createCustomerUseCase(
//       CreateCustomerParams(
//         firstName: firstNameController.text.trim(),
//         lastName: lastNameController.text.trim(),
//         companyName: _getOptionalText(companyNameController),
//         email: emailController.text.trim(),
//         phone: _getOptionalText(phoneController),
//         mobile: _getOptionalText(mobileController),
//         documentType: _selectedDocumentType.value,
//         documentNumber: documentNumberController.text.trim(),
//         address: _getOptionalText(addressController),
//         city: _getOptionalText(cityController),
//         state: _getOptionalText(stateController),
//         zipCode: _getOptionalText(zipCodeController),
//         country: 'Colombia',
//         status: _selectedStatus.value,
//         creditLimit: _parseDouble(creditLimitController.text),
//         paymentTerms: _parseInt(paymentTermsController.text),
//         birthDate: _birthDate.value,
//         notes: _getOptionalText(notesController),
//       ),
//     );

//     result.fold(
//       (failure) {
//         print(
//           '❌ CustomerFormController: Error al crear cliente - ${failure.message}',
//         );
//         _showError('Error al crear cliente', failure.message);
//       },
//       (customer) {
//         print(
//           '✅ CustomerFormController: Cliente creado exitosamente - ${customer.displayName}',
//         );
//         _showSuccess('Cliente creado exitosamente');

//         // ✅ CAMBIO: Navegar a la lista de clientes en lugar de Get.back()
//         if (Get.currentRoute.contains('/customers/create')) {
//           Get.offAllNamed('/customers');
//         } else {
//           Get.back(result: customer);
//         }
//       },
//     );
//   }

//   Future<void> _updateCustomer() async {
//     print('📝 Actualizando cliente...');

//     final result = await _updateCustomerUseCase(
//       UpdateCustomerParams(
//         id: _currentCustomer.value!.id,
//         firstName: firstNameController.text.trim(),
//         lastName: lastNameController.text.trim(),
//         companyName: _getOptionalText(companyNameController),
//         email: emailController.text.trim(),
//         phone: _getOptionalText(phoneController),
//         mobile: _getOptionalText(mobileController),
//         documentType: _selectedDocumentType.value,
//         documentNumber: documentNumberController.text.trim(),
//         address: _getOptionalText(addressController),
//         city: _getOptionalText(cityController),
//         state: _getOptionalText(stateController),
//         zipCode: _getOptionalText(zipCodeController),
//         country: 'Colombia',
//         status: _selectedStatus.value,
//         creditLimit: _parseDouble(creditLimitController.text),
//         paymentTerms: _parseInt(paymentTermsController.text),
//         birthDate: _birthDate.value,
//         notes: _getOptionalText(notesController),
//       ),
//     );

//     result.fold(
//       (failure) {
//         print(
//           '❌ CustomerFormController: Error al actualizar cliente - ${failure.message}',
//         );
//         _showError('Error al actualizar cliente', failure.message);
//       },
//       (customer) {
//         print(
//           '✅ CustomerFormController: Cliente actualizado exitosamente - ${customer.displayName}',
//         );
//         _showSuccess('Cliente actualizado exitosamente');

//         // ✅ PARA EDICIÓN: Ir al detalle del cliente editado
//         Get.offAllNamed('/customers/detail/${customer.id}');
//       },
//     );
//   }

//   // ==================== FORM FIELD CHANGES ====================
//   void changeStatus(CustomerStatus status) {
//     _selectedStatus.value = status;
//   }

//   // void changeDocumentType(DocumentType documentType) {
//   //   _selectedDocumentType.value = documentType;
//   //   // Limpiar y revalidar documento cuando cambia el tipo
//   //   documentNumberController.clear();
//   //   _documentAvailable.value = true;
//   // }

//   void changeDocumentType(DocumentType documentType) {
//     _selectedDocumentType.value = documentType;

//     // Si hay un número de documento, revalidar con el nuevo tipo
//     if (documentNumberController.text.trim().isNotEmpty) {
//       _documentAvailable.value = true; // Resetear estado
//       // Validar después de un pequeño delay para evitar múltiples validaciones
//       Future.delayed(const Duration(milliseconds: 500), () {
//         validateDocumentAvailability();
//       });
//     } else {
//       _documentAvailable.value = true;
//     }
//   }

//   // ✅ NUEVO: Método para manejar cambios en email con debounce
//   void onEmailChanged(String value) {
//     // Cancelar validación anterior si existe
//     _emailValidationTimer?.cancel();

//     // Resetear estado mientras el usuario escribe
//     if (value.trim().isEmpty) {
//       _emailAvailable.value = true;
//       return;
//     }

//     // Validar después de 800ms de inactividad
//     _emailValidationTimer = Timer(const Duration(milliseconds: 800), () {
//       validateEmailAvailability();
//     });
//   }

//   // ✅ NUEVO: Método para manejar cambios en documento con debounce
//   void onDocumentNumberChanged(String value) {
//     // Cancelar validación anterior si existe
//     _documentValidationTimer?.cancel();

//     // Resetear estado mientras el usuario escribe
//     if (value.trim().isEmpty) {
//       _documentAvailable.value = true;
//       return;
//     }

//     // Validar después de 800ms de inactividad
//     _documentValidationTimer = Timer(const Duration(milliseconds: 800), () {
//       validateDocumentAvailability();
//     });
//   }

//   void changeBirthDate(DateTime? date) {
//     _birthDate.value = date;
//   }

//   // ==================== VALIDATION ====================
//   // bool _validateForm() {
//   //   if (!formKey.currentState!.validate()) {
//   //     _showError('Formulario inválido', 'Por favor corrige los errores');
//   //     return false;
//   //   }

//   //   if (!_emailAvailable.value) {
//   //     _showError('Email no disponible', 'El email ya está registrado');
//   //     return false;
//   //   }

//   //   if (!_documentAvailable.value) {
//   //     _showError('Documento no disponible', 'El documento ya está registrado');
//   //     return false;
//   //   }

//   //   return true;
//   // }

//   bool _validateForm() {
//     if (!formKey.currentState!.validate()) {
//       _showError('Formulario inválido', 'Por favor corrige los errores');
//       return false;
//     }

//     if (!_emailAvailable.value) {
//       _showError('Email no disponible', 'El email ya está registrado');
//       return false;
//     }

//     if (!_documentAvailable.value) {
//       _showError('Documento no disponible', 'El documento ya está registrado');
//       return false;
//     }

//     return true;
//   }

//   // Validators individuales
//   String? validateFirstName(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'El nombre es requerido';
//     }
//     if (value.trim().length < 2) {
//       return 'El nombre debe tener al menos 2 caracteres';
//     }
//     return null;
//   }

//   String? validateLastName(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'El apellido es requerido';
//     }
//     if (value.trim().length < 2) {
//       return 'El apellido debe tener al menos 2 caracteres';
//     }
//     return null;
//   }

//   String? validateEmail(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'El email es requerido';
//     }
//     if (!GetUtils.isEmail(value.trim())) {
//       return 'Ingresa un email válido';
//     }
//     return null;
//   }

//   String? validateDocumentNumber(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'El número de documento es requerido';
//     }
//     if (value.trim().length < 3) {
//       return 'El documento debe tener al menos 3 caracteres';
//     }
//     return null;
//   }

//   String? validateCreditLimit(String? value) {
//     if (value != null && value.isNotEmpty) {
//       final parsed = double.tryParse(value);
//       if (parsed == null || parsed < 0) {
//         return 'Ingresa un límite de crédito válido';
//       }
//     }
//     return null;
//   }

//   String? validatePaymentTerms(String? value) {
//     if (value != null && value.isNotEmpty) {
//       final parsed = int.tryParse(value);
//       if (parsed == null || parsed < 1) {
//         return 'Los términos de pago deben ser al menos 1 día';
//       }
//     }
//     return null;
//   }

//   // ==================== ASYNC VALIDATION ====================
//   // Future<void> validateEmailAvailability() async {
//   //   final email = emailController.text.trim();
//   //   if (email.isEmpty || !GetUtils.isEmail(email)) return;

//   //   // Si estamos editando y el email no cambió, no validar
//   //   if (isEditMode && _currentCustomer.value?.email == email) {
//   //     _emailAvailable.value = true;
//   //     return;
//   //   }

//   //   _isValidatingEmail.value = true;

//   //   try {
//   //     final result = await _customerRepository.isEmailAvailable(
//   //       email,
//   //       excludeId: _currentCustomer.value?.id,
//   //     );

//   //     result.fold(
//   //       (failure) {
//   //         print('⚠️ Error al validar email: ${failure.message}');
//   //       },
//   //       (available) {
//   //         _emailAvailable.value = available;
//   //       },
//   //     );
//   //   } finally {
//   //     _isValidatingEmail.value = false;
//   //   }
//   // }

//   Future<void> validateEmailAvailability() async {
//     final email = emailController.text.trim();

//     // Validaciones previas
//     if (email.isEmpty) {
//       _emailAvailable.value = true;
//       return;
//     }

//     if (!GetUtils.isEmail(email)) {
//       _emailAvailable.value = true; // Dejar que el validator de campo lo maneje
//       return;
//     }

//     // Si estamos editando y el email no cambió, marcarlo como disponible
//     if (isEditMode && _currentCustomer.value?.email == email) {
//       _emailAvailable.value = true;
//       return;
//     }

//     _isValidatingEmail.value = true;
//     _emailAvailable.value = true; // Resetear estado

//     try {
//       print('🔍 Validando disponibilidad de email: $email');

//       final result = await _customerRepository.isEmailAvailable(
//         email,
//         excludeId: _currentCustomer.value?.id,
//       );

//       result.fold(
//         (failure) {
//           print('⚠️ Error al validar email: ${failure.message}');
//           _emailAvailable.value =
//               false; // En caso de error, marcar como no disponible por seguridad
//           _showError(
//             'Error de validación',
//             'No se pudo verificar la disponibilidad del email',
//           );
//         },
//         (available) {
//           print('📧 Email $email: ${available ? "DISPONIBLE" : "YA EXISTE"}');
//           _emailAvailable.value = available;

//           if (!available && !isEditMode) {
//             _showError('Email no disponible', 'Este email ya está registrado');
//           }
//         },
//       );
//     } catch (e) {
//       print('💥 Error inesperado al validar email: $e');
//       _emailAvailable.value = false;
//       _showError('Error de validación', 'Error al verificar email: $e');
//     } finally {
//       _isValidatingEmail.value = false;
//     }
//   }

//   // Future<void> validateDocumentAvailability() async {
//   //   final documentNumber = documentNumberController.text.trim();
//   //   if (documentNumber.isEmpty) return;

//   //   // Si estamos editando y el documento no cambió, no validar
//   //   if (isEditMode &&
//   //       _currentCustomer.value?.documentNumber == documentNumber &&
//   //       _currentCustomer.value?.documentType == _selectedDocumentType.value) {
//   //     _documentAvailable.value = true;
//   //     return;
//   //   }

//   //   _isValidatingDocument.value = true;

//   //   try {
//   //     final result = await _customerRepository.isDocumentAvailable(
//   //       _selectedDocumentType.value,
//   //       documentNumber,
//   //       excludeId: _currentCustomer.value?.id,
//   //     );

//   //     result.fold(
//   //       (failure) {
//   //         print('⚠️ Error al validar documento: ${failure.message}');
//   //       },
//   //       (available) {
//   //         _documentAvailable.value = available;
//   //       },
//   //     );
//   //   } finally {
//   //     _isValidatingDocument.value = false;
//   //   }
//   // }

//   Future<void> validateDocumentAvailability() async {
//     final documentNumber = documentNumberController.text.trim();

//     // Validaciones previas
//     if (documentNumber.isEmpty) {
//       _documentAvailable.value = true;
//       return;
//     }

//     if (documentNumber.length < 3) {
//       _documentAvailable.value =
//           true; // Dejar que el validator de campo lo maneje
//       return;
//     }

//     // Si estamos editando y el documento no cambió, marcarlo como disponible
//     if (isEditMode &&
//         _currentCustomer.value?.documentNumber == documentNumber &&
//         _currentCustomer.value?.documentType == _selectedDocumentType.value) {
//       _documentAvailable.value = true;
//       return;
//     }

//     _isValidatingDocument.value = true;
//     _documentAvailable.value = true; // Resetear estado

//     try {
//       print(
//         '🔍 Validando disponibilidad de documento: ${_selectedDocumentType.value.name}:$documentNumber',
//       );

//       final result = await _customerRepository.isDocumentAvailable(
//         _selectedDocumentType.value,
//         documentNumber,
//         excludeId: _currentCustomer.value?.id,
//       );

//       result.fold(
//         (failure) {
//           print('⚠️ Error al validar documento: ${failure.message}');
//           _documentAvailable.value =
//               false; // En caso de error, marcar como no disponible por seguridad
//           _showError(
//             'Error de validación',
//             'No se pudo verificar la disponibilidad del documento',
//           );
//         },
//         (available) {
//           print(
//             '📄 Documento ${_selectedDocumentType.value.name}:$documentNumber: ${available ? "DISPONIBLE" : "YA EXISTE"}',
//           );
//           _documentAvailable.value = available;

//           if (!available && !isEditMode) {
//             _showError(
//               'Documento no disponible',
//               'Este documento ya está registrado',
//             );
//           }
//         },
//       );
//     } catch (e) {
//       print('💥 Error inesperado al validar documento: $e');
//       _documentAvailable.value = false;
//       _showError('Error de validación', 'Error al verificar documento: $e');
//     } finally {
//       _isValidatingDocument.value = false;
//     }
//   }

//   // ==================== HELPERS ====================
//   String? _getOptionalText(TextEditingController controller) {
//     final text = controller.text.trim();
//     return text.isEmpty ? null : text;
//   }

//   double? _parseDouble(String text) {
//     final trimmed = text.trim();
//     if (trimmed.isEmpty) return null;
//     return double.tryParse(trimmed);
//   }

//   int? _parseInt(String text) {
//     final trimmed = text.trim();
//     if (trimmed.isEmpty) return null;
//     return int.tryParse(trimmed);
//   }

//   void cancel() {
//     Get.back();
//   }

//   /// Poblar formulario con datos del cliente
//   void _populateForm(Customer customer) {
//     print(
//       '📝 CustomerFormController: Poblando formulario con datos del cliente...',
//     );

//     firstNameController.text = customer.firstName;
//     lastNameController.text = customer.lastName;
//     companyNameController.text = customer.companyName ?? '';
//     emailController.text = customer.email;
//     phoneController.text = customer.phone ?? '';
//     mobileController.text = customer.mobile ?? '';
//     documentNumberController.text = customer.documentNumber;
//     addressController.text = customer.address ?? '';
//     cityController.text = customer.city ?? '';
//     stateController.text = customer.state ?? '';
//     zipCodeController.text = customer.zipCode ?? '';
//     creditLimitController.text = customer.creditLimit.toString();
//     paymentTermsController.text = customer.paymentTerms.toString();
//     notesController.text = customer.notes ?? '';

//     _selectedStatus.value = customer.status;
//     _selectedDocumentType.value = customer.documentType;
//     _birthDate.value = customer.birthDate;

//     print('✅ CustomerFormController: Formulario poblado exitosamente');
//   }

//   void _disposeControllers() {
//     firstNameController.dispose();
//     lastNameController.dispose();
//     companyNameController.dispose();
//     emailController.dispose();
//     phoneController.dispose();
//     mobileController.dispose();
//     documentNumberController.dispose();
//     addressController.dispose();
//     cityController.dispose();
//     stateController.dispose();
//     zipCodeController.dispose();
//     creditLimitController.dispose();
//     paymentTermsController.dispose();
//     notesController.dispose();
//   }

//   void _showError(String title, String message) {
//     Get.snackbar(
//       title,
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.red.shade100,
//       colorText: Colors.red.shade800,
//       icon: const Icon(Icons.error, color: Colors.red),
//       duration: const Duration(seconds: 4),
//     );
//   }

//   void _showSuccess(String message) {
//     Get.snackbar(
//       'Éxito',
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.green.shade100,
//       colorText: Colors.green.shade800,
//       icon: const Icon(Icons.check_circle, color: Colors.green),
//       duration: const Duration(seconds: 3),
//     );
//   }
// }

// lib/features/customers/presentation/controllers/customer_form_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import '../../domain/usecases/get_customer_by_id_usecase.dart';

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
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final companyNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final mobileController = TextEditingController();
  final documentNumberController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipCodeController = TextEditingController();
  final creditLimitController = TextEditingController();
  final paymentTermsController = TextEditingController();
  final notesController = TextEditingController();

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
  String get submitButtonText => isEditMode ? 'Actualizar' : 'Crear Cliente';

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
    _emailValidationTimer?.cancel();
    _documentValidationTimer?.cancel();
    _disposeControllers();
    super.onClose();
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

    if (!await _validateFormAsync()) {
      print('❌ CustomerFormController: Validación de formulario falló');
      return;
    }

    _isSaving.value = true;

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

    // 1. Validar campos básicos del formulario
    if (!formKey.currentState!.validate()) {
      _showError(
        'Formulario inválido',
        'Por favor corrige los errores en los campos',
      );
      return false;
    }

    // 2. Verificar que no haya validaciones en progreso
    if (_isValidatingEmail.value || _isValidatingDocument.value) {
      _showError(
        'Validación en progreso',
        'Espera a que terminen las validaciones',
      );
      return false;
    }

    // 3. Forzar validación de email si es necesario
    final email = emailController.text.trim();
    if (email.isNotEmpty && GetUtils.isEmail(email)) {
      if (!_emailValidatedOnce.value ||
          (isEditMode && _currentCustomer.value?.email != email) ||
          !isEditMode) {
        print('📧 Validando email antes de guardar...');
        await validateEmailAvailability();
      }
    }

    // 4. Forzar validación de documento si es necesario
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
      }
    }

    // 5. Verificar resultados de validaciones asíncronas
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
        print(
          '❌ CustomerFormController: Error al crear cliente - ${failure.message}',
        );
        _showError('Error al crear cliente', failure.message);
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
        print(
          '❌ CustomerFormController: Error al actualizar cliente - ${failure.message}',
        );
        _showError('Error al actualizar cliente', failure.message);
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

    // Si está vacío, resetear estado
    if (value.trim().isEmpty) {
      _emailAvailable.value = true;
      _emailValidatedOnce.value = false;
      return;
    }

    // Solo validar si es un email válido y después de un delay de 1.5 segundos
    if (GetUtils.isEmail(value.trim())) {
      _emailValidationTimer = Timer(const Duration(milliseconds: 1500), () {
        validateEmailAvailability();
      });
    }
  }

  void onDocumentNumberChanged(String value) {
    _documentValidationTimer?.cancel();

    // Si está vacío, resetear estado
    if (value.trim().isEmpty) {
      _documentAvailable.value = true;
      _documentValidatedOnce.value = false;
      return;
    }

    // Solo validar si tiene suficiente longitud y después de un delay de 1.5 segundos
    if (value.trim().length >= 3) {
      _documentValidationTimer = Timer(const Duration(milliseconds: 1500), () {
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
    firstNameController.dispose();
    lastNameController.dispose();
    companyNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    mobileController.dispose();
    documentNumberController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipCodeController.dispose();
    creditLimitController.dispose();
    paymentTermsController.dispose();
    notesController.dispose();
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
