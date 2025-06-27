// // lib/features/invoices/presentation/widgets/product_search_widget.dart
// import 'package:baudex_desktop/app/shared/screens/barcode_scanner_screen.dart';
// import 'package:baudex_desktop/features/products/domain/entities/product_price.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../../app/core/utils/responsive.dart';
// import '../../../../app/shared/widgets/custom_text_field.dart';
// import '../../../products/domain/entities/product.dart';
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

//   // Obtener controlador de facturas para acceso a productos
//   InvoiceFormController? get _invoiceController {
//     try {
//       return Get.find<InvoiceFormController>();
//     } catch (e) {
//       print('⚠️ InvoiceFormController no encontrado: $e');
//       return null;
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_onSearchChanged);

//     // Auto focus al abrir la pantalla
//     if (widget.autoFocus) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _focusNode.requestFocus();
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header
//         Row(
//           children: [
//             Icon(
//               Icons.qr_code_scanner,
//               color: Theme.of(context).primaryColor,
//               size: 24,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               'Buscar Productos',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//             const Spacer(),
//             if (_isSearching)
//               const SizedBox(
//                 width: 16,
//                 height: 16,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//           ],
//         ),
//         const SizedBox(height: 12),

//         // Campo de búsqueda principal con escáner
//         _buildSearchField(context),

//         // Resultados de búsqueda
//         if (_showResults && _searchResults.isNotEmpty) ...[
//           const SizedBox(height: 8),
//           _buildSearchResults(context),
//         ],

//         // Mensaje cuando no hay resultados
//         if (_showResults && _searchResults.isEmpty && !_isSearching) ...[
//           const SizedBox(height: 8),
//           _buildNoResultsMessage(),
//         ],

//         // Sugerencias rápidas cuando no hay búsqueda
//         if (!_showResults && _searchController.text.isEmpty) ...[
//           const SizedBox(height: 16),
//           _buildQuickSuggestions(context),
//         ],
//       ],
//     );
//   }

//   Widget _buildSearchField(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
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
//             blurRadius: 8,
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
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               decoration: InputDecoration(
//                 hintText: widget.hint ?? 'Escanea código o busca por nombre...',
//                 hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
//                 prefixIcon: Container(
//                   padding: const EdgeInsets.all(12),
//                   child: Icon(
//                     Icons.search,
//                     color: Theme.of(context).primaryColor,
//                     size: 24,
//                   ),
//                 ),
//                 border: InputBorder.none,
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 16,
//                 ),
//               ),
//               onSubmitted: (value) => _handleDirectSearch(value),
//             ),
//           ),

//           // Botón de limpiar (cuando hay texto)
//           if (_searchController.text.isNotEmpty)
//             IconButton(
//               icon: const Icon(Icons.clear),
//               onPressed: () {
//                 _searchController.clear();
//                 _focusNode.requestFocus();
//               },
//             ),

//           // Botón de escáner (solo en móvil)
//           if (context.isMobile)
//             Container(
//               margin: const EdgeInsets.only(right: 8),
//               child: Material(
//                 color: Theme.of(context).primaryColor,
//                 borderRadius: BorderRadius.circular(8),
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(8),
//                   onTap: _openBarcodeScanner,
//                   child: Container(
//                     padding: const EdgeInsets.all(12),
//                     child: const Icon(
//                       Icons.camera_alt,
//                       color: Colors.white,
//                       size: 24,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // Icono de código de barras (desktop)
//           if (!context.isMobile)
//             Container(
//               padding: const EdgeInsets.all(8),
//               margin: const EdgeInsets.only(right: 8),
//               child: Icon(Icons.qr_code, color: Colors.grey.shade400),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchResults(BuildContext context) {
//     return Container(
//       constraints: const BoxConstraints(maxHeight: 300),
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

//   Widget _buildProductTile(BuildContext context, Product product) {
//     final hasStock = product.stock > 0;
//     final price = product.sellingPrice ?? 0.0;

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//       child: Material(
//         color: hasStock ? Colors.white : Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(8),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(8),
//           onTap: hasStock ? () => _selectProduct(product) : null,
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 // Icono de producto
//                 Container(
//                   width: 50,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     color:
//                         hasStock
//                             ? Theme.of(context).primaryColor.withOpacity(0.1)
//                             : Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     Icons.inventory_2,
//                     color:
//                         hasStock
//                             ? Theme.of(context).primaryColor
//                             : Colors.grey.shade400,
//                   ),
//                 ),
//                 const SizedBox(width: 12),

//                 // Información del producto
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Nombre del producto
//                       Text(
//                         product.name,
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                           color: hasStock ? Colors.black : Colors.grey.shade500,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 4),

//                       // SKU y código de barras
//                       Row(
//                         children: [
//                           Text(
//                             'SKU: ${product.sku}',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                           if (product.barcode != null) ...[
//                             const SizedBox(width: 8),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 6,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue.shade50,
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 'CB: ${product.barcode}',
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   color: Colors.blue.shade700,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                       const SizedBox(height: 4),

//                       // Precio y stock
//                       Row(
//                         children: [
//                           Text(
//                             '\$${price.toStringAsFixed(0)}',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                               color:
//                                   hasStock
//                                       ? Theme.of(context).primaryColor
//                                       : Colors.grey.shade500,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color:
//                                   hasStock
//                                       ? Colors.green.shade100
//                                       : Colors.red.shade100,
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Text(
//                               hasStock
//                                   ? 'Stock: ${product.stock}'
//                                   : 'Sin stock',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w600,
//                                 color:
//                                     hasStock
//                                         ? Colors.green.shade800
//                                         : Colors.red.shade800,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Icono de acción
//                 Icon(
//                   hasStock ? Icons.add_circle : Icons.block,
//                   color:
//                       hasStock
//                           ? Theme.of(context).primaryColor
//                           : Colors.red.shade400,
//                   size: 28,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNoResultsMessage() {
//     return Container(
//       padding: const EdgeInsets.all(16),
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
//               'No se encontraron productos para "${_searchController.text}"',
//               style: TextStyle(fontSize: 14, color: Colors.orange.shade800),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickSuggestions(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Productos Populares',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.grey.shade700,
//             fontSize: 14,
//           ),
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           height: 80,
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             children:
//                 _getPopularProducts().map((product) {
//                   return Container(
//                     width: 120,
//                     margin: const EdgeInsets.only(right: 8),
//                     child: _buildQuickProductCard(context, product),
//                   );
//                 }).toList(),
//           ),
//         ),
//         const SizedBox(height: 16),

//         // Tips de uso
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.blue.shade50,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.blue.shade200),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 20),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   context.isMobile
//                       ? 'Tip: Toca el botón de cámara para escanear códigos'
//                       : 'Tip: Escanea el código de barras o escribe el nombre',
//                   style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildQuickProductCard(BuildContext context, Product product) {
//     return GestureDetector(
//       onTap: () => _selectProduct(product),
//       child: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.inventory_2,
//               color: Theme.of(context).primaryColor,
//               size: 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               product.name,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 2),
//             Text(
//               '\$${product.sellingPrice?.toStringAsFixed(0) ?? '0'}',
//               style: TextStyle(
//                 fontSize: 10,
//                 color: Theme.of(context).primaryColor,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ==================== LÓGICA DE BÚSQUEDA ====================

//   void _onSearchChanged() async {
//     final query = _searchController.text.trim();

//     if (query.isEmpty) {
//       setState(() {
//         _searchResults.clear();
//         _showResults = false;
//         _isSearching = false;
//       });
//       return;
//     }

//     // Evitar búsquedas repetidas
//     if (query == _lastSearchTerm) return;
//     _lastSearchTerm = query;

//     // Búsqueda mínima de 2 caracteres
//     if (query.length < 2) {
//       setState(() {
//         _searchResults.clear();
//         _showResults = false;
//       });
//       return;
//     }

//     setState(() {
//       _isSearching = true;
//     });

//     try {
//       List<Product> results = [];

//       // 1. Búsqueda exacta por código de barras (prioritaria)
//       final exactMatch = await _searchByBarcode(query);
//       if (exactMatch != null) {
//         setState(() {
//           _isSearching = false;
//         });
//         _selectProduct(exactMatch);
//         return;
//       }

//       // 2. Búsqueda por SKU exacto
//       final skuMatch = await _searchBySku(query);
//       if (skuMatch != null) {
//         results.add(skuMatch);
//       }

//       // 3. Búsqueda general por nombre
//       if (_invoiceController != null) {
//         final searchResults = await _invoiceController!.searchProducts(query);
//         results.addAll(searchResults);
//       } else {
//         // Fallback a productos mock
//         results.addAll(_searchInMockProducts(query));
//       }

//       // Eliminar duplicados y limitar resultados
//       final uniqueResults = <String, Product>{};
//       for (final product in results) {
//         uniqueResults[product.id] = product;
//       }

//       setState(() {
//         _searchResults.clear();
//         _searchResults.addAll(uniqueResults.values.take(8));
//         _showResults = true;
//         _isSearching = false;
//       });

//       print(
//         '✅ Búsqueda completada: ${_searchResults.length} productos encontrados',
//       );
//     } catch (e) {
//       print('❌ Error en búsqueda de productos: $e');
//       setState(() {
//         _searchResults.clear();
//         _showResults = true; // Mostrar mensaje de "sin resultados"
//         _isSearching = false;
//       });
//     }
//   }

//   Future<Product?> _searchByBarcode(String barcode) async {
//     try {
//       // Buscar producto por código de barras exacto
//       if (_invoiceController != null) {
//         final products = _invoiceController!.availableProducts;
//         return products.firstWhereOrNull(
//           (product) => product.barcode?.toLowerCase() == barcode.toLowerCase(),
//         );
//       }

//       // Fallback a mock
//       return _getMockProducts().firstWhereOrNull(
//         (product) => product.barcode?.toLowerCase() == barcode.toLowerCase(),
//       );
//     } catch (e) {
//       print('❌ Error en búsqueda por código de barras: $e');
//       return null;
//     }
//   }

//   Future<Product?> _searchBySku(String sku) async {
//     try {
//       if (_invoiceController != null) {
//         final products = _invoiceController!.availableProducts;
//         return products.firstWhereOrNull(
//           (product) => product.sku.toLowerCase() == sku.toLowerCase(),
//         );
//       }

//       return _getMockProducts().firstWhereOrNull(
//         (product) => product.sku.toLowerCase() == sku.toLowerCase(),
//       );
//     } catch (e) {
//       print('❌ Error en búsqueda por SKU: $e');
//       return null;
//     }
//   }

//   List<Product> _searchInMockProducts(String query) {
//     final mockProducts = _getMockProducts();
//     final searchTerm = query.toLowerCase();

//     return mockProducts.where((product) {
//       return product.name.toLowerCase().contains(searchTerm) ||
//           product.sku.toLowerCase().contains(searchTerm) ||
//           (product.description?.toLowerCase().contains(searchTerm) ?? false) ||
//           (product.barcode?.toLowerCase().contains(searchTerm) ?? false);
//     }).toList();
//   }

//   void _handleDirectSearch(String query) {
//     if (query.trim().isEmpty) return;

//     // Si hay resultados, seleccionar el primero
//     if (_searchResults.isNotEmpty) {
//       _selectProduct(_searchResults.first);
//     }
//   }

//   // ==================== SCANNER FUNCTIONALITY ====================

//   Future<void> _openBarcodeScanner() async {
//     try {
//       print('📱 Abriendo escáner de códigos de barras...');

//       final scannedCode = await Get.to<String>(
//         () => const BarcodeScannerScreen(),
//       );

//       if (scannedCode != null && scannedCode.isNotEmpty) {
//         print('🔍 Código escaneado: $scannedCode');
//         _searchController.text = scannedCode;

//         // Trigger búsqueda automática después del escaneo
//         _handleDirectSearch(scannedCode);
//       }
//     } catch (e) {
//       print('❌ Error al abrir escáner: $e');
//       _showError('Error de escáner', 'No se pudo abrir el escáner de códigos');
//     }
//   }

//   void _selectProduct(Product product, {double quantity = 1}) {
//     // Limpiar búsqueda
//     _searchController.clear();
//     setState(() {
//       _searchResults.clear();
//       _showResults = false;
//       _lastSearchTerm = '';
//     });

//     // Mantener el focus para continuar escaneando
//     _focusNode.requestFocus();

//     // Notificar selección usando la nueva funcionalidad del controlador
//     widget.onProductSelected(product, quantity);

//     print('✅ Producto seleccionado: ${product.name}');
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

//   // ==================== DATOS MOCK ====================

//   List<Product> _getPopularProducts() {
//     final allProducts = _getMockProducts();
//     return allProducts.take(4).toList();
//   }

//   List<Product> _getMockProducts() {
//     // Usar los mismos productos mock del controlador
//     if (_invoiceController != null &&
//         _invoiceController!.availableProducts.isNotEmpty) {
//       return _invoiceController!.availableProducts;
//     }

//     // Fallback a productos básicos
//     return [
//       Product(
//         id: '1',
//         name: 'Coca Cola 350ml',
//         sku: 'COCA-350',
//         barcode: '7501055363181',
//         type: ProductType.product,
//         status: ProductStatus.active,
//         stock: 50,
//         minStock: 10,
//         unit: 'pcs',
//         categoryId: 'bebidas',
//         createdById: 'system',
//         prices: [
//           ProductPrice(
//             id: '1',
//             productId: '1',
//             type: PriceType.price1,
//             amount: 2500.0,
//             currency: 'COP',
//             status: PriceStatus.active,
//             discountPercentage: 0.0,
//             minQuantity: 1.0,
//             createdAt: DateTime.now(),
//             updatedAt: DateTime.now(),
//           ),
//         ],
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//       ),
//       Product(
//         id: '2',
//         name: 'Pan Integral',
//         sku: 'PAN-INT-001',
//         barcode: '7702001234567',
//         type: ProductType.product,
//         status: ProductStatus.active,
//         stock: 25,
//         minStock: 5,
//         unit: 'pcs',
//         categoryId: 'panaderia',
//         createdById: 'system',
//         prices: [
//           ProductPrice(
//             id: '2',
//             productId: '2',
//             type: PriceType.price1,
//             amount: 4500.0,
//             currency: 'COP',
//             status: PriceStatus.active,
//             discountPercentage: 0.0,
//             minQuantity: 1.0,
//             createdAt: DateTime.now(),
//             updatedAt: DateTime.now(),
//           ),
//         ],
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//       ),
//     ];
//   }
// }

// lib/features/invoices/presentation/widgets/product_search_widget.dart
import 'package:baudex_desktop/app/shared/screens/barcode_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../products/domain/entities/product.dart';
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

  // Obtener controlador de facturas para acceso a productos
  InvoiceFormController? get _invoiceController {
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

    // Auto focus al abrir la pantalla
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
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
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Buscar Productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Spacer(),
            if (_isSearching)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Campo de búsqueda principal con escáner
        _buildSearchField(context),

        // Resultados de búsqueda
        if (_showResults && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSearchResults(context),
        ],

        // Mensaje cuando no hay resultados
        if (_showResults && _searchResults.isEmpty && !_isSearching) ...[
          const SizedBox(height: 8),
          _buildNoResultsMessage(),
        ],

        // ✅ NUEVO: Tips de uso cuando no hay búsqueda (sin productos populares)
        if (!_showResults && _searchController.text.isEmpty) ...[
          const SizedBox(height: 16),
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
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: widget.hint ?? 'Escanea código o busca por nombre...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
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
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final product = _searchResults[index];
          return _buildProductTile(context, product);
        },
      ),
    );
  }

  Widget _buildProductTile(BuildContext context, Product product) {
    final hasStock = product.stock > 0;
    final price = product.sellingPrice ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: hasStock ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: hasStock ? () => _selectProduct(product) : null,
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
                          color: hasStock ? Colors.black : Colors.grey.shade500,
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
                            '\$${price.toStringAsFixed(0)}',
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
                                  ? 'Stock: ${product.stock}'
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

  // ✅ NUEVO: Tips de uso sin productos populares
  Widget _buildUsageTips(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats de productos disponibles (si hay)
        GetBuilder<InvoiceFormController>(
          builder: (controller) {
            if (controller.availableProducts.isNotEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${controller.availableProducts.length} productos disponibles en el sistema',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: 12),

        // Tips de uso
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Cómo buscar productos:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTipItem(
                context,
                context.isMobile
                    ? 'Toca el botón de cámara para escanear códigos'
                    : 'Ingresa el código de barras completo',
                Icons.qr_code_scanner,
              ),
              _buildTipItem(
                context,
                'Escribe el SKU del producto',
                Icons.label,
              ),
              _buildTipItem(
                context,
                'Busca por nombre del producto',
                Icons.search,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(BuildContext context, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LÓGICA DE BÚSQUEDA ====================

  void _onSearchChanged() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showResults = false;
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
        _showResults = false;
      });
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

      // 3. Búsqueda general usando el controlador (datos reales)
      if (_invoiceController != null) {
        final searchResults = await _invoiceController!.searchProducts(query);
        results.addAll(searchResults);
      }

      // Eliminar duplicados y limitar resultados
      final uniqueResults = <String, Product>{};
      for (final product in results) {
        uniqueResults[product.id] = product;
      }

      setState(() {
        _searchResults.clear();
        _searchResults.addAll(uniqueResults.values.take(8));
        _showResults = true;
        _isSearching = false;
      });

      print(
        '✅ Búsqueda completada: ${_searchResults.length} productos encontrados',
      );
    } catch (e) {
      print('❌ Error en búsqueda de productos: $e');
      setState(() {
        _searchResults.clear();
        _showResults = true; // Mostrar mensaje de "sin resultados"
        _isSearching = false;
      });
    }
  }

  Future<Product?> _searchByBarcode(String barcode) async {
    try {
      // Buscar producto por código de barras exacto en datos reales
      if (_invoiceController != null) {
        final products = _invoiceController!.availableProducts;
        return products.firstWhereOrNull(
          (product) => product.barcode?.toLowerCase() == barcode.toLowerCase(),
        );
      }
      return null;
    } catch (e) {
      print('❌ Error en búsqueda por código de barras: $e');
      return null;
    }
  }

  Future<Product?> _searchBySku(String sku) async {
    try {
      if (_invoiceController != null) {
        final products = _invoiceController!.availableProducts;
        return products.firstWhereOrNull(
          (product) => product.sku.toLowerCase() == sku.toLowerCase(),
        );
      }
      return null;
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
    }
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
    // Limpiar búsqueda
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _showResults = false;
      _lastSearchTerm = '';
    });

    // Mantener el focus para continuar escaneando
    _focusNode.requestFocus();

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
