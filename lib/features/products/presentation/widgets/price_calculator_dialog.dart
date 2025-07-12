import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/core/utils/formatters.dart';

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
    Key? key,
    required this.initialCost,
    required this.onCalculate,
  }) : super(key: key);

  @override
  _PriceCalculatorDialogState createState() => _PriceCalculatorDialogState();
}

class _PriceCalculatorDialogState extends State<PriceCalculatorDialog> {
  late final TextEditingController _costController;
  final Map<String, TextEditingController> _percentageControllers = {
    'price1': TextEditingController(text: '30'),
    'price2': TextEditingController(text: '20'),
    'price3': TextEditingController(text: '15'),
    'special': TextEditingController(text: '10'),
  };

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController(text: widget.initialCost);
  }

  @override
  void dispose() {
    _costController.dispose();
    _percentageControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _calculate() {
    print('🧮 PriceCalculatorDialog: Iniciando cálculo...');
    
    // Usar parseNumber para convertir el texto formateado de vuelta a número
    final cost = AppFormatters.parseNumber(_costController.text) ?? 0;
    print('🧮 PriceCalculatorDialog: Costo parseado: $cost');
    
    if (cost <= 0) {
      print('❌ PriceCalculatorDialog: Costo inválido');
      Get.snackbar('Error', 'El costo debe ser un número positivo');
      return;
    }

    final calculatedPrices = <String, double>{};
    
    // Incluir el precio de costo en los resultados
    calculatedPrices['cost'] = cost;
    print('🧮 PriceCalculatorDialog: cost -> ${calculatedPrices['cost']}');
    
    _percentageControllers.forEach((key, controller) {
      final percentage = double.tryParse(controller.text) ?? 0;
      calculatedPrices[key] = cost * (1 + (percentage / 100));
      print('🧮 PriceCalculatorDialog: $key -> $percentage% = ${calculatedPrices[key]}');
    });

    print('🧮 PriceCalculatorDialog: Llamando callback...');
    
    // Cerrar el diálogo ANTES de llamar al callback para evitar problemas
    print('🧮 PriceCalculatorDialog: Cerrando diálogo...');
    Navigator.of(context).pop();
    print('🧮 PriceCalculatorDialog: Diálogo cerrado');
    
    // Llamar al callback después de cerrar
    widget.onCalculate(calculatedPrices);
    print('🧮 PriceCalculatorDialog: Callback ejecutado');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calculadora de Precios'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _costController,
              label: 'Precio de Costo',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
              inputFormatters: [CurrencyInputFormatter()],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Márgenes de Ganancia (%)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildPercentageField('Precio al Público', 'price1'),
            _buildPercentageField('Precio Mayorista', 'price2'),
            _buildPercentageField('Precio Distribuidor', 'price3'),
            _buildPercentageField('Precio Especial', 'special'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _calculate,
          child: const Text('Calcular y Aplicar'),
        ),
      ],
    );
  }

  Widget _buildPercentageField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CustomTextField(
        controller: _percentageControllers[key]!,
        label: label,
        keyboardType: TextInputType.number,
        suffixIcon: Icons.percent,
      ),
    );
  }
}
