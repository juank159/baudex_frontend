// lib/features/invoices/presentation/widgets/price_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_price.dart';

/// Formateador específico para campos de precio con separadores de miles
class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    String digitsOnly = newText.replaceAll('.', '').replaceAll(',', '');

    if (!RegExp(r'^\d*$').hasMatch(digitsOnly)) {
      return oldValue;
    }

    if (digitsOnly.length > 10) {
      return oldValue;
    }

    String formatted = _formatWithThousandsSeparator(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithThousandsSeparator(String digits) {
    if (digits.isEmpty || digits.length <= 3) return digits;

    String reversed = digits.split('').reversed.join();
    String formatted = '';

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted += '.';
      }
      formatted += reversed[i];
    }

    return formatted.split('').reversed.join();
  }
}

/// Clase para manejar tamaños responsive
class _SizeConfig {
  final bool isMobile;
  final bool isTablet;

  _SizeConfig({required this.isMobile, required this.isTablet});

  // Padding general
  double get dialogPadding => isMobile ? 12 : (isTablet ? 16 : 24);
  double get cardPadding => isMobile ? 10 : (isTablet ? 12 : 16);
  double get sectionSpacing => isMobile ? 12 : (isTablet ? 16 : 20);

  // Tamaños de fuente
  double get titleSize => isMobile ? 14 : (isTablet ? 16 : 18);
  double get subtitleSize => isMobile ? 12 : (isTablet ? 13 : 15);
  double get bodySize => isMobile ? 11 : (isTablet ? 12 : 14);
  double get smallSize => isMobile ? 9 : (isTablet ? 10 : 11);
  double get priceSize => isMobile ? 14 : (isTablet ? 16 : 18);
  double get priceLargeSize => isMobile ? 16 : (isTablet ? 18 : 20);

  // Tamaños de iconos
  double get iconSmall => isMobile ? 14 : (isTablet ? 16 : 18);
  double get iconMedium => isMobile ? 16 : (isTablet ? 18 : 22);
  double get iconLarge => isMobile ? 18 : (isTablet ? 20 : 24);

  // Tamaños de botones y controles
  double get buttonHeight => isMobile ? 40 : (isTablet ? 44 : 48);
  double get radioSize => isMobile ? 18 : (isTablet ? 20 : 24);
  double get checkboxSize => isMobile ? 18 : (isTablet ? 20 : 24);

  // Border radius
  double get radiusSmall => isMobile ? 6 : (isTablet ? 8 : 10);
  double get radiusMedium => isMobile ? 8 : (isTablet ? 10 : 12);
  double get radiusLarge => isMobile ? 12 : (isTablet ? 16 : 20);

  // Dialog width
  double get dialogWidth => isTablet ? 420 : 500;
}

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

class _PriceSelectorWidgetState extends State<PriceSelectorWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _customPriceController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  double? _selectedPrice;
  bool _isCustomPrice = false;

  @override
  void initState() {
    super.initState();
    _selectedPrice = widget.currentPrice;
    _customPriceController = TextEditingController(
      text: _formatPriceForInput(widget.currentPrice),
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _customPriceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  _SizeConfig _getConfig(BuildContext context) {
    return _SizeConfig(
      isMobile: Responsive.isMobile(context),
      isTablet: Responsive.isTablet(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(context);

    if (config.isMobile) {
      return _buildMobileDialog(context, config);
    } else {
      return _buildDialogModal(context, config);
    }
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileDialog(BuildContext context, _SizeConfig config) {
    return Dialog.fullscreen(
      child: Container(
        color: ElegantLightTheme.backgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Header compacto
              _buildMobileHeader(context, config),
              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(config.dialogPadding),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductInfo(context, config),
                      SizedBox(height: config.sectionSpacing),
                      _buildPricesSection(context, config),
                      SizedBox(height: config.sectionSpacing),
                      _buildCustomPriceSection(context, config),
                    ],
                  ),
                ),
              ),
              // Acciones
              _buildMobileActions(context, config),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TABLET/DESKTOP MODAL ====================
  Widget _buildDialogModal(BuildContext context, _SizeConfig config) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: config.isTablet ? 40 : 80,
              vertical: 24,
            ),
            child: Container(
              width: config.dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(config.radiusLarge),
                boxShadow: ElegantLightTheme.elevatedShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogHeader(context, config),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(config.dialogPadding),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductInfo(context, config),
                          SizedBox(height: config.sectionSpacing),
                          _buildPricesSection(context, config),
                          SizedBox(height: config.sectionSpacing),
                          _buildCustomPriceSection(context, config),
                        ],
                      ),
                    ),
                  ),
                  _buildDialogActions(context, config),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== HEADERS ====================
  Widget _buildMobileHeader(BuildContext context, _SizeConfig config) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: config.dialogPadding,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(config.radiusSmall),
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: config.iconSmall,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.attach_money,
            color: Colors.white,
            size: config.iconMedium,
          ),
          const SizedBox(width: 6),
          Text(
            'Seleccionar Precio',
            style: TextStyle(
              color: Colors.white,
              fontSize: config.subtitleSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, _SizeConfig config) {
    return Container(
      padding: EdgeInsets.all(config.cardPadding),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(config.radiusLarge),
          topRight: Radius.circular(config.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(config.isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(config.radiusSmall),
            ),
            child: Icon(
              Icons.attach_money,
              color: Colors.white,
              size: config.iconMedium,
            ),
          ),
          SizedBox(width: config.isMobile ? 8 : 10),
          Expanded(
            child: Text(
              'Seleccionar Precio',
              style: TextStyle(
                fontSize: config.titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(config.isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(config.radiusSmall),
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: config.iconSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PRODUCT INFO ====================
  Widget _buildProductInfo(BuildContext context, _SizeConfig config) {
    return Container(
      padding: EdgeInsets.all(config.cardPadding),
      decoration: BoxDecoration(
        color: ElegantLightTheme.cardColor,
        borderRadius: BorderRadius.circular(config.radiusMedium),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(config.isMobile ? 6 : 8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(config.radiusSmall),
            ),
            child: Icon(
              Icons.inventory_2,
              color: Colors.white,
              size: config.iconMedium,
            ),
          ),
          SizedBox(width: config.isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: config.bodySize,
                    color: ElegantLightTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${widget.product.sku}',
                  style: TextStyle(
                    color: ElegantLightTheme.textTertiary,
                    fontSize: config.smallSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PRICES SECTION ====================
  Widget _buildPricesSection(BuildContext context, _SizeConfig config) {
    final activePrices = widget.product.prices
            ?.where((price) => price.isActive && price.isValidNow)
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(config.isMobile ? 4 : 5),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.successGradient,
                borderRadius: BorderRadius.circular(config.radiusSmall - 2),
              ),
              child: Icon(
                Icons.sell,
                color: Colors.white,
                size: config.iconSmall,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Precios Disponibles',
              style: TextStyle(
                fontSize: config.subtitleSize,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: config.isMobile ? 8 : 10),
        if (activePrices.isNotEmpty)
          ...activePrices.map((price) => _buildPriceOption(price, config))
        else
          _buildNoPricesWarning(config),
      ],
    );
  }

  Widget _buildNoPricesWarning(_SizeConfig config) {
    return Container(
      padding: EdgeInsets.all(config.cardPadding),
      decoration: BoxDecoration(
        color: ElegantLightTheme.accentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(config.radiusMedium),
        border: Border.all(
          color: ElegantLightTheme.accentOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: ElegantLightTheme.accentOrange,
            size: config.iconMedium,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No hay precios configurados',
              style: TextStyle(
                fontSize: config.bodySize,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceOption(ProductPrice price, _SizeConfig config) {
    if (!_isPriceValid(price.finalAmount)) {
      return const SizedBox.shrink();
    }

    final priceValue = _getPriceValue(price.finalAmount);
    final isSelected = !_isCustomPrice && _selectedPrice == priceValue;

    return Padding(
      padding: EdgeInsets.only(bottom: config.isMobile ? 6 : 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isCustomPrice = false;
              _selectedPrice = priceValue;
              _customPriceController.text = _formatPriceForInput(priceValue);
            });
          },
          borderRadius: BorderRadius.circular(config.radiusMedium),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(config.isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? ElegantLightTheme.primaryBlue.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(config.radiusMedium),
              border: Border.all(
                color: isSelected
                    ? ElegantLightTheme.primaryBlue
                    : ElegantLightTheme.textTertiary.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Radio personalizado
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: config.radioSize,
                  height: config.radioSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        isSelected ? ElegantLightTheme.primaryGradient : null,
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : ElegantLightTheme.textTertiary,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check,
                          color: Colors.white, size: config.radioSize - 6)
                      : null,
                ),
                SizedBox(width: config.isMobile ? 8 : 10),

                // Info del precio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            price.type.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: config.bodySize,
                              color: isSelected
                                  ? ElegantLightTheme.primaryBlue
                                  : ElegantLightTheme.textPrimary,
                            ),
                          ),
                          if (price.hasDiscount) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: config.isMobile ? 4 : 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                gradient: ElegantLightTheme.errorGradient,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'DESC',
                                style: TextStyle(
                                  fontSize: config.smallSize - 2,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (price.name?.isNotEmpty == true)
                        Text(
                          price.name!,
                          style: TextStyle(
                            fontSize: config.smallSize,
                            color: ElegantLightTheme.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Precio
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(price.finalAmount),
                      style: TextStyle(
                        fontSize: config.priceSize,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? ElegantLightTheme.primaryBlue
                            : const Color(0xFF10B981),
                      ),
                    ),
                    if (price.hasDiscount && _isPriceValid(price.amount))
                      Text(
                        AppFormatters.formatCurrency(price.amount),
                        style: TextStyle(
                          fontSize: config.smallSize,
                          decoration: TextDecoration.lineThrough,
                          color: ElegantLightTheme.textTertiary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== CUSTOM PRICE ====================
  Widget _buildCustomPriceSection(BuildContext context, _SizeConfig config) {
    return Container(
      padding: EdgeInsets.all(config.cardPadding),
      decoration: BoxDecoration(
        color: ElegantLightTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(config.radiusMedium),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header y checkbox en una fila
          GestureDetector(
            onTap: () {
              setState(() {
                _isCustomPrice = !_isCustomPrice;
                if (_isCustomPrice) {
                  String cleanValue =
                      _customPriceController.text.replaceAll('.', '');
                  _selectedPrice = double.tryParse(cleanValue);
                }
              });
            },
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: config.checkboxSize,
                  height: config.checkboxSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: _isCustomPrice
                        ? ElegantLightTheme.primaryGradient
                        : null,
                    border: Border.all(
                      color: _isCustomPrice
                          ? Colors.transparent
                          : ElegantLightTheme.textTertiary,
                      width: 1.5,
                    ),
                  ),
                  child: _isCustomPrice
                      ? Icon(Icons.check,
                          color: Colors.white, size: config.checkboxSize - 6)
                      : null,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.all(config.isMobile ? 4 : 5),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(config.radiusSmall - 2),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: config.iconSmall,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Precio Personalizado',
                  style: TextStyle(
                    fontSize: config.subtitleSize,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Campo de precio
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isCustomPrice
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.only(top: config.isMobile ? 10 : 12),
              child: TextField(
                controller: _customPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [PriceInputFormatter()],
                style: TextStyle(
                  fontSize: config.priceSize,
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.primaryBlue,
                ),
                decoration: InputDecoration(
                  hintText: 'Ej: 25.000',
                  hintStyle: TextStyle(
                    color: ElegantLightTheme.textTertiary,
                    fontSize: config.bodySize,
                    fontWeight: FontWeight.normal,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(config.isMobile ? 6 : 8),
                    child: Container(
                      padding: EdgeInsets.all(config.isMobile ? 4 : 6),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius:
                            BorderRadius.circular(config.radiusSmall - 2),
                      ),
                      child: Icon(
                        Icons.attach_money,
                        color: Colors.white,
                        size: config.iconSmall,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(config.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(config.radiusMedium),
                    borderSide: BorderSide(
                      color: ElegantLightTheme.textTertiary.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(config.radiusMedium),
                    borderSide: const BorderSide(
                      color: ElegantLightTheme.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: config.isMobile ? 10 : 12,
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  String cleanValue = value.replaceAll('.', '');
                  _selectedPrice = double.tryParse(cleanValue);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================
  Widget _buildMobileActions(BuildContext context, _SizeConfig config) {
    final isValid = _selectedPrice != null && _selectedPrice! > 0;

    return Container(
      padding: EdgeInsets.all(config.dialogPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancelar
          Expanded(
            child: SizedBox(
              height: config.buttonHeight,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: ElegantLightTheme.textTertiary.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(config.radiusMedium),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: config.bodySize,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Aplicar
          Expanded(
            flex: 2,
            child: SizedBox(
              height: config.buttonHeight,
              child: Container(
                decoration: BoxDecoration(
                  gradient: isValid
                      ? ElegantLightTheme.successGradient
                      : const LinearGradient(
                          colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                        ),
                  borderRadius: BorderRadius.circular(config.radiusMedium),
                  boxShadow: isValid
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isValid
                        ? () => widget.onPriceChanged(_selectedPrice!)
                        : null,
                    borderRadius: BorderRadius.circular(config.radiusMedium),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: isValid ? Colors.white : Colors.grey,
                            size: config.iconMedium,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Aplicar',
                            style: TextStyle(
                              fontSize: config.bodySize,
                              fontWeight: FontWeight.w700,
                              color: isValid ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActions(BuildContext context, _SizeConfig config) {
    final isValid = _selectedPrice != null && _selectedPrice! > 0;

    return Container(
      padding: EdgeInsets.all(config.dialogPadding),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.textTertiary.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Cancelar
          Expanded(
            child: SizedBox(
              height: config.buttonHeight,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: ElegantLightTheme.textTertiary.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(config.radiusMedium),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: config.bodySize,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: config.isMobile ? 10 : 12),
          // Aplicar
          Expanded(
            flex: 2,
            child: SizedBox(
              height: config.buttonHeight,
              child: Container(
                decoration: BoxDecoration(
                  gradient: isValid
                      ? ElegantLightTheme.successGradient
                      : const LinearGradient(
                          colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                        ),
                  borderRadius: BorderRadius.circular(config.radiusMedium),
                  boxShadow: isValid
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isValid
                        ? () => widget.onPriceChanged(_selectedPrice!)
                        : null,
                    borderRadius: BorderRadius.circular(config.radiusMedium),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: isValid ? Colors.white : Colors.grey,
                            size: config.iconMedium,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Aplicar Precio',
                            style: TextStyle(
                              fontSize: config.bodySize,
                              fontWeight: FontWeight.w700,
                              color: isValid ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================
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

  double _getPriceValue(dynamic price) {
    if (price == null) return 0.0;
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      return price.toDouble();
    }
    return 0.0;
  }

  String _formatPriceForInput(double price) {
    if (price <= 0) return '';
    int priceInt = price.round();
    String priceStr = priceInt.toString();

    if (priceStr.length > 3) {
      String reversed = priceStr.split('').reversed.join();
      String formatted = '';
      for (int i = 0; i < reversed.length; i++) {
        if (i > 0 && i % 3 == 0) {
          formatted += '.';
        }
        formatted += reversed[i];
      }
      return formatted.split('').reversed.join();
    }
    return priceStr;
  }
}
