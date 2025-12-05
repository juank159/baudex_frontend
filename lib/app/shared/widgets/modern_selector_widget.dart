// lib/app/shared/widgets/modern_selector_widget.dart
import 'package:flutter/material.dart';
import '../../core/utils/responsive_helper.dart';
import '../../core/theme/elegant_light_theme.dart';

/// Widget selector moderno con bottom sheet animado
/// Usado para reemplazar dropdowns tradicionales con una experiencia más elegante
class ModernSelectorWidget<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) getDisplayText;
  final Widget Function(T)? getIcon;
  final String Function(T)? getDescription;
  final Function(T?) onChanged;
  final bool isRequired;
  final String? Function(T?)? validator;
  final bool enabled;
  final IconData? leadingIcon;
  final LinearGradient? iconGradient;

  const ModernSelectorWidget({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.getDisplayText,
    required this.onChanged,
    this.getIcon,
    this.getDescription,
    this.isRequired = false,
    this.validator,
    this.enabled = true,
    this.leadingIcon,
    this.iconGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _showSelector(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // Altura mínima para coincidir con TextField
          constraints: BoxConstraints(
            minHeight: isMobile ? 44 : 48,
          ),
          // Padding igual al TextField
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            // Mismo estilo que TextFields: fondo blanco, borde gris
            color: enabled ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              // Icono con gradiente - más compacto en desktop
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 6),
                decoration: BoxDecoration(
                  gradient:
                      enabled
                          ? (iconGradient ?? ElegantLightTheme.primaryGradient)
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
                          leadingIcon ?? Icons.tune,
                          color: Colors.white,
                          size: isMobile ? 16 : 18,
                        ),
              ),
              SizedBox(width: isMobile ? 10 : 12),

              // Layout diferente para mobile vs desktop/tablet
              Expanded(
                child: isMobile
                    // Mobile: Label arriba, valor abajo (vertical)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$label${isRequired ? ' *' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value != null ? getDisplayText(value as T) : hint,
                            style: TextStyle(
                              fontSize: 14,
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
                      )
                    // Desktop/Tablet: Todo en una fila (horizontal)
                    : Row(
                        children: [
                          Text(
                            '$label${isRequired ? ' *' : ''}:',
                            style: TextStyle(
                              fontSize: 14,
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              value != null ? getDisplayText(value as T) : hint,
                              style: TextStyle(
                                fontSize: 14,
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
                          ),
                        ],
                      ),
              ),

              // Icono de dropdown - compacto
              Container(
                padding: EdgeInsets.all(isMobile ? 4 : 4),
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
                  Icons.keyboard_arrow_down_rounded,
                  color:
                      enabled
                          ? ElegantLightTheme.primaryBlue
                          : ElegantLightTheme.textTertiary,
                  size: isMobile ? 18 : 20,
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
            getDescription: getDescription,
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
  final String Function(T)? getDescription;
  final Function(T) onSelected;

  const _ModernSelectorBottomSheet({
    required this.title,
    required this.items,
    required this.currentValue,
    required this.getDisplayText,
    required this.onSelected,
    this.getIcon,
    this.getDescription,
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
    final isMobile = ResponsiveHelper.isMobile(context);

    return SafeArea(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _animation.value) * 300),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              margin: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: ElegantLightTheme.elevatedShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient.scale(0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: ElegantLightTheme.glowShadow,
                          ),
                          child: const Icon(
                            Icons.checklist_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seleccionar ${widget.title}',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: ElegantLightTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.items.length} opciones disponibles',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ElegantLightTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ElegantLightTheme.textTertiary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: ElegantLightTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de opciones
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                                padding: EdgeInsets.all(isMobile ? 14 : 16),
                                decoration: BoxDecoration(
                                  gradient:
                                      isSelected
                                          ? LinearGradient(
                                            colors: [
                                              ElegantLightTheme.primaryBlue
                                                  .withValues(alpha: 0.12),
                                              ElegantLightTheme.primaryBlueLight
                                                  .withValues(alpha: 0.06),
                                            ],
                                          )
                                          : null,
                                  color:
                                      isSelected
                                          ? null
                                          : ElegantLightTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? ElegantLightTheme.primaryBlue
                                            : ElegantLightTheme.textTertiary
                                                .withValues(alpha: 0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: ElegantLightTheme
                                                  .primaryBlue
                                                  .withValues(alpha: 0.15),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Row(
                                  children: [
                                    // Icono
                                    if (widget.getIcon != null)
                                      Container(
                                        margin: const EdgeInsets.only(right: 14),
                                        child: widget.getIcon!(item),
                                      )
                                    else
                                      Container(
                                        margin: const EdgeInsets.only(right: 14),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient:
                                              isSelected
                                                  ? ElegantLightTheme
                                                      .primaryGradient
                                                  : ElegantLightTheme
                                                      .cardGradient,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          size: 18,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : ElegantLightTheme
                                                      .textTertiary,
                                        ),
                                      ),

                                    // Texto
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.getDisplayText(item),
                                            style: TextStyle(
                                              fontSize: isMobile ? 14 : 15,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                              color:
                                                  isSelected
                                                      ? ElegantLightTheme
                                                          .primaryBlue
                                                      : ElegantLightTheme
                                                          .textPrimary,
                                            ),
                                          ),
                                          if (widget.getDescription != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              widget.getDescription!(item),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: ElegantLightTheme
                                                    .textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Indicador de seleccion
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          gradient:
                                              ElegantLightTheme.primaryGradient,
                                          shape: BoxShape.circle,
                                          boxShadow:
                                              ElegantLightTheme.glowShadow,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 14,
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

                  // Padding inferior
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
