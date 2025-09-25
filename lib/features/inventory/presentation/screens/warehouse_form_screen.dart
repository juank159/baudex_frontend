// lib/features/inventory/presentation/screens/warehouse_form_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/warehouse_form_controller.dart';

class WarehouseFormScreen extends StatefulWidget {
  const WarehouseFormScreen({super.key});

  @override
  State<WarehouseFormScreen> createState() => _WarehouseFormScreenState();
}

class _WarehouseFormScreenState extends State<WarehouseFormScreen> {
  WarehouseFormController get controller => Get.find<WarehouseFormController>();

  @override
  void initState() {
    super.initState();
    // Asegurar que el controlador esté disponible
    try {
      Get.find<WarehouseFormController>();
    } catch (e) {
      // Si no está disponible, navegar de vuelta
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final warehouseFormController = Get.find<WarehouseFormController>();
      
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          
          final canLeave = await warehouseFormController.confirmDiscardChanges();
          if (canLeave) {
            Get.back();
          }
        },
        child: Scaffold(
          backgroundColor: ElegantLightTheme.backgroundColor,
          appBar: AppBar(
            title: Obx(() => Text(
              warehouseFormController.title,
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
            )),
            actions: _buildAppBarActions(context),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final canLeave = await warehouseFormController.confirmDiscardChanges();
                if (canLeave) {
                  Get.back();
                }
              },
              tooltip: 'Volver',
            ),
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
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                
                // Definir breakpoints para diseño responsive
                final isDesktop = screenWidth >= 1200;
                final isTablet = screenWidth >= 600 && screenWidth < 1200;
                
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ElegantLightTheme.backgroundColor,
                        ElegantLightTheme.backgroundColor.withOpacity(0.95),
                      ],
                    ),
                  ),
                  child: Obx(() {
                    if (warehouseFormController.isLoading) {
                      return const Center(child: LoadingWidget());
                    }

                    return _buildResponsiveForm(screenWidth, isDesktop, isTablet);
                  }),
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      // Si el controlador no está disponible, mostrar pantalla de error
      return _buildControllerErrorWidget(context);
    }
  }

  Widget _buildResponsiveForm(double screenWidth, bool isDesktop, bool isTablet) {
    final padding = isDesktop ? 24.0 : isTablet ? 20.0 : 16.0;
    final maxWidth = isDesktop ? screenWidth * 0.90 : double.infinity; // Usar 90% del ancho en desktop con layout de 2 columnas
    
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header elegante
            SliverToBoxAdapter(
              child: _buildElegantHeader(padding, isDesktop),
            ),

            // Formulario principal
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      if (isDesktop)
                        // Layout de 2 columnas para desktop - mejor aprovechamiento del espacio
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildInformationSection(isDesktop),
                            ),
                            SizedBox(width: isDesktop ? 24 : 20),
                            Expanded(
                              flex: 1,
                              child: _buildAdditionalSection(isDesktop),
                            ),
                          ],
                        )
                      else
                        // Layout de columna única para tablet/móvil
                        Column(
                          children: [
                            _buildInformationSection(isDesktop),
                            SizedBox(height: screenWidth >= 600 ? 18 : 16),
                            _buildAdditionalSection(isDesktop),
                          ],
                        ),
                      SizedBox(height: isDesktop ? 32 : 24),
                      _buildActionButtons(isDesktop),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElegantHeader(double padding, bool isDesktop) {
    return Container(
      margin: EdgeInsets.all(padding),
      padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: Icon(
              Icons.warehouse,
              color: Colors.white,
              size: isDesktop ? 40 : 32,
            ),
          ),
          SizedBox(width: isDesktop ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.title,
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                    fontSize: isDesktop ? 24 : 20,
                  ),
                )),
                SizedBox(height: isDesktop ? 8 : 6),
                Text(
                  controller.isCreateMode 
                      ? 'Complete los datos para crear un nuevo almacén en el sistema'
                      : 'Modifique los datos del almacén seleccionado',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: isDesktop ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Información Básica',
                style: Get.textTheme.titleLarge?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 20 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 24 : 20),
          
          // Campos del formulario
          _buildElegantTextField(
            controller: controller.nameController,
            validator: controller.validateName,
            label: 'Nombre del Almacén',
            hint: 'Ej: Almacén Central, Bodega Principal...',
            icon: Icons.warehouse,
            required: true,
            maxLength: 100,
            helperText: 'Nombre descriptivo del almacén (2-100 caracteres)',
            isDesktop: isDesktop,
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          
          _buildElegantTextField(
            controller: controller.codeController,
            validator: controller.validateCode,
            label: 'Código del Almacén',
            hint: 'Ej: ALM-001, CENTRAL, BODEGA-A...',
            icon: Icons.code,
            required: true,
            maxLength: 20,
            helperText: 'Código único alfanumérico (2-20 caracteres)',
            textCapitalization: TextCapitalization.characters,
            isDesktop: isDesktop,
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          
          _buildActiveStatusCard(isDesktop),
        ],
      ),
    );
  }

  Widget _buildAdditionalSection(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Información Adicional',
                style: Get.textTheme.titleLarge?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 20 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 24 : 20),
          
          // Campos opcionales
          _buildElegantTextField(
            controller: controller.descriptionController,
            validator: controller.validateDescription,
            label: 'Descripción',
            hint: 'Descripción detallada del almacén...',
            icon: Icons.description,
            required: false,
            maxLength: 500,
            maxLines: 3,
            helperText: 'Información adicional sobre el almacén (opcional)',
            textCapitalization: TextCapitalization.sentences,
            isDesktop: isDesktop,
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          
          _buildElegantTextField(
            controller: controller.addressController,
            validator: controller.validateAddress,
            label: 'Dirección',
            hint: 'Dirección física del almacén...',
            icon: Icons.location_on,
            required: false,
            maxLength: 200,
            maxLines: 2,
            helperText: 'Ubicación física del almacén (opcional)',
            textCapitalization: TextCapitalization.words,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }

  Widget _buildElegantTextField({
    required TextEditingController controller,
    required String? Function(String?) validator,
    required String label,
    required String hint,
    required IconData icon,
    required bool required,
    required bool isDesktop,
    int? maxLength,
    int maxLines = 1,
    String? helperText,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textSecondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLength: maxLength,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        style: TextStyle(
          color: ElegantLightTheme.textPrimary,
          fontSize: isDesktop ? 16 : 14,
        ),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          helperText: helperText,
          prefixIcon: Icon(icon, color: ElegantLightTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 16,
            vertical: isDesktop ? 16 : 12,
          ),
          labelStyle: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: isDesktop ? 16 : 14,
          ),
          hintStyle: TextStyle(
            color: ElegantLightTheme.textSecondary.withOpacity(0.6),
            fontSize: isDesktop ? 14 : 12,
          ),
          helperStyle: TextStyle(
            color: ElegantLightTheme.textSecondary.withOpacity(0.8),
            fontSize: isDesktop ? 12 : 11,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveStatusCard(bool isDesktop) {
    return Obx(() => Container(
      padding: EdgeInsets.all(isDesktop ? 20.0 : 16.0),
      decoration: BoxDecoration(
        gradient: controller.isActive 
            ? ElegantLightTheme.successGradient
            : ElegantLightTheme.errorGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ElegantLightTheme.glowShadow,
      ),
      child: Row(
        children: [
          Icon(
            controller.isActive ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: isDesktop ? 24 : 20,
          ),
          SizedBox(width: isDesktop ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado del Almacén',
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: isDesktop ? 16 : 14,
                  ),
                ),
                SizedBox(height: isDesktop ? 4 : 2),
                Text(
                  controller.isActive 
                      ? 'El almacén estará disponible para operaciones'
                      : 'El almacén no estará disponible para nuevas operaciones',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isDesktop ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: controller.isActive,
            onChanged: (_) => controller.toggleActiveStatus(),
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    ));
  }

  Widget _buildActionButtons(bool isDesktop) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    if (isMobile) {
      // Layout vertical para móviles para evitar overflow
      return Column(
        children: [
          // Botón cancelar
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantLightTheme.textSecondary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final canLeave = await controller.confirmDiscardChanges();
                    if (canLeave) {
                      Get.back();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          color: ElegantLightTheme.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cancelar',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Botón enviar
          SizedBox(
            width: double.infinity,
            child: Obx(() => Container(
              decoration: BoxDecoration(
                gradient: controller.isSaving 
                    ? ElegantLightTheme.glassGradient
                    : ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: controller.isSaving 
                    ? null
                    : [
                        BoxShadow(
                          color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: controller.isSaving ? null : controller.submitForm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (controller.isSaving)
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
                            controller.isCreateMode ? Icons.add : Icons.save,
                            color: Colors.white,
                            size: 18,
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            controller.isSaving 
                                ? (controller.isCreateMode ? 'Creando...' : 'Actualizando...')
                                : controller.submitButtonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
          ),
        ],
      );
    }
    
    // Layout horizontal para tablet/desktop
    return Row(
      children: [
        // Botón cancelar
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ElegantLightTheme.textSecondary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final canLeave = await controller.confirmDiscardChanges();
                  if (canLeave) {
                    Get.back();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 16 : 14,
                    horizontal: isDesktop ? 24 : 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: ElegantLightTheme.textSecondary,
                        size: isDesktop ? 20 : 18,
                      ),
                      SizedBox(width: isDesktop ? 8 : 6),
                      Flexible(
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: isDesktop ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        SizedBox(width: isDesktop ? 20 : 12),
        
        // Botón enviar
        Expanded(
          flex: 2,
          child: Obx(() => Container(
            decoration: BoxDecoration(
              gradient: controller.isSaving 
                  ? ElegantLightTheme.glassGradient
                  : ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: controller.isSaving 
                  ? null
                  : [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: controller.isSaving ? null : controller.submitForm,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isDesktop ? 16 : 14,
                    horizontal: isDesktop ? 24 : 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (controller.isSaving)
                        SizedBox(
                          width: isDesktop ? 18 : 16,
                          height: isDesktop ? 18 : 16,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Icon(
                          controller.isCreateMode ? Icons.add : Icons.save,
                          color: Colors.white,
                          size: isDesktop ? 20 : 18,
                        ),
                      SizedBox(width: isDesktop ? 8 : 6),
                      Flexible(
                        child: Text(
                          controller.isSaving 
                              ? (controller.isCreateMode ? 'Creando...' : 'Actualizando...')
                              : controller.submitButtonText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ),
      ],
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      // Botón de ayuda
      IconButton(
        icon: const Icon(Icons.help_outline),
        onPressed: _showHelpDialog,
        tooltip: 'Ayuda',
      ),
      const SizedBox(width: AppDimensions.paddingSmall),
    ];
  }

  void _showHelpDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? screenWidth * 0.9 : 500,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile)
                // Título para móvil - layout vertical
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.help, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ayuda - Almacenes',
                      style: Get.textTheme.titleMedium?.copyWith(
                        color: ElegantLightTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else
                // Título para tablet/desktop - layout horizontal
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.help, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ayuda - Almacenes',
                        style: Get.textTheme.titleLarge?.copyWith(
                          color: ElegantLightTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHelpItem(
                      icon: Icons.warehouse,
                      title: 'Nombre del Almacén',
                      description: 'Un nombre descriptivo que identifique claramente el almacén.',
                    ),
                    _buildHelpItem(
                      icon: Icons.code,
                      title: 'Código del Almacén',
                      description: 'Un código único alfanumérico para identificar el almacén en el sistema.',
                    ),
                    _buildHelpItem(
                      icon: Icons.description,
                      title: 'Descripción',
                      description: 'Información adicional sobre el almacén, como su propósito o características especiales.',
                    ),
                    _buildHelpItem(
                      icon: Icons.location_on,
                      title: 'Dirección',
                      description: 'La ubicación física del almacén para facilitar su localización.',
                    ),
                    _buildHelpItem(
                      icon: Icons.toggle_on,
                      title: 'Estado',
                      description: 'Los almacenes activos están disponibles para operaciones de inventario.',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Get.back(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Entendido',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: ElegantLightTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControllerErrorWidget(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Error - Formulario de Almacén',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          tooltip: 'Volver',
        ),
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
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ElegantLightTheme.neuomorphicShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.errorGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el formulario',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No se pudo inicializar el controlador del formulario',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Get.back(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Volver',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}