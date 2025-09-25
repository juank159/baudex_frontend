// lib/features/purchase_orders/presentation/widgets/futuristic_purchase_order_widgets.dart
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/animations/stats_animations.dart';
import '../../domain/entities/purchase_order.dart';

// Widget para mostrar el estado con animación 3D
class FuturisticStatusChip extends StatefulWidget {
  final PurchaseOrderStatus status;
  final double? size;

  const FuturisticStatusChip({Key? key, required this.status, this.size})
    : super(key: key);

  @override
  State<FuturisticStatusChip> createState() => _FuturisticStatusChipState();
}

class _FuturisticStatusChipState extends State<FuturisticStatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  LinearGradient _getStatusGradient() {
    switch (widget.status) {
      case PurchaseOrderStatus.draft:
        return const LinearGradient(
          colors: [Color(0xFF64748B), Color(0xFF475569)],
        );
      case PurchaseOrderStatus.pending:
        return ElegantLightTheme.warningGradient;
      case PurchaseOrderStatus.approved:
        return ElegantLightTheme.infoGradient;
      case PurchaseOrderStatus.sent:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
      case PurchaseOrderStatus.partiallyReceived:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
      case PurchaseOrderStatus.received:
        return ElegantLightTheme.successGradient;
      case PurchaseOrderStatus.rejected:
      case PurchaseOrderStatus.cancelled:
        return ElegantLightTheme.errorGradient;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case PurchaseOrderStatus.draft:
        return Icons.edit_note;
      case PurchaseOrderStatus.pending:
        return Icons.schedule;
      case PurchaseOrderStatus.approved:
        return Icons.check_circle;
      case PurchaseOrderStatus.sent:
        return Icons.send;
      case PurchaseOrderStatus.partiallyReceived:
        return Icons.pending_actions;
      case PurchaseOrderStatus.received:
        return Icons.inventory;
      case PurchaseOrderStatus.rejected:
        return Icons.cancel;
      case PurchaseOrderStatus.cancelled:
        return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale:
              widget.status == PurchaseOrderStatus.pending
                  ? _pulseAnimation.value
                  : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: (widget.size ?? 1) * 12,
              vertical: (widget.size ?? 1) * 6,
            ),
            decoration: BoxDecoration(
              gradient: _getStatusGradient(),
              borderRadius: BorderRadius.circular((widget.size ?? 1) * 20),
              boxShadow: [
                BoxShadow(
                  color: _getStatusGradient().colors.first.withOpacity(0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(),
                  color: Colors.white,
                  size: (widget.size ?? 1) * 16,
                ),
                SizedBox(width: (widget.size ?? 1) * 6),
                Text(
                  widget.status.displayStatus,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (widget.size ?? 1) * 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Card futurista para items de orden de compra
class FuturisticItemCard extends StatefulWidget {
  final PurchaseOrderItem item;
  final VoidCallback? onTap;

  const FuturisticItemCard({Key? key, required this.item, this.onTap})
    : super(key: key);

  @override
  State<FuturisticItemCard> createState() => _FuturisticItemCardState();
}

class _FuturisticItemCardState extends State<FuturisticItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.elasticCurve,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: FuturisticContainer(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icono del producto con efecto holográfico
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: ElegantLightTheme.glowShadow,
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: ElegantLightTheme.textPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Información del producto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.productName,
                              style: const TextStyle(
                                color: ElegantLightTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Progreso de recepción horizontal con estilo mejorado como cronología de eficiencia
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progreso de recepción',
                                      style: const TextStyle(
                                        color: ElegantLightTheme.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${widget.item.receivedPercentage.toInt()}%',
                                      style: TextStyle(
                                        color: ElegantLightTheme.textTertiary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Barra horizontal que muestra claramente la parte llena vs vacía con destello
                                Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: ElegantLightTheme.textSecondary.withOpacity(0.15), // Fondo más visible
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: ElegantLightTheme.textSecondary.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: widget.item.receivedPercentage / 100),
                                    duration: Duration(milliseconds: 800),
                                    curve: Curves.easeOutExpo,
                                    builder: (context, animatedValue, child) {
                                      return Row(
                                        children: [
                                          // Parte llena con destello
                                          if (animatedValue > 0)
                                            Flexible(
                                              flex: (animatedValue * 100).round(),
                                              child: Container(
                                                height: 10,
                                                margin: EdgeInsets.all(1),
                                                decoration: BoxDecoration(
                                                  gradient: widget.item.isFullyReceived
                                                      ? ElegantLightTheme.successGradient
                                                      : widget.item.isPartiallyReceived
                                                      ? ElegantLightTheme.warningGradient
                                                      : ElegantLightTheme.infoGradient,
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(5),
                                                  child: Stack(
                                                    children: [
                                                      // Efecto de destello cuando está casi completa
                                                      if (animatedValue >= widget.item.receivedPercentage / 100 * 0.98)
                                                        _ProgressShimmerEffect(
                                                          borderRadius: 5,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // Parte vacía
                                          if (animatedValue < 1.0)
                                            Flexible(
                                              flex: ((1.0 - animatedValue) * 100).round(),
                                              child: Container(
                                                height: 10,
                                                margin: EdgeInsets.all(1),
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Información detallada en grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ElegantLightTheme.textSecondary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        
                        // Determinar qué campos adicionales mostrar según el caso
                        final List<Widget> infoItems = [
                          _buildInfoItem(
                            'Cantidad',
                            AppFormatters.formatNumber(widget.item.quantity),
                            Icons.format_list_numbered,
                            screenWidth,
                          ),
                          _buildInfoItem(
                            'Recibido',
                            AppFormatters.formatNumber(widget.item.receivedQuantity ?? 0),
                            Icons.check_circle,
                            screenWidth,
                          ),
                        ];

                        // Mostrar dañados y faltantes según los datos reales
                        if (widget.item.hasDamagedItems) {
                          infoItems.add(
                            _buildInfoItem(
                              'Dañados',
                              AppFormatters.formatNumber(widget.item.actualDamagedQuantity),
                              Icons.warning_amber,
                              screenWidth,
                            ),
                          );
                        }
                        
                        if (widget.item.hasMissingItems) {
                          infoItems.add(
                            _buildInfoItem(
                              'Faltantes',
                              AppFormatters.formatNumber(widget.item.actualMissingQuantity),
                              Icons.remove_circle_outline,
                              screenWidth,
                            ),
                          );
                        }

                        infoItems.addAll([
                          _buildInfoItem(
                            'Precio Unit.',
                            AppFormatters.formatCurrency(widget.item.unitPrice),
                            Icons.monetization_on,
                            screenWidth,
                          ),
                          _buildInfoItem(
                            'Total',
                            AppFormatters.formatCurrency((widget.item.receivedQuantity ?? 0) * widget.item.unitPrice),
                            Icons.calculate,
                            screenWidth,
                          ),
                        ]);

                        // Layout responsive basado en número de items
                        if (screenWidth < 600) {
                          // Móvil: 2 columnas por fila
                          return Column(
                            children: [
                              for (int i = 0; i < infoItems.length; i += 2)
                                Padding(
                                  padding: EdgeInsets.only(bottom: i + 2 < infoItems.length ? 8 : 0),
                                  child: Row(
                                    children: [
                                      Expanded(child: infoItems[i]),
                                      if (i + 1 < infoItems.length) Expanded(child: infoItems[i + 1]),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        } else {
                          // Tablet/Desktop: una fila con todos los items
                          return Row(
                            children: infoItems.map((item) => Expanded(child: item)).toList(),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, double screenWidth) {
    // Tamaños responsive
    double iconSize = screenWidth >= 1200 ? 20 : screenWidth >= 800 ? 18 : 16;
    double labelFontSize = screenWidth >= 1200 ? 10 : screenWidth >= 800 ? 9 : 8;
    double valueFontSize = screenWidth >= 1200 ? 12 : screenWidth >= 800 ? 11 : 10;
    
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: iconSize),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: ElegantLightTheme.textTertiary,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: valueFontSize,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Timeline futurista para el workflow
class FuturisticWorkflowTimeline extends StatefulWidget {
  final PurchaseOrder order;

  const FuturisticWorkflowTimeline({Key? key, required this.order})
    : super(key: key);

  @override
  State<FuturisticWorkflowTimeline> createState() =>
      _FuturisticWorkflowTimelineState();
}

class _FuturisticWorkflowTimelineState extends State<FuturisticWorkflowTimeline>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    final events = _buildWorkflowEvents();
    _controllers = List.generate(
      events.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 100)),
        vsync: this,
      ),
    );
    _animations =
        _controllers
            .map(
              (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: controller,
                  curve: ElegantLightTheme.elasticCurve,
                ),
              ),
            )
            .toList();

    // Animar secuencialmente
    _animateSequentially();
  }

  void _animateSequentially() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 100));
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _buildWorkflowEvents() {
    final events = <Map<String, dynamic>>[];

    // Evento de creación
    if (widget.order.createdAt != null) {
      events.add({
        'title': 'Orden creada',
        'description': 'La orden de compra fue creada como borrador',
        'date': widget.order.createdAt!,
        'user': widget.order.createdBy ?? 'Sistema',
        'icon': Icons.add_circle,
        'color': const Color(0xFF64748B),
        'isCompleted': true,
      });
    }

    // Evento de aprobación
    if (widget.order.approvedAt != null) {
      events.add({
        'title': 'Orden aprobada',
        'description': 'La orden fue aprobada y lista para enviar',
        'date': widget.order.approvedAt!,
        'user': widget.order.approvedBy ?? 'Sistema',
        'icon': Icons.check_circle,
        'color': const Color(0xFF3B82F6),
        'isCompleted': true,
      });
    }

    // Evento de envío (basado en estado)
    if (widget.order.isSent || widget.order.isPartiallyReceived || widget.order.isReceived) {
      events.add({
        'title': 'Orden enviada',
        'description': 'La orden fue enviada al proveedor',
        'date': DateTime.now(), // Placeholder
        'user': 'Sistema',
        'icon': Icons.send,
        'color': const Color(0xFF8B5CF6),
        'isCompleted': true,
      });
    }

    // Evento de recepción parcial
    if (widget.order.isPartiallyReceived) {
      events.add({
        'title': 'Recepción parcial',
        'description': 'Algunos productos fueron recibidos. La orden está parcialmente completada.',
        'date': widget.order.deliveredDate ?? DateTime.now(),
        'user': 'Sistema',
        'icon': Icons.pending_actions,
        'color': const Color(0xFFF59E0B),
        'isCompleted': true,
      });
    }

    // Evento de recepción completa
    if (widget.order.isReceived) {
      events.add({
        'title': 'Orden recibida',
        'description':
            'Los productos fueron recibidos e ingresados al inventario',
        'date': widget.order.deliveredDate ?? DateTime.now(),
        'user': 'Sistema',
        'icon': Icons.inventory,
        'color': const Color(0xFF10B981),
        'isCompleted': true,
      });
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final events = _buildWorkflowEvents();
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Tamaños responsive para cronología
    double titleFontSize = screenWidth >= 1200 ? 20 : screenWidth >= 800 ? 18 : 16;
    double iconSize = screenWidth >= 1200 ? 50 : screenWidth >= 800 ? 45 : 40;
    double iconInnerSize = screenWidth >= 1200 ? 24 : screenWidth >= 800 ? 22 : 20;
    double spacing = screenWidth >= 1200 ? 16 : screenWidth >= 800 ? 14 : 12;
    double padding = screenWidth >= 1200 ? 16 : screenWidth >= 800 ? 14 : 12;
    double cardTitleSize = screenWidth >= 1200 ? 16 : screenWidth >= 800 ? 14 : 12;
    double cardDescSize = screenWidth >= 1200 ? 14 : screenWidth >= 800 ? 12 : 10;
    double cardMetaSize = screenWidth >= 1200 ? 12 : screenWidth >= 800 ? 10 : 9;
    double metaIconSize = screenWidth >= 1200 ? 14 : screenWidth >= 800 ? 12 : 11;

    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cronología del Flujo de Trabajo',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          ...events.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;

            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    50 * (1 - _animations[index].value.clamp(0.0, 1.0)),
                    0,
                  ),
                  child: Opacity(
                    opacity: _animations[index].value.clamp(0.0, 1.0),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icono del evento con tamaño responsive
                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  event['color'],
                                  event['color'].withOpacity(0.7),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: event['color'].withOpacity(0.4),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              event['icon'],
                              color: ElegantLightTheme.textPrimary,
                              size: iconInnerSize,
                            ),
                          ),
                          SizedBox(width: spacing),
                          // Contenido del evento responsive
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(padding),
                              decoration: BoxDecoration(
                                gradient: ElegantLightTheme.glassGradient,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ElegantLightTheme.textSecondary.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event['title'],
                                    style: TextStyle(
                                      color: ElegantLightTheme.textPrimary,
                                      fontSize: cardTitleSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    event['description'],
                                    style: TextStyle(
                                      color: ElegantLightTheme.textSecondary,
                                      fontSize: cardDescSize,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Metadata responsive
                                  screenWidth < 600 ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            color: ElegantLightTheme.textTertiary,
                                            size: metaIconSize,
                                          ),
                                          SizedBox(width: spacing / 4),
                                          Expanded(
                                            child: Text(
                                              _formatDate(event['date']),
                                              style: TextStyle(
                                                color: ElegantLightTheme.textTertiary,
                                                fontSize: cardMetaSize,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color: ElegantLightTheme.textTertiary,
                                            size: metaIconSize,
                                          ),
                                          SizedBox(width: spacing / 4),
                                          Expanded(
                                            child: Text(
                                              event['user'],
                                              style: TextStyle(
                                                color: ElegantLightTheme.textTertiary,
                                                fontSize: cardMetaSize,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ) : Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        color: ElegantLightTheme.textTertiary,
                                        size: metaIconSize,
                                      ),
                                      SizedBox(width: spacing / 4),
                                      Expanded(
                                        child: Text(
                                          _formatDate(event['date']),
                                          style: TextStyle(
                                            color: ElegantLightTheme.textTertiary,
                                            fontSize: cardMetaSize,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: spacing),
                                      Icon(
                                        Icons.person,
                                        color: ElegantLightTheme.textTertiary,
                                        size: metaIconSize,
                                      ),
                                      SizedBox(width: spacing / 4),
                                      Expanded(
                                        child: Text(
                                          event['user'],
                                          style: TextStyle(
                                            color: ElegantLightTheme.textTertiary,
                                            fontSize: cardMetaSize,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Efecto de destello para la barra de progreso
class _ProgressShimmerEffect extends StatefulWidget {
  final double borderRadius;

  const _ProgressShimmerEffect({
    required this.borderRadius,
  });

  @override
  State<_ProgressShimmerEffect> createState() => _ProgressShimmerEffectState();
}

class _ProgressShimmerEffectState extends State<_ProgressShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _shimmerAnimation.value * 2, 0),
              end: Alignment(1.0 + _shimmerAnimation.value * 2, 0),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.4),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}
