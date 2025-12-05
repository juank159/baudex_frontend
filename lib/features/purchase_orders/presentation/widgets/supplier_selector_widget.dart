// lib/features/purchase_orders/presentation/widgets/supplier_selector_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../suppliers/domain/entities/supplier.dart';
import '../controllers/purchase_order_form_controller.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';

class SupplierSelectorWidget extends StatefulWidget {
  final Supplier? selectedSupplier;
  final Function(Supplier) onSupplierSelected;
  final VoidCallback? onClearSupplier;
  final PurchaseOrderFormController? controller;
  final bool activateOnTextFieldTap;

  const SupplierSelectorWidget({
    super.key,
    this.selectedSupplier,
    required this.onSupplierSelected,
    this.onClearSupplier,
    this.controller,
    this.activateOnTextFieldTap = false,
  });

  @override
  State<SupplierSelectorWidget> createState() => SupplierSelectorWidgetState();
}

class SupplierSelectorWidgetState extends State<SupplierSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Supplier> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchField = false;
  String _lastSearchTerm = '';
  Timer? _debounceTimer;
  int _selectedIndex = -1; // Para navegación con teclas

  PurchaseOrderFormController? get _purchaseOrderController {
    if (widget.controller != null) {
      return widget.controller;
    }

    try {
      return Get.find<PurchaseOrderFormController>();
    } catch (e) {
      print('⚠️ PurchaseOrderFormController no encontrado: $e');
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
      _debounceTimer?.cancel();
      _searchController.removeListener(_onSearchChanged);
      _searchController.dispose();
      _focusNode.dispose();
    } catch (e) {
      print('⚠️ Error en dispose de SupplierSelectorWidget: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _purchaseOrderController;

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
              'No se encontró el controlador para gestionar proveedores',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display del proveedor actual
        Obx(() {
          final supplier = controller.selectedSupplier.value;
          return _buildSimpleSupplierDisplay(context, supplier);
        }),

        // Campo de búsqueda
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

  Widget _buildSimpleSupplierDisplay(BuildContext context, Supplier? supplier) {
    final supplierName = supplier?.name ?? 'Seleccionar proveedor';
    final hasSupplier = supplier != null;

    return GestureDetector(
      onTap:
          widget.activateOnTextFieldTap
              ? () {
                setState(() {
                  _showSearchField = true;
                });
                _focusNode.requestFocus();
              }
              : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasSupplier ? Colors.green.shade300 : Colors.grey.shade300,
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
            // Icono del proveedor
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    hasSupplier
                        ? Colors.green.shade100
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.business,
                color:
                    hasSupplier
                        ? Colors.green.shade600
                        : Theme.of(context).primaryColor,
                size: 16,
              ),
            ),

            const SizedBox(width: 12),

            // Nombre del proveedor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplierName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          hasSupplier ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                  if (hasSupplier) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${supplier.documentType.name.toUpperCase() ?? 'DOC'}: ${supplier.documentNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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

            // Botón de limpiar
            if (hasSupplier && widget.onClearSupplier != null) ...[
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    widget.onClearSupplier!();
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
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText:
                'Buscar proveedor... (↑↓ para navegar, Enter para seleccionar)',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
                        _resetSelection();
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onSubmitted: (value) => _handleEnterKey(),
        ),
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
          final supplier = _searchResults[index];
          final isKeyboardSelected = _selectedIndex == index;
          return _buildSupplierTile(context, supplier, isKeyboardSelected);
        },
      ),
    );
  }

  Widget _buildSupplierTile(
    BuildContext context,
    Supplier supplier,
    bool isKeyboardSelected,
  ) {
    return Obx(() {
      final controller = _purchaseOrderController;
      if (controller == null) return const SizedBox.shrink();

      final isSelected = controller.selectedSupplier.value?.id == supplier.id;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectSupplier(supplier),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isKeyboardSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : isSelected
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
                    Icons.business,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),

                // Información del proveedor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplier.name,
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
                        '${supplier.documentType?.name?.toUpperCase() ?? 'DOC'}: ${supplier.documentNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (supplier.email != null)
                        Text(
                          supplier.email!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
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
              'No se encontraron proveedores con ese criterio',
              style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NAVEGACIÓN CON TECLAS ====================

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && _searchResults.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _searchResults.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex =
              _selectedIndex <= 0
                  ? _searchResults.length - 1
                  : _selectedIndex - 1;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _handleEnterKey();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _closeSearch();
      }
    }
  }

  void _handleEnterKey() {
    if (_searchResults.isNotEmpty) {
      if (_selectedIndex >= 0 && _selectedIndex < _searchResults.length) {
        _selectSupplier(_searchResults[_selectedIndex]);
      } else {
        // Si no hay selección con teclas, usar el primero
        _selectSupplier(_searchResults.first);
      }
    }
  }

  void _resetSelection() {
    setState(() {
      _selectedIndex = -1;
    });
  }

  // ==================== LÓGICA DE BÚSQUEDA ====================

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (_showSearchField) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      } else {
        _closeSearch();
      }
    });
  }

  void _closeSearch() {
    _debounceTimer?.cancel();
    setState(() {
      _showSearchField = false;
      _searchController.clear();
      _searchResults.clear();
      _isSearching = false;
      _selectedIndex = -1;
    });
  }

  void _onSearchChanged() {
    if (!mounted) {
      print(
        '⚠️ SupplierSelectorWidget: Widget no montado, cancelando búsqueda',
      );
      return;
    }

    final query = _searchController.text.trim();

    // Cancelar timer anterior si existe
    _debounceTimer?.cancel();

    // Limpiar resultados si la consulta está vacía
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    // Evitar búsquedas duplicadas
    if (query == _lastSearchTerm) return;

    // Limpiar resultados si la consulta es muy corta
    if (query.length < 2) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    // Mostrar estado de carga inmediatamente
    setState(() {
      _isSearching = true;
    });

    // Configurar debounce de 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    try {
      _lastSearchTerm = query;

      List<Supplier> results = [];

      if (_purchaseOrderController != null) {
        results = await _purchaseOrderController!.searchSuppliers(query);
      }

      if (mounted) {
        setState(() {
          _searchResults.clear();
          _searchResults.addAll(results.take(8));
          _isSearching = false;
          _selectedIndex =
              _searchResults.isNotEmpty ? 0 : -1; // Auto-seleccionar el primero
        });
      }
    } catch (e) {
      print('❌ Error en búsqueda de proveedores: $e');
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
      }
    }
  }

  void _selectSupplier(Supplier supplier) {
    widget.onSupplierSelected(supplier);
    _closeSearch();

    print('🏢 Proveedor seleccionado: ${supplier.name}');

    Get.snackbar(
      'Proveedor Seleccionado',
      supplier.name,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
    );
  }
}
