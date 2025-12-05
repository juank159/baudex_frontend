// lib/features/inventory/presentation/widgets/futuristic_product_search_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_price.dart';

class ProductWithStock {
  final Product product;
  final int availableStock;

  const ProductWithStock({required this.product, required this.availableStock});
}

class FuturisticProductSearchWidget extends StatefulWidget {
  final String hintText;
  final Future<List<Product>> Function(String) searchFunction;
  final Function(Product) onProductSelected;
  final Future<int> Function(String productId)? getStockFunction;

  const FuturisticProductSearchWidget({
    super.key,
    required this.hintText,
    required this.searchFunction,
    required this.onProductSelected,
    this.getStockFunction,
  });

  @override
  State<FuturisticProductSearchWidget> createState() =>
      _FuturisticProductSearchWidgetState();
}

class _FuturisticProductSearchWidgetState
    extends State<FuturisticProductSearchWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  List<ProductWithStock> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.elasticCurve,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;

        // Responsive values
        final iconSize =
            isMobile
                ? 14.0
                : isTablet
                ? 15.0
                : 16.0;
        final textFontSize =
            isMobile
                ? 14.0
                : isTablet
                ? 15.0
                : 16.0;
        final hintFontSize =
            isMobile
                ? 13.0
                : isTablet
                ? 14.0
                : 15.0;
        final borderRadius = isMobile ? 10.0 : 12.0;
        final paddingHorizontal = isMobile ? 14.0 : 16.0;
        final paddingVertical = isMobile ? 14.0 : 16.0;
        final maxHeight =
            isMobile
                ? 250.0
                : isTablet
                ? 280.0
                : 300.0;

        return Column(
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        color:
                            _selectedProduct != null
                                ? ElegantLightTheme.successGradient.colors.first
                                    .withOpacity(0.5)
                                : ElegantLightTheme.textSecondary.withOpacity(
                                  0.2,
                                ),
                        width: _selectedProduct != null ? 2 : 1,
                      ),
                      boxShadow:
                          _focusNode.hasFocus
                              ? [
                                BoxShadow(
                                  color: ElegantLightTheme.primaryBlue
                                      .withOpacity(0.2),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ]
                              : null,
                    ),
                    child: TextFormField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: textFontSize,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: ElegantLightTheme.textSecondary.withOpacity(
                            0.6,
                          ),
                          fontWeight: FontWeight.normal,
                          fontSize: hintFontSize,
                        ),
                        prefixIcon: Container(
                          margin: EdgeInsets.all(isMobile ? 6 : 8),
                          padding: EdgeInsets.all(isMobile ? 6 : 8),
                          decoration: BoxDecoration(
                            gradient:
                                _selectedProduct != null
                                    ? ElegantLightTheme.successGradient
                                    : ElegantLightTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _selectedProduct != null
                                ? Icons.check
                                : Icons.search,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ),
                        suffixIcon:
                            _selectedProduct != null
                                ? IconButton(
                                  onPressed: _clearSelection,
                                  icon: Icon(
                                    Icons.clear,
                                    color: ElegantLightTheme.textSecondary,
                                    size: iconSize + 2,
                                  ),
                                )
                                : _isSearching
                                ? Container(
                                  margin: EdgeInsets.all(isMobile ? 10 : 12),
                                  width: isMobile ? 18 : 20,
                                  height: isMobile ? 18 : 20,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      ElegantLightTheme.primaryBlue,
                                    ),
                                  ),
                                )
                                : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: paddingHorizontal,
                          vertical: paddingVertical,
                        ),
                      ),
                      onChanged:
                          _selectedProduct == null ? _onSearchChanged : null,
                      readOnly: _selectedProduct != null,
                    ),
                  ),
                );
              },
            ),
            if (_showResults && _searchResults.isNotEmpty)
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: EdgeInsets.only(top: isMobile ? 6 : 8),
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.cardGradient,
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(
                          color: ElegantLightTheme.textSecondary.withOpacity(
                            0.2,
                          ),
                          width: 1,
                        ),
                        boxShadow: ElegantLightTheme.elevatedShadow,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder:
                            (context, index) => Divider(
                              height: 1,
                              color: ElegantLightTheme.textSecondary
                                  .withOpacity(0.1),
                            ),
                        itemBuilder: (context, index) {
                          final productWithStock = _searchResults[index];
                          return _buildProductOption(
                            productWithStock,
                            isMobile,
                            isTablet,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildProductOption(
    ProductWithStock productWithStock,
    bool isMobile,
    bool isTablet,
  ) {
    final product = productWithStock.product;
    final stock = productWithStock.availableStock;
    final hasStock = stock > 0;

    // Responsive values
    final padding =
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 16.0;
    final iconSize = isMobile ? 14.0 : 16.0;
    final iconPadding = isMobile ? 6.0 : 8.0;
    final spacing = isMobile ? 8.0 : 12.0;
    final titleFontSize = isMobile ? 13.0 : 14.0;
    final subtitleFontSize = isMobile ? 11.0 : 12.0;
    final priceFontSize = isMobile ? 9.0 : 10.0;
    final pricePadding = isMobile ? 4.0 : 6.0;
    final arrowSize = isMobile ? 14.0 : 16.0;

    return GestureDetector(
      onTap: hasStock ? () => _selectProduct(product) : null,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: hasStock ? Colors.transparent : Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border:
              hasStock
                  ? null
                  : Border.all(color: Colors.red.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                gradient:
                    hasStock
                        ? ElegantLightTheme.infoGradient
                        : ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasStock ? Icons.inventory_2 : Icons.block,
                color: Colors.white,
                size: iconSize,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  const SizedBox(height: 2),
                  isMobile
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.inventory,
                                size: subtitleFontSize,
                                color:
                                    stock > 0
                                        ? ElegantLightTheme
                                            .successGradient
                                            .colors
                                            .first
                                        : ElegantLightTheme
                                            .errorGradient
                                            .colors
                                            .first,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stock: $stock unidades',
                                style: TextStyle(
                                  color:
                                      stock > 0
                                          ? ElegantLightTheme
                                              .successGradient
                                              .colors
                                              .first
                                          : ElegantLightTheme
                                              .errorGradient
                                              .colors
                                              .first,
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ],
                          ),
                          if (product.sellingPrice != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: pricePadding,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ElegantLightTheme
                                    .successGradient
                                    .colors
                                    .first
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                AppFormatters.formatCurrency(
                                  product.sellingPrice!,
                                ),
                                style: TextStyle(
                                  color:
                                      ElegantLightTheme
                                          .successGradient
                                          .colors
                                          .first,
                                  fontSize: priceFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.inventory,
                                  size: subtitleFontSize,
                                  color:
                                      stock > 0
                                          ? ElegantLightTheme
                                              .successGradient
                                              .colors
                                              .first
                                          : ElegantLightTheme
                                              .errorGradient
                                              .colors
                                              .first,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Stock: $stock unidades',
                                  style: TextStyle(
                                    color:
                                        stock > 0
                                            ? ElegantLightTheme
                                                .successGradient
                                                .colors
                                                .first
                                            : ElegantLightTheme
                                                .errorGradient
                                                .colors
                                                .first,
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ],
                            ),
                          ),
                          if (product.sellingPrice != null) ...[
                            SizedBox(width: spacing),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: pricePadding,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ElegantLightTheme
                                    .successGradient
                                    .colors
                                    .first
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                AppFormatters.formatCurrency(
                                  product.sellingPrice!,
                                ),
                                style: TextStyle(
                                  color:
                                      ElegantLightTheme
                                          .successGradient
                                          .colors
                                          .first,
                                  fontSize: priceFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: ElegantLightTheme.textSecondary,
              size: arrowSize,
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _showResults = false;
        _searchResults = [];
      });
      return;
    }

    if (value.trim().length < 2) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Use real search function provided by parent widget
      final products = await widget.searchFunction(value.trim());

      // Get stock information for each product if the function is provided
      List<ProductWithStock> productsWithStock = [];

      if (widget.getStockFunction != null) {
        for (final product in products) {
          final stock = await widget.getStockFunction!(product.id);
          productsWithStock.add(
            ProductWithStock(product: product, availableStock: stock),
          );
        }
      } else {
        // If no stock function provided, use 0 as stock
        productsWithStock =
            products
                .map(
                  (product) =>
                      ProductWithStock(product: product, availableStock: 0),
                )
                .toList();
      }

      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = productsWithStock;
          _showResults = productsWithStock.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error searching products: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
          _showResults = false;
        });
      }
    }
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = null; // No mantener producto seleccionado
      _showResults = false;
      _searchResults = [];
    });

    // Limpiar completamente el search para el siguiente producto
    _searchController.clear();
    _focusNode.unfocus();

    // Ejecutar callback
    widget.onProductSelected(product);

    print('🔍 Product selected and search cleared: ${product.name}');
  }

  void _clearSelection() {
    setState(() {
      _selectedProduct = null;
    });
    _searchController.clear();
    _focusNode.requestFocus();
  }
}
