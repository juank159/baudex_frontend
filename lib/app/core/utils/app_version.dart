import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/elegant_light_theme.dart';

/// Versión instalada de la app (la del instalador, no la del .env), para
/// confirmar qué versión está corriendo un cliente.
class AppVersion {
  AppVersion._();

  static String? _label;
  static Future<String?>? _loading;

  /// "1.0.1 (3)", o `null` si todavía no se ha leído.
  static String? get label => _label;

  static Future<String?> load() => _loading ??= () async {
        try {
          final info = await PackageInfo.fromPlatform();
          _label = info.buildNumber.isEmpty
              ? info.version
              : '${info.version} (${info.buildNumber})';
        } catch (_) {
          _label = null;
        }
        return _label;
      }();
}

/// Texto discreto "Versión 1.0.1 (3)".
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key, this.textAlign = TextAlign.center});

  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AppVersion.load(),
      initialData: AppVersion.label,
      builder: (context, snapshot) {
        final label = snapshot.data;
        if (label == null) return const SizedBox.shrink();
        return Text(
          'Versión $label',
          textAlign: textAlign,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ElegantLightTheme.textTertiary,
          ),
        );
      },
    );
  }
}
