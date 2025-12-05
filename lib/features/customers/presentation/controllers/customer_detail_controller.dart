// lib/features/customers/presentation/controllers/customer_detail_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/safe_text_editing_controller.dart';
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
      Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: isMobile ? 24 : 40,
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header compacto
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.errorGradient,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMobile ? 16 : 20),
                        topRight: Radius.circular(isMobile ? 16 : 20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.delete_forever,
                            size: isMobile ? 24 : 28,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: isMobile ? 12 : 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Eliminar Cliente',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Acción irreversible',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content compacto
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 14),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red.shade600,
                                size: isMobile ? 20 : 22,
                              ),
                              SizedBox(width: isMobile ? 10 : 12),
                              Expanded(
                                child: Text(
                                  'Esta acción no se puede deshacer',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        Text(
                          '¿Eliminar "${_customer.value!.displayName}"?',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 15,
                            color: ElegantLightTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogButton(
                                label: 'Cancelar',
                                icon: Icons.close,
                                onTap: () => Get.back(),
                                isOutline: true,
                                isCompact: isMobile,
                              ),
                            ),
                            SizedBox(width: isMobile ? 10 : 12),
                            Expanded(
                              child: _buildDialogButton(
                                label: 'Eliminar',
                                icon: Icons.delete,
                                gradient: ElegantLightTheme.errorGradient,
                                onTap: () {
                                  Get.back();
                                  deleteCustomer();
                                },
                                isCompact: isMobile,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void showStatusChangeDialog() {
    if (_customer.value == null) return;

    Get.dialog(
      Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: isMobile ? 24 : 40,
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header compacto
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMobile ? 16 : 20),
                        topRight: Radius.circular(isMobile ? 16 : 20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.swap_horiz,
                            size: isMobile ? 24 : 28,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: isMobile ? 12 : 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cambiar Estado',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Actual: ${_getStatusDisplayName(_customer.value!.status)}',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Options
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: Column(
                      children: [
                        ...CustomerStatus.values.map((status) {
                          final isSelected = status == _customer.value!.status;
                          return Padding(
                            padding: EdgeInsets.only(bottom: isMobile ? 8 : 10),
                            child: _buildStatusOption(
                              status: status,
                              isSelected: isSelected,
                              isCompact: isMobile,
                              onTap: isSelected
                                  ? null
                                  : () {
                                      Get.back();
                                      updateCustomerStatus(status);
                                    },
                            ),
                          );
                        }),
                        SizedBox(height: isMobile ? 8 : 10),
                        SizedBox(
                          width: double.infinity,
                          child: _buildDialogButton(
                            label: 'Cancelar',
                            icon: Icons.close,
                            onTap: () => Get.back(),
                            isOutline: true,
                            isCompact: isMobile,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusOption({
    required CustomerStatus status,
    required bool isSelected,
    required VoidCallback? onTap,
    bool isCompact = false,
  }) {
    final color = _getStatusColor(status);
    final gradient = _getStatusGradient(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? gradient.scale(0.2)
                : LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.05),
                      color.withValues(alpha: 0.02),
                    ],
                  ),
            borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? gradient : null,
                  color: isSelected ? null : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  size: isCompact ? 18 : 20,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              SizedBox(width: isCompact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusDisplayName(status),
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : ElegantLightTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _getStatusDescription(status),
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: EdgeInsets.all(isCompact ? 4 : 6),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
                  ),
                  child: Icon(
                    Icons.check,
                    size: isCompact ? 14 : 16,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: isCompact ? 12 : 14,
                  color: color.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void showPurchaseCheckDialog() {
    final amountController = SafeTextEditingController(debugLabel: 'PurchaseCheckAmount');
    final customer = _customer.value!;
    final availableCredit = customer.creditLimit - customer.currentBalance;

    Get.dialog(
      Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: isMobile ? 24 : 40,
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header compacto
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.successGradient,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isMobile ? 16 : 20),
                          topRight: Radius.circular(isMobile ? 16 : 20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.credit_card,
                              size: isMobile ? 24 : 28,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: isMobile ? 12 : 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verificar Compra',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  customer.displayName,
                                  style: TextStyle(
                                    fontSize: isMobile ? 11 : 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content compacto
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Credit Info Card compacto
                          Container(
                            padding: EdgeInsets.all(isMobile ? 12 : 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
                                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.03),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                                  decoration: BoxDecoration(
                                    gradient: ElegantLightTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    size: isMobile ? 18 : 20,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 10 : 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Crédito Disponible',
                                        style: TextStyle(
                                          fontSize: isMobile ? 11 : 12,
                                          color: ElegantLightTheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        AppFormatters.formatCurrency(availableCredit),
                                        style: TextStyle(
                                          fontSize: isMobile ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: availableCredit > 0
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isMobile ? 14 : 20),

                          // Amount Input
                          Text(
                            'Monto de la Compra',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: ElegantLightTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          Container(
                            decoration: BoxDecoration(
                              color: ElegantLightTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: TextField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: ElegantLightTheme.textTertiary,
                                ),
                                prefixIcon: Container(
                                  margin: EdgeInsets.all(isMobile ? 6 : 8),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 10 : 12,
                                    vertical: isMobile ? 6 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: ElegantLightTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '\$',
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 12 : 16,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 16 : 24),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildDialogButton(
                                  label: 'Cancelar',
                                  icon: Icons.close,
                                  onTap: () => Get.back(),
                                  isOutline: true,
                                  isCompact: isMobile,
                                ),
                              ),
                              SizedBox(width: isMobile ? 10 : 12),
                              Expanded(
                                child: _buildDialogButton(
                                  label: 'Verificar',
                                  icon: Icons.check_circle,
                                  gradient: ElegantLightTheme.successGradient,
                                  onTap: () {
                                    final amount = double.tryParse(
                                      amountController.text.replaceAll(',', '.'),
                                    );
                                    if (amount != null && amount > 0) {
                                      Get.back();
                                      checkPurchaseCapability(amount);
                                    } else {
                                      _showError('Error', 'Ingresa un monto válido');
                                    }
                                  },
                                  isCompact: isMobile,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPurchaseCapabilityDialog(Map<String, dynamic> info) {
    final canPurchase = info['canPurchase'] as bool? ?? false;
    final reason = info['reason'] as String?;
    final availableCredit = info['availableCredit'] as double? ?? 0.0;
    final gradient = canPurchase ? ElegantLightTheme.successGradient : ElegantLightTheme.errorGradient;
    final color = canPurchase ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    Get.dialog(
      Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: isMobile ? 24 : 40,
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header compacto
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMobile ? 16 : 20),
                        topRight: Radius.circular(isMobile ? 16 : 20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                          ),
                          child: Icon(
                            canPurchase ? Icons.check_circle : Icons.cancel,
                            size: isMobile ? 28 : 36,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: isMobile ? 12 : 16),
                        Expanded(
                          child: Text(
                            canPurchase ? 'Compra Aprobada' : 'Compra Denegada',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content compacto
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: Column(
                      children: [
                        // Result Message
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 12 : 14),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: color.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                canPurchase ? Icons.thumb_up : Icons.warning_amber_rounded,
                                color: color,
                                size: isMobile ? 20 : 22,
                              ),
                              SizedBox(width: isMobile ? 10 : 12),
                              Expanded(
                                child: Text(
                                  canPurchase
                                      ? 'El cliente puede realizar esta compra'
                                      : reason ?? 'No se puede realizar la compra',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),

                        // Available Credit
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 12 : 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
                                ElegantLightTheme.primaryBlue.withValues(alpha: 0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                                    decoration: BoxDecoration(
                                      gradient: ElegantLightTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet,
                                      size: isMobile ? 14 : 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: isMobile ? 8 : 10),
                                  Text(
                                    'Crédito Disponible',
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 13,
                                      color: ElegantLightTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                AppFormatters.formatCurrency(availableCredit),
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: availableCredit > 0
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        // Close Button
                        SizedBox(
                          width: double.infinity,
                          child: _buildDialogButton(
                            label: 'Cerrar',
                            icon: Icons.close,
                            gradient: gradient,
                            onTap: () => Get.back(),
                            isCompact: isMobile,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== DIALOG WIDGETS ====================

  Widget _buildDialogButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    LinearGradient? gradient,
    bool isOutline = false,
    bool isCompact = false,
  }) {
    final buttonGradient = gradient ?? ElegantLightTheme.primaryGradient;
    final primaryColor = buttonGradient.colors.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 10 : 14,
            horizontal: isCompact ? 14 : 20,
          ),
          decoration: BoxDecoration(
            gradient: isOutline ? null : buttonGradient,
            color: isOutline ? Colors.transparent : null,
            borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
            border: isOutline
                ? Border.all(
                    color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : null,
            boxShadow: isOutline
                ? null
                : [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: isCompact ? 6 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isCompact ? 16 : 18,
                color: isOutline ? ElegantLightTheme.textSecondary : Colors.white,
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: isOutline ? ElegantLightTheme.textPrimary : Colors.white,
                ),
              ),
            ],
          ),
        ),
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

  String _getStatusDescription(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'Cliente habilitado para compras';
      case CustomerStatus.inactive:
        return 'Cliente temporalmente inactivo';
      case CustomerStatus.suspended:
        return 'Cliente suspendido - Sin compras';
    }
  }

  IconData _getStatusIcon(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return Icons.check_circle;
      case CustomerStatus.inactive:
        return Icons.pause_circle;
      case CustomerStatus.suspended:
        return Icons.block;
    }
  }

  Color _getStatusColor(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return const Color(0xFF10B981);
      case CustomerStatus.inactive:
        return const Color(0xFFF59E0B);
      case CustomerStatus.suspended:
        return const Color(0xFFEF4444);
    }
  }

  LinearGradient _getStatusGradient(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return ElegantLightTheme.successGradient;
      case CustomerStatus.inactive:
        return ElegantLightTheme.warningGradient;
      case CustomerStatus.suspended:
        return ElegantLightTheme.errorGradient;
    }
  }

  Color getStatusColor(CustomerStatus status) {
    return _getStatusColor(status);
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
