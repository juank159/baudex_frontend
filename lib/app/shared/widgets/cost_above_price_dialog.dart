// lib/app/shared/widgets/cost_above_price_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/elegant_light_theme.dart';
import '../../core/utils/formatters.dart';

/// Un producto cuyo costo por unidad supera su precio de venta por unidad.
class CostAbovePrice {
  final String productName;
  final double unitCost;
  final double unitPrice;

  const CostAbovePrice({
    required this.productName,
    required this.unitCost,
    required this.unitPrice,
  });

  /// `null` si el costo es razonable (o no hay precio con qué comparar).
  ///
  /// El error típico es anotar el costo del paquete o la caja como costo por
  /// unidad: los lotes quedan con un costo varias veces mayor al precio y
  /// cada venta registra pérdida (p. ej. chorizos a 14.000 la unidad que se
  /// venden a 2.500).
  static CostAbovePrice? check({
    required String productName,
    required double unitCost,
    required double? unitPrice,
  }) {
    if (unitPrice == null || unitPrice <= 0 || unitCost <= unitPrice) {
      return null;
    }
    return CostAbovePrice(
      productName: productName,
      unitCost: unitCost,
      unitPrice: unitPrice,
    );
  }
}

/// Pide confirmación antes de guardar costos mayores al precio de venta.
/// Devuelve `true` si el usuario decide guardar así (o si no hay avisos) y
/// `false` si quiere corregir.
Future<bool> confirmCostsAbovePrice(List<CostAbovePrice> warnings) async {
  if (warnings.isEmpty) return true;

  final result = await Get.dialog<bool>(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: ElegantLightTheme.warningOrange),
          const SizedBox(width: 8),
          const Expanded(child: Text('Revisa el costo')),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                warnings.length == 1
                    ? 'El costo por unidad es mayor que el precio de venta:'
                    : 'Estos productos tienen un costo por unidad mayor que su precio de venta:',
              ),
              const SizedBox(height: 12),
              for (final w in warnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Costo ${AppFormatters.formatCurrency(w.unitCost)}  ·  '
                        'Precio ${AppFormatters.formatCurrency(w.unitPrice)}  '
                        '(${AppFormatters.formatStock(w.unitCost / w.unitPrice)} veces)',
                        style: TextStyle(
                          color: ElegantLightTheme.errorRed,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              const Text(
                '¿Ingresaste el costo del paquete o la caja? El costo debe ser '
                'por UNIDAD: divide lo que pagaste por el paquete entre las '
                'unidades que trae.\n\nSi lo guardas así, cada venta de este '
                'producto se registrará con pérdida.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Guardar así'),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Corregir'),
        ),
      ],
    ),
    barrierDismissible: false,
  );
  return result ?? false;
}
