// lib/app/ui/layouts/main_layout.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../core/theme/elegant_light_theme.dart';

class MainLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final bool showDrawer;
  final IconData drawerIcon;

  const MainLayout({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.showBackButton = false, // Por defecto false para mostrar drawer
    this.showDrawer = true,
    this.drawerIcon = Icons.menu,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildElegantAppBar(),
      body: body,
      floatingActionButton: floatingActionButton,
      drawer: showDrawer ? (drawer ?? const AppDrawer()) : null,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  PreferredSizeWidget _buildElegantAppBar() {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          shadows: [
            Shadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      actions: actions,
      automaticallyImplyLeading: showBackButton,
      leading: showDrawer && !showBackButton
          ? Builder(
              builder: (context) => IconButton(
                icon: Icon(drawerIcon),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menú',
              ),
            )
          : null,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ElegantLightTheme.primaryGradient.colors.first,
              ElegantLightTheme.primaryGradient.colors.last,
              ElegantLightTheme.primaryBlue,
            ],
            stops: [0.0, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: ElegantLightTheme.primaryBlue.withOpacity(0.5),
    );
  }
}