// lib/features/products/presentation/widgets/modern_selector_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';

class ModernSelectorWidget<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) getDisplayText;
  final Widget Function(T)? getIcon;
  final Function(T?) onChanged;
  final bool isRequired;
  final String? Function(T?)? validator;
  final bool enabled;

  const ModernSelectorWidget({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.getDisplayText,
    required this.onChanged,
    this.getIcon,
    this.isRequired = false,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _showSelector(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: FuturisticContainer(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          gradient:
              enabled
                  ? ElegantLightTheme.cardGradient
                  : LinearGradient(
                    colors: [Colors.grey.shade100, Colors.grey.shade200],
                  ),
          child: Row(
            children: [
              // Icono con gradiente (igual que CategorySelector)
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  gradient:
                      enabled
                          ? ElegantLightTheme.infoGradient
                          : LinearGradient(
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade400,
                            ],
                          ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: enabled ? ElegantLightTheme.glowShadow : null,
                ),
                child:
                    value != null && getIcon != null
                        ? getIcon!(value as T)
                        : Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: isMobile ? 18 : 20,
                        ),
              ),
              SizedBox(width: isMobile ? 10 : 12),

              // Column con label y valor (igual que CategorySelector)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$label${isRequired ? ' *' : ''}',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: ElegantLightTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value != null ? getDisplayText(value as T) : hint,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color:
                            value != null
                                ? ElegantLightTheme.textPrimary
                                : ElegantLightTheme.textTertiary,
                        fontWeight:
                            value != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              // Icono de dropdown (igual que CategorySelector)
              Container(
                padding: EdgeInsets.all(isMobile ? 3 : 4),
                decoration: BoxDecoration(
                  color:
                      enabled
                          ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.1)
                          : ElegantLightTheme.textTertiary.withValues(
                            alpha: 0.1,
                          ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.arrow_drop_down,
                  color:
                      enabled
                          ? ElegantLightTheme.primaryBlue
                          : ElegantLightTheme.textTertiary,
                  size: isMobile ? 20 : 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _ModernSelectorBottomSheet<T>(
            title: label,
            items: items,
            currentValue: value,
            getDisplayText: getDisplayText,
            getIcon: getIcon,
            onSelected: (selectedValue) {
              onChanged(selectedValue);
              Navigator.pop(context);
            },
          ),
    );
  }
}

class _ModernSelectorBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? currentValue;
  final String Function(T) getDisplayText;
  final Widget Function(T)? getIcon;
  final Function(T) onSelected;

  const _ModernSelectorBottomSheet({
    required this.title,
    required this.items,
    required this.currentValue,
    required this.getDisplayText,
    required this.onSelected,
    this.getIcon,
  });

  @override
  State<_ModernSelectorBottomSheet<T>> createState() =>
      _ModernSelectorBottomSheetState<T>();
}

class _ModernSelectorBottomSheetState<T>
    extends State<_ModernSelectorBottomSheet<T>>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return SafeArea(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _animation.value) * 300),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: ElegantLightTheme.elevatedShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: ElegantLightTheme.glowShadow,
                          ),
                          child: const Icon(
                            Icons.tune,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Seleccionar ${widget.title}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: ElegantLightTheme.textTertiary
                                .withOpacity(0.1),
                            foregroundColor: ElegantLightTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de opciones
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final isSelected = item == widget.currentValue;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => widget.onSelected(item),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient:
                                      isSelected
                                          ? LinearGradient(
                                            colors: [
                                              ElegantLightTheme.primaryBlue
                                                  .withOpacity(0.1),
                                              ElegantLightTheme.primaryBlueLight
                                                  .withOpacity(0.05),
                                            ],
                                          )
                                          : null,
                                  color: isSelected ? null : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? ElegantLightTheme.primaryBlue
                                            : ElegantLightTheme.textTertiary
                                                .withOpacity(0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Icono (sin fondo)
                                    widget.getIcon != null
                                        ? widget.getIcon!(item)
                                        : Icon(
                                          Icons.check_circle_outline,
                                          size: 18,
                                          color:
                                              isSelected
                                                  ? Theme.of(
                                                    context,
                                                  ).primaryColor
                                                  : Colors.grey.shade600,
                                        ),
                                    const SizedBox(width: 16),

                                    // Texto
                                    Expanded(
                                      child: Text(
                                        widget.getDisplayText(item),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                          color:
                                              isSelected
                                                  ? Theme.of(
                                                    context,
                                                  ).primaryColor
                                                  : Colors.grey.shade800,
                                        ),
                                      ),
                                    ),

                                    // Indicador de selección
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          gradient:
                                              ElegantLightTheme.primaryGradient,
                                          shape: BoxShape.circle,
                                          boxShadow:
                                              ElegantLightTheme.glowShadow,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Padding inferior para el gesto
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
