// lib/app/core/theme/futuristic_notifications.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'elegant_light_theme.dart';

class FuturisticNotifications {
  static void showSuccess(
    String title,
    String message, {
    Duration? duration,
    VoidCallback? onTap,
  }) {
    Get.snackbar(
      '',
      '',
      titleText: _buildNotificationContent(
        title,
        message,
        Icons.check_circle,
        ElegantLightTheme.successGradient,
      ),
      messageText: const SizedBox.shrink(),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      borderRadius: 0,
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(16),
      duration: duration ?? const Duration(seconds: 4),
      animationDuration: ElegantLightTheme.normalAnimation,
      forwardAnimationCurve: ElegantLightTheme.elasticCurve,
      reverseAnimationCurve: ElegantLightTheme.smoothCurve,
      onTap: onTap != null ? (_) => onTap() : null,
    );
  }

  static void showError(
    String title,
    String message, {
    Duration? duration,
    VoidCallback? onTap,
  }) {
    Get.snackbar(
      '',
      '',
      titleText: _buildNotificationContent(
        title,
        message,
        Icons.error,
        ElegantLightTheme.errorGradient,
      ),
      messageText: const SizedBox.shrink(),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      borderRadius: 0,
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(16),
      duration: duration ?? const Duration(seconds: 5),
      animationDuration: ElegantLightTheme.normalAnimation,
      forwardAnimationCurve: ElegantLightTheme.elasticCurve,
      reverseAnimationCurve: ElegantLightTheme.smoothCurve,
      onTap: onTap != null ? (_) => onTap() : null,
    );
  }

  static void showWarning(
    String title,
    String message, {
    Duration? duration,
    VoidCallback? onTap,
  }) {
    Get.snackbar(
      '',
      '',
      titleText: _buildNotificationContent(
        title,
        message,
        Icons.warning,
        ElegantLightTheme.warningGradient,
      ),
      messageText: const SizedBox.shrink(),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      borderRadius: 0,
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(16),
      duration: duration ?? const Duration(seconds: 4),
      animationDuration: ElegantLightTheme.normalAnimation,
      forwardAnimationCurve: ElegantLightTheme.elasticCurve,
      reverseAnimationCurve: ElegantLightTheme.smoothCurve,
      onTap: onTap != null ? (_) => onTap() : null,
    );
  }

  static void showInfo(
    String title,
    String message, {
    Duration? duration,
    VoidCallback? onTap,
  }) {
    Get.snackbar(
      '',
      '',
      titleText: _buildNotificationContent(
        title,
        message,
        Icons.info,
        ElegantLightTheme.infoGradient,
      ),
      messageText: const SizedBox.shrink(),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      borderRadius: 0,
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(16),
      duration: duration ?? const Duration(seconds: 4),
      animationDuration: ElegantLightTheme.normalAnimation,
      forwardAnimationCurve: ElegantLightTheme.elasticCurve,
      reverseAnimationCurve: ElegantLightTheme.smoothCurve,
      onTap: onTap != null ? (_) => onTap() : null,
    );
  }

  static void showProcessing(
    String title,
    String message, {
    Duration? duration,
  }) {
    Get.snackbar(
      '',
      '',
      titleText: _buildProcessingNotification(title, message),
      messageText: const SizedBox.shrink(),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      borderRadius: 0,
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.all(16),
      duration: duration ?? const Duration(seconds: 3),
      animationDuration: ElegantLightTheme.normalAnimation,
      forwardAnimationCurve: ElegantLightTheme.elasticCurve,
      reverseAnimationCurve: ElegantLightTheme.smoothCurve,
    );
  }

  static Widget _buildNotificationContent(
    String title,
    String message,
    IconData icon,
    LinearGradient gradient,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradient.colors.first.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          ...ElegantLightTheme.elevatedShadow,
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            offset: const Offset(0, 0),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: ElegantLightTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ElegantLightTheme.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close,
                color: ElegantLightTheme.textSecondary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildProcessingNotification(String title, String message) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryGradient.colors.first.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.glowShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ElegantLightTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: ElegantLightTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showCustomDialog({
    required String title,
    required String content,
    required List<Widget> actions,
    IconData? icon,
    LinearGradient? gradient,
  }) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: gradient ?? ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: gradient != null
                        ? [
                            BoxShadow(
                              color: gradient.colors.first.withOpacity(0.4),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : ElegantLightTheme.glowShadow,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                title,
                style: const TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

// Extension para simplificar el uso
extension FuturisticNotificationExtensions on GetInterface {
  void showFuturisticSuccess(String title, String message) {
    FuturisticNotifications.showSuccess(title, message);
  }

  void showFuturisticError(String title, String message) {
    FuturisticNotifications.showError(title, message);
  }

  void showFuturisticWarning(String title, String message) {
    FuturisticNotifications.showWarning(title, message);
  }

  void showFuturisticInfo(String title, String message) {
    FuturisticNotifications.showInfo(title, message);
  }

  void showFuturisticProcessing(String title, String message) {
    FuturisticNotifications.showProcessing(title, message);
  }
}