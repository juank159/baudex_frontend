// lib/features/invoices/presentation/widgets/customer_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../customers/domain/entities/customer.dart';
import '../controllers/invoice_form_controller.dart';
import 'quick_create_customer_dialog.dart';

class CustomerSelectorWidget extends StatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer) onCustomerSelected;
  final VoidCallback? onClearCustomer;
  final InvoiceFormController?
  controller; // ✅ NUEVO: Recibir el controlador específico
  final Function(bool)? onFocusChanged; // ✅ NUEVO: Callback para cambios de focus

  const CustomerSelectorWidget({
    super.key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    this.onClearCustomer,
    this.controller, // ✅ NUEVO: Parámetro del controlador
    this.onFocusChanged, // ✅ NUEVO: Callback de focus
  });

  @override
  State<CustomerSelectorWidget> createState() => CustomerSelectorWidgetState();
}

class CustomerSelectorWidgetState extends State<CustomerSelectorWidget> {
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
    
    // ✅ NUEVO: Escuchar cambios de focus para coordinar con ProductSearchWidget
    _focusNode.addListener(() {
      widget.onFocusChanged?.call(_focusNode.hasFocus);
    });
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
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
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

  // ✅ NUEVO: Display simplificado del cliente con tema elegante
  Widget _buildSimpleCustomerDisplay(BuildContext context, Customer? customer) {
    final customerName = customer?.displayName ?? 'Consumidor Final';
    final isDefaultCustomer = customer != null && _isDefaultCustomer(customer);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefaultCustomer
              ? ElegantLightTheme.accentOrange.withOpacity(0.4)
              : ElegantLightTheme.textTertiary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          // Icono del cliente con gradiente
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: isDefaultCustomer
                  ? ElegantLightTheme.warningGradient
                  : ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isDefaultCustomer
                  ? [
                      BoxShadow(
                        color: ElegantLightTheme.accentOrange.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : ElegantLightTheme.glowShadow,
            ),
            child: Icon(
              isDefaultCustomer ? Icons.storefront : Icons.person,
              color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                if (isDefaultCustomer) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Venta mostrador',
                    style: TextStyle(
                      fontSize: 11,
                      color: ElegantLightTheme.accentOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Botón crear cliente nuevo (acceso rápido sin salir de factura)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _openCreateCustomerDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_add_alt_1,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botón de búsqueda con gradiente
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _toggleSearch,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
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
                    gradient: ElegantLightTheme.warningGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.accentOrange.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNode.hasFocus
              ? ElegantLightTheme.primaryBlue.withOpacity(0.5)
              : ElegantLightTheme.textTertiary.withOpacity(0.2),
          width: _focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: const TextStyle(
          fontSize: 14,
          color: ElegantLightTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar cliente...',
          hintStyle: const TextStyle(
            color: ElegantLightTheme.textTertiary,
            fontSize: 13,
          ),
          prefixIcon:
              _isSearching
                  ? Container(
                    padding: const EdgeInsets.all(12),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ),
                  )
                  : const Icon(
                      Icons.search,
                      color: ElegantLightTheme.textSecondary,
                    ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: ElegantLightTheme.textSecondary,
                    ),
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
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withOpacity(0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final customer = _searchResults[index];
            return _buildCustomerTile(context, customer);
          },
        ),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? ElegantLightTheme.primaryBlue.withOpacity(0.08)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: ElegantLightTheme.textTertiary.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Avatar con gradiente
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? ElegantLightTheme.primaryGradient
                        : ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? ElegantLightTheme.primaryBlue.withOpacity(0.3)
                          : ElegantLightTheme.textTertiary.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    customer.companyName != null
                        ? Icons.business
                        : Icons.person,
                    color: isSelected
                        ? Colors.white
                        : ElegantLightTheme.primaryBlue,
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
                          fontSize: 14,
                          color: isSelected
                              ? ElegantLightTheme.primaryBlue
                              : ElegantLightTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ElegantLightTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Indicador de selección con gradiente
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.accentOrange.withOpacity(0.1),
            ElegantLightTheme.accentOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.accentOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.warningGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.search_off,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No se encontraron clientes con ese criterio',
              style: TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CREAR CLIENTE RÁPIDO ====================

  /// Abre el dialog de creación rápida de cliente. Si el cajero estaba
  /// buscando algo, ese texto se pasa como nombre prellenado. Cuando el
  /// dialog crea exitosamente, el cliente queda seleccionado en la
  /// factura sin pasos adicionales. Funciona offline-first vía el
  /// usecase del repositorio (encola en SyncQueue si no hay red).
  void _openCreateCustomerDialog() {
    final prefilledName = _searchController.text.trim().isNotEmpty
        ? _searchController.text.trim()
        : null;

    Get.dialog(
      QuickCreateCustomerDialog(
        prefilledName: prefilledName,
        onCreated: (customer) {
          // Cerrar la búsqueda si estaba abierta y seleccionar el nuevo cliente.
          _closeSearch();
          widget.onCustomerSelected(customer);
        },
      ),
      barrierDismissible: true,
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
      print(
        '⚠️ CustomerSelectorWidget: Widget no montado, cancelando búsqueda',
      );
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
    // Buscar por nombre completo "Consumidor Final" en lugar de ID hardcodeado
    final fullName = '${customer.firstName} ${customer.lastName}'.trim();
    return fullName.toLowerCase() == 'consumidor final' ||
        customer.firstName.toLowerCase() == 'consumidor' && customer.lastName.toLowerCase() == 'final';
  }
}
