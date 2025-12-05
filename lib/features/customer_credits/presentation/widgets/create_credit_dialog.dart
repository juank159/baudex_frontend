// lib/features/customer_credits/presentation/widgets/create_credit_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../../../customers/data/datasources/customer_remote_datasource.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../domain/entities/customer_credit.dart';
import '../../data/models/customer_credit_model.dart';
import '../controllers/customer_credit_controller.dart';

/// Diálogo para crear un crédito manual con estilo Elegant
class CreateCreditDialog extends StatefulWidget {
  final String? preselectedCustomerId;

  const CreateCreditDialog({
    super.key,
    this.preselectedCustomerId,
  });

  @override
  State<CreateCreditDialog> createState() => _CreateCreditDialogState();
}

class _CreateCreditDialogState extends State<CreateCreditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _customerSearchController = TextEditingController();

  Customer? _selectedCustomer;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  bool _isSearching = false;
  List<Customer> _searchResults = [];

  // Saldo a favor del cliente (se aplica AUTOMÁTICAMENTE por defecto)
  double _clientBalance = 0.0;
  bool _skipAutoBalance = false; // Por defecto NO omitir, es decir, SÍ aplicar automáticamente
  bool _loadingBalance = false;

  // Verificación de crédito pendiente
  bool _hasPendingCredit = false;
  CustomerCredit? _pendingCredit; // Crédito pendiente existente
  bool _checkingPendingCredit = false;

  // Decoración elegante para inputs
  InputDecoration _elegantInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: ElegantLightTheme.primaryBlue, size: 20)
          : null,
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(
        color: ElegantLightTheme.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: ElegantLightTheme.textTertiary.withValues(alpha: 0.7),
        fontSize: 14,
      ),
      filled: true,
      fillColor: ElegantLightTheme.surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: ElegantLightTheme.primaryBlue,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 2,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.preselectedCustomerId != null) {
      _loadPreselectedCustomer();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPreselectedCustomer() async {
    // TODO: Cargar cliente preseleccionado
  }

  Future<void> _loadClientBalance(String customerId) async {
    setState(() {
      _loadingBalance = true;
      _clientBalance = 0.0;
      _skipAutoBalance = false; // Por defecto aplicar automáticamente
      _checkingPendingCredit = true;
      _hasPendingCredit = false;
      _pendingCredit = null;
    });

    try {
      final dioClient = Get.find<DioClient>();

      // Cargar saldo a favor y crédito pendiente en paralelo
      final results = await Future.wait([
        // Consultar saldo a favor vía API directa
        dioClient.get('/client-balance/customer/$customerId/available'),
        // Consultar crédito pendiente vía API directa
        dioClient.get('/customer-credits/customer/$customerId/pending-direct'),
      ]);

      // Procesar saldo a favor
      double balance = 0.0;
      final balanceResponse = results[0];
      if (balanceResponse.statusCode == 200 && balanceResponse.data != null) {
        final responseData = balanceResponse.data as Map<String, dynamic>;
        // La respuesta viene envuelta en {success, data, timestamp}
        final innerData = responseData['data'] as Map<String, dynamic>?;
        if (innerData != null) {
          final hasBalance = innerData['hasBalance'] as bool? ?? false;
          if (hasBalance) {
            balance = (innerData['amount'] as num?)?.toDouble() ?? 0;
          }
        }
      }

      // Procesar crédito pendiente
      CustomerCredit? pendingCredit;
      final creditResponse = results[1];
      if (creditResponse.statusCode == 200 && creditResponse.data != null) {
        try {
          final creditResponseData = creditResponse.data as Map<String, dynamic>;
          // La respuesta viene envuelta en {success, data, timestamp}
          final creditInnerData = creditResponseData['data'];
          if (creditInnerData != null && creditInnerData is Map<String, dynamic>) {
            pendingCredit = CustomerCreditModel.fromJson(creditInnerData);
          }
        } catch (_) {
          pendingCredit = null;
        }
      }

      setState(() {
        _clientBalance = balance;
        _loadingBalance = false;
        _checkingPendingCredit = false;
        _hasPendingCredit = pendingCredit != null;
        _pendingCredit = pendingCredit;
      });
    } catch (e) {
      debugPrint('Error cargando saldo/crédito: $e');
      setState(() {
        _clientBalance = 0.0;
        _loadingBalance = false;
        _checkingPendingCredit = false;
        _hasPendingCredit = false;
        _pendingCredit = null;
      });
    }
  }

  Future<void> _searchCustomers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Verificar si el datasource está registrado
      if (!Get.isRegistered<CustomerRemoteDataSource>()) {
        // Registrarlo si no existe
        final dioClient = Get.find<DioClient>();
        Get.put<CustomerRemoteDataSource>(
          CustomerRemoteDataSourceImpl(dioClient: dioClient),
        );
      }

      final datasource = Get.find<CustomerRemoteDataSource>();
      final result = await datasource.searchCustomers(query, 10);
      setState(() {
        _searchResults = result;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error buscando clientes: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      // Mostrar error al usuario
      if (mounted) {
        Get.snackbar(
          'Error',
          'No se pudo buscar clientes: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SafeArea(
        child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: ElegantLightTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado elegante
                  _buildHeader(),

                  const SizedBox(height: 28),

                  // Selección de cliente
                  _buildCustomerSection(),

                  const SizedBox(height: 20),

                  // Advertencia de crédito pendiente
                  if (_selectedCustomer != null && (_checkingPendingCredit || _hasPendingCredit))
                    _buildPendingCreditWarning(),

                  // Saldo a favor del cliente
                  if (_selectedCustomer != null && !_hasPendingCredit && (_loadingBalance || _clientBalance > 0))
                    _buildClientBalanceSection(),

                  // Campos del formulario
                  _buildFormFields(),

                  const SizedBox(height: 28),

                  // Botones de acción
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    // Título dinámico según el contexto
    final title = _hasPendingCredit ? 'Agregar Monto' : 'Crear Crédito';
    final subtitle = _hasPendingCredit
        ? 'Agregar al crédito existente'
        : 'Registrar una deuda del cliente';
    final icon = _hasPendingCredit ? Icons.trending_up : Icons.credit_card_rounded;

    return Row(
      children: [
        // Icono con gradiente
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.warningGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: ElegantLightTheme.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        // Botón cerrar elegante
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ElegantLightTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close_rounded,
                color: ElegantLightTheme.textTertiary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: ElegantLightTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            const Text(
              'Cliente',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedCustomer == null)
          Column(
            children: [
              // Campo de búsqueda elegante
              TextFormField(
                controller: _customerSearchController,
                style: const TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 15,
                ),
                decoration: _elegantInputDecoration(
                  labelText: 'Buscar cliente',
                  hintText: 'Nombre o documento...',
                  prefixIcon: Icons.search_rounded,
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ElegantLightTheme.primaryBlue,
                            ),
                          ),
                        )
                      : null,
                ),
                onChanged: _searchCustomers,
                validator: (value) {
                  if (_selectedCustomer == null) {
                    return 'Seleccione un cliente';
                  }
                  return null;
                },
              ),
              // Lista de resultados elegante
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                    ),
                    boxShadow: ElegantLightTheme.elevatedShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                      ),
                      itemBuilder: (context, index) {
                        final customer = _searchResults[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCustomer = customer;
                                _searchResults = [];
                                _customerSearchController.clear();
                              });
                              _loadClientBalance(customer.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  // Avatar elegante
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      gradient: ElegantLightTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        customer.firstName.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${customer.firstName} ${customer.lastName}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: ElegantLightTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          customer.documentNumber,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: ElegantLightTheme.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: ElegantLightTheme.textTertiary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          )
        else
          // Cliente seleccionado - card elegante
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                // Avatar con gradiente
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _selectedCustomer!.firstName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedCustomer!.firstName} ${_selectedCustomer!.lastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: ElegantLightTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedCustomer!.documentNumber,
                            style: TextStyle(
                              color: ElegantLightTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botón quitar cliente
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCustomer = null;
                        _clientBalance = 0.0;
                        _skipAutoBalance = false;
                        _hasPendingCredit = false;
                        _pendingCredit = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPendingCreditWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: _checkingPendingCredit
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange,
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        color: Color(0xFFD97706),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Crédito existente encontrado',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'El monto ingresado se agregará al crédito actual',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Info del crédito actual
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo actual',
                              style: TextStyle(
                                fontSize: 11,
                                color: ElegantLightTheme.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppFormatters.formatCurrency(_pendingCredit?.balanceDue ?? 0),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 35,
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                'Total original',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ElegantLightTheme.textTertiary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                AppFormatters.formatCurrency(_pendingCredit?.originalAmount ?? 0),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ElegantLightTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildClientBalanceSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.1),
            const Color(0xFF10B981).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: _loadingBalance
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo a favor disponible',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.formatCurrency(_clientBalance),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Indicador de aplicación automática
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Se aplicará automáticamente',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF047857),
                              ),
                            ),
                            Text(
                              'El saldo se usará al crear el crédito',
                              style: TextStyle(
                                fontSize: 11,
                                color: ElegantLightTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Opción para NO aplicar automáticamente
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _skipAutoBalance = !_skipAutoBalance;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _skipAutoBalance
                                  ? ElegantLightTheme.textTertiary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _skipAutoBalance
                                    ? ElegantLightTheme.textTertiary
                                    : ElegantLightTheme.textTertiary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: _skipAutoBalance
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'No usar el saldo ahora',
                            style: TextStyle(
                              fontSize: 12,
                              color: _skipAutoBalance
                                  ? ElegantLightTheme.textSecondary
                                  : ElegantLightTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFormFields() {
    // Si hay crédito pendiente, mostrar formulario simplificado
    if (_hasPendingCredit && _pendingCredit != null) {
      return Column(
        children: [
          // Monto a agregar
          TextFormField(
            controller: _amountController,
            style: const TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: _elegantInputDecoration(
              labelText: 'Monto a agregar',
              prefixIcon: Icons.add_circle_outline,
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [PriceInputFormatter()],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese el monto a agregar';
              }
              final amount = NumberInputFormatter.getNumericValue(value) ?? 0;
              if (amount <= 0) {
                return 'El monto debe ser mayor a cero';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Descripción (qué está llevando)
          TextFormField(
            controller: _descriptionController,
            style: const TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 15,
            ),
            decoration: _elegantInputDecoration(
              labelText: '¿Qué está llevando?',
              hintText: 'Ej: Mercancía adicional',
              prefixIcon: Icons.shopping_bag_outlined,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingrese qué está llevando';
              }
              return null;
            },
          ),
        ],
      );
    }

    // Formulario completo para nuevo crédito
    return Column(
      children: [
        // Monto
        TextFormField(
          controller: _amountController,
          style: const TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: _elegantInputDecoration(
            labelText: 'Monto del crédito',
            prefixIcon: Icons.attach_money_rounded,
            prefixText: '\$ ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [PriceInputFormatter()],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese el monto del crédito';
            }
            final amount = NumberInputFormatter.getNumericValue(value) ?? 0;
            if (amount <= 0) {
              return 'El monto debe ser mayor a cero';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Fecha de vencimiento
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dueDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: ElegantLightTheme.primaryBlue,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _dueDate = date;
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _elegantInputDecoration(
              labelText: 'Fecha de vencimiento',
              prefixIcon: Icons.calendar_today_rounded,
            ),
            child: Text(
              DateFormat('dd/MM/yyyy').format(_dueDate),
              style: const TextStyle(
                fontSize: 15,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Descripción
        TextFormField(
          controller: _descriptionController,
          style: const TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 15,
          ),
          decoration: _elegantInputDecoration(
            labelText: 'Descripción',
            hintText: 'Ej: Crédito por mercancía',
            prefixIcon: Icons.description_outlined,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese una descripción';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Notas
        TextFormField(
          controller: _notesController,
          style: const TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 15,
          ),
          decoration: _elegantInputDecoration(
            labelText: 'Notas (opcional)',
            prefixIcon: Icons.note_alt_outlined,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    // Determinar el texto y acción del botón según el contexto
    final buttonText = _hasPendingCredit ? 'Agregar Monto' : 'Crear Crédito';
    final buttonIcon = _hasPendingCredit ? Icons.add_rounded : Icons.add_circle_outline_rounded;

    return Row(
      children: [
        // Botón cancelar
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Botón crear/agregar crédito
        Expanded(
          flex: 2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _submitCredit,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              buttonIcon,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              buttonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _submitCredit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      Get.snackbar('Error', 'Seleccione un cliente', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final amount = NumberInputFormatter.getNumericValue(_amountController.text) ?? 0;
    final controller = Get.find<CustomerCreditController>();

    // Cerrar diálogo PRIMERO
    Get.back(result: true);

    // Ejecutar operación en segundo plano
    if (_hasPendingCredit && _pendingCredit != null) {
      controller.addAmountToCredit(
        creditId: _pendingCredit!.id,
        amount: amount,
        description: _descriptionController.text,
      );
    } else {
      controller.createCredit(
        customerId: _selectedCustomer!.id,
        amount: amount,
        dueDate: _dueDate.toIso8601String(),
        description: _descriptionController.text,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        skipAutoBalance: _skipAutoBalance,
      );
    }
  }
}
