// lib/features/breb/presentation/widgets/breb_ui.dart
//
// Piezas visuales de Bre-B, hechas con el tema elegante de la app
// (ElegantLightTheme / FuturisticContainer) para que estas pantallas se vean
// igual que el resto: mismas tarjetas, mismos degradados, mismos diálogos.
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';

/// Ícono blanco sobre un cuadro con degradado: el encabezado de tarjetas y
/// diálogos en toda la app.
class BrebIconBadge extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final double size;
  final bool glow;

  const BrebIconBadge({
    super.key,
    required this.icon,
    this.gradient = ElegantLightTheme.primaryGradient,
    this.size = 24,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.5),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.5),
        boxShadow: glow ? ElegantLightTheme.glowShadow : null,
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}

/// Tarjeta de sección: encabezado con ícono, título, ayuda y una acción
/// opcional a la derecha; debajo, el contenido.
class BrebSectionCard extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String? subtitle;
  final Widget? action;
  final List<Widget> children;

  const BrebSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.gradient = ElegantLightTheme.primaryGradient,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 480;
    return FuturisticContainer(
      isHoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BrebIconBadge(icon: icon, gradient: gradient),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: narrow ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (action != null) ...[const SizedBox(width: 12), action!],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: const TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Fila dentro de una tarjeta: fondo suave, borde fino y esquinas redondas.
/// Si lleva [onTap] responde al toque (y se nota: flecha y efecto al pasar).
class BrebRowTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const BrebRowTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ElegantLightTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.25)),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: ElegantLightTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta pequeña de estado ("Con QR", "Sin QR").
class BrebChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const BrebChip({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Estado vacío dentro de una tarjeta.
class BrebEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const BrebEmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: ElegantLightTheme.textTertiary, size: 30),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ElegantLightTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Carga dentro de una tarjeta: indicador del color de la app con su texto.
class BrebInlineLoading extends StatelessWidget {
  final String label;
  const BrebInlineLoading(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(ElegantLightTheme.primaryBlue),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(label, style: const TextStyle(color: ElegantLightTheme.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Caja de aviso (información, éxito, advertencia o error) dentro de un
/// diálogo o tarjeta.
class BrebNotice extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const BrebNotice.info(this.message, {super.key})
      : color = ElegantLightTheme.primaryBlue,
        icon = Icons.info_outline;
  const BrebNotice.success(this.message, {super.key})
      : color = ElegantLightTheme.successGreen,
        icon = Icons.check_circle_outline;
  const BrebNotice.warning(this.message, {super.key})
      : color = ElegantLightTheme.warningOrange,
        icon = Icons.warning_amber_rounded;
  const BrebNotice.error(this.message, {super.key})
      : color = ElegantLightTheme.errorRed,
        icon = Icons.error_outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: ElegantLightTheme.textPrimary, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de diálogo: ícono con degradado + texto (igual que "Agregar Moneda").
Widget brebDialogTitle(
  IconData icon,
  String title, {
  LinearGradient gradient = ElegantLightTheme.infoGradient,
}) {
  return Row(
    children: [
      BrebIconBadge(icon: icon, gradient: gradient, size: 20, glow: false),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

/// Forma de los diálogos de la app.
final ShapeBorder brebDialogShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

/// Campo de texto con el borde de la app.
InputDecoration brebInputDecoration({
  required String label,
  String? hint,
  String? helper,
  IconData? icon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    prefixIcon: icon == null ? null : Icon(icon, size: 20, color: ElegantLightTheme.textSecondary),
    filled: true,
    fillColor: ElegantLightTheme.surfaceColor,
    labelStyle: const TextStyle(color: ElegantLightTheme.textSecondary),
    floatingLabelStyle: const TextStyle(color: ElegantLightTheme.primaryBlue),
    helperStyle: const TextStyle(color: ElegantLightTheme.textSecondary, fontSize: 12),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: border(ElegantLightTheme.textTertiary.withValues(alpha: 0.5)),
    enabledBorder: border(ElegantLightTheme.textTertiary.withValues(alpha: 0.5)),
    focusedBorder: border(ElegantLightTheme.primaryBlue, 1.6),
  );
}

/// Botón de texto (Cancelar, Cerrar…) en el azul de la app.
ButtonStyle brebTextButtonStyle({Color color = ElegantLightTheme.primaryBlue}) =>
    TextButton.styleFrom(
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

/// Diálogo con el aspecto de la app: blanco, esquinas redondas, sin el tinte
/// de color que Material 3 le pone por defecto.
AlertDialog brebAlertDialog({
  required Widget title,
  required Widget content,
  required List<Widget> actions,
}) =>
    AlertDialog(
      backgroundColor: ElegantLightTheme.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: brebDialogShape,
      titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
      contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: title,
      content: content,
      actions: actions,
    );

/// Botón principal (azul de la app, esquinas redondas).
/// No fija la fuente: usa la de la app.
ButtonStyle brebPrimaryButtonStyle({Color color = ElegantLightTheme.primaryBlue}) =>
    ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      disabledBackgroundColor: ElegantLightTheme.textTertiary.withValues(alpha: 0.4),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

/// Botón secundario (borde, mismo radio).
ButtonStyle brebSecondaryButtonStyle({Color color = ElegantLightTheme.primaryBlue}) =>
    OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
