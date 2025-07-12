// library: app.core.utils.formatters
import 'package:intl/intl.dart';

class AppFormatters {
  // Formateador para números enteros con separadores de miles (ej: 1.234)
  static final numberFormat = NumberFormat('#,##0', 'es_CO');

  // Formateador para monedas colombianas con separadores de miles SIN decimales (ej: $ 1.234.567)
  static final currencyFormat = NumberFormat.currency(
    locale: 'es_CO', // Formato colombiano: punto para miles, sin decimales
    symbol: '\$ ',
    decimalDigits: 0,
  );

  // Formateador para monedas con decimales (solo para casos especiales)
  static final currencyFormatWithDecimals = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$ ',
    decimalDigits: 2,
  );

  // Formateador de stock y cantidades
  static final stockFormat = NumberFormat('#,##0.##', 'es_CO');

  /// Formatea un número (double o int) como un string con separadores de miles.
  ///
  /// Ejemplo: formatNumber(12345) => "12.345"
  static String formatNumber(num? value) {
    if (value == null) return '0';
    return numberFormat.format(value);
  }

  /// Formatea un número como moneda colombiana SIN decimales (recomendado para precios).
  ///
  /// Ejemplo: formatCurrency(1234567) => "$ 1.234.567"
  static String formatCurrency(num? value) {
    if (value == null) return '\$ 0';
    
    // Formatear sin símbolo y luego agregar el símbolo al inicio manualmente
    String formatted = numberFormat.format(value);
    return '\$ $formatted';
  }

  /// Formatea un número como moneda CON decimales (solo para casos especiales).
  ///
  /// Ejemplo: formatCurrencyWithDecimals(12345.67) => "$ 12.345,67"
  static String formatCurrencyWithDecimals(num? value) {
    if (value == null) return '\$ 0,00';
    
    // Crear un formateador temporal sin símbolo para decimales
    final decimalFormat = NumberFormat('#,##0.00', 'es_CO');
    String formatted = decimalFormat.format(value);
    return '\$ $formatted';
  }

  /// Formatea stock y cantidades (permite decimales si es necesario).
  ///
  /// Ejemplo: formatStock(1234.5) => "1.234,5", formatStock(1234) => "1.234"
  static String formatStock(num? value) {
    if (value == null) return '0';
    return stockFormat.format(value);
  }

  /// Formatea un precio específicamente (alias de formatCurrency para claridad).
  ///
  /// Ejemplo: formatPrice(1500000) => "$ 1.500.000"
  static String formatPrice(num? value) {
    return formatCurrency(value);
  }

  /// Convierte un string a número, removiendo separadores.
  ///
  /// Ejemplo: parseNumber("1.234.567") => 1234567
  static double? parseNumber(String? value) {
    if (value == null || value.isEmpty) return null;

    // Remover símbolo de moneda y espacios
    String cleaned = value.replaceAll(RegExp(r'[\$\s]'), '');

    // Reemplazar puntos por nada (separadores de miles) y comas por puntos (decimales)
    cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(cleaned);
  }
}
