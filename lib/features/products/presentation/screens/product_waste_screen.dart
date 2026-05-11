// lib/features/products/presentation/screens/product_waste_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/product_waste_controller.dart';

class ProductWasteScreen extends GetView<ProductWasteController> {
  const ProductWasteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWarningBanner(),
                const SizedBox(height: 16),
                _buildFormCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.red.shade700, Colors.red.shade500],
          ),
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
              'Registrar merma',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
    );
  }

  // ==================== WARNING BANNER ====================

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'La cantidad se descontará del stock. Esta acción no se puede deshacer.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FORM CARD ====================

  Widget _buildFormCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product info header
            _buildProductInfo(),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Quantity field
            _buildSectionLabel('Cantidad a descontar *'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.quantityCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Ej: 250.5',
                prefixIcon: const Icon(Icons.remove_circle_outline,
                    color: ElegantLightTheme.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Reason field
            _buildSectionLabel('Razón de la merma *'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.reasonCtrl,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText:
                    'Ej: Pérdida de agua, Producto vencido, Rotura, Burusas al cortar',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.notes_outlined,
                      color: ElegantLightTheme.textSecondary),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            Obx(
              () => SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed:
                      controller.isLoading.value ? null : controller.submit,
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_sweep_outlined, size: 20),
                  label: Text(
                    controller.isLoading.value
                        ? 'Registrando...'
                        : 'Registrar merma',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PRODUCT INFO ====================

  Widget _buildProductInfo() {
    return Obx(() {
      final name = controller.productName.value;
      final stock = controller.currentStock.value;

      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Icon(Icons.inventory_2_outlined,
                color: Colors.red.shade700, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Producto',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.layers_outlined,
                        size: 14,
                        color: ElegantLightTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Stock actual: ${AppFormatters.formatStock(stock)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ElegantLightTheme.textPrimary,
      ),
    );
  }
}
