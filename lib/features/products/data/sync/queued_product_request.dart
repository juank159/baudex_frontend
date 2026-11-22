// lib/features/products/data/sync/queued_product_request.dart
//
// Arma los requests de producto a partir de lo que quedó guardado en la cola
// de sincronización. Son funciones puras (sin Isar, sin GetX) para poder
// probarlas solas.
//
// Regla: nada de lo que viene de la cola puede romper el armado. Un texto que
// no se reconoce se envía tal cual al servidor (que lo acepta o lo rechaza con
// un 4xx visible); nunca se reemplaza por un valor por defecto, porque eso
// cambiaría en silencio el impuesto o el tipo real del producto.

import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';
import '../../domain/entities/tax_enums.dart';
import '../models/create_product_request_model.dart';
import '../models/update_product_request_model.dart';

/// Valor de servidor de la categoría de impuesto guardada en la cola.
///
/// Acepta el valor (`'IVA'`) o el nombre del enum (`'iva'`). Si no la
/// reconoce, devuelve el texto tal cual; `null` o vacío → `null`.
String? queuedTaxCategoryValue(Object? raw) {
  final parsed = TaxCategory.tryParse(raw);
  if (parsed != null) return parsed.value;
  return _rawText(raw);
}

/// Igual que [queuedTaxCategoryValue] para la categoría de retención.
String? queuedRetentionCategoryValue(Object? raw) {
  final parsed = RetentionCategory.tryParse(raw);
  if (parsed != null) return parsed.value;
  return _rawText(raw);
}

/// Request de creación a partir de los datos encolados.
/// [categoryId] es la categoría ya resuelta (sin id temporal).
CreateProductRequestModel createProductRequestFromQueue(
  Map<String, dynamic> data, {
  required String categoryId,
}) {
  final rawPrices = data['prices'];
  return CreateProductRequestModel(
    name: data['name']?.toString() ?? '',
    description: data['description'] as String?,
    sku: data['sku']?.toString() ?? '',
    barcode: data['barcode'] as String?,
    type: _enumName(ProductType.values, data['type']),
    status: _enumName(ProductStatus.values, data['status']),
    stock: _toDouble(data['stock']),
    minStock: _toDouble(data['minStock']),
    unit: data['unit'] as String?,
    weight: _toDouble(data['weight']),
    length: _toDouble(data['length']),
    width: _toDouble(data['width']),
    height: _toDouble(data['height']),
    images: data['images'] != null ? List<String>.from(data['images']) : null,
    metadata: data['metadata'] is Map
        ? Map<String, dynamic>.from(data['metadata'] as Map)
        : null,
    categoryId: categoryId,
    prices: rawPrices is List
        ? rawPrices
            .map<CreateProductPriceRequestModel>(
              (p) => CreateProductPriceRequestModel(
                type: _enumName(PriceType.values, p['type']) ?? '',
                name: p['name'] as String?,
                amount: _toDouble(p['amount']) ?? 0,
                currency: p['currency'] as String?,
                discountPercentage: _toDouble(p['discountPercentage']),
                discountAmount: _toDouble(p['discountAmount']),
                minQuantity: _toDouble(p['minQuantity']),
                notes: p['notes'] as String?,
              ),
            )
            .toList()
        : null,
    taxCategory: queuedTaxCategoryValue(data['taxCategory']),
    taxRate: _toDouble(data['taxRate']),
    isTaxable: data['isTaxable'] as bool?,
    taxDescription: data['taxDescription'] as String?,
    retentionCategory: queuedRetentionCategoryValue(data['retentionCategory']),
    retentionRate: _toDouble(data['retentionRate']),
    hasRetention: data['hasRetention'] as bool?,
  );
}

/// Request de actualización a partir de los datos encolados.
/// [categoryId] es la categoría ya resuelta (o `null` para no cambiarla).
UpdateProductRequestModel updateProductRequestFromQueue(
  Map<String, dynamic> data, {
  String? categoryId,
}) {
  final rawPrices = data['prices'];
  return UpdateProductRequestModel(
    name: data['name'] as String?,
    description: data['description'] as String?,
    sku: data['sku'] as String?,
    barcode: data['barcode'] as String?,
    type: _enumName(ProductType.values, data['type']),
    status: _enumName(ProductStatus.values, data['status']),
    stock: _toDouble(data['stock']),
    minStock: _toDouble(data['minStock']),
    unit: data['unit'] as String?,
    weight: _toDouble(data['weight']),
    length: _toDouble(data['length']),
    width: _toDouble(data['width']),
    height: _toDouble(data['height']),
    images: data['images'] != null ? List<String>.from(data['images']) : null,
    metadata: data['metadata'] is Map
        ? Map<String, dynamic>.from(data['metadata'] as Map)
        : null,
    categoryId: categoryId,
    prices: rawPrices is List
        ? rawPrices
            .map<UpdateProductPriceRequestModel>(
              (p) => UpdateProductPriceRequestModel(
                id: p['id'] as String?,
                type: _enumName(PriceType.values, p['type']) ?? '',
                name: p['name'] as String?,
                amount: _toDouble(p['amount']) ?? 0,
                currency: p['currency'] as String?,
                discountPercentage: _toDouble(p['discountPercentage']),
                discountAmount: _toDouble(p['discountAmount']),
                minQuantity: _toDouble(p['minQuantity']),
                notes: p['notes'] as String?,
              ),
            )
            .toList()
        : null,
    taxCategory: queuedTaxCategoryValue(data['taxCategory']),
    taxRate: _toDouble(data['taxRate']),
    isTaxable: data['isTaxable'] as bool?,
    taxDescription: data['taxDescription'] as String?,
    retentionCategory: queuedRetentionCategoryValue(data['retentionCategory']),
    retentionRate: _toDouble(data['retentionRate']),
    hasRetention: data['hasRetention'] as bool?,
  );
}

String? _rawText(Object? raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  return text.isEmpty ? null : text;
}

/// Nombre del enum si el texto coincide (sin distinguir mayúsculas);
/// si no, el texto tal cual.
String? _enumName<T extends Enum>(List<T> values, Object? raw) {
  final text = _rawText(raw);
  if (text == null) return null;
  final lower = text.toLowerCase();
  for (final e in values) {
    if (e.name.toLowerCase() == lower) return e.name;
  }
  return text;
}

double? _toDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
