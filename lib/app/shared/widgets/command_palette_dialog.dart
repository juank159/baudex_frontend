// lib/app/shared/widgets/command_palette_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../config/routes/app_routes.dart';
import '../../core/theme/elegant_light_theme.dart';
import '../controllers/app_drawer_controller.dart';
import '../models/drawer_menu_item.dart';
import '../utils/drawer_permission_filter.dart';

/// "Command palette" estilo Spotlight / Cmd-K — popup con buscador
/// fuzzy + lista filtrable de TODAS las rutas a las que el usuario
/// actual tiene permiso.
///
/// Disparador: atajo global `Ctrl + K`. Cuando se selecciona un
/// resultado se cierra el dialog y se navega con `Get.toNamed`.
///
/// Fuente de datos:
///   - Items vienen del `AppDrawerController.menuItems` (la misma
///     fuente del drawer), así no hay que mantener una lista paralela.
///   - Se aplica el `DrawerPermissionFilter` para que un usuario sin
///     permiso a un módulo tampoco lo vea en el palette.
class CommandPaletteDialog extends StatefulWidget {
  const CommandPaletteDialog({super.key});

  /// Flag estático que indica si HAY una instancia del palette abierta.
  /// Sirve para que el atajo `Ctrl + K` se comporte como un TOGGLE en
  /// vez de apilar dialogs (bug reportado: presionar Cmd+K múltiples
  /// veces abría varias instancias encima).
  static bool _isOpen = false;

  /// Acceso de solo-lectura para que callers externos (como el handler
  /// global de shortcuts) puedan decidir si abrir o cerrar.
  static bool get isOpen => _isOpen;

  /// Abre el palette SOLO si no hay otra instancia abierta. Si ya hay
  /// una, no hace nada (idempotente).
  static Future<void> show(BuildContext context) async {
    if (_isOpen) return;
    _isOpen = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        // El palette aparece "anclado" en la parte superior del viewport
        // para que la búsqueda quede cerca de las manos del usuario en
        // pantallas verticales.
        builder: (_) => const CommandPaletteDialog(),
      );
    } finally {
      // Se limpia el flag pase lo que pase: cerró por Esc, click fuera,
      // selección de un resultado, o un pop manual. Sin este finally
      // el palette quedaría "marcado como abierto" tras cerrarse y el
      // siguiente Cmd+K no lo reabriría.
      _isOpen = false;
    }
  }

  /// Comportamiento toggle para el atajo `Ctrl + K`. Si está abierto,
  /// lo cierra; si no, lo abre. Es el patrón estándar de Slack/Notion/
  /// VSCode: la misma tecla que abre la busqueda también la oculta.
  static Future<void> toggle(BuildContext context) async {
    if (_isOpen) {
      // Cerrar usando rootNavigator porque el dialog se monta ahí.
      // `maybePop` no rompe si por alguna razón el dialog ya se cerró
      // entre el check y este pop (race condition raro pero posible).
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
      return;
    }
    await show(context);
  }

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();

  // Lista plana (items + sub-items) que sirve de fuente para filtrar.
  late final List<_PaletteEntry> _allEntries;
  late List<_PaletteEntry> _filtered;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _allEntries = _collectEntries();
    _filtered = _allEntries;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Aplana el árbol de menú (incluyendo sub-items) y filtra por permisos.
  /// Resultado: una sola lista navegable.
  List<_PaletteEntry> _collectEntries() {
    if (!Get.isRegistered<AppDrawerController>()) return const [];
    final ctrl = Get.find<AppDrawerController>();
    final filtered = DrawerPermissionFilter.apply(ctrl.menuItems);

    final entries = <_PaletteEntry>[];
    for (final item in filtered) {
      if (item.hasSubmenu) {
        for (final child in item.submenu!) {
          if (child.route == null) continue;
          entries.add(_PaletteEntry(
            title: child.title,
            subtitle: child.subtitle,
            icon: child.icon,
            route: child.route!,
            groupHint: item.title,
          ));
        }
      } else if (item.route != null) {
        entries.add(_PaletteEntry(
          title: item.title,
          subtitle: item.subtitle,
          icon: item.icon,
          route: item.route!,
          groupHint: item.isInConfigurationGroup ? 'Configuración' : null,
        ));
      }
    }
    return entries;
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _allEntries;
      } else {
        _filtered = _allEntries.where((e) => e.matches(q)).toList();
      }
      _selectedIndex =
          _filtered.isEmpty ? 0 : _selectedIndex.clamp(0, _filtered.length - 1);
    });
  }

  void _navigateToSelected() {
    if (_filtered.isEmpty) return;
    final entry = _filtered[_selectedIndex];
    Navigator.of(context).pop();
    // toNamed es más seguro que offNamed: si la ruta no existe, no
    // tumba la sesión. El usuario puede volver con back.
    Get.toNamed(entry.route);
  }

  // ──────────────────────────────────────────────────────────────────
  // Teclas locales del palette: ↑/↓ navegar, Enter selecciona, Esc cierra.
  // Estos shortcuts viven DENTRO del dialog, así que no compiten con
  // los globales (Flutter resuelve el inner widget primero).
  // ──────────────────────────────────────────────────────────────────
  KeyEventResult _handleSearchKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    // Cmd/Ctrl + K dentro del palette = cerrarlo (toggle local).
    // Esta defensa garantiza que el "toggle con la misma tecla" funcione
    // aun si por algún motivo el Shortcuts global no procesa el evento
    // (puede pasar cuando el TextField está enfocado dentro del dialog
    // y la jerarquía de focus consume el atajo localmente).
    if (event.logicalKey == LogicalKeyboardKey.keyK &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_filtered.isEmpty) return KeyEventResult.handled;
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _filtered.length;
      });
      _scrollToSelected();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_filtered.isEmpty) return KeyEventResult.handled;
      setState(() {
        _selectedIndex =
            (_selectedIndex - 1 + _filtered.length) % _filtered.length;
      });
      _scrollToSelected();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _navigateToSelected();
      return KeyEventResult.handled;
    }
    // Esc lo deja pasar — Flutter lo asocia al cierre del dialog por
    // default. Si lo capturamos aquí se rompe.
    return KeyEventResult.ignored;
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    const itemHeight = 56.0;
    final target = _selectedIndex * itemHeight;
    final viewport = _scrollController.position.viewportDimension;
    final offset = _scrollController.offset;
    if (target < offset) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    } else if (target + itemHeight > offset + viewport) {
      _scrollController.animateTo(
        target + itemHeight - viewport,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.only(
        left: isMobile ? 12 : 80,
        right: isMobile ? 12 : 80,
        top: isMobile ? 60 : 80,
        bottom: isMobile ? 24 : 24,
      ),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchBar(),
                const Divider(height: 1, thickness: 1),
                Flexible(child: _buildResultsList()),
                const Divider(height: 1, thickness: 1),
                _buildHelpBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: ElegantLightTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Focus(
              onKeyEvent: _handleSearchKey,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Buscar pantallas, módulos, acciones...',
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.requestFocus();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              color: ElegantLightTheme.textTertiary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final entry = _filtered[index];
        final isSelected = index == _selectedIndex;
        return Material(
          color: isSelected
              ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.08)
              : Colors.transparent,
          child: InkWell(
            // No tomar focus — el TextField del search debe mantenerlo
            // para que el usuario siga tecleando sin perder posición.
            canRequestFocus: false,
            onTap: () {
              setState(() => _selectedIndex = index);
              _navigateToSelected();
            },
            onHover: (hover) {
              if (hover && _selectedIndex != index) {
                setState(() => _selectedIndex = index);
              }
            },
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ElegantLightTheme.primaryBlue
                              .withValues(alpha: 0.15)
                          : ElegantLightTheme.textTertiary
                              .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      entry.icon,
                      size: 17,
                      color: isSelected
                          ? ElegantLightTheme.primaryBlue
                          : ElegantLightTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          entry.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: ElegantLightTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (entry.groupHint != null ||
                            entry.subtitle != null)
                          Text(
                            entry.groupHint ?? entry.subtitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: ElegantLightTheme.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.subdirectory_arrow_left,
                      size: 14,
                      color: ElegantLightTheme.textTertiary,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: ElegantLightTheme.textTertiary.withValues(alpha: 0.05),
      child: Row(
        children: [
          _kbd('↑'),
          _kbd('↓'),
          const SizedBox(width: 4),
          Text(
            'navegar',
            style: TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          _kbd('Enter'),
          const SizedBox(width: 4),
          Text(
            'abrir',
            style: TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          _kbd('Esc'),
          const SizedBox(width: 4),
          Text(
            'cerrar',
            style: TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '${_filtered.length} resultado${_filtered.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kbd(String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          color: ElegantLightTheme.textPrimary,
        ),
      ),
    );
  }
}

/// Entrada normalizada que muestra el palette. Soporta búsqueda fuzzy
/// simple (substring case-insensitive sobre title, subtitle y groupHint).
class _PaletteEntry {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String route;
  final String? groupHint;

  _PaletteEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.groupHint,
  });

  bool matches(String queryLower) {
    if (title.toLowerCase().contains(queryLower)) return true;
    if (subtitle != null && subtitle!.toLowerCase().contains(queryLower)) {
      return true;
    }
    if (groupHint != null && groupHint!.toLowerCase().contains(queryLower)) {
      return true;
    }
    // Match contra la ruta sin slash inicial (útil para "/invoices" → invoices)
    if (route.replaceFirst('/', '').toLowerCase().contains(queryLower)) {
      return true;
    }
    return false;
  }
}

/// Helper utility para que callers (Intent, drawer, etc) no necesiten
/// importar el dialog directamente cuando lo abren por API.
class CommandPalette {
  CommandPalette._();

  /// Comportamiento toggle (recomendado para atajos de teclado):
  /// abre si está cerrado, cierra si está abierto. Es lo que esperan
  /// los usuarios cuando presionan Cmd+K dos veces seguidas.
  static Future<void> toggle() async {
    final ctx = Get.context;
    if (ctx == null) return;
    await CommandPaletteDialog.toggle(ctx);
  }

  /// Sólo abre — usar cuando ya sabes que el palette está cerrado
  /// (ej. desde un botón explícito, no desde un shortcut). Si ya estaba
  /// abierto, es idempotente (no abre otra instancia).
  static Future<void> open() async {
    final ctx = Get.context;
    if (ctx == null) return;
    await CommandPaletteDialog.show(ctx);
  }

  /// Navegación por ID de ruta — usado por los atajos `Alt + N`.
  static void navigateToRoute(String route) {
    if (route == AppRoutes.dashboard) {
      Get.offAllNamed(route);
    } else {
      Get.toNamed(route);
    }
  }
}
