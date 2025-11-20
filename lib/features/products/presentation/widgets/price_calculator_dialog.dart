// lib/features/products/presentation/widgets/price_calculator_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';

// Formatter para precios con separadores de miles
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Evitar ceros a la izquierda innecesarios
    digitsOnly = digitsOnly.replaceAll(RegExp(r'^0+'), '');
    if (digitsOnly.isEmpty) {
      digitsOnly = '0';
    }

    final number = int.parse(digitsOnly);
    final formatted = AppFormatters.formatNumber(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PriceCalculatorDialog extends StatefulWidget {
  final String initialCost;
  final Function(Map<String, double>) onCalculate;

  const PriceCalculatorDialog({
    super.key,
    required this.initialCost,
    required this.onCalculate,
  });

  @override
  State<PriceCalculatorDialog> createState() => _PriceCalculatorDialogState();
}

class _PriceCalculatorDialogState extends State<PriceCalculatorDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _costController;
  final Map<String, TextEditingController> _percentageControllers = {
    'price1': TextEditingController(text: '30'),
    'price2': TextEditingController(text: '20'),
    'price3': TextEditingController(text: '15'),
    'special': TextEditingController(text: '10'),
  };

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController(text: widget.initialCost);

    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.elasticCurve,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _costController.dispose();
    _percentageControllers.forEach((_, controller) => controller.dispose());
    _animationController.dispose();
    super.dispose();
  }

  void _calculate() {
    final cost = AppFormatters.parseNumber(_costController.text) ?? 0;

    if (cost <= 0) {
      Get.snackbar('Error', 'El costo debe ser un número positivo');
      return;
    }

    final calculatedPrices = <String, double>{};
    calculatedPrices['cost'] = cost;

    _percentageControllers.forEach((key, controller) {
      final percentage = double.tryParse(controller.text) ?? 0;
      calculatedPrices[key] = cost * (1 + (percentage / 100));
    });

    Navigator.of(context).pop();
    widget.onCalculate(calculatedPrices);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: FuturisticContainer(
                padding: const EdgeInsets.all(24),
                hasGlow: true,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with gradient
                      _buildHeader(context),
                      const SizedBox(height: 24),

                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildCostField(),
                              const SizedBox(height: 20),
                              _buildDivider(),
                              const SizedBox(height: 16),
                              _buildMarginsSection(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Actions
                      _buildActions(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ElegantLightTheme.glowShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calculate_rounded,
              color: Colors.white,
              size: isMobile ? 18 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Text(
              isMobile ? 'Calculadora' : 'Calculadora de Precios',
              style: TextStyle(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            iconSize: isMobile ? 20 : 24,
            padding: EdgeInsets.all(isMobile ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isMobile ? 32 : 40,
              minHeight: isMobile ? 32 : 40,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostField() {
    return FuturisticContainer(
      padding: const EdgeInsets.all(16),
      gradient: ElegantLightTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Precio de Costo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _costController,
            label: 'Ingrese el costo del producto',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.payments_outlined,
            inputFormatters: [CurrencyInputFormatter()],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            ElegantLightTheme.textTertiary.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildMarginsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final isMobile = ResponsiveHelper.isMobile(context);
            return Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 4 : 6),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: isMobile ? 14 : 16,
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Flexible(
                  child: Text(
                    isMobile ? 'Márgenes (%)' : 'Márgenes de Ganancia (%)',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 16,
                      fontWeight: FontWeight.bold,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _buildPercentageField(
          'Precio al Público',
          'price1',
          Icons.shopping_cart_outlined,
          ElegantLightTheme.successGradient,
        ),
        const SizedBox(height: 12),
        _buildPercentageField(
          'Precio Mayorista',
          'price2',
          Icons.store_outlined,
          ElegantLightTheme.infoGradient,
        ),
        const SizedBox(height: 12),
        _buildPercentageField(
          'Precio Distribuidor',
          'price3',
          Icons.local_shipping_outlined,
          ElegantLightTheme.warningGradient,
        ),
        const SizedBox(height: 12),
        _buildPercentageField(
          'Precio Especial',
          'special',
          Icons.star_outline,
          LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade600],
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageField(
    String label,
    String key,
    IconData icon,
    LinearGradient gradient,
  ) {
    return FuturisticContainer(
      padding: const EdgeInsets.all(12),
      gradient: ElegantLightTheme.cardGradient,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _percentageControllers[key]!,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: ElegantLightTheme.textTertiary
                                  .withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: ElegantLightTheme.textTertiary
                                  .withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: ElegantLightTheme.primaryBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.percent,
                      size: 18,
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Row(
      children: [
        Expanded(
          child: ElegantButton(
            text: 'Cancelar',
            icon: isMobile ? null : Icons.close,
            gradient: LinearGradient(
              colors: [Colors.grey.shade400, Colors.grey.shade600],
            ),
            height: isMobile ? 44 : 48,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: ElegantButton(
            text: isMobile ? 'Aplicar' : 'Calcular y Aplicar',
            icon: isMobile ? null : Icons.check_circle_outline,
            gradient: ElegantLightTheme.primaryGradient,
            height: isMobile ? 44 : 48,
            onPressed: _calculate,
          ),
        ),
      ],
    );
  }
}
