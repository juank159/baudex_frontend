import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_presentation.dart';

/// Dialog que permite elegir en qué presentación se vende un producto
/// (cartón, cajetilla, kilo, paquete, unidad, etc.).
///
/// Devuelve la presentación seleccionada via `Get.back(result: presentation)`
/// o `null` si el usuario cancela.
class PresentationPickerDialog extends StatelessWidget {
  final Product product;
  final List<ProductPresentation> presentations;

  const PresentationPickerDialog({
    super.key,
    required this.product,
    required this.presentations,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width < 480
        ? size.width - 32
        : (size.width < 800 ? 420.0 : 460.0);
    final maxHeight = size.height - 80;

    final active = presentations.where((p) => p.isActive).toList()
      ..sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: ElegantLightTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: active.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    return _PresentationTile(presentation: active[i]);
                  },
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¿Cómo se vende?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Get.back(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: ElegantLightTheme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(
            foregroundColor: ElegantLightTheme.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }
}

class _PresentationTile extends StatelessWidget {
  final ProductPresentation presentation;
  const _PresentationTile({required this.presentation});

  @override
  Widget build(BuildContext context) {
    final isDefault = presentation.isDefault;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.back(result: presentation),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: ElegantLightTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDefault
                  ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.4)
                  : ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
              width: isDefault ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: isDefault
                      ? ElegantLightTheme.primaryGradient
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ElegantLightTheme.surfaceColor,
                            ElegantLightTheme.cardColor,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isDefault
                      ? [
                          BoxShadow(
                            color: ElegantLightTheme.primaryBlue
                                .withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: isDefault
                      ? Colors.white
                      : ElegantLightTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            presentation.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: ElegantLightTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ElegantLightTheme.primaryBlue
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'default',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: ElegantLightTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Factor ${_formatFactor(presentation.factor)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: ElegantLightTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppFormatters.formatCurrency(presentation.price),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.primaryBlueDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: ElegantLightTheme.textTertiary.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra el factor sin decimales innecesarios: 1, 30, 6.5
  String _formatFactor(double factor) {
    if (factor == factor.truncateToDouble()) {
      return factor.toInt().toString();
    }
    return factor.toString();
  }
}
