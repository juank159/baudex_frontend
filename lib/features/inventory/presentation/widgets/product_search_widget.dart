// lib/features/inventory/presentation/widgets/product_search_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../products/domain/entities/product.dart';

class ProductSearchWidget extends StatefulWidget {
  final String hintText;
  final Function(Product) onProductSelected;
  final Future<List<Product>> Function(String) searchFunction;
  final Product? initialProduct;

  const ProductSearchWidget({
    super.key,
    required this.hintText,
    required this.onProductSelected,
    required this.searchFunction,
    this.initialProduct,
  });

  @override
  State<ProductSearchWidget> createState() => _ProductSearchWidgetState();
}

class _ProductSearchWidgetState extends State<ProductSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  
  // Add keyboard state management to prevent conflicts
  final Map<LogicalKeyboardKey, bool> _pressedKeys = <LogicalKeyboardKey, bool>{};
  
  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _controller.text = widget.initialProduct!.name;
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Add a small delay to allow tap events to complete before hiding results
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_focusNode.hasFocus) {
            setState(() {
              _showResults = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _pressedKeys.clear(); // Clear keyboard state on dispose
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      final results = await widget.searchFunction(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _selectProduct(Product product) {
    // Update UI immediately
    setState(() {
      _showResults = false;
    });
    
    // Update controller and call callback
    _controller.text = product.name;
    _focusNode.unfocus();
    
    // Call the product selection callback
    widget.onProductSelected(product);
    
    print('🔍 ProductSearchWidget: Product selected - ${product.name} (${product.id})');
  }

  // Key event handler to prevent keyboard state conflicts
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    try {
      if (event is KeyDownEvent) {
        if (_pressedKeys[event.logicalKey] == true) {
          // Key is already pressed, ignore this event
          return KeyEventResult.handled;
        }
        _pressedKeys[event.logicalKey] = true;
      } else if (event is KeyUpEvent) {
        _pressedKeys[event.logicalKey] = false;
      }
      return KeyEventResult.ignored; // Allow normal processing
    } catch (e) {
      // Clear state on any error
      _pressedKeys.clear();
      return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Focus(
          onKeyEvent: _handleKeyEvent,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _searchResults = [];
                              _showResults = false;
                            });
                            // Clear keyboard state when clearing field
                            _pressedKeys.clear();
                          },
                        )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
            ),
            onChanged: _performSearch,
            onTap: () {
              if (_searchResults.isNotEmpty) {
                setState(() {
                  _showResults = true;
                });
              }
            },
          ),
        ),
        if (_showResults && (_searchResults.isNotEmpty || _isSearching))
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(AppDimensions.paddingMedium),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: AppDimensions.paddingSmall),
                          Text('Buscando...'),
                        ],
                      ),
                    ),
                  )
                : _searchResults.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(AppDimensions.paddingMedium),
                        child: Center(
                          child: Text(
                            'No se encontraron productos',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          return ListTile(
                            title: Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.sku.isNotEmpty)
                                  Text(
                                    'SKU: ${product.sku}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (product.category?.name != null && product.category!.name.isNotEmpty)
                                  Text(
                                    'Categoría: ${product.category!.name}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: product.costPrice != null
                                ? Text(
                                    '\$${product.costPrice!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                            onTap: () => _selectProduct(product),
                            dense: true,
                          );
                        },
                      ),
          ),
      ],
    );
  }
}