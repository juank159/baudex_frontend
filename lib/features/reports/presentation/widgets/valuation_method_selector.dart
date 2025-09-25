// lib/features/reports/presentation/widgets/valuation_method_selector.dart
import 'package:flutter/material.dart';
import '../../../../app/config/themes/app_colors.dart';

class ValuationMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodChanged;

  const ValuationMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedMethod,
      decoration: const InputDecoration(
        labelText: 'Método de Valoración',
        prefixIcon: Icon(Icons.calculate),
        border: OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: 'FIFO',
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FIFO'),
                    Text(
                      'Primero en Entrar, Primero en Salir',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'LIFO',
          child: Row(
            children: [
              Icon(
                Icons.trending_down,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIFO'),
                    Text(
                      'Último en Entrar, Primero en Salir',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'WEIGHTED_AVERAGE',
          child: Row(
            children: [
              Icon(
                Icons.balance,
                size: 16,
                color: Colors.purple,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Promedio Ponderado'),
                    Text(
                      'Costo promedio de compras',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          onMethodChanged(value);
        }
      },
    );
  }
}