// lib/features/notifications/presentation/widgets/notification_card_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../dashboard/domain/entities/notification.dart' as entities;

class NotificationCardWidget extends StatefulWidget {
  final entities.Notification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationCardWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  State<NotificationCardWidget> createState() => _NotificationCardWidgetState();
}

class _NotificationCardWidgetState extends State<NotificationCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: ResponsiveHelper.isMobile(context)
                ? _buildMobileCard(context)
                : _buildDesktopCard(context),
          ),
        );
      },
    );
  }

  Widget _buildMobileCard(BuildContext context) {
    final typeColor = _getTypeColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [
                          typeColor.withOpacity(0.08),
                          typeColor.withOpacity(0.03),
                        ]
                      : widget.notification.isRead
                          ? [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.7),
                            ]
                          : [
                              typeColor.withOpacity(0.12),
                              typeColor.withOpacity(0.05),
                            ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.notification.isRead
                      ? Colors.white.withOpacity(0.4)
                      : typeColor.withOpacity(0.4),
                  width: widget.notification.isRead ? 1 : 1.5,
                ),
                boxShadow: [
                  ...ElegantLightTheme.glassShadow,
                  if (!widget.notification.isRead)
                    BoxShadow(
                      color: typeColor.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildModernTypeIcon(),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.notification.title,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontSize: 15,
                                      fontWeight: widget.notification.isRead
                                          ? FontWeight.w600
                                          : FontWeight.w700,
                                      color: ElegantLightTheme.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (!widget.notification.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                            gradient: _getTypeGradient(),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: typeColor.withOpacity(0.5),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      Text(
                                        widget.notification.formattedTime,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontSize: 12,
                                          color: ElegantLightTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _buildModernPriorityBadge(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.notification.message,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 14,
                            color: ElegantLightTheme.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!widget.notification.isRead && widget.onMarkAsRead != null)
                              _buildActionButton(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'Marcar leida',
                                color: ElegantLightTheme.successGreen,
                                onPressed: widget.onMarkAsRead!,
                              ),
                            if (widget.onDelete != null) ...[
                              if (!widget.notification.isRead && widget.onMarkAsRead != null)
                                const SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.delete_outline_rounded,
                                label: 'Eliminar',
                                color: ElegantLightTheme.errorRed,
                                onPressed: widget.onDelete!,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context) {
    final typeColor = _getTypeColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isHovered
                      ? [
                          typeColor.withOpacity(0.06),
                          typeColor.withOpacity(0.02),
                        ]
                      : widget.notification.isRead
                          ? [
                              Colors.white.withOpacity(0.85),
                              Colors.white.withOpacity(0.65),
                            ]
                          : [
                              typeColor.withOpacity(0.10),
                              typeColor.withOpacity(0.04),
                            ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered
                      ? typeColor.withOpacity(0.3)
                      : widget.notification.isRead
                          ? Colors.white.withOpacity(0.4)
                          : typeColor.withOpacity(0.3),
                  width: widget.notification.isRead ? 1 : 1.5,
                ),
                boxShadow: [
                  ...ElegantLightTheme.elevatedShadow,
                  if (!widget.notification.isRead || _isHovered)
                    BoxShadow(
                      color: typeColor.withOpacity(_isHovered ? 0.15 : 0.1),
                      blurRadius: _isHovered ? 20 : 12,
                      offset: const Offset(0, 4),
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        _buildModernTypeIcon(),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        if (!widget.notification.isRead)
                                          Container(
                                            width: 10,
                                            height: 10,
                                            margin: const EdgeInsets.only(right: 10),
                                            decoration: BoxDecoration(
                                              gradient: _getTypeGradient(),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: typeColor.withOpacity(0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            widget.notification.title,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontSize: 15,
                                              fontWeight: widget.notification.isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.w700,
                                              color: ElegantLightTheme.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildModernPriorityBadge(),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.notification.message,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 13,
                                  color: ElegantLightTheme.textSecondary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Time badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.textSecondary.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            widget.notification.formattedTime,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              color: ElegantLightTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Action buttons
                        if (!widget.notification.isRead && widget.onMarkAsRead != null)
                          _buildIconActionButton(
                            icon: Icons.check_circle_outline_rounded,
                            tooltip: 'Marcar como leida',
                            color: ElegantLightTheme.successGreen,
                            onPressed: widget.onMarkAsRead!,
                          ),
                        if (widget.onDelete != null)
                          _buildIconActionButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Eliminar',
                            color: ElegantLightTheme.errorRed,
                            onPressed: widget.onDelete!,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTypeIcon() {
    final iconData = _getTypeIconData();
    final color = _getTypeColor();
    final gradient = _getTypeGradient();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            iconData,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildModernPriorityBadge() {
    final priority = widget.notification.priority;
    final color = _getPriorityColor();
    final gradient = _getPriorityGradient();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPriorityIcon(),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Text(
              priority.displayName.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.12),
                color.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.12),
                  color.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIconData() {
    switch (widget.notification.type) {
      case entities.NotificationType.system:
        return Icons.settings_rounded;
      case entities.NotificationType.payment:
        return Icons.payment_rounded;
      case entities.NotificationType.invoice:
        return Icons.receipt_long_rounded;
      case entities.NotificationType.lowStock:
        return Icons.inventory_rounded;
      case entities.NotificationType.expense:
        return Icons.trending_down_rounded;
      case entities.NotificationType.sale:
        return Icons.trending_up_rounded;
      case entities.NotificationType.user:
        return Icons.person_rounded;
      case entities.NotificationType.reminder:
        return Icons.schedule_rounded;
    }
  }

  Color _getTypeColor() {
    switch (widget.notification.type) {
      case entities.NotificationType.system:
        return const Color(0xFF6366F1); // Indigo
      case entities.NotificationType.payment:
        return ElegantLightTheme.successGreen;
      case entities.NotificationType.invoice:
        return ElegantLightTheme.primaryBlue;
      case entities.NotificationType.lowStock:
        return ElegantLightTheme.warningOrange;
      case entities.NotificationType.expense:
        return ElegantLightTheme.errorRed;
      case entities.NotificationType.sale:
        return const Color(0xFF14B8A6); // Teal
      case entities.NotificationType.user:
        return const Color(0xFF8B5CF6); // Purple
      case entities.NotificationType.reminder:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  LinearGradient _getTypeGradient() {
    final color = _getTypeColor();
    switch (widget.notification.type) {
      case entities.NotificationType.system:
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        );
      case entities.NotificationType.payment:
        return ElegantLightTheme.successGradient;
      case entities.NotificationType.invoice:
        return ElegantLightTheme.infoGradient;
      case entities.NotificationType.lowStock:
        return ElegantLightTheme.warningGradient;
      case entities.NotificationType.expense:
        return ElegantLightTheme.errorGradient;
      case entities.NotificationType.sale:
        return const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
        );
      case entities.NotificationType.user:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
      case entities.NotificationType.reminder:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
    }
  }

  Color _getPriorityColor() {
    switch (widget.notification.priority) {
      case entities.NotificationPriority.low:
        return const Color(0xFF64748B); // Slate
      case entities.NotificationPriority.medium:
        return ElegantLightTheme.primaryBlue;
      case entities.NotificationPriority.high:
        return ElegantLightTheme.warningOrange;
      case entities.NotificationPriority.urgent:
        return ElegantLightTheme.errorRed;
    }
  }

  LinearGradient _getPriorityGradient() {
    switch (widget.notification.priority) {
      case entities.NotificationPriority.low:
        return const LinearGradient(
          colors: [Color(0xFF64748B), Color(0xFF475569)],
        );
      case entities.NotificationPriority.medium:
        return ElegantLightTheme.infoGradient;
      case entities.NotificationPriority.high:
        return ElegantLightTheme.warningGradient;
      case entities.NotificationPriority.urgent:
        return ElegantLightTheme.errorGradient;
    }
  }

  IconData _getPriorityIcon() {
    switch (widget.notification.priority) {
      case entities.NotificationPriority.low:
        return Icons.arrow_downward_rounded;
      case entities.NotificationPriority.medium:
        return Icons.remove_rounded;
      case entities.NotificationPriority.high:
        return Icons.arrow_upward_rounded;
      case entities.NotificationPriority.urgent:
        return Icons.priority_high_rounded;
    }
  }
}
