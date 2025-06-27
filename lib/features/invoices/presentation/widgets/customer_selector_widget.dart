// // lib/features/invoices/presentation/widgets/customer_selector_widget.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../customers/domain/entities/customer.dart';
// import '../controllers/invoice_form_controller.dart';

// class CustomerSelectorWidget extends StatefulWidget {
//   final Customer? selectedCustomer;
//   final Function(Customer) onCustomerSelected;
//   final VoidCallback? onClearCustomer;

//   const CustomerSelectorWidget({
//     super.key,
//     this.selectedCustomer,
//     required this.onCustomerSelected,
//     this.onClearCustomer,
//   });

//   @override
//   State<CustomerSelectorWidget> createState() => _CustomerSelectorWidgetState();
// }

// class _CustomerSelectorWidgetState extends State<CustomerSelectorWidget> {
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   final List<Customer> _searchResults = [];
//   bool _isSearching = false;
//   bool _showResults = false;
//   String _lastSearchTerm = '';

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
//             Icon(Icons.person, color: Theme.of(context).primaryColor, size: 24),
//             const SizedBox(width: 8),
//             Text(
//               'Cliente',
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

//         // Cliente actual o selector
//         _buildCurrentCustomerDisplay(context),

//         // Campo de búsqueda (solo visible cuando se busca)
//         if (_showResults) ...[
//           const SizedBox(height: 8),
//           _buildSearchField(context),
//         ],

//         // Resultados de búsqueda
//         if (_showResults && _searchResults.isNotEmpty) ...[
//           const SizedBox(height: 8),
//           _buildSearchResults(context),
//         ],

//         // Mensaje cuando no hay resultados
//         if (_showResults &&
//             _searchResults.isEmpty &&
//             !_isSearching &&
//             _searchController.text.isNotEmpty) ...[
//           const SizedBox(height: 8),
//           _buildNoResultsMessage(),
//         ],
//       ],
//     );
//   }

//   Widget _buildCurrentCustomerDisplay(BuildContext context) {
//     final customer = widget.selectedCustomer;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color:
//               customer?.id == 'consumidor_final'
//                   ? Colors.orange.shade300
//                   : Theme.of(context).primaryColor.withOpacity(0.3),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Información del cliente
//           Row(
//             children: [
//               // Avatar/Icono
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color:
//                       customer?.id == 'consumidor_final'
//                           ? Colors.orange.shade100
//                           : Theme.of(context).primaryColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: Icon(
//                   customer?.id == 'consumidor_final'
//                       ? Icons.storefront
//                       : Icons.person,
//                   color:
//                       customer?.id == 'consumidor_final'
//                           ? Colors.orange.shade600
//                           : Theme.of(context).primaryColor,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),

//               // Información del cliente
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       customer?.displayName ?? 'Sin cliente seleccionado',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     if (customer != null) ...[
//                       Text(
//                         customer.email,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                       if (customer.phone != null) ...[
//                         const SizedBox(height: 2),
//                         Text(
//                           customer.phone!,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey.shade500,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ],
//                 ),
//               ),

//               // Botones de acción
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Botón buscar/cambiar cliente
//                   Material(
//                     color: Theme.of(context).primaryColor,
//                     borderRadius: BorderRadius.circular(8),
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(8),
//                       onTap: _toggleSearch,
//                       child: Container(
//                         padding: const EdgeInsets.all(8),
//                         child: Icon(
//                           _showResults ? Icons.close : Icons.search,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                   ),

//                   // Botón limpiar (solo si no es consumidor final)
//                   if (customer?.id != 'consumidor_final' &&
//                       widget.onClearCustomer != null) ...[
//                     const SizedBox(width: 8),
//                     Material(
//                       color: Colors.orange.shade500,
//                       borderRadius: BorderRadius.circular(8),
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(8),
//                         onTap: () {
//                           widget.onClearCustomer!();
//                           setState(() {
//                             _showResults = false;
//                             _searchController.clear();
//                           });
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           child: const Icon(
//                             Icons.refresh,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ],
//           ),

//           // Etiqueta de consumidor final
//           if (customer?.id == 'consumidor_final') ...[
//             const SizedBox(height: 8),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.orange.shade100,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 'Venta mostrador - Cliente por defecto',
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: Colors.orange.shade800,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchField(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: TextField(
//         controller: _searchController,
//         focusNode: _focusNode,
//         style: const TextStyle(fontSize: 16),
//         decoration: InputDecoration(
//           hintText: 'Buscar cliente por nombre, email o teléfono...',
//           hintStyle: TextStyle(color: Colors.grey.shade500),
//           prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
//           suffixIcon:
//               _searchController.text.isNotEmpty
//                   ? IconButton(
//                     icon: const Icon(Icons.clear),
//                     onPressed: () {
//                       _searchController.clear();
//                       _focusNode.requestFocus();
//                     },
//                   )
//                   : null,
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 12,
//           ),
//         ),
//         onSubmitted: (value) => _handleDirectSearch(value),
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
//           final customer = _searchResults[index];
//           return _buildCustomerTile(context, customer);
//         },
//       ),
//     );
//   }

//   Widget _buildCustomerTile(BuildContext context, Customer customer) {
//     final isSelected = widget.selectedCustomer?.id == customer.id;

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
//       child: Material(
//         color:
//             isSelected
//                 ? Theme.of(context).primaryColor.withOpacity(0.1)
//                 : Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(8),
//           onTap: () => _selectCustomer(customer),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 // Avatar
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).primaryColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Icon(
//                     customer.companyName != null
//                         ? Icons.business
//                         : Icons.person,
//                     color: Theme.of(context).primaryColor,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),

//                 // Información del cliente
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         customer.displayName,
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 15,
//                           color:
//                               isSelected
//                                   ? Theme.of(context).primaryColor
//                                   : Colors.black,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         customer.email,
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey.shade600,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       if (customer.phone != null) ...[
//                         const SizedBox(height: 1),
//                         Text(
//                           customer.phone!,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey.shade500,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),

//                 // Indicador de selección
//                 if (isSelected)
//                   Icon(
//                     Icons.check_circle,
//                     color: Theme.of(context).primaryColor,
//                     size: 24,
//                   ),
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
//           Icon(Icons.person_search, color: Colors.orange.shade600, size: 20),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'No se encontraron clientes',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.orange.shade800,
//                   ),
//                 ),
//                 Text(
//                   'Intenta con otro término de búsqueda',
//                   style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ==================== LÓGICA DE BÚSQUEDA ====================

//   void _toggleSearch() {
//     setState(() {
//       _showResults = !_showResults;
//       if (_showResults) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _focusNode.requestFocus();
//         });
//       } else {
//         _searchController.clear();
//         _searchResults.clear();
//       }
//     });
//   }

//   void _onSearchChanged() async {
//     final query = _searchController.text.trim();

//     if (query.isEmpty) {
//       setState(() {
//         _searchResults.clear();
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
//       });
//       return;
//     }

//     setState(() {
//       _isSearching = true;
//     });

//     try {
//       List<Customer> results = [];

//       // Búsqueda usando el controlador
//       if (_invoiceController != null) {
//         results = await _invoiceController!.searchCustomers(query);
//       } else {
//         // Fallback a búsqueda local
//         results = _searchInAvailableCustomers(query);
//       }

//       setState(() {
//         _searchResults.clear();
//         _searchResults.addAll(results.take(10)); // Limitar a 10 resultados
//         _isSearching = false;
//       });

//       print(
//         '✅ Búsqueda de clientes completada: ${_searchResults.length} encontrados',
//       );
//     } catch (e) {
//       print('❌ Error en búsqueda de clientes: $e');
//       setState(() {
//         _searchResults.clear();
//         _isSearching = false;
//       });
//     }
//   }

//   List<Customer> _searchInAvailableCustomers(String query) {
//     if (_invoiceController == null) return [];

//     final customers = _invoiceController!.availableCustomers;
//     final searchTerm = query.toLowerCase();

//     return customers.where((customer) {
//       return customer.firstName.toLowerCase().contains(searchTerm) ||
//           customer.lastName.toLowerCase().contains(searchTerm) ||
//           (customer.companyName?.toLowerCase().contains(searchTerm) ?? false) ||
//           customer.email.toLowerCase().contains(searchTerm) ||
//           (customer.phone?.contains(searchTerm) ?? false) ||
//           customer.documentNumber.contains(searchTerm);
//     }).toList();
//   }

//   void _handleDirectSearch(String query) {
//     if (query.trim().isEmpty) return;

//     // Si hay resultados, seleccionar el primero
//     if (_searchResults.isNotEmpty) {
//       _selectCustomer(_searchResults.first);
//     }
//   }

//   void _selectCustomer(Customer customer) {
//     // Notificar selección
//     widget.onCustomerSelected(customer);

//     // Ocultar resultados
//     setState(() {
//       _showResults = false;
//       _searchController.clear();
//       _searchResults.clear();
//     });

//     print('👤 Cliente seleccionado: ${customer.displayName}');

//     // Feedback visual
//     Get.snackbar(
//       'Cliente Seleccionado',
//       customer.displayName,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.green.shade100,
//       colorText: Colors.green.shade800,
//       icon: const Icon(Icons.check_circle, color: Colors.green),
//       duration: const Duration(seconds: 2),
//       margin: const EdgeInsets.all(8),
//     );
//   }
// }

// lib/features/invoices/presentation/widgets/customer_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../customers/domain/entities/customer.dart';
import '../controllers/invoice_form_controller.dart';

class CustomerSelectorWidget extends StatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer) onCustomerSelected;
  final VoidCallback? onClearCustomer;

  const CustomerSelectorWidget({
    super.key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    this.onClearCustomer,
  });

  @override
  State<CustomerSelectorWidget> createState() => _CustomerSelectorWidgetState();
}

class _CustomerSelectorWidgetState extends State<CustomerSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Customer> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  String _lastSearchTerm = '';

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
            Icon(Icons.person, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Cliente',
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

        // ✅ SOLUCIÓN: Cliente actual reactivo usando GetBuilder
        GetBuilder<InvoiceFormController>(
          builder: (controller) {
            // Usar el cliente del controlador, no del widget
            final customer = controller.selectedCustomer;
            return _buildCurrentCustomerDisplay(context, customer);
          },
        ),

        // Campo de búsqueda (solo visible cuando se busca)
        if (_showResults) ...[
          const SizedBox(height: 8),
          _buildSearchField(context),
        ],

        // Resultados de búsqueda
        if (_showResults && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSearchResults(context),
        ],

        // Mensaje cuando no hay resultados
        if (_showResults &&
            _searchResults.isEmpty &&
            !_isSearching &&
            _searchController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildNoResultsMessage(),
        ],
      ],
    );
  }

  // ✅ ACTUALIZADO: Método que recibe el customer como parámetro
  Widget _buildCurrentCustomerDisplay(
    BuildContext context,
    Customer? customer,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCustomerBorderColor(customer, context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del cliente
          Row(
            children: [
              // Avatar/Icono
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getCustomerBackgroundColor(customer, context),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getCustomerIcon(customer),
                  color: _getCustomerIconColor(customer, context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Información del cliente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?.displayName ?? 'Cargando cliente...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            customer != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (customer != null) ...[
                      Text(
                        customer.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (customer.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          customer.phone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ] else ...[
                      // ✅ ESTADO DE CARGA
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Botones de acción
              _buildActionButtons(customer),
            ],
          ),

          // Etiqueta de cliente
          if (customer != null) _buildCustomerLabel(customer),
        ],
      ),
    );
  }

  // ✅ NUEVO: Botones de acción separados
  Widget _buildActionButtons(Customer? customer) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón buscar/cambiar cliente
        Material(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap:
                customer != null
                    ? _toggleSearch
                    : null, // Deshabilitado si está cargando
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _showResults ? Icons.close : Icons.search,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),

        // Botón limpiar (solo si no es consumidor final)
        if (customer != null &&
            !_isDefaultCustomer(customer) &&
            widget.onClearCustomer != null) ...[
          const SizedBox(width: 8),
          Material(
            color: Colors.orange.shade500,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                widget.onClearCustomer!();
                setState(() {
                  _showResults = false;
                  _searchController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.refresh, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ✅ NUEVO: Etiqueta del cliente
  Widget _buildCustomerLabel(Customer customer) {
    if (_isDefaultCustomer(customer)) {
      return Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Venta mostrador - Cliente por defecto',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Cliente seleccionado',
            style: TextStyle(
              fontSize: 11,
              color: Colors.green.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ NUEVOS: Métodos helper para colores e iconos
  Color _getCustomerBorderColor(Customer? customer, BuildContext context) {
    if (customer == null) return Colors.grey.shade300;
    if (_isDefaultCustomer(customer)) return Colors.orange.shade300;
    return Theme.of(context).primaryColor.withOpacity(0.3);
  }

  Color _getCustomerBackgroundColor(Customer? customer, BuildContext context) {
    if (customer == null) return Colors.grey.shade100;
    if (_isDefaultCustomer(customer)) return Colors.orange.shade100;
    return Theme.of(context).primaryColor.withOpacity(0.1);
  }

  IconData _getCustomerIcon(Customer? customer) {
    if (customer == null) return Icons.person_outline;
    if (_isDefaultCustomer(customer)) return Icons.storefront;
    return Icons.person;
  }

  Color _getCustomerIconColor(Customer? customer, BuildContext context) {
    if (customer == null) return Colors.grey.shade400;
    if (_isDefaultCustomer(customer)) return Colors.orange.shade600;
    return Theme.of(context).primaryColor;
  }

  bool _isDefaultCustomer(Customer customer) {
    return customer.id == 'consumidor_final' ||
        customer.id == '3c605381-362b-454a-8c0f-b3c055aa568d';
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Buscar cliente por nombre, email o teléfono...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
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
          final customer = _searchResults[index];
          return _buildCustomerTile(context, customer);
        },
      ),
    );
  }

  Widget _buildCustomerTile(BuildContext context, Customer customer) {
    // ✅ CORRECCIÓN: Usar el cliente del controlador para comparación
    return GetBuilder<InvoiceFormController>(
      builder: (controller) {
        final isSelected = controller.selectedCustomer?.id == customer.id;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Material(
            color:
                isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _selectCustomer(customer),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        customer.companyName != null
                            ? Icons.business
                            : Icons.person,
                        color: Theme.of(context).primaryColor,
                        size: 20,
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
                                      : Colors.black,
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
                          if (customer.phone != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              customer.phone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Indicador de selección
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
          Icon(Icons.person_search, color: Colors.orange.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No se encontraron clientes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                Text(
                  'Intenta con otro término de búsqueda',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LÓGICA DE BÚSQUEDA ====================

  void _toggleSearch() {
    setState(() {
      _showResults = !_showResults;
      if (_showResults) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      } else {
        _searchController.clear();
        _searchResults.clear();
      }
    });
  }

  void _onSearchChanged() async {
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

      setState(() {
        _searchResults.clear();
        _searchResults.addAll(results.take(10)); // Limitar a 10 resultados
        _isSearching = false;
      });

      print(
        '✅ Búsqueda de clientes completada: ${_searchResults.length} encontrados',
      );
    } catch (e) {
      print('❌ Error en búsqueda de clientes: $e');
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
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

    // Ocultar resultados
    setState(() {
      _showResults = false;
      _searchController.clear();
      _searchResults.clear();
    });

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
}
