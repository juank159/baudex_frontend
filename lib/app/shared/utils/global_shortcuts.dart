// lib/app/shared/utils/global_shortcuts.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../config/routes/app_routes.dart';
import '../widgets/command_palette_dialog.dart';
import '../widgets/keyboard_shortcuts_dialog.dart';

/// Capa de Shortcuts/Actions/Intents globales que se monta UNA SOLA VEZ
/// en `GetMaterialApp.builder`. Convierte combinaciones de teclas en
/// llamadas a funciones (`CommandPalette.open`, navegación, etc).
///
/// Por qué `Shortcuts/Actions` en vez de `HardwareKeyboard.addHandler`:
///   1. Respeta el árbol de focus de Flutter automáticamente. Si una
///      pantalla interna declara su propio `Shortcuts`, gana — los
///      atajos del invoice form (Ctrl+1..9) siguen vivos sin que este
///      handler los intercepte.
///   2. TextField absorbe primero las letras → no se disparan atajos
///      mientras el usuario escribe.
///   3. En macOS, `LogicalKeyboardKey.control` se mapea a Cmd; el
///      MacOSKeyMapper de Flutter lo hace por nosotros.
class GlobalShortcuts {
  GlobalShortcuts._();

  /// Wrapper para `GetMaterialApp.builder`. Envuelve el árbol con
  /// Shortcuts + Actions justo encima del Navigator.
  static Widget builder(BuildContext context, Widget? child) {
    if (child == null) return const SizedBox.shrink();
    return _GlobalShortcutsScope(child: child);
  }
}

// ──────────────────────────────────────────────────────────────────
// Intents — uno por acción. Marcadores que el Actions traduce.
// ──────────────────────────────────────────────────────────────────

class _OpenCommandPaletteIntent extends Intent {
  const _OpenCommandPaletteIntent();
}

class _ToggleDrawerIntent extends Intent {
  const _ToggleDrawerIntent();
}

class _ShowShortcutsGuideIntent extends Intent {
  const _ShowShortcutsGuideIntent();
}

class _NavigateIntent extends Intent {
  final String route;
  const _NavigateIntent(this.route);
}

// ──────────────────────────────────────────────────────────────────
// Widget que monta Shortcuts + Actions globales.
// ──────────────────────────────────────────────────────────────────

class _GlobalShortcutsScope extends StatelessWidget {
  final Widget child;
  const _GlobalShortcutsScope({required this.child});

  bool _shouldSkip() {
    // Las pantallas previas al login no manejan navegación de módulos,
    // así que silenciamos los atajos ahí para no abrir el palette/
    // drawer/etc. antes de tiempo. La guía de atajos SÍ se permite
    // (puede ser útil leerla antes de loguearse).
    final route = Get.currentRoute;
    const blockedRoutes = {
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.forgotPassword,
      AppRoutes.verifyEmail,
    };
    return blockedRoutes.contains(route);
  }

  void _openPalette() {
    if (_shouldSkip()) return;
    CommandPalette.open();
  }

  void _toggleDrawer() {
    if (_shouldSkip()) return;
    final ctx = Get.context;
    if (ctx == null) return;
    // Buscar el Scaffold de la pantalla actual. Si tiene drawer, lo
    // alternamos. Si no, no hacemos nada (evita errores en pantallas
    // sin drawer como dialogs full-screen).
    final scaffold = Scaffold.maybeOf(ctx);
    if (scaffold == null || !scaffold.hasDrawer) return;
    if (scaffold.isDrawerOpen) {
      Navigator.of(ctx).pop();
    } else {
      scaffold.openDrawer();
    }
  }

  void _openGuide() {
    final ctx = Get.context;
    if (ctx == null) return;
    KeyboardShortcutsDialog.show(ctx);
  }

  void _navigateTo(String route) {
    if (_shouldSkip()) return;
    if (Get.currentRoute == route) return;
    if (route == AppRoutes.dashboard) {
      Get.offAllNamed(route);
    } else {
      Get.toNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // Globales
        const SingleActivator(LogicalKeyboardKey.keyK, control: true, meta: true):
            const _OpenCommandPaletteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            const _OpenCommandPaletteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            const _OpenCommandPaletteIntent(),

        const SingleActivator(LogicalKeyboardKey.keyB, control: true):
            const _ToggleDrawerIntent(),
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
            const _ToggleDrawerIntent(),

        const SingleActivator(LogicalKeyboardKey.slash, control: true):
            const _ShowShortcutsGuideIntent(),
        const SingleActivator(LogicalKeyboardKey.slash, meta: true):
            const _ShowShortcutsGuideIntent(),

        // Acceso directo Alt+1..9 a las rutas más usadas.
        // Alt evita el choque con Ctrl+1..9 que el form de factura usa
        // para cambiar cantidades de productos.
        const SingleActivator(LogicalKeyboardKey.digit1, alt: true):
            _NavigateIntent(AppRoutes.dashboard),
        const SingleActivator(LogicalKeyboardKey.digit2, alt: true):
            _NavigateIntent(AppRoutes.invoicesWithTabs),
        const SingleActivator(LogicalKeyboardKey.digit3, alt: true):
            _NavigateIntent(AppRoutes.invoices),
        const SingleActivator(LogicalKeyboardKey.digit4, alt: true):
            _NavigateIntent(AppRoutes.cashRegister),
        const SingleActivator(LogicalKeyboardKey.digit5, alt: true):
            _NavigateIntent(AppRoutes.customers),
        const SingleActivator(LogicalKeyboardKey.digit6, alt: true):
            _NavigateIntent(AppRoutes.products),
        const SingleActivator(LogicalKeyboardKey.digit7, alt: true):
            _NavigateIntent(AppRoutes.inventory),
        const SingleActivator(LogicalKeyboardKey.digit8, alt: true):
            _NavigateIntent(AppRoutes.customerCredits),
        const SingleActivator(LogicalKeyboardKey.digit9, alt: true):
            _NavigateIntent(AppRoutes.expenses),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _OpenCommandPaletteIntent: CallbackAction<_OpenCommandPaletteIntent>(
            onInvoke: (_) {
              _openPalette();
              return null;
            },
          ),
          _ToggleDrawerIntent: CallbackAction<_ToggleDrawerIntent>(
            onInvoke: (_) {
              _toggleDrawer();
              return null;
            },
          ),
          _ShowShortcutsGuideIntent:
              CallbackAction<_ShowShortcutsGuideIntent>(
            onInvoke: (_) {
              _openGuide();
              return null;
            },
          ),
          _NavigateIntent: CallbackAction<_NavigateIntent>(
            onInvoke: (intent) {
              _navigateTo(intent.route);
              return null;
            },
          ),
        },
        // Focus invisible al nivel raíz para garantizar que los
        // shortcuts globales se procesen aunque no haya un widget
        // específico con focus (ej. justo después de cerrar un dialog).
        child: Focus(
          autofocus: false,
          // skipTraversal evita que este focus aparezca cuando el
          // usuario presiona Tab — no es un campo editable.
          skipTraversal: true,
          child: child,
        ),
      ),
    );
  }
}
