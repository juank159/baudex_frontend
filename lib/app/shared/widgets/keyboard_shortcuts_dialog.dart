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
///   - Menú "Atajos de teclado" en el footer del drawer
class KeyboardShortcutsDialog extends StatefulWidget {
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
        barrierColor: Colors.black.withValues(alpha: 0.35),
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

  @override
  State<KeyboardShortcutsDialog> createState() =>
      _KeyboardShortcutsDialogState();
}

class _KeyboardShortcutsDialogState extends State<KeyboardShortcutsDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // Animación cinematográfica: curva "expo out" `Cubic(0.16, 1, 0.3,
    // 1)` con 360ms. Arranca rápido y desacelera mucho al final, dando
    // sensación de modal "moderna y elegante" (estilo Linear / Vercel /
    // Raycast). Antes usaba `easeOutBack` (rebote) o `easeOutCubic`
    // (lineal), ambos se sentían más bruscos.
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    const elegantCurve = Cubic(0.16, 1, 0.3, 1);
    _fade = CurvedAnimation(parent: _animController, curve: elegantCurve);
    _scale = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: elegantCurve),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
    final groups = KeyboardShortcutsRegistry.groupedForUser();

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _handleKey(node, event, context),
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 40,
              vertical: 24,
            ),
            elevation: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 660,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ElegantLightTheme.textTertiary
                        .withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    ...ElegantLightTheme.elevatedShadow,
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue
                          .withValues(alpha: 0.10),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(context),
                      Flexible(
                        child: SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(20, 18, 20, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final entry in groups.entries) ...[
                                if (entry.value.isNotEmpty) ...[
                                  _buildGroup(entry.key, entry.value),
                                  const SizedBox(height: 16),
                                ],
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
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 14, 20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.keyboard_alt_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Atajos de teclado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Comandos disponibles para trabajar más rápido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.15),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(ShortcutScope scope, List<KeyboardShortcut> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: _gradientForScope(scope),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  _iconForScope(scope),
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  KeyboardShortcutsRegistry.scopeLabel(scope),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ElegantLightTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              KeyboardShortcutsRegistry.scopeHint(scope),
              style: TextStyle(
                fontSize: 11.5,
                color: ElegantLightTheme.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++) ...[
            _buildShortcutRow(items[i]),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Divider(
                  color: ElegantLightTheme.textTertiary
                      .withValues(alpha: 0.08),
                  height: 1,
                  thickness: 1,
                ),
              ),
          ],
        ],
      ),
    );
  }

  LinearGradient _gradientForScope(ShortcutScope scope) {
    switch (scope) {
      case ShortcutScope.global:
        return ElegantLightTheme.primaryGradient;
      case ShortcutScope.invoiceTabs:
        return ElegantLightTheme.successGradient;
      case ShortcutScope.invoiceForm:
        return ElegantLightTheme.warningGradient;
    }
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              s.description,
              style: TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textPrimary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Wrap(
            spacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0;
                  i < s.displayParts(isMacOs: _isMacOs).length;
                  i++) ...[
                _buildKeyChip(s.displayParts(isMacOs: _isMacOs)[i]),
                if (i < s.displayParts(isMacOs: _isMacOs).length - 1 &&
                    !_isMacOs)
                  Text(
                    '+',
                    style: TextStyle(
                      color: ElegantLightTheme.textTertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyChip(String label) {
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          // Sombra inferior tipo "tecla física".
          BoxShadow(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.4),
            offset: const Offset(0, 1.5),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: ElegantLightTheme.textPrimary,
          fontFamily: 'monospace',
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildFooterTip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            ElegantLightTheme.warningOrange.withValues(alpha: 0.10),
            ElegantLightTheme.warningOrange.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.warningOrange.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ElegantLightTheme.warningOrange.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: ElegantLightTheme.warningOrange,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: ElegantLightTheme.textSecondary,
                  height: 1.45,
                ),
                children: [
                  const TextSpan(text: 'Tip: presiona '),
                  TextSpan(
                    text: _isMacOs ? '⌘ + /' : 'Ctrl + /',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  const TextSpan(
                    text: ' en cualquier momento para abrir esta guía.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
