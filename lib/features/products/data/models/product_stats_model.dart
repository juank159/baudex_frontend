// // lib/features/products/data/models/product_stats_model.dart
// import '../../domain/entities/product_stats.dart';

// class ProductStatsModel {
//   final int total;
//   final int active;
//   final int inactive;
//   final int outOfStock;
//   final int lowStock;
//   final double activePercentage;
//   final double totalValue;
//   final double averagePrice;

//   const ProductStatsModel({
//     required this.total,
//     required this.active,
//     required this.inactive,
//     required this.outOfStock,
//     required this.lowStock,
//     required this.activePercentage,
//     this.totalValue = 0.0,
//     this.averagePrice = 0.0,
//   });

//   /// Convertir desde JSON
//   factory ProductStatsModel.fromJson(Map<String, dynamic> json) {
//     return ProductStatsModel(
//       total: json['total'] ?? 0,
//       active: json['active'] ?? 0,
//       inactive: json['inactive'] ?? 0,
//       outOfStock: json['outOfStock'] ?? 0,
//       lowStock: json['lowStock'] ?? 0,
//       activePercentage: (json['activePercentage'] ?? 0).toDouble(),
//       totalValue: (json['totalValue'] ?? 0).toDouble(),
//       averagePrice: (json['averagePrice'] ?? 0).toDouble(),
//     );
//   }

//   /// Convertir a JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'total': total,
//       'active': active,
//       'inactive': inactive,
//       'outOfStock': outOfStock,
//       'lowStock': lowStock,
//       'activePercentage': activePercentage,
//       'totalValue': totalValue,
//       'averagePrice': averagePrice,
//     };
//   }

//   /// Convertir a entidad del dominio
//   ProductStats toEntity() {
//     return ProductStats(
//       total: total,
//       active: active,
//       inactive: inactive,
//       outOfStock: outOfStock,
//       lowStock: lowStock,
//       activePercentage: activePercentage,
//       totalValue: totalValue,
//       averagePrice: averagePrice,
//     );
//   }

//   /// Crear desde entidad del dominio
//   factory ProductStatsModel.fromEntity(ProductStats entity) {
//     return ProductStatsModel(
//       total: entity.total,
//       active: entity.active,
//       inactive: entity.inactive,
//       outOfStock: entity.outOfStock,
//       lowStock: entity.lowStock,
//       activePercentage: entity.activePercentage,
//       totalValue: entity.totalValue,
//       averagePrice: entity.averagePrice,
//     );
//   }

//   ProductStatsModel copyWith({
//     int? total,
//     int? active,
//     int? inactive,
//     int? outOfStock,
//     int? lowStock,
//     double? activePercentage,
//     double? totalValue,
//     double? averagePrice,
//   }) {
//     return ProductStatsModel(
//       total: total ?? this.total,
//       active: active ?? this.active,
//       inactive: inactive ?? this.inactive,
//       outOfStock: outOfStock ?? this.outOfStock,
//       lowStock: lowStock ?? this.lowStock,
//       activePercentage: activePercentage ?? this.activePercentage,
//       totalValue: totalValue ?? this.totalValue,
//       averagePrice: averagePrice ?? this.averagePrice,
//     );
//   }

//   @override
//   String toString() {
//     return 'ProductStatsModel(total: $total, active: $active, inactive: $inactive, outOfStock: $outOfStock, lowStock: $lowStock, activePercentage: $activePercentage, totalValue: $totalValue, averagePrice: $averagePrice)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is ProductStatsModel &&
//         other.total == total &&
//         other.active == active &&
//         other.inactive == inactive &&
//         other.outOfStock == outOfStock &&
//         other.lowStock == lowStock &&
//         other.activePercentage == activePercentage &&
//         other.totalValue == totalValue &&
//         other.averagePrice == averagePrice;
//   }

//   @override
//   int get hashCode {
//     return total.hashCode ^
//         active.hashCode ^
//         inactive.hashCode ^
//         outOfStock.hashCode ^
//         lowStock.hashCode ^
//         activePercentage.hashCode ^
//         totalValue.hashCode ^
//         averagePrice.hashCode;
//   }
// }

// ===== SOLUCIÓN 3: FLUTTER - product_stats_model.dart =====
// Modelo corregido con manejo robusto

import 'package:baudex_desktop/features/products/domain/entities/product_stats.dart';

class ProductStatsModel {
  final int total;
  final int active;
  final int inactive;
  final int outOfStock;
  final int lowStock;
  final double activePercentage;
  final double totalValue;
  final double averagePrice;

  const ProductStatsModel({
    required this.total,
    required this.active,
    required this.inactive,
    required this.outOfStock,
    required this.lowStock,
    required this.activePercentage,
    this.totalValue = 0.0,
    this.averagePrice = 0.0,
  });

  /// ✅ MEJORADO: Convertir desde JSON con manejo robusto
  factory ProductStatsModel.fromJson(Map<String, dynamic> json) {
    print('🔍 ProductStatsModel.fromJson: Procesando JSON');
    print('📋 JSON recibido: $json');

    try {
      // Función helper para extraer enteros de forma segura
      int safeInt(String key, [List<String> alternatives = const []]) {
        // Probar la clave principal
        var value = json[key];
        if (value != null) {
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) return int.tryParse(value) ?? 0;
        }

        // Probar claves alternativas
        for (String altKey in alternatives) {
          value = json[altKey];
          if (value != null) {
            if (value is int) return value;
            if (value is double) return value.toInt();
            if (value is String) return int.tryParse(value) ?? 0;
          }
        }

        print(
          '⚠️ No se encontró valor para $key (alternativas: $alternatives)',
        );
        return 0;
      }

      // Función helper para extraer doubles de forma segura
      double safeDouble(String key, [double defaultValue = 0.0]) {
        var value = json[key];
        if (value != null) {
          if (value is double) return value;
          if (value is int) return value.toDouble();
          if (value is String) return double.tryParse(value) ?? defaultValue;
        }
        return defaultValue;
      }

      final model = ProductStatsModel(
        // Buscar en nombres principales y alternativos
        total: safeInt('total', ['totalProducts']),
        active: safeInt('active', ['activeProducts']),
        inactive: safeInt('inactive', ['inactiveProducts']),
        outOfStock: safeInt('outOfStock', ['outOfStockProducts']),
        lowStock: safeInt('lowStock', ['lowStockProducts']),
        activePercentage: safeDouble('activePercentage'),
        totalValue: safeDouble('totalValue'),
        averagePrice: safeDouble('averagePrice'),
      );

      print('✅ ProductStatsModel creado exitosamente: $model');
      return model;
    } catch (e, stackTrace) {
      print('❌ Error en ProductStatsModel.fromJson: $e');
      print('📋 JSON problemático: $json');
      print('🔍 StackTrace: $stackTrace');

      // Retornar modelo vacío en caso de error
      return const ProductStatsModel(
        total: 0,
        active: 0,
        inactive: 0,
        outOfStock: 0,
        lowStock: 0,
        activePercentage: 0.0,
        totalValue: 0.0,
        averagePrice: 0.0,
      );
    }
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'active': active,
      'inactive': inactive,
      'outOfStock': outOfStock,
      'lowStock': lowStock,
      'activePercentage': activePercentage,
      'totalValue': totalValue,
      'averagePrice': averagePrice,
    };
  }

  /// Convertir a entidad del dominio
  ProductStats toEntity() {
    return ProductStats(
      total: total,
      active: active,
      inactive: inactive,
      outOfStock: outOfStock,
      lowStock: lowStock,
      activePercentage: activePercentage,
      totalValue: totalValue,
      averagePrice: averagePrice,
    );
  }

  /// Crear desde entidad del dominio
  factory ProductStatsModel.fromEntity(ProductStats entity) {
    return ProductStatsModel(
      total: entity.total,
      active: entity.active,
      inactive: entity.inactive,
      outOfStock: entity.outOfStock,
      lowStock: entity.lowStock,
      activePercentage: entity.activePercentage,
      totalValue: entity.totalValue,
      averagePrice: entity.averagePrice,
    );
  }

  @override
  String toString() {
    return 'ProductStatsModel(total: $total, active: $active, inactive: $inactive, outOfStock: $outOfStock, lowStock: $lowStock, activePercentage: $activePercentage, totalValue: $totalValue, averagePrice: $averagePrice)';
  }

  // ✅ AÑADIDO: Método para verificar si las estadísticas son válidas
  bool get isValid => total >= 0 && active >= 0 && inactive >= 0;

  // ✅ AÑADIDO: Método para detectar si hay datos
  bool get hasData => total > 0 || active > 0 || inactive > 0;
}
