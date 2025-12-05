// lib/features/products/presentation/widgets/product_skeleton_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';

/// Widget de skeleton loading para productos
/// Muestra una representación visual mientras cargan los datos
class ProductSkeletonWidget extends StatefulWidget {
  const ProductSkeletonWidget({super.key});

  @override
  State<ProductSkeletonWidget> createState() => _ProductSkeletonWidgetState();
}

class _ProductSkeletonWidgetState extends State<ProductSkeletonWidget>
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              _buildShimmerBox(width: 36, height: 36, isCircle: true),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(width: 150, height: 14),
                    const SizedBox(height: 6),
                    _buildShimmerBox(width: 100, height: 10),
                  ],
                ),
              ),
              // Badge
              _buildShimmerBox(width: 60, height: 20, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildShimmerBox(width: double.infinity, height: 28, borderRadius: 6)),
              const SizedBox(width: 6),
              Expanded(child: _buildShimmerBox(width: double.infinity, height: 28, borderRadius: 6)),
              const SizedBox(width: 6),
              Expanded(child: _buildShimmerBox(width: double.infinity, height: 28, borderRadius: 6)),
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
          // Icon
          _buildShimmerBox(width: 56, height: 56, borderRadius: 14),
          const SizedBox(width: 20),
          // Info principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 200, height: 16),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildShimmerBox(width: 80, height: 12),
                    const SizedBox(width: 16),
                    _buildShimmerBox(width: 100, height: 12),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Info adicional
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 100, height: 12),
                const SizedBox(height: 8),
                _buildShimmerBox(width: 80, height: 12),
                const SizedBox(height: 8),
                _buildShimmerBox(width: 90, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Acciones
          Column(
            children: [
              _buildShimmerBox(width: 80, height: 26, borderRadius: 8),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildShimmerBox(width: 34, height: 34, borderRadius: 8),
                  const SizedBox(width: 6),
                  _buildShimmerBox(width: 34, height: 34, borderRadius: 8),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lista de skeletons para mostrar durante la carga inicial
class ProductSkeletonList extends StatelessWidget {
  final int itemCount;

  const ProductSkeletonList({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ProductSkeletonWidget(),
    );
  }
}
