// lib/features/invoices/presentation/widgets/enhanced_invoice_items_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:baudex_desktop/app/core/utils/responsive.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import '../controllers/invoice_form_controller.dart';
import './enhanced_invoice_item_widget.dart';

class EnhancedInvoiceItemsWidget extends StatefulWidget {
  final InvoiceFormController controller;
  final double height;
  final int selectedIndex;
  final Function(int) onSelectionChanged;

  const EnhancedInvoiceItemsWidget({
    super.key,
    required this.controller,
    this.height = 400.0,
    this.selectedIndex = -1,
    required this.onSelectionChanged,
  });

  @override
  State<EnhancedInvoiceItemsWidget> createState() =>
      _EnhancedInvoiceItemsWidgetState();
}

class _EnhancedInvoiceItemsWidgetState
    extends State<EnhancedInvoiceItemsWidget> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isShiftPressed = false;
  bool _isCtrlPressed = false;

  int get _selectedIndex => widget.selectedIndex;

  @override
  void initState() {
    super.initState();
    // Ya no necesitamos el focus aquí porque es global
    // Escuchar cambios en la lista de productos
    widget.controller.addListener(_onProductsChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    widget.controller.removeListener(_onProductsChanged);
    super.dispose();
  }

  void _onProductsChanged() {
    // Comentado: No hacer scroll automático al modificar productos
    // Solo mantener la posición actual donde está el usuario
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (_scrollController.hasClients && widget.controller.invoiceItems.isNotEmpty) {
    //     _scrollController.animateTo(
    //       0,
    //       duration: const Duration(milliseconds: 300),
    //       curve: Curves.easeInOut,
    //     );
    //   }
    // });
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Detectar teclas modificadoras
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _isShiftPressed = true;
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        _isCtrlPressed = true;
        return true;
      }

      // Manejar shortcuts para incrementar cantidad
      if (_selectedIndex >= 0 &&
          _selectedIndex < widget.controller.invoiceItems.length) {
        // NUEVOS SHORTCUTS CON SHIFT COMO MODIFICADOR PRINCIPAL

        // Shift + números (1-9) para incrementar cantidad específica
        if (_isShiftPressed && event.logicalKey.keyLabel.length == 1) {
          final key = event.logicalKey.keyLabel;
          if (RegExp(r'^[1-9]$').hasMatch(key)) {
            final increment = int.parse(key);
            _incrementQuantity(increment);
            return true;
          }
        }

        // Shift + '+' para incrementar de uno en uno
        if (_isShiftPressed && event.logicalKey == LogicalKeyboardKey.equal) {
          // Shift + = (que es +)
          _incrementQuantity(1);
          return true;
        }

        // Shift + '-' para decrementar de uno en uno
        if (_isShiftPressed && event.logicalKey == LogicalKeyboardKey.minus) {
          _decrementQuantity(1);
          return true;
        }

        // Shift + Enter para procesar la venta
        if (_isShiftPressed && event.logicalKey == LogicalKeyboardKey.enter) {
          _processSale();
          return true;
        }
      }

      // Navegación con flechas
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveSelection(-1);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveSelection(1);
        return true;
      }

      // Navegación rápida con Home/End
      if (event.logicalKey == LogicalKeyboardKey.home) {
        _moveToFirst();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.end) {
        _moveToLast();
        return true;
      }

      // Scroll con Page Up/Down
      if (event.logicalKey == LogicalKeyboardKey.pageUp) {
        _scrollPage(-1);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.pageDown) {
        _scrollPage(1);
        return true;
      }

      // NOTA: Manejo de eliminación ahora es global (Shift + Delete)
      // Este código local ya no se usa
      // if (event.logicalKey == LogicalKeyboardKey.delete ||
      //     event.logicalKey == LogicalKeyboardKey.backspace) {
      //   _deleteSelectedItem();
      //   return true;
      // }

      // Duplicar producto con Ctrl + D
      if (_isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyD) {
        _duplicateSelectedItem();
        return true;
      }

      // Limpiar lista con Ctrl + Shift + C
      if (_isCtrlPressed &&
          _isShiftPressed &&
          event.logicalKey == LogicalKeyboardKey.keyC) {
        _clearAllItems();
        return true;
      }
    }

    if (event is KeyUpEvent) {
      // Resetear teclas modificadoras
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _isShiftPressed = false;
      }
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        _isCtrlPressed = false;
      }
    }

    return false;
  }

  void _decrementQuantity(int decrement) {
    if (_selectedIndex >= 0 &&
        _selectedIndex < widget.controller.invoiceItems.length) {
      final item = widget.controller.invoiceItems[_selectedIndex];
      final newQuantity = (item.quantity - decrement).clamp(
        1.0,
        double.infinity,
      );

      if (newQuantity < 1) {
        // Si la cantidad sería menor a 1, mostrar confirmación para eliminar
        _showDeleteConfirmation();
        return;
      }

      final updatedItem = item.copyWith(quantity: newQuantity);
      widget.controller.updateItem(_selectedIndex, updatedItem);
    }
  }

  void _incrementQuantity(int increment) {
    if (_selectedIndex >= 0 &&
        _selectedIndex < widget.controller.invoiceItems.length) {
      final item = widget.controller.invoiceItems[_selectedIndex];
      final newQuantity = item.quantity + increment;

      // Validar stock si es necesario
      final product = widget.controller.availableProducts.firstWhereOrNull(
        (p) => p.id == item.productId,
      );

      if (product != null && !_isTemporaryProduct(product)) {
        if (newQuantity > product.stock) {
          _showStockError(product.name, product.stock);
          return;
        }
      }

      final updatedItem = item.copyWith(quantity: newQuantity);
      widget.controller.updateItem(_selectedIndex, updatedItem);
    }
  }

  void _setExactQuantity(double quantity) {
    if (_selectedIndex >= 0 &&
        _selectedIndex < widget.controller.invoiceItems.length) {
      final item = widget.controller.invoiceItems[_selectedIndex];

      // Validar stock si es necesario
      final product = widget.controller.availableProducts.firstWhereOrNull(
        (p) => p.id == item.productId,
      );

      if (product != null && !_isTemporaryProduct(product)) {
        if (quantity > product.stock) {
          _showStockError(product.name, product.stock);
          return;
        }
      }

      final updatedItem = item.copyWith(quantity: quantity);
      widget.controller.updateItem(_selectedIndex, updatedItem);
    }
  }

  bool _isTemporaryProduct(Product product) {
    return product.id.startsWith('temp_') ||
        product.id.startsWith('unregistered_') ||
        (product.metadata?['isTemporary'] == true);
  }

  void _moveSelection(int direction) {
    if (widget.controller.invoiceItems.isEmpty) return;

    final newIndex = (_selectedIndex + direction).clamp(
      0,
      widget.controller.invoiceItems.length - 1,
    );

    widget.onSelectionChanged(newIndex);
    _scrollToSelected();
  }

  void _scrollToSelected() {
    if (_scrollController.hasClients && _selectedIndex >= 0) {
      const itemHeight = 80.0; // Altura estimada de cada item
      final targetScroll = _selectedIndex * itemHeight;

      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollPage(int direction) {
    if (_scrollController.hasClients) {
      final currentScroll = _scrollController.offset;
      final pageSize = _scrollController.position.viewportDimension;
      final targetScroll = currentScroll + (direction * pageSize * 0.8);

      _scrollController.animateTo(
        targetScroll.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _deleteSelectedItem() {
    if (_selectedIndex >= 0 &&
        _selectedIndex < widget.controller.invoiceItems.length) {
      widget.controller.removeItem(_selectedIndex);

      // Ajustar selección después de eliminar
      if (widget.controller.invoiceItems.isNotEmpty) {
        final newIndex = _selectedIndex.clamp(
          0,
          widget.controller.invoiceItems.length - 1,
        );
        widget.onSelectionChanged(newIndex);
      } else {
        widget.onSelectionChanged(-1);
      }
    }
  }

  void _showStockError(String productName, double stock) {
    Get.snackbar(
      'Stock Insuficiente',
      'Solo hay ${stock.toInt()} unidades disponibles de $productName',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.warning, color: Colors.red),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
    );
  }

  void _moveToFirst() {
    if (widget.controller.invoiceItems.isNotEmpty) {
      widget.onSelectionChanged(0);
      _scrollToSelected();
    }
  }

  void _moveToLast() {
    if (widget.controller.invoiceItems.isNotEmpty) {
      widget.onSelectionChanged(widget.controller.invoiceItems.length - 1);
      _scrollToSelected();
    }
  }

  void _showPriceSelectorForSelected() {
    if (_selectedIndex >= 0 &&
        _selectedIndex < widget.controller.invoiceItems.length) {
      final item = widget.controller.invoiceItems[_selectedIndex];
      final product = widget.controller.availableProducts.firstWhereOrNull(
        (p) => p.id == item.productId,
      );

      if (product != null) {
        // Buscar el widget EnhancedInvoiceItemWidget y simular la acción de mostrar el selector de precios
        Get.snackbar(
          'Editar Precio',
          'Presiona en el precio del producto para editarlo',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue.shade100,
          colorText: Colors.blue.shade800,
          icon: const Icon(Icons.edit, color: Colors.blue),
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void _duplicateSelectedItem() {
    if (_selectedIndex >= 0 &&
        _selectedIndex < widget.controller.invoiceItems.length) {
      final item = widget.controller.invoiceItems[_selectedIndex];
      final product = widget.controller.availableProducts.firstWhereOrNull(
        (p) => p.id == item.productId,
      );

      if (product != null) {
        widget.controller.addOrUpdateProductToInvoice(
          product,
          quantity: item.quantity,
        );

        Get.snackbar(
          'Producto Duplicado',
          '${item.description} agregado nuevamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.content_copy, color: Colors.green),
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void _clearAllItems() {
    if (widget.controller.invoiceItems.isNotEmpty) {
      Get.dialog(
        AlertDialog(
          title: const Text('Confirmar'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar todos los productos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.controller.clearItems();
                Get.back();
                widget.onSelectionChanged(-1);
                Get.snackbar(
                  'Lista Limpia',
                  'Todos los productos han sido eliminados',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.orange.shade100,
                  colorText: Colors.orange.shade800,
                  icon: const Icon(Icons.clear_all, color: Colors.orange),
                  duration: const Duration(seconds: 2),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar Todo'),
            ),
          ],
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    if (_selectedIndex >= 0 &&
        _selectedIndex < widget.controller.invoiceItems.length) {
      final item = widget.controller.invoiceItems[_selectedIndex];

      Get.dialog(
        AlertDialog(
          title: const Text('Eliminar Producto'),
          content: Text(
            '¿Quieres eliminar "${item.description}" de la factura?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteSelectedItem();
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
    }
  }

  void _processSale() {
    if (widget.controller.invoiceItems.isEmpty) {
      Get.snackbar(
        'No hay productos',
        'Agrega productos antes de procesar la venta',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Llamar al método del controlador para guardar la factura
    widget.controller.saveInvoice();

    Get.snackbar(
      'Procesando Venta',
      'La factura está siendo procesada...',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.shopping_cart_checkout, color: Colors.green),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent:
          (node, event) =>
              _handleKeyEvent(event)
                  ? KeyEventResult.handled
                  : KeyEventResult.ignored,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: context.responsivePadding,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: Theme.of(context).primaryColor,
                      size: context.isMobile ? 20 : 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Productos (${widget.controller.invoiceItems.length})',
                        style: TextStyle(
                          fontSize: context.isMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    if (widget.controller.invoiceItems.isNotEmpty) ...[
                      _buildShortcutButton(),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: widget.controller.clearItems,
                        icon: Icon(
                          Icons.clear_all,
                          size: context.isMobile ? 14 : 16,
                        ),
                        label: Text(
                          'Limpiar',
                          style: TextStyle(
                            fontSize: context.isMobile ? 12 : 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Obx(() {
                  if (widget.controller.invoiceItems.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildProductsList();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutButton() {
    return InkWell(
      onTap: () => _showShortcutsDialog(),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard, size: 12, color: Colors.blue.shade600),
            const SizedBox(width: 4),
            Text(
              'Shortcuts',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.help_outline, size: 10, color: Colors.blue.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: context.responsivePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: context.isMobile ? 40 : 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: context.isMobile ? 12 : 16),
          Text(
            'No hay productos agregados',
            style: TextStyle(
              fontSize: context.isMobile ? 14 : 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.isMobile ? 6 : 8),
          Text(
            'Busca y agrega productos para comenzar la venta',
            style: TextStyle(
              fontSize: context.isMobile ? 12 : 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showShortcutsDialog(),
            icon: const Icon(Icons.keyboard, size: 16),
            label: const Text('Ver Shortcuts Disponibles'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showShortcutsDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.keyboard, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('Shortcuts de Teclado'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usa estos atajos para gestionar productos rápidamente:',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                _buildShortcutSection('Gestionar Cantidades', [
                  _buildShortcutItem(
                    'Shift + 1-9',
                    'Incrementar cantidad específica',
                  ),
                  _buildShortcutItem('Shift + +', 'Incrementar de uno en uno'),
                  _buildShortcutItem('Shift + -', 'Decrementar de uno en uno'),
                ]),
                const SizedBox(height: 16),
                _buildShortcutSection('Navegación', [
                  _buildShortcutItem('↑ ↓', 'Navegar productos'),
                  _buildShortcutItem('Home/End', 'Primer/Último producto'),
                  _buildShortcutItem('Page Up/Down', 'Scroll rápido'),
                ]),
                const SizedBox(height: 16),
                _buildShortcutSection('Acciones', [
                  _buildShortcutItem('Shift + Enter', 'Procesar venta'),
                  _buildShortcutItem('Shift + Delete', 'Eliminar producto'),
                  _buildShortcutItem('Ctrl + D', 'Duplicar producto'),
                  _buildShortcutItem('Ctrl + Shift + C', 'Limpiar todo'),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildShortcutItem(String key, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              key,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: widget.controller.invoiceItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = widget.controller.invoiceItems[index];
        final isSelected = index == _selectedIndex;

        Product? product;
        if (item.productId != null) {
          product = widget.controller.availableProducts.firstWhereOrNull(
            (p) => p.id == item.productId,
          );
        }

        return EnhancedInvoiceItemWidget(
          item: item,
          index: index,
          product: product,
          isSelected: isSelected,
          onTap: () {
            widget.onSelectionChanged(index);
          },
          onUpdate:
              (updatedItem) => widget.controller.updateItem(index, updatedItem),
          onRemove: () => widget.controller.removeItem(index),
          showPriceSelector: true,
        );
      },
    );
  }
}
