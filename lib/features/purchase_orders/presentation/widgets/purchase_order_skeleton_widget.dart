// lib/features/purchase_orders/presentation/widgets/purchase_order_skeleton_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';

/// Widget de skeleton loading para órdenes de compra
/// Muestra una representación visual mientras cargan los datos
class PurchaseOrderSkeletonWidget extends StatefulWidget {
  const PurchaseOrderSkeletonWidget({super.key});

  @override
  State<PurchaseOrderSkeletonWidget> createState() =>
      _PurchaseOrderSkeletonWidgetState();
}

class _PurchaseOrderSkeletonWidgetState
    extends State<PurchaseOrderSkeletonWidget>
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
        final screenWidth = MediaQuery.of(context).size.width;
        return screenWidth >= 1200
            ? _buildDesktopSkeleton()
            : _buildMobileSkeleton();
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
            borderRadius:
                isCircle ? null : BorderRadius.circular(borderRadius),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 36, maxHeight: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fila: indicador de estado + número de orden + badge
          Row(
            children: [
              _buildShimmerBox(width: 8, height: 8, isCircle: true),
              const SizedBox(width: 6),
              Expanded(child: _buildShimmerBox(width: 100, height: 10)),
              _buildShimmerBox(width: 50, height: 14, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 4),
          // Fila: proveedor + total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildShimmerBox(width: 8, height: 8),
                    const SizedBox(width: 3),
                    Expanded(child: _buildShimmerBox(width: 80, height: 8)),
                  ],
                ),
              ),
              _buildShimmerBox(width: 60, height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minHeight: 30, maxHeight: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fila: indicador + número + badge estado
          Row(
            children: [
              _buildShimmerBox(width: 8, height: 8, isCircle: true),
              const SizedBox(width: 6),
              Expanded(child: _buildShimmerBox(width: 120, height: 12)),
              _buildShimmerBox(width: 60, height: 16, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 3),
          // Fila: proveedor + fecha + total
          Row(
            children: [
              _buildShimmerBox(width: 10, height: 10),
              const SizedBox(width: 4),
              Expanded(flex: 2, child: _buildShimmerBox(width: 100, height: 9)),
              const SizedBox(width: 8),
              _buildShimmerBox(width: 10, height: 10),
              const SizedBox(width: 4),
              Expanded(child: _buildShimmerBox(width: 70, height: 9)),
              _buildShimmerBox(width: 80, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lista de skeletons para mostrar durante la carga inicial
class PurchaseOrderSkeletonList extends StatelessWidget {
  final int itemCount;

  const PurchaseOrderSkeletonList({
    super.key,
    this.itemCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final padding = isDesktop ? 32.0 : screenWidth >= 600 ? 24.0 : 16.0;

    if (isDesktop) {
      return GridView.builder(
        padding: EdgeInsets.all(padding),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 8.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const PurchaseOrderSkeletonWidget(),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(padding),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const PurchaseOrderSkeletonWidget(),
    );
  }
}

/// Skeleton para la vista de detalle de orden de compra
class PurchaseOrderDetailSkeleton extends StatefulWidget {
  const PurchaseOrderDetailSkeleton({super.key});

  @override
  State<PurchaseOrderDetailSkeleton> createState() =>
      _PurchaseOrderDetailSkeletonState();
}

class _PurchaseOrderDetailSkeletonState
    extends State<PurchaseOrderDetailSkeleton>
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
            borderRadius:
                isCircle ? null : BorderRadius.circular(borderRadius),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withOpacity(0.95),
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header skeleton
            _buildHeaderSkeleton(),
            const SizedBox(height: 12),
            // Workflow skeleton
            _buildWorkflowSkeleton(),
            const SizedBox(height: 12),
            // Tabs skeleton
            _buildTabsSkeleton(),
            const SizedBox(height: 12),
            // Content skeleton
            _buildContentSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título row compacto
          Row(
            children: [
              _buildShimmerBox(width: 42, height: 42, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(width: 160, height: 18),
                    const SizedBox(height: 4),
                    _buildShimmerBox(width: 120, height: 13),
                  ],
                ),
              ),
              _buildShimmerBox(width: 90, height: 28, borderRadius: 14),
            ],
          ),
          const SizedBox(height: 12),
          // Métricas inline como 4 chips
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildShimmerBox(width: 16, height: 16),
                      const SizedBox(height: 4),
                      _buildShimmerBox(width: 30, height: 12),
                      const SizedBox(height: 2),
                      _buildShimmerBox(width: 40, height: 9),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(width: 160, height: 16),
          const SizedBox(height: 16),
          // Workflow steps
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  child: Column(
                    children: [
                      _buildShimmerBox(width: 32, height: 32, isCircle: true),
                      const SizedBox(height: 6),
                      _buildShimmerBox(width: 50, height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildShimmerBox(width: double.infinity, height: 40, borderRadius: 12),
              ),
              const SizedBox(width: 12),
              _buildShimmerBox(width: 40, height: 40, borderRadius: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSkeleton() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: List.generate(
          4,
          (index) => Expanded(
            child: Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildShimmerBox(width: 14, height: 14),
                  const SizedBox(width: 4),
                  _buildShimmerBox(width: 40, height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(width: 160, height: 18),
          const SizedBox(height: 20),
          // Info rows
          ...List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.glassGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    _buildShimmerBox(width: 36, height: 36, borderRadius: 8),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(width: 80, height: 10),
                          const SizedBox(height: 4),
                          _buildShimmerBox(width: 140, height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton para estadísticas
class PurchaseOrderStatsSkeleton extends StatefulWidget {
  const PurchaseOrderStatsSkeleton({super.key});

  @override
  State<PurchaseOrderStatsSkeleton> createState() =>
      _PurchaseOrderStatsSkeletonState();
}

class _PurchaseOrderStatsSkeletonState
    extends State<PurchaseOrderStatsSkeleton>
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

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Stats cards grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : 2,
            childAspectRatio: isDesktop ? 1.5 : 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: List.generate(
              4,
              (index) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: ElegantLightTheme.elevatedShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildShimmerBox(width: 40, height: 40, borderRadius: 12),
                    const SizedBox(height: 12),
                    _buildShimmerBox(width: 60, height: 20),
                    const SizedBox(height: 6),
                    _buildShimmerBox(width: 80, height: 12),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Chart placeholder
          Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(width: 140, height: 16),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      7,
                      (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _buildShimmerBox(
                            width: double.infinity,
                            height: 40.0 + (index * 15.0) % 100,
                            borderRadius: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
