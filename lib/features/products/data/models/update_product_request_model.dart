// // lib/features/products/data/models/update_product_request_model.dart
// import '../../domain/entities/product.dart';
// import '../../domain/repositories/product_repository.dart';

// /// Modelo para actualización de precios que incluye ID opcional
// class UpdateProductPriceRequestModel {
//   final String? id; // ID del precio existente (null para crear nuevo)
//   final String type;
//   final String? name;
//   final double amount;
//   final String? currency;
//   final double? discountPercentage;
//   final double? discountAmount;
//   final double? minQuantity;
//   final String? notes;

//   const UpdateProductPriceRequestModel({
//     this.id,
//     required this.type,
//     this.name,
//     required this.amount,
//     this.currency,
//     this.discountPercentage,
//     this.discountAmount,
//     this.minQuantity,
//     this.notes,
//   });

//   Map<String, dynamic> toJson() {
//     final json = <String, dynamic>{
//       'type': type,
//       'amount': amount,
//     };

//     if (id != null) json['id'] = id;
//     if (name != null) json['name'] = name;
//     if (currency != null) json['currency'] = currency;
//     if (discountPercentage != null) json['discountPercentage'] = discountPercentage;
//     if (discountAmount != null) json['discountAmount'] = discountAmount;
//     if (minQuantity != null) json['minQuantity'] = minQuantity;
//     if (notes != null) json['notes'] = notes;

//     return json;
//   }
// }

// class UpdateProductRequestModel {
//   final String? name;
//   final String? description;
//   final String? sku;
//   final String? barcode;
//   final String? type;
//   final String? status;
//   final double? stock;
//   final double? minStock;
//   final String? unit;
//   final double? weight;
//   final double? length;
//   final double? width;
//   final double? height;
//   final List<String>? images;
//   final Map<String, dynamic>? metadata;
//   final String? categoryId;
//   final List<UpdateProductPriceRequestModel>? prices;

//   const UpdateProductRequestModel({
//     this.name,
//     this.description,
//     this.sku,
//     this.barcode,
//     this.type,
//     this.status,
//     this.stock,
//     this.minStock,
//     this.unit,
//     this.weight,
//     this.length,
//     this.width,
//     this.height,
//     this.images,
//     this.metadata,
//     this.categoryId,
//     this.prices,
//   });

//   factory UpdateProductRequestModel.fromParams({
//     String? name,
//     String? description,
//     String? sku,
//     String? barcode,
//     ProductType? type,
//     ProductStatus? status,
//     double? stock,
//     double? minStock,
//     String? unit,
//     double? weight,
//     double? length,
//     double? width,
//     double? height,
//     List<String>? images,
//     Map<String, dynamic>? metadata,
//     String? categoryId,
//     List<UpdateProductPriceRequestModel>? prices,
//   }) {
//     return UpdateProductRequestModel(
//       name: name,
//       description: description,
//       sku: sku,
//       barcode: barcode,
//       type: type?.name,
//       status: status?.name,
//       stock: stock,
//       minStock: minStock,
//       unit: unit,
//       weight: weight,
//       length: length,
//       width: width,
//       height: height,
//       images: images,
//       metadata: metadata,
//       categoryId: categoryId,
//       prices: prices,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     final json = <String, dynamic>{};

//     if (name != null) json['name'] = name;
//     if (description != null) json['description'] = description;
//     if (sku != null) json['sku'] = sku;
//     if (barcode != null) json['barcode'] = barcode;
//     if (type != null) json['type'] = type;
//     if (status != null) json['status'] = status;
//     if (stock != null) json['stock'] = stock;
//     if (minStock != null) json['minStock'] = minStock;
//     if (unit != null) json['unit'] = unit;
//     if (weight != null) json['weight'] = weight;
//     if (length != null) json['length'] = length;
//     if (width != null) json['width'] = width;
//     if (height != null) json['height'] = height;
//     if (images != null) json['images'] = images;
//     if (metadata != null) json['metadata'] = metadata;
//     if (categoryId != null) json['categoryId'] = categoryId;

//     // Incluir precios con IDs para actualización/creación
//     if (prices != null) {
//       json['prices'] = prices!.map((price) => price.toJson()).toList();
//     }

//     return json;
//   }

//   bool get hasUpdates {
//     return name != null ||
//         description != null ||
//         sku != null ||
//         barcode != null ||
//         type != null ||
//         status != null ||
//         stock != null ||
//         minStock != null ||
//         unit != null ||
//         weight != null ||
//         length != null ||
//         width != null ||
//         height != null ||
//         images != null ||
//         metadata != null ||
//         categoryId != null ||
//         (prices != null && prices!.isNotEmpty);
//   }

//   @override
//   String toString() => 'UpdateProductRequestModel(hasUpdates: $hasUpdates)';
// }

// lib/features/products/data/models/update_product_request_model.dart
import '../../domain/entities/product.dart';
import '../../domain/entities/tax_enums.dart';
import '../../domain/repositories/product_repository.dart';

/// Modelo para actualización de precios que incluye ID opcional
class UpdateProductPriceRequestModel {
  final String? id; // ID del precio existente (null para crear nuevo)
  final String type;
  final String? name;
  final double amount;
  final String? currency;
  final double? discountPercentage;
  final double? discountAmount;
  final double? minQuantity;
  final String? notes;

  const UpdateProductPriceRequestModel({
    this.id,
    required this.type,
    this.name,
    required this.amount,
    this.currency,
    this.discountPercentage,
    this.discountAmount,
    this.minQuantity,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    print(
      '🔄 UpdateProductPriceRequestModel.toJson(): Procesando precio ${type}',
    );

    final json = <String, dynamic>{'type': type, 'amount': amount};

    if (id != null) {
      json['id'] = id;
      print('   ✅ Incluido ID existente: $id');
    } else {
      print('   🆕 Precio nuevo (sin ID)');
    }

    if (name != null) json['name'] = name;
    if (currency != null) json['currency'] = currency;
    if (discountPercentage != null)
      json['discountPercentage'] = discountPercentage;
    if (discountAmount != null) json['discountAmount'] = discountAmount;
    if (minQuantity != null) json['minQuantity'] = minQuantity;
    if (notes != null) json['notes'] = notes;

    print('   📤 JSON final del precio: $json');
    return json;
  }

  @override
  String toString() {
    return 'UpdateProductPriceRequestModel(id: $id, type: $type, amount: $amount)';
  }
}

class UpdateProductRequestModel {
  final String? name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? type;
  final String? status;
  final double? stock;
  final double? minStock;
  final String? unit;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final List<String>? images;
  final Map<String, dynamic>? metadata;
  final String? categoryId;
  final List<UpdateProductPriceRequestModel>? prices;
  // Campos de facturación electrónica
  final String? taxCategory;
  final double? taxRate;
  final bool? isTaxable;
  final String? taxDescription;
  final String? retentionCategory;
  final double? retentionRate;
  final bool? hasRetention;

  const UpdateProductRequestModel({
    this.name,
    this.description,
    this.sku,
    this.barcode,
    this.type,
    this.status,
    this.stock,
    this.minStock,
    this.unit,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.images,
    this.metadata,
    this.categoryId,
    this.prices,
    // Campos de facturación electrónica
    this.taxCategory,
    this.taxRate,
    this.isTaxable,
    this.taxDescription,
    this.retentionCategory,
    this.retentionRate,
    this.hasRetention,
  });

  factory UpdateProductRequestModel.fromParams({
    String? name,
    String? description,
    String? sku,
    String? barcode,
    ProductType? type,
    ProductStatus? status,
    double? stock,
    double? minStock,
    String? unit,
    double? weight,
    double? length,
    double? width,
    double? height,
    List<String>? images,
    Map<String, dynamic>? metadata,
    String? categoryId,
    List<UpdateProductPriceRequestModel>? prices,
    // Campos de facturación electrónica
    TaxCategory? taxCategory,
    double? taxRate,
    bool? isTaxable,
    String? taxDescription,
    RetentionCategory? retentionCategory,
    double? retentionRate,
    bool? hasRetention,
  }) {
    print('🏗️ UpdateProductRequestModel.fromParams(): Construyendo modelo');
    print('   📊 Precios recibidos: ${prices?.length ?? 0}');

    if (prices != null && prices.isNotEmpty) {
      for (int i = 0; i < prices.length; i++) {
        final price = prices[i];
        print(
          '   Precio $i: ${price.type} - \$${price.amount} (ID: ${price.id ?? "NUEVO"})',
        );
      }
    }

    return UpdateProductRequestModel(
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      type: type?.name,
      status: status?.name,
      stock: stock,
      minStock: minStock,
      unit: unit,
      weight: weight,
      length: length,
      width: width,
      height: height,
      images: images,
      metadata: metadata,
      categoryId: categoryId,
      prices: prices,
      // Campos de facturación electrónica
      taxCategory: taxCategory?.value,
      taxRate: taxRate,
      isTaxable: isTaxable,
      taxDescription: taxDescription,
      retentionCategory: retentionCategory?.value,
      retentionRate: retentionRate,
      hasRetention: hasRetention,
    );
  }

  Map<String, dynamic> toJson() {
    print(
      '📤 UpdateProductRequestModel.toJson(): Serializando modelo completo',
    );

    final json = <String, dynamic>{};

    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    if (sku != null) json['sku'] = sku;
    if (barcode != null) json['barcode'] = barcode;
    if (type != null) json['type'] = type;
    if (status != null) json['status'] = status;
    if (stock != null) json['stock'] = stock;
    if (minStock != null) json['minStock'] = minStock;
    if (unit != null) json['unit'] = unit;
    if (weight != null) json['weight'] = weight;
    if (length != null) json['length'] = length;
    if (width != null) json['width'] = width;
    if (height != null) json['height'] = height;
    if (images != null) json['images'] = images;
    if (metadata != null) json['metadata'] = metadata;
    if (categoryId != null) json['categoryId'] = categoryId;
    // Campos de facturación electrónica
    if (taxCategory != null) json['taxCategory'] = taxCategory;
    if (taxRate != null) json['taxRate'] = taxRate;
    if (isTaxable != null) json['isTaxable'] = isTaxable;
    if (taxDescription != null) json['taxDescription'] = taxDescription;
    if (retentionCategory != null) json['retentionCategory'] = retentionCategory;
    if (retentionRate != null) json['retentionRate'] = retentionRate;
    if (hasRetention != null) json['hasRetention'] = hasRetention;

    // ✅ MEJORADO: Incluir precios con debug detallado
    if (prices != null && prices!.isNotEmpty) {
      print(
        '🏷️ UpdateProductRequestModel: Serializando ${prices!.length} precios',
      );

      final serializedPrices = <Map<String, dynamic>>[];

      for (int i = 0; i < prices!.length; i++) {
        final price = prices![i];
        print('   📋 Serializando precio $i: ${price.type}');

        final priceJson = price.toJson();
        serializedPrices.add(priceJson);

        print(
          '   ✅ Precio $i serializado: ${priceJson['type']} - \$${priceJson['amount']} - ID: ${priceJson['id'] ?? "NUEVO"}',
        );
      }

      json['prices'] = serializedPrices;
      print(
        '✅ UpdateProductRequestModel: ${serializedPrices.length} precios incluidos en JSON',
      );
    } else {
      print('⚠️ UpdateProductRequestModel: No hay precios para serializar');
      if (prices == null) {
        print('   - prices es null');
      } else if (prices!.isEmpty) {
        print('   - prices está vacío');
      }
    }

    print(
      '📋 UpdateProductRequestModel: JSON final contiene campos: ${json.keys.toList()}',
    );

    // ✅ VERIFICACIÓN FINAL
    if (json.containsKey('prices')) {
      final pricesInJson = json['prices'] as List;
      print(
        '🔍 Verificación final: JSON contiene ${pricesInJson.length} precios',
      );
    } else {
      print('🔍 Verificación final: JSON NO contiene campo "prices"');
    }

    return json;
  }

  bool get hasUpdates {
    final updates =
        name != null ||
        description != null ||
        sku != null ||
        barcode != null ||
        type != null ||
        status != null ||
        stock != null ||
        minStock != null ||
        unit != null ||
        weight != null ||
        length != null ||
        width != null ||
        height != null ||
        images != null ||
        metadata != null ||
        categoryId != null ||
        (prices != null && prices!.isNotEmpty) ||
        // Campos de facturación electrónica
        taxCategory != null ||
        taxRate != null ||
        isTaxable != null ||
        taxDescription != null ||
        retentionCategory != null ||
        retentionRate != null ||
        hasRetention != null;

    print('🔍 UpdateProductRequestModel.hasUpdates: $updates');
    if (prices != null && prices!.isNotEmpty) {
      print('   ✅ Incluye ${prices!.length} precios para actualizar');
    }

    return updates;
  }

  /// ✅ MÉTODO ADICIONAL: Para debug y validación
  void printDebugInfo() {
    print('🔍 UpdateProductRequestModel Debug Info:');
    print('   - name: $name');
    print('   - sku: $sku');
    print('   - categoryId: $categoryId');
    print('   - prices count: ${prices?.length ?? 0}');
    print('   - hasUpdates: $hasUpdates');

    if (prices != null && prices!.isNotEmpty) {
      print('   📊 Detalles de precios:');
      for (int i = 0; i < prices!.length; i++) {
        final price = prices![i];
        print(
          '     [$i] ${price.type}: \$${price.amount} (ID: ${price.id ?? "NUEVO"})',
        );
      }
    }
  }

  @override
  String toString() {
    return 'UpdateProductRequestModel(hasUpdates: $hasUpdates, pricesCount: ${prices?.length ?? 0})';
  }
}
