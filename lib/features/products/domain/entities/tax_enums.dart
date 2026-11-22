// lib/features/products/domain/entities/tax_enums.dart

/// Categorías de impuestos según la DIAN (Colombia)
/// Referencia: Dataico API para facturación electrónica
enum TaxCategory {
  /// Impuesto al Valor Agregado
  /// Tarifas comunes: 0%, 5%, 19%
  iva('IVA', 'IVA'),

  /// Impuesto Nacional al Consumo
  /// Aplicable a ciertos productos (restaurantes, bares, telefonía, etc.)
  /// Tarifas: 4%, 8%, 16%
  inc('INC', 'INC'),

  /// Impuesto Nacional al Consumo de Bolsas Plásticas
  /// Tarifa: Valor fijo por unidad
  incBolsa('INC_BOLSA', 'INC Bolsa'),

  /// Producto exento de impuestos
  /// Tarifa: 0%
  exento('EXENTO', 'Exento'),

  /// Producto no gravado (no aplica IVA)
  /// Ejemplo: Servicios profesionales, alimentos básicos
  noGravado('NO_GRAVADO', 'No Gravado');

  final String value;
  final String displayName;

  const TaxCategory(this.value, this.displayName);

  /// Obtiene la tasa predeterminada para esta categoría
  double get defaultRate {
    switch (this) {
      case TaxCategory.iva:
        return 19.0;
      case TaxCategory.inc:
        return 8.0;
      case TaxCategory.exento:
      case TaxCategory.noGravado:
        return 0.0;
      case TaxCategory.incBolsa:
        return 0.0; // Valor fijo, no porcentaje
    }
  }

  /// Determina si esta categoría requiere especificar una tasa
  bool get requiresRate {
    return this != TaxCategory.noGravado;
  }

  /// Reconoce el valor del servidor (`'IVA'`, `'NO_GRAVADO'`) o el nombre del
  /// enum (`'iva'`, `'noGravado'`), sin distinguir mayúsculas.
  /// Devuelve `null` si el texto no corresponde a ninguna categoría; nunca
  /// inventa una por defecto.
  static TaxCategory? tryParse(Object? raw) {
    if (raw is TaxCategory) return raw;
    if (raw == null) return null;
    final text = raw.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    for (final e in TaxCategory.values) {
      if (e.value.toLowerCase() == text || e.name.toLowerCase() == text) {
        return e;
      }
    }
    return null;
  }

  /// Obtiene el enum desde el valor string
  static TaxCategory fromString(String value) {
    return TaxCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaxCategory.noGravado,
    );
  }
}

/// Categorías de retenciones en la fuente
enum RetentionCategory {
  /// Retención en la fuente por IVA
  /// Tarifa común: 15%
  retIva('RET_IVA', 'Retención IVA', 15.0),

  /// Retención en la fuente por Renta
  /// Tarifas variables según concepto
  retRenta('RET_RENTA', 'Retención Renta', 2.5),

  /// Retención de Industria y Comercio
  /// Tarifa variable según municipio
  retIca('RET_ICA', 'Retención ICA', 0.0),

  /// Retención por CREE (Impuesto sobre la Renta para la Equidad)
  retCree('RET_CREE', 'Retención CREE', 0.0);

  final String value;
  final String displayName;
  final double defaultRate;

  const RetentionCategory(this.value, this.displayName, this.defaultRate);

  /// Reconoce el valor del servidor (`'RET_IVA'`) o el nombre del enum
  /// (`'retIva'`), sin distinguir mayúsculas. Devuelve `null` si no lo reconoce.
  static RetentionCategory? tryParse(Object? raw) {
    if (raw is RetentionCategory) return raw;
    if (raw == null) return null;
    final text = raw.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    for (final e in RetentionCategory.values) {
      if (e.value.toLowerCase() == text || e.name.toLowerCase() == text) {
        return e;
      }
    }
    return null;
  }

  /// Obtiene el enum desde el valor string
  static RetentionCategory? fromString(String? value) {
    if (value == null) return null;
    return RetentionCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RetentionCategory.retIva,
    );
  }
}

/// Tarifas de IVA comunes en Colombia
enum IVATaxRate {
  /// Sin IVA - Productos exentos o no gravados
  zero(0, '0%'),

  /// IVA reducido - Productos de la canasta básica
  reduced(5, '5%'),

  /// IVA general - Mayoría de productos y servicios
  general(19, '19%');

  final double value;
  final String displayName;

  const IVATaxRate(this.value, this.displayName);
}

/// Tarifas de INC (Impuesto Nacional al Consumo)
enum INCTaxRate {
  /// Tarifa del 4%
  four(4, '4%'),

  /// Tarifa del 8%
  eight(8, '8%'),

  /// Tarifa del 16%
  sixteen(16, '16%');

  final double value;
  final String displayName;

  const INCTaxRate(this.value, this.displayName);
}
