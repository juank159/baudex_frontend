// lib/features/invoices/presentation/widgets/modern_invoice_items_table.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baudex_desktop/app/core/theme/elegant_light_theme.dart';
import 'package:baudex_desktop/app/core/utils/responsive.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import '../controllers/invoice_form_controller.dart';
import '../../data/models/invoice_form_models.dart';
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
  State<ModernInvoiceItemsTable> createState() =>
      _ModernInvoiceItemsTableState();
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
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withOpacity(0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Obx(() {
        if (widget.controller.invoiceItems.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            _buildTableHeader(context),
            Divider(
              height: 1,
              color: ElegantLightTheme.textTertiary.withOpacity(0.15),
            ),
            Expanded(child: _buildTableBody(context)),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ElegantLightTheme.textTertiary.withOpacity(0.2),
              ),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: context.isMobile ? 28 : 36,
              color: ElegantLightTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin productos',
            style: TextStyle(
              fontSize: context.isMobile ? 12 : 14,
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Busca y agrega productos',
            style: TextStyle(
              fontSize: context.isMobile ? 10 : 12,
              color: ElegantLightTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 8 : 12,
        vertical: context.isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child:
          context.isMobile
              ? _buildMobileHeader(context)
              : _buildDesktopHeader(context),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 4,
          child: Text(
            'Producto',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
        ),
        const Expanded(
          flex: 3,
          child: Text(
            'Cant.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
        ),
        const Expanded(
          flex: 2,
          child: Text(
            'Total',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 4,
          child: Text(
            'Producto',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
        ),
        const Expanded(
          flex: 2,
          child: Text(
            'Cantidad',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
        ),
        const Expanded(
          flex: 2,
          child: Text(
            'Precio Unit.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
        ),
        const Expanded(
          flex: 2,
          child: Text(
            'Subtotal',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textPrimary,
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
    return Obx(() {
      // ✅ NUEVO: Detectar si este item fue recientemente actualizado
      final isRecentlyUpdated =
          widget.controller.lastUpdatedItemIndex == index &&
          widget.controller.shouldHighlightUpdatedItem;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: InkWell(
          onTap: () => widget.onSelectionChanged(index),
          child: Container(
            padding: EdgeInsets.all(context.isMobile ? 1 : 2),
            decoration: BoxDecoration(
              color: _getRowBackgroundColor(
                context,
                isSelected,
                isRecentlyUpdated,
              ),
              border: Border(
                left: BorderSide(
                  width: 3,
                  color: _getRowBorderColor(
                    context,
                    isSelected,
                    isRecentlyUpdated,
                  ),
                ),
              ),
              // ✅ NUEVO: Sombra adicional para productos recientemente actualizados
              boxShadow:
                  isRecentlyUpdated
                      ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child:
                context.isMobile
                    ? _buildMobileRow(
                      context,
                      item,
                      index,
                      isSelected,
                      isRecentlyUpdated,
                    )
                    : _buildDesktopRow(
                      context,
                      item,
                      index,
                      isSelected,
                      isRecentlyUpdated,
                    ),
          ),
        ),
      );
    });
  }

  // ✅ NUEVO: Método para determinar el color de fondo
  Color? _getRowBackgroundColor(
    BuildContext context,
    bool isSelected,
    bool isRecentlyUpdated,
  ) {
    if (isRecentlyUpdated) {
      return const Color(0xFF10B981).withOpacity(0.08); // Verde claro para actualizaciones
    } else if (isSelected) {
      return ElegantLightTheme.primaryBlue.withOpacity(0.05);
    }
    return null;
  }

  // ✅ NUEVO: Método para determinar el color del borde
  Color _getRowBorderColor(
    BuildContext context,
    bool isSelected,
    bool isRecentlyUpdated,
  ) {
    if (isRecentlyUpdated) {
      return const Color(0xFF10B981); // Verde para actualizaciones
    } else if (isSelected) {
      return ElegantLightTheme.primaryBlue;
    }
    return Colors.transparent;
  }

  Widget _buildMobileRow(
    BuildContext context,
    InvoiceItemFormData item,
    int index,
    bool isSelected,
    bool isRecentlyUpdated,
  ) {
    return Row(
      children: [
        // Información del producto (nombre + precio editable)
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? ElegantLightTheme.primaryBlue
                      : ElegantLightTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Precio unitario editable (como en desktop)
              GestureDetector(
                onTap: () => _showPriceEditDialog(context, item, index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppFormatters.formatCurrency(item.unitPrice),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.edit,
                        size: 10,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cantidad con botones +/-
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón decrementar (-)
              _buildMiniQuantityButton(
                icon: Icons.remove,
                onTap: () => _decrementQuantity(index, 1),
                isDecrease: true,
              ),
              // Cantidad
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isRecentlyUpdated
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : ElegantLightTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isRecentlyUpdated
                        ? const Color(0xFF10B981)
                        : ElegantLightTheme.primaryBlue.withOpacity(0.3),
                    width: isRecentlyUpdated ? 2 : 1,
                  ),
                ),
                child: Text(
                  AppFormatters.formatStock(item.quantity),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isRecentlyUpdated
                        ? const Color(0xFF10B981)
                        : ElegantLightTheme.primaryBlue,
                  ),
                ),
              ),
              // Botón incrementar (+)
              _buildMiniQuantityButton(
                icon: Icons.add,
                onTap: () => _incrementQuantity(index, 1),
                isDecrease: false,
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.primaryBlue,
            ),
          ),
        ),

        // Botón eliminar
        const SizedBox(width: 6),
        _buildMiniDeleteButton(index),
      ],
    );
  }

  // Botón mini para cantidad (+/-)
  Widget _buildMiniQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDecrease,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: isDecrease
                ? ElegantLightTheme.warningGradient
                : ElegantLightTheme.successGradient,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Botón mini eliminar
  Widget _buildMiniDeleteButton(int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _removeItem(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.errorGradient,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.delete_outline,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopRow(
    BuildContext context,
    InvoiceItemFormData item,
    int index,
    bool isSelected,
    bool isRecentlyUpdated,
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
                  color:
                      isSelected
                          ? ElegantLightTheme.primaryBlue
                          : ElegantLightTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 1),
                Text(
                  item.notes!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: ElegantLightTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Cantidad con botones de +/-
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón decrementar (-)
              _buildQuantityButton(
                context,
                icon: Icons.remove,
                onTap: () => _decrementQuantity(index, 1),
                isDecrease: true,
              ),

              // Cantidad
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isRecentlyUpdated
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : ElegantLightTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isRecentlyUpdated
                        ? const Color(0xFF10B981)
                        : ElegantLightTheme.primaryBlue.withOpacity(0.3),
                    width: isRecentlyUpdated ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRecentlyUpdated) ...[
                      const Icon(
                        Icons.trending_up,
                        size: 12,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      AppFormatters.formatStock(item.quantity),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isRecentlyUpdated
                            ? const Color(0xFF10B981)
                            : ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón incrementar (+)
              _buildQuantityButton(
                context,
                icon: Icons.add,
                onTap: () => _incrementQuantity(index, 1),
                isDecrease: false,
              ),
            ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ElegantLightTheme.textTertiary.withOpacity(0.2),
                      ),
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
                              color: ElegantLightTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.edit,
                          size: 10,
                          color: ElegantLightTheme.textSecondary,
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.primaryBlue,
            ),
          ),
        ),

        // Botón eliminar (reemplaza los 3 puntos)
        SizedBox(
          width: 50,
          child: _buildDeleteButton(context, index),
        ),
      ],
    );
  }

  // Botón de cantidad (+/-)
  Widget _buildQuantityButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required bool isDecrease,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: isDecrease
                ? ElegantLightTheme.warningGradient
                : ElegantLightTheme.successGradient,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: isDecrease
                    ? ElegantLightTheme.accentOrange.withOpacity(0.3)
                    : const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Botón eliminar elegante
  Widget _buildDeleteButton(BuildContext context, int index) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _removeItem(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.errorGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.delete_outline,
              size: 16,
              color: Colors.white,
            ),
          ),
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
      builder:
          (dialogContext) => PriceSelectorWidget(
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
    final itemsLength = widget.controller.invoiceItems.length;
    if (widget.selectedIndex >= itemsLength) {
      // Si no quedan items, seleccionar -1 (ninguno), sino el último
      final newIndex = itemsLength > 0 ? itemsLength - 1 : -1;
      widget.onSelectionChanged(newIndex);
    }
  }
}
