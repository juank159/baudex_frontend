// lib/app/shared/widgets/performance_mode_dialog.dart
//
// Configuración → Rendimiento: Automático / Liviano / Completo.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/breb/presentation/widgets/breb_ui.dart';
import '../../core/theme/elegant_light_theme.dart';
import '../../core/theme/performance_mode.dart';

/// Abre el diálogo de Rendimiento.
Future<void> showPerformanceModeDialog() =>
    Get.dialog<void>(const PerformanceModeDialog());

class PerformanceModeDialog extends StatefulWidget {
  const PerformanceModeDialog({super.key});

  @override
  State<PerformanceModeDialog> createState() => _PerformanceModeDialogState();
}

class _PerformanceModeDialogState extends State<PerformanceModeDialog> {
  late PerformanceSetting _selected = PerformanceMode.setting;

  static const _descriptions = {
    PerformanceSetting.auto:
        'La app decide. Si este equipo tarda en dibujar la pantalla, pasa sola a Liviano.',
    PerformanceSetting.light:
        'Más rápido al escribir y al cambiar de pantalla: sin desenfoques, sombras suaves ni animaciones decorativas.',
    PerformanceSetting.full:
        'Todos los efectos visuales. Para equipos con buena tarjeta gráfica.',
  };

  static const _icons = {
    PerformanceSetting.auto: Icons.auto_awesome_outlined,
    PerformanceSetting.light: Icons.bolt_outlined,
    PerformanceSetting.full: Icons.blur_on_outlined,
  };

  Future<void> _save() async {
    await PerformanceMode.choose(_selected);
    if (mounted) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return brebAlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.speed, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Rendimiento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              PerformanceMode.setting == PerformanceSetting.auto
                  ? 'Ahora: Automático (tema ${PerformanceMode.isLight ? 'liviano' : 'completo'} en este equipo).'
                  : 'Ahora: ${PerformanceMode.setting.label}.',
              style: const TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            for (final option in PerformanceSetting.values) ...[
              _Option(
                icon: _icons[option]!,
                title: option.label,
                description: _descriptions[option]!,
                selected: _selected == option,
                onTap: () => setState(() => _selected = option),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          style: brebTextButtonStyle(),
          onPressed: () => Get.back<void>(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: brebPrimaryButtonStyle(),
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const blue = ElegantLightTheme.primaryBlue;
    return Material(
      color: selected ? blue.withValues(alpha: 0.06) : ElegantLightTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? blue
                  : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: selected ? blue : ElegantLightTheme.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? blue : ElegantLightTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
