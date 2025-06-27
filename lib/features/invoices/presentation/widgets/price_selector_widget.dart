// // lib/features/invoices/presentation/widgets/price_selector_widget.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../../../app/core/utils/responsive.dart';
// import '../../../products/domain/entities/product.dart';
// import '../../../products/domain/entities/product_price.dart';

// class PriceSelectorWidget extends StatefulWidget {
//   final Product product;
//   final double currentPrice;
//   final Function(double newPrice) onPriceChanged;

//   const PriceSelectorWidget({
//     super.key,
//     required this.product,
//     required this.currentPrice,
//     required this.onPriceChanged,
//   });

//   @override
//   State<PriceSelectorWidget> createState() => _PriceSelectorWidgetState();
// }

// class _PriceSelectorWidgetState extends State<PriceSelectorWidget> {
//   late TextEditingController _customPriceController;
//   double? _selectedPrice;
//   bool _isCustomPrice = false;

//   @override
//   void initState() {
//     super.initState();
//     _selectedPrice = widget.currentPrice;
//     _customPriceController = TextEditingController(
//       text: widget.currentPrice.toStringAsFixed(2),
//     );
//   }

//   @override
//   void dispose() {
//     _customPriceController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ResponsiveLayout(
//       mobile: _buildMobileDialog(context),
//       tablet: _buildTabletDialog(context),
//       desktop: _buildDesktopDialog(context),
//     );
//   }

//   // ==================== MOBILE LAYOUT ====================
//   Widget _buildMobileDialog(BuildContext context) {
//     return Dialog.fullscreen(
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Seleccionar Precio'),
//           leading: IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//           backgroundColor: Theme.of(context).primaryColor,
//           foregroundColor: Colors.white,
//           elevation: 0,
//         ),
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildProductInfo(context, isMobile: true),
//                         const SizedBox(height: 24),
//                         _buildPricesList(context, isMobile: true),
//                         const SizedBox(height: 24),
//                         _buildCustomPriceSection(context, isMobile: true),
//                       ],
//                     ),
//                   ),
//                 ),
//                 _buildMobileActions(context),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ==================== TABLET LAYOUT ====================
//   Widget _buildTabletDialog(BuildContext context) {
//     return Dialog(
//       child: Container(
//         width: 450,
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.85,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildHeader(context),
//             Flexible(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildProductInfo(context, isMobile: false),
//                     const SizedBox(height: 20),
//                     _buildPricesList(context, isMobile: false),
//                     const SizedBox(height: 20),
//                     _buildCustomPriceSection(context, isMobile: false),
//                   ],
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: _buildDesktopActions(context),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ==================== DESKTOP LAYOUT ====================
//   Widget _buildDesktopDialog(BuildContext context) {
//     return Dialog(
//       child: Container(
//         width: 500,
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.8,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildHeader(context),
//             Flexible(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildProductInfo(context, isMobile: false),
//                     const SizedBox(height: 20),
//                     _buildPricesList(context, isMobile: false),
//                     const SizedBox(height: 20),
//                     _buildCustomPriceSection(context, isMobile: false),
//                   ],
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: _buildDesktopActions(context),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ==================== SHARED COMPONENTS ====================

//   Widget _buildHeader(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Theme.of(context).primaryColor.withOpacity(0.1),
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(12),
//           topRight: Radius.circular(12),
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.attach_money, color: Theme.of(context).primaryColor),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               'Seleccionar Precio',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//           ),
//           IconButton(
//             onPressed: () => Navigator.of(context).pop(),
//             icon: const Icon(Icons.close),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductInfo(BuildContext context, {required bool isMobile}) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.inventory_2, color: Colors.grey.shade600),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.product.name,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: isMobile ? 14 : 16,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'SKU: ${widget.product.sku}',
//                   style: TextStyle(
//                     color: Colors.grey.shade600,
//                     fontSize: isMobile ? 11 : 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPricesList(BuildContext context, {required bool isMobile}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Precios Disponibles:',
//           style: TextStyle(
//             fontSize: isMobile ? 16 : 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 12),

//         if (widget.product.prices?.isNotEmpty == true)
//           ...widget.product.prices!
//               .where((price) => price.isActive && price.isValidNow)
//               .map((price) => _buildPriceOption(price, isMobile: isMobile))
//               .toList()
//         else
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.orange.shade50,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.orange.shade200),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.warning, color: Colors.orange.shade600),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'No hay precios configurados para este producto',
//                     style: TextStyle(fontSize: isMobile ? 14 : 16),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildPriceOption(ProductPrice price, {required bool isMobile}) {
//     final isSelected = !_isCustomPrice && _selectedPrice == price.finalAmount;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: InkWell(
//         onTap: () {
//           setState(() {
//             _isCustomPrice = false;
//             _selectedPrice = price.finalAmount;
//             _customPriceController.text = price.finalAmount.toStringAsFixed(2);
//           });
//         },
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color:
//                 isSelected
//                     ? Theme.of(context).primaryColor.withOpacity(0.1)
//                     : null,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color:
//                   isSelected
//                       ? Theme.of(context).primaryColor
//                       : Colors.grey.shade300,
//               width: isSelected ? 2 : 1,
//             ),
//           ),
//           child: Row(
//             children: [
//               // Radio button
//               Radio<double>(
//                 value: price.finalAmount,
//                 groupValue: _isCustomPrice ? null : _selectedPrice,
//                 onChanged: (value) {
//                   setState(() {
//                     _isCustomPrice = false;
//                     _selectedPrice = value;
//                     _customPriceController.text = value!.toStringAsFixed(2);
//                   });
//                 },
//               ),

//               // Precio info
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             price.type.displayName,
//                             style: TextStyle(
//                               fontWeight: FontWeight.w600,
//                               fontSize: isMobile ? 14 : 15,
//                               color:
//                                   isSelected
//                                       ? Theme.of(context).primaryColor
//                                       : Colors.black,
//                             ),
//                           ),
//                         ),
//                         if (price.hasDiscount) ...[
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.red.shade100,
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               'DESCUENTO',
//                               style: TextStyle(
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.red.shade700,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),

//                     Row(
//                       children: [
//                         Text(
//                           '\${price.finalAmount.toStringAsFixed(2)}',
//                           style: TextStyle(
//                             fontSize: isMobile ? 16 : 18,
//                             fontWeight: FontWeight.bold,
//                             color:
//                                 isSelected
//                                     ? Theme.of(context).primaryColor
//                                     : Colors.green.shade600,
//                           ),
//                         ),

//                         if (price.hasDiscount) ...[
//                           const SizedBox(width: 8),
//                           Text(
//                             '\${price.amount.toStringAsFixed(2)}',
//                             style: TextStyle(
//                               fontSize: isMobile ? 12 : 14,
//                               decoration: TextDecoration.lineThrough,
//                               color: Colors.grey.shade600,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),

//                     if (price.name?.isNotEmpty == true)
//                       Text(
//                         price.name!,
//                         style: TextStyle(
//                           fontSize: isMobile ? 11 : 12,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCustomPriceSection(
//     BuildContext context, {
//     required bool isMobile,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Precio Personalizado:',
//           style: TextStyle(
//             fontSize: isMobile ? 16 : 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 12),

//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.blue.shade50,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.blue.shade200),
//           ),
//           child: Column(
//             children: [
//               Row(
//                 children: [
//                   Checkbox(
//                     value: _isCustomPrice,
//                     onChanged: (value) {
//                       setState(() {
//                         _isCustomPrice = value ?? false;
//                         if (_isCustomPrice) {
//                           _selectedPrice = double.tryParse(
//                             _customPriceController.text,
//                           );
//                         }
//                       });
//                     },
//                   ),
//                   Expanded(
//                     child: Text(
//                       'Usar precio personalizado',
//                       style: TextStyle(fontSize: isMobile ? 14 : 16),
//                     ),
//                   ),
//                 ],
//               ),
//               if (_isCustomPrice) ...[
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: _customPriceController,
//                   keyboardType: const TextInputType.numberWithOptions(
//                     decimal: true,
//                   ),
//                   inputFormatters: [
//                     FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
//                   ],
//                   style: TextStyle(fontSize: isMobile ? 14 : 16),
//                   decoration: InputDecoration(
//                     labelText: 'Precio personalizado',
//                     prefixText: '\$ ',
//                     border: const OutlineInputBorder(),
//                     contentPadding: EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: isMobile ? 8 : 12,
//                     ),
//                   ),
//                   onChanged: (value) {
//                     _selectedPrice = double.tryParse(value);
//                   },
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // ==================== ACTIONS ====================

//   Widget _buildMobileActions(BuildContext context) {
//     return Column(
//       children: [
//         const SizedBox(height: 12),
//         SizedBox(
//           width: double.infinity,
//           height: 48,
//           child: ElevatedButton(
//             onPressed:
//                 _selectedPrice != null && _selectedPrice! > 0
//                     ? () {
//                       widget.onPriceChanged(_selectedPrice!);
//                       Navigator.of(context).pop();
//                     }
//                     : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text(
//               'Aplicar Precio',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           width: double.infinity,
//           height: 48,
//           child: OutlinedButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancelar'),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDesktopActions(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: OutlinedButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Cancelar'),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: ElevatedButton(
//             onPressed:
//                 _selectedPrice != null && _selectedPrice! > 0
//                     ? () {
//                       widget.onPriceChanged(_selectedPrice!);
//                       Navigator.of(context).pop();
//                     }
//                     : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).primaryColor,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Aplicar Precio'),
//           ),
//         ),
//       ],
//     );
//   }
// }

// lib/features/invoices/presentation/widgets/price_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_price.dart';

class PriceSelectorWidget extends StatefulWidget {
  final Product product;
  final double currentPrice;
  final Function(double newPrice) onPriceChanged;

  const PriceSelectorWidget({
    super.key,
    required this.product,
    required this.currentPrice,
    required this.onPriceChanged,
  });

  @override
  State<PriceSelectorWidget> createState() => _PriceSelectorWidgetState();
}

class _PriceSelectorWidgetState extends State<PriceSelectorWidget> {
  late TextEditingController _customPriceController;
  double? _selectedPrice;
  bool _isCustomPrice = false;

  @override
  void initState() {
    super.initState();
    _selectedPrice = widget.currentPrice;
    _customPriceController = TextEditingController(
      text: widget.currentPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _customPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return _buildMobileDialog(context);
    } else {
      return _buildDesktopDialog(context);
    }
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileDialog(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seleccionar Precio'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductInfo(context, isMobile: true),
                        const SizedBox(height: 24),
                        _buildPricesList(context, isMobile: true),
                        const SizedBox(height: 24),
                        _buildCustomPriceSection(context, isMobile: true),
                      ],
                    ),
                  ),
                ),
                _buildMobileActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopDialog(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductInfo(context, isMobile: false),
                    const SizedBox(height: 20),
                    _buildPricesList(context, isMobile: false),
                    const SizedBox(height: 20),
                    _buildCustomPriceSection(context, isMobile: false),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildDesktopActions(context),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SHARED COMPONENTS ====================

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Seleccionar Precio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, {required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${widget.product.sku}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isMobile ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesList(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precios Disponibles:',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),

        if (widget.product.prices?.isNotEmpty == true)
          ...widget.product.prices!
              .where((price) => price.isActive && price.isValidNow)
              .map((price) => _buildPriceOption(price, isMobile: isMobile))
              .toList()
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No hay precios configurados para este producto',
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPriceOption(ProductPrice price, {required bool isMobile}) {
    // ✅ Verificar que el precio sea válido antes de mostrarlo
    if (!_isPriceValid(price.finalAmount)) {
      return const SizedBox.shrink(); // No mostrar precios inválidos
    }

    final priceValue = _getPriceValue(price.finalAmount);
    final isSelected = !_isCustomPrice && _selectedPrice == priceValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _isCustomPrice = false;
            _selectedPrice = priceValue;
            _customPriceController.text = priceValue.toStringAsFixed(2);
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Radio button
              Radio<double>(
                value: priceValue,
                groupValue: _isCustomPrice ? null : _selectedPrice,
                onChanged: (value) {
                  setState(() {
                    _isCustomPrice = false;
                    _selectedPrice = value;
                    _customPriceController.text = value!.toStringAsFixed(2);
                  });
                },
              ),

              // Precio info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            price.type.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 14 : 15,
                              color:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.black,
                            ),
                          ),
                        ),
                        if (price.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DESCUENTO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    Row(
                      children: [
                        Text(
                          '\$${_formatPrice(price.finalAmount)}',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.green.shade600,
                          ),
                        ),

                        if (price.hasDiscount &&
                            _isPriceValid(price.amount)) ...[
                          const SizedBox(width: 8),
                          Text(
                            '\$${_formatPrice(price.amount)}',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (price.name?.isNotEmpty == true)
                      Text(
                        price.name!,
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPriceSection(
    BuildContext context, {
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precio Personalizado:',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _isCustomPrice,
                    onChanged: (value) {
                      setState(() {
                        _isCustomPrice = value ?? false;
                        if (_isCustomPrice) {
                          _selectedPrice = double.tryParse(
                            _customPriceController.text,
                          );
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Usar precio personalizado',
                      style: TextStyle(fontSize: isMobile ? 14 : 16),
                    ),
                  ),
                ],
              ),
              if (_isCustomPrice) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _customPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                  decoration: InputDecoration(
                    labelText: 'Precio personalizado',
                    prefixText: '\$ ',
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: isMobile ? 8 : 12,
                    ),
                  ),
                  onChanged: (value) {
                    _selectedPrice = double.tryParse(value);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==================== ACTIONS ====================

  Widget _buildMobileActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed:
                _selectedPrice != null && _selectedPrice! > 0
                    ? () {
                      widget.onPriceChanged(_selectedPrice!);
                      Navigator.of(context).pop();
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Aplicar Precio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed:
                _selectedPrice != null && _selectedPrice! > 0
                    ? () {
                      widget.onPriceChanged(_selectedPrice!);
                      Navigator.of(context).pop();
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aplicar Precio'),
          ),
        ),
      ],
    );
  }

  // ==================== HELPER METHODS ====================

  /// Formatear precio de forma segura
  String _formatPrice(dynamic price) {
    if (price == null) return '0';

    double priceValue;
    if (price is String) {
      priceValue = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      priceValue = price.toDouble();
    } else {
      priceValue = 0.0;
    }

    return priceValue.toStringAsFixed(0); // Sin decimales para simplificar
  }

  /// Verificar si el precio es válido
  bool _isPriceValid(dynamic price) {
    if (price == null) return false;

    if (price is String) {
      final parsed = double.tryParse(price);
      return parsed != null && parsed > 0;
    } else if (price is num) {
      return price > 0;
    }

    return false;
  }

  /// Obtener valor numérico del precio
  double _getPriceValue(dynamic price) {
    if (price == null) return 0.0;

    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      return price.toDouble();
    }

    return 0.0;
  }
}
