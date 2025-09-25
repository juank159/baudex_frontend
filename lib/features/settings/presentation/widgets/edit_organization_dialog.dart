// lib/features/settings/presentation/widgets/edit_organization_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../controllers/organization_controller.dart';
import '../../domain/entities/organization.dart';

class EditOrganizationDialog extends StatefulWidget {
  final Organization organization;

  const EditOrganizationDialog({
    super.key,
    required this.organization,
  });

  @override
  State<EditOrganizationDialog> createState() => _EditOrganizationDialogState();
}

class _EditOrganizationDialogState extends State<EditOrganizationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _domainController;
  
  late String _selectedCurrency;
  late String _selectedLocale;
  late String _selectedTimezone;
  late bool _isActive;

  final _currencies = [
    {'code': 'COP', 'name': 'COP - Peso Colombiano'},
    {'code': 'USD', 'name': 'USD - Dólar Americano'},
    {'code': 'EUR', 'name': 'EUR - Euro'},
    {'code': 'MXN', 'name': 'MXN - Peso Mexicano'},
  ];

  final _locales = [
    {'code': 'es', 'name': 'Español'},
    {'code': 'en', 'name': 'English'},
    {'code': 'es_CO', 'name': 'Español (CO)'},
    {'code': 'es_ES', 'name': 'Español (ES)'},
    {'code': 'en_US', 'name': 'English (US)'},
    {'code': 'es_MX', 'name': 'Español (MX)'},
  ];

  final _timezones = [
    {'code': 'America/Bogota', 'name': 'Bogotá (COT)'},
    {'code': 'America/New_York', 'name': 'Nueva York (EST)'},
    {'code': 'Europe/Madrid', 'name': 'Madrid (CET)'},
    {'code': 'America/Mexico_City', 'name': 'México (CST)'},
  ];


  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.organization.name);
    _slugController = TextEditingController(text: widget.organization.slug);
    _domainController = TextEditingController(text: widget.organization.domain ?? '');
    
    _selectedCurrency = widget.organization.currency;
    _selectedLocale = widget.organization.locale;
    _selectedTimezone = widget.organization.timezone;
    _isActive = widget.organization.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrganizationController>();
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 900;
    
    // Responsive dialog sizing
    double dialogWidth;
    double maxHeight;
    EdgeInsets padding;
    
    if (isSmallScreen) {
      dialogWidth = screenSize.width * 0.95; // 95% of screen width on mobile
      maxHeight = screenSize.height * 0.9; // 90% of screen height
      padding = const EdgeInsets.all(AppDimensions.paddingMedium);
    } else if (isMediumScreen) {
      dialogWidth = 500; // Fixed width for tablets
      maxHeight = screenSize.height * 0.85;
      padding = const EdgeInsets.all(AppDimensions.paddingLarge);
    } else {
      dialogWidth = 600; // Fixed width for desktop
      maxHeight = 700;
      padding = const EdgeInsets.all(AppDimensions.paddingLarge);
    }

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: screenSize.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with padding
            Padding(
              padding: padding.copyWith(bottom: 0),
              child: _buildHeader(),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: padding.copyWith(top: 0, bottom: 0),
                child: _buildForm(controller),
              ),
            ),
            
            // Actions with padding
            Padding(
              padding: padding.copyWith(top: AppDimensions.spacingMedium),
              child: _buildActions(controller, isSmallScreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingSmall),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(
            Icons.edit,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar Organización',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Modifique la información de "${widget.organization.name}"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildForm(OrganizationController controller) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información básica
          _buildSectionTitle('Información Básica'),
          const SizedBox(height: AppDimensions.spacingMedium),
          
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Organización *',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
            validator: controller.validateOrganizationName,
          ),
          
          const SizedBox(height: AppDimensions.spacingMedium),
          
          TextFormField(
            controller: _slugController,
            decoration: const InputDecoration(
              labelText: 'Slug (Identificador único) *',
              prefixIcon: Icon(Icons.link),
              helperText: 'Solo letras minúsculas, números y guiones',
              border: OutlineInputBorder(),
            ),
            validator: controller.validateOrganizationSlug,
            enabled: false, // El slug generalmente no se puede cambiar
          ),
          
          const SizedBox(height: AppDimensions.spacingMedium),
          
          TextFormField(
            controller: _domainController,
            decoration: const InputDecoration(
              labelText: 'Dominio (Opcional)',
              prefixIcon: Icon(Icons.domain),
              border: OutlineInputBorder(),
            ),
            validator: controller.validateDomain,
          ),

          const SizedBox(height: AppDimensions.spacingMedium),

          // Estado
          SwitchListTile(
            title: const Text('Organización Activa'),
            subtitle: Text(_isActive ? 'La organización está activa' : 'La organización está inactiva'),
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeColor: AppColors.success,
          ),

          const SizedBox(height: AppDimensions.spacingLarge),

          // Configuración regional
          _buildSectionTitle('Configuración Regional'),
          const SizedBox(height: AppDimensions.spacingMedium),
          
          DropdownButtonFormField<String>(
            value: _currencies.any((currency) => currency['code'] == _selectedCurrency) 
                ? _selectedCurrency 
                : _currencies.first['code'],
            decoration: const InputDecoration(
              labelText: 'Moneda',
              prefixIcon: Icon(Icons.monetization_on),
              border: OutlineInputBorder(),
            ),
            isExpanded: true, // Prevents overflow
            items: _currencies.map((currency) {
              return DropdownMenuItem<String>(
                value: currency['code'],
                child: Text(
                  currency['name']!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCurrency = value!),
          ),
          
          const SizedBox(height: AppDimensions.spacingMedium),
          
          DropdownButtonFormField<String>(
            value: _locales.any((locale) => locale['code'] == _selectedLocale) 
                ? _selectedLocale 
                : _locales.first['code'],
            decoration: const InputDecoration(
              labelText: 'Idioma',
              prefixIcon: Icon(Icons.language),
              border: OutlineInputBorder(),
            ),
            isExpanded: true, // Prevents overflow
            items: _locales.map((locale) {
              return DropdownMenuItem<String>(
                value: locale['code'],
                child: Text(
                  locale['name']!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedLocale = value!),
          ),
          
          const SizedBox(height: AppDimensions.spacingMedium),
          
          DropdownButtonFormField<String>(
            value: _timezones.any((timezone) => timezone['code'] == _selectedTimezone) 
                ? _selectedTimezone 
                : _timezones.first['code'],
            decoration: const InputDecoration(
              labelText: 'Zona Horaria',
              prefixIcon: Icon(Icons.access_time),
              border: OutlineInputBorder(),
            ),
            isExpanded: true, // Prevents overflow
            items: _timezones.map((timezone) {
              return DropdownMenuItem<String>(
                value: timezone['code'],
                child: Text(
                  timezone['name']!,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedTimezone = value!),
          ),

          const SizedBox(height: AppDimensions.spacingLarge),

          // Información adicional
          _buildSectionTitle('Información Adicional'),
          const SizedBox(height: AppDimensions.spacingMedium),
          
          _buildInfoRow('ID', widget.organization.id),
          _buildInfoRow('Creado', _formatDate(widget.organization.createdAt)),
          _buildInfoRow('Actualizado', _formatDate(widget.organization.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallWidth = constraints.maxWidth < 300;
          
          if (isSmallWidth) {
            // Stack vertically on very small screens
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          } else {
            // Row layout for larger screens
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: constraints.maxWidth * 0.35, // 35% of available width
                  child: Text(
                    '$label:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildActions(OrganizationController controller, bool isSmallScreen) {
    return Obx(() {
      if (isSmallScreen) {
        // Stack buttons vertically on small screens
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: controller.isLoading ? null : _updateOrganization,
              icon: controller.isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
              label: Text(controller.isLoading ? 'Guardando...' : 'Guardar Cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
            TextButton(
              onPressed: controller.isLoading ? null : () => Get.back(),
              child: const Text('Cancelar'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingMedium,
                ),
              ),
            ),
          ],
        );
      } else {
        // Horizontal layout for larger screens
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: controller.isLoading ? null : () => Get.back(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: AppDimensions.spacingMedium),
            Flexible(
              child: ElevatedButton.icon(
                onPressed: controller.isLoading ? null : _updateOrganization,
                icon: controller.isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
                label: Text(controller.isLoading ? 'Guardando...' : 'Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLarge,
                    vertical: AppDimensions.paddingMedium,
                  ),
                ),
              ),
            ),
          ],
        );
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateOrganization() async {
    if (!_formKey.currentState!.validate()) {
      print('🚨 Validation failed');
      return;
    }

    print('✅ Form validation passed');
    final controller = Get.find<OrganizationController>();
    
    final updates = <String, dynamic>{
      'name': _nameController.text.trim(),
      'domain': _domainController.text.trim().isEmpty ? null : _domainController.text.trim(),
      'currency': _selectedCurrency,
      'locale': _selectedLocale,
      'timezone': _selectedTimezone,
      'isActive': _isActive,
    };

    print('📤 Sending updates: $updates');
    final success = await controller.updateCurrentOrganization(updates);
    print('📥 Update result: $success');
    
    if (success) {
      print('✅ Update successful! Closing dialog immediately...');
      
      // Cerrar el diálogo primero
      Navigator.of(context).pop();
      
      // Mostrar snackbar después de cerrar
      Get.snackbar(
        'Éxito',
        'Organización actualizada exitosamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        icon: const Icon(Icons.check_circle, color: Colors.green),
        duration: const Duration(seconds: 3),
      );
      
      print('✅ Dialog closed and snackbar shown');
    } else {
      print('❌ Update failed, dialog remains open');
    }
  }
}