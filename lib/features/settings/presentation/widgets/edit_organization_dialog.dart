// lib/features/settings/presentation/widgets/edit_organization_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/organization_controller.dart';
import '../../domain/entities/organization.dart';

class EditOrganizationDialog extends StatefulWidget {
  final Organization organization;

  const EditOrganizationDialog({super.key, required this.organization});

  /// Obtener el path del logo guardado localmente para una organización
  static Future<String?> getLogoPath(String orgId) async {
    final dir = await getApplicationDocumentsDirectory();
    final logoPath = '${dir.path}/org_logos/$orgId.png';
    if (await File(logoPath).exists()) return logoPath;
    return null;
  }

  @override
  State<EditOrganizationDialog> createState() => _EditOrganizationDialogState();
}

class _EditOrganizationDialogState extends State<EditOrganizationDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _domainController;

  // Campos de facturación
  late final TextEditingController _businessNameController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _footerMessageController;

  // Logo
  File? _logoFile;
  String? _currentLogoPath;
  bool _logoDeleted = false;
  bool _isSaving = false;

  late String _selectedCurrency;
  late String _selectedLocale;
  late String _selectedTimezone;
  late bool _isActive;

  // Animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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
    // América Latina
    {'code': 'America/Bogota', 'name': 'Bogotá, Colombia (UTC-5)'},
    {'code': 'America/Caracas', 'name': 'Caracas, Venezuela (UTC-4)'},
    {'code': 'America/Lima', 'name': 'Lima, Perú (UTC-5)'},
    {'code': 'America/Guayaquil', 'name': 'Guayaquil, Ecuador (UTC-5)'},
    {'code': 'America/Santiago', 'name': 'Santiago, Chile (UTC-3)'},
    {'code': 'America/Argentina/Buenos_Aires', 'name': 'Buenos Aires, Argentina (UTC-3)'},
    {'code': 'America/Mexico_City', 'name': 'Ciudad de México (UTC-6)'},
    {'code': 'America/Panama', 'name': 'Panamá (UTC-5)'},
    {'code': 'America/Santo_Domingo', 'name': 'Santo Domingo, RD (UTC-4)'},
    {'code': 'America/Havana', 'name': 'La Habana, Cuba (UTC-5)'},
    {'code': 'America/Costa_Rica', 'name': 'San José, Costa Rica (UTC-6)'},
    {'code': 'America/Guatemala', 'name': 'Guatemala (UTC-6)'},
    {'code': 'America/Tegucigalpa', 'name': 'Tegucigalpa, Honduras (UTC-6)'},
    {'code': 'America/Managua', 'name': 'Managua, Nicaragua (UTC-6)'},
    {'code': 'America/El_Salvador', 'name': 'San Salvador (UTC-6)'},
    {'code': 'America/Asuncion', 'name': 'Asunción, Paraguay (UTC-4)'},
    {'code': 'America/Montevideo', 'name': 'Montevideo, Uruguay (UTC-3)'},
    {'code': 'America/La_Paz', 'name': 'La Paz, Bolivia (UTC-4)'},
    {'code': 'America/Sao_Paulo', 'name': 'São Paulo, Brasil (UTC-3)'},
    // Norteamérica
    {'code': 'America/New_York', 'name': 'Nueva York (UTC-5)'},
    {'code': 'America/Chicago', 'name': 'Chicago (UTC-6)'},
    {'code': 'America/Denver', 'name': 'Denver (UTC-7)'},
    {'code': 'America/Los_Angeles', 'name': 'Los Ángeles (UTC-8)'},
    // Europa
    {'code': 'Europe/Madrid', 'name': 'Madrid, España (UTC+1)'},
    {'code': 'Europe/London', 'name': 'Londres (UTC+0)'},
    {'code': 'Europe/Paris', 'name': 'París, Francia (UTC+1)'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingLogo();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.organization.name);
    _slugController = TextEditingController(text: widget.organization.slug);
    _domainController = TextEditingController(
      text: widget.organization.domain ?? '',
    );

    final settings = widget.organization.settings ?? {};
    _businessNameController = TextEditingController(
      text: settings['businessName'] as String? ?? '',
    );
    _taxIdController = TextEditingController(
      text: settings['taxId'] as String? ?? '',
    );
    _addressController = TextEditingController(
      text: settings['address'] as String? ?? '',
    );
    _phoneController = TextEditingController(
      text: settings['phone'] as String? ?? '',
    );
    _emailController = TextEditingController(
      text: settings['email'] as String? ?? '',
    );
    _footerMessageController = TextEditingController(
      text: settings['footerMessage'] as String? ?? '',
    );

    _selectedCurrency = widget.organization.currency;
    _selectedLocale = widget.organization.locale;
    _selectedTimezone = widget.organization.timezone;
    _isActive = widget.organization.isActive;
  }

  Future<void> _loadExistingLogo() async {
    final path = await EditOrganizationDialog.getLogoPath(widget.organization.id);
    if (path != null && mounted) {
      setState(() => _currentLogoPath = path);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _slugController.dispose();
    _domainController.dispose();
    _businessNameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _footerMessageController.dispose();
    super.dispose();
  }

  // ==================== INPUT DECORATION ====================

  InputDecoration _elegantInputDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Container(
        margin: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(icon, size: 20, color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.7)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      labelStyle: TextStyle(
        color: ElegantLightTheme.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      helperStyle: TextStyle(
        color: ElegantLightTheme.textTertiary,
        fontSize: 12,
      ),
      filled: true,
      fillColor: enabled
          ? ElegantLightTheme.backgroundColor.withValues(alpha: 0.8)
          : ElegantLightTheme.cardColor.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: ElegantLightTheme.primaryBlue,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: ElegantLightTheme.errorRed.withValues(alpha: 0.6),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: ElegantLightTheme.errorRed,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    double dialogWidth = isSmallScreen ? screenSize.width * 0.95 : 620;
    double maxHeight = isSmallScreen ? screenSize.height * 0.92 : screenSize.height * 0.88;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 10 : 24,
            vertical: isSmallScreen ? 16 : 24,
          ),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              maxWidth: screenSize.width * 0.95,
            ),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
                  offset: const Offset(0, 16),
                  blurRadius: 48,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGradientHeader(isSmallScreen),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                      child: _buildForm(),
                    ),
                  ),
                  _buildElegantActions(isSmallScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildGradientHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 28,
        vertical: isSmallScreen ? 18 : 22,
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.25),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar Organización',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 17 : 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.organization.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FORM ====================

  Widget _buildForm() {
    final controller = Get.find<OrganizationController>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Información Básica ---
          _buildSectionHeader(
            'Información Básica',
            Icons.business_rounded,
            ElegantLightTheme.infoGradient,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nameController,
            decoration: _elegantInputDecoration(
              label: 'Nombre de la Organización *',
              icon: Icons.business,
            ),
            validator: controller.validateOrganizationName,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _slugController,
            decoration: _elegantInputDecoration(
              label: 'Slug (Identificador único) *',
              icon: Icons.link,
              helperText: 'Solo letras minúsculas, números y guiones',
              enabled: false,
            ),
            validator: controller.validateOrganizationSlug,
            enabled: false,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _domainController,
            decoration: _elegantInputDecoration(
              label: 'Dominio (Opcional)',
              icon: Icons.domain,
            ),
            validator: controller.validateDomain,
          ),
          const SizedBox(height: 14),

          _buildElegantSwitch(),

          const SizedBox(height: 28),

          // --- Configuración Regional ---
          _buildSectionHeader(
            'Configuración Regional',
            Icons.public_rounded,
            ElegantLightTheme.successGradient,
          ),
          const SizedBox(height: 16),

          _buildElegantDropdown(
            value: _currencies.any((c) => c['code'] == _selectedCurrency)
                ? _selectedCurrency
                : _currencies.first['code']!,
            label: 'Moneda',
            icon: Icons.monetization_on,
            items: _currencies,
            onChanged: (v) => setState(() => _selectedCurrency = v!),
          ),
          const SizedBox(height: 14),

          _buildElegantDropdown(
            value: _locales.any((l) => l['code'] == _selectedLocale)
                ? _selectedLocale
                : _locales.first['code']!,
            label: 'Idioma',
            icon: Icons.language,
            items: _locales,
            onChanged: (v) => setState(() => _selectedLocale = v!),
          ),
          const SizedBox(height: 14),

          _buildTimezoneSelector(),

          const SizedBox(height: 28),

          // --- Datos de Facturación ---
          _buildSectionHeader(
            'Datos de Facturación',
            Icons.receipt_long_rounded,
            ElegantLightTheme.warningGradient,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Estos datos aparecerán en las facturas impresas',
              style: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildLogoPicker(),
          const SizedBox(height: 16),

          TextFormField(
            controller: _businessNameController,
            decoration: _elegantInputDecoration(
              label: 'Nombre Comercial',
              icon: Icons.storefront_rounded,
              helperText: 'Nombre que aparece en la factura',
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _taxIdController,
            decoration: _elegantInputDecoration(
              label: 'NIT / Identificación Fiscal',
              icon: Icons.badge_rounded,
              helperText: 'Ej: 900.123.456-7',
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _addressController,
            decoration: _elegantInputDecoration(
              label: 'Dirección',
              icon: Icons.location_on_rounded,
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _phoneController,
            decoration: _elegantInputDecoration(
              label: 'Teléfono',
              icon: Icons.phone_rounded,
              helperText: 'Ej: +57 300 123 4567',
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _emailController,
            decoration: _elegantInputDecoration(
              label: 'Email de Contacto',
              icon: Icons.email_rounded,
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Ingrese un email válido';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _footerMessageController,
            decoration: _elegantInputDecoration(
              label: 'Mensaje pie de factura',
              icon: Icons.message_rounded,
              helperText: 'Ej: Gracias por su compra',
            ),
          ),

          const SizedBox(height: 28),

          // --- Información del sistema ---
          _buildSectionHeader(
            'Información del Sistema',
            Icons.info_outline_rounded,
            LinearGradient(
              colors: [
                ElegantLightTheme.textTertiary,
                ElegantLightTheme.textSecondary,
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildSystemInfoRow('ID', widget.organization.id),
          _buildSystemInfoRow('Creado', _formatDate(widget.organization.createdAt)),
          _buildSystemInfoRow('Actualizado', _formatDate(widget.organization.updatedAt)),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==================== SECTION HEADER ====================

  Widget _buildSectionHeader(String title, IconData icon, LinearGradient gradient) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ==================== SWITCH ====================

  Widget _buildElegantSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _isActive
            ? ElegantLightTheme.successGreen.withValues(alpha: 0.06)
            : ElegantLightTheme.errorRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isActive
              ? ElegantLightTheme.successGreen.withValues(alpha: 0.2)
              : ElegantLightTheme.errorRed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isActive ? ElegantLightTheme.successGreen : ElegantLightTheme.errorRed,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Organización Activa',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isActive ? 'La organización está activa' : 'La organización está inactiva',
                  style: TextStyle(
                    color: ElegantLightTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeColor: ElegantLightTheme.successGreen,
          ),
        ],
      ),
    );
  }

  // ==================== TIMEZONE SELECTOR ====================

  Widget _buildTimezoneSelector() {
    final currentTz = _timezones.firstWhere(
      (t) => t['code'] == _selectedTimezone,
      orElse: () => _timezones.first,
    );

    return InkWell(
      onTap: () => _showTimezonePickerDialog(),
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _elegantInputDecoration(
          label: 'Zona Horaria',
          icon: Icons.access_time_rounded,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                currentTz['name']!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: ElegantLightTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showTimezonePickerDialog() {
    final searchController = TextEditingController();
    var filtered = List<Map<String, String>>.from(_timezones);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 420,
              height: 500,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ElegantLightTheme.elevatedShadow,
              ),
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
                        ),
                        child: const Icon(Icons.public, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Seleccionar Zona Horaria',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar zona horaria...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ElegantLightTheme.primaryBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (query) {
                      setDialogState(() {
                        final q = query.toLowerCase();
                        filtered = _timezones
                            .where((t) =>
                                t['name']!.toLowerCase().contains(q) ||
                                t['code']!.toLowerCase().contains(q))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, index) {
                        final tz = filtered[index];
                        final isSelected = tz['code'] == _selectedTimezone;
                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          selected: isSelected,
                          selectedTileColor: ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
                          leading: Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? ElegantLightTheme.primaryBlue : Colors.grey.shade400,
                            size: 20,
                          ),
                          title: Text(
                            tz['name']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textPrimary,
                            ),
                          ),
                          onTap: () {
                            setState(() => _selectedTimezone = tz['code']!);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== DROPDOWN ====================

  Widget _buildElegantDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _elegantInputDecoration(label: label, icon: icon),
      isExpanded: true,
      dropdownColor: ElegantLightTheme.surfaceColor,
      borderRadius: BorderRadius.circular(14),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['code'],
          child: Text(
            item['name']!,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 14,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // ==================== LOGO PICKER ====================

  Widget _buildLogoPicker() {
    final hasLogo = _logoFile != null || (_currentLogoPath != null && !_logoDeleted);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          // Preview del logo
          GestureDetector(
            onTap: _pickLogo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: hasLogo
                    ? Colors.white
                    : ElegantLightTheme.primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasLogo
                      ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.2)
                      : ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: hasLogo
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              clipBehavior: Clip.antiAlias,
              child: hasLogo
                  ? Image.file(
                      _logoFile ?? File(_currentLogoPath!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                    )
                  : _buildLogoPlaceholder(),
            ),
          ),
          const SizedBox(width: 16),
          // Info y botones
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasLogo ? Icons.image_rounded : Icons.add_photo_alternate_rounded,
                      size: 18,
                      color: ElegantLightTheme.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Logo de Factura',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasLogo ? 'Imagen cargada correctamente' : 'Sin imagen seleccionada',
                  style: TextStyle(
                    color: hasLogo ? ElegantLightTheme.successGreen : ElegantLightTheme.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: _buildSmallButton(
                        label: hasLogo ? 'Cambiar' : 'Seleccionar',
                        icon: Icons.image_rounded,
                        gradient: ElegantLightTheme.primaryGradient,
                        onTap: _pickLogo,
                      ),
                    ),
                    if (hasLogo) ...[
                      const SizedBox(width: 8),
                      _buildSmallButton(
                        label: 'Eliminar',
                        icon: Icons.delete_outline_rounded,
                        gradient: ElegantLightTheme.errorGradient,
                        onTap: _removeLogo,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.25),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 28,
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            'Logo',
            style: TextStyle(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SYSTEM INFO ====================

  Widget _buildSystemInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================

  Widget _buildElegantActions(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 28,
        vertical: isSmallScreen ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSaveButton(),
                const SizedBox(height: 10),
                _buildCancelButton(),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildCancelButton(),
                const SizedBox(width: 12),
                _buildSaveButton(),
              ],
            ),
    );
  }

  Widget _buildSaveButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSaving ? null : _updateOrganization,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            gradient: _isSaving ? null : ElegantLightTheme.primaryGradient,
            color: _isSaving ? ElegantLightTheme.textTertiary.withValues(alpha: 0.3) : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isSaving
                ? []
                : [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSaving)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(Icons.save_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                _isSaving ? 'Guardando...' : 'Guardar Cambios',
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
    );
  }

  Widget _buildCancelButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSaving ? null : () => Get.back(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          decoration: BoxDecoration(
            color: ElegantLightTheme.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: _isSaving ? ElegantLightTheme.textTertiary : ElegantLightTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ==================== LOGO ACTIONS ====================

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _logoFile = File(picked.path);
          _logoDeleted = false;
        });
      }
    } catch (e) {
      debugPrint('Error seleccionando logo: $e');
    }
  }

  void _removeLogo() {
    setState(() {
      _logoFile = null;
      _logoDeleted = true;
    });
  }

  Future<void> _saveLogoLocally(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final logoDir = Directory('${dir.path}/org_logos');
    if (!await logoDir.exists()) await logoDir.create(recursive: true);
    final destPath = '${logoDir.path}/${widget.organization.id}.png';
    await file.copy(destPath);
  }

  Future<void> _deleteLogoLocally() async {
    final dir = await getApplicationDocumentsDirectory();
    final logoPath = '${dir.path}/org_logos/${widget.organization.id}.png';
    final file = File(logoPath);
    if (await file.exists()) await file.delete();
  }

  // ==================== HELPERS ====================

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ==================== UPDATE ====================

  Future<void> _updateOrganization() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final controller = Get.find<OrganizationController>();

      // Merge settings de facturación con settings existentes
      final currentSettings = Map<String, dynamic>.from(
        widget.organization.settings ?? {},
      );
      currentSettings['businessName'] = _businessNameController.text.trim();
      currentSettings['taxId'] = _taxIdController.text.trim();
      currentSettings['address'] = _addressController.text.trim();
      currentSettings['phone'] = _phoneController.text.trim();
      currentSettings['email'] = _emailController.text.trim();
      currentSettings['footerMessage'] = _footerMessageController.text.trim();

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'domain': _domainController.text.trim().isEmpty
            ? null
            : _domainController.text.trim(),
        'currency': _selectedCurrency,
        'locale': _selectedLocale,
        'timezone': _selectedTimezone,
        'isActive': _isActive,
        'settings': currentSettings,
      };

      final success = await controller.updateCurrentOrganization(updates);

      if (success) {
        // Guardar o eliminar logo localmente
        if (_logoFile != null) {
          await _saveLogoLocally(_logoFile!);
        } else if (_logoDeleted) {
          await _deleteLogoLocally();
        }

        Get.back();

        Get.snackbar(
          'Actualizado',
          'Organización actualizada exitosamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: ElegantLightTheme.successGreen.withValues(alpha: 0.15),
          colorText: ElegantLightTheme.successGreen,
          icon: const Icon(Icons.check_circle_rounded, color: ElegantLightTheme.successGreen),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(12),
          borderRadius: 14,
        );
      } else {
        if (mounted) setState(() => _isSaving = false);
      }
    } catch (e) {
      debugPrint('Error actualizando organización: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
