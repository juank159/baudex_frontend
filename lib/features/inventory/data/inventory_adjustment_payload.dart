// lib/features/inventory/data/inventory_adjustment_payload.dart

/// Campos que acepta `POST /inventory/adjustments/relative`
/// (`RelativeInventoryAdjustmentDto`). El servidor rechaza con 400 cualquier
/// otro campo, así que todo ajuste que se encola o se envía pasa por aquí.
const relativeAdjustmentFields = <String>{
  'productId',
  'adjustmentQuantity',
  'warehouseId',
  'notes',
  'movementDate',
  'unitCost',
  'idempotencyKey',
};

/// Deja solo los campos que el servidor acepta y quita los vacíos.
Map<String, dynamic> relativeAdjustmentPayload(Map<String, dynamic> request) => {
      for (final entry in request.entries)
        if (relativeAdjustmentFields.contains(entry.key) && entry.value != null)
          entry.key: entry.value,
    };
