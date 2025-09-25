// lib/app/shared/models/drawer_menu_item.dart
import 'package:flutter/material.dart';

/// Modelo para los items del menú del drawer
class DrawerMenuItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;
  final bool isInSettings;
  final bool isInConfigurationGroup;
  final bool isEnabled;
  final List<DrawerMenuItem>? submenu;
  
  const DrawerMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.subtitle,
    this.route,
    this.onTap,
    this.isInSettings = false,
    this.isInConfigurationGroup = false,
    this.isEnabled = true,
    this.submenu,
  });

  /// Getter para determinar si tiene submenú
  bool get hasSubmenu => submenu != null && submenu!.isNotEmpty;

  DrawerMenuItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    String? route,
    VoidCallback? onTap,
    bool? isInSettings,
    bool? isInConfigurationGroup,
    bool? isEnabled,
    List<DrawerMenuItem>? submenu,
  }) {
    return DrawerMenuItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      onTap: onTap ?? this.onTap,
      isInSettings: isInSettings ?? this.isInSettings,
      isInConfigurationGroup: isInConfigurationGroup ?? this.isInConfigurationGroup,
      isEnabled: isEnabled ?? this.isEnabled,
      submenu: submenu ?? this.submenu,
    );
  }
}