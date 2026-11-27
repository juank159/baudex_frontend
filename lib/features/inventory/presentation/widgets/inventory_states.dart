// lib/features/inventory/presentation/widgets/inventory_states.dart
//
// Estados de pantalla completa del módulo de Inventario (cargando, error y
// vacío) con el tema elegante de la app. Solo presentación.
import 'package:flutter/material.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../breb/presentation/widgets/breb_ui.dart';

/// Convierte el texto de un error en un mensaje claro para el cajero: nunca
/// muestra la excepción cruda ni el prefijo técnico del servidor.
String friendlyInventoryError(String? raw, {String what = 'la información'}) {
  final text = (raw ?? '').trim();
  final lower = text.toLowerCase();
  if (lower.contains('conexi') ||
      lower.contains('internet') ||
      lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('timeout') ||
      lower.contains('connection')) {
    return 'Sin conexión. Revisa el internet e intenta de nuevo.';
  }
  final clean = text.replaceFirst(RegExp(r'^Solicitud incorrecta:\s*'), '');
  final looksTechnical = clean.isEmpty ||
      clean.length > 140 ||
      RegExp(
              r'exception|error|null|stack|failed|status|internal|server|'
              r'not found|invalid|unauthorized|forbidden|bad request|'
              r'\bat\b|dart:|_\w+\(',
              caseSensitive: false)
          .hasMatch(clean);
  if (looksTechnical) {
    return 'Hubo un problema al cargar $what. Intenta de nuevo; si sigue fallando, avisa a soporte.';
  }
  return clean;
}

/// Da formato colombiano (miles con punto) a una cantidad que llega como
/// texto ("+120003" → "+120.003", "-5" → "−5"). Si no es un número, la deja
/// igual.
String formatInventoryQuantityText(String text) {
  final m = RegExp(r'^([+-]?)(\d+(?:\.\d+)?)$').firstMatch(text.trim());
  if (m == null) return text;
  final sign = m.group(1) == '-' ? '\u2212' : (m.group(1) ?? '');
  return '$sign${AppFormatters.formatStock(num.parse(m.group(2)!))}';
}

/// Carga de pantalla completa: indicador azul de la app con su texto.
class InventoryLoadingState extends StatelessWidget {
  final String message;
  const InventoryLoadingState(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation<Color>(ElegantLightTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error de pantalla completa: ícono en degradado, mensaje claro y botón
/// "Reintentar" con el azul de la app.
class InventoryErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const InventoryErrorState({
    super.key,
    this.title = 'No se pudo cargar',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrebIconBadge(
                icon: Icons.cloud_off_rounded,
                gradient: ElegantLightTheme.errorGradient,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: brebPrimaryButtonStyle(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Vacío de pantalla completa: ícono suave, título, explicación y, si aplica,
/// una acción.
class InventoryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  const InventoryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon = Icons.refresh_rounded,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: ElegantLightTheme.primaryBlue),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onAction,
                  style: brebSecondaryButtonStyle(),
                  icon: Icon(actionIcon, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
