// lib/features/notifications/presentation/widgets/notification_skeleton_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';

class NotificationSkeletonWidget extends StatefulWidget {
  final int itemCount;

  const NotificationSkeletonWidget({
    super.key,
    this.itemCount = 5,
  });

  @override
  State<NotificationSkeletonWidget> createState() => _NotificationSkeletonWidgetState();
}

class _NotificationSkeletonWidgetState extends State<NotificationSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(30 * (1 - value), 0),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: ResponsiveHelper.isMobile(context)
                    ? _buildMobileSkeleton(index)
                    : _buildDesktopSkeleton(index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileSkeleton(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    ...ElegantLightTheme.elevatedShadow,
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildElegantShimmer(
                          width: 48,
                          height: 48,
                          borderRadius: 14,
                          isCircular: false,
                          showGlow: true,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildElegantShimmer(
                                width: 160,
                                height: 16,
                                borderRadius: 8,
                              ),
                              const SizedBox(height: 6),
                              _buildElegantShimmer(
                                width: 100,
                                height: 12,
                                borderRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        _buildElegantShimmer(
                          width: 70,
                          height: 24,
                          borderRadius: 12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildElegantShimmer(
                      width: double.infinity,
                      height: 14,
                      borderRadius: 7,
                    ),
                    const SizedBox(height: 6),
                    _buildElegantShimmer(
                      width: 220,
                      height: 14,
                      borderRadius: 7,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildElegantShimmer(
                          width: 100,
                          height: 32,
                          borderRadius: 10,
                        ),
                        const SizedBox(width: 8),
                        _buildElegantShimmer(
                          width: 80,
                          height: 32,
                          borderRadius: 10,
                        ),
                      ],
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

  Widget _buildDesktopSkeleton(int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.85),
                      Colors.white.withOpacity(0.65),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: ElegantLightTheme.elevatedShadow,
                ),
                child: Row(
                  children: [
                    _buildElegantShimmer(
                      width: 48,
                      height: 48,
                      borderRadius: 14,
                      isCircular: false,
                      showGlow: true,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildElegantShimmer(
                                width: 10,
                                height: 10,
                                borderRadius: 5,
                                isCircular: true,
                              ),
                              const SizedBox(width: 10),
                              _buildElegantShimmer(
                                width: 220,
                                height: 15,
                                borderRadius: 8,
                              ),
                              const Spacer(),
                              _buildElegantShimmer(
                                width: 75,
                                height: 24,
                                borderRadius: 12,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildElegantShimmer(
                            width: 320,
                            height: 13,
                            borderRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    _buildElegantShimmer(
                      width: 85,
                      height: 28,
                      borderRadius: 10,
                    ),
                    const SizedBox(width: 12),
                    _buildElegantShimmer(
                      width: 38,
                      height: 38,
                      borderRadius: 10,
                    ),
                    const SizedBox(width: 6),
                    _buildElegantShimmer(
                      width: 38,
                      height: 38,
                      borderRadius: 10,
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

  Widget _buildElegantShimmer({
    required double width,
    required double height,
    double borderRadius = 8,
    bool isCircular = false,
    bool showGlow = false,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: isCircular ? null : BorderRadius.circular(borderRadius),
            shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ElegantLightTheme.primaryBlue.withOpacity(0.08),
                ElegantLightTheme.primaryBlue.withOpacity(0.15 * _pulseAnimation.value),
                ElegantLightTheme.primaryBlue.withOpacity(0.08),
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: showGlow
                ? [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue
                          .withOpacity(0.1 * _pulseAnimation.value),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
