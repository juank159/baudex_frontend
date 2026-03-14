// library: app.core.utils.formatters
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

  // Formateador de fecha y hora
  static final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es_CO');

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

  /// Muestra info de tasa de cambio: "1 USD = 4,000 COP"
  static String formatExchangeInfo(String foreignCode, double rate, String baseCode) {
    return '1 $foreignCode = ${formatCurrency(rate)} $baseCode';
  }

  /// Obtiene el símbolo de una moneda
  static String getCurrencySymbol(String currencyCode) {
    final info = _currencyMap[currencyCode.toUpperCase()];
    return info?['symbol'] as String? ?? currencyCode;
  }
}
