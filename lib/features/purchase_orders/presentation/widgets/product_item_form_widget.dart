import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/purchase_order_form_controller.dart';
import 'product_selector_widget.dart';

// Formatter que permite números con formateo de miles en tiempo real
class _RealTimeCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '');

    digitsOnly = digitsOnly.replaceAll(RegExp(r'^0+'), '');
    if (digitsOnly.isEmpty) digitsOnly = '0';

    final number = int.parse(digitsOnly);
    final formatted = AppFormatters.formatNumber(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

enum _ItemState { searchOnly, fullForm, completed }

class ProductItemFormWidget extends StatefulWidget {
  final PurchaseOrderItemForm item;
  final int index;
  final bool isActive;
  final Function(int) onQuantityChanged;
  final Function(double) onPriceChanged;
  final Function(double) onDiscountChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final Function(dynamic) onProductSelected;

  const ProductItemFormWidget({
    super.key,
    required this.item,
    required this.index,
    required this.isActive,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onDiscountChanged,
    this.onRemove,
    this.onComplete,
    this.onEdit,
    required this.onProductSelected,
  });

  @override
  State<ProductItemFormWidget> createState() => _ProductItemFormWidgetState();
}

class _ProductItemFormWidgetState extends State<ProductItemFormWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  bool _isUpdatingInternally = false;

  late AnimationController _fieldsAnimController;
  late Animation<double> _fieldsOpacity;
  late Animation<Offset> _fieldsSlide;

  _ItemState get _currentState {
    if (widget.item.isValid && !widget.isActive) {
      return _ItemState.completed;
    }
    if (widget.isActive && widget.item.productId.isEmpty) {
      return _ItemState.searchOnly;
    }
    return widget.isActive ? _ItemState.fullForm : _ItemState.completed;
  }

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.quantity > 0 ? widget.item.quantity.toString() : '1',
    );
    _priceController = TextEditingController(
      text: widget.item.unitPrice > 0
          ? AppFormatters.formatNumber(widget.item.unitPrice.toInt())
          : '',
    );
    _discountController = TextEditingController(
      text: widget.item.discountPercentage > 0
          ? widget.item.discountPercentage.toStringAsFixed(0)
          : '',
    );

    _fieldsAnimController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fieldsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fieldsAnimController, curve: Curves.easeOut),
    );
    _fieldsSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fieldsAnimController, curve: Curves.easeOut),
    );

    if (widget.item.productId.isNotEmpty && widget.isActive) {
      _fieldsAnimController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ProductItemFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animar campos al seleccionar producto
    if (oldWidget.item.productId.isEmpty &&
        widget.item.productId.isNotEmpty &&
        widget.isActive) {
      _fieldsAnimController.forward();
    }

    // Actualizar controllers si cambian externamente
    if (oldWidget.item != widget.item && !_isUpdatingInternally) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.item.quantity > 0) {
          _quantityController.text = widget.item.quantity.toString();
        }
        if (widget.item.unitPrice > 0) {
          _priceController.text =
              AppFormatters.formatNumber(widget.item.unitPrice.toInt());
        }
        if (widget.item.discountPercentage > 0) {
          _discountController.text =
              widget.item.discountPercentage.toStringAsFixed(0);
        }
      });
    }
    if (_isUpdatingInternally) _isUpdatingInternally = false;

    // Si se activa para edición y ya tiene producto, mostrar campos
    if (!oldWidget.isActive && widget.isActive && widget.item.productId.isNotEmpty) {
      _fieldsAnimController.forward();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _fieldsAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: _buildByState(),
    );
  }

  Widget _buildByState() {
    switch (_currentState) {
      case _ItemState.searchOnly:
        return _buildSearchOnly();
      case _ItemState.fullForm:
        return _buildFullForm();
      case _ItemState.completed:
        return _buildCompletedCard();
    }
  }

  // ==================== ESTADO 1: Solo búsqueda ====================

  Widget _buildSearchOnly() {
    return Container(
      key: const ValueKey('search_only'),
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Producto #${widget.index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Busca y selecciona un producto',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ProductSelectorWidget(
            selectedProduct: null,
            controller: Get.find<PurchaseOrderFormController>(),
            hint: 'Buscar por nombre, SKU o codigo...',
            activateOnTextFieldTap: true,
            onProductSelected: widget.onProductSelected,
            onClearProduct: () {},
          ),
        ],
      ),
    );
  }

  // ==================== ESTADO 2: Formulario completo ====================

  Widget _buildFullForm() {
    final subtotal = widget.item.quantity * widget.item.unitPrice;
    final discountAmt = subtotal * (widget.item.discountPercentage / 100);
    final total = subtotal - discountAmt;
    final isValid = widget.item.isValid;

    return Container(
      key: const ValueKey('full_form'),
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con producto seleccionado
          _buildProductHeader(),

          // Campos animados
          SlideTransition(
            position: _fieldsSlide,
            child: FadeTransition(
              opacity: _fieldsOpacity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    // Row de campos
                    _buildFieldsRow(),
                    const SizedBox(height: 14),
                    // Total + boton
                    _buildTotalBar(total, isValid),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.06),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusMedium - 1),
          topRight: Radius.circular(AppDimensions.radiusMedium - 1),
        ),
      ),
      child: Row(
        children: [
          // Badge numero
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${widget.index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Ingresa cantidad y precio de compra',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Cambiar producto
          Tooltip(
            message: 'Cambiar producto',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  widget.onProductSelected(null);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Icon(Icons.refresh, color: Colors.orange.shade700, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cantidad
        Expanded(
          flex: 2,
          child: _buildField(
            controller: _quantityController,
            label: 'Cantidad',
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              final qty = int.tryParse(value) ?? 0;
              _isUpdatingInternally = true;
              widget.onQuantityChanged(qty);
            },
          ),
        ),
        const SizedBox(width: 10),
        // Precio unitario
        Expanded(
          flex: 3,
          child: _buildField(
            controller: _priceController,
            label: 'Precio Unitario',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            formatters: [_RealTimeCurrencyFormatter()],
            onChanged: (value) {
              final price = AppFormatters.parseNumber(value) ?? 0.0;
              _isUpdatingInternally = true;
              widget.onPriceChanged(price);
            },
          ),
        ),
        const SizedBox(width: 10),
        // Descuento
        Expanded(
          flex: 2,
          child: _buildField(
            controller: _discountController,
            label: 'Desc. %',
            icon: Icons.percent,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            onChanged: (value) {
              final disc = double.tryParse(
                    value.replaceAll(RegExp(r'[^0-9.]'), ''),
                  ) ??
                  0.0;
              _isUpdatingInternally = true;
              widget.onDiscountChanged(disc);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required List<TextInputFormatter> formatters,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        isDense: true,
        filled: true,
        fillColor: AppColors.grey50,
      ),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      keyboardType: keyboardType,
      inputFormatters: formatters,
      onChanged: onChanged,
    );
  }

  Widget _buildTotalBar(double total, bool isValid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.success.withOpacity(0.08)
            : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: isValid
              ? AppColors.success.withOpacity(0.3)
              : AppColors.grey200,
        ),
      ),
      child: Row(
        children: [
          // Total
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total del item',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                AppFormatters.formatCurrency(total),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isValid ? AppColors.success : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Boton agregar
          ElevatedButton.icon(
            onPressed: isValid
                ? () {
                    widget.onComplete?.call();
                  }
                : null,
            icon: Icon(isValid ? Icons.check_circle : Icons.add_circle, size: 20),
            label: Text(isValid ? 'Agregar' : 'Completa los campos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.grey200,
              disabledForegroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              elevation: isValid ? 2 : 0,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ESTADO 3: Card completada ====================

  Widget _buildCompletedCard() {
    final subtotal = widget.item.quantity * widget.item.unitPrice;
    final discountAmt = subtotal * (widget.item.discountPercentage / 100);
    final total = subtotal - discountAmt;
    final hasDiscount = widget.item.discountPercentage > 0;

    return Container(
      key: const ValueKey('completed'),
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.success.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onEdit,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Badge numero verde
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.successGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#${widget.index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '${widget.item.quantity} x ${AppFormatters.formatCurrency(widget.item.unitPrice)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${widget.item.discountPercentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warningDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Total
                Text(
                  AppFormatters.formatCurrency(total),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                // Botones
                if (widget.onEdit != null)
                  _actionIcon(Icons.edit_outlined, AppColors.primary, widget.onEdit!),
                if (widget.onRemove != null)
                  _actionIcon(Icons.close, AppColors.error, widget.onRemove!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
