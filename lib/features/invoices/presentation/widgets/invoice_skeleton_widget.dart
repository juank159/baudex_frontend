// lib/features/invoices/presentation/widgets/invoice_skeleton_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';

/// Widget de skeleton loading para facturas
/// Muestra una representación visual mientras cargan los datos
class InvoiceSkeletonWidget extends StatefulWidget {
  const InvoiceSkeletonWidget({super.key});

  @override
  State<InvoiceSkeletonWidget> createState() => _InvoiceSkeletonWidgetState();
}

class _InvoiceSkeletonWidgetState extends State<InvoiceSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ResponsiveHelper.isMobile(context)
            ? _buildMobileSkeleton()
            : _buildDesktopSkeleton();
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 8,
    bool isCircle = false,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Número de factura y estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBox(width: 100, height: 16),
              _buildShimmerBox(width: 70, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          // Cliente
          Row(
            children: [
              _buildShimmerBox(width: 32, height: 32, isCircle: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(width: 150, height: 14),
                    const SizedBox(height: 4),
                    _buildShimmerBox(width: 100, height: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Totales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 50, height: 10),
                  const SizedBox(height: 4),
                  _buildShimmerBox(width: 80, height: 18),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildShimmerBox(width: 60, height: 10),
                  const SizedBox(height: 4),
                  _buildShimmerBox(width: 70, height: 18),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Icono/Avatar
          _buildShimmerBox(width: 48, height: 48, borderRadius: 12),
          const SizedBox(width: 16),
          // Info principal
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 120, height: 16),
                const SizedBox(height: 8),
                _buildShimmerBox(width: 180, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Cliente
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 100, height: 10),
                const SizedBox(height: 4),
                _buildShimmerBox(width: 140, height: 14),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Montos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildShimmerBox(width: 80, height: 18),
                const SizedBox(height: 6),
                _buildShimmerBox(width: 60, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Estado
          _buildShimmerBox(width: 80, height: 28, borderRadius: 14),
          const SizedBox(width: 16),
          // Acciones
          Row(
            children: [
              _buildShimmerBox(width: 36, height: 36, borderRadius: 8),
              const SizedBox(width: 8),
              _buildShimmerBox(width: 36, height: 36, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lista de skeletons para mostrar durante la carga inicial
class InvoiceSkeletonList extends StatelessWidget {
  final int itemCount;

  const InvoiceSkeletonList({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const InvoiceSkeletonWidget(),
    );
  }
}
