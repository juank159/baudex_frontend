// library: app.core.utils.formatters
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/tenant_datetime_service.dart';

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

  // Formateador de fechas
  static final dateFormat = DateFormat('dd/MM/yyyy', 'es_CO');

  // Formateador de fecha y hora (12h con AM/PM)
  static final dateTimeFormat = DateFormat('dd/MM/yyyy hh:mm a', 'es_CO');

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

  /// Formatea un número como moneda compacta para gráficos (K, M, etc.).
  ///
  /// Ejemplo: formatCompactCurrency(1500000) => "$ 1.5M"
  static String formatCompactCurrency(num? value) {
    if (value == null || value == 0) return '\$ 0';
    
    if (value >= 1000000) {
      return '\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$ ${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$ ${value.toStringAsFixed(0)}';
    }
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

  /// Parsea tasas de cambio de forma inteligente, detectando si el punto
  /// es separador decimal o de miles según el contexto.
  ///
  /// Ejemplos:
  ///   parseRate("0.12")     => 0.12  (punto = decimal, porque empieza con "0.")
  ///   parseRate("0,12")     => 0.12  (coma = decimal en es_CO)
  ///   parseRate("4.000")    => 4000  (punto = miles, 3 dígitos después)
  ///   parseRate("4.000,50") => 4000.5 (punto = miles, coma = decimal)
  ///   parseRate("1.5")      => 1.5   (punto = decimal, 1 dígito después)
  ///   parseRate("100.25")   => 100.25 (punto = decimal, 2 dígitos después)
  static double? parseRate(String? value) {
    if (value == null || value.isEmpty) return null;

    String cleaned = value.replaceAll(RegExp(r'[\$\s]'), '');
    if (cleaned.isEmpty) return null;

    // Caso 1: tiene puntos Y comas → formato es_CO completo (1.234,56)
    if (cleaned.contains('.') && cleaned.contains(',')) {
      return parseNumber(cleaned);
    }

    // Caso 2: solo comas, sin puntos → coma es decimal (0,12 o 1.234)
    if (cleaned.contains(',') && !cleaned.contains('.')) {
      cleaned = cleaned.replaceAll(',', '.');
      return double.tryParse(cleaned);
    }

    // Caso 3: solo puntos, sin comas
    if (cleaned.contains('.')) {
      final dotCount = '.'.allMatches(cleaned).length;

      if (dotCount > 1) {
        // Múltiples puntos = separadores de miles (1.234.567)
        cleaned = cleaned.replaceAll('.', '');
        return double.tryParse(cleaned);
      }

      // Un solo punto → detectar intención
      final parts = cleaned.split('.');

      // Si la parte izquierda es "0", el punto es decimal (0.12, 0.5)
      if (parts[0] == '0') {
        return double.tryParse(cleaned);
      }

      // Si la parte derecha tiene exactamente 3 dígitos → miles en es_CO (4.000)
      if (parts[1].length == 3) {
        cleaned = cleaned.replaceAll('.', '');
        return double.tryParse(cleaned);
      }

      // Cualquier otro caso → decimal (1.5, 100.25, 3.14)
      return double.tryParse(cleaned);
    }

    // Sin separadores
    return double.tryParse(cleaned);
  }

  /// Convierte un DateTime a la timezone del tenant antes de formatear
  static DateTime _toTenantTime(DateTime date) {
    try {
      if (Get.isRegistered<TenantDateTimeService>()) {
        return Get.find<TenantDateTimeService>().toLocal(date);
      }
    } catch (_) {}
    return date;
  }

  /// Formatea una fecha como string (convertida a timezone del tenant).
  ///
  /// Ejemplo: formatDate(DateTime(2023, 12, 25)) => "25/12/2023"
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return dateFormat.format(_toTenantTime(date));
  }

  /// Formatea una fecha y hora como string (convertida a timezone del tenant).
  ///
  /// Ejemplo: formatDateTime(DateTime(2023, 12, 25, 14, 30)) => "25/12/2023 14:30"
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return dateTimeFormat.format(_toTenantTime(dateTime));
  }

  /// Formatea una fecha para enviar a la API en formato YYYY-MM-DD.
  ///
  /// Ejemplo: formatDateForApi(DateTime(2023, 12, 25)) => "2023-12-25"
  static String formatDateForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Formatea el tiempo transcurrido desde una fecha hasta ahora.
  ///
  /// Ejemplo: formatTimeAgo(DateTime.now().subtract(Duration(hours: 2))) => "Hace 2 horas"
  static String formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';

    DateTime now;
    try {
      if (Get.isRegistered<TenantDateTimeService>()) {
        now = Get.find<TenantDateTimeService>().now();
      } else {
        now = DateTime.now();
      }
    } catch (_) {
      now = DateTime.now();
    }
    final difference = now.difference(_toTenantTime(dateTime));

    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Ahora';
    }
  }

  /// Formatea un número con separadores de miles y decimales opcionales (formato es_CO).
  /// Útil para tasas de cambio: formatRate(4000) => "4.000", formatRate(0.12) => "0,12"
  static String formatRate(num? value) {
    if (value == null) return '';
    if (value == value.roundToDouble() && value >= 1) {
      // Entero o sin decimales significativos
      return numberFormat.format(value);
    }
    // Con decimales
    final decimalFormat = NumberFormat('#,##0.######', 'es_CO');
    return decimalFormat.format(value);
  }

  // ==================== MULTI-MONEDA ====================

  /// Mapa de monedas comunes con símbolo y decimales
  static const _currencyMap = {
    'USD': {'symbol': 'US\$', 'decimals': 2},
    'EUR': {'symbol': '€', 'decimals': 2},
    'COP': {'symbol': '\$', 'decimals': 0},
    'MXN': {'symbol': 'MX\$', 'decimals': 2},
    'BRL': {'symbol': 'R\$', 'decimals': 2},
    'ARS': {'symbol': 'AR\$', 'decimals': 2},
    'PEN': {'symbol': 'S/', 'decimals': 2},
    'CLP': {'symbol': 'CL\$', 'decimals': 0},
    'BOB': {'symbol': 'Bs', 'decimals': 2},
    'VES': {'symbol': 'Bs.D', 'decimals': 2},
    'GBP': {'symbol': '£', 'decimals': 2},
    'DOP': {'symbol': 'RD\$', 'decimals': 2},
    'GTQ': {'symbol': 'Q', 'decimals': 2},
    'HNL': {'symbol': 'L', 'decimals': 2},
    'NIO': {'symbol': 'C\$', 'decimals': 2},
    'PAB': {'symbol': 'B/.', 'decimals': 2},
    'PYG': {'symbol': '₲', 'decimals': 0},
    'UYU': {'symbol': '\$U', 'decimals': 2},
    'CRC': {'symbol': '₡', 'decimals': 0},
  };

  /// Formatea un monto en moneda extranjera con símbolo correcto
  static String formatForeignCurrency(num? value, String currencyCode) {
    if (value == null) return '0';
    final info = _currencyMap[currencyCode.toUpperCase()];
    final symbol = info?['symbol'] as String? ?? currencyCode;
    final decimals = info?['decimals'] as int? ?? 2;
    final format = NumberFormat.currency(
      locale: 'en_US',
      symbol: '$symbol ',
      decimalDigits: decimals,
    );
    return format.format(value);
  }

  /// Muestra info de tasa de cambio: "1 USD = 4.000 COP", "1 VES = 8,27 COP"
  /// rate = cuántas unidades base vale 1 unidad extranjera (ej: 1 USD = 4.000 COP)
  static String formatExchangeInfo(String foreignCode, double rate, String baseCode) {
    return '1 $foreignCode = ${formatRate(rate)} $baseCode';
  }

  /// Obtiene el símbolo de una moneda
  static String getCurrencySymbol(String currencyCode) {
    final info = _currencyMap[currencyCode.toUpperCase()];
    return info?['symbol'] as String? ?? currencyCode;
  }
}

/// Parser y formatter DEDICADOS A PRECIOS en formato es_CO.
///
/// Convención clara (sin ambigüedad):
///   - El punto es SIEMPRE separador de miles: `10.000` → diez mil,
///     `1.000.000` → un millón.
///   - La coma es SIEMPRE decimal: `10.000,50` → 10000.50.
///
/// A diferencia de `parseRate` (donde "6" y "6.000" son casos distintos
/// según cantidad de dígitos), aquí nunca hay heurística — el punto nunca
/// es decimal. Esto evita el bug donde "1.0000" se interpretaba como 1.0.
class PriceFormat {
  /// Convierte un string con formato es_CO a double. Retorna null si no
  /// se puede parsear.
  static double? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    String cleaned = value.replaceAll(RegExp(r'[\$\s]'), '');
    if (cleaned.isEmpty) return null;
    // Punto = miles (se elimina); coma = decimal (se reemplaza por punto)
    cleaned = cleaned.replaceAll('.', '');
    cleaned = cleaned.replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  /// Formatea un double como precio es_CO (punto miles, coma decimal si hay).
  static String format(num value, {int decimals = 2}) {
    final intPart = value.truncate();
    final intFormatted = NumberFormat('#,##0', 'es_CO').format(intPart);
    final diff = (value - intPart).abs();
    if (diff < 0.0000001) return intFormatted;
    // Hay decimales — recortar a `decimals` dígitos sin trailing zeros
    final decimalStr = diff
        .toStringAsFixed(decimals)
        .substring(2)
        .replaceAll(RegExp(r'0+$'), '');
    if (decimalStr.isEmpty) return intFormatted;
    return '$intFormatted,$decimalStr';
  }
}

/// Formatter de INPUT para campos de PRECIO en es_CO con soporte decimal.
/// Re-formatea mientras el usuario escribe, agregando separadores de miles
/// automáticamente y respetando la coma decimal si la tipea.
///
/// Nota: se llama `DecimalPriceInputFormatter` (no `PriceInputFormatter`)
/// para no chocar con el formatter de precios enteros existente en
/// `number_input_formatter.dart`.
class DecimalPriceInputFormatter extends TextInputFormatter {
  final int maxDecimals;
  DecimalPriceInputFormatter({this.maxDecimals = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String cleaned = newValue.text.replaceAll(RegExp(r'[^\d.,]'), '');
    if (cleaned.isEmpty) return const TextEditingValue(text: '');

    // Separar parte entera de parte decimal. Si hay múltiples comas,
    // solo la primera cuenta como decimal.
    final commaIdx = cleaned.indexOf(',');
    String intRaw;
    String? decimalRaw;
    if (commaIdx >= 0) {
      intRaw = cleaned.substring(0, commaIdx).replaceAll('.', '');
      decimalRaw = cleaned
          .substring(commaIdx + 1)
          .replaceAll('.', '')
          .replaceAll(',', '');
      if (decimalRaw.length > maxDecimals) {
        decimalRaw = decimalRaw.substring(0, maxDecimals);
      }
    } else {
      intRaw = cleaned.replaceAll('.', '');
      decimalRaw = null;
    }

    // Parte entera: sin ceros a la izquierda
    intRaw = intRaw.replaceAll(RegExp(r'^0+(?=\d)'), '');
    if (intRaw.isEmpty) intRaw = '0';

    final intValue = int.tryParse(intRaw) ?? 0;
    final intFormatted = NumberFormat('#,##0', 'es_CO').format(intValue);

    String formatted;
    if (commaIdx >= 0) {
      formatted = '$intFormatted,${decimalRaw ?? ''}';
    } else {
      formatted = intFormatted;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter de tasas de cambio que permite formato es_CO (punto miles, coma
/// decimal) y re-formatea el input mientras el usuario escribe. Mantiene el
/// comportamiento del dialog de pago de facturas para dar consistencia al
/// sistema de multi-moneda.
class RateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String cleaned = newValue.text.replaceAll(RegExp(r'[^\d.,]'), '');
    if (cleaned.isEmpty) return const TextEditingValue(text: '');

    final parsed = AppFormatters.parseRate(cleaned);
    if (parsed == null) return oldValue;

    String formatted = AppFormatters.formatRate(parsed);

    // Si el usuario acaba de escribir una coma, mantenerla al final
    if (cleaned.endsWith(',') && !formatted.contains(',')) {
      formatted = '$formatted,';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
