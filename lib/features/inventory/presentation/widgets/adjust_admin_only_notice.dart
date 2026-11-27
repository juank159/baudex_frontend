// lib/features/inventory/presentation/widgets/adjust_admin_only_notice.dart
//
// Lo que ve en Ajuste de Stock / Ajustes Masivos quien no es administrador
// (si llega por ruta directa o atajo). No hay botón para aplicar.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../breb/presentation/widgets/breb_ui.dart';
import '../../domain/inventory_adjust_permission.dart';

class AdjustAdminOnlyNotice extends StatelessWidget {
  const AdjustAdminOnlyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 600;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(mobile ? 16 : 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: BrebSectionCard(
            key: const ValueKey('adjust-admin-only'),
            icon: Icons.lock_outline,
            gradient: ElegantLightTheme.warningGradient,
            title: 'Ajustar inventario',
            children: [
              const BrebNotice.warning(kAdjustInventoryAdminOnlyMessage),
              const SizedBox(height: 12),
              const Text(
                'Si hace falta corregir unidades, pídeselo al administrador.',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment:
                    mobile ? Alignment.center : Alignment.centerRight,
                child: SizedBox(
                  width: mobile ? double.infinity : null,
                  child: OutlinedButton.icon(
                    key: const ValueKey('adjust-admin-only-back'),
                    style: brebSecondaryButtonStyle(),
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Volver'),
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
