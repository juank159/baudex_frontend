import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/purchase_order_form_controller.dart';
import 'product_selector_widget.dart';

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

  // Multi-moneda: cuando están seteados, el campo "Precio" acepta el valor
  // EN la moneda extranjera y se convierte a base internamente.
  final String? foreignCurrency; // código ej: "VES"
  final String baseCurrency; // código base de la organización, ej: "COP"
  final double? exchangeRate; // 1 foreign = rate base
  final Function(double)? onForeignPriceChanged;

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
    this.foreignCurrency,
    this.baseCurrency = 'COP',
    this.exchangeRate,
    this.onForeignPriceChanged,
  });

  /// True cuando el widget debe mostrar el precio en moneda extranjera.
  bool get isForeignMode =>
      foreignCurrency != null &&
      foreignCurrency != baseCurrency &&
      (exchangeRate ?? 0) > 0;

  /// Valor mostrado en el campo de precio según modo (base o foreign).
  /// En modo foreign prefiere `foreignUnitPrice`; si no existe, deriva de
  /// `unitPrice / rate` para que el usuario vea el equivalente de lo que ya
  /// estaba guardado.
  double displayPrice() {
    if (!isForeignMode) return item.unitPrice;
    final f = item.foreignUnitPrice;
    if (f != null) return f;
    final r = exchangeRate!;
    return item.unitPrice / r;
  }

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

  /// Texto inicial del input de precio según modo (base o foreign).
  /// Usa el formato es_CO consistente con PriceInputFormatter:
  /// punto = miles, coma = decimal. Ej: 10000 → "10.000", 583.33 → "583,33".
  String _initialPriceText() {
    final displayed = widget.displayPrice();
    if (displayed <= 0) return '';
    return PriceFormat.format(displayed);
  }

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.quantity > 0 ? widget.item.quantity.toString() : '1',
    );
    _priceController = TextEditingController(
      text: _initialPriceText(),
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

    // Detectar cambios de contexto multi-moneda que exigen refrescar el
    // texto del input de precio (cambio de moneda, cambio de tasa).
    final currencyContextChanged =
        oldWidget.foreignCurrency != widget.foreignCurrency ||
            oldWidget.exchangeRate != widget.exchangeRate ||
            oldWidget.baseCurrency != widget.baseCurrency;

    // Actualizar controllers si cambian externamente
    if ((oldWidget.item != widget.item || currencyContextChanged) &&
        !_isUpdatingInternally) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.item.quantity > 0) {
          _quantityController.text = widget.item.quantity.toString();
        }
        // Refrescar precio según modo actual (base o foreign).
        final newPriceText = _initialPriceText();
        if (_priceController.text != newPriceText) {
          _priceController.text = newPriceText;
        }
        if (widget.item.discountPercentage > 0) {
          _discountController.text =
              widget.item.discountPercentage.toStringAsFixed(0);
        }
      });
    }
    if (_isUpdatingInternally) _isUpdatingInternally = false;

    // Si se activa para edición y ya tiene producto, mostrar campos + auto-scroll
    if (!oldWidget.isActive && widget.isActive && widget.item.productId.isNotEmpty) {
      _fieldsAnimController.forward();
      // Auto-scroll after form expansion animation completes
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      });
    }

    // Auto-scroll when becoming active (even without product selected)
    if (!oldWidget.isActive && widget.isActive && widget.item.productId.isEmpty) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      });
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
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${widget.index + 1}',
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Buscar producto',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
              if (widget.onRemove != null)
                _actionIcon(Icons.close, AppColors.error, widget.onRemove!),
            ],
          ),
          const SizedBox(height: 8),
          ProductSelectorWidget(
            selectedProduct: null,
            controller: Get.find<PurchaseOrderFormController>(),
            hint: 'Nombre, SKU o código...',
            activateOnTextFieldTap: true,
            autoActivate: true,
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
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header compacto con producto seleccionado
          _buildProductHeader(),

          // Campos animados
          SlideTransition(
            position: _fieldsSlide,
            child: FadeTransition(
              opacity: _fieldsOpacity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Column(
                  children: [
                    _buildFieldsRow(),
                    const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(9),
          topRight: Radius.circular(9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '#${widget.index + 1}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.item.productName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => widget.onProductSelected(null),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.swap_horiz, color: Colors.orange.shade700, size: 20),
              ),
            ),
          ),
          if (widget.onRemove != null) ...[
            const SizedBox(width: 4),
            _actionIcon(Icons.close, AppColors.error, widget.onRemove!),
          ],
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
        // Precio unitario — label + conversor en modo moneda extranjera
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(
                controller: _priceController,
                label: widget.isForeignMode
                    ? 'Precio en ${widget.foreignCurrency}'
                    : 'Precio Unitario',
                icon: Icons.attach_money,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                // DecimalPriceInputFormatter: convención es_CO estricta.
                //   - Punto = SIEMPRE miles (10.000, 1.000.000)
                //   - Coma = SIEMPRE decimal (10.000,50)
                // Evita el bug del RateInputFormatter donde "1.0000" se
                // interpretaba como 1.0 perdiendo los ceros.
                formatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  DecimalPriceInputFormatter(),
                ],
                onChanged: (value) {
                  final price = PriceFormat.parse(value) ?? 0.0;
                  _isUpdatingInternally = true;
                  if (widget.isForeignMode &&
                      widget.onForeignPriceChanged != null) {
                    widget.onForeignPriceChanged!(price);
                  } else {
                    widget.onPriceChanged(price);
                  }
                },
              ),
              if (widget.isForeignMode) _buildForeignEquivalent(),
            ],
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

  /// Línea pequeña debajo del campo de precio en modo foreign que muestra
  /// el equivalente en moneda base actualizado en tiempo real.
  Widget _buildForeignEquivalent() {
    final rate = widget.exchangeRate ?? 0;
    final foreignValue = AppFormatters.parseNumber(_priceController.text) ?? 0;
    final baseEquivalent = foreignValue * rate;
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Row(
        children: [
          Icon(Icons.sync_alt_rounded,
              size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              baseEquivalent > 0
                  ? '≈ ${AppFormatters.formatCurrency(baseEquivalent)}'
                  : '1 ${widget.foreignCurrency} = ${AppFormatters.formatRate(rate)} ${widget.baseCurrency}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isValid ? AppColors.success.withOpacity(0.08) : AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? AppColors.success.withOpacity(0.3) : AppColors.grey200,
        ),
      ),
      child: Row(
        children: [
          Text(
            AppFormatters.formatCurrency(total),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isValid ? AppColors.success : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: isValid ? () => widget.onComplete?.call() : null,
              icon: Icon(Icons.check_circle, size: 18),
              label: Text(isValid ? 'Agregar' : 'Completar', style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.grey200,
                disabledForegroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: isValid ? 1 : 0,
              ),
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
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            // Zona tappable para editar (todo excepto el botón eliminar)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onEdit,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: AppColors.successGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '#${widget.index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.productName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Text(
                                  '${widget.item.quantity} x ${AppFormatters.formatCurrency(widget.item.unitPrice)}',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                if (hasDiscount) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '-${widget.item.discountPercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warningDark),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(total),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Botón eliminar FUERA del InkWell de edición
            if (widget.onRemove != null) ...[
              const SizedBox(width: 4),
              _actionIcon(Icons.close, AppColors.error, widget.onRemove!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color),
      iconSize: 20,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      splashRadius: 18,
      tooltip: icon == Icons.close ? 'Eliminar producto' : null,
    );
  }
}
