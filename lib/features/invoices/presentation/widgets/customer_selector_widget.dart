// lib/features/invoices/presentation/widgets/customer_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../customers/domain/entities/customer.dart';
import '../controllers/invoice_form_controller.dart';

class CustomerSelectorWidget extends StatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer) onCustomerSelected;
  final VoidCallback? onClearCustomer;
  final InvoiceFormController? controller; // ✅ NUEVO: Recibir el controlador específico

  const CustomerSelectorWidget({
    super.key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    this.onClearCustomer,
    this.controller, // ✅ NUEVO: Parámetro del controlador
  });

  @override
  State<CustomerSelectorWidget> createState() => _CustomerSelectorWidgetState();
}

class _CustomerSelectorWidgetState extends State<CustomerSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Customer> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchField = false;
  String _lastSearchTerm = '';

  // ✅ MODIFICADO: Usar el controlador del widget como prioridad
  InvoiceFormController? get _invoiceController {
    // Priorizar el controlador del widget si está disponible
    if (widget.controller != null) {
      return widget.controller;
    }
    
    // Fallback a búsqueda global como último recurso
    try {
      return Get.find<InvoiceFormController>();
    } catch (e) {
      print('⚠️ InvoiceFormController no encontrado: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    try {
      // Remover listener antes de dispose
      _searchController.removeListener(_onSearchChanged);
      
      _searchController.dispose();
      _focusNode.dispose();
    } catch (e) {
      print('⚠️ Error en dispose de CustomerSelectorWidget: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _invoiceController;
    
    // ✅ VALIDACIÓN: Si no hay controlador, mostrar error descriptivo
    if (controller == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Error de Controlador',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'No se encontró el controlador para gestionar clientes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ SOLUCIÓN: Cliente actual reactivo usando Obx con controlador específico
        Obx(() {
          // Usar el cliente del controlador específico
          final customer = controller.selectedCustomer;
          return _buildSimpleCustomerDisplay(context, customer);
        }),

        // Campo de búsqueda (solo visible cuando se activa)
        if (_showSearchField) ...[
          const SizedBox(height: 4),
          _buildSearchField(context),
        ],

        // Resultados de búsqueda
        if (_showSearchField && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 2),
          _buildSearchResults(context),
        ],

        // Mensaje cuando no hay resultados
        if (_showSearchField &&
            _searchResults.isEmpty &&
            !_isSearching &&
            _searchController.text.isNotEmpty) ...[
          const SizedBox(height: 2),
          _buildNoResultsMessage(),
        ],
      ],
    );
  }

  // ✅ NUEVO: Display simplificado del cliente
  Widget _buildSimpleCustomerDisplay(BuildContext context, Customer? customer) {
    final customerName = customer?.displayName ?? 'Consumidor Final';
    final isDefaultCustomer = customer != null && _isDefaultCustomer(customer);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isDefaultCustomer ? Colors.orange.shade300 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono del cliente
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:
                  isDefaultCustomer
                      ? Colors.orange.shade100
                      : Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isDefaultCustomer ? Icons.storefront : Icons.person,
              color:
                  isDefaultCustomer
                      ? Colors.orange.shade600
                      : Theme.of(context).primaryColor,
              size: 16,
            ),
          ),

          const SizedBox(width: 12),

          // Nombre del cliente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (isDefaultCustomer) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Venta mostrador',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Botón de búsqueda
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _toggleSearch,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _showSearchField ? Icons.close : Icons.search,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

          // Botón de limpiar (solo si no es consumidor final)
          if (customer != null &&
              !isDefaultCustomer &&
              widget.onClearCustomer != null) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  widget.onClearCustomer!();
                  _closeSearch();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Buscar cliente...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon:
              _isSearching
                  ? Container(
                    padding: const EdgeInsets.all(12),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : Icon(Icons.search, color: Colors.grey.shade500),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _focusNode.requestFocus();
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onSubmitted: (value) => _handleDirectSearch(value),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final customer = _searchResults[index];
          return _buildCustomerTile(context, customer);
        },
      ),
    );
  }

  Widget _buildCustomerTile(BuildContext context, Customer customer) {
    return Obx(() {
      final controller = _invoiceController;
      if (controller == null) return const SizedBox.shrink();
      
      final isSelected = controller.selectedCustomer?.id == customer.id;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectCustomer(customer),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    customer.companyName != null
                        ? Icons.business
                        : Icons.person,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),

                // Información del cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Indicador de selección
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNoResultsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off, color: Colors.orange.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No se encontraron clientes con ese criterio',
              style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LÓGICA DE BÚSQUEDA ====================

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (_showSearchField) {
        // Abrir búsqueda
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      } else {
        // Cerrar búsqueda
        _closeSearch();
      }
    });
  }

  void _closeSearch() {
    setState(() {
      _showSearchField = false;
      _searchController.clear();
      _searchResults.clear();
      _isSearching = false;
    });
  }

  void _onSearchChanged() async {
    // Verificar que el widget esté montado
    if (!mounted) {
      print('⚠️ CustomerSelectorWidget: Widget no montado, cancelando búsqueda');
      return;
    }
    
    try {
      final query = _searchController.text.trim();

      if (query.isEmpty) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
        return;
      }

    // Evitar búsquedas repetidas
    if (query == _lastSearchTerm) return;
    _lastSearchTerm = query;

    // Búsqueda mínima de 2 caracteres
    if (query.length < 2) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      List<Customer> results = [];

      // Búsqueda usando el controlador
      if (_invoiceController != null) {
        results = await _invoiceController!.searchCustomers(query);
      } else {
        // Fallback a búsqueda local
        results = _searchInAvailableCustomers(query);
      }

      if (mounted) {
        setState(() {
          _searchResults.clear();
          _searchResults.addAll(results.take(8)); // Limitar resultados
          _isSearching = false;
        });
      }
    } catch (e) {
      print('❌ Error en búsqueda de clientes: $e');
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
      }
    }
    } catch (e) {
      print('⚠️ Error en _onSearchChanged (CustomerSelectorWidget): $e');
    }
  }

  List<Customer> _searchInAvailableCustomers(String query) {
    if (_invoiceController == null) return [];

    final customers = _invoiceController!.availableCustomers;
    final searchTerm = query.toLowerCase();

    return customers.where((customer) {
      return customer.firstName.toLowerCase().contains(searchTerm) ||
          customer.lastName.toLowerCase().contains(searchTerm) ||
          (customer.companyName?.toLowerCase().contains(searchTerm) ?? false) ||
          customer.email.toLowerCase().contains(searchTerm) ||
          (customer.phone?.contains(searchTerm) ?? false) ||
          customer.documentNumber.contains(searchTerm);
    }).toList();
  }

  void _handleDirectSearch(String query) {
    if (query.trim().isEmpty) return;

    // Si hay resultados, seleccionar el primero
    if (_searchResults.isNotEmpty) {
      _selectCustomer(_searchResults.first);
    }
  }

  void _selectCustomer(Customer customer) {
    // Notificar selección
    widget.onCustomerSelected(customer);

    // Cerrar búsqueda
    _closeSearch();

    print('👤 Cliente seleccionado: ${customer.displayName}');

    // Feedback visual
    Get.snackbar(
      'Cliente Seleccionado',
      customer.displayName,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
    );
  }

  bool _isDefaultCustomer(Customer customer) {
    return customer.id == 'consumidor_final' ||
        customer.id == '3c605381-362b-454a-8c0f-b3c055aa568d';
  }
}