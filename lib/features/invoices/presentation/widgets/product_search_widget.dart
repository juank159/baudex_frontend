// lib/features/invoices/presentation/widgets/product_search_widget.dart
import 'dart:async';
import 'package:baudex_desktop/app/shared/screens/barcode_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_price.dart';
import '../controllers/invoice_form_controller.dart';

class ProductSearchWidget extends StatefulWidget {
  final InvoiceFormController controller;
  final Function(Product product, double quantity) onProductSelected;
  final bool autoFocus;
  final String? hint;

  const ProductSearchWidget({
    super.key,
    required this.controller,
    required this.onProductSelected,
    this.autoFocus = false,
    this.hint,
  });

  @override
  State<ProductSearchWidget> createState() => _ProductSearchWidgetState();
}

class _ProductSearchWidgetState extends State<ProductSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // Para el TextField
  final FocusNode _keyboardFocusNode = FocusNode(); // ✅ NUEVO: Para el RawKeyboardListener
  final List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  String _lastSearchTerm = '';

  // ✅ NUEVO: Variables para navegación por teclado
  int _selectedResultIndex = -1;
  final ScrollController _resultsScrollController = ScrollController();

  // Timer para debounce
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Auto focus al abrir la pantalla - con delay para evitar bloqueos
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _focusNode.requestFocus(); // TextField focus
            // El keyboard focus se activará automáticamente cuando haya resultados
          }
        });
      });
    }
  }

  @override
  void dispose() {
    try {
      _debounceTimer?.cancel();
      
      // Remover listener antes de dispose
      _searchController.removeListener(_onSearchChanged);
      
      _searchController.dispose();
      _focusNode.dispose();
      _keyboardFocusNode.dispose(); // ✅ NUEVO: Limpiar keyboard focus node
      _resultsScrollController.dispose(); // ✅ NUEVO: Limpiar scroll controller
    } catch (e) {
      print('⚠️ Error en dispose de ProductSearchWidget: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.qr_code_scanner,
                color: Theme.of(context).primaryColor,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'Productos',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              if (_isSearching)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Campo de búsqueda principal con escáner
          _buildSearchField(context),

          // Resultados de búsqueda
          if (_showResults && _searchResults.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildSearchResults(context),
          ],

          // Opción de producto sin registrar o mensaje de no resultados
          if (_showResults && _searchResults.isEmpty && !_isSearching) ...[
            const SizedBox(height: 4),
            _buildUnregisteredProductOption(context),
          ],

        // Tips de uso cuando no hay búsqueda
        if (!_showResults && _searchController.text.isEmpty) ...[
          const SizedBox(height: 8),
          _buildUsageTips(context),
        ],
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _focusNode.hasFocus
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
          width: _focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Campo de texto principal
          Expanded(
            child: RawKeyboardListener(
              focusNode: _keyboardFocusNode, // ✅ NUEVO: FocusNode separado para navegación
              onKey: _handleKeyboardNavigation,
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: widget.hint ?? 'Buscar...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.search,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (value) => _handleDirectSearch(value),
              ),
            ),
          ),

          // Botón de limpiar (cuando hay texto)
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _focusNode.requestFocus();
              },
            ),

          // Botón de escáner (solo en móvil)
          if (context.isMobile)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _openBarcodeScanner,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

          // Icono de código de barras (desktop)
          if (!context.isMobile)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 8),
              child: Icon(Icons.qr_code, color: Colors.grey.shade400),
            ),
        ],
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
        controller: _resultsScrollController, // ✅ NUEVO: Usar scroll controller
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final product = _searchResults[index];
          final isSelected =
              index ==
              _selectedResultIndex; // ✅ NUEVO: Verificar si está seleccionado
          return _buildProductTile(context, product, isSelected: isSelected);
        },
      ),
    );
  }

  Widget _buildProductTile(
    BuildContext context,
    Product product, {
    bool isSelected = false,
  }) {
    final hasStock = product.stock > 0;
    final price = product.sellingPrice ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color:
            isSelected
                ? Theme.of(context).primaryColor.withOpacity(
                  0.1,
                ) // ✅ NUEVO: Color cuando está seleccionado
                : hasStock
                ? Colors.white
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: hasStock ? () => _selectProduct(product) : null,
          child: Container(
            decoration:
                isSelected
                    ? BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ), // ✅ NUEVO: Borde cuando está seleccionado
                    )
                    : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icono de producto
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color:
                          hasStock
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color:
                          hasStock
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Información del producto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del producto
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color:
                                hasStock ? Colors.black : Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // SKU y código de barras
                        Row(
                          children: [
                            Text(
                              'SKU: ${product.sku}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (product.barcode != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'CB: ${product.barcode}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Precio y stock
                        Row(
                          children: [
                            Text(
                              AppFormatters.formatCurrency(price),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    hasStock
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    hasStock
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                hasStock
                                    ? 'Stock: ${AppFormatters.formatStock(product.stock)}'
                                    : 'Sin stock',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      hasStock
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Icono de acción
                  Icon(
                    hasStock ? Icons.add_circle : Icons.block,
                    color:
                        hasStock
                            ? Theme.of(context).primaryColor
                            : Colors.red.shade400,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnregisteredProductOption(BuildContext context) {
    final searchValue = _searchController.text.trim();
    final isNumeric = _isNumericValue(searchValue);

    if (!isNumeric) {
      return _buildNoResultsMessage();
    }

    final price = double.tryParse(searchValue) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _createUnregisteredProduct(price),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.add_shopping_cart,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Producto sin registrar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Precio: ${AppFormatters.formatCurrency(price)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Icono de acción
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue.shade600,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              'No se encontraron productos para "${_searchController.text}"',
              style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTips(BuildContext context) {
    return const SizedBox.shrink(); // Vacío, sin tips innecesarios
  }

  // ==================== NAVEGACIÓN POR TECLADO ====================

  void _handleKeyboardNavigation(RawKeyEvent event) {
    // ✅ MEJORADO: Solo manejar navegación cuando hay resultados, sin quitar focus del TextField
    if (event is RawKeyDownEvent && _showResults && _searchResults.isNotEmpty) {
      print('🎹 Navegación detectada: ${event.logicalKey} - Resultados: ${_searchResults.length}');
      
      // Flecha hacia abajo
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedResultIndex = (_selectedResultIndex + 1).clamp(
            0,
            _searchResults.length - 1,
          );
          _scrollToSelected();
        });
        print('⬇️ Seleccionado: $_selectedResultIndex/${_searchResults.length - 1}');
        return;
      }

      // Flecha hacia arriba
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedResultIndex = (_selectedResultIndex - 1).clamp(
            0,
            _searchResults.length - 1,
          );
          _scrollToSelected();
        });
        print('⬆️ Seleccionado: $_selectedResultIndex/${_searchResults.length - 1}');
        return;
      }

      // Enter para seleccionar
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          _selectedResultIndex >= 0) {
        final selectedProduct = _searchResults[_selectedResultIndex];
        if (selectedProduct.stock > 0) {
          print('✅ Seleccionando con Enter: ${selectedProduct.name}');
          _selectProduct(selectedProduct);
          // ✅ NUEVO: Asegurar que el focus vuelva al TextField después de seleccionar con Enter
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) {
                _focusNode.requestFocus();
                print('🔍 Focus devuelto después de Enter - producto: ${selectedProduct.name}');
              }
            });
          });
        }
        return;
      }
    }
  }

  void _scrollToSelected() {
    if (_selectedResultIndex >= 0 && _resultsScrollController.hasClients) {
      const double itemHeight = 70.0; // Altura estimada de cada item
      final double targetOffset = _selectedResultIndex * itemHeight;

      _resultsScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  // ==================== LÓGICA DE BÚSQUEDA ====================

  void _onSearchChanged() {
    // Verificar que el widget esté montado y el controlador disponible
    if (!mounted) {
      print('⚠️ ProductSearchWidget: Widget no montado, cancelando búsqueda');
      return;
    }
    
    try {
      // ✅ NUEVO: Asegurar que el focus permanezca en el TextField mientras se escribe
      if (_focusNode.canRequestFocus && !_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusNode.requestFocus();
            print('🔍 Focus restaurado durante escritura');
          }
        });
      }
      
      // Cancelar timer anterior si existe
      _debounceTimer?.cancel();

      final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showResults = false;
        _isSearching = false;
        _lastSearchTerm = '';
        _selectedResultIndex = -1; // ✅ NUEVO: Resetear selección
      });
      return;
    }

    // ✅ NUEVO: Si el usuario está escribiendo y hay resultados visibles, resetear selección
    if (_showResults && _searchResults.isNotEmpty && query != _lastSearchTerm) {
      setState(() {
        _selectedResultIndex = -1; // Resetear selección mientras escribe
      });
      print('⌨️ Usuario escribiendo, selección reseteada');
    }

      // Crear nuevo timer con debounce
      _debounceTimer = Timer(_debounceDuration, () {
        _performSearch(query);
      });
    } catch (e) {
      print('⚠️ Error en _onSearchChanged (ProductSearchWidget): $e');
      // Cancelar timer si hay error
      _debounceTimer?.cancel();
    }
  }

  Future<void> _performSearch(String query) async {
    // Evitar búsquedas repetidas
    if (query == _lastSearchTerm) return;
    _lastSearchTerm = query;

    // Búsqueda mínima de 2 caracteres
    if (query.length < 2) {
      setState(() {
        _searchResults.clear();
        _showResults =
            true; // Mostrar para que aparezca la opción de producto sin registrar
      });
      return;
    }

    if (widget.controller.isLoadingProducts) {
      print('⚠️ Productos aún cargando, esperando...');
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      List<Product> results = [];

      // 1. Búsqueda exacta por código de barras (prioritaria)
      final exactMatch = await _searchByBarcode(query);
      if (exactMatch != null) {
        setState(() {
          _isSearching = false;
        });
        _selectProduct(exactMatch);
        return;
      }

      // 2. Búsqueda por SKU exacto
      final skuMatch = await _searchBySku(query);
      if (skuMatch != null) {
        results.add(skuMatch);
      }

      // 3. Búsqueda general usando el controlador
      final searchResults = await widget.controller.searchProducts(query);
      results.addAll(searchResults);

      // Eliminar duplicados y limitar resultados
      final uniqueResults = <String, Product>{};
      for (final product in results) {
        uniqueResults[product.id] = product;
      }

      if (mounted) {
        setState(() {
          _searchResults.clear();
          _searchResults.addAll(uniqueResults.values.take(8));
          _showResults = true;
          _isSearching = false;
          _selectedResultIndex =
              _searchResults.isNotEmpty
                  ? 0
                  : -1; // ✅ NUEVO: Seleccionar primer resultado automáticamente
        });
        
        // ✅ NUEVO: Activar keyboard focus cuando hay resultados PERO mantener TextField focus
        if (_searchResults.isNotEmpty) {
          // No quitar el focus del TextField, solo preparar el keyboard listener
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Asegurar que el TextField mantenga el focus para seguir escribiendo
              _focusNode.requestFocus();
            }
          });
        }
      }

      print(
        '✅ Búsqueda completada: ${_searchResults.length} productos encontrados',
      );
    } catch (e) {
      print('❌ Error en búsqueda de productos: $e');
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _showResults = true;
          _isSearching = false;
        });
      }
    }
  }

  Future<Product?> _searchByBarcode(String barcode) async {
    try {
      if (widget.controller.isLoadingProducts) {
        return null;
      }

      final products = widget.controller.availableProducts;
      return products.firstWhereOrNull(
        (product) => product.barcode?.toLowerCase() == barcode.toLowerCase(),
      );
    } catch (e) {
      print('❌ Error en búsqueda por código de barras: $e');
      return null;
    }
  }

  Future<Product?> _searchBySku(String sku) async {
    try {
      if (widget.controller.isLoadingProducts) {
        return null;
      }

      final products = widget.controller.availableProducts;
      return products.firstWhereOrNull(
        (product) => product.sku.toLowerCase() == sku.toLowerCase(),
      );
    } catch (e) {
      print('❌ Error en búsqueda por SKU: $e');
      return null;
    }
  }

  void _handleDirectSearch(String query) {
    if (query.trim().isEmpty) return;

    // Si hay resultados, seleccionar el primero
    if (_searchResults.isNotEmpty) {
      _selectProduct(_searchResults.first);
    } else if (_isNumericValue(query)) {
      // Si es un número y no hay resultados, crear producto sin registrar
      final price = double.tryParse(query) ?? 0.0;
      _createUnregisteredProduct(price);
    }
  }

  // ==================== FUNCIONES AUXILIARES ====================

  bool _isNumericValue(String value) {
    // Solo números de 6 dígitos o menos
    if (double.tryParse(value) == null) return false;
    String digitsOnly = value.replaceAll('.', '').replaceAll(',', '');
    return RegExp(r'^\d{1,6}$').hasMatch(digitsOnly);
  }

  void _createUnregisteredProduct(double price) {
    _showProductNameDialog(price);
  }

  void _showProductNameDialog(double price) {
    final TextEditingController nameController = TextEditingController();
    nameController.text = 'Producto sin registrar';

    // Seleccionar todo el texto cuando se abra el diálogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: nameController.text.length,
      );
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.add_shopping_cart,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('Nuevo Producto'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precio: ${AppFormatters.formatCurrency(price)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nombre del producto:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 100,
                  decoration: InputDecoration(
                    hintText: 'Escribe el nombre del producto...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.of(context).pop();
                      _createProductWithName(value.trim(), price);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Mantener focus en el campo de búsqueda
                  _focusNode.requestFocus();
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.of(context).pop();
                    _createProductWithName(name, price);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Agregar'),
              ),
            ],
          ),
    );
  }

  void _createProductWithName(String productName, double price) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final unregisteredProduct = Product(
      id: 'temp_$timestamp',
      name: productName,
      sku: 'TEMP-$timestamp',
      description: 'Producto no registrado en inventario',
      type: ProductType.product,
      status: ProductStatus.active,
      stock: 999, // Stock "infinito" para productos temporales
      minStock: 0,
      unit: 'pcs',
      barcode: null,
      weight: null,
      length: null,
      width: null,
      height: null,
      images: null,
      metadata: {
        'isTemporary': true,
        'originalPrice': price,
        'createdInPOS': true,
      },
      categoryId: 'temp-category',
      createdById: 'system',
      prices: [
        ProductPrice(
          id: 'temp_price_$timestamp',
          type: PriceType.price1,
          name: 'Precio Temporal',
          amount: price,
          currency: 'COP',
          status: PriceStatus.active,
          validFrom: DateTime.now(),
          validTo: null,
          discountPercentage: 0,
          discountAmount: null,
          minQuantity: 1,
          profitMargin: null,
          notes: 'Precio para producto temporal',
          productId: 'temp_$timestamp',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
      category: null,
      createdBy: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print(
      '✅ Producto temporal creado: $productName - ${AppFormatters.formatCurrency(price)}',
    );
    print('🆔 ID temporal: temp_$timestamp');
    _selectProduct(unregisteredProduct);
  }

  // ==================== SCANNER FUNCTIONALITY ====================

  Future<void> _openBarcodeScanner() async {
    try {
      print('📱 Abriendo escáner de códigos de barras...');

      final scannedCode = await Get.to<String>(
        () => const BarcodeScannerScreen(),
      );

      if (scannedCode != null && scannedCode.isNotEmpty) {
        print('🔍 Código escaneado: $scannedCode');
        _searchController.text = scannedCode;

        // Trigger búsqueda automática después del escaneo
        _handleDirectSearch(scannedCode);
      }
    } catch (e) {
      print('❌ Error al abrir escáner: $e');
      _showError('Error de escáner', 'No se pudo abrir el escáner de códigos');
    }
  }

  void _selectProduct(Product product, {double quantity = 1}) {
    // Cancelar cualquier búsqueda pendiente
    _debounceTimer?.cancel();

    // Limpiar búsqueda
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _showResults = false;
      _lastSearchTerm = '';
      _isSearching = false;
      _selectedResultIndex = -1; // ✅ NUEVO: Resetear selección
    });

    // ✅ MEJORADO: Asegurar que el focus vuelva al TextField de forma confiable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pequeño delay adicional para asegurar que toda la UI se haya actualizado
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _focusNode.requestFocus();
          print('🔍 Focus devuelto al campo de búsqueda después de seleccionar: ${product.name}');
        }
      });
    });

    // Notificar selección
    widget.onProductSelected(product, quantity);

    print('✅ Producto seleccionado: ${product.name}');
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
    );
  }
}
