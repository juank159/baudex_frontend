// lib/features/invoices/presentation/screens/printer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../controllers/thermal_printer_controller.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.elasticCurve,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MainLayout(
          title: _getResponsiveTitle(context),
          showBackButton: true,
          showDrawer: false,
          body: Container(
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
            child: GetBuilder<ThermalPrinterController>(
              builder: (controller) {
                return ResponsiveLayout(
                  mobile: _buildMobileLayout(context, controller),
                  tablet: _buildTabletLayout(context, controller),
                  desktop: _buildDesktopLayout(context, controller),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _getResponsiveTitle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return 'Impresoras';
    } else if (screenWidth < 800) {
      return 'Config. Impresoras';
    } else {
      return 'Configuración de Impresoras';
    }
  }

  // Layout para móviles
  Widget _buildMobileLayout(
    BuildContext context,
    ThermalPrinterController controller,
  ) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConnectionSection(context, controller),
          SizedBox(height: context.verticalSpacing),
          _buildDiscoverySection(context, controller),
          SizedBox(height: context.verticalSpacing),
          _buildSettingsSection(context, controller),
          SizedBox(height: context.verticalSpacing),
          _buildTestSection(context, controller),
        ],
      ),
    );
  }

  // Layout para tablets
  Widget _buildTabletLayout(
    BuildContext context,
    ThermalPrinterController controller,
  ) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildConnectionSection(context, controller)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildTestSection(context, controller)),
                ],
              ),
              SizedBox(height: context.verticalSpacing),
              _buildDiscoverySection(context, controller),
              SizedBox(height: context.verticalSpacing),
              _buildSettingsSection(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  // Layout para desktop
  Widget _buildDesktopLayout(
    BuildContext context,
    ThermalPrinterController controller,
  ) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildConnectionSection(context, controller),
                        SizedBox(height: context.verticalSpacing),
                        _buildTestSection(context, controller),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildDiscoverySection(context, controller),
                        SizedBox(height: context.verticalSpacing),
                        _buildSettingsSection(context, controller),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionSection(
    BuildContext context,
    ThermalPrinterController controller,
  ) {
    return FuturisticContainer(
      hasGlow: true,
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: Icon(
                    Icons.print,
                    color: Colors.white,
                    size: context.isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Estado de Conexión',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),

            // Estado actual
            Container(
              padding: EdgeInsets.all(context.isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color:
                    controller.isConnected
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                border: Border.all(
                  color:
                      controller.isConnected
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.isConnected ? Icons.check_circle : Icons.error,
                    color:
                        controller.isConnected
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                    size: context.isMobile ? 20 : 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.isConnected
                              ? 'Impresora Conectada'
                              : 'Sin Conexión',
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(
                              context,
                              mobile: 14,
                              tablet: 15,
                              desktop: 16,
                            ),
                            fontWeight: FontWeight.w600,
                            color:
                                controller.isConnected
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                          ),
                        ),
                        if (controller.selectedPrinter != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${controller.selectedPrinter!.ip}:${controller.selectedPrinter!.port}',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 11,
                                tablet: 12,
                                desktop: 13,
                              ),
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (!controller.isConnected &&
                controller.selectedPrinter != null) ...[
              SizedBox(height: context.verticalSpacing),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ElegantLightTheme.elevatedShadow,
                ),
                child: ElevatedButton.icon(
                  onPressed:
                      () => controller.connectToPrinter(
                        controller.selectedPrinter!,
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      vertical: context.isMobile ? 12 : 16,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.link),
                  label: Text(
                    'Reconectar',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverySection(
    BuildContext context,
    ThermalPrinterController controller,
  ) {
    return FuturisticContainer(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.warningGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: Icon(
                    Icons.search,
                    color: Colors.white,
                    size: context.isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Buscar Impresoras',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.elevatedShadow,
                  ),
                  child: IconButton(
                    onPressed: controller.refreshPrinters,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Actualizar',
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),

            // Lista de impresoras descubiertas
            if (controller.discoveredPrinters.isEmpty)
              Container(
                padding: EdgeInsets.all(context.isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.blue.shade600,
                      size: context.isMobile ? 20 : 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No se encontraron impresoras. Presiona "Actualizar" para buscar nuevamente.',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 13,
                            tablet: 14,
                            desktop: 15,
                          ),
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children:
                    controller.discoveredPrinters.map((printer) {
                      final isSelected =
                          controller.selectedPrinter?.ip == printer.ip;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
                                  : Colors.white,
                          border: Border.all(
                            color:
                                isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.isMobile ? 12 : 16,
                            vertical: context.isMobile ? 4 : 8,
                          ),
                          leading: Icon(
                            Icons.print,
                            color:
                                isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade600,
                            size: context.isMobile ? 20 : 24,
                          ),
                          title: Text(
                            printer.name,
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 14,
                                tablet: 15,
                                desktop: 16,
                              ),
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade800,
                            ),
                          ),
                          subtitle: Text(
                            '${printer.ip}:${printer.port}',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing:
                              isSelected
                                  ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).primaryColor,
                                  )
                                  : null,
                          onTap: () => controller.selectPrinter(printer),
                        ),
                      );
                    }).toList(),
              ),

            SizedBox(height: context.verticalSpacing),

            // Botón para agregar manualmente
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantLightTheme.primaryBlue,
                  width: 2,
                ),
                gradient: ElegantLightTheme.glassGradient,
              ),
              child: OutlinedButton.icon(
                onPressed: () => _showManualPrinterDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ElegantLightTheme.primaryBlue,
                  side: BorderSide.none,
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    vertical: context.isMobile ? 12 : 16,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(
                  'Agregar Impresora Manualmente',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    ThermalPrinterController controller,
  ) {
    return FuturisticContainer(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: context.isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Configuraciones de Impresión',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),

            // Ancho del papel
            Container(
              padding: EdgeInsets.all(context.isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ancho del papel:',
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  DropdownButton<int>(
                    value: controller.paperWidth,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(
                        context,
                        mobile: 14,
                        tablet: 15,
                        desktop: 16,
                      ),
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 58, child: Text('58mm')),
                      DropdownMenuItem(value: 80, child: Text('80mm')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.setPaperWidth(value);
                      }
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: context.verticalSpacing),

            // Corte automático
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SwitchListTile(
                title: Text(
                  'Corte automático',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  'Cortar papel automáticamente después de imprimir',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                    color: Colors.grey.shade600,
                  ),
                ),
                value: controller.autoCut,
                activeColor: Theme.of(context).primaryColor,
                onChanged: controller.setAutoCut,
              ),
            ),

            const SizedBox(height: 8),

            // Abrir caja registradora
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SwitchListTile(
                title: Text(
                  'Abrir caja registradora',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                subtitle: Text(
                  'Activar señal para abrir caja registradora',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                    color: Colors.grey.shade600,
                  ),
                ),
                value: controller.openCashDrawer,
                activeColor: Theme.of(context).primaryColor,
                onChanged: controller.setOpenCashDrawer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(
    BuildContext context,
    ThermalPrinterController controller,
  ) {
    return FuturisticContainer(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: Icon(
                    Icons.bug_report,
                    color: Colors.white,
                    size: context.isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pruebas',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),

            // Botón de prueba
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient:
                    controller.selectedPrinter != null
                        ? ElegantLightTheme.successGradient
                        : LinearGradient(
                          colors: [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                borderRadius: BorderRadius.circular(12),
                boxShadow:
                    controller.selectedPrinter != null
                        ? ElegantLightTheme.elevatedShadow
                        : null,
              ),
              child: ElevatedButton.icon(
                onPressed:
                    controller.selectedPrinter != null
                        ? () => controller.printTestReceipt()
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    vertical: context.isMobile ? 12 : 16,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.print),
                label: Text(
                  'Imprimir Recibo de Prueba',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: context.verticalSpacing * 0.5),

            if (controller.selectedPrinter == null)
              Container(
                padding: EdgeInsets.all(context.isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.orange.shade600,
                      size: context.isMobile ? 16 : 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selecciona una impresora para realizar pruebas',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 12,
                            tablet: 13,
                            desktop: 14,
                          ),
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showManualPrinterDialog(BuildContext context) {
    final ipController = TextEditingController();
    final portController = TextEditingController(text: '9100');
    final nameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: ElegantLightTheme.backgroundColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Agregar Impresora Manualmente',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                  desktop: 20,
                ),
                fontWeight: FontWeight.bold,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                color: Colors.grey.shade800,
              ),
              decoration: InputDecoration(
                labelText: 'Nombre de la impresora',
                hintText: 'Mi Impresora Térmica',
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 13,
                    tablet: 14,
                    desktop: 15,
                  ),
                ),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 13,
                    tablet: 14,
                    desktop: 15,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            SizedBox(height: context.verticalSpacing),
            TextField(
              controller: ipController,
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                color: Colors.grey.shade800,
              ),
              decoration: InputDecoration(
                labelText: 'Dirección IP',
                hintText: '192.168.1.100',
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 13,
                    tablet: 14,
                    desktop: 15,
                  ),
                ),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 13,
                    tablet: 14,
                    desktop: 15,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: context.verticalSpacing),
            TextField(
              controller: portController,
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                color: Colors.grey.shade800,
              ),
              decoration: InputDecoration(
                labelText: 'Puerto',
                hintText: '9100',
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 13,
                    tablet: 14,
                    desktop: 15,
                  ),
                ),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 13,
                    tablet: 14,
                    desktop: 15,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: ElegantLightTheme.textSecondary,
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final ip = ipController.text.trim();
                final port = int.tryParse(portController.text) ?? 9100;

                if (name.isNotEmpty && ip.isNotEmpty) {
                  Get.back();
                  final controller = Get.find<ThermalPrinterController>();
                  controller.addManualPrinter(name, ip, port);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Agregar',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
