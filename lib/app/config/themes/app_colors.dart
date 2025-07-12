// lib/app/config/themes/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ==================== COLORES PRINCIPALES ====================

  static const Color primary = Color(0xFF2196F3); // Azul principal
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);

  static const Color secondary = Color(0xFF03DAC6); // Verde azulado
  static const Color secondaryLight = Color(0xFF66FFF9);
  static const Color secondaryDark = Color(0xFF00A896);

  // ==================== COLORES DE SUPERFICIE ====================

  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundSecondary = Color(0xFFE3F2FD);

  // ==================== COLORES DE TEXTO ====================

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // ==================== COLORES DE ESTADO ====================

  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);

  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // ==================== COLORES NEUTRALES ====================

  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ==================== COLORES DE BORDE ====================

  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderDark = Color(0xFFBDBDBD);

  // ==================== TEMA OSCURO ====================

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextHint = Color(0xFF666666);

  static const Color darkBorderColor = Color(0xFF333333);

  // ==================== COLORES ESPECÍFICOS DE LA APP ====================

  static const Color authBackground = Color(0xFFF8F9FA);
  static const Color authCardBackground = Color(0xFFFFFFFF);
  static const Color authInputBackground = Color(0xFFFFFFFF);

  static const Color dashboardBackground = Color(0xFFF5F5F5);
  static const Color cardShadow = Color(0x1A000000);

  // ==================== GRADIENTES ====================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, successDark],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, warningDark],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [error, errorDark],
  );

  // ==================== MATERIAL COLOR SWATCH ====================

  static const MaterialColor primarySwatch =
      MaterialColor(0xFF2196F3, <int, Color>{
        50: Color(0xFFE3F2FD),
        100: Color(0xFFBBDEFB),
        200: Color(0xFF90CAF9),
        300: Color(0xFF64B5F6),
        400: Color(0xFF42A5F5),
        500: Color(0xFF2196F3),
        600: Color(0xFF1E88E5),
        700: Color(0xFF1976D2),
        800: Color(0xFF1565C0),
        900: Color(0xFF0D47A1),
      });

  // ==================== MÉTODOS HELPER ====================

  /// Obtener color con opacidad
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Obtener color de estado basado en tipo
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
      case 'completed':
        return success;
      case 'warning':
      case 'pending':
        return warning;
      case 'error':
      case 'failed':
      case 'inactive':
        return error;
      case 'info':
      case 'processing':
        return info;
      default:
        return grey500;
    }
  }

  /// Obtener color de texto basado en el fondo
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calcular luminancia del color de fondo
    final luminance = backgroundColor.computeLuminance();

    // Si el fondo es claro, usar texto oscuro; si es oscuro, usar texto claro
    return luminance > 0.5 ? textPrimary : darkTextPrimary;
  }

  /// Obtener color más claro
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );

    return hslLight.toColor();
  }

  /// Obtener color más oscuro
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }
}
