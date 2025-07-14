// lib/features/products/presentation/widgets/modern_selector_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label moderno
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: ResponsiveHelper.isMobile(context) ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.isMobile(context) ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                  ),
                ),
            ],
          ),
        ),

        // Selector moderno
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  enabled
                      ? (value != null
                          ? Theme.of(context).primaryColor.withOpacity(0.5)
                          : Colors.grey.shade300)
                      : Colors.grey.shade200,
              width: value != null ? 1.5 : 1,
            ),
            color: Colors.white,
            boxShadow: [
              if (value != null)
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? () => _showSelector(context) : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(
                  ResponsiveHelper.isMobile(context) ? 12 : 16,
                ),
                child: Row(
                  children: [
                    // Icono del valor seleccionado o por defecto (sin fondo)
                    value != null && getIcon != null
                        ? getIcon!(value!)
                        : Icon(
                          Icons.tune,
                          size: 18,
                          color:
                              value != null
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade400,
                        ),
                    const SizedBox(width: 12),

                    // Texto del valor seleccionado
                    Expanded(
                      child: Text(
                        value != null ? getDisplayText(value!) : hint,
                        style: TextStyle(
                          fontSize:
                              ResponsiveHelper.isMobile(context) ? 14 : 16,
                          fontWeight:
                              value != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                          color:
                              enabled
                                  ? (value != null
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade500)
                                  : Colors.grey.shade400,
                        ),
                      ),
                    ),

                    // Icono de dropdown
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color:
                          enabled ? Colors.grey.shade600 : Colors.grey.shade400,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * 300),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
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
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.tune,
                          size: 20,
                          color: Theme.of(context).primaryColor,
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
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade600,
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
                                color:
                                    isSelected
                                        ? Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade200,
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
                                                ? Theme.of(context).primaryColor
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
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),

                                  // Indicador de selección
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
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
    );
  }
}
