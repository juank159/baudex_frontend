// lib/features/purchase_orders/presentation/widgets/smart_workflow_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/purchase_order.dart';

// Widget inteligente que combina múltiples acciones en una sola
class SmartWorkflowWidget extends StatefulWidget {
  final PurchaseOrder order;
  final Function(String action, {Map<String, dynamic>? data})? onAction;

  const SmartWorkflowWidget({
    Key? key,
    required this.order,
    this.onAction,
  }) : super(key: key);

  @override
  State<SmartWorkflowWidget> createState() => _SmartWorkflowWidgetState();
}

class _SmartWorkflowWidgetState extends State<SmartWorkflowWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ElegantLightTheme.smoothCurve,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticContainer(
      hasGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Workflow Inteligente',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Acciones recomendadas basadas en el estado actual',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildSmartActions(),
        ],
      ),
    );
  }

  Widget _buildSmartActions() {
    switch (widget.order.status) {
      case PurchaseOrderStatus.draft:
        return _buildDraftActions();
      case PurchaseOrderStatus.pending:
        return _buildPendingActions();
      case PurchaseOrderStatus.approved:
        return _buildApprovedActions();
      case PurchaseOrderStatus.sent:
        return _buildSentActions();
      case PurchaseOrderStatus.partiallyReceived:
        return _buildPartiallyReceivedActions();
      case PurchaseOrderStatus.received:
        return _buildReceivedActions();
      case PurchaseOrderStatus.cancelled:
        return _buildCancelledActions();
      case PurchaseOrderStatus.rejected:
      default:
        return _buildDefaultActions();
    }
  }

  Widget _buildDraftActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 1200;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;
        final isMobile = screenWidth < 600;

        if (isMobile) {
          // Mobile: columna vertical
          return Column(
            children: [
              _buildCompactPrimaryAction(
                title: 'Enviar para Revisión',
                icon: Icons.send,
                gradient: ElegantLightTheme.infoGradient,
                onTap: () => _executeAction('submit_for_review'),
              ),
              const SizedBox(height: 8),
              _buildCompactSecondaryAction(
                title: 'Continuar Editando',
                icon: Icons.edit,
                onTap: () => _executeAction('edit'),
              ),
              const SizedBox(height: 8),
              if (widget.order.canCancel)
                _buildCompactDangerAction(
                  title: 'Cancelar Orden',
                  icon: Icons.cancel,
                  onTap: () => _executeAction('cancel'),
                ),
            ],
          );
        } else {
          // Desktop y Tablet: fila horizontal
          return Row(
            children: [
              Expanded(
                child: _buildCompactPrimaryAction(
                  title: 'Enviar para Revisión',
                  icon: Icons.send,
                  gradient: ElegantLightTheme.infoGradient,
                  onTap: () => _executeAction('submit_for_review'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactSecondaryAction(
                  title: 'Continuar Editando',
                  icon: Icons.edit,
                  onTap: () => _executeAction('edit'),
                ),
              ),
              if (widget.order.canCancel) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactDangerAction(
                    title: 'Cancelar Orden',
                    icon: Icons.cancel,
                    onTap: () => _executeAction('cancel'),
                  ),
                ),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildPendingActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;

        if (isMobile) {
          // Mobile: columna vertical
          return Column(
            children: [
              _buildCompactPrimaryAction(
                title: 'Aprobar y Enviar',
                icon: Icons.send,
                gradient: ElegantLightTheme.successGradient,
                onTap: () => _executeSmartAction('approve_and_send'),
              ),
              const SizedBox(height: 8),
              _buildCompactSecondaryAction(
                title: 'Solo Aprobar',
                icon: Icons.check,
                onTap: () => _executeAction('approve'),
              ),
              const SizedBox(height: 8),
              if (widget.order.canCancel)
                _buildCompactDangerAction(
                  title: 'Cancelar Orden',
                  icon: Icons.cancel,
                  onTap: () => _executeAction('cancel'),
                ),
            ],
          );
        } else {
          // Desktop y Tablet: fila horizontal
          return Row(
            children: [
              Expanded(
                child: _buildCompactPrimaryAction(
                  title: 'Aprobar y Enviar',
                  icon: Icons.send,
                  gradient: ElegantLightTheme.successGradient,
                  onTap: () => _executeSmartAction('approve_and_send'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactSecondaryAction(
                  title: 'Solo Aprobar',
                  icon: Icons.check,
                  onTap: () => _executeAction('approve'),
                ),
              ),
              if (widget.order.canCancel) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactDangerAction(
                    title: 'Cancelar Orden',
                    icon: Icons.cancel,
                    onTap: () => _executeAction('cancel'),
                  ),
                ),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildApprovedActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;

        if (isMobile) {
          // Mobile: columna vertical
          return Column(
            children: [
              _buildCompactPrimaryAction(
                title: 'Enviar al Proveedor',
                icon: Icons.send,
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                onTap: () => _executeAction('send'),
              ),
              const SizedBox(height: 8),
              if (widget.order.canCancel)
                _buildCompactDangerAction(
                  title: 'Cancelar Orden',
                  icon: Icons.cancel,
                  onTap: () => _executeAction('cancel'),
                ),
            ],
          );
        } else {
          // Desktop y Tablet: fila horizontal con botones más compactos
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: _buildCompactPrimaryAction(
                  title: 'Enviar al Proveedor',
                  icon: Icons.send,
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                  onTap: () => _executeAction('send'),
                ),
              ),
              if (widget.order.canCancel) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: _buildCompactDangerAction(
                    title: 'Cancelar Orden',
                    icon: Icons.cancel,
                    onTap: () => _executeAction('cancel'),
                  ),
                ),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildSentActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;

        if (isMobile) {
          // Mobile: columna vertical
          return Column(
            children: [
              _buildCompactPrimaryAction(
                title: 'Recepción Rápida',
                icon: Icons.flash_on,
                gradient: ElegantLightTheme.successGradient,
                onTap: () => _showQuickReceiveDialog(),
              ),
              const SizedBox(height: 8),
              _buildCompactSecondaryAction(
                title: 'Recepción Personalizada',
                icon: Icons.tune,
                onTap: () => _executeAction('custom_receive'),
              ),
              const SizedBox(height: 8),
              if (widget.order.canCancel)
                _buildCompactDangerAction(
                  title: 'Cancelar Orden',
                  icon: Icons.cancel,
                  onTap: () => _executeAction('cancel'),
                ),
            ],
          );
        } else {
          // Desktop y Tablet: fila horizontal con botones más compactos
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: _buildCompactPrimaryAction(
                  title: 'Recepción Rápida',
                  icon: Icons.flash_on,
                  gradient: ElegantLightTheme.successGradient,
                  onTap: () => _showQuickReceiveDialog(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: _buildCompactSecondaryAction(
                  title: 'Recepción Personalizada',
                  icon: Icons.tune,
                  onTap: () => _executeAction('custom_receive'),
                ),
              ),
              if (widget.order.canCancel) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: _buildCompactDangerAction(
                    title: 'Cancelar Orden',
                    icon: Icons.cancel,
                    onTap: () => _executeAction('cancel'),
                  ),
                ),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildReceivedActions() {
    return Column(
      children: [
        _buildInfoCard(
          'Orden Completada',
          'Todos los productos han sido recibidos e ingresados al inventario',
          Icons.check_circle,
          ElegantLightTheme.successGradient.colors.first,
        ),
      ],
    );
  }

  Widget _buildPartiallyReceivedActions() {
    return Column(
      children: [
        _buildInfoCard(
          'Orden Parcialmente Recibida',
          'Esta orden ha sido procesada parcialmente. Su ciclo de recepción ha finalizado.',
          Icons.check_circle_outline,
          ElegantLightTheme.warningGradient.colors.first,
        ),
      ],
    );
  }

  Widget _buildCancelledActions() {
    return Column(
      children: [
        _buildInfoCard(
          'Orden Cancelada',
          'Esta orden de compra ha sido cancelada y no puede ser procesada',
          Icons.cancel,
          ElegantLightTheme.errorGradient.colors.first,
        ),
      ],
    );
  }

  Widget _buildDefaultActions() {
    return _buildInfoCard(
      'Sin Acciones Disponibles',
      'No hay acciones disponibles para este estado',
      Icons.info,
      Colors.grey,
    );
  }

  Widget _buildPrimaryAction({
    required String title,
    required String description,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isProcessing ? _scaleAnimation.value : 1.0,
          child: FuturisticButton(
            text: title,
            icon: icon,
            gradient: gradient,
            width: double.infinity,
            height: 60,
            onPressed: _isProcessing ? null : onTap,
            isLoading: _isProcessing,
          ),
        );
      },
    );
  }

  Widget _buildSecondaryAction({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Ajustar padding y fontSize según el tamaño de pantalla
        double horizontalPadding = screenWidth >= 1200 ? 16 : screenWidth >= 800 ? 12 : 8;
        double fontSize = screenWidth >= 1200 ? 14 : screenWidth >= 800 ? 12 : 10;
        double iconSize = screenWidth >= 1200 ? 18 : screenWidth >= 800 ? 16 : 14;
        
        return Container(
          height: 45,
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (color ?? const Color(0xFF6366F1)).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isProcessing ? null : onTap,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: color ?? const Color(0xFF6366F1),
                      size: iconSize,
                    ),
                    SizedBox(width: screenWidth >= 800 ? 8 : 4),
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: color ?? ElegantLightTheme.textPrimary,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _executeAction(String action) {
    if (widget.onAction != null) {
      widget.onAction!(action);
    }
  }

  void _executeSmartAction(String action) async {
    setState(() {
      _isProcessing = true;
    });
    _animationController.repeat(reverse: true);

    // Simular procesamiento
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
    });
    _animationController.stop();
    _animationController.reset();

    if (widget.onAction != null) {
      widget.onAction!(action);
    }
  }

  void _showQuickReceiveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: FuturisticContainer(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.warningGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: ElegantLightTheme.textPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Recepción Rápida',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Deseas recibir automáticamente todos los items de esta orden?',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esto marcará todos los productos como recibidos al 100% y los ingresará al inventario.',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FuturisticButton(
                        text: 'Cancelar',
                        onPressed: () => Navigator.of(context).pop(),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF64748B), Color(0xFF475569)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FuturisticButton(
                        text: 'Confirmar',
                        icon: Icons.check,
                        onPressed: () {
                          Navigator.of(context).pop();
                          _executeSmartAction('quick_receive');
                        },
                        gradient: ElegantLightTheme.successGradient,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDangerAction({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Ajustar padding y fontSize según el tamaño de pantalla
        double horizontalPadding = screenWidth >= 1200 ? 16 : screenWidth >= 800 ? 12 : 8;
        double fontSize = screenWidth >= 1200 ? 14 : screenWidth >= 800 ? 12 : 10;
        double iconSize = screenWidth >= 1200 ? 18 : screenWidth >= 800 ? 16 : 14;
        
        return Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.errorGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ElegantLightTheme.errorGradient.colors.first.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactPrimaryAction({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSecondaryAction({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.grey.shade700, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDangerAction({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.errorGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.errorGradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}