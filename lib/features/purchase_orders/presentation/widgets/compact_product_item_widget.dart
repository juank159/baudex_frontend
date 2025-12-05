import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/purchase_order_form_controller.dart' as form_controller;
import '../controllers/purchase_order_form_controller.dart';
import 'product_selector_widget.dart';

// Formatter que permite números con formateo de miles en tiempo real
class RealTimeCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Extraer solo los dígitos
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Evitar ceros a la izquierda innecesarios
    digitsOnly = digitsOnly.replaceAll(RegExp(r'^0+'), '');
    if (digitsOnly.isEmpty) {
      digitsOnly = '0';
    }

    // Formatear con separadores de miles usando AppFormatters
    final number = int.parse(digitsOnly);
    final formatted = AppFormatters.formatNumber(number);

    // Calcular la nueva posición del cursor
    int newCursorPosition = formatted.length;

    // Si el usuario está escribiendo al final, mantener el cursor al final
    if (newValue.selection.baseOffset == newValue.text.length) {
      newCursorPosition = formatted.length;
    } else {
      // Para posiciones intermedias, mantener la posición relativa
      final oldDigitsCount =
          oldValue.text.replaceAll(RegExp(r'[^0-9]'), '').length;
      final newDigitsCount = digitsOnly.length;

      if (newDigitsCount > oldDigitsCount) {
        // Se agregó un dígito, mover el cursor al final
        newCursorPosition = formatted.length;
      } else {
        // Se eliminó un dígito, mantener posición proporcional
        newCursorPosition = formatted.length;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }
}

class CompactProductItemWidget extends StatefulWidget {
  final PurchaseOrderItemForm item;
  final int index;
  final Function(int) onQuantityChanged;
  final Function(double) onPriceChanged;
  final Function(double) onDiscountChanged;
  final VoidCallback? onRemove;
  final Function(dynamic) onProductSelected;

  const CompactProductItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onDiscountChanged,
    this.onRemove,
    required this.onProductSelected,
  });

  @override
  State<CompactProductItemWidget> createState() =>
      _CompactProductItemWidgetState();
}

class _CompactProductItemWidgetState extends State<CompactProductItemWidget> {
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  bool _isUpdatingInternally = false;

  /// Determina si el item debe mantenerse expandido para completar información básica
  bool get _shouldStayExpanded {
    // Mantener expandido si:
    // 1. No hay producto seleccionado
    // 2. Hay producto pero no hay precio unitario
    // 3. Hay producto y precio pero cantidad es 0
    return widget.item.productId.isEmpty ||
        widget.item.unitPrice <= 0 ||
        widget.item.quantity <= 0;
  }

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _priceController = TextEditingController();
    _discountController = TextEditingController();

    // Set initial values with formatting
    _quantityController.text = widget.item.quantity.toString();
    _priceController.text =
        widget.item.unitPrice > 0
            ? AppFormatters.formatNumber(widget.item.unitPrice.toInt())
            : '';
    _discountController.text =
        widget.item.discountPercentage > 0
            ? widget.item.discountPercentage.toString()
            : '';
  }

  @override
  void didUpdateWidget(CompactProductItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Actualizar los valores de los controladores si el item cambió externamente
    if (oldWidget.item != widget.item && !_isUpdatingInternally) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _quantityController.text = widget.item.quantity.toString();
        _priceController.text =
            widget.item.unitPrice > 0
                ? AppFormatters.formatNumber(widget.item.unitPrice.toInt())
                : '';
        _discountController.text =
            widget.item.discountPercentage > 0
                ? widget.item.discountPercentage.toString()
                : '';
      });
    }
    // Reset flag after update
    if (_isUpdatingInternally) {
      _isUpdatingInternally = false;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: ExpansionTile(
        initiallyExpanded: _shouldStayExpanded,
        title: _buildCompactTitle(),
        subtitle: _buildCompactSubtitle(),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppFormatters.formatCurrency(
                widget.item.quantity *
                    widget.item.unitPrice *
                    (1 - widget.item.discountPercentage / 100),
              ),
              style: Get.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (widget.onRemove != null) ...[
              const SizedBox(width: AppDimensions.paddingSmall),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18),
                onPressed: widget.onRemove,
                color: Colors.red.shade600,
                tooltip: 'Eliminar',
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ],
        ),
        children: [_buildExpandedContent()],
      ),
    );
  }

  Widget _buildCompactTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                widget.item.productId.isNotEmpty
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '#${widget.index + 1}',
            style: Get.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  widget.item.productId.isNotEmpty
                      ? AppColors.primary
                      : Colors.orange.shade700,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
        Expanded(
          child: Text(
            widget.item.productName.isNotEmpty
                ? widget.item.productName
                : 'Seleccionar producto...',
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight:
                  widget.item.productName.isNotEmpty
                      ? FontWeight.w600
                      : FontWeight.normal,
              color:
                  widget.item.productName.isNotEmpty
                      ? null
                      : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSubtitle() {
    if (widget.item.productId.isEmpty) {
      return Text(
        'Toca para seleccionar un producto',
        style: Get.textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Text(
      '${AppFormatters.formatStock(widget.item.quantity)} × ${AppFormatters.formatCurrency(widget.item.unitPrice)}',
      style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de producto
          Text(
            'Producto',
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          ProductSelectorWidget(
            selectedProduct: null,
            controller: Get.find<PurchaseOrderFormController>(),
            hint:
                widget.item.productName.isNotEmpty
                    ? widget.item.productName
                    : 'Buscar y seleccionar producto',
            activateOnTextFieldTap: true,
            onProductSelected: widget.onProductSelected,
            onClearProduct: () {
              // Limpiar el producto
            },
          ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Campos de cantidad, precio y descuento en una fila
          Text(
            'Detalles',
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),

          Row(
            children: [
              // Cantidad
              Expanded(flex: 2, child: _buildQuantityField()),
              const SizedBox(width: AppDimensions.paddingSmall),

              // Precio
              Expanded(flex: 3, child: _buildPriceField()),
              const SizedBox(width: AppDimensions.paddingSmall),

              // Descuento
              Expanded(
                flex: 2,
                child: _buildCompactNumberField(
                  controller: _discountController,
                  label: 'Desc. %',
                  icon: Icons.percent,
                  onChanged: (value) {
                    final discount =
                        double.tryParse(
                          value.replaceAll(RegExp(r'[^0-9.]'), ''),
                        ) ??
                        0.0;
                    _isUpdatingInternally = true;
                    widget.onDiscountChanged(discount);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Total del item
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total del Ítem:',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(
                    widget.item.quantity *
                        widget.item.unitPrice *
                        (1 - widget.item.discountPercentage / 100),
                  ),
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: 'Cantidad',
        prefixIcon: Icon(Icons.format_list_numbered, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSmall,
          vertical: AppDimensions.paddingSmall,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        isDense: true,
      ),
      style: Get.textTheme.bodySmall,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        final quantity = int.tryParse(value) ?? 0;
        _isUpdatingInternally = true;
        widget.onQuantityChanged(quantity);
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: InputDecoration(
        labelText: 'Precio Unit.',
        prefixIcon: Icon(Icons.attach_money, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSmall,
          vertical: AppDimensions.paddingSmall,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        isDense: true,
      ),
      style: Get.textTheme.bodySmall,
      keyboardType: TextInputType.number,
      inputFormatters: [
        RealTimeCurrencyFormatter(), // Formato en tiempo real con separadores
      ],
      onChanged: (value) {
        // Usar AppFormatters para parsear el número formateado
        final price = AppFormatters.parseNumber(value) ?? 0.0;
        print('💰 DEBUG: Precio formateado: "$value" -> parsed: $price');
        // Marcar que estamos actualizando internamente para evitar ciclos
        _isUpdatingInternally = true;
        widget.onPriceChanged(price);
      },
    );
  }

  Widget _buildCompactNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSmall,
          vertical: AppDimensions.paddingSmall,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        isDense: true,
      ),
      style: Get.textTheme.bodySmall,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,\s\$]')),
      ],
      onChanged: onChanged,
    );
  }
}
