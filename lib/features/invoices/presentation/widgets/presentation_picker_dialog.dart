import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_presentation.dart';

/// Dialog que permite elegir en qué presentación se vende un producto
/// (cartón, cajetilla, kilo, paquete, unidad, etc.).
///
/// Devuelve la presentación seleccionada via `Get.back(result: presentation)`
/// o `null` si el usuario cancela.
class PresentationPickerDialog extends StatelessWidget {
  final Product product;
  final List<ProductPresentation> presentations;

  const PresentationPickerDialog({
    super.key,
    required this.product,
    required this.presentations,
  });

  @override
  Widget build(BuildContext context) {
    final active = presentations.where((p) => p.isActive).toList()
      ..sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });

    return AlertDialog(
      title: Text('¿Cómo se vende ${product.name}?'),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: 380,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: active.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = active[i];
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: p.isDefault
                    ? Colors.blue.shade50
                    : Colors.grey.shade100,
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: p.isDefault ? Colors.blue : Colors.grey.shade700,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (p.isDefault) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'default',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                'factor ${p.factor} · ${p.currency} ${p.price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              onTap: () => Get.back(result: p),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
