// lib/features/customers/presentation/controllers/customer_detail_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/get_customer_by_id_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import '../../domain/usecases/delete_customer_usecase.dart';

class CustomerDetailController extends GetxController {
  // Dependencies
  final GetCustomerByIdUseCase _getCustomerByIdUseCase;
  final UpdateCustomerUseCase _updateCustomerUseCase;
  final DeleteCustomerUseCase _deleteCustomerUseCase;
  final CustomerRepository _customerRepository;

  CustomerDetailController({
    required GetCustomerByIdUseCase getCustomerByIdUseCase,
    required UpdateCustomerUseCase updateCustomerUseCase,
    required DeleteCustomerUseCase deleteCustomerUseCase,
    required CustomerRepository customerRepository,
  }) : _getCustomerByIdUseCase = getCustomerByIdUseCase,
       _updateCustomerUseCase = updateCustomerUseCase,
       _deleteCustomerUseCase = deleteCustomerUseCase,
       _customerRepository = customerRepository;

  // ==================== OBSERVABLES ====================
  final _isLoading = false.obs;
  final _isUpdatingStatus = false.obs;
  final _isDeleting = false.obs;
  final _isLoadingFinancialSummary = false.obs;
  final _customer = Rxn<Customer>();
  final _financialSummary = Rxn<Map<String, dynamic>>();
  final _canPurchaseInfo = Rxn<Map<String, dynamic>>();

  // ==================== GETTERS ====================
  bool get isLoading => _isLoading.value;
  bool get isUpdatingStatus => _isUpdatingStatus.value;
  bool get isDeleting => _isDeleting.value;
  bool get isLoadingFinancialSummary => _isLoadingFinancialSummary.value;
  Customer? get customer => _customer.value;
  Map<String, dynamic>? get financialSummary => _financialSummary.value;
  Map<String, dynamic>? get canPurchaseInfo => _canPurchaseInfo.value;

  bool get hasCustomer => _customer.value != null;
  String get customerId => Get.parameters['id'] ?? '';

  // ==================== LIFECYCLE ====================
  @override
  void onInit() {
    super.onInit();
    _loadCustomerData();
  }

  // ==================== DATA LOADING ====================
  Future<void> _loadCustomerData() async {
    if (customerId.isEmpty) {
      _showError('Error', 'ID de cliente no válido');
      Get.back();
      return;
    }

    await loadCustomer();
  }

  Future<void> loadCustomer() async {
    _isLoading.value = true;

    try {
      print('📥 Cargando detalles del cliente: $customerId');

      final result = await _getCustomerByIdUseCase(
        GetCustomerByIdParams(id: customerId),
      );

      result.fold(
        (failure) {
          _showError('Error al cargar cliente', failure.message);
          Get.back();
        },
        (customer) {
          _customer.value = customer;
          print('✅ Cliente cargado: ${customer.displayName}');

          // Cargar información financiera adicional en segundo plano
          _loadFinancialSummary();
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadFinancialSummary() async {
    if (_customer.value == null) return;

    _isLoadingFinancialSummary.value = true;

    try {
      print('💰 Cargando resumen financiero...');

      final result = await _customerRepository.getCustomerFinancialSummary(
        _customer.value!.id,
      );

      result.fold(
        (failure) {
          print('⚠️ Error al cargar resumen financiero: ${failure.message}');
        },
        (summary) {
          _financialSummary.value = summary;
          print('✅ Resumen financiero cargado');
        },
      );
    } finally {
      _isLoadingFinancialSummary.value = false;
    }
  }

  Future<void> refreshCustomer() async {
    await loadCustomer();
  }

  // ==================== CUSTOMER ACTIONS ====================
  Future<void> updateCustomerStatus(CustomerStatus newStatus) async {
    if (_customer.value == null) return;

    _isUpdatingStatus.value = true;

    try {
      print('🔄 Actualizando estado del cliente a: ${newStatus.name}');

      final result = await _updateCustomerUseCase(
        UpdateCustomerParams(id: _customer.value!.id, status: newStatus),
      );

      result.fold(
        (failure) {
          _showError('Error al actualizar estado', failure.message);
        },
        (updatedCustomer) {
          _customer.value = updatedCustomer;
          _showSuccess('Estado actualizado exitosamente');
          print('✅ Estado actualizado a: ${newStatus.name}');
        },
      );
    } finally {
      _isUpdatingStatus.value = false;
    }
  }

  Future<void> deleteCustomer() async {
    if (_customer.value == null) return;

    _isDeleting.value = true;

    try {
      print('🗑️ Eliminando cliente: ${_customer.value!.id}');

      final result = await _deleteCustomerUseCase(
        DeleteCustomerParams(id: _customer.value!.id),
      );

      result.fold(
        (failure) {
          _showError('Error al eliminar cliente', failure.message);
        },
        (_) {
          _showSuccess('Cliente eliminado exitosamente');
          Get.back(result: 'deleted');
        },
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  Future<void> checkPurchaseCapability(double amount) async {
    if (_customer.value == null) return;

    try {
      print(
        '💳 Verificando capacidad de compra por: \$${amount.toStringAsFixed(2)}',
      );

      final result = await _customerRepository.canMakePurchase(
        customerId: _customer.value!.id,
        amount: amount,
      );

      result.fold(
        (failure) {
          _showError('Error al verificar compra', failure.message);
        },
        (purchaseInfo) {
          _canPurchaseInfo.value = purchaseInfo;
          _showPurchaseCapabilityDialog(purchaseInfo);
        },
      );
    } catch (e) {
      _showError('Error inesperado', 'Error al verificar capacidad de compra');
    }
  }

  // ==================== UI ACTIONS ====================
  void goToEditCustomer() {
    Get.toNamed('/customers/edit/${_customer.value!.id}')?.then((result) {
      if (result != null) {
        // Cliente fue actualizado, recargar datos
        refreshCustomer();
      }
    });
  }

  void confirmDeleteCustomer() {
    if (_customer.value == null) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text(
          '¿Estás seguro que deseas eliminar el cliente "${_customer.value!.displayName}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              deleteCustomer();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void showStatusChangeDialog() {
    if (_customer.value == null) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              CustomerStatus.values.map((status) {
                return RadioListTile<CustomerStatus>(
                  title: Text(_getStatusDisplayName(status)),
                  value: status,
                  groupValue: _customer.value!.status,
                  onChanged: (CustomerStatus? value) {
                    if (value != null && value != _customer.value!.status) {
                      Get.back();
                      updateCustomerStatus(value);
                    }
                  },
                );
              }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void showPurchaseCheckDialog() {
    final amountController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Verificar Capacidad de Compra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el monto de la compra:'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Get.back();
                checkPurchaseCapability(amount);
              } else {
                Get.snackbar(
                  'Error',
                  'Ingresa un monto válido',
                  snackPosition: SnackPosition.TOP,
                );
              }
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseCapabilityDialog(Map<String, dynamic> info) {
    final canPurchase = info['canPurchase'] as bool? ?? false;
    final reason = info['reason'] as String?;
    final availableCredit = info['availableCredit'] as double? ?? 0.0;

    Get.dialog(
      AlertDialog(
        title: Text(canPurchase ? 'Compra Aprobada' : 'Compra Denegada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canPurchase)
              const Text('✅ El cliente puede realizar esta compra.')
            else
              Text('❌ ${reason ?? "No se puede realizar la compra"}'),
            const SizedBox(height: 8),
            Text(
              'Crédito disponible: \$${availableCredit.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================
  String _getStatusDisplayName(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'Activo';
      case CustomerStatus.inactive:
        return 'Inactivo';
      case CustomerStatus.suspended:
        return 'Suspendido';
    }
  }

  Color getStatusColor(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return Colors.green;
      case CustomerStatus.inactive:
        return Colors.orange;
      case CustomerStatus.suspended:
        return Colors.red;
    }
  }

  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
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
