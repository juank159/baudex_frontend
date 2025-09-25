// lib/features/dashboard/presentation/widgets/period_selector.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/themes/app_text_styles.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(
      builder: (controller) {
        return GestureDetector(
          onTap: () => _showPeriodDialog(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getSelectedIcon(controller.selectedPeriod),
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _getSelectedLabel(controller.selectedPeriod),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getSelectedIcon(String period) {
    switch (period) {
      case 'hoy':
        return Icons.today;
      case 'esta_semana':
        return Icons.view_week;
      case 'este_mes':
        return Icons.calendar_month;
      case 'custom':
        return Icons.tune;
      default:
        return Icons.calendar_today;
    }
  }

  String _getSelectedLabel(String period) {
    switch (period) {
      case 'hoy':
        return 'Hoy';
      case 'esta_semana':
        return 'Esta Semana';
      case 'este_mes':
        return 'Este Mes';
      case 'custom':
        return 'Personalizado';
      default:
        return 'Seleccionar Período';
    }
  }

  // Dialog espectacular para selección de período
  void _showPeriodDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _PeriodSelectionDialog(animation: animation);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

}

// Dialog espectacular con animaciones avanzadas
class _PeriodSelectionDialog extends StatefulWidget {
  final Animation<double> animation;
  
  const _PeriodSelectionDialog({required this.animation});

  @override
  State<_PeriodSelectionDialog> createState() => _PeriodSelectionDialogState();
}

class _PeriodSelectionDialogState extends State<_PeriodSelectionDialog>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador para animación escalonada de items
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Controlador para efecto glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Controladores individuales para cada item
    _itemControllers = List.generate(5, (index) => 
      AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    
    // Animaciones individuales con delay escalonado
    _itemAnimations = _itemControllers.map((controller) => 
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutBack,
        ),
      ),
    ).toList();
    
    // Iniciar animaciones con delay
    _startStaggeredAnimations();
  }
  
  void _startStaggeredAnimations() {
    // Iniciar glow primero
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _glowController.forward();
    });
    
    // Iniciar items con delay escalonado
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 300 + (i * 100)), () {
        if (mounted) _itemControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _glowController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1024;
    
    // Dimensiones responsivas
    final maxWidth = isMobile ? screenSize.width - 32 : (isTablet ? 450.0 : 500.0);
    final maxHeight = isMobile ? screenSize.height * 0.85 : (isTablet ? screenSize.height * 0.8 : 600.0);
    final horizontalMargin = isMobile ? 16.0 : 20.0;
    
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            minHeight: isMobile ? 300 : 400,
          ),
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2 * _glowAnimation.value),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Efecto glow de fondo
                      if (_glowAnimation.value > 0)
                        Positioned.fill(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.topCenter,
                                colors: [
                                  AppColors.primary.withOpacity(0.05 * _glowAnimation.value),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      
                      // Contenido principal con scroll para evitar overflow
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeader(context),
                              SizedBox(height: isMobile ? 16 : 24),
                              _buildPeriodOptions(context),
                              SizedBox(height: isMobile ? 12 : 20),
                              _buildCustomDateSection(context),
                              SizedBox(height: isMobile ? 16 : 24),
                              _buildActionButtons(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    
    return AnimatedBuilder(
      animation: _itemAnimations[0],
      builder: (context, child) {
        return Transform.scale(
          scale: _itemAnimations[0].value.clamp(0.0, 2.0),
          child: Opacity(
            opacity: _itemAnimations[0].value.clamp(0.0, 1.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.access_time,
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
                        'Seleccionar Período',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: isMobile ? 16 : 18,
                        ),
                      ),
                      SizedBox(height: isMobile ? 2 : 4),
                      Text(
                        'Elige el rango de tiempo para el análisis',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPeriodOptions(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    
    final periods = [
      {'key': 'hoy', 'label': 'Hoy', 'icon': Icons.today, 'subtitle': 'Solo el día de hoy'},
      {'key': 'esta_semana', 'label': 'Esta Semana', 'icon': Icons.view_week, 'subtitle': 'Últimos 7 días'},
      {'key': 'este_mes', 'label': 'Este Mes', 'icon': Icons.calendar_month, 'subtitle': 'Todo el mes actual'},
    ];
    
    return GetBuilder<DashboardController>(
      builder: (controller) {
        return Column(
          children: periods.asMap().entries.map((entry) {
            final index = entry.key;
            final period = entry.value;
            
            return AnimatedBuilder(
              animation: _itemAnimations[index + 1],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _itemAnimations[index + 1].value)),
                  child: Opacity(
                    opacity: _itemAnimations[index + 1].value.clamp(0.0, 1.0),
                    child: Container(
                      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                      child: _buildPeriodOption(
                        period['key'] as String,
                        period['label'] as String,
                        period['icon'] as IconData,
                        period['subtitle'] as String,
                        controller.selectedPeriod == period['key'],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildPeriodOption(String key, String label, IconData icon, String subtitle, bool isSelected) {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final isMobile = screenSize.width < 600;
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectPeriod(key),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.05),
                  ],
                )
              : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.textSecondary.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColors.primary
                    : AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: isMobile ? 14 : 16,
                      ),
                      child: Text(label),
                    ),
                    SizedBox(height: isMobile ? 1 : 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: isMobile ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
  
  Widget _buildCustomDateSection(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    
    return AnimatedBuilder(
      animation: _itemAnimations[4],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _itemAnimations[4].value)),
          child: Opacity(
            opacity: _itemAnimations[4].value.clamp(0.0, 1.0),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary?.withOpacity(0.1) ?? AppColors.primary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondary?.withOpacity(0.2) ?? AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: AppColors.secondary ?? AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rango Personalizado',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.secondary ?? AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        SizedBox(height: isMobile ? 1 : 2),
                        Text(
                          'Selecciona fechas específicas',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: isMobile ? 10 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _showDateRangePicker,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary ?? AppColors.primary,
                      side: BorderSide(
                        color: AppColors.secondary ?? AppColors.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Elegir'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Aplicar'),
          ),
        ),
      ],
    );
  }
  
  void _selectPeriod(String period) {
    final controller = Get.find<DashboardController>();
    controller.setPredefinedPeriod(period);
  }
  
  void _showDateRangePicker() async {
    final controller = Get.find<DashboardController>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    DateTimeRange? safeInitialRange;
    if (controller.selectedDateRange != null) {
      final currentRange = controller.selectedDateRange!;
      final safeStart = currentRange.start.isBefore(DateTime(2020)) 
          ? DateTime(2020, 1, 1) 
          : currentRange.start;
      final safeEnd = currentRange.end.isAfter(today) 
          ? today 
          : currentRange.end;
      
      if (!safeStart.isAfter(safeEnd)) {
        safeInitialRange = DateTimeRange(start: safeStart, end: safeEnd);
      }
    }
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: today,
      initialDateRange: safeInitialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setDateRange(picked);
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el dialog después de seleccionar
      }
    }
  }
}