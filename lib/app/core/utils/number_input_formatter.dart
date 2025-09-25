// File: lib/app/core/utils/number_input_formatter.dart
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// InputFormatter que formatea números en tiempo real con separadores de miles
/// mientras el usuario escribe, proporcionando feedback visual inmediato
class NumberInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##0', 'es_CO');
  final bool allowDecimals;
  final int maxDecimalPlaces;

  NumberInputFormatter({
    this.allowDecimals = false,
    this.maxDecimalPlaces = 2,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si el nuevo valor está vacío, permitir
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Solo permitir números, comas (decimales) y puntos (ya formateados)
    String filtered = newValue.text.replaceAll(RegExp(r'[^\d,.]'), '');

    // Si no permitimos decimales, quitar comas
    if (!allowDecimals) {
      filtered = filtered.replaceAll(',', '');
    }

    // Parsear el número removiendo formateo existente
    String numericOnly = _cleanNumericString(filtered);
    
    if (numericOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Validar decimales si están permitidos
    if (allowDecimals && numericOnly.contains(',')) {
      List<String> parts = numericOnly.split(',');
      if (parts.length > 2) {
        // Más de una coma, mantener solo la primera
        numericOnly = '${parts[0]},${parts.sublist(1).join('')}';
      }
      
      // Limitar decimales
      if (parts.length == 2 && parts[1].length > maxDecimalPlaces) {
        parts[1] = parts[1].substring(0, maxDecimalPlaces);
        numericOnly = '${parts[0]},${parts[1]}';
      }
    }

    // Formatear el número
    String formattedText = _formatNumber(numericOnly);

    // Calcular nueva posición del cursor
    int newCursorPosition = _calculateCursorPosition(
      oldValue.text,
      newValue.text,
      formattedText,
      newValue.selection.baseOffset,
    );

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  /// Limpia el string numérico removiendo formateo pero manteniendo decimales
  String _cleanNumericString(String input) {
    // Remover todos los puntos (separadores de miles)
    String cleaned = input.replaceAll('.', '');
    
    // Mantener solo el primer separador decimal (coma)
    if (allowDecimals) {
      List<String> parts = cleaned.split(',');
      if (parts.length > 2) {
        // Más de una coma, mantener solo la primera
        cleaned = '${parts[0]},${parts.sublist(1).join('')}';
      }
    }
    
    return cleaned;
  }

  /// Formatea el número con separadores de miles
  String _formatNumber(String numericString) {
    if (numericString.isEmpty) return '';

    if (allowDecimals && numericString.contains(',')) {
      // Manejar números con decimales
      List<String> parts = numericString.split(',');
      String integerPart = parts[0];
      String decimalPart = parts[1];

      if (integerPart.isEmpty) integerPart = '0';
      
      int intValue = int.tryParse(integerPart) ?? 0;
      String formattedInteger = _formatter.format(intValue);
      
      return '$formattedInteger,$decimalPart';
    } else {
      // Solo parte entera
      int intValue = int.tryParse(numericString) ?? 0;
      return _formatter.format(intValue);
    }
  }

  /// Calcula la nueva posición del cursor considerando los separadores agregados
  int _calculateCursorPosition(
    String oldText,
    String newText,
    String formattedText,
    int currentCursorPos,
  ) {
    // Si el texto formateado es más corto que la posición actual, ajustar
    if (currentCursorPos > formattedText.length) {
      return formattedText.length;
    }

    // Contar cuántos separadores se agregaron antes de la posición del cursor
    int separatorsBeforeCursor = 0;
    int actualPosition = 0;
    
    for (int i = 0; i < formattedText.length && actualPosition < currentCursorPos; i++) {
      if (formattedText[i] == '.') {
        separatorsBeforeCursor++;
      } else {
        actualPosition++;
      }
    }

    return currentCursorPos + separatorsBeforeCursor;
  }

  /// Método estático para obtener el valor numérico limpio del texto formateado
  static double? getNumericValue(String formattedText) {
    if (formattedText.isEmpty) return null;
    
    // Remover puntos (separadores de miles) y reemplazar coma por punto decimal
    String cleaned = formattedText.replaceAll('.', '').replaceAll(',', '.');
    
    return double.tryParse(cleaned);
  }

  /// Método estático para formatear un valor numérico como string para mostrar en campo
  static String formatValueForDisplay(double? value, {bool allowDecimals = false}) {
    if (value == null) return '';
    
    if (allowDecimals) {
      final formatter = NumberFormat('#,##0.##', 'es_CO');
      return formatter.format(value);
    } else {
      final formatter = NumberFormat('#,##0', 'es_CO');
      return formatter.format(value);
    }
  }
}

/// Formatter específico para precios (sin decimales)
class PriceInputFormatter extends NumberInputFormatter {
  PriceInputFormatter() : super(allowDecimals: false);
}

/// Formatter específico para cantidades (con decimales opcionales)
class QuantityInputFormatter extends NumberInputFormatter {
  QuantityInputFormatter() : super(allowDecimals: true, maxDecimalPlaces: 2);
}