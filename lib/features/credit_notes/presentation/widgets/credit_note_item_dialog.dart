// lib/features/credit_notes/presentation/widgets/credit_note_item_dialog.dart
import 'package:baudex_desktop/app/core/theme/elegant_light_theme.dart';
import 'package:baudex_desktop/app/core/utils/formatters.dart';
import 'package:baudex_desktop/app/core/utils/number_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../domain/entities/credit_note_item.dart';
import '../../domain/entities/credit_note.dart';
import '../../../products/domain/entities/product.dart';

class CreditNoteItemDialog extends StatefulWidget {
  final CreditNoteItem? item;
  final int? index;
  final List<dynamic>? invoiceItems; // Items de la factura
  final List<AvailableQuantityItem>? availableItems; // Cantidades disponibles

  const CreditNoteItemDialog({
    super.key,
    this.item,
    this.index,
    this.invoiceItems,
    this.availableItems,
  });

  @override
  State<CreditNoteItemDialog> createState() => _CreditNoteItemDialogState();
}

class _CreditNoteItemDialogState extends State<CreditNoteItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _notesController = TextEditingController();

  Product? _selectedProduct;
  AvailableQuantityItem? _selectedAvailableItem;
  String _unit = 'UND';
  double _subtotal = 0.0;
  double _discountAmount = 0.0;
  double _maxQuantity = double.infinity; // Cantidad máxima disponible
  String? _selectedInvoiceItemId;

  @override
  void initState() {
    super.initState();

    if (widget.item != null) {
      // Modo edición - cargar datos existentes con formato
      _descriptionController.text = widget.item!.description;
      _quantityController.text = NumberInputFormatter.formatValueForDisplay(
        widget.item!.quantity,
        allowDecimals: true,
      );
      _unitPriceController.text = NumberInputFormatter.formatValueForDisplay(
        widget.item!.unitPrice,
        allowDecimals: false,
      );
      _discountPercentageController.text =
          widget.item!.discountPercentage.toString();
      _notesController.text = widget.item!.notes ?? '';
      _unit = widget.item!.unit ?? 'UND';
      _calculateSubtotal();
    } else {
      // Modo nuevo item - descuento por defecto es 0
      _discountPercentageController.text = '0';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _discountPercentageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateSubtotal() {
    // Usar el parser del formatter para obtener el valor numérico correcto
    final quantity = NumberInputFormatter.getNumericValue(_quantityController.text) ?? 0.0;
    final unitPrice = NumberInputFormatter.getNumericValue(_unitPriceController.text) ?? 0.0;
    final discountPercentage =
        double.tryParse(_discountPercentageController.text) ?? 0.0;

    final subtotalBeforeDiscount = quantity * unitPrice;
    _discountAmount = subtotalBeforeDiscount * (discountPercentage / 100);
    _subtotal = subtotalBeforeDiscount - _discountAmount;

    setState(() {});
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'Campo requerido',
        'La descripción es obligatoria',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Usar el parser del formatter para obtener valores numéricos correctos
    final quantity = NumberInputFormatter.getNumericValue(_quantityController.text) ?? 0.0;
    final unitPrice = NumberInputFormatter.getNumericValue(_unitPriceController.text) ?? 0.0;
    final discountPercentage =
        double.tryParse(_discountPercentageController.text) ?? 0.0;

    if (quantity <= 0) {
      Get.snackbar(
        'Cantidad inválida',
        'La cantidad debe ser mayor a 0',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Validar que no exceda la cantidad máxima disponible
    if (_maxQuantity != double.infinity && quantity > _maxQuantity) {
      Get.snackbar(
        'Cantidad excedida',
        'La cantidad máxima disponible es ${_maxQuantity.toStringAsFixed(_maxQuantity.truncateToDouble() == _maxQuantity ? 0 : 2)}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (unitPrice <= 0) {
      Get.snackbar(
        'Precio inválido',
        'El precio debe ser mayor a 0',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final item = CreditNoteItem(
      id: widget.item?.id ?? '',
      description: _descriptionController.text.trim(),
      quantity: quantity,
      unitPrice: unitPrice,
      discountPercentage: discountPercentage,
      discountAmount: _discountAmount,
      subtotal: _subtotal,
      unit: _unit,
      creditNoteId: widget.item?.creditNoteId ?? '',
      productId: _selectedProduct?.id ?? _selectedAvailableItem?.productId,
      invoiceItemId: _selectedInvoiceItemId ?? widget.item?.invoiceItemId,
      notes:
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
      createdAt: widget.item?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Get.back(result: {'item': item, 'index': widget.index});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    final dialogWidth =
        isMobile ? size.width * 0.95 : (isTablet ? 500.0 : 600.0);
    final padding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final textSize = isMobile ? 13.0 : (isTablet ? 14.0 : 15.0);
    final titleSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);

    return SafeArea(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding * 2,
        ),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(maxHeight: size.height * 0.85),
          decoration: BoxDecoration(
            color: ElegantLightTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.item == null ? 'Agregar Item' : 'Editar Item',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Selector
                      _buildProductSelector(textSize, padding),

                      SizedBox(height: padding),

                      // Description
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Descripción',
                        icon: Icons.description,
                        textSize: textSize,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La descripción es requerida';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: padding),

                      // Quantity and Unit Price
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuantityField(
                              controller: _quantityController,
                              label: 'Cantidad',
                              icon: Icons.numbers,
                              textSize: textSize,
                              onChanged: (_) => _calculateSubtotal(),
                            ),
                          ),
                          SizedBox(width: padding),
                          Expanded(
                            child: _buildPriceField(
                              controller: _unitPriceController,
                              label: 'Precio Unitario',
                              icon: Icons.attach_money,
                              textSize: textSize,
                              onChanged: (_) => _calculateSubtotal(),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: padding),

                      // Discount Percentage (permite 0)
                      _buildDiscountField(
                        controller: _discountPercentageController,
                        label: 'Descuento (%)',
                        icon: Icons.percent,
                        textSize: textSize,
                        onChanged: (_) => _calculateSubtotal(),
                      ),

                      SizedBox(height: padding),

                      // Unit Selector
                      _buildUnitSelector(textSize, padding),

                      SizedBox(height: padding),

                      // Notes
                      _buildTextField(
                        controller: _notesController,
                        label: 'Notas (Opcional)',
                        icon: Icons.note,
                        textSize: textSize,
                        maxLines: 3,
                      ),

                      SizedBox(height: padding),

                      // Totals Summary
                      Container(
                        padding: EdgeInsets.all(padding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ElegantLightTheme.infoGradient.colors.first
                                  .withValues(alpha:0.1),
                              ElegantLightTheme.infoGradient.colors.last
                                  .withValues(alpha:0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ElegantLightTheme.infoGradient.colors.first
                                .withValues(alpha:0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_discountAmount > 0) ...[
                              _buildTotalRow(
                                'Descuento',
                                _discountAmount,
                                textSize,
                                ElegantLightTheme.textSecondary,
                              ),
                              const Divider(),
                            ],
                            _buildTotalRow(
                              'Total Item (IVA incluido)',
                              _subtotal,
                              textSize + 2,
                              ElegantLightTheme.textPrimary,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: ElegantLightTheme.surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: padding),
                        side: BorderSide(
                          color: ElegantLightTheme.textTertiary.withValues(alpha:
                            0.3,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: ElegantLightTheme.textSecondary,
                          fontSize: textSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: padding),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.successGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ElegantLightTheme
                                .successGradient
                                .colors
                                .first
                                .withValues(alpha:0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _save,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: padding),
                            alignment: Alignment.center,
                            child: Text(
                              'Guardar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: textSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildProductSelector(double textSize, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Producto de la Factura (Opcional)',
          style: TextStyle(
            fontSize: textSize - 1,
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showProductSelector(textSize, padding),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: ElegantLightTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ElegantLightTheme.textTertiary.withValues(alpha:0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedProduct?.name ??
                            'Seleccionar producto de la factura...',
                        style: TextStyle(
                          fontSize: textSize,
                          fontWeight:
                              _selectedProduct != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                          color:
                              _selectedProduct != null
                                  ? ElegantLightTheme.textPrimary
                                  : ElegantLightTheme.textTertiary,
                        ),
                      ),
                      if (_selectedProduct != null)
                        Text(
                          'SKU: ${_selectedProduct!.sku}',
                          style: TextStyle(
                            fontSize: textSize - 2,
                            color: ElegantLightTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _selectedProduct != null
                      ? Icons.check_circle
                      : Icons.arrow_forward_ios,
                  color:
                      _selectedProduct != null
                          ? ElegantLightTheme.successGradient.colors.first
                          : ElegantLightTheme.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        // Mostrar cantidad disponible si hay un item seleccionado
      if (_selectedAvailableItem != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ElegantLightTheme.infoGradient.colors.first.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ElegantLightTheme.infoGradient.colors.first.withValues(alpha:0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: ElegantLightTheme.infoGradient.colors.first,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cantidad disponible: ${_selectedAvailableItem!.availableQuantity.toStringAsFixed(_selectedAvailableItem!.availableQuantity.truncateToDouble() == _selectedAvailableItem!.availableQuantity ? 0 : 2)} ${_selectedAvailableItem!.unit}',
                        style: TextStyle(
                          fontSize: textSize - 1,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.infoGradient.colors.first,
                        ),
                      ),
                      if (_selectedAvailableItem!.creditedQuantity > 0 || _selectedAvailableItem!.draftQuantity > 0)
                        Text(
                          'Original: ${_selectedAvailableItem!.originalQuantity.toStringAsFixed(0)} | '
                          'Acreditada: ${_selectedAvailableItem!.creditedQuantity.toStringAsFixed(0)} | '
                          'En borrador: ${_selectedAvailableItem!.draftQuantity.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: textSize - 2,
                            color: ElegantLightTheme.textSecondary,
                          ),
                        ),
                      if (_selectedAvailableItem!.hasDraft)
                        Text(
                          'Borradores: ${_selectedAvailableItem!.draftCreditNoteNumbers.join(", ")}',
                          style: TextStyle(
                            fontSize: textSize - 2,
                            color: ElegantLightTheme.warningGradient.colors.first,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
      else if (_hasAvailableItems)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${_availableItemsCount} producto(s) con cantidad disponible para acreditar',
            style: TextStyle(
              fontSize: textSize - 2,
              color: ElegantLightTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        )
      else if (widget.invoiceItems != null && widget.invoiceItems!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${widget.invoiceItems!.length} producto(s) disponible(s) en la factura',
            style: TextStyle(
              fontSize: textSize - 2,
              color: ElegantLightTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  /// Verifica si hay items con cantidades disponibles
  bool get _hasAvailableItems =>
      widget.availableItems != null &&
      widget.availableItems!.any((item) => item.availableQuantity > 0);

  /// Cuenta los items con cantidades disponibles
  int get _availableItemsCount =>
      widget.availableItems?.where((item) => item.availableQuantity > 0).length ?? 0;

  void _showProductSelector(double textSize, double padding) {
    // Usar cantidades disponibles si están disponibles
    final useAvailableItems = widget.availableItems != null && widget.availableItems!.isNotEmpty;
    final availableItemsWithQuantity = widget.availableItems
        ?.where((item) => item.availableQuantity > 0)
        .toList() ?? [];

    if (useAvailableItems && availableItemsWithQuantity.isEmpty) {
      Get.snackbar(
        'Sin disponibilidad',
        'No hay productos con cantidad disponible para acreditar. Todos los productos ya han sido acreditados.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ElegantLightTheme.warningGradient.colors.first,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (!useAvailableItems && (widget.invoiceItems == null || widget.invoiceItems!.isEmpty)) {
      Get.snackbar(
        'No hay productos',
        'No hay productos en esta factura para seleccionar',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ElegantLightTheme.warningGradient.colors.first,
        colorText: Colors.white,
      );
      return;
    }

    Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar para indicar que es arrastrable
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                margin: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar Producto',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: textSize + 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            useAvailableItems
                                ? 'Solo productos con cantidad disponible'
                                : 'Toca un producto para seleccionarlo',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.8),
                              fontSize: textSize - 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Lista de productos
              Flexible(
                child: useAvailableItems
                    ? _buildAvailableItemsList(availableItemsWithQuantity, textSize, padding)
                    : _buildInvoiceItemsList(textSize, padding),
              ),
              // Padding inferior para SafeArea
              SizedBox(height: MediaQuery.of(context).padding.bottom + padding),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 200),
      exitBottomSheetDuration: const Duration(milliseconds: 150),
    );
  }

  /// Lista de items con cantidades disponibles (nueva)
  Widget _buildAvailableItemsList(
    List<AvailableQuantityItem> items,
    double textSize,
    double padding,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.all(padding),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final availableItem = items[index];
        final isFullyCredited = availableItem.isFullyCredited;
        final hasDraft = availableItem.hasDraft;

        return Padding(
          padding: EdgeInsets.only(bottom: padding / 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isFullyCredited
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _selectAvailableItem(availableItem);
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: isFullyCredited
                      ? ElegantLightTheme.surfaceColor.withValues(alpha:0.5)
                      : ElegantLightTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasDraft
                        ? ElegantLightTheme.warningGradient.colors.first.withValues(alpha:0.5)
                        : ElegantLightTheme.textTertiary.withValues(alpha:0.1),
                    width: hasDraft ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: isFullyCredited
                            ? LinearGradient(
                                colors: [Colors.grey[400]!, Colors.grey[500]!],
                              )
                            : ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isFullyCredited ? Icons.check_circle : Icons.inventory_2,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            availableItem.description,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: textSize,
                              color: isFullyCredited
                                  ? ElegantLightTheme.textTertiary
                                  : ElegantLightTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Cantidad disponible
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isFullyCredited
                                      ? Colors.grey.withValues(alpha:0.1)
                                      : ElegantLightTheme.successGradient.colors.first.withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Disponible: ${availableItem.availableQuantity.toStringAsFixed(availableItem.availableQuantity.truncateToDouble() == availableItem.availableQuantity ? 0 : 2)}',
                                  style: TextStyle(
                                    fontSize: textSize - 2,
                                    color: isFullyCredited
                                        ? Colors.grey
                                        : ElegantLightTheme.successGradient.colors.first,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Cantidad original
                              Text(
                                'de ${availableItem.originalQuantity.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: textSize - 2,
                                  color: ElegantLightTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Precio
                              Text(
                                AppFormatters.formatCurrency(availableItem.unitPrice),
                                style: TextStyle(
                                  fontSize: textSize - 1,
                                  color: ElegantLightTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          // Mostrar si tiene borradores
                          if (hasDraft)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    size: 14,
                                    color: ElegantLightTheme.warningGradient.colors.first,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'En borrador: ${availableItem.draftCreditNoteNumbers.join(", ")}',
                                      style: TextStyle(
                                        fontSize: textSize - 3,
                                        color: ElegantLightTheme.warningGradient.colors.first,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isFullyCredited)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ElegantLightTheme.successGradient.colors.first.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: ElegantLightTheme.successGradient.colors.first,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.block,
                          size: 20,
                          color: Colors.grey,
                        ),
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

  /// Lista de items de factura (fallback original)
  Widget _buildInvoiceItemsList(double textSize, double padding) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.all(padding),
      itemCount: widget.invoiceItems!.length,
      itemBuilder: (context, index) {
        final invoiceItem = widget.invoiceItems![index];
        return Padding(
          padding: EdgeInsets.only(bottom: padding / 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                _selectInvoiceItem(invoiceItem);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ElegantLightTheme.textTertiary.withValues(alpha:0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoiceItem.description ?? 'Sin descripción',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: textSize,
                              color: ElegantLightTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ElegantLightTheme.primaryGradient.colors.first.withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Cant: ${invoiceItem.quantity}',
                                  style: TextStyle(
                                    fontSize: textSize - 2,
                                    color: ElegantLightTheme.primaryGradient.colors.first,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppFormatters.formatCurrency(invoiceItem.unitPrice ?? 0),
                                style: TextStyle(
                                  fontSize: textSize - 1,
                                  color: ElegantLightTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.successGradient.colors.first.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: ElegantLightTheme.successGradient.colors.first,
                      ),
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

  /// Seleccionar un item de las cantidades disponibles
  void _selectAvailableItem(AvailableQuantityItem availableItem) {
    setState(() {
      _selectedAvailableItem = availableItem;
      _selectedInvoiceItemId = availableItem.invoiceItemId;
      _maxQuantity = availableItem.availableQuantity;
      _descriptionController.text = availableItem.description;
      _quantityController.text = NumberInputFormatter.formatValueForDisplay(
        availableItem.availableQuantity,
        allowDecimals: true,
      );
      _unitPriceController.text = NumberInputFormatter.formatValueForDisplay(
        availableItem.unitPrice,
        allowDecimals: false,
      );
      _unit = availableItem.unit;
      _discountPercentageController.text = '0';
    });
    _calculateSubtotal();

    Get.snackbar(
      'Producto seleccionado',
      'Cantidad máxima disponible: ${availableItem.availableQuantity.toStringAsFixed(availableItem.availableQuantity.truncateToDouble() == availableItem.availableQuantity ? 0 : 2)} ${availableItem.unit}',
      snackPosition: SnackPosition.TOP,
      backgroundColor: ElegantLightTheme.successGradient.colors.first,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(Icons.check_circle, color: Colors.white),
      ),
    );
  }

  void _selectInvoiceItem(dynamic invoiceItem) {
    // Actualizar los campos del formulario con formato
    // NOTA: El descuento por defecto es 0 en la nota de crédito
    // porque normalmente se devuelve el precio completo del producto
    print('🔍 DEBUG _selectInvoiceItem:');
    print('   - description: ${invoiceItem.description}');
    print('   - quantity: ${invoiceItem.quantity}');
    print('   - unitPrice: ${invoiceItem.unitPrice}');
    print('   - subtotal: ${invoiceItem.subtotal}');

    setState(() {
      _descriptionController.text = invoiceItem.description ?? '';
      _quantityController.text = NumberInputFormatter.formatValueForDisplay(
        (invoiceItem.quantity ?? 0).toDouble(),
        allowDecimals: true,
      );
      _unitPriceController.text = NumberInputFormatter.formatValueForDisplay(
        (invoiceItem.unitPrice ?? 0).toDouble(),
        allowDecimals: false,
      );
      _unit = invoiceItem.unit ?? 'UND';
      // Descuento por defecto 0 - el usuario puede cambiarlo si necesita
      _discountPercentageController.text = '0';
    });
    _calculateSubtotal();

    // DEBUG: Verificar subtotal calculado
    print('   - _subtotal calculado: $_subtotal');

    // Mostrar feedback visual
    Get.snackbar(
      'Producto seleccionado',
      invoiceItem.description ?? 'Producto cargado correctamente',
      snackPosition: SnackPosition.TOP,
      backgroundColor: ElegantLightTheme.successGradient.colors.first,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(Icons.check_circle, color: Colors.white),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double textSize,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: textSize,
        color: ElegantLightTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha:0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ElegantLightTheme.primaryGradient.colors.first,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: ElegantLightTheme.surfaceColor,
      ),
    );
  }

  Widget _buildQuantityField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double textSize,
    void Function(String)? onChanged,
  }) {
    // Determinar el label con la cantidad máxima si está disponible
    final hasMaxLimit = _maxQuantity != double.infinity;
    final maxQtyStr = hasMaxLimit
        ? _maxQuantity.toStringAsFixed(_maxQuantity.truncateToDouble() == _maxQuantity ? 0 : 2)
        : '';
    final labelWithMax = hasMaxLimit ? '$label (máx: $maxQtyStr)' : label;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        QuantityInputFormatter(), // Permite decimales con formato
      ],
      onChanged: (value) {
        // Validar en tiempo real si excede la cantidad máxima
        if (hasMaxLimit) {
          final currentValue = NumberInputFormatter.getNumericValue(value) ?? 0.0;
          if (currentValue > _maxQuantity) {
            // Ajustar automáticamente al máximo permitido
            final formattedMax = NumberInputFormatter.formatValueForDisplay(
              _maxQuantity,
              allowDecimals: true,
            );
            controller.text = formattedMax;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: formattedMax.length),
            );

            // Mostrar mensaje informativo
            Get.snackbar(
              'Cantidad ajustada',
              'La cantidad máxima disponible es $maxQtyStr',
              snackPosition: SnackPosition.TOP,
              backgroundColor: ElegantLightTheme.warningGradient.colors.first,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
              icon: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.warning_amber, color: Colors.white),
              ),
            );
          }
        }
        // Llamar al callback original
        onChanged?.call(value);
      },
      style: TextStyle(
        fontSize: textSize,
        color: ElegantLightTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: labelWithMax,
        prefixIcon: Icon(icon, size: 20),
        // Mostrar indicador de cantidad máxima
        suffixIcon: hasMaxLimit
            ? Tooltip(
                message: 'Cantidad máxima disponible: $maxQtyStr',
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.infoGradient.colors.first.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'máx: $maxQtyStr',
                    style: TextStyle(
                      fontSize: textSize - 2,
                      color: ElegantLightTheme.infoGradient.colors.first,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasMaxLimit
                ? ElegantLightTheme.infoGradient.colors.first.withValues(alpha:0.3)
                : ElegantLightTheme.textTertiary.withValues(alpha:0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ElegantLightTheme.primaryGradient.colors.first,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: ElegantLightTheme.surfaceColor,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo es requerido';
        }
        final number = NumberInputFormatter.getNumericValue(value);
        if (number == null || number <= 0) {
          return 'Debe ser mayor a 0';
        }
        if (hasMaxLimit && number > _maxQuantity) {
          return 'Máximo permitido: $maxQtyStr';
        }
        return null;
      },
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double textSize,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        PriceInputFormatter(), // Sin decimales con formato de miles
      ],
      onChanged: onChanged,
      style: TextStyle(
        fontSize: textSize,
        color: ElegantLightTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        prefixText: '\$ ',
        prefixStyle: TextStyle(
          color: ElegantLightTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: textSize,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha:0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ElegantLightTheme.primaryGradient.colors.first,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: ElegantLightTheme.surfaceColor,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo es requerido';
        }
        final number = NumberInputFormatter.getNumericValue(value);
        if (number == null || number <= 0) {
          return 'Debe ser mayor a 0';
        }
        return null;
      },
    );
  }

  /// Campo específico para descuento que permite 0
  Widget _buildDiscountField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double textSize,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: onChanged,
      style: TextStyle(
        fontSize: textSize,
        color: ElegantLightTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Opcional - puede ser 0',
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha:0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ElegantLightTheme.primaryGradient.colors.first,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: ElegantLightTheme.surfaceColor,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo es requerido';
        }
        final number = double.tryParse(value);
        if (number == null || number < 0) {
          return 'Debe ser 0 o mayor';
        }
        if (number > 100) {
          return 'No puede ser mayor a 100%';
        }
        return null;
      },
    );
  }

  Widget _buildUnitSelector(double textSize, double padding) {
    final units = ['UND', 'KG', 'LB', 'LT', 'ML', 'M', 'CM', 'CAJA', 'PAQ'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unidad',
          style: TextStyle(
            fontSize: textSize - 1,
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              units.map((unit) {
                final isSelected = _unit == unit;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _unit = unit;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: padding / 2,
                    ),
                    decoration: BoxDecoration(
                      gradient:
                          isSelected ? ElegantLightTheme.primaryGradient : null,
                      color: isSelected ? null : ElegantLightTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? Colors.transparent
                                : ElegantLightTheme.textTertiary.withValues(alpha:
                                  0.2,
                                ),
                      ),
                    ),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color:
                            isSelected
                                ? Colors.white
                                : ElegantLightTheme.textPrimary,
                        fontSize: textSize - 1,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount,
    double textSize,
    Color color, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: textSize,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
        Text(
          AppFormatters.formatCurrency(amount),
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
