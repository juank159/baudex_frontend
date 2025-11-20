//lib/features/settings/presentation/screens/user_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/user_preferences_controller.dart';
import '../controllers/organization_controller.dart';
import '../bindings/settings_binding.dart';

class UserPreferencesScreen extends StatelessWidget {
  const UserPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserPreferencesController>();
    
    // Ensure OrganizationController is initialized and refreshed
    _initializeOrganizationController();
    _refreshOrganizationData();

    return Obx(
      () => controller.isLoading
          ? _buildLoadingState()
          : MainLayout(
              title: 'Preferencias de Usuario',
              showBackButton: true,
              showDrawer: false,
              actions: _buildAppBarActions(context),
              body: _buildFuturisticContent(context),
            ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => Get.find<UserPreferencesController>().loadUserPreferences(),
        tooltip: 'Actualizar',
      ),
      const SizedBox(width: 16),
    ];
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(
                Icons.settings,
                color: ElegantLightTheme.textPrimary,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cargando preferencias...',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Configurando tu experiencia personal',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header futurístico
            _buildFuturisticHeader(),
            const SizedBox(height: 24),

            // Tabs futuristas
            _buildFuturisticTabs(),
            const SizedBox(height: 24),

            // Contenido del tab seleccionado
            Obx(() => _buildFuturisticTabContent()),

            // Espacio adicional al final
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticHeader() {
    return FuturisticContainer(
      hasGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        bool isMobile = screenWidth < 600;
                        
                        return Text(
                          isMobile ? 'Configuración' : 'Centro de Configuración',
                          style: TextStyle(
                            color: ElegantLightTheme.textPrimary,
                            fontSize: isMobile ? 18 : 24,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        bool isMobile = screenWidth < 600;
                        
                        return Text(
                          isMobile ? 'Personaliza Baudex' : 'Personaliza tu experiencia en Baudex',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: isMobile ? 13 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Métricas de configuración
          _buildConfigMetrics(),
        ],
      ),
    );
  }

  Widget _buildConfigMetrics() {
    final controller = Get.find<UserPreferencesController>();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount = screenWidth >= 1200 ? 4 : screenWidth >= 800 ? 2 : 2;
        // Aspecto ratio MUY compacto: reducido significativamente en TODAS las vistas
        double childAspectRatio = screenWidth >= 1200 ? 2.8 : screenWidth >= 800 ? 3.2 : 2.5;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildMetricCard(
              'Inventario',
              '${_getActiveSettingsCount(controller, 'inventory')}',
              Icons.inventory_2,
              ElegantLightTheme.infoGradient.colors.first,
              screenWidth,
            ),
            _buildMetricCard(
              'Interfaz',
              '${_getActiveSettingsCount(controller, 'interface')}',
              Icons.dashboard,
              ElegantLightTheme.warningGradient.colors.first,
              screenWidth,
            ),
            _buildMetricCard(
              'Notificaciones',
              '${_getActiveSettingsCount(controller, 'notifications')}',
              Icons.notifications,
              ElegantLightTheme.successGradient.colors.first,
              screenWidth,
            ),
            _buildMetricCard(
              'Financiero',
              '1',
              Icons.attach_money,
              ElegantLightTheme.primaryBlue,
              screenWidth,
            ),
          ],
        );
      },
    );
  }

  int _getActiveSettingsCount(UserPreferencesController controller, String category) {
    switch (category) {
      case 'inventory':
        return [
          controller.autoDeductInventory,
          controller.useFifoCosting,
          controller.validateStockBeforeInvoice,
          controller.allowOverselling,
          controller.showStockWarnings,
        ].where((setting) => setting).length;
      case 'interface':
        return [
          controller.showConfirmationDialogs,
          controller.useCompactMode,
        ].where((setting) => setting).length;
      case 'notifications':
        return [
          controller.enableExpiryNotifications,
          controller.enableLowStockNotifications,
        ].where((setting) => setting).length;
      default:
        return 0;
    }
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double screenWidth,
  ) {
    double iconSize = screenWidth >= 1200 ? 24 : screenWidth >= 800 ? 20 : 18;
    double valueFontSize = screenWidth >= 1200 ? 16 : screenWidth >= 800 ? 14 : 12;
    double labelFontSize = screenWidth >= 1200 ? 10 : screenWidth >= 800 ? 9 : 8;
    double spacing = screenWidth >= 1200 ? 8 : screenWidth >= 800 ? 6 : 4;

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(height: spacing),
          Text(
            value,
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: valueFontSize,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing / 2),
          Text(
            label,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: labelFontSize,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticTabs() {
    return Obx(
      () => FuturisticContainer(
        child: Column(
          children: [
            Row(
              children: [
                _buildTabHeader('Inventario', 0, Icons.inventory_2),
                _buildTabHeader('Interfaz', 1, Icons.dashboard),
                _buildTabHeader('Notificaciones', 2, Icons.notifications),
                _buildTabHeader('Financiero', 3, Icons.attach_money),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabHeader(String title, int index, IconData icon) {
    final controller = Get.find<UserPreferencesController>();
    final isSelected = controller.selectedTab.value == index;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          bool isMobile = screenWidth < 600;
          
          // Responsive sizing para móviles
          double iconSize = isMobile ? 16 : 20;
          double fontSize = isMobile ? 9 : 12;
          double verticalPadding = isMobile ? 8 : 12;
          double spacing = isMobile ? 2 : 4;
          
          // Textos más cortos para móviles
          String displayTitle;
          switch (title) {
            case 'Inventario':
              displayTitle = isMobile ? 'Stock' : 'Inventario';
              break;
            case 'Interfaz':
              displayTitle = isMobile ? 'UI' : 'Interfaz';
              break;
            case 'Notificaciones':
              displayTitle = isMobile ? 'Avisos' : 'Notificaciones';
              break;
            case 'Financiero':
              displayTitle = isMobile ? 'Money' : 'Financiero';
              break;
            default:
              displayTitle = title;
          }
          
          return GestureDetector(
            onTap: () => controller.switchTab(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                    size: iconSize,
                  ),
                  SizedBox(height: spacing),
                  Text(
                    displayTitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                      fontSize: fontSize,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFuturisticTabContent() {
    final controller = Get.find<UserPreferencesController>();
    
    switch (controller.selectedTab.value) {
      case 0:
        return _buildInventoryTab();
      case 1:
        return _buildInterfaceTab();
      case 2:
        return _buildNotificationsTab();
      case 3:
        return _buildFinancialTab();
      default:
        return _buildInventoryTab();
    }
  }

  Widget _buildInventoryTab() {
    final controller = Get.find<UserPreferencesController>();
    
    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuraciones de Inventario',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _buildFuturisticSwitchTile(
            title: 'Descuento automático de inventario',
            subtitle: 'Descuenta el stock automáticamente al crear facturas',
            icon: Icons.remove_circle_outline,
            value: controller.autoDeductInventory,
            onChanged: () => controller.toggleAutoDeductInventory(),
            color: ElegantLightTheme.infoGradient.colors.first,
          ),
          _buildFuturisticSwitchTile(
            title: 'Usar costos FIFO',
            subtitle: 'Calcular costos usando First In, First Out',
            icon: Icons.timeline_outlined,
            value: controller.useFifoCosting,
            onChanged: () => controller.toggleUseFifoCosting(),
            color: ElegantLightTheme.warningGradient.colors.first,
          ),
          _buildFuturisticSwitchTile(
            title: 'Validar stock antes de facturar',
            subtitle: 'Verificar disponibilidad antes de crear facturas',
            icon: Icons.verified_outlined,
            value: controller.validateStockBeforeInvoice,
            onChanged: () => controller.toggleValidateStockBeforeInvoice(),
            color: ElegantLightTheme.successGradient.colors.first,
          ),
          _buildFuturisticSwitchTile(
            title: 'Permitir sobreventa',
            subtitle: 'Permitir ventas con stock negativo',
            icon: Icons.warning_outlined,
            value: controller.allowOverselling,
            onChanged: () => controller.toggleAllowOverselling(),
            color: ElegantLightTheme.errorGradient.colors.first,
          ),
          _buildFuturisticSwitchTile(
            title: 'Mostrar alertas de stock',
            subtitle: 'Alertas cuando el stock esté bajo',
            icon: Icons.notification_important_outlined,
            value: controller.showStockWarnings,
            onChanged: () => controller.toggleShowStockWarnings(),
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceTab() {
    final controller = Get.find<UserPreferencesController>();
    
    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuraciones de Interfaz',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _buildFuturisticSwitchTile(
            title: 'Mostrar confirmaciones',
            subtitle: 'Confirmar acciones críticas antes de ejecutar',
            icon: Icons.help_outline,
            value: controller.showConfirmationDialogs,
            onChanged: () => controller.toggleShowConfirmationDialogs(),
            color: ElegantLightTheme.infoGradient.colors.first,
          ),
          _buildFuturisticSwitchTile(
            title: 'Modo compacto',
            subtitle: 'Usar vistas compactas en listas',
            icon: Icons.compress_outlined,
            value: controller.useCompactMode,
            onChanged: () => controller.toggleUseCompactMode(),
            color: ElegantLightTheme.warningGradient.colors.first,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    final controller = Get.find<UserPreferencesController>();
    
    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuraciones de Notificaciones',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _buildFuturisticSwitchTile(
            title: 'Notificaciones de vencimiento',
            subtitle: 'Alertas sobre productos próximos a vencer',
            icon: Icons.schedule_outlined,
            value: controller.enableExpiryNotifications,
            onChanged: () => controller.toggleEnableExpiryNotifications(),
            color: ElegantLightTheme.warningGradient.colors.first,
          ),
          _buildFuturisticSwitchTile(
            title: 'Notificaciones de stock bajo',
            subtitle: 'Alertas cuando el stock esté por agotarse',
            icon: Icons.inventory_outlined,
            value: controller.enableLowStockNotifications,
            onChanged: () => controller.toggleEnableLowStockNotifications(),
            color: ElegantLightTheme.errorGradient.colors.first,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuraciones Financieras',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _buildFuturisticProfitMarginSlider(),
        ],
      ),
    );
  }

  Widget _buildFuturisticSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required VoidCallback onChanged,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Responsive sizing
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        double cardPadding = isMobile ? 12 : isTablet ? 14 : 16;
        double iconContainerPadding = isMobile ? 8 : isTablet ? 10 : 12;
        double iconSize = isMobile ? 18 : isTablet ? 20 : 22;
        double titleFontSize = isMobile ? 14 : isTablet ? 15 : 16;
        double subtitleFontSize = isMobile ? 12 : isTablet ? 13 : 14;
        double horizontalSpacing = isMobile ? 12 : isTablet ? 14 : 16;
        double verticalSpacing = isMobile ? 2 : isTablet ? 3 : 4;
        double marginBottom = isMobile ? 12 : isTablet ? 14 : 16;
        
        return Container(
          margin: EdgeInsets.only(bottom: marginBottom),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(isMobile ? 10 : isTablet ? 11 : 12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconContainerPadding),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 8 : isTablet ? 9 : 10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              ),
              SizedBox(width: horizontalSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: verticalSpacing),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: subtitleFontSize,
                        height: isMobile ? 1.3 : 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: horizontalSpacing),
              _buildFuturisticSwitch(
                value: value, 
                onChanged: onChanged, 
                color: color, 
                isMobile: isMobile,
                isTablet: isTablet
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticSwitch({
    required bool value,
    required VoidCallback onChanged,
    required Color color,
    bool isMobile = false,
    bool isTablet = false,
  }) {
    // Responsive sizing for switch
    double switchWidth = isMobile ? 44 : isTablet ? 48 : 52;
    double switchHeight = isMobile ? 24 : isTablet ? 26 : 28;
    double thumbSize = isMobile ? 20 : isTablet ? 22 : 24;
    double margin = isMobile ? 1.5 : 2;
    double iconSize = isMobile ? 12 : isTablet ? 14 : 16;
    double blurRadius = isMobile ? 6 : isTablet ? 7 : 8;
    
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: switchWidth,
        height: switchHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(switchHeight / 2),
          gradient: value
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
              : LinearGradient(
                  colors: [
                    ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                    ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
                  ],
                ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: blurRadius,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            margin: EdgeInsets.all(margin),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(thumbSize / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: value
                ? Icon(
                    Icons.check,
                    color: color,
                    size: iconSize,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticProfitMarginSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Responsive sizing
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        double containerPadding = isMobile ? 14 : isTablet ? 17 : 20;
        double iconContainerPadding = isMobile ? 8 : isTablet ? 10 : 12;
        double iconSize = isMobile ? 18 : isTablet ? 20 : 24;
        double titleFontSize = isMobile ? 15 : isTablet ? 16 : 18;
        double subtitleFontSize = isMobile ? 12 : isTablet ? 13 : 14;
        double percentageFontSize = isMobile ? 14 : isTablet ? 16 : 18;
        double labelFontSize = isMobile ? 10 : isTablet ? 11 : 12;
        double exampleFontSize = isMobile ? 10 : isTablet ? 11 : 12;
        double horizontalSpacing = isMobile ? 12 : isTablet ? 14 : 16;
        double verticalSpacing = isMobile ? 4 : isTablet ? 6 : 8;
        double trackHeight = isMobile ? 4 : isTablet ? 5 : 6;
        double thumbRadius = isMobile ? 8 : isTablet ? 10 : 12;
        double overlayRadius = isMobile ? 14 : isTablet ? 17 : 20;
        
        return Obx(() {
          final orgController = Get.find<OrganizationController>();
          
          return Container(
            padding: EdgeInsets.all(containerPadding),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient,
              borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 14 : 16),
              border: Border.all(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconContainerPadding),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(isMobile ? 8 : isTablet ? 9 : 10),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: horizontalSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Margen de Ganancia',
                            style: TextStyle(
                              color: ElegantLightTheme.textPrimary,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: verticalSpacing / 2),
                          Text(
                            'Para productos temporales',
                            style: TextStyle(
                              color: ElegantLightTheme.textSecondary,
                              fontSize: subtitleFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : isTablet ? 14 : 16, 
                        vertical: isMobile ? 6 : isTablet ? 7 : 8
                      ),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(isMobile ? 16 : isTablet ? 18 : 20),
                        boxShadow: ElegantLightTheme.glowShadow,
                      ),
                      child: Text(
                        '${orgController.tempProfitMargin.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: percentageFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 18 : isTablet ? 21 : 24),
                SliderTheme(
                  data: SliderTheme.of(Get.context!).copyWith(
                    trackHeight: trackHeight,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
                    activeTrackColor: ElegantLightTheme.primaryBlue,
                    inactiveTrackColor: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
                    thumbColor: ElegantLightTheme.primaryBlue,
                    overlayColor: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: orgController.tempProfitMargin,
                    min: 5.0,
                    max: 50.0,
                    divisions: 45,
                    onChanged: (value) => orgController.updateTempProfitMargin(value),
                    onChangeEnd: (value) => orgController.saveProfitMargin(),
                  ),
                ),
                SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '5% Mínimo',
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '50% Máximo',
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : isTablet ? 14 : 16),
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : isTablet ? 11 : 12),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(isMobile ? 6 : isTablet ? 7 : 8),
                    border: Border.all(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: ElegantLightTheme.primaryBlue,
                        size: isMobile ? 16 : isTablet ? 18 : 20,
                      ),
                      SizedBox(width: isMobile ? 6 : isTablet ? 7 : 8),
                      Expanded(
                        child: Text(
                          isMobile 
                            ? 'Ej: \$1,800 → Costo: \$${(1800 * (1 - orgController.tempProfitMargin / 100)).toStringAsFixed(0)}, Ganancia: \$${(1800 * orgController.tempProfitMargin / 100).toStringAsFixed(0)}'
                            : 'Ejemplo: Producto de \$1,800 → Costo: \$${(1800 * (1 - orgController.tempProfitMargin / 100)).toStringAsFixed(0)}, Ganancia: \$${(1800 * orgController.tempProfitMargin / 100).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: ElegantLightTheme.primaryBlue,
                            fontSize: exampleFontSize,
                            fontWeight: FontWeight.w500,
                            height: isMobile ? 1.3 : 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  /// Ensure OrganizationController is available
  void _initializeOrganizationController() {
    try {
      if (!Get.isRegistered<OrganizationController>()) {
        debugPrint('🏢 OrganizationController not found, attempting to register...');
        final settingsBinding = SettingsBinding();
        settingsBinding.dependencies();
      }
    } catch (e) {
      debugPrint('⚠️ Error initializing OrganizationController: $e');
    }
  }

  /// Refresh organization data when screen loads
  void _refreshOrganizationData() {
    try {
      if (Get.isRegistered<OrganizationController>()) {
        final orgController = Get.find<OrganizationController>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          orgController.refresh();
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error refreshing organization data: $e');
    }
  }
}