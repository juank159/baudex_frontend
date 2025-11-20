// lib/features/invoices/presentation/screens/invoice_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/ui/layouts/main_layout.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen>
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
      CurvedAnimation(parent: _animationController, curve: ElegantLightTheme.elasticCurve),
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: MainLayout(
              title: _getResponsiveTitle(context),
              showBackButton: true,
              showDrawer: false,
              actions: _buildAppBarActions(context),
              body: _buildFuturisticContent(context),
            ),
          ),
        );
      },
    );
  }

  String _getResponsiveTitle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return 'Facturas';
    } else if (screenWidth < 800) {
      return 'Config. Facturas';
    } else {
      return 'Configuración de Facturas';
    }
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      _buildFuturisticSaveButton(context),
      const SizedBox(width: 16),
    ];
  }

  Widget _buildFuturisticSaveButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;
    bool isDesktop = screenWidth >= 1000;
    
    if (isMobile) {
      // Solo icono para móvil
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showSaveConfirmation(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.save_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    } else {
      // Estilo exacto de la referencia para tablet y desktop
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () => _showSaveConfirmation(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 16, 
                vertical: 12
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.save_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Guardar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 14 : 13,
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

  void _showSaveConfirmation(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;
    
    // Mostrar animación de guardado
    Get.dialog(
      barrierDismissible: false,
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: isMobile ? 280 : 320,
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ElegantLightTheme.surfaceColor,
                ElegantLightTheme.surfaceColor.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                offset: const Offset(0, 8),
                blurRadius: 32,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono animado
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + (0.5 * value),
                    child: Transform.rotate(
                      angle: value * 0.5,
                      child: Container(
                        width: isMobile ? 60 : 70,
                        height: isMobile ? 60 : 70,
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: ElegantLightTheme.glowShadow,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: isMobile ? 30 : 35,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isMobile ? 16 : 20),
              
              // Título
              Text(
                '¡Configuración Guardada!',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 8 : 10),
              
              // Subtítulo
              Text(
                'Los cambios se han aplicado exitosamente',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 20 : 24),
              
              // Botón de cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: ElegantLightTheme.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 12 : 14,
                    ),
                  ),
                  child: Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // Auto cerrar después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    });
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
      child: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  // Layout para móviles
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildNumberingSection(context),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildFormatSection(context),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildTaxSection(context),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1200),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildDefaultsSection(context),
                ),
              );
            },
          ),
          const SizedBox(height: 100), // Extra space at bottom
        ],
      ),
    );
  }

  // Layout para tablets
  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildNumberingSection(context)),
              const SizedBox(width: 24),
              Expanded(child: _buildFormatSection(context)),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTaxSection(context)),
              const SizedBox(width: 24),
              Expanded(child: _buildDefaultsSection(context)),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // Layout para desktop
  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
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
                    _buildNumberingSection(context),
                    const SizedBox(height: 32),
                    _buildTaxSection(context),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildFormatSection(context),
                    const SizedBox(height: 32),
                    _buildDefaultsSection(context),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNumberingSection(BuildContext context) {
    return FuturisticContainer(
      hasGlow: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          bool isMobile = screenWidth < 600;
          bool isTablet = screenWidth >= 600 && screenWidth < 1000;
          
          double iconPadding = isMobile ? 12 : isTablet ? 14 : 16;
          double iconSize = isMobile ? 20 : isTablet ? 22 : 24;
          double titleFontSize = isMobile ? 16 : isTablet ? 18 : 20;
          double spacing = isMobile ? 12 : isTablet ? 16 : 20;
          double verticalSpacing = isMobile ? 16 : isTablet ? 20 : 24;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Icon(
                      Icons.format_list_numbered,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      'Numeración de Facturas',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
            
            // Prefijo
            _buildSettingField(
              context,
              label: 'Prefijo',
              value: 'FACT-',
              hint: 'Ejemplo: FACT-, INV-, etc.',
              icon: Icons.text_fields,
            ),
            
            const SizedBox(height: 12),
            
            // Número inicial
            _buildSettingField(
              context,
              label: 'Número inicial',
              value: '1000',
              hint: 'Número desde donde empezar',
              icon: Icons.looks_one,
            ),
            
            const SizedBox(height: 12),
            
              // Vista previa futurística
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                      ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.preview,
                        color: Colors.white,
                        size: isMobile ? 16 : 18,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vista previa',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: ElegantLightTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'FACT-1000, FACT-1001, FACT-1002...',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : isTablet ? 12 : 13,
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormatSection(BuildContext context) {
    return FuturisticContainer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          bool isMobile = screenWidth < 600;
          bool isTablet = screenWidth >= 600 && screenWidth < 1000;
          
          double iconPadding = isMobile ? 12 : isTablet ? 14 : 16;
          double iconSize = isMobile ? 20 : isTablet ? 22 : 24;
          double titleFontSize = isMobile ? 16 : isTablet ? 18 : 20;
          double spacing = isMobile ? 12 : isTablet ? 16 : 20;
          double verticalSpacing = isMobile ? 16 : isTablet ? 20 : 24;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.successGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      'Formato de Facturas',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
            
            // Formato de fecha
            _buildFormatOption(
              context,
              title: 'Formato de fecha',
              current: 'DD/MM/YYYY',
              options: ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
              icon: Icons.calendar_today,
            ),
            
            const SizedBox(height: 16),
            
            // Formato de moneda
            _buildFormatOption(
              context,
              title: 'Formato de moneda',
              current: '\$ 1.234.567',
              options: ['\$ 1.234.567', '\$ 1,234,567', '1.234.567 \$'],
              icon: Icons.attach_money,
            ),
            
            const SizedBox(height: 16),
            
              // Idioma
              _buildFormatOption(
                context,
                title: 'Idioma',
                current: 'Español (Colombia)',
                options: ['Español (Colombia)', 'Español (México)', 'English (US)'],
                icon: Icons.language,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaxSection(BuildContext context) {
    return FuturisticContainer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          bool isMobile = screenWidth < 600;
          bool isTablet = screenWidth >= 600 && screenWidth < 1000;
          
          double iconPadding = isMobile ? 12 : isTablet ? 14 : 16;
          double iconSize = isMobile ? 20 : isTablet ? 22 : 24;
          double titleFontSize = isMobile ? 16 : isTablet ? 18 : 20;
          double spacing = isMobile ? 12 : isTablet ? 16 : 20;
          double verticalSpacing = isMobile ? 16 : isTablet ? 20 : 24;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.warningGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Icon(
                      Icons.percent,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      'Configuración de Impuestos',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
            
            // IVA por defecto
            _buildSettingField(
              context,
              label: 'IVA por defecto (%)',
              value: '19',
              hint: 'Porcentaje de IVA predeterminado',
              icon: Icons.calculate,
            ),
            
            const SizedBox(height: 12),
            
              // Switch futurístico para incluir IVA
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.1),
                      ElegantLightTheme.warningGradient.colors.last.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.warningGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: isMobile ? 16 : 18,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Incluir IVA por defecto',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                              fontWeight: FontWeight.w600,
                              color: ElegantLightTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Aplicar IVA automáticamente en nuevas facturas',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : isTablet ? 13 : 14,
                              color: ElegantLightTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: isMobile ? 0.8 : 1.0,
                      child: Switch(
                        value: true,
                        activeColor: ElegantLightTheme.warningGradient.colors.first,
                        onChanged: (value) {
                          // TODO: Implementar lógica
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDefaultsSection(BuildContext context) {
    return FuturisticContainer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          bool isMobile = screenWidth < 600;
          bool isTablet = screenWidth >= 600 && screenWidth < 1000;
          
          double iconPadding = isMobile ? 12 : isTablet ? 14 : 16;
          double iconSize = isMobile ? 20 : isTablet ? 22 : 24;
          double titleFontSize = isMobile ? 16 : isTablet ? 18 : 20;
          double spacing = isMobile ? 12 : isTablet ? 16 : 20;
          double verticalSpacing = isMobile ? 16 : isTablet ? 20 : 24;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      'Valores por Defecto',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
            
            // Términos y condiciones
            _buildSettingField(
              context,
              label: 'Términos y condiciones',
              value: 'Pago a 30 días',
              hint: 'Términos de pago predeterminados',
              icon: Icons.description,
              maxLines: 2,
            ),
            
            const SizedBox(height: 12),
            
            // Notas por defecto
            _buildSettingField(
              context,
              label: 'Notas por defecto',
              value: 'Gracias por su compra',
              hint: 'Nota que aparecerá en todas las facturas',
              icon: Icons.note,
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
              // Información adicional futurística
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.1),
                      ElegantLightTheme.infoGradient.colors.last.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: isMobile ? 16 : 18,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuración Empresarial',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : isTablet ? 14 : 15,
                              fontWeight: FontWeight.w600,
                              color: ElegantLightTheme.infoGradient.colors.first,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estos valores se aplicarán automáticamente a todas las nuevas facturas que crees.',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : isTablet ? 12 : 13,
                              color: ElegantLightTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingField(
    BuildContext context, {
    required String label,
    required String value,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 13 : isTablet ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: TextFormField(
                initialValue: value,
                maxLines: maxLines,
                style: TextStyle(
                  fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                  color: ElegantLightTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: ElegantLightTheme.textSecondary.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      icon, 
                      color: ElegantLightTheme.primaryBlue,
                      size: isMobile ? 16 : 18,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ElegantLightTheme.primaryBlue,
                      width: 2,
                    ),
                  ),
                  fillColor: ElegantLightTheme.surfaceColor,
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 12 : 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormatOption(
    BuildContext context, {
    required String title,
    required String current,
    required List<String> options,
    required IconData icon,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        bool isMobile = screenWidth < 600;
        bool isTablet = screenWidth >= 600 && screenWidth < 1000;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 13 : isTablet ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 8 : 12,
              ),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                border: Border.all(
                  color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon, 
                      color: Colors.white, 
                      size: isMobile ? 14 : 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: current,
                      isExpanded: true,
                      underline: Container(),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : isTablet ? 15 : 16,
                        color: ElegantLightTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      dropdownColor: ElegantLightTheme.surfaceColor,
                      items: options.map((option) => 
                        DropdownMenuItem(
                          value: option,
                          child: Text(
                            option,
                            style: TextStyle(
                              color: ElegantLightTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ).toList(),
                      onChanged: (value) {
                        // TODO: Implementar lógica de cambio
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}