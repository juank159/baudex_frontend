// lib/features/settings/presentation/widgets/create_organization_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../controllers/organization_controller.dart';
import '../../domain/entities/create_organization_request.dart';
import '../../domain/entities/organization.dart';

class CreateOrganizationDialog extends StatefulWidget {
  const CreateOrganizationDialog({super.key});

  @override
  State<CreateOrganizationDialog> createState() => _CreateOrganizationDialogState();
}

class _CreateOrganizationDialogState extends State<CreateOrganizationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _domainController = TextEditingController();
  
  String _selectedCurrency = 'COP';
  String _selectedLocale = 'es_CO';
  String _selectedTimezone = 'America/Bogota';
  SubscriptionPlan _selectedPlan = SubscriptionPlan.basic;

  final _currencies = [
    {'code': 'COP', 'name': 'Peso Colombiano (COP)'},
    {'code': 'USD', 'name': 'Dólar Americano (USD)'},
    {'code': 'EUR', 'name': 'Euro (EUR)'},
    {'code': 'MXN', 'name': 'Peso Mexicano (MXN)'},
  ];

  final _locales = [
    {'code': 'es_CO', 'name': 'Español (Colombia)'},
    {'code': 'es_ES', 'name': 'Español (España)'},
    {'code': 'en_US', 'name': 'English (US)'},
    {'code': 'es_MX', 'name': 'Español (México)'},
  ];

  final _timezones = [
    {'code': 'America/Bogota', 'name': 'América/Bogotá (COT)'},
    {'code': 'America/New_York', 'name': 'América/Nueva_York (EST)'},
    {'code': 'Europe/Madrid', 'name': 'Europa/Madrid (CET)'},
    {'code': 'America/Mexico_City', 'name': 'América/Ciudad_de_México (CST)'},
  ];

  final _plans = [
    {'plan': SubscriptionPlan.trial, 'name': 'Prueba', 'description': 'Plan de prueba gratuito por 30 días'},
    {'plan': SubscriptionPlan.basic, 'name': 'Básico', 'description': 'Plan básico con funcionalidades esenciales'},
    {'plan': SubscriptionPlan.premium, 'name': 'Premium', 'description': 'Plan premium con características avanzadas'},
    {'plan': SubscriptionPlan.enterprise, 'name': 'Empresarial', 'description': 'Plan empresarial con todas las funcionalidades'},
  ];

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

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: AppDimensions.spacingLarge),
            Expanded(
              child: SingleChildScrollView(
                child: _buildForm(controller),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildActions(controller),
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
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(
            Icons.add_business,
            color: AppColors.success,
            size: 24,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crear Nueva Organización',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Complete la información para crear una nueva organización',
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
              hintText: 'Ej: Mi Empresa S.A.S.',
              prefixIcon: Icon(Icons.business),
            ),
            validator: controller.validateOrganizationName,
            onChanged: _generateSlugFromName,
          ),
          
          const SizedBox(height: AppDimensions.spacingMedium),
          
          TextFormField(
            controller: _slugController,
            decoration: const InputDecoration(
              labelText: 'Slug (Identificador único) *',
              hintText: 'Ej: mi-empresa',
              prefixIcon: Icon(Icons.link),
              helperText: 'Solo letras minúsculas, números y guiones',
            ),
            validator: controller.validateOrganizationSlug,
          ),
          
          const SizedBox(height: AppDimensions.spacingMedium),
          
          TextFormField(
            controller: _domainController,
            decoration: const InputDecoration(
              labelText: 'Dominio (Opcional)',
              hintText: 'Ej: miempresa.com',
              prefixIcon: Icon(Icons.domain),
            ),
            validator: controller.validateDomain,
          ),

          const SizedBox(height: AppDimensions.spacingLarge),

          // Configuración regional
          _buildSectionTitle('Configuración Regional'),
          const SizedBox(height: AppDimensions.spacingMedium),
          
          DropdownButtonFormField<String>(
            value: _selectedCurrency,
            decoration: const InputDecoration(
              labelText: 'Moneda',
              prefixIcon: Icon(Icons.monetization_on),
            ),
            items: _currencies.map((currency) {
              return DropdownMenuItem<String>(
                value: currency['code'],
                child: Text(currency['name']!),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCurrency = value!),
          ),
          
          const SizedBox(height: AppDimensions.spacingMedium),
          
          DropdownButtonFormField<String>(
            value: _selectedLocale,
            decoration: const InputDecoration(
              labelText: 'Idioma',
              prefixIcon: Icon(Icons.language),
            ),
            items: _locales.map((locale) {
              return DropdownMenuItem<String>(
                value: locale['code'],
                child: Text(locale['name']!),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedLocale = value!),
          ),
          
          const SizedBox(height: AppDimensions.spacingMedium),
          
          DropdownButtonFormField<String>(
            value: _selectedTimezone,
            decoration: const InputDecoration(
              labelText: 'Zona Horaria',
              prefixIcon: Icon(Icons.access_time),
            ),
            items: _timezones.map((timezone) {
              return DropdownMenuItem<String>(
                value: timezone['code'],
                child: Text(timezone['name']!),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedTimezone = value!),
          ),

          const SizedBox(height: AppDimensions.spacingLarge),

          // Plan de suscripción
          _buildSectionTitle('Plan de Suscripción'),
          const SizedBox(height: AppDimensions.spacingMedium),
          
          ..._plans.map((plan) {
            return RadioListTile<SubscriptionPlan>(
              value: plan['plan']! as SubscriptionPlan,
              groupValue: _selectedPlan,
              onChanged: (value) => setState(() => _selectedPlan = value!),
              title: Text(plan['name']! as String),
              subtitle: Text(plan['description']! as String),
              activeColor: AppColors.primary,
            );
          }),
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

  Widget _buildActions(OrganizationController controller) {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: controller.isLoading ? null : () => Get.back(),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: AppDimensions.spacingMedium),
          ElevatedButton.icon(
            onPressed: controller.isLoading ? null : _createOrganization,
            icon: controller.isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
            label: Text(controller.isLoading ? 'Creando...' : 'Crear Organización'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
                vertical: AppDimensions.paddingMedium,
              ),
            ),
          ),
        ],
      );
    });
  }

  void _generateSlugFromName(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    
    _slugController.text = slug;
  }

  Future<void> _createOrganization() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = Get.find<OrganizationController>();
    
    final request = CreateOrganizationRequest(
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      domain: _domainController.text.trim().isEmpty ? null : _domainController.text.trim(),
      currency: _selectedCurrency,
      locale: _selectedLocale,
      timezone: _selectedTimezone,
      subscriptionPlan: _selectedPlan.value,
    );

    final success = await controller.createOrganization(request);
    
    if (success) {
      Get.back();
    }
  }
}