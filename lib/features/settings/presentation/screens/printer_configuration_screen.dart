// lib/features/settings/presentation/screens/printer_configuration_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/settings_controller.dart';
import '../bindings/settings_binding.dart';
import '../../domain/entities/printer_settings.dart';

class PrinterConfigurationScreen extends StatefulWidget {
  const PrinterConfigurationScreen({super.key});

  @override
  State<PrinterConfigurationScreen> createState() => _PrinterConfigurationScreenState();
}

class _PrinterConfigurationScreenState extends State<PrinterConfigurationScreen>
    with TickerProviderStateMixin {
  late SettingsController settingsController;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '9100');
  final TextEditingController _usbPathController = TextEditingController();
  
  // Form state
  PrinterConnectionType _connectionType = PrinterConnectionType.network;
  PaperSize _paperSize = PaperSize.mm80;
  bool _autoCut = true;
  bool _cashDrawer = false;
  bool _isDefault = false;
  
  PrinterSettings? _editingPrinter;
  bool _isEditMode = false;

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
      CurvedAnimation(parent: _animationController, curve: ElegantLightTheme.elasticCurve),
    );
    _animationController.forward();
    _initializeController();
  }

  Future<void> _initializeController() async {
    // Asegurar que las dependencias estén registradas
    if (!Get.isRegistered<SettingsController>()) {
      SettingsBinding().dependencies();
    }
    
    settingsController = Get.find<SettingsController>();
    
    // Cargar configuraciones si no están cargadas
    if (settingsController.printerSettings.isEmpty) {
      await settingsController.loadPrinterSettings();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _usbPathController.dispose();
    super.dispose();
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
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: ElegantLightTheme.elevatedShadow,
              ),
              child: IconButton(
                onPressed: _clearForm,
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Agregar nueva impresora',
              ),
            ),
          ],
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
            child: Obx(() {
              if (settingsController.isLoadingPrinterSettings) {
                return const Center(child: LoadingWidget());
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return _buildMobileLayout(context, settingsController);
                  } else if (constraints.maxWidth < 1200) {
                    return _buildTabletLayout(context, settingsController);
                  } else {
                    return _buildDesktopLayout(context, settingsController);
                  }
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, SettingsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPrinterForm(context, controller),
          const SizedBox(height: 24),
          _buildPrintersList(context, controller),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, SettingsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPrinterForm(context, controller),
          const SizedBox(height: 32),
          _buildPrintersList(context, controller),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, SettingsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adaptar padding y layout según el ancho disponible
        final isLargeDesktop = constraints.maxWidth > 1400;
        final padding = isLargeDesktop ? 32.0 : 16.0;
        final spacing = isLargeDesktop ? 32.0 : 16.0;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Formulario - Se adapta al tamaño de pantalla
              Expanded(
                flex: isLargeDesktop ? 2 : 1,
                child: _buildPrinterForm(context, controller),
              ),
              SizedBox(width: spacing),
              // Lista de impresoras - Se adapta al tamaño de pantalla
              Expanded(
                flex: isLargeDesktop ? 3 : 1,
                child: _buildPrintersList(context, controller),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrinterForm(BuildContext context, SettingsController controller) {
    return FuturisticContainer(
      hasGlow: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(Icons.print, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _isEditMode ? 'Editar Impresora' : 'Agregar Nueva Impresora',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Nombre de la impresora
            CustomTextField(
              controller: _nameController,
              label: 'Nombre de la Impresora',
              hint: 'Ej: Impresora Principal',
              prefixIcon: Icons.label,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Tipo de conexión
            Text(
              'Tipo de Conexión',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                // En pantallas muy pequeñas, usar layout vertical
                if (constraints.maxWidth < 500) {
                  return Column(
                    children: [
                      RadioListTile<PrinterConnectionType>(
                        title: const Text('Red (IP)'),
                        subtitle: const Text('Ethernet/WiFi'),
                        value: PrinterConnectionType.network,
                        groupValue: _connectionType,
                        onChanged: (value) {
                          setState(() {
                            _connectionType = value!;
                          });
                        },
                      ),
                      RadioListTile<PrinterConnectionType>(
                        title: const Text('USB'),
                        subtitle: const Text('Puerto USB'),
                        value: PrinterConnectionType.usb,
                        groupValue: _connectionType,
                        onChanged: (value) {
                          setState(() {
                            _connectionType = value!;
                          });
                        },
                      ),
                    ],
                  );
                } else {
                  // Layout horizontal para pantallas más grandes
                  return Row(
                    children: [
                      Expanded(
                        child: RadioListTile<PrinterConnectionType>(
                          title: const Text('Red (IP)'),
                          subtitle: const Text('Ethernet/WiFi'),
                          value: PrinterConnectionType.network,
                          groupValue: _connectionType,
                          onChanged: (value) {
                            setState(() {
                              _connectionType = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<PrinterConnectionType>(
                          title: const Text('USB'),
                          subtitle: const Text('Puerto USB'),
                          value: PrinterConnectionType.usb,
                          groupValue: _connectionType,
                          onChanged: (value) {
                            setState(() {
                              _connectionType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Configuración específica por tipo
            if (_connectionType == PrinterConnectionType.network) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  // En pantallas muy pequeñas, usar layout vertical
                  if (constraints.maxWidth < 500) {
                    return Column(
                      children: [
                        CustomTextField(
                          controller: _ipController,
                          label: 'Dirección IP',
                          hint: '192.168.1.100',
                          prefixIcon: Icons.router,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La dirección IP es requerida';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _portController,
                          label: 'Puerto',
                          hint: '9100',
                          prefixIcon: Icons.settings_ethernet,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    );
                  } else {
                    // Layout horizontal para pantallas más grandes
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CustomTextField(
                            controller: _ipController,
                            label: 'Dirección IP',
                            hint: '192.168.1.100',
                            prefixIcon: Icons.router,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La dirección IP es requerida';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: CustomTextField(
                            controller: _portController,
                            label: 'Puerto',
                            hint: '9100',
                            prefixIcon: Icons.settings_ethernet,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ] else ...[
              CustomTextField(
                controller: _usbPathController,
                label: 'Ruta USB',
                hint: '/dev/usb/lp0 o COM1',
                prefixIcon: Icons.usb,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La ruta USB es requerida';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            
            // Configuraciones adicionales
            Text(
              'Configuraciones Adicionales',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tamaño de papel
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tamaño de Papel'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<PaperSize>(
                        value: _paperSize,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt),
                        ),
                        items: PaperSize.values.map((size) {
                          return DropdownMenuItem(
                            value: size,
                            child: Text(size == PaperSize.mm58 ? '58mm' : '80mm'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _paperSize = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Switches futurísticos
            _buildFuturisticSwitchTile(
              title: 'Corte Automático',
              subtitle: 'Cortar papel automáticamente después de imprimir',
              value: _autoCut,
              onChanged: (value) {
                setState(() {
                  _autoCut = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildFuturisticSwitchTile(
              title: 'Apertura de Caja',
              subtitle: 'Abrir caja registradora al imprimir',
              value: _cashDrawer,
              onChanged: (value) {
                setState(() {
                  _cashDrawer = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildFuturisticSwitchTile(
              title: 'Impresora por Defecto',
              subtitle: 'Usar como impresora principal',
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Botones de acción - Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                // Si el espacio es muy limitado, usar layout vertical
                if (constraints.maxWidth < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isEditMode) ...[
                        _buildFuturisticButton(
                          text: 'Cancelar',
                          icon: Icons.cancel,
                          onPressed: _clearForm,
                          gradient: ElegantLightTheme.warningGradient,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildFuturisticButton(
                        text: 'Probar Conexión',
                        icon: Icons.wifi_find,
                        onPressed: controller.isTestingConnection 
                            ? null 
                            : () => _testConnection(controller),
                        gradient: ElegantLightTheme.infoGradient,
                        isLoading: controller.isTestingConnection,
                      ),
                      const SizedBox(height: 12),
                      _buildFuturisticButton(
                        text: 'Página de Prueba',
                        icon: Icons.print_outlined,
                        onPressed: controller.isTestingConnection 
                            ? null 
                            : () => _printTestPage(controller),
                        gradient: ElegantLightTheme.successGradient,
                        isLoading: controller.isTestingConnection,
                      ),
                      const SizedBox(height: 12),
                      _buildFuturisticButton(
                        text: _isEditMode ? 'Actualizar' : 'Agregar',
                        icon: _isEditMode ? Icons.update : Icons.add,
                        onPressed: controller.isSaving 
                            ? null 
                            : () => _savePrinter(controller),
                        gradient: ElegantLightTheme.primaryGradient,
                        isLoading: controller.isSaving,
                      ),
                    ],
                  );
                } else {
                  // Layout horizontal para pantallas más grandes
                  return Row(
                    children: [
                      if (_isEditMode) ...[
                        Expanded(
                          child: _buildFuturisticButton(
                            text: 'Cancelar',
                            icon: Icons.cancel,
                            onPressed: _clearForm,
                            gradient: ElegantLightTheme.warningGradient,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: _buildFuturisticButton(
                          text: 'Probar Conexión',
                          icon: Icons.wifi_find,
                          onPressed: controller.isTestingConnection 
                              ? null 
                              : () => _testConnection(controller),
                          gradient: ElegantLightTheme.infoGradient,
                          isLoading: controller.isTestingConnection,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFuturisticButton(
                          text: 'Página de Prueba',
                          icon: Icons.print_outlined,
                          onPressed: controller.isTestingConnection 
                              ? null 
                              : () => _printTestPage(controller),
                          gradient: ElegantLightTheme.successGradient,
                          isLoading: controller.isTestingConnection,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildFuturisticButton(
                          text: _isEditMode ? 'Actualizar' : 'Agregar',
                          icon: _isEditMode ? Icons.update : Icons.add,
                          onPressed: controller.isSaving 
                              ? null 
                              : () => _savePrinter(controller),
                          gradient: ElegantLightTheme.primaryGradient,
                          isLoading: controller.isSaving,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintersList(BuildContext context, SettingsController controller) {
    return FuturisticContainer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(Icons.list, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Impresoras Configuradas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.elevatedShadow,
                  ),
                  child: IconButton(
                    onPressed: () => controller.loadPrinterSettings(),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Actualizar lista',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (controller.printerSettings.isEmpty) ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.print_disabled,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay impresoras configuradas',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agrega tu primera impresora usando el formulario',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.printerSettings.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final printer = controller.printerSettings[index];
                  return _buildPrinterCard(context, controller, printer);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterCard(BuildContext context, SettingsController controller, PrinterSettings printer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: printer.isDefault 
            ? LinearGradient(
                colors: [
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
                ],
              )
            : ElegantLightTheme.glassGradient,
        border: Border.all(
          color: printer.isDefault 
              ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
              : ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
          width: printer.isDefault ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: printer.isDefault 
            ? ElegantLightTheme.glowShadow
            : ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: printer.isDefault 
                      ? ElegantLightTheme.primaryGradient 
                      : ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.elevatedShadow,
                ),
                child: Icon(
                  printer.isNetworkPrinter ? Icons.router : Icons.usb,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          printer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: ElegantLightTheme.textPrimary,
                          ),
                        ),
                        if (printer.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: ElegantLightTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: ElegantLightTheme.glowShadow,
                            ),
                            child: const Text(
                              'Por Defecto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      printer.connectionInfo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handlePrinterAction(controller, printer, value),
                itemBuilder: (context) => [
                  if (!printer.isDefault)
                    const PopupMenuItem(
                      value: 'setDefault',
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 18),
                          SizedBox(width: 8),
                          Text('Establecer por defecto'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'test',
                    child: Row(
                      children: [
                        Icon(Icons.print, size: 18),
                        SizedBox(width: 8),
                        Text('Probar conexión'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'printTest',
                    child: Row(
                      children: [
                        Icon(Icons.print_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Imprimir página de prueba'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                printer.paperSize == PaperSize.mm58 ? '58mm' : '80mm',
                Icons.receipt,
              ),
              const SizedBox(width: 8),
              if (printer.autoCut)
                _buildInfoChip('Corte Auto', Icons.content_cut),
              if (printer.cashDrawer)
                _buildInfoChip('Caja', Icons.point_of_sale),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
            ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ElegantLightTheme.primaryBlue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: ElegantLightTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _ipController.clear();
      _portController.text = '9100';
      _usbPathController.clear();
      _connectionType = PrinterConnectionType.network;
      _paperSize = PaperSize.mm80;
      _autoCut = true;
      _cashDrawer = false;
      _isDefault = false;
      _editingPrinter = null;
      _isEditMode = false;
    });
  }

  void _editPrinter(PrinterSettings printer) {
    setState(() {
      _editingPrinter = printer;
      _isEditMode = true;
      _nameController.text = printer.name;
      _connectionType = printer.connectionType;
      
      if (printer.isNetworkPrinter) {
        _ipController.text = printer.ipAddress ?? '';
        _portController.text = printer.port?.toString() ?? '9100';
      } else {
        _usbPathController.text = printer.usbPath ?? '';
      }
      
      _paperSize = printer.paperSize;
      _autoCut = printer.autoCut;
      _cashDrawer = printer.cashDrawer;
      _isDefault = printer.isDefault;
    });
  }

  Future<void> _testConnection(SettingsController controller) async {
    if (_nameController.text.isEmpty) {
      Get.snackbar('Error', 'El nombre de la impresora es requerido');
      return;
    }

    if (_connectionType == PrinterConnectionType.network && _ipController.text.isEmpty) {
      Get.snackbar('Error', 'La dirección IP es requerida');
      return;
    }

    if (_connectionType == PrinterConnectionType.usb && _usbPathController.text.isEmpty) {
      Get.snackbar('Error', 'La ruta USB es requerida');
      return;
    }

    final testPrinter = _createPrinterFromForm();
    await controller.testPrinterConnection(testPrinter);
  }

  Future<void> _printTestPage(SettingsController controller) async {
    if (_nameController.text.isEmpty) {
      Get.snackbar('Error', 'El nombre de la impresora es requerido');
      return;
    }

    if (_connectionType == PrinterConnectionType.network && _ipController.text.isEmpty) {
      Get.snackbar('Error', 'La dirección IP es requerida');
      return;
    }

    if (_connectionType == PrinterConnectionType.usb && _usbPathController.text.isEmpty) {
      Get.snackbar('Error', 'La ruta USB es requerida');
      return;
    }

    final testPrinter = _createPrinterFromForm();
    await controller.printTestPage(testPrinter);
  }

  Future<void> _savePrinter(SettingsController controller) async {
    if (_nameController.text.isEmpty) {
      Get.snackbar('Error', 'El nombre de la impresora es requerido');
      return;
    }

    if (_connectionType == PrinterConnectionType.network && _ipController.text.isEmpty) {
      Get.snackbar('Error', 'La dirección IP es requerida');
      return;
    }

    if (_connectionType == PrinterConnectionType.usb && _usbPathController.text.isEmpty) {
      Get.snackbar('Error', 'La ruta USB es requerida');
      return;
    }

    final printer = _createPrinterFromForm();
    await controller.savePrinterSettings(printer);
    
    if (!controller.isSaving) {
      _clearForm();
    }
  }

  PrinterSettings _createPrinterFromForm() {
    final id = _editingPrinter?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    if (_connectionType == PrinterConnectionType.network) {
      return PrinterSettings.networkPrinter(
        id: id,
        name: _nameController.text.trim(),
        ipAddress: _ipController.text.trim(),
        port: int.tryParse(_portController.text) ?? 9100,
        paperSize: _paperSize,
        autoCut: _autoCut,
        cashDrawer: _cashDrawer,
        isDefault: _isDefault,
      );
    } else {
      return PrinterSettings.usbPrinter(
        id: id,
        name: _nameController.text.trim(),
        usbPath: _usbPathController.text.trim(),
        paperSize: _paperSize,
        autoCut: _autoCut,
        cashDrawer: _cashDrawer,
        isDefault: _isDefault,
      );
    }
  }

  void _handlePrinterAction(SettingsController controller, PrinterSettings printer, String action) {
    switch (action) {
      case 'setDefault':
        controller.setDefaultPrinter(printer.id);
        break;
      case 'test':
        controller.testPrinterConnection(printer);
        break;
      case 'printTest':
        controller.printTestPage(printer);
        break;
      case 'edit':
        _editPrinter(printer);
        break;
      case 'delete':
        _showDeleteConfirmation(controller, printer);
        break;
    }
  }

  void _showDeleteConfirmation(SettingsController controller, PrinterSettings printer) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: ElegantLightTheme.backgroundColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Eliminar Impresora',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${printer.name}"?',
          style: const TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          _buildFuturisticButton(
            text: 'Cancelar',
            icon: Icons.cancel,
            onPressed: () => Get.back(),
            gradient: ElegantLightTheme.glassGradient,
          ),
          const SizedBox(width: 8),
          _buildFuturisticButton(
            text: 'Eliminar',
            icon: Icons.delete,
            onPressed: () {
              Get.back();
              controller.deletePrinterSettings(printer.id);
            },
            gradient: ElegantLightTheme.errorGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: value 
            ? LinearGradient(
                colors: [
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
                ],
              )
            : ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
              : ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
          width: value ? 2 : 1,
        ),
        boxShadow: value 
            ? ElegantLightTheme.glowShadow 
            : ElegantLightTheme.elevatedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: value 
                              ? ElegantLightTheme.primaryBlue 
                              : ElegantLightTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildFuturisticSwitch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: ElegantLightTheme.normalAnimation,
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          gradient: value 
              ? ElegantLightTheme.primaryGradient 
              : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: value 
              ? ElegantLightTheme.glowShadow 
              : ElegantLightTheme.elevatedShadow,
        ),
        child: AnimatedAlign(
          duration: ElegantLightTheme.normalAnimation,
          curve: ElegantLightTheme.elasticCurve,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: value
                ? Icon(
                    Icons.check,
                    color: ElegantLightTheme.primaryBlue,
                    size: 16,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticButton({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
    required LinearGradient gradient,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null ? gradient : LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null ? ElegantLightTheme.elevatedShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}