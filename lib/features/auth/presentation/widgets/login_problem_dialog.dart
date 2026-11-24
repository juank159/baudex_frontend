// lib/features/auth/presentation/widgets/login_problem_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/rules/login_failure_rules.dart';

/// Diálogo para los fallos de inicio de sesión que NO son de credenciales
/// (sin conexión con el servidor, o el equipo no pudo guardar la sesión).
/// Muestra el detalle técnico para que el cliente se lo pueda leer o copiar a
/// soporte.
class LoginProblemDialog extends StatelessWidget {
  const LoginProblemDialog({super.key, required this.view, this.onClose});

  final LoginFailureView view;
  final VoidCallback? onClose;

  IconData get _icon => switch (view.kind) {
        LoginFailureKind.connection => Icons.wifi_off_rounded,
        LoginFailureKind.localStorage => Icons.save_outlined,
        LoginFailureKind.deviceLimit => Icons.devices_rounded,
        _ => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final detail = view.detail;
    return Dialog(
      backgroundColor: ElegantLightTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  shape: BoxShape.circle,
                  boxShadow: ElegantLightTheme.elevatedShadow,
                ),
                child: Icon(_icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                view.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                view.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalle para soporte',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        detail,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  if (detail != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: '${view.title}: $detail'),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copiar detalle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ElegantLightTheme.primaryBlue,
                          side: const BorderSide(
                              color: ElegantLightTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ElegantLightTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Entendido',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
