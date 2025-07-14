// lib/features/invoices/presentation/screens/invoice_form_tabs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/app_scaffold.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../controllers/invoice_tabs_controller.dart';
import '../controllers/invoice_form_controller.dart';
import 'invoice_form_screen.dart';

class InvoiceFormTabsScreen extends StatefulWidget {
  const InvoiceFormTabsScreen({super.key});

  @override
  State<InvoiceFormTabsScreen> createState() => _InvoiceFormTabsScreenState();
}

class _InvoiceFormTabsScreenState extends State<InvoiceFormTabsScreen> {
  late InvoiceTabsController tabsController;

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador de pestañas
    print('🔖 INIT: Inicializando InvoiceTabsController...');
    tabsController = Get.put(InvoiceTabsController());

    // Agregar un callback después del primer frame para debug
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔖 POST-FRAME: Tabs disponibles: ${tabsController.tabs.length}');
      tabsController.printTabsInfo();
    });

    // Configurar shortcuts globales
    _setupGlobalShortcuts();
  }

  void _setupGlobalShortcuts() {
    ServicesBinding.instance.keyboard.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Ctrl+T - Nueva pestaña
      if ((event.logicalKey == LogicalKeyboardKey.keyT) &&
          (HardwareKeyboard.instance.isControlPressed)) {
        tabsController.addNewTab();
        return true;
      }

      // Ctrl+W - Cerrar pestaña actual
      if ((event.logicalKey == LogicalKeyboardKey.keyW) &&
          (HardwareKeyboard.instance.isControlPressed)) {
        if (tabsController.currentTab != null) {
          tabsController.closeTab(tabsController.currentTab!.id);
        }
        return true;
      }

      // Ctrl+Tab - Siguiente pestaña
      if ((event.logicalKey == LogicalKeyboardKey.tab) &&
          (HardwareKeyboard.instance.isControlPressed)) {
        final nextIndex =
            (tabsController.currentTabIndex + 1) % tabsController.tabs.length;
        tabsController.switchToTab(nextIndex);
        return true;
      }

      // Ctrl+1-5 - Ir a pestaña específica
      if (HardwareKeyboard.instance.isControlPressed &&
          event.logicalKey.keyLabel.length == 1) {
        final key = event.logicalKey.keyLabel;
        if (RegExp(r'^[1-5]$').hasMatch(key)) {
          final tabIndex = int.parse(key) - 1;
          if (tabIndex < tabsController.tabs.length) {
            tabsController.switchToTab(tabIndex);
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppScaffold(
        currentRoute: AppRoutes.invoicesWithTabs,
        appBar: _buildAppBar(),
        body: _buildTabContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Facturas'),
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bottom: _buildTabBar(),
      actions: [
        // Botón para nueva pestaña
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Nueva Factura (Ctrl+T)',
          onPressed:
              tabsController.canAddMoreTabs
                  ? () => tabsController.addNewTab()
                  : null,
        ),

        // Menú de opciones de pestañas
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(
                        Icons.content_copy,
                        size: 16,
                        color: Colors.lightBlue,
                      ),
                      SizedBox(width: 8),
                      Text('Duplicar Pestaña'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'close_others',
                  child: Row(
                    children: [
                      Icon(Icons.close_fullscreen, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cerrar Otras'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'shortcuts',
                  child: Row(
                    children: [
                      Icon(Icons.keyboard, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Ver Atajos'),
                    ],
                  ),
                ),
              ],
        ),

        // Botón de configuraciones (movido aquí desde el drawer izquierdo)
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Configuraciones',
          onPressed: () => _showConfigurationsMenu(context),
        ),
      ],
    );
  }

  PreferredSizeWidget? _buildTabBar() {
    if (!tabsController.hasTabs) {
      return null;
    }

    return PreferredSize(
      preferredSize: const Size.fromHeight(48.0),
      child: Obx(
        () => TabBar(
          controller: tabsController.tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs:
              tabsController.tabs.map((tab) {
                return _buildTabWidget(tab);
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabWidget(InvoiceTab tab) {
    final isActive = tabsController.currentTab?.id == tab.id;
    final hasUnsavedChanges = tab.controller.invoiceItems.isNotEmpty;

    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de cambios sin guardar
            if (hasUnsavedChanges)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),

            // Título de la pestaña
            Flexible(
              child: Text(
                tab.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),

            // Botón para cerrar pestaña
            if (tabsController.tabs.length > 1)
              GestureDetector(
                onTap: () => tabsController.closeTab(tab.id),
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 14, color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Obx(() {
      if (!tabsController.hasTabs) {
        return const Center(child: CircularProgressIndicator());
      }

      final currentTab = tabsController.currentTab;
      if (currentTab == null) {
        return const Center(child: Text('No hay pestaña seleccionada'));
      }

      // Usar el controlador directamente desde la pestaña actual
      return InvoiceFormScreen(
        key: ValueKey(currentTab.id),
        controller: currentTab.controller,
      );
    });
  }

  void _showConfigurationsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            builder:
                (context, scrollController) =>
                    _buildConfigurationsSheet(context, scrollController),
          ),
    );
  }

  Widget _buildConfigurationsSheet(
    BuildContext context,
    ScrollController scrollController,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle para arrastrar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Configuraciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildConfigurationTile(
                  icon: Icons.print,
                  title: 'Configuración de Impresora',
                  subtitle: 'Configurar impresora térmica',
                  onTap: () {
                    Navigator.pop(context);
                    _showPrinterSettings();
                  },
                ),

                _buildConfigurationTile(
                  icon: Icons.receipt_long,
                  title: 'Configuración de Facturas',
                  subtitle: 'Formato y numeración',
                  onTap: () {
                    Navigator.pop(context);
                    _showInvoiceSettings();
                  },
                ),

                Obx(
                  () => _buildConfigurationTile(
                    icon: Icons.tab,
                    title: 'Gestión de Pestañas',
                    subtitle: '${tabsController.tabs.length} pestañas abiertas',
                    onTap: () {
                      Navigator.pop(context);
                      _showTabsManagement();
                    },
                  ),
                ),

                const Divider(height: 32),

                _buildConfigurationTile(
                  icon: Icons.info,
                  title: 'Información del Sistema',
                  subtitle: 'Estado y estadísticas',
                  onTap: () {
                    Navigator.pop(context);
                    _showSystemInfo();
                  },
                ),

                _buildConfigurationTile(
                  icon: Icons.keyboard,
                  title: 'Atajos de Teclado',
                  subtitle: 'Ver lista completa',
                  onTap: () {
                    Navigator.pop(context);
                    _showKeyboardShortcuts(fromDrawer: true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // ==================== DRAWER ELIMINADO ====================
  // El drawer de configuraciones ahora es un BottomSheet accesible desde el AppBar

  void _handleMenuAction(String action) {
    switch (action) {
      case 'duplicate':
        tabsController.duplicateCurrentTab();
        break;
      case 'close_others':
        tabsController.closeOtherTabs();
        break;
      case 'shortcuts':
        _showKeyboardShortcuts(fromDrawer: false);
        break;
    }
  }

  void _showPrinterSettings() {
    Navigator.pop(context); // Cerrar drawer
    Get.toNamed('/settings/printer');
  }

  void _showInvoiceSettings() {
    Navigator.pop(context);
    Get.toNamed('/settings/invoices');
  }

  void _showTabsManagement() {
    Navigator.pop(context);
    _showTabsDialog();
  }

  void _showSystemInfo() {
    Navigator.pop(context);
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: context.isMobile ? double.infinity : 500,
            maxHeight:
                context.isMobile
                    ? MediaQuery.of(context).size.height * 0.7
                    : 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header elegante con gradiente
              Container(
                padding: EdgeInsets.all(context.isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade600, Colors.indigo.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información del Sistema',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 18,
                                tablet: 20,
                                desktop: 22,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estado actual del punto de venta',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(context.isMobile ? 16 : 24),
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de pestañas
                        _buildInfoCard(
                          context,
                          title: 'Gestión de Pestañas',
                          icon: Icons.tab,
                          color: Colors.blue,
                          items: [
                            _InfoItem(
                              'Pestañas abiertas',
                              '${tabsController.tabs.length}',
                            ),
                            _InfoItem(
                              'Máximo permitido',
                              '${InvoiceTabsController.maxTabs}',
                            ),
                            _InfoItem(
                              'Pestañas disponibles',
                              '${InvoiceTabsController.maxTabs - tabsController.tabs.length}',
                            ),
                          ],
                        ),
                        SizedBox(height: context.verticalSpacing),
                        // Card de aplicación
                        _buildInfoCard(
                          context,
                          title: 'Información de la Aplicación',
                          icon: Icons.apps,
                          color: Colors.green,
                          items: [
                            _InfoItem('Versión', '1.0.0'),
                            _InfoItem('Build', 'DEV'),
                            _InfoItem('Plataforma', 'Flutter Desktop'),
                            _InfoItem('Estado', 'Activo'),
                          ],
                        ),
                        SizedBox(height: context.verticalSpacing),
                        // Card de rendimiento
                        _buildInfoCard(
                          context,
                          title: 'Rendimiento del Sistema',
                          icon: Icons.speed,
                          color: Colors.orange,
                          items: [
                            _InfoItem(
                              'Memoria utilizada',
                              '${(tabsController.tabs.length * 15).toStringAsFixed(1)} MB',
                            ),
                            _InfoItem(
                              'Facturas en memoria',
                              '${tabsController.tabs.where((tab) => tab.controller.invoiceItems.isNotEmpty).length}',
                            ),
                            _InfoItem('Estado de conexión', 'Conectado'),
                          ],
                        ),
                        SizedBox(height: context.verticalSpacing),
                        // Información adicional
                        Container(
                          padding: EdgeInsets.all(context.isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.shade50,
                                Colors.cyan.shade100,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.cyan.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tips_and_updates,
                                color: Colors.cyan.shade600,
                                size: context.isMobile ? 20 : 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '💻 Información del Sistema',
                                      style: TextStyle(
                                        fontSize: Responsive.getFontSize(
                                          context,
                                          mobile: 13,
                                          tablet: 14,
                                          desktop: 15,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyan.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'El sistema está funcionando correctamente. Para obtener el mejor rendimiento, mantén menos de 5 pestañas abiertas.',
                                      style: TextStyle(
                                        fontSize: Responsive.getFontSize(
                                          context,
                                          mobile: 11,
                                          tablet: 12,
                                          desktop: 13,
                                        ),
                                        color: Colors.cyan.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer
              Container(
                padding: EdgeInsets.all(context.isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Última actualización: ${DateTime.now().toString().substring(0, 16)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.isMobile ? 16 : 20,
                          vertical: context.isMobile ? 8 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cerrar',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 15,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKeyboardShortcuts({bool fromDrawer = false}) {
    if (fromDrawer) {
      Navigator.pop(context); // Solo cerrar drawer si viene del drawer
    }
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: context.isMobile ? double.infinity : 600,
            maxHeight:
                context.isMobile
                    ? MediaQuery.of(context).size.height * 0.8
                    : 700,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header moderno con gradiente
              Container(
                padding: EdgeInsets.all(context.isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.keyboard,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atajos de Teclado',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 18,
                                tablet: 20,
                                desktop: 22,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mejora tu productividad con estos atajos',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido con scroll
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(context.isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShortcutSection(
                        context,
                        title: 'Gestión de Pestañas',
                        icon: Icons.tab,
                        color: Colors.blue,
                        shortcuts: [
                          _ShortcutItem(
                            'Ctrl + T',
                            'Nueva pestaña',
                            Icons.add_box,
                          ),
                          _ShortcutItem(
                            'Ctrl + W',
                            'Cerrar pestaña actual',
                            Icons.close,
                          ),
                          _ShortcutItem(
                            'Ctrl + Tab',
                            'Siguiente pestaña',
                            Icons.keyboard_tab,
                          ),
                          _ShortcutItem(
                            'Ctrl + 1-5',
                            'Ir a pestaña específica',
                            Icons.filter_1,
                          ),
                        ],
                      ),
                      SizedBox(height: context.verticalSpacing),
                      _buildShortcutSection(
                        context,
                        title: 'Gestión de Productos',
                        icon: Icons.inventory_2,
                        color: Colors.green,
                        shortcuts: [
                          _ShortcutItem(
                            '↑ / ↓',
                            'Navegar entre productos',
                            Icons.keyboard_arrow_up,
                          ),
                          _ShortcutItem(
                            'Shift + 1-9',
                            'Incrementar cantidad',
                            Icons.add_circle,
                          ),
                          _ShortcutItem(
                            'Shift + +',
                            'Incrementar cantidad en 1',
                            Icons.plus_one,
                          ),
                          _ShortcutItem(
                            'Shift + -',
                            'Decrementar cantidad en 1',
                            Icons.remove_circle,
                          ),
                          _ShortcutItem(
                            'Shift + Delete',
                            'Eliminar producto seleccionado',
                            Icons.delete,
                          ),
                        ],
                      ),
                      SizedBox(height: context.verticalSpacing),
                      _buildShortcutSection(
                        context,
                        title: 'Procesamiento de Ventas',
                        icon: Icons.point_of_sale,
                        color: Colors.orange,
                        shortcuts: [
                          _ShortcutItem(
                            'Shift + Enter',
                            'Procesar venta',
                            Icons.payment,
                          ),
                          _ShortcutItem(
                            'Ctrl + D',
                            'Duplicar producto',
                            Icons.content_copy,
                          ),
                          _ShortcutItem(
                            'Home',
                            'Ir al primer producto',
                            Icons.first_page,
                          ),
                          _ShortcutItem(
                            'End',
                            'Ir al último producto',
                            Icons.last_page,
                          ),
                        ],
                      ),
                      SizedBox(height: context.verticalSpacing),
                      // Tip adicional
                      Container(
                        padding: EdgeInsets.all(context.isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade50,
                              Colors.purple.shade100,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: Colors.purple.shade600,
                              size: context.isMobile ? 20 : 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '💡 Consejo',
                                    style: TextStyle(
                                      fontSize: Responsive.getFontSize(
                                        context,
                                        mobile: 13,
                                        tablet: 14,
                                        desktop: 15,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Usa los atajos de teclado para trabajar más rápido y ser más productivo en tu punto de venta.',
                                    style: TextStyle(
                                      fontSize: Responsive.getFontSize(
                                        context,
                                        mobile: 11,
                                        tablet: 12,
                                        desktop: 13,
                                      ),
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer con botón de acción
              Container(
                padding: EdgeInsets.all(context.isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Presiona ESC en cualquier momento para cerrar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.isMobile ? 16 : 20,
                          vertical: context.isMobile ? 8 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Entendido',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 15,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<_InfoItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Container(
            padding: EdgeInsets.all(context.isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: context.isMobile ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 15,
                      tablet: 16,
                      desktop: 17,
                    ),
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Lista de información
          Padding(
            padding: EdgeInsets.all(context.isMobile ? 12 : 16),
            child: Column(
              children:
                  items
                      .map((item) => _buildInfoRow(context, item, color))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    _InfoItem item,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Punto decorativo
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Etiqueta
          Expanded(
            flex: 3,
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Valor
          Expanded(
            flex: 2,
            child: Text(
              item.value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
                fontWeight: FontWeight.bold,
                color: accentColor.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<_ShortcutItem> shortcuts,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: EdgeInsets.all(context.isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: context.isMobile ? 18 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 15,
                      tablet: 16,
                      desktop: 17,
                    ),
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Lista de atajos
          Padding(
            padding: EdgeInsets.all(context.isMobile ? 12 : 16),
            child: Column(
              children:
                  shortcuts
                      .map(
                        (shortcut) =>
                            _buildShortcutRow(context, shortcut, color),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(
    BuildContext context,
    _ShortcutItem shortcut,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Icono del atajo
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              shortcut.icon,
              size: context.isMobile ? 14 : 16,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          // Combinación de teclas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              shortcut.keys,
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 11,
                  tablet: 12,
                  desktop: 13,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Descripción
          Expanded(
            child: Text(
              shortcut.description,
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 12,
                  tablet: 13,
                  desktop: 14,
                ),
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTabsDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: context.isMobile ? double.infinity : 550,
            maxHeight:
                context.isMobile
                    ? MediaQuery.of(context).size.height * 0.8
                    : 650,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header elegante con gradiente
              Container(
                padding: EdgeInsets.all(context.isMobile ? 20 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade600, Colors.indigo.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tab,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión de Pestañas',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 18,
                                tablet: 20,
                                desktop: 22,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Obx(
                            () => Text(
                              '${tabsController.tabs.length} pestañas abiertas de ${InvoiceTabsController.maxTabs} permitidas',
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(
                                  context,
                                  mobile: 12,
                                  tablet: 13,
                                  desktop: 14,
                                ),
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido - Lista de pestañas
              Flexible(
                child: Obx(
                  () =>
                      tabsController.tabs.isEmpty
                          ? _buildEmptyTabsState(context)
                          : SingleChildScrollView(
                            padding: EdgeInsets.all(context.isMobile ? 16 : 20),
                            child: Column(
                              children: [
                                // Estadísticas rápidas
                                _buildTabsStats(context),
                                SizedBox(height: context.verticalSpacing),
                                // Lista de pestañas
                                ...tabsController.tabs.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final tab = entry.value;
                                  return _buildTabCard(context, tab, index);
                                }).toList(),
                              ],
                            ),
                          ),
                ),
              ),
              // Footer con acciones
              Container(
                padding: EdgeInsets.all(context.isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    // Botón para nueva pestaña
                    Obx(
                      () => ElevatedButton.icon(
                        onPressed:
                            tabsController.canAddMoreTabs
                                ? () {
                                  tabsController.addNewTab();
                                  Get.back();
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: context.isMobile ? 12 : 16,
                            vertical: context.isMobile ? 8 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          'Nueva',
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(
                              context,
                              mobile: 12,
                              tablet: 13,
                              desktop: 14,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Botón cerrar
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.isMobile ? 16 : 20,
                          vertical: context.isMobile ? 8 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cerrar',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 15,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTabsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 32 : 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tab_unselected,
              size: context.isMobile ? 64 : 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay pestañas abiertas',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una nueva pestaña para comenzar',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabsStats(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            color: Colors.blue.shade600,
            size: context.isMobile ? 20 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 Estadísticas Rápidas',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 13,
                      tablet: 14,
                      desktop: 15,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    'Pestañas con productos: ${tabsController.tabs.where((tab) => tab.controller.invoiceItems.isNotEmpty).length} | '
                    'Facturas nuevas: ${tabsController.tabs.where((tab) => tab.isNewInvoice).length}',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 11,
                        tablet: 12,
                        desktop: 13,
                      ),
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabCard(BuildContext context, InvoiceTab tab, int index) {
    final isActive = index == tabsController.currentTabIndex;
    final hasUnsavedChanges = tab.controller.invoiceItems.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.indigo.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.indigo.shade300 : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? 12 : 16,
          vertical: context.isMobile ? 4 : 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.indigo.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isActive
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: isActive ? Colors.indigo.shade600 : Colors.grey.shade500,
            size: context.isMobile ? 20 : 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                tab.title,
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color:
                      isActive ? Colors.indigo.shade800 : Colors.grey.shade800,
                ),
              ),
            ),
            if (hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Sin guardar',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.inventory_2, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${tab.controller.invoiceItems.length} productos',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 11,
                    tablet: 12,
                    desktop: 13,
                  ),
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                tab.isNewInvoice ? Icons.add_circle : Icons.edit,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                tab.isNewInvoice ? 'Nueva factura' : 'Editando',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 11,
                    tablet: 12,
                    desktop: 13,
                  ),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        trailing:
            hasUnsavedChanges
                ? Icon(Icons.circle, color: Colors.orange.shade600, size: 12)
                : null,
        onTap: () {
          tabsController.switchToTab(index);
          Get.back();
        },
      ),
    );
  }
}

// Clase helper para los atajos de teclado
class _ShortcutItem {
  final String keys;
  final String description;
  final IconData icon;

  const _ShortcutItem(this.keys, this.description, this.icon);
}

// Clase helper para la información del sistema
class _InfoItem {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);
}
