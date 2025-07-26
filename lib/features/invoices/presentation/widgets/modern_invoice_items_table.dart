// lib/features/invoices/presentation/widgets/modern_invoice_items_table.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baudex_desktop/app/core/utils/responsive.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import '../controllers/invoice_form_controller.dart';
import '../../data/models/invoice_form_models.dart';
import '../../../products/domain/entities/product.dart';
import 'price_selector_widget.dart';

class ModernInvoiceItemsTable extends StatefulWidget {
  final InvoiceFormController controller;
  final int selectedIndex;
  final Function(int) onSelectionChanged;
  final double height;
  final ScrollController? scrollController;

  const ModernInvoiceItemsTable({
    super.key,
    required this.controller,
    this.selectedIndex = -1,
    required this.onSelectionChanged,
    this.height = 400.0,
    this.scrollController,
  });

  @override
  State<ModernInvoiceItemsTable> createState() => _ModernInvoiceItemsTableState();
}

class _ModernInvoiceItemsTableState extends State<ModernInvoiceItemsTable> {
  late final ScrollController _scrollController;
  late final bool _shouldDisposeController;
  
  @override
  void initState() {
    super.initState();
    // Usar el ScrollController pasado o crear uno nuevo
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
      _shouldDisposeController = false;
    } else {
      _scrollController = ScrollController();
      _shouldDisposeController = true;
    }
  }
  
  @override
  void dispose() {
    // Solo dispose si creamos el controller nosotros
    if (_shouldDisposeController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        if (widget.controller.invoiceItems.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            _buildTableHeader(context),
            const Divider(height: 1),
            Expanded(
              child: _buildTableBody(context),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: context.isMobile ? 28 : 36,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Sin productos',
            style: TextStyle(
              fontSize: context.isMobile ? 11 : 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Busca y agrega productos',
            style: TextStyle(
              fontSize: context.isMobile ? 9 : 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 4 : 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: context.isMobile 
        ? _buildMobileHeader(context)
        : _buildDesktopHeader(context),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            'Producto',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Cant.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Total',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            'Producto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Cantidad',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Precio Unit.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Subtotal',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(width: 50), // Espacio para acciones
      ],
    );
  }

  Widget _buildTableBody(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.controller.invoiceItems.length,
      itemBuilder: (context, index) {
        final item = widget.controller.invoiceItems[index];
        final isSelected = widget.selectedIndex == index;
        
        return _buildTableRow(context, item, index, isSelected);
      },
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    InvoiceItemFormData item,
    int index,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => widget.onSelectionChanged(index),
      child: Container(
        padding: EdgeInsets.all(context.isMobile ? 1 : 2),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).primaryColor.withOpacity(0.05)
            : null,
          border: Border(
            left: BorderSide(
              width: 3,
              color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            ),
          ),
        ),
        child: context.isMobile 
          ? _buildMobileRow(context, item, index, isSelected)
          : _buildDesktopRow(context, item, index, isSelected),
      ),
    );
  }

  Widget _buildMobileRow(
    BuildContext context,
    InvoiceItemFormData item,
    int index,
    bool isSelected,
  ) {
    return Column(
      children: [
        // Fila principal
        Row(
          children: [
            // Información del producto
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                        ? Theme.of(context).primaryColor
                        : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${AppFormatters.formatCurrency(item.unitPrice)} c/u',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Cantidad
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  AppFormatters.formatStock(item.quantity),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Subtotal
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatCurrency(item.subtotal),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Acciones (solo cuando está seleccionado)
        if (isSelected) ...[
          const SizedBox(height: 2),
          _buildMobileActions(context, item, index),
        ],
      ],
    );
  }

  Widget _buildDesktopRow(
    BuildContext context,
    InvoiceItemFormData item,
    int index,
    bool isSelected,
  ) {
    return Row(
      children: [
        // Producto
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 1),
                Text(
                  item.notes!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        // Cantidad
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              AppFormatters.formatStock(item.quantity),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        
        // Precio unitario
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: () => _showPriceEditDialog(context, item, index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            AppFormatters.formatCurrency(item.unitPrice),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.edit,
                          size: 10,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Subtotal
        Expanded(
          flex: 2,
          child: Text(
            AppFormatters.formatCurrency(item.subtotal),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        
        // Acciones
        SizedBox(
          width: 50,
          child: _buildDesktopActions(context, item, index),
        ),
      ],
    );
  }


  Widget _buildMobileActions(
    BuildContext context,
    InvoiceItemFormData item,
    int index,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          icon: Icons.edit,
          label: 'Precio',
          onTap: () => _showPriceEditDialog(context, item, index),
        ),
        _buildActionButton(
          context,
          icon: Icons.add,
          label: '+1',
          onTap: () => _incrementQuantity(index, 1),
        ),
        _buildActionButton(
          context,
          icon: Icons.remove,
          label: '-1',
          onTap: () => _decrementQuantity(index, 1),
        ),
        _buildActionButton(
          context,
          icon: Icons.delete,
          label: 'Eliminar',
          color: Colors.red,
          onTap: () => _removeItem(index),
        ),
      ],
    );
  }

  Widget _buildDesktopActions(
    BuildContext context,
    InvoiceItemFormData item,
    int index,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: Colors.grey.shade600,
      ),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        switch (value) {
          case 'increment':
            _incrementQuantity(index, 1);
            break;
          case 'decrement':
            _decrementQuantity(index, 1);
            break;
          case 'delete':
            _removeItem(index);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'increment',
          child: Row(
            children: [
              Icon(Icons.add, size: 16),
              SizedBox(width: 8),
              Text('Incrementar'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'decrement',
          child: Row(
            children: [
              Icon(Icons.remove, size: 16),
              SizedBox(width: 8),
              Text('Decrementar'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Eliminar', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: (color ?? Theme.of(context).primaryColor).withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: color ?? Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color ?? Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceEditDialog(
    BuildContext context,
    InvoiceItemFormData item,
    int index,
  ) {
    final product = widget.controller.availableProducts.firstWhereOrNull(
      (p) => p.id == item.productId,
    );

    if (product == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => PriceSelectorWidget(
        product: product,
        currentPrice: item.unitPrice,
        onPriceChanged: (newPrice) {
          final updatedItem = item.copyWith(unitPrice: newPrice);
          widget.controller.updateItem(index, updatedItem);
          // Use the dialog context specifically to close only the dialog
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        },
      ),
    );
  }

  void _incrementQuantity(int index, double increment) {
    final item = widget.controller.invoiceItems[index];
    final updatedItem = item.copyWith(quantity: item.quantity + increment);
    widget.controller.updateItem(index, updatedItem);
  }

  void _decrementQuantity(int index, double decrement) {
    final item = widget.controller.invoiceItems[index];
    final newQuantity = (item.quantity - decrement).clamp(1.0, double.infinity);
    
    if (newQuantity < 1) {
      _removeItem(index);
      return;
    }

    final updatedItem = item.copyWith(quantity: newQuantity);
    widget.controller.updateItem(index, updatedItem);
  }

  void _removeItem(int index) {
    widget.controller.removeItem(index);
    
    // Ajustar selección si es necesario
    if (widget.selectedIndex >= widget.controller.invoiceItems.length) {
      widget.onSelectionChanged(
        (widget.controller.invoiceItems.length - 1).clamp(0, double.infinity.toInt())
      );
    }
  }
}