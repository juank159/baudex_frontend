import 'package:flutter/material.dart';

/// Badge compacto que indica que un registro está pendiente de sincronización.
///
/// Muestra un icono de nube + texto "Pendiente" en naranja cuando el
/// entityId tiene un prefijo temporal (no sincronizado).
///
/// Uso:
/// ```dart
/// OfflineBadge(entityId: supplier.id)
/// ```
class OfflineBadge extends StatelessWidget {
  final String entityId;
  final List<String> offlinePrefixes;

  /// Todos los prefijos temporales conocidos del proyecto
  static const List<String> allKnownPrefixes = [
    'supplier_offline_',
    'customer_',
    'product_offline_',
    'expense_offline_',
    'inv_',
    'invoice_offline_',
    'category_offline_',
    'bank_',
    'po_',
    'po_offline_',
    'creditnote_offline_',
    'customercredit_offline_',
    'movement_',
    'batch_offline_',
  ];

  const OfflineBadge({
    super.key,
    required this.entityId,
    this.offlinePrefixes = allKnownPrefixes,
  });

  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool get _isOffline {
    // Si es un UUID válido, no es offline
    if (_uuidRegex.hasMatch(entityId)) return false;
    // Si tiene algún prefijo temporal conocido, es offline
    return offlinePrefixes.any((p) => entityId.startsWith(p));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 12, color: Colors.orange.shade700),
          const SizedBox(width: 3),
          Text(
            'Pendiente',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
