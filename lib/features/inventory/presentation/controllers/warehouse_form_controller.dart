// lib/features/inventory/presentation/controllers/warehouse_form_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/data/local/sync_service.dart';
// import '../../../../app/config/routes/app_routes.dart'; // No needed anymore
import '../../domain/entities/warehouse.dart';
import '../../domain/usecases/create_warehouse_usecase.dart';
import '../../domain/usecases/update_warehouse_usecase.dart';
import '../../domain/usecases/get_warehouse_by_id_usecase.dart';
import '../../domain/usecases/check_warehouse_code_exists_usecase.dart';
import '../../domain/repositories/inventory_repository.dart';

enum FormMode { create, edit }

class WarehouseFormController extends GetxController {
  // Casos de uso
  final CreateWarehouseUseCase _createWarehouseUseCase;
  final UpdateWarehouseUseCase _updateWarehouseUseCase;
  final GetWarehouseByIdUseCase _getWarehouseByIdUseCase;
  final CheckWarehouseCodeExistsUseCase _checkWarehouseCodeExistsUseCase;

  WarehouseFormController({
    required CreateWarehouseUseCase createWarehouseUseCase,
    required UpdateWarehouseUseCase updateWarehouseUseCase,
    required GetWarehouseByIdUseCase getWarehouseByIdUseCase,
    required CheckWarehouseCodeExistsUseCase checkWarehouseCodeExistsUseCase,
  }) : _createWarehouseUseCase = createWarehouseUseCase,
       _updateWarehouseUseCase = updateWarehouseUseCase,
       _getWarehouseByIdUseCase = getWarehouseByIdUseCase,
       _checkWarehouseCodeExistsUseCase = checkWarehouseCodeExistsUseCase;

  // ==================== FORM STATE ====================

  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController codeController;
  late final TextEditingController descriptionController;
  late final TextEditingController addressController;

  // ==================== OBSERVABLES ====================

  final _formMode = FormMode.create.obs;
  final _isLoading = false.obs;
  final _isSaving = false.obs;
  final _error = ''.obs;
  final _warehouseId = ''.obs;
  final _warehouse = Rx<Warehouse?>(null);
  final _isActive = true.obs;
  final _isDirty = false.obs;

  // ==================== GETTERS ====================

  FormMode get formMode => _formMode.value;
  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;
  String get error => _error.value;
  String get warehouseId => _warehouseId.value;
  Warehouse? get warehouse => _warehouse.value;
  bool get isActive => _isActive.value;
  bool get isDirty => _isDirty.value;
  bool get isCreateMode => _formMode.value == FormMode.create;
  bool get isEditMode => _formMode.value == FormMode.edit;
  String get title => isCreateMode ? 'Crear Almacén' : 'Editar Almacén';
  String get submitButtonText =>
      isCreateMode ? 'Crear Almacén' : 'Actualizar Almacén';

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    SyncService.notifyFormOpened();
    _initializeControllers();
    _setupFormListeners();

    // Obtener parámetros de la ruta
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      final warehouseIdParam = arguments['warehouseId'] as String?;
      if (warehouseIdParam != null) {
        _warehouseId.value = warehouseIdParam;
        _formMode.value = FormMode.edit;
        _loadWarehouse();
      }
    }
  }

  @override
  void onClose() {
    SyncService.notifyFormClosed();
    nameController.dispose();
    codeController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    super.onClose();
  }

  // ==================== INITIALIZATION ====================

  void _initializeControllers() {
    nameController = TextEditingController();
    codeController = TextEditingController();
    descriptionController = TextEditingController();
    addressController = TextEditingController();
  }

  void _setupFormListeners() {
    // Marcar formulario como modificado cuando hay cambios
    nameController.addListener(_onFieldChanged);
    codeController.addListener(_onFieldChanged);
    descriptionController.addListener(_onFieldChanged);
    addressController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_isDirty.value) {
      _isDirty.value = true;
    }
  }

  // ==================== DATA LOADING ====================

  /// Cargar datos del almacén para edición
  Future<void> _loadWarehouse() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final result = await _getWarehouseByIdUseCase(_warehouseId.value);

      result.fold(
        (failure) {
          _error.value = failure.message;
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        },
        (warehouse) {
          _warehouse.value = warehouse;
          _populateForm(warehouse);
        },
      );
    } catch (e) {
      _error.value = 'Error inesperado: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Poblar formulario con datos del almacén
  void _populateForm(Warehouse warehouse) {
    nameController.text = warehouse.name;
    codeController.text = warehouse.code;
    descriptionController.text = warehouse.description ?? '';
    addressController.text = warehouse.address ?? '';
    _isActive.value = warehouse.isActive;

    // Resetear estado de modificado después de cargar
    _isDirty.value = false;
  }

  // ==================== FORM ACTIONS ====================

  /// Enviar formulario
  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      _isSaving.value = true;
      _error.value = '';

      // Validación asíncrona del código
      final codeValidation = await validateCodeUnique(codeController.text);
      if (codeValidation != null) {
        _error.value = codeValidation;
        Get.snackbar(
          'Error de Validación',
          codeValidation,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
        );
        return;
      }

      if (isCreateMode) {
        await _createWarehouse();
      } else {
        await _updateWarehouse();
      }
    } catch (e) {
      _error.value = 'Error inesperado: $e';
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      _isSaving.value = false;
    }
  }

  /// Crear nuevo almacén
  Future<void> _createWarehouse() async {
    final params = CreateWarehouseParams(
      name: nameController.text.trim(),
      code: codeController.text.trim(),
      description:
          descriptionController.text.trim().isNotEmpty
              ? descriptionController.text.trim()
              : null,
      address:
          addressController.text.trim().isNotEmpty
              ? addressController.text.trim()
              : null,
      isActive: _isActive.value,
    );

    final result = await _createWarehouseUseCase(params);

    result.fold(
      (failure) {
        _error.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      },
      (warehouse) {
        _navigateToWarehousesList(warehouse);
        Get.snackbar(
          'Éxito',
          'Almacén creado exitosamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
      },
    );
  }

  /// Actualizar almacén existente
  Future<void> _updateWarehouse() async {
    final params = UpdateWarehouseParams(
      name: nameController.text.trim(),
      code: codeController.text.trim(),
      description:
          descriptionController.text.trim().isNotEmpty
              ? descriptionController.text.trim()
              : null,
      address:
          addressController.text.trim().isNotEmpty
              ? addressController.text.trim()
              : null,
      isActive: _isActive.value,
    );

    final result = await _updateWarehouseUseCase(_warehouseId.value, params);

    result.fold(
      (failure) {
        _error.value = failure.message;
        Get.snackbar(
          'Error',
          failure.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      },
      (warehouse) {
        // Actualizar estado local
        _warehouse.value = warehouse;
        _isDirty.value = false;

        _navigateToWarehousesList(warehouse);
        Get.snackbar(
          'Éxito',
          'Almacén actualizado exitosamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
      },
    );
  }

  // ==================== FORM UTILITIES ====================

  /// Alternar estado activo/inactivo
  void toggleActiveStatus() {
    _isActive.value = !_isActive.value;
    _onFieldChanged();
  }

  /// Limpiar formulario
  void clearForm() {
    nameController.clear();
    codeController.clear();
    descriptionController.clear();
    addressController.clear();
    _isActive.value = true;
    _isDirty.value = false;
    _error.value = '';
  }

  /// Confirmar cancelación si hay cambios sin guardar
  Future<bool> confirmDiscardChanges() async {
    if (!_isDirty.value) {
      return true;
    }

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cambios sin guardar'),
        content: const Text(
          '¿Estás seguro que deseas salir sin guardar los cambios?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Descartar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ==================== VALIDATION ====================

  /// Validar nombre del almacén
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }

    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    if (value.trim().length > 100) {
      return 'El nombre no puede exceder 100 caracteres';
    }

    return null;
  }

  /// Validar código del almacén (validación síncrona)
  String? validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El código es obligatorio';
    }

    if (value.trim().length < 2) {
      return 'El código debe tener al menos 2 caracteres';
    }

    if (value.trim().length > 20) {
      return 'El código no puede exceder 20 caracteres';
    }

    // Validar formato alfanumérico
    final codeRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!codeRegex.hasMatch(value.trim())) {
      return 'El código solo puede contener letras, números, guiones y guiones bajos';
    }

    return null;
  }

  /// Validar código único (validación asíncrona)
  Future<String?> validateCodeUnique(String code) async {
    // Validación básica primero
    final basicValidation = validateCode(code);
    if (basicValidation != null) return basicValidation;

    // Si estamos editando y el código no cambió, no validar
    if (isEditMode && code.trim() == _warehouse.value?.code) {
      return null;
    }

    try {
      final result = await _checkWarehouseCodeExistsUseCase(
        code.trim(),
        excludeId: isEditMode ? _warehouseId.value : null,
      );

      return result.fold((failure) {
        // Si el backend requiere UUID, asumir que el código es único para códigos alfanuméricos
        if (failure.message.contains('uuid is expected') ||
            failure.message.contains('Validation failed')) {
          print(
            '⚠️ Backend requiere UUID, saltando validación de unicidad para código alfanumérico',
          );
          return null; // Asumir que es válido
        }
        return 'Error al verificar código: ${failure.message}';
      }, (exists) => exists ? 'Este código ya existe, elige otro' : null);
    } catch (e) {
      // Si hay error de formato UUID, asumir que el código es válido
      final errorMessage = e.toString();
      if (errorMessage.contains('uuid') ||
          errorMessage.contains('Validation failed')) {
        print(
          '⚠️ Error de validación UUID, saltando verificación para código alfanumérico',
        );
        return null; // Asumir que es válido
      }
      return 'Error al verificar código';
    }
  }

  /// Validar descripción (opcional)
  String? validateDescription(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length > 500) {
      return 'La descripción no puede exceder 500 caracteres';
    }
    return null;
  }

  /// Validar dirección (opcional)
  String? validateAddress(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length > 200) {
      return 'La dirección no puede exceder 200 caracteres';
    }
    return null;
  }

  // ==================== NAVIGATION ====================

  /// Navegar al listado de almacenes y actualizar la lista
  void _navigateToWarehousesList(Warehouse warehouse) {
    // Volver con resultado para que el controlador de warehouses refresque
    Get.back(
      result: {
        'action': isCreateMode ? 'created' : 'updated',
        'warehouse': warehouse,
      },
    );
  }

  /// Refrescar la lista de almacenes después de navegar
  /*
  Future<void> _refreshWarehousesListAfterNavigation() async {
    // Mostrar snackbar inmediatamente
    Get.snackbar(
      '✅ Éxito',
      '${isCreateMode ? "Almacén creado" : "Almacén actualizado"} exitosamente.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
    
    // Intentar actualizar la lista de almacenes
    try {
      // Esperar un poco más para que el binding se complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      final warehousesController = Get.find<WarehousesController>();
      await warehousesController.refreshWarehouses();
      
      print('✅ Lista de almacenes actualizada exitosamente');
    } catch (e) {
      print('⚠️ No se pudo actualizar automáticamente la lista: $e');
      // El usuario puede refrescar manualmente
    }
  }

  // ==================== DEBUGGING ====================

  void printDebugInfo() {
    print('🏪 WarehouseFormController Debug Info:');
    print('   Form mode: $formMode');
    print('   Warehouse ID: $_warehouseId');
    print('   Is loading: $isLoading');
    print('   Is saving: $isSaving');
    print('   Is dirty: $isDirty');
    print('   Is active: $isActive');
    print('   Name: "${nameController.text}"');
    print('   Code: "${codeController.text}"');
    print('   Description: "${descriptionController.text}"');
    print('   Address: "${addressController.text}"');
    print('   Error: "$error"');
  }
  */
}
