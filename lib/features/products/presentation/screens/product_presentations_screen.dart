// lib/features/products/presentation/screens/product_presentations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../../domain/entities/product_presentation.dart';
import '../controllers/product_presentations_controller.dart';

class ProductPresentationsScreen
    extends GetView<ProductPresentationsController> {
  const ProductPresentationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (controller.errorMessage.value.isNotEmpty &&
            !controller.hasPresentations) {
          return _buildErrorState(context);
        }
        if (!controller.hasPresentations) {
          return _buildEmptyState(context);
        }
        return _buildList(context);
      }),
      // FAB adaptativo: mobile = redondo con sólo ícono; tablet/desktop
      // = extended con etiqueta (hay espacio de sobra). El patrón
      // estándar de Material 3 — un FAB con texto en mobile se ve
      // apretado y no respeta el tap target.
      floatingActionButton: _buildResponsiveFab(
        context,
        icon: Icons.add,
        label: 'Nueva Presentación',
        tooltip: 'Nueva presentación',
        onPressed: () => _showPresentationForm(context),
      ),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      title: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Presentaciones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            if (controller.productName.value.isNotEmpty)
              Text(
                controller.productName.value,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.loadPresentations,
          tooltip: 'Actualizar',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ==================== STATES ====================

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.view_list_outlined,
                size: 56,
                color: ElegantLightTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin presentaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega presentaciones para este producto\n(ej: unidad, caja, docena)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showPresentationForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar presentación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: ElegantLightTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Obx(
              () => Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.loadPresentations,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LIST ====================

  Widget _buildList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadPresentations,
      color: ElegantLightTheme.primaryBlue,
      child: Obx(
        () => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: controller.presentations.length,
          itemBuilder: (context, index) {
            final presentation = controller.presentations[index];
            return _PresentationCard(
              presentation: presentation,
              onEdit: () => _showPresentationForm(context, presentation),
              onDelete: () => _confirmDelete(context, presentation),
            );
          },
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _buildResponsiveFab(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: ElegantLightTheme.primaryBlue,
        tooltip: tooltip,
        child: Icon(icon, color: Colors.white),
      );
    }
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: ElegantLightTheme.primaryBlue,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showPresentationForm(
    BuildContext context, [
    ProductPresentation? existing,
  ]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PresentationFormDialog(
        existing: existing,
        onSave: (data) async {
          bool success;
          if (existing == null) {
            success = await controller.createPresentation(
              name: data['name'] as String,
              factor: data['factor'] as double,
              price: data['price'] as double,
              barcode: data['barcode'] as String?,
              sku: data['sku'] as String?,
              isDefault: data['isDefault'] as bool,
              isActive: data['isActive'] as bool,
            );
          } else {
            success = await controller.updatePresentation(
              id: existing.id,
              name: data['name'] as String,
              factor: data['factor'] as double,
              price: data['price'] as double,
              barcode: data['barcode'] as String?,
              sku: data['sku'] as String?,
              isDefault: data['isDefault'] as bool,
              isActive: data['isActive'] as bool,
            );
          }
          if (success) {
            if (ctx.mounted) Navigator.of(ctx).pop();
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductPresentation presentation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Eliminar presentación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Eliminar "${presentation.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ElegantLightTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.deletePresentation(presentation.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ==================== PRESENTATION CARD ====================

class _PresentationCard extends StatelessWidget {
  final ProductPresentation presentation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PresentationCard({
    required this.presentation,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: presentation.isDefault
            ? const BorderSide(
                color: ElegantLightTheme.primaryBlue,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ElegantLightTheme.primaryBlue
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    presentation.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: ElegantLightTheme.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (presentation.isDefault) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ElegantLightTheme.primaryBlue,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Principal',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!presentation.isActive)
                              const Text(
                                'Inactiva',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ElegantLightTheme.errorRed,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                      onPressed: onEdit,
                      tooltip: 'Editar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: ElegantLightTheme.errorRed,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Eliminar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Data row
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _InfoChip(
                  icon: Icons.straighten,
                  label: 'Factor',
                  value: '×${presentation.factor}',
                  color: const Color(0xFF7C3AED),
                ),
                _InfoChip(
                  icon: Icons.attach_money,
                  label: 'Precio',
                  value:
                      '${presentation.currency} ${_formatPrice(presentation.price)}',
                  color: ElegantLightTheme.successGreen,
                ),
                if (presentation.barcode != null &&
                    presentation.barcode!.isNotEmpty)
                  _InfoChip(
                    icon: Icons.qr_code,
                    label: 'Código',
                    value: presentation.barcode!,
                    color: ElegantLightTheme.textSecondary,
                  ),
                if (presentation.sku != null && presentation.sku!.isNotEmpty)
                  _InfoChip(
                    icon: Icons.tag,
                    label: 'SKU',
                    value: presentation.sku!,
                    color: ElegantLightTheme.textSecondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    // Format with thousands separator
    final parts = price.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PRESENTATION FORM DIALOG ====================

class _PresentationFormDialog extends StatefulWidget {
  final ProductPresentation? existing;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _PresentationFormDialog({
    this.existing,
    required this.onSave,
  });

  @override
  State<_PresentationFormDialog> createState() =>
      _PresentationFormDialogState();
}

class _PresentationFormDialogState extends State<_PresentationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _factorController;
  late final TextEditingController _priceController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _skuController;
  late bool _isDefault;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _factorController =
        TextEditingController(text: e != null ? e.factor.toString() : '1');
    // Al editar, mostrar el precio ya formateado con separador de
    // miles para que sea consistente con lo que el usuario escribe.
    _priceController = TextEditingController(
      text: e != null ? AppFormatters.formatNumber(e.price) : '',
    );
    _barcodeController = TextEditingController(text: e?.barcode ?? '');
    _skuController = TextEditingController(text: e?.sku ?? '');
    _isDefault = e?.isDefault ?? false;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _factorController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEditing ? Icons.edit : Icons.add,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Editar presentación' : 'Nueva presentación',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  controller: _nameController,
                  label: 'Nombre *',
                  hint: 'Ej: Caja, Docena, Unidad',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    if (v.trim().length > 50) {
                      return 'Máximo 50 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _factorController,
                        label: 'Factor *',
                        hint: 'Ej: 12 (para docena)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Requerido';
                          }
                          final n = double.tryParse(v.trim());
                          if (n == null || n <= 0) {
                            return 'Debe ser > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _priceController,
                        label: 'Precio *',
                        hint: 'Ej: 18.000',
                        keyboardType: TextInputType.number,
                        // Formateador con separador de miles (mismo
                        // patrón que el form de productos y la lista
                        // de precios — coherencia visual con el resto
                        // de la app).
                        inputFormatters: [PriceInputFormatter()],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Requerido';
                          }
                          final n = AppFormatters.parseNumber(v);
                          if (n == null || n < 0) {
                            return 'Debe ser >= 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _barcodeController,
                  label: 'Código de barras',
                  hint: 'Opcional',
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _skuController,
                  label: 'SKU',
                  hint: 'Opcional',
                ),
                const SizedBox(height: 16),
                // Toggles
                _buildToggleRow(
                  label: 'Presentación principal',
                  subtitle: 'Solo una puede ser principal',
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
                const SizedBox(height: 4),
                _buildToggleRow(
                  label: 'Activa',
                  subtitle: 'Disponible para venta',
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: ElegantLightTheme.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      validator: validator,
    );
  }

  Widget _buildToggleRow({
    required String label,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: ElegantLightTheme.primaryBlue,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await widget.onSave({
        'name': _nameController.text.trim(),
        'factor': double.parse(_factorController.text.trim()),
        // Usar `AppFormatters.parseNumber` porque el TextField muestra
        // el precio con separadores de miles ("18.000") y `double.parse`
        // los rompería.
        'price': AppFormatters.parseNumber(_priceController.text) ?? 0,
        'barcode': _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        'sku': _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        'isDefault': _isDefault,
        'isActive': _isActive,
      });
    } catch (e) {
      AppLogger.e('Error al guardar presentación: $e', tag: 'PresentationForm');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
