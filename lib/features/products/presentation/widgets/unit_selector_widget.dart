// lib/features/products/presentation/widgets/unit_selector_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import 'modern_selector_widget.dart';

enum MeasurementUnit {
  pieces,
  kilogram,
  gram,
  liter,
  milliliter,
  halfDozen,
  dozen,
  basket,
  bundle,
  box,
  package,
}

extension MeasurementUnitExtension on MeasurementUnit {
  String get displayName {
    switch (this) {
      case MeasurementUnit.pieces:
        return 'Piezas (pcs)';
      case MeasurementUnit.kilogram:
        return 'Kilogramos (kg)';
      case MeasurementUnit.gram:
        return 'Gramos (gr)';
      case MeasurementUnit.liter:
        return 'Litros (L)';
      case MeasurementUnit.milliliter:
        return 'Mililitros (ml)';
      case MeasurementUnit.halfDozen:
        return 'Media Docena (1/2 doc)';
      case MeasurementUnit.dozen:
        return 'Docena (doc)';
      case MeasurementUnit.basket:
        return 'Canasta';
      case MeasurementUnit.bundle:
        return 'Fardo';
      case MeasurementUnit.box:
        return 'Caja';
      case MeasurementUnit.package:
        return 'Paquete';
    }
  }

  String get shortName {
    switch (this) {
      case MeasurementUnit.pieces:
        return 'pcs';
      case MeasurementUnit.kilogram:
        return 'kg';
      case MeasurementUnit.gram:
        return 'gr';
      case MeasurementUnit.liter:
        return 'L';
      case MeasurementUnit.milliliter:
        return 'ml';
      case MeasurementUnit.halfDozen:
        return '1/2 doc';
      case MeasurementUnit.dozen:
        return 'doc';
      case MeasurementUnit.basket:
        return 'canasta';
      case MeasurementUnit.bundle:
        return 'fardo';
      case MeasurementUnit.box:
        return 'caja';
      case MeasurementUnit.package:
        return 'paquete';
    }
  }

  IconData get icon {
    switch (this) {
      case MeasurementUnit.pieces:
        return Icons.inventory_2_outlined;
      case MeasurementUnit.kilogram:
      case MeasurementUnit.gram:
        return Icons.fitness_center;
      case MeasurementUnit.liter:
      case MeasurementUnit.milliliter:
        return Icons.local_drink_outlined;
      case MeasurementUnit.halfDozen:
      case MeasurementUnit.dozen:
        return Icons.apps;
      case MeasurementUnit.basket:
        return Icons.shopping_basket_outlined;
      case MeasurementUnit.bundle:
        return Icons.all_inclusive;
      case MeasurementUnit.box:
        return Icons.inventory_outlined;
      case MeasurementUnit.package:
        return Icons.card_giftcard_outlined;
    }
  }

  Color get color {
    switch (this) {
      case MeasurementUnit.pieces:
        return Colors.blue;
      case MeasurementUnit.kilogram:
      case MeasurementUnit.gram:
        return Colors.orange;
      case MeasurementUnit.liter:
      case MeasurementUnit.milliliter:
        return Colors.cyan;
      case MeasurementUnit.halfDozen:
      case MeasurementUnit.dozen:
        return Colors.purple;
      case MeasurementUnit.basket:
        return Colors.brown;
      case MeasurementUnit.bundle:
        return Colors.green;
      case MeasurementUnit.box:
        return Colors.indigo;
      case MeasurementUnit.package:
        return Colors.pink;
    }
  }

  String get category {
    switch (this) {
      case MeasurementUnit.pieces:
        return 'Cantidad';
      case MeasurementUnit.kilogram:
      case MeasurementUnit.gram:
        return 'Peso';
      case MeasurementUnit.liter:
      case MeasurementUnit.milliliter:
        return 'Volumen';
      case MeasurementUnit.halfDozen:
      case MeasurementUnit.dozen:
        return 'Agrupación';
      case MeasurementUnit.basket:
      case MeasurementUnit.bundle:
      case MeasurementUnit.box:
      case MeasurementUnit.package:
        return 'Empaque';
    }
  }
}

// Función helper fuera de la extensión
MeasurementUnit? getMeasurementUnitFromShortName(String shortName) {
  for (var unit in MeasurementUnit.values) {
    if (unit.shortName.toLowerCase() == shortName.toLowerCase()) {
      return unit;
    }
  }
  return null;
}

class UnitSelectorWidget extends StatelessWidget {
  final MeasurementUnit? value;
  final Function(MeasurementUnit?) onChanged;
  final bool isRequired;
  final String? Function(MeasurementUnit?)? validator;
  final bool enabled;

  const UnitSelectorWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModernSelectorWidget<MeasurementUnit>(
      label: 'Unidad de Medida',
      hint: 'Seleccionar unidad',
      value: value,
      items: MeasurementUnit.values,
      getDisplayText: (unit) => unit.displayName,
      getIcon: (unit) => Icon(unit.icon, size: 18, color: unit.color),
      onChanged: onChanged,
      isRequired: isRequired,
      validator: validator,
      enabled: enabled,
    );
  }
}

// Widget mejorado del bottom sheet para mostrar unidades por categoría
class EnhancedUnitSelectorWidget extends StatelessWidget {
  final MeasurementUnit? value;
  final Function(MeasurementUnit?) onChanged;
  final bool isRequired;
  final String? Function(MeasurementUnit?)? validator;
  final bool enabled;

  const EnhancedUnitSelectorWidget({
    super.key,
    required this.value,
    required this.onChanged,
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
                'Unidad de Medida',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 14,
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
            color: enabled ? Colors.white : Colors.grey.shade50,
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
              onTap: enabled ? () => _showEnhancedSelector(context) : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical:
                      ResponsiveHelper.isMobile(context)
                          ? 20
                          : 16, // Más altura en móvil
                ),
                child: Row(
                  children: [
                    // Icono del valor seleccionado o por defecto (sin fondo)
                    Icon(
                      value?.icon ?? Icons.straighten,
                      size: 18,
                      color: value?.color ?? Colors.grey.shade400,
                    ),
                    const SizedBox(width: 12),

                    // Texto del valor seleccionado
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value?.displayName ?? 'Seleccionar unidad',
                            style: TextStyle(
                              fontSize: 16,
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
                          if (value != null)
                            Text(
                              value!.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: value!.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
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

  void _showEnhancedSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _EnhancedUnitSelectorBottomSheet(
            currentValue: value,
            onSelected: (selectedValue) {
              onChanged(selectedValue);
              Navigator.pop(context);
            },
          ),
    );
  }
}

class _EnhancedUnitSelectorBottomSheet extends StatefulWidget {
  final MeasurementUnit? currentValue;
  final Function(MeasurementUnit) onSelected;

  const _EnhancedUnitSelectorBottomSheet({
    required this.currentValue,
    required this.onSelected,
  });

  @override
  State<_EnhancedUnitSelectorBottomSheet> createState() =>
      _EnhancedUnitSelectorBottomSheetState();
}

class _EnhancedUnitSelectorBottomSheetState
    extends State<_EnhancedUnitSelectorBottomSheet>
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

  Map<String, List<MeasurementUnit>> get unitsByCategory {
    final Map<String, List<MeasurementUnit>> grouped = {};
    for (var unit in MeasurementUnit.values) {
      final category = unit.category;
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(unit);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

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
                          Icons.straighten,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Seleccionar Unidad de Medida',
                          style: TextStyle(
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

                // Lista de categorías y unidades
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: unitsByCategory.keys.length,
                    itemBuilder: (context, index) {
                      final category = unitsByCategory.keys.elementAt(index);
                      final units = unitsByCategory[category]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header de categoría
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                bottom: 8,
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),

                            // Grid de unidades
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio:
                                        1.4, // Aumentado para evitar overflow
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: units.length,
                              itemBuilder: (context, unitIndex) {
                                final unit = units[unitIndex];
                                final isSelected = unit == widget.currentValue;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => widget.onSelected(unit),
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? unit.color.withOpacity(0.1)
                                                : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? unit.color
                                                  : Colors.grey.shade200,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? unit.color
                                                      : unit.color.withOpacity(
                                                        0.1,
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              unit.icon,
                                              size: 16,
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : unit.color,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  unit.shortName,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        isSelected
                                                            ? unit.color
                                                            : Colors
                                                                .grey
                                                                .shade800,
                                                  ),
                                                ),
                                                Text(
                                                  unit.displayName
                                                      .split('(')[0]
                                                      .trim(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: unit.color,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
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
