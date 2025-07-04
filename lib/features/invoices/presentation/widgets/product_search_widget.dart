// // lib/features/invoices/presentation/widgets/product_search_widget.dart
// import 'dart:async';
// import 'package:baudex_desktop/app/shared/screens/barcode_scanner_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import '../../../../app/core/utils/responsive.dart';
// import '../../../products/domain/entities/product.dart';
// import '../../../products/domain/entities/product_price.dart';
// import '../controllers/invoice_form_controller.dart';

// class ProductSearchWidget extends StatefulWidget {
//   final Function(Product product, double quantity) onProductSelected;
//   final bool autoFocus;
//   final String? hint;

//   const ProductSearchWidget({
//     super.key,
//     required this.onProductSelected,
//     this.autoFocus = false,
//     this.hint,
//   });

//   @override
//   State<ProductSearchWidget> createState() => _ProductSearchWidgetState();
// }

// class _ProductSearchWidgetState extends State<ProductSearchWidget> {
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   final List<Product> _searchResults = [];
//   bool _isSearching = false;
//   bool _showResults = false;
//   String _lastSearchTerm = '';

//   // Timer para debounce
//   Timer? _debounceTimer;
//   static const Duration _debounceDuration = Duration(milliseconds: 300);

//   InvoiceFormController? get _invoiceController {
//     try {
//       return Get.find<InvoiceFormController>();
//     } catch (e) {
//       return null;
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_onSearchChanged);

//     // ✅ FOCO AUTOMÁTICO EN WINDOWS Y MÓVIL
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Future.delayed(const Duration(milliseconds: 300), () {
//         if (mounted) {
//           _focusNode.requestFocus();
//         }
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _debounceTimer?.cancel();
//     _searchController.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // ✅ CAMPO DE BÚSQUEDA SIMPLIFICADO
//         _buildSimpleSearchField(context),

//         // Resultados de búsqueda
//         if (_showResults && _searchResults.isNotEmpty) ...[
//           const SizedBox(height: 8),
//           _buildSearchResults(context),
//         ],

//         // ✅ NUEVA OPCIÓN: Producto sin registrar
//         if (_showResults &&
//             _searchResults.isEmpty &&
//             !_isSearching &&
//             _searchController.text.isNotEmpty) ...[
//           const SizedBox(height: 8),
//           _buildUnregisteredProductOption(context),
//         ],
//       ],
//     );
//   }

//   // ✅ NUEVO: Campo de búsqueda con foco automático y mejor UX
//   Widget _buildSimpleSearchField(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color:
//               _focusNode.hasFocus
//                   ? Theme.of(context).primaryColor
//                   : Colors.grey.shade300,
//           width: _focusNode.hasFocus ? 2 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Campo de texto principal
//           Expanded(
//             child: TextField(
//               controller: _searchController,
//               focusNode: _focusNode,
//               keyboardType: TextInputType.text,
//               textInputAction: TextInputAction.search,
//               autofocus: true, // ✅ AUTOFOCUS NATIVO
//               inputFormatters: [
//                 // Permitir números, letras y algunos caracteres especiales
//                 FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-_.]')),
//               ],
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               decoration: InputDecoration(
//                 hintText:
//                     widget.hint ?? 'Buscar producto, SKU o escribir precio...',
//                 hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
//                 prefixIcon:
//                     _isSearching
//                         ? Container(
//                           padding: const EdgeInsets.all(12),
//                           child: const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: Colors.blue,
//                             ),
//                           ),
//                         )
//                         : Icon(
//                           Icons.search,
//                           color:
//                               _focusNode.hasFocus
//                                   ? Theme.of(context).primaryColor
//                                   : Colors.grey.shade500,
//                         ),
//                 border: InputBorder.none,
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 14,
//                 ),
//               ),
//               onSubmitted: (value) => _handleDirectSearch(value),
//               onTap: () {
//                 // ✅ ASEGURAR FOCO AL HACER TAP
//                 if (!_focusNode.hasFocus) {
//                   _focusNode.requestFocus();
//                 }
//               },
//             ),
//           ),

//           // Botón de limpiar
//           if (_searchController.text.isNotEmpty)
//             IconButton(
//               icon: Icon(Icons.clear, color: Colors.grey.shade600),
//               onPressed: () {
//                 _searchController.clear();
//                 // ✅ MANTENER FOCO DESPUÉS DE LIMPIAR
//                 Future.delayed(const Duration(milliseconds: 50), () {
//                   if (mounted) {
//                     _focusNode.requestFocus();
//                   }
//                 });
//               },
//             ),

//           // Botón de escáner (solo en móvil)
//           if (context.isMobile)
//             Container(
//               margin: const EdgeInsets.only(right: 8),
//               child: Material(
//                 color: Theme.of(context).primaryColor,
//                 borderRadius: BorderRadius.circular(6),
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(6),
//                   onTap: _openBarcodeScanner,
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     child: const Icon(
//                       Icons.qr_code_scanner,
//                       color: Colors.white,
//                       size: 20,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ✅ NUEVO: Opción para producto sin registrar
//   Widget _buildUnregisteredProductOption(BuildContext context) {
//     final searchValue = _searchController.text.trim();
//     final isNumeric = _isNumericValue(searchValue);

//     if (!isNumeric) {
//       return _buildNoResultsMessage();
//     }

//     final price = double.tryParse(searchValue) ?? 0.0;

//     return Container(
//       margin: const EdgeInsets.only(top: 4),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.blue.shade200),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(8),
//           onTap: () => _createUnregisteredProduct(price),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 // Icono
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade100,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Icon(
//                     Icons.add_shopping_cart,
//                     color: Colors.blue.shade600,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),

//                 // Información
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Producto sin registrar',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 15,
//                           color: Colors.blue.shade800,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         'Precio: \$${price.toStringAsFixed(0)}',
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.blue.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Icono de acción
//                 Icon(
//                   Icons.arrow_forward_ios,
//                   color: Colors.blue.shade600,
//                   size: 16,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchResults(BuildContext context) {
//     return Container(
//       constraints: const BoxConstraints(maxHeight: 250),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ListView.builder(
//         shrinkWrap: true,
//         itemCount: _searchResults.length,
//         itemBuilder: (context, index) {
//           final product = _searchResults[index];
//           return _buildProductTile(context, product);
//         },
//       ),
//     );
//   }

//   // ✅ VERSIÓN SIMPLIFICADA del tile de producto
//   Widget _buildProductTile(BuildContext context, Product product) {
//     final hasStock = product.stock > 0;
//     final price = product.sellingPrice ?? 0.0;

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: hasStock ? () => _selectProduct(product) : null,
//         child: Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             border: Border(
//               bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
//             ),
//           ),
//           child: Row(
//             children: [
//               // Icono simple
//               Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color:
//                       hasStock
//                           ? Theme.of(context).primaryColor.withOpacity(0.1)
//                           : Colors.grey.shade200,
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 child: Icon(
//                   Icons.inventory_2,
//                   color:
//                       hasStock
//                           ? Theme.of(context).primaryColor
//                           : Colors.grey.shade400,
//                   size: 18,
//                 ),
//               ),
//               const SizedBox(width: 12),

//               // Información básica
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       product.name,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 15,
//                         color: hasStock ? Colors.black87 : Colors.grey.shade500,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),
//                     Row(
//                       children: [
//                         Text(
//                           '\$${price.toStringAsFixed(0)}',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 14,
//                             color:
//                                 hasStock
//                                     ? Theme.of(context).primaryColor
//                                     : Colors.grey.shade500,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color:
//                                 hasStock
//                                     ? Colors.green.shade100
//                                     : Colors.red.shade100,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             hasStock ? 'Stock: ${product.stock}' : 'Sin stock',
//                             style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.w600,
//                               color:
//                                   hasStock
//                                       ? Colors.green.shade700
//                                       : Colors.red.shade700,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               // Icono de acción
//               Icon(
//                 hasStock ? Icons.add_circle : Icons.block,
//                 color:
//                     hasStock
//                         ? Theme.of(context).primaryColor
//                         : Colors.red.shade400,
//                 size: 24,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNoResultsMessage() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.orange.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.orange.shade200),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.search_off, color: Colors.orange.shade600, size: 20),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               'No se encontraron productos',
//               style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ==================== LÓGICA DE BÚSQUEDA ====================

//   void _onSearchChanged() {
//     _debounceTimer?.cancel();

//     final query = _searchController.text.trim();

//     if (query.isEmpty) {
//       setState(() {
//         _searchResults.clear();
//         _showResults = false;
//         _isSearching = false;
//         _lastSearchTerm = '';
//       });
//       return;
//     }

//     _debounceTimer = Timer(_debounceDuration, () {
//       _performSearch(query);
//     });
//   }

//   Future<void> _performSearch(String query) async {
//     if (query == _lastSearchTerm) return;
//     _lastSearchTerm = query;

//     if (query.length < 2) {
//       setState(() {
//         _searchResults.clear();
//         _showResults =
//             true; // Mostrar para que aparezca la opción de producto sin registrar
//       });
//       return;
//     }

//     if (_invoiceController == null || _invoiceController!.isLoadingProducts) {
//       return;
//     }

//     setState(() {
//       _isSearching = true;
//       _showResults = true;
//     });

//     try {
//       List<Product> results = [];

//       // Búsqueda exacta por código de barras
//       final exactMatch = await _searchByBarcode(query);
//       if (exactMatch != null) {
//         setState(() {
//           _isSearching = false;
//         });
//         _selectProduct(exactMatch);
//         return;
//       }

//       // Búsqueda por SKU
//       final skuMatch = await _searchBySku(query);
//       if (skuMatch != null) {
//         results.add(skuMatch);
//       }

//       // Búsqueda general
//       final searchResults = await _invoiceController!.searchProducts(query);
//       results.addAll(searchResults);

//       // Eliminar duplicados
//       final uniqueResults = <String, Product>{};
//       for (final product in results) {
//         uniqueResults[product.id] = product;
//       }

//       if (mounted) {
//         setState(() {
//           _searchResults.clear();
//           _searchResults.addAll(
//             uniqueResults.values.take(6),
//           ); // Limitar a 6 resultados
//           _isSearching = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _searchResults.clear();
//           _isSearching = false;
//         });
//       }
//     }
//   }

//   Future<Product?> _searchByBarcode(String barcode) async {
//     try {
//       if (_invoiceController == null || _invoiceController!.isLoadingProducts) {
//         return null;
//       }

//       final products = _invoiceController!.availableProducts;
//       return products.firstWhereOrNull(
//         (product) => product.barcode?.toLowerCase() == barcode.toLowerCase(),
//       );
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<Product?> _searchBySku(String sku) async {
//     try {
//       if (_invoiceController == null || _invoiceController!.isLoadingProducts) {
//         return null;
//       }

//       final products = _invoiceController!.availableProducts;
//       return products.firstWhereOrNull(
//         (product) => product.sku.toLowerCase() == sku.toLowerCase(),
//       );
//     } catch (e) {
//       return null;
//     }
//   }

//   void _handleDirectSearch(String query) {
//     if (query.trim().isEmpty) return;

//     if (_searchResults.isNotEmpty) {
//       _selectProduct(_searchResults.first);
//     } else if (_isNumericValue(query)) {
//       // Si es un número y no hay resultados, crear producto sin registrar
//       final price = double.tryParse(query) ?? 0.0;
//       _createUnregisteredProduct(price);
//     }
//   }

//   // ==================== FUNCIONES AUXILIARES ====================

//   bool _isNumericValue(String value) {
//     return double.tryParse(value) != null;
//   }

//   // ✅ NUEVA FUNCIÓN: Crear producto sin registrar - CORREGIDA
//   void _createUnregisteredProduct(double price) {
//     final timestamp = DateTime.now().millisecondsSinceEpoch;

//     // ✅ CORRECCIÓN PRINCIPAL: NO crear Product completo, crear uno simple para el frontend
//     final unregisteredProduct = Product(
//       id: 'temp_$timestamp', // ✅ CAMBIO: usar prefijo 'temp_' en lugar de 'unregistered_'
//       name: 'Producto sin registrar',
//       sku: 'TEMP-$timestamp',
//       description: 'Producto no registrado en inventario',
//       type: ProductType.product,
//       status: ProductStatus.active,
//       stock: 999, // Stock "infinito" para productos temporales
//       minStock: 0,
//       unit: 'pcs',
//       barcode: null,
//       weight: null,
//       length: null,
//       width: null,
//       height: null,
//       images: null,
//       metadata: {
//         'isTemporary': true, // ✅ MARCAR COMO TEMPORAL
//         'originalPrice': price,
//         'createdInPOS': true,
//       },
//       categoryId: 'temp-category',
//       createdById: 'system',
//       prices: [
//         ProductPrice(
//           id: 'temp_price_$timestamp',
//           type: PriceType.price1,
//           name: 'Precio Temporal',
//           amount: price,
//           currency: 'COP',
//           status: PriceStatus.active,
//           validFrom: DateTime.now(),
//           validTo: null,
//           discountPercentage: 0,
//           discountAmount: null,
//           minQuantity: 1,
//           profitMargin: null,
//           notes: 'Precio para producto temporal',
//           productId: 'temp_$timestamp',
//           createdAt: DateTime.now(),
//           updatedAt: DateTime.now(),
//         ),
//       ],
//       category: null,
//       createdBy: null,
//       createdAt: DateTime.now(),
//       updatedAt: DateTime.now(),
//     );

//     print('✅ Producto temporal creado: \$${price.toStringAsFixed(0)}');
//     print('🆔 ID temporal: temp_$timestamp');
//     _selectProduct(unregisteredProduct);
//   }

//   // ==================== SCANNER Y SELECCIÓN ====================

//   Future<void> _openBarcodeScanner() async {
//     try {
//       final scannedCode = await Get.to<String>(
//         () => const BarcodeScannerScreen(),
//       );

//       if (scannedCode != null && scannedCode.isNotEmpty) {
//         _searchController.text = scannedCode;
//         _handleDirectSearch(scannedCode);
//       }
//     } catch (e) {
//       _showError('Error de escáner', 'No se pudo abrir el escáner de códigos');
//     }
//   }

//   void _selectProduct(Product product, {double quantity = 1}) {
//     _debounceTimer?.cancel();

//     // Limpiar búsqueda
//     _searchController.clear();
//     setState(() {
//       _searchResults.clear();
//       _showResults = false;
//       _lastSearchTerm = '';
//       _isSearching = false;
//     });

//     // ✅ MANTENER FOCO ACTIVO PARA CONTINUAR ESCANEANDO
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (mounted) {
//         _focusNode.requestFocus();
//       }
//     });

//     // Notificar selección
//     widget.onProductSelected(product, quantity);
//   }

//   void _showError(String title, String message) {
//     Get.snackbar(
//       title,
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.red.shade100,
//       colorText: Colors.red.shade800,
//       icon: const Icon(Icons.error, color: Colors.red),
//       duration: const Duration(seconds: 3),
//       margin: const EdgeInsets.all(8),
//     );
//   }
// }

// lib/features/invoices/presentation/widgets/product_search_widget.dart
import 'dart:async';
import 'package:baudex_desktop/app/shared/screens/barcode_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_price.dart';
import '../controllers/invoice_form_controller.dart';

class ProductSearchWidget extends StatefulWidget {
  final Function(Product product, double quantity) onProductSelected;
  final bool autoFocus;
  final String? hint;

  const ProductSearchWidget({
    super.key,
    required this.onProductSelected,
    this.autoFocus = false,
    this.hint,
  });

  @override
  State<ProductSearchWidget> createState() => _ProductSearchWidgetState();
}

class _ProductSearchWidgetState extends State<ProductSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  String _lastSearchTerm = '';

  // Timer para debounce
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  InvoiceFormController? get _invoiceController {
    try {
      return Get.find<InvoiceFormController>();
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Foco automático
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de búsqueda
        _buildSimpleSearchField(context),

        // Resultados de búsqueda
        if (_showResults && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSearchResults(context),
        ],

        // ✅ OPCIÓN PARA PRODUCTO TEMPORAL (solo números <= 6 dígitos)
        if (_showResults &&
            _searchResults.isEmpty &&
            !_isSearching &&
            _searchController.text.isNotEmpty &&
            _isTemporaryProduct(_searchController.text)) ...[
          const SizedBox(height: 8),
          _buildUnregisteredProductOption(context),
        ],

        // Mensaje cuando no hay resultados y no es producto temporal
        if (_showResults &&
            _searchResults.isEmpty &&
            !_isSearching &&
            _searchController.text.isNotEmpty &&
            !_isTemporaryProduct(_searchController.text)) ...[
          const SizedBox(height: 8),
          _buildNoResultsMessage(),
        ],
      ],
    );
  }

  Widget _buildSimpleSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Campo de texto principal
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-_.]')),
              ],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText:
                    widget.hint ?? 'Buscar producto, SKU o escribir precio...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                prefixIcon:
                    _isSearching
                        ? Container(
                          padding: const EdgeInsets.all(12),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          ),
                        )
                        : Icon(
                          Icons.search,
                          color:
                              _focusNode.hasFocus
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade500,
                        ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (value) => _handleDirectSearch(value),
              onTap: () {
                if (!_focusNode.hasFocus) {
                  _focusNode.requestFocus();
                }
              },
            ),
          ),

          // Botón de limpiar
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey.shade600),
              onPressed: () {
                _searchController.clear();
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mounted) {
                    _focusNode.requestFocus();
                  }
                });
              },
            ),

          // Botón de escáner (solo en móvil)
          if (context.isMobile)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: _openBarcodeScanner,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ FUNCIÓN MEJORADA: Determinar si es producto temporal
  bool _isTemporaryProduct(String value) {
    final trimmedValue = value.trim();

    // Debe ser solo números
    if (!RegExp(r'^\d+$').hasMatch(trimmedValue)) {
      return false;
    }

    // ✅ NUEVA LÓGICA: Solo números de hasta 6 dígitos son productos temporales
    // Más de 6 dígitos se consideran códigos de barras
    return trimmedValue.length <= 6;
  }

  // ✅ OPCIÓN MEJORADA: Producto sin registrar con diálogo obligatorio
  Widget _buildUnregisteredProductOption(BuildContext context) {
    final searchValue = _searchController.text.trim();
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
          onTap:
              () => _showProductNameDialog(price), // ✅ SIEMPRE mostrar diálogo
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
                        'Precio: \$${price.toStringAsFixed(0)} - Toca para personalizar',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Icono de edición
                Icon(Icons.edit, color: Colors.blue.shade600, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
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
          final product = _searchResults[index];
          return _buildProductTile(context, product);
        },
      ),
    );
  }

  // ✅ VISTA SÚPER SIMPLIFICADA: Solo nombre y precio (SIN STOCK)
  Widget _buildProductTile(BuildContext context, Product product) {
    final hasStock = product.stock > 0;
    final price = product.sellingPrice ?? 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasStock ? () => _selectProduct(product) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Icono simple
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      hasStock
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color:
                      hasStock
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade400,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // ✅ SOLO NOMBRE Y PRECIO (SIN STOCK NI INFORMACIÓN EXTRA)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Solo nombre del producto
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: hasStock ? Colors.black87 : Colors.grey.shade500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Solo precio
                    Text(
                      '\$${price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color:
                            hasStock
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade500,
                      ),
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
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
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
              'No se encontraron productos',
              style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DIÁLOGO OBLIGATORIO: Para editar nombre del producto temporal
  void _showProductNameDialog(double price) {
    final TextEditingController nameController = TextEditingController(
      text: 'Producto sin registrar',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Theme.of(context).primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Personalizar Producto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precio: \$${price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
                maxLength: 50,
                decoration: InputDecoration(
                  hintText: 'Ingresa el nombre del producto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.of(dialogContext).pop();
                    _createUnregisteredProduct(price, value.trim());
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final productName = nameController.text.trim();
                if (productName.isNotEmpty) {
                  Navigator.of(dialogContext).pop();
                  _createUnregisteredProduct(price, productName);
                } else {
                  Get.snackbar(
                    'Campo requerido',
                    'El nombre del producto no puede estar vacío',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red.shade100,
                    colorText: Colors.red.shade800,
                    duration: const Duration(seconds: 2),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  // ==================== LÓGICA DE BÚSQUEDA ====================

  void _onSearchChanged() {
    _debounceTimer?.cancel();

    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showResults = false;
        _isSearching = false;
        _lastSearchTerm = '';
      });
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query == _lastSearchTerm) return;
    _lastSearchTerm = query;

    if (query.length < 2) {
      setState(() {
        _searchResults.clear();
        _showResults = true;
      });
      return;
    }

    // ✅ Si es un producto temporal (número <= 6 dígitos), no buscar en base de datos
    if (_isTemporaryProduct(query)) {
      setState(() {
        _searchResults.clear();
        _showResults = true;
        _isSearching = false;
      });
      return;
    }

    if (_invoiceController == null || _invoiceController!.isLoadingProducts) {
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      List<Product> results = [];

      // ✅ MEJORADO: Solo buscar por código de barras si tiene más de 6 dígitos
      if (RegExp(r'^\d{7,}$').hasMatch(query)) {
        // Es un código de barras (más de 6 dígitos)
        final exactMatch = await _searchByBarcode(query);
        if (exactMatch != null) {
          setState(() {
            _isSearching = false;
          });
          _selectProduct(exactMatch);
          return;
        }
      }

      // Búsqueda por SKU
      final skuMatch = await _searchBySku(query);
      if (skuMatch != null) {
        results.add(skuMatch);
      }

      // Búsqueda general por nombre
      final searchResults = await _invoiceController!.searchProducts(query);
      results.addAll(searchResults);

      // Eliminar duplicados
      final uniqueResults = <String, Product>{};
      for (final product in results) {
        uniqueResults[product.id] = product;
      }

      if (mounted) {
        setState(() {
          _searchResults.clear();
          _searchResults.addAll(uniqueResults.values.take(6));
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
      }
    }
  }

  Future<Product?> _searchByBarcode(String barcode) async {
    try {
      if (_invoiceController == null || _invoiceController!.isLoadingProducts) {
        return null;
      }

      final products = _invoiceController!.availableProducts;
      return products.firstWhereOrNull(
        (product) => product.barcode?.toLowerCase() == barcode.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<Product?> _searchBySku(String sku) async {
    try {
      if (_invoiceController == null || _invoiceController!.isLoadingProducts) {
        return null;
      }

      final products = _invoiceController!.availableProducts;
      return products.firstWhereOrNull(
        (product) => product.sku.toLowerCase() == sku.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  void _handleDirectSearch(String query) {
    if (query.trim().isEmpty) return;

    if (_searchResults.isNotEmpty) {
      _selectProduct(_searchResults.first);
    } else if (_isTemporaryProduct(query)) {
      // ✅ Si es producto temporal, mostrar diálogo
      final price = double.tryParse(query) ?? 0.0;
      _showProductNameDialog(price);
    }
  }

  // ✅ FUNCIÓN MEJORADA: Crear producto temporal con nombre personalizado
  void _createUnregisteredProduct(double price, String productName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final unregisteredProduct = Product(
      id: 'temp_$timestamp',
      name: productName, // ✅ USAR EL NOMBRE PERSONALIZADO
      sku: 'TEMP-$timestamp',
      description: 'Producto temporal creado en POS',
      type: ProductType.product,
      status: ProductStatus.active,
      stock: 999,
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
        'customName': productName,
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
      '✅ Producto temporal creado: "$productName" - \$${price.toStringAsFixed(0)}',
    );
    _selectProduct(unregisteredProduct);
  }

  // ==================== SCANNER Y SELECCIÓN ====================

  Future<void> _openBarcodeScanner() async {
    try {
      final scannedCode = await Get.to<String>(
        () => const BarcodeScannerScreen(),
      );

      if (scannedCode != null && scannedCode.isNotEmpty) {
        _searchController.text = scannedCode;
        _handleDirectSearch(scannedCode);
      }
    } catch (e) {
      _showError('Error de escáner', 'No se pudo abrir el escáner de códigos');
    }
  }

  void _selectProduct(Product product, {double quantity = 1}) {
    _debounceTimer?.cancel();

    // Limpiar búsqueda
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _showResults = false;
      _lastSearchTerm = '';
      _isSearching = false;
    });

    // Mantener foco activo
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });

    // Notificar selección
    widget.onProductSelected(product, quantity);
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
