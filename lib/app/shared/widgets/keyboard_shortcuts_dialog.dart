// lib/app/shared/widgets/keyboard_shortcuts_dialog.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/elegant_light_theme.dart';
import '../data/keyboard_shortcuts_registry.dart';
import '../models/keyboard_shortcut.dart';

/// Dialog con la cheat sheet completa de atajos de teclado.
///
/// Lee del `KeyboardShortcutsRegistry` (única fuente de verdad), así
/// que cualquier atajo nuevo aparece automáticamente sin tocar este
/// archivo.
///
/// Accesible desde:
///   - Atajo `Ctrl + /`
///   - Botón "Atajos de teclado" en el footer del drawer
///   - Sección de configuración (si el usuario decide buscarla)
class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({super.key});

  /// Flag estático para que el atajo `Ctrl + /` se comporte como TOGGLE
  /// y no apile múltiples instancias del dialog al presionarlo varias
  /// veces.
  static bool _isOpen = false;
  static bool get isOpen => _isOpen;

  /// Abre la guía SOLO si no está ya abierta (idempotente).
  static Future<void> show(BuildContext context) async {
    if (_isOpen) return;
    _isOpen = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const KeyboardShortcutsDialog(),
      );
    } finally {
      _isOpen = false;
    }
  }

  /// Comportamiento toggle para el atajo `Ctrl + /`.
  static Future<void> toggle(BuildContext context) async {
    if (_isOpen) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) navigator.pop();
      return;
    }
    await show(context);
  }

  bool get _isMacOs {
    if (kIsWeb) return false;
    try {
      return Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  /// Listener interno: si el usuario presiona Ctrl/Cmd + / mientras la
  /// guía está visible, se cierra. Defensa adicional al `toggle` global
  /// para el caso en que el evento no suba al Shortcuts del MaterialApp.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event, BuildContext ctx) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.slash &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      Navigator.of(ctx).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final groups = KeyboardShortcutsRegistry.grouped;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _handleKey(node, event, context),
      child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final entry in groups.entries) ...[
                          _buildGroup(entry.key, entry.value),
                          const SizedBox(height: 18),
                        ],
                        _buildFooterTip(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.keyboard_alt_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Atajos de teclado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Comandos disponibles para trabajar más rápido',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(ShortcutScope scope, List<KeyboardShortcut> items) {
    return Container(
      decoration: BoxDecoration(
        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconForScope(scope),
                size: 16,
                color: ElegantLightTheme.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                KeyboardShortcutsRegistry.scopeLabel(scope),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: ElegantLightTheme.primaryBlue,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            KeyboardShortcutsRegistry.scopeHint(scope),
            style: TextStyle(
              fontSize: 11.5,
              color: ElegantLightTheme.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          for (final shortcut in items) _buildShortcutRow(shortcut),
        ],
      ),
    );
  }

  IconData _iconForScope(ShortcutScope scope) {
    switch (scope) {
      case ShortcutScope.global:
        return Icons.public_outlined;
      case ShortcutScope.invoiceTabs:
        return Icons.tab_outlined;
      case ShortcutScope.invoiceForm:
        return Icons.receipt_long_outlined;
    }
  }

  Widget _buildShortcutRow(KeyboardShortcut s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              s.description,
              style: TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 4,
            children: [
              for (final part in s.displayParts(isMacOs: _isMacOs))
                _buildKeyChip(part),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: ElegantLightTheme.textPrimary,
          fontFamily: 'monospace',
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildFooterTip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ElegantLightTheme.warningOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.warningOrange.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: ElegantLightTheme.warningOrange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tip: presiona ${_isMacOs ? '⌘' : 'Ctrl'} + / en cualquier momento '
              'para volver a abrir esta guía.',
              style: TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
