// lib/features/settings/presentation/screens/printer_configuration_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/app_scaffold.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../controllers/settings_controller.dart';
import '../bindings/settings_binding.dart';
import '../../domain/entities/printer_settings.dart';

class PrinterConfigurationScreen extends StatefulWidget {
  const PrinterConfigurationScreen({super.key});

  @override
  State<PrinterConfigurationScreen> createState() => _PrinterConfigurationScreenState();
}

class _PrinterConfigurationScreenState extends State<PrinterConfigurationScreen> {
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

  @override
  void initState() {
    super.initState();
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
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _usbPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.settingsPrinter,
      appBar: AppBar(
        title: const Text('Configuración de Impresoras'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearForm,
            icon: const Icon(Icons.add),
            tooltip: 'Agregar nueva impresora',
          ),
        ],
      ),
      body: Obx(() {
        if (settingsController.isLoadingPrinterSettings) {
          return const Center(child: LoadingWidget());
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(context, settingsController),
          tablet: _buildTabletLayout(context, settingsController),
          desktop: _buildDesktopLayout(context, settingsController),
        );
      }),
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formulario
          Expanded(
            flex: 2,
            child: _buildPrinterForm(context, controller),
          ),
          const SizedBox(width: 32),
          // Lista de impresoras
          Expanded(
            flex: 3,
            child: _buildPrintersList(context, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterForm(BuildContext context, SettingsController controller) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.print, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  _isEditMode ? 'Editar Impresora' : 'Agregar Nueva Impresora',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
            Row(
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
            ),
            const SizedBox(height: 16),
            
            // Configuración específica por tipo
            if (_connectionType == PrinterConnectionType.network) ...[
              Row(
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
            
            // Switches
            SwitchListTile(
              title: const Text('Corte Automático'),
              subtitle: const Text('Cortar papel automáticamente después de imprimir'),
              value: _autoCut,
              onChanged: (value) {
                setState(() {
                  _autoCut = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Apertura de Caja'),
              subtitle: const Text('Abrir caja registradora al imprimir'),
              value: _cashDrawer,
              onChanged: (value) {
                setState(() {
                  _cashDrawer = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Impresora por Defecto'),
              subtitle: const Text('Usar como impresora principal'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Botones de acción
            Row(
              children: [
                if (_isEditMode) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      type: ButtonType.outline,
                      onPressed: _clearForm,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: CustomButton(
                    text: _isEditMode ? 'Actualizar' : 'Probar Conexión',
                    icon: _isEditMode ? Icons.save : Icons.wifi_find,
                    onPressed: controller.isTestingConnection 
                        ? null 
                        : () => _testConnection(controller),
                    isLoading: controller.isTestingConnection,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: _isEditMode ? 'Guardar' : 'Agregar',
                    icon: _isEditMode ? Icons.update : Icons.add,
                    onPressed: controller.isSaving 
                        ? null 
                        : () => _savePrinter(controller),
                    isLoading: controller.isSaving,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintersList(BuildContext context, SettingsController controller) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Impresoras Configuradas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => controller.loadPrinterSettings(),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar lista',
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
        border: Border.all(
          color: printer.isDefault 
              ? Colors.blue.shade300 
              : Colors.grey.shade300,
          width: printer.isDefault ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: printer.isDefault 
            ? Colors.blue.shade50 
            : Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                printer.isNetworkPrinter ? Icons.router : Icons.usb,
                color: printer.isDefault ? Colors.blue.shade600 : Colors.grey.shade600,
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (printer.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Por Defecto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
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
        title: const Text('Eliminar Impresora'),
        content: Text('¿Estás seguro de que quieres eliminar "${printer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deletePrinterSettings(printer.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}