// // lib/features/customers/data/models/customer_stats_model.dart
// import '../../domain/entities/customer_stats.dart';

// class CustomerStatsModel extends CustomerStats {
//   const CustomerStatsModel({
//     required super.total,
//     required super.active,
//     required super.inactive,
//     required super.suspended,
//     required super.totalCreditLimit,
//     required super.totalBalance,
//     required super.activePercentage,
//     required super.customersWithOverdue,
//     required super.averagePurchaseAmount,
//   });

//   factory CustomerStatsModel.fromJson(Map<String, dynamic> json) {
//     return CustomerStatsModel(
//       total: (json['total'] as num?)?.toInt() ?? 0,
//       active: (json['active'] as num?)?.toInt() ?? 0,
//       inactive: (json['inactive'] as num?)?.toInt() ?? 0,
//       suspended: (json['suspended'] as num?)?.toInt() ?? 0,
//       totalCreditLimit: (json['totalCreditLimit'] as num?)?.toDouble() ?? 0.0,
//       totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0.0,
//       activePercentage: (json['activePercentage'] as num?)?.toDouble() ?? 0.0,
//       customersWithOverdue:
//           (json['customersWithOverdue'] as num?)?.toInt() ?? 0,
//       averagePurchaseAmount:
//           (json['averagePurchaseAmount'] as num?)?.toDouble() ?? 0.0,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'total': total,
//       'active': active,
//       'inactive': inactive,
//       'suspended': suspended,
//       'totalCreditLimit': totalCreditLimit,
//       'totalBalance': totalBalance,
//       'activePercentage': activePercentage,
//       'customersWithOverdue': customersWithOverdue,
//       'averagePurchaseAmount': averagePurchaseAmount,
//     };
//   }

//   CustomerStats toEntity() {
//     return CustomerStats(
//       total: total,
//       active: active,
//       inactive: inactive,
//       suspended: suspended,
//       totalCreditLimit: totalCreditLimit,
//       totalBalance: totalBalance,
//       activePercentage: activePercentage,
//       customersWithOverdue: customersWithOverdue,
//       averagePurchaseAmount: averagePurchaseAmount,
//     );
//   }

//   factory CustomerStatsModel.fromEntity(CustomerStats stats) {
//     return CustomerStatsModel(
//       total: stats.total,
//       active: stats.active,
//       inactive: stats.inactive,
//       suspended: stats.suspended,
//       totalCreditLimit: stats.totalCreditLimit,
//       totalBalance: stats.totalBalance,
//       activePercentage: stats.activePercentage,
//       customersWithOverdue: stats.customersWithOverdue,
//       averagePurchaseAmount: stats.averagePurchaseAmount,
//     );
//   }

//   @override
//   String toString() =>
//       'CustomerStatsModel(total: $total, active: $active, inactive: $inactive)';
// }

// lib/features/customers/data/models/customer_stats_model.dart
import '../../domain/entities/customer_stats.dart';

class CustomerStatsModel extends CustomerStats {
  const CustomerStatsModel({
    required super.total,
    required super.active,
    required super.inactive,
    required super.suspended,
    required super.totalCreditLimit,
    required super.totalBalance,
    required super.activePercentage,
    required super.customersWithOverdue,
    required super.averagePurchaseAmount,
  });

  // ==================== CONVERSIÓN DE DATOS (SOLO EN MODELO) ====================

  /// Crear desde JSON con manejo robusto de tipos
  factory CustomerStatsModel.fromJson(Map<String, dynamic> json) {
    return CustomerStatsModel(
      total: _parseInt(json['total']) ?? 0,
      active: _parseInt(json['active']) ?? 0,
      inactive: _parseInt(json['inactive']) ?? 0,
      suspended: _parseInt(json['suspended']) ?? 0,
      totalCreditLimit: _parseDouble(json['totalCreditLimit']) ?? 0.0,
      totalBalance: _parseDouble(json['totalBalance']) ?? 0.0,
      activePercentage: _parseDouble(json['activePercentage']) ?? 0.0,
      customersWithOverdue: _parseInt(json['customersWithOverdue']) ?? 0,
      averagePurchaseAmount: _parseDouble(json['averagePurchaseAmount']) ?? 0.0,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'active': active,
      'inactive': inactive,
      'suspended': suspended,
      'totalCreditLimit': totalCreditLimit,
      'totalBalance': totalBalance,
      'activePercentage': activePercentage,
      'customersWithOverdue': customersWithOverdue,
      'averagePurchaseAmount': averagePurchaseAmount,
    };
  }

  /// Convertir a entidad del dominio
  CustomerStats toEntity() {
    return CustomerStats(
      total: total,
      active: active,
      inactive: inactive,
      suspended: suspended,
      totalCreditLimit: totalCreditLimit,
      totalBalance: totalBalance,
      activePercentage: activePercentage,
      customersWithOverdue: customersWithOverdue,
      averagePurchaseAmount: averagePurchaseAmount,
    );
  }

  /// Crear desde entidad del dominio
  factory CustomerStatsModel.fromEntity(CustomerStats stats) {
    return CustomerStatsModel(
      total: stats.total,
      active: stats.active,
      inactive: stats.inactive,
      suspended: stats.suspended,
      totalCreditLimit: stats.totalCreditLimit,
      totalBalance: stats.totalBalance,
      activePercentage: stats.activePercentage,
      customersWithOverdue: stats.customersWithOverdue,
      averagePurchaseAmount: stats.averagePurchaseAmount,
    );
  }

  // ==================== MÉTODOS HELPER PRIVADOS ====================

  /// Parsear entero de forma segura
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.trim().isEmpty) return 0;
      try {
        return int.parse(value);
      } catch (e) {
        print('⚠️ Error parsing int from string: "$value" - $e');
        return null;
      }
    }
    if (value is num) return value.toInt();

    print('⚠️ Unexpected type for int value: ${value.runtimeType} - $value');
    return null;
  }

  /// Parsear double de forma segura
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return 0.0;
      try {
        return double.parse(value);
      } catch (e) {
        print('⚠️ Error parsing double from string: "$value" - $e');
        return null;
      }
    }
    if (value is num) return value.toDouble();

    print('⚠️ Unexpected type for double value: ${value.runtimeType} - $value');
    return null;
  }

  // ==================== MÉTODOS ADICIONALES PARA DEBUGGING ====================

  /// Crear con validación de datos del backend
  factory CustomerStatsModel.fromJsonSafe(Map<String, dynamic> json) {
    try {
      final model = CustomerStatsModel.fromJson(json);

      // Validar los datos
      if (!model.isValid) {
        print('⚠️ CustomerStatsModel: Datos inválidos detectados');
        print('   Errores: ${model.validationErrors.join(', ')}');
        print('   JSON original: $json');
      }

      return model;
    } catch (e, stackTrace) {
      print('❌ Error al crear CustomerStatsModel desde JSON: $e');
      print('   JSON: $json');
      print('   StackTrace: $stackTrace');

      // Retornar modelo con valores por defecto
      return const CustomerStatsModel(
        total: 0,
        active: 0,
        inactive: 0,
        suspended: 0,
        totalCreditLimit: 0.0,
        totalBalance: 0.0,
        activePercentage: 0.0,
        customersWithOverdue: 0,
        averagePurchaseAmount: 0.0,
      );
    }
  }

  /// Información de debugging
  Map<String, dynamic> toDebugMap() {
    return {
      'model_data': toJson(),
      'validation': {'is_valid': isValid, 'errors': validationErrors},
      'computed_values': {
        'health_status': healthStatus,
        'credit_usage': totalCreditUsage,
        'available_credit': availableCredit,
        'overdue_percentage': overduePercentage,
        'total_inactive': totalInactive,
      },
    };
  }

  @override
  String toString() =>
      'CustomerStatsModel(total: $total, active: $active, inactive: $inactive, '
      'suspended: $suspended, valid: $isValid)';
}
