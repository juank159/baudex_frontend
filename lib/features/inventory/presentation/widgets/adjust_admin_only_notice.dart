// lib/features/inventory/presentation/widgets/adjust_admin_only_notice.dart
//
// Lo que ve en Ajuste de Stock / Ajustes Masivos (y en movimiento manual e
// inventario inicial) quien no es administrador, si llega por ruta directa o
// atajo. No hay botón para aplicar.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/routes/app_routes.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../breb/presentation/widgets/breb_ui.dart';
import '../../domain/inventory_adjust_permission.dart';

class AdjustAdminOnlyNotice extends StatelessWidget {
  const AdjustAdminOnlyNotice({
    super.key,
    this.title = 'Ajustar inventario',
    this.message = kAdjustInventoryAdminOnlyMessage,
    this.hint = 'Si hace falta corregir unidades, pídeselo al administrador.',
    this.inDialog = false,
  });

  /// Aviso para movimiento manual e inventario inicial.
  const AdjustAdminOnlyNotice.manualMovement({
    super.key,
    this.inDialog = false,
    this.title = 'Entradas y salidas a mano',
    this.message = kManualMovementAdminOnlyMessage,
    this.hint =
        'Las ventas, compras y traslados siguen moviendo el stock solos. '
        'Si hace falta corregir unidades, pídeselo al administrador.',
  });

  final String title;
  final String message;
  final String hint;

  /// Dentro de un diálogo: solo la tarjeta, del alto de su contenido.
  final bool inDialog;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 600;
    final card = _card(context, mobile);
    if (inDialog) return card;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(mobile ? 16 : 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: card,
        ),
      ),
    );
  }

  Widget _card(BuildContext context, bool mobile) {
    return BrebSectionCard(
      key: const ValueKey('adjust-admin-only'),
      icon: Icons.lock_outline,
      gradient: ElegantLightTheme.warningGradient,
      title: title,
      children: [
        BrebNotice.warning(message),
        const SizedBox(height: 12),
        Text(
          hint,
          style: const TextStyle(
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
              // Desde el menú la pantalla queda sola (no hay a dónde
              // volver): se va al inicio.
              onPressed: () => Navigator.of(context).canPop()
                  ? Get.back()
                  : Get.offAllNamed(AppRoutes.dashboard),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Volver'),
            ),
          ),
        ),
      ],
    );
  }
}
